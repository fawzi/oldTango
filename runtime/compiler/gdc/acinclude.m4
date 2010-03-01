dnl Unix-specific configuration
AC_DEFUN([DPHOBOS_CONFIGURE_UNIX],[

AC_CHECK_HEADERS(pthread.h,:,
  [AC_MSG_ERROR([can't find pthread.h. Pthreads is the only supported thread library.])])

AC_MSG_CHECKING([for recursive mutex name])
AC_TRY_COMPILE([#include <pthread.h>],[
pthread_mutexattr_t attr;
pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);],
  [AC_DEFINE(HAVE_PTHREAD_MUTEX_RECURSIVE,1,[Determines how to declared recursive mutexes])
   AC_MSG_RESULT([PTHREAD_MUTEX_RECURSIVE])],
  [AC_MSG_RESULT([PTHREAD_MUTEX_RECURSIVE_NP])])

AC_CHECK_TYPES([pthread_barrier_t, pthread_barrierattr_t,
		pthread_rwlock_t, pthread_rwlockattr_t,
		pthread_spinlock_t],,,[#include <pthread.h>])

AC_CHECK_TYPES([clockid_t],,,[#include <pthread.h>])

dnl -pthread doesn't work because, by putting it in specs, it is passed
dnl to the linker instead of being interpreted by the driver...
dnl -lc_r ins't quite right because there is also a -lc_r_p
# -pthread

if test -z "$d_thread_lib"; then
    AC_MSG_CHECKING([for thread library linker argument])
    d_thread_lib=error
    for thrd_lib in "" -lc_r -lpthread -ldce; do
	d_savelibs=$LIBS
	LIBS="$LIBS $thrd_lib"

	AC_TRY_LINK([#include <pthread.h>],[
	pthread_create(0,0,0,0);],
	  [d_thread_lib=$thrd_lib],
	  :)

	LIBS=$d_savelibs

	if test "$d_thread_lib" != "error"; then
	    break
	fi
    done
    case "$d_thread_lib" in
      error) AC_MSG_ERROR([Not found!  You may need to use --enable-thread-lib]) ;;
      -*) AC_MSG_RESULT([$d_thread_lib]) ;;
      *) AC_MSG_RESULT([none needed]) ;;
    esac
fi
LIBS="$LIBS $d_thread_lib"

dnl BSD socket configuration

AC_CHECK_TYPES([socklen_t, siginfo_t],[],[],[
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>])

AC_MSG_CHECKING([for sa_len])
AC_TRY_COMPILE([
#include <sys/types.h>
#include <sys/socket.h>],[
struct sockaddr s; s.sa_len = 0;],
  [AC_MSG_RESULT([yes])
   DCFG_SA_LEN=GNU_BsdSockets_salen],
  [AC_MSG_RESULT([no])
   DCFG_SA_LEN=""])

if test -n "$DCFG_SA_LEN"; then
    AC_MSG_CHECKING([size of sa_len])
    AC_TRY_COMPILE([
#include <sys/types.h>
#include <sys/socket.h>],[
    struct sockaddr s;
    struct Test {
     int x: sizeof(s.sa_len)==1;
    };],
      [AC_MSG_RESULT([one byte])],
      [AC_MSG_RESULT([not one byte])
       AC_MSG_ERROR([Can not handle layout of sockaddr.  Please report this so your system can be supported.])])
else
    AC_MSG_CHECKING([size of sa_family])
    AC_TRY_COMPILE([
#include <sys/types.h>
#include <sys/socket.h>],[
    struct sockaddr s;
    struct Test {
     int x: sizeof(s.sa_family)==2;
    };],
      [AC_MSG_RESULT([two bytes])],
      [AC_MSG_RESULT([not two bytes])
       AC_MSG_ERROR([Can not handle layout of sockaddr.  Please report this so your system can be supported.])])
fi

AC_SEARCH_LIBS(sem_init, pthread rt posix4)

DCFG_PTHREAD_SUSPEND=
AC_SUBST(DCFG_PTHREAD_SUSPEND)

if true; then
    AC_CHECK_HEADERS(semaphore.h)
    AC_CHECK_FUNC(sem_init)
    AC_CHECK_FUNC(semaphore_create)
    AC_CHECK_FUNC(pthread_cond_wait)

    if test -z "$d_sem_impl"; then
	# Probably need to test what actually works.  sem_init is defined
	# on AIX and Darwin but does not actually work.
	# For now, test for Mach semaphores first so it overrides Posix.  AIX
	# is a special case.
	if test "$ac_cv_func_semaphore_create" = "yes"; then
	    d_sem_impl="mach"
	elif test "$ac_cv_func_sem_init" = "yes" && \
		test "$ac_cv_header_semaphore_h" = "yes" && \
		test -z "$d_is_aix"; then
	    d_sem_impl="posix"
	elif test "$ac_cv_func_pthread_cond_wait" = "yes"; then
	    d_sem_impl="pthreads"
	fi
    fi

    dnl TODO: change this to using pthreads? if so, define usepthreads
    dnl and configure semaphore

    case "$d_sem_impl" in
      posix) DCFG_SEMAPHORE_IMPL="GNU_Semaphore_POSIX" ;;
      mach)  DCFG_SEMAPHORE_IMPL="GNU_Semaphore_Mach"
	     d_module_mach=1 ;;
      pthreads) DCFG_SEMAPHORE_IMPL="GNU_Sempahore_Pthreads" ;;
      skyos) DCFG_SEMAPHORE_IMPL="GNU_Sempahore_Pthreads"
	     #D_EXTRA_OBJS="$D_EXTRA_OBJS std/c/skyos/compat.o"
	     ;;
      *)     AC_MSG_ERROR([No usable semaphore implementation]) ;;
    esac
else
    dnl Need to be able to query thread state for this method to be useful
    AC_CHECK_FUNC(pthread_suspend_np)
    AC_CHECK_FUNC(pthread_continue_np)

    if test "$ac_cv_func_pthread_suspend_np" = "yes" && \
       test "$ac_cv_func_pthread_continue_np" = "yes" ; then
	# TODO: need to test that these actually work.
	DCFG_PTHREAD_SUSPEND=GNU_pthread_suspend
    else
	AC_MSG_ERROR([TODO])
    fi
fi

AC_DEFINE(PHOBOS_USE_PTHREADS,1,[Define if using pthreads])

AC_CHECK_FUNC(mmap,DCFG_MMAP="GNU_Unix_Have_MMap",[])

AC_CHECK_FUNC(getpwnam_r,DCFG_GETPWNAM_R="GNU_Unix_Have_getpwnam_r",[])


# No std/c/unix/unix.o for Tango
D_EXTRA_OBJS="gcc/configunix.o gcc/cbridge_fdset.o $D_EXTRA_OBJS"
# Add "linux" module for compatibility even if not Linux
# Not for Tango
#D_EXTRA_OBJS="std/c/linux/linux.o $D_EXTRA_OBJS"
D_PREREQ_SRCS="$D_PREREQ_SRCS "'$(configunix_d_src)'
DCFG_UNIX="Unix"

])

