comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: sata.asm                                                           *
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
*   sata include file                                                      *
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
***************************************************************************|

.if DO_INIT_BIOS32

; Host Control Register offsets
AHCI_CTRL_REGS struct
  HBA_HC_Capabilities       dword
  HBA_HC_Glob_host_cntrl    dword
  HBA_HC_Interrupt_status   dword
  HBA_HC_Ports_implemented  dword
  HBA_HC_Version            dword
  HBA_HC_Ccc_ctl            dword
  HBA_HC_Ccc_ports          dword
  HBA_HC_Em_location        dword
  HBA_HC_Em_control         dword
  HBA_HC_Capabilities_ext   dword
  HBA_HC_Bohc               dword
AHCI_CTRL_REGS ends

HBA_PORT_REGS struct
  HBA_PORT_PxCLB     dword
  HBA_PORT_PxCLBU    dword
  HBA_PORT_PxFB      dword
  HBA_PORT_PxFBU     dword
  HBA_PORT_PxIS      dword
  HBA_PORT_PxIE      dword
  HBA_PORT_PxCMD     dword
  HBA_PORT_RESV0     dword
  HBA_PORT_PxTFD     dword
  HBA_PORT_PxSIG     dword
  HBA_PORT_PxSSTS    dword
  HBA_PORT_PxSCTL    dword
  HBA_PORT_PxSERR    dword
  HBA_PORT_PxSACT    dword
  HBA_PORT_PxCI      dword
  HBA_PORT_PxSNTF    dword
  HBA_PORT_PxFBS     dword
  HBA_PORT_PxDEVSLP  dword
  HBA_PORT_RESV1     dup 40
  HBA_PORT_PxVS      dword
HBA_PORT_REGS ends

HBA_PORT_CMD_ST    equ (1 <<  0)
HBA_PORT_CMD_FRE   equ (1 <<  4)
HBA_PORT_CMD_FR    equ (1 << 14)
HBA_PORT_CMD_CR    equ (1 << 15)
HBA_PORT_CMD_ICC   equ (0xF << 28)

SATA_SIG_ATA       equ  0x00000101  ; SATA drive
SATA_SIG_ATAPI     equ  0xEB140101  ; SATAPI drive
SATA_SIG_SEMB      equ  0xC33C0101  ; Enclosure management bridge
SATA_SIG_PM        equ  0x96690101  ; Port multiplier
SATA_SIG_NONE      equ  0x00000000  ; None Present
SATA_SIG_NON_ACT   equ  0x0000FFFF  ; Not Active

HBA_CMD_LIST struct
  dword0   dword
  prdbc    dword
  ctba     dword
  ctbau    dword
  resv     dup 16
HBA_CMD_LIST ends

; 0 = Read from device, 1 = write to device
SATA_DIR_SEND      equ  1
SATA_DIR_RECV      equ  0

FIS_REG_H2D struct
  fis_type         byte  ; FIS_TYPE_REG_H2D (0x27)
  flags            byte  ;
  command          byte  ;
  features         byte  ;
  lba_0            byte  ; sect_num
  lba_1            byte  ; cyl_low;
  lba_2            byte  ; cyl_high;
  dev_head         byte  ;
  lba_3            byte  ; sect_num_exp;
  lba_4            byte  ; cyl_low_exp;
  lba_5            byte  ; cyl_high_exp;
  features_exp     byte  ;
  sect_count_low   byte  ;
  sect_count_high  byte  ;
  reserved         byte  ;
  control          byte  ;
  resv             dword ;
FIS_REG_H2D ends

sata_controller_str    db  '(SATA Device)',0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize and detect any AHCI hard drive(s)
; on entry:
;  nothing
; on return
;  nothing
; destroys 
sata_detect proc near uses es
           push bp
           mov  bp,sp
           sub  sp,44

sata_hd_model   equ  [bp-42]  ; sata_hd_model[42]
sata_cntrl_idx  equ  [bp-44]  ; word

           call bios_get_ebda
           mov  es,ax
           mov  byte es:[EBDA_DATA->sata_disk_active],0x00
           mov  byte es:[EBDA_DATA->sata_next_device_id],0x00

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; try to detect a SATA by finding a SATA PCI controller
           xor  esi,esi
sata_cntrlr_detection:
           mov  sata_cntrl_idx,si
           push esi
           ;         unused   class   subclass prog int
           mov  ecx,00000000_00000001_00000110_00000001b
           mov  ax,0xB103
           int  1Ah
           pop  esi
           jc   init_sata_done

           ; found a sata controller, so initialize it
           call sata_initialize
           jc   init_sata_next

           push esi              ; save controller index number

           ; retrieve pointers
           imul esi,sizeof(SATA_CONTROLLER)
           add  esi,EBDA_DATA->sata_ahci_cntrls
           mov  edi,es:[esi+SATA_CONTROLLER->base]

           ;  2. Determine which ports are implemented by the HBA, by reading the PI register. 
           ;     This bit map value will aid software in determining how many ports are available 
           ;     and which port registers need to be initialized.
           mov  eax,fs:[edi+AHCI_CTRL_REGS->HBA_HC_Ports_implemented]
           xor  edx,edx          ; start with port 0
           mov  ecx,1
           mov  es:[esi+SATA_CONTROLLER->numdrives],dl
sata_ahci_det_drive_0:
           push eax              ; save drive bitmap
           push edx              ; save drive index
           push ecx              ; save bit position
           test eax,ecx
           jz   sata_ahci_det_drive_1

           ; see if there is a drive on this 'port'
           call sata_ahci_detect
           or   al,al
           jz   sata_ahci_det_drive_1

           ; calculate the device's buffer address
           movzx ebx,byte es:[esi+SATA_CONTROLLER->numdrives]
           shl  ebx,2
           mov  ebx,es:[esi+ebx+SATA_CONTROLLER->device_data]
           mov  al,es:[esi+SATA_CONTROLLER->numdrives]
           mov  fs:[ebx+SATA_DEVICE->device_num],al
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; send the IDENTIFY command
           mov  cx,ATA_CMD_IDENTIFY_DEVICE
           cmp  dword fs:[ebx+SATA_DEVICE->device_sig],SATA_SIG_ATA
           je   short @f
           mov  cx,ATA_CMD_IDENTIFY_DEVICE_PACKET
