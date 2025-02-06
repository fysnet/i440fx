comment |*******************************************************************
*  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: ebda.asm                                                           *
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
*   (extended) bios data area include file                                 *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.16                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 5 Feb 2025                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*  This source file is uses to manipulate the (extended) BIOS Data Area    *
*                                                                          *
***************************************************************************|

; this struct is initially at EBDA_SEG, but the OS is allowed
;  to move it as long as it updates 0x0040:0x000E with the 
;  new segment. (and interrupt vectors 41h and 46h, and any
;  other vector that has this initial segment value)
; the area from (EBDA_SEG * 0x10) to 0xA0000 is left for 
;  this ((EBDA_SIZE << 10) - 256) bytes and the IPL table (256 bytes).
; after we boot a device, the IPL table (256 bytes) is then
;  free to use for other purposes.
EBDA_DATA  struct
  size                  byte         ; size in 1k (1 = 1k, 2 = 2k, ...)
  
  escd_dirty            byte         ; 1 = the ESCD has been written to and needs to be committed
  
  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ; video
  video_ram             dword
  video_width           word
  video_height          word
  video_bpp             byte
  video_model           byte
  video_bpscanline      word
  video_red_mask_sz     byte
  video_red_pos         byte
  video_grn_mask_sz     byte
  video_grn_pos         byte
  video_blu_mask_sz     byte
  video_blu_pos         byte
  video_use_graphic     byte
  video_use_bga         byte
  vid_char_scrn_width   word
  vid_char_scrn_height  word
  vid_char_cur_x        word
  vid_char_cur_y        word
  vid_display_pixel     word         ; 0xE000:xxxx to the display pixel function
  vid_display_pixel_seg word         ;
  video_icon_cnt        byte
  video_icon_type       byte
  video_icon_palette    word
  
  mouse_driver_offset   word         ; 
  mouse_driver_seg      word
  mouse_index           byte         ; bits 3:0 = byte index into packet
  mouse_flags           byte         ; bit 7 = handler given, bits 3:0 = 1-based packet size
  mouse_data            dup  8

  i440_pcidev           word         ; high byte = bus, low byte = dev/func (bbbbbbbbdddddfff)
  i440_pciisa           word         ; high byte = bus, low byte = dev/func (bbbbbbbbdddddfff)
  pci_bios_io_addr      dword
  pci_bios_agp_io_addr  dword
  pci_bios_mem_addr     dword
  pci_bios_agp_mem_addr dword
  pci_bios_rom_start    dword

  pm_io_base            dword
  smb_io_base           dword
  pm_sci_int            byte
  acpi_enabled          byte
  
  cpuid_signature       dword
  cpuid_features        dword
  cpuid_ext_features    dword

  smp_cpus              word         ; number of cpus
  
  bios_table_cur_addr   dword        ; physical address of next available bios_table area
  mp_config_table       dword        ; multi-processor config table address
  mp_config_table_sz    word         ; size of table in bytes
  fp_config_table       dword        ; floating pointer table address
  fp_config_table_sz    word         ; size of table in bytes
  sm_config_table       dword        ; SM BIOS table address
  sm_config_table_sz    word         ; size of table in bytes
  
  acpi_base_address     dword        ; ACPI base address   ; top of (32-bit) memory minus 64k
  acpi_tables_size      word         ; all table size (does not include rsdp)
  rsdp_table            dword        ; RSDP table address
  rsdt_addr             dword        ; RSDT table address  ; --- starts acpi_base_address
  fadt_addr             dword        ; FADT table address
  facs_addr             dword        ; FACS table address
  dsdt_addr             dword        ; DSDT table address
  dsdt_addr_sz          word         ; size of table in bytes
  ssdt_addr             dword        ; SSDT table address
  ssdt_addr_sz          word         ; size of table in bytes
  madt_addr             dword        ; MADT table address
  madt_addr_sz          word         ; size of table in bytes
  hpet_addr             dword        ; ACPI HPET table address

  bios_uuid             dup  16      ; the bios' uuid (we clear it to zero) (DSP0124.3.7.0.pdf, page 36 defines format)
  qemu_cfg_port         byte         ; Found QEMU config port

  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ; count of floppy disk drives detected
  fdd_count             byte         ; count of floppy disk drives detected

  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ; fixed disk parameter table(s) (FDPTs)
  fdpt0                 dup  16
  fdpt1                 dup  16
  
  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ; ata_channels
  ata_0_iface           byte         ; ISA or PCI
  ata_0_iobase1         word         ; IO Base 1
  ata_0_iobase2         word         ; IO Base 2
  ata_0_irq             byte         ; IRQ
  ata_1_iface           byte         ; ISA or PCI
  ata_1_iobase1         word         ; IO Base 1
  ata_1_iobase2         word         ; IO Base 2
  ata_1_irq             byte         ; IRQ
  ata_2_iface           byte         ; ISA or PCI
  ata_2_iobase1         word         ; IO Base 1
  ata_2_iobase2         word         ; IO Base 2
  ata_2_irq             byte         ; IRQ
  ata_3_iface           byte         ; ISA or PCI
  ata_3_iobase1         word         ; IO Base 1
  ata_3_iobase2         word         ; IO Base 2
  ata_3_irq             byte         ; IRQ
  
  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ; ata devices
  ata_0_0_type          byte         ; Detected type of ata (ata/atapi/none/unknown)
  ata_0_0_device        byte         ; Detected type of attached devices (hd/cd/none)
  ata_0_0_removable     byte         ; Removable device flag
  ata_0_0_lock          byte         ; Locks for removable devices
  ata_0_0_mode          byte         ; transfer mode : PIO 16/32 bits - IRQ - ISADMA - PCIDMA
  ata_0_0_blksize       word         ; block size
  ata_0_0_translation   byte         ; type of translation
  ata_0_0_lchs_heads    word         ; logical chs heads
  ata_0_0_lchs_cyl      word         ; logical chs cylinders
  ata_0_0_lchs_spt      word         ; logical chs spt
  ata_0_0_pchs_heads    word         ; physical chs heads
  ata_0_0_pchs_cyl      word         ; physical chs cylinders
  ata_0_0_pchs_spt      word         ; physical chs spt
  ata_0_0_sectors_low   dword        ; Total sectors count
  ata_0_0_sectors_high  dword        ;
  
  ata_0_1_type          byte         ; Detected type of ata (ata/atapi/none/unknown)
  ata_0_1_device        byte         ; Detected type of attached devices (hd/cd/none)
  ata_0_1_removable     byte         ; Removable device flag
  ata_0_1_lock          byte         ; Locks for removable devices
  ata_0_1_mode          byte         ; transfer mode : PIO 16/32 bits - IRQ - ISADMA - PCIDMA
  ata_0_1_blksize       word         ; block size
  ata_0_1_translation   byte         ; type of translation
  ata_0_1_lchs_heads    word         ; logical chs heads
  ata_0_1_lchs_cyl      word         ; logical chs cylinders
  ata_0_1_lchs_spt      word         ; logical chs spt
  ata_0_1_pchs_heads    word         ; physical chs heads
  ata_0_1_pchs_cyl      word         ; physical chs cylinders
  ata_0_1_pchs_spt      word         ; physical chs spt
  ata_0_1_sectors_low   dword        ; Total sectors count
  ata_0_1_sectors_high  dword        ;
  
  ata_1_0_type          byte         ; Detected type of ata (ata/atapi/none/unknown)
  ata_1_0_device        byte         ; Detected type of attached devices (hd/cd/none)
  ata_1_0_removable     byte         ; Removable device flag
  ata_1_0_lock          byte         ; Locks for removable devices
  ata_1_0_mode          byte         ; transfer mode : PIO 16/32 bits - IRQ - ISADMA - PCIDMA
  ata_1_0_blksize       word         ; block size
  ata_1_0_translation   byte         ; type of translation
  ata_1_0_lchs_heads    word         ; logical chs heads
  ata_1_0_lchs_cyl      word         ; logical chs cylinders
  ata_1_0_lchs_spt      word         ; logical chs spt
  ata_1_0_pchs_heads    word         ; physical chs heads
  ata_1_0_pchs_cyl      word         ; physical chs cylinders
  ata_1_0_pchs_spt      word         ; physical chs spt
  ata_1_0_sectors_low   dword        ; Total sectors count
  ata_1_0_sectors_high  dword        ;
  
  ata_1_1_type          byte         ; Detected type of ata (ata/atapi/none/unknown)
  ata_1_1_device        byte         ; Detected type of attached devices (hd/cd/none)
  ata_1_1_removable     byte         ; Removable device flag
  ata_1_1_lock          byte         ; Locks for removable devices
  ata_1_1_mode          byte         ; transfer mode : PIO 16/32 bits - IRQ - ISADMA - PCIDMA
  ata_1_1_blksize       word         ; block size
  ata_1_1_translation   byte         ; type of translation
  ata_1_1_lchs_heads    word         ; logical chs heads
  ata_1_1_lchs_cyl      word         ; logical chs cylinders
  ata_1_1_lchs_spt      word         ; logical chs spt
  ata_1_1_pchs_heads    word         ; physical chs heads
  ata_1_1_pchs_cyl      word         ; physical chs cylinders
  ata_1_1_pchs_spt      word         ; physical chs spt
  ata_1_1_sectors_low   dword        ; Total sectors count
  ata_1_1_sectors_high  dword        ;
  
  ata_2_0_type          byte         ; Detected type of ata (ata/atapi/none/unknown)
  ata_2_0_device        byte         ; Detected type of attached devices (hd/cd/none)
  ata_2_0_removable     byte         ; Removable device flag
  ata_2_0_lock          byte         ; Locks for removable devices
  ata_2_0_mode          byte         ; transfer mode : PIO 16/32 bits - IRQ - ISADMA - PCIDMA
  ata_2_0_blksize       word         ; block size
  ata_2_0_translation   byte         ; type of translation
  ata_2_0_lchs_heads    word         ; logical chs heads
  ata_2_0_lchs_cyl      word         ; logical chs cylinders
  ata_2_0_lchs_spt      word         ; logical chs spt
  ata_2_0_pchs_heads    word         ; physical chs heads
  ata_2_0_pchs_cyl      word         ; physical chs cylinders
  ata_2_0_pchs_spt      word         ; physical chs spt
  ata_2_0_sectors_low   dword        ; Total sectors count
  ata_2_0_sectors_high  dword        ;
  
  ata_2_1_type          byte         ; Detected type of ata (ata/atapi/none/unknown)
  ata_2_1_device        byte         ; Detected type of attached devices (hd/cd/none)
  ata_2_1_removable     byte         ; Removable device flag
  ata_2_1_lock          byte         ; Locks for removable devices
  ata_2_1_mode          byte         ; transfer mode : PIO 16/32 bits - IRQ - ISADMA - PCIDMA
  ata_2_1_blksize       word         ; block size
  ata_2_1_translation   byte         ; type of translation
  ata_2_1_lchs_heads    word         ; logical chs heads
  ata_2_1_lchs_cyl      word         ; logical chs cylinders
  ata_2_1_lchs_spt      word         ; logical chs spt
  ata_2_1_pchs_heads    word         ; physical chs heads
  ata_2_1_pchs_cyl      word         ; physical chs cylinders
  ata_2_1_pchs_spt      word         ; physical chs spt
  ata_2_1_sectors_low   dword        ; Total sectors count
  ata_2_1_sectors_high  dword        ;
  
  ata_3_0_type          byte         ; Detected type of ata (ata/atapi/none/unknown)
  ata_3_0_device        byte         ; Detected type of attached devices (hd/cd/none)
  ata_3_0_removable     byte         ; Removable device flag
  ata_3_0_lock          byte         ; Locks for removable devices
  ata_3_0_mode          byte         ; transfer mode : PIO 16/32 bits - IRQ - ISADMA - PCIDMA
  ata_3_0_blksize       word         ; block size
  ata_3_0_translation   byte         ; type of translation
  ata_3_0_lchs_heads    word         ; logical chs heads
  ata_3_0_lchs_cyl      word         ; logical chs cylinders
  ata_3_0_lchs_spt      word         ; logical chs spt
  ata_3_0_pchs_heads    word         ; physical chs heads
  ata_3_0_pchs_cyl      word         ; physical chs cylinders
  ata_3_0_pchs_spt      word         ; physical chs spt
  ata_3_0_sectors_low   dword        ; Total sectors count
  ata_3_0_sectors_high  dword        ;
  
  ata_3_1_type          byte         ; Detected type of ata (ata/atapi/none/unknown)
  ata_3_1_device        byte         ; Detected type of attached devices (hd/cd/none)
  ata_3_1_removable     byte         ; Removable device flag
  ata_3_1_lock          byte         ; Locks for removable devices
  ata_3_1_mode          byte         ; transfer mode : PIO 16/32 bits - IRQ - ISADMA - PCIDMA
  ata_3_1_blksize       word         ; block size
  ata_3_1_translation   byte         ; type of translation
  ata_3_1_lchs_heads    word         ; logical chs heads
  ata_3_1_lchs_cyl      word         ; logical chs cylinders
  ata_3_1_lchs_spt      word         ; logical chs spt
  ata_3_1_pchs_heads    word         ; physical chs heads
  ata_3_1_pchs_cyl      word         ; physical chs cylinders
  ata_3_1_pchs_spt      word         ; physical chs spt
  ata_3_1_sectors_low   dword        ; Total sectors count
  ata_3_1_sectors_high  dword        ;
  
  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ata_hdcount           byte         ; map between (bios hd id - 0x80) and ata channels
  ata_0_0_hdidmap       byte         ;
  ata_0_1_hdidmap       byte         ;
  ata_1_0_hdidmap       byte         ;
  ata_1_1_hdidmap       byte         ;
  ata_2_0_hdidmap       byte         ;
  ata_2_1_hdidmap       byte         ;
  ata_3_0_hdidmap       byte         ;
  ata_3_1_hdidmap       byte         ;
  
  ata_cdcount           byte         ; map between (bios cd id - 0x80) and ata channels
  ata_0_0_cdidmap       byte         ;
  ata_0_1_cdidmap       byte         ;
  ata_1_0_cdidmap       byte         ;
  ata_1_1_cdidmap       byte         ;
  ata_2_0_cdidmap       byte         ;
  ata_2_1_cdidmap       byte         ;
  ata_3_0_cdidmap       byte         ;
  ata_3_1_cdidmap       byte         ;
  
  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  dpte_iobase1          word         ;
  dpte_iobase2          word         ;
  dpte_prefix           byte         ;
  dpte_unused           byte         ;
  dpte_irq              byte         ;
  dpte_blkcount         byte         ;
  dpte_dma              byte         ;
  dpte_pio              byte         ;
  dpte_options          word         ;
  dpte_reserved         word         ;
  dpte_revision         byte         ;
  dpte_checksum         byte         ;
  
  trsfsectors           word         ; Count of transferred sectors and bytes
  trsfbytes             dword        ;
  
  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  cdemu_active          byte         ; if not zero, emulation is active for the cdrom
  cdemu_media           byte         ; 0, 1, 2, 3, and 4
  cdemu_emulated_drive  byte         ; 0x00 or 0x80
  cdemu_controller_index byte        ; 
  cdemu_ilba            dword        ; starting lba of emulated image on CD-ROM
  cdemu_device_spec     word         ; 
  cdemu_buffer_offset   word         ;
  cdemu_load_segment    word         ;
  cdemu_sector_count    word         ;
  
  cdemu_vchs_cyl        word         ; emulated logical chs cylinders
  cdemu_vchs_spt        word         ; emulated logical chs spt
  cdemu_vchs_heads      word         ; emulated logical chs heads

  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ; AHCI
  sata_disk_active          byte      ; if not zero, emulation is active for the SATA
  sata_disk_media           dword     ; SATA_SIG_ATA or SATA_SIG_ATAPI
  sata_disk_emulated_drive  byte      ; 0x8x, or 0xEx (hard drive, or cdrom, x = 0 -> count of items found for that type)
  sata_disk_emulated_device byte      ; actual device of the booted drive
  sata_next_device_id       byte      ; next device id
  sata_disk_base_lba        dword     ; base LBA of emulated image within device

  sata_ahci_cntrls          dup (sizeof(SATA_CONTROLLER) * MAX_SATA_CONTROLLERS)

  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  usb_disk_active          byte      ; if not zero, emulation is active for the USB
  usb_disk_media           byte      ; 0, 1, or 2 (0 = 1.44M floppy, 1 = hard drive, 2 = cdrom) (See USB_MSD_MEDIA_*)
  usb_disk_emulated_drive  byte      ; 0x0x, 0x8x, or 0xEx (floppy, hard drive, or cdrom, x = 0 -> count of items found for that type)
  usb_disk_emulated_device byte      ; actual device of the booted drive
  usb_disk_emu_cdrom       byte      ; if not zero, cdrom is emulating a 512-byte drive
  usb_disk_base_lba        dword     ; base LBA of emulated image within device

  usb_uhci_cntrls          dup (sizeof(USB_CONTROLLER) * MAX_USB_CONTROLLERS)
  usb_ohci_cntrls          dup (sizeof(USB_CONTROLLER) * MAX_USB_CONTROLLERS)
  usb_ehci_cntrls          dup (sizeof(USB_CONTROLLER) * MAX_USB_CONTROLLERS)
  usb_xhci_cntrls          dup (sizeof(USB_CONTROLLER) * MAX_USB_CONTROLLERS)

  usb_ehci_legacy          byte      ; 0 = enumerate the EHCI and control all devices, 1 = give all devices to companion controller(s)
  usb_next_device_id       byte      ; next device id
  
  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ipl_table_entries     dup (sizeof(IPL_ENTRY) * IPL_TABLE_ENTRY_CNT) ; IPL Table: IPL_TABLE_ENTRY_CNT entries
  ipl_table_count       word         ; count on used entries
  ipl_sequence          word         ; sequence
  ipl_bootfirst         word         ; index of first boot device (or IPL_BOOT_FIRST_NONE if none)
  ipl_last_index        word         ; index of last booted IPL (only when we don't shutdown/restore)

  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ; E820 style memory table
  mem_base_ram_size     dword       ; base ram size up to 4gig
  mem_base_ext_ram_size qword       ; ram size above 4gig
  memory_table          dup (sizeof(MEM_TABLE) * MEM_TABLE_ENTRIES)
  memory_count          word        ; count of entries used
  mem_base_ram_alloc    dword       ; last allocated memory location
  
  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ; APIC
  apic_id               byte        ; apic id
  apic_version          byte        ; apic version
  apic_lvt_entries      byte        ; count of local vector table entries
  ioapic_id             byte        ; io apic id
  ioapic_ver            byte        ; io apic version
  ioapic_entries        byte        ; count of redirection entries

  ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ;
  unused                dup 723     ; unused / available space

EBDA_DATA  ends         ; end of structure declaration.

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; check to make sure the table is the correct size
.if (sizeof(EBDA_DATA) != (EBDA_SIZE << 10))
  %error 1 "EBDA_DATA table abnormal size"
  %print sizeof(EBDA_DATA)
.endif

SYS_MODEL_ID     equ  0xFC
SYS_SUBMODEL_ID  equ  0x00
BIOS_REVISION    equ  0x01

ebda_bios_config_table:
      dw 0x0008                ; size of table (in bytes)
      db SYS_MODEL_ID
      db SYS_SUBMODEL_ID
      db BIOS_REVISION
      ; Feature byte 1
      db ((0 << 7) | \ ; b7: 1=DMA channel 3 used by hard disk
          (1 << 6) | \ ; b6: 1=2 interrupt controllers present
          (1 << 5) | \ ; b5: 1=RTC present
          (1 << 4) | \ ; b4: 1=BIOS calls int 15h/4Fh every key
          (0 << 3) | \ ; b3: 1=wait for extern event supported (Int 15h/41h)
          (1 << 2) | \ ; b2: 1=extended BIOS data area used
          (0 << 1) | \ ; b1: 0=AT or ESDI bus, 1=MicroChannel
          (0 << 0))    ; b0: 1=Dual bus (MicroChannel + ISA)
      ; Feature byte 2
      db ((0 << 7) | \ ; b7: 1=32-bit DMA supported
          (1 << 6) | \ ; b6: 1=int16h, function 9 supported
          (0 << 5) | \ ; b5: 1=int15h/C6h (get POS data) supported
          (0 << 4) | \ ; b4: 1=int15h/C7h (get mem map info) supported
          (0 << 3) | \ ; b3: 1=int15h/C8h (en/dis CPU) supported
          (0 << 2) | \ ; b2: 1=non-8042 kb controller
          (0 << 1) | \ ; b1: 1=data streaming supported
          (0 << 0))    ; b0: reserved
      ; Feature byte 3
      db ((0 << 7) | \ ; b7: not used
          (0 << 6) | \ ; b6: reserved
          (0 << 5) | \ ; b5: reserved
          (0 << 4) | \ ; b4: POST supports ROM-to-RAM enable/disable
          (0 << 3) | \ ; b3: SCSI on system board
          (0 << 2) | \ ; b2: info panel installed
          (0 << 1) | \ ; b1: Initial Machine Load (IML) system - BIOS on disk
          (0 << 0))    ; b0: SCSI supported in IML
      ; Feature byte 4
      db ((0 << 7) | \ ; b7: IBM private
          (0 << 6) | \ ; b6: EEPROM present
          (0 << 3) | \ ; b5-3: ABIOS presence (011 = not supported)
          (0 << 2) | \ ; b2: private
          (0 << 1) | \ ; b1: memory split above 16Mb supported
          (0 << 0))    ; b0: POSTEXT directly supported by POST
      ; Feature byte 5 (IBM)
      db ((0 << 7) | \ ; b7: IBM private
          (0 << 6) | \ ; b6: IBM private
          (0 << 5) | \ ; b5: IBM private
          (0 << 4) | \ ; b4: reserved
          (0 << 3) | \ ; b3: reserved
          (0 << 2) | \ ; b2: reserved
          (0 << 1) | \ ; b1: enhanced mouse
          (0 << 0))    ; b0: flash EPROM

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get the address of the ebda
; initially set to 0x9Fxx
; OS can move it (Win98 does)
; On entry:
;  nothing
; On return:
;  ax = segment of EBDA
;  destroys nothing
bios_get_ebda proc near
           push ds
           mov  ax,0x40
           mov  ds,ax
           mov  ax,[0x000E]
           pop  ds
           ret
bios_get_ebda endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write a seg:offset to a given interrupt vector in the BDA
; On entry:
;  ax = interrupt vector number
;  bx = offset
;  cx = segment
; On return:
;  nothing
;  destroys nothing
set_int_vector proc near uses ax bx dx ds
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; ds = 0x0000
           xor  dx,dx
           mov  ds,dx

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; calculate address in IDT
           shl  ax,2
           xchg bx,ax
           mov  [bx+0],ax
           mov  [bx+2],cx

           ret
set_int_vector endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the IVT
; On entry:
;  es = 0x0000
; On return:
;  nothing
;  destroys all general
post_init_ivt proc near
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; the first 120 interrupt vectors need to point
           ;  to a default handler (int 0x00 - int 0x77)
           ; we use a 32-bit rep stosd to do this
           xor  di,di
           mov  cx,120
           mov  eax,(BIOS_BASE << 16) ; BIOS_BASE:dummy_handler
           mov  ax,offset dummy_handler
           cld
           rep
             stosd
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Division by zero (INT 0)
           xor  bx,bx
           mov  ax,offset int00_handler
           mov  [bx],ax
           add  bx,4

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Single Step (INT 1)
           mov  ax,offset int01_handler
           mov  [bx],ax
           add  bx,4

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; NonMaskable (INT 2)
           mov  ax,offset int02_handler
           mov  [bx],ax
           add  bx,4
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Break Point (INT 3)
           mov  ax,offset int03_handler
           mov  [bx],ax
           add  bx,4

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Overflow (INT 4)
           mov  ax,offset int04_handler
           mov  [bx],ax
           add  bx,4

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Bound Fault (INT 5)
           mov  ax,offset int05_handler
           mov  [bx],ax
           add  bx,4

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Invalid Opcode (INT 6)
           mov  ax,offset int06_handler
           mov  [bx],ax
           add  bx,4
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Processor extension not available (INT 7)
           mov  ax,offset int07_handler
           mov  [bx],ax
          ;add  bx,4
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; master PIC vector
           mov  bx,(8 * 4)
           mov  cx,8
           mov  ax,offset eoi_master_pic  ; BIOS_BASE:eoi_master_pic
@@:        mov  [bx],ax
           add  bx,4
           loop @b
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; slave PIC vector
           mov  bx,0x01C0
           mov  cx,0x08
           mov  ax,offset eoi_both_pic  ; BIOS_BASE:eoi_both_pic
@@:        mov  [bx],ax
           add  bx,4
           loop @b

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; equipment configuration check
           mov  ax,0x11
           mov  cx,BIOS_BASE
           mov  bx,offset int11_handler
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; memory size check
           mov  ax,0x12
           mov  cx,BIOS_BASE
           mov  bx,offset int12_handler
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; system services
           mov  ax,0x15
           mov  cx,BIOS_BASE
           mov  bx,offset int15_handler
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; printer services
           mov  ax,0x17
           mov  cx,BIOS_BASE
           mov  bx,offset int17_handler
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; bootstrap failure
           mov  ax,0x18
           mov  cx,BIOS_BASE
           mov  bx,offset int18_handler
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; bootstrap loader
           mov  ax,0x19
           mov  cx,BIOS_BASE
           mov  bx,offset int19_handler
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; MDA/CGA video parameter table
           mov  ax,0x1D
           xor  cx,cx
           xor  bx,bx
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Character Font for upper 128 chars
           mov  ax,0x1F
           xor  cx,cx
           xor  bx,bx
           call set_int_vector
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; all vectors from 0x60 to 0x67 point to 0000:0000
           xor  ax,ax
           mov  cx,16
           mov  di,0x180
           cld
           rep
             stosw
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; all vectors from 0x78 to 0xFF point to 0000:0000
           xor  ax,ax
           mov  cx,272
           mov  di,0x1E0
           cld
           rep
             stosw
           
           ret
post_init_ivt endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the Extended BDA
; On entry:
;  es = 0x0000
; On return:
;  nothing
;  destroys all general
post_init_ebda proc near uses cx di
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set the first byte of the ebda to the size
           push es
           mov  ax,EBDA_SEG
           mov  es,ax
           xor  di,di
           mov  al,EBDA_SIZE     ; size in 1k's
           stosb
           xor  al,al
           mov  cx,((EBDA_SIZE < 10) - 1)
           rep
             stosb
           pop  es

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; store the segment in the bda
           mov  ax,EBDA_SEG
           mov  es:[0x040E],ax
           
           ret
post_init_ebda endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the boot vectors
; On entry:
;  es = 0x0000
; On return:
;  nothing
;  destroys all general
init_boot_vectors proc near uses ds

           mov  ax,EBDA_SEG
           mov  ds,ax
           
           ; table was cleared out for us by post_init_ebda above

           ; User selected device not set
           mov  word [EBDA_DATA->ipl_bootfirst],IPL_BOOT_FIRST_NONE
           mov  word [EBDA_DATA->ipl_table_count],0

           ; we haven't tried booting anything yet
           mov  word [EBDA_DATA->ipl_sequence],IPL_BOOT_FIRST_NONE

           ret
init_boot_vectors endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; add a device to the boot vector list
; On entry:
;  eax = base LBA
;  ecx = seg:off of vector
;  edx = high word = flags
;  dh = type (IPL_TYPE_*)
;  dl = device number to use
;  es:si -> description string (si = 0 if no string)
; On return:
;  carry = set if not added
;  destroys none
add_boot_vector proc near uses eax bx cx edx si di ds
           
           mov  bx,EBDA_SEG
           mov  ds,bx
           
           ; get the next entry's address
           mov  bx,[EBDA_DATA->ipl_table_count]
           cmp  bx,IPL_TABLE_ENTRY_CNT
           jae  short @f
           
           imul bx,sizeof(IPL_ENTRY)
           add  bx,EBDA_DATA->ipl_table_entries

           ; store our information
           mov        [bx+IPL_ENTRY->type],dh
           mov        [bx+IPL_ENTRY->device],dl
           mov        [bx+IPL_ENTRY->vector],ecx
           mov        [bx+IPL_ENTRY->base_lba],eax
           mov  byte  [bx+IPL_ENTRY->description],0
           shr  edx,16
           mov        [bx+IPL_ENTRY->flags],dx
           mov  dword [bx+IPL_ENTRY->reserved],0

           ; is there a description string passed
           or   si,si
           jz   short add_boot_vector_no_str
           mov  cx,(IPL_ENTRY_MAX_DESC_LEN - 1)
           xor  di,di
@@:        mov  al,es:[si]
           inc  si
           mov  [bx+di+IPL_ENTRY->description],al
           inc  di
           or   al,al
           jz   short add_boot_vector_no_str
           loop @b
           ; make sure it is zero terminated
           mov  byte [bx+di+IPL_ENTRY->description],0

add_boot_vector_no_str:
           inc  word [EBDA_DATA->ipl_table_count]
           clc
           ret
                
@@:        stc
           ret
add_boot_vector endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; find the first device that matches specified type
; On entry:
;  al = type (IPL_TYPE_*)
; On return:
;  carry = set if not found
;  ax = one based index of found entry
;  destroys none
find_boot_vector proc near uses bx cx dx ds
           
           mov  bx,EBDA_SEG
           mov  ds,bx
           
           mov  bx,EBDA_DATA->ipl_table_entries
           mov  cx,[EBDA_DATA->ipl_table_count]
           mov  dl,al
           xor  ax,ax
@@:        cmp  ax,cx
           jae  short find_boot_vector_done

           cmp  [bx+IPL_ENTRY->type],dl
           je   short @f

           add  bx,sizeof(IPL_ENTRY)
           inc  ax
           jmp  short @b
           
           ; one based
@@:        inc  ax
           clc
           ret
                
find_boot_vector_done:
           xor  ax,ax
           stc
           ret
find_boot_vector endp

press_f12_str     db  'Press F12 for boot menu, F10 for setup.',13,10,0
boot_option_str   db  'Boot options:',13,10,0
select_boot_opt   db  13,10,'Select boot device (A to %c): ',0
ipl_str0          db  ' %c: ',0
device_id_str     db  ' (Dev: %02X) ',0
boot_count_down_str      db  13,'Continue in %i seconds.  ',0
boot_count_down_str_crlf db 13,10,10,0

DRIVETYPES_LEN    equ  13  ; bytes each
drivetypes        dup  DRIVETYPES_LEN,0
                  db  'Floppy',0,0,0,0,0,0,0
                  db  'Hard Disk',0,0,0,0
                  db  'CD-Rom',0,0,0,0,0,0,0
                  db  'ATAPI Device',0
                  db  'USB Device',0,0,0
                  db  'Network',0,0,0,0,0,0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; delay and check for key stroke, displaying countdown
; on entry:
;  ax = ticks to delay (between checking for a key press)
;  cx = loop count (count of times to check for a key press)
;  ds = BIOS_BASE
; on return
;  nothing
; destroys nothing
delay_ticks_and_check_for_keystroke_str proc near uses ax cx si
@@:        push cx
           mov  si,offset boot_count_down_str
           call bios_printf
           add  sp,2
           call delay_ticks
           push ax
           call check_for_keystroke
           or   al,al
           pop  ax
           loopz @b
           mov  si,offset boot_count_down_str_crlf
           call bios_printf
           ret
delay_ticks_and_check_for_keystroke_str endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; give the user an opportunity to press F10/F12/etc.
; On entry:
;  es = 0x0000
;  ds = BIOS_BASE
; On return:
;  nothing
;  destroys all general
interactive_bootkey proc near uses es
           push bp
           mov  bp,sp

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; clear the keyboard buffer
@@:        call check_for_keystroke
           or   al,al
           jz   short @f
           call get_keystroke
           jmp  short @b
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if the user has indicated 'fastboot' in the cmos,
           ;  skip allowing them to press F12
@@:        mov  ah,0x3F
           call cmos_get_byte
           test al,1
           jz   short interactive_do

           ; we still have to check for F10 though
@@:        mov  ah,01
           int  16h
           jz   interactive_done
           xor  ah,ah
           int  16h
           cmp  ax,0x4400      ; F10
           jne  short @b
           call far offset bios_setup,BIOS_BASE2
           jmp  interactive_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if there are no entries, skip all of this
interactive_do:
           mov  ax,EBDA_SEG       ; es = EBDA_SEG
           mov  es,ax
           cmp  word es:[EBDA_DATA->ipl_table_count],0x00
           je   interactive_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; show the 'press f12' display
           mov  si,offset press_f12_str
           call display_string
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get the boot delay count from the escd
           mov  bx,ESCD_DATA->boot_delay
           mov  cx,sizeof(byte)
           call bios_read_escd
           ; al = seconds
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; delay for about (default = 3) seconds, monitoring a keystroke
           ; (18.2 times a second is 55mS a tick)
           ; (54.95mS * (18.2 / 2) * ('3' * 2)) = 3,000mS = 3.000 seconds
           movzx cx,al ; al=seconds ; loop count, count of checks for a key press
           shl  cx,1   ; x 2        ;
           jz   short @f            ; don't wait if count = 0
           mov  ax,9   ; (18.2 / 2) ; ticks between checking for a key press
           call delay_ticks_and_check_for_keystroke_str

           ; did we find a keystroke?
@@:        call check_for_keystroke
           or   al,al
           jz   interactive_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; process a keykeystroke
           call get_keystroke

           ; if it is F10, do our 'setup app'. we (usually) don't return
           cmp  ax,0x4400      ; F10
           jne  short @f
           call far offset bios_setup,BIOS_BASE2
           jmp  interactive_done

           ; if it is F12, allow the user to choose a boot option
@@:        cmp  ax,0x8600      ; F12
           jne  interactive_done
           
           ; clear the keyboard buffer
@@:        call check_for_keystroke
           or   al,al
           jz   short @f
           call get_keystroke
           jmp  short @b

@@:        mov  si,offset boot_option_str
           call display_string
           
           xor  cx,cx
           mov  bx,EBDA_DATA->ipl_table_entries
ipl_entry_loop:
           cmp  cx,es:[EBDA_DATA->ipl_table_count]
           jae  short ipl_entry_loop_done

           mov  si,offset ipl_str0
           mov  ax,cx
           add  al,'A'           ; we do A -> Z
           push ax               ;
           call bios_printf
           add  sp,2

           movzx ax,byte es:[bx+IPL_ENTRY->type]
           test al, 0x80
           jz   short @f
           mov  ax,IPL_TYPE_NET
@@:        imul si,ax,DRIVETYPES_LEN
           add  si,offset drivetypes
           call display_string

           movzx ax,byte es:[bx+IPL_ENTRY->device]
           push ax
           mov  si,offset device_id_str
           call bios_printf
           add  sp,2

           ; print a description, if present
           push cx
           lea  si,[bx+IPL_ENTRY->description]
           mov  cx,IPL_ENTRY_MAX_DESC_LEN
@@:        mov  al,es:[si]
           or   al,al
           jz   short @f
           call display_char
           inc  si
           loop @b

@@:        pop  cx
           mov  al,13
           call display_char
           mov  al,10
           call display_char

ipl_entry_loop_break:
           inc  cx
           add  bx,sizeof(IPL_ENTRY)
           jmp  short ipl_entry_loop

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; print message and process a keykeystroke
ipl_entry_loop_done:
           dec  cx
           mov  ax,cx
           add  al,'A'
           push ax
           mov  si,offset select_boot_opt
           call bios_printf
           add  sp,2

get_valid_keystroke:
           call get_keystroke
           cmp  ax,0x011B        ; escaped
           je   short valid_keystroke_done

           call display_char

           ; we assume that only a->z or A->Z have been pressed
           ; cx = last allowed char
           xor  ah,ah
           sub  al,'A'
           and  al,11011111b     ; convert lower-case to upper-case
           cmp  ax,cx
           jbe  short is_valid_keystroke
           mov  al,0x08          ; backspace (erase invalid key)
           call display_char
           jmp  short get_valid_keystroke

is_valid_keystroke:
           ; entry is one based
           inc  ax
           mov  es:[EBDA_DATA->ipl_bootfirst],ax

valid_keystroke_done:
           mov  al,13
           call display_char
           mov  al,10
           call display_char
           
interactive_done:
           mov  sp,bp
           pop  bp
           ret
interactive_bootkey endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; delay a number of ticks
; On entry:
;  ax = count of ticks to wait
; On return:
;  nothing
;  destroys none
delay_ticks proc near uses eax ebx ecx edx es
           
           pushf                 ; save current interupt flag
           mov  cx,0x40          ; es = 0x0040
           mov  es,cx
           sti                   ; ensure interrupts are firing

           movzx eax,ax          ; eax = ticks to wait
           mov  ecx,es:[0x006C]  ; get current value
delay_ticks_loop:
           hlt                   ; wait for interrupt (only increments on an interrupt)
           mov  edx,es:[0x006C]  ; get current value
           cmp  edx,ecx          ; if (cur > prev)
           jna  short @f         ;
           mov  ebx,edx
           sub  ebx,ecx          ;  num = num - (cur - prev)
           sub  eax,ebx          ;
           jmp  short delay_ticks_next
@@:        jnb  short delay_ticks_next ; wrapped around at midnight
           sub  eax,edx          ;  num = num - cur
delay_ticks_next:
           mov  ecx,edx          ; restore current
           cmp  eax,0            ; if num > 0, continue
           jg   short delay_ticks_loop
           popf                  ; restore the interrupt flag

           ret
delay_ticks endp

.end
