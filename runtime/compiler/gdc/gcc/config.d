// gcc/config.d is a generated file
module gcc.config;

private import gcc.builtins;
private import gcc.configext;

alias __builtin_Clong Clong_t;
alias __builtin_Culong Culong_t;
// frags-ac.in...


private
{
version (PPC)
{
    version (GNU_WantLongDoubleFormat128)
	version = GNU_UseLongDoubleFormat128;
    else version (GNU_WantLongDoubleFormat64)
	{ }
    else
    {
	version (GNU_LongDouble128)
	    version = GNU_UseLongDoubleFormat128;
    }
}

version (GNU_UseLongDoubleFormat128)
{
    // Currently, the following test from cdefs.h is not supported:
    //# if __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__-0 < 1040
    version (all)
	const char[] __DARWIN_LDBL_COMPAT  = "$LDBL128";
    else
	const char[] __DARWIN_LDBL_COMPAT  = "$LDBLStub";
    const char[] __DARWIN_LDBL_COMPAT2 = "$LDBL128";

    const char[] __LIBMLDBL_COMPAT = "$LDBL128";
}
else
{
    const char[] __DARWIN_LDBL_COMPAT  = "";
    const char[] __DARWIN_LDBL_COMPAT2 = "";

    const char[] __LIBMLDBL_COMPAT = "";
}
}

