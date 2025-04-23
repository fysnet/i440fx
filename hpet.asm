comment |*******************************************************************
*  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: hpet.asm                                                           *
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
*   hpet include file                                                      *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.16                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 22 Apr 2025                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

.if DO_INIT_BIOS32

HPET_PHYS_ADDRESS    equ  0xFED00000

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; detect if an hpet is available
; on entry:
;  ds -> EBDA
;  fs -> 0x00000000:0xFFFFFFFF
; on return
;  nothing
; destroys none
det_hpet_init proc near uses ax edi
           
          ;mov  byte [EBDA_DATA->found_hpet],0
           mov  edi,HPET_PHYS_ADDRESS
           mov  eax,fs:[edi]
           shr  eax,16
           cmp  ax,0x8086
           jne  short @f
           mov  byte [EBDA_DATA->found_hpet],1

@@:        ret
det_hpet_init endp

.endif

.end
