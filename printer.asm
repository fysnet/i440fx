comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: printer.asm                                                        *
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
*   printer include file                                                   *
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

srvs_17_unknown_call_str  db 13,10,'services_17: Unknown call 0x%02X',0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; The printer services function
; on entry:
;  ds = 0x0040
;  stack currently has (after we set bp):
;   flags    cs      ip      es      ds
;  [bp+44] [bp+42] [bp+40] [bp+38] [bp+36]
;    edi     esi     ebp     esp     ebx     edx     ecx     eax
;  [bp+04] [bp+08] [bp+12] [bp+16] [bp+20] [bp+24] [bp+28] [bp+32]
; on return
;  nothing
; destroys nothing
int17_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           ;sub  sp,4
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; make sure dx < 3
           mov  bx,REG_DX
           cmp  bx,0x03
           jnb  short int17_func_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get the timeout value
           mov  cl,[bx+0x78]
           xor  ch,ch

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get the port address
           shl  bx,1
           mov  dx,[bx+0x08]
           or   dx,dx
           jz   short int17_func_fail

           ; service call
           mov  ah,REG_AH
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; write character
           cmp  ah,0x00          ; 
           jne  short @f
           
           mov  al,REG_AL
           out  dx,al
           add  dx,2
           in   al,dx
           or   al,0x01
           out  dx,al
           nop
           and  al,0xFE
           out  dx,al
           
           dec  dx
int17_func_00_timeout:
           in   al,dx
           test al,0x40
           jnz  short int17_func_02
           loop int17_func_00_timeout
           jmp  short int17_func_02

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize port
@@:        cmp  ah,0x01          ; 
           jne  short @f

           add  dx,2
           in   al,dx
           and  al,(~0x04)
           out  dx,al
           nop
           or   al,0x04
           out  dx,al

           jmp  short int17_func_02

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get printer status
@@:        cmp  ah,0x02          ; 
           jne  short @f
int17_func_02:
           ; return the status in ah
           mov  dx,REG_DX
           inc  dx
           in   al,dx
           xor  al,0x48          ; toggle bits 6 and 3  ?????
           ; did we timeout (cx = 0 if timed out)
           or   cx,cx
           jnz  short int17_func_02_ret
           or   al,0x01
int17_func_02_ret:
           mov  REG_AH,al
           jmp  short int17_func_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown function call
@@:        push ds
           push cs
           pop  ds
           shr  ax,8
           push ax
           mov  si,offset srvs_17_unknown_call_str
           call bios_printf
           add  sp,2
           pop  ds

           mov  byte REG_AH,0x86
           ;jmp  short int17_func_fail

int17_func_fail:
           or   word REG_FLAGS,0x0001
           mov  sp,bp
           pop  bp
           ret

int17_func_success:
           and  word REG_FLAGS,(~0x0001)
           mov  sp,bp
           pop  bp
           ret
int17_function endp

.end
