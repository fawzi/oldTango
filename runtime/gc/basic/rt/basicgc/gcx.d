/**
 * This module contains the garbage collector implementation.
 *
 * Copyright: Copyright (C) 2001-2007 Digital Mars, www.digitalmars.com.
 *            All rights reserved.
 * License:
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 * Authors:   Walter Bright, David Friedman, Sean Kelly
 */
module rt.basicgc.gcx;
// D Programming Language Garbage Collector implementation

/************** Debugging ***************************/

//debug = PRINTF;               // turn on printf's
//debug = COLLECT_PRINTF;       // turn on printf's
//debug = THREADINVARIANT;      // check thread integrity
//debug = LOGGING;              // log allocations / frees
//debug = MEMSTOMP;             // stomp on memory
//debug = SENTINEL;             // add underrun/overrrun protection
//debug = PTRCHECK;             // more pointer checking
//debug = PTRCHECK2;            // thorough but slow pointer checking

/*************** Configuration *********************/

version = STACKGROWSDOWN;       // growing the stack means subtracting from the stack pointer
                                // (use for Intel X86 CPUs)
                                // else growing the stack means adding to the stack pointer
version = MULTI_THREADED;       // produce multithreaded version

/***************************************************/

private import rt.basicgc.gcbits;
private import rt.basicgc.gcstats;
private import rt.basicgc.gcalloc;
private import tango.core.sync.Atomic;

private{
    version (Win32)
    {
        private extern (Windows) 
        {
            int QueryPerformanceCounter   (ulong *count);
            int QueryPerformanceFrequency (ulong *frequency);
        }
    }

    version (Posix)
    {
        private import tango.stdc.posix.sys.time;
    }

    version (Win32){
        /// systemwide realtime clock
        ulong realtimeClock(){
            ulong res;
            if (! QueryPerformanceCounter (&res))
                throw new Exception ("high-resolution timer is not available");
            return res;
        }
        /// frequency (in seconds) of the systemwide realtime clock
        ulong realtimeClockFreq(){
            ulong res;
            if (! QueryPerformanceFrequency (&res))
                throw new Exception ("high-resolution timer is not available");
            return res;
        }
    } else version (Posix) {
    
        /// systemwide realtime clock
        ulong realtimeClock(){
            timeval tv;
            if (gettimeofday (&tv, null))
                throw new Exception ("Timer :: linux timer is not available");

            return (cast(ulong) tv.tv_sec * 1_000_000) + tv.tv_usec;
        }
    
        /// frequency (in seconds) of the systemwide realtime clock
        ulong realtimeClockFreq(){
            return 1_000_000UL;
        }
    }
}
import cImports=rt.cImports: calloc, free, malloc, realloc, memcpy, memmove, memset;
//private import cstdlib = tango.stdc.stdlib : calloc, free, malloc, realloc;
//private import cstring = tango.stdc.string : memcpy, memmove, memset;
debug(THREADINVARIANT) private import tango.stdc.posix.pthread;
debug(PRINTF) private import tango.stdc.posix.pthread : pthread_self, pthread_t;
debug private import tango.stdc.stdio : printf;
private import tango.stdc.stdio : printf; // pippo
private import tango.stdc.stdlib: abort;
version (GNU)
{
    // BUG: The following import will likely not work, since the gcc
    //      subdirectory is elsewhere.  Instead, perhaps the functions
    //      could be declared directly or some other resolution could
    //      be found.
    private import gcc.builtins; // for __builtin_unwind_init
}


struct BlkInfo
{
    void*  base;
    size_t size;
    uint   attr;
}

private
{
    enum BlkAttr : uint
    {
        FINALIZE = 0b0000_0001,
        NO_SCAN  = 0b0000_0010,
        NO_MOVE  = 0b0000_0100,
        ALL_BITS = 0b1111_1111
    }

    extern (C) void* rt_stackBottom();
    extern (C) void* rt_stackTop();

    extern (C) void rt_finalize( void* p, bool det = true );

    alias void delegate( void*, void* ) scanFn;

    extern (C) void rt_scanStaticData( scanFn scan );

    version (MULTI_THREADED)
    {
        extern (C) bool thread_needLock();
        extern (C) void thread_suspendAll();
        extern (C) void thread_resumeAll();

        extern (C) void thread_scanAll( scanFn fn, void* curStackTop = null );
    }

    extern (C) void onOutOfMemoryError();

    enum
    {
        OPFAIL = ~cast(size_t)0
    }
}


alias GC gc_t;


/* ======================= Leak Detector =========================== */


debug (LOGGING)
{
    struct Log
    {
        void*  p;
        size_t size;
        size_t line;
        char*  file;
        void*  parent;

        void print()
        {
            printf("    p = %x, size = %d, parent = %x ", p, size, parent);
            if (file)
            {
                printf("%s(%u)", file, line);
            }
            printf("\n");
        }
    }


    struct LogArray
    {
        size_t dim;
        size_t allocdim;
        Log *data;

        void Dtor()
        {
            if (data)
                cImports.free(data);
            data = null;
        }

        void reserve(size_t nentries)
        {
            assert(dim <= allocdim);
            if (allocdim - dim < nentries)
            {
                allocdim = (dim + nentries) * 2;
                assert(dim + nentries <= allocdim);
                if (!data)
                {
                    data = cast(Log*)cImports.malloc(allocdim * Log.sizeof);
                    if (!data && allocdim)
                        onOutOfMemoryError();
                }
                else
                {   Log *newdata;

                    newdata = cast(Log*)cImports.malloc(allocdim * Log.sizeof);
                    if (!newdata && allocdim)
                        onOutOfMemoryError();
                    cImports.memcpy(newdata, data, dim * Log.sizeof);
                    cImports.free(data);
                    data = newdata;
                }
            }
        }


        void push(Log log)
        {
            reserve(1);
            data[dim++] = log;
        }

        void remove(size_t i)
        {
            cImports.memmove(data + i, data + i + 1, (dim - i) * Log.sizeof);
            dim--;
        }


        size_t find(void *p)
        {
            for (size_t i = 0; i < dim; i++)
            {
                if (data[i].p == p)
                    return i;
            }
            return OPFAIL; // not found
        }


        void copy(LogArray *from)
        {
            reserve(from.dim - dim);
            assert(from.dim <= allocdim);
            cImports.memcpy(data, from.data, from.dim * Log.sizeof);
            dim = from.dim;
        }
    }
}


/* ============================ GC =============================== */


class GCLock { }                // just a dummy so we can get a global lock


const uint GCVERSION = 1;       // increment every time we change interface
                                // to GC.

class GC
{
    // For passing to debug code
    static size_t line;
    static char*  file;

    uint gcversion = GCVERSION;

    Gcx *gcx;                   // implementation
    static ClassInfo gcLock;    // global lock

    version(AllocTimeStats){
        ulong totalAllocTime;
        ulong nAlloc;
    }


    void initialize()
    {
        gcLock = GCLock.classinfo;
        gcx = cast(Gcx*)cImports.calloc(1, Gcx.sizeof);
        if (!gcx)
            onOutOfMemoryError();
        gcx.initialize();
        setStackBottom(rt_stackBottom());
    }


    void Dtor()
    {
        version (linux)
        {
            //debug(PRINTF) printf("Thread %x ", pthread_self());
            //debug(PRINTF) printf("GC.Dtor()\n");
        }

        if (gcx)
        {
            gcx.Dtor();
            cImports.free(gcx);
            gcx = null;
        }
    }


    invariant
    {
        if (gcx)
        {
            gcx.thread_Invariant();
        }
    }


    void finishGCRun()
    {
        if (thread_needLock())
        {
            int dummy;
            synchronized (gcLock){
                ++dummy;
            }
        }
    }

    /**
     *
     */
    void enable()
    {
        if (!thread_needLock())
        {
            assert(gcx.disabled > 0);
            gcx.disabled--;
        }
        else synchronized (gcLock)
        {
            assert(gcx.disabled > 0);
            gcx.disabled--;
        }
    }


    /**
     *
     */
    void disable()
    {
        if (!thread_needLock())
        {
            gcx.disabled++;
        }
        else synchronized (gcLock)
        {
            gcx.disabled++;
        }
    }


    /**
     *
     */
    uint getAttr(void* p)
    {
        if (!p)
        {
            return 0;
        }

        uint go()
        {
            Pool* pool = gcx.findPool(p);
            uint  oldb = 0;

            if (pool)
            {
                auto biti = cast(size_t)(p - pool.baseAddr) / 16;

                oldb = gcx.getBits(pool, biti);
            }
            return oldb;
        }

        if (!thread_needLock())
        {
            return go();
        }
        else synchronized (gcLock)
        {
            return go();
        }
    }


    /**
     *
     */
    uint setAttr(void* p, uint mask)
    {
        if (!p)
        {
            return 0;
        }

        uint go()
        {
            Pool* pool = gcx.findPool(p);
            uint  oldb = 0;

            if (pool)
            {
                auto biti = cast(size_t)(p - pool.baseAddr) / 16;

                oldb = gcx.getBits(pool, biti);
                gcx.setBits(pool, biti, mask);
            }
            return oldb;
        }

        if (!thread_needLock())
        {
            return go();
        }
        else synchronized (gcLock)
        {
            return go();
        }
    }


    /**
     *
     */
    uint clrAttr(void* p, uint mask)
    {
        if (!p)
        {
            return 0;
        }

        uint go()
        {
            Pool* pool = gcx.findPool(p);
            uint  oldb = 0;

            if (pool)
            {
                auto biti = cast(size_t)(p - pool.baseAddr) / 16;

                oldb = gcx.getBits(pool, biti);
                gcx.clrBits(pool, biti, mask);
            }
            return oldb;
        }

        if (!thread_needLock())
        {
            return go();
        }
        else synchronized (gcLock)
        {
            return go();
        }
    }


