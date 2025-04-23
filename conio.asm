comment |*******************************************************************
*  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: conio.asm                                                          *
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
*   conio include file                                                     *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.16                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 31 Jan 2025                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; display a char to the screen using the VGA BIOS
; On entry:
;  al = char to display
; On return:
;  nothing
;  destroys nothing
display_char proc near uses ax bx

; send to bochs debug ports
.if BX_VIRTUAL_PORTS
           cmp  al,13
           je   short @f
           push dx
           mov  dx,BX_INFO_PORT
           out  dx,al
           pop  dx
@@:
.endif

.if DO_SERIAL_DEBUG
           cmp  al,13
           je   short @f
           push ax
           push dx
           xor  dx,dx  ; first com port
           mov  ah,1
           call debug_serial_out
           pop  dx
           pop  ax
@@:
.endif

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if we are in the graphics mode, call that function
           push ax
           push ds
           call bios_get_ebda
           mov  ds,ax
           mov  bl,[EBDA_DATA->video_use_graphic]
           pop  ds
           pop  ax
           or   bl,bl
           jz   short @f
           call vid_display_char
           ret

@@:        mov  ah,0Eh             ; print char service
           mov  bx,0x0007          ;
           int  10h                ; output the character
           ret
display_char endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; display a string to the screen using the VGA BIOS
; On entry:
;  ds:si -> asciiz string to display
; On return:
;  nothing
;  destroys nothing
display_string proc near uses ax si
           cld
@@:        lodsb
           or   al,al
           jz   short @f
           call display_char
           jmp  short @b
@@:        ret
display_string endp

; flags used in the bios_printf routine
PRINTF_IN_FORMAT    equ  1
PRINTF_IS_LONG      equ  2
PRINTF_IS_ZERO      equ  4
PRINTF_IS_SPACE     equ  8
PRINTF_IS_NEGATIVE  equ 16

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; display a formatted string to the screen using the VGA BIOS (or our video 'driver')
; On entry:
;  ds:si -> asciiz formatted string to display
;  stack holds items to 'insert' (last pushed, first used)
;  caller restores stack (cdecl)
; On return:
;  nothing
;  destroys nothing
;
; we support: i,d,u,x,X,c,s
;      flags: l = use 32-bit arg
;             0 = zero pad (left side)
;         space = space pad (left side)
;          1->9 = nibbles to print
bios_printf proc near uses all

           ; get the byte pointer to the first parameter
           ;  it is just after the 'ret' value and before the 'all' above
           mov  bp,sp
           add  bp,((8 * 2) + 2)  ; size of all registers pushed with 'all', plus the 'ret'
           ; bp -> first used parameter (if any)

           ; reset our flags
bios_printf_start:
           xor  dx,dx            ; PRINTF_* flags above
           xor  bx,bx            ; format width
bios_printf_start_1:
           lodsb
           or   al,al
           jz   short bios_printf_done
           
           cmp  al,'%'
           jne  short @f
           or   dx,PRINTF_IN_FORMAT
           jmp  short bios_printf_start_1

@@:        test dx,PRINTF_IN_FORMAT
           jnz  short @f
           call display_char
           jmp  short bios_printf_start_1

           ; if it is a 0, zero pad to left
@@:        cmp  al,'0'
           jne  short @f
           or   dx,PRINTF_IS_ZERO
           jmp  short bios_printf_start_1

           ; if it is a space, space pad to left
@@:        cmp  al,' '
           jne  short @f
           or   dx,PRINTF_IS_SPACE
           jmp  short bios_printf_start_1
           
           ; if it is a 1->9, it is part of a width
@@:        cmp  al,'1'
           jb   short @f
           cmp  al,'9'
           ja   short @f
           imul bx,bx,10
           sub  al,'0'
           xor  ah,ah
           add  bx,ax
           jmp  short bios_printf_start_1

           ; if the 'l' char is given, it is a 32-bit arg
@@:        cmp  al,'l'
           jne  short @f
           or   dx,PRINTF_IS_LONG
           jmp  short bios_printf_start_1

           ; if the char is 'x' or 'X', then print a hex value
@@:        mov  ah,al
           and  ah,0xDF
           cmp  ah,'X'
           jne  short @f
put_value: call print_value
           jmp  short bios_printf_start
           
           ; if the char is 'i', then print a dec value
@@:        cmp  al,'i'
           je   short put_value

           ; if the char is 'd', then print a dec value
           cmp  al,'d'
           je   short put_value

           ; if the char is 'u', then print a unsigned dec value
           cmp  al,'u'
           je   short put_value

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if the char is 'c', then print a char
           cmp  al,'c'
           jne  short @f
           call get_arg
           call display_char
           jmp  short bios_printf_start

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if the char is 's', then print a string
@@:        cmp  al,'s'
           jne  short @f
           call get_arg
           push si
           mov  si,ax
           call display_string
           pop  si
           jmp  bios_printf_start

