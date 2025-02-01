comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: mouse.asm                                                          *
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
*   mouse services file                                                    *
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
; dis/enables the mouse's interrupts and events
; on entry:
;  al = 0 = disabled, 1 = enable
; on return
;  al = command byte read
; destroys nothing
enable_mouse_int_and_events proc near uses bx
           mov  bl,al            ; save dis/enable flag
           
           in   al,PORT_PS2_STATUS
           test al,0x02
           jnz  short enable_mouse_ret
           
           ; get command byte
           mov  al,0x20
           out  PORT_PS2_STATUS,al
@@:        in   al,PORT_PS2_STATUS
           test al,1
           jz   short @b
           in   al,PORT_PS2_DATA
           mov  ah,al        ; save for return

           in   al,PORT_PS2_STATUS
           test al,0x02
           jnz  short enable_mouse_ret

           mov  al,ah
           ; bl = 0 = disable, 1 = enable
           or   bl,bl            ; disable?
           jnz  short @f
           and  al,0xFD          ; turn off IRQ 12 generation
           or   al,0x20          ; disable mouse serial clock
           jmp  short enable_mouse_write
@@:        or   al,0x02          ; turn on IRQ 12 generation
           and  al,0xDF          ; enable mouse serial clock
enable_mouse_write:
           push ax
           mov  al,0x60          ; write command byte
           out  PORT_PS2_STATUS,al
           pop  ax
           out  PORT_PS2_DATA,al
           
           mov  al,ah
           clc
           ret

enable_mouse_ret:
           xor  al,al
           stc
           ret
enable_mouse_int_and_events endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a byte to the mouse
; on entry:
;  al = byte to write
; on return
;  carry clear:
;    success
;  carry set:
;    error
; destroys nothing
; notes:
;  any byte sent should return an 0xFA (acknowledge)
;  we check it here
send_to_mouse_ctrl proc near uses ax
           mov  ah,al            ; save the byte to write

           in   al,PORT_PS2_STATUS
           test al,0x02
           jnz  short @f
           
           mov  al,0xD4          ; write mouse byte
           out  PORT_PS2_STATUS,al
           mov  al,ah
           out  PORT_PS2_DATA,al

           ; get the acknowledge
           call get_mouse_data
           jc   short @f
           cmp  al,0xFA
           jne  short @f
           
           ; return success
           clc
           ret

           ; return failure
@@:        stc
           ret
send_to_mouse_ctrl endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a byte to the keyboard
; on entry:
;  al = byte to write
; on return
;  carry clear:
;    success
;  carry set:
;    error
; destroys nothing
set_kbd_command_byte proc near uses ax
           mov  ah,al            ; save the byte to write
           
           in   al,PORT_PS2_STATUS
           test al,0x02
           jnz  short @f

           mov  al,0xD4          ; write mouse byte
           out  PORT_PS2_STATUS,al
           mov  al,0x60          ; write command byte
           out  PORT_PS2_STATUS,al
           mov  al,ah
           out  PORT_PS2_DATA,al

           clc
           ret
           
@@:        stc
           ret
set_kbd_command_byte endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get a byte from the mouse controller
; on entry:
;  nothing
; on return
;  carry clear:
;    al = byte read
;  carry set:
;    error
; destroys nothing
get_mouse_data proc near uses cx
           
           ; remember to preserved ah

           mov  cx,20000   ; unknown how many times we should loop????
@@:        in   al,PORT_PS2_STATUS
           and  al,0x21
           cmp  al,0x21
           loopne short @b
           jcxz short @f

           in   al,PORT_PS2_DATA

           ; return success
           clc
           ret

           ; return fail
@@:        stc
           ret
get_mouse_data endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; BIOS Services (MOUSE)
; on entry:
;  ds = 0x0040
;  stack currently has (after we set bp):
;   flags    cs      ip      es      ds
;  [bp+44] [bp+42] [bp+40] [bp+38] [bp+36]
;    edi     esi     ebp     esp     ebx     edx     ecx     eax
;  [bp+04] [bp+08] [bp+12] [bp+16] [bp+20] [bp+24] [bp+28] [bp+32]
; on return
;   0x00: success
;   0x01: invalid subfunction (AL > 9)
;   0x02: invalid input value (out of allowable range)
;   0x03: interface error
;   0x04: resend command received from mouse controller,
;         device driver should attempt command again
;   0x05: cannot enable mouse, since no far call has been installed
;   0x80/0x86: mouse service not implemented
; destroys all general (preserved by interrupt call)
int15_function_mouse proc near ; don't put anything here
           push bp
           mov  bp,sp

           ; get the address to the EBDA
           call bios_get_ebda
           mov  es,ax

           mov  al,REG_AL
           ; ds = 0x40
           ; es = segment to EBDA
           ; al = subservice

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; enable/disable mouse
           cmp  al,0x00
           jne  short @f

           cmp  byte REG_BH,0x00 ; disable
           jne  short mouse_int15_00_1
           
           ; disable the mouse
           xor  al,al            ; disable IRQ12 and packet
           call enable_mouse_int_and_events
           jc   mouse_int15_fail
           
           mov  al,0xF5          ; disable mouse command
           call send_to_mouse_ctrl
           jc   mouse_int15_fail
           jmp  mouse_int15_success

