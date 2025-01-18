comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: sys_man.asm                                                        *
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
*   system management include file                                         *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.15                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 17 Jan 2025                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

; what version of the SYS MAN specs we support
; (must be at least 2.0 (0x0200))
; (2.4 = 0x0204, etc.)
SYSMAN_VER   equ  0x0204   ; 2.4

.if DO_INIT_BIOS32

.ifdef BX_QEMU
bx_vendor_str       db  'QEMU',0
.else
bx_vendor_str       db  'The Bochs Project',0
.endif
bx_version_str      db  BIOS_VERSION,0
bx_socket_dest_str  db  'CPU ?',0
bx_dimm_str         db  'DIMM ?',0

.if (SYSMAN_VER >= 0x0203)
bx_date_str         db  ___DATE___,0  ; mm/dd/yyyy
.else
bx_date_str         db  ___DATE__,0   ; mm/dd/yy
.endif


; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the SM BIOS
; on entry:
;  ds -> EBDA
; on return
;  nothing
; destroys none
smbios_init proc near uses alld

           mov  eax,[EBDA_DATA->bios_table_cur_addr]
           add  eax,15
           and  eax,(~15)
           mov  [EBDA_DATA->sm_config_table],eax
           mov  edi,eax

           ; skip over the entry point for now
           add  edi,32
           xor  esi,esi          ; used for max struct size
           xor  ebp,ebp          ; used for count of structurs
           
           call smbios_type_0_init
           call smbios_type_max_size
           call smbios_type_1_init
           call smbios_type_max_size
           call smbios_type_3_init
           call smbios_type_max_size

           mov  cx,[EBDA_DATA->smp_cpus]
           mov  bx,1
@@:        call smbios_type_4_init
           call smbios_type_max_size
           inc  bx
           loop @b

.if (SYSMAN_VER >= 0x0201)
           ; get RAM size in Megs
           ; (does not include anything above 4gig ?)
           mov  eax,[EBDA_DATA->mem_base_ram_size]
           shr  eax,20
           ; eax = ram size in megs
           mov  ecx,eax
           add  ecx,0x3FFF
           shr  ecx,14
           ; cx = number of 'devices'

           mov  edx,eax
           push eax
           call smbios_type_16_init
           call smbios_type_max_size
           pop  eax

           xor  bx,bx
@@:        push eax
           ; if this is not the last one, we send 0x4000
           ; if this is the last one, send (((eax - 1) & 0x3FFF) + 1)
           push bx
           mov  edx,0x4000   ; assume not last one
           inc  bx
           cmp  bx,cx
           jb   short mem_next
           mov  edx,eax
           dec  edx
           and  edx,0x3FFF
           inc  edx
mem_next:  pop  bx

           call smbios_type_17_init
           call smbios_type_max_size
           call smbios_type_19_init
           call smbios_type_max_size
           call smbios_type_20_init
           call smbios_type_max_size
           
           pop  eax
           inc  bx
           loop @b
.endif
           call smbios_type_32_init
           call smbios_type_max_size
           call smbios_type_127_init
           call smbios_type_max_size

           ; update pointer for next table entry
           mov  [EBDA_DATA->bios_table_cur_addr],edi
           sub  edi,[EBDA_DATA->sm_config_table]
           mov  eax,edi                  ; eax = length
           mov  [EBDA_DATA->sm_config_table_sz],ax
           
           ; initialize the entry point stuff
           mov  ecx,esi          ; ecx = max struct size
           mov  edi,[EBDA_DATA->sm_config_table]
           mov  esi,edi
           add  esi,32
           sub  eax,32  ; size of the entry point (entry - base)
           call smbios_entry_point_init

  ; writemem "C:\bochs\images\winxp\dd.bin" 0x000FAF70 293
  ;mov  eax,[EBDA_DATA->sm_config_table]
  ;mov  cx,[EBDA_DATA->sm_config_table_sz]
  ;xchg cx,cx

           ret
