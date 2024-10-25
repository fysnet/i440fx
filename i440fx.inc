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
*   main include file                                                      *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.08                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 25 Oct 2024                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|
; our bios version (in ascii format)
BIOS_VERSION      equ  '1.00.00'

; our base for this bios
BIOS_BASE         equ  0xE000
BIOS_BASE2        equ  0xF000

; set to 1 to add debug code
DO_DEBUG          equ  0
DO_SERIAL_DEBUG   equ  1

; set to 1 to do the pci32/smp/acpi/etc bios setup
; (setting to 0 is more like the 'legacy' bios)
; (setting to 1 is more like the 'latest' bios)
DO_INIT_BIOS32    equ  1

; if 1, send chars to debug ports
BX_VIRTUAL_PORTS  equ  (1 | DO_DEBUG)
BX_INFO_PORT      equ  0x402
BX_DEBUG_PORT     equ  0x403

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; EBDA area and sizes
EBDA_SIZE              equ       4  ; in 1k's            ; 1k size points to 0x9FC0
EBDA_SEG               equ  (0xA000 - (EBDA_SIZE << 6))  ; 2k size points to 0x9F80
BASE_MEM_IN_K          equ  (640 - EBDA_SIZE)            ; 3k size points to 0x9F40
                                                         ; 4k size points to 0x9F00
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Port List
PORT_DMA_ADDR_2        equ  0x0004
PORT_DMA_CNT_2         equ  0x0005
PORT_DMA1_MASK_REG     equ  0x000A
PORT_DMA1_MODE_REG     equ  0x000B
PORT_DMA1_CLEAR_FF_REG equ  0x000C
PORT_DMA1_MASTER_CLEAR equ  0x000D
PORT_PIC_MASTER_CMD    equ  0x0020
PORT_PIC_MASTER_DATA   equ  0x0021
PORT_PIT_CHANNEL0      equ  0x0040
PORT_PIT_CHANNEL1      equ  0x0041
PORT_PIT_CHANNEL2      equ  0x0042
PORT_PIT_MODE          equ  0x0043
PORT_PS2_DATA          equ  0x0060
PORT_PS2_CTRLB         equ  0x0061
PORT_PS2_STATUS        equ  0x0064
PORT_DIAG              equ  0x0080
PORT_DMA_PAGE_2        equ  0x0081
PORT_A20               equ  0x0092
PORT_PIC_SLAVE_CMD     equ  0x00A0
PORT_PIC_SLAVE_DATA    equ  0x00A1
PORT_DMA2_MASK_REG     equ  0x00D4
PORT_DMA2_MODE_REG     equ  0x00D6
PORT_DMA2_MASTER_CLEAR equ  0x00DA
PORT_ATA2_CMD_BASE     equ  0x0170
PORT_ATA1_CMD_BASE     equ  0x01F0
PORT_FD_DOR            equ  0x03F2
PORT_FD_STATUS         equ  0x03F4
PORT_FD_DATA           equ  0x03F5

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; BIOS Boot Specification stuff:
IPL_BOOT_FIRST_NONE    equ  0x00FF
IPL_TABLE_ENTRY_CNT    equ  16        ; maximum count of entries allowed
IPL_ENTRY_MAX_DESC_LEN equ  16
; entry types 
IPL_TYPE_FLOPPY       equ  0x01       ; BIOS Spec compliant type number 1
IPL_TYPE_HARDDISK     equ  0x02       ; BIOS Spec compliant type number 2
IPL_TYPE_CDROM        equ  0x03       ; BIOS Spec compliant type number 3
IPL_TYPE_PCMCIA       equ  0x04       ; BIOS Spec compliant type number 4
IPL_TYPE_USB          equ  0x05       ; BIOS Spec compliant type number 5
IPL_TYPE_BEV          equ  0x80       ; BIOS Spec compliant type number 128

IPL_FLAGS_NSATA       equ  (0 << 0)   ; not SATA hard drive (any device that is not an SATA device)
IPL_FLAGS_SATA        equ  (1 << 0)   ; is SATA device

