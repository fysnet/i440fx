comment |*******************************************************************
*  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: apm.asm                                                            *
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
*   apm include file                                                       *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.15                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 3 Jan 2025                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

apm_poweroff_string  db  'Shutdown',0
apm_suspend_string   db  'Suspend',0
apm_standby_string   db  'Standby',0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; 16-bit real/pmode out string
; on entry:
;  dx = port value
;  ax = string offset
; on return
;  nothing
; destroys none
apm_send_rm_string proc near uses ax bx
           mov  bx,ax
@@:        mov  al,cs:[bx]
           or   al,al
           jz   short @f
           out  dx,al
           inc  bx
           jmp  short @b
@@:        ret
apm_send_rm_string endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; real_mode apm int 15 service call handler
; on entry:
;  general registers
; on return
;  general registers
; destroys none
apm_do_realmode proc far

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; ah = service 53h, al = subservice
           pushf                 ; 16-bit protected mode needs the flags preserved

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM installation check
           cmp  al,0x00
           jne  short @f

           mov  ax,0x0102        ; version 1.2
           mov  bx,0x504D        ; 'PM'
           mov  cx,((1<<0) | (1<<1)) ; 16-bit and 32-bit interface supported
           jmp  int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM connect realmode interface
@@:        cmp  al,0x01
           jne  short @f
           jmp  int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM connect 16-bit pmode interface
@@:        cmp  al,0x02
           jne  short @f

           mov  bx,offset apm_do_realmode
           mov  ax,BIOS_BASE
           mov  si,0xFFF0
           mov  cx,BIOS_BASE
           mov  di,0xFFF0
           jmp  int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM connect 32-bit pmode interface
@@:        cmp  al,0x03
           jne  short @f

           mov  ax,BIOS_BASE
           mov  ebx,offset apm_do_pmode32
           mov  cx,BIOS_BASE
           mov  esi,0xFFF0FFF0
           mov  dx,BIOS_BASE
           mov  di,0xFFF0
           jmp  int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM disconnect 
@@:        cmp  al,0x04
           jne  short @f
           jmp  int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM CPU idle
@@:        cmp  al,0x05
           jne  short @f
           
           sti
           hlt
           
           jmp  int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM CPU busy
@@:        cmp  al,0x06
           jne  short @f

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  int15_apm_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM set power state
@@:        cmp  al,0x07
           jne  short @f

           cmp  bx,0x01
           jne  int15_apm_success_noah

           ; turn off system?
           cmp  cx,0x0003
           jne  short apm_real_07_03
           cli
           mov  dx,0x8900
           mov  ax,offset apm_poweroff_string
           call apm_send_rm_string
apm_real_07_00:
           hlt
           jmp  short apm_real_07_00

apm_real_07_03:
           ; suspend system?
           cmp  cx,0x0002
           jne  short apm_real_07_02
           push dx
           mov  dx,0x8900
           mov  ax,offset apm_suspend_string
           call apm_send_rm_string
           pop  dx
           jmp  short int15_apm_success_noah

apm_real_07_02:
           ; standby system?
           cmp  cx,0x0001
           jne  short int15_apm_success_noah
           push dx
           mov  dx,0x8900
           mov  ax,offset apm_standby_string
           call apm_send_rm_string
           pop  dx
           jmp  short int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Enable/Disable
@@:        cmp  al,0x08
           jne  short @f

           jmp  short int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Restore power on defaults
@@:        cmp  al,0x09
           jne  short @f

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  short int15_apm_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Get Power Status
@@:        cmp  al,0x0A
           jne  short @f

           mov  bx,0x01FF
           mov  cx,0x80FF
           mov  dx,0xFFFF
           xor  si,si

           jmp  short int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Get PM Event
@@:        cmp  al,0x0B
           jne  short @f

           mov  ah,0x80
           jmp  short int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Get Power Status
@@:        cmp  al,0x0C
           jne  short @f

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  short int15_apm_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Enable/Disable Device PM
@@:        cmp  al,0x0D
           jne  short @f

           ; freedos calls this one
           ; xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  short int15_apm_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Get Driver Version
@@:        cmp  al,0x0E
           jne  short @f

           mov  ax,0x0102
           jmp  short int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Engage/Disengae
@@:        cmp  al,0x0F
           jne  short @f
           jmp  short int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Get Capabilities
@@:        cmp  al,0x10
           jne  short @f

           mov  bl,0x00
           mov  cx,0x0000
           jmp  short int15_apm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM unknown/unsupported call
@@:
           ;xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

int15_apm_fail:
           mov  ah,0x00
int15_apm_fail_noah:
           popf                  ; 16-bit protected mode needs the flags preserved
           stc
int15_apm_fail_ret:
           retf

int15_apm_success:
           mov  ah,0x00
int15_apm_success_noah:
           popf                  ; 16-bit protected mode needs the flags preserved
           clc