    /**
     *
     */
    void *malloc(size_t size, uint bits = 0)
    {
        version(AllocTimeStats){
            atomicAdd(nAlloc,1);
            auto t=realtimeClock();
            scope(exit){
                atomicAdd(totalAllocTime,realtimeClock()-t);
            }
        }
        
        if (!size)
        {
            return null;
        }

        if (!thread_needLock())
        {
            return mallocNoSync(size, bits);
        }
        else synchronized (gcLock)
        {
            return mallocNoSync(size, bits);
        }
    }


    //
    //
    //
    private void *mallocNoSync(size_t size, uint bits = 0)
    {
        assert(size != 0);

        void *p = null;
        Bins bin;

        //debug(PRINTF) printf("GC::malloc(size = %d, gcx = %p)\n", size, gcx);
        assert(gcx);
        //debug(PRINTF) printf("gcx.self = %x, pthread_self() = %x\n", gcx.self, pthread_self());

        size += SENTINEL_EXTRA;

        // Compute size bin
        // Cache previous binsize lookup - Dave Fladebo.
        static size_t lastsize = -1;
        static Bins lastbin;
        if (size == lastsize)
            bin = lastbin;
        else
        {
            bin = gcx.findBin(size);
            lastsize = size;
            lastbin = bin;
        }

        if (bin < B_PAGE)
        {
            p = gcx.bucket[bin];
            if (p is null)
            {
                if (!gcx.allocPage(bin) && !gcx.disabled)   // try to find a new page
                {
                    if (!thread_needLock())
                    {
                        /* Then we haven't locked it yet. Be sure
                         * and lock for a collection, since a finalizer
                         * may start a new thread.
                         */
                        synchronized (gcLock)
                        {
                            gcx.fullcollectshell();
                        }
                    }
                    else if (!gcx.fullcollectshell())       // collect to find a new page
                    {
                        //gcx.newPool(1);
                    }
                }
                if (!gcx.bucket[bin] && !gcx.allocPage(bin))
                {   int result;

                    gcx.newPool(1);         // allocate new pool to find a new page
                    result = gcx.allocPage(bin);
                    if (!result)
                        onOutOfMemoryError();
                }
                p = gcx.bucket[bin];
            }

            // Return next item from free list
            gcx.bucket[bin] = (cast(List*)p).next;
            if( !(bits & BlkAttr.NO_SCAN) )
                cImports.memset(p + size, 0, binsize[bin] - size);
            //debug(PRINTF) printf("\tmalloc => %x\n", p);
            debug (MEMSTOMP) cImports.memset(p, 0xF0, size);
        }
        else
        {
            p = gcx.bigAlloc(size);
            if (!p)
                onOutOfMemoryError();
        }
        size -= SENTINEL_EXTRA;
        p = sentinel_add(p);
        sentinel_init(p, size);
        gcx.log_malloc(p, size);

        if (bits)
        {
            Pool *pool = gcx.findPool(p);
            assert(pool!is null,"pool is null!");

            gcx.setBits(pool, cast(size_t)(p - pool.baseAddr) / 16, bits);
        }
        return p;
    }


    /**
     *
     */
    void *calloc(size_t size, uint bits = 0)
    {
        version(AllocTimeStats){
            atomicAdd(nAlloc,1);
            auto t=realtimeClock();
            scope(exit){
                atomicAdd(totalAllocTime,realtimeClock()-t);
            }
        }

        if (!size)
        {
            return null;
        }

        if (!thread_needLock())
        {
            return callocNoSync(size, bits);
        }
        else synchronized (gcLock)
        {
            return callocNoSync(size, bits);
        }
    }


    //
    //
    //
    private void *callocNoSync(size_t size, uint bits = 0)
    {
        assert(size != 0);

        //debug(PRINTF) printf("calloc: %x len %d\n", p, len);
        void *p = mallocNoSync(size, bits);
        cImports.memset(p, 0, size);
        return p;
    }


    /**
     *
     */
    void *realloc(void *p, size_t size, uint bits = 0)
    {
        version(AllocTimeStats){
            atomicAdd(nAlloc,1);
            auto t=realtimeClock();
            scope(exit){
                atomicAdd(totalAllocTime,realtimeClock()-t);
            }
        }

        if (!thread_needLock())
        {
            return reallocNoSync(p, size, bits);
        }
        else synchronized (gcLock)
        {
            return reallocNoSync(p, size, bits);
        }
    }


    //
    //
    //
    private void *reallocNoSync(void *p, size_t size, uint bits = 0)
    {
        if (!size)
        {   if (p)
            {   freeNoSync(p);
                p = null;
            }
        }
        else if (!p)
        {
            p = mallocNoSync(size, bits);
        }
        else
        {   void *p2;
            size_t psize;

            //debug(PRINTF) printf("GC::realloc(p = %x, size = %u)\n", p, size);
            version (SENTINEL)
            {
                sentinel_Invariant(p);
                psize = *sentinel_size(p);
                if (psize != size)
                {
                    if (psize)
                    {
                        Pool *pool = gcx.findPool(p);

                        if (pool)
                        {
                            auto biti = cast(size_t)(p - pool.baseAddr) / 16;

                            if (bits)
                            {
                                gcx.clrBits(pool, biti, BlkAttr.ALL_BITS);
                                gcx.setBits(pool, biti, bits);
                            }
                            else
                            {
                                bits = gcx.getBits(pool, biti);
                            }
                        }
                    }
                    p2 = mallocNoSync(size, bits);
                    if (psize < size)
                        size = psize;
                    //debug(PRINTF) printf("\tcopying %d bytes\n",size);
                    cImports.memcpy(p2, p, size);
                    p = p2;
                }
            }
            else
            {
                psize = gcx.findSize(p);        // find allocated size
                if (psize >= PAGESIZE && size >= PAGESIZE)
                {
                    auto psz = psize / PAGESIZE;
                    auto newsz = (size + PAGESIZE - 1) / PAGESIZE;
                    if (newsz == psz)
                        return p;

                    auto pool = gcx.findPool(p);
                    auto pagenum = (p - pool.baseAddr) / PAGESIZE;

                    if (newsz < psz)
                    {   // Shrink in place
                        synchronized (gcLock)
                        {
                            debug (MEMSTOMP) cImports.memset(p + size, 0xF2, psize - size);
                            pool.freePages(pagenum + newsz, psz - newsz);
                        }
                        return p;
                    }
                    else if (pagenum + newsz <= pool.npages)
                    {
                        // Attempt to expand in place
                        synchronized (gcLock)
                        {
                            for (size_t i = pagenum + psz; 1;)
                            {
                                if (i == pagenum + newsz)
                                {
                                    debug (MEMSTOMP) cImports.memset(p + psize, 0xF0, size - psize);
                                    cImports.memset(&pool.pagetable[pagenum + psz], B_PAGEPLUS, newsz - psz);
                                    return p;
                                }
                                if (i == pool.ncommitted)
                                {
                                    auto u = pool.extendPages(pagenum + newsz - pool.ncommitted);
                                    if (u == OPFAIL)
                                        break;
                                    i = pagenum + newsz;
                                    continue;
                                }
                                if (pool.pagetable[i] != B_FREE)
                                    break;
                                i++;
                            }
                        }
                    }
                }
                if (psize < size ||             // if new size is bigger
                    psize > size * 2)           // or less than half
                {
                    if (psize)
                    {
                        Pool *pool = gcx.findPool(p);

                        if (pool)
                        {
                            auto biti = cast(size_t)(p - pool.baseAddr) / 16;

                            if (bits)
                            {
                                gcx.clrBits(pool, biti, BlkAttr.ALL_BITS);
                                gcx.setBits(pool, biti, bits);
                            }
                            else
                            {
                                bits = gcx.getBits(pool, biti);
                            }
                        }
                    }
                    p2 = mallocNoSync(size, bits);
                    if (psize < size)
                        size = psize;
                    //debug(PRINTF) printf("\tcopying %d bytes\n",size);
                    cImports.memcpy(p2, p, size);
                    p = p2;
                }
            }
        }
        return p;
    }


    /**
     * Attempt to in-place enlarge the memory block pointed to by p by at least
     * minbytes beyond its current capacity, up to a maximum of maxsize.  This
     * does not attempt to move the memory block (like realloc() does).
     *
     * Returns:
     *  0 if could not extend p,
     *  total size of entire memory block if successful.
     */
    size_t extend(void* p, size_t minsize, size_t maxsize)
    {
        version(AllocTimeStats){
            atomicAdd(nAlloc,1);
            auto t=realtimeClock();
            scope(exit){
                atomicAdd(totalAllocTime,realtimeClock()-t);
            }
        }

        if (!thread_needLock())
        {
            return extendNoSync(p, minsize, maxsize);
        }
        else synchronized (gcLock)
        {
            return extendNoSync(p, minsize, maxsize);
        }
    }


    //
    //
    //
    private size_t extendNoSync(void* p, size_t minsize, size_t maxsize)
    in
    {
        assert( minsize <= maxsize );
    }
    body
    {
        //debug(PRINTF) printf("GC::extend(p = %x, minsize = %u, maxsize = %u)\n", p, minsize, maxsize);
        version (SENTINEL)
        {
            return 0;
        }
        auto psize = gcx.findSize(p);   // find allocated size
        if (psize < PAGESIZE)
            return 0;                   // cannot extend buckets

        auto psz = psize / PAGESIZE;
        auto minsz = (minsize + PAGESIZE - 1) / PAGESIZE;
        auto maxsz = (maxsize + PAGESIZE - 1) / PAGESIZE;

        auto pool = gcx.findPool(p);
        auto pagenum = (p - pool.baseAddr) / PAGESIZE;

        size_t sz;
        for (sz = 0; sz < maxsz; sz++)
        {
            auto i = pagenum + psz + sz;
            if (i == pool.ncommitted)
                break;
            if (pool.pagetable[i] != B_FREE)
            {   if (sz < minsz)
                    return 0;
                break;
            }
        }
        if (sz >= minsz)
        {
        }
        else if (pagenum + psz + sz == pool.ncommitted)
        {
            auto u = pool.extendPages(minsz - sz);
            if (u == OPFAIL)
                return 0;
            sz = minsz;
        }
        else
            return 0;
        debug (MEMSTOMP) cImports.memset(p + psize, 0xF0, (psz + sz) * PAGESIZE - psize);
        cImports.memset(pool.pagetable + pagenum + psz, B_PAGEPLUS, sz);
        gcx.p_cache = null;
        gcx.size_cache = 0;
        return (psz + sz) * PAGESIZE;
    }