@@:        ; we should not have gotten here, so we are going to return. done.

bios_printf_done:
           ret
bios_printf endp

; gets an arg from [bp], using 'is_long'
; returns in ax or eax
get_arg    proc near
           test dx,PRINTF_IS_LONG
           jnz  short @f
           
           mov  ax,[bp]
           add  bp,2
           ret

@@:        mov  eax,[bp]
           add  bp,4
           ret
get_arg    endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; display a formatted number
; On entry:
;  bp -> current parameter
;  al = 'X', 'x', 'd', 'i', 'u'
;  bx = format width
;  dx = flags
; On return:
;  nothing
;  destroys nothing
print_value proc near uses bx cx dx si di
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; save flags in di
           mov  di,dx
           ; save the token in dl
           mov  dl,al
           xor  eax,eax
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get the arg
           push dx
           mov  dx,di
           call get_arg
           pop  dx

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; is it the 'x' or 'X'
           mov  dh,dl
           and  dh,0xDF
           cmp  dh,'X'
           je   short do_hexadecimal

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; print a decimal ('u', 'i', 'd')
is_decimal:
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if no width is given, use the default for the given arg
           or   bx,bx
           jnz  short @f
           mov  bx,5
           test di,PRINTF_IS_LONG
           jz   short @f
           mov  bx,10
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if 'i' or 'd', then eax = signed
@@:        cmp  dl,'u'
           je   short is_unsigned
           ; if is_long, we need to sign extend ax to eax
           test di,PRINTF_IS_LONG
           jnz  short @f
           movsx eax,ax
@@:        ; if it is negative, set '-' flag and negate eax
           test  eax,(1<<31)
           jz   short is_unsigned
           or   di,PRINTF_IS_NEGATIVE
           neg  eax

           ; we now have an unsigned value in eax
is_unsigned:
           mov  cx,bx
           mov  ebx,10
           xor  si,si
@@:        xor  edx,edx
           div  ebx
           push dx
           inc  si
           or   eax,eax
           loopnz @b
           jmp  short need_padding

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; print a hexadecimal ('X', 'x')
do_hexadecimal:
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; if no width is given, use the default for the given arg
           or   bx,bx
           jnz  short @f
           mov  bx,4
           test di,PRINTF_IS_LONG
           jz   short @f
           mov  bx,8

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; upper case/lower case?
@@:        mov  dh,('A'-'9'-1)
           cmp  dl,'X'
           je   short @f
           cmp  dl,'x'
           jne  short is_decimal
           mov  dh,('a'-'9'-1)

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
@@:        mov  cx,bx
           xor  si,si
@@:        push ax
           inc  si
           shr  eax,4
           loopnz @b

need_padding:
           ; are there padding spaces needed
           jcxz short not_space

           ; did the user add the zero or space flag?
           test di,PRINTF_IS_ZERO
           jz   short not_zero
           ; negative?
           test di,PRINTF_IS_NEGATIVE
           jz   short @f
           mov  al,'-'
           call display_char
           and  di,(~PRINTF_IS_NEGATIVE)
           dec  cx
           jcxz short not_space
@@:        mov  al,'0'
@@:        call display_char
           loop @b
           ; don't allow the space to happen
           jmp  short not_space

not_zero:  test di,PRINTF_IS_SPACE
           jz   short not_space
           ; negative?
           test di,PRINTF_IS_NEGATIVE
           jz   short @f
           dec  cx
           jcxz short neg_char
@@:        mov  al,' '
@@:        call display_char
           loop @b
neg_char:  test di,PRINTF_IS_NEGATIVE
           jz   short not_space
           mov  al,'-'
           call display_char
           and  di,(~PRINTF_IS_NEGATIVE)

           ; si = count of pushes
not_space: test di,PRINTF_IS_NEGATIVE
           jz   short @f
           mov  al,'-'
           call display_char
@@:        mov  cx,si
do_hex:    pop  ax
           and  al,0x0F
           cmp  al,9
           jbe  short @f
           add  al,dh
@@:        add  al,'0'
           call display_char
           loop do_hex

           ret