dnl Garbage collection configuration
AC_DEFUN([DPHOBOS_CONFIGURE_GC], [

# Not for Tango
#D_GC_MODULES=internal/gc/gcgcc.o

d_gc_alloc=
d_gc_stack=
d_gc_data=

case "$d_target_os" in
  aix*)     d_gc_data="$d_gc_data GC_Use_Data_Fixed"
	    ;;
  cygwin*)  d_gc_data="$d_gc_data GC_Use_Data_Fixed"
	    ;;
  darwin*)
        # Not for Tango
        # D_GC_MODULES="$D_GC_MODULES internal/gc/gc_dyld.o"
	    D_MEM_MODULES="$D_MEM_MODULES memory_dyld.o"
	    d_gc_stack=GC_Use_Stack_Fixed
	    d_gc_data="$d_gc_data GC_Use_Data_Dyld"
	    ;;
  freebsd*)
        # Not for Tango
        # D_GC_MODULES="$D_GC_MODULES internal/gc/gc_freebsd.o"
	    D_MEM_MODULES="$D_MEM_MODULES memory_freebsd.o"
	    d_gc_stack=GC_Use_Stack_FreeBSD
	    d_gc_data="$d_gc_data GC_Use_Data_Fixed"
	    dnl maybe just GC_Use_Stack_ExternC
	    ;;
  linux*)
  	    #d_gc_stack=GC_Use_Stack_Proc_Stat
	    d_gc_data="$d_gc_data GC_Use_Data_Fixed"
	    #have_proc_maps=1
	    ;;
  skyos*)
        d_gc_data="$d_gc_data GC_Use_Data_Fixed"
	    ;;
  *)
        # Not for Tango
        # D_GC_MODULES=internal/gc/gcgcc.o
            ;;
esac

if test -z "$d_gc_alloc"; then
    AC_CHECK_FUNC(mmap,d_gc_alloc=GC_Use_Alloc_MMap,[])
fi
if test -z "$d_gc_alloc"; then
    AC_CHECK_FUNC(valloc,d_gc_alloc=GC_Use_Alloc_Valloc,[])
fi
if test -z "$d_gc_alloc"; then
    # Use malloc as a fallback
    d_gc_alloc=GC_Use_Alloc_Malloc
fi
#if test -z "$d_gc_alloc"; then
#    AC_MSG_ERROR([No usable memory allocation routine])
#fi

if test -z "$d_gc_stack"; then
    AC_MSG_CHECKING([for __libc_stack_end])
    AC_TRY_LINK([],[
	extern long __libc_stack_end;
	return __libc_stack_end == 0;],
      [AC_MSG_RESULT(yes)
       d_gc_stack=GC_Use_Stack_GLibC],
      [AC_MSG_RESULT(no)])
fi
if test -z "$d_gc_stack"; then
    d_gc_stack=GC_Use_Stack_Guess
    # Not for Tango
    # D_GC_MODULES="$D_GC_MODULES internal/gc/gc_guess_stack.o"
fi
if test -z "$d_gc_stack"; then
    AC_MSG_ERROR([No usable stack origin information])
fi

dnl if test -z "$d_gc_data"; then
dnl     AC_MSG_CHECKING([for __data_start and _end])
dnl     AC_TRY_LINK([],[
dnl 	    extern int __data_start;
dnl 	    extern int _end;
dnl 	    return & _end - & __data_start;],
dnl 	[AC_MSG_RESULT(yes)
dnl 	 d_gc_data="$d_gc_data GC_Use_Data_Data_Start_End"],
dnl 	[AC_MSG_RESULT(no)])
dnl fi
if test -n "$have_proc_maps" && test "$enable_proc_maps" = auto; then
    enable_proc_maps=yes
fi
if test "$enable_proc_maps" = yes; then
    d_gc_data="$d_gc_data GC_Use_Data_Proc_Maps"
fi
if test -z "$d_gc_data"; then
    AC_MSG_ERROR([No usable data segment information])
fi

f="-fversion=$d_gc_alloc -fversion=$d_gc_stack"
for m in $d_gc_data; do f="$f -fversion=$m"; done
# Not for Tango.  Instead, set D_MEM_FLAGS directly.
#D_GC_FLAGS=$f
D_MEM_FLAGS=$f

])