@@:        lea  eax,[ebx+SATA_DEVICE->rxtx_buffer]
           push eax      ; physical address of buffer
           pushd 0       ; physical address of command packet
           push  0       ; count
           pushd 512     ; buffer length
           pushd 0       ; lba_high
           pushd 0       ; lba_low
           push cx       ; command
           push SATA_DIR_RECV
           call sata_cmd_data_io
           add  sp,26
           cmp  eax,512
           je   short @f

           ; error retrieving the IDENTIFY packet
           ;  free the buffer used and continue to next drive
           mov  eax,ebx
           call memory_free
           movzx ebx,byte es:[esi+SATA_CONTROLLER->numdrives]
           shl  ebx,2
           mov  dword es:[esi+ebx+SATA_CONTROLLER->device_data],0
           jmp  sata_ahci_det_drive_1
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; save some information for the service calls
@@:        lea  eax,[ebx+SATA_DEVICE->rxtx_buffer]
           mov  cx,fs:[eax+10]
           mov  fs:[ebx+SATA_DEVICE->blk_size],cx
           mov  cx,fs:[eax+(1*2)]
           mov  fs:[ebx+SATA_DEVICE->cylinders],cx
           mov  cx,fs:[eax+(3*2)]
           mov  fs:[ebx+SATA_DEVICE->heads],cx
           mov  cx,fs:[eax+(6*2)]
           mov  fs:[ebx+SATA_DEVICE->spt],cx
           
           ; if bit 10 of word 83 is set, we support 48-bit LBAs
           ; (first get the 28bit just in case)
           mov  cx,fs:[eax+(61*2)]
           shl  ecx,16
           mov  cx,fs:[eax+(61*2)]
           mov  fs:[ebx+SATA_DEVICE->sectors_low],ecx
           mov  dword fs:[ebx+SATA_DEVICE->sectors_high],0
           test word fs:[eax+(83*2)],(1<<10)
           jz   short @f
           ; else get the 64-bit count
           mov  cx,fs:[eax+(101*2)]
           shl  ecx,16
           mov  cx,fs:[eax+(100*2)]
           mov  fs:[ebx+SATA_DEVICE->sectors_low],ecx
           mov  cx,fs:[eax+(103*2)]
           shl  ecx,16
           mov  cx,fs:[eax+(102*2)]
           mov  fs:[ebx+SATA_DEVICE->sectors_high],ecx
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get model string
           ; (it is in big-endian format)
@@:        mov  cx,20
           push esi
           lea  si,sata_hd_model
@@:        mov  dl,fs:[eax+54+1]
           mov  ss:[si],dl
           mov  dl,fs:[eax+54+0]
           mov  ss:[si+1],dl
           add  si,2
           add  eax,2
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
           pop  esi

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now print what we found
           cmp  dword fs:[ebx+SATA_DEVICE->device_sig],SATA_SIG_ATA
           jne  short sata_ahci_det_drive_2
           ; is ATA
           mov  edx,fs:[ebx+SATA_DEVICE->sectors_high]
           mov  eax,fs:[ebx+SATA_DEVICE->sectors_low]
           shrd eax,edx,11
           shr  edx,11
           mov  cl,'M'
           or   edx,edx
           jnz  short sata_ahci_high
           cmp  eax,(1<<16)
           jb   short @f
sata_ahci_high:
           shrd eax,edx,10
           shr  edx,10
           mov  cl,'G'
@@:        push ds
           push bx
           push si
           movzx bx,byte es:[esi+SATA_CONTROLLER->numdrives]
           mov  si,offset sata_print_str1
           push BIOS_BASE2
           pop  ds
           push cx
           push eax
           push bx
           call bios_printf
           add  sp,8
           pop  si
           pop  bx
           pop  ds
           jmp  short sata_ahci_det_drive_3

sata_ahci_det_drive_2:
           push ds
           push bx
           push si
           movzx bx,byte es:[esi+SATA_CONTROLLER->numdrives]
           mov  si,offset sata_print_str2
           push BIOS_BASE2
           pop  ds
           push bx
           call bios_printf
           add  sp,2
           pop  si
           pop  bx
           pop  ds

sata_ahci_det_drive_3:
           push si
           lea  si,sata_hd_model
           cmp  byte ss:[si],0
           je   short sata_ahci_det_drive_4
           mov  al,'('
           call display_char
@@:        mov  al,ss:[si]
           or   al,al
           jz   short @f
           call display_char
           inc  si
           jmp  short @b
@@:        mov  al,')'
           call display_char
           mov  al,13
           call display_char
           mov  al,10
           call display_char
sata_ahci_det_drive_4:
           pop  si

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; add this drive to our vector table
           push si
           push es
           mov  edx,((IPL_FLAGS_SATA << 16) | (IPL_TYPE_HARDDISK << 8) | (0 << 0))
           ; controller index in bits 5:4, device number in 3:0
           mov  dl,sata_cntrl_idx
           shl  dl,4
           or   dl,fs:[ebx+SATA_DEVICE->device_num]
           push cs
           pop  es
           xor  eax,eax          ; lba = 0
           xor  ecx,ecx          ; vector = 0000:0000
           mov  si,offset sata_controller_str
           call add_boot_vector
           pop  es
           pop  si

           inc  byte es:[esi+SATA_CONTROLLER->numdrives]
           cmp  byte es:[esi+SATA_CONTROLLER->numdrives],SATA_DEVICE_MAX
           jb   short sata_ahci_det_drive_1
           xor  ecx,ecx          ; indicate no more
           
sata_ahci_det_drive_1:
           pop  ecx              ; restore bit position
           pop  edx              ; restore drive index
           pop  eax              ; restore the drive bitmap
           inc  edx              ; move to next port
           shl  ecx,1            ; move to next bit position
           jnz  sata_ahci_det_drive_0
           pop  esi              ; restore controller index number

           ; loop so that we can see if there are any more
init_sata_next:
           inc  esi
           cmp  esi,MAX_SATA_CONTROLLERS
           jb   sata_cntrlr_detection

init_sata_done:
           mov  sp,bp            ; restore the stack
           pop  bp
           ret
sata_detect endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; SATA Disk Emulation: is emulation active
; on entry:
;  es = segment of EBDA
; on return
;  ax = zero = not active, else is active
; destroys nothing
sata_disk_emu_active proc near
           movzx ax,byte es:[EBDA_DATA->sata_disk_active]
           ret
sata_disk_emu_active endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; SATA Disk Emulation: return the drive number that is being emulated
; on entry:
;  es = segment of EBDA
; on return
;  ax = drive number being emulated
; destroys nothing
sata_disk_emu_drive proc near
           movzx ax,byte es:[EBDA_DATA->sata_disk_emulated_drive]
           ret
sata_disk_emu_drive endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the found ahci controller
; on entry:
;  es -> EBDA
;  bh = bus
;  bl = dev/func
;  esi = 0 for first controller, 1 for second, 2 for third, etc
; on return
;  carry clear if successful
; destroys none
sata_initialize proc near uses alld ds
           
           ; the AHCI is memmapped, so find the address
           mov  ax,0xB10A
           mov  di,0x24
           int  1Ah
           ; is it Port IO?
           test cl,1
           jnz  sata_initialize_error
           and  cl,(~0xF)
           mov  edi,ecx
           push ecx              ; save the base
           
           ; make sure IO is allowed
           mov  ax,0xB109
           mov  di,0x04
           int  1Ah
           or   cx,6             ; memory io and busmaster enable
           mov  ax,0xB10C
           mov  di,0x04
           int  1Ah

           pop  edi              ; restore the address in edi
           
           ; start to save information
           imul esi,sizeof(SATA_CONTROLLER)
           add  esi,EBDA_DATA->sata_ahci_cntrls
           
           mov  byte es:[esi+SATA_CONTROLLER->valid],0  ; not valid for now
           mov  es:[esi+SATA_CONTROLLER->busdevfunc],bx
           mov  es:[esi+SATA_CONTROLLER->base],edi
           ;mov  byte es:[esi+SATA_CONTROLLER->flags],0
           
           push edi
           ; get the irq
           mov  ax,0xB108
           mov  di,0x3C
           int  1Ah
           mov  es:[esi+SATA_CONTROLLER->irq],cl
           pop  edi
           
           ; read the CAPs register
           ; if CAPS.SAM = 1, only AHCI is supported
           test dword fs:[edi+AHCI_CTRL_REGS->HBA_HC_Capabilities],(1<<18)
           jnz  short sata_ahci_only

           ; AHCI controller supports AHCI or legacy
           ; so, see if the AHCI Legacy flag is set
           mov  bx,ESCD_DATA->ahci_legacy
           mov  cx,sizeof(byte)
           call bios_read_escd
           or   al,al
           jz   short @f
           
           ; user states to use legacy, so clear the bit, and
           ; return as if an error occured so the Legacy ATA will get it.
           and  dword fs:[edi+AHCI_CTRL_REGS->HBA_HC_Glob_host_cntrl],(~(1<<31))
           jmp  sata_initialize_error

