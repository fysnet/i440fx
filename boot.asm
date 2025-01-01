comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: boot.asm                                                           *
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
*   boot include file                                                      *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.14                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 31 Dec 2024                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

no_boot_device_str  db 'No Boot Device specified...',13,10,0
boot_failure_str0   db 'Error reading from drive.'13,10,0
boot_failure_str1   db 'Drive not bootable.'13,10,0
boot_failure_str2   db 'CD-ROM boot failure code: 0x%04X'13,10,0
boot_failure_str3   db 'USB boot failure code: 0x%04X'13,10,0
boot_failure_str4   db 'SATA boot failure code: 0x%04X'13,10,0
booting_from_str    db 'Trying to boot from ',0

boot_to_IPL_type  db 0, IPL_TYPE_FLOPPY, IPL_TYPE_HARDDISK, IPL_TYPE_CDROM, 0, IPL_TYPE_USB, IPL_TYPE_BEV, 0, 0, 0, 0, 0, 0, 0, 0, 0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Get IPL entry from table
; on entry:
;  es = EBDA_SEG
;  ax = boot device index
; on return
;  ax = offset of entry into the table
; destroys nothing
get_boot_vector proc near
           cmp  ax,es:[EBDA_DATA->ipl_table_count]
           jae  short @f
           imul ax,sizeof(IPL_ENTRY)
           add  ax,EBDA_DATA->ipl_table_entries
           ret
@@:        mov  ax,-1
           ret
get_boot_vector endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; The boot services function
; on entry:
;  ax = index to boot device (zero on first time)
;  ds = 0x0040
; on return
;  nothing
; destroys nothing
int19_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           sub  sp,8

boot_dev_type      equ [bp-2]   ; word
boot_segment       equ [bp-4]   ; word (boot_segment and boot_offset
boot_offset        equ [bp-6]   ; word     must remain in this order)
boot_drive         equ [bp-7]   ; byte

           push es
           
           ; did the user specify a boot device?
           mov  bx,EBDA_SEG
           mov  es,bx
           cmp  word es:[EBDA_DATA->ipl_bootfirst],IPL_BOOT_FIRST_NONE
           jne  short boot_found_valid

           ; ax = sequence number (zero for first time here)
           mov  cx,ax            ; store in cx

           ; CMOS regs 0x3D and 0x38 contain the boot sequence:
           ; CMOS reg 0x3D & 0x0f : 1st boot device
           ; CMOS reg 0x3D & 0xf0 : 2nd boot device
           ; CMOS reg 0x38 & 0xf0 : 3rd boot device
           ; Boot device codes:
           ;  0x00 : not defined
           ;  0x01 : first floppy
           ;  0x02 : first harddrive
           ;  0x03 : first cdrom
           ;  0x04 : first pcmcia
           ;  0x05 : first usb
           ;  0x06 : embedded network
           ;  0x07 - 0x7f : reserved
           ;  0x80 : BEV device
           ; else : boot failure
           mov  ah,0x3D
           call cmos_get_byte
           mov  bl,al
           mov  ah,0x38
           call cmos_get_byte
           and  ax,0x00F0
           shl  ax,4
           or   al,bl
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; ax = 0x0CBA  ; A = 1st, B = 2nd, C = 3rd
           ; cx = nibble index (0, 1, 2)
           shl  cx,2
           shr  ax,cl
           ; ax = ax_nibbles[cx] = boot device

           push cs
           pop  ds

           ; find the first valid device
           mov  bx,offset boot_to_IPL_type
           mov  cx,3
           mov  dx,ax
@@:        mov  ax,dx
           and  ax,0x00F
           jz   short boot_find_0
           xlatb
           call find_boot_vector
           jnc  short boot_found_valid
boot_find_0:
           shr  dx,4
           loop @b
           jmp  short boot_invalid_boot_device

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; did the user select a device (via F12 boot)
boot_found_valid:
           mov  bx,es:[EBDA_DATA->ipl_bootfirst]
           cmp  bx,IPL_BOOT_FIRST_NONE
           je   short @f
           mov  ax,bx            ; new boot device value
           mov  word es:[EBDA_DATA->ipl_bootfirst],IPL_BOOT_FIRST_NONE
           mov  word es:[EBDA_DATA->ipl_sequence],IPL_BOOT_FIRST_NONE
@@:        cmp  ax,0x0000
           ja   short @f
boot_invalid_boot_device:
           mov  si,offset no_boot_device_str
           call display_string
           call freeze

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; make zero based, and read from the IPL table
@@:        dec  ax
           mov  es:[EBDA_DATA->ipl_last_index],ax
           call get_boot_vector
           cmp  ax,-1
           je   nonbootable_device

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; print a string indicating which device we are booting
           mov  bx,ax
           movzx ax,byte es:[bx+IPL_ENTRY->type]
           mov  boot_dev_type,ax  ; save it for later
           or   ax,ax
           jz   short boot_invalid_boot_device
           cmp  ax,IPL_TYPE_BEV
           ja   short boot_invalid_boot_device
           jb   short @f
           mov  ax,IPL_TYPE_NET

@@:        mov  si,offset booting_from_str
           call display_string
           imul si,ax,DRIVETYPES_LEN
           add  si,offset drivetypes
           call display_string
           mov  al,32
           call display_char
           
           lea  si,[bx+IPL_ENTRY->description]
           mov  cx,IPL_ENTRY_MAX_DESC_LEN
