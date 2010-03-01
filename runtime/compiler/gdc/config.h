/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.in by autoheader.  */

/* Define to 1 if the system has the type `clockid_t'. */
/* #undef HAVE_CLOCKID_T */

/* Define to 1 if you have the `exp2' function. */
#define HAVE_EXP2 1

/* Define to 1 if you have the `flockfile' function. */
#define HAVE_FLOCKFILE 1

/* Define to 1 fpclassify and signbit are available */
#define HAVE_FP_CLASSIFY_SIGNBIT 1

/* Define to 1 if you have the `funlockfile' function. */
#define HAVE_FUNLOCKFILE 1

/* Define to 1 if you have the `getc_unlocked' function. */
#define HAVE_GETC_UNLOCKED 1

/* Define to 1 if you have the `getwc_unlocked' function. */
/* #undef HAVE_GETWC_UNLOCKED */

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the `C' library (-lC). */
/* #undef HAVE_LIBC */

/* Define to 1 if you have the `m' library (-lm). */
#define HAVE_LIBM 1

/* Define to 1 if you have the `log2' function. */
#define HAVE_LOG2 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if the system has the type `pthread_barrierattr_t'. */
/* #undef HAVE_PTHREAD_BARRIERATTR_T */

/* Define to 1 if the system has the type `pthread_barrier_t'. */
/* #undef HAVE_PTHREAD_BARRIER_T */

/* Define to 1 if you have the <pthread.h> header file. */
#define HAVE_PTHREAD_H 1

/* Determines how to declared recursive mutexes */
#define HAVE_PTHREAD_MUTEX_RECURSIVE 1

/* Define to 1 if the system has the type `pthread_rwlockattr_t'. */
#define HAVE_PTHREAD_RWLOCKATTR_T 1

/* Define to 1 if the system has the type `pthread_rwlock_t'. */
#define HAVE_PTHREAD_RWLOCK_T 1

/* Define to 1 if the system has the type `pthread_spinlock_t'. */
/* #undef HAVE_PTHREAD_SPINLOCK_T */

/* Define to 1 if you have the `putc_unlocked' function. */
#define HAVE_PUTC_UNLOCKED 1

/* Define to 1 if you have the `putwc_unlocked' function. */
/* #undef HAVE_PUTWC_UNLOCKED */

/* Define to 1 if you have the <semaphore.h> header file. */
#define HAVE_SEMAPHORE_H 1

/* Define to 1 if the system has the type `siginfo_t'. */
#define HAVE_SIGINFO_T 1

/* Define to 1 if it is possible to determine the size of the DIR struct */
#define HAVE_SIZEOF_DIR 1

/* Define to 1 if it is possible to determine the size of the FILE struct */
#define HAVE_SIZEOF_FILE 1

/* Define to 1 if you have the `snprintf' function. */
#define HAVE_SNPRINTF 1

/* Define to 1 if the system has the type `socklen_t'. */
#define HAVE_SOCKLEN_T 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Global timezone variable */
#define HAVE_TIMEZONE 1

/* Extra fields in struct tm */
#define HAVE_TM_GMTOFF_AND_ZONE 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if you have the `vsnprintf' function. */
#define HAVE_VSNPRINTF 1

/* Define to 1 if you have the `_snprintf' function. */
/* #undef HAVE__SNPRINTF */

/* Another global timezone variable */
/* #undef HAVE__TIMEZONE */

/* Define to 1 if you have the `_vsnprintf' function. */
/* #undef HAVE__VSNPRINTF */

/* Name of package */
#define PACKAGE "libphobos"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT ""

/* Define to the full name of this package. */
#define PACKAGE_NAME "libphobos"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "libphobos version-unused"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "libphobos"

/* Define to the version of this package. */
#define PACKAGE_VERSION "version-unused"

/* Define if using pthreads */
#define PHOBOS_USE_PTHREADS 1

/* Define if mutexes are recursive by default */
/* #undef PTHREAD_MUTEX_ALREADY_RECURSIVE */

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Version number of package */
#define VERSION "version-unused"

/* Enable GNU extensions on systems that have them.  */
#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif
