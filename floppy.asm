comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: floppy.asm                                                         *
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
*   floppy include file                                                    *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.16                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 9 Dec 2024                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

; can be up to IPL_ENTRY_MAX_DESC_LEN-1 chars
fdc_controller_str  db  '(FDC Device)',0

BDA_FDD_RECAL_STATUS  equ  0x003E
BDA_FDD_MOTOR_STATUS  equ  0x003F
BDA_FDD_MOTOR_ONOFF   equ  0x0040
BDA_FDD_LAST_STATUS   equ  0x0041

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the floppy drive(s)
; on entry:
;  es = 0x0000
; on return
;  nothing
; destroys all general
init_floppy proc near uses ds es
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; ds = 0x0040, es = EBDA
           mov  ax,0x0040
           mov  ds,ax
           mov  ax,EBDA_SEG
           mov  es,ax

           xor  al,al
           mov  [BDA_FDD_RECAL_STATUS],al     ; drive 0 & 1 uncalibrated, no interrupt has occurred
           mov  [BDA_FDD_MOTOR_STATUS],al     ; diskette motor status: read op, drive0, motors off
           mov  [BDA_FDD_MOTOR_ONOFF],al      ; diskette motor timeout counter: not active
           mov  [BDA_FDD_LAST_STATUS],al      ; diskette controller status return code
           mov  [0x0042],al      ; disk & diskette controller status register 0
           mov  [0x0043],al      ; diskette controller status register 1
           mov  [0x0044],al      ; diskette controller status register 2
           mov  [0x0045],al      ; diskette controller cylinder number
           mov  [0x0046],al      ; diskette controller head number
           mov  [0x0047],al      ; diskette controller sector number
           mov  [0x0048],al      ; diskette controller bytes written
           mov  [0x008B],al      ; diskette configuration data

           mov  es:[EBDA_DATA->fdd_count],al
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; (048F) diskette controller information
           mov  ah,0x10          ; get CMOS diskette drive type
           call cmos_get_byte
           mov  ah, al           ; save byte to AH
look_drive0:
           shr  al,4             ; look at top 4 bits for drive 0
           jz   short f0_missing ; jump if no drive0
           mov  bl,0x07          ; drive0 determined, multi-rate, has changed line

           ; add this drive to our vector table
           push es
           push cs
           pop  es
           xor  eax,eax          ; lba = 0
           xor  ecx,ecx          ; vector = 0000:0000
           mov  si,offset fdc_controller_str
           mov  edx,((IPL_FLAGS_NSATA << 16) | (IPL_TYPE_FLOPPY << 8) | (0 << 0))
           call add_boot_vector
           pop  es

           ; increment count of drives found
           inc  byte es:[EBDA_DATA->fdd_count]

           jmp  short look_drive1
f0_missing:
           mov  bl,0x00          ; no drive0
look_drive1:
           mov  al,ah            ; restore from AH
           and  al,0x0F          ; look at bottom 4 bits for drive 1
           jz   short f1_missing ; jump if no drive1
           or   bl,0x70          ; drive1 determined, multi-rate, has changed line

           ; add this drive to our vector table
           push es
           push cs
           pop  es
           xor  eax,eax          ; lba = 0
           xor  ecx,ecx          ; vector = 0000:0000
           mov  si,offset fdc_controller_str
           mov  edx,((IPL_FLAGS_NSATA << 16) | (IPL_TYPE_FLOPPY << 8) | (1 << 0))
           call add_boot_vector
           pop  es

           ; increment count of drives found
           inc  byte es:[EBDA_DATA->fdd_count]
           
f1_missing:                      ; leave high bits in BL zerod
           mov  [0x008F],bl      ; put new val in BDA (diskette controller information)
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           xor  al,al
           mov  [0x0090],al      ; diskette 0 media state
           mov  [0x0091],al      ; diskette 1 media state
                                 ; diskette 0,1 operational starting state
                                 ; drive type has not been determined,
                                 ; has no changed detection line
           mov  [0x0092],al
           mov  [0x0093],al
           mov  [0x0094],al      ; diskette 0 current cylinder
           mov  [0x0095],al      ; diskette 1 current cylinder
           
           mov  al,0x02
           out  PORT_DMA1_MASK_REG,al ; clear DMA-1 channel 2 mask bit

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set the interrupt vectors
           mov  ax,0x1E
           mov  bx,offset diskette_param_table
           mov  cx,BIOS_BASE
           call set_int_vector

           mov  ax,0x40
           mov  bx,offset int13_handler
           mov  cx,BIOS_BASE
           call set_int_vector

           mov  ax,0x0E
           mov  bx,offset int0E_handler
           mov  cx,BIOS_BASE
           call set_int_vector

           ret
