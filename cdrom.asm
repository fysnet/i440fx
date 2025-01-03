comment |*******************************************************************
*  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: cdrom.asm                                                          *
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
*   cdrom include file                                                     *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.14                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 3 Jan 2025                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

ATAPI_CMD_TEST_READY              equ  0x00
ATAPI_CMD_REQUEST_SENSE           equ  0x03
ATAPI_CMD_FORMAT_UNIT             equ  0x04
ATAPI_CMD_INQUIRY                 equ  0x12
ATAPI_CMD_START_STOP              equ  0x1B
ATAPI_CMD_LOCK_UNLOCK             equ  0x1E
ATAPI_CMD_READ_FORMAT_CAPACITIES  equ  0x23
ATAPI_CMD_READ_CAPACITY           equ  0x25
ATAPI_CMD_READ_10                 equ  0x28
ATAPI_CMD_WRITE_10                equ  0x2A
ATAPI_CMD_SEEK                    equ  0x2B
ATAPI_CMD_WRITE_AND_VERIFY_10     equ  0x2E
ATAPI_CMD_VERIFY_10               equ  0x2F
ATAPI_CMD_FLUSH_CACHE             equ  0x35
ATAPI_CMD_READ_SUB_CHANNEL        equ  0x42
ATAPI_CMD_READ_TOC                equ  0x43
ATAPI_CMD_READ_HEADER             equ  0x44
ATAPI_CMD_PLAY_AUDIO              equ  0x45
ATAPI_CMD_GET_CONFIGURATION       equ  0x46
ATAPI_CMD_PLAY_AUDIO_MSF          equ  0x47
ATAPI_CMD_PLAY_AUDIO_TI           equ  0x48
ATAPI_CMD_GET_EVENT_STATUS_NOTIFICATION equ  0x4A
ATAPI_CMD_PAUSE_RESUME            equ  0x4B
ATAPI_CMD_STOP_PLAY_SCAN          equ  0x4E
ATAPI_CMD_READ_DISC_INFO          equ  0x51
ATAPI_CMD_READ_TRACK_RZONE_INFO   equ  0x52
ATAPI_CMD_RESERVE_RZONE_TRACK     equ  0x53
ATAPI_CMD_SEND_OPC                equ  0x54
ATAPI_CMD_MODE_SELECT             equ  0x55
ATAPI_CMD_REPAIR_RZONE_TRACK      equ  0x58
ATAPI_CMD_MODE_SENSE              equ  0x5A
ATAPI_CMD_CLOSE_TRACK             equ  0x5B
ATAPI_CMD_BLANK                   equ  0xA1
ATAPI_CMD_SEND_EVENT              equ  0xA2
ATAPI_CMD_SEND_KEY                equ  0xA3
ATAPI_CMD_REPORT_KEY              equ  0xA4
ATAPI_CMD_LOAD_UNLOAD             equ  0xA6
ATAPI_CMD_SET_READ_AHEAD          equ  0xA7
ATAPI_CMD_READ_12                 equ  0xA8
ATAPI_CMD_WRITE_12                equ  0xAA
ATAPI_CMD_READ_SERIAL_NUM         equ  0xAB
ATAPI_CMD_GET_PERFORMANCE         equ  0xAC
ATAPI_CMD_READ_DVD_STRUCTURE      equ  0xAD
ATAPI_CMD_SET_STREAMING           equ  0xB6
ATAPI_CMD_READ_CD_MSF             equ  0xB9
ATAPI_CMD_SCAN                    equ  0xBA
ATAPI_CMD_SET_SPEED               equ  0xBB
ATAPI_CMD_PLAY_CD                 equ  0xBC
ATAPI_CMD_MECH_STATUS             equ  0xBD
ATAPI_CMD_READ_CD                 equ  0xBE

cdrom_isotag     db  'CD001'
cdrom_eltorito   db  'EL TORITO SPECIFICATION'

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; CD-ROM disc El Torito: initialize
; on entry:
;  es = 0x0000
; on return
;  nothing
; destroys nothing
cdemu_init proc near uses ax es
           call bios_get_ebda
           mov  es,ax
           mov  byte es:[EBDA_DATA->cdemu_active],0x00
           ret
cdemu_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; CD-ROM disc El Torito: is emulation active
; on entry:
;  es = segment of EBDA
; on return
;  ax = zero = not active, else is active
; destroys nothing
cdrom_emu_active proc near
           xor  ah,ah
           mov  al,es:[EBDA_DATA->cdemu_active]
           ret
cdrom_emu_active endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; CD-ROM disc El Torito: return the drive number that is being emulated
; on entry:
;  es = segment of EBDA
; on return
;  ax = drive number being emulated
; destroys nothing
cdrom_emu_drive proc near
           xor  ah,ah
           mov  al,es:[EBDA_DATA->cdemu_emulated_drive]
           ret
cdrom_emu_drive endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; load CD-ROM boot sector
; on entry:
;  es = segment of EBDA
;  dl = device
; on return
;  al = status = 0 = successful
;  ah = drive number to return (0x81, 0xE0, etc.)
; destroys nothing
boot_cdrom_funtion proc near uses bx cx dx si di ds
           push bp
           mov  bp,sp
           sub  sp,0x810

cdrom_buffer     equ  [bp-0x800]  ; cdrom_buffer[2048]
cdrom_atapi_cmd  equ  [bp-0x80C]  ; cdrom_atapi_cmd[12]
cdrom_device     equ  [bp-0x80E]  ; word
cdrom_segment    equ  [bp-0x810]  ; word

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; find the first cdrom
           xor  cx,cx
@@:        mov  ax,cx
           call atapi_is_cdrom
           or   ax,ax
           jnz  short @f
           inc  cx
           cmp  cx,BX_MAX_ATA_DEVICES
           jb   short @b

           ; error, didn't find a cdrom
           mov  ax,0x0002
           jmp  cdrom_boot_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; store the device index
@@:        mov  ax,cx            ; ax = device index
           mov  cdrom_device,ax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; see if it is ready
           call atapi_is_ready
           or   al,al
           jz   short @f
           ; error, cdrom not ready
           mov  ax,0x0002
           jmp  cdrom_boot_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read the Boot Record Volume Descriptor
@@:        push ss
           pop  ds
           lea  bx,cdrom_atapi_cmd
           mov  byte [bx+00],ATAPI_CMD_READ_10
           mov  byte [bx+01],0x00
           mov  byte [bx+02],((0x11 & 0xFF000000) >> 24)  ; LBA
           mov  byte [bx+03],((0x11 & 0x00FF0000) >> 16)
           mov  byte [bx+04],((0x11 & 0x0000FF00) >>  8)
           mov  byte [bx+05],((0x11 & 0x000000FF) >>  0)
           mov  byte [bx+06],0x00
           mov  byte [bx+07],((0x01 & 0xFF00) >> 8) ; count
           mov  byte [bx+08],((0x01 & 0x00FF) >> 0)
           mov  byte [bx+09],0x00
           mov  word [bx+10],0x0000
           lea  bx,cdrom_buffer
           push bx
           push ss
           push ATA_DATA_IN
           pushd 2048
           push 0
           lea  ax,cdrom_atapi_cmd
           push ax
           push ss
           push 12
           push word cdrom_device
           call atapi_cmd_packet
           add  sp,20
           or   ax,ax
           jz   short @f
           mov  ax,3
           jmp  cdrom_boot_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check for valid items