smbios_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a the entry point SM BIOS structure
; on entry:
;  ds -> EBDA
;  fs:edi->start of structure
;  cx = max struct size
;  eax = size of all type structures included
;  esi = pointer to the type structures (usually just passed this one)
;  ebp = count of structures added
; on return
;  fs:edi->byte after structure
; destroys none
smbios_entry_point_init proc near
           mov   word fs:[edi+0],'S_'  ; '_SM_' signature
           mov   word fs:[edi+2],'_M'  ;  (must do it in two words to break up the _SM_ so that an OS doesn't find the wrong _SM_)

           mov  byte  fs:[edi+4],0       ; checksum (patched later)
           mov  byte  fs:[edi+5],31
           mov  byte  fs:[edi+6],((SYSMAN_VER >> 8) & 0xFF)
           mov  byte  fs:[edi+7],(SYSMAN_VER & 0xFF)
           mov        fs:[edi+8],cx      ; max structure size
           mov  byte  fs:[edi+10],0      ; entry point revision
           
           ; formatted area
           mov  dword fs:[edi+11],0
           mov  byte  fs:[edi+15],0

           ; anchor string
           mov  dword fs:[edi+16],'IMD_' ; '_DMI_'
           mov  byte  fs:[edi+20],'_'

           mov  byte  fs:[edi+21],0      ; intermediate checksum (patched later)
           mov        fs:[edi+22],ax     ; size of table (not including this struct)
           mov        fs:[edi+24],esi    ; pointer to first structure
           mov        fs:[edi+28],bp     ; number of structures included
           
           ; entry point revision
           mov  byte  fs:[edi+30],(((SYSMAN_VER >> 4) & 0xF0) | (SYSMAN_VER & 0x0F))
           
           ; update the checksum
           mov  ax,16
           call calc_checksum
           mov  fs:[edi+4],al            ; checksum
           
           ; update the intermediate checksum
           push edi
           add  edi,16
           mov  ax,15
           call calc_checksum
           pop  edi
           mov  fs:[edi+21],al           ; intermediate checksum
           
           ret
smbios_entry_point_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; adjust max size of type variable
; on entry:
;  eax = size of last type created
;  esi = running current max size
;  ebp = running count of structures
; on return
;  esi = (new) running current max size
;  ebp = (new) running count of structures
; destroys none
smbios_type_max_size proc near
           cmp  eax,esi
           jbe  short @f
           mov  esi,eax
@@:        inc  ebp
           ret
smbios_type_max_size endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a type 0 SM BIOS structure
; on entry:
;  ds -> EBDA
;  fs:edi->start of structure
; on return
;  fs:edi->byte after structure
;  eax = size of this struct
; destroys none
smbios_type_0_init proc near uses esi
           
           ; save for size calculation of this type
           mov  esi,edi

           ; header
           mov  byte fs:[edi+0],0x00   ; type 0
           mov  byte fs:[edi+1],0      ; size of this structure (patched later)
           mov  word fs:[edi+2],0      ; handle

           ; type 0 structure
           mov  byte fs:[edi+4],1      ; string 1 is the vendor string
           mov  byte fs:[edi+5],2      ; string 2 is the version string
           mov  word fs:[edi+6],BIOS_BASE ; start of the bios
           mov  byte fs:[edi+8],3      ; string 3 is the date string
           mov  byte fs:[edi+9],(((0x10000 - BIOS_BASE) >> 12) - 1)
           mov  byte fs:[edi+10+0],((1 << 4) | \ ; ISA is supported
                                    (1 << 7))    ; PCI is supported
           mov  byte fs:[edi+10+1],((1 << 1) | \ ; Plug&Play is supported
                                    (1 << 2) | \ ; APM is supported
                                    (1 << 3) | \ ; BIOS is Upgradeable
                                    (1 << 4) | \ ; BIOS shadowing is allowed
                                    (1 << 7))    ; Boot from CD-ROM is allowed
           mov  byte fs:[edi+10+2],((1 << 0) | \ ; Selectable boot is supported
                                    (1 << 3) | \ ; EDD Specification is supported
                                    (1 << 6) | \ ; Int 13h - 5.25" / 360 KB Floppy Services
                                    (1 << 7))    ; Int 13h - 5.25" / 1.2 KB Floppy Services
           mov  byte fs:[edi+10+3],((1 << 0) | \ ; Int 13h - 3.5" / 720 KB Floppy Services
                                    (1 << 1) | \ ; Int 13h - 3.5" / 2.88 KB Floppy Services
                                    (1 << 3) | \ ; Int 9h, 8042 Keyboard Services
                                    (1 << 4) | \ ; Int 14h, Serial Services
                                    (1 << 5))    ; Int 17h - Printer Services
           mov  byte fs:[edi+10+4],0
           mov  byte fs:[edi+10+5],0
           mov  byte fs:[edi+10+6],0
           mov  byte fs:[edi+10+7],0
           mov  eax,18                          ; size so far
.if (SYSMAN_VER >= 0x0201)
           mov  byte fs:[edi+18+0],((1 << 0) | \ ; ACPI is supported
                                    (1 << 1))    ; USB legacy is supported
           mov  eax,19                          ; size so far
.endif
.if (SYSMAN_VER >= 0x0203)
           mov  byte fs:[edi+18+1],((1 << 0) | \ ; ACPI is supported
                                    (1 << 1))    ; USB legacy is supported
           mov  eax,20                          ; size so far
.endif
.if (SYSMAN_VER >= 0x0204)
           mov  byte fs:[edi+20],1              ; BIOS major release
           mov  byte fs:[edi+21],0              ; BIOS minor release
           mov  byte fs:[edi+22],0xFF           ; Controller major release
           mov  byte fs:[edi+23],0xFF           ; Controller minor release
           mov  eax,24                          ; size so far
.endif
.if (SYSMAN_VER >= 0x0301)
           mov  word fs:[edi+24],0x0000         ; extended size of physical device
           mov  eax,26                          ; size so far
.endif
           mov  fs:[edi+1],al     ; size of this structure
           add  edi,eax

           ; now for the strings
           push esi
           push ds
           push cs
           pop  ds

           ; vendor string (string 1)
           mov  si,offset bx_vendor_str
@@:        lodsb
           mov  fs:[edi],al
           inc  edi
           or   al,al
           jnz  short @b
           
           ; version string (string 2)
           mov  si,offset bx_version_str
@@:        lodsb
           mov  fs:[edi],al
           inc  edi
           or   al,al
           jnz  short @b
           
           ; date string (string 3)
           mov  si,offset bx_date_str
@@:        lodsb
           mov  fs:[edi],al
           inc  edi
           or   al,al
           jnz  short @b

           ; null terminator
           mov  byte fs:[edi],0
           inc  edi
           pop  ds
           pop  esi
           
           ; return size of this struct in eax
           mov  eax,edi
           sub  eax,esi
           
           ret
smbios_type_0_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a type 1 SM BIOS structure
; on entry:
;  ds -> EBDA
;  fs:edi->start of structure
; on return
;  fs:edi->byte after structure
;  eax = size of this struct
; destroys none
smbios_type_1_init proc near uses ecx esi
           
           ; header
           mov  byte fs:[edi+0],0x01   ; type 1
           mov  byte fs:[edi+1],0      ; size of this structure (patched later)
           mov  word fs:[edi+2],0x0100 ; handle

           ; type 1 structure
           mov  byte fs:[edi+4],0      ; no string attached
           mov  byte fs:[edi+5],0      ; no string attached
           mov  byte fs:[edi+6],0      ; no string attached
           mov  byte fs:[edi+7],0      ; no string attached
           mov  eax,8                  ; size so far

.if (SYSMAN_VER >= 0x0201)
           push edi
           add  edi,eax
           lea  si,[EBDA_DATA->bios_uuid]
           mov  cx,16
@@:        lodsb
           mov  fs:[edi],al
           inc  edi
           loop @b
           pop  edi

           mov  byte fs:[edi+24],0x06  ; wakeup type is power switch
           mov  eax,25                 ; size so far
.endif

.if (SYSMAN_VER >= 0x0204)
           mov  byte fs:[edi+25],0     ; no string attached
           mov  byte fs:[edi+26],0     ; no string attached
           mov  eax,27                 ; size so far
.endif
           
           mov  fs:[edi+1],al     ; size of this structure
           add  edi,eax

           ; null terminator
           mov  word fs:[edi],0
           add  edi,2
           add  eax,2
           
           ret
smbios_type_1_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a type 3 SM BIOS structure
; on entry:
;  ds -> EBDA
;  fs:edi->start of structure
; on return
;  fs:edi->byte after structure
;  eax = size of this struct
; destroys none
smbios_type_3_init proc near
           
           ; header
           mov  byte fs:[edi+0],0x03   ; type 3
           mov  byte fs:[edi+1],0      ; size of this structure (patched later)
           mov  word fs:[edi+2],0x0300 ; handle

           ; type 3 structure
           mov  byte fs:[edi+4],0      ; no string attached
           mov  byte fs:[edi+5],1      ; type = other
           mov  byte fs:[edi+6],0      ; no string attached
           mov  byte fs:[edi+7],0      ; no string attached
           mov  byte fs:[edi+8],0      ; no string attached
           mov  eax,9                  ; size so far

.if (SYSMAN_VER >= 0x0201)
           mov  byte fs:[edi+9],3      ; boot-up state (safe)
           mov  byte fs:[edi+10],3     ; power supply state (safe)
           mov  byte fs:[edi+11],3     ; thermal state (safe)
           mov  byte fs:[edi+12],2     ; security state (unknown)
           mov  eax,13                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0203)
           mov  dword fs:[edi+13],0    ; OEM defined
           mov  byte fs:[edi+17],0     ; height of enclosure
           mov  byte fs:[edi+18],0     ; number of power cords
           mov  byte fs:[edi+19],0     ; contained element count
           ; no elements follow
           mov  eax,20                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0207)
           mov  byte fs:[edi+20],0     ; sku string
           mov  byte fs:[edi+21],0     ; terminator
           mov  eax,22                 ; size so far