init_floppy endp

diskette_param_table:
    ;  New diskette parameter table adding 3 parameters from IBM
    ;  Since no provisions are made for multiple drive types, most
    ;  values in this table are ignored.  I set parameters for 1.44M
    ;  floppy here
    db  0xAF
    db  0x02                     ; head load time 0000001, DMA used
    db  0x25
    db  0x02
    db    18
    db  0x1B
    db  0xFF
    db  0x6C
    db  0xF6
    db  0x0F
    db  0x08
    db    79                     ; maximum track
    db     0                     ; data transfer rate
    db     4                     ; drive type in cmos

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; does floppy drive exist
; on entry:
;  dl = drive
; on return
;  al = 0 if no drive
;  al = type if drive found
; destroys none
floppy_drive_exist proc near
           ; get the device type
           ; CMOS R10 = AB = A = drive 0, B = drive 1
           mov  ah,0x10
           call cmos_get_byte
           or   dl,dl
           jnz  short @f
           shr  al,4
@@:        and  al,0x0F
           ret
floppy_drive_exist endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; is the floppy media a known type
; on entry:
;  ds = 0x0040
;  dl = drive
; on return
;  al = 0 = unknown
; destroys none
floppy_media_known proc near uses bx
           mov  al,[BDA_FDD_RECAL_STATUS]
           or   dl,dl
           jz   short @f
           shr  al,1
@@:        and  al,1
           jz   short floppy_media_known_ret
           mov  bx,0x90
           or   dl,dl
           jz   short @f
           inc  bx
@@:        mov  al,[bx]
           shr  al,4
           and  al,1
floppy_media_known_ret:           
           ret
floppy_media_known endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; floppy media state and config data bitfields
; config_data:
;  bits 7:6  last data rate set by controller
;            00=500kbps, 01=300kbps, 10=250kbps, 11=1Mbps
;  bits 5:4  last diskette drive step rate selected
;            00=0Ch, 01=0Dh, 10=0Eh, 11=0Ah
;  bits 3:2  {data rate at start of operation}
;  bits 1:0  reserved
;
; media_state:
;  bits 7:6  data rate
;            00=500kbps, 01=300kbps, 10=250kbps, 11=1Mbps
;  bit  5    double stepping required (e.g. 360kB in 1.2MB)
;  bit  4    media type established
;  bit  3    drive capable of supporting 4MB media
;  bits 2:0  on exit from BIOS, contains
;            000 trying 360kB in 360kB
;            001 trying 360kB in 1.2MB
;            010 trying 1.2MB in 1.2MB
;            011 360kB in 360kB established
;            100 360kB in 1.2MB established
;            101 1.2MB in 1.2MB established
;            110 reserved
;            111 all other formats/drives
;
; media state in high byte, config data in low byte
fd_media_sense:
  dw  0x0000         ; type 0 = not used here (filler word)
  dw  0x3500         ; type 1 = 360k 5.25" disk
  dw  0x3500         ; type 2 = 1.2meg 5.25" disk
  dw  0x3700         ; type 3 = 720k 3.50" disk
  dw  0x3700         ; type 4 = 1.44meg 3.50" disk
  dw  0xF7CC         ; type 5 = 2.88meg 3.50" disk
  dw  0x3700         ; type 6 = 160k 5.25" disk
  dw  0x3700         ; type 7 = 180k 5.25" disk
  dw  0x3700         ; type 8 = 320k 5.25" disk

; media chs values for drive type
; first word is CX value, then a DH byte
fd_media_chs:
  dw  0x0000         ; type 0 = not used here (filler)
   db  0             ;
  dw  0x2709         ; type 1 = 360k 5.25" disk
   db  1             ;  max cyl 39, spt 9, max head 1
  dw  0x4F0F         ; type 2 = 1.2meg 5.25" disk
   db  1             ;  max cyl 79, spt 15, max head 1
  dw  0x4F09         ; type 3 = 720k 3.50" disk
   db  1             ;  max cyl 79, spt 9, max head 1
  dw  0x4F12         ; type 4 = 1.44meg 3.50" disk
   db  1             ;  max cyl 79, spt 18, max head 1
  dw  0x4F24         ; type 5 = 2.88meg 3.50" disk
   db  1             ;  max cyl 79, spt 36, max head 1
  dw  0x2708         ; type 6 = 160k 5.25" disk
   db  0             ;  max cyl 39, spt 8, max head 0
  dw  0x2709         ; type 7 = 180k 5.25" disk
   db  0             ;  max cyl 39, spt 9, max head 0
  dw  0x2708         ; type 8 = 320k 5.25" disk
   db  1             ;  max cyl 39, spt 8, max head 1

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; try to determine the media type
; on entry:
;  ds = 0x0040
;  dl = drive
; on return
;  al = 0 = unknown
; destroys none
floppy_media_sense proc near uses bx
           ; try to recalibrate the drive
           call floppy_drive_recal
           
           or   al,al
           jz   short floppy_media_sense_ret

           ; set the offset of the media state byte
           mov  bx,0x90
           or   dl,dl
           jz   short @f
           inc  bx