@@:        cmp  byte [bx+0],0x00
           je   short @f
           mov  ax,0x0004
           jmp  cdrom_boot_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; string at [bx+1] should be 'CD001'
@@:        push 5
           push cs
           push offset cdrom_isotag
           push ss
           lea  ax,[bx+1]
           push ax
           call strncmp
           add  sp,10
           or   ax,ax
           jz   short @f
           mov  ax,5
           jmp  cdrom_boot_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; string at [bx+7] should be 'EL TORITO SPECIFICATION'
@@:        push 23
           push cs
           push offset cdrom_eltorito
           push ss
           lea  ax,[bx+7]
           push ax
           call strncmp
           add  sp,10
           or   ax,ax
           jz   short @f
           mov  ax,6
           jmp  cdrom_boot_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Get the Boot Catalog address
@@:        mov  eax,[bx+0x0047]  ; LBA
           lea  bx,cdrom_atapi_cmd
           mov  byte [bx+00],ATAPI_CMD_READ_10
           mov  byte [bx+01],0x00
           rol  eax,8            ; LBA
           mov  [bx+02],al       ;  (high byte)
           rol  eax,8            ;
           mov  [bx+03],al       ;
           rol  eax,8            ;
           mov  [bx+04],al       ;
           rol  eax,8            ;
           mov  [bx+05],al       ;  (low byte)
           mov  byte [bx+06],0x00
           mov  byte [bx+07],((0x01 & 0xFF00) >> 8) ; count
           mov  byte [bx+08],((0x01 & 0x00FF) >> 0)
           mov  byte [bx+09],0x00
           mov  word [bx+10],0x0000
           lea  bx,cdrom_buffer
           push bx
           push ss
           push ATA_DATA_IN
           pushd 2048
           push 0
           lea  ax,cdrom_atapi_cmd
           push ax
           push ss
           push 12
           push word cdrom_device
           call atapi_cmd_packet
           add  sp,20
           or   ax,ax
           jz   short @f
           mov  ax,7
           jmp  cdrom_boot_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check the validation entry
; 0000A000  01 00 00 00 4D 69 63 72-6F 73 6F 66 74 20 43 6F     ....Microsoft.Co
; 0000A010  72 70 6F 72 61 74 69 6F-6E 00 00 00 4C 49 55 AA     rporation...LIU.
           ;  offset  size  value       description
           ;   0x00     1   0x01         Header ID (must be 1)
           ;   0x01     1   0,1,2,0xEF   Platform (0 = 80x86)
           ;   0x02     2   0x0000       reserved
           ;   0x04    24   varies       Manufacturer ID
           ;   0x1C     2   crc          two-byte crc of this entry (zero sum)
           ;   0x1E     2   sig          0x55 0xAA
@@:        cmp  byte [bx+0x00],0x01 ; 1 = Header ID
           je   short @f
           mov  ax,8
           jmp  cdrom_boot_done

@@:        cmp  byte [bx+0x01],0x00 ; 0 = platform = 80x86
           je   short @f
           mov  ax,9
           jmp  cdrom_boot_done
           
@@:        cmp  word [bx+0x1E],0xAA55 ; 0x55 0xAA
           je   short @f
           mov  ax,10
           jmp  cdrom_boot_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we are at the first entry
           ; (should be the initial/default entry)