int15_apm_success_ret:
           retf
apm_do_realmode  endp


; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; this is the pmode service
.pmode

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; 32-bit pmode out string
; on entry:
;  dx = port value
;  ax = string offset
; on return
;  nothing
; destroys none
apm_send_pm_string proc near uses ax bx
           mov  bx,ax
@@:        mov  al,cs:[bx]
           or   al,al
           jz   short @f
           out  dx,al
           inc  bx
           jmp  short @b
@@:        ret
           ret
apm_send_pm_string endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; real_mode apm int 15 service call handler
; 16-bit pmode apm int 15 service call handler
; on entry:
;  general registers
; on return
;  general registers
; destroys none
apm_do_pmode32 proc far
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; ah = service 53h, al = subservice
           pushfd                ; 32-bit protected mode needs the flags preserved
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM installation check
           cmp  al,0x00
           jne  short @f

           mov  ax,0x0102        ; version 1.2
           mov  bx,0x504D        ; 'PM'
           mov  cx,((1<<0) | (1<<1)) ; 16-bit and 32-bit interface supported
           jmp  int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM connect realmode interface
@@:        cmp  al,0x01
           jne  short @f
           jmp  int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM connect 16-bit pmode interface
@@:        cmp  al,0x02
           jne  short @f

           mov  bx,offset apm_do_realmode
           mov  ax,BIOS_BASE
           mov  si,0xFFF0
           mov  cx,BIOS_BASE
           mov  di,0xFFF0
           jmp  int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM connect 32-bit pmode interface
@@:        cmp  al,0x03
           jne  short @f

           mov  ebx,offset apm_do_pmode32
           mov  ax,BIOS_BASE
           mov  cx,BIOS_BASE
           mov  esi,0xFFF0FFF0
           mov  dx,BIOS_BASE
           mov  di,0xFFF0
           jmp  int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM disconnect 
@@:        cmp  al,0x04
           jne  short @f
           jmp  int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM CPU idle
@@:        cmp  al,0x05
           jne  short @f

           sti
           hlt

           jmp  int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM CPU busy
@@:        cmp  al,0x06
           jne  short @f

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  int15_apm_pm_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM set power state
@@:        cmp  al,0x07
           jne  short @f

           cmp  bx,0x01
           jne  int15_apm_pm_success_noah

           ; turn off system?
           cmp  cx,0x0003
           jne  short apm_pmode_07_03
           cli
           mov  dx,0x8900
           mov  ax,offset apm_poweroff_string
           call apm_send_pm_string
apm_pmode_07_00:
           hlt
           jmp  short apm_pmode_07_00

apm_pmode_07_03:
           ; suspend system?
           cmp  cx,0x0002
           jne  short apm_pmode_07_02
           push dx
           mov  dx,0x8900
           mov  ax,offset apm_suspend_string
           call apm_send_pm_string
           pop  dx
           jmp  short int15_apm_pm_success_noah

apm_pmode_07_02:
           ; standby system?
           cmp  cx,0x0001
           jne  short int15_apm_pm_success_noah
           push dx
           mov  dx,0x8900
           mov  ax,offset apm_standby_string
           call apm_send_pm_string
           pop  dx
           jmp  short int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Enable/Disable
@@:        cmp  al,0x08
           jne  short @f

           jmp  short int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Restore power on defaults
@@:        cmp  al,0x09
           jne  short @f

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  short int15_apm_pm_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Get Power Status
@@:        cmp  al,0x0A
           jne  short @f

           mov  bx,0x01FF
           mov  cx,0x80FF
           mov  dx,0xFFFF
           xor  si,si

           jmp  short int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Get PM Event
@@:        cmp  al,0x0B
           jne  short @f

           mov  ah,0x80
           jmp  short int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Get Power Status
@@:        cmp  al,0x0C
           jne  short @f

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  short int15_apm_pm_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Enable/Disable Device PM
@@:        cmp  al,0x0D
           jne  short @f

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  short int15_apm_pm_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Get Driver Version
@@:        cmp  al,0x0E
           jne  short @f

           mov  ax,0x0102
           jmp  short int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Engage/Disengae
@@:        cmp  al,0x0F
           jne  short @f
           jmp  short int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM Get Capabilities
@@:        cmp  al,0x10
           jne  short @f

           mov  bl,0x00
           mov  cx,0x0000
           jmp  short int15_apm_pm_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; APM unknown/unsupported call
@@:
           ;xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

int15_apm_pm_fail:
           mov  ah,0x00
int15_apm_pm_fail_noah:
           popfd                 ; 32-bit protected mode needs the flags preserved
           stc
           retf

int15_apm_pm_success:
           mov  ah,0x00
int15_apm_pm_success_noah:
           popfd                 ; 32-bit protected mode needs the flags preserved
           clc
           retf
apm_do_pmode32  endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; move back to real mode
.rmode

.end