    /**
     *
     */
    size_t reserve(size_t size)
    {
        if (!size)
        {
            return 0;
        }

        if (!thread_needLock())
        {
            return reserveNoSync(size);
        }
        else synchronized (gcLock)
        {
            return reserveNoSync(size);
        }
    }


    //
    //
    //
    private size_t reserveNoSync(size_t size)
    {
        assert(size != 0);
        assert(gcx);

        return gcx.reserve(size);
    }


    /**
     *
     */
    void free(void *p)
    {
        version(AllocTimeStats){
            atomicAdd(nAlloc,1);
            auto t=realtimeClock();
            scope(exit){
                atomicAdd(totalAllocTime,realtimeClock()-t);
            }
        }

        if (!p)
        {
            return;
        }

        if (!thread_needLock())
        {
            return freeNoSync(p);
        }
        else synchronized (gcLock)
        {
            return freeNoSync(p);
        }
    }


    //
    //
    //
    private void freeNoSync(void *p)
    {
        assert (p);

        Pool*  pool;
        size_t pagenum;
        Bins   bin;
        size_t biti;

        // Find which page it is in
        pool = gcx.findPool(p);
        if (!pool)                              // if not one of ours
            return;                             // ignore
        sentinel_Invariant(p);
        p = sentinel_sub(p);
        pagenum = cast(size_t)(p - pool.baseAddr) / PAGESIZE;
        biti = cast(size_t)(p - pool.baseAddr) / 16;
        gcx.clrBits(pool, biti, BlkAttr.ALL_BITS);

        bin = cast(Bins)pool.pagetable[pagenum];
        if (bin == B_PAGE)              // if large alloc
        {   size_t npages;
            size_t n;

            // Free pages
            npages = 1;
            n = pagenum;
            while (++n < pool.ncommitted && pool.pagetable[n] == B_PAGEPLUS)
                npages++;
            debug (MEMSTOMP) cImports.memset(p, 0xF2, npages * PAGESIZE);
            pool.freePages(pagenum, npages);
        }
        else
        {   // Add to free list
            List *list = cast(List*)p;

            debug (MEMSTOMP) cImports.memset(p, 0xF2, binsize[bin]);

            list.next = gcx.bucket[bin];
            gcx.bucket[bin] = list;
        }
        gcx.log_free(sentinel_add(p));
    }


    /**
     * Determine the base address of the block containing p.  If p is not a gc
     * allocated pointer, return null.
     */
    void* addrOf(void *p)
    {
        if (!p)
        {
            return null;
        }

        if (!thread_needLock())
        {
            return addrOfNoSync(p);
        }
        else synchronized (gcLock)
        {
            return addrOfNoSync(p);
        }
    }


    //
    //
    //
    void* addrOfNoSync(void *p)
    {
        if (!p)
        {
            return null;
        }

        return gcx.findBase(p);
    }


    /**
     * Determine the allocated size of pointer p.  If p is an interior pointer
     * or not a gc allocated pointer, return 0.
     */
    size_t sizeOf(void *p)
    {
        if (!p)
        {
            return 0;
        }

        if (!thread_needLock())
        {
            return sizeOfNoSync(p);
        }
        else synchronized (gcLock)
        {
            return sizeOfNoSync(p);
        }
    }


    //
    //
    //
    private size_t sizeOfNoSync(void *p)
    {
        assert (p);

        version (SENTINEL)
        {
            p = sentinel_sub(p);
            size_t size = gcx.findSize(p);

            // Check for interior pointer
            // This depends on:
            // 1) size is a power of 2 for less than PAGESIZE values
            // 2) base of memory pool is aligned on PAGESIZE boundary
            if (cast(size_t)p & (size - 1) & (PAGESIZE - 1))
                size = 0;
            return size ? size - SENTINEL_EXTRA : 0;
        }
        else
        {
            if (p == gcx.p_cache)
                return gcx.size_cache;

            size_t size = gcx.findSize(p);

            // Check for interior pointer
            // This depends on:
            // 1) size is a power of 2 for less than PAGESIZE values
            // 2) base of memory pool is aligned on PAGESIZE boundary
            if (cast(size_t)p & (size - 1) & (PAGESIZE - 1))
                size = 0;
            else
            {
                gcx.p_cache = p;
                gcx.size_cache = size;
            }

            return size;
        }
    }


    /**
     * Determine the base address of the block containing p.  If p is not a gc
     * allocated pointer, return null.
     */
    BlkInfo query(void *p)
    {
        if (!p)
        {
            BlkInfo i;
            return  i;
        }

        if (!thread_needLock())
        {
            return queryNoSync(p);
        }
        else synchronized (gcLock)
        {
            return queryNoSync(p);
        }
    }


    //
    //
    //
    BlkInfo queryNoSync(void *p)
    {
        assert(p);

        return gcx.getInfo(p);
    }


    /**
     * Verify that pointer p:
     *  1) belongs to this memory pool
     *  2) points to the start of an allocated piece of memory
     *  3) is not on a free list
     */
    void check(void *p)
    {
        if (!p)
        {
            return;
        }

        if (!thread_needLock())
        {
            checkNoSync(p);
        }
        else synchronized (gcLock)
        {
            checkNoSync(p);
        }
    }


    //
    //
    //
    private void checkNoSync(void *p)
    {
        assert(p);

        sentinel_Invariant(p);
        debug (PTRCHECK)
        {
            Pool*  pool;
            size_t pagenum;
            Bins   bin;
            size_t size;

            p = sentinel_sub(p);
            pool = gcx.findPool(p);
            assert(pool);
            pagenum = cast(size_t)(p - pool.baseAddr) / PAGESIZE;
            bin = cast(Bins)pool.pagetable[pagenum];
            assert(bin <= B_PAGE);
            size = binsize[bin];
            assert((cast(size_t)p & (size - 1)) == 0);

            debug (PTRCHECK2)
            {
                if (bin < B_PAGE)
                {
                    // Check that p is not on a free list
                    List *list;

                    for (list = gcx.bucket[bin]; list; list = list.next)
                    {
                        assert(cast(void*)list != p);
                    }
                }
            }
        }
    }


    //
    //
    //
    private void setStackBottom(void *p)
    {
        version (STACKGROWSDOWN)
        {
            //p = (void *)((uint *)p + 4);
            if (p > gcx.stackBottom)
            {
                //debug(PRINTF) printf("setStackBottom(%x)\n", p);
                gcx.stackBottom = p;
            }
        }
        else
        {
            //p = (void *)((uint *)p - 4);
            if (p < gcx.stackBottom)
            {
                //debug(PRINTF) printf("setStackBottom(%x)\n", p);
                gcx.stackBottom = cast(char*)p;
            }
        }
    }


    /**
     * add p to list of roots
     */
    void addRoot(void *p)
    {
        if (!p)
        {
            return;
        }

        if (!thread_needLock())
        {
            gcx.addRoot(p);
        }
        else synchronized (gcLock)
        {
            gcx.addRoot(p);
        }
    }


    /**
     * remove p from list of roots
     */
    void removeRoot(void *p)
    {
        if (!p)
        {
            return;
        }

        if (!thread_needLock())
        {
            gcx.removeRoot(p);
        }
        else synchronized (gcLock)
        {
            gcx.removeRoot(p);
        }
    }


    /**
     * add range to scan for roots
     */
    void addRange(void *p, size_t sz)
    {
        if (!p || !sz)
        {
            return;
        }

        //debug(PRINTF) printf("+GC.addRange(pbot = x%x, ptop = x%x)\n", pbot, ptop);
        if (!thread_needLock())
        {
            gcx.addRange(p, p + sz);
        }
        else synchronized (gcLock)
        {
            gcx.addRange(p, p + sz);
        }
        //debug(PRINTF) printf("-GC.addRange()\n");
    }


    /**
     * remove range
     */
    void removeRange(void *p)
    {
        if (!p)
        {
            return;
        }

        if (!thread_needLock())
        {
            gcx.removeRange(p);
        }
        else synchronized (gcLock)
        {
            gcx.removeRange(p);
        }
    }


    /**
     * do full garbage collection
     */
    void fullCollect()
    {
        debug(PRINTF) printf("GC.fullCollect()\n");

        if (!thread_needLock())
        {
            gcx.fullcollectshell();
        }
        else synchronized (gcLock)
        {
            gcx.fullcollectshell();
        }

        version (none)
        {
            GCStatsInternal statsInt;

            getStats(statsInt);
            debug(PRINTF) printf("poolSize = %x, usedSize = %x, freelistSize = %x\n",
                    statsInt.poolSize, statsInt.usedSize, statsInt.freelistSize);
        }

        gcx.log_collect();
    }


    /**
     * do full garbage collection ignoring roots
     */
    void fullCollectNoStack()
    {
        if (!thread_needLock())
        {
            gcx.noStack++;
            gcx.fullcollectshell();
            gcx.noStack--;
        }
        else synchronized (gcLock)
        {
            gcx.noStack++;
            gcx.fullcollectshell();
            gcx.noStack--;
        }
    }


