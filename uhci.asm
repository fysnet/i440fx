comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: uhci.asm                                                           *
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
*   uhci include file                                                      *
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

UHCI_COMMAND      equ   0x00
UHCI_STATUS       equ   0x02
UHCI_INTERRUPT    equ   0x04
UHCI_FRAME_NUM    equ   0x06
UHCI_FRAME_BASE   equ   0x08
UHCI_SOF_MOD      equ   0x0C
UHCI_PORTSC_0     equ   0x10
UHCI_PORTSC_1     equ   0x12

UHCI_PTR_T        equ  (1<<0)
UHCI_PTR_Q        equ  (1<<1)
UHCI_PTR_Vf       equ  (1<<2)

TOGGLE_0          equ  (0<<19)
TOGGLE_1          equ  (1<<19)

UHCI_STATUS_ACTIVE  equ (0x80 << 16)

UHCI_MEMORY_SIZE   equ  (4096 + (1072 * USB_DEVICE_MAX))
UHCI_MEMORY_ALIGN  equ  4096

UHCI_QH struct
	horz_ptr    dword
	vert_ptr    dword
  resv0       dword
  resv1       dword
UHCI_QH ends

UHCI_TD struct
  link_ptr   dword
  reply      dword
	info       dword
	buff_ptr   dword
UHCI_TD ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; detect a uhci controller via the PCI services
; on entry:
;  es -> EBDA
; on return
;  nothing
; destroys none
init_uhci_boot  proc near uses alld
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; try to detect a UHCI by finding a UHCI PCI controller
           xor  esi,esi
uhci_cntrlr_detection:
           push esi
           ;         unused   class   subclass prog int
           mov  ecx,00000000_00001100_00000011_00000000b
           mov  ax,0xB103
           int  1Ah
           pop  esi
           jc   init_uhci_boot_done

           ; found a UHCI controller, so initialize it
           call uhci_initialize
           jc   init_uhci_boot_next

           ; initialize the stack
           call uhci_stack_initialize

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; see if there are any devices present and enumerate them
           xor  edx,edx
           ; point to our controller's block memory (use es:esi+USB_CONTROLLER->)
           push esi
           mov  ebp,esi          ; save the controller index in ebp
           imul esi,sizeof(USB_CONTROLLER)
           add  esi,EBDA_DATA->usb_uhci_cntrls

           ; initialize our callback pointers
           mov  word es:[esi+USB_CONTROLLER->callback_bulk],offset uhci_do_bulk_packet
           mov  word es:[esi+USB_CONTROLLER->callback_control],offset uhci_control_packet
           mov  byte es:[esi+USB_CONTROLLER->device_cnt],0

uhci_dev_detection:
           call uhci_port_reset
           or   al,al
           jz   short @f

           ; allocate the devices memory block
           movzx ebx,byte es:[esi+USB_CONTROLLER->device_cnt]
           imul ebx,sizeof(dword)
           add  ebx,esi
           add  ebx,USB_CONTROLLER->device_data
           mov  eax,sizeof(USB_DEVICE)
           mov  ecx,1
           ;push dx
           ;mov  dx,offset mem_uhci_device_data
           call memory_allocate
           ;pop  dx
           mov  es:[ebx],eax
           mov  ebx,eax
           
           mov  al,es:[esi+USB_CONTROLLER->device_cnt]
           mov  fs:[ebx+USB_DEVICE->device_num],al

           ; we have something connected and enabled
           call uhci_enumerate
           or   ax,ax
           jnz  short @f

           ; mark the controller type (and index)
           mov  ax,bp            ; controller index
           shl  al,4             ; index is in bits 5:4
           or   al,USB_CONTROLLER_UHCI
           mov  fs:[ebx+USB_DEVICE->controller],al
           
           ; mount the drive
           call usb_mount_device
           or   al,al
           jz   short @f

           ; increment the count of devices found
           inc  byte es:[esi+USB_CONTROLLER->device_cnt]
           cmp  byte es:[esi+USB_CONTROLLER->device_cnt],USB_DEVICE_MAX
           je   short uhci_dev_detection0
           
           ; try the next port
@@:        inc  edx
           movzx eax,byte es:[esi+USB_CONTROLLER->numports]
           cmp  edx,eax
           jb   short uhci_dev_detection

           ; if no devices found, stop the controller
uhci_dev_detection0:
           cmp  byte es:[esi+USB_CONTROLLER->device_cnt],0
           jne  short @f
           mov  dx,es:[esi+USB_CONTROLLER->base]
          ;add  dx,UHCI_COMMAND
           xor  ax,ax
           out  dx,ax

           ; and free the allocated memory
           mov  eax,es:[esi+USB_CONTROLLER->base_memory]
           or   eax,eax
           jz   short @f
           call memory_free

           ; loop so that we can see if there are any more
@@:        pop  esi
init_uhci_boot_next:
           inc  esi
           cmp  esi,MAX_USB_CONTROLLERS
           jb   uhci_cntrlr_detection

init_uhci_boot_done:
           ret
