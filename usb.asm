comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: usb.asm                                                            *
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
*   usb include file                                                       *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.14                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 19 Dec 2024                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

.if DO_INIT_BIOS32

; Reset wait times (in ms).  USB 2.0 specs, page 153, section 7.1.7.5, paragraph 3
USB_TDRSTR      equ  50   ; reset on a root hub
USB_TDRST       equ  10   ; minimum delay for a reset
USB_TRHRSI      equ   3   ; No more than this between resets for root hubs
USB_TRSTRCY     equ  10   ; reset recovery

BBB_CBW     struct
  sig         dword
  tag         dword
  length      dword
  flags       byte
  lun         byte
  cb_len      byte
  cmnd        dup 16
BBB_CBW     ends

BBB_CSW     struct
  sig         dword
  tag         dword
  residue     dword
  status      byte
BBB_CSW     ends

PID_SETUP         equ  0x2D
PID_IN            equ  0x69
PID_OUT           equ  0xE1

.enum CONTROL_EP, ISO_EP, BULK_EP, INTERRUPT_EP

; arbatrary numbers so we can determine which one we are using
USB_PROTO_BBB     equ  0xBB
USB_PROTO_CBI     equ  0xCB
;USB_PROTO_UASP    equ  0xAA

USB_REQUEST struct
  request_type  byte
  request       byte
  value         word
  index         word
  length        word
USB_REQUEST ends

request_device_str    db  0x80, 0x06, 0x00, 0x01, 0x00, 0x00, ?, ?
request_config_str    db  0x80, 0x06, 0x00, 0x02, 0x00, 0x00, ?, ?
request_set_config    db  0x00, 0x09,    ?,    ?, 0x00, 0x00, ?, ?
request_cbi_cmd_str   db  0x21, 0, 0, 0, 0, 0, ?, ?

; can be up to IPL_ENTRY_MAX_DESC_LEN-1 chars
CONTROLLER_STR_LEN  equ  14
usb_controller_str  db  '(UHCI Device)',0
                    db  '(OHCI Device)',0
                    db  '(EHCI Device)',0
                    db  '(xHCI Device)',0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; USB Disk Emulation: initialize
; on entry:
;  es = 0x0000
; on return
;  nothing
; destroys nothing
usb_disk_init proc near uses ax bx cx es
           call bios_get_ebda
           mov  es,ax
           mov  byte es:[EBDA_DATA->usb_disk_active],0x00
           mov  byte es:[EBDA_DATA->usb_next_device_id],0x00

           ; get the ehci legacy flag from the escd
           mov  bx,ESCD_DATA->ehci_legacy
           mov  cx,sizeof(byte)
           call bios_read_escd
           mov  es:[EBDA_DATA->usb_ehci_legacy],al

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; detect any xHCI devices
           call init_xhci_boot
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; detect any EHCI devices (must be before the uhci and ohci)
           call init_ehci_boot
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; detect any UHCI devices
           call init_uhci_boot

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; detect any OHCI devices
           call init_ohci_boot

           ret
usb_disk_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; USB Disk Emulation: is emulation active
; on entry:
;  es = segment of EBDA
; on return
;  ax = zero = not active, else is active
; destroys nothing
usb_disk_emu_active proc near
           movzx ax,byte es:[EBDA_DATA->usb_disk_active]
           ret
usb_disk_emu_active endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; USB Disk Emulation: return the drive number that is being emulated
; on entry:
;  es = segment of EBDA
; on return
;  ax = drive number being emulated
; destroys nothing
usb_disk_emu_drive proc near
           movzx ax,byte es:[EBDA_DATA->usb_disk_emulated_drive]
           ret
usb_disk_emu_drive endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Get next device address id
; on entry:
;  es = segment of EBDA
; on return
;  ax = next id to use
; destroys nothing
usb_get_address_id proc near
           inc  byte es:[EBDA_DATA->usb_next_device_id]
           movzx ax,byte es:[EBDA_DATA->usb_next_device_id]
           cmp  al,0x0F
           jbe  short @f

           ; error, we have too many devices attached
           xchg cx,cx

@@:        ret
usb_get_address_id endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; given a configuration, find specified descriptor
; on entry:
;  fs:edi -> configuration buffer
;  al = type of descriptor to find
;  ah = index (0 = 1st, 1 = 2nd, etc)
;  cx = length of configuration buffer
; on return
;  eax = offset from edi to found descriptor
;      = -1 if not found
; destroys nothing
usb_config_find_desc proc near uses ebx ecx edx
           
           movzx ebx,word cx     ; save the length of the config buffer
           movzx cx,byte ah      ; cx = the index
           mov  dl,al            ; type to search for
           xor  eax,eax
config_find_0:
           cmp  fs:[edi + eax + 1],dl
           je   short @f
config_find_1:
           push edx
           movzx edx,byte fs:[edi + eax + 0]
           add  eax,edx
           pop  edx
           cmp  eax,ebx
           jb   short config_find_0
           
           mov  eax,-1
           ret

@@:        or   cx,cx
           jz   short @f
           dec  cx
           jmp  short config_find_1

           ; make sure the whole descriptor is available
@@:        movzx edx,byte fs:[edi + eax + 0]
           add  edx,eax
           cmp  edx,ebx
           jbe  short @f

           mov  eax,-1

           ; 09 02 20 00 01 01 00 C0-00
           ; 09 04 00 00 02 08 06 50 00
           ; 07 05 81 02 40 00-00 
           ; 07 05 02 02 40 00 00 

@@:        ret
usb_config_find_desc endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get the endpoint information from the config descriptor
; on entry:
;  fs:ebx -> USB_DEVICE
;  fs:edi -> configuration buffer
;  cx = length of configuration buffer
; on return
;  ax = count of found endpoints (should be 2)
; destroys nothing
usb_configure_device proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,6

usb_config_eps  equ  [bp-2]
usb_config_len  equ  [bp-4]
usb_config_idx  equ  [bp-5]
           
           mov  word usb_config_eps,0
           mov  usb_config_len,cx
           
           ; now find the interface descriptor and check the class (08), subclass (06), and protocol (50)
           mov  al,0x04            ; type of descriptor to find (Interface)
           mov  ah,0               ; index (0 = 1st, 1 = 2nd, etc)
           call usb_config_find_desc
           cmp  eax,-1
           jle  usb_configure_device_error

           ; eax = offset from edi
           ; all devices must have a class code of 8
           cmp  byte fs:[edi + eax + 5],0x08 ; 8 = MSD
           jne  usb_configure_device_done
           
           ; if a device has a sub_class code of 6 and a protocol of 0x50, do BBB
           cmp  word fs:[edi + eax + 6],0x5006 ; 6 = SCSI transparent command set
           je   short usb_config_is_bbb        ; 0x50 = Bulk Only Transport
           
           ; if a device has a sub_class code of 4 and a protocol of 0x50, do BBB
           cmp  word fs:[edi + eax + 6],0x5004 ; 4 = UFI Command Specs
           je   short usb_config_is_bbb        ; 0x50 = Bulk Only Transport

           ; if a device has a sub_class code of 4 and a protocol of 0x00, do CB(i)
           cmp  word fs:[edi + eax + 6],0x0004 ; 4 = UFI Command Specs
           je   usb_config_is_cbi        ; 0x00 = Control/Bulk

           ; if a device has a sub_class code of 4 and a protocol of 0x01, do CB(i)
           cmp  word fs:[edi + eax + 6],0x0104 ; 4 = UFI Command Specs
           je   usb_config_is_cbi        ; 0x01 = Control/Bulk/Interrupt

;           ; if a device has a sub_class code of 6 and a protocol of 0x62, do UASP
;           ; however, most if not all UASP devices will default to BBB, and since
;           ;  we are simply booting it, BBB will be just fine...
;           cmp  word fs:[edi + eax + 6],0x6206 ; 6 = SCSI transparent command set
;           je   short usb_config_is_uasp       ; 0x62 = UASP
           
           jmp  usb_configure_device_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; found a BBB device, so gather some information about it
           ; we need two EndPoints
usb_config_is_bbb:
           mov  byte fs:[ebx+USB_DEVICE->protocol],USB_PROTO_BBB

           mov  byte usb_config_idx,0
usb_config_ep_loop:           
           mov  ah,usb_config_idx  ; index (0 = 1st, 1 = 2nd, etc)
           mov  cx,usb_config_len  ; length of config desc
           mov  al,0x05            ; type of descriptor to find (endpoint)
           call usb_config_find_desc
           cmp  eax,-1
           jle  usb_configure_device_error

           ; found an endpoint, is a bulk ep?
           cmp  byte fs:[edi + eax + 3],0x02  ; 2 = bulk
           jne  short usb_config_ep_loop_0

           mov  dl,fs:[edi + eax + 2]
           lea  esi,[ebx+USB_DEVICE->endpoint_in]
           test dl,0x80
           jnz  short @f
           add  esi,sizeof(USB_DEVICE_EP)