mouse_int15_00_1:
           ; enable the mouse
           cmp  byte REG_BH,0x01 ; enable
           jne  short mouse_int15_00_3

           test byte es:[EBDA_DATA->mouse_flags],0x80
           jnz  short mouse_int15_00_2
           mov  byte REG_AH,0x05 ; no far call handler
           jmp  mouse_int15_fail_noah
mouse_int15_00_2:
           xor  al,al            ; disable IRQ12 and packet
           call enable_mouse_int_and_events
           jc   mouse_int15_fail
           mov  al,0xF4
           call send_to_mouse_ctrl            ; enable mouse command
           jc   mouse_int15_fail
           mov  al,1             ; turn IRQ12 and packet generation on
           call enable_mouse_int_and_events
           jc   mouse_int15_fail
           jmp  mouse_int15_success

mouse_int15_00_3:
           ; unknown sub/sub/call
           xchg cx,cx
           jmp  mouse_int15_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; reset (0x01) or initialize (0x05) mouse
@@:        cmp  al,0x01
           je   short mouse_reset_init_0
           cmp  al,0x05
           jne  short @f
           
           ; service 0x05 only (initialize)
           ; check packet size (we only support 3 and 4)
           mov  byte REG_AH,0x02 ; assume invalid packet size
           mov  bh,REG_BH
           cmp  bh,0x01
           jb   mouse_int15_fail_noah
           cmp  bh,0x08
           ja   mouse_int15_fail_noah
           mov  al,es:[EBDA_DATA->mouse_flags]
           and  al,0xF8
           or   al,bh
           mov  byte es:[EBDA_DATA->mouse_index],0x00
           mov  es:[EBDA_DATA->mouse_flags],al

           ; both services 0x01 and 0x05
mouse_reset_init_0:
           xor  al,al            ; disable IRQ12 and packet
           call enable_mouse_int_and_events
           jc   mouse_int15_fail
           
           mov  al,0xFF
           call send_to_mouse_ctrl
           jc   mouse_int15_fail
           call get_mouse_data   ; byte 0 (0xAA)
           jc   mouse_int15_fail
           mov  bl,al
           call get_mouse_data   ; byte 1 (0x00)
           jc   mouse_int15_fail
           mov  bh,al
           mov  REG_BX,bx
           
           mov  al,1             ; turn IRQ12 and packet generation on
           call enable_mouse_int_and_events
           jc   mouse_int15_fail
           jmp  mouse_int15_success
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set sample rate
@@:        cmp  al,0x02
           jne  short @f

           mov  bh,REG_BH        ; sample rate
           mov  al,10            ; bl == 0, sample rate = 10
           cmp  bh,0x00
           je   short mouse_sample_rate_0
           mov  al,20            ; bl == 1, sample rate = 20
           cmp  bh,0x01
           je   short mouse_sample_rate_0
           mov  al,40            ; bl == 2, sample rate = 40
           cmp  bh,0x02
           je   short mouse_sample_rate_0
           mov  al,60            ; bl == 3, sample rate = 60
           cmp  bh,0x03
           je   short mouse_sample_rate_0
           mov  al,80            ; bl == 4, sample rate = 80
           cmp  bh,0x04
           je   short mouse_sample_rate_0
           mov  al,100           ; bl == 5, sample rate = 100
           cmp  bh,0x05
           je   short mouse_sample_rate_0
           mov  al,200           ; bl == 6, sample rate = 200
           cmp  bh,0x06
           ja   mouse_int15_fail  ; bl > 6 (error)