.endif
          
           mov  fs:[edi+1],al     ; size of this structure
           add  edi,eax
           
           ; null terminator
           mov  word fs:[edi],0
           add  edi,2
           add  eax,2
           
           ret
smbios_type_3_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a type 4 SM BIOS structure
; on entry:
;  ds -> EBDA
;  fs:edi->start of structure
;  bx = cpu number (1 based)
; on return
;  fs:edi->byte after structure
;  eax = size of this struct
; destroys none
smbios_type_4_init proc near uses ebx ecx esi
           
           ; save for size calculation of this type
           mov  esi,edi
           
           ; header
           mov  byte fs:[edi+0],0x04   ; type 4
           mov  byte fs:[edi+1],0      ; size of this structure (patched later)
           mov  word fs:[edi+2],0x0400 ; handle
           or        fs:[edi+2],bl

           ; type 4 structure
           mov  byte fs:[edi+4],1      ; socket destination string
           mov  byte fs:[edi+5],3      ; type = CPU
           mov  byte fs:[edi+6],1      ; processor family = other
           mov  byte fs:[edi+7],0      ; no string attached
           mov  eax,[EBDA_DATA->cpuid_signature]
           mov        fs:[edi+8],eax   ; processor id
           mov  eax,[EBDA_DATA->cpuid_features]
           mov        fs:[edi+12],eax
           mov  byte fs:[edi+16],0     ; no string attached
           mov  byte fs:[edi+17],0     ; voltage
           mov  word fs:[edi+18],0     ; external clock
           mov  word fs:[edi+20],0     ; max speed
           mov  word fs:[edi+22],0     ; cur speed
           mov  byte fs:[edi+24],0x41  ; status (socket, enabled)
           mov  byte fs:[edi+25],0x01  ; upgraged (unknown)
           mov  eax,26                 ; size so far

