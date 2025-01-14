comment |*******************************************************************
*  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: harddrive.asm                                                      *
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
*            https:;github.com/fysnet/i440fx                               *
*                                                                          *
* DESCRIPTION:                                                             *
*   harddrive include file                                                 *
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
*   - define INT13_FLAT_ADDR 1 to allow the flat address space in serv 42h *
*                                                                          *
***************************************************************************|

.if DO_DEBUG           
hd_tran_none_str   db 'none',0
hd_tran_lba_str    db 'lba',0
hd_tran_large_str  db 'large',0
hd_tran_rechs_str  db 'r-echs',0
hd_lchs_str        db ' LCHS=%d/%d/%d',13,10,0
ata_x_x_str        db  'ata%d-%d: PCHS=%u/%d/%d translation=',0
.endif

INT13_FLAT_ADDR  equ  0

ata_print_slave    db ' slave',0
ata_print_master   db 'master',0
ata_print_str0     db 'ata%d %s: ',0
ata_print_str1     db ' ATA-%d Hard-Disk (%4u %cBytes)',13,10,0
ata_print_str2     db ' ATAPI-%d CD-Rom/DVD-Rom',13,10,0
ata_print_str3     db ' ATAPI-%d Device',13,10,0
ata_print_str4     db ' Unknown Device',13,10,0

hd_panic_string  db  'PANIC: file: ', %FILE, ' -- line: %i',13,10,0

; can be up to IPL_ENTRY_MAX_DESC_LEN-1 chars
ata_controller_str    db  '(ATA Device)',0
atapi_controller_str  db  '(ATAPI Device)',0

HDD_FDPT   struct
  phy_max_cyls       word
  phy_max_heads      byte
  signature          byte
  log_spt            byte
  start_wp_cyl       word
  resv1              byte
  control            byte
  log_max_cyls       word
  log_max_heads      byte
  landing_zone       word
  phy_spt            byte
  crc                byte
HDD_FDPT   ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; display a panic string and freeze
; on entry:
;  stack has line number
; on return
;  does not return...
; destroys all general
hdd_panic  proc near ; add nothing here
           push cs
           pop  ds
           mov  si,offset hd_panic_string
           call bios_printf
           add  sp,2
           call freeze
           .noret
hdd_panic  endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the hard drive(s)
; on entry:
;  es = 0x0000
; on return
;  nothing
; destroys all general
init_harddrive proc near uses ds
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
           mov  al,0x0A          ; 0000 1010 = reserved, disable IRQ 14
           mov  dx,0x03F6
           out  dx,al
           
           mov  es:[0x0474],al   ; hard disk status of last operation
           mov  es:[0x0477],al   ; hard disk port offset (XT only ???)
           mov  es:[0x048C],al   ; hard disk status register
           mov  es:[0x048D],al   ; hard disk error register
           mov  es:[0x048E],al   ; hard disk task complete flag
           mov  al,0x01
           mov  es:[0x0475],al   ; hard disk number attached
           mov  al,0xC0
           mov  es:[0x0476],al   ; hard disk control byte
           
           mov  ax,0x13
           mov  bx,offset int13_handler
           mov  cx,BIOS_BASE
           call set_int_vector
           mov  ax,0x76
           mov  bx,offset int76_handler
           mov  cx,BIOS_BASE
           call set_int_vector
           mov  ax,0x41
           mov  bx,EBDA_DATA->fdpt0
           mov  cx,EBDA_SEG
           call set_int_vector
           mov  ax,0x46
           mov  bx,EBDA_DATA->fdpt1
           mov  cx,EBDA_SEG
           call set_int_vector

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; move disk geometry data from CMOS to EBDA disk parameter table(s)
           mov  ah,0x12
           call cmos_get_byte
           push ax
           and  al,0xF0
           cmp  al,0xF0
           jne  short @f

           mov  ah,0x19
           mov  ch,0x1B          ; starting cmos register for type 47 drive 0
           mov  di,EBDA_DATA->fdpt0
           call init_harddrive_params

@@:        pop  ax
           and  al,0x0F
           cmp  al,0x0F
           jne  short @f

           mov  ah,0x1A
           mov  ch,0x24          ; starting cmos register for type 47 drive 1
           mov  di,EBDA_DATA->fdpt1
           call init_harddrive_params

@@:        ret
init_harddrive endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the hard drive parameters
; on entry:
;  ds = EBDA
;  ah = cmos register to get type
;  ch = starting cmos register for harddrive info (0x1B for 1st, 0x24 for second)
;  di-> fixed disk parameter table in EBDA
; on return
;  nothing
; destroys all general
;   CMOS    purpose              param table offset
;   1B/24    cylinders low              00
;   1C/25    cylinders high             01
;   1D/26    heads                      02
;   1E/27    write pre-comp low         05
;   1F/28    write pre-comp high        06
;   20/29    retries/bad map/heads>8    08
;   21/2A    landing zone low           0C
;   22/2B    landing zone high          0D
;   23/2C    sectors/track              0E
init_harddrive_params proc near uses ds
           
           call cmos_get_byte
           cmp  al,47            ; decimal 47 - user definable
           jne  init_harddrive_params_done

           mov  ax,EBDA_SEG
           mov  ds,ax

           ; Filling EBDA table for hard disk 0.
           mov  ah,ch
           add  ah,4             ; 0x1F / 0x28  ; write pre-comp high byte
           call cmos_get_byte
           mov  dh,al
           mov  ah,ch
           add  ah,3             ; 0x1E / 0x27  ; write pre-comp low byte
           call cmos_get_byte
           mov  ah,dh
           mov  [di+HDD_FDPT->start_wp_cyl],ax  ; write precomp word
           
           mov  ah,ch
           add  ah,5             ; 0x20 / 0x29  ; control byte
           call cmos_get_byte
           mov  [di+HDD_FDPT->control],al  ; drive control byte
           
           mov  ah,ch
           add  ah,7             ; 0x22 / 0x2B  ; landing zone high byte
           call cmos_get_byte
           mov  dh,al
           mov  ah,ch
           add  ah,6             ; 0x21 / 0x2A  ; landing zone low byte
           call cmos_get_byte
           mov  ah,dh
           mov  [di+HDD_FDPT->landing_zone],ax  ; landing zone word
           
           mov  ah,ch
           add  ah,1             ; 0x1C / 0x25  ; cylinders high byte
           call cmos_get_byte
           mov  bh,al
           mov  ah,ch
          ;add  ah,0             ; 0x1B / 0x24  ; cylinders low byte
           call cmos_get_byte
           mov  bl,al            ; bx = cylinders
           
           mov  ah,ch
           add  ah,2             ; 0x1D / 0x26  ; heads
           call cmos_get_byte
           mov  cl,al            ; cl = heads
           
           mov  ah,ch
           add  ah,8             ; 0x23 / 0x2C  ; spt
           call cmos_get_byte
           mov  dl,al            ; dl = sectors
           
           cmp  bx,1024
           ja   short @f         ; if cylinders > 1024, use translated style CHS

           ; no logical CHS mapping used, just physical CHS
           ; use Standard Fixed Disk Parameter Table (FDPT)
           mov  [di+HDD_FDPT->phy_spt],dl       ; number of physical sectors
           jmp  short hd0_post_store_logical
           
           ; complies with Phoenix style Translated Fixed Disk Parameter Table (FDPT)
@@:        mov  [di+HDD_FDPT->log_max_cyls],bx  ; number of physical cylinders
           mov  [di+HDD_FDPT->log_max_heads],cl ; number of physical heads
           mov  [di+HDD_FDPT->log_spt],dl       ; number of physical sectors
           mov  [di+HDD_FDPT->phy_spt],dl       ; number of logical sectors (same)
           mov  al,0xA0
           mov  [di+HDD_FDPT->signature],al     ; A0h signature, indicates translated table
           
           cmp  bx,2048
           ja   short @f
           ; 1024 < c <= 2048 cylinders
           shr  bx,1
           shl  cl,1
           jmp  short hd0_post_store_logical
           
@@:        cmp  bx,4096
           ja   short @f
           ; 2048 < c <= 4096 cylinders
           shr  bx,2
           shl  cl,2
           jmp  short hd0_post_store_logical
           
@@:        cmp  bx,8192
           ja   short @f
           ; 4096 < c <= 8192 cylinders
           shr  bx,3
           shl  cl,3
           jmp  short hd0_post_store_logical
           
@@:        ; 8192 < c <= 16384 cylinders
           shr  bx,4
           shl  cl,4
           
hd0_post_store_logical:
           mov  [di+HDD_FDPT->phy_max_cyls],bx  ; number of physical cylinders
           mov  [di+HDD_FDPT->phy_max_heads],cl  ; number of physical heads

           ; checksum
           mov  cx,15            ; repeat count
           xor  al,al            ; sum
@@:        add  al,[di]
           inc  di
           loop @b
           not  al               ; now take 2s complement
           inc  al
           mov  [di],al

init_harddrive_params_done:
           ret
init_harddrive_params endp


ATA_CHANNEL_SIZE    equ   6  ; size of ata_x 
ATA_DEVICE_SIZE     equ  28  ; size of ata_x_x

; Global defines -- ATA register and register bits.
; command block & control block regs
ATA_CB_DATA  equ  0   ; data reg         in/out pio_base_addr1+0
ATA_CB_ERR   equ  1   ; error            in     pio_base_addr1+1
ATA_CB_FR    equ  1   ; feature reg         out pio_base_addr1+1
ATA_CB_SC    equ  2   ; sector count     in/out pio_base_addr1+2
ATA_CB_SN    equ  3   ; sector number    in/out pio_base_addr1+3
ATA_CB_CL    equ  4   ; cylinder low     in/out pio_base_addr1+4
ATA_CB_CH    equ  5   ; cylinder high    in/out pio_base_addr1+5
ATA_CB_DH    equ  6   ; device head      in/out pio_base_addr1+6
ATA_CB_STAT  equ  7   ; primary status   in     pio_base_addr1+7
ATA_CB_CMD   equ  7   ; command             out pio_base_addr1+7
ATA_CB_ASTAT equ  6   ; alternate status in     pio_base_addr2+6
ATA_CB_DC    equ  6   ; device control      out pio_base_addr2+6
ATA_CB_DA    equ  7   ; device address   in     pio_base_addr2+7

ATA_CB_ER_ICRC   equ  0x80    ; ATA Ultra DMA bad CRC
ATA_CB_ER_BBK    equ  0x80    ; ATA bad block
ATA_CB_ER_UNC    equ  0x40    ; ATA uncorrected error
ATA_CB_ER_MC     equ  0x20    ; ATA media change
ATA_CB_ER_IDNF   equ  0x10    ; ATA id not found
ATA_CB_ER_MCR    equ  0x08    ; ATA media change request
ATA_CB_ER_ABRT   equ  0x04    ; ATA command aborted
ATA_CB_ER_NTK0   equ  0x02    ; ATA track 0 not found
ATA_CB_ER_NDAM   equ  0x01    ; ATA address mark not found

ATA_CB_ER_P_SNSKEY   equ  0xf0   ; ATAPI sense key (mask)
ATA_CB_ER_P_MCR      equ  0x08   ; ATAPI Media Change Request
ATA_CB_ER_P_ABRT     equ  0x04   ; ATAPI command abort
ATA_CB_ER_P_EOM      equ  0x02   ; ATAPI End of Media
ATA_CB_ER_P_ILI      equ  0x01   ; ATAPI Illegal Length Indication

