comment |*******************************************************************
*  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: services.asm                                                       *
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
*   bios services file                                                     *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.16                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 14 Mar 2025                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

srvs_15_unknown_call_str  db 'services_15_%i: Unknown call 0x%04X',13,10,0

.even
pmode_IDT_info:
   dw 0x0000    ; limit 15:00
   dw 0x0000    ; base  15:00
   db 0x0E      ; base  23:16
   db 0x00      ; base  31:24

.even
rmode_IDT_info:
   dw 0x03FF    ; limit 15:00
   dw 0x0000    ; base  15:00
   db 0x00      ; base  23:16
   db 0x00      ; base  31:24

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Enable/Disable the A20 line
; on entry:
;  al = state (1 = enable)
; on return
;  al = previous state
; destroys none
set_enable_a20 proc near
           mov  ah,al            ; save desired state
           in   al,PORT_A20      ; get current state
           push ax               ; save for return
           or   al,0x02          ; assume setting it
           or   ah,ah            ; if ah != 0, don't clear it
           jnz  short @f         ;
           and  al,0xFD          ; clear it
@@:        out  PORT_A20,al      ; write it back
           pop  ax
           shr  al,1
           and  al,1
           ret
set_enable_a20 endp

.para
unreal_post_gdt:
           dw   ((4 * 8) - 1)
           dd   ((BIOS_BASE << 4) + unreal_post_gdt)
           dw   0x0000

           ; code descriptor (0x08)
           dw   0xFFFF            ; limit 15:0 = normal 64k
           dw   ((BIOS_BASE << 4) & 0xFFFF) ; base 15:0
           db   ((BIOS_BASE >> 12) & 0xFF)  ; base 23:16
           db   0x9B              ; access
           dw   0x0000            ; base 31:24 / limit 19:16

           ; data descriptor (16-bit) (0x10)
           dw   0xFFFF            ; limit 15:0 = normal 64k
           dw   ((BIOS_BASE << 4) & 0xFFFF) ; base 15:0
           db   ((BIOS_BASE >> 12) & 0xFF)  ; base 23:16
           db   0x93              ; access
           dw   0x0000            ; base 31:24 / limit 19:16

           ; data descriptor (32-bit) (0x18)
           dw   0xFFFF            ; limit 15:0 = 4Gig
           dw   0x0000            ; base 15:0
           db   0x00              ; base 23:16
           db   0x92              ; access
           dw   0x00CF            ; base 31:24 / limit 19:16

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; setup unreal mode (4gig limits) for fs
;  this is only used during POST boot. As soon as
;   we give up control to the first boot sector,
;   we no longer call this routine. (except for
;   calls via USB emulation)
; on entry:
;  nothing
; on return
;  ax = previous state of a20 (bit 0 = 1 = set)
; destroys none
unreal_post proc near
           push bx
           push eax
           
           ; make sure the A20 line is on
           mov  al,1
           call set_enable_a20
           push ax

           ; load the GDT
           lgdt far cs:[unreal_post_gdt]
           
           ; set the PE bit
           mov  eax,cr0
           or   al,1
           mov  cr0,eax
           jmp  far offset unreal_post_00,0x0008
unreal_post_00:
           mov  ax,0x18
           mov  fs,ax

           mov  eax,cr0
           and  al,0xFE
           mov  cr0,eax
           jmp  far offset unreal_post_01,BIOS_BASE
unreal_post_01:
           xor  ax,ax            ; make sure fs = 0
           mov  fs,ax

           pop  bx               ; previous state of A20 line
           pop  eax
           mov  ax,bx
           pop  bx
           ret
unreal_post endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; restore the unreal mode (4gig limits) for fs
;  this is only used during POST boot. As soon as
;   we give up control to the first boot sector,
;   we no longer call this routine.
; on entry:
;  nothing
; on return
;  nothing
; destroys none
real_post  proc near uses eax
           ; make sure the A20 line is off
           mov  al,0
           call set_enable_a20

           ; load the GDT
           lgdt far cs:[unreal_post_gdt]
           
           ; set the PE bit
           mov  eax,cr0
           or   al,1
           mov  cr0,eax
           jmp  far offset real_post_00,0x0008
real_post_00:
           mov  ax,0x10
           mov  fs,ax
           
           mov  eax,cr0
           and  al,0xFE
           mov  cr0,eax
           jmp  far offset real_post_01,BIOS_BASE
real_post_01:
           xor  ax,ax
           mov  fs,ax
           ret
