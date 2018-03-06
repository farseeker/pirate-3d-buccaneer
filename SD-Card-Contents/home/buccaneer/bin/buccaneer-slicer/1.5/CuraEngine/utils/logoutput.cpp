/** Copyright (C) 2013 David Braam - Released under terms of the AGPLv3 License */
#include <stdio.h>
#include <stdarg.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>

#include "utils/logoutput.h"

int verbose_level;

void logError(const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    vfprintf(stdout, fmt, args);
    va_end(args);
    fflush(stdout);
}

void _log(const char* fmt, ...)
{
    if (verbose_level < 1)
        return;

    va_list args;
    va_start(args, fmt);
    vfprintf(stdout, fmt, args);
    va_end(args);
    fflush(stdout);
}

int logging = 0;
struct timespec lastLog;

void logLongProgress(const char* type, long value, long maxValue)
{
		int doLog = 0;
		struct timespec thisLog;
    if (verbose_level < 2)
        return;
		if (verbose_level < 3) {
			if (logging == 0) {
				doLog = 1;
			} else {
				clock_gettime(CLOCK_MONOTONIC,  &thisLog);
				if (thisLog.tv_sec - lastLog.tv_sec > 1)
					doLog = 1;
			}
			if (doLog) {
		    fprintf(stdout, "Progress:%s:%i:%i\n", type, (int)(value/1024), (int)(maxValue/1024));
		    fflush(stdout);
		    clock_gettime(CLOCK_MONOTONIC,  &lastLog);
		    logging = 1;
		  }
	    return;
  	}

}

void logProgress(const char* type, int value, int maxValue)
{
//		int doLog = 0;
//		struct timespec thisLog;
    if (verbose_level < 2)
        return;
/*		if (verbose_level < 3) {
			if (logging == 0) {
				doLog = 1;
			} else {
				clock_gettime(CLOCK_MONOTONIC,  &thisLog);
				if (thisLog.tv_sec - lastLog.tv_sec > 1)
					doLog = 1;
			}
			if (doLog) {
*/
		    fprintf(stdout, "Progress:%s:%i:%i\n", type, value, maxValue);
		    fflush(stdout);
//		    clock_gettime(CLOCK_MONOTONIC,  &lastLog);
//		    logging = 1;
//		  }
//	    return;
//  	}

}