; ATAPI Interrupt Reason bits in the Sector Count reg (CB_SC)
ATA_CB_SC_P_TAG      equ  0xf8   ; ATAPI tag (mask)
ATA_CB_SC_P_REL      equ  0x04   ; ATAPI release
ATA_CB_SC_P_IO       equ  0x02   ; ATAPI I/O
ATA_CB_SC_P_CD       equ  0x01   ; ATAPI C/D

; bits 7-4 of the device/head (CB_DH) reg
ATA_CB_DH_DEV0   equ  0xa0    ; select device 0
ATA_CB_DH_DEV1   equ  0xb0    ; select device 1
ATA_CB_DH_LBA    equ  0x40    ; use LBA

; status reg (CB_STAT and CB_ASTAT) bits
ATA_CB_STAT_BSY    equ  0x80  ; busy
ATA_CB_STAT_RDY    equ  0x40  ; ready
ATA_CB_STAT_DF     equ  0x20  ; device fault
ATA_CB_STAT_WFT    equ  0x20  ; write fault (old name)
ATA_CB_STAT_SKC    equ  0x10  ; seek complete
ATA_CB_STAT_SERV   equ  0x10  ; service
ATA_CB_STAT_DRQ    equ  0x08  ; data request
ATA_CB_STAT_CORR   equ  0x04  ; corrected
ATA_CB_STAT_IDX    equ  0x02  ; index
ATA_CB_STAT_ERR    equ  0x01  ; error (ATA)
ATA_CB_STAT_CHK    equ  0x01  ; check (ATAPI)

; device control reg (CB_DC) bits
ATA_CB_DC_HD15     equ  0x08  ; bit should always be set to one
ATA_CB_DC_SRST     equ  0x04  ; soft reset
ATA_CB_DC_NIEN     equ  0x02  ; disable interrupts

; Most mandatory and optional ATA commands (from ATA-3),
ATA_CMD_CFA_ERASE_SECTORS              equ  0xC0
ATA_CMD_CFA_REQUEST_EXT_ERR_CODE       equ  0x03
ATA_CMD_CFA_TRANSLATE_SECTOR           equ  0x87
ATA_CMD_CFA_WRITE_MULTIPLE_WO_ERASE    equ  0xCD
ATA_CMD_CFA_WRITE_SECTORS_WO_ERASE     equ  0x38
ATA_CMD_CHECK_POWER_MODE1              equ  0xE5
ATA_CMD_CHECK_POWER_MODE2              equ  0x98
ATA_CMD_DEVICE_RESET                   equ  0x08
ATA_CMD_EXECUTE_DEVICE_DIAGNOSTIC      equ  0x90
ATA_CMD_FLUSH_CACHE                    equ  0xE7
ATA_CMD_FORMAT_TRACK                   equ  0x50
ATA_CMD_IDENTIFY_DEVICE                equ  0xEC
ATA_CMD_IDENTIFY_DEVICE_PACKET         equ  0xA1
ATA_CMD_IDENTIFY_PACKET_DEVICE         equ  0xA1
ATA_CMD_IDLE1                          equ  0xE3
ATA_CMD_IDLE2                          equ  0x97
ATA_CMD_IDLE_IMMEDIATE1                equ  0xE1
ATA_CMD_IDLE_IMMEDIATE2                equ  0x95
ATA_CMD_INITIALIZE_DRIVE_PARAMETERS    equ  0x91
ATA_CMD_INITIALIZE_DEVICE_PARAMETERS   equ  0x91
ATA_CMD_NOP                            equ  0x00
ATA_CMD_PACKET                         equ  0xA0
ATA_CMD_READ_BUFFER                    equ  0xE4
ATA_CMD_READ_DMA                       equ  0xC8
ATA_CMD_READ_DMA_QUEUED                equ  0xC7
ATA_CMD_READ_MULTIPLE                  equ  0xC4
ATA_CMD_READ_SECTORS                   equ  0x20
ATA_CMD_READ_VERIFY_SECTORS            equ  0x40
ATA_CMD_RECALIBRATE                    equ  0x10
ATA_CMD_REQUEST_SENSE                  equ  0x03
ATA_CMD_SEEK                           equ  0x70
ATA_CMD_SET_FEATURES                   equ  0xEF
ATA_CMD_SET_MULTIPLE_MODE              equ  0xC6
ATA_CMD_SLEEP1                         equ  0xE6
ATA_CMD_SLEEP2                         equ  0x99
ATA_CMD_STANDBY1                       equ  0xE2
ATA_CMD_STANDBY2                       equ  0x96
ATA_CMD_STANDBY_IMMEDIATE1             equ  0xE0
ATA_CMD_STANDBY_IMMEDIATE2             equ  0x94
ATA_CMD_WRITE_BUFFER                   equ  0xE8
ATA_CMD_WRITE_DMA                      equ  0xCA
ATA_CMD_WRITE_DMA_QUEUED               equ  0xCC
ATA_CMD_WRITE_MULTIPLE                 equ  0xC5
ATA_CMD_WRITE_SECTORS                  equ  0x30
ATA_CMD_WRITE_VERIFY                   equ  0x3C

ATA_IFACE_NONE      equ  0x00
ATA_IFACE_ISA       equ  0x01
ATA_IFACE_PCI       equ  0x02

ATA_TYPE_NONE       equ  0x00
ATA_TYPE_UNKNOWN    equ  0x01
ATA_TYPE_ATA        equ  0x02
ATA_TYPE_ATAPI      equ  0x03

ATA_DEVICE_NONE    equ  0x00
ATA_DEVICE_HD      equ  0xFF
ATA_DEVICE_CDROM   equ  0x05

ATA_MODE_NONE      equ  0x00
ATA_MODE_PIO16     equ  0x00
ATA_MODE_PIO32     equ  0x01
ATA_MODE_ISADMA    equ  0x02
ATA_MODE_PCIDMA    equ  0x03
ATA_MODE_USEIRQ    equ  0x10

ATA_TRANSLATION_NONE    equ  0
ATA_TRANSLATION_LBA     equ  1
ATA_TRANSLATION_LARGE   equ  2
ATA_TRANSLATION_RECHS   equ  3

ATA_DATA_NO        equ  0x00
ATA_DATA_IN        equ  0x01
ATA_DATA_OUT       equ  0x02

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the hard drive's EBDA initial settings
; on entry:
;  nothing
; on return
;  nothing
; destroys all general
ata_init   proc near uses ds
           
           call bios_get_ebda
           mov  ds,ax
           
           mov  cx,BX_MAX_ATA_INTERFACES
           xor  bx,bx
@@:        mov  byte [bx+EBDA_DATA->ata_0_iface],ATA_IFACE_NONE
           mov  word [bx+EBDA_DATA->ata_0_iobase1],0x0000
           mov  word [bx+EBDA_DATA->ata_0_iobase2],0x0000
           mov  byte [bx+EBDA_DATA->ata_0_irq],0
           add  bx,ATA_CHANNEL_SIZE
           loop @b

           mov  cx,BX_MAX_ATA_DEVICES
           xor  bx,bx
@@:        mov  byte [bx+EBDA_DATA->ata_0_0_type],ATA_TYPE_NONE
           mov  byte [bx+EBDA_DATA->ata_0_0_device],ATA_DEVICE_NONE
           mov  byte [bx+EBDA_DATA->ata_0_0_removable],0
           mov  byte [bx+EBDA_DATA->ata_0_0_lock],0
           mov  byte [bx+EBDA_DATA->ata_0_0_mode],ATA_MODE_NONE
           mov  word [bx+EBDA_DATA->ata_0_0_blksize],0
           mov  byte [bx+EBDA_DATA->ata_0_0_translation],ATA_TRANSLATION_NONE
           mov  word [bx+EBDA_DATA->ata_0_0_lchs_heads],0
           mov  word [bx+EBDA_DATA->ata_0_0_lchs_cyl],0
           mov  word [bx+EBDA_DATA->ata_0_0_lchs_spt],0
           mov  word [bx+EBDA_DATA->ata_0_0_pchs_heads],0
           mov  word [bx+EBDA_DATA->ata_0_0_pchs_cyl],0
           mov  word [bx+EBDA_DATA->ata_0_0_pchs_spt],0
           mov  dword [bx+EBDA_DATA->ata_0_0_sectors_low],0
           mov  dword [bx+EBDA_DATA->ata_0_0_sectors_high],0
           add  bx,ATA_DEVICE_SIZE
           loop @b

           mov  cx,BX_MAX_ATA_DEVICES
           xor  bx,bx
@@:        mov  byte [bx+EBDA_DATA->ata_0_0_hdidmap],BX_MAX_ATA_DEVICES
           mov  byte [bx+EBDA_DATA->ata_0_0_cdidmap],BX_MAX_ATA_DEVICES
           add  bx,1
           loop @b

           mov  byte [bx+EBDA_DATA->ata_hdcount],0
           mov  byte [bx+EBDA_DATA->ata_cdcount],0

           ret
ata_init   endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the hard drive(s)
; on entry:
;  nothing
; on return
;  nothing
; destroys all general
ata_detect proc near uses ds
           call bios_get_ebda
           mov  ds,ax

           mov  byte [EBDA_DATA->ata_0_iface],ATA_IFACE_ISA
           mov  word [EBDA_DATA->ata_0_iobase1],PORT_ATA1_CMD_BASE
           mov  word [EBDA_DATA->ata_0_iobase2],0x3F0
           mov  byte [EBDA_DATA->ata_0_irq],14

           mov  byte [EBDA_DATA->ata_1_iface],ATA_IFACE_ISA
           mov  word [EBDA_DATA->ata_1_iobase1],PORT_ATA2_CMD_BASE
           mov  word [EBDA_DATA->ata_1_iobase2],0x370
           mov  byte [EBDA_DATA->ata_1_irq],15

           mov  byte [EBDA_DATA->ata_2_iface],ATA_IFACE_ISA
           mov  word [EBDA_DATA->ata_2_iobase1],0x1E8
           mov  word [EBDA_DATA->ata_2_iobase2],0x3E0
           mov  byte [EBDA_DATA->ata_2_irq],12

           mov  byte [EBDA_DATA->ata_3_iface],ATA_IFACE_ISA
           mov  word [EBDA_DATA->ata_3_iobase1],0x168
           mov  word [EBDA_DATA->ata_3_iobase2],0x360
           mov  byte [EBDA_DATA->ata_3_irq],11
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; allocate room on the stack for some locals
           push bp
           mov  bp,sp
           sub  sp,0x256

