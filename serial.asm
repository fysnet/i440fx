comment |*******************************************************************
*  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: serial.asm                                                         *
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
*   serial include file                                                    *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.15                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 20 Jan 2025                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the serial port(s)
; on entry:
;  es = 0x0000
; on return
;  nothing
; destroys all general
init_serial proc near
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set the interrupt vector
           mov  ax,0x14
           mov  bx,offset int14_handler
           mov  cx,0xE000
           call set_int_vector

           xor  bx,bx
           mov  cl,10            ; timeout value (default to 10)
           mov  dx,0x03F8        ; Serial I/O address, port 1
           call detect_serial
           mov  dx,0x02F8        ; Serial I/O address, port 2
           call detect_serial
           mov  dx,0x03E8        ; Serial I/O address, port 3
           call detect_serial
           mov  dx,0x02E8        ; Serial I/O address, port 4
           call detect_serial
           shl  bx,9
           mov  ax,es:[0x410]    ; Equipment word bits 9..11 determine # serial ports
           and  ax,0xF1FF
           or   ax,bx            ; set number of serial port
           mov  es:[0x410],ax
           ret
init_serial endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; detect a serial port
; on entry:
;  es = 0x000
;  cl = timeout value
;  dx = port value
;  bx = index (0, 1, 2, or 3)
; on return
;  al = type: 0 = none, 1 = 8250, 2 = 16450 (or 8250 w/ scratch reg), 3 = 16550, 4 = 16550A
;  bx = new index
; destroys ax bx dx
detect_serial proc near uses si
           mov  si,dx            ; save port base address

           ; try to toggle the CTS, DSR, RI, and DCD bits (clear)
           add  dx,4             ; base + 4
           in   al,dx
           mov  ah,al            ; save the byte read
           mov  al,0x10          ; put in loop mode (CTS, DSR, RI, and DCD = 0)
           out  dx,al
           add  dx,2             ; base + 6
           in   al,dx            ; read modem status
           and  al,0xF0          ; inverted CTS, DSR, RI, or DCD are set, no UART
           mov  al,0             ; assume no UART attached
           jnz  short detect_serial_none

           ; try to toggle the CTS, DSR, RI, and DCD bits (set)
           sub  dx,2             ; base + 4
           mov  al,0x1F          ; put in loop mode (CTS, DSR, RI, and DCD = 1)
           out  dx,al            ; 
           add  dx,2             ; base + 6
           in   al,dx            ; read modem status
           and  al,0xF0          ; 
           cmp  al,0xF0          ; CTS, DSR, RI, or DCD should all be set
           mov  al,0             ; assume no UART attached
           jne  short detect_serial_none

           ; we have an UART, so restore the Modem Control Register
           sub  dx,2             ; base + 4
           mov  al,ah            ;
           out  dx,al            ;

           ; we have at least a 8250
           ; see if we have a scratch register
           ; write 0x55/0xAA and read them back to see if it matches
           add  dx,3             ; base + 7
           in   al,dx            ;
           mov  ah,al            ; save the value read
           mov  al,0x55          ; try 0x55
           out  dx,al            ;
           in   al,dx            ;
           cmp  al,0x55          ; did we read 0x55
           mov  al,1             ; no? then an 8250
           jne  short detect_serial_done
           mov  al,0xAA          ; try 0xAA
           out  dx,al            ;
           in   al,dx            ;
           cmp  al,0xAA          ; did we read 0xAA
           mov  al,1             ; no? then an 8250
           jne  short detect_serial_done

           ; we have an UART with a scratch register (8250 or 16450)
           ;  restore the original value
           mov  al,ah            ;
           out  dx,al            ;

           ; now check if there is a FIFO
           sub  dx,5             ; base + 2
           mov  al,1             ; enable FIFO
           out  dx,al            ;
           in   al,dx            ;
           mov  ah,al            ; save value read
           xor  al,al            ; some older software relies that the FIFO is not enabled
           out  dx,al            ;

           ; test the result     ; bit 7:6 = 00 = no FIFO, = 01 = unusable, 1x = enabled
           mov  al,2             ; assume a UART with a scratch register (8250 or 16450)
           test ah,0x80          ; bit 7 set = enabled
           jz   short detect_serial_done

           mov  al,3             ; assume a UART with a scratch register (16550, no FIFO)
           test ah,0x40          ; bit 6 set = unusable FIFO
           jz   short detect_serial_done

           ; else we have a 16550A, with scratch register and usable FIFO
           mov  al,4

detect_serial_done:
           ; (remember to preserve 'al' here)
           ; write the address to the BDA
           mov  dx,si            ; restore port base address
           push bx
           shl  bx,1
           mov  es:[bx+0x400],dx ; Serial I/O address
           pop  bx
           mov  es:[bx+0x47C],cl ; Serial timeout
           inc  bx
           
           ; make sure there isn't a pending interrupt
           call eoi_master_pic