.if (SYSMAN_VER >= 0x0201)
           mov  word fs:[edi+26],0xFFFF ; cache 1 info not supported
           mov  word fs:[edi+28],0xFFFF ; cache 2 info not supported
           mov  word fs:[edi+30],0xFFFF ; cache 3 info not supported
           mov  eax,32                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0203)
           mov  byte fs:[edi+32],0     ; string not attached
           mov  byte fs:[edi+33],0     ; string not attached
           mov  byte fs:[edi+34],0     ; string not attached
           mov  eax,35                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0205)
           mov  byte fs:[edi+35],1     ; core count
           mov  byte fs:[edi+36],1     ; core enabled count
           mov  byte fs:[edi+37],1     ; thread count
           mov  word fs:[edi+38],0     ; processor characteristics  (*todo*)
           mov  eax,40                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0206)
           mov  word fs:[edi+40],11    ; processor family  (*todo*: will need to detect the processor. page 47 for type value)
           mov  eax,42                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0300)
           mov  word fs:[edi+42],1     ; core count (16-bit)
           mov  word fs:[edi+44],1     ; core enabled count (16-bit)
           mov  word fs:[edi+46],1     ; thread count (16-bit)
           mov  eax,48                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0306)
           mov  word fs:[edi+48],0     ; thread enabled (0 = unknown)