@@:        ; user states to use AHCI, try setting the bit (we test it below)
           mov  dword fs:[edi+AHCI_CTRL_REGS->HBA_HC_Glob_host_cntrl],(1<<31)

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; controller supports AHCI only (no legacy) or the ESCD->legacy == 0
sata_ahci_only:
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; reset the controller
           mov  dword fs:[edi+AHCI_CTRL_REGS->HBA_HC_Glob_host_cntrl],0x80000001
@@:        test dword fs:[edi+AHCI_CTRL_REGS->HBA_HC_Glob_host_cntrl],0x00000001
           jnz  short @b

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; retrieve the controller version
           mov  eax,fs:[edi+AHCI_CTRL_REGS->HBA_HC_Version]
           mov  es:[esi+SATA_CONTROLLER->version],eax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; To place the AHCI HBA into a minimally initialized state, system software shall:
           ;  1. Indicate that system software is AHCI aware by setting GHC.AE to 1.
           ;     (Note: We don't neccassarily follow the specs in order.  We do 1., 4., 2., etc.)
           mov  cx,5             ; 5 tries
@@:        test dword fs:[edi+AHCI_CTRL_REGS->HBA_HC_Glob_host_cntrl],(1<<31)
           jnz  short @f
           ; delay 100mS
           mov  eax,100
           call mdelay
           mov  dword fs:[edi+AHCI_CTRL_REGS->HBA_HC_Glob_host_cntrl],(1<<31)
           loop @b
           ; else, the bit never enabled, so return error
           jmp  short sata_initialize_error

@@:        ; CTRL.AE = 1, let's continue
           ;  4. Determine how many command slots the HBA supports, by reading CAP.NCS.
           ;     (We also get the count of allocated drives (ports) it has)
           mov  eax,fs:[edi+AHCI_CTRL_REGS->HBA_HC_Capabilities]
           and  ax,0x1F1F
           mov  es:[esi+SATA_CONTROLLER->numports],al
           inc  ah
           mov  es:[esi+SATA_CONTROLLER->command_slots],ah
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we have found and initialized a AHCI
           ; mark this information valid
           mov  byte es:[esi+SATA_CONTROLLER->valid],1

           ; print that we found a AHCI
           mov  ax,BIOS_BASE2
           mov  ds,ax
           movzx ax,byte es:[esi+SATA_CONTROLLER->numports]
           push ax
           movzx ax,byte es:[esi+SATA_CONTROLLER->irq]
           push ax
           push dword es:[esi+SATA_CONTROLLER->base]
           mov  si,offset ahci_found_str0
           call bios_printf
           add  sp,8

           ; successful return
           clc
           ret
           
sata_initialize_error:
           stc
           ret
sata_initialize endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; detect a drive on a given AHCI port
; on entry:
;  es -> EBDA
;  edx = zero-based port number
;  es:esi -> SATA_CONTROLLER
;  fs:edi -> AHCI register set
; on return
;  al = 0 = no drive, 1 = drive found
; destroys none
sata_ahci_detect proc near uses ebx
           ; reset the port
           call sata_reset_port
           or   al,al
           jz   short sata_ahci_detect_error

           ; initialize the port's memory base
           call sata_port_initialize
           or   al,al
           jz   short sata_ahci_detect_error

           ; get the pointer to the device_data
           movzx ebx,byte es:[esi+SATA_CONTROLLER->numdrives]
           shl  ebx,2
           mov  ebx,es:[esi+ebx+SATA_CONTROLLER->device_data]

           ; now get the device type
           call sata_get_port_type
           cmp  eax,SATA_SIG_ATA
           je   short @f
           cmp  eax,SATA_SIG_ATAPI
           je   short @f

           ; else no drive attached, so free the memory and return
           mov  eax,ebx
           call memory_free
           movzx ebx,byte es:[esi+SATA_CONTROLLER->numdrives]
           shl  ebx,2
           mov  dword es:[esi+ebx+SATA_CONTROLLER->device_data],0
           jmp  short sata_ahci_detect_error

           ; save the device type
@@:        mov  fs:[ebx+SATA_DEVICE->device_sig],eax

           ; type needs to be SATA_SIG_ATA or SATA_SIG_ATAPI
           cmp  eax,SATA_SIG_ATA
           je   short sata_ahci_detect_done
           cmp  eax,SATA_SIG_ATAPI
           jne  short sata_ahci_detect_error
           
sata_ahci_detect_done:
           mov  al,1
           ret
           
sata_ahci_detect_error:
           xor  al,al
           ret
sata_ahci_detect endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; reset a HBA port
; on entry:
;  es -> EBDA
;  edx = zero-based port number
;  es:esi -> SATA_CONTROLLER
;  fs:edi -> AHCI register set
; on return
;  al = 0 = failed to reset, 1 = success
; destroys none
sata_reset_port proc near uses ecx edx
           ; Cause a port reset (COMRESET) by writing 1 to the PxSCTL.DET field to invoke a COMRESET on the 
           ;  interface and start a re-establishment of Phy layer communications. Software shall wait at least 
           ;  1 millisecond before clearing PxSCTL.DET to 0.  This ensures that at least one COMRESET signal is 
           ;  sent over the interface. After clearing PxSCTL.DET to 0, software should wait for communication to 
           ;  be re-established as indicated by PxSSTS.DET being set to 3. Then software should write all 1s to the 
           ;  PxSERR register to clear any bits that were set as part of the port reset.
           
           ; calculate port address (simply multiply by 0x80 + 0x100)
           shl  edx,7
           add  edx,0x100        ; ports start at offset 0x100

           ; HBA_PORT_PxSCTL.DET = 1
           mov  eax,fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSCTL]
           and  al,0xF0
           or   al,0x01
           mov  fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSCTL],eax

           ; wait at least 1 ms
           mov  eax,1
           call mdelay

           ; HBA_PORT_PxSCTL.DET = 0
           mov  eax,fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSCTL]
           and  al,0xF0
           mov  fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSCTL],eax
           
           ; now wait for the status to become active
           mov  ecx,(500 * 1000)