real_post  endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; keypad numerical number scan bytes we allow
int15_numpad_keys db 0x52  ; '0'
                  db 0x4F  ; '1'
                  db 0x50  ; '2'
                  db 0x51  ; '3'
                  db 0x4B  ; '4'
                  db 0x4C  ; '5'
                  db 0x4D  ; '6'
                  db 0x47  ; '7'
                  db 0x48  ; '8'
                  db 0x49  ; '9'
                  db 0x00  ; end marker (no more)

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Keyboard Intercept routine
; We check the see if the user is doing a ALT+xxx combination.
;   (https://en.wikipedia.org/wiki/Alt_code)
; on entry:
;  ds = 0x0040
;  al = keyboard scan byte (from INT 09)
; on return
;  carry clear
;    tell caller to ignore keypress
;  carry set
;    tell caller to process key as normal
; destroys all general (they are preserved by interrupt call)
int15_keyb_intercept proc near uses ds
           push ax
           call bios_get_ebda
           mov  ds,ax
           pop  ax
           
           ; alt pressed code = 0x38
           cmp  al,(0x00 | 0x38)
           je   short int15_keyb_int_start
           
           ; alt release code = 0xB8
           cmp  al,(0x80 | 0x38)
           je   short int15_keyb_int_end
           
           ; else, any keypad numeral (0x47 -> 0x52, excluding 0x4A an 0x4E)
           ; (we watch for the release of the key)
           mov  si,offset int15_numpad_keys
           mov  ah,al
           and  ah,0x7F
           xor  bx,bx
@@:        cmp  byte cs:[bx+si],0
           je   short int15_keyb_int_end
           cmp  cs:[bx+si],ah
           je   short @f
           inc  bx
           jmp  short @b
           
           ; found a numpad numerical key press/release
           ; bx = 0 -> 9
@@:        test al,0x80
           jz   short int15_keyb_int_ignore
           
           ; found a numpad numerical key release
           mov  al,[EBDA_DATA->keyb_int_value]
           mov  cl,10
           mul  cl
           add  al,bl
           mov  [EBDA_DATA->keyb_int_value],al
           or   byte [EBDA_DATA->keyb_int_flags],0000_0010b
           call int15_keyb_intercept_bda
           jmp  short int15_keyb_int_ignore
           
           ; the alt key was pressed
int15_keyb_int_start:
           mov  byte [EBDA_DATA->keyb_int_value],0
           mov  byte [EBDA_DATA->keyb_int_flags],0000_0001b
           call int15_keyb_intercept_bda
           jmp  short int15_keyb_int_done
           
           ; the alt key was released
int15_keyb_int_end:
           mov  al,[EBDA_DATA->keyb_int_flags]
           mov  byte [EBDA_DATA->keyb_int_flags],0000_0000b
           
           and  al,0000_0011b
           cmp  al,0000_0011b
           jne  short int15_keyb_int_done
           
           ; 'insert' this char into the keyboard
           mov  ah,5
           movzx cx,byte [EBDA_DATA->keyb_int_value]
           int  16h
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; tell the caller to process the key as normal
int15_keyb_int_done:
           stc
           ret
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; tell the caller to ignore the key press/release
int15_keyb_int_ignore:
           clc
           ret
int15_keyb_intercept endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; store the alt+XXX value in the BDA at 0x00419
; on entry:
;  ds = EBDA
;  ds:[EBDA_DATA->keyb_int_value] = value to store
; on return
;  nothing
; destroys nothing
int15_keyb_intercept_bda proc near uses ax es
           xor  ax,ax
           mov  es,ax
           mov  al,[EBDA_DATA->keyb_int_value]
           mov  es:[0x00419],al
           ret
int15_keyb_intercept_bda endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; BIOS Services
; on entry:
;  ds = 0x0040
;  stack currently has (after we set bp):
;   flags    cs      ip      es      ds
;  [bp+44] [bp+42] [bp+40] [bp+38] [bp+36]
;    edi     esi     ebp     esp     ebx     edx     ecx     eax
;  [bp+04] [bp+08] [bp+12] [bp+16] [bp+20] [bp+24] [bp+28] [bp+32]
; on return
;  nothing
; destroys all general (preserved by interrupt call)
int15_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           ;sub  sp,4

           ; service call
           mov  ax,REG_AX
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build ABIOS system parameter table?
           ; OS2Warp40 calls this one
           cmp  ah,0x04          ; 
           jne  short @f
           
           jmp  int15_func_fail
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Locate ROM Basic
@@:        cmp  ah,0x22          ; 
           jne  short @f
           
           ; If we were going to support the 'Cassette Basic',
           ;  it would reside at 0xF6000->0xFE000 and this function
           ;  would return 0xF600:0000 in es:bx, with ah=0
           ; However, we just don't have the room to do so.
           jmp  int15_func_fail
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; A20 control
@@:        cmp  ah,0x24          ; 
           jne  short @f

           cmp  al,0x00          ; disable a20
           je   short int15_24_00
           cmp  al,0x01
           jne  short int15_24_02
int15_24_00:
           call set_enable_a20
           jmp  int15_func_success
int15_24_02:
           cmp  al,0x02
           jne  short int15_24_03
           in   al,PORT_A20
           shr  al,1
           and  al,1
           jmp  int15_func_success
int15_24_03:
           cmp  al,0x03
           jne  short int15_24_04
           mov  word REG_BX,0x03
           jmp  int15_func_success
int15_24_04:
           jmp  int15_func_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; wait on external event
@@:        cmp  ah,0x41          ; 
           jne  short @f
           mov  byte REG_AH,0x86 ; unsupported function
           jmp  int15_func_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; HP 95LX/100LX/200LX installation check
@@:        cmp  ax,0x4DD4        ; 
           jne  short @f
           xor  bx,bx
           mov  byte REG_AH,0x86 ; unsupported function
           jmp  int15_func_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Keyboard intercept
           ; (this is usually hooked)
@@:        cmp  ah,0x4F          ; 
           jne  short @f
           call int15_keyb_intercept
           jmp  int15_func_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; removable media eject
@@:        cmp  ah,0x52          ; 
           jne  short @f

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  int15_func_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; call the APM
@@:        cmp  ah,0x53          ; 
           jne  short @f
           
           ; make sure all the (general) registers are set
           mov  eax,REG_EAX
           mov  ebx,REG_EBX
           mov  ecx,REG_ECX
           mov  edx,REG_EDX
           mov  esi,REG_ESI
           mov  edi,REG_EDI

           ; call the real mode APM interface
           call far offset apm_do_realmode,BIOS_BASE

           ; restore all the registers
           mov  REG_EAX,eax
           mov  REG_EBX,ebx
           mov  REG_ECX,ecx
           mov  REG_EDX,edx
           mov  REG_ESI,esi
           mov  REG_EDI,edi

           jnc  int15_func_success_noah
           jmp  int15_func_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; device open
@@:        cmp  ah,0x80          ; 
           jne  short @f
           ; ignored
           jmp  int15_func_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; device close
@@:        cmp  ah,0x81          ; 
           jne  short @f
           ; ignored
           jmp  int15_func_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; program termination
@@:        cmp  ah,0x82          ; 
           jne  short @f
           ; ignored
           jmp  int15_func_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        cmp  ah,0x83          ; 
           jne  short @f

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  int15_func_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; copy extended memory
@@:        cmp  ah,0x87          ; 
           jne  @f

           cli
           mov  al,1
           call set_enable_a20
           push ax               ; save for restoring

           movzx eax,word REG_ES
           movzx esi,word REG_SI
           mov  es,ax

           ; initialize the gdt
           shl  eax,4
           add  eax,esi
           mov  word es:[si+0x08+0x00],((6 * 8) - 1)     ; limit 15:0 = (6 * 8 bytes per descriptor) - 1
           mov       es:[si+0x08+0x02],ax                ; base 15:0
           shr  eax,16                                   ;
           mov       es:[si+0x08+0x04],al                ; base 23:16
           mov  byte es:[si+0x08+0x05],0x93              ; access
           mov  word es:[si+0x08+0x06],0x0000            ; base 31:24 / limit 19:16

           ; source segment (built by caller)
           ; mov  word es:[si+0x10+0x00],????            ; limit 15:0 = normal 64k
           ; mov  word es:[si+0x10+0x02],????            ; base 15:0
           ; mov  byte es:[si+0x10+0x04],??              ; base 23:16
           ; mov  byte es:[si+0x10+0x05],0x93            ; access
           ; mov  word es:[si+0x10+0x06],????            ; base 31:24 / limit 19:16

           ; target segment (built by caller)
           ; mov  word es:[si+0x18+0x00],????            ; limit 15:0 = normal 64k
           ; mov  word es:[si+0x18+0x02],????            ; base 15:0
           ; mov  byte es:[si+0x18+0x04],??              ; base 23:16
           ; mov  byte es:[si+0x18+0x05],0x93            ; access
           ; mov  word es:[si+0x18+0x06],????            ; base 31:24 / limit 19:16
           
           ; code descriptor
           mov  word es:[si+0x20+0x00],0xFFFF            ; limit 15:0 = normal 64k
           mov  word es:[si+0x20+0x02],((BIOS_BASE << 4) & 0xFFFF) ; base 15:0
           mov  byte es:[si+0x20+0x04],((BIOS_BASE >> 12) & 0xFF)  ; base 23:16
           mov  byte es:[si+0x20+0x05],0x9B              ; access
           mov  word es:[si+0x20+0x06],0x0000            ; base 31:24 / limit 19:16

           ; stack descriptor
           xor  eax,eax
           mov  ax,ss
           shl  eax,4
           mov  word es:[si+0x28+0x00],0xFFFF            ; limit 15:0 = normal 64k
           mov       es:[si+0x28+0x02],ax                ; base 15:0
           shr  eax,16                                   ;
           mov       es:[si+0x28+0x04],al                ; base 23:16
           mov  byte es:[si+0x28+0x05],0x93              ; access
           mov  word es:[si+0x28+0x06],0x0000            ; base 31:24 / limit 19:16

           ; count of words to copy (0x8000 max)
           mov  cx,REG_CX
           
           ; save the current stack location to the BDA
           mov  [0x0067],sp
           mov  [0x0069],ss

           lgdt far es:[si + 0x08]
           lidt far cs:[pmode_IDT_info]
           ; todo: do we need to do something with the IDT ?????
           
           ; set the PE bit
           mov  eax,cr0
           or   al,1
           mov  cr0,eax
           jmp  far offset int15_pmode,0x0020
int15_pmode:
           mov  ax,0x28   ;; if interrupts are off, why do we care about ss ?????
           mov  ss,ax
           mov  ax,0x10
           mov  ds,ax
           mov  ax,0x18
           mov  es,ax
           xor  si,si
           xor  di,di
           cld
           rep
             movsw
           
           ; make sure the ds and es limits are set back to 64k
           mov  ax,0x28
           mov  ds,ax
           mov  es,ax
           
           mov  eax,cr0
           and  al,0xFE
           mov  cr0,eax
           jmp  far offset int15_rmode,BIOS_BASE
int15_rmode:
           ; restore the IDT to normal real-mode defaults
           lidt far cs:[rmode_IDT_info]

           ; restore our stack location from the BDA
           mov  ax,0x40
           mov  ds,ax
           mov  ss,[0x0069]
           mov  sp,[0x0067]

           pop  ax               ; restore the previous A20 state
           call set_enable_a20   ; 
           sti
           jmp  int15_func_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; return extended memory (above 1Meg)
           ; returns count of KB's after 0x00100000
@@:        cmp  ah,0x88          ; 
           jne  short @f

           mov  ah,0x30
           call cmos_get_byte
           mov  bl,al
           mov  ah,0x31
           call cmos_get_byte
           mov  bh,al

           ; if the OS is using this service, it probably doesn't
           ;  know about the E820 service which can mark blocks as
           ;  reserved. Therefore, since we use the upper-end memory
           ;  area for ACPI and BIOS usage, we decrement the amount
           ;  of total memory returned to account for this.
           ; (if EBDA_DATA->mem_base_ram_alloc > 64meg, no need to do the following 'sub')
           push ds
           call bios_get_ebda
           mov  ds,ax
           cmp  dword [EBDA_DATA->mem_base_ram_alloc],0x03FF0000
           pop  ds
           jae  short int15_func_88_limit0
           sub  bx,((((BIOS_EXT_MEMORY_USE + ACPI_DATA_SIZE) + 65535) / 65536) * 64)
int15_func_88_limit0:

           ; According to Ralf Brown's interrupt the limit should be 15M,
           ;  but real machines mostly return max 63M.
           cmp  bx,0xFFC0   ; 64512   ; (63 * 1024)
           jna  short int15_func_88_limit1
           mov  bx,0xFFC0   ; 64512
int15_func_88_limit1:
           mov  REG_AX,bx
           jmp  int15_func_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        cmp  ah,0x89          ; 
           jne  short @f

           ; rombios.c line 4192
           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  int15_func_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Device busy interrupt.
           ; Called by INT 16h when no key available
@@:        cmp  ah,0x90          ; 
           jne  short @f
           ; ignored
           jmp  int15_func_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Interrupt complete.
           ; Hook: Called by IRQ handlers
@@:        cmp  ah,0x91          ; 
           jne  short @f
           jmp  int15_func_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        cmp  ah,0xBF          ; 
           jne  short @f

           ;xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;

           mov  byte REG_AH,0x86
           jmp  int15_func_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Get Configuration Table
@@:        cmp  ah,0xC0          ; 
           jne  short @f
           mov  word REG_BX,offset ebda_bios_config_table
           mov  word REG_ES,BIOS_BASE
           jmp  short int15_func_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; return EDBA address
@@:        cmp  ah,0xC1          ; 
           jne  short @f
           call bios_get_ebda
           mov  REG_ES,ax
           jmp  short int15_func_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Programmable Option Select (PS50 only???)
@@:        cmp  ah,0xC4          ; 
           jne  short @f
           ; two sub functions, 0x00 and 0x01
           ;xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;
           jmp  short int15_func_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        cmp  ah,0xC6          ; 
           jne  short @f

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;
           ; need to set the bit in "Feature byte 2" of the ebda_bios_config_table if we support this function

           jmp  short int15_func_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        cmp  ah,0xC7          ; 
           jne  short @f

           ;xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;
           ; need to set the bit in "Feature byte 2" of the ebda_bios_config_table if we support this function

           jmp  short int15_func_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        cmp  ah,0xC8          ; 
           jne  short @f

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;
           ; need to set the bit in "Feature byte 2" of the ebda_bios_config_table if we support this function

           jmp  short int15_func_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; EISA BIOS
@@:        cmp  ah,0xD8          ; 
           jne  short @f
           mov  byte REG_AH,0x86 ; unsupported function
           jmp  short int15_func_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown (Linux calls this one)
@@:        cmp  ah,0xE9          ;  ax = 0xE980
           jne  short @f
           mov  byte REG_AH,0x86 ; unsupported function
           jmp  short int15_func_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown (Linux calls this one)
@@:        cmp  ah,0xEC          ; 
           jne  short @f
           mov  byte REG_AH,0x86 ; unsupported function
           jmp  short int15_func_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        cmp  ah,0xF9          ; 
           jne  short @f
           
           ; ax = 0xF963
           ;;;; ?????
           
           mov  byte REG_AH,0x86 ; unsupported function

           jmp  short int15_func_fail_noah


@@:        push ds
           push cs
           pop  ds
           push ax
           push 16
           mov  si,offset srvs_15_unknown_call_str
           call bios_printf
           add  sp,4
           pop  ds

           mov  byte REG_AH,0x86
           jmp  short int15_func_fail_noah

int15_func_fail:
           mov  byte REG_AH,0x86 ; unsupported function
int15_func_fail_noah:
           or   word REG_FLAGS,0x0001
           mov  sp,bp
           pop  bp
           ret

int15_func_success:
           mov  byte REG_AH,0x00
int15_func_success_noah:
           and  word REG_FLAGS,(~0x0001)
           mov  sp,bp
           pop  bp
           ret
int15_function endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; BIOS Services (32-bit) (real mode)
; on entry:
;  ds = 0x0040
;  stack currently has (after we set bp):
;   flags    cs      ip      es      ds
;  [bp+44] [bp+42] [bp+40] [bp+38] [bp+36]
;    edi     esi     ebp     esp     ebx     edx     ecx     eax
;  [bp+04] [bp+08] [bp+12] [bp+16] [bp+20] [bp+24] [bp+28] [bp+32]
; on return
;  nothing
; destroys all general (preserved by interrupt call)
int15_function32 proc near ; don't put anything here
           push bp
           mov  bp,sp
           ;sub  sp,4

           ; service call
           mov  ax,REG_AX
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; wait cx:dx microseconds
           cmp  ah,0x86          ; 
           jne  short @f

           sti
           
           mov  ax,REG_CX
           shl  eax,16
           mov  ax,REG_DX
           
           ; convert to numbers of 15usec ticks
           mov  ebx,15
           xor  edx,edx
           div  ebx
           mov  ecx,eax
           
           ; wait for ecx number of refresh requests
           in   al,PORT_PS2_CTRLB
           and  al,(1<<4)        ; bit four toggles with each refresh request
           mov  ah,al
           
           ; if ecx is initially <= 15, don't wait
;           or   ecx,ecx
;           je   short int1586_tick_end
;int1586_tick:
;           in   al,PORT_PS2_CTRLB
;           and  al,(1<<4)
;           cmp  al,ah
;           je   short int1586_tick
;           mov  ah,al
;           dec  ecx
;           jnz  short int1586_tick
;int1586_tick_end:
           jmp  int15_func32_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Get memory map calls
@@:        cmp  ah,0xE8          ; get system memory (0x01 or 0x20)
           jne  @f

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Get memory map > 64 (AX = 0xE801)
           cmp  al,0x01          ; get memory size for > 64Meg
           jne  short int15_func32_E8_20

           mov  ah,0x30
           call cmos_get_byte
           mov  cl,al
           mov  ah,0x31
           call cmos_get_byte
           mov  ch,al
           cmp  cx,0x3C00
           jna  short int15_func32_E8_01_0
           mov  cx,0x3C00
int15_func32_E8_01_0:
           
           mov  ah,0x34
           call cmos_get_byte
           mov  dl,al
           mov  ah,0x35
           call cmos_get_byte
           mov  dh,al

           ; if the OS is using this service, it probably doesn't
           ;  know about the E820 service which can mark blocks as
           ;  reserved. Therefore, since we use the upper-end memory
           ;  area for ACPI and BIOS usage, we decrement the amount
           ;  of total memory returned to account for this.
           sub  dx,(((BIOS_EXT_MEMORY_USE + ACPI_DATA_SIZE) + 65535) / 65536)
           jnc  short int15_func32_E8_01_1
           xor  dx,dx
int15_func32_E8_01_1:
           mov  REG_AX,cx   ; 1M -> 16M (in K)
           mov  REG_CX,cx   ; 1M -> 16M (in K)
           mov  REG_BX,dx   ; 16M -> end (in 64k)
           mov  REG_DX,dx   ; 16M -> end (in 64k)
           jmp  int15_func32_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Get system memory map (AX = 0xE820)
int15_func32_E8_20:
           cmp  al,0x20          ; get system memory map
           jne  short int15_func32_E8_error

           mov  edx,REG_EDX
           cmp  edx,0x534D4150   ; check signature
           jne  short int15_func32_E8_error

           push ds
           call bios_get_ebda
           mov  ds,ax

           mov  ecx,REG_ECX
           movzx eax,word [EBDA_DATA->memory_count]
           mov  ebx,REG_EBX
           cmp  ebx,eax
           jnb  short int15_func32_E8_20_2
           imul si,bx,sizeof(MEM_TABLE)
           add  si,EBDA_DATA->memory_table
.if (APCI_VERSION < 3)
           mov  eax,20
.else
           mov  eax,24  ; sizeof(MEM_TABLE)
.endif
           cmp  ecx,eax
           jbe  short int15_func32_E8_20_0
           mov  ecx,eax
int15_func32_E8_20_0:
           push cx
           push es
           mov  ax,REG_ES
           mov  es,ax
           mov  di,REG_DI
           rep
             movsb
           pop  es
           pop  cx
           ; was this the last one
           inc  bx
           cmp  bx,[EBDA_DATA->memory_count]
           jb   short int15_func32_E8_20_1
           xor  ebx,ebx
int15_func32_E8_20_1:
           mov  REG_EAX,edx
           mov  REG_EBX,ebx
           mov  REG_ECX,ecx
           pop  ds
           jmp  short int15_func32_success_noah

int15_func32_E8_20_2:
           pop  ds
           mov  byte REG_AH,0x86
           mov  dword REG_EBX,0x00000000
           jmp  short int15_func32_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown (AX = 0xE8??)
int15_func32_E8_error:
           mov  byte REG_AH,0x86 ; unsupported function
           jmp  short int15_func32_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown system32 services call
@@:        push ds
           push cs
           pop  ds
           push ax
           push 32
           mov  si,offset srvs_15_unknown_call_str
           call bios_printf
           add  sp,4
           pop  ds

           mov  byte REG_AH,0x86
           jmp  short int15_func32_fail_noah

int15_func32_fail:
           ;mov  byte REG_AH,0x00  ;;;; ??????
int15_func32_fail_noah:
           or   word REG_FLAGS,0x0001
           mov  sp,bp
           pop  bp
           ret

int15_func32_success:
           mov  byte REG_AH,0x00
int15_func32_success_noah:
           and  word REG_FLAGS,(~0x0001)
           mov  sp,bp
           pop  bp
           ret
int15_function32 endp

.end