.endif

           mov  fs:[edi+1],al     ; size of this structure
           add  edi,eax

           ; now for the strings
           push esi
           push ds
           push cs
           pop  ds

           ; socket destination string (string 1)
           mov  ecx,edi
           mov  si,offset bx_socket_dest_str
@@:        lodsb
           mov  fs:[edi],al
           inc  edi
           or   al,al
           jnz  short @b

           ; *todo*: what if cpu num > 9
           ; put the CPU number in the string
           add  bl,'0'
           mov  fs:[ecx+4],bl
           
           ; null terminator
           mov  byte fs:[edi],0
           inc  edi
           pop  ds
           pop  esi
           
           ; return size of this struct in eax
           mov  eax,edi
           sub  eax,esi

           ret
smbios_type_4_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a type 16 SM BIOS structure
; on entry:
;  ds -> EBDA
;  fs:edi->start of structure
;  cx = count of 'mem devices' we have
;  edx = mem size in megs
; on return
;  fs:edi->byte after structure
;  eax = size of this struct
; destroys none
smbios_type_16_init proc near uses ecx edx
           
           ; header
           mov  byte fs:[edi+0],0x10   ; type 16
           mov  byte fs:[edi+1],0      ; size of this structure (patched later)
           mov  word fs:[edi+2],0x1000 ; handle

           ; type 16 structure
           mov  byte fs:[edi+4],3      ; location 3 = system board or mobo
           mov  byte fs:[edi+5],3      ; use = system memory
           mov  byte fs:[edi+6],1      ; error correction = other
           
           ; change memory size from bytes to kilobytes
           push eax
           mov  eax,edx
           xor  edx,edx
           shld edx,eax,10
           shl  eax,10
           mov  fs:[edi+7],eax         ; max capacity
           pop  eax
.if (SYSMAN_VER >= 0x0207)
           or   edx,edx
           jz   short @f
           mov  dword fs:[edi+7],0x80000000 ; (use extended field)
@@:
.endif
           mov  word fs:[edi+11],0xFFFE ; error info (none provided)
           mov       fs:[edi+13],cx
           mov  eax,15                 ; size so far

.if (SYSMAN_VER >= 0x0207)
           mov  fs:[edi+15+0],eax       ; lo number of Mbytes
           mov  fs:[edi+15+4],edx       ; high number of Mbytes
           mov  eax,23                 ; size so far
.endif
           
           mov  fs:[edi+1],al     ; size of this structure
           add  edi,eax

           ; null terminator
           mov  word fs:[edi],0
           add  edi,2
           add  eax,2
           
           ret
smbios_type_16_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a type 17 SM BIOS structure
; on entry:
;  ds -> EBDA
;  fs:edi->start of structure
;  bx = instance
;  edx = mem size in megs
; on return
;  fs:edi->byte after structure
;  eax = size of this struct
; destroys none
smbios_type_17_init proc near uses ebx ecx edx esi ebp
           
           ; save for size calculation of this type
           mov  ebp,edi
           
           ; header
           mov  byte fs:[edi+0],0x11   ; type 17
           mov  byte fs:[edi+1],0      ; size of this structure (patched later)
           mov  word fs:[edi+2],0x1100 ; handle (0x1100 = bx)
           or        fs:[edi+2],bl

           ; type 17 structure
           mov  word fs:[edi+4],0x1000 ; physical handle
           mov  word fs:[edi+6],0xFFFE ; error info (none provided)
           mov  word fs:[edi+8],64     ; total width
           mov  word fs:[edi+10],64    ; data width
           mov       fs:[edi+12],dx    ; megabytes                          ;;;;; 2 (dx = 0, we need it to be 2 ??????????) ;;;; ben * 3
           mov  byte fs:[edi+14],9     ; form factor (9 = dimm)
           mov  byte fs:[edi+15],0     ; device set
           mov  byte fs:[edi+16],1     ; string 1: device locator
           mov  byte fs:[edi+17],0     ; no string attached
           mov  byte fs:[edi+18],7     ; memory type (7 = ram)
           mov  word fs:[edi+19],0     ; type detail
           mov  eax,20                 ; size so far