detect_serial_none:
           ret
detect_serial endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; serial function call
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
int14_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           
           sti                   ; enable interrupts
           
           ; dx = 0, 1, 2, or 3
           mov  dx,REG_DX
           cmp  dx,3
           ja   serial_function_error

           mov  bx,dx           ; dx = 0, 1, 2, or 3
           mov  cl,[bx+0x007C]  ; timeout counter[dx]
           xor  ch,ch

           imul bx,dx,sizeof(word)
           mov  dx,[bx+0x0000]  ; port addr at [0x0400...0x0407]
           or   dx,dx
           jz   serial_function_error

           mov  ax,REG_AX
           ; dx = serial port io address
           ; cx = timeout counter
           ; ah = service requested

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ;  reset/initialize port
           cmp  ah,0x00
           jne  short @f

           inc  dx               ; base + 1
           xor  al,al            ; disable all interrupts
           out  dx,al            ;

           add  dx,2             ; base + 3
           mov  al,0x80          ; enable DLAB (so we can set baud rate divisor)
           out  dx,al            ;

           ; set the baud rate
           ; baud rate = (115200 / word written) (0 = 1047 = baud of ~110)
           mov  bx,1047          ; 115200 / 1047 = 110.0286533
           mov  cl,REG_AL        ; value passed is in bits 7:5 of AL
           shr  cl,5             ; put in cl and test for zero
           jz   short ser_init_0 ; 115200 / (1536 >> 1) = 150
           mov  bx,1536          ; 115200 / (1536 >> 2) = 300
           shr  bx,cl            ; 115200 / (1536 >> 3) = 600
ser_init_0:                      ; 115200 / (1536 >> 4) = 1200, etc.
           sub  dx,3             ; base + 0
           mov  al,bl            ; set divisor
           out  dx,al            ;  (lo byte)
           inc  dx               ; base + 1
           mov  al,bh            ;  (hi byte)
           out  dx,al            ;

           ; set the parity, stop, and data bits
           mov  al,REG_AL
           and  al,000_11_1_11b  ; 4:3 = parity, 2 = stop, 1:0 = data bits
           add  dx,2             ; base + 3
           out  dx,al

           dec  dx               ; base + 2
           mov  al,0xC7          ; enable FIFO, clear them, 14-byte threshold
           out  dx,al

           add  dx,2             ; base + 4
           mov  al,0x03          ; IQR's disabled, TRS/DSR set
           out  dx,al

           inc  dx               ; base + 5
           in   al,dx            ; get line status
           mov  ah,al            ;  return in AH
           inc  dx               ; base + 6
           in   al,dx            ; get line status
           mov  REG_AX,ax        ;  return in AX

           jmp  serial_function_success

           ; dx = serial port io address
           ; cx = timeout counter
           ; ah = service requested
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ;  write character to port
@@:        cmp  ah,0x01
           jne  short @f

           mov  bx,[0x006C]      ; get timer ticks
           add  dx,5             ; base + 5
ser_write_0:
           in   al,dx            ; read the line status
           and  al,01100000b     ; is the tx empty and not doing anything?
           cmp  al,01100000b     ;
           je   short ser_write_1
           jcxz short ser_write_1
           mov  si,[0x006C]      ; get timer ticks
           cmp  si,bx            ;
           je   short ser_write_0
           mov  bx,si            ; we try cx * timer ticks
           loop ser_write_0
ser_write_1:
           jcxz short ser_write_2 ; did we time out?
           sub  dx,5             ; base + 0
           mov  al,REG_AL
           out  dx,al
           add  dx,5             ; base + 5
           in   al,dx            ; return line status
           and  al,0x7F          ; bit 7 clear = success
           mov  REG_AH,al
           jmp  short serial_function_success
ser_write_2:
           mov  al,0x80          ; bit 7 set = error
           mov  REG_AH,al
           jmp  short serial_function_success

           ; dx = serial port io address
           ; cx = timeout counter
           ; ah = service requested
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ;  read character from port
@@:        cmp  ah,0x02
           jne  short @f

           mov  bx,[0x006C]      ; get timer ticks
           add  dx,5             ; base + 5
ser_read_0:
           in   al,dx            ;
           test al,0x01          ; bit 0 set = data ready to be read
           jnz  short ser_read_1
           jcxz short ser_read_1
           mov  si,[0x006C]      ; get timer ticks
           cmp  si,bx            ;
           je   short ser_read_0
           mov  bx,si            ; we try cx * timer ticks
           loop ser_read_0
ser_read_1:
           jcxz short ser_read_2 ; did we time out?
           in   al,dx            ; dx = base + 5
           mov  ah,al            ; line status
           and  ah,0x7F          ; bit 7 clear = success
           sub  dx,5             ; base + 0
           in   al,dx            ; read the char
           mov  REG_AX,ax        ; return
           jmp  short serial_function_success
