/* nortlib.h include file for nortlib
 * $Log$
 * This is a fork to provide nl_error functionality to a Qt app. 
 *
 * Revision 1.22  2012/02/27 01:03:50  ntallen
 * Added ascii_escape() function
 *
 * Revision 1.21  2009/03/02 17:11:30  ntallen
 * Added const to char* declarations as necessary.
 *
 * Revision 1.20  2008/08/16 14:44:26  ntallen
 * MSG codes from msg.h
 *
 * Revision 1.19  2007/05/09 17:14:47  ntallen
 * Delete functions from another library
 *
 * Revision 1.18  2001/12/04 15:06:05  nort
 * Debugging, etc.
 *
 * Revision 1.17  2001/10/11 16:34:41  nort
 * Added compiler.oui. Fixed compiler.h.
 *
 * Revision 1.16  2001/09/10 17:31:47  nort
 *
 * Patch to nl_error.c to match correct prototype
 * Patch to nortlib.h to exclude functions not ported QNX6
 * Add GNU support files
 *
 * Revision 1.15  2001/01/18 15:07:20  nort
 * Getcon functions, memo_shutdown() and ci_time_str()
 *
 * Revision 1.14  1999/06/18 18:04:05  nort
 * Added ci_settime (a long time ago?)
 * Added DigSelect() from dccc.c
 *
 * Revision 1.13  1996/04/02  19:06:44  nort
 * Put back some tma.h defs to support old version (temporarily)
 *
 * Revision 1.12  1996/04/02  18:35:56  nort
 * Pruned log, removed tmcalgo funcs to tma.h
 *
 * Revision 1.1  1992/08/25  15:31:42  nort
 * Initial revision
 *
 */
#ifndef _NORTLIB_H_INCLUDED
#define _NORTLIB_H_INCLUDED

#include <sys/types.h>

#if defined(_MSC_VER) && _MSC_VER < 1900

#include <stdarg.h>

#define snprintf c99_snprintf
#define vsnprintf c99_vsnprintf

extern "C" {
  int c99_vsnprintf(char *outBuf, size_t size, const char *format, va_list ap);
  int c99_snprintf(char *outBuf, size_t size, const char *format, ...);
};

#endif

extern int (*nl_error)(int level, const char *s, ...); /* nl_error.cpp */
int nl_err(int level, const char *s, ...); /* nl_error.cpp */
#ifdef va_start
  int nl_verror(int level, const char *fmt, va_list args); /* nl_verr.cpp */
#endif

//#ifdef __cplusplus
//};
//#endif

/* These codes are taken from the old msg.h */
#define MSG_DEBUG -2
#define MSG_EXIT -1
#define MSG_EXIT_NORM MSG_EXIT
#define MSG 0
#define MSG_PASS MSG
#define MSG_WARN 1
#define MSG_FAIL 2
#define MSG_FATAL 3
#define MSG_EXIT_ABNORM 4
#define MSG_DBG(X) (MSG_DEBUG-(X))

extern int nl_debug_level; /* nldbg.c */
extern int nl_response; /* nlresp.c */
int set_response(int newval); /* nlresp.c */
#define NLRSP_DIE 3
#define NLRSP_WARN 1
#define NLRSP_QUIET 0
const char *ascii_escape(const char *ibuf);

#endif
