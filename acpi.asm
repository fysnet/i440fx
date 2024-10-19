comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: acpi.asm                                                           *
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
*   acpi include file                                                      *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.08                                         *
*          Command line: nbasm i44fx /z<enter>                             *
*                                                                          *
* Last Updated: 19 Oct 2024                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

.if DO_INIT_BIOS32

acpi_tables_str   db  'ACPI tables: RSDP addr = 0x%08lX, RSDT addr = 0x%08lX, size = %u',13,10,0

SMI_CMD_IO_ADDR   equ  0xB2

RSDP_TABLE        struct
  signature              dup 8  ; ACPI signature, contains 'RSD PTR '
  checksum               byte   ; checksum
  oem_id                 dup 6  ; OEM identification
  revision               byte   ; Must be 0 for 1.0, 2 for 2.0
  rsdt_physical_address  dword  ; 32-bit physical address of RSDT
  length                 dword  ; XSDT Length in bytes including hdr
  xsdt_physical_address  qword  ; 64-bit physical address of XSDT
  extended_checksum      byte   ; Checksum of entire table
  reserved               dup 3  ; Reserved field must be 0
RSDP_TABLE        ends

ACPI_TABLE_HEADER struct
  signature        dup 4     ; ACPI signature
  length           dword     ; length of table (including this header)
  revision         byte      ; ACPI specification minor version
  checksum         byte      ; checksum of table
  oem_id           dup 6     ; OEM id
  oem_table_id     dup 8     ; OEM table id
  oem_revision     dword     ; OEM revision number
  creator_id       dword     ; ASL compiler ID
  creator_rev      dword     ; ASL compiler revision
ACPI_TABLE_HEADER ends

FADT_TABLE        struct
  header             dup  sizeof(ACPI_TABLE_HEADER)
  firmware_ctrl      dword   ; Physical address of FACS
  dsdt               dword   ; Physical address of DSDT
  model              byte    ; System Interrupt Model
  reserved1          byte    ; Reserved
  sci_int            word    ; System vector of SCI interrupt
  smi_cmd            dword   ; Port address of SMI command port
  acpi_enable        byte    ; Value to write to smi_cmd to enable ACPI
  acpi_disable       byte    ; Value to write to smi_cmd to disable ACPI
  S4bios_req         byte    ; Value to write to SMI CMD to enter S4BIOS state
  reserved2          byte    ; Reserved - must be zero
  pm1a_evt_blk       dword   ; Port address of Power Mgt 1a acpi_event Reg Blk
  pm1b_evt_blk       dword   ; Port address of Power Mgt 1b acpi_event Reg Blk
  pm1a_cnt_blk       dword   ; Port address of Power Mgt 1a Control Reg Blk
  pm1b_cnt_blk       dword   ; Port address of Power Mgt 1b Control Reg Blk
  pm2_cnt_blk        dword   ; Port address of Power Mgt 2 Control Reg Blk
  pm_tmr_blk         dword   ; Port address of Power Mgt Timer Ctrl Reg Blk
  gpe0_blk           dword   ; Port addr of General Purpose acpi_event 0 Reg Blk
  gpe1_blk           dword   ; Port addr of General Purpose acpi_event 1 Reg Blk
  pm1_evt_len        byte    ; Byte length of ports at pm1_x_evt_blk
  pm1_cnt_len        byte    ; Byte length of ports at pm1_x_cnt_blk
  pm2_cnt_len        byte    ; Byte Length of ports at pm2_cnt_blk
  pm_tmr_len         byte    ; Byte Length of ports at pm_tm_blk
  gpe0_blk_len       byte    ; Byte Length of ports at gpe0_blk
  gpe1_blk_len       byte    ; Byte Length of ports at gpe1_blk
  gpe1_base          byte    ; Offset in gpe model where gpe1 events start
  reserved3          byte    ; Reserved
  plvl2_lat          word    ; Worst case HW latency to enter/exit C2 state
  plvl3_lat          word    ; Worst case HW latency to enter/exit C3 state
  flush_size         word    ; Size of area read to flush caches
  flush_stride       word    ; Stride used in flushing caches
  duty_offset        byte    ; Bit location of duty cycle field in p_cnt reg
  duty_width         byte    ; Bit width of duty cycle field in p_cnt reg
  day_alarm          byte    ; Index to day-of-month alarm in RTC CMOS RAM
  mon_alarm          byte    ; Index to month-of-year alarm in RTC CMOS RAM
  century            byte    ; Index to century in RTC CMOS RAM
  reserved4          byte    ; Reserved
  reserved5          byte    ; Reserved
  reserved6          byte    ; Reserved
  flags              dword   ; flags