@@:        mov  eax,fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSSTS]
           and  al,0x0F
           cmp  al,0x03
           je   short @f
           .adsize
           loop @b
           
           ; failed to reset
           xor  al,al
           ret
           
@@:        ; clear SERR register
           mov  dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSERR],0xFFFFFFFF
           mov  al,1
           ret
sata_reset_port endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize an SATA port for use
; on entry:
;  es -> EBDA
;  edx = zero-based port number
;  es:esi -> SATA_CONTROLLER
;  fs:edi -> AHCI register set
; on return
;  al = 0 = failed to reset, 1 = success
; destroys none
sata_port_initialize proc near uses ebx ecx edx edi
           ; 5. For each implemented port, system software shall allocate memory for and program:
           ;     PxCLB (and PxCLBU if CAP.S64A is set to 1)
           ;     PxFB (and PxFBU if CAP.S64A is set to 1)
           ;    It is good practice for system software to ‘zero-out’ the memory allocated and referenced 
           ;    by PxCLB and PxFB. After setting PxFB and PxFBU to the physical address of the FIS receive
           ;    area, system software shall set PxCMD.FRE to 1.
           
           push edi              ; save the port register set address

           ; allocate the device's memory block
           mov  eax,sizeof(SATA_DEVICE)
           mov  ecx,1024         ; 1k alignment
           call memory_allocate  ;
           ; and store the address to the controller's memory block
           movzx ecx,byte es:[esi+SATA_CONTROLLER->numdrives]
           shl  ecx,2
           mov  es:[esi+ecx+SATA_CONTROLLER->device_data],eax

           ; clear out the memory
           mov  edi,eax
           mov  ax,sizeof(SATA_DEVICE)
           call memset32

           ; create the command list's table pointers
           push edi              ; save the address to the command list
           mov  cx,32
           lea  eax,[edi+SATA_DEVICE->command_table]
@@:       ;mov  fs:[edi+HBA_CMD_LIST->dword0],0
          ;mov  fs:[edi+HBA_CMD_LIST->prdbc],0
           mov  fs:[edi+HBA_CMD_LIST->ctba],eax
          ;mov  fs:[edi+HBA_CMD_LIST->ctbau],0
           add  eax,sizeof(SATA_COMMAND_TABLE)
           add  edi,sizeof(HBA_CMD_LIST)
           loop @b
           pop  eax              ; restore the address to the command list

           pop  edi              ; restore the port register set address
           push edx              ; save the port number
           ; calculate port address (simply multiply by 0x80 + 0x100)
           shl  edx,7
           add  edx,0x100        ; ports start at offset 0x100
           
           ; write the address of the command list to the port
           mov  fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxCLB],eax
           mov  dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxCLBU],0
           
           ; write the address of the FIS to the port
           add  eax,SATA_DEVICE->recv_fis
           mov  fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxFB],eax
           mov  dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxFBU],0

           ; enable the FIS
           or   dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxCMD],HBA_PORT_CMD_FRE
           
           ; disallow power management
           mov  ecx,(3 << 8)     ; versions 0.95 -> 1.3
           mov  eax,es:[esi+SATA_CONTROLLER->version]
           cmp  eax,0x00010300
           jbe  short @f
           mov  ecx,(7 << 8)     ; version 1.3.1 and above
@@:        mov  fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSCTL],ecx
           pop  edx              ; restore the port number
           
           ; start the command engine
           call sata_start_cmd
           
           mov  al,1
           ret
sata_port_initialize endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; start the command engine
; on entry:
;  es -> EBDA
;  edx = zero-based port number
;  es:esi -> SATA_CONTROLLER
;  fs:edi -> AHCI register set
; on return
;  nothing
; destroys none
sata_start_cmd proc near uses edx
           ; 6. For each implemented port, clear the PxSERR register, by writing 1s to each implemented 
           ;    bit location.
           ; 7. Determine which events should cause an interrupt, and set each implemented port’s PxIE 
           ;    register with the appropriate enables. To enable the HBA to generate interrupts, system
           ;    software must also set GHC.IE to a 1.
           ; Note: Due to the multi-tiered nature of the AHCI HBA’s interrupt architecture, system software
           ;    must always ensure that the PxIS (clear this first) and IS.IPS (clear this second) registers 
           ;    are cleared to 0 before programming the PxIE and GHC.IE registers. This will prevent any 
           ;    residual bits set in these registers from causing an interrupt to be asserted.
           
           ; calculate port address (simply multiply by 0x80 + 0x100)
           shl  edx,7
           add  edx,0x100        ; ports start at offset 0x100
           
           ; clear SERR register
           mov  dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSERR],0x07FF0F03
           
           ; clear the IS register and set the IE register, setting GHC.IE if we want an interrupt to occur.
           ; since I don't use interrupts, make sure they are all turned off
           mov  dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxIS],0xFFFFFFFF
           mov  dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxIE],0x00000000
           and  dword fs:[edi+AHCI_CTRL_REGS->HBA_HC_Glob_host_cntrl],(~(1 << 1))
           
           ; clear the DRQ and BSY bits before we start the engine
           test dword fs:[edi+AHCI_CTRL_REGS->HBA_HC_Capabilities],(1 << 24)
           jz   short sata_start_cmd_0

           or   dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxCMD],(1 << 3)
@@:        test dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxCMD],(1 << 3)
           jnz  short @b

sata_start_cmd_0:
           ; set FRE (bit4) and ST (bit0)
           or   dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxCMD],(HBA_PORT_CMD_FRE | HBA_PORT_CMD_ST)
           
           ret
sata_start_cmd endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get the type of drive attached (if any)
; (HBA_PORT_CMD_FRE must have been set first or this doesn't return valid values)
; on entry:
;  es -> EBDA
;  edx = zero-based port number
;  es:esi -> SATA_CONTROLLER
;  fs:edi -> AHCI register set
; on return
;  eax = type attached (if any)
; destroys none
sata_get_port_type proc near uses ecx edx
           ; calculate port address (simply multiply by 0x80 + 0x100)
           shl  edx,7
           add  edx,0x100        ; ports start at offset 0x100
           
           mov  eax,SATA_SIG_NONE
           mov  ecx,fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSSTS]
           and  cx,0x0F0F
           cmp  cl,3
           jne  short @f
           
           mov  eax,SATA_SIG_NON_ACT
           cmp  ch,1
           jne  short @f
           
           mov  eax,fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSIG]
@@:        ret
sata_get_port_type endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send an io command to the device
; on entry:
;  es = segment of EBDA
;  edx = zero-based port number
;  fs:ebx -> SATA_DEVICE
;  es:esi -> SATA_CONTROLLER
;  fs:edi -> AHCI register set
;  stack contains: (cdecl)
;    ioflag, command, lba_low, lba_high, buflen,  count,   packet,  buffer
;    [bp+4], [bp+6],  [bp+8],  [bp+12],  [bp+16], [bp+20], [bp+22], [bp+26]
;    (word)  (word)   (dword)  (dword)   (dword)  (word)   (dword)  (dword)
; on return:
;  eax = count of bytes transferred
;      = -1 = error
; destroys none (except eax)
;  (since all of this will be in (un)real mode, we only allow 1 PRD Table entry which allows
;   up to 4Meg to be transferred.)
sata_cmd_data_io proc near ; don't add anything here
           push bp
           mov  bp,sp
           sub  sp,10

