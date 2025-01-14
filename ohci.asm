comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: ohci.asm                                                           *
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
*   ohci include file                                                      *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.15                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 8 Dec 2024                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

.if DO_INIT_BIOS32

OHCI_OP_REGS struct            ; initial values
  HcRevision           dword   ; 0x00000110
  HcControl            dword   ; 0x00000000
  HcCommandStatus      dword   ; 0x00000000
  HcInterruptStatus    dword   ; 0x00000000
  HcInterruptEnable    dword   ; 0x00000000
  HcInterruptDisable   dword   ; 0x00000000
  HcHCCA               dword   ; 0x00000000
  HcPeriodCurrentED    dword   ; 0x00000000
  HcControlHeadED      dword   ; 0x00000000
  HcControlCurrentED   dword   ; 0x00000000
  HcBulkHeadED         dword   ; 0x00000000
  HcBulkCurrentED      dword   ; 0x00000000
  HcDoneHead           dword   ; 0x00000000
  HcFmInterval         dword   ; 0x00002EDF
  HcFmRemaining        dword   ; 0x00000000
  HcFmNumber           dword   ; 0x00000000
  HcPeriodicStart      dword   ; 0x00000000
  HcLSThreshold        dword   ; 0x00000628
  HcRhDescriptorA      dword   ; 0x10000901
  HcRhDescriptorB      dword   ; 0x00020000
  HcRhStatus           dword   ; 0x00000000
  HcRhPortStatus       dup (1003 * sizeof(dword))
OHCI_OP_REGS ends

; HC Control Status
HC_CONTROL_CBSR        equ  0x00000003
HC_CONTROL_PLE         equ  0x00000004
HC_CONTROL_IE          equ  0x00000008
HC_CONTROL_CLE         equ  0x00000010
HC_CONTROL_BLE         equ  0x00000020
HC_CONTROL_HCFS        equ  0x000000C0
HC_CONTROL_IR          equ  0x00000100
HC_CONTROL_RWC         equ  0x00000200
HC_CONTROL_RWE         equ  0x00000400
HC_CONTROL_HCFS_OPER   equ  0x00000080

; HC Command Status
HC_COMMAND_STATUS_HCR  equ  0x00000001
HC_COMMAND_STATUS_CLF  equ  0x00000002
HC_COMMAND_STATUS_BLF  equ  0x00000004
HC_COMMAND_STATUS_OCR  equ  0x00000008
HC_COMMAND_STATUS_SOC  equ  0x00030000

; HC Interrupt Status
HC_INT_STATUS_SO       equ  0x00000001
HC_INT_STATUS_WDH      equ  0x00000002
HC_INT_STATUS_SF       equ  0x00000004
HC_INT_STATUS_RD       equ  0x00000008
HC_INT_STATUS_UE       equ  0x00000010
HC_INT_STATUS_FNO      equ  0x00000020
HC_INT_STATUS_RHSC     equ  0x00000040
HC_INT_STATUS_OC       equ  0x04000000

; HCRhPortStatus[x]
HC_PORT_STATUS_CCS     equ  0x00000001
HC_PORT_STATUS_PES     equ  0x00000002
HC_PORT_STATUS_PSS     equ  0x00000004
HC_PORT_STATUS_POCI    equ  0x00000008
HC_PORT_STATUS_PRS     equ  0x00000010
HC_PORT_STATUS_PPS     equ  0x00000100
HC_PORT_STATUS_LSDA    equ  0x00000200
HC_PORT_STATUS_CSC     equ  0x00010000
HC_PORT_STATUS_PESC    equ  0x00020000
HC_PORT_STATUS_PSSC    equ  0x00040000
HC_PORT_STATUS_OCIC    equ  0x00080000
HC_PORT_STATUS_PRSC    equ  0x00100000

OHCI_MEMORY_SIZE   equ  ((2080 * 2) * USB_DEVICE_MAX)

OHCI_TOKEN_SETUP       equ  0
OHCI_TOKEN_OUT         equ  1
OHCI_TOKEN_IN          equ  2
OHCI_TOKEN_RESV        equ  3  ; error if this is found

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Endpoint Descriptors
OHCI_ED_DIR_TD     equ  0   ; from TD
OHCI_ED_DIR_OUT    equ  1   ; OUT
OHCI_ED_DIR_IN     equ  2   ; IN

OHCI_ED_MPS_MASK   equ  0x07FF0000
OHCI_ED_MPS_SHFT   equ  16
OHCI_ED_F          equ  0x00008000
OHCI_ED_sKip       equ  0x00004000
OHCI_ED_S          equ  0x00002000
OHCI_ED_D_MASK     equ  0x00001800
OHCI_ED_D_SHFT     equ  11
OHCI_ED_EN_MASK    equ  0x00000780
OHCI_ED_EN_SHFT    equ  7
OHCI_ED_FA_MASK    equ  0x0000007F
OHCI_ED_TOGGLE_0   equ  0x00000000
OHCI_ED_TOGGLE_1   equ  (1<<1)
OHCI_ED_HALTED     equ  (1<<0)

OHCI_ED struct
  flags      dword  ;
  tailp      dword  ;
  headp      dword  ;
  nexted     dword  ;
  r0         dword  ;
  r1         dword  ;
  r2         dword  ;
  r3         dword  ;
OHCI_ED ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Transfer Descriptors
OHCI_TD_CC_MASK    equ  0xF0000000
OHCI_TD_CC_SHFT    equ  28
OHCI_TD_EC_MASK    equ  0x0C000000
OHCI_TD_EC_SHFT    equ  26
OHCI_TD_T_MASK     equ  0x03000000
OHCI_TD_T_SHFT     equ  24
OHCI_iTD_FC_MASK   equ  0x03000000
OHCI_iTD_FC_SHFT   equ  24
OHCI_TD_DI_MASK    equ  0x00E00000
OHCI_TD_DI_SHFT    equ  21
OHCI_TD_DP_MASK    equ  0x00180000
OHCI_TD_DP_SHFT    equ  19
OHCI_TD_R          equ  0x00040000

OHCI_TD_FROM_ED    equ  (0<<1)
OHCI_TD_FROM_TD    equ  (1<<1)

OHCI_TD_T0_MASK    equ  0x01000000

; must be a multiple of 32 bytes
OHCI_TD struct
  flags      dword  ;
  cbp        dword  ;
  nexttd     dword  ;
  be         dword  ;
  ; the following items are our stuff
  our_cbp    dword  ;
  our_size   dword  ;
  r0         dword  ;
  r1         dword  ;