    /**
     * minimize free space usage
     */
    void minimize()
    {
        if (!thread_needLock())
        {
            gcx.minimize();
        }
        else synchronized (gcLock)
        {
            gcx.minimize();
        }
    }


    /**
     * Retrieve statistics about garbage collection.
     * Useful for debugging and tuning.
     */
    void getStats(out GCStatsInternal stats, int statDetail=0)
    {
        if (!thread_needLock())
        {
            getStatsNoSync(stats,statDetail);
        }
        else synchronized (gcLock)
        {
            getStatsNoSync(stats,statDetail);
        }
    }


    //
    //
    //
    private void getStatsNoSync(out GCStatsInternal stats, int statDetail=0)
    {
        cImports.memset(&stats, 0, GCStatsInternal.sizeof);
        if (statDetail==0){
            size_t psize = 0;
            size_t usize = 0;
            size_t flsize = 0;

            size_t n;
            size_t bsize = 0;

            //debug(PRINTF) printf("getStats()\n");

            for (n = 0; n < gcx.npools; n++)
            {   Pool *pool = gcx.pooltable[n];

                psize += pool.ncommitted * PAGESIZE;
                for (size_t j = 0; j < pool.ncommitted; j++)
                {
                    Bins bin = cast(Bins)pool.pagetable[j];
                    if (bin == B_FREE)
                        stats.freeBlocks++;
                    else if (bin == B_PAGE)
                        stats.pageBlocks++;
                    else if (bin < B_PAGE)
                        bsize += PAGESIZE;
                }
            }

            for (n = 0; n < B_PAGE; n++)
            {
                //debug(PRINTF) printf("bin %d\n", n);
                for (List *list = gcx.bucket[n]; list; list = list.next)
                {
                    //debug(PRINTF) printf("\tlist %x\n", list);
                    flsize += binsize[n];
                }
            }

            usize = bsize - flsize;

            stats.poolSize = psize;
            stats.usedSize = bsize - flsize;
            stats.freelistSize = flsize;
        }
        stats.totalMarkTime=gcx.totalMarkTime;
        stats.totalSweepTime=gcx.totalSweepTime;
        stats.totalPagesFreed=gcx.totalPagesFreed;
        stats.gcCounter=gcx.gcCounter;
        version(AllocTimeStats){
            stats.totalAllocTime=totalAllocTime;
            stats.totalAllocTimeFreq=realtimeClockFreq();
            stats.nAlloc=nAlloc;
        }
    }

    size_t gcCounter(){
        return gcx.gcCounter;
    }

    /// calls all destructors of GC managed objects
    void callAllDestructors(){
        gcx.callAllDestructors();
    }
    
}


/* ============================ Gcx =============================== */

enum
{   PAGESIZE =    4096,
    COMMITSIZE = (4096*16),
    POOLSIZE =   (4096*256),
}


enum
{
    B_16,
    B_32,
    B_64,
    B_128,
    B_256,
    B_512,
    B_1024,
    B_2048,
    B_PAGE,             // start of large alloc
    B_PAGEPLUS,         // continuation of large alloc
    B_FREE,             // free page
    B_UNCOMMITTED,      // memory not committed for this page
    B_MAX
}


alias ubyte Bins;


struct List
{
    List *next;
}


struct Range
{
    void *pbot;
    void *ptop;
}


const uint binsize[B_MAX] = [ 16,32,64,128,256,512,1024,2048,4096 ];
const uint notbinsize[B_MAX] = [ ~(16u-1),~(32u-1),~(64u-1),~(128u-1),~(256u-1),
                                ~(512u-1),~(1024u-1),~(2048u-1),~(4096u-1) ];

/* ============================ Gcx =============================== */


struct Gcx
{
    debug (THREADINVARIANT)
    {
        pthread_t self;
        void thread_Invariant()
        {
            if (self != pthread_self())
                printf("thread_Invariant(): gcx = %x, self = %x, pthread_self() = %x\n", this, self, pthread_self());
            assert(self == pthread_self());
        }
    }
    else
    {
        void thread_Invariant() { }
    }

    void *p_cache;
    size_t size_cache;

    size_t nroots;
    size_t rootdim;
    void **roots;

    size_t nranges;
    size_t rangedim;
    Range *ranges;

    uint noStack;       // !=0 means don't scan stack
    uint log;           // turn on logging
    uint anychanges;
    void *stackBottom;
    uint inited;
    int disabled;       // turn off collections if >0

    byte *minAddr;      // min(baseAddr)
    byte *maxAddr;      // max(topAddr)

    size_t npools;
    Pool **pooltable;

    List *bucket[B_MAX];        // free list for each size

    real totalMarkTime;
    real totalSweepTime;
    real totalPagesFreed;
    size_t gcCounter;    // counter of gc collections, guaranteed to change at each mark and at each sweep phase, 1 during the sweep phase

    void initialize()
    {   int dummy;

        (cast(byte*)this)[0 .. Gcx.sizeof] = 0;
        stackBottom = cast(char*)&dummy;
        log_init();
        debug (THREADINVARIANT)
            self = pthread_self();
        //printf("gcx = %p, self = %x\n", this, self);
        gcCounter=0;
        inited = 1;
    }


    void Dtor()
    {
        inited = 0;

        for (size_t i = 0; i < npools; i++)
        {   Pool *pool = pooltable[i];

            pool.Dtor();
            cImports.free(pool);
        }
        if (pooltable)
            cImports.free(pooltable);

        if (roots)
            cImports.free(roots);

        if (ranges)
            cImports.free(ranges);
    }


    void Invariant() { }


    void invariantTest()
    {
        if (inited)
        {
        //printf("Gcx.invariant(): this = %p\n", this);
            size_t i;

            // Assure we're called on the right thread
            debug (THREADINVARIANT) assert(self == pthread_self());

            for (i = 0; i < npools; i++)
            {   Pool *pool = pooltable[i];
                if (pool is null){
                    printf("pool was null in gcx\n"); // pippo
                    abort();
                }

                pool.Invariant();
                if (i == 0)
                {
                    assert(minAddr == pool.baseAddr);
                }
                if (i + 1 < npools)
                {
                    assert(pool.opCmp(pooltable[i + 1]) < 0);
                }
                else if (i + 1 == npools)
                {
                    assert(maxAddr == pool.topAddr);
                }
            }

            if (roots)
            {
                assert(rootdim != 0);
                assert(nroots <= rootdim);
            }

            if (ranges)
            {
                assert(rangedim != 0);
                assert(nranges <= rangedim);

                for (i = 0; i < nranges; i++)
                {
                    assert(ranges[i].pbot);
                    assert(ranges[i].ptop);
                    assert(ranges[i].pbot <= ranges[i].ptop);
                }
            }

            for (i = 0; i < B_PAGE; i++)
            {
                for (List *list = bucket[i]; list; list = list.next)
                {
                }
            }
        }
    }


    /**
     *
     */
    void addRoot(void *p)
    {
        if (nroots == rootdim)
        {
            size_t newdim = rootdim * 2 + 16;
            void** newroots;

            newroots = cast(void**)cImports.malloc(newdim * newroots[0].sizeof);
            if (!newroots)
                onOutOfMemoryError();
            if (roots)
            {   cImports.memcpy(newroots, roots, nroots * newroots[0].sizeof);
                cImports.free(roots);
            }
            roots = newroots;
            rootdim = newdim;
        }
        roots[nroots] = p;
        nroots++;
    }

    invariant{
        // invariantTest should aquire the gc lock :(... but this might change some synchronization and
        // slows down gc_malloc much, switching it off for now)
        // invariantTest();
    }

    /**
     *
     */
    void removeRoot(void *p)
    {
        for (size_t i = nroots; i--;)
        {
            if (roots[i] == p)
            {
                nroots--;
                cImports.memmove(roots + i, roots + i + 1, (nroots - i) * roots[0].sizeof);
                return;
            }
        }
        assert(0);
    }


    /**
     *
     */
    void addRange(void *pbot, void *ptop)
    {
        debug(PRINTF) printf("Thread %x ", pthread_self());
        debug(PRINTF) printf("%x.Gcx::addRange(%x, %x), nranges = %d\n", this, pbot, ptop, nranges);
        if (nranges == rangedim)
        {
            size_t newdim = rangedim * 2 + 16;
            Range *newranges;

            newranges = cast(Range*)cImports.malloc(newdim * newranges[0].sizeof);
            if (!newranges)
                onOutOfMemoryError();
            if (ranges)
            {   cImports.memcpy(newranges, ranges, nranges * newranges[0].sizeof);
                cImports.free(ranges);
            }
            ranges = newranges;
            rangedim = newdim;
        }
        ranges[nranges].pbot = pbot;
        ranges[nranges].ptop = ptop;
        nranges++;
    }


    /**
     *
     */
    void removeRange(void *pbot)
    {
        debug(PRINTF) printf("Thread %x ", pthread_self());
        debug(PRINTF) printf("%x.Gcx.removeRange(%x), nranges = %d\n", this, pbot, nranges);
        for (size_t i = nranges; i--;)
        {
            if (ranges[i].pbot == pbot)
            {
                nranges--;
                cImports.memmove(ranges + i, ranges + i + 1, (nranges - i) * ranges[0].sizeof);
                return;
            }
        }
        debug(PRINTF) printf("Wrong thread\n");

        // This is a fatal error, but ignore it.
        // The problem is that we can get a Close() call on a thread
        // other than the one the range was allocated on.
        //assert(zero);
    }