sata_cmd_port   equ  [bp-4]   ;  dword
sata_cmd_slot   equ  [bp-8]   ;  dword
sata_cmd_atapi  equ  [bp-9]   ;  byte
           
           ; save the registers we use
           push edx
           push ecx
           push ebx
           push esi
           push edi

           mov  sata_cmd_port,edx
           
           ; calculate port address (simply multiply by 0x80 + 0x100)
           shl  edx,7
           add  edx,0x100        ; ports start at offset 0x100
           ; clear any pending interrupt bits
           mov  dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxIS],0xFFFFFFFF

           ; find a free slot to use
           mov  edx,sata_cmd_port
           call sata_find_cmdslot
           cmp  eax,-1
           je   sata_cmd_data_io_done
           mov  sata_cmd_slot,eax

           imul eax,sizeof(HBA_CMD_LIST)
           add  eax,SATA_DEVICE->command_list
           add  eax,ebx
           mov  edx,fs:[eax+HBA_CMD_LIST->ctba]

           ; fs:ebx -> SATA_DEVICE->
           ; fs:eax -> SATA_DEVICE->command_list[slot]
           ; fs:edx -> SATA_DEVICE->command_table[slot]
           
           ; are we an atapi device
           xor  cl,cl
           cmp  dword fs:[ebx+SATA_DEVICE->device_sig],SATA_SIG_ATA
           je   short @f
           inc  cl
@@:        mov  sata_cmd_atapi,cl
           
           ; setup the Command List
           push ebx
           movzx ecx,byte sata_cmd_atapi
           shl  ecx,5
           movzx ebx,byte [bp+4] ; send or receive
           shl  ebx,6
           or   ecx,ebx
           pop  ebx
           or   ecx,((1 << 16) | (1 << 7) | (sizeof(FIS_REG_H2D) / sizeof(dword)))
           mov  fs:[eax+HBA_CMD_LIST->dword0],ecx
           mov  dword fs:[eax+HBA_CMD_LIST->prdbc],0
           push eax              ; save the address to the hba command list

           ; setup the Command Table
           push edi
           mov  ax,sizeof(SATA_COMMAND_TABLE)
           mov  edi,edx
           call memset32
           pop  edi

           lea  eax,[edx+SATA_COMMAND_TABLE->cfis]
           mov  byte fs:[eax+FIS_REG_H2D->fis_type],0x27
           mov  byte fs:[eax+FIS_REG_H2D->flags],(1 << 7)
           ; assume is not atapi
           mov  cx,[bp+6]        ; command
           mov  fs:[eax+FIS_REG_H2D->command],cl
           mov  byte fs:[eax+FIS_REG_H2D->features],0
           cmp  byte sata_cmd_atapi,0
           je   short @f
           ; is atapi
           push esi
           mov  esi,[bp+22]      ; packet pointer
           mov  ecx,fs:[esi+0]
           mov  fs:[edx+SATA_COMMAND_TABLE->acmd+0],ecx
           mov  ecx,fs:[esi+4]
           mov  fs:[edx+SATA_COMMAND_TABLE->acmd+4],ecx
           mov  ecx,fs:[esi+8]
           mov  fs:[edx+SATA_COMMAND_TABLE->acmd+8],ecx
           mov  ecx,fs:[esi+12]
           mov  fs:[edx+SATA_COMMAND_TABLE->acmd+12],ecx
           pop  esi
           mov  byte fs:[eax+FIS_REG_H2D->command],ATA_CMD_PACKET
           mov  byte fs:[eax+FIS_REG_H2D->features],1
           mov  dword [bp+8],0   ; make sure lba = 0
           mov  word [bp+20],0   ; make sure count = 0

@@:        ; If we are using 28-bit LBA's, we use LBA0, LBA1, LBA2, and the
           ;  lower half of dev_head.
           ; If we are using 48-bit LBA's, we use LBA0, 1, 2, 3, 4, and 5.
           ; It won't matter that we set the lower half of Dev_Head when
           ;  using 48-bit LBA's, so there is no need for an if() statement here
           ;  or some other way to determine if we are using 48-bit LBA's.
           ;  A 28-bit command will only use LBA0, 1, 2, and half of dev_head.
           ;  A 48-bit command will only use LBA0, 1, 2, 3, 4, and 5, not dev_head.
           mov  ecx,[bp+8]       ; lba low
           mov  fs:[eax+FIS_REG_H2D->lba_0],cl
           shr  ecx,8
           mov  fs:[eax+FIS_REG_H2D->lba_1],cl
           shr  ecx,8
           mov  fs:[eax+FIS_REG_H2D->lba_2],cl
           shr  ecx,8
           push cx
           and  cl,0x0F
           or   cl,(0xA0 | 0x40)
           mov  fs:[eax+FIS_REG_H2D->dev_head],cl
           pop  cx
           mov  fs:[eax+FIS_REG_H2D->lba_3],cl
           mov  ecx,[bp+12]       ; lba high
           mov  fs:[eax+FIS_REG_H2D->lba_4],cl
           mov  fs:[eax+FIS_REG_H2D->lba_5],ch
           mov  byte fs:[eax+FIS_REG_H2D->features_exp],0

           mov  cx,[bp+20]       ; count
           mov  fs:[eax+FIS_REG_H2D->sect_count_low],cl
           mov  fs:[eax+FIS_REG_H2D->sect_count_high],ch
           mov  dword fs:[eax+FIS_REG_H2D->reserved],0
           ; setting bit 3 ensures that this FIS gets sent since the Device Control
           ; register will have bit 3 cleared.  A FIS will only be sent if the
           ; Command register and command field are different, or the Device Control
           ; register and the control field are different.
           mov  byte fs:[eax+FIS_REG_H2D->control],(1 << 3)
           mov  dword fs:[eax+FIS_REG_H2D->resv],0

           ; we only support 1 entry since this would transfer up to 4Megs of data
           lea  edx,[edx+SATA_COMMAND_TABLE->prdt_entries]
           mov  ecx,[bp+26]      ; buffer
           mov  fs:[edx+SATA_PRDT_ENTRY->dba],ecx
           mov  dword fs:[edx+SATA_PRDT_ENTRY->dbau],0
           mov  dword fs:[edx+SATA_PRDT_ENTRY->reserved],0
           mov  ecx,[bp+16]      ; buf len
           mov  fs:[edx+SATA_PRDT_ENTRY->dword3],ecx

           ; if the command engine is not running, start it
           mov  edx,sata_cmd_port
           shl  edx,7
           add  edx,0x100        ; ports start at offset 0x100
           ; clear any pending interrupt bits
           test dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxCMD],(1 << 15)
           jnz  short @f
           push edx
           mov  edx,sata_cmd_port
           call sata_start_cmd
           pop  edx

           ; wait until the port is no longer busy before issuing a new command