@@:        and  dl,0x7F
           mov  fs:[esi+USB_DEVICE_EP->ep_val],dl
           mov  dx,fs:[edi + eax + 4]
           mov  fs:[esi+USB_DEVICE_EP->ep_mps],dx
           mov  dl,fs:[edi + eax + 5]
           mov  fs:[esi+USB_DEVICE_EP->ep_interval],dl
           ; todo: we must check to make sure a sector size (2048 max)
           ;       divided by this mps isn't more than the TDs we have allocated)
           ;       (for 512 byte sectors, we must have at least an 8-byte mps)
           ;       (for 2048 byte sectors, we must have at least a 32-byte mps)
           ;       (for 4096 byte sectors, we must have at least a 64-byte mps)
           ;       (we currently only allow 2048 max sector size)
           mov  byte fs:[esi+USB_DEVICE_EP->ep_toggle],0

           ; if this device is a super-speed device, the next descriptor
           ;  will be an endpoint-companion descriptor. If so we need to
           ;  get the max burst value
           mov  byte fs:[esi+USB_DEVICE_EP->ep_max_burst],0
           cmp  word fs:[edi + eax + 7],0x3006  ; 0x06 is the size, 0x30 is the type
           jne  short @f
           mov  dl,fs:[edi + eax + 7 + 2]
           mov  fs:[esi+USB_DEVICE_EP->ep_max_burst],dl

@@:        inc  word usb_config_eps
           cmp  word usb_config_eps,2
           je   short usb_configure_device_done

usb_config_ep_loop_0:
           inc  byte usb_config_idx
           jmp  short usb_config_ep_loop
           

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; found a CB(i) device, so gather some information about it
           ; we need at least two EndPoints (possibly 3)
usb_config_is_cbi:
           mov  byte fs:[ebx+USB_DEVICE->protocol],USB_PROTO_CBI
           ; we only need the two bulk eps, so do the same as BBB
           mov  byte usb_config_idx,0
           jmp  usb_config_ep_loop


;           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;           ; found a UASP device, so gather some information about it
;           ; we need at least four EndPoints
;usb_config_is_uasp:
;           mov  byte fs:[ebx+USB_DEVICE->protocol],USB_PROTO_UASP
;           ;;;;;;;;;;;;;;
;           jmp  short usb_configure_device_error


usb_configure_device_done:
           mov  ax,usb_config_eps
           mov  sp,bp
           pop  bp
           ret

usb_configure_device_error:
           mov  ax,-1
           mov  sp,bp
           pop  bp
           ret
usb_configure_device endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read the drive's capacity
; on entry:
;  dx = zero based port number (0 -> (USB_DEVICE_MAX-1)) (is device number - 1)
;  es:esi-> = this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  eax = bytes read
;      = negative value if error
; destroys none
usb_drive_capacity proc near
           cmp  byte fs:[ebx+USB_DEVICE->protocol],USB_PROTO_BBB  ; BBB
           jne  short @f
           call usb_drive_capacity_bbb
           ret

@@:        cmp  byte fs:[ebx+USB_DEVICE->protocol],USB_PROTO_CBI  ; CB(i)
           jne  short @f
           call usb_drive_capacity_cbi
           ret

;@@:        cmp  byte fs:[ebx+USB_DEVICE->protocol],USB_PROTO_UASP   ; UASP
;           jne  short @f
;           call usb_drive_capacity_uasp
;           ret

@@:        ;xchg cx,cx  ;;;;;;;;;;;;;;;;;;;;

           ret
usb_drive_capacity endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read the drive's capacity (using BBB)
; on entry:
;  dx = zero based port number (0 -> (USB_DEVICE_MAX-1)) (is device number - 1)
;  es:esi-> = this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  eax = bytes read
;      = negative value if error
; destroys none
usb_drive_capacity_bbb proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,16

usb_caps_bbb_cbw  equ  [bp-4]
usb_caps_bbb_csw  equ  [bp-8]
usb_caps_bbb_buf  equ  [bp-12]
usb_caps_bbb_tag  equ  [bp-16]
           
           ; save the addresses to our buffers
           lea  ecx,[ebx+USB_DEVICE->cbw]
           mov  usb_caps_bbb_cbw,ecx
           lea  ecx,[ebx+USB_DEVICE->csw]
           mov  usb_caps_bbb_csw,ecx
           lea  ecx,[ebx+USB_DEVICE->rxtx_buffer]
           mov  usb_caps_bbb_buf,ecx
           lea  ecx,[ebx+USB_DEVICE->next_tag]
           inc  dword fs:[ecx]
           mov  ecx,fs:[ecx]
           mov  usb_caps_bbb_tag,ecx

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build a command block wrapper
           mov  edi,usb_caps_bbb_cbw
           mov  ax,sizeof(BBB_CBW)
           call memset32
           mov  dword fs:[edi+BBB_CBW->sig],0x43425355
           mov        fs:[edi+BBB_CBW->tag],ecx
           mov  dword fs:[edi+BBB_CBW->length],8
           mov  byte fs:[edi+BBB_CBW->flags],0x80
           mov  byte fs:[edi+BBB_CBW->lun],0x00
           mov  byte fs:[edi+BBB_CBW->cb_len],10
             mov  byte fs:[edi+BBB_CBW->cmnd+0],0x25  ; read capacity(10)
            ;mov  byte fs:[edi+BBB_CBW->cmnd+1],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+2],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+3],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+4],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+5],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+6],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+7],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+8],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+9],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+10],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+11],0

           ; send the CBW packet
           mov  al,PID_OUT         ; direction (PID_IN or PID_OUT)
           mov  cx,sizeof(BBB_CBW) ; packet size
           call es:[esi+USB_CONTROLLER->callback_bulk]
           cmp  eax,-1
           jle  short usb_caps_bbb_done

           ; send the IN packets packet
           mov  edi,usb_caps_bbb_buf
           mov  al,PID_IN          ; direction (PID_IN or PID_OUT)
           mov  cx,8               ; packet size
           call es:[esi+USB_CONTROLLER->callback_bulk]
           cmp  eax,-1
           jle  short usb_caps_bbb_done
           mov  usb_caps_bbb_buf,eax  ; save the count (8)

           ; send the CSW packets packet
           mov  edi,usb_caps_bbb_csw
           mov  al,PID_IN          ; direction (PID_IN or PID_OUT)
           mov  cx,sizeof(BBB_CSW) ; packet size
           call es:[esi+USB_CONTROLLER->callback_bulk]
           cmp  eax,-1
           jle  short usb_caps_bbb_done
           
           ; make sure the tag is the same
           mov  ecx,fs:[edi+BBB_CSW->tag]
           cmp  ecx,usb_caps_bbb_tag
           jne  short usb_caps_bbb_done
           
           mov  eax,usb_caps_bbb_buf  ; restore the count from above
usb_caps_bbb_done:
           mov  sp,bp
           pop  bp
           ret
usb_drive_capacity_bbb endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read the drive's capacity (Using CBI)
; on entry:
;  dx = zero based port number (0 -> (USB_DEVICE_MAX-1)) (is device number - 1)
;  es:esi-> = this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  eax = bytes read
;      = negative value if error
; destroys none
usb_drive_capacity_cbi proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,4

usb_caps_cbi_buf  equ  [bp-4]

           ; save the addresses to our buffers
           lea  ecx,[ebx+USB_DEVICE->rxtx_buffer]
           mov  usb_caps_cbi_buf,ecx

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build a command block
           mov  edi,usb_caps_cbi_buf
           mov  ax,12
           call memset32
           
           mov  byte fs:[edi+0],0x25  ; read capacity(10)
          ;mov  byte fs:[edi+1],0
          ;mov  byte fs:[edi+2],0
          ;mov  byte fs:[edi+3],0
          ;mov  byte fs:[edi+4],0
          ;mov  byte fs:[edi+5],0
          ;mov  byte fs:[edi+6],0
          ;mov  byte fs:[edi+7],0
          ;mov  byte fs:[edi+8],0
          ;mov  byte fs:[edi+9],0
          ;mov  byte fs:[edi+10],0
          ;mov  byte fs:[edi+11],0

           ; send the CBW packet
           mov  edi,offset request_cbi_cmd_str
           mov  cx,12
           xor  dx,dx
           mov  al,PID_OUT
           call es:[esi+USB_CONTROLLER->callback_control]
           cmp  eax,-1
           jle  short usb_caps_cbi_done

           ; send the IN packets packet
           mov  edi,usb_caps_cbi_buf
           mov  al,PID_IN          ; direction (PID_IN or PID_OUT)
           mov  cx,8               ; packet size
           call es:[esi+USB_CONTROLLER->callback_bulk]