print_value endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Bochs VBE Extensions (BGA)
;  (https://wiki.osdev.org/Bochs_VBE_Extensions)
;
.enum  VBE_DISPI_INDEX_ID, VBE_DISPI_INDEX_XRES, VBE_DISPI_INDEX_YRES, VBE_DISPI_INDEX_BPP, \
       VBE_DISPI_INDEX_ENABLE, VBE_DISPI_INDEX_BANK, VBE_DISPI_INDEX_VIRT_WIDTH, VBE_DISPI_INDEX_VIRT_HEIGHT, \
       VBE_DISPI_INDEX_X_OFFSET, VBE_DISPI_INDEX_Y_OFFSET

VBE_DISPI_DISABLED     equ 0x00
VBE_DISPI_ENABLED      equ 0x01
VBE_DISPI_LFB_ENABLED  equ 0x40

VBE_DISPI_INDEX_PORT   equ 0x1CE
VBE_DISPI_DATA_PORT    equ 0x1CF

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; our graphics video stuff starts here

CONIO_CHAR_COLOR  equ  ((204 << 16) | (203 << 8) | 200)   ; rgb
CONIO_CHAR_BACK   equ  ((  0 << 16) | (  0 << 8) |   0)   ; rgb

VID_FONT_WIDTH   equ   8
VID_FONT_HEIGHT  equ  14

VBE_DEFAULT_WIDTH   equ  ((1024 + 7) & ~0x7)  ; in QEMU, must be a multiple of 8
VBE_DEFAULT_HEIGHT  equ  768
VBE_DEFAULT_BPP     equ  32

banner_res  dw  VBE_DEFAULT_WIDTH, VBE_DEFAULT_HEIGHT, 32
            dw  VBE_DEFAULT_WIDTH, VBE_DEFAULT_HEIGHT, 24
            dw  VBE_DEFAULT_WIDTH, VBE_DEFAULT_HEIGHT, 16
            dw  VBE_DEFAULT_WIDTH, VBE_DEFAULT_HEIGHT, 15
            dw  800, 600, 16
            dw  800, 600, 15
            dw  800, 600, 8
            dw  0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read a word from the BGA
; On entry:
;  bx = index register
; On return:
;  ax = value read
; destroys none
bga_read_word proc near uses dx
           mov  dx,VBE_DISPI_INDEX_PORT
           mov  ax,bx
           out  dx,ax
           mov  dx,VBE_DISPI_DATA_PORT
           in   ax,dx
           ret
bga_read_word endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write a word to the BGA
; On entry:
;  ax = value to write
;  bx = index register
; On return:
;  nothing
; destroys none
bga_write_word proc near uses dx
           push ax
           mov  dx,VBE_DISPI_INDEX_PORT
           mov  ax,bx
           out  dx,ax
           pop  ax
           mov  dx,VBE_DISPI_DATA_PORT
           out  dx,ax
           ret
bga_write_word endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; create and start our banner screen
; On entry:
;  ds = 0xE000
; On return:
;  nothing
; destroys all general
put_banner proc near uses ds es
           call bios_get_ebda
           mov  ds,ax

           mov  byte [EBDA_DATA->video_use_graphic],0
           mov  byte [EBDA_DATA->video_use_bga],0

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; check to see the the BGA is available
           mov  bx,VBE_DISPI_INDEX_ID
           call bga_read_word
           cmp  ax,0xB0C2
           jb   short put_banner_no_bga
           cmp  ax,0xB0C5
           ja   short put_banner_no_bga

           ; find the BGA PCI device
           mov  ax,0xB102        ; find device
           mov  dx,0x1234        ; vendor id
           mov  cx,0x1111        ; device id
           xor  si,si            ; first one
           int  1Ah
           jc   short put_banner_no_bga

           ; get the BAR 0 address
           mov  dx,bx            ; dx = bus/devfunc
           mov  bx,0x10          ; BAR0
           call pci_config_read_dword
           and  eax,0xFFFFFFF0
           mov  [EBDA_DATA->video_ram],eax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; BGA is available, so use it

           ; disable the BGA
           mov  ax,VBE_DISPI_DISABLED
           mov  bx,VBE_DISPI_INDEX_ENABLE
           call bga_write_word

           ; set width to VBE_DEFAULT_WIDTH
           mov  ax,VBE_DEFAULT_WIDTH
           mov  bx,VBE_DISPI_INDEX_XRES
           call bga_write_word

           ; set height to VBE_DEFAULT_HEIGHT
           mov  ax,VBE_DEFAULT_HEIGHT
           mov  bx,VBE_DISPI_INDEX_YRES
           call bga_write_word

           ; set bpp to VBE_DEFAULT_BPP
           mov  ax,VBE_DEFAULT_BPP
           mov  bx,VBE_DISPI_INDEX_BPP
           call bga_write_word

           ; enable the BGA
           mov  ax,(VBE_DISPI_ENABLED | VBE_DISPI_LFB_ENABLED)
           mov  bx,VBE_DISPI_INDEX_ENABLE
           call bga_write_word

           mov  word [EBDA_DATA->video_width],VBE_DEFAULT_WIDTH
           mov  word [EBDA_DATA->video_height],VBE_DEFAULT_HEIGHT
           mov  byte [EBDA_DATA->video_bpp],VBE_DEFAULT_BPP
           mov  byte [EBDA_DATA->video_model],4
           mov  word [EBDA_DATA->video_bpscanline],(VBE_DEFAULT_WIDTH * ((VBE_DEFAULT_BPP + 1) / 8)) ; +1 to catch 15
           mov  byte [EBDA_DATA->video_use_graphic],1
           mov  byte [EBDA_DATA->video_use_bga],1
           jmp  put_banner_have_bga

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we first need to see if we have a VBE 2.0+ video 
           ; adapter installed.
put_banner_no_bga:
           mov  ax,(EBDA_SEG - 0x20) ; we need 0x200 bytes
           mov  es,ax
           xor  di,di
           mov  dword es:[di],'2EBV'
           mov  ax,0x4F00
           int  10h
           
           cmp  ax,0x004F
           jne  banner_bad_vesa
           cmp  dword es:[di],'ASEV'
           jne  banner_bad_vesa
           cmp  word es:[di+4],0x0200
           jb   banner_bad_vesa

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; VBE2 is supported, so get the information from the
           ;  screen mode we desire
           mov  bx,offset banner_res
           mov  si,es:[di+0x0E+0]
           mov  ax,es:[di+0x0E+2]
           mov  es,ax
           ; loop through all modes trying to
           ;  match a mode we specify
banner_res_loop:
           push si
           mov  cx,64 ; don't do more than 64
@@:        mov  ax,es:[si]
           push word cs:[bx+0]  ; width
           push word cs:[bx+2]  ; height
           push word cs:[bx+4]  ; bpp
           call vbe2_check_mode
           add  sp,6
           or   ax,ax        ; if ax = 0, mode not accepted
           jnz  short @f
           add  si,2
           cmp  word es:[si],0xFFFF
           loopne @b
           pop  si
           add  bx,6
           cmp  word cs:[bx+0],0x0000
           jne  short banner_res_loop
           ; we didn't find a mode we liked
           jmp  banner_bad_vesa

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we found a mode we like (mode in ax)
           ; store the information in the EBDA
@@:        pop  si
           
           ; before we destroy es, get the version so we
           ;  can get the correct scanline size
           mov  cx,es:[di+4]
           mov  dx,ax            ; save mode in dx

           ; now point to the mode information
           mov  es,bx            ; bx = seg of found mode info
           mov  eax,es:[0x0028]
           mov  [EBDA_DATA->video_ram],eax
           mov  ax,es:[0x0012]
           mov  [EBDA_DATA->video_width],ax
           mov  ax,es:[0x0014]
           mov  [EBDA_DATA->video_height],ax
           mov  al,es:[0x0019]
           mov  [EBDA_DATA->video_bpp],al
           mov  al,es:[0x001B]
           mov  [EBDA_DATA->video_model],al
           
           ; if the VESA mode is 3.00+, we get the
           ;  scan line width from [0x0032], else from [0x0010]
           mov  ax,es:[0x0010]
           cmp  cx,0x0300
           jb   short @f
           mov  ax,es:[0x0032]
@@:        mov  [EBDA_DATA->video_bpscanline],ax
           
           ; color bitmap
           mov  al,es:[0x001F]
           mov  [EBDA_DATA->video_red_mask_sz],al
           mov  al,es:[0x0020]
           mov  [EBDA_DATA->video_red_pos],al
           mov  al,es:[0x0021]
           mov  [EBDA_DATA->video_grn_mask_sz],al
           mov  al,es:[0x0022]
           mov  [EBDA_DATA->video_grn_pos],al
           mov  al,es:[0x0023]
           mov  [EBDA_DATA->video_blu_mask_sz],al
           mov  al,es:[0x0024]
           mov  [EBDA_DATA->video_blu_pos],al
           mov  byte [EBDA_DATA->video_use_graphic],1

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; calculate our 'text' screen size
put_banner_have_bga:
           push dx
           xor  dx,dx
           mov  ax,[EBDA_DATA->video_width]
           mov  bx,VID_FONT_WIDTH
           div  bx
           mov  [EBDA_DATA->vid_char_scrn_width],ax
           xor  dx,dx
           mov  ax,[EBDA_DATA->video_height]
           mov  bx,VID_FONT_HEIGHT
           div  bx
           mov  [EBDA_DATA->vid_char_scrn_height],ax
           mov  word [EBDA_DATA->vid_char_cur_x],0
           mov  word [EBDA_DATA->vid_char_cur_y],0
           pop  dx

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set the function to call to display a pixel
           call display_pixel_function
           or   ax,ax
           jz   short banner_bad_vesa

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now switch to that mode
           cmp  byte [EBDA_DATA->video_use_bga],0
           jne  short @f

           ; use the VGA BIOS to switch to the mode
           mov  ax,0x4F02
           mov  bx,dx
           int  10h
           cmp  ax,0x004F
           jne  short banner_bad_vesa

           ; display the bochs icon
@@:        call banner_icon
           
           ; display the text banner
           mov  ax,BIOS_BASE2
           mov  ds,ax
           mov  si,offset banner_str
           call bios_printf

           ret
           
banner_bad_vesa:
           mov  ax,BIOS_BASE2
           mov  ds,ax
           mov  si,offset banner_str
           call bios_printf
           
           mov  si,offset banner_no_vesa_str
           call display_string

           ret
put_banner endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; retrieve the mode information for a given screen mode and check
;  to see if it matches our requested resolution
; On entry:
;  ax = mode
;  [bp+04 + 10] = bpp
;  [bp+08 + 10] = height
;  [bp+12 + 10] = width
; On return:
;  ax = mode if accepted, 0 if not
;  bx = segment where accepted mode info is stored
;   (bx is preserved *unless* mode is accepted)
;  destroys none
vbe2_check_mode proc near uses cx edx di es ; 10 bytes
           push bp
           mov  bp,sp
           
           mov  cx,ax            ; cx = mode
           
           mov  ax,(EBDA_SEG - 0x20 - 0x10) ; we need 0x100 bytes (below the video info we already got)
           mov  es,ax
           xor  di,di

           mov  ax,0x4F01
           int  10h
           cmp  ax,0x004F
           jne  short bad_vesa_info
           
           ; check to see if it matches our requests
           mov  dx,es:[di+0]
           ; must be supported by both the card and the screen
           ; must be a graphics mode
           ; must have a linear mode
           and  dx,((1<<7) | (1<<4) | (1<<0))
           cmp  dx,((1<<7) | (1<<4) | (1<<0))
           jne  short bad_vesa_info
           ; linear address must be > 0
           cmp  dword es:[0x0028],0
           je   short bad_vesa_info
           ; memory model must be 4 (packed pixel) or 6 (direct color)
           mov  dl,es:[0x001B]
           cmp  dl,0x04
           je   short @f
           cmp  dl,0x06
           jne  short bad_vesa_info
@@:        ; we have a valid screen mode, now check to
           ; see if it matches the requested resolution
           movzx dx,byte es:[di+0x0019]
           cmp  dx,[bp+4+10]     ; bpp
           jne  short bad_vesa_info
           mov  dx,es:[di+0x0014]
           cmp  dx,[bp+6+10]     ; height
           jne  short bad_vesa_info
           mov  dx,es:[di+0x0012]
           cmp  dx,[bp+8+10]     ; width
           jne  short bad_vesa_info
           
           ; we found a mode that matches our request
           ; return the mode and bx = segment of information
           mov  ax,cx
           mov  bx,es

           mov  sp,bp
           pop  bp
           ret

bad_vesa_info:
           xor  ax,ax            ; mode not accepted
           mov  sp,bp
           pop  bp
           ret
vbe2_check_mode endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; restore the screen mode to the default bios mode
; on entry:
;  nothing
; on return:
;  nothing
; destroys nothing
display_restore_default proc near uses ax ds
           mov  ax,EBDA_SEG
           mov  ds,ax

           ; is the BGA active?
           cmp  byte [EBDA_DATA->video_use_bga],0
           je   short @f
           
           ; if so, disable it
           mov  ax,VBE_DISPI_DISABLED
           mov  bx,VBE_DISPI_INDEX_ENABLE
           call bga_write_word
           mov  byte [EBDA_DATA->video_use_bga],0

@@:        mov  byte [EBDA_DATA->video_use_graphic],0
           mov  ax,0x0003
           int  10h
           ret
display_restore_default endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;  If the Memory Model field in the Video Information block is returned as 4,
;   the Mask and Size fields in the Info Block may be and usually are zero.
;   Therefore, the pixels are assumed as follows:
;      8 bits per pixel: rrrgggbb
;     15 bits per pixel: xrrrrrgggggbbbbb
;     16 bits per pixel: rrrrrggggggbbbbb
;     24 bits per pixel: rrrrrrrrggggggggbbbbbbbb
;     32 bits per pixel: xxxxxxxxrrrrrrrrggggggggbbbbbbbb
;  If the Memory Model field in the Video Information block is returned as 6,
;   the Mask and Size fields in the Info Block should be valid.

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; determine the 'display pixel' function and set it in the EBDA
; On entry:
;  ds -> EBDA
; On return:
;  ax = 0 = didn't find a suitable pixel format
; destroys none
display_pixel_function proc near uses bx cx
           mov  ah,[EBDA_DATA->video_bpp]
           mov  al,[EBDA_DATA->video_model]
           cmp  al,0x04
           jne  short function_model_06

           mov  bx,offset display_draw_pixel8
           cmp  ah,8
           je   function_model_done
           mov  bx,offset display_draw_pixel15
           cmp  ah,15
           je   function_model_done
           mov  bx,offset display_draw_pixel16
           cmp  ah,16
           je   function_model_done
           mov  bx,offset display_draw_pixel24
           cmp  ah,24
           je   function_model_done
           mov  bx,offset display_draw_pixel32
           cmp  ah,32
           je   function_model_done
function_model_error:
           xor  ax,ax
           ret

function_model_06:
           cmp  ah,8
           jne  short @f
           mov  cx,[EBDA_DATA->video_red_mask_sz]
           cmp  cx,0x0503
           jne  short function_model_error
           mov  cx,[EBDA_DATA->video_grn_mask_sz]
           cmp  cx,0x0203
           jne  short function_model_error
           mov  cx,[EBDA_DATA->video_blu_mask_sz]
           cmp  cx,0x0002
           jne  short function_model_error
           mov  bx,offset display_draw_pixel8
           jmp  function_model_done

@@:        cmp  ah,15
           jne  short @f
           mov  cx,[EBDA_DATA->video_red_mask_sz]
           cmp  cx,0x0A05
           jne  short function_model_error
           mov  cx,[EBDA_DATA->video_grn_mask_sz]
           cmp  cx,0x0505
           jne  short function_model_error
           mov  cx,[EBDA_DATA->video_blu_mask_sz]
           cmp  cx,0x0005
           jne  short function_model_error
           mov  bx,offset display_draw_pixel15
           jmp  function_model_done

@@:        cmp  ah,16
           jne  short @f
           mov  cx,[EBDA_DATA->video_red_mask_sz]
           cmp  cx,0x0B05
           jne  short function_model_error
           mov  cx,[EBDA_DATA->video_grn_mask_sz]
           cmp  cx,0x0506
           jne  short function_model_error
           mov  cx,[EBDA_DATA->video_blu_mask_sz]
           cmp  cx,0x0005
           jne  short function_model_error
           mov  bx,offset display_draw_pixel16
           jmp  short function_model_done

@@:        cmp  ah,24
           jne  short @f
           mov  cx,[EBDA_DATA->video_red_mask_sz]
           cmp  cx,0x1008
           jne  function_model_error
           mov  cx,[EBDA_DATA->video_grn_mask_sz]
           cmp  cx,0x0808
           jne  function_model_error
           mov  cx,[EBDA_DATA->video_blu_mask_sz]
           cmp  cx,0x0008
           jne  function_model_error
           mov  bx,offset display_draw_pixel24
           jmp  short function_model_done

@@:        cmp  ah,32
           jne  short @f
           mov  cx,[EBDA_DATA->video_red_mask_sz]
           cmp  cx,0x1008
           jne  function_model_error
           mov  cx,[EBDA_DATA->video_grn_mask_sz]
           cmp  cx,0x0808
           jne  function_model_error
           mov  cx,[EBDA_DATA->video_blu_mask_sz]
           cmp  cx,0x0008
           jne  function_model_error
           mov  bx,offset display_draw_pixel32
           jmp  short function_model_done
@@:        jmp  function_model_error

function_model_done:
           mov  [EBDA_DATA->vid_display_pixel],bx
           mov  word [EBDA_DATA->vid_display_pixel_seg],BIOS_BASE
           mov  ax,bx
           ret
display_pixel_function endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw an 8-bit pixel
; rrrgggbb
; on entry:
;  eax = 32-bit pixel to draw
;  edi = position to draw
; on return
;  edi = edi + 1
; * must be a far call *
display_draw_pixel8 proc far uses eax ebx ecx
           ; convert from 00000000rrrrrrrrggggggggbbbbbbbb
           ;           to                         rrrgggbb
           mov  ebx,eax
           mov  ecx,eax
           and  eax,0x00E00000  ; red
           shr  eax,16
           and  bx,0x0000E000   ; green
           shr  bx,11
           and  cx,0x000000C0   ; blue
           shr  cx,6
           or   ax,bx
           or   ax,cx
           mov  fs:[edi],al
           add  edi,1
           retf
display_draw_pixel8 endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw an 15-bit pixel
; xrrrrrgggggbbbbb
; on entry:
;  eax = 32-bit pixel to draw
;  edi = position to draw
; on return
;  edi = edi + 2
; * must be a far call *
display_draw_pixel15 proc far uses eax ebx ecx
           ; convert from 00000000rrrrrrrrggggggggbbbbbbbb
           ;           to                 xrrrrrgggggbbbbb
           mov  ebx,eax
           mov  ecx,eax
           and  eax,0x00F80000  ; red
           shr  eax,9
           and  bx,0x0000F800   ; green
           shr  bx,6
           and  cx,0x000000F8   ; blue
           shr  cx,3
           or   ax,bx
           or   ax,cx
           mov  fs:[edi],ax
           add  edi,2
           retf
display_draw_pixel15 endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw an 16-bit pixel
; rrrrrggggggbbbbb
; on entry:
;  eax = 32-bit pixel to draw
;  edi = position to draw
; on return
;  edi = edi + 2
; * must be a far call *
display_draw_pixel16 proc far uses eax ebx ecx
           ; convert from 00000000rrrrrrrrggggggggbbbbbbbb
           ;           to                 rrrrrggggggbbbbb
           mov  ebx,eax
           mov  ecx,eax
           and  eax,0x00F80000  ; red
           shr  eax,8
           and  bx,0x0000FC00   ; green
           shr  bx,5
           and  cx,0x000000F8   ; blue
           shr  cx,3
           or   ax,bx
           or   ax,cx
           mov  fs:[edi],ax
           add  edi,2
           retf
display_draw_pixel16 endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw an 24-bit pixel
; rrrrrrrrggggggggbbbbbbbb
; on entry:
;  eax = 32-bit pixel to draw
;  edi = position to draw
; on return
;  edi = edi + 3
; * must be a far call *
display_draw_pixel24 proc far uses eax
           mov  fs:[edi],ax
           shr  eax,16
           mov  fs:[edi+2],al
           add  edi,3
           retf
display_draw_pixel24 endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw an 32-bit pixel
; xxxxxxxxrrrrrrrrggggggggbbbbbbbb
; on entry:
;  eax = 32-bit pixel to draw
;  edi = position to draw
; on return
;  edi = edi + 4
; * must be a far call *
display_draw_pixel32 proc far
           mov  fs:[edi],eax
           add  edi,4
           retf
display_draw_pixel32 endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; set information about the new run/string
; on entry:
;  es -> EBDA
;  ds:si -> icon current rle position
; on return:
;  ds:si - > next position
; destroys none
banner_icon_start proc near uses ax
           mov  byte es:[EBDA_DATA->video_icon_type],0
           lodsb
           cmp  al,128
           jna  short @f
           sub  al,128
           mov  byte es:[EBDA_DATA->video_icon_type],1
@@:        mov  es:[EBDA_DATA->video_icon_cnt],al
           ret
banner_icon_start endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get next pixel in run/string
; on entry:
;  es -> EBDA
;  ds:si -> icon current rle position
; on return:
;  eax = 32-bit pixel
;  ds:si - > next position
; destroys none
banner_icon_get_next proc near uses bx

           cmp  byte es:[EBDA_DATA->video_icon_cnt],0
           ja   short @f
           call banner_icon_start

@@:        cmp  byte es:[EBDA_DATA->video_icon_type],0
           jne  short banner_get_next_str
           
           ; is a run [si] = index
           xor  bh,bh
           mov  bl,[si]
           shl  bx,2
           add  bx,es:[EBDA_DATA->video_icon_palette]
           mov  eax,[bx]
           dec  byte es:[EBDA_DATA->video_icon_cnt]
           jnz  short @f
           inc  si
@@:        ret

           ; is a string [si] = index
banner_get_next_str:
           xor  bh,bh
           mov  bl,[si]
           inc  si
           shl  bx,2
           add  bx,es:[EBDA_DATA->video_icon_palette]
           mov  eax,[bx]
           dec  byte es:[EBDA_DATA->video_icon_cnt]
           ret
banner_icon_get_next endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; display the banner icon to the upper-right corner
; On entry:
;  
; On return:
;  nothing
; destroys none
banner_icon proc near uses alld ds es
           ; es -> ebda
           call bios_get_ebda
           mov  es,ax
           
           ; ds:si -> icon bitmap
           mov  ax,BIOS_BASE2
           mov  ds,ax
           mov  si,offset our_main_icon

           ; get the information about the icon
           movzx edx,word [si+0]     ; width
           movzx ecx,word [si+2]     ; height
           add  si,4
           lodsw
           mov  es:[EBDA_DATA->video_icon_palette],si
           mov  byte es:[EBDA_DATA->video_icon_cnt],0
           shl  ax,2
           add  si,ax
           
           mov  edi,es:[EBDA_DATA->video_ram]

           ; make 15 = 16 (8 = 8, 15 = 16, 16 = 16, 24 = 24, 32 = 32)
           movzx ebx,byte es:[EBDA_DATA->video_bpp]
           inc  bl
           and  bl,(~7)
           shr  bl,3     ; bytes per pixel

           movzx eax,word es:[EBDA_DATA->video_width]
           sub  eax,edx
           push edx
           mul  ebx      ; bytes per pixel
           add  edi,eax

           ; move to the bottom line of the icon so we can move up
           ; (bmp's are in reverse order)
           movzx ebx,word es:[EBDA_DATA->video_bpscanline]
           mov  eax,ecx
           mul  ebx
           add  edi,eax

           pop  edx
           
icon_loop: push ecx
           push edi
           mov  ecx,edx
@@:        call banner_icon_get_next
           call far es:[EBDA_DATA->vid_display_pixel]
           .adsize
           loop @b
           pop  edi
           pop  ecx
           sub  edi,ebx
           loop icon_loop
           
           ret
banner_icon endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; display a char to the screen
; On entry:
;  al = char
; On return:
;  nothing
; destroys none
vid_display_char proc near uses alld ds es
           
           push ax

           ; ds -> ebda
           call bios_get_ebda
           mov  ds,ax
           mov  edi,[EBDA_DATA->video_ram]

           ; get bytes per pixel
           movzx ebx,byte [EBDA_DATA->video_bpp]
           inc  bx
          ;and  bx,(~7)
           shr  bx,3     ; bytes per pixel
           
           ; calculate the vertical position
           movzx eax,word [EBDA_DATA->vid_char_cur_y]
           mov  ecx,VID_FONT_HEIGHT
           mul  ecx
           movzx ecx,word [EBDA_DATA->video_bpscanline]
           mul  ecx
           add  edi,eax
           
           ; calculate the horizontal position
           movzx eax,word [EBDA_DATA->vid_char_cur_x]
           mov  ecx,VID_FONT_WIDTH
           mul  ecx
           mul  ebx              ; bytes per pixel
           add  edi,eax

           pop  ax

           ; is it a special char?
           cmp  al,13
           jne  short @f
           mov  word [EBDA_DATA->vid_char_cur_x],0x0000
           jmp  vid_display_char_done
@@:        cmp  al,10
           jne  short @f
           inc  word [EBDA_DATA->vid_char_cur_y]
           jmp  short vid_display_char_check
@@:        cmp  al,8
           jne  short @f
           cmp  word [EBDA_DATA->vid_char_cur_x],0
           je   short vid_display_char_done
           dec  word [EBDA_DATA->vid_char_cur_x]
           jmp  short vid_display_char_done

@@:        ; calculate the char position
           ; (our chars are 8-bits in width)
           ; es:si -> font
           xor  ah,ah
           mov  cx,BIOS_BASE2
           mov  es,cx
           mov  si,offset our_font
           mov  cx,VID_FONT_HEIGHT
           mul  cx
           add  si,ax

           movzx edx,word [EBDA_DATA->video_bpscanline]
           mov  cx,VID_FONT_HEIGHT
char_main: push cx
           push edi
           mov  al,es:[si]
           inc  si
           mov  cx,8
char_line: shl  al,1
           push eax
           mov  eax,CONIO_CHAR_BACK
           jnc  short @f
           mov  eax,CONIO_CHAR_COLOR
@@:        call far [EBDA_DATA->vid_display_pixel]
           pop  eax
           loop char_line
           pop  edi
           pop  cx
           add  edi,edx
           loop char_main

           ; move to next char position
           inc  word [EBDA_DATA->vid_char_cur_x]

           ; check to make sure we aren't 'out of bounds'
vid_display_char_check:
           mov  ax,[EBDA_DATA->vid_char_cur_x]
           cmp  ax,[EBDA_DATA->vid_char_scrn_width]
           jb   short @f
           mov  word [EBDA_DATA->vid_char_cur_x],0x0000
           inc  word [EBDA_DATA->vid_char_cur_y]
@@:        mov  ax,[EBDA_DATA->vid_char_cur_y]
           cmp  ax,[EBDA_DATA->vid_char_scrn_height]
           jb   short vid_display_char_done

           ; we need to scroll the screen
           call vid_display_scroll_screen
           dec  word [EBDA_DATA->vid_char_cur_y]
           
vid_display_char_done:
           ret
vid_display_char endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; scrolls the video screen up one char height
; (calls the display icon routine)
; On entry:
;  ds -> EBDA
; On return:
;  nothing
; destroys all general
vid_display_scroll_screen proc near
           movzx eax,word [EBDA_DATA->video_bpscanline]
           mov  ecx,VID_FONT_HEIGHT
           mul  ecx
           push eax              ; save the count of bytes in one char line height

           mov  edi,[EBDA_DATA->video_ram]
           mov  esi,edi
           add  esi,eax

           movzx eax,word [EBDA_DATA->video_bpscanline]
           movzx ecx,word [EBDA_DATA->video_height]
           sub  ecx,VID_FONT_HEIGHT
           mul  ecx

           mov  ecx,eax
@@:        mov  al,fs:[esi]
           inc  esi
           mov  fs:[edi],al
           inc  edi
           .adsize               ; use ecx in the loop
           loop @b
           
           pop  ecx              ; restore count of bytes in one char line height
           xor  al,al
@@:        mov  fs:[edi],al
           inc  edi
           .adsize               ; use ecx in the loop
           loop @b

           call banner_icon

           ret
vid_display_scroll_screen endp

.end