@@:        test dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxTFD],((1 << 7) | (1 << 3))  ; BSY or DRQ
           jnz  short @b

           ; issue command
           mov  ecx,sata_cmd_slot
           mov  eax,1
           shl  eax,cl
           mov  fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxCI],eax
           
           ; wait for the completion of command
           xor  cx,cx            ; assume no error
@@:        test fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxCI],eax
           jz   short @f

           ; was there an error?
           test dword fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxIS], \
              ((1 << 4) | (1 << 6) | (1 << 7) | (1 << 22) | (1 << 23) | (1 << 24) | (1 << 26) | (1 << 27) | (1 << 28) | (1 << 29) | (1 << 30))
           jz   short @b
           mov  cx,1             ; error

           ; clear any status bits
@@:        mov  eax,fs:[edi+AHCI_CTRL_REGS->HBA_HC_Interrupt_status]
           push eax
           mov  eax,fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxIS]
           mov  fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxIS],eax
           mov  eax,fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSERR]
           mov  fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSERR],eax
           pop  eax
           mov  fs:[edi+AHCI_CTRL_REGS->HBA_HC_Interrupt_status],eax

           ; if cx = 0, successful transfer
           pop  eax              ; restore the address to the hba command list
           mov  eax,fs:[eax+HBA_CMD_LIST->prdbc]
           or   cx,cx
           jz   short @f
           xor  eax,eax
           ; mov  edx,sata_cmd_port
           ; call sata_stop_cmd
           ; call sata_start_cmd

           ; count of bytes transferred
@@:        ;mov  es:[EBDA_DATA->trsfbytes],eax
           
sata_cmd_data_io_done:
           ; restore the registers we used
           pop  edi
           pop  esi
           pop  ebx
           pop  ecx
           pop  edx

           mov  sp,bp            ; restore the stack
           pop  bp
           ret
sata_cmd_data_io endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; find a free command slot
; on entry:
;  es -> EBDA
;  edx = zero-based port number
;  es:esi -> SATA_CONTROLLER
;  fs:edi -> AHCI register set
; on return
;  eax = slot number (or -1 if none found)
; destroys none
sata_find_cmdslot proc near uses ebx ecx edx
           ; An empty command slot has its respective bit cleared to 0 in both the PxCI 
           ;  and PxSACT registers.
           ; (The PxSACT register is used for Native Queue Commands, but still used here for completeness)
           
           ; calculate port address (simply multiply by 0x80 + 0x100)
           shl  edx,7
           add  edx,0x100        ; ports start at offset 0x100
           
           ; If not set in SACT and CI, the slot is free
           mov  eax,fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxSACT]
           or   eax,fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxCI]

           ; count of valid slots
           movzx ebx,byte es:[esi+SATA_CONTROLLER->command_slots]
           
           ; find a zero bit in eax starting with bit 0
           mov  edx,1
           xor  ecx,ecx
@@:        test eax,edx
           jz   short @f
           shl  edx,1
           inc  ecx
           cmp  ecx,ebx
           jb   short @b
           mov  ecx,-1

@@:        mov  eax,ecx
           ret
sata_find_cmdslot endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get the controller and device data pointers from dl
;  a controller and drive are encoded in dl as:
; on entry:
;  es = segment of EBDA
;  dl = BIOS device address
; on return
;  fs:ebx -> SATA_DEVICE
;  es:esi -> this SATA_CONTROLLER structure
;  edx = port number (zero based)
sata_get_cntrl_device proc near uses eax
           ; dl = our device address
           ;  - reserved field containing zeros 7:6     (xx)
           ;  - zero based controller index in bits 5:4 (II)
           ;  - zero based device number in bits 3:0    (DDDD)
           
           ; point to our controller struct (use es:esi+SATA_CONTROLLER->)
           and  dl,0011111b
           movzx esi,dl
           shr  esi,4
           and  esi,0x3
           imul esi,sizeof(SATA_CONTROLLER)
           add  esi,EBDA_DATA->sata_ahci_cntrls

           ; point to our device struct (use fs:ebx+SATA_DEVICE->)
           and  edx,0xF
           imul ebx,edx,sizeof(dword)
           add  ebx,SATA_CONTROLLER->device_data
           add  ebx,esi
           mov  ebx,es:[ebx]
           
           movzx edx,byte fs:[ebx+SATA_DEVICE->port]
           ret
sata_get_cntrl_device endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; load SATA boot sector
; on entry:
;  eax = base_lba on SATA device of this 'partition'
;  es = segment of EBDA
;  dl = device
; on return
;  al = status = 0 = successful
;  ah = drive number to return (0x8x, 0xEx)
; destroys nothing
boot_sata_funtion proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,2

boot_sata_device  equ  [bp-2]
           
           ; save the device and base lba values
           mov  boot_sata_device,dl
           mov  es:[EBDA_DATA->sata_disk_base_lba],eax

           ; get the controller and device data pointers
           call sata_get_cntrl_device

           ;;;;;;; if we are a cdrom, we need to create a packet instead

           ; read the first sector from the disk
           mov  edi,es:[esi+SATA_CONTROLLER->base]
           mov  ecx,es:[EBDA_DATA->sata_disk_base_lba]
           lea  eax,[ebx+SATA_DEVICE->rxtx_buffer]
           push eax      ; physical address of buffer
           pushd 0       ; physical address of command packet
           push  1       ; count
           push  0       ; high word of buffer length
           push  word fs:[ebx+SATA_DEVICE->blk_size] ; buffer length
           pushd 0       ; lba_high
           push  ecx     ; lba_low
           push ATA_CMD_READ_SECTORS ; command
           push SATA_DIR_RECV
           call sata_cmd_data_io
           add  sp,26
           
           movzx ecx,word fs:[ebx+SATA_DEVICE->blk_size]
           cmp  eax,ecx
           jne  short sata_boot_error
           
           ;; if we are a cdrom, we need to find the boot catalog (like cdemu does)

           lea  esi,[ebx+SATA_DEVICE->rxtx_buffer]
           
           ; copy the boot sector to 0x07C0:0000
           push es
           xor  ax,ax
           mov  es,ax
           mov  di,0x7C00
           mov  cx,(512>>2)
@@:        mov  eax,fs:[esi]
           add  esi,4
           stosd
           loop @b
           pop  es

           ; set the emulation type and DL value
           mov  eax,fs:[ebx+SATA_DEVICE->device_sig]
           mov  es:[EBDA_DATA->sata_disk_media],eax
           mov  al,fs:[ebx+SATA_DEVICE->device_num]
           add  al,0x80  ; ben 0x90
           mov  es:[EBDA_DATA->sata_disk_emulated_drive],al

           mov  al,boot_sata_device
           mov  es:[EBDA_DATA->sata_disk_emulated_device],al
           mov  ah,es:[EBDA_DATA->sata_disk_emulated_drive]
           mov  byte es:[EBDA_DATA->sata_disk_active],1

           xor  al,al
           mov  sp,bp            ; restore the stack
           pop  bp
           ret

sata_boot_error:
           mov  al,1
           mov  sp,bp            ; restore the stack
           pop  bp
           ret
boot_sata_funtion endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; SATA hard drive disk services
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
int13_satadisk_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           sub  sp,30