    /**
     * Find Pool that pointer is in.
     * Return null if not in a Pool.
     * Assume pooltable[] is sorted.
     */
    Pool *findPool(void *p)
    {
        if (p >= minAddr && p < maxAddr)
        {
            if (npools == 1)
            {
                return pooltable[0];
            }

            for (size_t i = 0; i < npools; i++)
            {   Pool *pool;

                pool = pooltable[i];
                if (p < pool.topAddr)
                {   if (pool.baseAddr <= p)
                        return pool;
                    break;
                }
            }
        }
        return null;
    }


    /**
     * Find base address of block containing pointer p.
     * Returns null if not a gc'd pointer
     */
    void* findBase(void *p)
    {
        Pool *pool;

        pool = findPool(p);
        if (pool)
        {
            size_t offset = cast(size_t)(p - pool.baseAddr);
            size_t pn = offset / PAGESIZE;
            Bins   bin = cast(Bins)pool.pagetable[pn];

            // Adjust bit to be at start of allocated memory block
            if (bin <= B_PAGE)
            {
                return pool.baseAddr + (offset & notbinsize[bin]);
            }
            else if (bin == B_PAGEPLUS)
            {
                do
                {   --pn, offset -= PAGESIZE;
                } while (cast(Bins)pool.pagetable[pn] == B_PAGEPLUS);

                return pool.baseAddr + (offset & (offset.max ^ (PAGESIZE-1)));
            }
            else
            {
                // we are in a B_FREE or B_UNCOMMITTED page
                return null;
            }
        }
        return null;
    }


    /**
     * Find size of pointer p.
     * Returns 0 if not a gc'd pointer
     */
    size_t findSize(void *p)
    {
        Pool*  pool;
        size_t size = 0;

        pool = findPool(p);
        if (pool)
        {
            size_t pagenum;
            Bins   bin;

            pagenum = cast(size_t)(p - pool.baseAddr) / PAGESIZE;
            bin = cast(Bins)pool.pagetable[pagenum];
            size = binsize[bin];
            if (bin == B_PAGE)
            {   size_t npages = pool.ncommitted;
                ubyte* pt;
                size_t i;

                pt = &pool.pagetable[0];
                for (i = pagenum + 1; i < npages; i++)
                {
                    if (pt[i] != B_PAGEPLUS)
                        break;
                }
                size = (i - pagenum) * PAGESIZE;
            }
        }
        return size;
    }


    /**
     *
     */
    BlkInfo getInfo(void* p)
    {
        Pool*   pool;
        BlkInfo info;

        pool = findPool(p);
        if (pool)
        {
            size_t offset = cast(size_t)(p - pool.baseAddr);
            size_t pn = offset / PAGESIZE;
            Bins   bin = cast(Bins)pool.pagetable[pn];

            ////////////////////////////////////////////////////////////////////
            // findAddr
            ////////////////////////////////////////////////////////////////////

            if (bin <= B_PAGE)
            {
                info.base = pool.baseAddr + (offset & notbinsize[bin]);
            }
            else if (bin == B_PAGEPLUS)
            {
                do
                {   --pn, offset -= PAGESIZE;
                } while (cast(Bins)pool.pagetable[pn] == B_PAGEPLUS);

                info.base = pool.baseAddr + (offset & (offset.max ^ (PAGESIZE-1)));

                // fix bin for use by size calc below
                bin = cast(Bins)pool.pagetable[pn];
            }

            ////////////////////////////////////////////////////////////////////
            // findSize
            ////////////////////////////////////////////////////////////////////

            info.size = binsize[bin];
            if (bin == B_PAGE)
            {   size_t npages = pool.ncommitted;
                ubyte* pt;
                size_t i;

                pt = &pool.pagetable[0];
                for (i = pn + 1; i < npages; i++)
                {
                    if (pt[i] != B_PAGEPLUS)
                        break;
                }
                info.size = (i - pn) * PAGESIZE;
            }

            ////////////////////////////////////////////////////////////////////
            // getBits
            ////////////////////////////////////////////////////////////////////

            info.attr = getBits(pool, cast(size_t)(offset / 16));
        }
        return info;
    }


    /**
     * Compute bin for size.
     */
    static Bins findBin(size_t size)
    {   Bins bin;

        if (size <= 256)
        {
            if (size <= 64)
            {
                if (size <= 16)
                    bin = B_16;
                else if (size <= 32)
                    bin = B_32;
                else
                    bin = B_64;
            }
            else
            {
                if (size <= 128)
                    bin = B_128;
                else
                    bin = B_256;
            }
        }
        else
        {
            if (size <= 1024)
            {
                if (size <= 512)
                    bin = B_512;
                else
                    bin = B_1024;
            }
            else
            {
                if (size <= 2048)
                    bin = B_2048;
                else
                    bin = B_PAGE;
            }
        }
        return bin;
    }


    /**
     * Allocate a new pool of at least size bytes.
     * Sort it into pooltable[].
     * Mark all memory in the pool as B_FREE.
     * Return the actual number of bytes reserved or 0 on error.
     */
    size_t reserve(size_t size)
    {
        size_t npages = (size + PAGESIZE - 1) / PAGESIZE;
        Pool*  pool = newPool(npages);

        if (!pool || pool.extendPages(npages) == OPFAIL)
            return 0;
        return pool.ncommitted * PAGESIZE;
    }


    /**
     * Minimizes physical memory usage by returning free pools to the OS.
     */
    void minimize()
    {
        size_t n;
        size_t pn;
        Pool*  pool;
        size_t ncommitted;

        for (n = 0; n < npools; n++)
        {
            pool = pooltable[n];
            ncommitted = pool.ncommitted;
            for (pn = 0; pn < ncommitted; pn++)
            {
                if (cast(Bins)pool.pagetable[pn] != B_FREE)
                    break;
            }
            if (pn < ncommitted)
            {
                n++;
                continue;
            }
            pool.Dtor();
            cImports.free(pool);
            cImports.memmove(pooltable + n,
                            pooltable + n + 1,
                            (--npools - n) * (Pool*).sizeof);
            minAddr = pooltable[0].baseAddr;
            maxAddr = pooltable[npools - 1].topAddr;
        }
    }


    /**
     * Allocate a chunk of memory that is larger than a page.
     * Return null if out of memory.
     */
    void *bigAlloc(size_t size)
    {
        Pool*  pool;
        size_t npages;
        size_t n;
        size_t pn;
        size_t freedpages;
        void*  p;
        int    state;

        npages = (size + PAGESIZE - 1) / PAGESIZE;

        for (state = 0; ; )
        {
            // This code could use some refinement when repeatedly
            // allocating very large arrays.

            for (n = 0; n < npools; n++)
            {
                pool = pooltable[n];
                pn = pool.allocPages(npages);
                if (pn != OPFAIL)
                    goto L1;
            }

            // Failed
            switch (state)
            {
            case 0:
                if (disabled)
                {   state = 1;
                    continue;
                }
                // Try collecting
                freedpages = fullcollectshell();
                if (freedpages >= npools * ((POOLSIZE / PAGESIZE) / 4))
                {   state = 1;
                    continue;
                }
                // Release empty pools to prevent bloat
                minimize();
                // Allocate new pool
                pool = newPool(npages);
                if (!pool)
                {   state = 2;
                    continue;
                }
                pn = pool.allocPages(npages);
                assert(pn != OPFAIL);
                goto L1;
            case 1:
                // Release empty pools to prevent bloat
                minimize();
                // Allocate new pool
                pool = newPool(npages);
                if (!pool)
                    goto Lnomemory;
                pn = pool.allocPages(npages);
                assert(pn != OPFAIL);
                goto L1;
            case 2:
                goto Lnomemory;
            default:
                assert(false);
            }
        }

      L1:
        pool.pagetable[pn] = B_PAGE;
        if (npages > 1)
            cImports.memset(&pool.pagetable[pn + 1], B_PAGEPLUS, npages - 1);
        p = pool.baseAddr + pn * PAGESIZE;
        cImports.memset(cast(char *)p + size, 0, npages * PAGESIZE - size);
        debug (MEMSTOMP) cImports.memset(p, 0xF1, size);
        //debug(PRINTF) printf("\tp = %x\n", p);
        return p;

      Lnomemory:
        return null; // let mallocNoSync handle the error
    }


    /**
     * Allocate a new pool with at least npages in it.
     * Sort it into pooltable[].
     * Return null if failed.
     */
    Pool *newPool(size_t npages)
    {
        Pool*  pool;
        Pool** newpooltable;
        size_t newnpools;
        size_t i;

        //debug(PRINTF) printf("************Gcx::newPool(npages = %d)****************\n", npages);

        // Round up to COMMITSIZE pages
        npages = (npages + (COMMITSIZE/PAGESIZE) - 1) & ~(COMMITSIZE/PAGESIZE - 1);

        // Minimum of POOLSIZE
        if (npages < POOLSIZE/PAGESIZE)
            npages = POOLSIZE/PAGESIZE;
        else if (npages > POOLSIZE/PAGESIZE)
        {   // Give us 150% of requested size, so there's room to extend
            auto n = npages + (npages >> 1);
            if (n < size_t.max/PAGESIZE)
                npages = n;
        }

        // Allocate successively larger pools up to 8 megs
        if (npools)
        {   size_t n;

            n = npools;
            if (n > 8)
                n = 8;                  // cap pool size at 8 megs
            n *= (POOLSIZE / PAGESIZE);
            if (npages < n)
                npages = n;
        }

        pool = cast(Pool *)cImports.calloc(1, Pool.sizeof);
        if (pool)
        {
            pool.initialize(npages);
            if (!pool.baseAddr)
                goto Lerr;

            newnpools = npools + 1;
            newpooltable = cast(Pool **)cImports.realloc(pooltable, newnpools * (Pool *).sizeof);
            if (!newpooltable)
                goto Lerr;

            // Sort pool into newpooltable[]
            for (i = 0; i < npools; i++)
            {
                if (pool.opCmp(newpooltable[i]) < 0)
                     break;
            }
            cImports.memmove(newpooltable + i + 1, newpooltable + i, (npools - i) * (Pool *).sizeof);
            newpooltable[i] = pool;

            pooltable = newpooltable;
            npools = newnpools;

            minAddr = pooltable[0].baseAddr;
            maxAddr = pooltable[npools - 1].topAddr;
        }
        return pool;

      Lerr:
        pool.Dtor();
        cImports.free(pool);
        return null;
    }


