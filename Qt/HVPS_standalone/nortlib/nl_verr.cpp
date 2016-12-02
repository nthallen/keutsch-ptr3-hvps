/* nl_verr.c contains nl_verror() which allows easy expansion of
 * the nl_error capabilities in many cases.
 */
#include <QErrorMessage>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "nortlib.h"
char rcsid_nl_verr_c[] =
  "$Header$";


static QErrorMessage *QEM = 0;

#define MAX_MESSAGE_SIZE 120
int nl_verror(int level, const char *fmt, va_list args) {
  char *lvlmsg;
  char ef[MAX_MESSAGE_SIZE];
  int nc = 0; // The number of characters already in the buffer

  if (level < -1 && nl_debug_level > level) return(level);
  switch (level) {
    case -1: lvlmsg = ""; break;
    case 0: lvlmsg = ""; break;
    case 1: lvlmsg = "Warning: "; break;
    case 2: lvlmsg = "Error: "; break;
    case 3: lvlmsg = "Fatal: "; break;
    default:
      if (level <= -2) lvlmsg = "Debug: ";
      else lvlmsg = "Internal: ";
      break;
  }
  nc = snprintf(&ef[0], MAX_MESSAGE_SIZE, "%s", lvlmsg);
  if (nc < MAX_MESSAGE_SIZE) {
    vsnprintf(&ef[nc], MAX_MESSAGE_SIZE-nc, fmt, args);
  }
  if (QEM == 0) {
    QEM = new QErrorMessage();
  }
  if (level >= 3 || level == -1) {
    QEM->setModal(true);
    QEM->showMessage(ef);
    QEM->exec();
    if (level > 3) {
      ::abort();
    } else {
      ::exit(level > 0 ? level : 0);
    }
  } else {
    QEM->showMessage(ef);
    return level;
  }
}
/*
=Name nl_verror(): stdarg-style error message routine
=Subject Nortlib
=Synopsis

#include <stdarg.h>
#include "nortlib.h"
int nl_verror(FILE *ef, int level, const char *fmt, va_list args);

=Description

nl_verror() provides the same error message functionality as
=nl_err=() but with stdarg.h-style arguments. (nl_err() is
actually implemented by calling nl_verror()). This makes is
possible to create error message functions that do a little more
work on the message and then call nl_verror() to do the final
processing. =compile_error=() is written this way in order to
output the current input filename and line number before each
message.

=Returns

The level argument unless level dictates termination.

=SeeAlso

=nl_error=(), =nl_err=(), =nl_response=, =set_response=().

=End
*/