init_uhci_boot  endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the found uhci controller
; on entry:
;  es -> EBDA
;  bh = bus
;  bl = dev/func
;  si = 0 for first controller, 1 for second, 2 for third, etc
; on return
;  carry clear if successful
; destroys none
uhci_initialize proc near uses alld ds
           ; if the revision isn't 0x10, we don't support this UHCI
           mov  ax,0xB108
           mov  di,0x60
           int  1Ah
           cmp  cl,0x10
           jne  uhci_initialize_error
           
           ; get the IO address
           mov  ax,0xB10A
           mov  di,0x20
           int  1Ah
           ; is it Port IO?
           test cl,1
           jz   uhci_initialize_error
           and  cl,(~1)

           ; start to save information
           imul si,sizeof(USB_CONTROLLER)
           add  si,EBDA_DATA->usb_uhci_cntrls
           
           mov  byte es:[si+USB_CONTROLLER->valid],0  ; not valid for now
           mov  es:[si+USB_CONTROLLER->busdevfunc],bx
           mov  es:[si+USB_CONTROLLER->base],cx
           mov  byte es:[si+USB_CONTROLLER->flags],0

           ; get the irq
           mov  ax,0xB108
           mov  di,0x3C
           int  1Ah
           mov  es:[si+USB_CONTROLLER->irq],cl
           
           ; make sure IO is allowed
           mov  ax,0xB109
           mov  di,0x04
           int  1Ah
           or   cx,0x05
           mov  ax,0xB10C
           mov  di,0x04
           int  1Ah

           ; reset the controller
           mov  dx,es:[si+USB_CONTROLLER->base]
          ;add  dx,UHCI_COMMAND
           mov  ax,4
           out  dx,ax
           
           mov  eax,USB_TDRST
           call mdelay

           xor  ax,ax
           out  dx,ax

           mov  eax,USB_TRSTRCY
           call mdelay

           ; check to see if we are a little endian or big endian controller
           mov  dx,es:[si+USB_CONTROLLER->base]
           add  dx,UHCI_PORTSC_0
           in   ax,dx
           test ax,0x8000
           jnz  short uhci_initialize_error

           ; check the defaults
           mov  dx,es:[si+USB_CONTROLLER->base]
          ;add  dx,UHCI_COMMAND
           in   ax,dx
           cmp  ax,0x0000
           jne  short uhci_initialize_error

           add  dx,02            ; UHCI_STATUS
           in   ax,dx
           cmp  ax,0x0020
           jne  short uhci_initialize_error
           mov  ax,0x00FF        ; clear any bits that are set
           out  dx,ax

           add  dx,10            ; UHCI_SOF_MOD
           in   al,dx
           cmp  al,0x40
           jne  short uhci_initialize_error

           ; if we set bit 1 in the command register, the controller
           ;  will reset itself and then clear the bit. Check that it does.
           mov  dx,es:[si+USB_CONTROLLER->base]
          ;add  dx,UHCI_COMMAND
           mov  ax,0x0002
           out  dx,ax
           mov  eax,42
           call mdelay
           in   ax,dx
           test ax,0x0002
           jnz  short uhci_initialize_error

           ; get the count of ports
           ;;; UHCI always has 2
           mov  byte es:[si+USB_CONTROLLER->numports],2

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we have found and initialized a UHCI
           ; (allocate some memory for it)
           mov  eax,UHCI_MEMORY_SIZE
           mov  ecx,UHCI_MEMORY_ALIGN
           ;push dx
           ;mov  dx,offset mem_uhci_stack
           call memory_allocate
           ;pop  dx
           mov  es:[si+USB_CONTROLLER->base_memory],eax

           ; mark this information valid
           mov  byte es:[si+USB_CONTROLLER->valid],1

           ; print that we found a UHCI
           mov  ax,BIOS_BASE2
           mov  ds,ax
           push dword es:[si+USB_CONTROLLER->base_memory]
           movzx ax,byte es:[si+USB_CONTROLLER->irq]
           push ax
           movzx ax,byte es:[si+USB_CONTROLLER->numports]
           push ax
           push word es:[si+USB_CONTROLLER->base]
           mov  si,offset uhci_found_str0
           call bios_printf
           add  sp,10
           
           ; successful return
           clc
           ret

uhci_initialize_error:
           stc
           ret