hd_buffer       equ  [bp-0x200]  ; hd_buffer[512]
hd_hdcount      equ  [bp-0x202]  ;  word
hd_cdcount      equ  [bp-0x204]  ;  word
hd_device       equ  [bp-0x206]  ;  word
hd_type         equ  [bp-0x208]  ;  word
hd_iobase1      equ  [bp-0x20A]  ;  word
hd_iobase2      equ  [bp-0x20C]  ;  word
hd_blksize      equ  [bp-0x20E]  ;  word
hd_channel      equ  [bp-0x210]  ;  word
hd_slave        equ  [bp-0x212]  ;  word
hd_sectors_low  equ  [bp-0x216]  ; dword
hd_sectors_high equ  [bp-0x21A]  ; dword
hd_cylinders    equ  [bp-0x21C]  ;  word
hd_heads        equ  [bp-0x21E]  ;  word
hd_spt          equ  [bp-0x220]  ;  word
hd_translation  equ  [bp-0x222]  ;  word
hd_removable    equ  [bp-0x224]  ;  word
hd_mode         equ  [bp-0x226]  ;  word
hd_sizeinmb     equ  [bp-0x22A]  ; dword
hd_version      equ  [bp-0x22C]  ;  word
hd_model        equ  [bp-0x256]  ; hd_model[42]

           mov  word hd_hdcount,0
           mov  word hd_cdcount,0

           mov  word hd_device,0
ata_device_detection:
           ; calculate channel and slave values
           mov  ax,hd_device
           mov  hd_slave,ax
           shr  ax,1
           mov  hd_channel,ax
           and  word hd_slave,1
           shl  word hd_slave,4

           ; get the two base io addresses
           imul bx,ax,ATA_CHANNEL_SIZE
           mov  ax,[bx+EBDA_DATA->ata_0_iobase1]
           mov  hd_iobase1,ax
           mov  ax,[bx+EBDA_DATA->ata_0_iobase2]
           mov  hd_iobase2,ax
           
           ; disable interrupts
           mov  dx,hd_iobase2
           add  dx,ATA_CB_DC
           mov  al,(ATA_CB_DC_HD15 | ATA_CB_DC_NIEN)
           out  dx,al

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; look for device
           
           ; select which drive
           mov  dx,hd_iobase1
           add  dx,ATA_CB_DH
           mov  ax,ATA_CB_DH_DEV0
           add  ax,hd_slave
           out  dx,al

           mov  dx,hd_iobase1
           add  dx,ATA_CB_SC
           mov  al,0x55
           out  dx,al      ; out ATA_CB_SC,55
           inc  dx
           mov  al,0xAA
           out  dx,al      ; out ATA_CB_SN,AA

           dec  dx
           out  dx,al      ; out ATA_CB_SC,AA
           mov  al,0x55
           inc  dx
           out  dx,al      ; out ATA_CB_SN,55
           
           dec  dx
           out  dx,al      ; out ATA_CB_SC,55
           mov  al,0xAA
           inc  dx
           out  dx,al      ; out ATA_CB_SN,AA
           
           dec  dx
           in   al,dx      ; in ATA_CB_SC (55)
           mov  ah,al
           inc  dx         ; in ATA_CB_SN (AA)
           in   al,dx

           ; if ax == 0x55AA, we found a drive
           cmp  ax,0x55AA
           jne  short ata_no_drive_found
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we found a device
           mov  ax,hd_device
           imul bx,ax,ATA_DEVICE_SIZE
           mov  byte [bx+EBDA_DATA->ata_0_0_type],ATA_TYPE_UNKNOWN
           
           push es
           push ds
           pop  es
           call ata_reset
           pop  es
           
           ; check for ata or atapi
           mov  dx,hd_iobase1
           add  dx,ATA_CB_DH
           mov  ax,ATA_CB_DH_DEV0
           add  ax,hd_slave
           out  dx,al

           mov  dx,hd_iobase1
           add  dx,ATA_CB_SC
           in   al,dx      ; in ATA_CB_SC
           mov  ah,al
           inc  dx
           in   al,dx      ; in ATA_CB_SN

           ; if ax = 0x0101, it is ata
           cmp  ax,0x0101
           jne  short ata_no_drive_found

           inc  dx
           in   al,dx      ; in ATA_CB_CL
           mov  ah,al
           inc  dx
           in   al,dx      ; in ATA_CB_CH
           mov  cx,ax      ; save it in cx
           add  dx,2
           in   al,dx      ; in ATA_CB_STAT

           ; if cx = 0x14EB, we have atapi
           cmp  cx,0x14EB
           jne  short @f
           mov  byte [bx+EBDA_DATA->ata_0_0_type],ATA_TYPE_ATAPI
           jmp  short ata_no_drive_found
@@:        ; if cx = 0x0000 and al != 0, we have ata
           cmp  cx,0x0000
           jne  short @f
           cmp  al,0x00
           je   short @f
           mov  byte [bx+EBDA_DATA->ata_0_0_type],ATA_TYPE_ATA
           jmp  short ata_no_drive_found
@@:        ; there is no drive attached
           mov  byte [bx+EBDA_DATA->ata_0_0_type],ATA_TYPE_NONE

ata_no_drive_found:
           ; calculate pointer to the current device struct
           mov  ax,hd_device
           imul bx,ax,ATA_DEVICE_SIZE

           ; get the type found
           xor  ah,ah
           mov  al,[bx+EBDA_DATA->ata_0_0_type]
           mov  hd_type,ax

           ; did we find an ATA device
           cmp  word hd_type,ATA_TYPE_ATA
           jne  try_atapi_identify
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; send the IDENTIFY command
           
           ; temporary values for the transfer
           mov  byte [bx+EBDA_DATA->ata_0_0_device],ATA_DEVICE_HD
           mov  byte [bx+EBDA_DATA->ata_0_0_mode],ATA_MODE_PIO16
           
           ; on entry to ata_cmd_data_io, bx -> EBDA_device[]
           lea  ax,hd_buffer
           push ax       ; offset of buffer
           push ss       ; segment of buffer
           pushd 0       ; lba_high
           pushd 0       ; lba_low
           push 0        ; sector
           push 0        ; head
           push 0        ; cylinder
           push 1        ; count
           push ATA_CMD_IDENTIFY_DEVICE
           push word hd_device ; device index
           push 0        ; io_flag (0 = read, 1 = write)
           call ata_cmd_data_io
           add  sp,26

           or   ax,ax
           jz   short @f
           ;
           ; panic: we didn't detect the ATA via INQUIRY
           push %LINE
           jmp  hdd_panic
           ;

           ; ss:di points to the buffer
@@:        lea  di,hd_buffer
           mov  al,ss:[di+0]
           and  al,0x80
           shr  al,7
           mov  hd_removable,al

           mov  byte hd_mode,ATA_MODE_PIO32
           cmp  byte ss:[di+96],0
           jnz  short @f
           mov  byte hd_mode,ATA_MODE_PIO16

@@:        mov  ax,ss:[di+10]
           mov  hd_blksize,ax

           mov  ax,ss:[di+(1 * sizeof(word))]
           mov  hd_cylinders,ax
           mov  ax,ss:[di+(3 * sizeof(word))]
           mov  hd_heads,ax
           mov  ax,ss:[di+(6 * sizeof(word))]
           mov  hd_spt,ax
           
           ; assume words 60 and 61
           mov  eax,ss:[di+(60 * sizeof(word))]
           mov  hd_sectors_low,eax
           mov  dword hd_sectors_high,0
           mov  ax,ss:[di+(83 * sizeof(word))]
           test ax,(1 << 10)
           jz   short @f
           mov  eax,ss:[di+(100 * sizeof(word))]
           mov  hd_sectors_low,eax
           mov  eax,ss:[di+(102 * sizeof(word))]
           mov  hd_sectors_high,eax
           
@@:        mov  byte [bx+EBDA_DATA->ata_0_0_device],ATA_DEVICE_HD
           mov  al,hd_removable
           mov  [bx+EBDA_DATA->ata_0_0_removable],al
           mov  al,hd_mode
           mov  [bx+EBDA_DATA->ata_0_0_mode],al
           mov  ax,hd_blksize
           mov  [bx+EBDA_DATA->ata_0_0_blksize],ax
           mov  ax,hd_heads
           mov  [bx+EBDA_DATA->ata_0_0_pchs_heads],ax
           mov  ax,hd_cylinders
           mov  [bx+EBDA_DATA->ata_0_0_pchs_cyl],ax
           mov  ax,hd_spt
           mov  [bx+EBDA_DATA->ata_0_0_pchs_spt],ax
           mov  eax,hd_sectors_low
           mov  [bx+EBDA_DATA->ata_0_0_sectors_low],eax
           mov  eax,hd_sectors_high
           mov  [bx+EBDA_DATA->ata_0_0_sectors_high],eax

.if DO_DEBUG
           ; print the found device
           push ds
           push cs
           pop  ds
           push word hd_spt
           push word hd_heads
           push word hd_cylinders
           push word hd_slave
           push word hd_channel
           mov  si,offset ata_x_x_str
           call bios_printf
           add  sp,10
           pop  ds
.endif
           ; get the translation from the CMOS
           mov  ax,hd_channel
           shr  ax,1
           add  ax,0x39
           mov  ah,al
           call cmos_get_byte
           xor  ah,ah
           
           ; for (shift=hd_device%4; shift>0; shift--) translation >>= 2;
           mov  cx,hd_device
           and  cx,3
@@:        jcxz short @f    ; the loop below will catch cx=0, but
           shr  ax,2        ;  we jmp back to here so to use @@'s
           loop @b
@@:        and  ax,3
           mov  hd_translation,ax
           mov  [bx+EBDA_DATA->ata_0_0_translation],al
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initalize the parameters due to the translation used
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; translation = none
           cmp  ax,ATA_TRANSLATION_NONE
           jne  short hd_not_translation_none
.if DO_DEBUG           
           push ds
           push cs
           pop  ds
           mov  si,offset hd_tran_none_str
           call display_string
           pop  ds
.endif
           jmp  hd_translation_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; translation = lba
hd_not_translation_none:
           cmp  ax,ATA_TRANSLATION_LBA
           jne  short hd_not_translation_lba
.if DO_DEBUG           
           push ds
           push cs
           pop  ds
           mov  si,offset hd_tran_lba_str
           call display_string
           pop  ds
.endif
           
           mov  word hd_spt,63
           xor  edx,edx
           mov  eax,hd_sectors_low
           mov  ecx,63
           div  ecx
           mov  hd_sectors_low,eax
           push eax        ; save sectors_low
           shr  eax,10     ; div by 1024

           ; if hd_heads > 64, hd_heads = 128
           cmp  ax,64
           jna  short @f
           mov  ax,128
           jmp  short hd_lba_cylinders
@@:        ; if hd_heads > 32 hd_heads = 64
           cmp  ax,32
           jna  short @f
           mov  ax,64
           jmp  short hd_lba_cylinders
@@:        ; if hd_heads > 16 hd_heads = 32
           cmp  ax,16
           jna  short @f
           mov  ax,32
           jmp  short hd_lba_cylinders
           ; else, hd_heads = 16
@@:        mov  ax,16

hd_lba_cylinders:
           mov  hd_heads,ax
           mov  cx,ax      ; cx = heads
           pop  eax        ; restore sectors_low
           xor  edx,edx
           movzx ecx,cx
           div  ecx
           mov  hd_cylinders,ax
           jmp  short hd_translation_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; translation = large
hd_not_translation_lba:
           cmp  ax,ATA_TRANSLATION_LARGE
           jne  short hd_not_translation_large
.if DO_DEBUG           
           push ds
           push cs
           pop  ds
           mov  si,offset hd_tran_large_str
           call display_string
           pop  ds
.endif

hd_translation_is_large:
           mov  ax,hd_cylinders
           mov  cx,hd_heads