FADT_TABLE        ends

; ACPI 1.0 Firmware ACPI Control Structure (FACS)
FACS_TABLE        struct
  signature          dup 4   ; ACPI Signature
	length             dword   ; Length of structure, in bytes
	hardware_signature dword   ; Hardware configuration signature
	fw_wake_vector     dword   ; ACPI OS waking vector
	global_lock        dword   ; Global Lock
	S4bios_f           dword   ; bit 0 = Indicates if S4BIOS support is present
	resverved          dup 40  ; Reserved - must be zero
FACS_TABLE        ends

APIC_PROCESSOR          equ  0
APIC_IO                 equ  1
APIC_XRUPT_OVERRIDE     equ  2
APIC_NMI                equ  3
APIC_LOCAL_NMI          equ  4
APIC_ADDRESS_OVERRIDE   equ  5
APIC_IO_SAPIC           equ  6
APIC_LOCAL_SAPIC        equ  7
APIC_XRUPT_SOURCE       equ  8
APIC_RESERVED           equ  9

MADT_TABLE        struct
  header             dup  sizeof(ACPI_TABLE_HEADER)
  local_apic_addr    dword   ; Physical address of local APIC
  flags              dword   ; flags
MADT_TABLE        ends

MADT_PROC_TABLE   struct
  hdr_type           byte    ;
  hdr_length         byte    ;
  processor_id       byte    ; processor id
  local_apic_id      byte    ; local apic id
  flags              dword   ; flags
MADT_PROC_TABLE   ends

MADT_IO_APIC      struct
  hdr_type           byte    ;
  hdr_length         byte    ;
  io_apic_id         byte    ; IO APIC id
  reserved           byte    ; reserved
  address            dword   ; APIC physical address
  interrupt          dword   ; global system interrupt (GSI)
MADT_IO_APIC      ends

MADT_INT_OVERRIDE struct
  hdr_type           byte    ;
  hdr_length         byte    ;
  bus                byte    ; identifies the bus
  source             byte    ; bus relative interrupt source
  gsi                dword   ; GSI that source will signal
  flags              word    ; flags
MADT_INT_OVERRIDE ends

HPET_PHYS_ADDRESS    equ  0xFED00000

MADT_HPET         struct
  header             dup  sizeof(ACPI_TABLE_HEADER)
  timer_block_id     dword   ; 
   address_space_id      byte
   register_bit_width    byte
   register_bit_offset   byte
   reserved              byte
   phys_address          qword
  hpet_number        byte    ; 
  min_tick           word    ; 
  page_protect       byte    ; 