; 0000A020  88 02 00 00 00 00 01 00-15 00 00 00 00 00 00 00     ................
; 0000A030  00 00 00 00 00 00 00 00-00 00 00 00 00 00 00 00     ................
           ;  offset  size  value       description
           ;   0x00     1   0x00,0x88    0 = not bootable, 0x88 = bootable
           ;   0x01     1   0,1,2,3      media type (0=non emulation, 1 = 1_20 floppy, 2 = 1_44 floppy, 3 = 2_88, 4 = hard drive
           ;   0x02     2   varies       Load segment of image (0 = 0x07C0)
           ;   0x04     1   varies       Partition Entry type (from MBR)
           ;   0x05     1   0x00         reserved
           ;   0x06     2   varies       Count of (512-byte) sectors to load
           ;   0x08     4   lba          (2048-byte) lba to start loading
           ;   0x0C    20   zeros        reserved
@@:        add  bx,0x20  ; size of entry
           cmp  byte [bx+0x00],0x88 ; 0x88 = Bootable
           je   short @f
           
           ; todo: go to the next entry.
           ;  the one after the initial will have 0x90 as the header id if there are
           ;   more entries to follow, else 0x91 means last entry.
           ;  a lot of CD-ROMs have a zero at the 2nd entry with nothing following.
           ;  (i.e.: they only have the Initial entry abov)

           mov  ax,11
           jmp  cdrom_boot_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; save some information to the EBDA
@@:        mov  al,[bx+0x01]     ; media type
           mov  es:[EBDA_DATA->cdemu_media],al
           ; if media type = no emulation, we have to set drive to 0xE0 (a Win2k 'bug' ?)
           ; todo: if more than 1 cdrom is used, this should be 0xE0, 0xE1, etc. ????
           mov  ah,0xE0          ; assume no emulation
           cmp  al,0x00          ; 0 = no emu
           je   short @f         ;
           mov  ah,0x00          ; assume floppy
           cmp  al,4             ; 1,2,3 = floppy
           jb   short @f         ;
           mov  ah,0x80          ; 4 = hard drive
@@:        mov  es:[EBDA_DATA->cdemu_emulated_drive],ah
           mov  ax,cdrom_device
           shr  ax,1
           mov  es:[EBDA_DATA->cdemu_controller_index],al
           mov  ax,cdrom_device
           and  al,1
           mov  es:[EBDA_DATA->cdemu_device_spec],al
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; boot segment value, lba, count, etc
           mov  dx,0x07C0
           cmp  word [bx+0x02],0x0000
           je   short @f
           mov  dx,[bx+0x02]     ; save in dx for later
@@:        mov  es:[EBDA_DATA->cdemu_load_segment],dx
           mov  word es:[EBDA_DATA->cdemu_buffer_offset],0x0000
           movzx ecx,word [bx+06] ; count of 512-byte sectors
           mov  es:[EBDA_DATA->cdemu_sector_count],cx
           mov  eax,[bx+0x08]    ; 2048-byte lba
           mov  es:[EBDA_DATA->cdemu_ilba],eax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read the sector(s) into memory
           lea  bx,cdrom_atapi_cmd
           mov  byte [bx+00],ATAPI_CMD_READ_10
           mov  byte [bx+01],0x00
           rol  eax,8            ; LBA
           mov  [bx+02],al       ;  (high byte)
           rol  eax,8            ;
           mov  [bx+03],al       ;
           rol  eax,8            ;
           mov  [bx+04],al       ;
           rol  eax,8            ;
           mov  [bx+05],al       ;  (low byte)
           mov  byte [bx+06],0x00
           push cx               ; save count of sectors
           dec  cx               ; count of 2048-byte sectors =
           shr  cx,2             ;  ((512-byte sectors - 1) / 4) + 1
           inc  cx               ;
           ror  cx,8             ; count
           mov  [bx+07],cl       ;  (high byte)
           ror  cx,8             ;
           mov  [bx+08],cl       ;  (low byte)
           pop  cx               ; restore count of sectors
           mov  byte [bx+09],0x00
           mov  word [bx+10],0x0000
           push 0x0000
           push dx
           push ATA_DATA_IN
           shl  ecx,9            ; 512-byte sectors to bytes
           push ecx
           push 0
           lea  ax,cdrom_atapi_cmd
           push ax
           push ss
           push 12
           push word cdrom_device
           call atapi_cmd_packet
           add  sp,20
           or   ax,ax
           jz   short @f
           mov  ax,12
           jmp  cdrom_boot_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; save the media type
@@:        mov  al,es:[EBDA_DATA->cdemu_media]
           cmp  al,0x01  ; 1.2M floppy
           jne  short @f
           mov  word es:[EBDA_DATA->cdemu_vchs_spt],15
           mov  word es:[EBDA_DATA->cdemu_vchs_cyl],80
           mov  word es:[EBDA_DATA->cdemu_vchs_heads],2
           jmp  short cdrom_boot_done_emu
@@:        cmp  al,0x02  ; 1.44M floppy
           jne  short @f
           mov  word es:[EBDA_DATA->cdemu_vchs_spt],18
           mov  word es:[EBDA_DATA->cdemu_vchs_cyl],80
           mov  word es:[EBDA_DATA->cdemu_vchs_heads],2
           jmp  short cdrom_boot_done_emu
@@:        cmp  al,0x03  ; 2.88M floppy
           jne  short @f
           mov  word es:[EBDA_DATA->cdemu_vchs_spt],36
           mov  word es:[EBDA_DATA->cdemu_vchs_cyl],80
           mov  word es:[EBDA_DATA->cdemu_vchs_heads],2
           jmp  short cdrom_boot_done_emu
@@:        cmp  al,0x04  ; hard drive
           jne  short cdrom_boot_done_emu
           
           ;;;;;;;;;;;;;;;
           ; todo: ******
           ; this assumes the loaded data is a MBR with a valid partition table,
           ;  *and* the first entry is the booted entry
           push ds
           mov  ax,es:[EBDA_DATA->cdemu_load_segment]
           mov  ds,ax
           mov  si,es:[EBDA_DATA->cdemu_buffer_offset]
           xor  ah,ah
           mov  al,[si+(446+6)]
           push ax
           and  al,0x3F
           mov  es:[EBDA_DATA->cdemu_vchs_spt],ax
           pop  ax
           shl  ax,2
           mov  al,[si+(446+7)]
           inc  ax
           mov  es:[EBDA_DATA->cdemu_vchs_cyl],ax
           xor  ah,ah
           mov  al,[si+(446+5)]
           inc  ax
           mov  es:[EBDA_DATA->cdemu_vchs_heads],ax
           pop  ds
           ;;;;; end of todo:

cdrom_boot_done_emu:
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Increase bios installed hardware number of devices?
           cmp  byte es:[EBDA_DATA->cdemu_media],0
           je   short cdrom_boot_done_1
           
           ; increment the count of drives installed
           cmp  byte es:[EBDA_DATA->cdemu_emulated_drive],0
           jne  short @f

           ; increment the count of floppy drives installed
           push ds
           xor  ax,ax
           mov  ds,ax
           or   byte [0x0410],0x41
           pop  ds
           jmp  short cdrom_boot_done_0
           
           ; increment the count of hard drives installed
@@:        inc  byte es:[EBDA_DATA->ata_hdcount]
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if there was an emulation specified, it should now be active
cdrom_boot_done_0:
           mov  byte es:[EBDA_DATA->cdemu_active],0x01

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set return value to ah = drive, al = 0 = no error
cdrom_boot_done_1:
           mov  ah,es:[EBDA_DATA->cdemu_emulated_drive]
           xor  al,al            ; no error

cdrom_boot_done:
           mov  sp,bp            ; restore the stack
           pop  bp
           ret
boot_cdrom_funtion endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; CD-ROM disc El Torito services
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
int13_eltorito_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           ; sub  sp,4

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; ds -> BIOS Data Area
           mov  ax,0x0040
           mov  ds,ax

           ; service call
           mov  ax,REG_AX

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; terminate disk emu / get status
           ; ds:si-> points to packet
           ; dl = drive or 0x7F to terminate all
           cmp  ax,0x4B00
           je   short int13_eltorito_4B
           cmp  ax,0x4B01
           jne  short @f

int13_eltorito_4B:
           ; todo: for now we hard code this. This really needs to be worked on 
           ; if DL != 0xE0, should we return carry and *not* fill the packet????
           cmp  byte REG_DL,0xE0
           jne  short int13_eltorito_fail
           
           push ds
           mov  ax,REG_DS
           mov  ds,ax
           mov  bx,REG_SI
           mov  al,0x13
           mov  [bx+0x00],al
           mov  al,es:[EBDA_DATA->cdemu_media]
           mov  [bx+0x01],al
           mov  al,es:[EBDA_DATA->cdemu_emulated_drive]
           mov  [bx+0x02],al
           mov  al,es:[EBDA_DATA->cdemu_controller_index]
           mov  [bx+0x03],al
           mov  eax,es:[EBDA_DATA->cdemu_ilba]
           mov  [bx+0x04],eax
           mov  ax,es:[EBDA_DATA->cdemu_device_spec]
           mov  [bx+0x08],ax
           mov  ax,es:[EBDA_DATA->cdemu_buffer_offset]
           mov  [bx+0x0A],ax
           mov  ax,es:[EBDA_DATA->cdemu_load_segment]
           mov  [bx+0x0C],ax
           mov  ax,es:[EBDA_DATA->cdemu_sector_count]
           mov  [bx+0x0E],ax
           mov  ax,es:[EBDA_DATA->cdemu_vchs_cyl]
           mov  [bx+0x10],al
           mov  al,es:[EBDA_DATA->cdemu_vchs_spt]
           and  al,0x3F
           shl  ah,6
           or   al,ah
           mov  [bx+0x11],al
           mov  ax,es:[EBDA_DATA->cdemu_vchs_heads]
           mov  [bx+0x12],al
           pop  ds

           cmp  byte REG_AL,0x00
           jne  short int13_eltorito_success
           mov  byte es:[EBDA_DATA->cdemu_active],0x00
           jmp  short int13_eltorito_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        ;cmp  ah,0x  ; next value
           ;jne  short @f
           ;
           ;
           ;jmp  short int13_eltorito_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown function found

           xchg cx,cx  ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

           jmp  short int13_eltorito_fail

int13_eltorito_fail:
           mov  byte REG_AH,0x01  ; default to invalid function in AH or invalid parameter
int13_eltorito_fail_noah:
           mov  ah,REG_AH
           mov  [0x0074],ah
int13_eltorito_fail_nostatus:
           or   word REG_FLAGS,0x0001
           mov  sp,bp
           pop  bp
           ret

int13_eltorito_success:
           mov  byte REG_AH,0x00  ; no error
int13_eltorito_success_noah:
           mov  byte [0x0074],0x00
           and  word REG_FLAGS,(~0x0001)
           mov  sp,bp
           pop  bp
           ret
int13_eltorito_function endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; CD-ROM disc El Torito services: Emulation function
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
cdrom_emu_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           sub  sp,0x0E

cdemu_emu_device     equ  [bp-0x02]
cdrom_emu_atapi_cmd  equ  [bp-0x0E]  ; cdrom_emu_atapi_cmd[12]
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; ds -> BIOS Data Area
           mov  ax,0x0040
           mov  ds,ax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; at this point, we are emulating a floppy or hardisk
           ;  from a CD-ROM
           xor  ah,ah
           mov  al,es:[EBDA_DATA->cdemu_controller_index]
           shl  al,1
           add  al,es:[EBDA_DATA->cdemu_device_spec]
           mov  cdemu_emu_device,ax
           imul bx,ax,ATA_DEVICE_SIZE
           
           ; clear the BDA status byte
           mov  byte [0x0074],0x00

           ; service call
           mov  ah,REG_AH
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; these functions simply return success
           cmp  ah,0x00          ; disk controller reset
           je   cdrom_emu_success
           cmp  ah,0x09          ; initialize drive parameters
           je   cdrom_emu_success
           cmp  ah,0x0C          ; seek to specified cylinder
           je   cdrom_emu_success
           cmp  ah,0x0D          ; alternate disk reset  // FIXME: should really reset ?
           je   cdrom_emu_success
           cmp  ah,0x10          ; check drive ready     // FIXME: should check if ready ?
           je   cdrom_emu_success
           cmp  ah,0x11          ; recalibrate
           je   cdrom_emu_success
           cmp  ah,0x14          ; controller internal diagnostic
           je   cdrom_emu_success
           cmp  ah,0x16          ; detect disk change
           je   cdrom_emu_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; these functions return disk write-protected
           mov  byte REG_AH,0x03
           cmp  ah,0x03          ; write disk sectors
           je   cdrom_emu_fail_noah
           cmp  ah,0x05          ; format disk track
           je   cdrom_emu_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disk status
           cmp  ah,0x01          ; read disk status
           jne  short @f
           mov  al,[0x0074]
           mov  REG_AH,al
           mov  byte [0x0074],0x00
           or   al,al
           jnz  cdrom_emu_fail_nostatus
           jmp  cdrom_emu_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read/verify disk sectors
@@:        cmp  ah,0x02          ; read disk sectors
           je   short cdrom_emu_transfer
           cmp  ah,0x04          ; verify disk sectors
           jne  @f
cdrom_emu_transfer:
           ; if sectors = 0, no need to continue
           mov  al,REG_AL
           or   al,al
           je   cdrom_emu_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if (sector > emulated spt) or (cylinder >= emulated cyls)
           ; or (head > emulated heads), then error
           mov  ax es:[EBDA_DATA->cdemu_vchs_spt]
           mov  cl,REG_CL
           and  cx,0x3F
           cmp  cx,ax
           ja   cdrom_emu_fail
           mov  ax,es:[EBDA_DATA->cdemu_vchs_cyl]
           mov  cl,REG_CL
           shl  cx,2        ; ch = 0 from above
           mov  cl,REG_CH
           cmp  cx,ax
           jae  cdrom_emu_fail
           mov  ax,es:[EBDA_DATA->cdemu_vchs_heads]
           xor  ch,ch
           mov  cl,REG_DH
           cmp  cx,ax
           jae  cdrom_emu_fail

           ; now that we verified good parameters,
           ;  if verify call, simply return good
           cmp  byte REG_AH,0x04
           je   cdrom_emu_success

           ; calculate the virtual lba inside the emulated image
           ; vlba = (((cylinder * vheads) + head) * vspt) + sector - 1;
           movzx eax,byte REG_CL
           shl  ax,2
           mov  al,REG_CH
           movzx ebx,word es:[EBDA_DATA->cdemu_vchs_heads]
           mul  ebx
           movzx ebx,byte REG_DH
           add  eax,ebx
           movzx ebx,word es:[EBDA_DATA->cdemu_vchs_spt]
           mul  ebx
           movzx ebx,byte REG_CL
           and  bl,0x3F
           add  eax,ebx
           dec  eax
           
           ; eax = virtual (512-byte) lba in emulated image
           xor  edx,edx          ;
           mov  ebx,eax          ; save in ebx
           shr  eax,2            ; eax = starting physical lba on (2048-byte) cd-rom
           mov  cx,bx            ;
           and  cx,0x03          ; cx = count of (512-byte) sectors before wanted sector
           shl  cx,9             ;  (convert to bytes)
           mov  dl,REG_AL        ;
           add  ebx,edx          ;
           dec  ebx              ;
           shr  ebx,2            ; ebx = ending (2048-byte) lba on cd-rom
           mov  edx,ebx          ;
           sub  edx,eax          ;
           inc  dx               ; dx = count of (2048-byte) sectors to read

           ; add the base of the emulated image
           add  eax,es:[EBDA_DATA->cdemu_ilba]
           
           lea  si,cdrom_emu_atapi_cmd
           mov  byte ss:[si+00],ATAPI_CMD_READ_10
           mov  byte ss:[si+01],0x00
           rol  eax,8            ; LBA
           mov  ss:[si+02],al    ;  (high byte)
           rol  eax,8            ;
           mov  ss:[si+03],al    ;
           rol  eax,8            ;
           mov  ss:[si+04],al    ;
           rol  eax,8            ;
           mov  ss:[si+05],al    ;  (low byte)
           mov  byte ss:[si+06],0x00
           mov  ss:[si+07],dh    ; Count (high byte)
           mov  ss:[si+08],dl    ;       (low byte)
           mov  byte ss:[si+09],0x00
           mov  word ss:[si+10],0x0000
           
           ; 'normalize' the address
           mov  bx,REG_BX
           shr  bx,4
           mov  ax,REG_ES
           add  ax,bx
           mov  bx,REG_BX
           and  bx,0x000F
           
           push bx               ; offset
           push ax               ; segment
           push ATA_DATA_IN      ; read
           movzx eax,byte REG_AL ;
           shl  eax,9            ; number of bytes wanted
           push eax              ;
           push cx               ; count before
           push si               ; offset command block
           push ss               ; segment command block
           push 12               ; size in byte of command block
           push word cdemu_emu_device
           call atapi_cmd_packet
           add  sp,20
           or   ax,ax
           jz   cdrom_emu_success
           mov  word REG_AX,0x0200
           jmp  short cdrom_emu_fail_noah
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disk drive parameters
@@:        cmp  ah,0x08
           jne  short @f

           mov  ax,es:[EBDA_DATA->cdemu_vchs_cyl]
           dec  ax
           mov  bx,es:[EBDA_DATA->cdemu_vchs_spt]
           mov  cx,es:[EBDA_DATA->cdemu_vchs_heads]
           dec  cx
           mov  byte REG_AL,0x00
           mov  byte REG_BL,0x00
           mov  REG_CH,al
           shr  ax,2
           and  al,0xC0
           and  bl,0x3F
           or   al,bl
           mov  REG_CL,al
           mov  REG_DH,cl
           mov  byte REG_DL,0x02  ; todo: floppy: 1 or 2, hddrv = hdcount
           mov  ax,es:[EBDA_DATA->cdemu_media]
           shl  ax,1
           mov  REG_BL,al
           mov  ax,offset diskette_param_table
           mov  REG_DI,ax
           mov  REG_ES,cs
           jmp  short cdrom_emu_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disk drive type/size
@@:        cmp  ah,0x15
           jne  short @f
           mov  ah,0x02          ; assume a floppy with change-line support
           mov  al,es:[EBDA_DATA->cdemu_media]
           cmp  al,0x04
           jbe  short cdrom_emu_ah15_0
           mov  ah,0x03
cdrom_emu_ah15_0:
           ;
           ; todo: cx:dx ???? (most bios' don't set it anyway)
           ;
           mov  REG_AH,ah
           jmp  short cdrom_emu_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        ;cmp  ah,0x  ; next value
           ;jne  short @f
           ;
           ;
           ;jmp  short cdrom_emu_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; print a message of this unknown call value
@@:        push ds
           push cs
           pop  ds
           shr  ax,8
           push ax
           mov  si,offset cdrom_emu_unknown_call_str
           call bios_printf
           add  sp,2
           pop  ds
           jmp  short cdrom_emu_fail

cdrom_emu_fail:
           mov  byte REG_AH,0x01  ; default to invalid function in AH or invalid parameter
cdrom_emu_fail_noah:
           mov  ah,REG_AH
           mov  [0x0074],ah
cdrom_emu_fail_nostatus:
           or   word REG_FLAGS,0x0001
           jmp  short cdrom_emu_function_done

cdrom_emu_success:
           mov  byte REG_AH,0x00  ; no error
cdrom_emu_success_noah:
           mov  byte [0x0074],0x00
           and  word REG_FLAGS,(~0x0001)

cdrom_emu_function_done:
           mov  sp,bp
           pop  bp
           ret
cdrom_emu_function endp

cdrom_emu_unknown_call_str  db 'cdrom_emu: Unknown call 0x%02X',13,10,0
cdrom_rdy_size_str          db '%iMB medium detected',13,10,0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; CD-ROM disc services
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
int13_cdrom_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           sub  sp,0x0E

cd_sv_device    equ  [bp-0x02]
cd_atapi_cmd    equ  [bp-0x0E]  ; cd_atapi_cmd[12]
           
           ; get the device
           movzx bx,byte REG_DL
           cmp  bl,0xE0
           jb   cd_int13_fail
           cmp  bl,(0xE0 + BX_MAX_ATA_DEVICES)
           jae  cd_int13_fail
           
           ; else, valid DL number
           sub  bx,0xE0
           mov  al,es:[bx+EBDA_DATA->ata_0_0_cdidmap]
           cmp  al,BX_MAX_ATA_DEVICES
           jae  cd_int13_fail

           xor  ah,ah
           mov  cd_sv_device,ax
           imul bx,ax,ATA_DEVICE_SIZE
           
           mov  ah,REG_AH
           ; cd_sv_device = device
           ; es = segment of EBDA
           ; ah = service
           ; bx ->EBDA_DATA->device

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; todo: the following currently return success 
           ;  (some of them we can call the int13_harddisk_function equivalent)
           ;  (if we restore sp and pop bp, we can 'jmp' to the function)
           ;      mov  sp,bp
           ;      pop  bp
           ;      jmp  int13_harddisk_function
           ;
           ; controller reset
           cmp  ah,0x00
           je   cd_int13_success
           ; initialize drive parameters
           cmp  ah,0x09
           je   cd_int13_success
           ; seek to specified cylinder
           cmp  ah,0x0C
           je   cd_int13_success
           ; alternate disk reset
           cmp  ah,0x0D
           je   cd_int13_success
           ; check drive ready
           cmp  ah,0x10
           je   cd_int13_success
           ; recalibrate
           cmp  ah,0x11
           je   cd_int13_success
           ; internal diagnostic
           cmp  ah,0x14
           je   cd_int13_success
           ; detect disc change
           cmp  ah,0x16
           je   cd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; these return disc write protected
           mov  byte REG_AH,03
           ; write disc sectors
           cmp  ah,0x03
           je   cd_int13_fail_noah
           ; format disc track
           cmp  ah,0x05
           je   cd_int13_fail_noah
           ; extended write
           cmp  ah,0x43
           je   cd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; these return unimplemented
           ; read sectors
           cmp  ah,0x02
           je   cd_int13_fail
           ; verify sectors
           cmp  ah,0x04
           je   cd_int13_fail
           ; read disc drive parameters
           cmp  ah,0x08
           je   cd_int13_fail
           ; read disc sectors with ECC
           cmp  ah,0x0A
           je   cd_int13_fail
           ; write disc sectors with ECC
           cmp  ah,0x0B
           je   cd_int13_fail
           ; set media type for format
           cmp  ah,0x18
           je   cd_int13_fail
           ; send packet command (edd v3.0)
           cmp  ah,0x50
           je   cd_int13_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disc status
           cmp  ah,0x01
           jne  short @f
           mov  ah,es:[0x0074]
           mov  REG_AH,ah
           mov  byte es:[0x0074],0x00
           or   ah,ah
           jnz  cd_int13_fail_nostatus
           jmp  cd_int13_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disc drive size
@@:        cmp  ah,0x15
           jne  short @f
           mov  byte REG_AH,0x02
           jmp  cd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS Install check
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
           jmp  cd_int13_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS extended read/verify/seek
@@:        cmp  ah,0x42          ; extended read
           je   short cd_int13_ext_transfer
           cmp  ah,0x44          ; extended verify
           je   short cd_int13_ext_transfer
           cmp  ah,0x47          ; extended seek
           jne  @f
cd_int13_ext_transfer:
           push es
           mov  si,REG_SI
           mov  ax,REG_DS
           mov  es,ax
           mov  eax,es:[si+EXT_SERV_PACKET->ex_lba+0] ; get low 32-bits
           mov  edx,es:[si+EXT_SERV_PACKET->ex_lba+4] ; get high 32-bits
           mov  cx,es:[si+EXT_SERV_PACKET->ex_size]
           pop  es
           
           ; if size of packet < 16, error
           cmp  cx,16
           jb   cd_int13_fail
           ; if edx:eax >= EBDA_DATA->ata_0_0_sectors, error
           cmp  edx,es:[bx+EBDA_DATA->ata_0_0_sectors_high]
           ja   cd_int13_fail
           jb   short cd_int13_ext_transfer1
           cmp  eax,es:[bx+EBDA_DATA->ata_0_0_sectors_low]
           jae  cd_int13_fail
cd_int13_ext_transfer1:
           ; if we are verifying or seeking to sector(s), just return as good
           cmp  byte REG_AH,0x44
           je   cd_int13_success
           cmp  byte REG_AH,0x47
           je   cd_int13_success

           ; else do the transfer
           push ds
           mov  si,REG_SI
           mov  dx,REG_DS
           mov  ds,dx

.if INT13_FLAT_ADDR
           ; if seg:off == 0xFFFF:FFFF and ex_size >= 18, use the flat address
           mov  di,[si+EXT_SERV_PACKET->ex_offset]  ; offset of buffer
           mov  dx,[si+EXT_SERV_PACKET->ex_segment] ; segment of buffer
           cmp  byte [si+EXT_SERV_PACKET->ex_size],18
           jb   short cd_int13_flat_0
           cmp  dword [si+EXT_SERV_PACKET->ex_offset],0xFFFFFFFF
           jne  short cd_int13_flat_0
           mov  edi,[si+EXT_SERV_PACKET->ex_flataddr]
           mov  edx,edi
           shr  edx,4     ; dx = segment
           and  di,0x000F ; di = offset
           ; there is an error if high 16-bit of edx is non zero
           test edx,0xFFFF0000
           pop  ds
           jnz  cd_int13_fail
cd_int13_flat_0:
.endif
           ; edx:eax = lba (todo: we only do eax. edx must be zero)
           ; ecx = count of sectors to transfer
           mov  eax,[si+EXT_SERV_PACKET->ex_lba+0] ; get low 32-bits
          ;mov  edx,[si+EXT_SERV_PACKET->ex_lba+4] ; get high 32-bits
           movzx ecx,word [si+EXT_SERV_PACKET->ex_count]

           push ds
           push ss
           pop  ds
           lea  bx,cd_atapi_cmd
           mov  byte [bx+00],ATAPI_CMD_READ_10
           mov  byte [bx+01],0x00
.if DO_INIT_BIOS32
           bswap eax
.else
           call _bswap
.endif
           mov       [bx+02],eax  ; LBA
           mov  byte [bx+06],0x00
           mov       [bx+07],ch  ; count (high byte)
           mov       [bx+08],cl  ; count (low byte)
           mov  byte [bx+09],0x00
           mov  word [bx+10],0x0000
           pop  ds

.if INT13_FLAT_ADDR
           push di                                    ; offset of buffer
           push dx                                    ; segment of buffer
.else
           push word [si+EXT_SERV_PACKET->ex_offset]  ; offset of buffer
           push word [si+EXT_SERV_PACKET->ex_segment] ; segment of buffer
.endif
           push ATA_DATA_IN
           shl  ecx,11
           push ecx              ; count in bytes
           push 0
           lea  ax,cd_atapi_cmd
           push ax
           push ss
           push 12
           push word cd_sv_device
           call atapi_cmd_packet
           add  sp,20
           
           ; get count of sectors transferred
           mov  ecx,es:[EBDA_DATA->trsfbytes]
           shr  ecx,11           ; convert to sectors
           mov  [si+EXT_SERV_PACKET->ex_count],cx

           ; get the status (ax = status)
           or   ax,ax
           jz   cd_int13_success
           ; else there was an error
           mov  byte REG_AH,0x0C
           jmp  cd_int13_fail_noah
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS lock/unlock drive
@@:        cmp  ah,0x45
           jne  short @f
           cmp  byte REG_AL,2
           ja   cd_int13_fail

           mov  al,REG_AL
           ; sub function in AL
           cmp  al,0x02
           ja   cd_int13_fail

           cmp  al,0x00          ; lock it
           jne  short cd_int13_lock_0
           mov  word REG_AX,0xB401
           cmp  byte es:[bx+EBDA_DATA->ata_0_0_lock],0xFF
           je   cd_int13_fail_noah
           inc  byte es:[bx+EBDA_DATA->ata_0_0_lock]
           mov  byte REG_AL,1
           jmp  cd_int13_success

cd_int13_lock_0:
           cmp  al,0x01          ; unlock it
           jne  short cd_int13_lock_1
           mov  word REG_AX,0xB000
           cmp  byte es:[bx+EBDA_DATA->ata_0_0_lock],0x00
           je   cd_int13_fail_noah
           dec  byte es:[bx+EBDA_DATA->ata_0_0_lock]
           ; fall through
cd_int13_lock_1:
           ; return the lock status in AL
           mov  byte REG_AL,0
           cmp  byte es:[bx+EBDA_DATA->ata_0_0_lock],0
           je   cd_int13_success
           mov  byte REG_AL,1
           jmp  cd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS eject media
@@:        cmp  ah,0x46
           jne  short @f
           ; get the lock status
           mov  byte REG_AH,0xB1
           cmp  byte es:[bx+EBDA_DATA->ata_0_0_lock],0
           jne  short cd_int13_fail_noah

           ; call the services to do the eject
           mov  dl,REG_DL
           mov  ah,0x52
           int  15h
           mov  REG_AH,ah
           jc   short cd_int13_fail_noah
           jmp  short cd_int13_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS get drive parameters
@@:        cmp  ah,0x48
           jne  short @f
           push ds
           call bios_get_ebda
           mov  ds,ax
           push es
           mov  es,REG_DS
           mov  di,REG_SI
           mov  ax,cd_sv_device
           call int13_edd
           pop  es
           pop  ds
           or   ax,ax
           jnz  short cd_int13_fail
           jmp  short cd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS extended media change
@@:        cmp  ah,0x49
           jne  short @f
           ; todo:
           mov  byte REG_AH,6
           jmp  short cd_int13_fail_nostatus

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS set hardware configuration
@@:        cmp  ah,0x4E
           jne  short @f
           mov  al,REG_AL
           cmp  al,0x01          ; disable prefetch
           je   short cd_int13_success
           cmp  al,0x03          ; set pio mode 0
           je   short cd_int13_success
           cmp  al,0x04          ; set default pio transfer mode
           je   short cd_int13_success
           cmp  al,0x06          ; disable inter 13h dma
           je   short cd_int13_success
           jmp  short cd_int13_fail ; else, fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        ;cmp  ah,0x  ; next value
           ;jne  short @f
           ;
           ;
           ;jmp  cd_int13_success

           
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
cd_int13_fail:
           mov  byte REG_AH,0x01 ; invalid function or parameter
cd_int13_fail_noah:
           mov  al,REG_AH
           mov  es:[0x0074],al
cd_int13_fail_nostatus:
           or   word REG_FLAGS,0x0001
           jmp  short @f

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function was successful
cd_int13_success:
           mov  byte REG_AH,0x00 ; success
cd_int13_success_noah:
           mov  al,REG_AH
           mov  es:[0x0074],al
           and  word REG_FLAGS,(~0x0001)

@@:        pop  es
           mov  sp,bp
           pop  bp
           ret
int13_cdrom_function endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; is device a cdrom?
; on entry:
;  es = segment of EBDA
;  ax = device num
; on return
;  ax = 0 = no
; destroys nothing
atapi_is_cdrom proc near uses bx
           ; get the device entry
           imul bx,ax,ATA_DEVICE_SIZE
           
           ; if device > max devices, return 0
           cmp  ax,BX_MAX_ATA_DEVICES
           jnb  short @f
           
           cmp  byte es:[bx+EBDA_DATA->ata_0_0_type],ATA_TYPE_ATAPI
           jne  short @f

           cmp  byte es:[bx+EBDA_DATA->ata_0_0_device],ATA_DEVICE_CDROM
           jne  short @f

           mov  ax,0x0001
           ret

@@:        xor  ax,ax
           ret
atapi_is_cdrom endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get sense command
; on entry:
;  es = segment of EBDA
;  ax = device num
; on return
;  ax = 0 = success
;  bl = asc
;  bh = ascq
; destroys nothing
atapi_cmd_get_sense proc near uses di
           push bp
           mov  bp,sp
           sub  sp,0x16

cdrom_sns_device     equ  [bp-0x02]
cdrom_sns_atapi_cmd  equ  [bp-0x04]  ; cdrom_rdy_atapi_cmd[12]
cdrom_sns_atapi_buf  equ  [bp-0x16]  ; cdrom_rdy_atapi_buf[18]

           mov  cdrom_sns_device,ax
           
           ; clear the command packet
           lea  di,cdrom_sns_atapi_cmd
           push 12
           push ss
           push di
           call misc_clear_buffer
           add  sp,6
           mov  byte ss:[di+0],ATAPI_CMD_REQUEST_SENSE
           mov  byte ss:[di+4],18

           ; send the sense command
           lea  bx,cdrom_sns_atapi_buf
           push bx               ; offset
           push ss               ; segment
           push ATA_DATA_IN      ; read
           pushd 18              ;
           push 0                ; count before
           push di               ; offset command block
           push ss               ; segment command block
           push 12               ; size in byte of command block
           push word cdrom_sns_device
           call atapi_cmd_packet
           add  sp,20
           or   ax,ax
           jnz  short atapi_cmd_get_sense_error

           mov  bx,ss:[bx+12]    ; bl = asc, bh = ascq
atapi_cmd_get_sense_success:
           xor  ax,ax
           mov  sp,bp
           pop  bp

atapi_cmd_get_sense_error:
           mov  ax,2
           mov  sp,bp
           pop  bp
           ret
atapi_cmd_get_sense endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; is cdrom ready?
; on entry:
;  es = segment of EBDA
;  ax = device num
; on return
;  al = 0 = ready
; destroys nothing
atapi_is_ready proc near uses bx cx dx si di
           push bp
           mov  bp,sp
           sub  sp,0x16

cdrom_rdy_device     equ  [bp-0x02]
cdrom_rdy_atapi_cmd  equ  [bp-0x0E]  ; cdrom_rdy_atapi_cmd[12]
cdrom_rdy_atapi_buf  equ  [bp-0x16]  ; cdrom_rdy_atapi_buf[8]
           
           push eax

           ; get the device entry
           mov  cdrom_rdy_device,ax
           imul bx,ax,ATA_DEVICE_SIZE
           
           cmp  byte es:[bx+EBDA_DATA->ata_0_0_type],ATA_TYPE_ATAPI
           jne  atapi_is_ready_error
           
           ; clear the command packet
           lea  di,cdrom_rdy_atapi_cmd
           push 12
           push ss
           push di
           call misc_clear_buffer
           add  sp,6
           mov  byte ss:[di+0],ATAPI_CMD_READ_CAPACITY

           xor  dx,dx            ; in progress = 0
           mov  cx,5000          ; timeout count
cdrom_ready_loop:
           ; send the read_capacity command
           lea  bx,cdrom_rdy_atapi_buf
           push bx               ; offset
           push ss               ; segment
           push ATA_DATA_IN      ; read
           pushd 8               ;
           push 0                ; count before
           push di               ; offset command block
           push ss               ; segment command block
           push 12               ; size in byte of command block
           push word cdrom_rdy_device
           call atapi_cmd_packet
           add  sp,20
           or   ax,ax
           jz   short cdrom_ready_next

           ; get the sense
           mov  ax,cdrom_rdy_device
           call atapi_cmd_get_sense
           or   ax,ax
           jnz  short cdrom_ready_loop_dec
           ; bl = asc, bh = ascq

           ; if medium not present, return
           cmp  bl,0x3A  ; medium not present
           je   short atapi_is_ready_error

           ; if asc == 0x04 && ascq == 0x01 && inprogress
           cmp  bx,0x0104
           jne  short cdrom_ready_loop_dec
           or   dx,dx
           jnz  short cdrom_ready_loop_dec

           ; in progress of becoming ready
           mov  cx,30000         ; give it more time
           inc  dx               ; in progress

cdrom_ready_loop_dec:
           sub  cx,100
           jnz  short cdrom_ready_loop
           jmp  short atapi_is_ready_error

cdrom_ready_next:
           ; get the device entry
           mov  ax,cdrom_rdy_device
           imul bx,ax,ATA_DEVICE_SIZE

           ; check the block size
           lea  si,cdrom_rdy_atapi_buf
           mov  eax,ss:[si+4]
.if DO_INIT_BIOS32
           bswap eax
.else
           call _bswap
.endif
           cmp  eax,2048
           je   short @f
           cmp  eax,512
           jne  short atapi_is_ready_error
@@:        mov  es:[bx+EBDA_DATA->ata_0_0_blksize],ax
           
           ; get count of sectors
           mov  ecx,ss:[si+0]
.if DO_INIT_BIOS32
           bswap ecx
.else
           xchg ecx,eax
           call _bswap
           xchg ecx,eax
.endif
           cmp  ax,2048
           jne  short @f
           shl  ecx,2   ; convert to 512-byte sector count
@@:        mov  eax,es:[bx+EBDA_DATA->ata_0_0_sectors_low]
           cmp  ecx,eax
           je   short atapi_is_ready_success

           ; update the sector count
           mov  es:[bx+EBDA_DATA->ata_0_0_sectors_low],ecx

           ; print a message
           push ds
           push cs
           pop  ds
           shr  ecx,11           ; convert to megabytes
           push cx
           mov  si,offset cdrom_rdy_size_str
           call bios_printf
           add  sp,2
           pop  ds

atapi_is_ready_success:
           pop  eax
           xor  al,al
           mov  sp,bp
           pop  bp
           ret

atapi_is_ready_error:
           pop  eax
           mov  al,1
           mov  sp,bp
           pop  bp
           ret
atapi_is_ready endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send an io command to the atapi device
; on entry:
;  es = segment of EBDA
;  stack contains: (cdecl)
;    device, cmdlen, cmdseg, cmdoff,  header,  length   inout    segment, offset
;    [bp+4], [bp+6], [bp+8], [bp+10], [bp+12], [bp+14], [bp+18], [bp+20], [bp+22]
; on return:                                   (dword)
;    0 : no error
;    1 : error in parameters
;    2 : BUSY bit set
;    3 : error
;    4 : not ready
; destroys none (except ax)
atapi_cmd_packet proc near ; don't add anything here
           push bp
           mov  bp,sp
           sub  sp,12

atapi_loop      equ  [bp-2]   ; word
atapi_count     equ  [bp-4]   ; word
atapi_lcount    equ  [bp-6]   ; word
atapi_lbefore   equ  [bp-8]   ; word
atapi_lafter    equ  [bp-10]  ; word
atapi_mode      equ  [bp-11]  ; byte

           ; save the registers we use
           push edx
           push ecx
           push ebx
           push eax
           push si
           push di
           
           mov  ax,[bp+4]        ; device
           shr  ax,1             ; ax = channel
           imul si,ax,ATA_CHANNEL_SIZE
           mov  di,es:[si+EBDA_DATA->ata_0_iobase1]
           mov  si,es:[si+EBDA_DATA->ata_0_iobase2]
           imul bx,ax,ATA_DEVICE_SIZE

           ; make sure we aren't doing a write
           cmp  word [bp+18],ATA_DATA_OUT
           jne  short @f
           mov  ax,1
           jmp  ata_cmd_packet_done

@@:        ; make sure the header length is even
           test word [bp+12],0x0001
           jz   short @f
           mov  ax,1
           jmp  ata_cmd_packet_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; adjust the cmdlen value
@@:        mov  ax,[bp+6]
           cmp  ax,12
           jnb  short @f
           mov  ax,12
@@:        cmp  ax,16
           jna  short @f
           mov  ax,16
@@:        shr  ax,1             ; words
           mov  [bp+6],ax        ; save it

           ; reset the counters
           mov  word es:[EBDA_DATA->trsfsectors],0x0000
           mov  dword es:[EBDA_DATA->trsfbytes],0x00000000

           ; get the status of the device
           mov  dx,di            ; iobase1
           add  dx,ATA_CB_STAT
           in   al,dx
           test al,ATA_CB_STAT_BSY
           jz   short @f
           mov  ax,2
           jmp  ata_cmd_packet_done

@@:        mov  dx,si            ; iobase2
           add  dx,ATA_CB_DC
           mov  al,(ATA_CB_DC_HD15 | ATA_CB_DC_NIEN)
           out  dx,al
           mov  dx,di            ; iobase1
           inc  dx               ; features
           xor  al,al
           out  dx,al
           inc  dx               ; sector count
           out  dx,al
           inc  dx               ; sector number
           out  dx,al
           inc  dx               ; cyl low
           mov  al,0xF0
           out  dx,al
           inc  dx               ; cyl high
           mov  al,0xFF
           out  dx,al
           inc  dx               ; device/head
           mov  ax,[bp+4]        ; device
           and  al,1             ; slave
           shl  al,4             ; bit 4
           or   al,ATA_CB_DH_DEV0
           out  dx,al            ; select the drive
           inc  dx               ; command
           mov  al,ATA_CMD_PACKET
           out  dx,al
           
           ; device should be ok to receive command
           ; wait for the not busy
           mov  al,NOT_BSY_DRQ
           mov  dx,di            ; iobase1
           mov  cx,IDE_TIMEOUT
           call await_ide

           mov  dx,di            ; iobase1
           add  dx,ATA_CB_STAT
           in   al,dx

           ; if status & ATA_CB_STAT_ERR = error
           test al,ATA_CB_STAT_ERR
           jz   short @f
           mov  ax,3
           jmp  ata_cmd_packet_done
@@:        test al,ATA_CB_STAT_DRQ
           jnz  short @f
           mov  ax,4
           jmp  ata_cmd_packet_done

           ; 'normalize' address
@@:        mov  ax,[bp+10]
           shr  ax,4
           add  [bp+8],ax
           and  word [bp+10],0x000F

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; send command to device
           sti                   ; enable interrupts
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; do a transfer of the command
           mov  dx,di            ; iobase1

           push si               ; save iobase2
           push es
           mov  ax,[bp+8]
           mov  es,ax
           mov  si,[bp+10]
           mov  cx,[bp+6]        ; in words
           es:
           rep
             outsw
           pop  es
           pop  si

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; are we sending/receiving data with this command?
           cmp  word [bp+18],ATA_DATA_NO
           jne  short @f

           ; wait for the not busy
           mov  al,NOT_BSY
           mov  dx,di            ; iobase1
           mov  cx,IDE_TIMEOUT
           call await_ide
           add  dx,ATA_CB_STAT
           in   al,dx
           jmp  ata_cmd_packet_status_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; send/receive data
@@:        mov  word atapi_loop,0
ata_cmd_packet_loop:
           mov  al,NOT_BSY       ; assume wait for BSY
           cmp  word atapi_loop,0
           jne  short @f
           ; first time we need to wait DRQ
           mov  dx,si            ; iobase2
           add  dx,ATA_CB_ASTAT
           in   al,dx
           mov  al,NOT_BSY_DRQ
@@:        mov  dx,di            ; iobase1
           mov  cx,IDE_TIMEOUT
           call await_ide
           inc  word atapi_loop

           mov  dx,di            ; iobase1
           add  dx,ATA_CB_STAT
           in   al,dx
           mov  ah,al            ; save status in ah
           mov  dx,di            ; iobase1
           add  dx,ATA_CB_SC
           in   al,dx

           ; check if command completed
           in   al,dx
           and  al,0x07
           cmp  al,0x03
           jne  short @f
           mov  al,ah            ; need to pass along the status in al
           and  ah,(ATA_CB_STAT_RDY | ATA_CB_STAT_ERR)
           cmp  ah,ATA_CB_STAT_RDY
           je   ata_cmd_packet_status_done
           
           ; check if error
@@:        test  ah,ATA_CB_STAT_ERR
           jz   short @f
           mov  ax,3
           jmp  ata_cmd_packet_done

           ; 'normalize' address
@@:        mov  ax,[bp+22]
           shr  ax,4
           add  [bp+20],ax
           and  word [bp+22],0x000F
           
           mov  dx,di            ; iobase1
           add  dx,ATA_CB_CH
           in   al,dx
           shl  ax,8
           dec  dx
           in   al,dx
           mov  atapi_lcount,ax

           ; if (header > lcount)
          ;mov  ax,atapi_lcount
           cmp  [bp+12],ax
           jna  short @f
           mov  atapi_lbefore,ax
           sub  [bp+12],ax
           mov  word atapi_lcount,0
           jmp  short ata_cmd_next0
           ; else
@@:        mov  ax,[bp+12]
           mov  atapi_lbefore,ax
           mov  word [bp+12],0
           sub  atapi_lcount,ax
           
ata_cmd_next0:
           ; if (lcount > length)
           movzx eax,word atapi_lcount
           cmp  eax,[bp+14]
           jna  short @f
           sub  eax,[bp+14]
           mov  atapi_lafter,ax
           mov  eax,[bp+14]
           mov  atapi_lcount,ax
           mov  dword [bp+14],0
           jmp  short ata_cmd_next1
           ; else
@@:        mov  word atapi_lafter,0
           movzx eax,word atapi_lcount
           sub  [bp+14],eax
ata_cmd_next1:
           mov  ax,atapi_lcount
           mov  atapi_count,ax

           ; if any of the counts not divisible by 4, must use word mode
           mov  dl,es:[bx+EBDA_DATA->ata_0_0_mode]
           mov  ax,atapi_lbefore
           or   ax,atapi_lcount
           or   ax,atapi_lafter
           and  al,0x03
           jz   short @f
           mov  dl,ATA_MODE_PIO16
           
           ; if count is odd, add extra byte
@@:        mov  atapi_mode,dl
           test word atapi_lcount,0x0001
           jz   short @f
           inc  word atapi_lcount
           and  word atapi_lafter,(~0x0001)
           
           ; adjust the mode count (first assume 16-bit)
@@:        shr  word atapi_lcount,1
           shr  word atapi_lbefore,1
           shr  word atapi_lafter,1
           cmp  dl,ATA_MODE_PIO32
           jne  short @f
           ; if 32-bit, do it again
           shr  word atapi_lcount,1
           shr  word atapi_lbefore,1
           shr  word atapi_lafter,1

@@:        mov  dx,di            ; iobase1
           mov  cx,atapi_lbefore
           jcxz short ata_packet_no_before
           cmp  byte atapi_mode,ATA_MODE_PIO32
           je   short atapi_do_32bit
           ; 16-bit
@@:        in   ax,dx
           loop @b
           jmp  short ata_packet_no_before
atapi_do_32bit:
           in   eax,dx
           loop atapi_do_32bit
           
ata_packet_no_before:
           mov  cx,atapi_lcount
           jcxz short ata_packet_after

           push di
           push es
           mov  di,[bp+22]
           mov  ax,[bp+20]
           mov  es,ax
           cmp  byte atapi_mode,ATA_MODE_PIO32
           je   short @f
           ; 16-bit
           rep
             insw
           jmp  short ata_packet_after
@@:        ; 32-bit
           rep
             insd
ata_packet_after:
           pop  es
           pop  di
           
           mov  cx,atapi_lafter
           jcxz short ata_packet_done
           cmp  byte atapi_mode,ATA_MODE_PIO32
           je   short atapi_do_32bit_1
           ; 16-bit
@@:        in   ax,dx
           loop @b
           jmp  short ata_packet_done
atapi_do_32bit_1:
           in   eax,dx
           loop short atapi_do_32bit_1

ata_packet_done:
           ; new buffer address
           movzx eax,word atapi_count
           add  [bp+22],ax
           add  es:[EBDA_DATA->trsfbytes],eax
           jmp  ata_cmd_packet_loop

ata_cmd_packet_status_done:
           ; al = status
           and  al,(ATA_CB_STAT_BSY | ATA_CB_STAT_RDY | ATA_CB_STAT_DF | ATA_CB_STAT_DRQ | ATA_CB_STAT_ERR)
           cmp  al,ATA_CB_STAT_RDY
           je   short @f
           mov  ax,4
           jmp  short ata_cmd_packet_done

           ; enable interrupts
@@:        mov  dx,si            ; iobase2
           add  dx,ATA_CB_DC
           mov  al,ATA_CB_DC_HD15
           out  dx,al

           ; return success
           xor  ax,ax
           
ata_cmd_packet_done:
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
atapi_cmd_packet endp

.end