@@:        call floppy_drive_exist
           ; al = type (or zero if none)
           
           cmp  al,0x08
           jbe  short @f
           xor  al,al

@@:        push ax               ; save type found (or zero)
           push bx               ; save media state offset
           xor  bh,bh
           mov  bl,al
           shl  bx,1             ; word sized
           mov  ax,cs:[bx+fd_media_sense]
           pop  bx               ; restore the media offset

           mov  [bx],ah          ; media state
           mov  [0x008B],al      ; config data
           
           pop  ax               ; restore the type found (or zero)
           or   al,al
           jz   short floppy_media_sense_ret

           mov  al,1
           ret

floppy_media_sense_ret:
           xor  al,al
           ret
floppy_media_sense endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; set the BDA's floppy cylinder value
; on entry:
;  ds = 0x0040
;  dl = drive
;  al = cylinder
; on return
;  nothing
; destroys none
set_floppy_cylinder proc near uses bx
           xor  bh,bh
           mov  bl,dl
           mov  [bx+0x94],al   ; set the cyl value
           ret
set_floppy_cylinder endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; reset the floppy controller
; on entry:
;  ds = 0x0040
; on return
;  nothing
; destroys none
floppy_reset_controller proc near uses dx
           
           mov  dx,PORT_FD_DOR
           in   al,dx

           ; reset
           and  al,(~0x04)
           out  dx,al

           ; set to normal operation
           or   al,0x04
           out  dx,al

           ; wait for the controller to be done
           mov  dx,PORT_FD_STATUS
@@:        in   al,dx
           and  al,0xC0
           cmp  al,0x80
           jne  short @b

           ret
floppy_reset_controller endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; prepare the floppy controller for a command
; on entry:
;  ds = 0x0040
;  dl = drive
; on return
;  nothing
; destroys none
floppy_prepare_controller proc near uses bx dx
           
           ; make sure the interrupt bit is cleared
           and  byte [BDA_FDD_RECAL_STATUS],0x7F

           mov  ah,dl            ; save the drive in ah
           mov  dx,PORT_FD_DOR
           in   al,dx
           and  al,0x04          ; are we in reset mode?
           mov  bl,al            ; save in bl
           
           mov  al,0x20
           or   ah,ah            ; drive
           jnz  short @f
           mov  al,0x10
@@:        or   al,0x0C
           or   al,ah
           out  dx,al

           ; reset the disk motor timeout value (for IRQ 8)
           mov  byte [BDA_FDD_MOTOR_ONOFF],37 ; ((1000 / 18.2) * 37) = 2.032 seconds

           ; wait for drive readiness
           mov  dx,PORT_FD_STATUS
@@:        in   al,dx
           and  al,0xC0
           cmp  al,0x80
           jne  short @b

;           ; if previously not reset
;           or   bl,bl
;           jz   short floppy_prepare_done
;
;           sti
;
;@@:        test byte [BDA_FDD_RECAL_STATUS],0x80
;           jz   short @b
;
;           cli
;
;           ; clear it for next time
;           and byte [BDA_FDD_RECAL_STATUS],0x7F
;
;floppy_prepare_done:
           ret
floppy_prepare_controller endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; try to recalibrate the drive
; on entry:
;  ds = 0x0040
;  dl = drive
; on return
;  al = 0 = fail
; destroys none
floppy_drive_recal proc near uses bx dx

           call floppy_prepare_controller

           mov  ah,dl            ; save drive in ah
           mov  dx,PORT_FD_DATA
           mov  al,0x07
           out  dx,al
           mov  al,ah
           out  dx,al
           
           sti

@@:        test byte [BDA_FDD_RECAL_STATUS],0x80
           jz   short @b

           cli

           mov  al,[BDA_FDD_RECAL_STATUS]
           and  al,0x7F

           ; ah = drive from above
           mov  dl,ah
           mov  ah,02
           mov  bx,0x0095
           or   dl,dl
           jnz  short @f
           mov  ah,01
           mov  bx,0x0094