@@:        cmp  ax,1024
           jbe  short @f
           shr  ax,1      ; cyl >>= 1
           shl  cx,1      ; heads <<= 1
           cmp  cx,128    ; stop if heads == 128+
           jae  short @f
           jmp  short @b
@@:        jmp  short hd_translation_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; translation = r-echs
hd_not_translation_large:
           cmp  ax,ATA_TRANSLATION_RECHS
           jne  short hd_translation_done
.if DO_DEBUG           
           push ds
           push cs
           pop  ds
           mov  si,offset hd_tran_rechs_str
           call display_string
           pop  ds
.endif

           ; make sure we don't overflow
           mov  ax,hd_heads
           cmp  ax,16
           jne  short hd_translation_is_large
           mov  ax,hd_cylinders
           cmp  ax,61439
           jbe  short @f
           mov  word hd_cylinders,61439
@@:        mov  word hd_heads,15
           xor  edx,edx
           movzx eax,word hd_cylinders
           mov  ecx,15     ;
           shl  eax,4      ; mul 16
           div  ecx        ; div 15
           mov  hd_cylinders,ax
           ; then do the 'large' translation stuff too
           jmp  short hd_translation_is_large

hd_translation_done:
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; make sure the lchs.cylinders isn't above 1024
           cmp  word hd_cylinders,1024
           jbe  short @f
           mov  word hd_cylinders,1024
@@:        
.if DO_DEBUG           
           push ds
           push cs
           pop  ds
           mov  si,offset hd_lchs_str
           push word hd_spt
           push word hd_heads
           push word hd_cylinders
           call bios_printf
           add  sp,6
           pop  ds
.endif

           mov  ax,hd_heads
           mov  [bx+EBDA_DATA->ata_0_0_lchs_heads],ax
           mov  ax,hd_cylinders
           mov  [bx+EBDA_DATA->ata_0_0_lchs_cyl],ax
           mov  ax,hd_spt
           mov  [bx+EBDA_DATA->ata_0_0_lchs_spt],ax
           
           mov  ax,hd_device
           mov  si,hd_hdcount
           mov  [si+EBDA_DATA->ata_0_0_hdidmap],al
           inc  si
           mov  hd_hdcount,si
           jmp  short not_atapi_identify

try_atapi_identify:
           ; did we find an ATA device
           cmp  word hd_type,ATA_TYPE_ATAPI
           jne  short not_atapi_identify

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; send the ATAPI IDENTIFY command
           
           ; temporary values for the transfer
           mov  byte [bx+EBDA_DATA->ata_0_0_device],ATA_DEVICE_CDROM
           mov  byte [bx+EBDA_DATA->ata_0_0_mode],ATA_MODE_PIO16
           
           ; on entry to ata_cmd_data_io, bx -> EBDA_device[]
           lea  ax,hd_buffer
           push ax       ; offset of buffer
           push ss       ; segment of buffer
           pushd 0       ; lba_high
           pushd 0       ; lba_low
           push 0        ; sector
           push 0        ; head
           push 0        ; cylinder
           push 1        ; count
           push ATA_CMD_IDENTIFY_DEVICE_PACKET
           push word hd_device ; device index
           push 0        ; io_flag (0 = read, 1 = write)
           call ata_cmd_data_io
           add  sp,26

           or   ax,ax
           jz   short @f
           ;
           ; panic: we didn't detect the ATA via INQUIRY
           push %LINE
           jmp  hdd_panic
           ;

           ; ss:di points to the buffer
@@:        lea  di,hd_buffer
           ; type
           mov  al,ss:[di+1]
           and  al,0x1F
           mov  [bx+EBDA_DATA->ata_0_0_device],al
           ; removable
           mov  al,ss:[di+0]
           and  al,0x80
           shr  al,7
           mov  [bx+EBDA_DATA->ata_0_0_removable],al
           ; mode
           mov  al,ATA_MODE_PIO32
           cmp  byte ss:[di+96],0
           jnz  short @f
           mov  al,ATA_MODE_PIO16
@@:        mov  [bx+EBDA_DATA->ata_0_0_mode],al
           mov  ax,2048
           mov  [bx+EBDA_DATA->ata_0_0_blksize],ax

           mov  ax,hd_device
           mov  si,hd_cdcount
           mov  [si+EBDA_DATA->ata_0_0_cdidmap],al
           inc  si
           mov  hd_cdcount,si

not_atapi_identify:
           cmp  word hd_type,ATA_TYPE_ATA
           jne  short not_ata_blksize

           ; default to:
           mov  cx,((21 << 8) | 11)  ; left = 21, right = 11
           cmp  word hd_blksize,1024
           jne  short @f
           mov  cx,((22 << 8) | 10)  ; left = 22, right = 10
           jmp  short hd_do_shift
@@:        cmp  word hd_blksize,4096
           jne  short hd_do_shift
           mov  cx,((24 << 8) | 8)  ; left = 24, right = 8
hd_do_shift:
           mov  eax,[bx+EBDA_DATA->ata_0_0_sectors_low]
           shr  eax,cl
           mov  cl,ch
           mov  edx,[bx+EBDA_DATA->ata_0_0_sectors_high]
           shl  edx,cl
           or   eax,edx
           mov  hd_sizeinmb,eax

           jmp  short @f  ; skip over type check (i.e.: fall through)
not_ata_blksize:
           cmp  word hd_type,ATA_TYPE_ATAPI
           jne  short not_atapi_blksize
@@:
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get ata(pi) version
           mov  ax,ss:[di+160]
           mov  cx,(1<<15)
           mov  dx,15
@@:        test ax,cx
           jnz  short @f
           shr  cx,1
           dec  dx
           jnz  short @b
@@:        mov  hd_version,dx
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get model string
           ; (it is in big-endian format)
           push di
           add  di,54  ; offset 54 (word 27)
           lea  si,hd_model
           mov  cx,20
@@:        mov  al,ss:[di+1]
           mov  ss:[si],al
           mov  al,ss:[di]
           mov  ss:[si+1],al
           add  si,2
           add  di,2
           loop @b

           ; now go backwards through any trailing spaces
           mov  cx,40
@@:        dec  si
           cmp  byte ss:[si],0x20
           jne  short @f
           loop @b

@@:        ; make sure it is null terminated
           inc  si
           xor  al,al
           mov  ss:[si],al
           pop  di

not_atapi_blksize:
           ; don't print anything if nothing found
           cmp  word hd_type,ATA_TYPE_NONE
           jne  short @f
           jmp  hd_done_print
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now print what we found
@@:        mov  ax,offset ata_print_slave
           cmp  word hd_slave,0
           jne  short @f
           mov  ax,offset ata_print_master
@@:        mov  si,offset ata_print_str0
           push ds
           push cs
           pop  ds
           push ax
           push word hd_channel
           call bios_printf
           add  sp,4
           pop  ds

           cmp  word hd_type,ATA_TYPE_ATA
           jne  short not_ata_print
           push ds
           push cs
           pop  ds
           lea  di,hd_model
@@:        mov  al,ss:[di]
           or   al,al
           jz   short @f
           call display_char
           inc  di
           jmp  short @b
@@:        pop  ds
           mov  eax,hd_sizeinmb
           mov  dl,'M'
           cmp  eax,(1<<16)
           jb   short @f
           shr  eax,10
           mov  dl,'G'
@@:        mov  si,offset ata_print_str1
           push ds
           push cs
           pop  ds
           push dx
           push ax
           push word hd_version
           call bios_printf
           add  sp,6
           pop  ds

           ; add this drive to our vector table
           push es
           push cs
           pop  es
           xor  eax,eax          ; lba = 0
           xor  ecx,ecx          ; vector = 0000:0000
           mov  si,offset ata_controller_str
           mov  edx,((IPL_FLAGS_NSATA << 16) | (IPL_TYPE_HARDDISK << 8) | (0 << 0))
           mov  dl,hd_device
           add  dl,0x80
           call add_boot_vector
           pop  es

           jmp  short hd_done_print

not_ata_print:
           cmp  word hd_type,ATA_TYPE_ATAPI
           jne  short not_atapi_print
           push ds
           push cs
           pop  ds
           lea  di,hd_model
@@:        mov  al,ss:[di]
           or   al,al
           jz   short @f
           call display_char
           inc  di
           jmp  short @b
@@:        pop  ds

           mov  si,offset ata_print_str2
           mov  al,[bx+EBDA_DATA->ata_0_0_device]
           cmp  al,ATA_DEVICE_CDROM
           je   short @f
           mov  si,offset ata_print_str3
@@:        push ds
           push cs
           pop  ds
           push word hd_version
           call bios_printf
           add  sp,2
           pop  ds
           
           ; add this drive to our vector table
           push es
           push cs
           pop  es
           xor  eax,eax          ; lba = 0
           xor  ecx,ecx          ; vector = 0000:0000
           mov  si,offset atapi_controller_str
           mov  edx,((IPL_FLAGS_NSATA << 16) | (IPL_TYPE_CDROM << 8) | (0 << 0))
           mov  dl,hd_device
           add  dl,0x80
           call add_boot_vector
           pop  es

           jmp  short hd_done_print

not_atapi_print:
           push ds
           push cs
           pop  ds
           mov  si,offset ata_print_str4
           call display_string
           pop  ds

hd_done_print:
           ; we are at the end of the for loop.
           ; increment device and loop
           inc  word hd_device
           cmp  word hd_device,BX_MAX_ATA_DEVICES
           je   short @f
           jmp  ata_device_detection

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; done detecting and displaying the ata(pi) devices
@@:        mov  ax,hd_cdcount
           mov  [EBDA_DATA->ata_cdcount],al
           mov  ax,hd_hdcount
           mov  [EBDA_DATA->ata_hdcount],al
           
           ; save the count of hard drives to the BIOS Data Area
           push ds
           xor  bx,bx
           mov  ds,bx
           mov  [0x0475],al

           ; make sure and move to the next line
           push cs
           pop  ds
           mov  al,13
           call display_char
           mov  al,10
           call display_char
           pop  ds
           
           mov  sp,bp            ; restore the stack
           pop  bp
           ret
ata_detect endp

TIMEOUT          equ  0
BSY              equ  1
NOT_BSY          equ  2
NOT_BSY_DRQ      equ  3
NOT_BSY_NOT_DRQ  equ  4
NOT_BSY_RDY      equ  5
IDE_TIMEOUT      equ  32000

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; reset a device
; on entry:
;  es = segment of EBDA
;  ax = device index (0,1,2,...,7)
;  [bx+EBDA_DATA->ata_0_0_type] -> ata_device_t[device]
; on return
;  nothing
; destroys none
ata_reset  proc near uses all
           
           ; ax = device
           mov  cx,ax            ; save for later
           shr  ax,1             ; ax = channel

           imul si,ax,ATA_CHANNEL_SIZE
           mov  di,es:[si+EBDA_DATA->ata_0_iobase1]
           mov  si,es:[si+EBDA_DATA->ata_0_iobase2]

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; do the reset
           mov  al,(ATA_CB_DC_HD15 | ATA_CB_DC_NIEN | ATA_CB_DC_SRST)
           mov  dx,si
           add  dx,ATA_CB_DC
           out  dx,al

           ; wait for BSY
           push cx
           mov  dx,di
           mov  al,BSY
           mov  cx,20
           call await_ide
           pop  cx
           
           ; clear SRST
           mov  al,(ATA_CB_DC_HD15 | ATA_CB_DC_NIEN)
           mov  dx,si
           add  dx,ATA_CB_DC
           out  dx,al

           mov  al,es:[bx+EBDA_DATA->ata_0_0_type]
           cmp  al,ATA_TYPE_NONE
           je   short ata_reset_enable

           ; select the drive
           mov  al,ATA_CB_DH_DEV0
           and  cl,1             ; cl = slave
           shl  cl,4
           add  al,cl
           mov  dx,di
           add  dx,ATA_CB_DH
           out  dx,al

           ; get id
           mov  dx,di
           add  dx,ATA_CB_SC
           in   al,dx
           mov  ah,al
           inc  dx
           in   al,dx
           ; ah = sector, al = number

           cmp  ax,0x0101
           jne  short ata_wait_not_busy

           mov  al,NOT_BSY_RDY
           mov  ah,es:[bx+EBDA_DATA->ata_0_0_type]
           cmp  ah,ATA_TYPE_ATA
           je   short @f
           mov  al,NOT_BSY