extern (C) {

real acosl( real ); pragma(GNU_asm,acosl,"acosl" ~ __LIBMLDBL_COMPAT);
real asinl( real ); pragma(GNU_asm,asinl,"asinl" ~ __LIBMLDBL_COMPAT);
real atanl( real ); pragma(GNU_asm,atanl,"atanl" ~ __LIBMLDBL_COMPAT);
real atan2l( real, real ); pragma(GNU_asm,atan2l,"atan2l" ~ __LIBMLDBL_COMPAT);
real cosl( real ); pragma(GNU_asm,cosl,"cosl" ~ __LIBMLDBL_COMPAT);
real sinl( real ); pragma(GNU_asm,sinl,"sinl" ~ __LIBMLDBL_COMPAT);
real tanl( real ); pragma(GNU_asm,tanl,"tanl" ~ __LIBMLDBL_COMPAT);
real acoshl( real ); pragma(GNU_asm,acoshl,"acoshl" ~ __LIBMLDBL_COMPAT);
real asinhl( real ); pragma(GNU_asm,asinhl,"asinhl" ~ __LIBMLDBL_COMPAT);
real atanhl( real ); pragma(GNU_asm,atanhl,"atanhl" ~ __LIBMLDBL_COMPAT);
real coshl( real ); pragma(GNU_asm,coshl,"coshl" ~ __LIBMLDBL_COMPAT);
real sinhl( real ); pragma(GNU_asm,sinhl,"sinhl" ~ __LIBMLDBL_COMPAT);
real tanhl( real ); pragma(GNU_asm,tanhl,"tanhl" ~ __LIBMLDBL_COMPAT);
real expl( real ); pragma(GNU_asm,expl,"expl" ~ __LIBMLDBL_COMPAT);
real exp2l( real ); pragma(GNU_asm,exp2l,"exp2l" ~ __LIBMLDBL_COMPAT);
real expm1l( real ); pragma(GNU_asm,expm1l,"expm1l" ~ __LIBMLDBL_COMPAT);
real logl( real ); pragma(GNU_asm,logl,"logl" ~ __LIBMLDBL_COMPAT);
real log10l( real ); pragma(GNU_asm,log10l,"log10l" ~ __LIBMLDBL_COMPAT);
real log2l( real ); pragma(GNU_asm,log2l,"log2l" ~ __LIBMLDBL_COMPAT);
real log1pl( real ); pragma(GNU_asm,log1pl,"log1pl" ~ __LIBMLDBL_COMPAT);
real logbl( real ); pragma(GNU_asm,logbl,"logbl" ~ __LIBMLDBL_COMPAT);
real modfl( real, real * ); pragma(GNU_asm,modfl,"modfl" ~ __LIBMLDBL_COMPAT);
real ldexpl( real, int ); pragma(GNU_asm,ldexpl,"ldexpl" ~ __LIBMLDBL_COMPAT);
real frexpl( real, int * ); pragma(GNU_asm,frexpl,"frexpl" ~ __LIBMLDBL_COMPAT);
int ilogbl( real ); pragma(GNU_asm,ilogbl,"ilogbl" ~ __LIBMLDBL_COMPAT);
real scalbnl( real, int ); pragma(GNU_asm,scalbnl,"scalbnl" ~ __LIBMLDBL_COMPAT);
real scalblnl( real, Clong_t ); pragma(GNU_asm,scalblnl,"scalblnl" ~ __LIBMLDBL_COMPAT);
real fabsl( real ); pragma(GNU_asm,fabsl,"fabsl" ~ __LIBMLDBL_COMPAT);
real cbrtl( real ); pragma(GNU_asm,cbrtl,"cbrtl" ~ __LIBMLDBL_COMPAT);
real hypotl( real, real ); pragma(GNU_asm,hypotl,"hypotl" ~ __LIBMLDBL_COMPAT);
real powl( real, real ); pragma(GNU_asm,powl,"powl" ~ __LIBMLDBL_COMPAT);
real sqrtl( real ); pragma(GNU_asm,sqrtl,"sqrtl" ~ __LIBMLDBL_COMPAT);
real erfl( real ); pragma(GNU_asm,erfl,"erfl" ~ __LIBMLDBL_COMPAT);
real erfcl( real ); pragma(GNU_asm,erfcl,"erfcl" ~ __LIBMLDBL_COMPAT);
real lgammal( real ); pragma(GNU_asm,lgammal,"lgammal" ~ __LIBMLDBL_COMPAT);
real tgammal( real ); pragma(GNU_asm,tgammal,"tgammal" ~ __LIBMLDBL_COMPAT);
real ceill( real ); pragma(GNU_asm,ceill,"ceill" ~ __LIBMLDBL_COMPAT);
real floorl( real ); pragma(GNU_asm,floorl,"floorl" ~ __LIBMLDBL_COMPAT);
real nearbyintl( real ); pragma(GNU_asm,nearbyintl,"nearbyintl" ~ __LIBMLDBL_COMPAT);
real rintl( real ); pragma(GNU_asm,rintl,"rintl" ~ __LIBMLDBL_COMPAT);
Clong_t lrintl( real ); pragma(GNU_asm,lrintl,"lrintl" ~ __LIBMLDBL_COMPAT);
long llrintl( real ); pragma(GNU_asm,llrintl,"llrintl" ~ __LIBMLDBL_COMPAT);
real roundl( real ); pragma(GNU_asm,roundl,"roundl" ~ __LIBMLDBL_COMPAT);
Clong_t lroundl( real ); pragma(GNU_asm,lroundl,"lroundl" ~ __LIBMLDBL_COMPAT);
long llroundl( real ); pragma(GNU_asm,llroundl,"llroundl" ~ __LIBMLDBL_COMPAT);
real truncl( real ); pragma(GNU_asm,truncl,"truncl" ~ __LIBMLDBL_COMPAT);
real fmodl( real, real); pragma(GNU_asm,fmodl,"fmodl" ~ __LIBMLDBL_COMPAT);
real remainderl( real, real ); pragma(GNU_asm,remainderl,"remainderl" ~ __LIBMLDBL_COMPAT);
real remquol( real, real, int * ); pragma(GNU_asm,remquol,"remquol" ~ __LIBMLDBL_COMPAT);
real copysignl( real, real ); pragma(GNU_asm,copysignl,"copysignl" ~ __LIBMLDBL_COMPAT);
real nanl( char * ); pragma(GNU_asm,nanl,"nanl" ~ __LIBMLDBL_COMPAT);
real nextafterl( real, real ); pragma(GNU_asm,nextafterl,"nextafterl" ~ __LIBMLDBL_COMPAT);
double nexttoward( double, real ); pragma(GNU_asm,nexttoward,"nexttoward" ~ __LIBMLDBL_COMPAT);
float nexttowardf( float, real ); pragma(GNU_asm,nexttowardf,"nexttowardf" ~ __LIBMLDBL_COMPAT);
real nexttowardl( real, real ); pragma(GNU_asm,nexttowardl,"nexttowardl" ~ __LIBMLDBL_COMPAT);
real fdiml( real, real ); pragma(GNU_asm,fdiml,"fdiml" ~ __LIBMLDBL_COMPAT);
real fmaxl( real, real ); pragma(GNU_asm,fmaxl,"fmaxl" ~ __LIBMLDBL_COMPAT);
real fminl( real, real ); pragma(GNU_asm,fminl,"fminl" ~ __LIBMLDBL_COMPAT);
real fmal( real, real, real ); pragma(GNU_asm,fmal,"fmal" ~ __LIBMLDBL_COMPAT);

/*

pragma(GNU_asm,"_acosl" ~ __LIBMLDBL_COMPAT) real acosl( real );
pragma(GNU_asm,"_asinl" ~ __LIBMLDBL_COMPAT) real asinl( real );
pragma(GNU_asm,"_atanl" ~ __LIBMLDBL_COMPAT) real atanl( real );
pragma(GNU_asm,"_atan2l" ~ __LIBMLDBL_COMPAT) real atan2l( real, real );
pragma(GNU_asm,"_cosl" ~ __LIBMLDBL_COMPAT) real cosl( real );
pragma(GNU_asm,"_sinl" ~ __LIBMLDBL_COMPAT) real sinl( real );
pragma(GNU_asm,"_tanl" ~ __LIBMLDBL_COMPAT) real tanl( real );
pragma(GNU_asm,"_acoshl" ~ __LIBMLDBL_COMPAT) real acoshl( real );
pragma(GNU_asm,"_asinhl" ~ __LIBMLDBL_COMPAT) real asinhl( real );
pragma(GNU_asm,"_atanhl" ~ __LIBMLDBL_COMPAT) real atanhl( real );
pragma(GNU_asm,"_coshl" ~ __LIBMLDBL_COMPAT) real coshl( real );
pragma(GNU_asm,"_sinhl" ~ __LIBMLDBL_COMPAT) real sinhl( real );
pragma(GNU_asm,"_tanhl" ~ __LIBMLDBL_COMPAT) real tanhl( real );
pragma(GNU_asm,"_expl" ~ __LIBMLDBL_COMPAT) real expl( real );
pragma(GNU_asm,"_exp2l" ~ __LIBMLDBL_COMPAT) real exp2l( real );
pragma(GNU_asm,"_expm1l" ~ __LIBMLDBL_COMPAT) real expm1l( real );
pragma(GNU_asm,"_logl" ~ __LIBMLDBL_COMPAT) real logl( real );
pragma(GNU_asm,"_log10l" ~ __LIBMLDBL_COMPAT) real log10l( real );
pragma(GNU_asm,"_log2l" ~ __LIBMLDBL_COMPAT) real log2l( real );
pragma(GNU_asm,"_log1pl" ~ __LIBMLDBL_COMPAT) real log1pl( real );
pragma(GNU_asm,"_logbl" ~ __LIBMLDBL_COMPAT) real logbl( real );
pragma(GNU_asm,"_modfl" ~ __LIBMLDBL_COMPAT) real modfl( real, real * );
pragma(GNU_asm,"_ldexpl" ~ __LIBMLDBL_COMPAT) real ldexpl( real, int );
pragma(GNU_asm,"_frexpl" ~ __LIBMLDBL_COMPAT) real frexpl( real, int * );
pragma(GNU_asm,"_ilogbl" ~ __LIBMLDBL_COMPAT)  int ilogbl( real );
pragma(GNU_asm,"_scalbnl" ~ __LIBMLDBL_COMPAT) real scalbnl( real, int );
pragma(GNU_asm,"_scalblnl" ~ __LIBMLDBL_COMPAT) real scalblnl( real, Clong_t );
pragma(GNU_asm,"_fabsl" ~ __LIBMLDBL_COMPAT) real fabsl( real );
pragma(GNU_asm,"_cbrtl" ~ __LIBMLDBL_COMPAT) real cbrtl( real );
pragma(GNU_asm,"_hypotl" ~ __LIBMLDBL_COMPAT) real hypotl( real, real );
pragma(GNU_asm,"_powl" ~ __LIBMLDBL_COMPAT) real powl( real, real );
pragma(GNU_asm,"_sqrtl" ~ __LIBMLDBL_COMPAT) real sqrtl( real );
pragma(GNU_asm,"_erfl" ~ __LIBMLDBL_COMPAT) real erfl( real );
pragma(GNU_asm,"_erfcl" ~ __LIBMLDBL_COMPAT) real erfcl( real );
pragma(GNU_asm,"_lgammal" ~ __LIBMLDBL_COMPAT) real lgammal( real );
pragma(GNU_asm,"_tgammal" ~ __LIBMLDBL_COMPAT) real tgammal( real );
pragma(GNU_asm,"_ceill" ~ __LIBMLDBL_COMPAT) real ceill( real );
pragma(GNU_asm,"_floorl" ~ __LIBMLDBL_COMPAT) real floorl( real );
pragma(GNU_asm,"_nearbyintl" ~ __LIBMLDBL_COMPAT) real nearbyintl( real );
pragma(GNU_asm,"_rintl" ~ __LIBMLDBL_COMPAT) real rintl( real );
pragma(GNU_asm,"_lrintl" ~ __LIBMLDBL_COMPAT)  Clong_t lrintl( real );
pragma(GNU_asm,"_llrintl" ~ __LIBMLDBL_COMPAT)  long llrintl( real );
pragma(GNU_asm,"_roundl" ~ __LIBMLDBL_COMPAT) real roundl( real );
pragma(GNU_asm,"_lroundl" ~ __LIBMLDBL_COMPAT)  Clong_t lroundl( real );
pragma(GNU_asm,"_llroundl" ~ __LIBMLDBL_COMPAT)  long llroundl( real );
pragma(GNU_asm,"_truncl" ~ __LIBMLDBL_COMPAT) real truncl( real );
pragma(GNU_asm,"_fmodl" ~ __LIBMLDBL_COMPAT) real fmodl( real, real);
pragma(GNU_asm,"_remainderl" ~ __LIBMLDBL_COMPAT) real remainderl( real, real );
pragma(GNU_asm,"_remquol" ~ __LIBMLDBL_COMPAT) real remquol( real, real, int * );
pragma(GNU_asm,"_copysignl" ~ __LIBMLDBL_COMPAT) real copysignl( real, real );
pragma(GNU_asm,"_nanl" ~ __LIBMLDBL_COMPAT) real nanl( const char * );
pragma(GNU_asm,"_nextafterl" ~ __LIBMLDBL_COMPAT) real nextafterl( real, real );
pragma(GNU_asm,"_nexttoward" ~ __LIBMLDBL_COMPAT)  double nexttoward( double, real );
pragma(GNU_asm,"_nexttowardf" ~ __LIBMLDBL_COMPAT)  float nexttowardf( float, real );
pragma(GNU_asm,"_nexttowardl" ~ __LIBMLDBL_COMPAT) real nexttowardl( real, real );
pragma(GNU_asm,"_fdiml" ~ __LIBMLDBL_COMPAT) real fdiml( real, real );
pragma(GNU_asm,"_fmaxl" ~ __LIBMLDBL_COMPAT) real fmaxl( real, real );
pragma(GNU_asm,"_fminl" ~ __LIBMLDBL_COMPAT) real fminl( real, real );
pragma(GNU_asm,"_fmal" ~ __LIBMLDBL_COMPAT) real fmal( real, real, real );
*/

alias __builtin_sqrt sqrt;
}