@@:        or   al,ah
           
           mov  [BDA_FDD_RECAL_STATUS],al
           mov  byte [bx],0x00

           mov  al,1
           ret
floppy_drive_recal endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Floppy disk services
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
int13_diskette_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           sub  sp,0x08

fd_sv_sector    equ  [bp-0x02]
fd_sv_head      equ  [bp-0x04]
fd_sv_count     equ  [bp-0x06]
fd_sv_type      equ  [bp-0x07]

           ; make sure the device is valid
           mov  dx,REG_DX
           cmp  dl,0x01
           ja   fd_int13_fail

           ; get the device type
           call floppy_drive_exist
           jnz  short @f
           ; no type specified
           mov  byte REG_AH,0x80
           jmp  fd_int13_fail_noah
@@:        mov  fd_sv_type,al

           mov  ah,REG_AH
           ; ah = service
           ; dl = drive
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; controller reset
           cmp  ah,0x00
           jne  short @f
           ; todo: why don't we actually reset the device?  (call floppy_reset_controller)
           xor  al,al
           call set_floppy_cylinder
           jmp  fd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disk status
@@:        cmp  ah,0x01
           jne  short @f
           mov  al,[BDA_FDD_LAST_STATUS]
           mov  REG_AH,al
           or   al,al
           jz   fd_int13_success_noah
           jmp  fd_int13_fail_noah
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read/write/verify disk sectors
@@:        cmp  ah,0x02          ; read disk sectors
           je   short fd_int13_transfer
           cmp  ah,0x03          ; write disk sectors
           je   short fd_int13_transfer
           cmp  ah,0x04          ; verify disk sectors
           jne  @f
fd_int13_transfer:
           xor  ah,ah
           mov  al,REG_AL
           mov  fd_sv_count,ax
           ;mov  al,REG_CL
           ;shl  ax,2
           ;and  ah,0x03
           ;mov  al,REG_CH
           ;mov  fd_sv_cylinder,ax
           xor  ah,ah
           mov  al,REG_CL
           and  al,0x3F
           mov  fd_sv_sector,ax
           mov  al,REG_DH
           mov  fd_sv_head,ax
           
           ; if head > 1, count > 72, or count == 0, or sector == 0, error
           mov  ax,fd_sv_count
           or   ax,ax
           jz   fd_int13_fail
           cmp  ax,72
           ja   fd_int13_fail
           cmp  word fd_sv_sector,00
           je   fd_int13_fail
           cmp  word fd_sv_head,1
           ja   fd_int13_fail

           ; see if media in the drive and type is known
           call floppy_media_known
           or   al,al
           jnz  short fd_int13_transfer_1
           ; unknown media, so try to retrieve it
           call floppy_media_sense
           or   al,al
           jnz  short fd_int13_transfer_1
           ; unknown type, return error
           mov  byte REG_AH,0x0C
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah

fd_int13_transfer_1:
           ; if we are verifying a sector(s), just return as good
           mov  ah,REG_AH
           cmp  ah,0x04
           je   fd_int13_success
           
           ; setup the DMA controller
           mov  dx,REG_ES
           shr  dx,12            ; dx = page
           mov  ax,REG_ES
           shl  ax,4             ; ax = base_es
           mov  bx,ax
           add  bx,REG_BX        ; bx = base_address
           cmp  bx,ax
           jnb  short fd_int13_transfer_2
           inc  dx               ; increment the page
fd_int13_transfer_2:
           movzx cx,byte REG_AL  ; count
           shl  cx,9             ; 512-byte sectors
           dec  cx               ; -1

           ; check for 64k boundary overrun
           mov  ax,bx            ; bx = base address
           add  ax,cx            ; cx = count of bytes - 1
           cmp  ax,bx            ; last byte
           jnb  short fd_int13_transfer_3
           mov  byte REG_AH,0x09
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah

