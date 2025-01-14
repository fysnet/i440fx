comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: misc.asm                                                           *
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
*   misc include file                                                      *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.15                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 8 Dec 2024                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; freeze the system
; on entry:
;  nothing
; on return
;  does not return
freeze     proc near
@@:        hlt
           jmp  short @b
           .noret
freeze     endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; on entry:
;  al = byte to convert
; on return
;  al = byte converted
bcd_to_bin proc near uses bx
           mov  bl,al
           and  bl,0x0F          ; bl has low digit
           shr  al,4             ; al has high digit
           mov  bh,10
           mul  bh               ; multiply high digit by 10 (result in AX)
           add  al,bl            ; then add low digit
           ret
bcd_to_bin endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; on entry:
;  al = byte to convert
; on return
;  al = byte converted
bin_to_bcd proc near uses bx
           mov  bh,ah            ; preserved ah
           xor  ah,ah
           mov  bl,10
           div  bl
           shl  al,4
           add  al,ah
           mov  ah,bh            ; restore ah
           ret
bin_to_bcd endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; compare two strings
; on entry:
;  stack contains: (cdecl)
;    t_off,  t_seg,  s_off,   s_seg,  count
;    [bp+4], [bp+6], [bp+8], [bp+10], [bp+12]
; on return
;  ax = 0 = match
strncmp    proc near ; don't add anything here
           push bp
           mov  bp,sp

           push cx
           push si
           push di
           push ds
           push es

           mov  si,[bp+8]
           mov  ax,[bp+10]
           mov  ds,ax
           mov  di,[bp+4]
           mov  ax,[bp+6]
           mov  es,ax
           mov  cx,[bp+12]
           mov  ax,1             ; assume no match
           repe
             cmpsb
           jnz  short @f
           xor  ax,ax            ; is a match

@@:        pop  es
           pop  ds
           pop  di
           pop  si
           pop  cx

           mov  sp,bp
           pop  bp
           ret
strncmp    endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; clears a buffer
; on entry:
;  stack contains: (cdecl)
;    t_off,  t_seg,  count
;    [bp+4], [bp+6], [bp+8]
; on return
;  ax = 0 = match
misc_clear_buffer proc near ; don't add anything here
           push bp
           mov  bp,sp

           push es
           push di
           push cx
           push ax
           
           xor  al,al
           mov  di,[bp+4]
           mov  es,[bp+6]
           mov  cx,[bp+8]
           rep
             stosb
           
           pop  ax
           pop  cx
           pop  di
           pop  es

           mov  sp,bp
           pop  bp
           ret
misc_clear_buffer endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; standard memory copy (16-bit using segmentation)
; on entry:
;  stack contains: (cdecl)
;    t_off,  t_seg,  s_off,   s_seg,  count
;    [bp+4], [bp+6], [bp+8], [bp+10], [bp+12]
; on return
;  nothing
memcpy16   proc near ; don't add anything here
           push bp
           mov  bp,sp

           push cx
           push si
           push di
           push ds
           push es

           mov  si,[bp+8]
           mov  ax,[bp+10]
           mov  ds,ax
           mov  di,[bp+4]
           mov  ax,[bp+6]
           mov  es,ax
           mov  cx,[bp+12]
           
           rep
             movsb
           
           pop  es
           pop  ds
           pop  di
           pop  si
           pop  cx

           mov  sp,bp
           pop  bp
           ret
memcpy16   endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; standard memory copy (32-bit using flat address space)
; on entry:
;  stack contains: (cdecl)
;    t_addr, s_addr,  count
;    [bp+4], [bp+8], [bp+12]
; on return
;  nothing
memcpy32   proc near ; don't add anything here
           push bp
           mov  bp,sp

           push ecx
           push esi
           push edi
           push ax

           mov  esi,[bp+8]
           mov  edi,[bp+4]
           mov  ecx,[bp+12]

@@:        mov  al,fs:[esi]
           inc  esi
           mov  fs:[edi],al
           inc  edi
           .adsize
           loop @b
           
           pop  ax
           pop  edi
           pop  esi
           pop  ecx

           mov  sp,bp
           pop  bp
           ret
memcpy32   endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; standard memory compare (32-bit using flat address space)
; on entry:
;  stack contains: (cdecl)
;    t_addr, s_addr,  count
;    [bp+4], [bp+8], [bp+12]
; on return
;  ax = 0 = memory is equal
memcmp32   proc near ; don't add anything here
           push bp
           mov  bp,sp

           push ecx
           push esi
           push edi

           mov  esi,[bp+8]
           mov  edi,[bp+4]
           mov  ecx,[bp+12]
           dec  edi

@@:        inc  edi
           mov  al,fs:[esi]
           inc  esi
           cmp  fs:[edi],al
           .adsize
           loope @b
           
           ; was the last one a match
           ;cmp  fs:[edi],al
           mov  ax,1
           jne  short @f
           xor  ax,ax
           
@@:        pop  edi
           pop  esi
           pop  ecx

           mov  sp,bp
           pop  bp
           ret
memcmp32   endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; clear a buffer (32-bit using flat address space)
; on entry:
;  ax = size of buffer
;  fs:edi-> buffer to clear
; on return
;  nothing
memset32   proc near uses ax cx edi
           mov  cx,ax
           xor  al,al
@@:        mov  fs:[edi],al
           inc  edi
           loop @b
           ret
memset32   endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; calculate the crc of a 'table'
; on entry:
;  fs:edi-> table
;  ax = size of 'table'
; on return
;  al = crc
; destroys none
calc_checksum proc near uses cx edi
           mov  cx,ax
           xor  al,al
@@:        add  al,fs:[edi]
           inc  edi
           loop @b
           neg  al
           ret
calc_checksum endp

.if (!DO_INIT_BIOS32)
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; bswap a 32-bit (eax) from little-endian to big-endian (or visa-versa)
; this is used if we don't have a 486+
; on entry:
;  eax = value to bswap
; on return
;  eax = bswapped value
; destroys none
_bswap     proc near
           ;11 22 33 44
           ror  eax,8
           ;44 11 22 33
           xchg ah,al
           ;44 11 33 22
           ror  eax,16
           ;33 22 44 11
           xchg ah,al
           ;33 22 11 44
           ror  eax,8
           ;44 33 22 11
           ret
_bswap     endp

.endif

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; delays count milliseconds
; on entry:
;  eax = count of ms
;   (if eax > 0x003FFFFF, this will not work correctly)
; on return
;  nothing
; destroys none
mdelay     proc near uses eax cx dx
           shl  eax,10           ; convert from mS to uS
           mov  dx,ax            ; cx:dx = uS
           shr  eax,16
           mov  cx,ax
           mov  ah,0x86
           int  15h           
           ret
mdelay     endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; delays count microseconds
; on entry:
;  eax = count of us
; on return
;  nothing
; destroys none
udelay     proc near uses eax cx dx
           mov  dx,ax            ; cx:dx = uS
           shr  eax,16
           mov  cx,ax
           mov  ah,0x86
           int  15h           
           ret
udelay     endp

.end