mouse_sample_rate_0:
           mov  ah,al            ; save the sample rate
           mov  al,0xF3          ; set sample rate command
           call send_to_mouse_ctrl
           jc   mouse_int15_fail
           mov  al,ah            ; restore sample rate
           call send_to_mouse_ctrl
           jc   mouse_int15_fail
           jmp  mouse_int15_success
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Set Resolution
@@:        cmp  al,0x03
           jne  short @f

           ; must be 0, 1, 2, or 3
           mov  bh,REG_BH
           cmp  bh,0x03
           ja   mouse_int15_fail

           ; disable the mouse
           xor  al,al            ; disable IRQ12 and packet
           call enable_mouse_int_and_events
           jc   mouse_int15_fail
           mov  ah,al            ; save the command byte read
           
           mov  al,0xE8          ; set resolution command
           call send_to_mouse_ctrl
           jc   short mouse_restore_fail
           mov  al,bh
           call send_to_mouse_ctrl
           jc   short mouse_restore_fail
           
           ; success, and restore function
mouse_restore_success:
           mov  al,ah
           call set_kbd_command_byte
           jc   mouse_int15_fail
           jmp  mouse_int15_success
           ; fail, and restore function
mouse_restore_fail:
           mov  al,ah
           call set_kbd_command_byte
           jmp  mouse_int15_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get device id
@@:        cmp  al,0x04
           jne  short @f

           ; disable the mouse
           xor  al,al            ; disable IRQ12 and packet
           call enable_mouse_int_and_events
           jc   mouse_int15_fail
           ;mov  ah,al            ; save the command byte read

           mov  al,0xF2          ; get mouse ID command
           call send_to_mouse_ctrl
           jc   short mouse_restore_fail
           call get_mouse_data   ; id
           jc   short mouse_restore_fail
           mov  REG_BH,al
           ;jmp  short mouse_restore_success     ; Bochs doesn't restore the int/events..........................
           jmp  mouse_int15_success
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; return Status or set Scaling Factor
@@:        cmp  al,0x06
           jne  short @f

           ; subfunction
           mov  bh,REG_BH
           cmp  bh,0x00          ; return status
           jne  short mouse_status_sf_0
           ; return status
           
mouse_return_status:
           ; disable the mouse
           xor  al,al            ; disable IRQ12 and packet
           call enable_mouse_int_and_events
           jc   mouse_int15_fail
           mov  ah,al            ; save the command byte read

           mov  al,0xE9          ; get mouse info command
           call send_to_mouse_ctrl
           jc   short mouse_restore_fail
           call get_mouse_data   ; byte 0
           jc   short mouse_restore_fail
           mov  REG_BL,al
           call get_mouse_data   ; byte 1
           jc   short mouse_restore_fail
           mov  REG_CL,al
           call get_mouse_data   ; byte 2
           jc   short mouse_restore_fail
           mov  REG_DL,al
           jmp  short mouse_restore_success

           ; set Scaling Factor to 1:1 or 2:1
mouse_status_sf_0:
           ; disable the mouse
           xor  al,al            ; disable IRQ12 and packet
           call enable_mouse_int_and_events
           jc   short mouse_int15_fail
           mov  ah,al            ; save the command byte read

           mov  al,0xE6          ; assume 1:1
           cmp  bh,0x01          ; 1:1
           je   short mouse_status_sf_1
           cmp  bh,0x02          ; 2:1
           jne  short mouse_status_sf_2
           inc  al  ; 0xE7       ; 2:1
mouse_status_sf_1:
           call send_to_mouse_ctrl
           jc   short mouse_restore_fail
           jmp  mouse_restore_success
           
mouse_status_sf_2:
           ; unknown sub function
           xchg cx,cx
           jmp  short mouse_int15_fail
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set Mouse Handler Address
@@:        cmp  al,0x07
           jne  short @f

           mov  ax,REG_ES
           mov  es:[EBDA_DATA->mouse_driver_seg],ax
           mov  bx,REG_BX
           mov  es:[EBDA_DATA->mouse_driver_offset],bx
           
           ; will be 0000:0000 to remove the handler
           or   ax,ax
           jnz  short mouse_set_handler_0
           or   bx,bx
           jnz  short mouse_set_handler_0

           ; remove it
           test byte es:[EBDA_DATA->mouse_flags],0x80
           jz   short mouse_set_handler_1
           
           ; clear the flag and disable the mouse
           and  byte es:[EBDA_DATA->mouse_flags],0x7F
           xor  al,al            ; disable IRQ12 and packet
           call enable_mouse_int_and_events
           jc   short mouse_int15_fail
           jmp  short mouse_set_handler_1