fd_int13_transfer_3:
           mov  al,0x06
           out  PORT_DMA1_MASK_REG,al
           xor  al,al
           out  PORT_DMA1_CLEAR_FF_REG,al  ; clear the flip-flop
           mov  ax,bx            ; base address
           out  PORT_DMA_ADDR_2,al
           xchg ah,al
           out  PORT_DMA_ADDR_2,al
           xor  al,al
           out  PORT_DMA1_CLEAR_FF_REG,al  ; clear the flip-flop
           mov  ax,cx            ; count
           out  PORT_DMA_CNT_2,al
           xchg ah,al
           out  PORT_DMA_CNT_2,al

           ; perpare to read the sector(s)
           mov  ah,REG_AH
           cmp  ah,0x02          ; read sectors
           jne  short fd_int13_transfer_write
           
           mov  al,0x46          ; single mode, increment, autoinit disable, transfer type=write, channel 2
           out  PORT_DMA1_MODE_REG,al
           mov  ax,dx            ; page
           out  PORT_DMA_PAGE_2,al
           mov  al,02            ; unmask channel 2
           out  PORT_DMA1_MASK_REG,al

           ; setup the floppy controller for the transfer
           mov  dl,REG_DL
           call floppy_prepare_controller
           
           mov  dx,PORT_FD_DATA
           mov  al,0xE6
           out  dx,al
           jmp  short fd_int13_transfer_4
           
fd_int13_transfer_write:
           ; perpare to write the sector(s)
           mov  al,0x4A          ; single mode, increment, autoinit disable, transfer type=read, channel 2
           out  PORT_DMA1_MODE_REG,al
           mov  ax,dx            ; page
           out  PORT_DMA_PAGE_2,al
           mov  al,02            ; unmask channel 2
           out  PORT_DMA1_MASK_REG,al

           ; setup the floppy controller for the transfer
           mov  dl,REG_DL
           call floppy_prepare_controller
           
           mov  dx,PORT_FD_DATA
           mov  al,0xC5
           out  dx,al

fd_int13_transfer_4:
           ; command was sent to the floppy controller
           ; so send the parameters
           ; dx = PORT_FD_DATA
           mov  al,REG_DH        ; (head << 2) | drive
           shl  al,2
           or   al,REG_DL
           out  dx,al
           mov  al,REG_CH        ; cylinder
           out  dx,al
           mov  al,REG_DH        ; head
           out  dx,al
           mov  al,REG_CL        ; sector
           out  dx,al
           mov  al,0x02          ; 512-byte sector size
           out  dx,al
           mov  al,REG_CL        ; eot
           add  al,REG_AL
           dec  al
           out  dx,al
           xor  al,al            ; gap length
           out  dx,al
           mov  al,0xFF          ; DTL
           out  dx,al

           ; now wait for the status
           sti
fd_int13_transfer_5:
           mov  al,[BDA_FDD_MOTOR_ONOFF]
           or   al,al
           jnz  short fd_int13_transfer_6
           call floppy_reset_controller
           mov  byte REG_AH,0x80
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah
fd_int13_transfer_6:
           test byte [BDA_FDD_RECAL_STATUS],0x80
           jz   short fd_int13_transfer_5

           cli

           and  byte [BDA_FDD_RECAL_STATUS],0x7F
           mov  dx,PORT_FD_STATUS
           in   al,dx
           and  al,0xC0
           cmp  al,0xC0
           je   short fd_int13_transfer_7
           call floppy_reset_controller
           mov  byte REG_AH,0x80
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah

fd_int13_transfer_7:
           mov  bx,0x0042        ; floppy drive controller status
           ; read in the return bytes
           mov  cx,7
           mov  dx,PORT_FD_DATA
fd_int13_transfer_8:
           in   al,dx
           mov  [bx],al
           inc  bx
           loop fd_int13_transfer_8

           ; if the return status isn't good
           mov  al,[0x0042]
           and  al,0xC0
           jz   short fd_int13_transfer_10
           ; was it a read
           cmp  byte REG_AH,0x02
           jne  short fd_int13_transfer_9
           mov  byte REG_AH,0x20
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah
fd_int13_transfer_9:
           ; was a write
           test byte [0x0043],0x02
           jz   fd_int13_fail
           mov  byte REG_AH,0x03
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah

fd_int13_transfer_10:
           mov  al,REG_CH
           mov  dl,REG_DL
           call set_floppy_cylinder
           jmp  fd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; format track
@@:        cmp  ah,0x05
           jne  @f
           xor  ah,ah
           mov  al,REG_AL
           mov  fd_sv_count,ax
           ;mov  al,REG_CL
           ;shl  ax,2
           ;and  ah,0x03
           ;mov  al,REG_CH
           ;mov  fd_sv_cylinder,ax
           mov  al,REG_DH
           mov  fd_sv_head,ax
           
           ; if head > 1, count > 36, or count == 0, or sector == 0, error
           mov  ax,fd_sv_count
           or   ax,ax
           jz   fd_int13_fail
           cmp  ax,36
           ja   fd_int13_fail
           cmp  word fd_sv_sector,00
           je   fd_int13_fail
           cmp  word fd_sv_head,1
           ja   fd_int13_fail

           ; see if media in the drive and type is known
           call floppy_media_known
           or   al,al
           jnz  short fd_int13_format_0
           ; unknown media, so try to retrieve it
           call floppy_media_sense
           or   al,al
           jnz  short fd_int13_format_0
           ; unknown type, return error
           mov  byte REG_AH,0x0C
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah

