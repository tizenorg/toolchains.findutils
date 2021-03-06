dnl Reentrant time functions like localtime_r.

dnl Copyright (C) 2003, 2006, 2007 Free Software Foundation, Inc.
dnl This file is free software; the Free Software Foundation
dnl gives unlimited permission to copy and/or distribute it,
dnl with or without modifications, as long as this notice is preserved.

dnl Written by Paul Eggert.

AC_DEFUN([gl_TIME_R],
[
  AC_REQUIRE([gl_USE_SYSTEM_EXTENSIONS])
  AC_REQUIRE([AC_C_RESTRICT])

  AC_CACHE_CHECK([whether localtime_r is compatible with its POSIX signature],
    [gl_cv_time_r_posix],
    [AC_TRY_COMPILE(
       [#include <time.h>],
       [/* We don't need to append 'restrict's to the argument types,
	   even though the POSIX signature has the 'restrict's,
	   since C99 says they can't affect type compatibility.  */
	struct tm * (*ptr) (time_t const *, struct tm *) = localtime_r;
        if (ptr) return 0;],
       [gl_cv_time_r_posix=yes],
       [gl_cv_time_r_posix=no])])
  if test $gl_cv_time_r_posix = yes; then
    REPLACE_LOCALTIME_R=0
  else
    REPLACE_LOCALTIME_R=1
    AC_LIBOBJ([time_r])
    gl_PREREQ_TIME_R
  fi
])

# Prerequisites of lib/time_r.c.
AC_DEFUN([gl_PREREQ_TIME_R], [
  :
])
