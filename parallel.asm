comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: parallel.asm                                                       *
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
*   parallel include file                                                  *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.16                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 8 Dec 2024                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|


; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; detect a parallel port
; on entry:
;  cl = timeout value
;  dx = port value
;  bx = index (0 or 1)
; on return
;  bx = new index
; destroys all general
detect_parport proc near
           push dx
           add  dx,2
           in   al,dx
           and  al,0xDF          ; clear input mode
           out  dx,al
           pop  dx
           mov  al,0xAA
           out  dx,al
           in   al,dx
           cmp  al,0xAA
           jne  short @f
           push bx
           shl  bx,1
           mov  es:[bx+0x408],dx ; Parallel I/O address
           pop  bx
           mov  es:[bx+0x478],cl ; Parallel printer timeout
           inc  bx
@@:        ret
detect_parport endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the parallel port(s)
; on entry:
;  nothing
; on return
;  nothing
; destroys all general
init_parallel proc near
           xor  bx,bx
           mov  cl,20            ; timeout value
           mov  dx,0x378         ; Parallel I/O address, port 1
           call detect_parport
           mov  dx,0x278         ; Parallel I/O address, port 2
           call detect_parport
           shl  bx,14
           mov  ax,es:[0x410]    ; Equipment word bits 14..15 determine # parallel ports
           and  ax,0x3FFF
           or   ax,bx            ; set number of parallel ports
           mov  es:[0x410],ax
           ret
init_parallel endp

.end
