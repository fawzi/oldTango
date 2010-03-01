module gcc.configunix;
private import gcc.config;

alias gcc.config.Coff_t off_t;
alias gcc.config.tm tm;

private alias void FILE;
private alias void DIR;

extern(C) {

const int NFDBITS = 32;
const int __FD_SET_SIZEOF = 128;
const int FD_SETSIZE = 1024;
alias ushort mode_t;
alias int pid_t;
alias uint uid_t;
alias uint gid_t;
alias int ssize_t;

enum {
  DT_UNKNOWN = 0,
  DT_FIFO = 1,
  DT_CHR = 2,
  DT_DIR = 4,
  DT_BLK = 6,
  DT_REG = 8,
  DT_LNK = 10,
  DT_SOCK = 12,
  DT_WHT = 14,
}
enum {
  O_RDONLY = 0,
  O_WRONLY = 1,
  O_RDWR = 2,
  O_NONBLOCK = 4,
  O_CREAT = 512,
  O_EXCL = 2048,
  O_TRUNC = 1024,
  O_APPEND = 8,
  O_NOFOLLOW = 256,
}

enum {
  F_DUPFD = 0,
  F_GETFD = 1,
  F_SETFD = 2,
  F_GETFL = 3,
  F_SETFL = 4,
}
enum {
  F_OK = 0,
  R_OK = 4,
  W_OK = 2,
  X_OK = 1,
}


alias int time_t;
struct timespec {
    int tv_sec;
    int tv_nsec;
}

static assert(timespec.tv_sec.offsetof == 0);
static assert(timespec.tv_nsec.offsetof == 4);
static assert(timespec.sizeof == 8);


struct timeval {
    int tv_sec;
    int tv_usec;
}

static assert(timeval.tv_sec.offsetof == 0);
static assert(timeval.tv_usec.offsetof == 4);
static assert(timeval.sizeof == 8);


struct timezone {
    int tz_minuteswest;
    int tz_dsttime;
}

static assert(timezone.tz_minuteswest.offsetof == 0);
static assert(timezone.tz_dsttime.offsetof == 4);
static assert(timezone.sizeof == 8);


struct utimbuf {
    int actime;
    int modtime;
}

static assert(utimbuf.actime.offsetof == 0);
static assert(utimbuf.modtime.offsetof == 4);
static assert(utimbuf.sizeof == 8);


enum {
  S_IFIFO = 4096,
  S_IFCHR = 8192,
  S_IFDIR = 16384,
  S_IFBLK = 24576,
  S_IFREG = 32768,
  S_IFLNK = 40960,
  S_IFSOCK = 49152,
  S_IFMT = 61440,
  S_IRUSR = 256,
  S_IWUSR = 128,
  S_IXUSR = 64,
  S_IRGRP = 32,
  S_IWGRP = 16,
  S_IXGRP = 8,
  S_IROTH = 4,
  S_IWOTH = 2,
  S_IXOTH = 1,
  S_IRWXG = 56,
  S_IRWXO = 7,
}

struct struct_stat {
    int st_dev;
    uint st_ino;
    ushort st_mode;
    ushort st_nlink;
    uint st_uid;
    uint st_gid;
    int st_rdev;
    int st_atime;
   ubyte[4] ___pad1;
    int st_mtime;
   ubyte[4] ___pad2;
    int st_ctime;
   ubyte[4] ___pad3;
    long st_size;
    long st_blocks;
    int st_blksize;
   ubyte[28] ___pad4;
}

static assert(struct_stat.st_dev.offsetof == 0);
static assert(struct_stat.st_ino.offsetof == 4);
static assert(struct_stat.st_mode.offsetof == 8);
static assert(struct_stat.st_nlink.offsetof == 10);
static assert(struct_stat.st_uid.offsetof == 12);
static assert(struct_stat.st_gid.offsetof == 16);
static assert(struct_stat.st_rdev.offsetof == 20);
static assert(struct_stat.st_atime.offsetof == 24);
static assert(struct_stat.st_mtime.offsetof == 32);
static assert(struct_stat.st_ctime.offsetof == 40);
static assert(struct_stat.st_size.offsetof == 48);
static assert(struct_stat.st_blocks.offsetof == 56);
static assert(struct_stat.st_blksize.offsetof == 64);
static assert(struct_stat.sizeof == 96);


// from <sys/signal.h>
enum {
  SIGHUP = 1,
  SIGINT = 2,
  SIGQUIT = 3,
  SIGILL = 4,
  SIGABRT = 6,
  SIGIOT = 6,
  SIGBUS = 10,
  SIGFPE = 8,
  SIGKILL = 9,
  SIGUSR1 = 30,
  SIGSEGV = 11,
  SIGUSR2 = 31,
  SIGPIPE = 13,
  SIGALRM = 14,
  SIGTERM = 15,
  SIGSTKFLT = 0,
  SIGCHLD = 20,
  SIGCONT = 19,
  SIGSTOP = 17,
  SIGTSTP = 18,
  SIGTTIN = 21,
  SIGTTOU = 22,
  SIGIO = 23,
  SIGPOLL = 0,
  SIGPROF = 27,
  SIGWINCH = 28,
  SIGURG = 16,
  SIGXCPU = 24,
  SIGXFSZ = 25,
  SIGVTALRM = 26,
  SIGTRAP = 5,
  SIGPWR = 0,
  SIGSYS = 12,
}
enum {
  SA_NOCLDSTOP = 8,
  SA_NOCLDWAIT = 32,
  SA_SIGINFO = 64,
  SA_ONSTACK = 1,
  SA_RESTART = 2,
  SA_NODEFER = 16,
  SA_RESETHAND = 4,
}

struct sigset_t { ubyte[4] opaque; }
alias  void function(int) __sighandler_t;
const __sighandler_t SIG_DFL = cast(__sighandler_t) 0;
const __sighandler_t SIG_IGN = cast(__sighandler_t) 1;
const __sighandler_t SIG_ERR = cast(__sighandler_t) -1;

/* siginfo_t is not finished... see gen_unix.c */
struct siginfo_t {
    int si_signo;
    int si_errno;
    int si_code;
   ubyte[52] ___pad1;
}

static assert(siginfo_t.si_signo.offsetof == 0);
static assert(siginfo_t.si_errno.offsetof == 4);
static assert(siginfo_t.si_code.offsetof == 8);
static assert(siginfo_t.sizeof == 64);


struct sigaction_t {
    union {
        void function(int) sa_handler;
        void function(int, siginfo_t *, void *) sa_sigaction;
    }
    sigset_t sa_mask;
    int sa_flags;
}

static assert(sigaction_t.sa_flags.offsetof == 8);
static assert(sigaction_t.sizeof == 12);


// from <sys/mman.h>
extern(D) const void * MAP_FAILED = cast(void *) -1;
enum { PROT_NONE = 0, PROT_READ = 1, PROT_WRITE = 2, PROT_EXEC = 4 }
enum { MAP_SHARED = 0x1, MAP_PRIVATE = 0x2, MAP_ANON = 0x1000,       MAP_ANONYMOUS = 0x1000,  MAP_FIXED = 16,
  MAP_FILE = 0,
  MAP_NORESERVE = 64,
}

enum {
  MS_ASYNC = 1,
  MS_INVALIDATE = 2,
  MS_SYNC = 16,
}

enum {
  MCL_CURRENT = 1,
  MCL_FUTURE = 2,
}

enum {
  MADV_NORMAL = 0,
  MADV_RANDOM = 1,
  MADV_SEQUENTIAL = 2,
  MADV_WILLNEED = 3,
  MADV_DONTNEED = 4,
}


enum {
  EPERM = 1,
  ENOENT = 2,
  ESRCH = 3,
  EINTR = 4,
  ENXIO = 6,
  E2BIG = 7,
  ENOEXEC = 8,
  EBADF = 9,
  ECHILD = 10,
  EINPROGRESS = 36,
  EWOULDBLOCK = 35,
  EAGAIN = 35,
}

struct sem_t { ubyte[4] opaque; }
alias uint pthread_t;
struct pthread_attr_t { ubyte[40] opaque; }
struct pthread_cond_t { ubyte[28] opaque; }
struct pthread_condattr_t { ubyte[8] opaque; }
struct pthread_mutex_t { ubyte[44] opaque; }
struct pthread_mutexattr_t { ubyte[12] opaque; }
struct sched_param {
    int sched_priority;
   ubyte[4] ___pad1;
}

static assert(sched_param.sched_priority.offsetof == 0);
static assert(sched_param.sizeof == 8);


struct pthread_barrier_t;
struct pthread_barrierattr_t;
struct pthread_rwlock_t { ubyte[128] opaque; }
struct pthread_rwlockattr_t { ubyte[16] opaque; }
struct pthread_spinlock_t;


enum : int {
  PTHREAD_CANCEL_ENABLE = 1,
  PTHREAD_CANCEL_DISABLE = 0,
  PTHREAD_CANCEL_DEFERRED = 2,
  PTHREAD_CANCEL_ASYNCHRONOUS = 0,
}

alias Culong_t clockid_t;
alias uint socklen_t;
// from <sys/socket.h>
const int SOL_SOCKET = 65535

;enum : int {
  SO_DEBUG = 1,
  SO_ACCEPTCONN = 2,
  SO_REUSEADDR = 4,
  SO_KEEPALIVE = 8,
  SO_DONTROUTE = 16,
  SO_BROADCAST = 32,
  SO_USELOOPBACK = 64,
  SO_LINGER = 128,
  SO_OOBINLINE = 256,
  SO_REUSEPORT = 512,
  SO_TIMESTAMP = 1024,
  SO_SNDBUF = 4097,
  SO_RCVBUF = 4098,
  SO_SNDLOWAT = 4099,
  SO_RCVLOWAT = 4100,
  SO_SNDTIMEO = 4101,
  SO_RCVTIMEO = 4102,
  SO_ERROR = 4103,
  SO_TYPE = 4104,
}

struct linger {
    int l_onoff;
    int l_linger;
}

static assert(linger.l_onoff.offsetof == 0);
static assert(linger.l_linger.offsetof == 4);
static assert(linger.sizeof == 8);



enum : int {
  SOCK_STREAM = 1,
  SOCK_DGRAM = 2,
  SOCK_RAW = 3,
  SOCK_RDM = 4,
  SOCK_SEQPACKET = 5,
}

enum : int {
  MSG_OOB = 1,
  MSG_PEEK = 2,
  MSG_DONTROUTE = 4,
}

enum : int {
  AF_UNSPEC = 0,
  AF_UNIX = 1,
  AF_INET = 2,
  AF_IPX = 23,
  AF_APPLETALK = 16,
  AF_INET6 = 30,
  AF_BOGOSITY = 0,
}

enum : int {
  PF_UNSPEC = 0,
  PF_UNIX = 1,
  PF_INET = 2,
  PF_IPX = 23,
  PF_APPLETALK = 16,
}

// from <netinet/in.h>
enum : int {
  IPPROTO_IP = 0,
  IPPROTO_ICMP = 1,
  IPPROTO_IGMP = 2,
  IPPROTO_GGP = 3,
  IPPROTO_TCP = 6,
  IPPROTO_PUP = 12,
  IPPROTO_UDP = 17,
  IPPROTO_IDP = 22,
  IPPROTO_IPV6 = 41,
}

enum : uint {
  INADDR_ANY = 0x0,
  INADDR_LOOPBACK = 0x7f000001,
  INADDR_BROADCAST = 0xffffffff,
  INADDR_NONE = 0xffffffff,
  ADDR_ANY = 0,
}
// from <netinet/tcp.h>
enum : int {
  TCP_NODELAY = 1,
}

// from <netinet6/in6.h>
enum : int {
  IPV6_UNICAST_HOPS = 4,
  IPV6_MULTICAST_IF = 9,
  IPV6_MULTICAST_HOPS = 10,
  IPV6_MULTICAST_LOOP = 11,
  IPV6_JOIN_GROUP = 12,
  IPV6_LEAVE_GROUP = 13,
}

// from <netdb.h>
struct protoent {
    char * p_name;
    char ** p_aliases;
    int p_proto;
}

static assert(protoent.p_proto.offsetof == 8);
static assert(protoent.sizeof == 12);


struct servent {
    char * s_name;
    char ** s_aliases;
    int s_port;
    char * s_proto;
}

static assert(servent.s_port.offsetof == 8);
static assert(servent.sizeof == 16);


struct hostent {
    char * h_name;
    char ** h_aliases;
    int h_addrtype;
    int h_length;
    char ** h_addr_list;
char* h_addr()
{
       return h_addr_list[0];
}
}

static assert(hostent.h_addrtype.offsetof == 8);
static assert(hostent.h_length.offsetof == 12);
static assert(hostent.sizeof == 20);


struct addrinfo { }
struct passwd {
    char * pw_name;
    char * pw_passwd;
    uint pw_uid;
    uint pw_gid;
   ubyte[8] ___pad1;
    char * pw_gecos;
    char * pw_dir;
    char * pw_shell;
   ubyte[4] ___pad2;
}

static assert(passwd.pw_uid.offsetof == 8);
static assert(passwd.pw_gid.offsetof == 12);
static assert(passwd.sizeof == 40);


}