alias __builtin_sqrtf sqrtf;

//   C stdio config for std.stdio
const bool Have_fwide = 1;
const bool Have_getdelim = 0;
const bool Have_fgetln = 1;
const bool Have_fgetline = 0;
const bool Have_Unlocked_Stdio = 1;
const bool Have_Unlocked_Wide_Stdio = 0;

// ...frags-ac.in

// from <dirent.h>
const size_t dirent_d_name_offset = 8;
const size_t dirent_d_name_size = 256;
const size_t dirent_remaining_size = 0;
const size_t DIR_struct_size = 80;

// from <stdlib.h>
const int RAND_MAX = 2147483647;

// from <stdio.h>
const size_t FILE_struct_size = 88;
const int EOF = -1;
const int FOPEN_MAX = 20;
const int FILENAME_MAX = 1024;
const int TMP_MAX = 308915776;
const int L_tmpnam = 1024;
const int PATH_MAX = 1024;

// from <sys/types.h>
alias long Coff_t;
alias uint Csize_t;
alias int Ctime_t;
alias uint Cclock_t;

// from <time.h>
const uint CLOCKS_PER_SEC = 1000000;
struct tm {
    int tm_sec;
    int tm_min;
    int tm_hour;
    int tm_mday;
    int tm_mon;
    int tm_year;
    int tm_wday;
    int tm_yday;
    int tm_isdst;
    int tm_gmtoff;
    char * tm_zone;
}