; (the format here are not BIOS Boot Specification compliant)
; (If the caller calls PNP/BIOS Boot Spec serivce 0x62, we will build the IPL table on the fly)
IPL_ENTRY  struct
  type                  byte         ; type of device
  device                byte         ; device value to use to read/write using bios services
  vector                dword        ; if rom device, this is seg:offset to call for services
  base_lba              dword        ; emulated base LBA (lba from start of media to emulated image)
  description           dup  IPL_ENTRY_MAX_DESC_LEN  ; character description of the device
  flags                 word         ; flags: see IPL_FLAGS_* above
  reserved              dup  4       ; not used
IPL_ENTRY  ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; USB Device
USB_DEVICE_MAX          equ  4             ; max devices supported per controller

USB_MSD_MEDIA_FLOPPY     equ  0
USB_MSD_MEDIA_HARDDRIVE  equ  1
USB_MSD_MEDIA_CDROM      equ  2

; these values are combined with the 'usb_disk_emulated_drive' value
; zero based controller type in bits 7:6  (CC)
; zero based controller index in bits 5:4 (II)
; zero based device number in bits 3:0    (DDDD)
;                            CCIIDDDD
USB_CONTROLLER_UHCI     equ  00000000b
USB_CONTROLLER_OHCI     equ  01000000b
USB_CONTROLLER_EHCI     equ  10000000b
USB_CONTROLLER_xHCI     equ  11000000b

; 4 bytes
USB_DEVICE_EP struct
  ep_val           byte              ; endpoint value (0x01, 0x02, etc)
  ep_toggle        byte              ; current toggle
  ep_mps           word              ; endpoints max packet size
  ep_interval      byte              ; interval (usually 0x00)
  ep_max_burst     byte              ; xhci: max burst (usually 0x0F)
USB_DEVICE_EP ends

; this is a structure that all present devices get. It holds information
;  about the device, its buffers, etc.
; 4096 bytes
USB_DEVICE struct
  device_num       byte              ; zero based device index on this controller
  port             byte              ; port (0, 1, etc)
  speed            byte              ; speed (0 = fs, 1 = ls, 2 = hs, 3 = ss)
  mps              word              ; max packet size (ep 0)
  dev_addr         byte              ; device address (port + 1)
  protocol         byte              ; BBB / CBI / UASP
  controller       byte              ; type of controller
  bios_addr        byte              ; the address we give it for BIOS use
  endpoint_in      dup (sizeof(USB_DEVICE_EP))  ; IN endpoint
  endpoint_out     dup (sizeof(USB_DEVICE_EP))  ; OUT endpoint
  org_media        byte              ; type of device before emulation
  cyls             word              ; emulated number of cyls
  heads            byte              ; emulated number of heads
  spt              byte              ; emulated number of spt
  media            byte              ; emulated media type
  boot_dl          byte              ; emulated BIOS DL number
  block_size       word              ; size of a sector
  sectors          qword             ; count of sectors
  base_lba         qword             ; base lba of (emulated) image

  request          dup 8
  cbw              dup 31
  filler1          byte
  csw              dup 13
  filler2          dup 3
  next_tag         dword
  event_status     qword

  reserved         dup 628

  xhci_protocol    byte              ; xhci: protocol of the port (XHCI_USB2 or XHCI_USB3)
  slot_id          byte              ; xhci: slot id for this device
  slot_context     dup 24            ; xhci: sizeof(xHCI_SLOT_CONTEXT)
  ep_contexts      dup (40 * 32)     ; xhci: sizeof(xHCI_EP_CONTEXT) * 32

  rxtx_buffer      dup 2048
USB_DEVICE ends

.if (sizeof(USB_DEVICE) != 4096)
%ERROR 1 'USB_DEVICE != 4096 bytes'
%print sizeof(USB_DEVICE)
.endif

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
MAX_USB_CONTROLLERS  equ  4         ; we allow up to 4 controllers of each type
                                    ; (with ehci, there will be 1 UHCI plus 3 UHCI/OHCI controllers)
