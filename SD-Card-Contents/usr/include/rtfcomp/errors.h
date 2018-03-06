///////////////////////////////////////////////////////////////////////////////
// ERRORS.H
//
// Include file containing error codes for RTF compression library
//
// Dr J A Gow : 28/02/2007
//
// This file is distributed under the terms and conditions of the LGPL - please
// see the file LICENCE in the package root directory.
//
///////////////////////////////////////////////////////////////////////////////

#ifndef _ERRORS_H_
#define _ERRORS_H_

//
// Error codes

enum {
	LZRTF_ERR_NOERROR=0,
	LZRTF_ERR_NOMEM,
	LZRTF_ERR_BADCOMPRESSEDSIZE,
	LZRTF_ERR_BADCRC,
	LZRTF_ERR_BADARGS,
	LZRTF_ERR_BADMAGIC,
	LZRTF_ERR_BADINPUT,
	LZRTF_ERR_MAXERRCODE
};

#endif