usb_caps_cbi_done:
           mov  sp,bp
           pop  bp
           ret
usb_drive_capacity_cbi endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read/write a sector from the drive
; on entry:
;  eax = lba to read/write
;  cl = PID_IN or PID_OUT
;  es:esi-> = this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
;  edi-> = physical address of buffer to read/write
; on return
;  eax = bytes read (512 for a 'floppy' or 'hard drive', 2048 for a cdrom)
;      = negative value if error
; destroys none
usb_rxtx_sector proc near
           cmp  byte fs:[ebx+USB_DEVICE->protocol],USB_PROTO_BBB  ; BBB
           jne  short @f
           call usb_rxtx_sector_bbb
           ret

@@:        cmp  byte fs:[ebx+USB_DEVICE->protocol],USB_PROTO_CBI  ; CB(i)
           jne  short @f
           call usb_rxtx_sector_cbi
           ret

;@@:        cmp  byte fs:[ebx+USB_DEVICE->protocol],USB_PROTO_UASP   ; UASP
;           jne  short @f
;           call usb_drive_capacity_uasp
;           ret

@@:        xchg cx,cx  ;;;;;;;;;;;;;;;;;;;;

           ret
usb_rxtx_sector endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read/write a sector from/to the drive (Using BBB)
; on entry:
;  eax = lba to read/write
;  cl = PID_IN or PID_OUT
;  es:esi-> = this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
;  edi-> = physical address of buffer to read/write
; on return
;  eax = bytes read (512 for a 'floppy' or 'hard drive', 2048 for a cdrom)
;      = negative value if error
; destroys none
usb_rxtx_sector_bbb proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,22

usb_rxtx_bbb_lba  equ  [bp-4]   ; dword
usb_rxtx_bbb_cbw  equ  [bp-8]   ; dword
usb_rxtx_bbb_csw  equ  [bp-12]  ; dword
usb_rxtx_bbb_buf  equ  [bp-16]  ; dword
usb_rxtx_bbb_tag  equ  [bp-20]  ; dword
usb_rxtx_bbb_dir  equ  [bp-21]  ; byte

           ; save the addresses to our buffers
           mov  usb_rxtx_bbb_dir,cl
           mov  usb_rxtx_bbb_lba,eax
           mov  usb_rxtx_bbb_buf,edi
           lea  ecx,[ebx+USB_DEVICE->cbw]
           mov  usb_rxtx_bbb_cbw,ecx
           lea  ecx,[ebx+USB_DEVICE->csw]
           mov  usb_rxtx_bbb_csw,ecx
           lea  ecx,[ebx+USB_DEVICE->next_tag]
           inc  dword fs:[ecx]
           mov  ecx,fs:[ecx]
           mov  usb_rxtx_bbb_tag,ecx

           ; determine the direction state
           mov  dx,0x2880      ; dh = read(10) command, dl = 0x80 = flags
           cmp  byte usb_rxtx_bbb_dir,PID_IN
           je   short @f
           mov  dx,0x2A00      ; dh = write(10) command, dl = 0x00 = flags
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build a command block wrapper
@@:        mov  edi,usb_rxtx_bbb_cbw
           mov  ax,sizeof(BBB_CBW)
           call memset32
           mov  dword fs:[edi+BBB_CBW->sig],0x43425355
           mov        fs:[edi+BBB_CBW->tag],ecx
           movzx eax,word fs:[ebx+USB_DEVICE->block_size]
           mov       fs:[edi+BBB_CBW->length],eax
           mov       fs:[edi+BBB_CBW->flags],dl
           mov  byte fs:[edi+BBB_CBW->lun],0x00
           mov  byte fs:[edi+BBB_CBW->cb_len],10
             mov       fs:[edi+BBB_CBW->cmnd+0],dh
            ;mov  byte fs:[edi+BBB_CBW->cmnd+1],0
             mov  eax,usb_rxtx_bbb_lba
             bswap eax
             mov  fs:[edi+BBB_CBW->cmnd+2],eax
            ;mov  byte fs:[edi+BBB_CBW->cmnd+6],0
             mov  byte fs:[edi+BBB_CBW->cmnd+7],0  ; count high-byte
             mov  byte fs:[edi+BBB_CBW->cmnd+8],1  ; count low-byte
            ;mov  byte fs:[edi+BBB_CBW->cmnd+9],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+10],0
            ;mov  byte fs:[edi+BBB_CBW->cmnd+11],0
           
           ; send the CBW packet
           mov  al,PID_OUT         ; direction (PID_IN or PID_OUT)
           mov  cx,sizeof(BBB_CBW) ; packet size
           call es:[esi+USB_CONTROLLER->callback_bulk]
           cmp  eax,-1
           jle  short usb_rxtx_sector_bbb_done

           ; send the IN/OUT packets
           mov  edi,usb_rxtx_bbb_buf
           mov  al,usb_rxtx_bbb_dir ; direction (PID_IN or PID_OUT)
           mov  cx,fs:[ebx+USB_DEVICE->block_size] ; packet size
           call es:[esi+USB_CONTROLLER->callback_bulk]
           cmp  eax,-1
           jle  short usb_rxtx_sector_bbb_done
           mov  usb_rxtx_bbb_buf,eax  ; save the count (512 or 2048)

           ; send the CSW packets packet
           mov  edi,usb_rxtx_bbb_csw
           mov  al,PID_IN          ; direction (PID_IN or PID_OUT)
           mov  cx,sizeof(BBB_CSW) ; packet size
           call es:[esi+USB_CONTROLLER->callback_bulk]
           cmp  eax,-1
           jle  short usb_rxtx_sector_bbb_done

           ; make sure the tag is the same
           mov  ecx,fs:[edi+BBB_CSW->tag]
           cmp  ecx,usb_rxtx_bbb_tag
           jne  short usb_rxtx_sector_bbb_done
           
           mov  eax,usb_rxtx_bbb_buf  ; restore the count from above
usb_rxtx_sector_bbb_done:
           mov  sp,bp
           pop  bp
           ret
usb_rxtx_sector_bbb endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read a sector from the drive (Using CBI)
; on entry:
;  eax = lba to read/write
;  cl = PID_IN or PID_OUT
;  es:esi-> = this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
;  fs:edi-> = buffer to read/write
; on return
;  eax = bytes read (512 for a 'floppy' or 'hard drive', 2048 for a cdrom)
;      = negative value if error
; destroys none
usb_rxtx_sector_cbi proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,10

usb_rxtx_cbi_lba   equ  [bp-4]   ; dword
usb_rxtx_cbi_buf   equ  [bp-8]   ; dword
usb_rxtx_cbi_dir   equ  [bp-9]   ; byte

           ; save the addresses to our buffers
           mov  usb_rxtx_cbi_dir,cl
           mov  usb_rxtx_cbi_lba,eax
           mov  usb_rxtx_cbi_buf,edi
           lea  edi,[ebx+USB_DEVICE->rxtx_buffer]

           ; determine the direction state
           mov  dh,0x28        ; dh = read(10) command
           cmp  byte usb_rxtx_cbi_dir,PID_IN
           je   short @f
           mov  dh,0x2A        ; dh = write(10) command

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; build a command block
           ; (must be at [eax+USB_DEVICE->rxtx_buffer])
@@:        mov  ax,12
           call memset32
           
           mov       fs:[edi+0],dh
          ;mov  byte fs:[edi+1],0
           mov  eax,usb_rxtx_cbi_lba
           bswap eax
           mov  fs:[edi+2],eax
          ;mov  byte fs:[edi+6],0
           mov  byte fs:[edi+7],0  ; count high-byte
           mov  byte fs:[edi+8],1  ; count low-byte
          ;mov  byte fs:[edi+9],0
          ;mov  byte fs:[edi+10],0
          ;mov  byte fs:[edi+11],0

           ; send the CBW packet
           mov  edi,offset request_cbi_cmd_str
           mov  cx,12
           xor  dx,dx
           mov  al,PID_OUT
           call es:[esi+USB_CONTROLLER->callback_control]
           cmp  eax,-1
           jle  short usb_rxtx_cbi_done

           ; send the IN/OUT packets packet
           mov  edi,usb_rxtx_cbi_buf
           mov  al,usb_rxtx_cbi_dir ; direction (PID_IN or PID_OUT)
           mov  cx,fs:[ebx+USB_DEVICE->block_size] ; packet size
           call es:[esi+USB_CONTROLLER->callback_bulk]
           
usb_rxtx_cbi_done:
           mov  sp,bp
           pop  bp
           ret