OHCI_TD ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; detect a ohci controller via the PCI services
; on entry:
;  es -> EBDA
; on return
;  nothing
; destroys none
init_ohci_boot  proc near uses alld
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; try to detect a OHCI by finding a OHCI PCI controller
           xor  esi,esi
ohci_cntrlr_detection:
           push esi
           ;         unused   class   subclass prog int
           mov  ecx,00000000_00001100_00000011_00010000b
           mov  ax,0xB103
           int  1Ah
           pop  esi
           jc   init_ohci_boot_done

           ; found a OHCI controller, so initialize it
           call ohci_initialize
           jc   init_ohci_boot_next

           ; initialize the stack
           call ohci_stack_initialize
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; see if there are any devices present and enumerate them
           xor  edx,edx
           ; point to our controller's block memory (use es:esi+USB_CONTROLLER->)
           push esi
           mov  ebp,esi          ; save the controller index in ebp
           imul esi,sizeof(USB_CONTROLLER)
           add  esi,EBDA_DATA->usb_ohci_cntrls

           ; initialize our callback pointers
           mov  word es:[esi+USB_CONTROLLER->callback_bulk],offset ohci_do_bulk_packet
           mov  word es:[esi+USB_CONTROLLER->callback_control],offset ohci_control_packet
           mov  byte es:[esi+USB_CONTROLLER->device_cnt],0

ohci_dev_detection:
           call ohci_port_reset
           or   al,al
           jz   short @f
           
           ; allocate the devices memory block
           movzx ebx,byte es:[esi+USB_CONTROLLER->device_cnt]
           imul ebx,sizeof(dword)
           add  ebx,USB_CONTROLLER->device_data
           add  ebx,esi
           mov  eax,sizeof(USB_DEVICE)
           mov  ecx,1
           ;push dx
           ;mov  dx,offset mem_ohci_device_data
           call memory_allocate
           ;pop  dx
           mov  es:[ebx],eax
           mov  ebx,eax
           
           mov  al,es:[esi+USB_CONTROLLER->device_cnt]
           mov  fs:[ebx+USB_DEVICE->device_num],al

           ; we have something connected and enabled
           call ohci_enumerate
           or   ax,ax
           jnz  short @f

           ; mark the controller type (and index)
           mov  ax,bp            ; controller index
           shl  al,4             ; index is in bits 5:4
           or   al,USB_CONTROLLER_OHCI
           mov  fs:[ebx+USB_DEVICE->controller],al
           
           ; mount the drive
           call usb_mount_device
           or   al,al
           jz   short @f

           ; increment the count of devices found
           inc  byte es:[esi+USB_CONTROLLER->device_cnt]
           cmp  byte es:[esi+USB_CONTROLLER->device_cnt],USB_DEVICE_MAX
           je   short ohci_dev_detection0

           ; try the next port
@@:        inc  edx
           movzx eax,byte es:[esi+USB_CONTROLLER->numports]
           cmp  edx,eax
           jb   short ohci_dev_detection

           ; if no devices found, stop the controller
ohci_dev_detection0:
           cmp  byte es:[esi+USB_CONTROLLER->device_cnt],0
           jne  short @f

           mov  edi,es:[esi+USB_CONTROLLER->base]
           and  dword fs:[edi+OHCI_OP_REGS->HcControl],(~0x0000003C) ; clear bits 5:2 (disable all lists)

           ; and free the allocated memory
           mov  eax,es:[esi+USB_CONTROLLER->base_memory]
           or   eax,eax
           jz   short @f
           call memory_free

           ; loop so that we can see if there are any more
@@:        pop  esi
init_ohci_boot_next:
           inc  esi
           cmp  esi,MAX_USB_CONTROLLERS
           jb   ohci_cntrlr_detection
           
init_ohci_boot_done:
           ret
init_ohci_boot  endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the found ohci controller
; on entry:
;  es -> EBDA
;  bh = bus
;  bl = dev/func
;  si = 0 for first controller, 1 for second, 2 for third, etc
; on return
;  carry clear if successful
; destroys none
ohci_initialize proc near uses alld ds
           
           ; the OHCI is memmapped, so find the address
           mov  ax,0xB10A
           mov  di,0x10
           int  1Ah
           ; is it Port IO?
           test cl,1
           jnz  ohci_initialize_error
           and  cl,(~0xF)
           mov  edi,ecx          ; save the base in edi
           
           ; make sure IO is allowed
           push edi
           mov  ax,0xB109
           mov  di,0x04
           int  1Ah
           or   cx,6             ; memory io and busmaster enable
           mov  ax,0xB10C
           mov  di,0x04
           int  1Ah
           pop  edi

           ; if the revision isn't 0x10, we don't support this OHCI
           mov  eax,fs:[edi]     ; eax = 0x00000110
           cmp  al,0x10
           jne  ohci_initialize_error
           
           ; start to save information
           imul si,sizeof(USB_CONTROLLER)
           add  si,EBDA_DATA->usb_ohci_cntrls
           
           mov  byte es:[si+USB_CONTROLLER->valid],0  ; not valid for now
           mov  es:[si+USB_CONTROLLER->busdevfunc],bx
           mov  es:[si+USB_CONTROLLER->base],edi
           mov  byte es:[si+USB_CONTROLLER->flags],0

           ; get the irq
           push edi
           mov  ax,0xB108
           mov  di,0x3C
           int  1Ah
           mov  es:[si+USB_CONTROLLER->irq],cl
           pop  edi
           
           ; reset the controller
           or   dword fs:[edi+OHCI_OP_REGS->HcCommandStatus],(1<<0)
           
           ; wait for it to be done
           mov  eax,USB_TDRST
           call mdelay

           ; did it finish?
           test dword fs:[edi+OHCI_OP_REGS->HcCommandStatus],(1<<0)
           jnz  short ohci_initialize_error

           ; wait for the recovery time
           mov  eax,USB_TRSTRCY
           call mdelay

           ; the controller should now be in the suspend state
           mov  eax,fs:[edi+OHCI_OP_REGS->HcControl]
           and  eax,HC_CONTROL_HCFS
           cmp  eax,HC_CONTROL_HCFS
           jne  short ohci_initialize_error

           ; the frame interval should be set to 0x2EDF (11,999d)
           mov  eax,fs:[edi+OHCI_OP_REGS->HcFmInterval]
           and  eax,0x3FFF
           cmp  eax,0x2EDF
           jne  short ohci_initialize_error

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we need to get the alignment requirement
           ;  write all 1's to the HcHCCA register and read back, do a 1's compliment, and add 1
           ;  this is the minimum alignment that must take place
           ;mov  dword fs:[edi+OHCI_OP_REGS->HcHCCA],0xFFFFFFFF
           ;mov  ecx,fs:[edi+OHCI_OP_REGS->HcHCCA]
           ;not  ecx
           ;inc  ecx
           ;cmp  ecx,4096         ; we don't support anything above 4k alignment
           ;ja   short ohci_initialize_error
           mov  ecx,16  ; align on a 16-byte boundary

           ; get the count of ports
           mov  eax,fs:[edi+OHCI_OP_REGS->HcRhDescriptorA]
           mov  es:[si+USB_CONTROLLER->numports],al
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we have found and initialized a OHCI
           ; (allocate some memory for it)
           mov  eax,OHCI_MEMORY_SIZE
           ;push dx
           ;mov  dx,offset mem_ohci_stack
           call memory_allocate
           ;pop  dx
           mov  es:[si+USB_CONTROLLER->base_memory],eax

           ; mark this information valid
           mov  byte es:[si+USB_CONTROLLER->valid],1

           ; print that we found a OHCI
           mov  ax,BIOS_BASE2
           mov  ds,ax
           push dword es:[si+USB_CONTROLLER->base_memory]
           movzx ax,byte es:[si+USB_CONTROLLER->irq]
           push ax
           movzx ax,byte es:[si+USB_CONTROLLER->numports]
           push ax
           push dword es:[si+USB_CONTROLLER->base]
           mov  si,offset ohci_found_str0
           call bios_printf
           add  sp,12

           ; successful return
           clc
           ret