fd_int13_format_0:
           ; setup the DMA controller
           mov  dx,REG_ES
           shr  dx,12            ; dx = page
           mov  ax,REG_ES
           shl  ax,4             ; ax = base_es
           mov  bx,ax
           add  bx,REG_BX        ; bx = base_address
           cmp  bx,ax
           jnb  short fd_int13_format_1
           inc  dx               ; increment the page
fd_int13_format_1:
           movzx cx,byte REG_AL  ; count
           shl  cx,2             ; 4 bytes of info per sector
           dec  cx               ; -1

           ; check for 64k boundary overrun
           mov  ax,bx            ; bx = base address
           add  ax,cx            ; cx = count of bytes - 1
           cmp  ax,bx            ; last byte
           jnb  short fd_int13_format_2
           mov  byte REG_AH,0x09
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah

fd_int13_format_2:
           mov  al,0x06
           out  PORT_DMA1_MASK_REG,al
           xor  al,al
           out  PORT_DMA1_CLEAR_FF_REG,al  ; clear the flip-flop
           mov  ax,bx            ; base address
           out  PORT_DMA_ADDR_2,al
           xchg ah,al
           out  PORT_DMA_ADDR_2,al
           xor  al,al
           out  PORT_DMA1_CLEAR_FF_REG,al  ; clear the flip-flop
           mov  ax,cx            ; count
           out  PORT_DMA_CNT_2,al
           xchg ah,al
           out  PORT_DMA_CNT_2,al

           mov  al,0x4A          ; single mode, increment, autoinit disable, transfer type=read, channel 2
           out  PORT_DMA1_MODE_REG,al
           mov  ax,dx            ; page
           out  PORT_DMA_PAGE_2,al
           mov  al,02            ; unmask channel 2
           out  PORT_DMA1_MASK_REG,al

           ; setup the floppy controller for the format
           mov  dl,REG_DL
           call floppy_prepare_controller
           
           ; send command and parameters to the floppy controller
           mov  dx,PORT_FD_DATA
           mov  al,0x4D
           out  dx,al
           mov  al,REG_DH        ; (head << 2) | drive
           shl  al,2
           or   al,REG_DL
           out  dx,al
           mov  al,0x02          ; 512-byte sector size
           out  dx,al
           mov  al,fd_sv_count
           out  dx,al
           xor  al,al            ; gap length
           out  dx,al
           mov  al,0xF6          ; fill byte
           out  dx,al

           ; now wait for the status
           sti

fd_int13_format_3:
           mov  al,[BDA_FDD_MOTOR_ONOFF]
           or   al,al
           jnz  short fd_int13_format_4
           call floppy_reset_controller
           mov  byte REG_AH,0x80
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah
fd_int13_format_4:
           test byte [BDA_FDD_RECAL_STATUS],0x80
           jz   short fd_int13_format_3

           cli

           and  byte [BDA_FDD_RECAL_STATUS],0x7F

           mov  dx,PORT_FD_STATUS
           in   al,dx
           and  al,0xC0
           cmp  al,0xC0
           je   short fd_int13_format_5
           call floppy_reset_controller
           mov  byte REG_AH,0x80
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah

fd_int13_format_5:
           mov  bx,0x0042        ; floppy drive controller status
           ; read in the return bytes
           mov  cx,7
           mov  dx,PORT_FD_DATA
fd_int13_format_6:
           in   al,dx
           mov  [bx],al
           inc  bx
           loop fd_int13_format_6

           ; if the return status isn't good
           mov  al,[0x0042]
           and  al,0xC0
           jz   short fd_int13_format_7
           test byte [0x0043],0x02
           jz   fd_int13_fail
           mov  byte REG_AH,0x03
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah

fd_int13_format_7:
           mov  al,REG_CH
           mov  dl,REG_DL
           call set_floppy_cylinder
           jmp  fd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get drive parameters
@@:        cmp  ah,0x08
           jne  short @f

           ; get the count of floppies we support
           xor  dl,dl
           mov  ah,0x10
           call cmos_get_byte
           test al,0xF0
           jz   short fd_int13_params_0
           inc  dl
fd_int13_params_0:
           test al,0x0F
           jz   short fd_int13_params_1
           inc  dl
