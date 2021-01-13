#ifndef COMMON_H
#define COMMON_H

#define SREC_VER "1.51"

#define HEADER2 "Copyright (c) 2000-2019 Ant Goffart - http://www.s-record.com/\n\n"

#include <stdio.h>
#include <stdint.h>

#define max(a,b) (((a)>(b))?(a):(b))
#define min(a,b) (((a)<(b))?(a):(b))

uint8_t char_to_uint8(char s);
uint32_t str_to_uint32(char *s);
uint32_t file_size(FILE *f);

#endif