; 100 bytes
USB_CONTROLLER struct
  valid            byte             ; is this information valid?
  busdevfunc       word             ; bus dev/func
  base             dword            ; base IO address (Port IO or Memmapped)
  irq              byte             ; irq
  numports         byte             ; number of root hub ports on this controller
  base_memory      dword            ; base of our allocated memory (xhci: is extended caps instead)
  callback_bulk    word             ; BIOS_SEG:offset of callback routine for bulk transfers
  callback_control word             ; BIOS_SEG:offset of callback routine for control transfers
  op_reg_offset    byte             ; xhci & ehci: op register set offset
  context_size     byte             ; xhci: context size (32 or 64)
  flags            byte             ; xhci: bit 0 = use 64-bit addresses (remaining are reserved)
  page_size        word             ; xhci: page_size
  max_slots        byte             ; xhci: max slots
  slots_buffer     dword            ; xhci: physical address of the slots buffers
  command_ring     dup 12           ; xhci: command ring (struct xHCI_RING)
  event_ring       dup 20           ; xhci: event ring (struct xHCI_EVENT_RING)
  dcbaap_addr      dword            ; xhci: dcbaap address
  reserved         dup 20
  device_cnt       byte             ; count of devices found on this controller
  device_data      dup (sizeof(dword) * USB_DEVICE_MAX)
USB_CONTROLLER ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
MAX_SATA_CONTROLLERS  equ  2        ; we allow up to 2 controllers (no more than 4)
MAX_PRDT_ENTRIES      equ  8        ; we allow up to 8 PRDT entries per command slot (this aligns the next entry for us)
SATA_DEVICE_MAX       equ  4        ; four drives per SATA controller (no more than 16)

; 16 bytes
SATA_PRDT_ENTRY    struct
  dba              dword
  dbau             dword
  reserved         dword
  dword3           dword
SATA_PRDT_ENTRY    ends

; 256 bytes
SATA_COMMAND_TABLE struct
  cfis             dup 64
  acmd             dup 16
  reserved         dup 48
  prdt_entries     dup (MAX_PRDT_ENTRIES * sizeof(SATA_PRDT_ENTRY))
SATA_COMMAND_TABLE ends

; 12,288 bytes
SATA_DEVICE struct
  ; the following three items must remain first and in this order
  command_list     dup 1024         ; command list buffer (32 * sizeof(HBA_CMD_LIST))
  command_table    dup (32 * sizeof(SATA_COMMAND_TABLE)) ; command table
  recv_fis         dup 256
  rxtx_buffer      dup 2048         ; temp buffer for transfers
  device_num       byte             ; zero based device index on this controller
  port             byte             ; port (0, 1, etc)
  device_sig       dword            ; device signature (type) SATA_SIG_ATA or SATA_SIG_ATAPI
  blk_size         word             ; bytes per sector
  cylinders        word             ; count of cylinders
  heads            word             ; count of heads
  spt              word             ; count of sectors per track
  sectors_low      dword            ; count of sectors (low dword)
  sectors_high     dword            ; count of sectors (high dword)
  reserved         dup 746
SATA_DEVICE ends

.if (sizeof(SATA_DEVICE) != 12288)
  %error 1 "SATA_DEVICE table abnormal size"
  %print sizeof(SATA_DEVICE)
.endif

; 100 bytes
SATA_CONTROLLER struct
  valid            byte             ; is this information valid?
  busdevfunc       word             ; bus dev/func
  base             dword            ; base IO address (Memmapped)
  irq              byte             ; irq
  numports         byte             ; number of ports on this controller
  command_slots    byte             ; number command slots
  numdrives        byte             ; number of drives on this controller
  version          dword            ; controller version
  ;base_memory      dword            ; base of our allocated memory (xhci: is extended caps instead)
  ;callback_bulk    word             ; BIOS_SEG:offset of callback routine for bulk transfers
  ;callback_control word             ; BIOS_SEG:offset of callback routine for control transfers
  ;op_reg_offset    byte             ; xhci & ehci: op register set offset
  ;context_size     byte             ; xhci: context size (32 or 64)
  ;flags            byte             ; xhci: bit 0 = use 64-bit addresses (remaining are reserved)
  ;page_size        word             ; xhci: page_size
  ;max_slots        byte             ; xhci: max slots
  ;slots_buffer     dword            ; xhci: physical address of the slots buffers
  ;command_ring     dup 12           ; xhci: command ring (struct xHCI_RING)
  ;event_ring       dup 20           ; xhci: event ring (struct xHCI_EVENT_RING)
  ;dcbaap_addr      dword            ; xhci: dcbaap address
  reserved         dup 69
  ;device_cnt       byte             ; count of devices found on this controller
  device_data      dup (sizeof(dword) * SATA_DEVICE_MAX)
