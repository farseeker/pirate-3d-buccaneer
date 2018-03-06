///////////////////////////////////////////////////////////////////////////////
// RTFCOMP.H
//
// Include file for RTF compression library.
//
// Dr J A Gow : 25/02/2007
//
// This file is distributed under the terms and conditions of the LGPL - please
// see the file LICENCE in the package root directory.
//
///////////////////////////////////////////////////////////////////////////////

#ifndef _RTFCOMP_H_
#define _RTFCOMP_H_


#ifdef _CPLUSPLUS
extern "C" {
#endif

#include <rtfcomp/errors.h>	// error codes

//
// The options structure. This is extensible in case we add further options
// to the RTF converters without breaking compatibility with old programs

typedef struct _tag_RTFOPTS {

	int		lenOpts;	// the length of this structure
	unsigned int	isCompressed;	// generate/receive compressed RTF if true

} RTFOPTS;

//
// The library is reentrant and requires no initialization. Functions can be
// simply used when needed.

//
// Exported functions

///////////////////////////////////////////////////////////////////////////////
// LZRTFCompress
//
// EXPORTED, DLLAPI
//
// Compress an RTF string. Feed it a pointer to receive the result string
// pointer, the pointer to the source string and the length of the source
// string. The function will return error codes as documented in errorcodes.h
//
// Note, you (as the caller) takes ownership of the destination byte buffer
// which is dynamically allocated: so better make sure you free it when done
// with it or memory leaks will ensue. Note that the length of the output string
// can be had from the first little-endian DWORD in the output buffer, but
// it is returned anyway for convenience.
//
///////////////////////////////////////////////////////////////////////////////

int LZRTFCompress(unsigned char ** dest, unsigned int * outlen,
                  unsigned char * src, int len);

///////////////////////////////////////////////////////////////////////////////
// LZRTFDecompress
//
// EXPORTED, DLLAPI
//
// Decompress an RTF block. Feed it the source string pointer and length, and
// also a pointer to an unsigned int to receive the length of the output
// buffer. It returns an error code as documented in errorcodes.h
//
///////////////////////////////////////////////////////////////////////////////

int LZRTFDecompress(unsigned char ** dest, unsigned int * outlen, 
                    unsigned char * src, unsigned int len);

///////////////////////////////////////////////////////////////////////////////
// LZRTFConvertRTFToUTF8
//
// EXPORTED, DLLAPI
//
// Convert an RTF-encoded string to a UTF-8 encoded one. This is crude - we
// just assume that the RTF encoding is ANSI and that all characters are 
// either raw, or escaped out with the backslash/apostrophe sequence
//
///////////////////////////////////////////////////////////////////////////////

int LZRTFConvertRTFToUTF8(unsigned char ** utfout, unsigned int * utflen,
                          unsigned char * rtfin, unsigned int rtflen,
                          RTFOPTS * options);

///////////////////////////////////////////////////////////////////////////////
// LZRTFConvertUTF8ToRTF
//
// EXPORTED, DLLAPI
//
// Convert an RTF-encoded string to a UTF-8 encoded one. This is crude - we
// just assume that the RTF encoding is ANSI and that all characters are 
// either raw, or escaped out with the backslash/apostrophe sequence
// The header should be without the enclosing group, and  without the \rtf1
// control code. Unicode code points outside of the ANSI range are
// encoded as \uxxxxxxxx
//
///////////////////////////////////////////////////////////////////////////////

int LZRTFConvertUTF8ToRTF(unsigned char ** rtfout, unsigned int * lenOut,
                          unsigned char * utfin, unsigned int len,
                          unsigned char * rtfhdr, unsigned int hdrlen,
			  RTFOPTS * options);

///////////////////////////////////////////////////////////////////////////////
// LZRTFGetStringErrorCode
//
// EXPORTED, DLLAPI
//
// Return a user-friendly error message for each defined error code.
//
///////////////////////////////////////////////////////////////////////////////

const char * LZRTFGetStringErrorCode(int ec);

#ifdef _CPLUSPLUS
}
#endif
#endif