usb_rxtx_sector_cbi endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; mount the device
; on entry:
;  dx = zero based port number (0 -> (USB_DEVICE_MAX-1)) (is device number - 1)
;  fs:ebx -> USB_DEVICE
;  es:esi-> = this USB_CONTROLLER structure
; on return
;  al = 1 if successful
; destroys none
usb_mount_device proc near uses ebx ecx edx esi edi ds
           push bp
           mov  bp,sp
           sub  sp,4

mt_tx_buffer   equ  [bp-4]

           lea  eax,[ebx+USB_DEVICE->rxtx_buffer]
           mov  mt_tx_buffer,eax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; try the inquiry command

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; try to get the drive capacity
           ; QEMU requires you do this twice, for the first time
           ;  is for QEMU's sake to get the capacity.......weird
;.ifdef BX_QEMU
           call usb_drive_capacity
;.endif
           call usb_drive_capacity
           cmp  eax,8                   ; we are expecting 8 bytes
           jl   usb_mount_error

           ; 8-byte return has last LBA, size of sector
           mov  edi,mt_tx_buffer
           mov  eax,fs:[edi+0]
           bswap eax
           inc  eax
           mov  fs:[ebx+USB_DEVICE->sectors+0],eax
           mov  dword fs:[ebx+USB_DEVICE->sectors+4],0
           mov  eax,fs:[edi+4]
           bswap eax
           mov  fs:[ebx+USB_DEVICE->block_size],ax
           mov  fs:[ebx+USB_DEVICE->log_size],ax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; try to read a sector from the device
           xor  eax,eax
           mov  cl,PID_IN
           mov  edi,mt_tx_buffer
           call usb_rxtx_sector
           cmp  eax,-1
           jle  usb_mount_error
           ; does count of bytes read = fs:[ebx+USB_DEVICE->block_size]
           movzx ecx,word fs:[ebx+USB_DEVICE->block_size]
           cmp  eax,ecx
           jne  usb_mount_error

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; determine if the loaded sector is a MBR, or has a BPB, etc,
           ;  and try to indicate it a HD, Floppy, or CDROM
           ; 1) check the count of sectors, if it is 2880, we are a floppy
           ; 2) check the sector size, if it is 2048, we are a cdrom
           ; 3) see if the first sector is a BPB, if not HD
           ;    if it is a BPB, check some of the items to determine HD or Floppy

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; is it a CD-ROM
           cmp  word fs:[ebx+USB_DEVICE->block_size],2048
           jne  short usb_mount_test_floppy
           call usb_mount_hdd_cdrom
           jmp  usb_mount_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; is it a floppy
           ; check to see if the sectors = 2880
           ;  * we assume it is a floppy if it has 2880 sectors *
usb_mount_test_floppy:
           cmp  word fs:[ebx+USB_DEVICE->sectors+4],0
           ja   short @f
           cmp  word fs:[ebx+USB_DEVICE->sectors+0],2880
           jne  short @f

           ; we need to update the CHS values from the LBA value
           mov  byte fs:[ebx+USB_DEVICE->org_media],USB_MSD_MEDIA_FLOPPY
           mov  byte fs:[ebx+USB_DEVICE->media],USB_MSD_MEDIA_FLOPPY
           mov  byte fs:[ebx+USB_DEVICE->boot_dl],0
           mov  dword fs:[ebx+USB_DEVICE->base_lba],0
           mov  word fs:[ebx+USB_DEVICE->log_size],512
           ; convert from LBAs to CHS
           mov  cl,18   ; sectors per track
           mov  al,2    ; heads
           call convert_lba_cylinders
           call usb_add_boot_vector
           call usb_mount_display
           jmp  short usb_mount_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; is it a hard drive?
           ;  we have read the first sector. (at mt_tx_buffer)
           ;  determine if it is a MBR, BPB, etc.
           ;  if the BPB states a floppy emulation, we set the LBAs to 2880 
           ;  if the BPB states a hard drive, or is MBR, continue on
           ; A lot of OSes, including freedos, *assume* that if we boot the floppy, dl will be 0
           ; (freedos' bootsector doesn't even save dl)
           ; therefore, we set dl to zero for floppys, 0x80 for harddrives, and 0xE0 for cdroms
@@:        ; we need to update the CHS values from the LBA value

           mov  byte fs:[ebx+USB_DEVICE->org_media],USB_MSD_MEDIA_HARDDRIVE

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check to see if it is a floppy disk image with a BPB
           mov  edi,mt_tx_buffer
           call usb_mount_hdd_floppy
           or   al,al
           jnz  short usb_mount_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; else emulate a hard drive
           mov  byte fs:[ebx+USB_DEVICE->media],USB_MSD_MEDIA_HARDDRIVE
           mov  byte fs:[ebx+USB_DEVICE->boot_dl],0x80
           mov  dword fs:[ebx+USB_DEVICE->base_lba],0
           mov  word fs:[ebx+USB_DEVICE->log_size],512
           ; convert from LBAs to CHS
           mov  cl,63
           mov  al,16
           call convert_lba_cylinders ; ax = 41 (msdos), 656 (win95), 3641 (winxp)
           call usb_add_boot_vector
           call usb_mount_display

           ; we need to increment the count of hard drives in the BDA
           push ds
           xor  cx,cx
           mov  ds,cx
           inc  byte [0x0475]
           pop  ds

usb_mount_done:
           ; successful mount
           mov  al,1
           mov  sp,bp
           pop  bp
           ret

usb_mount_error:
           xor  al,al
           mov  sp,bp
           pop  bp
           ret
usb_mount_device endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; display the type of device we found
; on entry:
;  fs:ebx -> USB_DEVICE
; on return
;  nothing
; destroys none
usb_mount_display proc near uses alld ds
           ; is it an actual floppy disk
           cmp  byte fs:[ebx+USB_DEVICE->org_media],USB_MSD_MEDIA_FLOPPY
           jne  short usb_mount_display_0

           push word fs:[ebx+USB_DEVICE->bios_addr]
           push word fs:[ebx+USB_DEVICE->sectors]
           mov  bx,4
           mov  si,offset usb_mount_floppy_str
           jmp  usb_mount_disp_do

usb_mount_display_0:
           ; else see if the actual media is a hard drive
           cmp  byte fs:[ebx+USB_DEVICE->org_media],USB_MSD_MEDIA_HARDDRIVE
           jne  short usb_mount_display_1

           ; now see if we are emulating a floppy
           cmp  byte fs:[ebx+USB_DEVICE->media],USB_MSD_MEDIA_FLOPPY
           jne  short @f

           ; is an emulated floppy type
           push word fs:[ebx+USB_DEVICE->bios_addr]
           push word fs:[ebx+USB_DEVICE->sectors]
           push dword fs:[ebx+USB_DEVICE->base_lba]
           mov  bx,8
           mov  si,offset usb_mount_hdd_flpy_str
           jmp  short usb_mount_disp_do

@@:        ; is an actual hard drive type
           push word fs:[ebx+USB_DEVICE->bios_addr]
           push dword fs:[ebx+USB_DEVICE->sectors+0]
           mov  bx,6
           mov  si,offset usb_mount_harddisk_str
           jmp  short usb_mount_disp_do

usb_mount_display_1:
           cmp  byte fs:[ebx+USB_DEVICE->org_media],USB_MSD_MEDIA_CDROM
           jne  short usb_mount_display_2

           ; now see if we are emulating a floppy
           cmp  byte fs:[ebx+USB_DEVICE->media],USB_MSD_MEDIA_FLOPPY
           jne  short @f

           ; is an emulated floppy type
           push word fs:[ebx+USB_DEVICE->bios_addr]
           push word fs:[ebx+USB_DEVICE->sectors]
           push dword fs:[ebx+USB_DEVICE->base_lba]
           mov  bx,8
           mov  si,offset usb_mount_cd_flpy_str
           jmp  short usb_mount_disp_do

@@:        ; now see if we are emulating a hard drive
           cmp  byte fs:[ebx+USB_DEVICE->media],USB_MSD_MEDIA_HARDDRIVE
           jne  short @f

           ; is an emulated hard drive type
           push word fs:[ebx+USB_DEVICE->bios_addr]
           push dword fs:[ebx+USB_DEVICE->sectors+0]
           push dword fs:[ebx+USB_DEVICE->base_lba]
           mov  bx,10
           mov  si,offset usb_mount_cd_hdd_str
           jmp  short usb_mount_disp_do

@@:        ; else is an actual cdrom
           push word fs:[ebx+USB_DEVICE->bios_addr]
           push dword fs:[ebx+USB_DEVICE->sectors+0]
           mov  bx,6
           mov  si,offset usb_mount_cdrom_str