.if (SYSMAN_VER >= 0x0203)
           mov  word fs:[edi+21],0     ; speed (0 = unknown)
           mov  byte fs:[edi+23],0     ; no string attached
           mov  byte fs:[edi+24],0     ; no string attached
           mov  byte fs:[edi+25],0     ; no string attached
           mov  byte fs:[edi+26],0     ; no string attached
           mov  eax,27                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0206)
           mov  byte fs:[edi+27],0     ; attributes
           mov  eax,28                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0207)
           mov       fs:[edi+28],edx   ; compliment offset 12
           mov  word fs:[edi+32],0     ; unknown speed
           mov  eax,34                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0208)
           mov  word fs:[edi+34],0     ; min voltage
           mov  word fs:[edi+36],0     ; max voltage
           mov  word fs:[edi+38],0     ; configured voltage
           mov  eax,40                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0302)
           mov  byte fs:[edi+40],3     ; mem tech (3 = DRAM)
           mov  word fs:[edi+41],2     ; operating mode (bit 1 = other)
           mov  byte fs:[edi+43],0     ; no string attached
           mov  word fs:[edi+44],0     ; manufacturer id
           mov  word fs:[edi+46],0     ; product id
           mov  word fs:[edi+48],0     ; subsystem manufacturer id
           mov  word fs:[edi+50],0     ; subsystem product id
           mov  dword fs:[edi+52+0],0  ; non volatile size in bytes
           mov  dword fs:[edi+56+4],0  ; 
           xor  esi,esi
           shld esi,edx,20
           shl  edx,20
           mov  fs:[edi+60+0],edx      ; volatile size in bytes
           mov  fs:[edi+60+4],esi      ; 
           mov  dword fs:[edi+68+0],0xFFFFFFFF
           mov  dword fs:[edi+68+4],0xFFFFFFFF
           mov  dword fs:[edi+76+0],0xFFFFFFFF
           mov  dword fs:[edi+76+4],0xFFFFFFFF
           mov  eax,84                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0303)
           mov  dword fs:[edi+84],0    ; extended speed
           mov  dword fs:[edi+88],0    ; extended speed
           mov  eax,92                 ; size so far
.endif
.if (SYSMAN_VER >= 0x0307)
           mov  word fs:[edi+92],0     ; PCIC0 manufacturer ID
           mov  word fs:[edi+94],0     ; PCIC0 revision
           mov  word fs:[edi+96],0     ; RCD manufacturer ID
           mov  word fs:[edi+98],0     ; RCD revision
           mov  eax,100                ; size so far
.endif
           
           mov  fs:[edi+1],al     ; size of this structure
           add  edi,eax

           ; now for the strings
           push ds
           push cs
           pop  ds

           ; dimm string (string 1)
           mov  ecx,edi
           mov  si,offset bx_dimm_str
@@:        lodsb
           mov  fs:[edi],al
           inc  edi
           or   al,al
           jnz  short @b

           ; put the number in the string
           add  bl,'0'
           mov  fs:[ecx+5],bl
           
           ; null terminator
           mov  byte fs:[edi],0
           inc  edi
           pop  ds

           ; return size of this struct in eax
           mov  eax,edi
           sub  eax,ebp

           ret
smbios_type_17_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a type 19 SM BIOS structure
; on entry:
;  ds -> EBDA
;  fs:edi->start of structure
;  bx = instance
;  edx = mem size in megs
; on return
;  fs:edi->byte after structure
;  eax = size of this struct
; destroys none
smbios_type_19_init proc near uses ebx ecx edx
           
           ; header
           mov  byte fs:[edi+0],0x13   ; type 19
           mov  byte fs:[edi+1],0      ; size of this structure (patched later)
           mov  word fs:[edi+2],0x1300 ; handle
           or        fs:[edi+2],bl

           ; type 19 structure
           movzx eax,bx
           shl  eax,24
           mov       fs:[edi+4],eax
           shl  edx,10
           dec  edx
           add  eax,edx
           mov       fs:[edi+8],eax
           mov  word fs:[edi+12],0x1000
           mov  byte fs:[edi+14],1
           mov  eax,15                 ; size so far