@@:        mov  dx,di
           mov  cx,IDE_TIMEOUT
           call await_ide

ata_wait_not_busy:
           mov  al,NOT_BSY
           mov  dx,di
           mov  cx,IDE_TIMEOUT
           call await_ide

ata_reset_enable:
           mov  al,ATA_CB_DC_HD15
           mov  dx,si
           add  dx,ATA_CB_DC
           out  dx,al

           ret
ata_reset  endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send an io command to the device
; on entry:
;  ds = segment of EBDA
;  [bx+EBDA_DATA->ata_0_0_type] -> ata_device_t[device]
;  stack contains: (cdecl)
;    ioflag, device, command, count, cylinder,  head,   sector,  lba_low, lba_high, segment, offset
;    [bp+4], [bp+6], [bp+8], [bp+10], [bp+12], [bp+14], [bp+16], [bp+18],  [bp+22], [bp+26], [bp+28]
;  if sector == 0, use LBA, else use CHS                         (dword)   (dword)
;  ioflag = 0 = read, else = 1 = write
; on return:
;    0 = no error
;    1 = BUSY bit set
;    2 = read error
;    3 = expected DRQ=1
;    4 = no sectors left to read/verify
;    5 = more sectors to read/verify
;    6 = no sectors left to write
;    7 = more sectors to write
; destroys none (except ax)
ata_cmd_data_io proc near ; don't add anything here
           push bp
           mov  bp,sp
           sub  sp,0x02

blksize_io  equ  [bp-0x02]  ;  word
           
           ; save the registers we use
           push edx
           push ecx
           push ebx
           push eax
           push si
           push di

           mov  ax,[bp+6]        ; device
           shr  ax,1             ; ax = channel

           imul si,ax,ATA_CHANNEL_SIZE
           mov  di,[si+EBDA_DATA->ata_0_iobase1]
           mov  si,[si+EBDA_DATA->ata_0_iobase2]
           mov  dl,[bx+EBDA_DATA->ata_0_0_mode]

           ; get the count of words to read/write
           mov  cx,0x200    ; assume 512 bytes
           mov  ax,[bp+8]
           cmp  ax,ATA_CMD_IDENTIFY_DEVICE
           je   short @f
           cmp  ax,ATA_CMD_IDENTIFY_DEVICE_PACKET
           je   short @f
           mov  cx,[bx+EBDA_DATA->ata_0_0_blksize]
@@:        shr  cx,1        ; words
           cmp  dl,ATA_MODE_PIO32
           jne  short @f
           shr  cx,1        ; dwords
@@:        mov  blksize_io,cx    ; blksize
           
           ; reset count of transferred data
           mov  word [EBDA_DATA->trsfsectors],0
           mov  dword [EBDA_DATA->trsfbytes],0

           ; if the controller is busy, return
           mov  dx,di            ; iobase1
           add  dx,ATA_CB_STAT
           in   al,dx
           test al,ATA_CB_STAT_BSY
           jz   short @f
           mov  ax,1
           jmp  ata_cmd_data_io_done

@@:        mov  dx,si            ; iobase2
           add  dx,ATA_CB_DC
           mov  al,(ATA_CB_DC_HD15 | ATA_CB_DC_NIEN)
           out  dx,al

           ; sector will be 0 only on lba access. Convert to lba-chs
           cmp  word [bp+16],0x00 ; sector
           jne  short ata_sector_non_zero

           ; is count >= 256 sectors
           mov  ax,[bp+10]       ; count
           or   ah,ah
           jnz  short @f
           
           ; will we be more than a 28-bit lba?
           cmp  dword [bp+22],0  ; lba_high
           jne  short @f

           ; will we be more than a 28-bit lba?
           mov  eax,(1<<28)
           movzx ecx,word [bp+10] ; count
           sub  eax,ecx
           cmp  [bp+18],eax      ; lba_low
           jnae short ata_sector_28_bit

           ; send the High Order bytes
@@:        mov  dx,di            ; iobase1
           add  dx,ATA_CB_FR
           xor  al,al
           out  dx,al            ; Features

           inc  dx
           mov  al,[bp+10+1]     ; high byte of count
           out  dx,al            ; sector count

           inc  dx
           mov  al,[bp+18+3]     ; bits 31:24
           out  dx,al            ; sector number
           
           inc  dx
           mov  al,[bp+22]       ; bits 7:0
           out  dx,al            ; cyl low
           
           inc  dx
           mov  al,[bp+22+1]     ; bits 15:8
           out  dx,al            ; sector number
           
           or   word [bp+8],0x04        ; command (use HO)
           and  word [bp+10],0xFF       ; count
           and dword [bp+18],0x00FFFFFF ; lba_low

ata_sector_28_bit:
           ; sector = lowbyte(lba_low)
           mov  eax,[bp+18]
           xor  ah,ah
           mov  [bp+16],ax

           ; lba_low >>= 8
           shr  dword [bp+18],8

           ; cylinder = lowword(lba_low)
           mov  eax,[bp+18]
           mov  [bp+12],ax

           ; head = (highword(lba_low) & 0xF) | ATA_CB_DH_LBA
           shr  eax,16
           and  ax,0x000F
           or   ax,ATA_CB_DH_LBA
           mov  [bp+14],ax

ata_sector_non_zero:
           mov  dx,di            ; iobase1
           add  dx,ATA_CB_FR
           xor  al,al
           out  dx,al            ; Features

           inc  dx
           mov  al,[bp+10]       ; low byte of count
           out  dx,al            ; sector count

           inc  dx
           mov  al,[bp+16]       ; sector
           out  dx,al            ; sector number
           
           inc  dx
           mov  al,[bp+12]       ; low byte
           out  dx,al            ; cyl low
           
           inc  dx
           mov  al,[bp+12+1]     ; high byte
           out  dx,al            ; cyl high

           inc  dx
           mov  ax,[bp+6]        ; device
           and  al,1             ; ax = slave
           shl  al,4
           add  al,ATA_CB_DH_DEV0
           or   al,[bp+14]       ; head
           out  dx,al
           
           inc  dx
           mov  al,[bp+8]        ; command
           out  dx,al            ; send the command

           ; wait for the not busy
           mov  al,NOT_BSY_DRQ
           mov  dx,di            ; iobase1
           mov  cx,IDE_TIMEOUT
           call await_ide

           ; get the status byte
           mov  dx,di            ; iobase1
           add  dx,ATA_CB_STAT
           in   al,dx

           ; if status & ATA_CB_STAT_ERR = error
           test al,ATA_CB_STAT_ERR
           jz   short @f
           mov  ax,2
           jmp  ata_cmd_data_io_done
@@:        test al,ATA_CB_STAT_DRQ
           jnz  short @f
           mov  ax,3
           jmp  ata_cmd_data_io_done
           
@@:        sti                   ; enable interrupts
           
ata_io_main_loop:
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; do a sector transfer
           mov  dx,di            ; iobase1

           push di               ; save iobase1
           push si               ; save iobase2
           push es
           mov  di,[bp+28]       ; offset
           mov  ax,[bp+26]       ; segment
           mov  cx,blksize_io    ; count of words/dwords

           ; make sure we don't overrun a segment
           cmp  di,0xF800
           jbe  short @f
           sub  di,0x0800        ; sub 2k from offset
           add  ax,0x0080        ; add 2k to segment
@@:        mov  es,ax
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; do we do words or dwords ?
           mov  al,[bx+EBDA_DATA->ata_0_0_mode]
           cmp  al,ATA_MODE_PIO32
           je   short ata_do_32bit

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 16-bits at a time
           cmp  word [bp+4],0    ; 0 = read
           jne  short ata_io_main_write16
           rep
             insw  ; read in cx words
           jmp  short ata_io_next
ata_io_main_write16:
           mov  si,di
           es:
           rep
             outsw  ; write in cx words
           mov  di,si
           jmp  short ata_io_next

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 32-bits at a time
ata_do_32bit:
           cmp  word [bp+4],0    ; 0 = read
           jne  short ata_io_main_write32
           rep
             insd  ; read in cx dwords
           jmp  short ata_io_next
ata_io_main_write32:
           mov  si,di
           es:
           rep
             outsd  ; write in cx dwords
           mov  di,si

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; save the address for next time
ata_io_next:
           mov  [bp+28],di       ; offset
           mov  [bp+26],es       ; segment
           pop  es
           pop  si
           pop  di

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           inc  word [EBDA_DATA->trsfsectors]
           dec  word [bp+10]     ; count

           ; if it was a read, we need to wait
           cmp  word [bp+4],0    ; 0 = read
           jne  short @f
           ; wait for the not busy
           mov  al,NOT_BSY
           mov  dx,di            ; iobase1
           mov  cx,IDE_TIMEOUT
           call await_ide

@@:        mov  dx,di            ; iobase1
           add  dx,ATA_CB_STAT
           in   al,dx            ; status

           cmp  word [bp+4],0    ; 0 = read
           jne  short ata_io_status_write
           
           cmp  word [bp+10],0   ; count
           jnz  short ata_io_status0

           and  al,(ATA_CB_STAT_BSY | ATA_CB_STAT_RDY | ATA_CB_STAT_DRQ | ATA_CB_STAT_ERR)
           cmp  al,ATA_CB_STAT_RDY
           je   short ata_io_main_end_loop
           mov  ax,4
           jmp  short ata_cmd_data_io_done

ata_io_status0:
           and  al,(ATA_CB_STAT_BSY | ATA_CB_STAT_RDY | ATA_CB_STAT_DRQ | ATA_CB_STAT_ERR)
           cmp  al,(ATA_CB_STAT_RDY | ATA_CB_STAT_DRQ)
           je   ata_io_main_loop
           mov  ax,5
           jmp  short ata_cmd_data_io_done


ata_io_status_write:
           cmp  word [bp+10],0   ; count
           jnz  short ata_io_status1

           and  al,(ATA_CB_STAT_BSY | ATA_CB_STAT_RDY | ATA_CB_STAT_DF | ATA_CB_STAT_DRQ | ATA_CB_STAT_ERR)
           cmp  al,ATA_CB_STAT_RDY
           je   short ata_io_main_end_loop
           mov  ax,6
           jmp  short ata_cmd_data_io_done

