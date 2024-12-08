comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: cmos.asm                                                           *
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
*   main source file                                                       *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.14                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 8 Dec 2024                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
* Todo:                                                                    *
*  - at the comment below, where we check the memory, create the E820      *
*    list of memory. then at the E820 service call, simply choose the      *
*    correct entry in the list.                                            *
*  - add usb drives to the drive emulation                                 *
*  - pci                                                                   *
*  - bochs graphic boot screen                                             *
*  - should check for 586+ (but won't be able to print if not)(beep???)    *
*  -                                                                       *
*                                                                          *
*                                                                          *
***************************************************************************|

.model tiny

include 'i440fx.inc'

outfile 'i440fx.bin'

.code

.if DO_INIT_BIOS32
.586        ; the i440fx is a Pentium+, so 586 would be okay here (required for DO_INIT_BIOS32 == 1)
.else
.386P       ; Legacy can be 80x386
.endif

; make sure we are using an assembler that supports the new items included here
.if (_VER < 2714h)
%error 1, 'This source requires NBASM version 00.27.14 or higher'
.end  ; if we get this error, be done. No need to continue on.
.endif

.rmode
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ;  we are loaded to 0xE0000
           ;  this address is E000:0000
           org 0x00000

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; POST: Main Post entry point
           ;  this address is E000:0000

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; setup our segments
           mov  ax,0xE000              ; ds = this segment
           mov  ds,ax                  ;
           xor  ax,ax                  ; es and ss = 0x0000
           mov  es,ax                  ;
           mov  ss,ax                  ; top of stack at 0000:FFFF
           mov  sp,ax                  ;  (0x0FFFF)
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ;  Check for 386+ machine.
           pushf                   ; save the interrupt bit
           push 0F000h             ; if bits 15:14 are still set
           popf                    ;  after pushing/poping to/from
           pushf                   ;  the flags register then we have
           pop  ax                 ;  a 386+
           and  ax,0F000h          ;
@@:        jz   short @b           ; it's not a 386+
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; since we have a working conio that uses int 10h
           ;  fairly early in the initialization, we need to
           ;  set INT 10h to simply iret until we initialize
           ;  the video rom.
           mov  ax,0x10                ; interrtupt 10h
           mov  bx,offset int10_handler
           mov  cx,BIOS_BASE
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Reset and initialize the DMA controller(s)
           xor  ax,ax
           out  PORT_DMA1_MASTER_CLEAR,al
           out  PORT_DMA2_MASTER_CLEAR,al
           mov  al,0xC0
           out  PORT_DMA2_MODE_REG,al
           xor  al,al
           out  PORT_DMA2_MASK_REG,al
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Depending on the Shutdown status, we need to
           ;  possibly skip certian items.
           ; Get the current status, and reset it for next time
           mov  ah,0x0F
           call cmos_get_byte
           mov  bl,al                  ; save the shutdown status in BL
           mov  ax,0x0F00
           call cmos_put_byte

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if status was 0x00 or 0x0D and above, do normal post
           cmp  bl,0x00
           je   short normal_post
           cmp  bl,0x0D
           jae  short normal_post
           
           ; if status was 0x05, use the eoi and the jmp 0040:0067
           cmp  bl,0x05
           je   short eoi_jmp_post

           ; if status was 0x0A, use the jmp at 0040:0067
           cmp  bl,0x0A
           je   short jmp_post
           
           ; if status was 0x0B, use the iret at 0040:0067
           cmp  bl,0x0B
           je   short iret_post

           ; if status was 0x0C, use the retf at 0040:0067
           cmp  bl,0x0C
           je   short retf_post
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; else, it is a status we don't know about.
           ; give an error and halt.
           mov  ax,BIOS_BASE2
           mov  ds,ax
           xor  bh,bh
           push bx
           mov  si,offset unknown_shutdown
           call bios_printf
           add  sp,2
           ; freeze
           call freeze

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; POST: various POST functions

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; do EOI and then jmp from 0040:0067h
eoi_jmp_post:
           call init_pic

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; jmp from 0040:0067h
jmp_post:  xor  ax,ax
           mov  ds,ax
           jmp  far [0x0467]

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; iret from 0040:0067h
iret_post: xor  ax,ax
           mov  ds,ax
           mov  sp,[0x0467]
           mov  ss,[0x0469]
           iret

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; retf from 0040:0067h
retf_post: xor  ax,ax
           mov  ds,ax
           mov  sp,[0x0467]
           mov  ss,[0x0469]
           retf
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; do a s3 post
s3_post:   ;mov  sp,0x0FFE
.if DO_INIT_BIOS32
           call rombios32_init
           ; we can now write to 0x000E0000->0x000FFFFF
.endif
           call s3_resume
           xor  bl,bl
           and  ax,ax
           jz   short normal_post
           
           mov  ax,BIOS_BASE2
           mov  ds,ax
           mov  si,offset s3_resume_error
           call bios_printf
           ;add  sp,2
           call freeze
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; do a normal post bootup
           ; shutdown status is in BL
           ; cs = 0xE000
           ; ds = 0xE000
           ; es = 0x0000
           ; ss = 0x0000
           ; sp = 0x0000 (first push at 0x0000:FFFE)
normal_post:
           cli
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; use unreal mode for fs
           call unreal_post
           
           ; save the shutdown status
           mov  es:[0x04B0],bl
           
           ; if shutdown status == 0xFE, do S2 post
           cmp  bl,0xFE
           je   short s3_post
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; clear out the BDA (0x0040:0000 - > 0x0040:00FF)
           mov  cx,128   ; 128 words
           xor  ax,ax
           mov  di,0x0400
           cld
           rep
             stosw

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the IVT
           call post_init_ivt
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; base memory size
           mov  ax,BASE_MEM_IN_K
           mov  es:[0x0413],ax
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if we wanted to do a manufacturer's test, this
           ;  is where we would do it
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if we wanted to test the memory, this is where
           ;  we would do it
           ; if [0x0472] == 0x1234, then skip test
           ; (however, we cleared that memory a few lines above)
           call build_mem_table
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the ebda
           call post_init_ebda
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; PIT setup
           mov  ax,08h
           mov  bx,offset int08_handler
           mov  cx,BIOS_BASE
           call set_int_vector
           
           mov  al,00_11_010_0b     ; channel 0, lo/hi, rate generator, binary mode
           out  PORT_PIT_MODE,al
           xor  al,al
           out  PORT_PIT_CHANNEL0,al
           out  PORT_PIT_CHANNEL0,al
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Keyboard setup
           mov  ax,09h
           mov  bx,offset int09_handler
           mov  cx,0xE000
           call set_int_vector
           mov  ax,16h
           mov  bx,offset int16_handler
           mov  cx,0xE000
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; BIOS Keyboard flags
           xor  al,al
           mov  es:[0x417],al    ; keyboard shift flags, set 1
           mov  es:[0x418],al    ; keyboard shift flags, set 2
           mov  es:[0x419],al    ; keyboard alt-numpad work area
           mov  es:[0x471],al    ; keyboard ctrl-break flag
           mov  es:[0x497],al    ; keyboard status flags 4
           mov  al,0x10
           mov  es:[0x496],al    ; keyboard status flags 3
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Keyboard buffer pointers
           mov  ax,0x001E
           mov  es:[0x041A],ax   ; head pointer
           mov  es:[0x041C],ax   ; tail pointer
           mov  es:[0x0480],ax   ; start pointer
           mov  ax,0x003E
           mov  es:[0x0482],ax   ; end pointer

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Initialize the keyboard
           call init_keyboard
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; move CMOS equipment byte to BDA
           mov  bx,es:[0x0410]
           mov  ah,0x14
           call cmos_get_byte
           mov  bl,al
           mov  es:[0x0410],bx
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the parallel port(s)
           call init_parallel
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the serial port(s)
           call init_serial
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the RTC
           call init_rtc
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; irq9 (irq2 redirect)
           mov  ax,71h
           mov  bx,offset int71_handler
           mov  cx,BIOS_BASE
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; ps2 mouse
           mov  ax,74h
           mov  bx,offset int74_handler
           mov  cx,BIOS_BASE
           call set_int_vector

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; irq13 (fpu exception)
           mov  ax,75h
           mov  bx,offset int75_handler
           mov  cx,BIOS_BASE
           call set_int_vector

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; int 10 dummy
           mov  ax,10h
           mov  bx,offset int10_handler
           mov  cx,BIOS_BASE
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Initialize the PIC
           call init_pic

.if DO_INIT_BIOS32
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ;  here is were we initialize the 32-bit stuff
           call rombios32_init
           ; we can now write to 0x000E0000->0x000FFFFF
.else
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Initialize the PCI
           ; this is done if we are a legacy only....
           call init_pci_bases
           call init_pci_irqs
.endif
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; was the ESCD read from the flash memory?
           call bios_escd_init

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; scan for the video rom
           mov  cx,0xC000
           mov  ax,0xC780
           call pnp_scan_rom
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Hack fix: SeaVGABIOS does not setup a video mode
           mov  dx,0x03D4
           xor  al,al
           out  dx,al
           inc  dx
           in   al,dx
           test al,al
           jnz  short @f
           mov  ax,0x0003
           int  10h
@@:
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we can finally print our banner
           call put_banner
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the boot vectors
           call init_boot_vectors
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the floppy drive(s)
           call init_floppy

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the harddrive(s)/cdrom(s)
           call init_harddrive
           call ata_init
           call sata_detect
           call ata_detect

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the eltorito/USB boot emulation
           call cdemu_init
.if DO_INIT_BIOS32
           call usb_disk_init
.endif

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the apm
           call pnp_initialize

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; scan for the optional rom(s)
           mov  cx,0xC800
           mov  ax,0xE000
           call pnp_scan_rom

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check to see if user pressed the F12 key
           sti        ; enable interrupts
           call interactive_bootkey

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; restore the A20 line (off) and gs and fs limits
           ;call real_post
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; restore the screen mode
           ;call display_restore_default

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we are now ready to boot a device, so call our
           ;  int 19 handler
           xor  ax,ax
           int  19h


           mov  bx,$
           mov  ax,0xFF19
unsupported:
           push cs
           pop  ds
           push bx
           push ax
           mov  si,offset unsupport_str
           call bios_printf
           add  sp,4
           call freeze
unsupport_str  db  13,10,'Unsupported break: ax=0x%04X  bx=0x%04X',13,10,0

;debugout:
;           push ds
;           push cs
;           pop  ds
;           push ax
;           mov  si,offset debugout_str
;           call bios_printf
;           add  sp,2
;           pop  ds
;           ret
;debugout_str  db  'Debugout string: 0x%04X',13,10,0


; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; general interrupt handlers
.even
int00_handler:  ; Division by zero
           mov  bx,$
           mov  ax,0
           call unsupported
           iret
           
.even
int01_handler:  ; Single Step
           mov  bx,$
           mov  ax,1
           call unsupported
           iret
           
.even
int02_handler:  ; NonMaskable
           mov  bx,$
           mov  ax,2
           call unsupported
           iret
           
.even
int03_handler:  ; Break Point
           mov  bx,$
           mov  ax,3
           call unsupported
           iret
           
.even
int04_handler:  ; Overflow
           mov  bx,$
           mov  ax,4
           call unsupported
           iret
           
.even
int05_handler:  ; Bound Fault
           mov  bx,$
           mov  ax,5
           call unsupported
           iret
           
.even
int06_handler:  ; Invalid Opcode
           mov  bx,$
           mov  ax,6
           call unsupported

           ;xchg cx,cx
           ;pop  ax  ; ip
           ;pop  bx  ; cs
           ;pop  cx  ; flags
           ;mov  dx,1234h
           ;xchg cx,cx
           ;iret
           
.even
int07_handler:  ; Processor extension not available
           mov  bx,$
           mov  ax,7
           call unsupported
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; remember that in real mode, when an exception of 8 through 15 occurs, int08_handler through int15_handler will be called.
; we could move the interrupts from int08... to int16..., but then a guest using this BIOS won't be able to 'hook' the
;  correct handler. Therefore, we have no way of knowing if int 0x0D is a General Protection Fault or INT 13h for disk services...
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; System Timer ISR Entry Point
.even
int08_handler:
           sti                   ; allow interrupts again
           push eax
           push ds
           
           mov  ax,0x40
           mov  ds,ax
           
           ; is it time to turn off drive(s)?
           mov  al,[0x0040]
           or   al,al
           jz   short @f
           dec  al
           mov  [0x0040],al
           jnz  short @f

           ; turn motor(s) off?
           push dx
           mov  dx,0x03F2
           in   al,dx
           and  al,0xCF
           out  dx,al
           pop  dx

@@:        mov  eax,[0x006C]     ; get ticks dword
           inc  eax
           ; compare eax to one day's worth of timer ticks at 18.2 hz
           cmp  eax,0x001800B0
           jb   short @f
           ; there has been a midnight rollover at this point
           xor  eax,eax          ; zero out counter
           inc  byte [0x0070]    ; increment rollover flag
@@:        mov  [0x006C],eax     ; store new ticks dword
           ; chain to user timer tick INT 1Ch
           int  1Ch
           cli
           call eoi_master_pic
           pop  ds
           pop  eax
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Keyboard Hardware Service Entry Point
.even
int09_handler:
           cli
           push ax
           mov  al,0xAD          ; disable keyboard
           out  PORT_PS2_STATUS,al
           mov  al,0x0B
           in   al,PORT_PS2_DATA ; read key from keyboard controller
           sti
           push es
           push ds
           pushad
           
           mov  ah,0x4F          ; allow for keyboard intercept
           stc
           int  15h
           push ax               ; push dummy value so our stack is same as REG_xx's
           push bp
           mov  bp,sp
           mov  REG_AL,al        ; adjust the pushed al register
           pop  bp
           pop  ax
           jnc  short int09_done
           
           ; check for extended key
           push 0x0040
           pop  ds
           cmp  al,0xE0
           jne  short @f
           mov  al,[0x0096]      ; mf2_state |= 0x02
           or   al,0x02
           mov  [0x0096],al
           jmp  short int09_done
           
@@:        ; check for pause key
           cmp  al,0xE1
           jne  short @f
           mov  al,[0x0096]      ; mf2_state |= 0x01
           or   al,0x01
           mov  [0x0096],al
           jmp  short int09_done
@@:        call int09_function
           
int09_done:
           popad
           pop  ds
           pop  es
           cli
           call  eoi_master_pic
           
           ; Notify keyboard interrupt complete w/ int 15h, function AX=9102
           mov  ax,0x9102
           int  15h
           
int09_finish:
           mov  al,0xAE          ; enable keyboard
           out  PORT_PS2_STATUS,al
           pop  ax
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
.even
int0A_handler:
           mov  bx,$
           mov  ax,0x0A
           call unsupported
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
.even
int0B_handler:
           mov  bx,$
           mov  ax,0x0B
           call unsupported
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
.even
int0C_handler:
           mov  bx,$
           mov  ax,0x0C
           call unsupported
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
.even
int0D_handler:
           mov  bx,$
           mov  ax,0x0D
           call unsupported
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Floppy Hardware ISR Entry Point
.even
int0E_handler:
           push ax
           push dx
           mov  dx,0x03F4
           in   al,dx
           and  al,0xC0
           cmp  al,0xC0
           je   short int0e_normal
           mov  dx,0x03F5
           mov  al,0x08 ; sense interrupt status
           out  dx,al
@@:        mov  dx,0x03F4
           in   al,dx
           and  al,0xC0
           cmp  al,0xC0
           jne  short @b
@@:        mov  dx,0x03F5
           in   al,dx
           mov  dx,0x03f4
           in   al,dx
           and  al,0xC0
           cmp  al,0xC0
           je   short @b
int0e_normal:
           push ds
           xor  ax,ax
           mov  ds,ax
           call eoi_master_pic
           or   byte [0x043E],0x80 ; diskette interrupt has occurred
           pop  ds

           ; Notify diskette interrupt complete w/ int 15h, function AX=9101
           mov  ax,0x9101
           int  15h
           pop  dx
           pop  ax
           iret
           
.even
int0F_handler:
           ; For IRQ7 and IRQ15, to check if an IRQ is a real IRQ or a spurious IRQ, we
           ; check the PIC's ISR. If it's a real IRQ, its corresponding bit will be set,
           ; and if it's a spurious IRQ it won't be.
           push ax
           mov  al,0x0B
           out  PORT_PIC_MASTER_CMD,al
           in   al,PORT_PIC_MASTER_CMD
           test al,(1<<7)
           pop  ax
           jz   short int0F_handler_1

           ; if called from the APIC, we don't do the above check
int0F_handler_0:
           ;
           ; do whatever we are going to do here...
           ;
           push ax
           mov  al,0x20
           out  PORT_PIC_MASTER_CMD,al
           pop  ax
int0F_handler_1:
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Video Support Service Entry Point
;  we don't do anything since the Video BIOS should handle this one
.even
int10_handler:
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Equipment List Service Entry Point
.even
int11_handler:
           push ds
           mov  ax,0x0040
           mov  ds,ax
           mov  ax,[0x0010]
           pop  ds
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Memory Size Service Entry Point
.even
int12_handler:
           push ds
           mov  ax,0x0040
           mov  ds,ax
           mov  ax,[0x0013]
           pop  ds
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Hard drive, CD-ROM, and diskette Service Entry Point
.even
int13_handler:
           push  es
           push  ds
           pushad

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; all but the floppy want a pointer to EBDA_SEG
           push ax
           call bios_get_ebda
           mov  es,ax
           pop  ax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check for an eltorito function
           cmp  ah,0x4A
           jb   short @f
           cmp  ah,0x4D
           ja   short @f
           call int13_eltorito_function
           jmp  short int13_out

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check if USB disk emulation is active
           ; (* dx should not be modified before here *)
.if DO_INIT_BIOS32
@@:        call usb_disk_emu_active
           or   ax,ax
           jz   short @f
           call usb_disk_emu_drive
           cmp  al,dl
           jne  short @f
           call int13_usb_disk_function
           jmp  short int13_out

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check if SATA disk emulation is active
           ; (* dx should not be modified before here *)
@@:        call sata_disk_emu_active
           or   ax,ax
           jz   short @f
           call sata_disk_emu_drive
           cmp  al,dl
           jne  short @f
           call int13_satadisk_function
           jmp  short int13_out
.endif

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check if cdrom emulation is active
           ; (* dx should not be modified before here *)
@@:        call cdrom_emu_active
           or   ax,ax
           jz   short @f
           call cdrom_emu_drive
           cmp  al,dl
           jne  short @f
           call cdrom_emu_function
           jmp  short int13_out

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; the diskette service comes here
@@:        cmp  dl,0x80
           jae  short @f
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; is a floppy diskette
           mov  ax,0x0040
           mov  ds,ax
           call int13_diskette_function
           jmp  short int13_out

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; is it a cd-rom
@@:        cmp  dl,0xE0
           jb   short @f

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; it is a cdrom
           call int13_cdrom_function
           jmp  short int13_out

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; it is a hard drive
@@:        call int13_harddisk_function
           
int13_out: popad
           pop  ds
           pop  es
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Serial Comm Service Entry Point
.even
int14_handler:
           push es
           push ds
           pushad
           mov  ax,0x0040
           mov  ds,ax
           call int14_function
           popad
           pop  ds
           pop  es
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; BIOS Services Entry Point
.even
int15_handler:
           push  es
           push  ds
           pushad
           
           mov  bx,0x40
           mov  ds,bx
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 32-bit handler (still real-mode code)
           cmp   ah,0x86
           je    short int15_handler32
           cmp   ah,0xE8
           jne   short @f
int15_handler32:
           call int15_function32
           jmp   short int15_handler_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; mouse services
@@:        cmp   ah,0xC2
           jne   short @f
           call  int15_function_mouse
           jmp   short int15_handler_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; all remaining function calls
@@:        call  int15_function
int15_handler_done:
           popad
           pop  ds
           pop  es
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Keyboard Service Entry Point
.even
int16_handler:
           sti
           push es
           push ds
           pushad
           mov  ax,0x40
           mov  ds,ax
           call int16_function
           popad
           pop  ds
           pop  es
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Printer Service Entry Point
.even
int17_handler:
           push es
           push ds
           pushad
           mov  ax,0x40
           mov  ds,ax
           call int17_function
           popad
           pop  ds
           pop  es
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Boot Fail Service Entry Point
.even
int18_handler:
           ; Reset SP and SS
           xor  ax,ax
           mov  ss,ax
           mov  sp,ax
           
           ; Get the boot sequence number out of the IPL memory
           mov  ax,EBDA_SEG
           mov  ds,ax
           mov  ax,[EBDA_DATA->ipl_sequence]  ; bx is now the sequence number
           inc  ax                            ; ++
           mov  [EBDA_DATA->ipl_sequence],ax  ; Write it back
           
           mov  bx,0x0040                 ; and reset the segment to the bda.
           mov  ds,bx    
           
           ; Carry on in the INT 19h handler, using the new sequence number (ax)
           jmp  short int19_next_boot
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; BIOS Boot Service Entry Point
.even
int19_handler:
           push bp
           mov  bp,sp

           ; Reset SS and SP
           xor  ax,ax
           mov  ss,ax
           mov  sp,ax
           
           ; Start from the first boot device (0, in AX)
           mov  bx,EBDA_SEG
           mov  ds,bx                     ; Set segment to write to the IPL memory
           mov  [EBDA_DATA->ipl_sequence],ax  ; Save the sequence number
           
           mov  bx,0x0040                 ; and reset the segment to the bda.
           mov  ds,bx    
           
int19_next_boot:
           ; ax = sequence number
           call int19_function
           ; if it returned, we failed, so invoke the boot recovery function
           int  18h
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Time of Day Service Entry Point / PCI Service Entry Point
.even
int1A_handler:
           push es
           push ds
           pushad

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; TCG Services?
           cmp  ah,0xBB
           jne  short @f
           call tcgbios_function
           jmp short int1A_handler_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; PCI Services?
@@:        cmp  ah,0xB1
           jne  short @f
           call pcibios_function
           jmp short int1A_handler_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown service (Win95 calls this one with ax=0xB002)
@@:        cmp  ah,0xB0
           jne  short @f
            xchg cx,cx
           jmp short int1A_handler_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Time of Day Services
@@:        mov  ax,0x0040
           mov  ds,ax
           call int1A_function
int1A_handler_done:           
           popad
           pop  ds
           pop  es
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
.even
int1B_handler:
           mov  bx,$
           mov  ax,0x1B
           call unsupported
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
.even
int1C_handler:
           ; this is called from the timer irq, and most OS'es hook this one
           ;mov  bx,$
           ;mov  ax,0x1C
           ;call unsupported
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
.even
int1D_handler: ; mda/cga parameter table
  ; video should handle this one
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Diskette hardware Entry Point
.even
int1E_handler:
           ; the floppy code set this handler to point to 'diskette_param_table'
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
.even
int1F_handler: ; character font
  ; video should handle this one
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Diskette services Entry Point
.even
int40_handler:
           mov  bx,$
           mov  ax,0x40
           call unsupported
           ;;; call the int13_handler, but just "a ways down from the top" ????
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
.even
int41_handler:
  ; hard drive should have handled this one
           xchg cx,cx ; ben ;;;;;;;;;;;;;;;;;;
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
.even
int46_handler:
  ; hard drive should have handled this one
           xchg cx,cx ; ben ;;;;;;;;;;;;;;;;;;
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; CMOS RTC (IRQ8) Entry Point
.even
int70_handler:
           push es
           push ds
           pushad
           mov  ax,0x0040
           mov  ds,ax
           xchg cx,cx ; ben ;;;;;;;;;;;;;;;;;;
           call int70_function
           popad
           pop  ds
           pop  es
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; IRQ9 handler(Redirect to IRQ2)
.even
int71_handler:
           push ax
           mov  al,0x20
           out  PORT_PIC_SLAVE_CMD,al
           pop  ax
           int  0Ah
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; IRQ10 handler
.even
int72_handler:
           push ax
           mov  al,0x20
           out  PORT_PIC_SLAVE_CMD,al
           pop  ax
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; IRQ11 handler
.even
int73_handler:
           push ax
           mov  al,0x20
           out  PORT_PIC_SLAVE_CMD,al
           pop  ax
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; PS2 Mouse hardware interrupt
.even
int74_handler:
           sti
           pushad
           push ds
           
           call bios_get_ebda
           mov  ds,ax
           
           push 0x00             ; placeholder for status
           push 0x00             ; placeholder for X
           push 0x00             ; placeholder for Y
           push 0x00             ; placeholder for Z
           call int74_function
           or   al,al            ; if !0, make the far call to the handler
           jz   short @f
           
           ; make far call to EBDA:mouse_driver_offset
           ;  (callee uses the stack as above)
           call far [EBDA_DATA->mouse_driver_offset]
           
@@:        cli
           call eoi_both_pic
           add  sp,8             ; pop status, x, y, z
           
           pop ds
           popad
           
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; fpu exception?
.even
int75_handler:
           out  0xF0,al          ; clear irq13
           call eoi_both_pic    ; clear interrupt
           int  02h              ; legacy nmi call
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Hard drive completion
.even
int76_handler:
           ; record completion in BIOS task complete flag
           push  ax
           push  ds
           mov   ax,0x0040
           mov   ds,ax
           mov   byte [0x008E],0xFF
           call  eoi_both_pic
           
           ; xchg cx,cx ; ben ;;;;;;;;;;;;;;;;;;

           ; Notify fixed disk interrupt complete w/ int 15h, function AX=9100
           mov   ax,0x9100
           int   0x15
           pop   ds
           pop   ax
           iret
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; IRQ15 handler
.even
int77_handler:
           ; For IRQ7 and IRQ15, to check if an IRQ is a real IRQ or a spurious IRQ, we
           ; check the PIC's ISR. If it's a real IRQ, its corresponding bit will be set,
           ; and if it's a spurious IRQ it won't be.
           push ax
           mov  al,0x0B
           out  PORT_PIC_SLAVE_CMD,al
           in   al,PORT_PIC_SLAVE_CMD
           test al,(1<<7)
           pop  ax
           jz   short int77_handler_1

           ; if called from the APIC, we don't do the above check
int77_handler_0:
           ;
           ; do whatever we are going to do here...
           ;           
           push ax
           mov  al,0x20
           out  PORT_PIC_SLAVE_CMD,al
           pop  ax

int77_handler_1:
           push ax
           mov  al,0x20
           out  PORT_PIC_MASTER_CMD,al
           pop  ax
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; do nothing but return
.even
dummy_handler:

           ; int 68h, ah = 43h = Novell DOS 7.0 EMM386.EXE installation check?
           ; int 68h, ah = 4Fh = ???
           ; int 5Ch, ah = 0, NetBIOS interface???

           ; to find out what (software) interrupt
           ;  step once, then dump the memory before current cs:IP value (ex: 0xCD 0x10 = int 10h)
           ;xchg cx,cx ; ben ;;;;;;;;;;;;;;;;;;
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; 
; returns
;  ax = 0 = 
;  ax = 1 = 
s3_resume proc near uses ax bx cx ds
           xor  ax,ax
           mov  ds,ax

           mov  bx,[0x04B2]   ; offset
           mov  cx,[0x04B4]   ; segment
           mov  al,[0x04B0]   ; resume_flag

.if DO_DEBUG
           jmp  short @f
s3_resume_str  db 'S3 resume called: flag=%i, %04X:%04X',13,10,0
@@:        push ds
           push cs
           pop  ds
           push bx
           push cx
           push ax
           mov  si,offset s3_resume_str
           call bios_printf
           add  sp,6
           pop  ds
.endif
           ; if flag != 0xFE, no resume
           cmp  al,0xFE
           jne  short s2_resume_error
           
           ; if the vector == 0, no resume
           mov  ax,cx
           or   ax,bx
           jz   short s2_resume_error

           ; clear the flag
           xor  al,al
           mov  [0x04B0],al   ; resume_flag
           ; set the wakeup vector
           mov  [0x04B6],bx   ; offset
           mov  [0x04B8],cx   ; segment

           ; resume jump
           jmp  far [0x04B6]

           mov  ax,1
           ret

s2_resume_error:
           xor  ax,ax
           ret
s3_resume endp

.if DO_INIT_BIOS32

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; start the 32-bit bios initialization stuff
; on entry:
;  nothing
; on return
;  nothing
; destroys all general
rombios32_init proc near uses ds es

           call bios_get_ebda
           mov  ds,ax
           xor  ax,ax
           mov  es,ax
           
           ; nothing before here can use 486+ instructions
.ifdef BX_QEMU
           call qemu_cfg_port_probe
           mov  [EBDA_DATA->qemu_cfg_port],al
.endif
           call cpu_probe
           call setup_mtrr
           call smp_probe

           ; was the shutdown status == 0xFE?
           mov  al,es:[0x04B0]   ; shutdown flag
           cmp  al,0xFE
           jne  short @f

           mov  bx,offset pci_find_440fx
           call pci_for_each_device
           ;call bios_lock_shadow_ram
           ;;;;; ben: we need to implement the remaining parts here
           ; call find_resume_vector
           ; mov  es:[0x04B2],bx   ; segment:offset
           ; mov  es:[0x04B4],ds   ; segment:offset
           ; if not zero
           ;  mov  bx,offset reinit_piix4_pm
           ;  call pci_for_each_device
           mov  bx,$
           mov  ax,0x3232
           call unsupported
           ; ret  ;;; we're done here

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
@@:        ; shutdown status was not 0xFE
           call pci_bios_init

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we can now write to 0x000E0000->0x000FFFFF
           mov  eax,((BIOS_BASE2 << 4) + bios_table_address)
           mov  [EBDA_DATA->bios_table_cur_addr],eax
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create the MP table
           call mptable_init

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; find a uuid (QEMU has this, Bochs clears it to zero)
           call uuid_probe

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the smbios
           call smbios_init

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the acpi
           call acpi_bios_init

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check to make sure we didn't overrun the bios_table_cur_addr
           ; (currently at 0xF42F4. We have up to 0xFBFFF to work with (almost 32k left))
           mov  eax,[EBDA_DATA->bios_table_cur_addr]
           cmp  eax,(0x100000 - 0x4000)
           jbe  short @f
           mov  bx,$
           mov  ax,0xFFFF
           call unsupported

@@:        ret
rombios32_init endp

.endif   ; DO_INIT_BIOS32


; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
include 'escd.asm'
include 'cmos.asm'
include 'misc.asm'
include 'conio.asm'
include 'ebda.asm'      ; must be before any file that uses the ebda
include 'keyboard.asm'
include 'parallel.asm'
include 'serial.asm'
include 'rtc.asm'
include 'tcg.asm'
include 'pic.asm'
include 'cpu.asm'
include 'apic.asm'
include 'pci.asm'
include 'floppy.asm'
include 'harddrive.asm'
include 'cdrom.asm'
include 'sata.asm'
include 'services.asm'
include 'apm.asm'
include 'mouse.asm'
include 'printer.asm'
include 'boot.asm'
include 'acpi.asm'
include 'memory.asm'
include 'sys_man.asm'
include 'pnp.asm'

include 'usb.asm'
include 'uhci.asm'
include 'ohci.asm'
include 'ehci.asm'
include 'xhci.asm'

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; this many bytes left in the first block
; %print (0x10000 - $)   ; 8,328

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           org 0x10000
.rmode
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; this is our font we use with the graphics mode
our_font:  ; 3,584 bytes (256 * 14)
include 'font8x14.asm'

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; this is our main icon
our_main_icon:  ; 8,362 bytes
include 'icon_image.asm'

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; this is our acpi-dsdt binary data
.if DO_INIT_BIOS32
include 'dsdt_data.asm'
.endif

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; next static item goes here

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; pnp bios structure
.para
pnpbios_structure:
  db  "$PnP"       ; 0x24 0x50 0x6E 0x50
  db  0x10         ; version
  db  0x21         ; length
  dw  0x00         ; control field (0 = no event notification, 1 = polling, 2 = interrupt)
  db  ?            ; checksum (calculated in-line below)
  dd  ((BIOS_BASE << 4) + pnp_event_flag) ; event notification flag address
  dw  pnpbios_real ; real mode 16 bit offset
  dw  BIOS_BASE    ; real mode 16 bit segment
  dw  pnpbios_prot ; 16 bit protected mode offset
  dd  (BIOS_BASE << 4) ; 16 bit protected mode segment base
  dd  0x00         ; OEM device identifier
  dw  BIOS_BASE    ; real mode 16 bit data segment
  dd  (BIOS_BASE << 4) ; 16 bit protected mode segment base
.checksum 0x21 0x08  ; do a byte checksum of the last 0x21 bytes, placing the result at offset 8

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; This is the area were our 'setup app' is located
include 'setup.asm'

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; This is where we will (dynamically) store tables and other information
; (this area is not writable until we call the 'pci_bios_init' function,
;  and then will be read only after we are done and lock the shadow ram)
.para
bios_table_address:
           ; don't place anything between here and the ESCD below. It will be overwritten...

; this many bytes left in the second block (before ESCD)
; %print (0x20000 - 0x4000 - $)  ; roughly 27k still

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Extended System Configuration Data (ESCD)
           ; we are an Intel 28F001BX-T type Flash ROM that stores
           ;  the ESCD at end of ROM - 0x4000 with a size of 0x2000
           ; if a parameter of 'flash_data=' is given, as in:
           ;  romimage: file=$BXSHARE/i440fx.bin, flash_data="escd.bin"
           ; the 'escd.bin' file should be 0x2000 (8,192d) bytes in size and will
           ;  replace this area when the ROM is loaded.
           ; use 'flash_data=none' to not overwrite this area
           ; (call bios_commit_escd to write it back before we boot the OS)
           org (0x20000 - 0x4000)

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; the format of this area is defined in the ESCD specification
           ;  with a header signature of 'ACFG'
           ; we use the end of this area to store other information, such
           ;  as the saved state of the Num Lock, etc.
           ; (we write defaults here incase one uses it without escd support)
           ; (the only downfall is, we have to keep it in sync with the ESCD_DATA structure)
escd       dw  12       ; size of the 'ESCD correct' data (right now, just this header = 12)
           db  'ACFG'   ; signature
           db  0        ; minor version
           db  2        ; major version
           db  0        ; number of board entries
           db  0,0,0    ; reserved

           db  0        ; 0 = enumerate ehci devices, 1 = enumerate all hs devices as fs on companion controllers
           db  1        ; 0 = leave the num lock off, 1 = turn on num_lock at boot time
           db  3        ; number of seconds to wait for a F12 press before boot (0 means no delay, 3 = default)
           db  0        ; 0 = enumerate ahci devices, 1 = enumerate all capable ahci devices as edi devices

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Free space. Can be used to store static info
           ; (to save space in 0xE000:0000, we place some string data here)
           org (0x20000 - 0x2000)
banner_str          db  'Bochs all assembly 16-bit legacy bios.',13,10
                    db  'Build date: ' __DATE__ ', ver 1.00',13,10,10,0
banner_no_vesa_str  db  'Did not find a suitible VBE2 screen mode...',13,10,0
unknown_shutdown    db  'Error: unknown shutdown status found: %i',0
s3_resume_error     db  'Error: returned from s3 resume',0

uhci_found_str0         db 'Found UHCI controller at 0x%04X (%i ports), irq = %i, ram = 0x%08lX',13,10,0
ohci_found_str0         db 'Found OHCI controller at 0x%08lX (%i ports), irq = %i, ram = 0x%08lX',13,10,0
ehci_found_str0         db 'Found EHCI controller at 0x%08lX (%i ports), irq = %i, ram = 0x%08lX',13,10,0
ehci_found_str1         db 'Found EHCI controller at 0x%08lX (companions %i:%i) ** Config = 0 **',13,10,0
xhci_found_str0         db 'Found xHCI controller at 0x%08lX (%i ports), irq = %i',13,10,0
usb_mount_floppy_str    db  ' Found USB Floppy disk with %i sectors. (0x%02X)',13,10,0
usb_mount_hdd_flpy_str  db  ' Found USB Hard disk emulating a floppy at lba %li with %i sectors. (0x%02X)',13,10,0
usb_mount_harddisk_str  db  ' Found USB Hard disk with %li sectors. (0x%02X)',13,10,0
usb_mount_cdrom_str     db  ' Found USB CDROM disc with %li sectors. (0x%02X)',13,10,0
usb_mount_cd_flpy_str   db  ' Found USB CDROM disc emulating a floppy at lba %li with %i sectors. (0x%02X)',13,10,0
usb_mount_cd_hdd_str    db  ' Found USB CDROM disc emulating a hdd at lba %li with %li sectors. (0x%02X)',13,10,0

ahci_found_str0     db 'Found SATA AHCI controller at 0x%08lX (irq = %i) with %i ports',13,10,0
sata_print_str1     db ' SATA-%d Hard-Disk (%8lu %cBytes) ',0
sata_print_str2     db ' SATAPI-%d CD-Rom/DVD-Rom ',0

pci_rom_region_str  db  'Region %i: 0x%08lX',13,10,0
pci_rom_copied_str  db  'PCI ROM copied to 0x%08lX (size = 0x%08lX)',13,10,0

apic_found_str      db  'Found APIC%i with version 0x%02X, with %i lvt entries.',13,10,0

; this many bytes left in the second block (after ESCD)
; %print (0x1FFF0 - $)  ; 7,003

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Power up entry point
           org 0x1FFF0
.rmode
           jmp  far 0x0000,0xE000   ; jmp far offset,segment
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Date ROM was made in MM/DD/YY format
rom_date   db  '02/10/24',0
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; System Model ID number
rom_id     db  0xFF, 0xFF

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check to make sure we are the correct length
.if ($ != 0x20000)
  %ERROR 1 'File length not at 0x20000'
  %PRINT $
.endif
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; end of file
.end