MADT_HPET         ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the acpi tables
; on entry:
;  ds -> EBDA
; on return
;  nothing
; destroys none
acpi_bios_init proc near uses alld ds
           
           ; if not enabled, don't initialize it
           mov  al,[EBDA_DATA->acpi_enabled]
           jz   acpi_bios_init_done

           ; we have to have at least 1Meg of RAM
           mov  edx,[EBDA_DATA->mem_base_ram_size]
           cmp  edx,(0x00100000 + ACPI_DATA_SIZE)
           jb   acpi_bios_init_done

           ; get next buffer space
           mov  eax,[EBDA_DATA->bios_table_cur_addr]
           add  eax,15 
           and  eax,(~15)
           mov  [EBDA_DATA->rsdp_table],eax
           ; update pointer for next table entry
           add  eax,sizeof(RSDP_TABLE)
           mov  [EBDA_DATA->bios_table_cur_addr],eax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; edx = mem_base_ram_size
           sub  edx,ACPI_DATA_SIZE
           and  edx,0xFFFFF000  ; must be 4k aligned
           mov  [EBDA_DATA->acpi_base_address],edx

           ; rsdt address
           mov  [EBDA_DATA->rsdt_addr],edx
           add  edx,(sizeof(ACPI_TABLE_HEADER) + (sizeof(dword) * 4))

           ; fadt address
           add  edx,7         ; align on an 8-byte boundary
           and  edx,(~7)
           mov  [EBDA_DATA->fadt_addr],edx
           add  edx,sizeof(FADT_TABLE)

           ; facs (must be 64-byte aligned)
           add  edx,63
           and  edx,(~0x3F)
           mov  [EBDA_DATA->facs_addr],edx
           add  edx,sizeof(FACS_TABLE)

           ; dsdt address
           add  edx,7         ; align on an 8-byte boundary
           and  edx,(~7)
           mov  [EBDA_DATA->dsdt_addr],edx
           mov  eax,offset acpi_dsdt_end
           sub  eax,offset acpi_dsdt_start
           mov  [EBDA_DATA->dsdt_addr_sz],ax
           add  edx,eax

           ; ssdt address
           add  edx,7         ; align on an 8-byte boundary
           and  edx,(~7)
           mov  [EBDA_DATA->ssdt_addr],edx
           mov  edi,edx
           call acpi_build_ssdt
           mov  [EBDA_DATA->ssdt_addr_sz],ax
           add  edx,eax

           ; madt
           add  edx,7         ; align on an 8-byte boundary
           and  edx,(~7)
           mov  [EBDA_DATA->madt_addr],edx
           mov  eax,sizeof(MADT_PROC_TABLE)
           imul ax,[EBDA_DATA->smp_cpus]
           add  ax,(sizeof(MADT_TABLE) + sizeof(MADT_IO_APIC) + sizeof(MADT_INT_OVERRIDE))
           mov  [EBDA_DATA->madt_addr_sz],ax
           add  edx,eax

           ; hpet address
           add  edx,7         ; align on an 8-byte boundary
           and  edx,(~7)
           mov  [EBDA_DATA->hpet_addr],edx
           add  edx,sizeof(MADT_HPET)

           ; calculate size of these tables
           ; (must be <= 64k)
           mov  eax,edx
           sub  eax,[EBDA_DATA->acpi_base_address]
           mov  [EBDA_DATA->acpi_tables_size],ax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; print the info (to the log file. The video hasn't been initialized yet)
           push ds
           mov  si,offset acpi_tables_str
           push word [EBDA_DATA->acpi_tables_size]
           push dword [EBDA_DATA->acpi_base_address]
           push dword [EBDA_DATA->rsdp_table]
           push cs
           pop  ds
           call bios_printf
           add  sp,10
           pop  ds
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build the RSDP table
           ; (cannot put a string of 'RSD PTR' here in this line of code)
           ; (a guest may find this string as the incorrect location)
           mov  edi,[EBDA_DATA->rsdp_table]
           mov  dword fs:[edi+RSDP_TABLE->signature+0],' DSR'
           mov  dword fs:[edi+RSDP_TABLE->signature+4],' RTP'
           mov  byte  fs:[edi+RSDP_TABLE->checksum],0         ; checksum (patched later)
.ifdef BX_QEMU
           mov  dword fs:[edi+RSDP_TABLE->oem_id+0],'UMEQ'    ; 'QEMU  '
           mov  word  fs:[edi+RSDP_TABLE->oem_id+4],'  '      ;
.else
           mov  dword fs:[edi+RSDP_TABLE->oem_id+0],'HCOB'    ; 'BOCHS '
           mov  word  fs:[edi+RSDP_TABLE->oem_id+4],' S'      ;
.endif
           mov  byte  fs:[edi+RSDP_TABLE->revision],0 ; 2         ; 2.0
           mov  eax,[EBDA_DATA->rsdt_addr]
           mov  fs:[edi+RSDP_TABLE->rsdt_physical_address],eax
           ; version 2.0 starts here
           mov  dword fs:[edi+RSDP_TABLE->length],0 ; sizeof(RSDP_TABLE)
           ; extended is not used
           mov  dword fs:[edi+RSDP_TABLE->xsdt_physical_address+0],0
           mov  dword fs:[edi+RSDP_TABLE->xsdt_physical_address+4],0
           mov  dword fs:[edi+RSDP_TABLE->extended_checksum],0  ; clears the reserved too
           mov  ax,20
           call calc_checksum
           mov  fs:[edi+RSDP_TABLE->checksum],al
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build the RSDT table
           mov  edi,[EBDA_DATA->rsdt_addr]
           push edi
           add  edi,sizeof(ACPI_TABLE_HEADER)
           mov  eax,[EBDA_DATA->fadt_addr]
           mov  fs:[edi+0],eax
           mov  eax,[EBDA_DATA->ssdt_addr]
           mov  fs:[edi+4],eax
           mov  eax,[EBDA_DATA->madt_addr]
           mov  fs:[edi+8],eax
           mov  eax,[EBDA_DATA->hpet_addr]
           mov  fs:[edi+12],eax
           pop  edi
           mov  eax,'TDSR'
           mov  ecx,(sizeof(ACPI_TABLE_HEADER) + (sizeof(dword) * 4))
           mov  dl,1                ; revision
           call acpi_build_header
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build the FADT table
           mov  edi,[EBDA_DATA->fadt_addr]
           mov  eax,[EBDA_DATA->facs_addr]
           mov  fs:[edi+FADT_TABLE->firmware_ctrl],eax
           mov  eax,[EBDA_DATA->dsdt_addr]
           mov  fs:[edi+FADT_TABLE->dsdt],eax
           mov  byte fs:[edi+FADT_TABLE->model],1
           mov  byte fs:[edi+FADT_TABLE->reserved1],0
           movzx ax,byte [EBDA_DATA->pm_sci_int]
           mov  fs:[edi+FADT_TABLE->sci_int],al
           mov  dword fs:[edi+FADT_TABLE->smi_cmd],SMI_CMD_IO_ADDR
           mov  byte  fs:[edi+FADT_TABLE->acpi_enable],0xF1
           mov  byte  fs:[edi+FADT_TABLE->acpi_disable],0xF0
           mov  byte  fs:[edi+FADT_TABLE->S4bios_req],0
           mov  byte  fs:[edi+FADT_TABLE->reserved2],0
           mov  eax,pm_io_base
           mov        fs:[edi+FADT_TABLE->pm1a_evt_blk],eax
           mov  dword fs:[edi+FADT_TABLE->pm1b_evt_blk],0
           add  eax,4
           mov        fs:[edi+FADT_TABLE->pm1a_cnt_blk],eax
           mov  dword fs:[edi+FADT_TABLE->pm1b_cnt_blk],0
           mov  dword fs:[edi+FADT_TABLE->pm2_cnt_blk],0
           add  eax,4
           mov        fs:[edi+FADT_TABLE->pm_tmr_blk],eax
           mov  dword fs:[edi+FADT_TABLE->gpe0_blk],0
           mov  dword fs:[edi+FADT_TABLE->gpe1_blk],0
           mov  byte  fs:[edi+FADT_TABLE->pm1_evt_len],4
           mov  byte  fs:[edi+FADT_TABLE->pm1_cnt_len],2
           mov  byte  fs:[edi+FADT_TABLE->pm2_cnt_len],0
           mov  byte  fs:[edi+FADT_TABLE->pm_tmr_len],4
           mov  byte  fs:[edi+FADT_TABLE->gpe0_blk_len],0
           mov  byte  fs:[edi+FADT_TABLE->gpe1_blk_len],0
           mov  byte  fs:[edi+FADT_TABLE->gpe1_base],0
           mov  byte  fs:[edi+FADT_TABLE->reserved3],0
           mov  word  fs:[edi+FADT_TABLE->plvl2_lat],0x0FFF
           mov  word  fs:[edi+FADT_TABLE->plvl3_lat],0x0FFF
           mov  word  fs:[edi+FADT_TABLE->flush_size],0
           mov  word  fs:[edi+FADT_TABLE->flush_stride],0
           mov  byte  fs:[edi+FADT_TABLE->duty_offset],0
           mov  byte  fs:[edi+FADT_TABLE->duty_width],0
           mov  byte  fs:[edi+FADT_TABLE->day_alarm],0 ; if we supported it, this would be 0x7D
           mov  byte  fs:[edi+FADT_TABLE->mon_alarm],0 ; if we supported it, this would be 0x7E
           mov  byte  fs:[edi+FADT_TABLE->century],0
           mov  byte  fs:[edi+FADT_TABLE->reserved4],0
           mov  byte  fs:[edi+FADT_TABLE->reserved5],0
           mov  byte  fs:[edi+FADT_TABLE->reserved6],0
           mov  dword fs:[edi+FADT_TABLE->flags],((1 << 0) | (1 << 2) | (1 << 4) | (1 << 5) | (1 << 6))
           mov  eax,'PCAF'
           mov  ecx,sizeof(FADT_TABLE)
           mov  dl,1                ; revision
           call acpi_build_header

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build the FACS table
           mov  edi,[EBDA_DATA->facs_addr]
           mov  ax,sizeof(FACS_TABLE)
           call memset32
           mov  dword fs:[edi+FACS_TABLE->signature],'SCAF'
           mov  dword fs:[edi+FACS_TABLE->length],sizeof(FACS_TABLE)
           mov  dword fs:[edi+FACS_TABLE->hardware_signature],0
           mov  dword fs:[edi+FACS_TABLE->fw_wake_vector],0
           mov  dword fs:[edi+FACS_TABLE->global_lock],0
           mov  dword fs:[edi+FACS_TABLE->S4bios_f],0
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build the DSDT
           ; we simply include a binary file and copy that file to the correct location
           mov  edi,[EBDA_DATA->dsdt_addr]
           mov  esi,((BIOS_BASE2 << 4) + acpi_dsdt_start)
           mov  cx,[EBDA_DATA->dsdt_addr_sz]
@@:        mov  al,fs:[esi]
           inc  esi
           mov  fs:[edi],al
           inc  edi
           loop @b

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build the MADT table
           mov  edi,[EBDA_DATA->madt_addr]
           mov  ax,[EBDA_DATA->madt_addr_sz]
           call memset32
           mov  dword fs:[edi+MADT_TABLE->local_apic_addr],APIC_BASE_ADDR
           mov  dword fs:[edi+MADT_TABLE->flags],1
           add  edi,sizeof(MADT_TABLE)
           mov  cx,[EBDA_DATA->smp_cpus]
           xor  bx,bx
@@:        mov  byte  fs:[edi+MADT_PROC_TABLE->hdr_type],APIC_PROCESSOR
           mov  byte  fs:[edi+MADT_PROC_TABLE->hdr_length],sizeof(MADT_PROC_TABLE)
           mov        fs:[edi+MADT_PROC_TABLE->processor_id],bl
           mov        fs:[edi+MADT_PROC_TABLE->local_apic_id],bl
           mov  dword fs:[edi+MADT_PROC_TABLE->flags],1
           add  edi,sizeof(MADT_PROC_TABLE)
           inc  bx
           loop @b

           mov  byte  fs:[edi+MADT_IO_APIC->hdr_type],APIC_IO
           mov  byte  fs:[edi+MADT_IO_APIC->hdr_length],sizeof(MADT_IO_APIC)
           mov  cx,[EBDA_DATA->smp_cpus]
           mov        fs:[edi+MADT_IO_APIC->io_apic_id],cl
           mov  dword fs:[edi+MADT_IO_APIC->address],IOAPIC_BASE_ADDR
           mov  dword fs:[edi+MADT_IO_APIC->interrupt],0
           add  edi,sizeof(MADT_IO_APIC)

           mov  byte  fs:[edi+MADT_INT_OVERRIDE->hdr_type],APIC_XRUPT_OVERRIDE
           mov  byte  fs:[edi+MADT_INT_OVERRIDE->hdr_length],sizeof(MADT_INT_OVERRIDE)
           mov  byte  fs:[edi+MADT_INT_OVERRIDE->bus],0
           mov  byte  fs:[edi+MADT_INT_OVERRIDE->source],0
           mov  dword fs:[edi+MADT_INT_OVERRIDE->gsi],2
           mov  word  fs:[edi+MADT_INT_OVERRIDE->flags],0

           mov  edi,[EBDA_DATA->madt_addr]
           mov  cx,[EBDA_DATA->madt_addr_sz]
           mov  eax,'CIPA'
           mov  dl,1                ; revision
           call acpi_build_header

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build the HPET table
           mov  edi,[EBDA_DATA->hpet_addr]
           mov  ax,sizeof(MADT_HPET)
           call memset32
           mov  eax,fs:[HPET_PHYS_ADDRESS] ; get cap register
           mov        fs:[edi+MADT_HPET->timer_block_id],eax
           mov  dword fs:[edi+MADT_HPET->phys_address+0],HPET_PHYS_ADDRESS
           mov  dword fs:[edi+MADT_HPET->phys_address+4],0

           mov  cx,sizeof(MADT_HPET)
           mov  eax,'TEPH'
           mov  dl,1                ; revision
           call acpi_build_header

  ; writemem "C:\bochs\images\winxp\dd.bin" 0x1FFF0000 34872
  ;mov eax,[EBDA_DATA->acpi_base_address]
  ;mov cx,[EBDA_DATA->acpi_tables_size]
  ;xchg cx,cx

acpi_bios_init_done:
           ret
acpi_bios_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; build ssdt table
; on entry:
;  ds -> EBDA
;  fs:edi-> current position to build table
; on return
;  eax = size of the table built
; destroys none
acpi_build_ssdt proc near uses bx cx dx edi

           ; the Processor Block uses either one of the two following forms:
           ; 1) Rootchar NamePath | PrefixPath Name Path
           ;    Which is \_PR.CPU0, etc.
           ; 2) DwordData ByteData
           ;    Which is: 0x5B 0x83 (ProcessorOp)
           ;              ?? ?? ?? ??
           ;    Must be a 4-byte field, nothing more.
           ; We do option 2 here.
           
           push edi
           
           ; skip over the header for now
           add  edi,sizeof(ACPI_TABLE_HEADER)

           ; caluculate the length of processor block and scope block excluding PkgLength
           mov  cx,[EBDA_DATA->smp_cpus]
           xor  ch,ch        ; can't have more than 255 here
           push cx
           imul cx,13                                                    ; 13-bytes per object below   (cannot be more than 16...
           add  cx,4                                                     ; 4 bytes for the '_PR_'            ...or we have to use a 3-byte length below)

           mov  byte fs:[edi],0x10 ; ScopeOp                             ; 0x10
           inc  edi                                                      ;
                                                                         ;
           ; package length is encoded as:
           ; bits 7:6 = how many byte to follow
           ;   00b = no bytes follow  (value = 0x00 -> 0x3F)
           ;   01b = one byte follows (value = 0x000 -> 0x0FFF)
           ;   10b = two bytes follow (value = 0x00000 -> 0x0FFFFF)
           ;   11b = three bytes follow (value 0x00000000 -> 0x0FFFFFFF)

           ; if (length <= 63) we can use a single byte                  ;
           inc  cx                                                       ; assume one byte for the length (1 byte length)
           mov  fs:[edi],cl                                              ; 0x??  (one byte opcode < 63) (bits 7:6 = 00)
           cmp  cl,63                                                    ; 
           jbe  short @f                                                 ;  or
           inc  cx                                                       ; two byte opcode (63+) (another byte)
           mov  al,cl                                                    ; 0x4? | (0x0??x >> 4)
           and  al,0x0F                                                  ;
           or   al,0x40                                                  ;  (bits 7:4 = 0100b)
           mov  fs:[edi],al                                              ;
           inc  edi                                                      ;
           shr  cx,4                                                     ; get high byte (0x0??x >> 4)
           mov  fs:[edi],cl                                              ;
                                                                         ;
           ; now the _PR_ name                                           ;
