comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: icon_image.asm                                                     *
*                                                                          *
* This code is freeware, not public domain.  Please use respectfully.      *
*                                                                          *
* You may:                                                                 *
*  - use this code for learning purposes only.                             *
*  - use this code in your own Operating System development.               *
*  - distribute any code that you produce pertaining to this code          *
*    as long as it is for learning purposes only, not for profit,          *
*    and you give credit where credit is due.                              *
*                                                                          *
* You may NOT:                                                             *
*  - distribute this code for any purpose other than listed above.         *
*  - distribute this code for profit.                                      *
*                                                                          *
* You MUST:                                                                *
*  - include this whole comment block at the top of this file.             *
*  - include contact information to where the original source is located.  *
*            https://github.com/fysnet/i440fx                              *
*                                                                          *
* DESCRIPTION:                                                             *
*   icon include file                                                      *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.08                                         *
*          Command line: nbasm i44fx /z<enter>                             *
*                                                                          *
* Last Updated: 19 Oct 2024                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; an image can be any size with the following format:
;  word  width
;  word  height
;  word  size of palette in 32-bit pixels (ex: 4 = four 32-bit pixels)
;  byte  run/string count 
;        128 or less = run. run = count of single byte
;        129 or more = string. string = byte - 128 count of bytes to follow
;  byte  index into palette
;  (repeat count/byte fields)
;
;  this RLE can be created using bmp2bios.exe
;    bmo2bios image.ico > icon_image.asm
;
;  to make smaller images, use as few pixel colors as possible.
;  i.e.: if the image has 20 colors, it will use less than an image with 60 different colors.
;

  dw  240  ; width
  dw  102  ; height
  dw   16  ; palette size
  ; pallet (16 pixels)
  dd  0x00FCFCFD, 0x009065CE, 0x00BABBE8, 0x005B521B, 0x00090907, 0x00A1A1A0, 0x003F51D4, 0x005094F1
  dd  0x00624DC1, 0x00A89FDA, 0x00616160, 0x00887710, 0x00B09506, 0x00D7BB02, 0x00C1AF30, 0x001A029C
  ; pixel table:
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 103 0x00's
  db  103, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 111 0x00's
  db  111, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 86 0x00's
  db  86, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x03
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 19 0x00's
  db  19, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 86 0x00's
  db  86, 0x00
  ; count of 1 bytes
  db  129, 0x03
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 19 0x00's
  db  19, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 1 bytes
  db  129, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x08's
  db  2, 0x08
  ; count of 2 bytes
  db  130, 0x06, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 4 0x06's
  db  4, 0x06
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 9 bytes
  db  137, 0x02, 0x00, 0x02, 0x08, 0x06, 0x02, 0x08, 0x07, 0x00
  ; run of 2 0x08's
  db  2, 0x08
  ; count of 6 bytes
  db  134, 0x09, 0x00, 0x09, 0x06, 0x07, 0x00
  ; run of 2 0x08's
  db  2, 0x08
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 6 bytes
  db  134, 0x08, 0x06, 0x07, 0x02, 0x00, 0x02
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 4 bytes
  db  132, 0x00, 0x01, 0x06, 0x07
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 4 0x06's
  db  4, 0x06
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 2 0x06's
  db  2, 0x06
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 4 0x06's
  db  4, 0x06
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 2 0x06's
  db  2, 0x06
  ; run of 11 0x00's
  db  11, 0x00
  ; run of 2 0x08's
  db  2, 0x08
  ; run of 3 0x06's
  db  3, 0x06
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 6 bytes
  db  134, 0x02, 0x08, 0x06, 0x07, 0x00, 0x02
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 14 bytes
  db  142, 0x00, 0x01, 0x06, 0x07, 0x00, 0x08, 0x02, 0x00, 0x08, 0x06, 0x02, 0x01, 0x06, 0x02
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 2 bytes
  db  130, 0x02, 0x09
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 1 bytes
  db  129, 0x00
  ; run of 2 0x08's
  db  2, 0x08
  ; count of 2 bytes
  db  130, 0x07, 0x00
  ; run of 2 0x08's
  db  2, 0x08
  ; count of 2 bytes
  db  130, 0x09, 0x02
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 4 bytes
  db  132, 0x00, 0x01, 0x06, 0x07
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 3 0x06's
  db  3, 0x06
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 6 0x00's
  db  6, 0x00
  ; run of 2 0x08's
  db  2, 0x08
  ; run of 3 0x06's
  db  3, 0x06
  ; count of 9 bytes
  db  137, 0x07, 0x00, 0x02, 0x08, 0x06, 0x02, 0x08, 0x07, 0x02
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 8 bytes
  db  136, 0x00, 0x01, 0x06, 0x07, 0x00, 0x09, 0x06, 0x07
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x01, 0x02, 0x00, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x06
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 8 bytes
  db  136, 0x02, 0x09, 0x00, 0x06, 0x02, 0x00, 0x09, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 2 0x02's
  db  2, 0x02
  ; count of 3 bytes
  db  131, 0x00, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x01, 0x07, 0x00, 0x02, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x09
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 8 0x00's
  db  8, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x01, 0x07, 0x00, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 7 bytes
  db  135, 0x02, 0x06, 0x02, 0x00, 0x06, 0x02, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; count of 3 bytes
  db  131, 0x00, 0x01, 0x09
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 2 0x02's
  db  2, 0x02
  ; count of 4 bytes
  db  132, 0x07, 0x00, 0x02, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x01, 0x02, 0x00, 0x02, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x09
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x06, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 7 bytes
  db  135, 0x07, 0x00, 0x01, 0x09, 0x00, 0x09, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 18 0x00's
  db  18, 0x00
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x09
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 5 bytes
  db  133, 0x09, 0x07, 0x00, 0x02, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; run of 2 0x09's
  db  2, 0x09
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x02, 0x07, 0x00, 0x02, 0x08
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 5 bytes
  db  133, 0x01, 0x02, 0x00, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 4 bytes
  db  132, 0x08, 0x02, 0x00, 0x06
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x08, 0x02, 0x00, 0x09, 0x08
  ; run of 2 0x06's
  db  2, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x06
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 19 0x00's
  db  19, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 6 bytes
  db  134, 0x02, 0x06, 0x02, 0x00, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x06
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 5 bytes
  db  133, 0x09, 0x07, 0x00, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x02, 0x07, 0x00, 0x02, 0x06
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 5 bytes
  db  133, 0x01, 0x02, 0x00, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x06, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x06's
  db  5, 0x06
  ; count of 1 bytes
  db  129, 0x07
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 6 bytes
  db  134, 0x08, 0x06, 0x07, 0x00, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x06, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x09
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 20 0x00's
  db  20, 0x00
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x0A
  ; run of 19 0x00's
  db  19, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 3 bytes
  db  131, 0x01, 0x06, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x08
  ; run of 3 0x06's
  db  3, 0x06
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x08
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x08, 0x09, 0x00, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 9 bytes
  db  137, 0x01, 0x09, 0x00, 0x02, 0x06, 0x02, 0x00, 0x01, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x06, 0x00, 0x07
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x08
  ; run of 3 0x06's
  db  3, 0x06
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 8 bytes
  db  136, 0x08, 0x02, 0x00, 0x09, 0x07, 0x00, 0x01, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 4 bytes
  db  132, 0x01, 0x02, 0x00, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x01
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x08, 0x09, 0x00, 0x02, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x06
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 19 0x00's
  db  19, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 19 0x00's
  db  19, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x08, 0x07
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 3 bytes
  db  131, 0x09, 0x07, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 10 bytes
  db  138, 0x08, 0x06, 0x08, 0x07, 0x00, 0x02, 0x06, 0x07, 0x00, 0x01
  ; run of 3 0x06's
  db  3, 0x06
  ; count of 3 bytes
  db  131, 0x02, 0x06, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 8 bytes
  db  136, 0x02, 0x00, 0x02, 0x06, 0x02, 0x01, 0x06, 0x07
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 3 bytes
  db  131, 0x09, 0x00, 0x06
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 30 bytes
  db  158, 0x08, 0x06, 0x07, 0x00, 0x02, 0x06, 0x02, 0x01, 0x06, 0x07, 0x00, 0x01, 0x06, 0x02, 0x00, 0x02
  db       0x08, 0x06, 0x07, 0x00, 0x02, 0x06, 0x07, 0x09, 0x06, 0x07, 0x00, 0x01, 0x06, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 9 bytes
  db  137, 0x06, 0x07, 0x00, 0x02, 0x06, 0x02, 0x01, 0x06, 0x07
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x06, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 15 bytes
  db  143, 0x02, 0x06, 0x02, 0x00, 0x01, 0x06, 0x00, 0x02, 0x06, 0x02, 0x01, 0x06, 0x07, 0x00, 0x01
  ; run of 3 0x06's
  db  3, 0x06
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 3 bytes
  db  131, 0x03, 0x04, 0x0A
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 30 0x00's
  db  30, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 4 bytes
  db  132, 0x09, 0x02, 0x01, 0x02
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 50 0x00's
  db  50, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x06
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 19 0x00's
  db  19, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 16 0x00's
  db  16, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 6 bytes
  db  134, 0x05, 0x00, 0x04, 0x03, 0x04, 0x03
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x07
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 8 bytes
  db  136, 0x08, 0x02, 0x00, 0x02, 0x09, 0x00, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x06
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 22 0x00's
  db  22, 0x00
  ; count of 5 bytes
  db  133, 0x01, 0x02, 0x00, 0x09, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x09, 0x07, 0x00, 0x09, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x01, 0x02, 0x00, 0x09, 0x06
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x06
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x06
  ; run of 15 0x00's
  db  15, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x08, 0x07
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 19 0x00's
  db  19, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 15 0x00's
  db  15, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x03
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x04
  ; run of 2 0x05's
  db  2, 0x05
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 11 bytes
  db  139, 0x02, 0x08, 0x06, 0x02, 0x00, 0x01, 0x06, 0x07, 0x00, 0x02, 0x08
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 3 bytes
  db  131, 0x02, 0x00, 0x08
  ; run of 4 0x06's
  db  4, 0x06
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; run of 5 0x06's
  db  5, 0x06
  ; count of 1 bytes
  db  129, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x06
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 23 0x00's
  db  23, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 1 bytes
  db  129, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 2 0x06's
  db  2, 0x06
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 2 0x06's
  db  2, 0x06
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 4 0x06's
  db  4, 0x06
  ; count of 1 bytes
  db  129, 0x02
  ; run of 15 0x00's
  db  15, 0x00
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x07
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 4 0x06's
  db  4, 0x06
  ; count of 1 bytes
  db  129, 0x02
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 3 bytes
  db  131, 0x08, 0x06, 0x07
  ; run of 35 0x00's
  db  35, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x02
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 98 0x00's
  db  98, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x02
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 98 0x00's
  db  98, 0x00
  ; count of 1 bytes
  db  129, 0x03
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 8 bytes
  db  136, 0x04, 0x05, 0x00, 0x05, 0x03, 0x04, 0x03, 0x05
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 97 0x00's
  db  97, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x04, 0x05, 0x00
  ; run of 5 0x04's
  db  5, 0x04
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 97 0x00's
  db  97, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x04, 0x05, 0x00
  ; run of 5 0x04's
  db  5, 0x04
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 98 0x00's
  db  98, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x0A, 0x05
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 3 bytes
  db  131, 0x04, 0x05, 0x00
  ; run of 5 0x04's
  db  5, 0x04
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 104 0x00's
  db  104, 0x00
  ; count of 8 bytes
  db  136, 0x04, 0x05, 0x00, 0x05, 0x0A, 0x04, 0x03, 0x05
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 102 0x00's
  db  102, 0x00
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 3 bytes
  db  131, 0x04, 0x0A, 0x05
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 106 0x00's
  db  106, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 105 0x00's
  db  105, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 106 0x00's
  db  106, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 23 0x00's
  db  23, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 46 0x00's
  db  46, 0x00
  ; run of 2 0x05's
  db  2, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 6 0x00's
  db  6, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 6 0x00's
  db  6, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x05
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x00, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x05
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 4 bytes
  db  132, 0x02, 0x00, 0x05, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x09
  ; run of 5 0x00's
  db  5, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x05
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 34 0x00's
  db  34, 0x00
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x02
  ; run of 20 0x00's
  db  20, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x03
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 44 0x00's
  db  44, 0x00
  ; count of 7 bytes
  db  135, 0x0A, 0x04, 0x05, 0x00, 0x02, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x04's
  db  2, 0x04
  ; run of 2 0x02's
  db  2, 0x02
  ; count of 18 bytes
  db  146, 0x04, 0x03, 0x02, 0x05, 0x04, 0x05, 0x00, 0x05, 0x04, 0x0A, 0x00, 0x05, 0x04, 0x02, 0x00, 0x0A
  db       0x04, 0x05
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 13 bytes
  db  141, 0x05, 0x04, 0x0A, 0x00, 0x05, 0x04, 0x02, 0x00, 0x05, 0x04, 0x0A, 0x02, 0x03
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 1 bytes
  db  129, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x04's
  db  2, 0x04
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 4 bytes
  db  132, 0x0A, 0x09, 0x04, 0x03
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 2 0x04's
  db  2, 0x04
  ; run of 2 0x0A's
  db  2, 0x0A
  ; count of 1 bytes
  db  129, 0x05
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 7 bytes
  db  135, 0x02, 0x04, 0x0A, 0x02, 0x00, 0x0A, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 6 bytes
  db  134, 0x0A, 0x04, 0x05, 0x00, 0x0A, 0x04
  ; run of 3 0x0A's
  db  3, 0x0A
  ; count of 1 bytes
  db  129, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x04
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 5 bytes
  db  133, 0x03, 0x04, 0x05, 0x03, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 3 0x0A's
  db  3, 0x0A
  ; count of 17 bytes
  db  145, 0x00, 0x05, 0x04, 0x02, 0x00, 0x05, 0x04, 0x0A, 0x02, 0x03, 0x09, 0x05, 0x04, 0x00, 0x05, 0x04
  db       0x05
  ; run of 33 0x00's
  db  33, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x0A
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x05
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 42 0x00's
  db  42, 0x00
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 17 bytes
  db  145, 0x04, 0x03, 0x00, 0x02, 0x04, 0x0A, 0x00, 0x02, 0x04, 0x0A, 0x00, 0x05, 0x04, 0x05, 0x02, 0x04
  db       0x0A
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 13 bytes
  db  141, 0x02, 0x04, 0x0A, 0x00, 0x05, 0x04, 0x05, 0x00, 0x02, 0x04, 0x0A, 0x00, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 17 bytes
  db  145, 0x04, 0x0A, 0x00, 0x03, 0x04, 0x00, 0x05, 0x04, 0x0A, 0x05, 0x0A, 0x04, 0x0A, 0x00, 0x0A, 0x04
  db       0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 10 bytes
  db  138, 0x0A, 0x04, 0x02, 0x00, 0x05, 0x04, 0x05, 0x00, 0x04, 0x03
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 15 bytes
  db  143, 0x0A, 0x04, 0x02, 0x00, 0x05, 0x03, 0x00, 0x02, 0x04, 0x0A, 0x00, 0x02, 0x04, 0x05, 0x02
  ; run of 2 0x04's
  db  2, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 9 bytes
  db  137, 0x05, 0x04, 0x05, 0x00, 0x05, 0x04, 0x05, 0x00, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x04, 0x0A, 0x02, 0x03, 0x05
  ; run of 51 0x00's
  db  51, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x0A
  ; run of 11 0x04's
  db  11, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 41 0x00's
  db  41, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 10 bytes
  db  138, 0x0A, 0x04, 0x02, 0x00, 0x0A, 0x04, 0x02, 0x00, 0x03, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 9 bytes
  db  137, 0x04, 0x0A, 0x02, 0x00, 0x04, 0x0A, 0x00, 0x02, 0x04
  ; run of 2 0x0A's
  db  2, 0x0A
  ; count of 2 bytes
  db  130, 0x04, 0x02
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 10 bytes
  db  138, 0x04, 0x03, 0x00, 0x02, 0x04, 0x0A, 0x00, 0x02, 0x04, 0x0A
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 6 bytes
  db  134, 0x0A, 0x04, 0x05, 0x00, 0x0A, 0x04
  ; run of 2 0x02's
  db  2, 0x02
  ; count of 4 bytes
  db  132, 0x04, 0x0A, 0x00, 0x05
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 5 bytes
  db  133, 0x00, 0x0A, 0x04, 0x0A, 0x05
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 8 bytes
  db  136, 0x05, 0x04, 0x05, 0x00, 0x05, 0x04, 0x05, 0x02
  ; run of 2 0x04's
  db  2, 0x04
  ; run of 2 0x05's
  db  2, 0x05
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x04, 0x0A, 0x02, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x0A, 0x04, 0x00, 0x04, 0x0A
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x05
  ; run of 52 0x00's
  db  52, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 16 0x04's
  db  16, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 39 0x00's
  db  39, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 18 bytes
  db  146, 0x05, 0x04, 0x03, 0x00, 0x05, 0x04, 0x02, 0x00, 0x0A, 0x04, 0x02, 0x00, 0x03, 0x04, 0x05, 0x00
  db       0x03, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 4 bytes
  db  132, 0x03, 0x04, 0x03, 0x0A
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 4 bytes
  db  132, 0x05, 0x00, 0x04, 0x03
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 4 bytes
  db  132, 0x05, 0x04, 0x05, 0x00
  ; run of 2 0x03's
  db  2, 0x03
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x03, 0x04, 0x02, 0x05, 0x04
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x03
  ; run of 3 0x00's
  db  3, 0x00
  ; run of 2 0x04's
  db  2, 0x04
  ; run of 2 0x02's
  db  2, 0x02
  ; count of 6 bytes
  db  134, 0x04, 0x0A, 0x00, 0x03, 0x04, 0x00
  ; run of 2 0x0A's
  db  2, 0x0A
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x04's
  db  2, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x03, 0x04, 0x00, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x0A, 0x04, 0x05, 0x03, 0x04
  ; run of 5 0x00's
  db  5, 0x00
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 2 bytes
  db  130, 0x05, 0x00
  ; run of 2 0x04's
  db  2, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x0A
  ; run of 50 0x00's
  db  50, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x0A, 0x03
  ; run of 18 0x04's
  db  18, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 37 0x00's
  db  37, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x0A
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 18 bytes
  db  146, 0x04, 0x05, 0x00, 0x05, 0x04, 0x05, 0x00, 0x0A, 0x04, 0x0A, 0x05, 0x0A, 0x04, 0x02, 0x00, 0x03
  db       0x04, 0x02
  ; run of 2 0x0A's
  db  2, 0x0A
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 23 bytes
  db  151, 0x0A, 0x04, 0x02, 0x00, 0x03, 0x04, 0x0A, 0x02, 0x03, 0x04, 0x00, 0x02, 0x04, 0x0A, 0x00, 0x02
  db       0x00, 0x02, 0x04, 0x0A, 0x00, 0x05, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 9 bytes
  db  137, 0x0A, 0x04, 0x02, 0x00, 0x04, 0x0A, 0x00, 0x0A, 0x03
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x04
  ; run of 3 0x00's
  db  3, 0x00
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 11 bytes
  db  139, 0x0A, 0x00, 0x04, 0x0A, 0x00, 0x05, 0x04, 0x00, 0x02, 0x04, 0x05
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 11 bytes
  db  139, 0x0A, 0x00, 0x0A, 0x04, 0x02, 0x0A, 0x04, 0x02, 0x00, 0x05, 0x04
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 2 bytes
  db  130, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 8 bytes
  db  136, 0x05, 0x00, 0x0A, 0x04, 0x0A, 0x02, 0x0A, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 4 bytes
  db  132, 0x04, 0x0A, 0x00, 0x02
  ; run of 48 0x00's
  db  48, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 9 0x04's
  db  9, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 2 0x0B's
  db  2, 0x0B
  ; run of 11 0x04's
  db  11, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 36 0x00's
  db  36, 0x00
  ; count of 7 bytes
  db  135, 0x02, 0x04, 0x03, 0x02, 0x00, 0x02, 0x04
  ; run of 2 0x0A's
  db  2, 0x0A
  ; count of 12 bytes
  db  140, 0x03, 0x04, 0x0A, 0x00, 0x05, 0x04, 0x0A, 0x00, 0x0A, 0x04, 0x05, 0x0A
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 6 bytes
  db  134, 0x02, 0x00, 0x0A, 0x04, 0x02, 0x00
  ; run of 2 0x0A's
  db  2, 0x0A
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 8 bytes
  db  136, 0x0A, 0x04, 0x05, 0x00, 0x0A, 0x04, 0x05, 0x0A
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 10 bytes
  db  138, 0x02, 0x00, 0x03, 0x0A, 0x00, 0x0A, 0x00, 0x05, 0x04, 0x03
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x0A's
  db  2, 0x0A
  ; count of 10 bytes
  db  138, 0x00, 0x05, 0x04, 0x05, 0x00, 0x09, 0x03, 0x02, 0x0A, 0x04
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 4 bytes
  db  132, 0x03, 0x04, 0x05, 0x03
  ; run of 2 0x04's
  db  2, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x0A's
  db  2, 0x0A
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x05
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 4 bytes
  db  132, 0x03, 0x04, 0x05, 0x03
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 2 bytes
  db  130, 0x02, 0x00
  ; run of 2 0x0A's
  db  2, 0x0A
  ; count of 15 bytes
  db  143, 0x02, 0x03, 0x04, 0x02, 0x00, 0x05, 0x03, 0x02, 0x00, 0x04, 0x00, 0x0A, 0x04, 0x05, 0x03
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 7 bytes
  db  135, 0x02, 0x00, 0x03, 0x0A, 0x00, 0x0A, 0x02
  ; run of 45 0x00's
  db  45, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x0C
  ; run of 4 0x0D's
  db  4, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 11 0x04's
  db  11, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 34 0x00's
  db  34, 0x00
  ; count of 13 bytes
  db  141, 0x02, 0x03, 0x04, 0x05, 0x02, 0x00, 0x04, 0x03, 0x00, 0x05, 0x0A, 0x02, 0x00
  ; run of 3 0x05's
  db  3, 0x05
  ; count of 1 bytes
  db  129, 0x00
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 4 bytes
  db  132, 0x02, 0x00, 0x0A, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 4 bytes
  db  132, 0x05, 0x04, 0x05, 0x00
  ; run of 2 0x05's
  db  2, 0x05
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 10 bytes
  db  138, 0x05, 0x0A, 0x02, 0x00, 0x05, 0x0A, 0x00, 0x02, 0x0A, 0x05
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 4 bytes
  db  132, 0x05, 0x0A, 0x05, 0x02
  ; run of 3 0x05's
  db  3, 0x05
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 5 bytes
  db  133, 0x02, 0x05, 0x0A, 0x04, 0x0A
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x0A, 0x05
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 7 bytes
  db  135, 0x0A, 0x04, 0x0A, 0x05, 0x00, 0x0A, 0x04
  ; run of 2 0x02's
  db  2, 0x02
  ; count of 2 bytes
  db  130, 0x0A, 0x05
  ; run of 3 0x00's
  db  3, 0x00
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 6 bytes
  db  134, 0x0A, 0x04, 0x00, 0x02, 0x0A, 0x05
  ; run of 3 0x00's
  db  3, 0x00
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 11 bytes
  db  139, 0x02, 0x05, 0x0A, 0x05, 0x00, 0x05, 0x04, 0x05, 0x00, 0x0A, 0x05
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x0A, 0x05
  ; run of 44 0x00's
  db  44, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x0A
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 7 0x0D's
  db  7, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 2 0x0C's
  db  2, 0x0C
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 34 0x00's
  db  34, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x03, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x05
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x0A
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x05
  ; run of 15 0x00's
  db  15, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x05
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x03
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x03, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x05
  ; run of 15 0x00's
  db  15, 0x00
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x02
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x0A
  ; run of 52 0x00's
  db  52, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 9 0x0D's
  db  9, 0x0D
  ; count of 1 bytes
  db  129, 0x0E
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 4 0x0D's
  db  4, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 38 0x00's
  db  38, 0x00
  ; count of 3 bytes
  db  131, 0x03, 0x04, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x02
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x0A
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x04
  ; run of 15 0x00's
  db  15, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x05
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x03, 0x04
  ; run of 16 0x00's
  db  16, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x05
  ; run of 15 0x00's
  db  15, 0x00
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x05
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x03
  ; run of 50 0x00's
  db  50, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 12 0x0D's
  db  12, 0x0D
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 5 0x0D's
  db  5, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 36 0x00's
  db  36, 0x00
  ; run of 2 0x05's
  db  2, 0x05
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x05's
  db  2, 0x05
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 16 0x00's
  db  16, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x05's
  db  2, 0x05
  ; run of 16 0x00's
  db  16, 0x00
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 1 bytes
  db  129, 0x02
  ; run of 15 0x00's
  db  15, 0x00
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 1 bytes
  db  129, 0x02
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x05's
  db  2, 0x05
  ; run of 49 0x00's
  db  49, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 14 0x0D's
  db  14, 0x0D
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 6 0x0D's
  db  6, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x02
  ; run of 27 0x00's
  db  27, 0x00
  ; run of 6 0x02's
  db  6, 0x02
  ; run of 28 0x00's
  db  28, 0x00
  ; run of 6 0x02's
  db  6, 0x02
  ; run of 28 0x00's
  db  28, 0x00
  ; run of 3 0x02's
  db  3, 0x02
  ; count of 1 bytes
  db  129, 0x09
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 57 0x00's
  db  57, 0x00
  ; run of 5 0x02's
  db  5, 0x02
  ; count of 2 bytes
  db  130, 0x05, 0x02
  ; run of 33 0x00's
  db  33, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0E
  ; run of 15 0x0D's
  db  15, 0x0D
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 7 0x0D's
  db  7, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 16 0x00's
  db  16, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x08, 0x01
  ; run of 7 0x08's
  db  7, 0x08
  ; run of 6 0x0F's
  db  6, 0x0F
  ; count of 3 bytes
  db  131, 0x08, 0x09, 0x02
  ; run of 22 0x00's
  db  22, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x01, 0x08
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 20 0x00's
  db  20, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x01
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 2 0x08's
  db  2, 0x08
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x08's
  db  7, 0x08
  ; count of 1 bytes
  db  129, 0x09
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 6 0x08's
  db  6, 0x08
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x09
  ; run of 2 0x08's
  db  2, 0x08
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 3 bytes
  db  131, 0x08, 0x09, 0x02
  ; run of 28 0x00's
  db  28, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x0B, 0x0E
  ; run of 16 0x0D's
  db  16, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 3 0x04's
  db  3, 0x04
  ; run of 8 0x0D's
  db  8, 0x0D
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 15 0x00's
  db  15, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 18 0x0F's
  db  18, 0x0F
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 19 0x00's
  db  19, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 14 0x0F's
  db  14, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 14 0x0F's
  db  14, 0x0F
  ; count of 3 bytes
  db  131, 0x08, 0x09, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x08
  ; run of 16 0x0F's
  db  16, 0x0F
  ; count of 2 bytes
  db  130, 0x01, 0x02
  ; run of 24 0x00's
  db  24, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 18 0x0D's
  db  18, 0x0D
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 10 0x0D's
  db  10, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 15 0x00's
  db  15, 0x00
  ; run of 20 0x0F's
  db  20, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 17 0x0F's
  db  17, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x08
  ; run of 18 0x0F's
  db  18, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 18 0x0F's
  db  18, 0x0F
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 21 0x00's
  db  21, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x0A
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 20 0x0D's
  db  20, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 10 0x0D's
  db  10, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 13 0x00's
  db  13, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 20 0x0F's
  db  20, 0x0F
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 19 0x0F's
  db  19, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 13 0x00's
  db  13, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 19 0x0F's
  db  19, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 20 0x0F's
  db  20, 0x0F
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x05, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 22 0x0D's
  db  22, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 12 0x0D's
  db  12, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x05
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 11 0x0F's
  db  11, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 13 0x00's
  db  13, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 11 0x0F's
  db  11, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 20 0x0F's
  db  20, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 10 0x00's
  db  10, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 8 0x00's
  db  8, 0x00
  ; run of 10 0x0F's
  db  10, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 16 0x00's
  db  16, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 23 0x0D's
  db  23, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 13 0x0D's
  db  13, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 2 bytes
  db  130, 0x09, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 11 0x00's
  db  11, 0x00
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x09, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 10 0x00's
  db  10, 0x00
  ; run of 11 0x0F's
  db  11, 0x0F
  ; run of 2 0x08's
  db  2, 0x08
  ; count of 2 bytes
  db  130, 0x01, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 3 0x0F's
  db  3, 0x0F
  ; count of 2 bytes
  db  130, 0x08, 0x01
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x01
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 25 0x0D's
  db  25, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 15 0x0D's
  db  15, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x01, 0x08
  ; run of 3 0x0F's
  db  3, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 4 bytes
  db  132, 0x01, 0x08, 0x09, 0x02
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 1 bytes
  db  129, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 26 0x0D's
  db  26, 0x0D
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 16 0x0D's
  db  16, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 8 0x00's
  db  8, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 4 bytes
  db  132, 0x02, 0x01, 0x0F, 0x09
  ; run of 7 0x00's
  db  7, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 21 0x00's
  db  21, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 14 0x00's
  db  14, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 2 bytes
  db  130, 0x0B, 0x0E
  ; run of 28 0x0D's
  db  28, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 17 0x0D's
  db  17, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 12 0x00's
  db  12, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 21 0x00's
  db  21, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 14 0x00's
  db  14, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 30 0x0D's
  db  30, 0x0D
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 19 0x0D's
  db  19, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 11 0x00's
  db  11, 0x00
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 22 0x00's
  db  22, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 10 0x00's
  db  10, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 21 0x00's
  db  21, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 1 bytes
  db  129, 0x03
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0E
  ; run of 29 0x0D's
  db  29, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 11 0x0D's
  db  11, 0x0D
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 8 0x0D's
  db  8, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 10 0x00's
  db  10, 0x00
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 22 0x00's
  db  22, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 29 0x0D's
  db  29, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 5 0x0D's
  db  5, 0x0D
  ; run of 7 0x0C's
  db  7, 0x0C
  ; count of 2 bytes
  db  130, 0x0D, 0x0C
  ; run of 6 0x0D's
  db  6, 0x0D
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x05
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 22 0x00's
  db  22, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x08
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 14 0x0D's
  db  14, 0x0D
  ; count of 4 bytes
  db  132, 0x0C, 0x0D, 0x0C, 0x0D
  ; run of 2 0x0C's
  db  2, 0x0C
  ; count of 1 bytes
  db  129, 0x0D
  ; run of 2 0x0C's
  db  2, 0x0C
  ; count of 2 bytes
  db  130, 0x0D, 0x0C
  ; run of 4 0x0D's
  db  4, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 5 0x0D's
  db  5, 0x0D
  ; run of 11 0x0C's
  db  11, 0x0C
  ; run of 4 0x0D's
  db  4, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 8 0x00's
  db  8, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 10 0x00's
  db  10, 0x00
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 22 0x00's
  db  22, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 9 0x0F's
  db  9, 0x0F
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x0F's
  db  9, 0x0F
  ; run of 16 0x00's
  db  16, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 11 0x0D's
  db  11, 0x0D
  ; run of 15 0x0C's
  db  15, 0x0C
  ; run of 3 0x0D's
  db  3, 0x0D
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 2 bytes
  db  130, 0x0B, 0x0D
  ; run of 6 0x0C's
  db  6, 0x0C
  ; run of 2 0x0B's
  db  2, 0x0B
  ; run of 2 0x03's
  db  2, 0x03
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 4 0x0C's
  db  4, 0x0C
  ; run of 4 0x0D's
  db  4, 0x0D
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 23 0x00's
  db  23, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 16 0x00's
  db  16, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 16 0x00's
  db  16, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 11 0x0D's
  db  11, 0x0D
  ; run of 10 0x0C's
  db  10, 0x0C
  ; count of 1 bytes
  db  129, 0x0D
  ; run of 6 0x0C's
  db  6, 0x0C
  ; count of 2 bytes
  db  130, 0x0D, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 2 bytes
  db  130, 0x0B, 0x0D
  ; run of 5 0x0C's
  db  5, 0x0C
  ; run of 2 0x03's
  db  2, 0x03
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 4 0x0C's
  db  4, 0x0C
  ; count of 4 bytes
  db  132, 0x0D, 0x0C, 0x0D, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 9 0x00's
  db  9, 0x00
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 23 0x00's
  db  23, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 8 0x00's
  db  8, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 15 0x00's
  db  15, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 17 0x00's
  db  17, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 7 0x0D's
  db  7, 0x0D
  ; run of 7 0x0C's
  db  7, 0x0C
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x04
  ; run of 2 0x03's
  db  2, 0x03
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 2 0x0C's
  db  2, 0x0C
  ; count of 1 bytes
  db  129, 0x0D
  ; run of 2 0x0C's
  db  2, 0x0C
  ; count of 2 bytes
  db  130, 0x0D, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; run of 5 0x0C's
  db  5, 0x0C
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 3 bytes
  db  131, 0x0B, 0x0C, 0x0D
  ; run of 2 0x0C's
  db  2, 0x0C
  ; count of 2 bytes
  db  130, 0x0D, 0x0C
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 10 0x0F's
  db  10, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 13 0x00's
  db  13, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 22 0x00's
  db  22, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 10 0x0F's
  db  10, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 13 0x00's
  db  13, 0x00
  ; run of 10 0x0F's
  db  10, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 18 0x00's
  db  18, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 7 0x0D's
  db  7, 0x0D
  ; run of 5 0x0C's
  db  5, 0x0C
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 11 0x04's
  db  11, 0x04
  ; count of 5 bytes
  db  133, 0x03, 0x0B, 0x0C, 0x0D, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; run of 3 0x0C's
  db  3, 0x0C
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 11 0x04's
  db  11, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 3 0x0C's
  db  3, 0x0C
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 10 0x0F's
  db  10, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 22 0x00's
  db  22, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 10 0x0F's
  db  10, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 19 0x00's
  db  19, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 4 0x0D's
  db  4, 0x0D
  ; run of 7 0x0C's
  db  7, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 16 0x04's
  db  16, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0A
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 3 bytes
  db  131, 0x0B, 0x0C, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 4 bytes
  db  132, 0x0B, 0x0D, 0x0C, 0x03
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 2 0x0C's
  db  2, 0x0C
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 9 0x00's
  db  9, 0x00
  ; run of 11 0x0F's
  db  11, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x00's
  db  8, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 23 0x00's
  db  23, 0x00
  ; run of 11 0x0F's
  db  11, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 20 0x00's
  db  20, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 4 0x0D's
  db  4, 0x0D
  ; run of 3 0x0C's
  db  3, 0x0C
  ; count of 3 bytes
  db  131, 0x0D, 0x0C, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 22 0x04's
  db  22, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 5 0x0D's
  db  5, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 2 0x0B's
  db  2, 0x0B
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 3 0x0F's
  db  3, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 22 0x00's
  db  22, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 3 0x0F's
  db  3, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 21 0x00's
  db  21, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 2 0x0D's
  db  2, 0x0D
  ; run of 6 0x0C's
  db  6, 0x0C
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0E
  ; run of 4 0x0D's
  db  4, 0x0D
  ; count of 1 bytes
  db  129, 0x0E
  ; run of 2 0x0B's
  db  2, 0x0B
  ; count of 1 bytes
  db  129, 0x03
  ; run of 14 0x04's
  db  14, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 7 0x0D's
  db  7, 0x0D
  ; count of 1 bytes
  db  129, 0x0E
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 4 0x0F's
  db  4, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 22 0x00's
  db  22, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 4 0x0F's
  db  4, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 22 0x00's
  db  22, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 6 0x0C's
  db  6, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 10 0x0D's
  db  10, 0x0D
  ; count of 3 bytes
  db  131, 0x0E, 0x0B, 0x03
  ; run of 10 0x04's
  db  10, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 11 0x0D's
  db  11, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 2 bytes
  db  130, 0x08, 0x09
  ; run of 4 0x0F's
  db  4, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 21 0x00's
  db  21, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; run of 2 0x01's
  db  2, 0x01
  ; run of 3 0x0F's
  db  3, 0x0F
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 23 0x00's
  db  23, 0x00
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 4 0x0C's
  db  4, 0x0C
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0E
  ; run of 13 0x0D's
  db  13, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 11 0x04's
  db  11, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 10 0x0D's
  db  10, 0x0D
  ; count of 1 bytes
  db  129, 0x0E
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 3 bytes
  db  131, 0x08, 0x02, 0x08
  ; run of 4 0x0F's
  db  4, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 7 0x00's
  db  7, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 21 0x00's
  db  21, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 3 bytes
  db  131, 0x08, 0x00, 0x08
  ; run of 4 0x0F's
  db  4, 0x0F
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 24 0x00's
  db  24, 0x00
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 4 bytes
  db  132, 0x03, 0x0D, 0x0C, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 13 0x0D's
  db  13, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 15 0x04's
  db  15, 0x04
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 9 0x0D's
  db  9, 0x0D
  ; count of 1 bytes
  db  129, 0x0E
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 10 0x00's
  db  10, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 2 bytes
  db  130, 0x00, 0x02
  ; run of 5 0x0F's
  db  5, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 21 0x00's
  db  21, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 2 bytes
  db  130, 0x00, 0x02
  ; run of 5 0x0F's
  db  5, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 24 0x00's
  db  24, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 13 0x0D's
  db  13, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 2 0x0C's
  db  2, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 9 0x0D's
  db  9, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 3 bytes
  db  131, 0x02, 0x00, 0x09
  ; run of 5 0x0F's
  db  5, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 20 0x00's
  db  20, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 3 bytes
  db  131, 0x02, 0x00, 0x09
  ; run of 5 0x0F's
  db  5, 0x0F
  ; count of 2 bytes
  db  130, 0x08, 0x01
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 24 0x00's
  db  24, 0x00
  ; run of 10 0x04's
  db  10, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x0C
  ; run of 13 0x0D's
  db  13, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 6 0x0C's
  db  6, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0E
  ; run of 8 0x0D's
  db  8, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 15 0x0F's
  db  15, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 6 0x00's
  db  6, 0x00
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x01, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 14 0x0F's
  db  14, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x00's
  db  9, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x08
  ; run of 13 0x00's
  db  13, 0x00
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 13 0x0D's
  db  13, 0x0D
  ; count of 2 bytes
  db  130, 0x0E, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 9 0x0C's
  db  9, 0x0C
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 8 0x0D's
  db  8, 0x0D
  ; count of 1 bytes
  db  129, 0x0E
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 14 0x0F's
  db  14, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 4 bytes
  db  132, 0x01, 0x02, 0x09, 0x01
  ; run of 10 0x0F's
  db  10, 0x0F
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x0F's
  db  9, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 3 0x09's
  db  3, 0x09
  ; count of 2 bytes
  db  130, 0x01, 0x08
  ; run of 3 0x0F's
  db  3, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 13 0x0F's
  db  13, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 2 0x09's
  db  2, 0x09
  ; count of 2 bytes
  db  130, 0x02, 0x09
  ; run of 2 0x08's
  db  2, 0x08
  ; run of 3 0x0F's
  db  3, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 12 0x00's
  db  12, 0x00
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0E
  ; run of 13 0x0D's
  db  13, 0x0D
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 10 0x0C's
  db  10, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 10 0x04's
  db  10, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 8 0x0D's
  db  8, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 13 0x0F's
  db  13, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 21 0x0F's
  db  21, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 17 0x0F's
  db  17, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 4 0x00's
  db  4, 0x00
  ; run of 13 0x0F's
  db  13, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x08
  ; run of 17 0x0F's
  db  17, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 14 0x0D's
  db  14, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; run of 11 0x0C's
  db  11, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 8 0x0D's
  db  8, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 11 0x0F's
  db  11, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 13 0x00's
  db  13, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 18 0x0F's
  db  18, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 16 0x0F's
  db  16, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x00's
  db  8, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 11 0x0F's
  db  11, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 11 0x00's
  db  11, 0x00
  ; run of 17 0x0F's
  db  17, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x05
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0E
  ; run of 13 0x0D's
  db  13, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 10 0x0C's
  db  10, 0x0C
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 2 0x0C's
  db  2, 0x0C
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 7 0x0D's
  db  7, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 10 0x0F's
  db  10, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 16 0x0F's
  db  16, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 15 0x0F's
  db  15, 0x0F
  ; run of 8 0x00's
  db  8, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 10 0x0F's
  db  10, 0x0F
  ; run of 12 0x00's
  db  12, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x08
  ; run of 16 0x0F's
  db  16, 0x0F
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x0A
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 14 0x0D's
  db  14, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 10 0x0C's
  db  10, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 5 0x0C's
  db  5, 0x0C
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0E
  ; run of 6 0x0D's
  db  6, 0x0D
  ; count of 2 bytes
  db  130, 0x0E, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x08
  ; run of 11 0x0F's
  db  11, 0x0F
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 20 0x00's
  db  20, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 12 0x0F's
  db  12, 0x0F
  ; count of 2 bytes
  db  130, 0x08, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 15 0x0F's
  db  15, 0x0F
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 13 0x0D's
  db  13, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 11 0x04's
  db  11, 0x04
  ; count of 3 bytes
  db  131, 0x0B, 0x0C, 0x0D
  ; run of 5 0x0C's
  db  5, 0x0C
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 9 0x0C's
  db  9, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 3 0x0D's
  db  3, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x08's
  db  2, 0x08
  ; count of 4 bytes
  db  132, 0x0F, 0x08, 0x01, 0x02
  ; run of 20 0x00's
  db  20, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x09
  ; run of 3 0x08's
  db  3, 0x08
  ; run of 2 0x0F's
  db  2, 0x0F
  ; run of 2 0x08's
  db  2, 0x08
  ; count of 2 bytes
  db  130, 0x09, 0x02
  ; run of 24 0x00's
  db  24, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x01
  ; run of 2 0x08's
  db  2, 0x08
  ; run of 2 0x0F's
  db  2, 0x0F
  ; run of 2 0x08's
  db  2, 0x08
  ; count of 3 bytes
  db  131, 0x01, 0x09, 0x02
  ; run of 9 0x00's
  db  9, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 2 0x08's
  db  2, 0x08
  ; count of 3 bytes
  db  131, 0x0F, 0x08, 0x01
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x01
  ; run of 2 0x08's
  db  2, 0x08
  ; run of 4 0x0F's
  db  4, 0x0F
  ; run of 2 0x08's
  db  2, 0x08
  ; count of 2 bytes
  db  130, 0x01, 0x09
  ; run of 7 0x00's
  db  7, 0x00
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 12 0x0D's
  db  12, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 26 0x04's
  db  26, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 11 0x0C's
  db  11, 0x0C
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; run of 2 0x03's
  db  2, 0x03
  ; run of 9 0x04's
  db  9, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 90 0x00's
  db  90, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 51 0x00's
  db  51, 0x00
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 9 0x0D's
  db  9, 0x0D
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 4 bytes
  db  132, 0x03, 0x0C, 0x0B, 0x03
  ; run of 15 0x04's
  db  15, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 13 0x0C's
  db  13, 0x0C
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 13 0x04's
  db  13, 0x04
  ; count of 3 bytes
  db  131, 0x0A, 0x05, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 91 0x00's
  db  91, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 51 0x00's
  db  51, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 5 0x0D's
  db  5, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 4 0x0C's
  db  4, 0x0C
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 12 0x04's
  db  12, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 18 0x0C's
  db  18, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x05
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 90 0x00's
  db  90, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 53 0x00's
  db  53, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x0A
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 2 0x0D's
  db  2, 0x0D
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 9 0x0C's
  db  9, 0x0C
  ; run of 2 0x03's
  db  2, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 19 0x0C's
  db  19, 0x0C
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 90 0x00's
  db  90, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 55 0x00's
  db  55, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 15 0x04's
  db  15, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 14 0x0C's
  db  14, 0x0C
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 19 0x0C's
  db  19, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 90 0x00's
  db  90, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x01
  ; run of 56 0x00's
  db  56, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x03
  ; run of 11 0x04's
  db  11, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 17 0x0C's
  db  17, 0x0C
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 18 0x0C's
  db  18, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 11 0x04's
  db  11, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 90 0x00's
  db  90, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 58 0x00's
  db  58, 0x00
  ; count of 1 bytes
  db  129, 0x03
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 18 0x0C's
  db  18, 0x0C
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 16 0x0C's
  db  16, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 9 0x00's
  db  9, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 91 0x00's
  db  91, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 58 0x00's
  db  58, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 20 0x0C's
  db  20, 0x0C
  ; count of 1 bytes
  db  129, 0x0D
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 14 0x0C's
  db  14, 0x0C
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 2 0x0D's
  db  2, 0x0D
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x02
  ; run of 90 0x00's
  db  90, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 57 0x00's
  db  57, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x0A
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 14 0x0C's
  db  14, 0x0C
  ; count of 1 bytes
  db  129, 0x0D
  ; run of 7 0x0C's
  db  7, 0x0C
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 12 0x0C's
  db  12, 0x0C
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 5 0x0D's
  db  5, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 90 0x00's
  db  90, 0x00
  ; count of 1 bytes
  db  129, 0x08
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 54 0x00's
  db  54, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 9 0x04's
  db  9, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 19 0x0C's
  db  19, 0x0C
  ; count of 1 bytes
  db  129, 0x0D
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 10 0x0C's
  db  10, 0x0C
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 8 0x0D's
  db  8, 0x0D
  ; count of 2 bytes
  db  130, 0x0E, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x09
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 90 0x00's
  db  90, 0x00
  ; count of 1 bytes
  db  129, 0x01
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x09
  ; run of 53 0x00's
  db  53, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 12 0x04's
  db  12, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 18 0x0C's
  db  18, 0x0C
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 8 0x0C's
  db  8, 0x0C
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 12 0x0D's
  db  12, 0x0D
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 90 0x00's
  db  90, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x0F's
  db  7, 0x0F
  ; count of 1 bytes
  db  129, 0x08
  ; run of 51 0x00's
  db  51, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 16 0x04's
  db  16, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 15 0x0C's
  db  15, 0x0C
  ; count of 1 bytes
  db  129, 0x0D
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 6 0x0C's
  db  6, 0x0C
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 15 0x0D's
  db  15, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 91 0x00's
  db  91, 0x00
  ; run of 8 0x0F's
  db  8, 0x0F
  ; run of 49 0x00's
  db  49, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x0A
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 6 bytes
  db  134, 0x03, 0x0B, 0x0E, 0x0D, 0x0B, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 14 0x0C's
  db  14, 0x0C
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 5 0x0C's
  db  5, 0x0C
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0E
  ; run of 14 0x0D's
  db  14, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x0B
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x09's
  db  7, 0x09
  ; run of 91 0x00's
  db  91, 0x00
  ; run of 8 0x09's
  db  8, 0x09
  ; run of 48 0x00's
  db  48, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 7 0x0D's
  db  7, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 11 0x0C's
  db  11, 0x0C
  ; count of 1 bytes
  db  129, 0x0D
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 4 0x0C's
  db  4, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0E
  ; run of 15 0x0D's
  db  15, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 32 0x00's
  db  32, 0x00
  ; count of 1 bytes
  db  129, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 10 0x0D's
  db  10, 0x0D
  ; count of 2 bytes
  db  130, 0x0E, 0x03
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 10 0x0C's
  db  10, 0x0C
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 3 0x0C's
  db  3, 0x0C
  ; count of 1 bytes
  db  129, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 16 0x0D's
  db  16, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x05
  ; run of 37 0x00's
  db  37, 0x00
  ; count of 6 bytes
  db  134, 0x02, 0x0A, 0x04, 0x03, 0x0A, 0x05
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x03
  ; run of 100 0x00's
  db  100, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 12 0x0D's
  db  12, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 6 0x0C's
  db  6, 0x0C
  ; count of 1 bytes
  db  129, 0x0D
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 3 bytes
  db  131, 0x0C, 0x0B, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 17 0x0D's
  db  17, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 39 0x00's
  db  39, 0x00
  ; count of 7 bytes
  db  135, 0x0A, 0x03, 0x05, 0x02, 0x05, 0x04, 0x05
  ; run of 16 0x00's
  db  16, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x02
  ; run of 99 0x00's
  db  99, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 12 0x0D's
  db  12, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 5 0x0C's
  db  5, 0x0C
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0E
  ; run of 16 0x0D's
  db  16, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 40 0x00's
  db  40, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x05
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 17 0x00's
  db  17, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 32 0x00's
  db  32, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 39 0x00's
  db  39, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 27 0x00's
  db  27, 0x00
  ; count of 2 bytes
  db  130, 0x09, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 13 0x0D's
  db  13, 0x0D
  ; count of 2 bytes
  db  130, 0x0E, 0x0B
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 3 0x0C's
  db  3, 0x0C
  ; run of 10 0x04's
  db  10, 0x04
  ; run of 17 0x0D's
  db  17, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x02
  ; run of 28 0x00's
  db  28, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 3 bytes
  db  131, 0x0A, 0x00, 0x05
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 6 bytes
  db  134, 0x03, 0x00, 0x05, 0x04, 0x05, 0x0A
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 3 bytes
  db  131, 0x05, 0x00, 0x0A
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 3 bytes
  db  131, 0x0A, 0x03, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 3 0x00's
  db  3, 0x00
  ; run of 2 0x04's
  db  2, 0x04
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 3 bytes
  db  131, 0x03, 0x04, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; run of 6 0x04's
  db  6, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x03
  ; run of 3 0x04's
  db  3, 0x04
  ; run of 28 0x00's
  db  28, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 15 0x0D's
  db  15, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 9 0x04's
  db  9, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 15 0x0D's
  db  15, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x0B
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x02
  ; run of 29 0x00's
  db  29, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 3 0x02's
  db  3, 0x02
  ; count of 4 bytes
  db  132, 0x00, 0x02, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x02, 0x05, 0x00, 0x0A, 0x04
  ; run of 2 0x0A's
  db  2, 0x0A
  ; count of 17 bytes
  db  145, 0x05, 0x02, 0x00, 0x02, 0x04, 0x05, 0x00, 0x05, 0x04, 0x05, 0x00, 0x05, 0x04, 0x05, 0x00, 0x02
  db       0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 1 bytes
  db  129, 0x02
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 2 0x02's
  db  2, 0x02
  ; count of 1 bytes
  db  129, 0x05
  ; run of 2 0x03's
  db  2, 0x03
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 8 bytes
  db  136, 0x05, 0x04, 0x05, 0x02, 0x00, 0x05, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 5 bytes
  db  133, 0x02, 0x0A, 0x04, 0x00, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x0A's
  db  2, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 6 bytes
  db  134, 0x04, 0x0A, 0x00, 0x02, 0x03, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x03's
  db  2, 0x03
  ; count of 4 bytes
  db  132, 0x02, 0x00, 0x0A, 0x03
  ; run of 28 0x00's
  db  28, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x0A
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0E
  ; run of 14 0x0D's
  db  14, 0x0D
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 15 0x04's
  db  15, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 15 0x0D's
  db  15, 0x0D
  ; count of 2 bytes
  db  130, 0x0B, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 30 0x00's
  db  30, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 6 0x00's
  db  6, 0x00
  ; run of 2 0x0A's
  db  2, 0x0A
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 1 bytes
  db  129, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 5 bytes
  db  133, 0x04, 0x05, 0x00, 0x0A, 0x04
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 6 bytes
  db  134, 0x05, 0x04, 0x02, 0x00, 0x03, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 3 bytes
  db  131, 0x09, 0x04, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 4 bytes
  db  132, 0x0A, 0x03, 0x05, 0x03
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 6 bytes
  db  134, 0x02, 0x04, 0x00, 0x02, 0x04, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x02
  ; run of 29 0x00's
  db  29, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x0A
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 14 0x0D's
  db  14, 0x0D
  ; count of 2 bytes
  db  130, 0x0E, 0x0B
  ; run of 12 0x04's
  db  12, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 14 0x0D's
  db  14, 0x0D
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 31 0x00's
  db  31, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 5 0x0A's
  db  5, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 2 0x0A's
  db  2, 0x0A
  ; count of 3 bytes
  db  131, 0x04, 0x05, 0x00
  ; run of 2 0x0A's
  db  2, 0x0A
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 4 bytes
  db  132, 0x04, 0x0A, 0x02, 0x04
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 10 bytes
  db  138, 0x0A, 0x04, 0x02, 0x00, 0x03, 0x0A, 0x00, 0x02, 0x04, 0x0A
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x0A
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 5 bytes
  db  133, 0x04, 0x05, 0x02, 0x04, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x04
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 1 bytes
  db  129, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x05
  ; run of 31 0x00's
  db  31, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x0A
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0B
  ; run of 15 0x0D's
  db  15, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 10 0x04's
  db  10, 0x04
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 13 0x0D's
  db  13, 0x0D
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 33 0x00's
  db  33, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x03
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 4 bytes
  db  132, 0x05, 0x04, 0x0A, 0x05
  ; run of 2 0x0A's
  db  2, 0x0A
  ; count of 4 bytes
  db  132, 0x04, 0x00, 0x05, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 5 bytes
  db  133, 0x04, 0x05, 0x00, 0x0A, 0x03
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x05
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 6 bytes
  db  134, 0x03, 0x0A, 0x00, 0x02, 0x04, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x0A
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 6 bytes
  db  134, 0x05, 0x04, 0x02, 0x00, 0x03, 0x0A
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x04
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 1 bytes
  db  129, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x0A
  ; run of 34 0x00's
  db  34, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 14 0x0D's
  db  14, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 10 0x0D's
  db  10, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 3 bytes
  db  131, 0x03, 0x0A, 0x02
  ; run of 34 0x00's
  db  34, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 3 0x00's
  db  3, 0x00
  ; run of 2 0x03's
  db  2, 0x03
  ; count of 3 bytes
  db  131, 0x00, 0x05, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 6 bytes
  db  134, 0x04, 0x05, 0x00, 0x0A, 0x04, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 4 bytes
  db  132, 0x05, 0x00, 0x03, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; run of 2 0x0A's
  db  2, 0x0A
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 3 bytes
  db  131, 0x0A, 0x04, 0x0A
  ; run of 3 0x00's
  db  3, 0x00
  ; run of 2 0x0A's
  db  2, 0x0A
  ; count of 4 bytes
  db  132, 0x00, 0x02, 0x04, 0x02
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x03
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x03
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x04
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 1 bytes
  db  129, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 36 0x00's
  db  36, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 8 0x04's
  db  8, 0x04
  ; run of 2 0x03's
  db  2, 0x03
  ; run of 12 0x0D's
  db  12, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 10 0x04's
  db  10, 0x04
  ; count of 1 bytes
  db  129, 0x0B
  ; run of 7 0x0D's
  db  7, 0x0D
  ; count of 1 bytes
  db  129, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x0A, 0x02
  ; run of 37 0x00's
  db  37, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x03
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 6 bytes
  db  134, 0x0A, 0x04, 0x05, 0x0A, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x04, 0x03, 0x0A
  ; run of 2 0x04's
  db  2, 0x04
  ; count of 7 bytes
  db  135, 0x0A, 0x00, 0x04, 0x0A, 0x03, 0x0A, 0x04
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x03
  ; run of 2 0x0A's
  db  2, 0x0A
  ; count of 4 bytes
  db  132, 0x03, 0x02, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x05
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 6 bytes
  db  134, 0x03, 0x0A, 0x00, 0x0A, 0x04, 0x0A
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x05
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 1 bytes
  db  129, 0x04
  ; run of 2 0x05's
  db  2, 0x05
  ; count of 1 bytes
  db  129, 0x04
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x05
  ; run of 38 0x00's
  db  38, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x0A
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 8 0x0D's
  db  8, 0x0D
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 5 0x04's
  db  5, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x0C
  ; run of 2 0x0D's
  db  2, 0x0D
  ; count of 2 bytes
  db  130, 0x0C, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x02
  ; run of 39 0x00's
  db  39, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x0A
  ; run of 2 0x05's
  db  2, 0x05
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x0A
  ; run of 3 0x05's
  db  3, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 4 bytes
  db  132, 0x05, 0x0A, 0x05, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 4 bytes
  db  132, 0x05, 0x0A, 0x05, 0x00
  ; run of 2 0x05's
  db  2, 0x05
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x02
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x0A
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 6 bytes
  db  134, 0x02, 0x04, 0x05, 0x00, 0x0A, 0x03
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x05
  ; run of 4 0x00's
  db  4, 0x00
  ; count of 7 bytes
  db  135, 0x05, 0x0A, 0x00, 0x05, 0x00, 0x0A, 0x04
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 6 bytes
  db  134, 0x02, 0x04, 0x02, 0x00, 0x04, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x05
  ; run of 40 0x00's
  db  40, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x0A
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 2 0x0C's
  db  2, 0x0C
  ; run of 4 0x0D's
  db  4, 0x0D
  ; count of 1 bytes
  db  129, 0x0C
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; run of 2 0x03's
  db  2, 0x03
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 40 0x00's
  db  40, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x03
  ; run of 45 0x00's
  db  45, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x04, 0x05
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 2 0x04's
  db  2, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x02
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 13 0x00's
  db  13, 0x00
  ; count of 4 bytes
  db  132, 0x0A, 0x04, 0x0A, 0x04
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x04, 0x0A
  ; run of 2 0x00's
  db  2, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x04
  ; run of 43 0x00's
  db  43, 0x00
  ; count of 3 bytes
  db  131, 0x02, 0x0A, 0x03
  ; run of 8 0x04's
  db  8, 0x04
  ; run of 2 0x03's
  db  2, 0x03
  ; count of 3 bytes
  db  131, 0x0C, 0x0D, 0x03
  ; run of 4 0x04's
  db  4, 0x04
  ; run of 5 0x00's
  db  5, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 13 0x04's
  db  13, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 42 0x00's
  db  42, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x03
  ; run of 45 0x00's
  db  45, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 2 bytes
  db  130, 0x03, 0x0A
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 4 0x04's
  db  4, 0x04
  ; count of 2 bytes
  db  130, 0x03, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 14 0x00's
  db  14, 0x00
  ; count of 3 bytes
  db  131, 0x05, 0x04, 0x03
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 2 bytes
  db  130, 0x02, 0x03
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x02
  ; run of 3 0x00's
  db  3, 0x00
  ; count of 1 bytes
  db  129, 0x03
  ; run of 3 0x04's
  db  3, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 46 0x00's
  db  46, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x03
  ; run of 14 0x04's
  db  14, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x03
  ; run of 8 0x04's
  db  8, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 44 0x00's
  db  44, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 48 0x00's
  db  48, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 6 0x00's
  db  6, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 6 0x00's
  db  6, 0x00
  ; run of 2 0x02's
  db  2, 0x02
  ; run of 8 0x00's
  db  8, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 18 0x00's
  db  18, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 11 0x00's
  db  11, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 7 0x00's
  db  7, 0x00
  ; count of 1 bytes
  db  129, 0x02
  ; run of 50 0x00's
  db  50, 0x00
  ; count of 2 bytes
  db  130, 0x05, 0x0A
  ; run of 11 0x04's
  db  11, 0x04
  ; count of 1 bytes
  db  129, 0x0A
  ; run of 10 0x00's
  db  10, 0x00
  ; count of 1 bytes
  db  129, 0x05
  ; run of 6 0x04's
  db  6, 0x04
  ; count of 1 bytes
  db  129, 0x05
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 83 0x00's
  db  83, 0x00
  ; count of 2 bytes
  db  130, 0x0A, 0x03
  ; run of 7 0x04's
  db  7, 0x04
  ; count of 1 bytes
  db  129, 0x03
  ; run of 13 0x00's
  db  13, 0x00
  ; count of 5 bytes
  db  133, 0x02, 0x05, 0x0A, 0x05, 0x02
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 87 0x00's
  db  87, 0x00
  ; count of 6 bytes
  db  134, 0x02, 0x05, 0x03, 0x04, 0x0A, 0x05
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 128 0x00's
  db  128, 0x00
  ; run of 42 0x00's
  db  42, 0x00

.end