sd_sv_port      equ  [bp-4]   ; dword
sd_sv_count     equ  [bp-6]   ; word
sd_sv_cylinder  equ  [bp-8]   ; word
sd_sv_sector    equ  [bp-10]   ; word
sd_sv_head      equ  [bp-12]   ; word
sd_sv_lba_low   equ  [bp-16]   ; dword
sd_sv_lba_high  equ  [bp-20]   ; dword
sd_sv_cur_gdt   equ  [bp-28]   ; qword (fword + 2 filler)
sd_sv_cur_a20   equ  [bp-29]   ; byte

           ; retrieve the current GDT, and set it to ours
           push fs                 ; preserve the fs segment register
           sgdt far sd_sv_cur_gdt ; save the current GDT address
           call unreal_post        ;
           mov  sd_sv_cur_a20,al  ; save current a20 status
           
           ; set ds = bios data area (0x0040)
           mov  ax,0x0040
           mov  ds,ax
           
           ; clear completion flag
           mov  byte [0x008E],0

           ; make sure the device is valid
           mov  dx,REG_DX
           cmp  dl,0x80  ; ben 0x90
           jb   sd_int13_fail
           cmp  dl,(0x80 + SATA_DEVICE_MAX)   ; ben 0x90
           jae  sd_int13_fail

           ; get our emulated device value
           mov  dl,es:[EBDA_DATA->sata_disk_emulated_device]
           ; get the controller and device data pointers
           call sata_get_cntrl_device
           mov  sd_sv_port,edx
           
           mov  ah,REG_AH
           ; ah = service
           ; es = segment of EBDA
           ; fs:ebx -> SATA_DEVICE
           ; es:esi -> this SATA_CONTROLLER structure
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; controller reset
           cmp  ah,0x00
           jne  short @f
           ; we ignore this one, return success
           jmp  sd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disk status
@@:        cmp  ah,0x01
           jne  short @f
           mov  ah,[0x0074]
           mov  REG_AH,ah
           mov  byte [0x0074],0x00
           or   ah,ah
           jnz  sd_int13_fail_nostatus
           jmp  sd_int13_success_noah
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; transfer sectors
@@:        cmp  ah,0x02          ; read disk sectors
           je   short sd_int13_transfer
           cmp  ah,0x03          ; write disk sectors
           je   short sd_int13_transfer
           cmp  ah,0x04          ; verify disk sectors
           jne  @f
sd_int13_transfer:
           xor  ah,ah
           mov  al,REG_AL
           mov  sd_sv_count,ax
           mov  al,REG_CL
           shl  ax,2
           and  ah,0x03
           mov  al,REG_CH
           mov  sd_sv_cylinder,ax
           xor  ah,ah
           mov  al,REG_CL
           and  al,0x3F
           mov  sd_sv_sector,ax
           mov  al,REG_DH
           mov  sd_sv_head,ax

           ; if count > 128, or count == 0, or sector == 0, error
           cmp  word sd_sv_count,0
           je   sd_int13_fail
           cmp  word sd_sv_count,128
           ja   sd_int13_fail
           cmp  word sd_sv_sector,0
           je   sd_int13_fail

           ; check that the chs value is within our lchs value
           mov  ax,fs:[ebx+SATA_DEVICE->cylinders]
           cmp  sd_sv_cylinder,ax
           jae  sd_int13_fail
           mov  ax,fs:[ebx+SATA_DEVICE->heads]
           cmp  sd_sv_head,ax
           jae  sd_int13_fail
           mov  ax,fs:[ebx+SATA_DEVICE->spt]
           cmp  sd_sv_sector,ax
           ja   sd_int13_fail

           ; if we are verifying a sector(s), just return as good
           cmp  byte REG_AH,0x04
           je   sd_int13_success

           ;;;; if we are a cdrom, we need to use a packet interface

           ; lba = (((cylinder * lchs_heads) + head) * lchs_spt) + (sector - 1);
           movzx eax,word sd_sv_cylinder
           movzx ecx,word fs:[ebx+SATA_DEVICE->heads]
           mul  ecx
           movzx ecx,word sd_sv_head
           add  eax,ecx
           movzx ecx,word fs:[ebx+SATA_DEVICE->spt]
           mul  ecx
           movzx ecx,word sd_sv_sector
           add  eax,ecx
           dec  eax
           mov  sd_sv_lba_low,eax
           mov  dword sd_sv_lba_high,0

           mov  cx,SATA_DIR_RECV      ; read
           mov  di,ATA_CMD_READ_SECTORS
           cmp  byte REG_AH,0x02
           je   short sd_int13_read
           mov  cx,SATA_DIR_SEND      ; write
           mov  di,ATA_CMD_WRITE_SECTORS
sd_int13_read:
           ; physical address
           movzx eax,word REG_ES
           shl  eax,4
           movzx edx,word REG_BX
           add  eax,edx
           push eax      ; physical address of buffer
           pushd 0       ; physical address of command packet
           ; count of sectors and buffer length
           movzx edx,word sd_sv_count
           push dx       ; count
           movzx eax,word fs:[ebx+SATA_DEVICE->blk_size]
           mul  edx
           push eax      ; buffer length
           ; calculate lba
           xor  edx,edx
           mov  eax,es:[EBDA_DATA->sata_disk_base_lba]
           add  eax,sd_sv_lba_low
           adc  edx,sd_sv_lba_high
           push edx      ; lba_high
           push eax      ; lba_low
           push di       ; command
           push cx       ; direction
           mov  edi,es:[esi+SATA_CONTROLLER->base]
           mov  edx,sd_sv_port
           call sata_cmd_data_io
           add  sp,26

           movzx ecx,word sd_sv_count
           mov  REG_AL,cl
           movzx edx,word fs:[ebx+SATA_DEVICE->blk_size]
           imul edx,ecx
           cmp  eax,edx
           je   sd_int13_success
           
           ; else there was an error
           mov  word REG_AX,0x0C00
           jmp  sd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; format disk track
@@:        cmp  ah,0x05
           jne  short @f
           ; we currently don't support this function
           mov  byte REG_AH,0x01
           jmp  sd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get disk drive parameters
@@:        cmp  ah,0x08
           jne  short @f
           mov  word REG_AX,0x0000
           ; cylinder (ch = low 8 bits, cl = high bits in 7:6)
           mov  cx,fs:[ebx+SATA_DEVICE->cylinders]
           dec  cx               ; zero based
           xchg ch,cl
           shl  cl,6
           ; spt (low 5:0 bits of cl)
           mov  ax,fs:[ebx+SATA_DEVICE->spt]
           and  al,0x3F
           or   cl,al
           mov  REG_CX,cx
           ; zero based head in dh
           mov  ax,fs:[ebx+SATA_DEVICE->heads]
           dec  ax
           mov  REG_DH,al
           ; dl = count of drives
           mov  al,es:[esi+SATA_CONTROLLER->numdrives]
           mov  REG_DL,al
           ; es:di (floppies only)
           jmp  sd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize controller with drive parameters
@@:        cmp  ah,0x09
           jne  short @f
           
           jmp  sd_int13_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check drive ready