static assert(tm.tm_sec.offsetof == 0);
static assert(tm.tm_min.offsetof == 4);
static assert(tm.tm_hour.offsetof == 8);
static assert(tm.tm_mday.offsetof == 12);
static assert(tm.tm_mon.offsetof == 16);
static assert(tm.tm_year.offsetof == 20);
static assert(tm.tm_wday.offsetof == 24);
static assert(tm.tm_yday.offsetof == 28);
static assert(tm.tm_isdst.offsetof == 32);
static assert(tm.tm_gmtoff.offsetof == 36);
static assert(tm.sizeof == 44);


extern(C) {

enum {
  FP_NAN = 1,
  FP_INFINITE = 2,
  FP_ZERO = 3,
  FP_SUBNORMAL = 5,
  FP_NORMAL = 4,
}

}


// TODO: configurate ?  This is a real mess...
version (linux) {
    version(X86)
        version = Use_FP_Math;
    else version(X86_64)
        version = Use_FP_Math;
    else version(PPC)
        version = Use_FP_Math;
    else version(PPC64)
        version = Use_FP_Math;
    else version(SPARC)
        version = Use_FP_Math;
    else version(SPARC64)
        version = Use_FP_Math;
    // any system using IEEE FP is fine, just not listed

} else version (darwin) {
    // could use direct ieee stuff, but long double/real is a problem
  extern (C) {
      // the 'real' versions are declared, but do not actually exist...
      int __isnand(double);
      int __isnanf(float);
      int __isnan(real);
      int __isfinited(double);
      int __isfinitef(float);
      int __isfinite(real);
      int __isnormald(double);
      int __isnormalf(float);
      int __isnormal(real);
      int __fpclassifyd(double);
      int __fpclassifyf(float);
      int __fpclassify(real);
      int __isinfd(double);
      int __isinff(float);
      int __isinf(real);
      int __signbitd(double);
      int __signbitf(float);
      int __signbitl(real);
  }

  int isnan(real x) { return __isnand(x); }
  int isfinite(real x) { return __isfinited(x); }
  int isnormal(real x) { return __isnormald(x); }
  int isnormal(double x) { return __isnormald(x); }
  int isnormal(float x) { return __isnormalf(x); }
  int issubnormal(real x) { return __fpclassifyd(x) == FP_SUBNORMAL; }
  int issubnormal(double x) { return __fpclassifyd(x) == FP_SUBNORMAL; }
  int issubnormal(float x) { return __fpclassifyf(x) == FP_SUBNORMAL; }
  int isinf(real x) { return __isinfd(x); }
  int signbit(real x) { return __signbitd(x); }
  int fpclassify(real x) { return __fpclassifyd(x); }
  int fpclassify(double x) { return __fpclassifyd(x); }
  int fpclassify(float x) { return __fpclassifyf(x); }
} else version (solaris) {
    // for now this is a copy of the darwin stuff (and doesn't work)
  extern (C) {
      // the 'real' versions are declared, but do not actually exist...
      int __isnand(double);
      int __isnanf(float);
      int __isnan(real);
      int __isfinited(double);
      int __isfinitef(float);
      int __isfinite(real);
      int __isnormald(double);
      int __isnormalf(float);
      int __isnormal(real);
      int __fpclassifyd(double);
      int __fpclassifyf(float);
      int __fpclassify(real);
      int __isinfd(double);
      int __isinff(float);
      int __isinf(real);
      int __signbitd(double);
      int __signbitf(float);
      int __signbitl(real);
  }

  int isnan(real x) { return __isnand(x); }
  int isfinite(real x) { return __isfinited(x); }
  int isnormal(real x) { return __isnormald(x); }
  int isnormal(double x) { return __isnormald(x); }
  int isnormal(float x) { return __isnormalf(x); }
  int issubnormal(real x) { return __fpclassifyd(x) == FP_SUBNORMAL; }
  int issubnormal(double x) { return __fpclassifyd(x) == FP_SUBNORMAL; }
  int issubnormal(float x) { return __fpclassifyf(x) == FP_SUBNORMAL; }
  int isinf(real x) { return __isinfd(x); }
  int signbit(real x) { return __signbitd(x); }
  int fpclassify(real x) { return __fpclassifyd(x); }
  int fpclassify(double x) { return __fpclassifyd(x); }
  int fpclassify(float x) { return __fpclassifyf(x); }
} else {
    version = Use_FP_Math;
}