mouse_set_handler_0:
           ; set the flag (don't enable the mouse)
           or   byte es:[EBDA_DATA->mouse_flags],0x80

mouse_set_handler_1:
           jmp  short mouse_int15_success
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; write to pointer port
@@:        cmp  al,0x08
           jne  short @f
           
           ; bl = byte to write
           mov  al,bl
           call send_to_mouse_ctrl
           jc   short mouse_int15_fail
           jmp  short mouse_int15_success
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read (three bytes) from pointer port
@@:        cmp  al,0x09
           jne  short @f
           ; this is that same as calling subfunction 0x06/BH = 0x00
           jmp  mouse_return_status

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        ;cmp  al,0x  ; next value
           ;jne  short @f
           ;
           ;
           ;jmp  hd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; print a message of this unknown call value
           xchg cx,cx
           push ds
           push cs
           pop  ds
           push ax
           push 3
           mov  si,offset srvs_15_unknown_call_str
           call bios_printf
           add  sp,4
           pop  ds

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function failed, or we didn't support function in AH
mouse_int15_fail:
           mov  byte REG_AH,0x01 ; invalid (sub)function or parameter
mouse_int15_fail_noah:
           or   word REG_FLAGS,0x0001
           mov  sp,bp
           pop  bp
           ret

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function was successful
mouse_int15_success:
           mov  byte REG_AH,0x00 ; success
           and  word REG_FLAGS,(~0x0001)
           mov  sp,bp
           pop  bp
           ret
int15_function_mouse endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; BIOS Services (MOUSE IRQ)
; on entry:
;  ds = segment of EBDA
;  stack currently has (after we set bp):
;   [bp+0x0A] = place holder for 'status'
;   [bp+0x08] = place holder for 'x'
;   [bp+0x06] = place holder for 'y'
;   [bp+0x04] = place holder for 'z'
; on return:
;  al = 0 = no far call, 1 = do far call
; caller saves all registers
int74_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           
           in   al,PORT_PS2_STATUS
           and  al,0x21   ; bit 5 = mouse output buffer full, bit 0 = output buffer full
           cmp  al,0x21
           jne  short int74_function_done

           ; read the byte
           in   al,PORT_PS2_DATA

           ; if no driver loaded, don't call it
           test byte [EBDA_DATA->mouse_flags],0x80
           jz   short int74_function_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; are we at byte 0?
           cmp  byte [EBDA_DATA->mouse_index],0
           jne  short @f

           ; we might be at byte index zero. If so, bit 3 should be set
           ; if not set, ignore the byte and ready for the next one
           test al,(1<<3)
           jz   short int74_function_done
           
           ; bit 3 is set and we think we are at index zero
           ; clear the packet buffer
           mov  dword [EBDA_DATA->mouse_data+0],0
           mov  dword [EBDA_DATA->mouse_data+4],0
           mov  byte  [EBDA_DATA->mouse_index],0
           jmp  short int74_function_next
           
           ; make sure we don't overrun our buffer
@@:        cmp  byte [EBDA_DATA->mouse_index],8
           je   short int74_function_packet
           
           ; we think we are at byte 1,2,3,4,5,6,or 7
           ; store the byte and ready for the next or done
int74_function_next:
           movzx bx,byte [EBDA_DATA->mouse_index]
           and  bx,0x0F
           mov  [bx+EBDA_DATA->mouse_data],al
           inc  byte [EBDA_DATA->mouse_index]
           
           ; are we at the user specified packet size?
           mov  al,[EBDA_DATA->mouse_flags]
           and  al,0xF
           cmp  [EBDA_DATA->mouse_index],al
           jb   short int74_function_done

           ; else, we are at the user specified packet size
int74_function_packet:
           xor  ah,ah            ; high order byte = 0
           mov  al,[EBDA_DATA->mouse_data+0]
           mov  [bp+0x0A],ax     ; status
           mov  al,[EBDA_DATA->mouse_data+1]
           mov  [bp+0x08],ax     ; X
           mov  al,[EBDA_DATA->mouse_data+2]
           mov  [bp+0x06],ax     ; Y
           mov  al,[EBDA_DATA->mouse_data+3]
           mov  [bp+0x04],ax
           mov  byte [EBDA_DATA->mouse_index],0x00

           ; we have a driver installed, so call it
           mov  al,1             ; al = 1 = make the far call
           mov  sp,bp            ; restore the stack
           pop  bp
           ret

int74_function_done:
           xor  al,al            ; al = 0 = don't make the far call
           mov  sp,bp            ; restore the stack
           pop  bp
           ret
int74_function endp

.end