uhci_initialize endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the uhci's stack
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
;  since we do not need a periodical stack, we simply point all frame pointers
;   to a single string of Queue Heads. This string of Queue Heads has one Queue Head
;   for each device we will support (USB_DEVICE_MAX).
;  we then point each Queue Head to the next, with that last pointed to the first.
;  the vertical pointer of these QHs will be temporarily marked TERM.
;  we then create an identical string of Queue Heads, each corresponding to each
;   device we support. Each of these QHs will have enough room allocated for a single
;   TD for the Horz pointer (Short Packet TD), and 512/8 = 64 TDs for the vertical pointer.
;   (this allows any device with 512-byte sectors and an 8 byte packet, or
;    this allows any device with 2048-byte sectors and a 32 byte packet)
;  when a transaction is needed, the secondary QH will be built, and once complete, 
;   the primary QH's vertical pointer will be pointed to this QH.
;  once the transaction is complete, failed or success, the primary QH's vertical
;   pointer is then again marked as TERM.
;  each QH and TD is aligned on a 16-byte boundary.
;
;  [frame0][frame1][frame2][frame3][frame4]...[frame1023]
;     |       |       |       |       |    ...    /
;     |       |       |       |       |----------/
;     |       |       |       |------/
;     |       |       |------/
;     |       |------/
;     |------/
;     |
;     v
;   (primary)         (secondary)  
;       |                 |
;       v                 v
; /-->[queue head]---->[queue head]-->[Transfer Desc_SPD]
; |      |                |
; |   [queue head]->    [Transfer Desc_0]
; |      |                |
; |   [queue head]->    [Transfer Desc_1]
; |      |                |
; \<--[queue head]->    [Transfer Desc_2]
;                         |
;                       [Transfer Desc_3]
;                         |
;                       [Transfer Desc_4]
;                         ...
;                       [Transfer Desc_X]
;
; This needs (1024 * 4) bytes for the frame:          4 * 1024
; USB_DEVICE_MAX * 16 bytes for the Primary QHs:      USB_DEVICE_MAX * 16
; USB_DEVICE_MAX * 16 bytes for the Secondary QHs:    USB_DEVICE_MAX * 16
; USB_DEVICE_MAX * 16 bytes for the Short Packet TD:  USB_DEVICE_MAX * 16
; USB_DEVICE_MAX * 16 * (512 / 8) bytes for TDs:      USB_DEVICE_MAX * 16 * (512 / 8)
;                                                    --------------------------------
;                                                      (4 * 1024) + 
;                                                      ((16 + 16 + 16 + (16 * (512 / 8))) * USB_DEVICE_MAX
;                                                    --------------------------------
;                            total bytes allocated:    4096 + (1072 * USB_DEVICE_MAX) = UHCI_MEMORY_SIZE
;
uhci_stack_initialize proc near uses alld
           ; point to our controller's block memory
           imul si,sizeof(USB_CONTROLLER)
           add  si,EBDA_DATA->usb_uhci_cntrls

           ; aligned memory starts here
           mov  edi,es:[si+USB_CONTROLLER->base_memory]

           ; create frame list
           lea  eax,[edi + 4096]  ; pointer to the first primary QH
           or   eax,UHCI_PTR_Q
           mov  cx,1024
@@:        mov  fs:[edi],eax
           add  edi,4
           loop @b

           ; create primary QH String
           lea  eax,[edi + (16 * USB_DEVICE_MAX)]  ; pointer to corresponding secondary QH
           or   eax,(UHCI_PTR_Q | UHCI_PTR_T)
           mov  edx,edi                            ; save current address (first primary QH)
           or   edx,UHCI_PTR_Q
           push edx
           mov  cx,USB_DEVICE_MAX
@@:        add  edx,16
           mov  fs:[edi],edx
           mov  fs:[edi+4],eax
           add  eax,16
           add  edi,16
           loop @b
           ; point last QH to first QH
           pop  edx
           mov  fs:[edi-16],edx

           ; create secondary QH String
           lea  eax,[edi + (16 * USB_DEVICE_MAX)]  ; pointer to corresponding TDs
           ;or   eax,UHCI_PTR_T
           mov  cx,USB_DEVICE_MAX
@@:        mov  fs:[edi],eax
           add  eax,16
           mov  fs:[edi+4],eax
           add  eax,(64 * 16)
           add  edi,16
           loop @b
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now there is enough room for each secondary QH to
           ;  have a single SPD TD (pointed to by the Horz Ptr)
           ;  and up to 64 regular TDs (pointed to by the Vert Ptr)

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now point the controller to this stack
           mov  dx,es:[si+USB_CONTROLLER->base]
           add  dx,UHCI_FRAME_BASE
           mov  eax,es:[si+USB_CONTROLLER->base_memory]
           out  dx,eax
           ; start at the first frame
           mov  dx,es:[si+USB_CONTROLLER->base]
           add  dx,UHCI_FRAME_NUM
           xor  ax,ax
           out  dx,ax
           ; make sure SOF = 0x40
           mov  dx,es:[si+USB_CONTROLLER->base]
           add  dx,UHCI_SOF_MOD
           mov  al,0x40
           out  dx,al
           ; allow all interrupts
           mov  dx,es:[si+USB_CONTROLLER->base]
           add  dx,UHCI_INTERRUPT
           mov  ax,0  ; 0x000F
           out  dx,ax
           ; clear any status bits
           mov  dx,es:[si+USB_CONTROLLER->base]
           add  dx,UHCI_STATUS
           mov  ax,0x001F
           out  dx,ax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; start the controller
           mov  dx,es:[si+USB_CONTROLLER->base]
           add  dx,UHCI_COMMAND
           mov  ax,((1<<7) | (1<<6) | (1<<0))
           out  dx,ax
           ; wait for it to actually start
@@:        in   ax,dx
           test ax,(1<<5)
           jnz  short @b
           
           ret
uhci_stack_initialize endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; reset a uhci port
; on entry:
;  es -> EBDA
;  edx = port number (0 or 1)
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  al = 1 = port connected/enabled
;     = 0 = no device attached
; destroys none
uhci_port_reset proc near uses dx

           ; port = 0x10 + (bx * 2)
           shl  dx,1
           add  dx,UHCI_PORTSC_0

           ; reset the port, holding the bit set for at least 50ms
           add  dx,es:[esi+USB_CONTROLLER->base]
           in   ax,dx
           or   ax,(1<<9)
           out  dx,ax

           mov  eax,50
           call mdelay

           ; clear the reset. Do not clear the CSC bit until
           ;  after the reset has been complete (done later)
           ; the controller must have the CSC bit cleared while
           ;  not in reset.
           ; (bit 9 must already be clear when we clear the CSC bit)
           in   ax,dx
           and  ax,0xFCB1
           out  dx,ax

           ; this is not the USB_TRSTRCY value. If we wait too long,
           ;  the device may go into suspend state before we have a 
           ;  chance to enable it
           mov  eax,300
           call udelay

           ; clear the CSC bit before we set the enable bit
           in   ax,dx
           or   ax,0x0003
           out  dx,ax
           or   ax,0x0005
           out  dx,ax

           ; wait for it to be enabled
           mov  eax,50
           call udelay

           ; now clear the PEDC bit, and CSC if it is still set
           in   ax,dx
           or   ax,0x000F
           out  dx,ax

           ; short delay before we start sending packets
           mov  eax,50
           call mdelay

           ; is there something connected and it is enabled?
           in   ax,dx
           and  ax,0x0005
           cmp  ax,0x0005
           jne  short @f

           ; connected and enabled
           mov  al,1
           ret

           ; nothing connected and/or did not enable
@@:        xor  al,al
           ret
uhci_port_reset endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; enumerate a connected device
; on entry:
;  es -> EBDA
;  dx = port number (0 or 1)
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  ax =  0 = good enumeration
;     = -1 = error
; destroys none
uhci_enumerate proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,4

uhci_tx_buffer_0    equ  [bp-4]
           
           ; get the address to our return buffer
           lea  eax,[ebx+USB_DEVICE->rxtx_buffer]
           mov  uhci_tx_buffer_0,eax ; save for later

           ; get some information from the port
           push dx
           shl  dx,1
           add  dx,UHCI_PORTSC_0
           add  dx,es:[esi+USB_CONTROLLER->base]
           in   ax,dx
           pop  dx
           mov  byte fs:[ebx+USB_DEVICE->speed],1 ; assume low-speed
           mov  word fs:[ebx+USB_DEVICE->mps],8
           mov  cx,8             ; count of bytes to transfer
           test ax,(1<<8)
           jnz  short @f
           mov  byte fs:[ebx+USB_DEVICE->speed],0 ; is full-speed
           mov  word fs:[ebx+USB_DEVICE->mps],64
           mov  cx,64            ; count of bytes to transfer (should only return 18)
@@:        mov  byte fs:[ebx+USB_DEVICE->dev_addr],0
           
           ; get the devices descriptor
           mov  edi,offset request_device_str
           mov  al,PID_IN
           call uhci_control_packet
           ; if we didn't return at least 8 bytes, there was an error
           cmp  eax,8
           jl   uhci_enumerate_done

           ; get the max packet size for this device
           mov  edi,uhci_tx_buffer_0
           call usb_get_mps
           mov  fs:[ebx+USB_DEVICE->mps],ax
           call uhci_port_reset

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set the address of the device
           call usb_get_address_id
           mov  cl,0x05          ; request = 0x05 = set address
           call uhci_set_attribute
           cmp  eax,-1
           jle  short uhci_enumerate_done
           mov  fs:[ebx+USB_DEVICE->dev_addr],al

           ; get the devices descriptor
           mov  cx,18
           mov  edi,offset request_device_str
           mov  al,PID_IN
           call uhci_control_packet
           ; if we didn't return 18 bytes, there was an error
           cmp  eax,18
           jl   short uhci_enumerate_done

           ; if the class and subclass are not 0x00 & 0x00, then return
           mov  edi,uhci_tx_buffer_0
           cmp  word fs:[edi+4],0x0000   ; class and subclass == 0 ?
           jne  short uhci_enumerate_done

           ; we need to get the configuration descriptor
           mov  cx,512
           mov  edi,offset request_config_str
           mov  al,PID_IN
           call uhci_control_packet

           ; if returned -1, error
           cmp  eax,-1
           jle  short uhci_enumerate_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now find the interface descriptor 
           ; check the class (08), subclass (06), and protocol (0x50)  BBB
           ; check the class (08), subclass (06), and protocol (0x62)  UASP
           ; check the class (08), subclass (04), and protocol (0x50)  CB(i) with BBB
           ; check the class (08), subclass (04), and protocol (0x01)  CBI
           ; check the class (08), subclass (04), and protocol (0x00)  CB
           ; and if so, retreive the device data
           mov  edi,uhci_tx_buffer_0    ; start address of config desc
           mov  cx,ax              ; length of config descriptor
           call usb_configure_device
           cmp  ax,2               ; must have at least 2 bulk endpoints found
           jb   short uhci_enumerate_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now send the Set Configuration Request
           movzx ax,byte fs:[edi + 5] ; configuration value
           mov  cl,0x09          ; request = 0x09 = set configuration
           call uhci_set_attribute
           cmp  eax,-1
           jle  short uhci_enumerate_done

           ; return good enumeration
           xor  ax,ax
           mov  sp,bp
           pop  bp
           ret

uhci_enumerate_done:
           mov  ax,-1
           mov  sp,bp
           pop  bp
           ret
uhci_enumerate endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a control transfer to the controller
; on entry:
;  es -> EBDA
;  al = direction (PID_IN or PID_OUT)
;  cx = length of bytes to request
;  dx = unused
;  es:esi -> this USB_CONTROLLER structure
;  cs:edi -> request packet to send
;  fs:ebx -> USB_DEVICE
; on return
;  eax = size of buffer received
;      = negative value if error
; destroys none
uhci_control_packet proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,28

uhci_ct_running_cnt    equ  [bp-2]
uhci_ct_tx_buffer      equ  [bp-6]
uhci_ct_requ_buffer    equ  [bp-10]
uhci_ct_requ_packet    equ  [bp-14]
uhci_ct_org_vert_addr  equ  [bp-18]
uhci_ct_secondary_qh   equ  [bp-22]
uhci_ct_last_td        equ  [bp-26]
uhci_ct_direction      equ  [bp-27]
           
           ; save some items
           mov  uhci_ct_direction,al
           mov  uhci_ct_running_cnt,cx
           mov  uhci_ct_requ_packet,edi

           lea  eax,[ebx+USB_DEVICE->rxtx_buffer]
           mov  uhci_ct_tx_buffer,eax
           lea  eax,[ebx+USB_DEVICE->request]
           mov  uhci_ct_requ_buffer,eax

           ; get the devices primary QH
           mov  edi,es:[esi+USB_CONTROLLER->base_memory]
           add  edi,4096         ; size of the stack frame pointers
           movzx eax,byte fs:[ebx+USB_DEVICE->device_num]
           shl  eax,4            ; each QH is 16 bytes
           add  edi,eax          ; edi now points to this device's primary QH
           push edi              ; save it

           ; get the secondary QH
           mov  edi,fs:[edi+UHCI_QH->vert_ptr] ; vert pointer points to secondary QH
           and  edi,(~0xF)       ; edi now points to secondary QH
           push edi              ; save it
           mov  uhci_ct_secondary_qh,edi ; save it for the uhci_check_qh routine below
           mov  eax,fs:[edi+UHCI_QH->vert_ptr] ; we need to preserved the vert pointer address
           mov  uhci_ct_org_vert_addr,eax
           and  dword fs:[edi+UHCI_QH->horz_ptr],(~UHCI_PTR_T)
           
           mov  edi,fs:[edi+UHCI_QH->horz_ptr] ; get SPD TD address from horz pointer
           and  edi,(~0xF)       ; edi now points to SPD TD
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create STATUS td in the SPD TD
           mov  dword fs:[edi+UHCI_TD->link_ptr],UHCI_PTR_T
           movzx eax,byte fs:[ebx+USB_DEVICE->speed]
           shl  eax,26           ; bit 26 = low-/full-speed
           or   eax,((3 << 27) | (1<<24) | UHCI_STATUS_ACTIVE) ; cerr = 3, IOC, active bit set
           mov  fs:[edi+UHCI_TD->reply],eax

           movzx eax,byte fs:[ebx+USB_DEVICE->dev_addr]
           shl  eax,8
           ;           len                        toggle      endpt
           or   eax,((((0 - 1) & 0x7FF) << 21) | TOGGLE_1 | (0 << 15))
           ; direction is opposite
           mov  al,PID_IN
           cmp  byte uhci_ct_direction,PID_OUT
           je   short @f
           mov  al,PID_OUT
@@:        mov  fs:[edi+8],eax
           
           mov  dword fs:[edi+12],0x00000000
           mov  uhci_ct_last_td,edi

           ; restore the pointer to the secondary QH
           pop  edi              ; restore secondary QH address
           and  dword fs:[edi+UHCI_QH->vert_ptr],(~UHCI_PTR_T)
           mov  edi,fs:[edi+UHCI_QH->vert_ptr] ; get TD address from vert pointer
           and  edi,(~0xF)       ; edi now points to first TD

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create SETUP packet
           mov  eax,edi
           add  eax,16
           or   eax,UHCI_PTR_Vf
           mov  fs:[edi+UHCI_TD->link_ptr],eax
           
           movzx eax,byte fs:[ebx+USB_DEVICE->speed]
           shl  eax,26           ; bit 26 = low-/full-speed
           or   eax,((3 << 27) | UHCI_STATUS_ACTIVE) ; cerr = 3, active bit set
           mov  fs:[edi+UHCI_TD->reply],eax

           movzx eax,byte fs:[ebx+USB_DEVICE->dev_addr]
           shl  eax,8
           ;           len                        toggle      endpt       pid
           or   eax,((((8 - 1) & 0x7FF) << 21) | TOGGLE_0 | (0 << 15) | PID_SETUP)
           mov  fs:[edi+UHCI_TD->info],eax

           mov  eax,uhci_ct_requ_buffer
           mov  fs:[edi+UHCI_TD->buff_ptr],eax
           add  edi,16

           ; create request packet
           push esi
           mov  esi,uhci_ct_requ_packet
           mov  ecx,cs:[esi+0]
           mov  fs:[eax+0],ecx
           mov  cx,cs:[esi+4]
           mov  fs:[eax+4],cx
           mov  cx,uhci_ct_running_cnt
           mov  fs:[eax+6],cx          ; length
           pop  esi

           mov  edx,TOGGLE_1     ; toggle bit (1 for first IN/OUT after the SETUP)
uhci_td_loop0:
           mov  eax,edi
           add  eax,16
           or   eax,UHCI_PTR_Vf
           mov  fs:[edi+UHCI_TD->link_ptr],eax

           movzx eax,byte fs:[ebx+USB_DEVICE->speed]
           shl  eax,26           ; bit 26 = low-/full-speed
           or   eax,((1 << 29) | (3 << 27) | UHCI_STATUS_ACTIVE) ; spd, cerr = 3, active bit set
           mov  fs:[edi+UHCI_TD->reply],eax

           mov  cx,uhci_ct_running_cnt
           cmp  cx,fs:[ebx+USB_DEVICE->mps]
           jbe  short @f
           mov  cx,fs:[ebx+USB_DEVICE->mps]
@@:        push cx
           dec  cx
           and  cx,0x7FF         ;
           movzx eax,cx          ;
           shl  eax,21           ; count of bytes to tx
           pop  cx
           sub  uhci_ct_running_cnt,cx
           or   eax,edx          ; toggle
           movzx ecx,byte fs:[ebx+USB_DEVICE->dev_addr]
           shl  ecx,8
           or   eax,ecx          ; device address
           mov  al,uhci_ct_direction
           mov  fs:[edi+UHCI_TD->info],eax

           mov  eax,uhci_ct_tx_buffer
           mov  fs:[edi+UHCI_TD->buff_ptr],eax
           movzx ecx,word fs:[ebx+USB_DEVICE->mps]
           add  eax,ecx
           mov  uhci_ct_tx_buffer,eax

           add  edi,16           ; move to next TD
           xor  edx,TOGGLE_1     ; toggle bit

           cmp  word uhci_ct_running_cnt,0
           ja   uhci_td_loop0

           ; mark the last TD as the end
           or   dword fs:[edi-16],UHCI_PTR_T
           
           ; restore pointer to the primary QH
           pop  edi

           ; we are ready to allow the controller to process our QH and TD's
           and  dword fs:[edi+UHCI_QH->vert_ptr],(~UHCI_PTR_T)
           wbinvd
           
           ; wait for the last TD to be processed
           mov  eax,uhci_ct_last_td
           call uhci_wait_for_complete
           or   eax,eax
           jne  short uhci_control_packet_done

           ; mark the QH as TERM again
           or   dword fs:[edi+UHCI_QH->vert_ptr],UHCI_PTR_T
           ; restore the secondary vert pointer
           mov  edi,fs:[edi+UHCI_QH->vert_ptr]
           and  edi,(~0xF)
           mov  eax,uhci_ct_org_vert_addr
           mov  fs:[edi+UHCI_QH->vert_ptr],eax

           ; we now have a transaction that may or may not have completed successfully
           ; we need to check the TD(s)
           mov  al,uhci_ct_direction
           mov  edi,uhci_ct_secondary_qh        ; edi -> Secondary QH
           call uhci_check_qh

uhci_control_packet_done:           
           mov  sp,bp
           pop  bp
           ret
uhci_control_packet endp

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
uhci_set_attribute proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,20

uhci_ad_value_word     equ  [bp-2]
uhci_ad_request_byte   equ  [bp-4]
uhci_ad_requ_buffer    equ  [bp-8]
uhci_ad_org_vert_addr  equ  [bp-12]
uhci_ad_secondary_qh   equ  [bp-16]
uhci_ad_last_td        equ  [bp-20]

           ; save some items
           mov  uhci_ad_value_word,ax
           mov  uhci_ad_request_byte,cl
           lea  eax,[ebx+USB_DEVICE->request]
           mov  uhci_ad_requ_buffer,eax

           ; get the devices primary QH
           mov  edi,es:[esi+USB_CONTROLLER->base_memory]
           add  edi,4096         ; size of the stack frame pointers
           movzx eax,byte fs:[ebx+USB_DEVICE->device_num]
           shl  eax,4            ; each QH is 16 bytes
           add  edi,eax          ; edi now points to this device's primary QH
           push edi              ; save it

           ; get the secondary QH
           mov  edi,fs:[edi+UHCI_QH->vert_ptr] ; vert pointer points to secondary QH
           and  edi,(~0xF)       ; edi now points to secondary QH
           push edi              ; save it
           mov  uhci_ad_secondary_qh,edi ; save it for the uhci_check_qh routine below
           mov  eax,fs:[edi+UHCI_QH->vert_ptr] ; we need to preserved the vert pointer address
           mov  uhci_ad_org_vert_addr,eax
           and  dword fs:[edi+UHCI_QH->horz_ptr],(~UHCI_PTR_T)
           
           mov  edi,fs:[edi+UHCI_QH->horz_ptr] ; get SPD TD address from horz pointer
           and  edi,(~0xF)       ; edi now points to SPD TD
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create STATUS td in the SPD TD
           mov  dword fs:[edi+UHCI_TD->link_ptr],UHCI_PTR_T
           
           movzx eax,byte fs:[ebx+USB_DEVICE->speed]
           shl  eax,26           ; bit 26 = low-/full-speed
           or   eax,((3 << 27) | (1<<24) | UHCI_STATUS_ACTIVE) ; cerr = 3, IOC, active bit set
           mov  fs:[edi+UHCI_TD->reply],eax

           movzx eax,byte fs:[ebx+USB_DEVICE->dev_addr]
           shl  eax,8
           ;           len                        toggle      endpt       pid
           or   eax,((((0 - 1) & 0x7FF) << 21) | TOGGLE_1 | (0 << 15) | PID_IN)
           mov  fs:[edi+UHCI_TD->info],eax

           mov  dword fs:[edi+UHCI_TD->buff_ptr],0x00000000
           mov  uhci_ad_last_td,edi

           ; restore the pointer to the secondary QH
           pop  edi              ; restore secondary QH address
           and  dword fs:[edi+UHCI_QH->vert_ptr],(~UHCI_PTR_T)
           mov  edi,fs:[edi+UHCI_QH->vert_ptr] ; get TD address from vert pointer
           and  edi,(~0xF)       ; edi now points to first TD

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create SETUP packet
           mov  dword fs:[edi+UHCI_TD->link_ptr],UHCI_PTR_T

           movzx eax,byte fs:[ebx+USB_DEVICE->speed]
           shl  eax,26           ; bit 26 = low-/full-speed
           or   eax,((3 << 27) | UHCI_STATUS_ACTIVE) ; cerr = 3, active bit set
           mov  fs:[edi+UHCI_TD->reply],eax

           movzx eax,byte fs:[ebx+USB_DEVICE->dev_addr]
           shl  eax,8
           ;           len                        toggle      endpt       pid
           or   eax,((((8 - 1) & 0x7FF) << 21) | TOGGLE_0 | (0 << 15) | PID_SETUP)
           mov  fs:[edi+UHCI_TD->info],eax

           mov  eax,uhci_ad_requ_buffer
           mov  fs:[edi+UHCI_TD->buff_ptr],eax

           ; create request packet
           mov  byte fs:[eax+0],0x00   ; host to device, standard, device
           mov  cl,uhci_ad_request_byte
           mov       fs:[eax+1],cl     ; request value
           mov  cx,uhci_ad_value_word
           mov       fs:[eax+2],cx
           mov  word fs:[eax+4],0      ; index
           mov  word fs:[eax+6],0      ; length

           ; restore pointer to the primary QH
           pop  edi

           ; we are ready to allow the controller to process our QH and TD's
           and  dword fs:[edi+UHCI_QH->vert_ptr],(~UHCI_PTR_T)
           wbinvd

           ; wait for the last TD to be processed
           mov  eax,uhci_ad_last_td
           call uhci_wait_for_complete
           or   eax,eax
           jne  short @f

           ; mark the QH as TERM again
           or   dword fs:[edi+UHCI_QH->vert_ptr],UHCI_PTR_T
           ; restore the secondary vert pointer
           mov  edi,fs:[edi+UHCI_QH->vert_ptr]
           and  edi,(~0xF)
           mov  eax,uhci_ad_org_vert_addr
           mov  fs:[edi+UHCI_QH->vert_ptr],eax

           ; we now have a transaction that may or may not have completed successfully
           ; we need to check the TD(s)
           xor  al,al
           mov  edi,uhci_ad_secondary_qh    ; edi -> Secondary QH
           call uhci_check_qh
           or   eax,eax
           jnz  short @f
           movzx eax,word uhci_ad_value_word

@@:        mov  sp,bp
           pop  bp
           ret
uhci_set_attribute endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a bulk packet
; on entry:
;  al = direction (PID_IN or PID_OUT)
;  cx = size of packet to send
;  dx = unused
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
;  edi -> physical address of buffer to read/write
; on return
;  eax = bytes sent/received
;      = negative value if error
; destroys none
uhci_do_bulk_packet proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,20

uhci_bk_running_cnt    equ  [bp-2]
uhci_bk_tx_buffer      equ  [bp-6]
uhci_bk_org_vert_addr  equ  [bp-10]
uhci_bk_secondary_qh   equ  [bp-14]
uhci_bk_direction      equ  [bp-16]
uhci_bk_last_td        equ  [bp-20]

           ; save some items
           mov  uhci_bk_running_cnt,cx
           mov  uhci_bk_tx_buffer,edi
           mov  uhci_bk_direction,al

           ; get the devices primary QH
           mov  edi,es:[esi+USB_CONTROLLER->base_memory]
           add  edi,4096         ; size of the stack frame pointers
           movzx eax,byte fs:[ebx+USB_DEVICE->device_num]
           shl  eax,4            ; each QH is 16 bytes
           add  edi,eax          ; edi now points to this device's primary QH
           push edi              ; save it

           ; get the secondary QH
           mov  edi,fs:[edi+UHCI_QH->vert_ptr] ; vert pointer points to secondary QH
           and  edi,(~0xF)       ; edi now points to secondary QH
           mov  uhci_bk_secondary_qh,edi ; save it for the uhci_check_qh routine below
           mov  eax,fs:[edi+UHCI_QH->vert_ptr] ; we need to preserved the vert pointer address
           mov  uhci_bk_org_vert_addr,eax
           or   dword fs:[edi+UHCI_QH->horz_ptr],UHCI_PTR_T
           
           and  dword fs:[edi+UHCI_QH->vert_ptr],(~UHCI_PTR_T)
           mov  edi,fs:[edi+UHCI_QH->vert_ptr] ; get TD address from vert pointer
           and  edi,(~0xF)       ; edi now points to first TD

           ; are we doing an in or an out
           push esi              ; save the pointer to our controller struct
           lea  esi,[ebx+USB_DEVICE->endpoint_in]
           cmp  byte uhci_bk_direction,PID_IN
           je   short @f
           add  esi,sizeof(USB_DEVICE_EP)
           
           ; fs:esi -> endpoint info
@@:        movzx edx,byte fs:[esi+USB_DEVICE_EP->ep_toggle] ; toggle bit
           shl  edx,19
bk_uhci_td_loop0:
           mov  eax,edi
           add  eax,16
           or   eax,UHCI_PTR_Vf
           mov  fs:[edi+UHCI_TD->link_ptr],eax

           movzx eax,byte fs:[ebx+USB_DEVICE->speed]
           shl  eax,26           ; bit 26 = low-/full-speed
           or   eax,((3 << 27) | UHCI_STATUS_ACTIVE) ; cerr = 3, active bit set
           cmp  byte uhci_bk_direction,PID_IN
           jne  short @f
           or   eax,(1 << 29)  ; spd
@@:        mov  fs:[edi+UHCI_TD->reply],eax
           
           mov  cx,uhci_bk_running_cnt
           cmp  cx,fs:[esi+USB_DEVICE_EP->ep_mps]
           jbe  short @f
           mov  cx,fs:[esi+USB_DEVICE_EP->ep_mps]
@@:        push cx
           dec  cx
           and  cx,0x7FF         ;
           movzx eax,cx          ;
           shl  eax,21           ; count of bytes to tx
           pop  cx
           sub  uhci_bk_running_cnt,cx
           or   eax,edx          ; toggle
           movzx ecx,byte fs:[ebx+USB_DEVICE->dev_addr]
           shl  ecx,8
           or   eax,ecx          ; device address
           movzx ecx,byte fs:[esi+USB_DEVICE_EP->ep_val] ; endpoint value
           shl  ecx,15
           or   eax,ecx
           mov  al,uhci_bk_direction
           mov  fs:[edi+UHCI_TD->info],eax

           mov  eax,uhci_bk_tx_buffer
           mov  fs:[edi+UHCI_TD->buff_ptr],eax
           movzx ecx,word fs:[esi+USB_DEVICE_EP->ep_mps]
           add  eax,ecx
           mov  uhci_bk_tx_buffer,eax

           add  edi,16           ; move to next TD
           xor  edx,TOGGLE_1     ; toggle bit

           cmp  word uhci_bk_running_cnt,0
           ja   bk_uhci_td_loop0

           ; mark the last TD as the end
           sub  edi,16
           or   dword fs:[edi],UHCI_PTR_T
           or   dword fs:[edi+UHCI_QH->vert_ptr],(1 << 24) ; set the IOC
           mov  uhci_bk_last_td,edi

           ; save our toggle
           shr  edx,19
           mov  fs:[esi+USB_DEVICE_EP->ep_toggle],dl

           ; restore pointer to our CONTROLLER and the primary QH
           pop  esi
           pop  edi

           ; we are ready to allow the controller to process our QH and TD's
           and  dword fs:[edi+UHCI_QH->vert_ptr],(~UHCI_PTR_T)
           wbinvd
           
           ; wait for the last TD to be processed
           mov  eax,uhci_bk_last_td
           call uhci_wait_for_complete
           or   eax,eax
           jnz  short uhci_do_bulk_packet_done

           ; mark the QH as TERM again
           or   dword fs:[edi+UHCI_QH->vert_ptr],UHCI_PTR_T
           ; restore the secondary vert pointer
           mov  edi,fs:[edi+UHCI_QH->vert_ptr]
           and  edi,(~0xF)
           mov  eax,uhci_bk_org_vert_addr
           mov  fs:[edi+UHCI_QH->vert_ptr],eax

           ; we now have a transaction that may or may not have completed successfully
           ; we need to check the TD(s)
           mov  al,uhci_bk_direction
           mov  edi,uhci_bk_secondary_qh    ; edi -> Secondary QH
           call uhci_check_qh
           
uhci_do_bulk_packet_done:
           mov  sp,bp
           pop  bp
           ret
uhci_do_bulk_packet endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; check the TDs just executed
; on entry:
;  al = PID (IN or OUT or 0x00)
;  fs:edi -> Secondary QH
; on return
;  eax = size received/sent
;      = negative if error found
; destroys none
uhci_check_qh proc near uses ebx ecx edx
           mov  dl,al            ; dl = PID to check for
           mov  ebx,edi          ; save the address of the Secondary QH
           xor  eax,eax          ; count of bytes read or written

           ; scroll through all TDs that have the TERM bit clear
           ;  or until one of them has an error or SPD
           add  ebx,4            ; start with the vertical entry
uhci_check_loop_0:
           test dword fs:[ebx],UHCI_PTR_T
           jnz  short uhci_check_loop_1
           mov  ebx,fs:[ebx]
           and  ebx,(~0xF)
           mov  ecx,fs:[ebx+4]
           test ecx,0x00800000    ; still active
           jnz  short uhci_check_loop_1
           test ecx,0x007F0000    ; was there an error
           jnz  short uhci_check_loop_2
           ; if the PID of this TD matches specified PID,
           ;  add to our running total
           cmp  fs:[ebx+8],dl
           jne  short @f
           inc  ecx
           and  ecx,0x07FF
           add  eax,ecx

           ; did we short packet?
@@:        cmp  byte fs:[ebx+8],PID_IN
           jne  short uhci_check_loop_0
           push eax
           mov  eax,fs:[ebx+8]
           shr  eax,21
           inc  eax
           and  eax,0x7FF
           cmp  ecx,eax
           pop  eax
           jnb  short uhci_check_loop_0

uhci_check_loop_1:
           ; if there was an STATUS entry, check it too
           test dword fs:[edi],UHCI_PTR_T
           jnz  short @f
           ; check that the STATUS TD didn't error out
           mov  ebx,fs:[edi]
           and  ebx,(~0xF)
           mov  ecx,fs:[ebx+4]
           test ecx,0x00FF0000
           jnz  short uhci_check_loop_2
@@:        ret
           
uhci_check_loop_2:
           mov  eax,-1
           ret
uhci_check_qh endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; waits for the active bit in the specified TD to be cleared (by the controller)
; (uses a time out just so we don't freeze here)
; on entry:
;  es:esi -> this USB_CONTROLLER structure
;  fs:eax -> TD
; on return
;  eax = 0 if successful
;      = -1 if timed out
;      = status (bits 6:0)
; destroys none
uhci_wait_for_complete proc near uses ebx ecx dx
           mov  ebx,eax
           mov  ecx,0x00FFFFFF
           mov  dx,es:[si+USB_CONTROLLER->base]
           add  dx,UHCI_STATUS
           ; is the INTerrupt bit set in the STATUS register?
@@:        in   ax,dx
           test al,1
           jz   short uhci_wait_next
           out  dx,ax
           test dword fs:[ebx+UHCI_TD->reply],UHCI_STATUS_ACTIVE
           jz   short @f
           ; this will pause slightly, make sure the memory is 'intact' and serialize the instruction stream
           ; (however, is this ever the case in Bochs?. Probably does none of these things...)
           ;wbinvd
uhci_wait_next:
           dec  ecx
           jnz  short @b

           ;;;; we timed out
           xchg cx,cx
           
           mov  eax,-1
           ret

           ; if the status == 0, we are good
@@:        mov  eax,fs:[ebx+UHCI_TD->reply]
           and  eax,0x007F0000
           shr  eax,16
           ret
uhci_wait_for_complete endp

.endif  ; DO_INIT_BIOS32

.end