extern (C)
{
    int open(char*, int, ...);
    ssize_t read(int, void*, size_t);
    ssize_t write(int, void*, size_t);
    int close(int);
    off_t lseek(int, off_t, int);
    int access(char *path, int mode);
    int utime(char *path, utimbuf *buf);
    int fstat(int, struct_stat*);
    int stat(char*, struct_stat*);
    int lstat(char *, struct_stat *);
    int chmod(char *, mode_t);
    int chdir(char*);
    int mkdir(char*, mode_t);
    int rmdir(char*);
    char* getcwd(char*, size_t);

    pid_t fork();
    int dup(int);
    int dup2(int, int);
    int pipe(int[2]);
    pid_t wait(int*);
    pid_t waitpid(pid_t, int*, int);
    int kill(pid_t, int);

    int gettimeofday(timeval*, void*);
    time_t time(time_t*);
    tm *localtime(time_t*);

    int sem_init (sem_t *, int, uint);
    int sem_destroy (sem_t *);
    sem_t * sem_open (char *, int, ...);
    int sem_close(sem_t *);
    int sem_wait(sem_t*);
    int sem_post(sem_t*);
    int sem_trywait(sem_t*);
    int sem_getvalue(sem_t*, int*);

    int sigemptyset(sigset_t*);
    int sigfillset(sigset_t*);
    int sigdelset(sigset_t*, int);
    int sigismember(sigset_t *set, int);
    int sigaction(int, sigaction_t*, sigaction_t*);
    int sigsuspend(sigset_t*);

    Clong_t sysconf(int name);

    // version ( Unix_Pthread )...
    int pthread_attr_init(pthread_attr_t *);
    int pthread_attr_destroy(pthread_attr_t *);
    int pthread_attr_setdetachstate(pthread_attr_t *, int);
    int pthread_attr_getdetachstate(pthread_attr_t *, int *);
    int pthread_attr_setguardsize(pthread_attr_t*, size_t);
    int pthread_attr_getguardsize(pthread_attr_t*, size_t *);
    int pthread_attr_setinheritsched(pthread_attr_t *, int);
    int pthread_attr_getinheritsched(pthread_attr_t *, int *);
    int pthread_attr_setschedparam(pthread_attr_t *, sched_param *);
    int pthread_attr_getschedparam(pthread_attr_t *, sched_param *);
    int pthread_attr_setschedpolicy(pthread_attr_t *, int);
    int pthread_attr_getschedpolicy(pthread_attr_t *, int*);
    int pthread_attr_setscope(pthread_attr_t *, int);
    int pthread_attr_getscope(pthread_attr_t *, int*);
    int pthread_attr_setstack(pthread_attr_t *, void*, size_t);
    int pthread_attr_getstack(pthread_attr_t *, void**, size_t *);
    int pthread_attr_setstackaddr(pthread_attr_t *, void *);
    int pthread_attr_getstackaddr(pthread_attr_t *, void **);
    int pthread_attr_setstacksize(pthread_attr_t *, size_t);
    int pthread_attr_getstacksize(pthread_attr_t *, size_t *);

    int pthread_create(pthread_t*, pthread_attr_t*, void* (*)(void*), void*);
    int pthread_join(pthread_t, void**);
    int pthread_kill(pthread_t, int);
    pthread_t pthread_self();
    int pthread_equal(pthread_t, pthread_t);
    int pthread_suspend_np(pthread_t);
    int pthread_continue_np(pthread_t);
    int pthread_cancel(pthread_t);
    int pthread_setcancelstate(int state, int *oldstate);
    int pthread_setcanceltype(int type, int *oldtype);
    void pthread_testcancel();
    int pthread_detach(pthread_t);
    void pthread_exit(void*);
    int pthread_getattr_np(pthread_t, pthread_attr_t*);
    int pthread_getconcurrency();
    int pthread_getcpuclockid(pthread_t, clockid_t*);

    int pthread_cond_init(pthread_cond_t *, pthread_condattr_t *);
    int pthread_cond_destroy(pthread_cond_t *);
    int pthread_cond_signal(pthread_cond_t *);
    int pthread_cond_broadcast(pthread_cond_t *);
    int pthread_cond_wait(pthread_cond_t *, pthread_mutex_t *);
    int pthread_cond_timedwait(pthread_cond_t *, pthread_mutex_t *, timespec *);
    int pthread_condattr_init(pthread_condattr_t *);
    int pthread_condattr_destroy(pthread_condattr_t *);
    int pthread_condattr_getpshared(pthread_condattr_t *, int *);
    int pthread_condattr_setpshared(pthread_condattr_t *, int);

    int pthread_mutex_init(pthread_mutex_t *, pthread_mutexattr_t *);
    int pthread_mutex_lock(pthread_mutex_t *);
    int pthread_mutex_trylock(pthread_mutex_t *);
    int pthread_mutex_unlock(pthread_mutex_t *);
    int pthread_mutex_destroy(pthread_mutex_t *);
    int pthread_mutexattr_init(pthread_mutexattr_t *);
    int pthread_mutexattr_destroy(pthread_mutexattr_t *);
    int pthread_mutexattr_getpshared(pthread_mutexattr_t *, int *);
    int pthread_mutexattr_setpshared(pthread_mutexattr_t *, int);

    int pthread_barrierattr_init(pthread_barrierattr_t*);
    int pthread_barrierattr_getpshared(pthread_barrierattr_t*, int*);
    int pthread_barrierattr_destroy(pthread_barrierattr_t*);
    int pthread_barrierattr_setpshared(pthread_barrierattr_t*, int);

    int pthread_barrier_init(pthread_barrier_t*, pthread_barrierattr_t*, uint);
    int pthread_barrier_destroy(pthread_barrier_t*);
    int pthread_barrier_wait(pthread_barrier_t*);

    // version ( Unix_Sched )
    void sched_yield();

    // from <sys/mman.h>
    void* mmap(void* addr, size_t len, int prot, int flags, int fd, off_t offset);
    int munmap(void* addr, size_t len);
    int msync(void* start, size_t length, int flags);
    int madvise(void*, size_t, int);
    int mlock(void*, size_t);
    int munlock(void*, size_t);
    int mlockall(int);
    int munlockall();
    void* mremap(void*, size_t, size_t, Culong_t); // Linux specific
    int mincore(void*, size_t, ubyte*);
    int remap_file_pages(void*, size_t, int, ssize_t, int); // Linux specific
    int shm_open(char*, int, mode_t);
    int shm_unlink(char*);

    // from <fcntl.h>
    int fcntl(int fd, int cmd, ...);

    int select(int n, fd_set *, fd_set *, fd_set *, timeval *);

    // could probably rewrite fd_set stuff in D, but for now...
    struct fd_set {
        ubyte opaque[__FD_SET_SIZEOF];
    }
    private void _d_gnu_fd_set(int n, fd_set * p);
    private void _d_gnu_fd_clr(int n, fd_set * p);
    private int  _d_gnu_fd_isset(int n, fd_set * p);
    private void _d_gnu_fd_copy(fd_set * f, fd_set * t);
    private void _d_gnu_fd_zero(fd_set * p);
    // maybe these should go away in favor of fd_set methods
    version (none)
    {
        void FD_SET(int n, inout fd_set p) { return _d_gnu_fd_set(n, & p); }
        void FD_CLR(int n, inout fd_set p) { return _d_gnu_fd_clr(n, & p); }
        int FD_ISSET(int n, inout fd_set p) { return _d_gnu_fd_isset(n, & p); }
        void FD_COPY(inout fd_set f, inout fd_set t) { return _d_gnu_fd_copy(& f, & t); }
        void FD_ZERO(inout fd_set p) { return _d_gnu_fd_zero(& p); }
    }
    void FD_SET(int n,  fd_set * p) { return _d_gnu_fd_set(n, p); }
    void FD_CLR(int n,  fd_set * p) { return _d_gnu_fd_clr(n, p); }
    int FD_ISSET(int n, fd_set * p) { return _d_gnu_fd_isset(n, p); }
    void FD_COPY(fd_set * f, inout fd_set * t) { return _d_gnu_fd_copy(f, t); }
    void FD_ZERO(fd_set * p) { return _d_gnu_fd_zero(p); }

    // from <pwd.h>
    passwd *getpwnam(char *name);
    passwd *getpwuid(uid_t uid);
    int getpwnam_r(char *name, passwd *pwbuf, char *buf, size_t buflen, passwd **pwbufp);
    int getpwuid_r(uid_t uid, passwd *pwbuf, char *buf, size_t buflen, passwd **pwbufp);

    // The following is mostly based on std/c/linux/socket.d

    // There doesn't seem to be a need to configure these structs beyond
    // the BsdSockets_salen bit.
    struct in_addr
    {
        uint s_addr;
    }

    struct sockaddr
    {
        version(GNU_BsdSockets_salen) {
            ubyte  sa_len;
            ubyte  sa_family;
        } else {
            ushort sa_family;
        }
        ubyte[14] sa_data;
    }

    struct sockaddr_in
    {
        version( BsdSockets_salen ) {
            ubyte sin_len = sockaddr_in.sizeof;
            ubyte sin_family = AF_INET;
        } else {
            ushort sin_family = AF_INET;
        }
        ushort sin_port;
        in_addr sin_addr;
        ubyte[8] sin_zero;
    }

    // std/socket.d
    enum: int
    {
        SD_RECEIVE =  0,
        SD_SEND =     1,
        SD_BOTH =     2,
    }

    int socket(int af, int type, int protocol);
    int bind(int s, sockaddr* name, int namelen);
    int connect(int s, sockaddr* name, int namelen);
    int listen(int s, int backlog);
    int accept(int s, sockaddr* addr, int* addrlen);
    int shutdown(int s, int how);
    int getpeername(int s, sockaddr* name, int* namelen);
    int getsockname(int s, sockaddr* name, int* namelen);
    ssize_t send(int s, void* buf, size_t len, int flags);
    ssize_t sendto(int s, void* buf, size_t len, int flags, sockaddr* to, int tolen);
    ssize_t recv(int s, void* buf, size_t len, int flags);
    ssize_t recvfrom(int s, void* buf, size_t len, int flags, sockaddr* from, int* fromlen);
    int getsockopt(int s, int level, int optname, void* optval, int* optlen);
    int setsockopt(int s, int level, int optname, void* optval, int optlen);
    uint inet_addr(char* cp);
    char* inet_ntoa(in_addr ina);
    hostent* gethostbyname(char* name);
    int gethostbyname_r(char* name, hostent* ret, void* buf, size_t buflen, hostent** result, int* h_errnop);
    int gethostbyname2_r(char* name, int af, hostent* ret, void* buf, size_t buflen, hostent** result, int* h_errnop);
    hostent* gethostbyaddr(void* addr, int len, int type);
    protoent* getprotobyname(char* name);
    protoent* getprotobynumber(int number);
    servent* getservbyname(char* name, char* proto);
    servent* getservbyport(int port, char* proto);
    int gethostname(char* name, int namelen);
    int getaddrinfo(char* nodename, char* servname, addrinfo* hints, addrinfo** res);
    void freeaddrinfo(addrinfo* ai);
    int getnameinfo(sockaddr* sa, socklen_t salen, char* node, socklen_t nodelen, char* service, socklen_t servicelen, int flags);

    private import tango.stdc.stdint;

    version(BigEndian)
    {
            uint16_t htons(uint16_t x)
            {
                    return x;
            }


            uint32_t htonl(uint32_t x)
            {
                    return x;
            }
    }
    else version(LittleEndian)
    {
            private import std.intrinsic;


            uint16_t htons(uint16_t x)
            {
                    return (x >> 8) | (x << 8);
            }


            uint32_t htonl(uint32_t x)
            {
                    return bswap(x);
            }
    }
    else
    {
            static assert(0);
    }

    alias htons ntohs;
    alias htonl ntohl;

    // from <time.h>
    char* asctime_r(tm* t, char* buf);
    char* ctime_r(time_t* timep, char* buf);
    tm* gmtime_r(time_t* timep, tm* result);
    tm* localtime_r(time_t* timep, tm* result);

    // misc.
    uint alarm(uint);
    char* basename(char*);
    //wint_t btowc(int);
    int chown(char*, uid_t, gid_t);
    int chroot(char*);
    size_t confstr(int, char*, size_t);
    int creat(char*, mode_t);
    char* ctermid(char*);
    char* dirname(char*);
    int fattach(int, char*);
    int fchmod(int, mode_t);
    int fdatasync(int);
    int ffs(int);
    int fmtmsg(int, char*, int, char*, char*, char*);
    int fpathconf(int, int);

    extern char** environ;

}