@@:        inc  edi                                                      ;
           mov  dword fs:[edi],'_RP_'                                    ; '_PR_'
           add  edi,4                                                    ;

           pop  cx
           xor  bx,bx
processor_object:
           mov  byte fs:[edi],0x5B                                       ; 0x5B = ProcessorOP
           inc  edi                                                      ;
           mov  byte fs:[edi],0x83                                       ; 0x83
           inc  edi                                                      ;
           mov  byte fs:[edi],11                                         ; 0x0B = length of this object
           inc  edi                                                      ;
           mov  byte fs:[edi],'C'                                        ; 'C'
           inc  edi                                                      ;
           mov  byte fs:[edi],'P'                                        ; 'P'
           inc  edi                                                      ;
           mov  byte fs:[edi],'U'                                        ; 'U'
           inc  edi                                                      ;

           ; now calculate the 100's, 10's, and 1's digits.           
           push cx
           ; 100s digit
           mov  ax,bx
           mov  cl,100
           div  cl
           mov  dh,al            ; save the 100's in dh
           ; 10s digit
           mov  al,ah
           xor  ah,ah
           mov  cl,10
           div  cl
           mov  dl,al            ; save the 10's in dl
           ; 1s digit
           add  ah,'0'
           mov  fs:[edi],ah                                              ; '0'
           inc  edi                                                      ;
           pop  cx

           ; if there were a 10's or 100's digits, backup and place them
           or   dh,dh
           jz   short @f
           add  dh,'0'
           mov  fs:[edi-3],dh
           ; if there was a 100's digit, we must do the 10's digit
           jmp  short pr_must_10