ohci_initialize_error:
           stc
           ret
ohci_initialize endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the ohci's stack
; (we don't need periodical, only bulk)
; on entry:
;  es -> EBDA
;  bh = bus
;  bl = dev/func
;  si = 0 for first controller, 1 for second, 2 for third, etc
; on return
;  nothing
; destroys none
;
;  since we do not need a periodical stack, we don't use the HCCA. (don't enable it)
;  therefore, we only need the Control list and the Bulk list
;  each list is as follows:
;   we create a single Endpoint Descriptor (ED) for each available device, each pointing
;    to the next, with the last having a next-pointer of zero.
;   we then create (the memory area for) a string of TDs for each ED. 
;   this TD string must be at least 64 TDs per string
;   (this allows any device with 512-byte sectors and an 8 byte packet, or
;    this allows any device with 2048-byte sectors and a 32 byte packet)
;   we use a 16-byte ED and TD, and an extra 16 bytes for our storage area
;    making each ED and TD 32 bytes each.
;
;   (list (control or bulk))
;       |
;       v
;     [    ED    ]---->[   TD0   ]
;        |                |
;     [    ED    ]->   [   TD1   ]
;        |                |
;     [    ED    ]->   [   TD2   ]
;        |                |
;     [    ED    ]->   [   TD3   ]
;                         |
;                      [   TD4   ]
;                         |
;                      [   TD5   ]
;                         ...
;                      [   TDX   ]
;
;  Control:
;   USB_DEVICE_MAX * 32 bytes for the Control EDs:      USB_DEVICE_MAX * 32
;   USB_DEVICE_MAX * 32 * (512 / 8) bytes for TDs:      USB_DEVICE_MAX * 32 * (512 / 8)
;  Bulk:
;   USB_DEVICE_MAX * 32 bytes for the Control EDs:      USB_DEVICE_MAX * 32
;   USB_DEVICE_MAX * 32 * (512 / 8) bytes for TDs:      USB_DEVICE_MAX * 32 * (512 / 8)
;                                                    --------------------------------
;                                                      (((32 + (32 * (512 / 8))) * 2) * USB_DEVICE_MAX
;                                                    --------------------------------
;                            total bytes allocated:    (2080 * 2 * USB_DEVICE_MAX) = OHCI_MEMORY_SIZE
;
ohci_stack_initialize proc near uses alld
           ; point to our controller's block memory
           imul si,sizeof(USB_CONTROLLER)
           add  si,EBDA_DATA->usb_ohci_cntrls

           ; aligned memory starts here
           mov  edi,es:[si+USB_CONTROLLER->base_memory]

           ; create USB_DEVICE_MAXs EDs for the Control list
           mov  cx,USB_DEVICE_MAX
@@:        mov  dword fs:[edi+OHCI_ED->flags],OHCI_ED_sKip
           ;mov  dword fs:[edi+OHCI_ED->tailp],0
           ;mov  dword fs:[edi+OHCI_ED->headp],0
           lea  eax,[edi+sizeof(OHCI_ED)]
           mov        fs:[edi+OHCI_ED->nexted],eax
           ;mov  dword fs:[edi+OHCI_ED->r0],0
           ;mov  dword fs:[edi+OHCI_ED->r1],0
           ;mov  dword fs:[edi+OHCI_ED->r2],0
           ;mov  dword fs:[edi+OHCI_ED->r3],0
           ;add  ebx,(64 * sizeof(OHCI_TD))
           add  edi,sizeof(OHCI_ED)
           loop @b
           mov  dword fs:[edi+OHCI_ED->nexted - sizeof(OHCI_ED)],0

           ; create USB_DEVICE_MAXs EDs for the Bulk list
           mov  cx,USB_DEVICE_MAX
@@:        mov  dword fs:[edi+OHCI_ED->flags],OHCI_ED_sKip
           ;mov  dword fs:[edi+OHCI_ED->tailp],0
           ;mov  dword fs:[edi+OHCI_ED->headp],0
           lea  eax,[edi+sizeof(OHCI_ED)]
           mov        fs:[edi+OHCI_ED->nexted],eax
           ;mov  dword fs:[edi+OHCI_ED->r0],0
           ;mov  dword fs:[edi+OHCI_ED->r1],0
           ;mov  dword fs:[edi+OHCI_ED->r2],0
           ;mov  dword fs:[edi+OHCI_ED->r3],0
           ;add  ebx,(64 * sizeof(OHCI_TD))
           add  edi,sizeof(OHCI_ED)
           loop @b
           mov  dword fs:[edi+OHCI_ED->nexted - sizeof(OHCI_ED)],0

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now point the controller to this stack
           mov  edi,es:[si+USB_CONTROLLER->base]
           
           ; reset the state
           mov  dword fs:[edi+OHCI_OP_REGS->HcControl],0
           
           ; wait for the port reset time
           mov  eax,USB_TDRSTR
           call mdelay

           ; frame interval
           mov  dword fs:[edi+OHCI_OP_REGS->HcFmInterval],0xA7782EDF
           ;mov  dword fs:[edi+OHCI_OP_REGS->HcPeriodicStart],0x00002A2F

           ; port power (power all ports globally)
           or   dword fs:[edi+OHCI_OP_REGS->HcRhDescriptorA],(1<<9)
           and  dword fs:[edi+OHCI_OP_REGS->HcRhDescriptorB],0x0000FFFF

           ; clear the HCCA simply for debugging purposes
           mov  dword fs:[edi+OHCI_OP_REGS->HcHCCA],0

           mov  eax,es:[si+USB_CONTROLLER->base_memory]
           ; control list
           mov  fs:[edi+OHCI_OP_REGS->HcControlHeadED],eax
           mov  dword fs:[edi+OHCI_OP_REGS->HcControlCurrentED],0
           ; move to the bulk list
           add  eax,(sizeof(OHCI_ED) * USB_DEVICE_MAX * 1)
           ; bulk list
           mov  fs:[edi+OHCI_OP_REGS->HcBulkHeadED],eax
           mov  dword fs:[edi+OHCI_OP_REGS->HcBulkCurrentED],0

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; start the controller (set it to operational)
           mov  dword fs:[edi+OHCI_OP_REGS->HcControl],0x00000080

           ; power all ports per the PowerSwitchingMode bit
           ;mov  dword fs:[edi+OHCI_OP_REGS->HcRhStatus],0x00008000
           
           ; set the interrupt here
           ;
           ; allow all interrupts
           ; #define HC_INTS_ALLOWED   (HC_INT_STATUS_OC | HC_INT_STATUS_RHSC | HC_INT_STATUS_UE | HC_INT_STATUS_RD | HC_INT_STATUS_WDH | HC_INT_STATUS_SO)
           ;mov  dword fs:[edi+OHCI_OP_REGS->HcInterruptEnable],(0x80000000 | HC_INTS_ALLOWED)

           ret
ohci_stack_initialize endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get the device's primary ED
; on entry:
;  es -> EBDA
;  eax = 0 = Control List, 1 = Bulk list
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  eax = address of ED
; destroys none
ohci_get_ed_address proc near uses ecx
           mov  ecx,es:[esi+USB_CONTROLLER->base_memory]
           imul eax,(sizeof(OHCI_ED) * USB_DEVICE_MAX * 1)  ; skip over Control EDs (eax == 1)
           add  ecx,eax
           movzx eax,byte fs:[ebx+USB_DEVICE->device_num]
           imul eax,sizeof(OHCI_ED) ; each ED is 32 bytes
           add  eax,ecx          ; eax now points to this device's primary ED
           ret
ohci_get_ed_address endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get the device's primary TD
; on entry:
;  es -> EBDA
;  eax = 0 = Control List, 1 = Bulk list
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  eax = address of TD
; destroys none
ohci_get_td_address proc near uses ecx
           mov  ecx,es:[esi+USB_CONTROLLER->base_memory]
           add  ecx,(sizeof(OHCI_ED) * USB_DEVICE_MAX * 2)  ; skip over EDs
           imul eax,(sizeof(OHCI_TD) * USB_DEVICE_MAX * 64) ; skip over Control TDs (eax == 1)
           add  ecx,eax
           movzx eax,byte fs:[ebx+USB_DEVICE->device_num]
           imul eax,(64 * sizeof(OHCI_TD))
           add  eax,ecx
           ret
ohci_get_td_address endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; reset a ohci port
; on entry:
;  es -> EBDA
;  edx = port number (0 or 1)
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  al = 1 = port connected/enabled
;     = 0 = no device attached
; destroys none
ohci_port_reset proc near uses edx edi
            
           ; calculate which port it is
           mov  edi,es:[esi+USB_CONTROLLER->base]
           shl  edx,2           ; ports are dword is size
           
           ; only try to reset it if there is a connection
           test dword fs:[edi+edx+OHCI_OP_REGS->HcRhPortStatus],HC_PORT_STATUS_CCS
           jz   short ohci_port_reset_no
           
           mov  dword fs:[edi+edx+OHCI_OP_REGS->HcRhPortStatus],HC_PORT_STATUS_PRS
@@:        mov  eax,USB_TRSTRCY
           call mdelay
           ; the port reset done bit will be set when the reset is done
           test dword fs:[edi+edx+OHCI_OP_REGS->HcRhPortStatus],HC_PORT_STATUS_PRSC
           jz   short @b
           
           ; clear the PESC, PSSC, OCIC, and PRSC bits (WC)
           or   dword fs:[edi+edx+OHCI_OP_REGS->HcRhPortStatus], \
                   (HC_PORT_STATUS_PESC | HC_PORT_STATUS_PSSC | HC_PORT_STATUS_OCIC | HC_PORT_STATUS_PRSC)
           
           ; is the connected and enabled bit set
           mov  eax,fs:[edi+edx+OHCI_OP_REGS->HcRhPortStatus]
           and  eax,(HC_PORT_STATUS_PES | HC_PORT_STATUS_CCS)
           cmp  eax,(HC_PORT_STATUS_PES | HC_PORT_STATUS_CCS)
           jne  short ohci_port_reset_no

           ; connected and enabled
           mov  al,1
           ret

           ; nothing connected and/or did not enable
ohci_port_reset_no:
           xor  al,al
           ret
ohci_port_reset endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; enumerate a connected device
; on entry:
;  es -> EBDA
;  edx = port number (0 or 1)
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  ax =  0 = good enumeration
;     = -1 = error
; destroys none
ohci_enumerate proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,4

ohci_tx_buffer_0    equ  [bp-4]  ; dword

           ; calculate which port it is
           push edx             ; save port number
           mov  edi,es:[esi+USB_CONTROLLER->base]
           shl  edx,2           ; ports are dword is size

           ; get the address to our return buffer
           lea  eax,[ebx+USB_DEVICE->rxtx_buffer]
           mov  ohci_tx_buffer_0,eax ; save for later

           ; get some information from the port
           mov  byte fs:[ebx+USB_DEVICE->speed],1 ; assume low-speed
           mov  word fs:[ebx+USB_DEVICE->mps],8
           mov  cx,8             ; count of bytes to transfer
           test dword fs:[edi+edx+OHCI_OP_REGS->HcRhPortStatus],HC_PORT_STATUS_LSDA
           jnz  short @f
           mov  byte fs:[ebx+USB_DEVICE->speed],0 ; is full-speed
           mov  word fs:[ebx+USB_DEVICE->mps],64
           mov  cx,64            ; count of bytes to transfer (should only return 18)
@@:        mov  byte fs:[ebx+USB_DEVICE->dev_addr],0
           pop  edx              ; restore port number

           ; get the devices descriptor
           mov  edi,offset request_device_str
           mov  al,PID_IN
           call ohci_control_packet
           ; if we didn't return at least 8 bytes, there was an error
           cmp  eax,8
           jl   ohci_enumerate_done

           ; get the max packet size for this device
           mov  edi,ohci_tx_buffer_0
           call usb_get_mps
           mov  fs:[ebx+USB_DEVICE->mps],ax
           call ohci_port_reset

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set the address of the device
           call usb_get_address_id
           mov  cl,0x05          ; request = 0x05 = set address
           call ohci_set_attribute
           cmp  eax,-1
           jle  short ohci_enumerate_done
           mov  fs:[ebx+USB_DEVICE->dev_addr],al

           ; get the devices descriptor
           mov  cx,18
           mov  edi,offset request_device_str
           mov  al,PID_IN
           call ohci_control_packet
           ; if we didn't return 18 bytes, there was an error
           cmp  eax,18
           jl   short ohci_enumerate_done

           ; if the class and subclass are not 0x00 & 0x00, then return
           mov  edi,ohci_tx_buffer_0
           cmp  word fs:[edi+4],0x0000   ; class and subclass == 0 ?
           jne  short ohci_enumerate_done

           ; we need to get the configuration descriptor
           mov  cx,512
           mov  edi,offset request_config_str
           mov  al,PID_IN
           call ohci_control_packet
           ; if returned -1, error
           cmp  eax,-1
           jle  short ohci_enumerate_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now find the interface descriptor 
           ; check the class (08), subclass (06), and protocol (0x50)  BBB
           ; check the class (08), subclass (06), and protocol (0x62)  UASP
           ; check the class (08), subclass (04), and protocol (0x50)  CB(i) with BBB
           ; check the class (08), subclass (04), and protocol (0x01)  CBI
           ; check the class (08), subclass (04), and protocol (0x00)  CB
           ; and if so, retreive the device data
           mov  edi,ohci_tx_buffer_0    ; start address of config desc
           mov  cx,ax              ; length of config descriptor
           call usb_configure_device
           cmp  ax,2               ; must have at least 2 bulk endpoints found
           jb   short ohci_enumerate_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now send the Set Configuration Request
           movzx ax,byte fs:[edi + 5] ; configuration value
           mov  cl,0x09          ; request = 0x09 = set configuration
           call ohci_set_attribute
           cmp  eax,-1
           jle  short ohci_enumerate_done

           ; return good enumeration
           xor  ax,ax
           mov  sp,bp
           pop  bp
           ret

ohci_enumerate_done:
           mov  ax,-1
           mov  sp,bp
           pop  bp
           ret
ohci_enumerate endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a control transfer to the controller
; on entry:
;  es -> EBDA
;  al = direction (PID_IN or PID_OUT)
;  cx = length of bytes to request
;  dx = unused
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
;  cs:edi -> request packet to send
; on return
;  eax = size of buffer received
;      = negative value if error
; destroys none
ohci_control_packet proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,26

ohci_ct_running_cnt    equ  [bp-2]     ; word
ohci_ct_tx_buffer      equ  [bp-6]     ; dword
ohci_ct_requ_buffer    equ  [bp-10]    ; dword
ohci_ct_requ_packet    equ  [bp-14]    ; dword
ohci_ct_first_td       equ  [bp-18]    ; dword
ohci_ct_ed_addr        equ  [bp-22]    ; dword
ohci_ct_td_count       equ  [bp-24]    ; word
ohci_ct_direction      equ  [bp-25]    ; byte

           ; save some items
           mov  ohci_ct_running_cnt,cx
           mov  ohci_ct_requ_packet,edi
           
           ; the OHCI uses 1 for out, 2 for in
           mov  byte ohci_ct_direction,OHCI_TOKEN_IN
           cmp  al,PID_IN
           je   short @f
           mov  byte ohci_ct_direction,OHCI_TOKEN_OUT

@@:        lea  eax,[ebx+USB_DEVICE->rxtx_buffer]
           mov  ohci_ct_tx_buffer,eax
           lea  eax,[ebx+USB_DEVICE->request]
           mov  ohci_ct_requ_buffer,eax

           ; get the device's primary ED
           mov  eax,0  ; control list
           call ohci_get_ed_address
           mov  ohci_ct_ed_addr,eax
           
           ; get the device's TD list
           mov  eax,0  ; control list
           call ohci_get_td_address
           mov  ohci_ct_first_td,eax
           mov  edi,eax
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create SETUP packet
           mov  eax,((14 << OHCI_TD_CC_SHFT) | (0 << OHCI_TD_EC_SHFT) | ((OHCI_TD_FROM_TD | 0) << OHCI_TD_T_SHFT) | \
                      (7 << OHCI_TD_DI_SHFT) | (OHCI_TOKEN_SETUP << OHCI_TD_DP_SHFT))
           mov  fs:[edi+OHCI_TD->flags],eax
           mov  eax,ohci_ct_requ_buffer
           mov  fs:[edi+OHCI_TD->cbp],eax
           mov  fs:[edi+OHCI_TD->our_cbp],eax
           add  eax,(8 - 1)
           mov  fs:[edi+OHCI_TD->be],eax
           mov  dword fs:[edi+OHCI_TD->our_size],8
           lea  eax,[edi+sizeof(OHCI_TD)]
           mov  fs:[edi+OHCI_TD->nexttd],eax
           add  edi,sizeof(OHCI_TD)
           mov  word ohci_ct_td_count,1

           ; create request packet
           push esi
           mov  esi,ohci_ct_requ_packet
           mov  eax,ohci_ct_requ_buffer
           mov  ecx,cs:[esi+0]
           mov  fs:[eax+0],ecx
           mov  cx,cs:[esi+4]
           mov  fs:[eax+4],cx
           mov  cx,ohci_ct_running_cnt
           mov  fs:[eax+6],cx          ; length
           pop  esi
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IN/OUT packets
           ; (we clear the Rounding bit so that when a short packet is detected,
           ;  the controller will mark the ED as Halted and continue to the next ED)
           mov  edx,(OHCI_TD_FROM_TD | 1) ; toggle bit (1 for first IN/OUT after the SETUP)
           shl  edx,OHCI_TD_T_SHFT
ohci_td_loop0:
           mov  eax,((14 << OHCI_TD_CC_SHFT) | (0 << OHCI_TD_EC_SHFT) | (7 << OHCI_TD_DI_SHFT))
           or   eax,edx
           movzx ecx,byte ohci_ct_direction
           cmp  cl,OHCI_TOKEN_IN
           jne  short @f
           or   eax,OHCI_TD_R
@@:        shl  ecx,OHCI_TD_DP_SHFT
           or   eax,ecx
           mov  fs:[edi+OHCI_TD->flags],eax

           mov  eax,ohci_ct_tx_buffer
           mov  fs:[edi+OHCI_TD->cbp],eax
           mov  fs:[edi+OHCI_TD->our_cbp],eax
           push eax
           movzx ecx,word fs:[ebx+USB_DEVICE->mps]
           add  eax,ecx
           mov  ohci_ct_tx_buffer,eax
           pop  eax

           movzx ecx,word ohci_ct_running_cnt
           cmp  cx,fs:[ebx+USB_DEVICE->mps]
           jbe  short @f
           mov  cx,fs:[ebx+USB_DEVICE->mps]
@@:        sub  ohci_ct_running_cnt,cx
           add  eax,ecx
           dec  eax
           mov  fs:[edi+OHCI_TD->be],eax
           mov  fs:[edi+OHCI_TD->our_size],ecx

           lea  eax,[edi+sizeof(OHCI_TD)]
           mov  fs:[edi+OHCI_TD->nexttd],eax
           add  edi,sizeof(OHCI_TD)

           xor  edx,OHCI_TD_T0_MASK ; toggle bit
           inc  word ohci_ct_td_count

           cmp  word ohci_ct_running_cnt,0
           ja   ohci_td_loop0

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Process the SETUP and remaining packets
           mov  edi,ohci_ct_ed_addr
           mov  eax,ohci_ct_first_td
           movzx ecx,word ohci_ct_td_count
           movzx edx,word fs:[ebx+USB_DEVICE->mps]
           shl  edx,16
           mov  dh,(1<<0) ; control list
           mov  dl,0  ; control EP
           call ohci_process_transaction
           cmp  eax,-1
           je   short ohci_control_packet_done

           push eax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Status packet
           mov  edi,ohci_ct_first_td
           mov  eax,((14 << OHCI_TD_CC_SHFT) | (0 << OHCI_TD_EC_SHFT) | ((OHCI_TD_FROM_TD | 1) << OHCI_TD_T_SHFT) | \
                      (7 << OHCI_TD_DI_SHFT))
           movzx ecx,byte ohci_ct_direction
           xor  ecx,00000011b    ; change a 01b to a 10b   or   a 10b to a 01b
           shl  ecx,OHCI_TD_DP_SHFT
           or   eax,ecx
           mov  fs:[edi+OHCI_TD->flags],eax
           xor  eax,eax
           mov  fs:[edi+OHCI_TD->cbp],eax
           mov  fs:[edi+OHCI_TD->our_cbp],eax
           mov  fs:[edi+OHCI_TD->be],eax
           mov  dword fs:[edi+OHCI_TD->our_size],0
           lea  eax,[edi+sizeof(OHCI_TD)]
           mov  fs:[edi+OHCI_TD->nexttd],eax
           add  edi,sizeof(OHCI_TD)

           ; wait for the TD to be done
           mov  edi,ohci_ct_ed_addr
           mov  eax,ohci_ct_first_td
           mov  ecx,1
           movzx edx,word fs:[ebx+USB_DEVICE->mps]
           shl  edx,16
           mov  dh,(1<<0) ; control list
           mov  dl,0  ; control EP
           call ohci_process_transaction

           ; restore the count of bytes transferred
           pop  eax

ohci_control_packet_done:
           ; mark the ED as sKip
           mov  edi,ohci_ct_ed_addr
           mov  dword fs:[edi+OHCI_ED->flags],OHCI_ED_sKip

           mov  sp,bp
           pop  bp
           ret
ohci_control_packet endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a "set attribute" style control out request
; on entry:
;  es -> EBDA
;  ax = value to set the requests 'value' field to
;  cl = request value (5 = set address, 9 = set configuration)
;  dx = unused
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  eax = passed ax 'value'
;      = negative value if error
; destroys none
ohci_set_attribute proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,16

ohci_ad_value_word     equ  [bp-2]   ; word
ohci_ad_request_byte   equ  [bp-4]   ; word
ohci_ad_requ_buffer    equ  [bp-8]   ; dword
ohci_ad_ed_addr        equ  [bp-12]  ; dword
ohci_ad_first_td       equ  [bp-16]  ; dword

           ; save some items
           mov  ohci_ad_value_word,ax
           mov  ohci_ad_request_byte,cl
           lea  eax,[ebx+USB_DEVICE->request]
           mov  ohci_ad_requ_buffer,eax

           ; get the device's primary ED
           mov  eax,0  ; control list
           call ohci_get_ed_address
           mov  ohci_ad_ed_addr,eax
           
           ; get the device's TD list
           mov  eax,0  ; control list
           call ohci_get_td_address
           mov  ohci_ad_first_td,eax
           mov  edi,eax
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create SETUP packet
           mov  eax,((14 << OHCI_TD_CC_SHFT) | (0 << OHCI_TD_EC_SHFT) | ((OHCI_TD_FROM_TD | 0) << OHCI_TD_T_SHFT) | \
                      (7 << OHCI_TD_DI_SHFT) | (OHCI_TOKEN_SETUP << OHCI_TD_DP_SHFT))
           mov  fs:[edi+OHCI_TD->flags],eax
           mov  eax,ohci_ad_requ_buffer
           mov  fs:[edi+OHCI_TD->cbp],eax
           mov  fs:[edi+OHCI_TD->our_cbp],eax
           add  eax,(8 - 1)
           mov  fs:[edi+OHCI_TD->be],eax
           mov  dword fs:[edi+OHCI_TD->our_size],8
           lea  eax,[edi+sizeof(OHCI_TD)]
           mov  fs:[edi+OHCI_TD->nexttd],eax
           add  edi,sizeof(OHCI_TD)

           ; create request packet
           mov  eax,ohci_ad_requ_buffer
           mov  byte fs:[eax+0],0x00   ; host to device, standard, device
           mov  cl,ohci_ad_request_byte
           mov       fs:[eax+1],cl     ; request value
           mov  cx,ohci_ad_value_word
           mov       fs:[eax+2],cx
           mov  word fs:[eax+4],0      ; index
           mov  word fs:[eax+6],0      ; length

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Process the SETUP packet
           mov  edi,ohci_ad_ed_addr
           mov  eax,ohci_ad_first_td
           mov  ecx,1
           movzx edx,word fs:[ebx+USB_DEVICE->mps]
           shl  edx,16
           mov  dh,(1<<0) ; control list
           mov  dl,0  ; control EP
           call ohci_process_transaction
           cmp  eax,-1
           je   short ohci_set_attribute_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Status packet
           mov  edi,ohci_ad_first_td
           mov  eax,((14 << OHCI_TD_CC_SHFT) | (0 << OHCI_TD_EC_SHFT) | ((OHCI_TD_FROM_TD | 1) << OHCI_TD_T_SHFT) | \
                      (7 << OHCI_TD_DI_SHFT) | (OHCI_TOKEN_IN << OHCI_TD_DP_SHFT))
           mov  fs:[edi+OHCI_TD->flags],eax
           xor  eax,eax
           mov  fs:[edi+OHCI_TD->cbp],eax
           mov  fs:[edi+OHCI_TD->our_cbp],eax
           mov  fs:[edi+OHCI_TD->be],eax
           mov  dword fs:[edi+OHCI_TD->our_size],0
           lea  eax,[edi+sizeof(OHCI_TD)]
           mov  fs:[edi+OHCI_TD->nexttd],eax
           add  edi,sizeof(OHCI_TD)

           ; wait for the TD to be done
           mov  edi,ohci_ad_ed_addr
           mov  eax,ohci_ad_first_td
           mov  ecx,1
           movzx edx,word fs:[ebx+USB_DEVICE->mps]
           shl  edx,16
           mov  dh,(1<<0) ; control list
           mov  dl,0  ; control EP
           call ohci_process_transaction
           cmp  eax,-1
           je   short ohci_set_attribute_done

           movzx eax,word ohci_ad_value_word

ohci_set_attribute_done:
           ; mark the ED as sKip
           mov  edi,ohci_ad_ed_addr
           mov  dword fs:[edi+OHCI_ED->flags],OHCI_ED_sKip

           mov  sp,bp
           pop  bp
           ret
ohci_set_attribute endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a bulk packet
; on entry:
;  al = direction (PID_IN or PID_OUT)
;  cx = size of packet to send
;  dx = unused
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
;  fs:edi -> physical address of buffer to read/write
; on return
;  eax = bytes sent/received
;      = negative value if error
; destroys none
ohci_do_bulk_packet proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,18

ohci_bk_running_cnt    equ  [bp-2]   ; word
ohci_bk_tx_buffer      equ  [bp-6]   ; dword
ohci_bk_ed_addr        equ  [bp-10]  ; dword
ohci_bk_first_td       equ  [bp-14]  ; dword
ohci_bk_td_count       equ  [bp-16]  ; word
ohci_bk_direction      equ  [bp-17]  ; byte

           ; save some items
           mov  ohci_bk_running_cnt,cx
           mov  ohci_bk_tx_buffer,edi
           mov  word ohci_bk_td_count,0

           ; the OHCI uses 1 for out, 2 for in
           mov  byte ohci_bk_direction,OHCI_TOKEN_IN
           cmp  al,PID_IN
           je   short @f
           mov  byte ohci_bk_direction,OHCI_TOKEN_OUT

@@:        ; get the device's primary ED
           mov  eax,1  ; bulk list
           call ohci_get_ed_address
           mov  ohci_bk_ed_addr,eax
           
           ; get the device's TD list
           mov  eax,1  ; bulk list
           call ohci_get_td_address
           mov  ohci_bk_first_td,eax
           mov  edi,eax
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IN/OUT packets
           push esi              ; save the CONTROLLER pointer
           
           ; are we doing an in or an out
           lea  esi,[ebx+USB_DEVICE->endpoint_in]
           cmp  byte ohci_bk_direction,OHCI_TOKEN_IN
           je   short @f
           add  esi,sizeof(USB_DEVICE_EP)
           
           ; fs:esi -> endpoint info
@@:        movzx edx,byte fs:[esi+USB_DEVICE_EP->ep_toggle] ; toggle bit
           or   edx,OHCI_TD_FROM_TD
           shl  edx,OHCI_TD_T_SHFT
bk_ohci_td_loop0:
           mov  eax,((14 << OHCI_TD_CC_SHFT) | (0 << OHCI_TD_EC_SHFT) | (7 << OHCI_TD_DI_SHFT))
           or   eax,edx
           movzx ecx,byte ohci_bk_direction
           cmp  cl,OHCI_TOKEN_IN
           jne  short @f
           or   eax,OHCI_TD_R
@@:        shl  ecx,OHCI_TD_DP_SHFT
           or   eax,ecx
           mov  fs:[edi+OHCI_TD->flags],eax

           mov  eax,ohci_bk_tx_buffer
           mov  fs:[edi+OHCI_TD->cbp],eax
           mov  fs:[edi+OHCI_TD->our_cbp],eax
           movzx ecx,word fs:[esi+USB_DEVICE_EP->ep_mps]
           add  ohci_bk_tx_buffer,ecx

           movzx ecx,word ohci_bk_running_cnt
           cmp  cx,fs:[esi+USB_DEVICE_EP->ep_mps]
           jbe  short @f
           mov  cx,fs:[esi+USB_DEVICE_EP->ep_mps]
@@:        sub  ohci_bk_running_cnt,cx
           add  eax,ecx
           dec  eax
           mov  fs:[edi+OHCI_TD->be],eax
           mov  fs:[edi+OHCI_TD->our_size],ecx

           lea  eax,[edi+sizeof(OHCI_TD)]
           mov  fs:[edi+OHCI_TD->nexttd],eax
           add  edi,sizeof(OHCI_TD)

           xor  edx,OHCI_TD_T0_MASK ; toggle bit
           inc  word ohci_bk_td_count

           cmp  word ohci_bk_running_cnt,0
           ja   bk_ohci_td_loop0

           ; save the current toggle for next time
           shr  edx,OHCI_TD_T_SHFT
           and  dl,1
           mov  fs:[esi+USB_DEVICE_EP->ep_toggle],dl

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Process the packets
           mov  edi,ohci_bk_ed_addr
           mov  eax,ohci_bk_first_td
           movzx ecx,word ohci_bk_td_count
           movzx edx,word fs:[esi+USB_DEVICE_EP->ep_mps]
           shl  edx,16
           mov  dh,(1<<1) ; bulk list
           mov  dl,fs:[esi+USB_DEVICE_EP->ep_val]
           pop  esi              ; restore the CONTROLLER pointer
           call ohci_process_transaction
           
           ; mark the ED as sKip
           mov  edi,ohci_bk_ed_addr
           mov  dword fs:[edi+OHCI_ED->flags],OHCI_ED_sKip

           mov  sp,bp
           pop  bp
           ret
ohci_do_bulk_packet endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; modifies the ED and tells the controller to start the transaction
; (uses a time out just so we don't freeze here)
; on entry:
;  ecx = count of TDs to check
;  edx = high word = MPS for this endpoint
;  dl  = endpoint
;  dh  = list ((1<<0) = control, (1<<1) = bulk)
;  fs:edi -> ED
;  fs:eax -> first TD
;  fs:ebx -> USB_DEVICE
;  es:esi -> this USB_CONTROLLER structure
; on return
;  eax >= 0 if successful (return count of bytes transferred)
;      = -1 if timed out
; destroys none
ohci_process_transaction proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,4

ohci_proc_timer        equ  [bp-4]   ; dword
           
           ; save the address to the first TD and the count of TDs
           push eax   ; address of first TD
           push ecx   ; count of TDs to check
           push edx   ; dl = endpoint, dh = list to enable

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create ED
           push eax
           mov  eax,edx          ; high word = ep->mps
          ;shl  eax,OHCI_ED_MPS_SHFT
           and  eax,0xFFFF0000
           cmp  byte fs:[ebx+USB_DEVICE->speed],0
           je   short @f
           or   eax,OHCI_ED_S
@@:       ;or   eax,(OHCI_ED_DIR_TD << OHCI_ED_D_SHFT)
           and  edx,0x0000007F
           shl  edx,OHCI_ED_EN_SHFT ; endpoint 
           or   eax,edx
           mov  dl,fs:[ebx+USB_DEVICE->dev_addr]
           and  dl,0x7F
           or   al,dl            ; dev address
           mov  fs:[edi+OHCI_ED->flags],eax
           pop  eax
           mov  fs:[edi+OHCI_ED->headp],eax
           imul ecx,sizeof(OHCI_TD)
           add  eax,ecx
           mov  fs:[edi+OHCI_ED->tailp],eax

           ; we are ready to allow the controller to process our list
           wbinvd

           pop  edx              ; dl = endpoint, dh = list to enable
           and  edx,0x0000FFFF   ; we only want the lower word (clear the high word)
           push edx              ; save for below
           ; dx = 000000BC_00000000b  ; B = bulk list, C = control list
           shr  dx,4
           ; dx = 00000000_00BC0000b  ; B = bulk list, C = control list
           and  dx,0x00000030    ; control or bulk list
           or   dx,0x00000080    ; bits 7:6 = operational
           pop  eax              ; restore list flags in eax
           ; eax = 000000BC_00000000b  ; B = bulk list, C = control list
           shr  ax,7
           ; eax = 00000000_00000BC0b  ; B = bulk list, C = control list

           ; tell the controller we inserted an ED
           mov  edi,es:[esi+USB_CONTROLLER->base]
           mov  fs:[edi+OHCI_OP_REGS->HcCommandStatus],eax
           mov  fs:[edi+OHCI_OP_REGS->HcControl],edx

           ; clear the controllers HcInterruptStatus register
           mov  eax,fs:[edi+OHCI_OP_REGS->HcInterruptStatus]
           mov  fs:[edi+OHCI_OP_REGS->HcInterruptStatus],eax
           
           pop  ecx              ; count of TDs to check
           pop  edi              ; address of first TD
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; wait for the last TD to be processed
           ; (return the count of bytes transfered)
           mov  dword ohci_proc_timer,0x00FFFFFF
           xor  edx,edx          ; count of bytes transferred
ohci_process_loop:
           mov  eax,fs:[edi+OHCI_TD->flags]
           and  eax,OHCI_TD_CC_MASK
           shr  eax,OHCI_TD_CC_SHFT
           cmp  al,0x0E
           jae  short ohci_process_loop_1

           ; acknowledge the 'interrupt'
           push eax
           mov  ebx,es:[esi+USB_CONTROLLER->base]
           mov  eax,fs:[ebx+OHCI_OP_REGS->HcInterruptStatus]
           mov  fs:[ebx+OHCI_OP_REGS->HcInterruptStatus],eax
           pop  eax

           ; if CC == 0, check and continue
           ; if CC == 1,2,3,4,5,6,7,8,9,10,11, or 12, error
           cmp  al,0
           jne  short ohci_process_loop_error_1

           ; if it is TOKEN_IN or TOKEN_OUT, process, else continue
           mov  ebx,fs:[edi+OHCI_TD->flags]
           and  ebx,OHCI_TD_DP_MASK
           shr  ebx,OHCI_TD_DP_SHFT
           cmp  bl,OHCI_TOKEN_RESV  ; reserved flag
           je   short ohci_process_loop_error
           cmp  bl,OHCI_TOKEN_SETUP ; just continue
           je   short ohci_process_loop_0
           
           ; if an OUT packet, add the size and continue
           cmp  bl,OHCI_TOKEN_OUT
           je   short @f

           ; else an IN packet
           ; if CBP == 0, success and not short packet
           mov  eax,fs:[edi+OHCI_TD->cbp]
           or   eax,eax
           jz   short @f

           ; else was a short packet
           sub  eax,fs:[edi+OHCI_TD->our_cbp]
           add  edx,eax
           jmp  short ohci_process_loop_done

           ; cbp == 0
@@:        add  edx,fs:[edi+OHCI_TD->our_size]
           
ohci_process_loop_0:
           dec  cx
           jz   short ohci_process_loop_done
           add  edi,sizeof(OHCI_TD)
           mov  dword ohci_proc_timer,0x00FFFFFF
           
ohci_process_loop_1:
           dec  dword ohci_proc_timer
           jnz  short ohci_process_loop

           ; timed-out
           xchg cx,cx
           jmp  short ohci_process_loop_error

           ; return count of bytes transferred
ohci_process_loop_done:
           mov  eax,edx
           mov  sp,bp
           pop  bp
           ret

ohci_process_loop_error:
           mov  eax,-1
           mov  sp,bp
           pop  bp
           ret

ohci_process_loop_error_1:
           neg  al
           cbw
           cwd
           mov  sp,bp
           pop  bp
           ret
ohci_process_transaction endp

.endif  ; DO_INIT_BIOS32

.end