ser_read_2:
           mov  al,0x80          ; bit 7 set = error
           mov  REG_AH,al
           jmp  short serial_function_success

           ; dx = serial port io address
           ; cx = timeout counter
           ; ah = service requested
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ;  read port status
@@:        cmp  ah,0x03          ; read port status
           jne  short @f

           add  dx,5             ; base + 5
           in   al,dx            ; read the line status
           mov  ah,al            ; place in ah
           inc  dx               ; base + 6
           in   al,dx            ; read the modem status
           mov  REG_AX,ax        ;
           jmp  short serial_function_success

           ; dx = serial port io address
           ; cx = timeout counter
           ; ah = service requested
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ;  
@@:        
           ; unknown function call
           mov  bx,$
           mov  ax,0x3334
           call unsupported

           ;  unknown function number
           jmp  short serial_function_error

serial_function_success:
           ; clear the carry
           and  word REG_FLAGS,(~0x0001)
           mov  sp,bp
           pop  bp
           ret
           
serial_function_error:
           ; set the carry
           or   word REG_FLAGS,0x0001
           mov  sp,bp
           pop  bp
           ret
int14_function endp

.if DO_SERIAL_DEBUG
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a char or string of chars to a serial port
; (don't call before we call 'detect_serial' above)
; on entry:
;  ah = 1 = send a char
;    al = char
;  ah = 2 = send a string of chars
;    ds:si-> asciiz string
;  ah = 3 = send a string of bytes
;    fs:esi-> string
;    cx = count
;  dx = com port (0 = first, 1 = second, etc)
; on return
;  nothing
; destroys none
debug_serial_out proc near uses alld es
           xor  bx,bx
           mov  es,bx

           ; get the com port address
           imul bx,dx,sizeof(word)
           mov  dx,es:[bx+0x0400] ; Serial I/O address
           or   dx,dx
           jz   short debug_serial_out_done

           cmp  ah,1
           jne  short debug_serial_out_0
           call debug_serial_char
           jmp  short debug_serial_out_done

debug_serial_out_0:
           cmp  ah,2
           jne  short debug_serial_out_1
@@:        lodsb
           or   al,al
           jz   short debug_serial_out_done
           call debug_serial_char
           jmp  short @b

debug_serial_out_1:
           cmp  ah,3
           jne  short debug_serial_out_2
           xor  bx,bx
debug_serial_out_1a:
           mov  al,fs:[esi]
           inc  esi
           push ax
           shr  al,4
           add  al,'0'
           cmp  al,'9'
           jbe  short @f
           add  al,7           
@@:        call debug_serial_char
           pop  ax
           and  al,0x0F
           add  al,'0'
           cmp  al,'9'
           jbe  short @f
           add  al,7           
@@:        call debug_serial_char
           mov  al,' '
           inc  bl
           cmp  bl,8
           jne  short @f
           mov  al,'-'
@@:        cmp  bl,16
           jne  short @f
           mov  al,10
           xor  bl,bl
@@:        call debug_serial_char
           loop debug_serial_out_1a
           mov  al,10
           call debug_serial_char
           jmp  short debug_serial_out_done

debug_serial_out_2:


debug_serial_out_done:
           ret
debug_serial_out endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a char to a serial port
; on entry:
;  al = char
;  dx = com port address (0x3F8, 0x2F8, 0x3E8, 0x2E8)
; on return
;  nothing
; destroys none
debug_serial_char proc near uses ax dx
           add  dx,5      ; base + 5
           push ax
@@:        in   al,dx
           and  al,01100000b
           cmp  al,01100000b
           jne  short @b
           pop  ax

           sub  dx,5      ; base + 0
           out  dx,al
           ret
debug_serial_char endp

debug_regs_str  db  'eax=0x%08lX ebx=0x%08lX ecx=0x%08lX edx=0x%08lX esi=0x%08lX edi=0x%08lX esp=0x%08lX ds=0x%04X es=0x%04X fs=0x%04X',13,10,0

debug_regs proc near uses alld ds
           mov  ebp,esp

           push fs
           push es
           push ds
           push ebp
           push edi
           push esi
           push edx
           push ecx
           push ebx
           push eax
           push cs
           pop  ds
           mov  si,offset debug_regs_str
           call bios_printf
           add  sp,34

           ret
debug_regs endp


           ;mov  si,offset debug_regs
           ;call far offset E000_call,0xE000
;E000_call  proc near
;           call si
;           retf
;E000_call  endp

;mouse_str  db  'status = 0x%02X, x = %i, y = %i, z = %i',13,10,0
;E000_call  proc near uses si ds
;           
;           push dx
;           push cx
;           push bx
;           push ax
;           push cs
;           pop  ds
;           mov  si,offset mouse_str
;           call bios_printf
;           add  sp,8
;           
;           retf
;E000_call  endp


.endif

.end