@@:        or   dl,dl
           jz   short @f
pr_must_10:
           add  dl,'0'
           mov  fs:[edi-2],dl

@@:        mov  fs:[edi],bl                                              ; index
           inc  edi                                                      ;
           mov  byte fs:[edi],0x10                                       ; 0x10 = Processor block address
           inc  edi                                                      ;
           mov  byte fs:[edi],0xB0                                       ; 0xB0
           inc  edi                                                      ;
           mov  byte fs:[edi],0x00                                       ; 0x00
           inc  edi                                                      ;
           mov  byte fs:[edi],0x00                                       ; 0x00
           inc  edi                                                      ;
           mov  byte fs:[edi],0x06                                       ; 0x06 = Processor block length
           inc  edi                                                      ;

           inc  bx
           dec  cx
           jnz  processor_object

           mov  ecx,edi
           pop  edi
           sub  ecx,edi
           mov  eax,'TDSS'
           mov  dl,1                ; revision
           call acpi_build_header

           mov  eax,ecx
           ret
acpi_build_ssdt endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; build acpi header
; on entry:
;  ds -> EBDA
;  fs:edi-> current position to build header
;  eax = 32-bit signature (in little-endian)
;  ecx = size of table
;  dl = revision of table
; on return
;  nothgin
; destroys none
acpi_build_header proc near uses eax
           mov        fs:[edi+ACPI_TABLE_HEADER->signature],eax
           mov        fs:[edi+ACPI_TABLE_HEADER->length],ecx
           mov        fs:[edi+ACPI_TABLE_HEADER->revision],dl
           mov  byte  fs:[edi+ACPI_TABLE_HEADER->checksum],0  ; patched later