usb_mount_disp_do:
           mov  ax,BIOS_BASE2
           mov  ds,ax
           call bios_printf
           add  sp,bx

usb_mount_display_2:
           ret
usb_mount_display endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; add this entry to the boot vector list
; on entry:
;  fs:ebx -> USB_DEVICE
; on return
;  nothing
; destroys none
usb_add_boot_vector proc near uses eax ecx edx si es
           mov  eax,fs:[ebx+USB_DEVICE->base_lba]
           mov  edx,((IPL_FLAGS_NSATA << 16) | (IPL_TYPE_USB << 8) | (0 << 0))

           ; calculate the emulated device number to use
           ; device address = (dx = zero based device number) + 1
           mov  dl,fs:[ebx+USB_DEVICE->device_num]
           or   dl,fs:[ebx+USB_DEVICE->controller]
           mov  fs:[ebx+USB_DEVICE->bios_addr],dl
           
           ; add this drive to our vector table
           push cs
           pop  es
           movzx si,byte fs:[ebx+USB_DEVICE->controller]
           shr  si,6
           imul si,CONTROLLER_STR_LEN
           add  si,offset usb_controller_str
           xor  ecx,ecx          ; vector = 0000:0000
           call add_boot_vector
           ret
usb_add_boot_vector endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; convert LBAs (edx:eax) to cylinders
; on entry:
;  fs:ebx -> USB_DEVICE
;  al = heads
;  cl = spt
; on return
;  eax = cylinders
;  (this will round up)
; destroys none
convert_lba_cylinders proc near uses ecx edx
           mov  fs:[ebx+USB_DEVICE->heads],al
           mov  fs:[ebx+USB_DEVICE->spt],cl

           mov  edx,fs:[ebx+USB_DEVICE->sectors+4]
           mov  eax,fs:[ebx+USB_DEVICE->sectors+0]
           ; divide by 'heads' with remainder
           movzx ecx,byte fs:[ebx+USB_DEVICE->heads]
           div  ecx
           ; if remainder > 0, increment eax
           cmp  dl,0
           jz   short @f
           inc  eax
           ; divide by 'spt' with remainder
@@:        movzx ecx,byte fs:[ebx+USB_DEVICE->spt]
           xor  edx,edx
           div  ecx
           ; if remainder > 0, increment eax
           cmp  dl,0
           jz   short @f
           inc  eax
@@:        mov  fs:[ebx+USB_DEVICE->cyls],ax
           ret
convert_lba_cylinders endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get the controller and device data pointers from dl
; on entry:
;  es = segment of EBDA
;  dl = BIOS device address
; on return
;  fs:ebx -> USB_DEVICE
;  es:esi -> this USB_CONTROLLER structure
;  dx = port number (zero based)
usb_get_cntrl_device proc near uses eax
           ; dl = our device address
           ; controller type in bits 7:6
           ; controller index in bits 5:4
           ; zero based port in bits 3:0

           ; point to our controller struct (use es:esi+USB_CONTROLLER->)
           movzx esi,dl
           shr  esi,6
           imul esi,(sizeof(USB_CONTROLLER) * MAX_USB_CONTROLLERS)
           movzx eax,dl
           shr  al,4
           and  al,0x3
           imul eax,sizeof(USB_CONTROLLER)
           add  esi,eax
           add  esi,EBDA_DATA->usb_uhci_cntrls

           ; point to our device struct (use fs:ebx+USB_DEVICE->)
           and  edx,0xF
           imul ebx,edx,sizeof(dword)
           add  ebx,USB_CONTROLLER->device_data
           add  ebx,esi
           mov  ebx,es:[ebx]
           
           ret