ata_io_status1:
           and  al,(ATA_CB_STAT_BSY | ATA_CB_STAT_RDY | ATA_CB_STAT_DRQ | ATA_CB_STAT_ERR)
           cmp  al,(ATA_CB_STAT_RDY | ATA_CB_STAT_DRQ)
           je   ata_io_main_loop
           mov  ax,7
           jmp  short ata_cmd_data_io_done

ata_io_main_end_loop:
           ; enable interrupts
           mov  dx,si            ; iobase2
           add  dx,ATA_CB_DC
           mov  al,ATA_CB_DC_HD15
           out  dx,al

           ; return success
           xor  ax,ax
           
ata_cmd_data_io_done:
           ; restore the registers we used
           pop  di
           pop  si
           ; we need to preserved the return value in ax
           mov  bx,ax            ; bx = return value
           pop  eax              ; restore eax
           mov  ax,bx            ; ax = return value
           pop  ebx              ; restore ebx
           pop  ecx
           pop  edx

           mov  sp,bp            ; restore the stack
           pop  bp
           ret
ata_cmd_data_io endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; wait for ide to be ready
; on entry:
;  cx = timout
;  al = flag
;  dx = iobase1
; on return
;  ax = 0 = success
; destroys none
await_ide  proc near uses ax bx ecx dx esi
           
           movzx esi,cx          ; timeout
           xor  ecx,ecx          ; time = 0
           mov  bl,al            ; flag

           add  dx,ATA_CB_STAT
           in   al,dx

await_ide_loop:
           in   al,dx            ; status in al
           mov  ah,al            ; save in ah as well
           inc  ecx              ; time++
           
           cmp  bl,BSY
           jne  short @f
           ; result = status & ATA_CB_STAT_BSY;
           and  al,ATA_CB_STAT_BSY
           jmp  short await_result
@@:        cmp  bl,NOT_BSY
           jne  short @f
           ; result = !(status & ATA_CB_STAT_BSY);
           and  al,ATA_CB_STAT_BSY
           xor  al,ATA_CB_STAT_BSY
           jmp  short await_result
@@:        cmp  bl,NOT_BSY_DRQ
           jne  short @f
           ; result = !(status & ATA_CB_STAT_BSY) && (status & ATA_CB_STAT_DRQ);
           and  al,ATA_CB_STAT_BSY
           xor  al,ATA_CB_STAT_BSY
           jz   short await_result
           mov  al,ah
           and  al,ATA_CB_STAT_DRQ
           jmp  short await_result
@@:        cmp  bl,NOT_BSY_NOT_DRQ
           jne  short @f
           ; result = !(status & ATA_CB_STAT_BSY) && !(status & ATA_CB_STAT_DRQ);
           and  al,ATA_CB_STAT_BSY
           xor  al,ATA_CB_STAT_BSY
           jz   short await_result
           mov  al,ah
           and  al,ATA_CB_STAT_DRQ
           xor  al,ATA_CB_STAT_DRQ
           jmp  short await_result
@@:        cmp  bl,NOT_BSY_RDY
           jne  short @f
           ; result = !(status & ATA_CB_STAT_BSY) && (status & ATA_CB_STAT_RDY);
           and  al,ATA_CB_STAT_BSY
           xor  al,ATA_CB_STAT_BSY
           jz   short await_result
           mov  al,ah
           and  al,ATA_CB_STAT_RDY
           jmp  short await_result
@@:        cmp  bl,TIMEOUT
           jne  short await_result
           xor  al,al
           
await_result:
           or   al,al
           jnz  short await_done

           test ah,ATA_CB_STAT_ERR
           jnz  short await_done1

           or   esi,esi            ; esi == 0
           jz   short await_done1
           mov  eax,ecx
           shr  eax,11
           cmp  eax,esi
           ja   short await_done1

           jmp  short await_ide_loop

await_done1:
           mov  ax,0xFFFF
           ret

await_done:
           xor  ax,ax
           ret
await_ide  endp

EXT_SERV_PACKET struct
  ex_size      byte     ; 0x10 or 0x18
  ex_resv      byte     ;
  ex_count     word     ; ( <= 0x7F)
  ex_offset    word     ; seg:offset of transfer buffer
  ex_segment   word     ;  (FFFF:FFFF = use flataddr)
  ex_lba       qword    ; lba of starting sector
  ex_flataddr  qword    ; 64-bit flat address of transfer buffer
EXT_SERV_PACKET ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; ATA hard drive disk services
; on entry:
;  es = segment of EBDA
;  stack currently has (after we set bp):
;   flags    cs      ip      es      ds
;  [bp+44] [bp+42] [bp+40] [bp+38] [bp+36]
;    edi     esi     ebp     esp     ebx     edx     ecx     eax
;  [bp+04] [bp+08] [bp+12] [bp+16] [bp+20] [bp+24] [bp+28] [bp+32]
; on return
;  nothing
; destroys nothing
int13_harddisk_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           sub  sp,0x12

hd_sv_device    equ  [bp-0x02]
hd_sv_count     equ  [bp-0x04]
hd_sv_cylinder  equ  [bp-0x06]
hd_sv_sector    equ  [bp-0x08]
hd_sv_head      equ  [bp-0x0A]
hd_sv_lba_low   equ  [bp-0x0E]
hd_sv_lba_high  equ  [bp-0x12]

           ; set ds = es
           push es
           pop  ds

           ; set es = bios data area (0x0040)
           push es
           mov  ax,0x0040
           mov  es,ax
           
           ; clear completion flag
           mov  byte es:[0x008E],0
           
           ; make sure the device is valid
           mov  dx,REG_DX
           cmp  dl,0x80
           jb   hd_int13_fail
           cmp  dl,(0x80 + BX_MAX_ATA_DEVICES)
           jae  hd_int13_fail
           
           ; get the device
           mov  bl,dl
           xor  bh,bh
           sub  bx,0x80
           mov  al,[bx+EBDA_DATA->ata_0_0_hdidmap]
           cmp  al,BX_MAX_ATA_DEVICES
           jae  hd_int13_fail

           xor  ah,ah
           mov  hd_sv_device,ax
           imul bx,ax,ATA_DEVICE_SIZE
           
           mov  ah,REG_AH
           ; hd_sv_device = device
           ; ds = segment of EBDA
           ; ah = service
           ; bx ->EBDA_DATA->device
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; controller reset
           cmp  ah,0x00
           jne  short @f
           mov  ax,hd_sv_device
           push es
           push ds
           pop  es
           call ata_reset
           pop  es
           jmp  hd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disk status
@@:        cmp  ah,0x01
           jne  short @f
           mov  ah,es:[0x0074]
           mov  REG_AH,ah
           mov  byte es:[0x0074],0x00
           or   ah,ah
           jnz  hd_int13_fail_nostatus
           jmp  hd_int13_success_noah
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; transfer sectors
@@:        cmp  ah,0x02          ; read disk sectors
           je   short hd_int13_transfer
           cmp  ah,0x03          ; write disk sectors
           je   short hd_int13_transfer
           cmp  ah,0x04          ; verify disk sectors
           jne  @f
hd_int13_transfer:
           xor  ah,ah
           mov  al,REG_AL
           mov  hd_sv_count,ax
           mov  al,REG_CL
           shl  ax,2
           and  ah,0x03
           mov  al,REG_CH
           mov  hd_sv_cylinder,ax
           xor  ah,ah
           mov  al,REG_CL
           and  al,0x3F
           mov  hd_sv_sector,ax
           mov  al,REG_DH
           mov  hd_sv_head,ax

           ; if count > 128, or count == 0, or sector == 0, error
           cmp  word hd_sv_count,0
           je   hd_int13_fail
           cmp  word hd_sv_count,128
           ja   hd_int13_fail
           cmp  word hd_sv_sector,0
           je   hd_int13_fail
           
           ; check that the chs value is within our lchs value
           mov  ax,[bx+EBDA_DATA->ata_0_0_lchs_cyl]
           cmp  hd_sv_cylinder,ax
           jae  hd_int13_fail
           mov  ax,[bx+EBDA_DATA->ata_0_0_lchs_heads]
           cmp  hd_sv_head,ax
           jae  hd_int13_fail
           mov  ax,[bx+EBDA_DATA->ata_0_0_lchs_spt]
           cmp  hd_sv_sector,ax
           ja   hd_int13_fail

           ; if we are verifying a sector(s), just return as good
           cmp  byte REG_AH,0x04
           je   hd_int13_success

           ; do we need to translate from chs to lba
           mov  dx,[bx+EBDA_DATA->ata_0_0_lchs_heads]
           mov  ax,[bx+EBDA_DATA->ata_0_0_pchs_heads]
           cmp  dx,ax
           jne  short hd_int13_translate
           mov  dx,[bx+EBDA_DATA->ata_0_0_lchs_spt]
           mov  ax,[bx+EBDA_DATA->ata_0_0_pchs_spt]
           cmp  dx,ax
           je   short hd_int13_notranslate
hd_int13_translate:
           ; lba = (((cylinder * lchs_heads) + head) * lchs_spt) + (sector - 1);
           movzx eax,word hd_sv_cylinder
           movzx ecx,word [bx+EBDA_DATA->ata_0_0_lchs_heads]
           mul  ecx
           movzx ecx,word hd_sv_head
           add  eax,ecx
           movzx ecx,word [bx+EBDA_DATA->ata_0_0_lchs_spt]
           mul  ecx
           movzx ecx,word hd_sv_sector
           add  eax,ecx
           dec  eax
           mov  hd_sv_lba_low,eax
           mov  dword hd_sv_lba_high,0
           mov  word hd_sv_sector,0x0000 ; force LBA
hd_int13_notranslate:
           xor  ax,ax                 ; ioflag (0 = read)
           mov  cx,ATA_CMD_READ_SECTORS
           cmp  byte REG_AH,0x02
           je   short hd_int13_read
           inc  ax                    ; ioflag (1 = write)
           mov  cx,ATA_CMD_WRITE_SECTORS
hd_int13_read:
           ; on entry to ata_cmd_data_io, bx -> EBDA_device[]
           push word REG_BX           ; offset of buffer
           push word REG_ES           ; segment of buffer
           push dword hd_sv_lba_high  ; lba_high
           push dword hd_sv_lba_low   ; lba_low
           push word hd_sv_sector     ; sector
           push word hd_sv_head       ; head
           push word hd_sv_cylinder   ; cylinder
           push word hd_sv_count      ; count
           push cx                    ; command
           push word hd_sv_device     ; device index
           push ax                    ; io_flag (0 = read, 1 = write)
           call ata_cmd_data_io
           add  sp,26

           ; get count of sectors transferred
           mov  cx,[EBDA_DATA->trsfsectors]
           mov  REG_AL,cl

           ; get the status (ax = status)
           or   ax,ax
           jz   hd_int13_success
           ; else there was an error
           mov  byte REG_AH,0x0C
           jmp  hd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; format disk track
@@:        cmp  ah,0x05
           jne  short @f
           ; we currently don't support this function
           mov  byte REG_AH,0x01
           jmp  hd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get disk drive parameters