@@:        cmp  ah,0x10
           jne  short @f
           ; read the PxTFD register
           mov  edi,fs:[esi+SATA_CONTROLLER->base]
           mov  edx,sd_sv_port
           shl  edx,7
           add  edx,0x100        ; ports start at offset 0x100
           mov  eax,fs:[edi+edx+HBA_PORT_REGS->HBA_PORT_PxTFD]
           test al,ATA_CB_STAT_BSY
           jz   sd_int13_success
           mov  byte REG_AH,0xAA ; drive not ready
           jmp  sd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disk drive size
@@:        cmp  ah,0x15
           jne  short @f
           mov  eax,fs:[ebx+SATA_DEVICE->sectors_low]
           mov  REG_DX,ax
           shr  eax,16
           mov  REG_CX,ax
           mov  byte REG_AH,0x03 ; hard disk
           jmp  sd_int13_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set media type format
@@:        cmp  ah,0x18
           jne  short @f
           mov  byte REG_AH,0x01 ; function not available
           jmp  sd_int13_fail_noah

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
           jmp  sd_int13_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS extended services
@@:        cmp  ah,0x42          ; extended read
           je   short sd_int13_ext_transfer
           cmp  ah,0x43          ; extended write
           je   short sd_int13_ext_transfer
           cmp  ah,0x44          ; extended verify
           je   short sd_int13_ext_transfer
           cmp  ah,0x47          ; extended seek
           jne  @f
sd_int13_ext_transfer:
           push es
           mov  di,REG_SI
           mov  ax,REG_DS
           mov  es,ax
           mov  eax,es:[di+EXT_SERV_PACKET->ex_lba+0] ; get low 32-bits
           mov  edx,es:[di+EXT_SERV_PACKET->ex_lba+4] ; get high 32-bits
           mov  cx,es:[di+EXT_SERV_PACKET->ex_size]
           pop  es
           ; if size of packet < 16, error
           cmp  cx,16
           jb   sd_int13_fail
           ; if edx:eax >= EBDA_DATA->ata_0_0_sectors, error
           cmp  edx,fs:[ebx+SATA_DEVICE->sectors_high]
           ja   sd_int13_fail
           jb   short sd_int13_ext_transfer1
           cmp  eax,fs:[ebx+SATA_DEVICE->sectors_low]
           jae  sd_int13_fail
sd_int13_ext_transfer1:
           ; if we are verifying or seeking to sector(s), just return as good
           mov  ah,REG_AH
           cmp  ah,0x44
           je   sd_int13_success
           cmp  ah,0x47
           je   sd_int13_success

           ; else do the transfer
           mov  cx,SATA_DIR_RECV      ; read
           mov  word sd_sv_count,ATA_CMD_READ_SECTORS
           cmp  byte REG_AH,0x42
           je   short sd_int13_read1
           mov  cx,SATA_DIR_SEND      ; write
           mov  word sd_sv_count,ATA_CMD_WRITE_SECTORS
sd_int13_read1:
           push ds
           mov  di,REG_SI
           mov  ds,REG_DS
           ; physical address
           movzx eax,word [di+EXT_SERV_PACKET->ex_segment] ; segment of buffer
           shl  eax,4
           movzx edx,word [di+EXT_SERV_PACKET->ex_offset]  ; offset of buffer
           add  eax,edx

           ;;; if this is a cdrom, we need to do a packet interface
           
           push eax      ; physical address of buffer
           pushd 0       ; physical address of command packet
           ; count of sectors and buffer length
           movzx edx,word [di+EXT_SERV_PACKET->ex_count]
           push dx       ; count
           movzx eax,word fs:[ebx+SATA_DEVICE->blk_size]
           mul  edx
           push eax      ; buffer length
           ; calculate lba
           xor  edx,edx
           mov  eax,es:[EBDA_DATA->sata_disk_base_lba]
           add  eax,[di+EXT_SERV_PACKET->ex_lba+0]
           adc  edx,[di+EXT_SERV_PACKET->ex_lba+4]
           push edx      ; lba_high
           push eax      ; lba_low
           push word sd_sv_count ; command
           push cx       ; direction
           mov  edi,es:[esi+SATA_CONTROLLER->base]
           mov  edx,sd_sv_port
           call sata_cmd_data_io
           add  sp,26
           
           ;;;; ben: this needs to be different......
           mov  di,REG_SI
           movzx ecx,word [di+EXT_SERV_PACKET->ex_count]
           movzx edx,word fs:[ebx+SATA_DEVICE->blk_size]
           imul edx,ecx
           cmp  eax,edx
           pop  ds
           je   short sd_int13_success

           ; else there was an error
           mov  word REG_AH,0x0C
           jmp  short sd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS media
@@:        cmp  ah,0x45          ; lock/unlock drive
           je   short sd_int13_media
           cmp  ah,0x49          ; extended media change
           jne  short @f
sd_int13_media:
           ; we don't do anything, so just return success
           jmp  short sd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS eject media
@@:        cmp  ah,0x46
           jne  short @f
           mov  byte REG_AH,0xB2 ; media not removable
           jmp  short sd_int13_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS get drive parameters
@@:        cmp  ah,0x48
           jne  short @f
           push es
           mov  es,REG_DS
           mov  di,REG_SI
           mov  ax,sd_sv_port
           call int13_edd
           pop  es
           or   ax,ax
           jnz  short sd_int13_fail
           jmp  short sd_int13_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS set hardware configuration
@@:        cmp  ah,0x4E
           jne  short @f
           mov  al,REG_AL
           cmp  al,0x01          ; disable prefetch
           je   short sd_int13_success
           cmp  al,0x03          ; set pio mode 0
           je   short sd_int13_success
           cmp  al,0x04          ; set default pio transfer mode
           je   short sd_int13_success
           cmp  al,0x06          ; disable inter 13h dma
           je   short sd_int13_success
           jmp  short sd_int13_fail ; else, fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        ;cmp  ah,0x  ; next value
           ;jne  short @f
           ;
           ;
           ;jmp  sd_int13_success

           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; print a message of this unknown call value
           push ds
           push cs
           pop  ds
           shr  ax,8
           push ax
           mov  si,offset sd_int13_unknown_call_str
           call bios_printf
           add  sp,2
           call freeze
           pop  ds

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function failed, or we didn't support function in AH
sd_int13_fail:
           mov  byte REG_AH,0x01 ; invalid function or parameter
sd_int13_fail_noah:
           mov  al,REG_AH
           mov  [0x0074],al
sd_int13_fail_nostatus:
           or   word REG_FLAGS,0x0001
           jmp  short @f

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function was successful
sd_int13_success:
           mov  byte REG_AH,0x00 ; success
sd_int13_success_noah:
           mov  al,REG_AH
           mov  [0x0074],al
           and  word REG_FLAGS,(~0x0001)

@@:        ; restore the caller's gdt and a20 line
           lgdt far sd_sv_cur_gdt
           mov  al,sd_sv_cur_a20
           call set_enable_a20
           pop  fs

           mov  sp,bp
           pop  bp
           ret
int13_satadisk_function endp

sd_int13_unknown_call_str  db 13,10,'*** sd_int13: Unknown call 0x%02X ***',13,10,0

.endif

.end