version (Use_FP_Math)
{
    import gcc.fpmath;

    int isnan(real x) { return fpclassify(x)==FP_NAN; }
    int isfinite(real x) {
        int r = fpclassify(x);
        return r != FP_NAN && r != FP_INFINITE;
    }
    int isnormal(real x) { return fpclassify(x)==FP_NORMAL; }
    int isnormal(double x) { return fpclassify(x)==FP_NORMAL; }
    int isnormal(float x) { return fpclassify(x)==FP_NORMAL; }
    int issubnormal(real x) { return fpclassify(x) == FP_SUBNORMAL; }
    int issubnormal(double x) { return fpclassify(x) == FP_SUBNORMAL; }
    int issubnormal(float x) { return fpclassify(x) == FP_SUBNORMAL; }
    int isinf(real x) { return fpclassify(x)==FP_INFINITE; }
}

// TODO: configure these
private import tango.stdc.stdio;
extern (C) int ferror(FILE *);
extern (C) int feof(FILE *);
extern (C) void clearerr(FILE *);
extern (C) void rewind(FILE *);
extern (C) int _bufsize(FILE *);
extern (C) int fileno(FILE *);

alias __builtin_snprintf Csnprintf;
alias __builtin_vsnprintf Cvsnprintf;
alias __builtin_snprintf C_snprintf;
alias __builtin_vsnprintf C_vsnprintf;

version (GNU_Have_strtold)
{
    extern (C) real strtold(char*, char**);
    alias strtold cstrtold;
}
else
{
    private extern (C) double strtod(char*, char**);
    extern (D) real cstrtold(char* a, char** b) { return strtod(a, b); }
}