@@:        cmp  ah,0x08
           jne  short @f
           mov  word REG_AX,0x0000
           ; cylinder (ch = low 8 bits, cl = high bits in 7:6)
           mov  cx,[bx+EBDA_DATA->ata_0_0_lchs_cyl]
           dec  cx               ; zero based
           xchg ch,cl
           shl  cl,6
           ; spt (low 5:0 bits of cl)
           mov  ax,[bx+EBDA_DATA->ata_0_0_lchs_spt]
           and  al,0x3F
           or   cl,al
           mov  REG_CX,cx
           ; zero based head in dh
           mov  ax,[bx+EBDA_DATA->ata_0_0_lchs_heads]
           dec  ax
           mov  REG_DH,al
           ; dl = count of drives
           mov  al,[EBDA_DATA->ata_hdcount]
           mov  REG_DL,al
           ; es:di (floppies only)
           jmp  hd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize controller with drive parameters
@@:        cmp  ah,0x09
           jne  short @f

           ; we can call init_harddrive_params for this ??? minus the adding to the vector table ???

           jmp  hd_int13_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check drive ready
@@:        cmp  ah,0x10
           jne  short @f
           mov  ax,hd_sv_device
           shr  ax,1
           imul si,ax,ATA_CHANNEL_SIZE
           mov  dx,[si+EBDA_DATA->ata_0_iobase1]
           add  dx,ATA_CB_STAT
           in   al,dx
           and  al,(ATA_CB_STAT_BSY | ATA_CB_STAT_RDY)
           cmp  al,ATA_CB_STAT_RDY
           je   hd_int13_success
           mov  byte REG_AH,0xAA ; drive not ready
           jmp  hd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disk drive size