    /**
     * Allocate a page of bin's.
     * Returns:
     *  0       failed
     */
    int allocPage(Bins bin)
    {
        Pool*  pool;
        size_t n;
        size_t pn;
        byte*  p;
        byte*  ptop;

        //debug(PRINTF) printf("Gcx::allocPage(bin = %d)\n", bin);
        for (n = 0; n < npools; n++)
        {
            pool = pooltable[n];
            pn = pool.allocPages(1);
            if (pn != OPFAIL)
                goto L1;
        }
        return 0;               // failed

      L1:
        pool.pagetable[pn] = cast(ubyte)bin;

        // Convert page to free list
        size_t size = binsize[bin];
        List **b = &bucket[bin];

        p = pool.baseAddr + pn * PAGESIZE;
        ptop = p + PAGESIZE;
        for (; p < ptop; p += size)
        {
            (cast(List *)p).next = *b;
            *b = cast(List *)p;
        }
        return 1;
    }


    /**
     * Search a range of memory values and mark any pointers into the GC pool.
     */
    void mark(void *pbot, void *ptop)
    {
        void **p1 = cast(void **)pbot;
        void **p2 = cast(void **)ptop;
        size_t pcache = 0;
        uint changes = 0;

        //printf("marking range: %p -> %p\n", pbot, ptop);
        for (; p1 < p2; p1++)
        {
            Pool *pool;
            byte *p = cast(byte *)(*p1);

            //if (log) debug(PRINTF) printf("\tmark %x\n", p);
            if (p >= minAddr && p < maxAddr)
            {
                if ((cast(size_t)p & ~(PAGESIZE-1)) == pcache)
 	            continue;

                pool = findPool(p);
                if (pool)
                {
                    size_t offset = cast(size_t)(p - pool.baseAddr);
                    size_t biti;
                    size_t pn = offset / PAGESIZE;
                    Bins   bin = cast(Bins)pool.pagetable[pn];

                    //debug(PRINTF) printf("\t\tfound pool %x, base=%x, pn = %d, bin = %d, biti = x%x\n", pool, pool.baseAddr, pn, bin, biti);

                    // Adjust bit to be at start of allocated memory block
                    if (bin <= B_PAGE)
                    {
                        biti = (offset & notbinsize[bin]) >> 4;
                        //debug(PRINTF) printf("\t\tbiti = x%x\n", biti);
                    }
                    else if (bin == B_PAGEPLUS)
                    {
                        do
                        {   --pn;
                        } while (cast(Bins)pool.pagetable[pn] == B_PAGEPLUS);
                        biti = pn * (PAGESIZE / 16);
                    }
                    else
                    {
                        // Don't mark bits in B_FREE or B_UNCOMMITTED pages
                        continue;
                    }

                    if (bin >= B_PAGE) // Cache B_PAGE and B_PAGEPLUS lookups
                        pcache = cast(size_t)p & ~(PAGESIZE-1);

                    //debug(PRINTF) printf("\t\tmark(x%x) = %d\n", biti, pool.mark.test(biti));
                    if (!pool.mark.test(biti))
                    {
                        //if (log) debug(PRINTF) printf("\t\tmarking %x\n", p);
                        pool.mark.set(biti);
                        if (!pool.noscan.test(biti))
                        {
                            pool.scan.set(biti);
                            changes = 1;
                        }
                        log_parent(sentinel_add(pool.baseAddr + biti * 16), sentinel_add(pbot));
                    }
                }
            }
        }
        anychanges |= changes;
    }


    /**
     * Return number of full pages free'd.
     */
    size_t fullcollectshell()
    {
        // The purpose of the 'shell' is to ensure all the registers
        // get put on the stack so they'll be scanned
        void *sp;
        size_t result;
        version (GNU)
        {
            __builtin_unwind_init();
            sp = & sp;
        }
        else version(LDC)
        {
            version(X86)
            {
                uint eax,ecx,edx,ebx,ebp,esi,edi;
                asm
                {
                    mov eax[EBP], EAX      ;
                    mov ecx[EBP], ECX      ;
                    mov edx[EBP], EDX      ;
                    mov ebx[EBP], EBX      ;
                    mov ebp[EBP], EBP      ;
                    mov esi[EBP], ESI      ;
                    mov edi[EBP], EDI      ;
                    mov  sp[EBP], ESP      ;
                }
            }
            else version (X86_64)
            {
                ulong rax,rbx,rcx,rdx,rbp,rsi,rdi,r8,r9,r10,r11,r12,r13,r14,r15;
                asm
                {
                    movq rax[RBP], RAX      ;
                    movq rbx[RBP], RBX      ;
                    movq rcx[RBP], RCX      ;
                    movq rdx[RBP], RDX      ;
                    movq rbp[RBP], RBP      ;
                    movq rsi[RBP], RSI      ;
                    movq rdi[RBP], RDI      ;
                    movq r8 [RBP], R8       ; 
                    movq r9 [RBP], R9       ; 
                    movq r10[RBP], R10      ;
                    movq r11[RBP], R11      ;
                    movq r12[RBP], R12      ;
                    movq r13[RBP], R13      ;
                    movq r14[RBP], R14      ;
                    movq r15[RBP], R15      ;
                    movq  sp[RBP], RSP      ;
                }
            }
            else
            {
                static assert( false, "Architecture not supported." );
            }
        }
        else
        {
        asm
        {
            pushad              ;
            mov sp[EBP],ESP     ;
        }
        }
        result = fullcollect(sp);
        version (GNU)
        {
            // nothing to do
        }
        else version(LDC)
        {
            // nothing to do
        }
        else
        {
        asm
        {
            popad               ;
        }
        }
        return result;
    }