fd_int13_params_1:
           xor  ah,ah
           mov  byte REG_BH,0x00
           mov  al,fd_sv_type
           mov  REG_BL,al
           mov  REG_DL,dl
           imul bx,ax,3
           mov  ax,cs:[bx+fd_media_chs+0]
           mov  REG_CX,ax
           mov  al,cs:[bx+fd_media_chs+2]
           mov  REG_DH,al
           mov  ax,offset diskette_param_table
           mov  REG_DI,ax
           mov  word REG_ES,BIOS_BASE
           mov  word REG_AX,0x0000
           jmp  fd_int13_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read type
@@:        cmp  ah,0x15
           jne  short @f
           mov  byte REG_AH,0x01
           cmp  byte fd_sv_type,0x00
           jne  short fd_int13_type15_0
           mov  byte REG_AH,0x00
fd_int13_type15_0:
           jmp  fd_int13_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get change line status
@@:        cmp  ah,0x16
           jne  short @f
           mov  byte REG_AH,0x06 ; change line not supported
           jmp  fd_int13_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set diskette type for format (old)
@@:        cmp  ah,0x17
           jne  short @f
           
           mov  bx,0x91
           or   dl,dl
           jnz  short fd_int13_type_old_0
           dec  bx
fd_int13_type_old_0:
           ; bx = base address
           mov  al,[bx]          ; status

           ; drive type specified
           mov  ah,REG_AL
           cmp  ah,0x00
           je   fd_int13_fail
           cmp  ah,0x01
           jne  short fd_int13_type_old_1
           mov  ah,al
           and  ah,0x0F
           or   ah,0x90          ; 1001_0000, rate = 250
           jmp  short fd_int13_type_old_5
fd_int13_type_old_1:
           cmp  ah,0x02
           jne  short fd_int13_type_old_2
           mov  ah,al
           and  ah,0x0F
           or   ah,0x70          ; 0111_0000, rate = 300
           jmp  short fd_int13_type_old_5
fd_int13_type_old_2:
           cmp  ah,0x03
           jne  short fd_int13_type_old_3
           mov  ah,al
           and  ah,0x0F
           or   ah,0x10          ; 0001_0000, rate = 500
           jmp  short fd_int13_type_old_5
fd_int13_type_old_3:
           cmp  ah,0x04
           jne  fd_int13_fail
           mov  ah,al
           and  ah,0x0F
           test al,0x12          ; 720k in a 720k drive
           jz   short fd_int13_type_old_4
           or   ah,0x50          ; 0101_0000, rate = 300
           jmp  short fd_int13_type_old_5
fd_int13_type_old_4
           or   ah,0x90          ; 1001_0000, rate = 250
fd_int13_type_old_5:
           mov  [bx],ah
           jmp  fd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set diskette type for format
@@:        cmp  ah,0x18
           jne  @f

           ; see if media in the drive and type is known
           call floppy_media_known
           or   al,al
           jnz  short fd_int13_type_0
           ; unknown media, so try to retrieve it
           call floppy_media_sense
           or   al,al
           jnz  short fd_int13_type_0
           ; unknown type, return error
           mov  byte REG_AH,0x0C
           mov  byte REG_AL,0x00
           jmp  fd_int13_fail_noah

fd_int13_type_0:
           mov  bx,0x91
           or   dl,dl
           jnz  short fd_int13_type_00
           dec  bx
fd_int13_type_00:
           ; bx = base address
           mov  al,[bx]          ; status
           
           ; get parameters
           mov  cl,REG_CL        ;
           and  cl,0x3F          ; cl = spt
           mov  dl,REG_CH        ; dx = cyls
           mov  dh,REG_CL        ;
           shr  dh,6             ;

           ; drive type specified
           mov  ah,fd_sv_type
           cmp  ah,0x01          ; 360k, 5.25"
           je   short fd_int13_type_1
           cmp  ah,0x06          ; 160k, 5.25"
           je   short fd_int13_type_1
           cmp  ah,0x07          ; 180k, 5.25"
           je   short fd_int13_type_1
           cmp  ah,0x08          ; 320k, 5.25"
           jne  short fd_int13_type_2
fd_int13_type_1:
           ; if cyl = 39 and spt = 8 or 9
           cmp  dx,39
           jne  fd_int13_type_bad_type
           cmp  cl,9
           je   short fd_int13_type_1_0
           cmp  cl,8
           je   fd_int13_type_bad_type
fd_int13_type_1_0:
           mov  ah,al
           and  ah,0x0F
           or   ah,0x90          ; 1001_0000, rate = 250
           jmp  fd_int13_type_good

