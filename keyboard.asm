comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: keyboard.asm                                                       *
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
*   keyboard include file                                                  *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.14                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 02 Nov 2024                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

kb_panic_string  db  'PANIC: file: ', %FILE, ' -- line: %i',13,10,0

MAX_SCAN_CODE   equ  0x58

SCANCODES STRUCT
  sc_normal      word   ;
  sc_shift       word   ;
  sc_control     word   ;
  sc_alt         word   ;
  sc_lock_flags  word   ;
SCANCODES ENDS

scan_to_scanascii:
  dw  0x0000, 0x0000, 0x0000, 0x0000, 0x00  ; nothing
  dw  0x011b, 0x011b, 0x011b, 0x0100, 0x00  ;  escape
  dw  0x0231, 0x0221, 0x0000, 0x7800, 0x00  ;  1!
  dw  0x0332, 0x0340, 0x0300, 0x7900, 0x00  ;  2@
  dw  0x0433, 0x0423, 0x0000, 0x7a00, 0x00  ;  3#
  dw  0x0534, 0x0524, 0x0000, 0x7b00, 0x00  ;  4$
  dw  0x0635, 0x0625, 0x0000, 0x7c00, 0x00  ;  5%
  dw  0x0736, 0x075e, 0x071e, 0x7d00, 0x00  ;  6^
  dw  0x0837, 0x0826, 0x0000, 0x7e00, 0x00  ;  7&
  dw  0x0938, 0x092a, 0x0000, 0x7f00, 0x00  ;  8*
  dw  0x0a39, 0x0a28, 0x0000, 0x8000, 0x00  ;  9(
  dw  0x0b30, 0x0b29, 0x0000, 0x8100, 0x00  ;  0)
  dw  0x0c2d, 0x0c5f, 0x0c1f, 0x8200, 0x00  ;  -_
  dw  0x0d3d, 0x0d2b, 0x0000, 0x8300, 0x00  ;  =+
  dw  0x0e08, 0x0e08, 0x0e7f, 0x0000, 0x00  ;  backspace
  dw  0x0f09, 0x0f00, 0x0000, 0x0000, 0x00  ;  tab
  dw  0x1071, 0x1051, 0x1011, 0x1000, 0x40  ;  Q
  dw  0x1177, 0x1157, 0x1117, 0x1100, 0x40  ;  W
  dw  0x1265, 0x1245, 0x1205, 0x1200, 0x40  ;  E
  dw  0x1372, 0x1352, 0x1312, 0x1300, 0x40  ;  R
  dw  0x1474, 0x1454, 0x1414, 0x1400, 0x40  ;  T
  dw  0x1579, 0x1559, 0x1519, 0x1500, 0x40  ;  Y
  dw  0x1675, 0x1655, 0x1615, 0x1600, 0x40  ;  U
  dw  0x1769, 0x1749, 0x1709, 0x1700, 0x40  ;  I
  dw  0x186f, 0x184f, 0x180f, 0x1800, 0x40  ;  O
  dw  0x1970, 0x1950, 0x1910, 0x1900, 0x40  ;  P
  dw  0x1a5b, 0x1a7b, 0x1a1b, 0x0000, 0x00  ;  [{
  dw  0x1b5d, 0x1b7d, 0x1b1d, 0x0000, 0x00  ;  ]}
  dw  0x1c0d, 0x1c0d, 0x1c0a, 0x0000, 0x00  ;  Enter
  dw  0x0000, 0x0000, 0x0000, 0x0000, 0x00  ;  L Ctrl
  dw  0x1e61, 0x1e41, 0x1e01, 0x1e00, 0x40  ;  A
  dw  0x1f73, 0x1f53, 0x1f13, 0x1f00, 0x40  ;  S
  dw  0x2064, 0x2044, 0x2004, 0x2000, 0x40  ;  D
  dw  0x2166, 0x2146, 0x2106, 0x2100, 0x40  ;  F
  dw  0x2267, 0x2247, 0x2207, 0x2200, 0x40  ;  G
  dw  0x2368, 0x2348, 0x2308, 0x2300, 0x40  ;  H
  dw  0x246a, 0x244a, 0x240a, 0x2400, 0x40  ;  J
  dw  0x256b, 0x254b, 0x250b, 0x2500, 0x40  ;  K
  dw  0x266c, 0x264c, 0x260c, 0x2600, 0x40  ;  L
  dw  0x273b, 0x273a, 0x0000, 0x0000, 0x00  ;  ;:
  dw  0x2827, 0x2822, 0x0000, 0x0000, 0x00  ;  '"
  dw  0x2960, 0x297e, 0x0000, 0x0000, 0x00  ;  `~
  dw  0x0000, 0x0000, 0x0000, 0x0000, 0x00  ;  L shift
  dw  0x2b5c, 0x2b7c, 0x2b1c, 0x0000, 0x00  ;  |\
  dw  0x2c7a, 0x2c5a, 0x2c1a, 0x2c00, 0x40  ;  Z
  dw  0x2d78, 0x2d58, 0x2d18, 0x2d00, 0x40  ;  X
  dw  0x2e63, 0x2e43, 0x2e03, 0x2e00, 0x40  ;  C
  dw  0x2f76, 0x2f56, 0x2f16, 0x2f00, 0x40  ;  V
  dw  0x3062, 0x3042, 0x3002, 0x3000, 0x40  ;  B
  dw  0x316e, 0x314e, 0x310e, 0x3100, 0x40  ;  N
  dw  0x326d, 0x324d, 0x320d, 0x3200, 0x40  ;  M
  dw  0x332c, 0x333c, 0x0000, 0x0000, 0x00  ;  ,<
  dw  0x342e, 0x343e, 0x0000, 0x0000, 0x00  ;  .>
  dw  0x352f, 0x353f, 0x0000, 0x0000, 0x00  ;  /?
  dw  0x0000, 0x0000, 0x0000, 0x0000, 0x00  ;  R Shift
  dw  0x372a, 0x372a, 0x0000, 0x0000, 0x00  ;  *
  dw  0x0000, 0x0000, 0x0000, 0x0000, 0x00  ;  L Alt
  dw  0x3920, 0x3920, 0x3920, 0x3920, 0x00  ;  space
  dw  0x0000, 0x0000, 0x0000, 0x0000, 0x00  ;  caps lock
  dw  0x3b00, 0x5400, 0x5e00, 0x6800, 0x00  ;  F1
  dw  0x3c00, 0x5500, 0x5f00, 0x6900, 0x00  ;  F2
  dw  0x3d00, 0x5600, 0x6000, 0x6a00, 0x00  ;  F3
  dw  0x3e00, 0x5700, 0x6100, 0x6b00, 0x00  ;  F4
  dw  0x3f00, 0x5800, 0x6200, 0x6c00, 0x00  ;  F5
  dw  0x4000, 0x5900, 0x6300, 0x6d00, 0x00  ;  F6
  dw  0x4100, 0x5a00, 0x6400, 0x6e00, 0x00  ;  F7
  dw  0x4200, 0x5b00, 0x6500, 0x6f00, 0x00  ;  F8
  dw  0x4300, 0x5c00, 0x6600, 0x7000, 0x00  ;  F9
  dw  0x4400, 0x5d00, 0x6700, 0x7100, 0x00  ;  F10
  dw  0x0000, 0x0000, 0x0000, 0x0000, 0x00  ;  Num Lock
  dw  0x0000, 0x0000, 0x0000, 0x0000, 0x00  ;  Scroll Lock
  dw  0x4700, 0x4737, 0x7700, 0x0007, 0x20  ;  7 Home
  dw  0x4800, 0x4838, 0x0000, 0x0008, 0x20  ;  8 UP
  dw  0x4900, 0x4939, 0x8400, 0x0009, 0x20  ;  9 PgUp
  dw  0x4a2d, 0x4a2d, 0x0000, 0x0000, 0x00  ;  -
  dw  0x4b00, 0x4b34, 0x7300, 0x0004, 0x20  ;  4 Left
  dw  0x4c00, 0x4c35, 0x0000, 0x0005, 0x20  ;  5
  dw  0x4d00, 0x4d36, 0x7400, 0x0006, 0x20  ;  6 Right
  dw  0x4e2b, 0x4e2b, 0x0000, 0x0000, 0x00  ;  +
  dw  0x4f00, 0x4f31, 0x7500, 0x0001, 0x20  ;  1 End
  dw  0x5000, 0x5032, 0x0000, 0x0002, 0x20  ;  2 Down
  dw  0x5100, 0x5133, 0x7600, 0x0003, 0x20  ;  3 PgDn
  dw  0x5200, 0x5230, 0x0000, 0x0000, 0x20  ;  0 Ins
  dw  0x5300, 0x532e, 0x0000, 0x0000, 0x20  ;  Del
  dw  0x0000, 0x0000, 0x0000, 0x0000, 0x00  ;
  dw  0x0000, 0x0000, 0x0000, 0x0000, 0x00  ;
  dw  0x565c, 0x567c, 0x0000, 0x0000, 0x00  ;  \|
  dw  0x8500, 0x8700, 0x8900, 0x8b00, 0x00  ;  F11
  dw  0x8600, 0x8800, 0x8a00, 0x8c00, 0x00  ;  F12

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; display a panic string and freeze
; on entry:
;  nothing
; on return
;  does not return...
; destroys all general
kbd_panic  proc near ; add nothing here
           mov  si,offset kb_panic_string
           call bios_printf
           add  sp,2
           call freeze
           .noret
kbd_panic  endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; wait for keyboard in buffer to be empty
; on entry:
;  nothing
; on return
;  zf = 1 input buffer is empty
; destroys all general
kbd_in_empty proc near uses ax cx
           xor  cx,cx  ; loop 0x10000 times
@@:        in   al,PORT_PS2_STATUS
           test al,2             ; if bit 1 is set, the input buffer is full
           jz   short @f
           ; do short delay
           xor  al,al
           out  PORT_DIAG,al
           loop @b
           push %line
           jmp  short kbd_panic
@@:        ret
kbd_in_empty endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; wait for keyboard out buffer to be full
; on entry:
;  nothing
; on return
;  zf = 0 if buffer is full (ready for read)
; destroys all general
kbd_out_full proc near uses ax cx
           xor  cx,cx  ; loop 0x10000 times
@@:        in   al,PORT_PS2_STATUS
           test al,1             ; if bit 0 is set, the output buffer is full
           jnz  short @f
           ; do short delay
           xor  al,al
           out  PORT_DIAG,al
           loop @b
           push %line
           jmp  short kbd_panic
@@:        ret
kbd_out_full endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Initialize the keyboard
; on entry:
;  nothing
; on return
;  nothing
; destroys all general
init_keyboard proc near
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; clear the keyboard IN buffer
           call kbd_in_empty

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; clear the keyboard OUT buffer
           mov  cx,0x2000
init_keyboard_0:
           ; do short delay
           xor  al,al
           out  PORT_DIAG,al

           in   al,PORT_PS2_STATUS
           test al,1             ; if bit 0 is set, the output buffer is full
           jz   short @f
           
           ; read in the byte and reset the counter
           in   al,PORT_PS2_DATA
           mov  cx,0x2000

@@:        loop init_keyboard_0
           

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize controller

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; send self test
           mov  al,0xAA
           out  PORT_PS2_STATUS,al
           call kbd_in_empty

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; byte should return 0x55
           call kbd_out_full
           in   al,PORT_PS2_DATA
           cmp  al,0x55
           je   short @f
           push %line
           jmp  short kbd_panic

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; send 0xAB (interface test)
@@:        mov  al,0xAB
           out  PORT_PS2_STATUS,al
           call kbd_in_empty
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; byte should return 0x00
           call kbd_out_full
           in   al,PORT_PS2_DATA
           cmp  al,0x00
           je   short @f
           push %line
           jmp  short kbd_panic

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; enable clock
@@:        mov  al,0xAE
           out  PORT_PS2_STATUS,al
           call kbd_in_empty
           
           mov  al,0xA8
           out  PORT_PS2_STATUS,al
           call kbd_in_empty

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize keyboard

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; reset keyboard and self test
           mov  al,0xFF
           out  PORT_PS2_DATA,al
           call kbd_in_empty

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; byte should return 0xFA, 0xAA
           call kbd_out_full
           in   al,PORT_PS2_DATA
           cmp  al,0xFA
           je   short @f
           push %line
           jmp  kbd_panic
@@:        call kbd_out_full
           in   al,PORT_PS2_DATA
           cmp  al,0xAA
           je   short @f
           push %line
           jmp  kbd_panic

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; disable keyboard
@@:        mov  al,0xF5
           out  PORT_PS2_DATA,al
           call kbd_in_empty
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; byte should return 0xFA
           call kbd_out_full
           in   al,PORT_PS2_DATA
           cmp  al,0xFA
           je   short @f
           push %line
           jmp  kbd_panic

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; write keyboard mode
@@:        mov  al,0x60
           out  PORT_PS2_STATUS,al
           call kbd_in_empty
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; send command: scan code convert, disable mouse, enable IRQ 1
           mov  al,0x61
           out  PORT_PS2_DATA,al
           call kbd_in_empty

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; enable keyboard
           mov  al,0xF4
           out  PORT_PS2_DATA,al
           call kbd_in_empty

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; byte should return 0xFA
           call kbd_out_full
           in   al,PORT_PS2_DATA
           cmp  al,0xFA
           je   short @f
           push %line
           jmp  kbd_panic

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; done, we can return
@@:        mov  al,0x77
           out  PORT_DIAG,al
           ret
init_keyboard endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; check for a keystroke
; on entry:
;  nothing
; on return
;  al = non-zero if keystroke is present
; destroys ax
check_for_keystroke proc near
           mov  ah,0x01
           int  16h
           mov  al,0             ; assume not (don't use xor al,al)
           jz   short @f
           inc  al
@@:        ret
check_for_keystroke endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; returns a keystroke
; on entry:
;  nothing
; on return
;  al = high byte of bios scancode
;  ah = low byte of bios scancode
; destroys ax
get_keystroke proc near
           xor  ax,ax
           int  16h
           ret
get_keystroke endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; delay and check for key stroke
; on entry:
;  ax = ticks to delay (between checking for a key press)
;  cx = loop count (count of times to check for a key press)
; on return
;  nothing
; destroys nothing
delay_ticks_and_check_for_keystroke proc near uses ax cx
@@:        call delay_ticks
           push ax
           call check_for_keystroke
           or   al,al
           pop  ax
           jnz  short @f
           loop @b
@@:        ret
delay_ticks_and_check_for_keystroke endp


; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; The interrupt handler called this function
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
int09_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           sub  sp,6

int09_scan_code    equ [bp-1]   ; byte
int09_shift_flags  equ [bp-2]   ; byte
int09_mf2_flags    equ [bp-3]   ; byte
int09_mf2_state    equ [bp-4]   ; byte
int09_altkp_val    equ [bp-5]   ; byte
           
           mov  ax,REG_AX
           mov  int09_scan_code,al

           ; anything to do?
           cmp  al,0
           je   int09_function_done

           ; get the flags
           mov  al,[0x0017]
           mov  int09_shift_flags,al
           mov  al,[0x0018]
           mov  int09_mf2_flags,al
           mov  al,[0x0096]
           mov  int09_mf2_state,al
           mov  al,[0x0019]
           mov  int09_altkp_val,al

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; scancode action

           ; Caps Lock press
           cmp  byte int09_scan_code,0x3A
           jne  short @f
           xor  byte int09_shift_flags,0x40
           or   byte int09_mf2_flags,0x40
           jmp  int09_function_break

@@:        ; Caps Lock release
           cmp  byte int09_scan_code,0xBA
           jne  short @f
           and  byte int09_mf2_flags,(~0x40)
           jmp  int09_function_break

@@:        ; L Shift press
           cmp  byte int09_scan_code,0x2A
           jne  short @f
           or   byte int09_shift_flags,0x02
           jmp  int09_function_break

@@:        ; L Shift release
           cmp  byte int09_scan_code,0xAA
           jne  short @f
           and  byte int09_shift_flags,(~0x02)
           jmp  int09_function_break

@@:        ; R Shift press
           cmp  byte int09_scan_code,0x36
           jne  short @f
           or   byte int09_shift_flags,0x01
           jmp  int09_function_break

@@:        ; R Shift release
           cmp  byte int09_scan_code,0xB6
           jne  short @f
           and  byte int09_shift_flags,(~0x01)
           jmp  int09_function_break

@@:        ; Ctrl press
           cmp  byte int09_scan_code,0x1D
           jne  short @f
           test byte int09_mf2_state,0x01
           jnz  int09_function_break
           or   byte int09_shift_flags,0x04
           test byte int09_mf2_state,0x02
           jz   short ctrl_press_01
           or   byte int09_mf2_state,0x04
           jmp  int09_function_break
ctrl_press_01:
           or   byte int09_mf2_flags,0x01
           jmp  int09_function_break

@@:        ; Ctrl release
           cmp  byte int09_scan_code,0x9D
           jne  short @f
           test byte int09_mf2_state,0x01
           jnz  int09_function_break
           and  byte int09_shift_flags,(~0x04)
           test byte int09_mf2_state,0x02
           jz   short ctrl_press_02
           and  byte int09_mf2_state,(~0x04)
           jmp  int09_function_break
ctrl_press_02:
           and  byte int09_mf2_flags,(~0x01)
           jmp  int09_function_break

@@:        ; Alt press
           cmp  byte int09_scan_code,0x38
           jne  short @f
           or   byte int09_shift_flags,0x08
           test byte int09_mf2_state,0x02
           jz   short alt_press_01
           or   byte int09_mf2_state,0x08
           jmp  int09_function_break
alt_press_01:
           or   byte int09_mf2_flags,0x02
           jmp  int09_function_break

@@:        ; Alt release
           cmp  byte int09_scan_code,0xB8
           jne  short @f
           and  byte int09_shift_flags,(~0x08)
           test byte int09_mf2_state,0x02
           jz   short alt_press_02
           and  byte int09_mf2_state,(~0x08)
           jmp  short alt_press_03
alt_press_02:
           and  byte int09_mf2_flags,(~0x02)
alt_press_03:
           cmp  byte int09_altkp_val,0
           je   int09_function_break
           mov  al,int09_altkp_val
           xor  ah,ah
           call enqueue_key
           mov  byte int09_altkp_val,0
           jmp  int09_function_break

@@:        ; Num Lock press
           cmp  byte int09_scan_code,0x45
           jne  short @f
           test byte int09_mf2_state,0x03
           jnz  int09_function_break
           or   byte int09_mf2_flags,0x20
           xor  byte int09_shift_flags,0x20
           jmp  int09_function_break

@@:        ; Num Lock release
           cmp  byte int09_scan_code,0xC5
           jne  short @f
           test byte int09_mf2_state,0x03
           jnz  int09_function_break
           and  byte int09_mf2_flags,(~0x20)
           jmp  int09_function_break

@@:        ; Scroll Lock or Ctrl-Break press
           cmp  byte int09_scan_code,0x46
           jne  short @f
           test byte int09_mf2_state,0x02
           jnz  short scroll_lock0
           test byte int09_mf2_state,0x10
           jnz  short scroll_lock1
           test byte int09_shift_flags,0x04
           jz   short scroll_lock1
scroll_lock0:
           ; ctrl break press
           and  byte int09_mf2_state,(~0x02)
           mov  byte [0x0071],0x80
           mov  al,[0x001A]
           mov  [0x001C],al
           int  1Bh
           xor  ax,ax
           call enqueue_key
           jmp  int09_function_break
scroll_lock1:
           or   byte int09_mf2_flags,0x10
           xor  byte int09_shift_flags,0x10
           jmp  int09_function_break

@@:        ; Scroll Lock or Ctrl-Break release
           cmp  byte int09_scan_code,0xC6
           jne  short @f
           test byte int09_mf2_state,0x02
           jnz  short scroll_lock2
           test byte int09_mf2_state,0x10
           jnz  short scroll_lock3
           test byte int09_shift_flags,0x04
           jz   short scroll_lock3
scroll_lock2:
           ; ctrl break release
           ; do nothing
           jmp  int09_function_break
scroll_lock3:
           and  byte int09_mf2_flags,(~0x10)
           jmp  int09_function_break

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; any other scancode
@@:        test byte int09_scan_code,0x80
           jz   short @f         ; we ignore any releases
           jmp  int09_function_done

@@:        cmp  byte int09_scan_code,MAX_SCAN_CODE
           jbe  short @f         ; we ignore anything greater than MAX_SCAN_CODE
           jmp  int09_function_done
           
           ; alt-ctrl-del
@@:        cmp  byte int09_scan_code,0x53
           jne  short @f
           mov  al,int09_shift_flags
           and  al,0x0F
           cmp  al,0x0C
           jne  short @f
           mov  word [0x0072],0x1234
           jmp  far 0xFFF0,0xF000   ; jmp far offset,segment

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set ds and calculate the offset to the scancode data
@@:        push cs
           pop  ds
           movzx ax,byte int09_scan_code
           imul bx,ax,sizeof(SCANCODES)
           add  bx,offset scan_to_scanascii

           test byte int09_shift_flags,0x08 ; alt
           jz   short @f
           mov  ax,[bx+SCANCODES->sc_alt]
           cmp  ah,0
           jne  short int09_function_enqueue
           mov  al,int09_altkp_val
           imul ax,ax,10
           add  al,[bx+SCANCODES->sc_alt]
           mov  int09_altkp_val,al
           push 0x0040
           pop  ds
           jmp  short int09_function_done

@@:        test byte int09_shift_flags,0x04 ; ctrl
           jz   short @f
           mov  ax,[bx+SCANCODES->sc_control]
           jmp  short int09_function_enqueue

@@:        test byte int09_mf2_state,0x02 ; extended keys
           jz   short @f
           cmp  byte int09_scan_code,0x47
           jb   short @f
           cmp  byte int09_scan_code,0x53
           ja   short @f
           mov  ax,[bx+SCANCODES->sc_normal]
           mov  al,0xE0
           jmp  short int09_function_enqueue

@@:        test byte int09_shift_flags,0x03 ; lshift + rshift
           jz   short @f
           mov  ax,[bx+SCANCODES->sc_lock_flags]
           test int09_shift_flags,al
           jz   short int09_lock_0
           mov  ax,[bx+SCANCODES->sc_normal]
           jmp  short int09_function_enqueue
int09_lock_0:
           mov  ax,[bx+SCANCODES->sc_shift]
           jmp  short int09_function_enqueue

           ; num lock on?
@@:        mov  ax,[bx+SCANCODES->sc_lock_flags]
           test int09_shift_flags,al
           jz   short int09_lock_1
           mov  ax,[bx+SCANCODES->sc_shift]
           jmp  short int09_function_enqueue
int09_lock_1:
           mov  ax,[bx+SCANCODES->sc_normal]

int09_function_enqueue:
           mov  int09_scan_code,ah
           push 0x0040
           pop  ds
           call enqueue_key

int09_function_break:
           mov  ah,int09_scan_code
           and  ah,0x7F
           cmp  ah,0x1D
           je   short @f
           and  byte int09_mf2_state,(~0x01)
@@:        and  byte int09_mf2_state,(~0x02)

int09_function_done:
           ; write back the flags
           mov  al,int09_shift_flags
           mov  [0x0017],al
           mov  al,int09_mf2_flags
           mov  [0x0018],al
           mov  al,int09_mf2_state
           mov  [0x0096],al
           mov  al,int09_altkp_val
           mov  [0x0019],al

           mov  sp,bp
           pop  bp
           ret
int09_function endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Enqueue a key stroke
; on entry:
;  ds = 0x0040
;  ah = scan_code
;  al = ascii_code
; on return
;  al = 1 = success
; destroys nothing
enqueue_key proc near uses bx si

; this needs to be re-written
; currently, there is always room in the buffer.
;   the check is made if there is room for the next scancode
; we need to write it so the check is for the current scancode
           
           ; ds:[0x001A] = buffer head
           ; ds:[0x001C] = buffer tail
           ; ds:[0x0080] = buffer start
           ; ds:[0x0082] = buffer end

           mov  bx,[0x001C]
           mov  si,bx
           add  bx,sizeof(word)
           cmp  bx,[0x0082]
           jb   short @f
           mov  bx,[0x0080]
@@:        cmp  bx,[0x001A]
           je   short enqueue_key_error
           mov  [si],ax
           mov  [0x001C],bx

           mov  al,1
           ret

enqueue_key_error:
           xor  al,al
           ret
enqueue_key endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Dequeue a key stroke
; on entry:
;  ds = 0x0040
;  al = 1 = increment to next code, 0 = no
; on return
;  ah = scan_code
;  al = ascii_code
;  zf = set = no key, clear = key found (ax = key)
; destroys nothing
dequeue_key proc near uses bx cx

           ; ds:[0x001A] = buffer head
           ; ds:[0x001C] = buffer tail
           ; ds:[0x0080] = buffer start
           ; ds:[0x0082] = buffer end

           ; is there a key available
           mov  bx,[0x001A]
           cmp  bx,[0x001C]
           je   short dequeue_key_done_no_key

           ; else there is a key available
           mov  cx,[bx]          ; cx = scan code/ascii code

           ; are we to increment it?
           or   al,al
           jz   short dequeue_key_done_key

           ; increment pointer, wrapping if needed
           add  bx,sizeof(word)
           cmp  bx,[0x0082]
           jb   short @f
           mov  bx,[0x0080]
@@:        mov  [0x001A],bx
           
dequeue_key_done_key:
           ; return key in ax
           mov  ax,cx
           ; clear zero flag
           inc  cx
           cmp  ax,cx

           ret

dequeue_key_done_no_key:
           ret
dequeue_key endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; waits for a key press
;  will call the OS Hook--Device Busy service
; on entry:
;  ds = 0x0040
; on return
;  nothing
; destroys nothing
int16_wait_for_keypress proc near
           cli
           mov  bx,[0x001A]      ; = buffer head
           cmp  bx,[0x001C]      ; = buffer tail
           jne  short int16_wait_for_keypress_done
           sti

           ; call the OS Hook service once
           mov  ax,0x9002
           int  15h
           
@@:        cli
           mov  bx,[0x001A]      ; = buffer head
           cmp  bx,[0x001C]      ; = buffer tail
           jne  short int16_wait_for_keypress_done
           sti
           jmp  short @b

int16_wait_for_keypress_done:
           sti
           ret
int16_wait_for_keypress endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; The keyboard services function
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
int16_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           ;sub  sp,4

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check the LEDs against the shift flags
           mov  al,[0x0017]      ; shift flags
           mov  ah,[0x0097]      ; LED flags
           mov  bx,ax            ; save for later
           shr  al,4
           and  al,0x07
           and  ah,0x07
           xor  al,ah
           jz   short key_int16_no_leds

           cli
           mov  al,0xED
           out  PORT_PS2_DATA,al
@@:        in   al,PORT_PS2_STATUS
           test al,1
           jnz  short @f
           mov  al,0x21
           out  PORT_DIAG,al
           jmp  short @b

@@:        in   al,PORT_PS2_DATA
           cmp  al,0xFA
           jne  short key_int16_no_leds0

           mov  ax,bx            ; restore the flags
           and  ah,0xF8
           shr  al,4
           and  al,0x07
           or   ah,al
           mov  al,ah
           and  al,0x07
           out  PORT_PS2_DATA,al

@@:        in   al,PORT_PS2_STATUS
           test al,1
           jnz  short @f
           mov  al,0x21
           out  PORT_DIAG,al
           jmp  short @b
@@:        in   al,PORT_PS2_DATA
           mov  [0x0097],ah
key_int16_no_leds0:
           sti

key_int16_no_leds:
           mov  ah,REG_AH
           ; ds = 0x0040
           ; ah = service
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read keyboard input (waiting for input)
           cmp  ah,0x00
           jne  short @f

           call int16_wait_for_keypress
           mov  al,1             ; increment
           call dequeue_key
           cmp  ah,0x00          ; ah = scan_code
           je   short key_int16_next1
           cmp  al,0xF0          ; al = ascii_code
           je   short key_int16_next2
key_int16_next1:
           cmp  al,0xE0
           jne  short key_int16_next3
key_int16_next2:
           xor  al,al
key_int16_next3:
           mov  REG_AX,ax
           jmp  key_int16_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check for keystroke
@@:        cmp  ah,0x01
           jne  short @f

           xor  al,al            ; don't increment
           call dequeue_key
           jz   short key_int16_next7
           cmp  ah,0x00          ; ah = scan_code
           je   short key_int16_next4
           cmp  al,0xF0          ; al = ascii_code
           je   short key_int16_next5
key_int16_next4:
           cmp  al,0xE0
           jne  short key_int16_next6
key_int16_next5:
           xor  al,al
key_int16_next6:
           mov  REG_AX,ax
           ; clear zero flag
           and  word REG_FLAGS,(~0x0040)
           jmp  key_int16_done
key_int16_next7:
           ; set zero flag
           or   word REG_FLAGS,0x0040
           jmp  key_int16_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get shift flag status
@@:        cmp  ah,0x02
           jne  short @f
           mov  al,[0x0017]
           mov  REG_AL,al
           jmp  key_int16_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set typematic rate and delay
@@:        cmp  ah,0x03
           jne  short @f
           mov  al,REG_AL

           ; set default delay and rate
           cmp  al,0x00
           jne  short key_int16_rate_0
           ; PCjr and PS/2 only?
           jmp  key_int16_done

           ; increase delay before repeat
key_int16_rate_0:
           cmp  al,0x01
           jne  short key_int16_rate_1
           ; PCjr only?
           jmp  key_int16_done

           ; decrease repeat rate by factor of 2
key_int16_rate_1:
           cmp  al,0x02
           jne  short key_int16_rate_2
           ; PCjr only?
           jmp  key_int16_done

           ; increase delay and decrease repeat rate
key_int16_rate_2:
           cmp  al,0x03
           jne  short key_int16_rate_3
           ; PCjr only?
           jmp  key_int16_done

           ; turn off typematic repeat
key_int16_rate_3:
           cmp  al,0x04
           jne  short key_int16_rate_4
           ; PCjr and PS/2 only?
           jmp  key_int16_done

           ; set repeat rate and delay
key_int16_rate_4:
           cmp  al,0x05
           jne  key_int16_done

           ; send the tprate command
           mov  al,0xF3
           out  PORT_PS2_DATA,al
           call kbd_out_full
           in   al,PORT_PS2_DATA  ; get the 0xFA (acknowledge)

           ; send the data byte
           ; repeat rate in bits 4:0 (00000b = 30hz, ..., 11111b = 2Hz)
           ; delay in bits 6:5 (00b = 250ms, 01b = 500ms, 10b = 750ms, 11b = 1000ms)
           ; bit 7 = 0
           mov  al,REG_BL        ; BL = repeat rate
           and  al,00011111b
           mov  ah,REG_BH        ; BH = delay
           and  ah,00000011b
           shl  ah,5
           or   al,ah
           out  PORT_PS2_DATA,al
           call kbd_out_full
           in   al,PORT_PS2_DATA  ; get the 0xFA (acknowledge)
           jmp  key_int16_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; enqueue a keystroke
@@:        cmp  ah,0x05
           jne  short @f
           mov  ax,REG_CX
           call enqueue_key      ; al = 1 = success
           xor  al,1             ; need to toggle it
           mov  REG_AL,al
           jmp  key_int16_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get keyboard functionality
@@:        cmp  ah,0x09
           jne  short @f
           ; bit  us   Description
           ;  7   N   reserved
           ;  6   N   INT 16/AH=20h-22h supported (122-key keyboard support)
           ;  5   Y   INT 16/AH=10h-12h supported (enhanced keyboard support)
           ;  4   Y   INT 16/AH=0Ah supported
           ;  3   N   INT 16/AX=0306h supported
           ;  2   N   INT 16/AX=0305h supported
           ;  1   N   INT 16/AX=0304h supported
           ;  0   N   INT 16/AX=0300h supported
           mov  byte REG_AL,0x30
           jmp  key_int16_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Get keyboard ID
@@:        cmp  ah,0x0A
           jne  short @f

           xor  bx,bx
           mov  al,0xF2
           out  PORT_PS2_DATA,al
           call kbd_out_full
           in   al,PORT_PS2_DATA
           cmp  al,0xFA
           jne  short key_int16_next9
           mov  cx,2
key_int16_next8:
           call kbd_out_full
           in   al,PORT_PS2_DATA
           shr  bx,8
           mov  bh,al
           loop key_int16_next8
key_int16_next9:
           mov  REG_BX,bx
           jmp  key_int16_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get enhanced keystroke
@@:        cmp  ah,0x10
           jne  short @f

           call int16_wait_for_keypress
           mov  al,1             ; increment
           call dequeue_key
           cmp  ah,0x00          ; ah = scan_code
           je   short key_int16_next11
           cmp  al,0xF0          ; al = ascii_code
           jne  short key_int16_next11
           xor  al,al
key_int16_next11:
           mov  REG_AX,ax
           jmp  short key_int16_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check for enhanced keystroke
@@:        cmp  ah,0x011
           jne  short @f
           xor  al,al            ; don't increment
           call dequeue_key
           jz   short key_int16_next13
           cmp  ah,0x00          ; ah = scan_code
           je   short key_int16_next12
           cmp  al,0xF0          ; al = ascii_code
           jne  short key_int16_next12
           xor  al,al
key_int16_next12:
           mov  REG_AX,ax
           ; clear zero flag
           and  word REG_FLAGS,(~0x0040)
           jmp  short key_int16_done
key_int16_next13:
           ; set zero flag
           or   word REG_FLAGS,0x0040
           jmp  short key_int16_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get extended keyboard status
@@:        cmp  ah,0x12
           jne  short @f
           mov  ah,[0x0018]
           and  ah,0x73
           mov  al,[0x0096]
           and  al,0x0C
           or   ah,al
           mov  al,[0x0017]
           mov  REG_AX,ax
           jmp  short key_int16_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Get Keyboard information ???
@@:        cmp  ah,0x6F
           jne  short @f
           cmp  byte REG_AL,0x08
           jne  short key_int16_done
           mov  byte REG_AH,0x02 ; unsupported
           jmp  short key_int16_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; keyboard capabilities check (called by DOS 3.2+)
@@:        cmp  ah,0x92
           jne  short @f
           mov  byte REG_AH,0x80
           jmp  short key_int16_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 122 keys capability check (called by DOS 3.2+)
@@:        cmp  ah,0xA2
           jne  short @f
           ; mov  byte REG_AH,0x00
           jmp  short key_int16_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        ;cmp  ah,0x  ; next value
           ;jne  short @f
           ;
           ;
           ;jmp  short key_int16_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; print a message of this unknown call value
           ;push ds
           ;push cs
           ;pop  ds
           ;shr  ax,8
           ;push ax
           ;mov  si,offset key_int16_unknown_call_str
           ;call bios_printf
           ;add  sp,2
           ;call freeze
           ;pop  ds

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function was successful
key_int16_done:
           mov  sp,bp
           pop  bp
           ret
int16_function endp

key_int16_unknown_call_str  db 'key_int16: Unknown call 0x%02X',13,10,0

.end