    /**
     *
     */
    size_t fullcollect(void *stackTop)
    {
        size_t n;
        Pool*  pool;

        debug(COLLECT_PRINTF) printf("Gcx.fullcollect()\n");

        ulong t1=realtimeClock();
        
        thread_suspendAll();
        ++gcCounter;
        assert((gcCounter & cast(size_t)1) ==1,"unexpected gcCounter value");

        p_cache = null;
        size_cache = 0;

        anychanges = 0;
        for (n = 0; n < npools; n++)
        {
            pool = pooltable[n];
            pool.mark.zero();
            pool.scan.zero();
            pool.freebits.zero();
        }

        // Mark each free entry, so it doesn't get scanned
        for (n = 0; n < B_PAGE; n++)
        {
            for (List *list = bucket[n]; list; list = list.next)
            {
                pool = findPool(list);
                assert(pool);
                pool.freebits.set(cast(size_t)(cast(byte*)list - pool.baseAddr) / 16);
            }
        }

        for (n = 0; n < npools; n++)
        {
            pool = pooltable[n];
            pool.mark.copy(&pool.freebits);
        }

        rt_scanStaticData( &mark );

        version (MULTI_THREADED)
        {
            if (!noStack)
            {
                // Scan stacks and registers for each paused thread
                thread_scanAll( &mark, stackTop );
            }
        }
        else
        {
            if (!noStack)
            {
                // Scan stack for main thread
                debug(PRINTF) printf(" scan stack bot = %x, top = %x\n", stackTop, stackBottom);
                version (STACKGROWSDOWN)
                    mark(stackTop, stackBottom);
                else
                    mark(stackBottom, stackTop);
            }
        }

        // Scan roots[]
        debug(COLLECT_PRINTF) printf("scan roots[]\n");
        mark(roots, roots + nroots);

        // Scan ranges[]
        debug(COLLECT_PRINTF) printf("scan ranges[]\n");
        //log++;
        for (n = 0; n < nranges; n++)
        {
            debug(COLLECT_PRINTF) printf("\t%x .. %x\n", ranges[n].pbot, ranges[n].ptop);
            mark(ranges[n].pbot, ranges[n].ptop);
        }
        //log--;

        debug(COLLECT_PRINTF) printf("\tscan heap\n");
        while (anychanges)
        {
            anychanges = 0;
            for (n = 0; n < npools; n++)
            {
                uint *bbase;
                uint *b;
                uint *btop;

                pool = pooltable[n];

                bbase = pool.scan.base();
                btop = bbase + pool.scan.nwords;
                for (b = bbase; b < btop;)
                {   Bins   bin;
                    size_t pn;
                    size_t u;
                    size_t bitm;
                    byte*  o;

                    bitm = *b;
                    if (!bitm)
                    {   b++;
                        continue;
                    }
                    *b = 0;

                    o = pool.baseAddr + (b - bbase) * 32 * 16;
                    if (!(bitm & 0xFFFF))
                    {
                        bitm >>= 16;
                        o += 16 * 16;
                    }
                    for (; bitm; o += 16, bitm >>= 1)
                    {
                        if (!(bitm & 1))
                            continue;

                        pn = cast(size_t)(o - pool.baseAddr) / PAGESIZE;
                        bin = cast(Bins)pool.pagetable[pn];
                        if (bin < B_PAGE)
                        {
                            mark(o, o + binsize[bin]);
                        }
                        else if (bin == B_PAGE || bin == B_PAGEPLUS)
                        {
                            if (bin == B_PAGEPLUS)
                            {
                                while (pool.pagetable[pn - 1] != B_PAGE)
                                    pn--;
                            }
                            u = 1;
                            while (pn + u < pool.ncommitted && pool.pagetable[pn + u] == B_PAGEPLUS)
                                u++;
                            mark(o, o + u * PAGESIZE);
                        }
                    }
                }
            }
        }

        thread_resumeAll();
        
        auto t2=realtimeClock();
        totalMarkTime += cast(real)(t2-t1)/cast(real)realtimeClockFreq();

        // Free up everything not marked
        debug(COLLECT_PRINTF) printf("\tfree'ing\n");
        size_t freedpages = 0;
        size_t freed = 0;
        for (n = 0; n < npools; n++)
        {   size_t pn;
            size_t ncommitted;
            uint*  bbase;

            pool = pooltable[n];
            bbase = pool.mark.base();
            ncommitted = pool.ncommitted;
            for (pn = 0; pn < ncommitted; pn++, bbase += PAGESIZE / (32 * 16))
            {
                Bins bin = cast(Bins)pool.pagetable[pn];

                if (bin < B_PAGE)
                {   byte* p;
                    byte* ptop;
                    size_t biti;
                    size_t bitstride;
                    auto   size = binsize[bin];

                    p = pool.baseAddr + pn * PAGESIZE;
                    ptop = p + PAGESIZE;
                    biti = pn * (PAGESIZE/16);
                    bitstride = size / 16;

    version(none) // BUG: doesn't work because freebits() must also be cleared
    {
                    // If free'd entire page
                    if (bbase[0] == 0 && bbase[1] == 0 && bbase[2] == 0 && bbase[3] == 0 &&
                        bbase[4] == 0 && bbase[5] == 0 && bbase[6] == 0 && bbase[7] == 0)
                    {
                        for (; p < ptop; p += size, biti += bitstride)
                        {
                            if (pool.finals.nbits && pool.finals.testClear(biti))
                                rt_finalize(cast(List *)sentinel_add(p), false/*noStack > 0*/);
                            gcx.clrBits(pool, biti, BlkAttr.ALL_BITS);

                            List *list = cast(List *)p;
                            //debug(PRINTF) printf("\tcollecting %x\n", list);
                            log_free(sentinel_add(list));

                            debug (MEMSTOMP) cImports.memset(p, 0xF3, size);
                        }
                        pool.pagetable[pn] = B_FREE;
                        freed += PAGESIZE;
                        //debug(PRINTF) printf("freeing entire page %d\n", pn);
                        continue;
                    }
    }
                    for (; p < ptop; p += size, biti += bitstride)
                    {
                        if (!pool.mark.test(biti))
                        {
                            sentinel_Invariant(sentinel_add(p));

                            pool.freebits.set(biti);
                            if (pool.finals.nbits && pool.finals.testClear(biti))
                                rt_finalize(cast(List *)sentinel_add(p), false/*noStack > 0*/);
                            clrBits(pool, biti, BlkAttr.ALL_BITS);

                            List *list = cast(List *)p;
                            debug(PRINTF) printf("\tcollecting %x\n", list);
                            log_free(sentinel_add(list));

                            debug (MEMSTOMP) cImports.memset(p, 0xF3, size);

                            freed += size;
                        }
                    }
                }
                else if (bin == B_PAGE)
                {   size_t biti = pn * (PAGESIZE / 16);

                    if (!pool.mark.test(biti))
                    {   byte *p = pool.baseAddr + pn * PAGESIZE;

                        sentinel_Invariant(sentinel_add(p));
                        if (pool.finals.nbits && pool.finals.testClear(biti))
                            rt_finalize(sentinel_add(p), false/*noStack > 0*/);
                        clrBits(pool, biti, BlkAttr.ALL_BITS);

                        debug(COLLECT_PRINTF) printf("\tcollecting big %x\n", p);
                        log_free(sentinel_add(p));
                        pool.pagetable[pn] = B_FREE;
                        freedpages++;
                        debug (MEMSTOMP) cImports.memset(p, 0xF3, PAGESIZE);
                        while (pn + 1 < ncommitted && pool.pagetable[pn + 1] == B_PAGEPLUS)
                        {
                            pn++;
                            pool.pagetable[pn] = B_FREE;
                            freedpages++;

                            debug (MEMSTOMP)
                            {   p += PAGESIZE;
                                cImports.memset(p, 0xF3, PAGESIZE);
                            }
                        }
                    }
                }
            }
        }

        // Zero buckets
        bucket[] = null;

        // Free complete pages, rebuild free list
        debug(COLLECT_PRINTF) printf("\tfree complete pages\n");
        size_t recoveredpages = 0;
        for (n = 0; n < npools; n++)
        {   size_t pn;
            size_t ncommitted;

            pool = pooltable[n];
            ncommitted = pool.ncommitted;
            for (pn = 0; pn < ncommitted; pn++)
            {
                Bins   bin = cast(Bins)pool.pagetable[pn];
                size_t biti;
                size_t u;

                if (bin < B_PAGE)
                {
                    size_t size = binsize[bin];
                    size_t bitstride = size / 16;
                    size_t bitbase = pn * (PAGESIZE / 16);
                    size_t bittop = bitbase + (PAGESIZE / 16);
                    byte*  p;

                    biti = bitbase;
                    for (biti = bitbase; biti < bittop; biti += bitstride)
                    {   if (!pool.freebits.test(biti))
                            goto Lnotfree;
                    }
                    pool.pagetable[pn] = B_FREE;
                    recoveredpages++;
                    continue;

                 Lnotfree:
                    p = pool.baseAddr + pn * PAGESIZE;
                    for (u = 0; u < PAGESIZE; u += size)
                    {   biti = bitbase + u / 16;
                        if (pool.freebits.test(biti))
                        {   List *list;

                            list = cast(List *)(p + u);
                            if (list.next != bucket[bin])       // avoid unnecessary writes
                                list.next = bucket[bin];
                            bucket[bin] = list;
                        }
                    }
                }
            }
        }

        totalSweepTime  += cast(real)(realtimeClock()-t2)/cast(real)realtimeClockFreq();
        totalPagesFreed += cast(real)(freedpages + recoveredpages);

        debug(COLLECT_PRINTF) printf("recovered pages = %d\n", recoveredpages);
        debug(COLLECT_PRINTF) printf("\tfree'd %u bytes, %u pages from %u pools\n", freed, freedpages, npools);
        auto oldV=flagAdd!(size_t)(gcCounter,1);
        assert((oldV&cast(size_t)1) == 1,"unexpected gc counter value");

        return freedpages + recoveredpages;
    }


    /**
     *
     */
    uint getBits(Pool* pool, size_t biti)
    in
    {
        assert( pool );
    }
    body
    {
        uint bits;

        if (pool.finals.nbits &&
            pool.finals.test(biti))
            bits |= BlkAttr.FINALIZE;
        if (pool.noscan.test(biti))
            bits |= BlkAttr.NO_SCAN;
//        if (pool.nomove.nbits &&
//            pool.nomove.test(biti))
//            bits |= BlkAttr.NO_MOVE;
        return bits;
    }


    /**
     *
     */
    void setBits(Pool* pool, size_t biti, uint mask)
    in
    {
        assert( pool );
    }
    body
    {
        if (mask & BlkAttr.FINALIZE)
        {
            if (!pool.finals.nbits)
                pool.finals.alloc(pool.mark.nbits);
            pool.finals.set(biti);
        }
        if (mask & BlkAttr.NO_SCAN)
        {
            pool.noscan.set(biti);
        }
//        if (mask & BlkAttr.NO_MOVE)
//        {
//            if (!pool.nomove.nbits)
//                pool.nomove.alloc(pool.mark.nbits);
//            pool.nomove.set(biti);
//        }
    }


    /**
     *
     */
    void clrBits(Pool* pool, size_t biti, uint mask)
    in
    {
        assert( pool );
    }
    body
    {
        if (mask & BlkAttr.FINALIZE && pool.finals.nbits)
            pool.finals.clear(biti);
        if (mask & BlkAttr.NO_SCAN)
            pool.noscan.clear(biti);
//        if (mask & BlkAttr.NO_MOVE && pool.nomove.nbits)
//            pool.nomove.clear(biti);
    }

    /// calls all destructors, but does not collect
    void callAllDestructors(){
        Pool*  pool;

        for (size_t n = 0; n < npools; n++)
        {   size_t pn;
            size_t ncommitted;
            uint*  bbase;

            pool = pooltable[n];
            ncommitted = pool.ncommitted;
            for (pn = 0; pn < ncommitted; pn++, bbase += PAGESIZE / (32 * 16))
            {
                Bins bin = cast(Bins)pool.pagetable[pn];

                if (bin < B_PAGE)
                {   byte* p;
                    byte* ptop;
                    size_t biti;
                    size_t bitstride;
                    auto   size = binsize[bin];

                    p = pool.baseAddr + pn * PAGESIZE;
                    ptop = p + PAGESIZE;
                    biti = pn * (PAGESIZE/16);
                    bitstride = size / 16;

                    for (; p < ptop; p += size, biti += bitstride)
                    {
                        if (pool.finals.nbits && pool.finals.testClear(biti))
                            rt_finalize(cast(List *)sentinel_add(p), false/*noStack > 0*/);
                    }
                }
                else if (bin == B_PAGE) {
                    size_t biti = pn * (PAGESIZE / 16);

                    byte *p = pool.baseAddr + pn * PAGESIZE;

                    sentinel_Invariant(sentinel_add(p));
                    if (pool.finals.nbits && pool.finals.testClear(biti))
                        rt_finalize(sentinel_add(p), false/*noStack > 0*/);
                }
            }
        }
    }


    /***** Leak Detector ******/