fd_int13_type_2:
           cmp  ah,0x02          ; 1.2M, 5.25"
           jne  short fd_int13_type_3
           ; if cyl = 39 and spt = 8 or 9
           cmp  dx,39
           jne  short fd_int13_type_2_2
           cmp  cl,9
           je   short fd_int13_type_2_0
           cmp  cl,8
           je   fd_int13_type_bad_type
fd_int13_type_2_0:
           mov  ah,al
           and  ah,0x0F
           or   ah,0x70          ; 0111_0000, rate = 300
           jmp  fd_int13_type_good
fd_int13_type_2_2:
           ; if cyl = 79 and spt = 15
           cmp  dx,79
           jne  fd_int13_type_bad_type
           cmp  cl,15
           jne  fd_int13_type_bad_type
           mov  ah,al
           and  ah,0x0F
           or   ah,0x10          ; 0001_0000, rate = 500
           jmp  short fd_int13_type_good

fd_int13_type_3:
           cmp  ah,0x03          ; 720k, 3.50"
           jne  short fd_int13_type_4
           ; if cyl = 79 and spt = 9
           cmp  dx,79
           jne  short fd_int13_type_bad_type
           cmp  cl,9
           jne  short fd_int13_type_bad_type
           mov  ah,al
           and  ah,0x0F
           or   ah,0x90          ; 1001_0000, rate = 250
           jmp  short fd_int13_type_good

fd_int13_type_4:
           cmp  ah,0x04          ; 1.44M, 3.50"
           jne  short fd_int13_type_5
           ; if cyl = 79 and spt = 9
           cmp  dx,79
           jne  short fd_int13_type_bad_type
           cmp  cl,9             ; 720k in a 1.44M drive
           jne  short fd_int13_type_4_0
           mov  ah,al
           and  ah,0x0F
           or   ah,0x90          ; 1001_0000, rate = 250
           jmp  short fd_int13_type_good
fd_int13_type_4_0:
           ; if cyl = 79 and spt = 18
           cmp  cl,18            ; 1.44M in a 1.44M drive
           jne  short fd_int13_type_bad_type
           mov  ah,al
           and  ah,0x0F
           or   ah,0x10          ; 0001_0000, rate = 500
           jmp  short fd_int13_type_good

fd_int13_type_5:
           cmp  ah,0x05          ; 2.88M, 3.50"
           jne  short fd_int13_type_bad_type
           ; if cyl = 79 and spt = 9
           cmp  dx,79
           jne  short fd_int13_type_bad_type
           cmp  cl,9             ; 720k in a 2.88M drive
           jne  short fd_int13_type_5_0
           mov  ah,al
           and  ah,0x0F
           or   ah,0x90          ; 1001_0000, rate = 250
           jmp  short fd_int13_type_good
           ; if cyl = 79 and spt = 18
fd_int13_type_5_0:
           cmp  cl,18            ; 1.44M in a 2.88M drive
           jne  short fd_int13_type_5_1
           mov  ah,al
           and  ah,0x0F
           or   ah,0x10          ; 0001_0000, rate = 500
           jmp  short fd_int13_type_good
           ; if cyl = 79 and spt = 36
fd_int13_type_5_1:
           cmp  cl,36            ; 2.88M in a 2.88M drive
           jne  short fd_int13_type_bad_type
           mov  ah,al
           and  ah,0x0F
           or   ah,0xD0          ; 1101_0000, rate = 1mb
           jmp  short fd_int13_type_good
fd_int13_type_bad_type:
           ; unknown type or combination
           mov  byte REG_AH,0x0C
           jmp  short fd_int13_fail_noah
           
fd_int13_type_good:
           mov  [bx],ah
           mov  ax,offset diskette_param_table
           mov  REG_DI,ax
           mov  word REG_ES,BIOS_BASE
           jmp  short fd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown function found
@@:           
           xchg cx,cx
           ; fall through

           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function failed, or we didn't support function in AH
fd_int13_fail:
           mov  byte REG_AH,0x01 ; invalid function or parameter
fd_int13_fail_noah:
           mov  al,REG_AH
           mov  [BDA_FDD_LAST_STATUS],al
fd_int13_fail_nostatus:
           or   word REG_FLAGS,0x0001
           jmp  short @f

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function was successful
fd_int13_success:
           mov  byte REG_AH,0x00 ; success
fd_int13_success_noah:
           mov  al,REG_AH
           mov  es:[BDA_FDD_LAST_STATUS],al
           and  word REG_FLAGS,(~0x0001)

@@:        pop  es
           mov  sp,bp
           pop  bp
           ret
int13_diskette_function endp

.end