.ifdef BX_QEMU
           mov  dword fs:[edi+ACPI_TABLE_HEADER->oem_id],'UMEQ'
           mov  word  fs:[edi+ACPI_TABLE_HEADER->oem_id+4],'  '
           mov  dword fs:[edi+ACPI_TABLE_HEADER->oem_table_id],'UMEQ'
.else
           mov  dword fs:[edi+ACPI_TABLE_HEADER->oem_id],'HCOB'
           mov  word  fs:[edi+ACPI_TABLE_HEADER->oem_id+4],' S'
           mov  dword fs:[edi+ACPI_TABLE_HEADER->oem_table_id],'CPXB'
.endif
           mov        fs:[edi+ACPI_TABLE_HEADER->oem_table_id+4],eax
           mov  dword fs:[edi+ACPI_TABLE_HEADER->oem_revision],1
.ifdef BX_QEMU
           mov  dword fs:[edi+ACPI_TABLE_HEADER->creator_id],'UMEQ'
.else
           mov  dword fs:[edi+ACPI_TABLE_HEADER->creator_id],'CPXB'
.endif
           mov  dword fs:[edi+ACPI_TABLE_HEADER->creator_rev],1
           mov  ax,cx
           call calc_checksum
           mov  fs:[edi+ACPI_TABLE_HEADER->checksum],al

           ret
acpi_build_header endp


.endif  ; DO_INIT_BIOS32

.end