    debug (LOGGING)
    {
        LogArray current;
        LogArray prev;


        void log_init()
        {
            //debug(PRINTF) printf("+log_init()\n");
            current.reserve(1000);
            prev.reserve(1000);
            //debug(PRINTF) printf("-log_init()\n");
        }


        void log_malloc(void *p, size_t size)
        {
            //debug(PRINTF) printf("+log_malloc(p = %x, size = %d)\n", p, size);
            Log log;

            log.p = p;
            log.size = size;
            log.line = GC.line;
            log.file = GC.file;
            log.parent = null;

            GC.line = 0;
            GC.file = null;

            current.push(log);
            //debug(PRINTF) printf("-log_malloc()\n");
        }


        void log_free(void *p)
        {
            //debug(PRINTF) printf("+log_free(%x)\n", p);
            size_t i;

            i = current.find(p);
            if (i == OPFAIL)
            {
                debug(PRINTF) printf("free'ing unallocated memory %x\n", p);
            }
            else
                current.remove(i);
            //debug(PRINTF) printf("-log_free()\n");
        }


        void log_collect()
        {
            //debug(PRINTF) printf("+log_collect()\n");
            // Print everything in current that is not in prev

            debug(PRINTF) printf("New pointers this cycle: --------------------------------\n");
            size_t used = 0;
            for (size_t i = 0; i < current.dim; i++)
            {
                size_t j;

                j = prev.find(current.data[i].p);
                if (j == OPFAIL)
                    current.data[i].print();
                else
                    used++;
            }

            debug(PRINTF) printf("All roots this cycle: --------------------------------\n");
            for (size_t i = 0; i < current.dim; i++)
            {
                void *p;
                size_t j;

                p = current.data[i].p;
                if (!findPool(current.data[i].parent))
                {
                    j = prev.find(current.data[i].p);
                    if (j == OPFAIL)
                        debug(PRINTF) printf("N");
                    else
                        debug(PRINTF) printf(" ");;
                    current.data[i].print();
                }
            }

            debug(PRINTF) printf("Used = %d-------------------------------------------------\n", used);
            prev.copy(&current);

            debug(PRINTF) printf("-log_collect()\n");
        }


        void log_parent(void *p, void *parent)
        {
            //debug(PRINTF) printf("+log_parent()\n");
            size_t i;

            i = current.find(p);
            if (i == OPFAIL)
            {
                debug(PRINTF) printf("parent'ing unallocated memory %x, parent = %x\n", p, parent);
                Pool *pool;
                pool = findPool(p);
                assert(pool);
                size_t offset = cast(size_t)(p - pool.baseAddr);
                size_t biti;
                size_t pn = offset / PAGESIZE;
                Bins bin = cast(Bins)pool.pagetable[pn];
                biti = (offset & notbinsize[bin]);
                debug(PRINTF) printf("\tbin = %d, offset = x%x, biti = x%x\n", bin, offset, biti);
            }
            else
            {
                current.data[i].parent = parent;
            }
            //debug(PRINTF) printf("-log_parent()\n");
        }

    }
    else
    {
        void log_init() { }
        void log_malloc(void *p, size_t size) { }
        void log_free(void *p) { }
        void log_collect() { }
        void log_parent(void *p, void *parent) { }
    }
}


/* ============================ Pool  =============================== */


struct Pool
{
    byte* baseAddr;
    byte* topAddr;
    GCBits mark;        // entries already scanned, or should not be scanned
    GCBits scan;        // entries that need to be scanned
    GCBits freebits;    // entries that are on the free list
    GCBits finals;      // entries that need finalizer run on them
    GCBits noscan;      // entries that should not be scanned

    size_t npages;
    size_t ncommitted;    // ncommitted <= npages
    ubyte* pagetable;


    void initialize(size_t npages)
    {
        size_t poolSize;

        //debug(PRINTF) printf("Pool::Pool(%u)\n", npages);
        poolSize = npages * PAGESIZE;
        assert(poolSize >= POOLSIZE);
        baseAddr = cast(byte *)os_mem_map(poolSize);

        // Some of the code depends on page alignment of memory pools
        assert((cast(size_t)baseAddr & (PAGESIZE - 1)) == 0);

        if (!baseAddr)
        {
            //debug(PRINTF) printf("GC fail: poolSize = x%x, errno = %d\n", poolSize, errno);
            //debug(PRINTF) printf("message = '%s'\n", sys_errlist[errno]);

            npages = 0;
            poolSize = 0;
        }
        //assert(baseAddr);
        topAddr = baseAddr + poolSize;

        mark.alloc(cast(size_t)poolSize / 16);
        scan.alloc(cast(size_t)poolSize / 16);
        freebits.alloc(cast(size_t)poolSize / 16);
        noscan.alloc(cast(size_t)poolSize / 16);

        pagetable = cast(ubyte*)cImports.malloc(npages);
        if (!pagetable)
            onOutOfMemoryError();
        cImports.memset(pagetable, B_UNCOMMITTED, npages);

        this.npages = npages;
        ncommitted = 0;
    }


    void Dtor()
    {
        if (baseAddr)
        {
            int result;

            if (ncommitted)
            {
                result = os_mem_decommit(baseAddr, 0, ncommitted * PAGESIZE);
                assert(result == 0);
                ncommitted = 0;
            }

            if (npages)
            {
                result = os_mem_unmap(baseAddr, npages * PAGESIZE);
                assert(result == 0);
                npages = 0;
            }

            baseAddr = null;
            topAddr = null;
        }
        if (pagetable)
            cImports.free(pagetable);

        mark.Dtor();
        scan.Dtor();
        freebits.Dtor();
        finals.Dtor();
        noscan.Dtor();
    }


    void Invariant() { }


    invariant
    {
        //mark.Invariant();
        //scan.Invariant();
        //freebits.Invariant();
        //finals.Invariant();
        //noscan.Invariant();

        if (baseAddr)
        {
            //if (baseAddr + npages * PAGESIZE != topAddr)
                //printf("baseAddr = %p, npages = %d, topAddr = %p\n", baseAddr, npages, topAddr);
            assert(baseAddr + npages * PAGESIZE == topAddr);
            assert(ncommitted <= npages);
        }

        for (size_t i = 0; i < npages; i++)
        {   Bins bin = cast(Bins)pagetable[i];

            assert(bin < B_MAX);
        }
    }


    /**
     * Allocate n pages from Pool.
     * Returns OPFAIL on failure.
     */
    size_t allocPages(size_t n)
    {
        size_t i;
        size_t n2;

        //debug(PRINTF) printf("Pool::allocPages(n = %d)\n", n);
        n2 = n;
        for (i = 0; i < ncommitted; i++)
        {
            if (pagetable[i] == B_FREE)
            {
                if (--n2 == 0)
                {   //debug(PRINTF) printf("\texisting pn = %d\n", i - n + 1);
                    return i - n + 1;
                }
            }
            else
                n2 = n;
        }
        return extendPages(n);
    }

    /**
     * Extend Pool by n pages.
     * Returns OPFAIL on failure.
     */
    size_t extendPages(size_t n)
    {
        //debug(PRINTF) printf("Pool::extendPages(n = %d)\n", n);
        if (ncommitted + n <= npages)
        {
            size_t tocommit;

            tocommit = (n + (COMMITSIZE/PAGESIZE) - 1) & ~(COMMITSIZE/PAGESIZE - 1);
            if (ncommitted + tocommit > npages)
                tocommit = npages - ncommitted;
            //debug(PRINTF) printf("\tlooking to commit %d more pages\n", tocommit);
            //fflush(stdout);
            if (os_mem_commit(baseAddr, ncommitted * PAGESIZE, tocommit * PAGESIZE) == 0)
            {
                cImports.memset(pagetable + ncommitted, B_FREE, tocommit);
                auto i = ncommitted;
                ncommitted += tocommit;

                while (i && pagetable[i - 1] == B_FREE)
                    i--;

                return i;
            }
            //debug(PRINTF) printf("\tfailed to commit %d pages\n", tocommit);
        }

        return OPFAIL;
    }


    /**
     * Free npages pages starting with pagenum.
     */
    void freePages(size_t pagenum, size_t npages)
    {
        cImports.memset(&pagetable[pagenum], B_FREE, npages);
    }


    /**
     * Used for sorting pooltable[]
     */
    int opCmp(Pool *p2)
    {
        if (baseAddr < p2.baseAddr)
            return -1;
        else
        return cast(int)(baseAddr > p2.baseAddr);
    }
}


/* ============================ SENTINEL =============================== */


version (SENTINEL)
{
    const size_t SENTINEL_PRE = cast(size_t) 0xF4F4F4F4F4F4F4F4UL; // 32 or 64 bits
    const ubyte SENTINEL_POST = 0xF5;           // 8 bits
    const uint SENTINEL_EXTRA = 2 * size_t.sizeof + 1;


    size_t* sentinel_size(void *p)  { return &(cast(size_t *)p)[-2]; }
    size_t* sentinel_pre(void *p)   { return &(cast(size_t *)p)[-1]; }
    ubyte* sentinel_post(void *p) { return &(cast(ubyte *)p)[*sentinel_size(p)]; }


    void sentinel_init(void *p, size_t size)
    {
        *sentinel_size(p) = size;
        *sentinel_pre(p) = SENTINEL_PRE;
        *sentinel_post(p) = SENTINEL_POST;
    }


    void sentinel_Invariant(void *p)
    {
        assert(*sentinel_pre(p) == SENTINEL_PRE);
        assert(*sentinel_post(p) == SENTINEL_POST);
    }


    void *sentinel_add(void *p)
    {
        return p + 2 * size_t.sizeof;
    }


    void *sentinel_sub(void *p)
    {
        return p - 2 * size_t.sizeof;
    }
}
else
{
    const uint SENTINEL_EXTRA = 0;


    void sentinel_init(void *p, size_t size)
    {
    }


    void sentinel_Invariant(void *p)
    {
    }


    void *sentinel_add(void *p)
    {
        return p;
    }


    void *sentinel_sub(void *p)
    {
        return p;
    }
}