usb_get_cntrl_device endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; check to see if the BPB at this location specifies a floppy
; (if the emulated device is a hard drive with a 1.44Meg floppy image
;  at LBA 0, we emulate a floppy disk, *not* the hard drive. Only
;  lba's 0 to 2879 are accessible.)
; on entry:
;  fs:edi -> sector read (BPB)
;  fs:ebx -> USB_DEVICE
;  es:esi -> this USB_CONTROLLER structure
;  es = segment of EBDA
; on return
;  al = 1 = is 1.44 meg at this location
;     = 0 = not a 1.44 meg at this location
; destroys nothing
usb_mount_hdd_floppy proc near
           ; detect to see if a FAT style BPB is present
           ; (if byte[0] == 0xEB and byte[2] == 0x90)
           cmp  byte fs:[edi+0],0xEB
           jne  short @f
           cmp  byte fs:[edi+2],0x90
           je   short usb_mount_isfloppy_jmp

           ; (if byte[0] == 0xE9 and word[1] < 0x1FE)
@@:        cmp  byte fs:[edi+0],0xE9
           jne  usb_mount_isfloppy_error
           cmp  word fs:[edi+1],0x1FE
           ja   usb_mount_isfloppy_error

           ; we found a valid jump instruction at offset zero
           ; so check the bytes per sector value is 512
usb_mount_isfloppy_jmp:
           cmp  word fs:[edi+11],512
           jne  usb_mount_isfloppy_error
           
           ; check the sectors reserved value is not zero
           cmp  word fs:[edi+14],0
           je   usb_mount_isfloppy_error
           
           ; check the fats value is 1 or 2
           cmp  byte fs:[edi+16],0
           je   usb_mount_isfloppy_error
           cmp  byte fs:[edi+16],2
           ja   usb_mount_isfloppy_error

           ; check the system type value to be 'FAT12   '
           cmp  dword fs:[edi+54],0x31544146
           jne  short usb_mount_isfloppy_error
           cmp  dword fs:[edi+58],0x20202032
           jne  short usb_mount_isfloppy_error

           ; check the sectors or sectors_extended field to be 2880
           cmp  word fs:[edi+19],2880
           je   short @f
           cmp  word fs:[edi+19],0
           jne  short usb_mount_isfloppy_error
           cmp  dword fs:[edi+32],2880
           jne  short usb_mount_isfloppy_error

           ; we found a 1.44Meg floppy 'image', so emulate that.
@@:        mov  byte fs:[ebx+USB_DEVICE->media],USB_MSD_MEDIA_FLOPPY
           mov  byte fs:[ebx+USB_DEVICE->boot_dl],0
           mov  byte fs:[ebx+USB_DEVICE->heads],2
           mov  byte fs:[ebx+USB_DEVICE->spt],18
           mov  word fs:[ebx+USB_DEVICE->cyls],80
           mov  dword fs:[ebx+USB_DEVICE->sectors+0],2880
           mov  dword fs:[ebx+USB_DEVICE->sectors+4],0
           mov  dword fs:[ebx+USB_DEVICE->base_lba],0
           mov  word fs:[ebx+USB_DEVICE->log_size],512
           call usb_add_boot_vector
           call usb_mount_display
           
           mov  al,1
           ret

usb_mount_isfloppy_error:
           xor  al,al
           ret
usb_mount_hdd_floppy endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; check to see if hdd image is a CD-ROM with a bootable image on it
; on entry:
;  fs:edi -> sector read (also a valid buffer pointer to read other sectors to)
;  fs:ebx -> USB_DEVICE
;  es:esi-> = this USB_CONTROLLER structure
;  es = segment of EBDA
; on return
;  al = 1 = found image
;     = 0 = no bootable image found
; destroys nothing
usb_mount_hdd_cdrom proc near
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; try to read sector 16 from the device
           mov  eax,17
           mov  cl,PID_IN
           call usb_rxtx_sector
           cmp  eax,-1
           jle  usb_mount_iscdrom_error

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check for valid items
@@:        cmp  byte fs:[edi+0],0x00
           jne  usb_mount_iscdrom_error

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; string at [edi+1] should be 'CD001'
@@:        pushd 5
           mov  eax,offset cdrom_isotag
           add  eax,(BIOS_BASE << 4)
           push eax
           lea  eax,[edi+1]
           push eax
           call memcmp32
           add  sp,12
           or   ax,ax
           jnz  usb_mount_iscdrom_error

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; string at [edi+7] should be 'EL TORITO SPECIFICATION'
@@:        pushd 23
           mov  eax,offset cdrom_eltorito
           add  eax,(BIOS_BASE << 4)
           push eax
           lea  eax,[edi+7]
           push eax
           call memcmp32
           add  sp,12
           or   ax,ax
           jnz  usb_mount_iscdrom_error

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Get the Boot Catalog address
@@:        mov  eax,fs:[edi+0x0047]  ; LBA
           mov  cl,PID_IN
           call usb_rxtx_sector
           cmp  eax,-1
           jle  usb_mount_iscdrom_error

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
           cmp  byte fs:[edi+0x00],0x01 ; 1 = Header ID
           jne  usb_mount_iscdrom_error
           cmp  byte fs:[edi+0x01],0x00 ; 0 = platform = 80x86
           jne  usb_mount_iscdrom_error
           cmp  word fs:[edi+0x1E],0xAA55 ; 0x55 0xAA
           jne  usb_mount_iscdrom_error

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we are at the first entry (edi + 0x20)
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
           cmp  byte fs:[edi+0x20+0x00],0x88 ; 0x88 = Bootable
           je   short @f
           
           ; todo: go to the next entry.
           ;  the one after the initial will have 0x90 as the header id if there are
           ;   more entries to follow, else 0x91 means last entry.
           ;  a lot of CD-ROMs have a zero at the 2nd entry with nothing following.
           ;  (i.e.: they only have the Initial entry abov)

           jmp  usb_mount_iscdrom_error

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get the emulation type
@@:        mov  byte fs:[ebx+USB_DEVICE->org_media],USB_MSD_MEDIA_CDROM
           mov  al,fs:[edi+0x20+0x01] ; media type
           cmp  al,0x00          ; 0 = no emu
           jne  short @f         ;

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; no emulation, so mount as a CD-ROM form LBA 0
           ; we have to set drive to 0xE0 (a Win2k 'bug' ?)
           mov  byte fs:[ebx+USB_DEVICE->media],USB_MSD_MEDIA_CDROM
           mov  byte fs:[ebx+USB_DEVICE->boot_dl],0xE0
           mov  byte fs:[ebx+USB_DEVICE->heads],0
           mov  byte fs:[ebx+USB_DEVICE->spt],0
           mov  word fs:[ebx+USB_DEVICE->cyls],0
           mov  dword fs:[ebx+USB_DEVICE->sectors+0],0
           mov  dword fs:[ebx+USB_DEVICE->sectors+4],0
           mov  dword fs:[ebx+USB_DEVICE->base_lba],0
           mov  word fs:[ebx+USB_DEVICE->log_size],2048
           call usb_add_boot_vector
           call usb_mount_display
           
           mov  al,1
           ret

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; floppy emulation
@@:        cmp  al,3             ; 1,2,3 = floppy
           ja   short @f         ;
           
           mov  byte fs:[ebx+USB_DEVICE->media],USB_MSD_MEDIA_FLOPPY
           mov  byte fs:[ebx+USB_DEVICE->boot_dl],0
           mov  byte fs:[ebx+USB_DEVICE->heads],2
           mov  byte fs:[ebx+USB_DEVICE->spt],18
           mov  word fs:[ebx+USB_DEVICE->cyls],80
           mov  dword fs:[ebx+USB_DEVICE->sectors+0],2880
           mov  dword fs:[ebx+USB_DEVICE->sectors+4],0
           mov  eax,fs:[edi+0x20+0x08]    ; 2048-byte lba
           mov  fs:[ebx+USB_DEVICE->base_lba],eax
           mov  word fs:[ebx+USB_DEVICE->log_size],512
           call usb_add_boot_vector
           call usb_mount_display
           
           mov  al,1
           ret
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; else, it has to be a hard drive
@@:        mov  byte fs:[ebx+USB_DEVICE->media],USB_MSD_MEDIA_HARDDRIVE
           mov  byte fs:[ebx+USB_DEVICE->boot_dl],0x80
           mov  byte fs:[ebx+USB_DEVICE->heads],2 ;;;;;;;;;;;;;;;;;;;;;
           mov  byte fs:[ebx+USB_DEVICE->spt],18 ;;;;;;;;;;;;;;;;;;;;;
           mov  word fs:[ebx+USB_DEVICE->cyls],80 ;;;;;;;;;;;;;;;;;;;;;
           mov  dword fs:[ebx+USB_DEVICE->sectors+0],2880 ;;;;;;;;;;;;;;;;;;;;;
           mov  dword fs:[ebx+USB_DEVICE->sectors+4],0
           mov  eax,fs:[edi+0x20+0x08]    ; 2048-byte lba
           mov  fs:[ebx+USB_DEVICE->base_lba],eax
           mov  word fs:[ebx+USB_DEVICE->log_size],512
           call usb_add_boot_vector
           call usb_mount_display
           
           mov  al,1
           ret

;  for the CDROM emulation to work (floppy or hdd), we have to read 512-byte sectors,
;   not 2048 byte sectors in the INT calls..........
;           mov  dx,[bx+0x02]     ; save in dx for later
;           mov  es:[EBDA_DATA->cdemu_load_segment],dx
;           mov  word es:[EBDA_DATA->cdemu_buffer_offset],0x0000
;           movzx ecx,word [bx+06] ; count of 512-byte sectors
;           mov  es:[EBDA_DATA->cdemu_sector_count],cx

usb_mount_iscdrom_error:
           xor  al,al
           ret
usb_mount_hdd_cdrom endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; load USB boot sector
; on entry:
;  eax = base_lba on USB device of this 'partition'
;  es = segment of EBDA
;  dl = device
; on return
;  al = status = 0 = successful
;  ah = drive number to return (0x0x, 0x8x, 0xEx)
; destroys nothing
boot_usb_funtion proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,2

boot_usb_device  equ  [bp-2]
           
           ; save the device and base lba values
           mov  boot_usb_device,dl
           mov  es:[EBDA_DATA->usb_disk_base_lba],eax

           ; get the controller and device data pointers
           call usb_get_cntrl_device

           ; get our buffer address
           lea  edi,[ebx+USB_DEVICE->rxtx_buffer]

           ; read the first sector from the disk
           mov  eax,es:[EBDA_DATA->usb_disk_base_lba]
           mov  cl,PID_IN
           call usb_rxtx_sector
           cmp  eax,-1
           jle  short usb_boot_done

           ;xchg cx,cx ; ben

           lea  esi,[ebx+USB_DEVICE->rxtx_buffer]

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
           mov  al,fs:[ebx+USB_DEVICE->media]
           mov  es:[EBDA_DATA->usb_disk_media],al
           mov  al,fs:[ebx+USB_DEVICE->boot_dl]
           mov  es:[EBDA_DATA->usb_disk_emulated_drive],al

           mov  al,boot_usb_device
           mov  es:[EBDA_DATA->usb_disk_emulated_device],al
           mov  ah,es:[EBDA_DATA->usb_disk_emulated_drive]
           xor  al,al

           mov  byte es:[EBDA_DATA->usb_disk_active],1
usb_boot_done:
           mov  sp,bp            ; restore the stack
           pop  bp
           ret
boot_usb_funtion endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; USB Disk Emulation services
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
int13_usb_disk_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           sub  sp,24

usb_sv_device    equ  [bp-2]  ; word
usb_sv_count     equ  [bp-4]  ; word
usb_sv_cylinder  equ  [bp-6]  ; word
usb_sv_sector    equ  [bp-8]  ; word
usb_sv_head      equ  [bp-10]  ; word
usb_sv_lba_low   equ  [bp-14]  ; dword
usb_sv_cur_gdt   equ  [bp-22]  ; qword (fword + 2 filler)
usb_sv_cur_a20   equ  [bp-23]  ; byte
usb_sv_direction equ  [bp-24]  ; byte

           ; retrieve the current GDT, and set it to ours
           push fs                 ; preserve the fs segment register
           sgdt far usb_sv_cur_gdt ; save the current GDT address
           call unreal_post        ;
           mov  usb_sv_cur_a20,al  ; save current a20 status

           ; get our emulated device value
           mov  dl,es:[EBDA_DATA->usb_disk_emulated_device]
           ; get the controller and device data pointers
           call usb_get_cntrl_device
           mov  usb_sv_device,dx

           ; set ds = bios data area (0x0040)
           mov  ax,0x0040
           mov  ds,ax
           
           ; clear completion flag
           mov  byte [0x008E],0
           
           mov  ah,REG_AH

           ; es = segment of EBDA
           ; ah = service
           ;  fs:ebx -> USB_DEVICE
           ;  es:esi-> = this USB_CONTROLLER structure
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; controller reset
           cmp  ah,0x00
           jne  short @f
           ; we ignore this one
           jmp  int13_usb_disk_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disk status
@@:        cmp  ah,0x01
           jne  short @f

           ; are we the floppy drive?
           cmp  byte es:[EBDA_DATA->usb_disk_media],USB_MSD_MEDIA_FLOPPY
           jne  short int13_usb_status0
           ; floppy
           mov  ah,[0x0041]
           mov  REG_AH,ah
           jmp  short int13_usb_status1
int13_usb_status0:
           ; hard drive
           xor  ah,ah
           xchg ah,[0x0074]
           mov  REG_AH,ah
int13_usb_status1:
           or   ah,ah
           jnz  int13_usb_disk_fail_nostatus
           jmp  int13_usb_disk_success_noah
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; transfer sectors
@@:        cmp  ah,0x02          ; read disk sectors
           je   short int13_usb_transfer
           cmp  ah,0x03          ; write disk sectors
           je   short int13_usb_transfer
           cmp  ah,0x04          ; verify disk sectors
           jne  @f
int13_usb_transfer:
           xor  ah,ah
           mov  al,REG_AL
           mov  usb_sv_count,ax
           mov  al,REG_CL
           shl  ax,2
           and  ah,0x03
           mov  al,REG_CH
           mov  usb_sv_cylinder,ax
           xor  ah,ah
           mov  al,REG_CL
           and  al,0x3F
           mov  usb_sv_sector,ax
           mov  al,REG_DH
           mov  usb_sv_head,ax

           ; if count > 128, or count == 0, or sector == 0, error
           cmp  word usb_sv_count,0
           je   int13_usb_disk_fail
           cmp  word usb_sv_count,128
           ja   int13_usb_disk_fail
           cmp  word usb_sv_sector,0
           je   int13_usb_disk_fail
           
           ; convert to LBA
           ; lba = (((cylinder * heads) + head) * spt) + (sector - 1);
           movzx eax,word usb_sv_cylinder
           movzx ecx,byte fs:[ebx+USB_DEVICE->heads]
           mul  ecx
           movzx ecx,word usb_sv_head
           add  eax,ecx
           movzx ecx,byte fs:[ebx+USB_DEVICE->spt]
           mul  ecx
           movzx ecx,word usb_sv_sector
           add  eax,ecx
           dec  eax
           mov  usb_sv_lba_low,eax
           
           ; check to see if within our limits
           ; (we don't have to check hiword, since CHS could never get that high)
           movzx ecx,word usb_sv_count
           add  eax,ecx
           dec  eax
           cmp  eax,fs:[ebx+USB_DEVICE->sectors]
           jae  int13_usb_disk_fail
           
           ; if we are verifying a sector(s), just return as good
           cmp  byte REG_AH,0x04
           je   int13_usb_disk_success
           
           mov  byte usb_sv_direction,PID_IN
           cmp  byte REG_AH,0x02
           je   short int13_usb_read
           mov  byte usb_sv_direction,PID_OUT
int13_usb_read:
           ; calculate physical address of callers buffer
           movzx edi,word REG_ES
           movzx ecx,word REG_BX
           shl  edi,4
           add  edi,ecx

           ; running count of sectors read/written
           xor  cx,cx
int13_usb_tx_sectors_loop:
           push cx
           mov  eax,usb_sv_lba_low
           add  eax,es:[EBDA_DATA->usb_disk_base_lba]
           mov  dx,usb_sv_device
           mov  cl,usb_sv_direction
           call usb_rxtx_sector
           movzx edx,word fs:[ebx+USB_DEVICE->block_size]
           cmp  eax,edx
           je   short int13_usb_tx_sectors_0
           add  sp,2
           mov  byte REG_AH,0x0C
           jmp  int13_usb_disk_fail_noah

int13_usb_tx_sectors_0:
           ; move to next sector
           movzx eax,word fs:[ebx+USB_DEVICE->block_size]
           add  edi,eax

           inc  dword usb_sv_lba_low
           pop  cx
           inc  cx
           dec  word usb_sv_count
           jnz  short int13_usb_tx_sectors_loop

           ; if a hard drive, need to set the completion flag
           cmp  byte es:[EBDA_DATA->usb_disk_media],USB_MSD_MEDIA_HARDDRIVE
           jne  short int13_usb_tx_sectors_1
           ; completion code in the BDA
           mov  byte [0x008E],0xFF
           clc
           mov  ax,0x9100
           int  15h
int13_usb_tx_sectors_1:
           
           ; count of sectors transferred
           mov  REG_AL,cl
           jmp  int13_usb_disk_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; format disk track
@@:        cmp  ah,0x05
           jne  short @f
           ; we currently don't support this function

           ; we could simply write 0xFA to the sector.....
           ;  fill the rxdx_buffer with 0xFA(?) and then write to the sector(s)
           ;   mov  cl,PID_OUT
           ;   add  eax,es:[EBDA_DATA->usb_disk_base_lba]
           ;   call usb_rxtx_sector
           
           ; completion code in the BDA
           ;mov  byte [0x008E],0xFF

           mov  byte REG_AH,0x01
           jmp  int13_usb_disk_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get disk drive parameters
@@:        cmp  ah,0x08
           jne  short @f
           
           ; cylinder (ch = low 8 bits, cl = high bits in 7:6)
           mov  cx,fs:[ebx+USB_DEVICE->cyls]
           dec  cx               ; zero based
           xchg ch,cl
           shl  cl,6
           ; spt (low 5:0 bits of cl)
           mov  al,fs:[ebx+USB_DEVICE->spt]
           and  al,0x3F
           or   cl,al
           mov  REG_CX,cx
           ; zero based head in dh
           mov  al,fs:[ebx+USB_DEVICE->heads]
           dec  al
           mov  REG_DH,al
           ; dl = count of drives
           mov  dl,es:[EBDA_DATA->ata_hdcount]
           inc  dl      ; include this emulated one
           cmp  byte es:[EBDA_DATA->usb_disk_media],USB_MSD_MEDIA_FLOPPY
           jne  short int13_usb_params_0
           mov  dl,1             ; when emulating the floppy, only support 1 floppy drive
           ; bl and es:di (floppies only)
           mov  byte REG_BL,0x04
           mov  ax,offset diskette_param_table
           mov  REG_DI,ax
           mov  word REG_ES,BIOS_BASE
int13_usb_params_0:
           mov  REG_DL,dl
           mov  word REG_AX,0x0000
           jmp  int13_usb_disk_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize controller with drive parameters
@@:        cmp  ah,0x09
           jne  short @f

           ; we can call init_harddrive_params for this ??? minus the adding to the vector table ???

           jmp  int13_usb_disk_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check drive ready
@@:        cmp  ah,0x10
           jne  short @f
           ; we should always be ready
           jmp  int13_usb_disk_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read disk drive size
@@:        cmp  ah,0x15
           jne  short @f

           mov  ah,0x01          ; floppy disk
           cmp  byte es:[EBDA_DATA->usb_disk_media],USB_MSD_MEDIA_FLOPPY
           je   short int13_usb_size_0
           mov  eax,fs:[ebx+USB_DEVICE->sectors]
           mov  REG_DX,ax
           shr  eax,16
           mov  REG_CX,ax
           mov  ah,0x03          ; hard disk
int13_usb_size_0:           
           mov  REG_AH,ah
           jmp  int13_usb_disk_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get change line status
@@:        cmp  ah,0x16
           jne  short @f
           mov  byte REG_AH,0x06 ; change line not supported
           jmp  int13_usb_disk_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set media type format
@@:        cmp  ah,0x18
           jne  short @f
           mov  byte REG_AH,0x01 ; function not available
           jmp  int13_usb_disk_fail_noah

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
           jmp  int13_usb_disk_success_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS extended services
@@:        cmp  ah,0x42          ; extended read
           je   short int13_usb_ext_transfer
           cmp  ah,0x43          ; extended write
           je   short int13_usb_ext_transfer
           cmp  ah,0x44          ; extended verify
           je   short int13_usb_ext_transfer
           cmp  ah,0x47          ; extended seek
           jne  @f
int13_usb_ext_transfer:
           push ds
           mov  di,REG_SI
           mov  ds,REG_DS
           mov  ax,[di+EXT_SERV_PACKET->ex_count]    ; count
           mov  usb_sv_count,ax
           mov  eax,[di+EXT_SERV_PACKET->ex_lba+0] ; get low 32-bits
           mov  usb_sv_lba_low,eax
           mov  edx,[di+EXT_SERV_PACKET->ex_lba+4] ; get high 32-bits
           ;mov  usb_sv_lba_high,edx
           mov  cx,[di+EXT_SERV_PACKET->ex_size]
           pop  ds
           ; if size of packet < 16, error
           cmp  cx,16
           jb   int13_usb_disk_fail
           ; if edx:eax >= USB_DEVICE->sectors, error
           cmp  edx,fs:[ebx+USB_DEVICE->sectors+4]
           ja   int13_usb_disk_fail
           jb   short int13_usb_ext_transfer1
           cmp  eax,fs:[ebx+USB_DEVICE->sectors+0]
           jae  int13_usb_disk_fail
int13_usb_ext_transfer1:
           ; if we are verifying or seeking to sector(s), just return as good
           cmp  byte REG_AH,0x44
           je   int13_usb_disk_success
           cmp  byte REG_AH,0x47
           je   int13_usb_disk_success

           cmp  word usb_sv_count,0
           je   int13_usb_disk_fail

           ; else do the transfer
           mov  byte usb_sv_direction,PID_IN
           cmp  byte REG_AH,0x42
           je   short int13_usb_ext_read
           mov  byte usb_sv_direction,PID_OUT
int13_usb_ext_read:
           ; calculate physical address of callers buffer
           push ds
           push si
           mov  si,REG_SI
           mov  ds,REG_DS
           ; if seg:off == 0xFFFF:FFFF and ex_size >= 18, use the flat address
           movzx ecx,word [si+EXT_SERV_PACKET->ex_offset]  ; offset of buffer
           movzx edi,word [si+EXT_SERV_PACKET->ex_segment] ; segment of buffer
           shl  edi,4
           add  edi,ecx
           cmp  byte [si+EXT_SERV_PACKET->ex_size],18
           jb   short int13_usb_flat_0
           cmp  dword [si+EXT_SERV_PACKET->ex_offset],0xFFFFFFFF
           jne  short int13_usb_flat_0
           mov  edi,[si+EXT_SERV_PACKET->ex_flataddr]
int13_usb_flat_0:
           pop  si
           pop  ds
           
           ; running count of sectors read/written
           xor  cx,cx
int13_usb_tx_sectors_loop_1:
           push cx
           mov  eax,usb_sv_lba_low
           add  eax,es:[EBDA_DATA->usb_disk_base_lba]
           mov  dx,usb_sv_device
           mov  cl,usb_sv_direction
           call usb_rxtx_sector
           pop  cx
           movzx edx,word fs:[ebx+USB_DEVICE->block_size]
           cmp  eax,edx
           mov  byte REG_AH,0x0C
           jne  int13_usb_disk_fail_noah

           ; move to next sector
           movzx eax,word fs:[ebx+USB_DEVICE->block_size]
           add  edi,eax

           inc  dword usb_sv_lba_low
           inc  cx
           dec  word usb_sv_count
           jnz  short int13_usb_tx_sectors_loop_1

           ; if a hard drive, need to set the completion flag
           cmp  byte es:[EBDA_DATA->usb_disk_media],USB_MSD_MEDIA_HARDDRIVE
           jne  short int13_usb_tx_sectors_2
           ; completion code in the BDA
           mov  byte [0x008E],0xFF
           clc
           mov  ax,0x9100
           int  15h
int13_usb_tx_sectors_2:

           push ds
           push si
           mov  si,REG_SI
           mov  ds,REG_DS
           mov  [si+EXT_SERV_PACKET->ex_count],cx
           pop  si
           pop  ds

           jmp  short int13_usb_disk_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS media
@@:        cmp  ah,0x45          ; lock/unlock drive
           je   short int13_usb_media
           cmp  ah,0x49          ; extended media change
           jne  short @f
int13_usb_media:
           ; we don't do anything, so just return success
           jmp  short int13_usb_disk_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS eject media
@@:        cmp  ah,0x46
           jne  short @f
           mov  byte REG_AH,0xB2 ; media not removable
           jmp  short int13_usb_disk_fail_noah

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS get drive parameters
@@:        cmp  ah,0x48
           jne  short @f

           push ds
           mov  ds,REG_DS
           mov  di,REG_SI
           call usb_int13_edd
           pop  ds
           or   ax,ax
           jnz  short int13_usb_disk_fail
           jmp  short int13_usb_disk_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; IBM/MS set hardware configuration
@@:        cmp  ah,0x4E
           jne  short @f
           mov  al,REG_AL
           cmp  al,0x01          ; disable prefetch
           je   short int13_usb_disk_success
           cmp  al,0x03          ; set pio mode 0
           je   short int13_usb_disk_success
           cmp  al,0x04          ; set default pio transfer mode
           je   short int13_usb_disk_success
           cmp  al,0x06          ; disable inter 13h dma
           je   short int13_usb_disk_success
           jmp  short int13_usb_disk_fail ; else, fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
@@:        ;cmp  ah,0x  ; next value
           ;jne  short @f
           ;
           ;
           ;jmp  int13_usb_disk_success

           xchg cx,cx

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; print a message of this unknown call value
           ;push ds
           ;push cs
           ;pop  ds
           ;shr  ax,8
           ;push ax
           ;mov  si,offset int13_usb_unknown_call_str
           ;call bios_printf
           ;add  sp,2
           ;call freeze
           ;pop  ds

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function failed, or we didn't support function in AH
int13_usb_disk_fail:
           mov  byte REG_AH,0x01  ; default to invalid function in AH or invalid parameter
int13_usb_disk_fail_noah:
           mov  ah,REG_AH
           mov  [0x0074],ah
int13_usb_disk_fail_nostatus:
           or   word REG_FLAGS,0x0001
           jmp  short @f

int13_usb_disk_success:
           mov  byte REG_AH,0x00  ; no error
int13_usb_disk_success_noah:
           mov  byte [0x0074],0x00
           and  word REG_FLAGS,(~0x0001)

           ; restore the caller's gdt and a20 line
@@:        lgdt far usb_sv_cur_gdt
           mov  al,usb_sv_cur_a20
           call set_enable_a20
           pop  fs

           mov  sp,bp
           pop  bp
           ret
int13_usb_disk_function endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; return the drive parameters in es:di
; on entry:
;  es = segment of EBDA
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
;  ds:di->address of parameter list
; on return
;  ax = 0 = success, else failed
; destroys none
usb_int13_edd proc near uses ebx ecx edx
           push eax              ; do not put above with 'uses'

           ; get the size requested
           mov  ax,[di+INT13_DPT->dpt_size]
           cmp  ax,26
           jb   usb_int13_edd_error

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; we only do EDD v1.x for USB emulation

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; size is at least 26, so do EDD 1.x
           mov  word [di+INT13_DPT->dpt_size],26
           cmp  byte es:[EBDA_DATA->usb_disk_media],USB_MSD_MEDIA_HARDDRIVE
           jne  short usb_dpt_is_atapi

           ; values are valid, so write them
           mov  word [di+INT13_DPT->dpt_infos],(1<<1)  ; is valid
           movzx eax,word fs:[ebx+USB_DEVICE->cyls]
           mov  [di+INT13_DPT->dpt_cylinders],eax
           movzx eax,byte fs:[ebx+USB_DEVICE->heads]
           mov  [di+INT13_DPT->dpt_heads],eax
           movzx eax,byte fs:[ebx+USB_DEVICE->spt]
           mov  [di+INT13_DPT->dpt_spt],eax
           mov  eax,fs:[ebx+USB_DEVICE->sectors+0]
           mov  [di+INT13_DPT->dpt_sector_count1],eax
           mov  eax,fs:[ebx+USB_DEVICE->sectors+4]
           mov  [di+INT13_DPT->dpt_sector_count2],eax
           jmp  short usb_dpt_is_not_atapi

usb_dpt_is_atapi:
           cmp  byte es:[EBDA_DATA->usb_disk_media],USB_MSD_MEDIA_CDROM
           jne  short usb_dpt_is_not_atapi
           ; removable, media change, lockable, max values
           ; cyl/head/spt field is not valid (0<<1)
           mov  ax,((1<<2) | (1<<4) | (1<<5) | (1<< 6)) ; | (0<<1)
           mov  [di+INT13_DPT->dpt_infos],ax
           mov  eax,0xFFFFFFFF
           mov  [di+INT13_DPT->dpt_cylinders],eax
           mov  [di+INT13_DPT->dpt_heads],eax
           mov  [di+INT13_DPT->dpt_spt],eax
           mov  [di+INT13_DPT->dpt_sector_count1],eax
           mov  [di+INT13_DPT->dpt_sector_count2],eax
usb_dpt_is_not_atapi:
           mov  ax,fs:[ebx+USB_DEVICE->block_size]
           mov  [di+INT13_DPT->dpt_blksize],ax

           ; successful return
usb_int13_edd_success:
           pop  eax
           xor  ax,ax
           ret

           ; there was an error (return !0)
usb_int13_edd_error:
           pop  eax
           mov  ax,1
           ret
usb_int13_edd endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; calculates the mps from the 18 byte DEVICE DESCRIPTOR
; on entry:
;  fs:edi-> = DEVICE DESCRIPTOR
; on return
;  ax = mps
; destroys none
usb_get_mps proc near uses cx
            movzx cx,byte fs:[edi+7]

            cmp  word fs:[edi+2],0x0300
            jb   short @f

            ; is 3.0, so return 2^mps
            mov  ax,1
            shl  ax,cl
            ret

            ; is 2.xx or less
@@:         mov  ax,cx
            ret
usb_get_mps endp

.endif  ; DO_INIT_BIOS32

.end
