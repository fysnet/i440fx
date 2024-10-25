comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: tcg.asm                                                            *
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
*   tcg include file                                                       *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.08                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 25 Oct 2024                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Trusted Computing services function
; on entry:
;  stack currently has (after we set bp):
;   flags    cs      ip      es      ds
;  [bp+44] [bp+42] [bp+40] [bp+38] [bp+36]
;    edi     esi     ebp     esp     ebx     edx     ecx     eax
;  [bp+04] [bp+08] [bp+12] [bp+16] [bp+20] [bp+24] [bp+28] [bp+32]
; on return
;  nothing
; destroys nothing
tcgbios_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           ; sub  sp,4

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; TCG BIOS (Trusted Computing Group)
           ; ah = 0xBB
           ; al = service

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        ;cmp  al,0x??
           ;jne  short @f

           ; TCG PC Client Specific Implementation Specification For Conventional BIOS
           ;  (Version 1.20 FINAL/Revision 1.00/July 13, 2005/For TPM Family 1.2; Level 2)
           ; http://www.trustedcomputinggroup.org/
           ; https://learn.microsoft.com/en-us/previous-versions/dd424551(v=msdn.10)?redirectedfrom=MSDN
           ; https://learn.microsoft.com/en-us/previous-versions/windows/hardware/wlk/ff567624(v=vs.85)
           ; https://thestarman.pcministry.com/asm/mbr/W7MBR.htm

           ; eax != 0 = not supported ????
           mov  dword REG_EAX,0x12345678

           ; mov  dword REG_EBX,0x41504354   ; ebx = 'TCPA' if supported
           ; mov  word REG_CX,0x0102         ; version 1.2

           ;jmp  short tcg_int1A_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown function call
@@:
           
           ;mov  bx,$
           ;mov  ax,0x1ABB
           ;call unsupported
           

tcg_int1A_fail:
           or   word REG_FLAGS,0x0001

           mov  sp,bp
           pop  bp
           ret

tcg_int1A_success:
           mov  byte REG_AH,0x00 ; success
           and  word REG_FLAGS,(~0x0001)

           mov  sp,bp
           pop  bp
           ret
tcgbios_function endp

.end