@@:        cmp  ah,0x15
           jne  short @f
           ; count = (((cylinders - 1) * heads * spt
           movzx eax,word [bx+EBDA_DATA->ata_0_0_lchs_cyl]
           dec  eax
           movzx ecx,word [bx+EBDA_DATA->ata_0_0_lchs_heads]
           mul  ecx
           movzx ecx,word [bx+EBDA_DATA->ata_0_0_lchs_spt]
           mul  ecx
           mov  REG_DX,ax
           shr  eax,16
           mov  REG_CX,ax
           mov  byte REG_AH,0x03 ; hard disk
           jmp  hd_int13_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set media type format
@@:        cmp  ah,0x18
           jne  short @f
           mov  byte REG_AH,0x01 ; function not available
           jmp  hd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS installation check
@@:        cmp  ah,0x41
           jne  short @f
           cmp  word REG_BX,0x55AA
           jne  short @f
           mov  word REG_BX,0xAA55
           mov  byte REG_AH,0x30 ; EDD 3.0
           ; 0x0007 = bit 0 = functions 42h,43h,44h,47h,48h
           ;          bit 1 = functions 45h,46h,48h,49h, INT 15/AH=52h
           ;          bit 2 = functions 48h,4Eh
           mov  word REG_CX,0x0007
           jmp  hd_int13_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS extended services
@@:        cmp  ah,0x42          ; extended read
           je   short hd_int13_ext_transfer
           cmp  ah,0x43          ; extended write
           je   short hd_int13_ext_transfer
           cmp  ah,0x44          ; extended verify
           je   short hd_int13_ext_transfer
           cmp  ah,0x47          ; extended seek
           jne  @f
hd_int13_ext_transfer:
           push es
           mov  si,REG_SI
           mov  ax,REG_DS
           mov  es,ax
           mov  eax,es:[si+EXT_SERV_PACKET->ex_lba+0] ; get low 32-bits
           mov  edx,es:[si+EXT_SERV_PACKET->ex_lba+4] ; get high 32-bits
           movzx cx,byte es:[si+EXT_SERV_PACKET->ex_size]
           pop  es
           ; if size of packet < 16, error
           cmp  cx,16
           jb   hd_int13_fail
           ; if edx:eax >= EBDA_DATA->ata_0_0_sectors, error
           cmp  edx,[bx+EBDA_DATA->ata_0_0_sectors_high]
           ja   hd_int13_fail
           jb   short hd_int13_ext_transfer1
           cmp  eax,[bx+EBDA_DATA->ata_0_0_sectors_low]
           jae  hd_int13_fail
hd_int13_ext_transfer1:
           ; if we are verifying or seeking to sector(s), just return as good
           mov  ah,REG_AH
           cmp  ah,0x44
           je   hd_int13_success
           cmp  ah,0x47
           je   hd_int13_success

           ; else do the transfer
           xor  ax,ax                 ; ioflag (0 = read)
           mov  cx,ATA_CMD_READ_SECTORS
           cmp  byte REG_AH,0x42
           je   short hd_int13_read1
           inc  ax                    ; ioflag (1 = write)
           mov  cx,ATA_CMD_WRITE_SECTORS
hd_int13_read1:
           push es
           mov  si,REG_SI
           mov  dx,REG_DS
           mov  es,dx
           
.if INT13_FLAT_ADDR
           ; if seg:off == 0xFFFF:FFFF and ex_size >= 18, use the flat address
           mov  di,es:[si+EXT_SERV_PACKET->ex_offset]  ; offset of buffer
           mov  dx,es:[si+EXT_SERV_PACKET->ex_segment] ; segment of buffer
           cmp  byte es:[si+EXT_SERV_PACKET->ex_size],18
           jb   short int13_flat_0
           cmp  dword es:[si+EXT_SERV_PACKET->ex_offset],0xFFFFFFFF
           jne  short int13_flat_0
           mov  edi,es:[si+EXT_SERV_PACKET->ex_flataddr]
           mov  edx,edi
           shr  edx,4     ; dx = segment
           and  di,0x000F ; di = offset
           ; there is an error if high 16-bit of edx is non zero
           test edx,0xFFFF0000
           jz   short int13_flat_0
           pop  es
           jmp  hd_int13_fail
int13_flat_0:
.endif
           ; on entry to ata_cmd_data_io, bx -> EBDA_device[]
.if INT13_FLAT_ADDR
           push di                                       ; offset of buffer
           push dx                                       ; segment of buffer
.else
           push word es:[si+EXT_SERV_PACKET->ex_offset]  ; offset of buffer
           push word es:[si+EXT_SERV_PACKET->ex_segment] ; segment of buffer
.endif
           push dword es:[si+EXT_SERV_PACKET->ex_lba+4]  ; lba_high
           push dword es:[si+EXT_SERV_PACKET->ex_lba+0]  ; lba_low
           push 0x0000                                   ; sector (0 = indicate lba)
           push 0x0000                                   ; head
           push 0x0000                                   ; cylinder
           push word es:[si+EXT_SERV_PACKET->ex_count]   ; count
           push cx                                       ; command
           push word hd_sv_device                        ; device index
           push ax                                       ; io_flag (0 = read, 1 = write)
           call ata_cmd_data_io
           add  sp,26
           
           ; get count of sectors transferred
           mov  cx,[EBDA_DATA->trsfsectors]
           mov  es:[si+EXT_SERV_PACKET->ex_count],cx
           pop  es

           ; get the status (ax = status)
           or   ax,ax
           jz   short hd_int13_success
           ; else there was an error
           mov  byte REG_AH,0x0C
           jmp  short hd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS media
@@:        cmp  ah,0x45          ; lock/unlock drive
           je   short hd_int13_media
           cmp  ah,0x49          ; extended media change
           jne  short @f
hd_int13_media:
           ; we don't do anything, so just return success
           jmp  short hd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS eject media
@@:        cmp  ah,0x46
           jne  short @f
           mov  byte REG_AH,0xB2 ; media not removable
           jmp  short hd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS get drive parameters
@@:        cmp  ah,0x48
           jne  short @f
           push es
           mov  es,REG_DS
           mov  di,REG_SI
           mov  ax,hd_sv_device
           call int13_edd
           pop  es
           or   ax,ax
           jnz  short hd_int13_fail
           jmp  short hd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS set hardware configuration
@@:        cmp  ah,0x4E
           jne  short @f
           mov  al,REG_AL
           cmp  al,0x01          ; disable prefetch
           je   short hd_int13_success
           cmp  al,0x03          ; set pio mode 0
           je   short hd_int13_success
           cmp  al,0x04          ; set default pio transfer mode
           je   short hd_int13_success
           cmp  al,0x06          ; disable inter 13h dma
           je   short hd_int13_success
           jmp  short hd_int13_fail ; else, fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        ;cmp  ah,0x  ; next value
           ;jne  short @f
           ;
           ;
           ;jmp  hd_int13_success

           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; print a message of this unknown call value
           push ds
           push cs
           pop  ds
           shr  ax,8
           push ax
           mov  si,offset hd_int13_unknown_call_str
           call bios_printf
           add  sp,2
           call freeze
           pop  ds

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function failed, or we didn't support function in AH
hd_int13_fail:
           mov  byte REG_AH,0x01 ; invalid function or parameter
hd_int13_fail_noah:
           mov  al,REG_AH
           mov  es:[0x0074],al
hd_int13_fail_nostatus:
           or   word REG_FLAGS,0x0001
           jmp  short @f

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function was successful
hd_int13_success:
           mov  byte REG_AH,0x00 ; success
hd_int13_success_noah:
           mov  al,REG_AH
           mov  es:[0x0074],al
           and  word REG_FLAGS,(~0x0001)

@@:        pop  es
           mov  sp,bp
           pop  bp
           ret
int13_harddisk_function endp

hd_int13_unknown_call_str  db 13,10,'*** hd_int13: Unknown call 0x%02X ***',13,10,0

; 66 bytes (74 if iface_path is 16 bytes)
; (user will specify 74 if path is 16 bytes)
INT13_DPT  struct
  ; size = 26 = v1.x
  dpt_size            word
  dpt_infos           word
  dpt_cylinders      dword
  dpt_heads          dword
  dpt_spt            dword
  dpt_sector_count1  dword
  dpt_sector_count2  dword
  dpt_blksize         word
  ; size = 30 = v2.x
  dpt_dpte_offset     word
  dpt_dpte_segment    word
  ; size >= 66 = v3.x
  dpt_key             word
  dpt_dpi_length      byte
  dpt_reserved1       byte
  dpt_reserved2       word
  dpt_host_bus         dup 4
  dpt_iface_type       dup 8
  dpt_iface_path       dup 8
  ; if a t13 bios (length requested > 74)
  ;  the device path is 16 bytes long
  dpt_device_path      dup 8
  dpt_reserved3       byte
  dpt_checksum        byte
INT13_DPT  ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; return the drive parameters in es:di
; on entry:
;  ds = segment of EBDA
;  ax = device index (0,1,2,...,7)
;  es:di->address of parameter list
; on return
;  ax = 0 = success, else failed
; destroys none
int13_edd  proc near uses ebx ecx edx
           push bp
           mov  bp,sp
           sub  sp,10

dpt_req_sz   equ  [bp-2]
dpt_type     equ  [bp-4]
dpt_device   equ  [bp-6]
dpt_iface    equ  [bp-8]
dpt_len_flag equ  [bp-9]

           push eax              ; do not put above with 'uses'
           
           ; bx = device's information
           mov  dpt_device,ax
           imul bx,ax,ATA_DEVICE_SIZE
           
           ; get the type of device
           xor  ah,ah
           mov  al,[bx+EBDA_DATA->ata_0_0_type]
           mov  dpt_type,ax
           
           ; get the size requested
           mov  ax,es:[di+INT13_DPT->dpt_size]
           cmp  ax,26
           jb   int13_edd_error
           mov  dpt_req_sz,ax

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; size is at least 26, so do EDD 1.x
           mov  word es:[di+INT13_DPT->dpt_size],26
           cmp  word dpt_type,ATA_TYPE_ATA
           jne  short dpt_is_atapi

           ; get and save the count of phys cylinders
           movzx ecx,word [bx+EBDA_DATA->ata_0_0_pchs_cyl]
           mov  ax,(1<<1)        ; assume valid
           
           ; is the information we have valid?
           mov  edx,[bx+EBDA_DATA->ata_0_0_sectors_high]
           or   edx,edx
           jz   short @f
           xor  edx,edx
           mov  eax,[bx+EBDA_DATA->ata_0_0_sectors_low]
           movzx ecx,word [bx+EBDA_DATA->ata_0_0_pchs_spt]
           div  ecx
           xor  edx,edx
           movzx ecx,word [bx+EBDA_DATA->ata_0_0_pchs_heads]
           div  ecx
           cmp  eax,0x3FFF
           jbe  short @f
           ; our values are not valid
           xor  ax,ax
           mov  ecx,0x3FFF
           ; values are valid, so write them
@@:        mov  es:[di+INT13_DPT->dpt_infos],ax
           mov  es:[di+INT13_DPT->dpt_cylinders],ecx
           movzx eax,word [bx+EBDA_DATA->ata_0_0_pchs_heads]
           mov  es:[di+INT13_DPT->dpt_heads],eax
           movzx eax,word [bx+EBDA_DATA->ata_0_0_pchs_spt]
           mov  es:[di+INT13_DPT->dpt_spt],eax
           mov  eax,[bx+EBDA_DATA->ata_0_0_sectors_low]
           mov  es:[di+INT13_DPT->dpt_sector_count1],eax
           mov  eax,[bx+EBDA_DATA->ata_0_0_sectors_high]
           mov  es:[di+INT13_DPT->dpt_sector_count2],eax
           jmp  short dpt_is_not_atapi
dpt_is_atapi:
           cmp  word dpt_type,ATA_TYPE_ATAPI
           jne  short dpt_is_not_atapi
           ; removable, media change, lockable, max values
           ; cyl/head/spt field is not valid (0<<1)
           mov  ax,((1<<2) | (1<<4) | (1<<5) | (1<< 6)) ; | (0<<1)
           mov  es:[di+INT13_DPT->dpt_infos],ax
           mov  eax,0xFFFFFFFF
           mov  es:[di+INT13_DPT->dpt_cylinders],eax
           mov  es:[di+INT13_DPT->dpt_heads],eax
           mov  es:[di+INT13_DPT->dpt_spt],eax
           mov  es:[di+INT13_DPT->dpt_sector_count1],eax
           mov  es:[di+INT13_DPT->dpt_sector_count2],eax
dpt_is_not_atapi:
           mov  ax,[bx+EBDA_DATA->ata_0_0_blksize]
           mov  es:[di+INT13_DPT->dpt_blksize],ax
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; see if size is at least 30 (EDD 2.x)
           cmp  word dpt_req_sz,30
           jb   int13_edd_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; size is at least 30, so do EDD 2.x
           ; (put the address of our dpte and then fill the dpte)
           call bios_get_ebda
           mov  word es:[di+INT13_DPT->dpt_size],30
           mov  es:[di+INT13_DPT->dpt_dpte_segment],ax
           mov  ax,EBDA_DATA->dpte_iobase1
           mov  es:[di+INT13_DPT->dpt_dpte_offset],ax
           
           ; get translation and mode values
           mov  al,[bx+EBDA_DATA->ata_0_0_translation]
           mov  ah,[bx+EBDA_DATA->ata_0_0_mode]

           ; options
           mov  dx,(1<<4)  ; lba translation
           cmp  ah,ATA_MODE_PIO32
           jne  short @f
           or   dx,(1<<7)

@@:        ; are we an ata device
           cmp  word dpt_type,ATA_TYPE_ATA
           jne  short dpt_is_atapi1

           cmp  al,ATA_TRANSLATION_NONE
           je   short @f
           or   dx,(1<<3)        ; chs translation
@@:        cmp  al,ATA_TRANSLATION_LBA
           jne  short @f
           or   dx,(1<<9)        ;
@@:        cmp  al,ATA_TRANSLATION_RECHS
           jne  short @f
           or   dx,(3<<9)        ;
           jmp  short dpt_is_not_atapi1

dpt_is_atapi1:
           cmp  word dpt_type,ATA_TYPE_ATAPI
           jne  short dpt_is_not_atapi1
           or   dx,((1<<5) | (1<<6)) ; removable, atapi device

dpt_is_not_atapi1:
           ; make ds:[si+EBDA_DATA->  = channel info
           mov  ax,dpt_device
           shr  ax,1
           imul si,ax,ATA_CHANNEL_SIZE

           mov  ax,[si+EBDA_DATA->ata_0_iobase1]
           mov  [EBDA_DATA->dpte_iobase1],ax
           mov  ax,[si+EBDA_DATA->ata_0_iobase2]
           add  ax,ATA_CB_DC
           mov  [EBDA_DATA->dpte_iobase2],ax
           mov  ax,dpt_device
           and  al,1
           shl  al,4
           or   al,0xE0
           mov  [EBDA_DATA->dpte_prefix],al
           mov  byte [EBDA_DATA->dpte_unused],0xCB
           mov  al,[si+EBDA_DATA->ata_0_irq]
           mov  [EBDA_DATA->dpte_irq],al
           mov  byte [EBDA_DATA->dpte_blkcount],0x01
           mov  byte [EBDA_DATA->dpte_dma],0x00
           mov  byte [EBDA_DATA->dpte_pio],0x00
           mov  [EBDA_DATA->dpte_options],dx
           mov  word [EBDA_DATA->dpte_reserved],0x0000
           mov  byte [EBDA_DATA->dpte_revision],0x11

           ; calculate the crc of the dpte
           xor  al,al
           mov  cx,15
           mov  si,EBDA_DATA->dpte_iobase1
@@:        add  al,[si]
           inc  si
           loop @b
           not  al
           mov  [EBDA_DATA->dpte_checksum],al
           
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; see if size is at least 66 (EDD 3.x)
           cmp  word dpt_req_sz,66
           jb   int13_edd_success
           
           ; if the requested 66 bytes, then do t13
           ; else do phoenix device path length
           mov  byte dpt_len_flag,0
           cmp  word dpt_req_sz,74
           jb   short @f
           mov  byte dpt_len_flag,1

@@:        ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; size is at least 66, so do EDD 3.x
           mov  word es:[di+INT13_DPT->dpt_size],66
           
           ; make ds:[si+EBDA_DATA->  = channel info
           mov  ax,dpt_device
           shr  ax,1
           imul si,ax,ATA_CHANNEL_SIZE

           xor  ah,ah
           mov  al,[si+EBDA_DATA->ata_0_iface]
           mov  dpt_iface,ax
           
           mov  word es:[di+INT13_DPT->dpt_key],0xBEDD
           mov  word es:[di+INT13_DPT->dpt_dpi_length],36
           cmp  byte dpt_len_flag,0
           je   short @f
           mov  word es:[di+INT13_DPT->dpt_dpi_length],44
@@:        mov  byte es:[di+INT13_DPT->dpt_reserved1],0
           mov  word es:[di+INT13_DPT->dpt_reserved2],0

           cmp  word dpt_iface,ATA_IFACE_ISA
           jne  short @f
           mov  byte es:[di+INT13_DPT->dpt_host_bus+0],'I'
           mov  byte es:[di+INT13_DPT->dpt_host_bus+1],'S'
           mov  byte es:[di+INT13_DPT->dpt_host_bus+2],'A'
           mov  byte es:[di+INT13_DPT->dpt_host_bus+3],' '
           mov  ax,[si+EBDA_DATA->ata_0_iobase1]
           mov  es:[di+INT13_DPT->dpt_iface_path+0],ax
           mov  word es:[di+INT13_DPT->dpt_iface_path+2],0x0000
           mov  dword es:[di+INT13_DPT->dpt_iface_path+4],0x00000000
           ; todo: else is PCI (two places)

           ; fill in the iface type with 'ATA     ' or 'ATAPI   '
@@:        cmp  word dpt_type,ATA_TYPE_ATA
           jne  short @f
           mov  byte es:[di+INT13_DPT->dpt_iface_type+0],'A'
           mov  byte es:[di+INT13_DPT->dpt_iface_type+1],'T'
           mov  byte es:[di+INT13_DPT->dpt_iface_type+2],'A'
           mov  byte es:[di+INT13_DPT->dpt_iface_type+3],' '
           mov  byte es:[di+INT13_DPT->dpt_iface_type+4],' '
           mov  byte es:[di+INT13_DPT->dpt_iface_type+5],' '
           mov  byte es:[di+INT13_DPT->dpt_iface_type+6],' '
           mov  byte es:[di+INT13_DPT->dpt_iface_type+7],' '
           jmp  short dpt_next_0
@@:        cmp  word dpt_type,ATA_TYPE_ATAPI
           jne  short dpt_next_0
           mov  byte es:[di+INT13_DPT->dpt_iface_type+0],'A'
           mov  byte es:[di+INT13_DPT->dpt_iface_type+1],'T'
           mov  byte es:[di+INT13_DPT->dpt_iface_type+2],'A'
           mov  byte es:[di+INT13_DPT->dpt_iface_type+3],'P'
           mov  byte es:[di+INT13_DPT->dpt_iface_type+4],'I'
           mov  byte es:[di+INT13_DPT->dpt_iface_type+5],' '
           mov  byte es:[di+INT13_DPT->dpt_iface_type+6],' '
           mov  byte es:[di+INT13_DPT->dpt_iface_type+7],' '

dpt_next_0:
           mov  ax,dpt_device
           and  al,1
           mov  es:[di+INT13_DPT->dpt_device_path+0],al
           mov  byte es:[di+INT13_DPT->dpt_device_path+1],0x00
           mov  word es:[di+INT13_DPT->dpt_device_path+2],0x0000
           mov  dword es:[di+INT13_DPT->dpt_device_path+4],0x00000000

           ; from here on, dpt_device_path can be 16 bytes long instead of 8
           ; (we don't need bx anymore)
           ; we set bx = 0 if it is 8 bytes long
           xor  bx,bx
           mov  cx,36            ; length used below
           cmp  byte dpt_len_flag,0
           je   short @f
           mov  bx,8  ; or set it to 8 as an offset
           mov  cx,43            ; length used below
           mov  dword es:[di+INT13_DPT->dpt_device_path+8],0x00000000
           mov  dword es:[di+INT13_DPT->dpt_device_path+12],0x00000000
           
           ; everything from here on, that addresses past 'dpt_device_path' needs the bx offset
@@:        mov  byte es:[bx+di+INT13_DPT->dpt_reserved3],0x00
           
           ; calculate the crc of the dpt
           xor  al,al
           lea  si,[di+INT13_DPT->dpt_key]
@@:        add  al,es:[si]
           inc  si
           loop @b
           not  al
           mov  es:[bx+di+INT13_DPT->dpt_checksum],al
           
           ; successful return
int13_edd_success:
           pop  eax
           xor  ax,ax
           mov  sp,bp
           pop  bp
           ret

           ; there was an error (return !0)
int13_edd_error:
           pop  eax
           mov  ax,1
           mov  sp,bp
           pop  bp
           ret
int13_edd  endp

.end