SATA_CONTROLLER ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; E820 style memory table
E820_RAM       equ   1
E820_RESERVED  equ   2
E820_ACPI      equ   3
E820_NVS       equ   4
E820_UNUSABLE  equ   5

MEM_TABLE_ENTRIES     equ  20
BIOS_EXT_MEMORY_USE   equ  (65536 * 4)

ACPI_DATA_SIZE    equ  0x00010000    ; 64k (65536)

BX_MAX_ATA_INTERFACES  equ  4
BX_MAX_ATA_DEVICES     equ  8

MEM_TABLE  struct
  mem_base              qword
  mem_size              qword
  mem_type              dword
MEM_TABLE  ends

PM_IO_BASE            equ  0xB000
SMB_IO_BASE           equ  0xB100
AP_BOOT_ADDR_SZ       equ  0x100   ; must be a multiple of 0x10
AP_BOOT_ADDR          equ  ((EBDA_SEG << 4) - AP_BOOT_ADDR_SZ)

APIC_BASE_ADDR        equ  0xFEE00000
APIC_REG_SEL          equ  0x000
APIC_REG_DATA         equ  0x010
APIC_REG_ID           equ  0x020
APIC_REG_VER          equ  0x030
APIC_REG_TRP          equ  0x080
APIC_REG_EOI          equ  0x0B0
APIC_REG_LDR          equ  0x0D0
APIC_REG_DFR          equ  0x0E0
APIC_REG_SIV          equ  0x0F0
APIC_REG_ICR          equ  0x300
APIC_REG_TIMER        equ  0x320
APIC_REG_THERM        equ  0x330
APIC_REG_PERFORM      equ  0x340
APIC_REG_LINT0        equ  0x350
APIC_REG_LINT1        equ  0x360
APIC_REG_LERROR       equ  0x370

IOAPIC_BASE_ADDR      equ  0xFEC00000
IOAPIC_REG_ID         equ  0x000
IOAPIC_REG_VER        equ  0x001
IOAPIC_REG_ARB        equ  0x002
IOAPIC_REG_REDIR      equ  0x010  ; first indirect table register (0x10 and 0x11)
                        ;  0x012  ; second indirect table register (0x12 and 0x13)
                        ;  ....

; each service call pushes the registers onto the stack with pusha
; we can then access them via [bp+regoffset]
; (we compensate for pushing bp first)
;   flags    cs      ip      es      ds
;  [bp+44] [bp+42] [bp+40] [bp+38] [bp+36]
;    edi     esi     ebp     esp     ebx     edx     ecx     eax
;  [bp+04] [bp+08] [bp+12] [bp+16] [bp+20] [bp+24] [bp+28] [bp+32]
REG_FLAGS equ  [bp+44]
REG_CS    equ  [bp+42]
REG_IP    equ  [bp+40]
REG_ES    equ  [bp+38]
REG_DS    equ  [bp+36]
REG_EAX   equ  [bp+32]
REG_AX    equ  [bp+32]
REG_AL    equ  [bp+32]
REG_AH    equ  [bp+33]
REG_ECX   equ  [bp+28]
REG_CX    equ  [bp+28]
REG_CL    equ  [bp+28]
REG_CH    equ  [bp+29]
REG_EDX   equ  [bp+24]
REG_DX    equ  [bp+24]
REG_DL    equ  [bp+24]
REG_DH    equ  [bp+25]
REG_EBX   equ  [bp+20]
REG_BX    equ  [bp+20]
REG_BL    equ  [bp+20]
REG_BH    equ  [bp+21]
REG_ESP   equ  [bp+16]
REG_SP    equ  [bp+16]
REG_EBP   equ  [bp+12]
REG_BP    equ  [bp+12]
REG_ESI   equ  [bp+08]
REG_SI    equ  [bp+08]
REG_EDI   equ  [bp+04]
REG_DI    equ  [bp+04]

.end