@@:        mov  al,es:[si]
           or   al,al
           jz   short @f
           call display_char
           inc  si
           loop @b

@@:        mov  al,13
           call display_char
           mov  al,10
           call display_char

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now we can try to load the media

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; are we a hard disk or floppy?
           mov  dl,es:[bx+IPL_ENTRY->device]
           cmp  word boot_dev_type,IPL_TYPE_FLOPPY
           je   short @f
           cmp  word boot_dev_type,IPL_TYPE_HARDDISK
           jne  short boot_type_type_usb

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; first see if we are a SATA disk
.if DO_INIT_BIOS32
           test word es:[bx+IPL_ENTRY->flags],IPL_FLAGS_SATA
           jz   short @f
           ; call the sata boot code
           mov  eax,es:[bx+IPL_ENTRY->base_lba]
           call boot_sata_funtion
           or   al,al
           jz   short boot_usb_good
.endif

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read from the disk
           ; (OS2Warp40 assumes cs == 0x0000 !!!)
@@:        xor  ax,ax            ; 0x0000:7C00
           mov  es,ax            ; segment
           mov  bx,0x7C00        ; offset

           mov  boot_segment,ax  ;  save for later
           mov  boot_offset,bx   ;  
           mov  boot_drive,dl    ;  
           mov  ax,0x0201        ; service 0x02, read 0x01 sector
           mov  cx,0x0001        ; track 0, sector 1
           mov  dh,0x00          ; head 0 (dl = drive from above)
           int  13h              ; call the service
           jnc  short boot_media_okay

           ; else, error loading from media
           mov  si,offset boot_failure_str0
           call display_string
           jmp  nonbootable_device

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we successfully read the sector
           ; check to see if it is a bootable sector
boot_media_okay:
           ; if we are a floppy, check the cmos flag first
           cmp  word boot_dev_type,IPL_TYPE_FLOPPY
           jne  short @f
           mov  ah,0x38
           call cmos_get_byte
           test al,1
           jnz  boot_jump_to_sector
@@:        mov  ax,es:[0x7DFE]
           cmp  ax,0xAA55
           je   boot_jump_to_sector
           cmp  ax,0x55AA        ; some incorrectly use this too
           je   short boot_jump_to_sector
           
           mov  si,offset boot_failure_str1
           call display_string
.if DO_INIT_BIOS32
           jmp  nonbootable_device
.else
           jmp  short nonbootable_device
.endif
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; are we a USB disk
boot_type_type_usb:
.if DO_INIT_BIOS32
           cmp  word boot_dev_type,IPL_TYPE_USB
           jne  short boot_type_type_cdrom

           ; call the usb boot code
           mov  eax,es:[bx+IPL_ENTRY->base_lba]
           call boot_usb_funtion
           or   al,al
           jz   short boot_usb_good

           ; print error code
           push ax
           mov  si,offset boot_failure_str3
           call bios_printf
           add  sp,2
           jmp  short nonbootable_device

boot_usb_good:
           mov  boot_drive,ah
           mov  word boot_segment,0x07C0
           mov  word boot_offset,0x0000
           jmp  short boot_jump_to_sector
.endif
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; are we a CD-ROM?
boot_type_type_cdrom:
           cmp  word boot_dev_type,IPL_TYPE_CDROM
           jne  short boot_type_try_bev

           ; call the cdrom boot code
           call boot_cdrom_funtion
           or   al,al
           jz   short boot_cdrom_good

           ; print error code
           push ax
           mov  si,offset boot_failure_str2
           call bios_printf
           add  sp,2
           jmp  short nonbootable_device

boot_cdrom_good:
           mov  boot_drive,ah
           mov  ax,es:[EBDA_DATA->cdemu_load_segment]
           mov  boot_segment,ax
           mov  word boot_offset,0x0000
           jmp  short boot_jump_to_sector

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; are we a BEV device?
           ; if so, the IPL code already got the address
boot_type_try_bev:
           cmp  word boot_dev_type,IPL_TYPE_BEV
           jne  short nonbootable_device
           
           mov  eax,es:[bx+IPL_ENTRY->vector]
           mov  boot_offset,ax
           shr  eax,16
           mov  boot_segment,ax
           mov  byte boot_drive,0x00

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 'jump' to the newly loaded sector
boot_jump_to_sector:
           
           ; incase the boot code 'returns' (ret, retf, iret),
           ;  lets have it return to INT 18h
           pushf
           push cs
           push offset int18_handler
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; disable the ioapic and restore the 8259 pic
           call ioapic_disable
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; restore the screen mode
           call display_restore_default

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; make sure the BIOS ROM is read only
.if DO_INIT_BIOS32
           call far offset bios_lock_shadow_ram,BIOS_BASE
.endif     
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; make sure that we write the escd back to the flash rom
           call far offset bios_commit_escd,BIOS_BASE

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; setup the registers and jump to the boot code
           mov  dl,boot_drive
           mov  ax,BIOS_BASE2
           mov  es,ax
           xor  ax,ax            ; I can find nowhere where it states ds=0
           mov  ds,ax            ; however, most references say they might be
           mov  di,offset pnpbios_structure
           jmp  far boot_offset

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if we make it here, we didn't boot that device,
           ;  so return and let INT 18h try the next one
nonbootable_device:
           pop  es
           mov  sp,bp
           pop  bp
           ret
int19_function endp

.end