.if (SYSMAN_VER >= 0x0207)
           mov  dword fs:[edi+15+0],0   ; extended start
           mov  dword fs:[edi+15+4],0   ; 
           mov  dword fs:[edi+23+0],0   ; extended ending
           mov  dword fs:[edi+23+4],0   ; 
           mov  eax,31                 ; size so far
.endif
           
           mov  fs:[edi+1],al     ; size of this structure
           add  edi,eax

           ; null terminator
           mov  word fs:[edi],0
           add  edi,2
           add  eax,2
           
           ret
smbios_type_19_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a type 20 SM BIOS structure
; on entry:
;  ds -> EBDA
;  fs:edi->start of structure
;  bx = instance
;  edx = mem size in megs
; on return
;  fs:edi->byte after structure
;  eax = size of this struct
; destroys none
smbios_type_20_init proc near uses ebx ecx edx
           
           ; header
           mov  byte fs:[edi+0],0x14   ; type 20
           mov  byte fs:[edi+1],0      ; size of this structure (patched later)
           mov  word fs:[edi+2],0x1400 ; handle
           or        fs:[edi+2],bl

           ; type 20 structure
           movzx eax,bx
           shl  eax,24
           mov       fs:[edi+4],eax
           shl  edx,10
           dec  edx
           add  eax,edx
           mov       fs:[edi+8],eax
           mov  word fs:[edi+12],0x1100
           or        fs:[edi+12],bl
           mov  word fs:[edi+14],0x1300
           or        fs:[edi+14],bl
           mov  byte fs:[edi+16],1
           mov  byte fs:[edi+17],0
           mov  byte fs:[edi+18],0
           mov  eax,19                 ; size so far
.if (SYSMAN_VER >= 0x0207)
           mov  dword fs:[edi+19+0],0   ; extended start
           mov  dword fs:[edi+19+4],0   ; 
           mov  dword fs:[edi+27+0],0   ; extended ending
           mov  dword fs:[edi+27+4],0   ; 
           mov  eax,35                 ; size so far
.endif
           
           mov  fs:[edi+1],al     ; size of this structure
           add  edi,eax

           ; null terminator
           mov  word fs:[edi],0
           add  edi,2
           add  eax,2
           
           ret
smbios_type_20_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a type 32 SM BIOS structure
; on entry:
;  ds -> EBDA
;  fs:edi->start of structure
; on return
;  fs:edi->byte after structure
;  eax = size of this struct
; destroys none
smbios_type_32_init proc near uses ebx ecx edx
           
           ; header
           mov  byte fs:[edi+0],0x20   ; type 32
           mov  byte fs:[edi+1],0      ; size of this structure (patched later)
           mov  word fs:[edi+2],0x2000 ; handle

           ; type 32 structure
           mov  dword fs:[edi+4],0
           mov  word  fs:[edi+8],0
           mov  byte  fs:[edi+10],0    ; no errors detected
           mov  eax,11                 ; size so far
           
           mov  fs:[edi+1],al     ; size of this structure
           add  edi,eax

           ; null terminator
           mov  word fs:[edi],0
           add  edi,2
           add  eax,2
           
           ret
smbios_type_32_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a type 127 SM BIOS structure (ending marker)
; on entry:
;  ds -> EBDA
;  fs:edi->start of structure
; on return
;  fs:edi->byte after structure
;  eax = size of this struct
; destroys none
smbios_type_127_init proc near
           
           ; header
           mov  byte fs:[edi+0],0x7F   ; type 127
           mov  byte fs:[edi+1],4      ; size of this structure
           mov  word fs:[edi+2],0x7F00 ; handle
           
           mov  eax,4
           add  edi,eax

           ; null terminator
           mov  word fs:[edi],0
           add  edi,2
           add  eax,2
           
           ret
smbios_type_127_init endp


.endif  ; DO_INIT_BIOS32

.end
