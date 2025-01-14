comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: setup.asm                                                          *
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
*   setup include file                                                     *
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
*  - To save space, if the object doesn't use the 'string' or 'resv'       *
*     members, it doesn't need to declare/allocate space for it since      *
*     each object is in a linked-list instead of relying on the size       *
*     of the object to find the next object.                               *
*                                                                          *
*  - All EDIT_BOXes with associated UP/DOWN objects should have these      *
*     UP/DOWN objects follow the EDIT_BOX object in UP then DOWN order.    *
*    This way the code can assume the UP will be the next object and the   *
*     DOWN will be the object after the UP.                                *
*                                                                          *
***************************************************************************|

;                          red          green     blue
GUI_BACKGROUND    equ  ((152 << 16) | (173 << 8) | 214)
GUI_BUTTON_HI     equ  ((172 << 16) | (193 << 8) | 234)
GUI_BUTTON_LO     equ  ((132 << 16) | (153 << 8) | 194)
GUI_BUTTON_DARK   equ  ((102 << 16) | (123 << 8) | 164)
GUI_BUTTON_LIGHT  equ  ((182 << 16) | (203 << 8) | 244)
GUI_COLOR_FOCUS   equ  (( 75 << 16) | ( 75 << 8) |  75)
GUI_TEXT_COLOR    equ  (( 20 << 16) | ( 20 << 8) |  20)

GUI_BOX_BUTTON_UP    equ  (0 << 0)
GUI_BOX_BUTTON_DN    equ  (1 << 0)
GUI_BOX_BUTTON_FILL  equ  (1 << 1)

; object->flags
GUI_EDITBOX_VALUE    equ  (1 << 0)
GUI_INCBOX_ISDOWN    equ  (1 << 1)
GUI_OBJECT_VISIBLE   equ  (1 << 6)
GUI_OBJECT_TABSTOP   equ  (1 << 7)

.enum  GUI_TYPE_NONE, GUI_TYPE_STATIC, GUI_TYPE_CHECKBOX, GUI_TYPE_EDITBOX, \
       GUI_TYPE_INCBOX, GUI_TYPE_BUTTON, GUI_TYPE_FRAME

GUI_RECT struct
  x_pos      word    ; x position from left of parent
  y_pos      word    ; y position from top of parent
  width      word    ; width of object
  height     word    ; height of object
GUI_RECT ends
temp_rect  ST  GUI_RECT

GUI_DATE_TIME struct
  year       word
  month      byte
  day        byte
  hour       byte
  min        byte
  sec        byte
GUI_DATE_TIME ends
gui_date_time  ST  GUI_DATE_TIME

GUI_OBJ_FLAG_NONE    equ  0
GUI_OBJ_FLAG_DO_NEXT equ  (1 << 0)

; 64 bytes
GUI_OBJECT struct
  parent     word    ; offset to parent
  prev       word    ; offset to previous object
  next       word    ; offset to next object
  event      word    ; pointer to a function when this object is clicked
  draw       word    ; offset to the draw routine for this object
  type       byte    ; type of object
  flags      byte    ;
  
  ; the next four must remain this size and in this order (match GUI_RECT above)
  x_pos      word    ; x position from left of parent
  y_pos      word    ; y position from top of parent
  width      word    ; width of object
  height     word    ; height of object

  value     dword    ; a un/signed value used by this object
  value1    dword    ; a un/signed value used by this object
  string    dup 32   ; a string of chars used by this object
  resv      dup 6    ;
GUI_OBJECT ends

gui_root_object:
  dw  0                    ; no parent
  dw  0                    ; no prev
  dw  offset gui_num_lock  ; first object (must not be NULL)
  dw  0                    ; no event
  dw  0                    ; no draw routing
  db  GUI_TYPE_NONE        ; the root has no type
  db  0                    ;
  dw  0,0                  ; top left = 0,0
  dw  0,0                  ; width, height
  dd  0                    ; no value
  dd  0                    ; no value1

gui_num_lock:
  dw  offset gui_root_object ; parent = root
  dw  0                    ; no prev (don't move to the root)
  dw  offset gui_ehci_legacy ; next item goes here
  dw  offset gui_checkbox_event
  dw  offset gui_draw_checkbox
  db  GUI_TYPE_CHECKBOX    ; this is a check box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)  ; flags
  dw  25,25                ; top left (x,y)
  dw  200,20               ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  'Num-Lock on at bootup',0

gui_ehci_legacy:
  dw  offset gui_root_object ; parent = root
  dw  offset gui_num_lock    ; previous
  dw  offset gui_ahci_legacy ; next item goes here
  dw  offset gui_checkbox_event
  dw  offset gui_draw_checkbox
  db  GUI_TYPE_CHECKBOX    ; this is a check box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  25,50                ; top left (x,y)
  dw  200,20               ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  'Legacy EHCI?',0

gui_ahci_legacy:
  dw  offset gui_root_object ; parent = root
  dw  offset gui_ehci_legacy ; previous
  dw  offset gui_floppy_sig  ; next item goes here
  dw  offset gui_checkbox_event
  dw  offset gui_draw_checkbox
  db  GUI_TYPE_CHECKBOX    ; this is a check box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  25,75                ; top left (x,y)
  dw  200,20               ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  'Legacy AHCI?',0

gui_floppy_sig:
  dw  offset gui_root_object ; parent = root
  dw  offset gui_ahci_legacy ; previous
  dw  offset gui_fast_boot   ; next item goes here
  dw  offset gui_checkbox_event
  dw  offset gui_draw_checkbox
  db  GUI_TYPE_CHECKBOX    ; this is a check box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  25,100               ; top left (x,y)
  dw  200,20               ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  'Floppy Sig Check',0

gui_fast_boot:
  dw  offset gui_root_object ; parent = root
  dw  offset gui_floppy_sig  ; previous
  dw  offset gui_cmos_date_str  ; next item goes here
  dw  offset gui_checkbox_event
  dw  offset gui_draw_checkbox
  db  GUI_TYPE_CHECKBOX    ; this is a check box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  25,125               ; top left (x,y)
  dw  200,20               ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  'Fast Boot',0

gui_cmos_date_str:
  dw  offset gui_root_object ; parent = root
  dw  offset gui_fast_boot   ; previous
  dw  offset gui_cmos_month  ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_static
  db  GUI_TYPE_STATIC      ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; 
  dw  15,154               ; top left (x,y)
  dw  144,20               ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  'Date: (MM:DD:YYYY)',0

gui_cmos_month:
  dw  offset gui_root_object   ; parent = root
  dw  offset gui_cmos_date_str ; previous
  dw  offset gui_cmos_month_up ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  (GUI_OBJECT_VISIBLE | GUI_EDITBOX_VALUE) ; use the 'value' field to fill the box
  dw  170,150              ; top left (x,y)
  dw  30,20                ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  dup 32,0                 ; save room for the string to print

gui_cmos_month_up:
  dw  offset gui_cmos_month ; parent = month
  dw  offset gui_cmos_month ; previous
  dw  offset gui_cmos_month_down ; next item goes here
  dw  offset gui_button_up_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.month ; value
  dw  sizeof(byte)
  dd  12                   ; limit

gui_cmos_month_down:
  dw  offset gui_cmos_month    ; parent = month
  dw  offset gui_cmos_month_up ; previous
  dw  offset gui_cmos_days     ; next item goes here
  dw  offset gui_button_dn_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.month ; value
  dw  sizeof(byte)
  dd  1                    ; limit

gui_cmos_days:
  dw  offset gui_root_object     ; parent = root
  dw  offset gui_cmos_month_down ; previous
  dw  offset gui_cmos_days_up    ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  (GUI_OBJECT_VISIBLE | GUI_EDITBOX_VALUE) ; use the 'value' field to fill the box
  dw  215,150              ; top left (x,y)
  dw  30,20                ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  dup 32,0                 ; save room for the string to print

gui_cmos_days_up:
  dw  offset gui_cmos_days ; parent = days
  dw  offset gui_cmos_days ; previous
  dw  offset gui_cmos_days_down ; next item goes here
  dw  offset gui_button_up_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.day ; value
  dw  sizeof(byte)
  dd  31                   ; limit (adjusted by 'gui_button_up_event' call)

gui_cmos_days_down:
  dw  offset gui_cmos_days    ; parent = mins
  dw  offset gui_cmos_days_up ; previous
  dw  offset gui_cmos_year    ; next item goes here
  dw  offset gui_button_dn_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.day ; value
  dw  sizeof(byte)
  dd  1                    ; limit

gui_cmos_year:
  dw  offset gui_root_object    ; parent = root
  dw  offset gui_cmos_days_down ; previous
  dw  offset gui_cmos_year_up   ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  (GUI_OBJECT_VISIBLE | GUI_EDITBOX_VALUE) ; use the 'value' field to fill the box
  dw  260,150              ; top left (x,y)
  dw  50,20                ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  dup 32,0                 ; save room for the string to print

gui_cmos_year_up:
  dw  offset gui_cmos_year ; parent = year
  dw  offset gui_cmos_year ; previous
  dw  offset gui_cmos_year_down ; next item goes here
  dw  offset gui_button_up_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.year ; value
  dw  sizeof(word)
  dd  9999                 ; limit

gui_cmos_year_down:
  dw  offset gui_cmos_year     ; parent = secs
  dw  offset gui_cmos_year_up  ; previous
  dw  offset gui_cmos_time_str ; next item goes here
  dw  offset gui_button_dn_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.year ; value
  dw  sizeof(word)
  dd  2000                 ; limit

gui_cmos_time_str:
  dw  offset gui_root_object    ; parent = root
  dw  offset gui_cmos_year_down ; previous
  dw  offset gui_cmos_hours     ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_static
  db  GUI_TYPE_STATIC      ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; flags
  dw  15,179               ; top left (x,y)
  dw  144,20               ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  '  Time: (HH:MM:SS)',0

gui_cmos_hours:
  dw  offset gui_root_object   ; parent = root
  dw  offset gui_cmos_time_str ; previous
  dw  offset gui_cmos_hours_up ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  (GUI_OBJECT_VISIBLE | GUI_EDITBOX_VALUE) ; use the 'value' field to fill the box
  dw  170,175              ; top left (x,y)
  dw  30,20                ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  dup 32,0                 ; save room for the string to print

gui_cmos_hours_up:
  dw  offset gui_cmos_hours ; parent = hours
  dw  offset gui_cmos_hours ; previous
  dw  offset gui_cmos_hours_down ; next item goes here
  dw  offset gui_button_up_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.hour ; value
  dw  sizeof(byte)
  dd  23                   ; limit

gui_cmos_hours_down:
  dw  offset gui_cmos_hours    ; parent = hours
  dw  offset gui_cmos_hours_up ; previous
  dw  offset gui_cmos_mins     ; next item goes here
  dw  offset gui_button_dn_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.hour ; value
  dw  sizeof(byte)
  dd  0                    ; limit

gui_cmos_mins:
  dw  offset gui_root_object     ; parent = root
  dw  offset gui_cmos_hours_down ; previous
  dw  offset gui_cmos_mins_up    ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  (GUI_OBJECT_VISIBLE | GUI_EDITBOX_VALUE) ; use the 'value' field to fill the box
  dw  215,175              ; top left (x,y)
  dw  30,20                ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  dup 32,0                 ; save room for the string to print

gui_cmos_mins_up:
  dw  offset gui_cmos_mins ; parent = mins
  dw  offset gui_cmos_mins ; previous
  dw  offset gui_cmos_mins_down ; next item goes here
  dw  offset gui_button_up_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.min ; value
  dw  sizeof(byte)
  dd  59                   ; limit

gui_cmos_mins_down:
  dw  offset gui_cmos_mins    ; parent = mins
  dw  offset gui_cmos_mins_up ; previous
  dw  offset gui_cmos_secs    ; next item goes here
  dw  offset gui_button_dn_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.min ; value
  dw  sizeof(byte)
  dd  0                    ; limit

gui_cmos_secs:
  dw  offset gui_root_object    ; parent = root
  dw  offset gui_cmos_mins_down ; previous
  dw  offset gui_cmos_secs_up   ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  (GUI_OBJECT_VISIBLE | GUI_EDITBOX_VALUE) ; use the 'value' field to fill the box
  dw  260,175              ; top left (x,y)
  dw  30,20                ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  dup 32,0                 ; save room for the string to print

gui_cmos_secs_up:
  dw  offset gui_cmos_secs ; parent = secs
  dw  offset gui_cmos_secs ; previous
  dw  offset gui_cmos_secs_down ; next item goes here
  dw  offset gui_button_up_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.sec ; value
  dw  sizeof(byte)
  dd  59                   ; limit

gui_cmos_secs_down:
  dw  offset gui_cmos_secs    ; parent = secs
  dw  offset gui_cmos_secs_up ; previous
  dw  offset gui_floppy0_type_str ; next item goes here
  dw  offset gui_button_dn_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dw  offset gui_date_time.sec ; value
  dw  sizeof(byte)
  dd  0                    ; limit

gui_floppy0_type_str:
  dw  offset gui_root_object    ; parent = root
  dw  offset gui_cmos_secs_down ; previous
  dw  offset gui_floppy0_type   ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_static
  db  GUI_TYPE_STATIC      ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; flags
  dw  54,204               ; top left (x,y)
  dw  105,20               ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  'Floppy0 type:',0

gui_floppy0_type:
  dw  offset gui_root_object      ; parent = root
  dw  offset gui_floppy0_type_str ; previous
  dw  offset gui_floppy0_type_up  ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; use the 'string' field to fill the box
  dw  170,200              ; top left (x,y)
  dw  100,20               ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  dup 32,0                 ; save room for the string to print

gui_floppy0_type_up:
  dw  offset gui_floppy0_type ; parent = floppy0 type
  dw  offset gui_floppy0_type ; previous
  dw  offset gui_floppy0_type_down ; next item goes here
  dw  offset gui_floppy_up_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_floppy0_type_down:
  dw  offset gui_floppy0_type     ; parent = floppy0 type
  dw  offset gui_floppy0_type_up  ; previous
  dw  offset gui_floppy1_type_str ; next item goes here
  dw  offset gui_floppy_dn_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_floppy1_type_str:
  dw  offset gui_root_object       ; parent = root
  dw  offset gui_floppy0_type_down ; previous
  dw  offset gui_floppy1_type      ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_static
  db  GUI_TYPE_STATIC      ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; flags
  dw  54,229               ; top left (x,y)
  dw  105,20               ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  'Floppy1 type:',0

gui_floppy1_type:
  dw  offset gui_root_object      ; parent = root
  dw  offset gui_floppy1_type_str ; previous
  dw  offset gui_floppy1_type_up  ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; use the 'string' field to fill the box
  dw  170,225              ; top left (x,y)
  dw  100,20               ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  dup 32,0                 ; save room for the string to print

gui_floppy1_type_up:
  dw  offset gui_floppy1_type ; parent = floppy1 type
  dw  offset gui_floppy1_type ; previous
  dw  offset gui_floppy1_type_down ; next item goes here
  dw  offset gui_floppy_up_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_floppy1_type_down:
  dw  offset gui_floppy1_type    ; parent = floppy1 type
  dw  offset gui_floppy1_type_up ; previous
  dw  offset gui_ipl_list_box    ; next item goes here
  dw  offset gui_floppy_dn_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_list_box:
  dw  offset gui_root_object       ; parent = root
  dw  offset gui_floppy1_type_down ; previous
  dw  offset gui_ipl_entry0        ; next item goes here
  dw  0                    ;
  dw  offset gui_draw_frame
  db  GUI_TYPE_FRAME       ; this is a frame box
  db  GUI_OBJECT_VISIBLE   ; flags
  dw  350,25               ; top left (x,y)
  dw  282,220              ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  'IPL entries',0

; IPL entries (up to IPL_TABLE_ENTRY_CNT currently we only have 8)
gui_ipl_entry0:
  dw  offset gui_root_object   ; parent = root
  dw  offset gui_ipl_list_box  ; previous
  dw  offset gui_ipl_entry0_up ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; use the 'string' field to fill the box
  dw  360,40               ; top left (x,y)
  dw  250,20               ; width, height
  dd  0                    ; index 0 in the ipl list (changes with up/down)
  dd  0                    ; index 0 in the list
  dup 32,0                 ; save room for the string to print

gui_ipl_entry0_up:
  dw  offset gui_ipl_entry0 ; parent = ipl_entry0
  dw  offset gui_ipl_entry0 ; previous
  dw  offset gui_ipl_entry0_down ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry0_down:
  dw  offset gui_ipl_entry0    ; parent = ipl_entry0
  dw  offset gui_ipl_entry0_up ; previous
  dw  offset gui_ipl_entry1    ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry1:
  dw  offset gui_root_object     ; parent = root
  dw  offset gui_ipl_entry0_down ; previous
  dw  offset gui_ipl_entry1_up   ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; use the 'string' field to fill the box
  dw  360,65               ; top left (x,y)
  dw  250,20               ; width, height
  dd  1                    ; index 1 in the ipl list (changes with up/down)
  dd  1                    ; index 1 in the list
  dup 32,0                 ; save room for the string to print

gui_ipl_entry1_up:
  dw  offset gui_ipl_entry1 ; parent = ipl_entry0
  dw  offset gui_ipl_entry1 ; previous
  dw  offset gui_ipl_entry1_down ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry1_down:
  dw  offset gui_ipl_entry1    ; parent = ipl_entry0
  dw  offset gui_ipl_entry1_up ; previous
  dw  offset gui_ipl_entry2    ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry2:
  dw  offset gui_root_object     ; parent = root
  dw  offset gui_ipl_entry1_down ; previous
  dw  offset gui_ipl_entry2_up   ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; use the 'string' field to fill the box
  dw  360,90               ; top left (x,y)
  dw  250,20               ; width, height
  dd  2                    ; index 2 in the ipl list (changes with up/down)
  dd  2                    ; index 2 in the list
  dup 32,0                 ; save room for the string to print

gui_ipl_entry2_up:
  dw  offset gui_ipl_entry2 ; parent = ipl_entry0
  dw  offset gui_ipl_entry2 ; previous
  dw  offset gui_ipl_entry2_down ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry2_down:
  dw  offset gui_ipl_entry2    ; parent = ipl_entry0
  dw  offset gui_ipl_entry2_up ; previous
  dw  offset gui_ipl_entry3    ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry3:
  dw  offset gui_root_object     ; parent = root
  dw  offset gui_ipl_entry2_down ; previous
  dw  offset gui_ipl_entry3_up   ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; use the 'string' field to fill the box
  dw  360,115              ; top left (x,y)
  dw  250,20               ; width, height
  dd  3                    ; index 3 in the ipl list (changes with up/down)
  dd  3                    ; index 3 in the list
  dup 32,0                 ; save room for the string to print

gui_ipl_entry3_up:
  dw  offset gui_ipl_entry3 ; parent = ipl_entry0
  dw  offset gui_ipl_entry3 ; previous
  dw  offset gui_ipl_entry3_down ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry3_down:
  dw  offset gui_ipl_entry3    ; parent = ipl_entry0
  dw  offset gui_ipl_entry3_up ; previous
  dw  offset gui_ipl_entry4    ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry4:
  dw  offset gui_root_object     ; parent = root
  dw  offset gui_ipl_entry3_down ; previous
  dw  offset gui_ipl_entry4_up   ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; use the 'string' field to fill the box
  dw  360,140              ; top left (x,y)
  dw  250,20               ; width, height
  dd  4                    ; index 4 in the ipl list (changes with up/down)
  dd  4                    ; index 4 in the list
  dup 32,0                 ; save room for the string to print

gui_ipl_entry4_up:
  dw  offset gui_ipl_entry4 ; parent = ipl_entry0
  dw  offset gui_ipl_entry4 ; previous
  dw  offset gui_ipl_entry4_down ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry4_down:
  dw  offset gui_ipl_entry4    ; parent = ipl_entry0
  dw  offset gui_ipl_entry4_up ; previous
  dw  offset gui_ipl_entry5    ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry5:
  dw  offset gui_root_object     ; parent = root
  dw  offset gui_ipl_entry4_down ; previous
  dw  offset gui_ipl_entry5_up   ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; use the 'string' field to fill the box
  dw  360,165              ; top left (x,y)
  dw  250,20               ; width, height
  dd  5                    ; index 5 in the ipl list (changes with up/down)
  dd  5                    ; index 5 in the list
  dup 32,0                 ; save room for the string to print

gui_ipl_entry5_up:
  dw  offset gui_ipl_entry5 ; parent = ipl_entry0
  dw  offset gui_ipl_entry5 ; previous
  dw  offset gui_ipl_entry5_down ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry5_down:
  dw  offset gui_ipl_entry5    ; parent = ipl_entry0
  dw  offset gui_ipl_entry5_up ; previous
  dw  offset gui_ipl_entry6    ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry6:
  dw  offset gui_root_object     ; parent = root
  dw  offset gui_ipl_entry5_down ; previous
  dw  offset gui_ipl_entry6_up   ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; use the 'string' field to fill the box
  dw  360,190              ; top left (x,y)
  dw  250,20               ; width, height
  dd  6                    ; index 6 in the ipl list (changes with up/down)
  dd  6                    ; index 6 in the list
  dup 32,0                 ; save room for the string to print

gui_ipl_entry6_up:
  dw  offset gui_ipl_entry6 ; parent = ipl_entry0
  dw  offset gui_ipl_entry6 ; previous
  dw  offset gui_ipl_entry6_down ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry6_down:
  dw  offset gui_ipl_entry6    ; parent = ipl_entry0
  dw  offset gui_ipl_entry6_up ; previous
  dw  offset gui_ipl_entry7    ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry7:
  dw  offset gui_root_object     ; parent = root
  dw  offset gui_ipl_entry6_down ; previous
  dw  offset gui_ipl_entry7_up   ; next item goes here
  dw  0                    ; no event
  dw  offset gui_draw_editbox
  db  GUI_TYPE_EDITBOX     ; this is an edit box
  db  GUI_OBJECT_VISIBLE   ; use the 'string' field to fill the box
  dw  360,215              ; top left (x,y)
  dw  250,20               ; width, height
  dd  7                    ; index 7 in the ipl list (changes with up/down)
  dd  7                    ; index 7 in the list
  dup 32,0                 ; save room for the string to print

gui_ipl_entry7_up:
  dw  offset gui_ipl_entry7 ; parent = ipl_entry0
  dw  offset gui_ipl_entry7 ; previous
  dw  offset gui_ipl_entry7_down ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_ipl_entry7_down:
  dw  offset gui_ipl_entry7    ; parent = ipl_entry0
  dw  offset gui_ipl_entry7_up ; previous
  dw  offset gui_button_exit   ; next item goes here
  dw  offset gui_ipl_entry_event
  dw  offset gui_draw_incbox
  db  GUI_TYPE_INCBOX      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE | GUI_INCBOX_ISDOWN)  ; flags
  dw  0,0                  ; top left (x,y) (draw routine gets location from parent)
  dw  10,10                ; width, height
  dd  0                    ; value
  dd  0                    ; limit

gui_button_exit:
  dw  offset gui_root_object     ; parent = root
  dw  offset gui_ipl_entry7_down ; previous
  dw  offset gui_button_apply    ; next item goes here
  dw  offset gui_object_exit
  dw  offset gui_draw_button
  db  GUI_TYPE_BUTTON      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (we calculate these later)
  dw  80,25                ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  '  Exit',0

gui_button_apply:
  dw  offset gui_root_object ; parent = root
  dw  offset gui_button_exit ; previous
  dw  0                    ; next item goes here
  dw  offset gui_object_apply
  dw  offset gui_draw_button
  db  GUI_TYPE_BUTTON      ; this is an inc box
  db  (GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)   ; flags
  dw  0,0                  ; top left (x,y) (we calculate these later)
  dw  80,25                ; width, height
  dd  0                    ; value
  dd  0                    ; value1
  db  ' Apply',0

cmos_reg_b     db  0
current_focus  dw  offset gui_num_lock
mouse_found    db  0


; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; this is our main 'setup' app entry point
; on entry:
;  es = EBDA
;  fs = flat selected with base = 0, limit = max
; on return
;  nothing
; destroys nothing
bios_setup proc far

           ; make sure we are in the graphics mode
           cmp  byte es:[EBDA_DATA->video_use_graphic],0
           jne  short @f
           ;; for now, just return
           retf

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; from this point on, we don't return
@@:        mov  ax,BIOS_BASE2
           mov  ds,ax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; make sure the cmos is in binary mode and 24-hour mode
           mov  al,0Bh
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           mov  cmos_reg_b,al
           or   al,((1<<2) | (1<<1))
           out  PORT_CMOS_DATA,al

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the objects
           ;  (we don't call 'bios_read_escd' because it is a near function)
           mov  bx,offset escd
           mov  al,[bx+ESCD_DATA->num_lock]
           mov  [gui_num_lock+GUI_OBJECT->value],al
           mov  al,[bx+ESCD_DATA->ehci_legacy]
           mov  [gui_ehci_legacy+GUI_OBJECT->value],al
           mov  al,[bx+ESCD_DATA->ahci_legacy]
           mov  [gui_ahci_legacy+GUI_OBJECT->value],al
           
           ; floppy signature check
           mov  al,0x38
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           and  al,1
           mov  [gui_floppy_sig+GUI_OBJECT->value],al
           
           ; fast boot
           mov  al,0x3F
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           and  al,1
           mov  [gui_fast_boot+GUI_OBJECT->value],al
           
           ; floppy0
           mov  al,0x10
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           push ax
           and  al,0x0F
           cmp  al,5
           jbe  short @f
           mov  al,6
@@:        mov  si,offset gui_floppy0_type
           mov  [si+GUI_OBJECT->value],al
           call gui_floppy_update
           pop  ax
           ; floppy1
           shr  al,4
           cmp  al,5
           jbe  short @f
           mov  al,6
@@:        mov  si,offset gui_floppy1_type
           mov  [si+GUI_OBJECT->value],al
           call gui_floppy_update

           ; fill the IPL list
           call gui_ipl_entry_fill

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; clear the screen
           mov  edi,es:[EBDA_DATA->video_ram]
           movzx ecx,word es:[EBDA_DATA->video_width]
           movzx eax,word es:[EBDA_DATA->video_height]
           imul ecx,eax
           mov  eax,GUI_BACKGROUND
@@:        call far es:[EBDA_DATA->vid_display_pixel]
           .adsize
           loop @b
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; calculate the postion for the Apply and Exit buttons
           mov  ax,es:[EBDA_DATA->video_height]
           sub  ax,[gui_button_exit+GUI_OBJECT->height]
           sub  ax,10
           mov  [gui_button_exit+GUI_OBJECT->y_pos],ax
           mov  [gui_button_apply+GUI_OBJECT->y_pos],ax
           mov  ax,es:[EBDA_DATA->video_width]
           sub  ax,[gui_button_apply+GUI_OBJECT->width]
           sub  ax,10
           mov  [gui_button_apply+GUI_OBJECT->x_pos],ax
           sub  ax,[gui_button_exit+GUI_OBJECT->width]
           sub  ax,10
           mov  [gui_button_exit+GUI_OBJECT->x_pos],ax
           
           ; scroll through the objects, drawing each one
           mov  eax,GUI_OBJ_FLAG_DO_NEXT
           mov  si,offset gui_root_object
           call gui_draw_object
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; reset, initialize, and enable the mouse
           call gui_init_mouse
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the date and time values
           call gui_init_time
           call gui_fill_time
           
           ; our loop would start here
gui_main_loop:
           ; update the display
           call gui_mouse_cursor
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; wait for the second to change, or a mouse event
           mov  al,00h
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           mov  ah,al
gui_wait_loop:
           ; if the left button was pressed
           ;  see if it was on an object
           test word gui_mouse_status,1
           jz   short @f
           call gui_mouse_event
           and  word gui_mouse_status,(~1)

           ; was a key pressed?
@@:        call gui_key_event
           
           ; are we in a different pos?
@@         mov  cx,gui_mouse_cur_lx
           cmp  cx,gui_mouse_cur_x
           jne  short @f
           mov  cx,gui_mouse_cur_ly
           cmp  cx,gui_mouse_cur_y
           je   short gui_wait_loop_0
@@:        call gui_mouse_cursor
           
           ; time to update the seconds?
gui_wait_loop_0:
           in   al,PORT_CMOS_DATA
           cmp  ah,al
           je   short gui_wait_loop
           
           ; time to update the date/time data
           call gui_update_time
           
           ; update all of the date/time values
           jmp  short gui_main_loop
           
           .noret
bios_setup endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; restore some items and reboot
; on entry:
;  es = EBDA
; on return
;  nothing
; destroys nothing
gui_object_exit proc near
           
           ; on exit, restore REG B of the CMOS
           mov  al,0Bh
           out  PORT_CMOS_INDEX,al
           mov  al,cmos_reg_b
           out  PORT_CMOS_DATA,al

           ; reset mouse so our handler is 'released'
           mov  ax,0xC201
           int  15h

           ; do a reset
           jmp  far 0xFFF0,0xF000

           .noret
gui_object_exit endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; apply any changes that we have made
; on entry:
;  es = EBDA
; on return
;  nothing
; destroys nothing
gui_object_apply proc near uses ax bx cx ds
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; write back the date/time values to the CMOS
           call gui_update_cmos

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; floppy signature check
           mov  al,0x38
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           and  al,(~1)
           mov  ah,[gui_floppy_sig+GUI_OBJECT->value]
           and  ah,1
           or   al,ah
           out  PORT_CMOS_DATA,al

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; fast boot
           mov  al,0x3F
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           and  al,(~1)
           mov  ah,[gui_fast_boot+GUI_OBJECT->value]
           and  ah,1
           or   al,ah
           out  PORT_CMOS_DATA,al

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; floppy0
           mov  al,0x10
           out  PORT_CMOS_INDEX,al
           mov  al,[gui_floppy1_type+GUI_OBJECT->value]
           shl  al,4
           or   al,[gui_floppy0_type+GUI_OBJECT->value]
           out  PORT_CMOS_DATA,al

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; make sure the cmos crc is correct
           ; only from 0x10 to 0x2D exclusive
           xor  bx,bx
           mov  cx,0x10          ; 0x10 to 0x2D
@@:        mov  ax,cx
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           add  bx,ax
           inc  cx
           cmp  cl,0x2D
           jbe  short @b
           ; write the new crc
           mov  al,0x2E
           out  PORT_CMOS_INDEX,al
           mov  al,bh
           out  PORT_CMOS_DATA,al
           mov  al,0x2F
           out  PORT_CMOS_INDEX,al
           mov  al,bl
           out  PORT_CMOS_DATA,al

.if DO_INIT_BIOS32
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; update the escd
           ;  (we don't call 'bios_write_escd' because it is a near function)
           mov  bx,offset escd
           mov  al,[gui_num_lock+GUI_OBJECT->value]
           mov  [bx+ESCD_DATA->num_lock],al
           mov  al,[gui_ehci_legacy+GUI_OBJECT->value]
           mov  [bx+ESCD_DATA->ehci_legacy],al
           mov  al,[gui_ahci_legacy+GUI_OBJECT->value]
           mov  [bx+ESCD_DATA->ahci_legacy],al
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; mark as dirty and write it to the flash rom
           call far offset bios_lock_shadow_ram,BIOS_BASE
           mov  ax,EBDA_SEG
           mov  ds,ax
           mov  byte [EBDA_DATA->escd_dirty],1
           call far offset bios_commit_escd,BIOS_BASE
           call far offset bios_unlock_shadow_ram,BIOS_BASE
.endif
           ret
gui_object_apply endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the date/time variables from the CMOS
; on entry:
;  nothing
; on return
;  nothing
; destroys nothing
gui_init_time proc near uses ax cx
           mov  al,04h
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           mov  gui_date_time.hour,al

           mov  al,02h
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           mov  gui_date_time.min,al

           mov  al,00h
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           mov  gui_date_time.sec,al

           mov  al,08h
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           mov  gui_date_time.month,al

           mov  al,07h
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           mov  gui_date_time.day,al

           mov  ax,32h
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           mov  cx,100
           mul  cx
           mov  gui_date_time.year,ax

           mov  ax,09h
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           add  gui_date_time.year,ax

           ret
gui_init_time endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; update the CMOS form the date/time variables
; on entry:
;  nothing
; on return
;  nothing
; destroys nothing
gui_update_cmos proc near uses ax cx dx
           mov  al,04h
           out  PORT_CMOS_INDEX,al
           mov  al,gui_date_time.hour
           out  PORT_CMOS_DATA,al

           mov  al,02h
           out  PORT_CMOS_INDEX,al
           mov  al,gui_date_time.min
           out  PORT_CMOS_DATA,al

           mov  al,00h
           out  PORT_CMOS_INDEX,al
           mov  al,gui_date_time.sec
           out  PORT_CMOS_DATA,al

           mov  al,08h
           out  PORT_CMOS_INDEX,al
           mov  al,gui_date_time.month
           out  PORT_CMOS_DATA,al

           mov  al,07h
           out  PORT_CMOS_INDEX,al
           mov  al,gui_date_time.day
           out  PORT_CMOS_DATA,al

           xor  dx,dx
           mov  ax,gui_date_time.year
           mov  cx,100
           div  cx   ; al = century, dl = year (00-99)

           push ax
           push ax
           ; write the century to 0x32 (IBM's Century byte)
           mov  al,32h
           out  PORT_CMOS_INDEX,al
           pop  ax
           out  PORT_CMOS_DATA,al
           ; we also need to write it to 0x37 (PS/2's Century byte)
           mov  al,37h
           out  PORT_CMOS_INDEX,al
           pop  ax
           out  PORT_CMOS_DATA,al

           mov  al,09h
           out  PORT_CMOS_INDEX,al
           mov  dl,al
           out  PORT_CMOS_DATA,al

           ret
gui_update_cmos endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; fill the date/time objects with the saved values
; on entry:
;  nothing
; on return
;  nothing
; destroys nothing
gui_fill_time proc near uses eax cx
           ; catch the limit on the day of the month
           mov  al,gui_date_time.month
           mov  cx,gui_date_time.year
           call get_days_in_month
           cmp  gui_date_time.day,al
           jbe  short @f
           mov  gui_date_time.day,al
           ; set the upper limit
@@:        mov  [gui_cmos_days_up+GUI_OBJECT->value1],al
           
           movzx eax,byte gui_date_time.hour
           mov  [gui_cmos_hours+GUI_OBJECT->value],eax

           mov  al,gui_date_time.min
           mov  [gui_cmos_mins+GUI_OBJECT->value],eax

           mov  al,gui_date_time.sec
           mov  [gui_cmos_secs+GUI_OBJECT->value],eax

           mov  al,gui_date_time.month
           mov  [gui_cmos_month+GUI_OBJECT->value],eax

           mov  al,gui_date_time.day
           mov  [gui_cmos_days+GUI_OBJECT->value],eax

           mov  ax,gui_date_time.year
           mov  [gui_cmos_year+GUI_OBJECT->value],eax

           ret
gui_fill_time endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; increment the date/time fields
; on entry:
;  nothing
; on return
;  nothing
; destroys nothing
gui_update_time proc near
           ; increment the sec
           inc  byte gui_date_time.sec
           cmp  byte gui_date_time.sec,60
           jb   short gui_update_time_done
           
           ; increment the min
           mov  byte gui_date_time.sec,0
           inc  byte gui_date_time.min
           cmp  byte gui_date_time.min,60
           jb   short gui_update_time_done

           ; increment the hour
           mov  byte gui_date_time.min,0
           inc  byte gui_date_time.hour
           cmp  byte gui_date_time.hour,24
           jb   short gui_update_time_done

           ; calculate total days in this month
           mov  al,gui_date_time.month
           mov  cx,gui_date_time.year
           call get_days_in_month

           ; increment the day
           mov  byte gui_date_time.hour,0
           inc  byte gui_date_time.day
           cmp  gui_date_time.day,al
           jbe  short gui_update_time_done
           
           ; increment the month
           mov  byte gui_date_time.day,1
           inc  byte gui_date_time.month
           cmp  byte gui_date_time.month,13
           jb   short gui_update_time_done

           ; increment the year
           mov  byte gui_date_time.month,1
           inc  byte gui_date_time.year
           
gui_update_time_done:           
           call gui_fill_time
           ret
gui_update_time endp

month_days  db  31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; calculate the days in a month
; (accounts for leap years)
; on entry:
;  al = 1 based month
;  cx = year
; on return
;  al = days in that month
; destroys nothing
get_days_in_month proc near uses bx cx dx
           xchg cx,ax            ; save the year in ax, month in cl

           mov  bx,offset month_days
           xor  ch,ch
           dec  cx
           add  bx,cx
           mov  cl,[bx]

           ; do we need to account for a leap year
           cmp  cl,28
           jne  short get_days_in_month_done

           ; a leap year is when a year is evenly divisible by 4
           ;  but not evenly divisible by 100
           ;  unless it is evenly divisible by 400
           push ax
           xor  dx,dx
           mov  bx,400
           div  bx
           pop  ax
           or   dx,dx
           jz   short get_days_in_month_leap

           test al,3
           jnz  short get_days_in_month_done

           xor  dx,dx
           mov  bx,100
           div  bx
           or   dx,dx
           jz   short get_days_in_month_done

get_days_in_month_leap:
           inc  cl
get_days_in_month_done:
           mov  al,cl
           ret
get_days_in_month endp

floppy_type_str  db  'None',0,0,0,0,0,0,0,0
                 db  '360K 5.25',0,0,0
                 db  '1.2M 5.25',0,0,0
                 db  '720K 3.50',0,0,0
                 db  '1.44M 3.50',0,0
                 db  '2.88M 3.50',0,0
                 db  'Unknown',0,0,0,0,0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize floppy edit box
; on entry:
;  es = EBDA
;  al = type (0 -> 5)
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_floppy_update proc near uses ax cx si di es
           lea  di,[si+GUI_OBJECT->string]
           xor  ah,ah
           mov  si,12
           mul  si
           mov  si,ax
           add  si,offset floppy_type_str
           push ds
           pop  es
           mov  cx,12
           rep
             movsb
           ret
gui_floppy_update endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; increment and update the floppy type string
; on entry:
;  es = EBDA
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_floppy_up_event proc near uses ax si
           mov  si,[si+GUI_OBJECT->parent]
           mov  al,[si+GUI_OBJECT->value]
           cmp  al,5
           jnb  short @f
           inc  al
           mov  [si+GUI_OBJECT->value],al
           call gui_floppy_update
           call gui_mouse_cursor
@@:        ret
gui_floppy_up_event endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; decrement and update the floppy type string
; on entry:
;  es = EBDA
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_floppy_dn_event proc near uses ax si
           mov  si,[si+GUI_OBJECT->parent]
           mov  al,[si+GUI_OBJECT->value]
           cmp  al,0
           jna  short @f
           dec  al
           mov  [si+GUI_OBJECT->value],al
           call gui_floppy_update
           call gui_mouse_cursor
@@:        ret
gui_floppy_dn_event endp

gui_ipl_object_list  dw  offset gui_ipl_entry0
                     dw  offset gui_ipl_entry1
                     dw  offset gui_ipl_entry2
                     dw  offset gui_ipl_entry3
                     dw  offset gui_ipl_entry4
                     dw  offset gui_ipl_entry5
                     dw  offset gui_ipl_entry6
                     dw  offset gui_ipl_entry7

gui_ipl_entry_fill proc near uses all es
           mov  ax,EBDA_SEG
           mov  es,ax
           
           mov  bx,offset gui_ipl_object_list
           mov  cx,8
gui_ipl_entry_fill_loop:
           push bx
           push cx
           mov  bx,[bx]

           push bx
           and  byte [bx+GUI_OBJECT->flags],(~GUI_OBJECT_VISIBLE)
           mov  bx,[bx+GUI_OBJECT->next]
           and  byte [bx+GUI_OBJECT->flags],(~GUI_OBJECT_VISIBLE)
           mov  bx,[bx+GUI_OBJECT->next]
           and  byte [bx+GUI_OBJECT->flags],(~GUI_OBJECT_VISIBLE)
           pop  bx
           mov  si,[bx+GUI_OBJECT->value]
           cmp  si,es:[EBDA_DATA->ipl_table_count]
           jae  short gui_ipl_entry_fill_next
           imul si,sizeof(IPL_ENTRY)
           add  si,EBDA_DATA->ipl_table_entries
           lea  si,[si+IPL_ENTRY->description]

           push bx
           or   byte [bx+GUI_OBJECT->flags],GUI_OBJECT_VISIBLE
           mov  bx,[bx+GUI_OBJECT->next]
           or   byte [bx+GUI_OBJECT->flags],GUI_OBJECT_VISIBLE
           mov  bx,[bx+GUI_OBJECT->next]
           or   byte [bx+GUI_OBJECT->flags],GUI_OBJECT_VISIBLE
           pop  bx

           lea  di,[bx+GUI_OBJECT->string]
           mov  cx,IPL_ENTRY_MAX_DESC_LEN
@@:        mov  al,es:[si]
           inc  si
           mov  [di],al
           inc  di
           loop @b
           xor  al,al
           mov  [di],al

gui_ipl_entry_fill_next:
           pop  cx
           pop  bx
           add  bx,sizeof(word)
           loop gui_ipl_entry_fill_loop

           ret
gui_ipl_entry_fill endp

gui_ipl_entry_event proc near uses all es
           mov  ax,EBDA_SEG
           mov  es,ax

           mov  eax,[si+GUI_OBJECT->value]
           cmp  ax,es:[EBDA_DATA->ipl_table_count]
           jae  short @f





@@:        ret
gui_ipl_entry_event endp

; the status word has the following format:
; bits 15-8   reserved (0)
;      7      Y data overflowed
;      6      X data overflowed
;      5      Y data is negative
;      4      X data is negative
;      3      reserved (1)
;      2      reserved (0)
;      1      right button pressed
;      0      left button pressed
gui_mouse_status  dw  0
gui_mouse_cur_x   dw  0   ; these four must stay in this order
gui_mouse_cur_y   dw  0   ;
gui_mouse_width   dw  10  ;
gui_mouse_height  dw  16  ;
gui_mouse_cur_z   dw  0
gui_mouse_cur_lx  dw  0   ; these four must stay in this order
gui_mouse_cur_ly  dw  0   ;
                  dw  10  ;
                  dw  16  ;
gui_drawing       db  0

; our mouse cursor
; 32-bit pixels. High byte !0, indicates transparent (don't plot pixel)
gui_mouse_cursor_bitmap:
  dd  0x00000000, 0x00000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000,
  dd  0x00000000, 0x00FFFFFF, 0x00000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000,
  dd  0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000,
  dd  0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000,
  dd  0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000,
  dd  0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0xFF000000, 0xFF000000, 0xFF000000,
  dd  0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0xFF000000, 0xFF000000,
  dd  0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0xFF000000,
  dd  0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00000000,
  dd  0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0x00000000, 0x00000000, 0xFF000000,
  dd  0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0xFF000000, 0xFF000000, 0xFF000000,
  dd  0x00000000, 0x00FFFFFF, 0x00000000, 0xFF000000, 0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0xFF000000, 0xFF000000,
  dd  0xFF000000, 0x00000000, 0xFF000000, 0xFF000000, 0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0xFF000000, 0xFF000000,
  dd  0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0xFF000000,
  dd  0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0x00000000, 0x00FFFFFF, 0x00FFFFFF, 0x00000000, 0xFF000000,
  dd  0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0x00000000, 0x00000000, 0xFF000000, 0xFF000000

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the mouse hardware and handler
; on entry:
;  es = EBDA
; on return
;  nothing
; destroys nothing
gui_init_mouse proc near uses ax bx
           mov  ax,0xC201  ; reset
           int  15h
           jc   short gui_init_mouse_done
           cmp  bx,0x00AA
           jne  short gui_init_mouse_done

           mov  ax,0xC205  ; initialize
           mov  bh,4       ; 4-byte packet size
           int  15h
           jc   short gui_init_mouse_done

           ; after reset, the mouse is set up to send a
           ;  3-byte packet. (no z-corrd). if we send a
           ;  set-sample-rate of 200, then 100, then 80,
           ;  the mouse, if capable, will initialize to
           ;  a wheel-mouse mode (z-corrd).
           mov  ax,0xC202
           mov  bh,06h     ; 6 = 200
           int  15h
           mov  ax,0xC202
           mov  bh,05h     ; 5 = 100
           int  15h
           mov  ax,0xC202
           mov  bh,04h     ; 4 = 80
           int  15h

           ; get the type to make sure we are now set to wheel-mouse mode
           mov  ax,0xC204
           int  15h
           cmp  bh,0x03
           je   short @f

           ; else we must re-initialize to a 3-byte packet
           mov  ax,0xC205  ; initialize
           mov  bh,3       ; 3-byte packet size
           int  15h

@@:        push es
           mov  ax,0xF000
           mov  es,ax
           mov  bx,offset gui_mouse_handler
           mov  ax,0xC207
           int  15h
           pop  es

           mov  ax,0xC200  ; enable the mouse
           mov  bh,01h
           int  15h

           mov  ax,es:[EBDA_DATA->video_width]
           shr  ax,1
           mov  gui_mouse_cur_x,ax
           mov  ax,es:[EBDA_DATA->video_height]
           shr  ax,1
           mov  gui_mouse_cur_y,ax

           ; mark that we found and can use the mouse
           mov  byte mouse_found,1
           
gui_init_mouse_done:
           ret
gui_init_mouse endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; this is our mouse handler. the BIOS will call this
;  handler each time a mouse packet is created.
; on entry:
;  the stack is filled with a 4 byte packet:
;  (remember the retf address and bp)
;    status     [bp + 12]
;    x data     [bp + 10]
;    y data     [bp + 8]
;    z data     [bp + 6]
;    return     [bp + 2]
;    bp         [bp + 0]
; on return
;  nothing
; destroys nothing
gui_mouse_handler proc far
           push bp
           mov  bp,sp

           cmp  byte cs:gui_drawing,0
           jne  short gui_mouse_handler_2
           
           push ax
           push cx
           push es

           mov  ax,EBDA_SEG
           mov  es,ax

           mov  cx,[bp+12]
           mov  cs:gui_mouse_status,cx

           test cl,0x40
           jnz  short gui_mouse_handler_0
           mov  ax,[bp+10]
           test cl,0x10
           jz   short @f
           mov  ah,0xFF
@@:        add  cs:gui_mouse_cur_x,ax
           jns  short @f
           mov  word cs:gui_mouse_cur_x,0
@@:        mov  ax,es:[EBDA_DATA->video_width]
           cmp  ax,cs:gui_mouse_cur_x
           jg   short gui_mouse_handler_0
           dec  ax
           mov  cs:gui_mouse_cur_x,ax

gui_mouse_handler_0:
           test cl,0x80
           jnz  short gui_mouse_handler_1
           mov  ax,[bp+8]
           test cl,0x20
           jz   short @f
           mov  ah,0xFF
@@:        sub  cs:gui_mouse_cur_y,ax
           jns  short @f
           mov  word cs:gui_mouse_cur_y,0
@@:        mov  ax,es:[EBDA_DATA->video_height]
           cmp  ax,cs:gui_mouse_cur_y
           jg   short gui_mouse_handler_1
           dec  ax
           mov  cs:gui_mouse_cur_y,ax

gui_mouse_handler_1:
           mov  ax,[bp+6]
           cbw
           mov  cs:gui_mouse_cur_z,ax
           
           pop  es
           pop  cx
           pop  ax

gui_mouse_handler_2:
           mov  sp,bp
           pop  bp
           retf
gui_mouse_handler endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; display the mouse cursor
; on entry:
;  es = EBDA
;  fs = flat selected with base = 0, limit = max
; on return
;  nothing
; destroys nothing (must preserve ah)
gui_mouse_cursor proc near uses all
           ; don't let the hander update if we are drawing
           mov  byte gui_drawing,1
           
           ; first draw a box for the background
           mov  bx,offset gui_mouse_cur_lx
           call gui_get_topleft
           mov  dx,GUI_BOX_BUTTON_FILL
           mov  eax,GUI_BACKGROUND
           call gui_draw_box

           ; scroll through the objects, drawing each one
           mov  eax,GUI_OBJ_FLAG_DO_NEXT
           mov  si,offset gui_root_object
           call gui_draw_object

           ; draw the current focus?
           mov  si,current_focus
           or   si,si
           jz   short @f
           lea  bx,[si+GUI_OBJECT->x_pos]
           call gui_get_topleft
           call gui_draw_focus

           ; now draw the cursor
@@:        mov  bx,offset gui_mouse_cur_x
           call gui_get_topleft
           mov  dx,offset gui_mouse_cursor_bitmap
           call gui_blt_box

           ; update the last position
           mov  ax,gui_mouse_cur_x
           mov  gui_mouse_cur_lx,ax
           mov  ax,gui_mouse_cur_y
           mov  gui_mouse_cur_ly,ax

           mov  byte gui_drawing,0

           ret
gui_mouse_cursor endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; a mouse button was pressed
; on entry:
;  es = EBDA
;  fs = flat selected with base = 0, limit = max
; on return
;  nothing
; destroys nothing (must preserve ah)
gui_mouse_event proc near uses ax cx dx si
           
           mov  si,offset gui_root_object
           mov  si,[si+GUI_OBJECT->next]
           mov  cx,gui_mouse_cur_x
           mov  dx,gui_mouse_cur_y
gui_mouse_event_0:
           mov  ax,[si+GUI_OBJECT->x_pos]
           cmp  cx,ax
           jb   short gui_mouse_event_1
           add  ax,[si+GUI_OBJECT->width]
           cmp  cx,ax
           jae  short gui_mouse_event_1
           mov  ax,[si+GUI_OBJECT->y_pos]
           cmp  dx,ax
           jb   short gui_mouse_event_1
           add  ax,[si+GUI_OBJECT->height]
           cmp  dx,ax
           jae  short gui_mouse_event_1

           ; set this object as having the focus
           mov  current_focus,si

           ; if there is an event handler for this object, call it
           mov  ax,[si+GUI_OBJECT->event]
           or   ax,ax
           jz   short gui_mouse_event_2
           call ax
           jmp  short gui_mouse_event_2

gui_mouse_event_1:
           mov  si,[si+GUI_OBJECT->next]
           or   si,si
           jnz  short gui_mouse_event_0

gui_mouse_event_2:
           ret
gui_mouse_event endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; a key was pressed
; on entry:
;  es = EBDA
; on return
;  nothing
; destroys nothing (must preserve ah)
gui_key_event proc near uses ax si
           mov  ah,1
           int  16h
           jz   short gui_key_event_none

           ; get the key's scan code
           xor  ah,ah
           int  16h

           ; if current focus is null, no need to continue
           mov  si,current_focus
           or   si,si
           jz   short gui_key_event_none
           
           ; space bar?
           cmp  ax,0x3920
           jne  short @f
           
           ; simulate a mouse click on the object with the focus
           mov  ax,[si+GUI_OBJECT->event]
           or   ax,ax
           jz   short gui_key_event_none
           call ax
           jmp  short gui_key_event_done

           ; tab key?
@@:        cmp  ax,0x0F09
           jne  short @f

           ; try to move the focus to the next object
gui_tab_loop_0:
           mov  si,[si+GUI_OBJECT->next]
           or   si,si
           jnz  short gui_tab_loop_1
           ; 'return' to the first one
           mov  si,[gui_root_object+GUI_OBJECT->next]
gui_tab_loop_1:
           mov  al,[si+GUI_OBJECT->flags]
           and  al,(GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)
           cmp  al,(GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)
           jne  short gui_tab_loop_0
           mov  current_focus,si
           jmp  short gui_key_event_done
           
           ; shift-tab?
@@:        cmp  ax,0x0F00
           jne  short @f

           ; try to move the focus to the prev object
gui_tab_loop_2:
           mov  si,[si+GUI_OBJECT->prev]
           or   si,si
           jz   short gui_key_event_none
           mov  al,[si+GUI_OBJECT->flags]
           and  al,(GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)
           cmp  al,(GUI_OBJECT_TABSTOP | GUI_OBJECT_VISIBLE)
           jne  short gui_tab_loop_2
           mov  current_focus,si
           jmp  short gui_key_event_done

           ; next key to check goes here...
@@:



gui_key_event_done:
           ; draw the desktop again
           call gui_mouse_cursor
gui_key_event_none:
           ret
gui_key_event endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; return the top left corner location of object in edi
; on entry:
;  es = EBDA
;  fs = flat selected with base = 0, limit = max
;  ds:bx -> rect object
; on return
;  fs:edi -> top left corner on screen
;  ecx = bytes per pixel
; destroys nothing
gui_get_topleft proc near uses eax edx
           movzx eax,word [bx+GUI_RECT->y_pos]
           movzx ecx,word es:[EBDA_DATA->video_bpscanline]
           mul  ecx

           movzx ecx,byte es:[EBDA_DATA->video_bpp]
           inc  cl               ; incase it is 15
           shr  cl,3             ; divide by 8
           movzx edx,word [bx+GUI_RECT->x_pos]
           imul edx,ecx
           add  eax,edx

           mov  edi,es:[EBDA_DATA->video_ram]
           add  edi,eax
           ret
gui_get_topleft endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw an object to the screen
; on entry:
;  es = EBDA
;  fs = flat selected with base = 0, limit = max
;  eax = flags (GUI_OBJ_FLAG_*)
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_draw_object proc near uses cx si

gui_draw_object_loop:
           ; what type of object are we
           mov  cl,[si+GUI_OBJECT->type]
           cmp  cl,GUI_TYPE_NONE
           je   short @f
           
           ; if the object is not marked visible, don't display it
           test byte [si+GUI_OBJECT->flags],GUI_OBJECT_VISIBLE
           jz   short @f

           ; if not-null, call the draw routine
           mov  cx,[si+GUI_OBJECT->draw]
           or   cx,cx
           jz   short @f
           
           ; call the draw function
           call cx
           
           ; do we do the next one?
@@:        test eax,GUI_OBJ_FLAG_DO_NEXT
           jz   short gui_draw_object_done
           mov  si,[si+GUI_OBJECT->next]
           or   si,si
           jnz  short gui_draw_object_loop
                
gui_draw_object_done:
           ret
gui_draw_object endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw text to the screen
; on entry:
;  es = EBDA
;  edx = background color
;  fs = flat selected with base = 0, limit = max
;  ds:si -> object
;  fs:edi -> location of first char
; on return
;  nothing
; destroys nothing
gui_draw_text proc near uses alld
           mov  ebp,edx            ; save background color in ebp
           
           ; ebx = bytes per pixel
           movzx ebx,byte es:[EBDA_DATA->video_bpp]
           inc  bl               ; incase it is 15
           shr  bl,3             ; divide by 8

           ; get the width of the object
           mov  cx,[si+GUI_OBJECT->width]
           lea  si,[si+GUI_OBJECT->string]
           ; do we still have room?
gui_draw_text_loop:
           cmp  cx,VID_FONT_WIDTH
           jb   short gui_draw_text_done

           ; calculate the char position (es:si -> font)
           ; (our chars are 8-bits in width)
           xor  ah,ah
           lodsb  ; get char
           or   al,al
           jz   short gui_draw_text_done

           push si
           push cx
           push edi
           
           mov  si,offset our_font
           mov  cx,VID_FONT_HEIGHT
           mul  cx 
           add  si,ax
           
           movzx edx,word es:[EBDA_DATA->video_bpscanline]
           mov  cx,VID_FONT_HEIGHT
gui_char_main: 
           push cx
           push dx
           push edi
           mov  dl,[si]
           inc  si
           mov  cx,8
gui_char_line: 
           mov  eax,GUI_TEXT_COLOR
           shl  dl,1
           jc   short @f
           mov  eax,ebp
@@:        call far es:[EBDA_DATA->vid_display_pixel]
           loop gui_char_line
           pop  edi
           pop  dx
           pop  cx
           add  edi,edx
           loop gui_char_main

           pop  edi
           pop  cx
           pop  si

           ; move to next char position
           sub  cx,VID_FONT_WIDTH
           imul eax,ebx,VID_FONT_WIDTH
           add  edi,eax
           jmp  short gui_draw_text_loop
           
gui_draw_text_done:
           ret
gui_draw_text endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw text to the screen
; on entry:
;  es = EBDA
;  fs = flat selected with base = 0, limit = max
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_draw_static proc near uses ebx ecx edx
           ; if the object is not marked visible, don't display it
           test byte [si+GUI_OBJECT->flags],GUI_OBJECT_VISIBLE
           jnz  short @f
           ret

@@:        lea  bx,[si+GUI_OBJECT->x_pos]
           call gui_get_topleft
           mov  edx,GUI_BACKGROUND
           call gui_draw_text
           ret
gui_draw_static endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw a checkbox
; on entry:
;  es = EBDA
;  fs = flat selected with base = 0, limit = max
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_draw_checkbox proc near uses alld
           ; if the object is not marked visible, don't display it
           test byte [si+GUI_OBJECT->flags],GUI_OBJECT_VISIBLE
           jnz  short @f
           ret
           
           ; draw a box
@@:        lea  bx,[si+GUI_OBJECT->x_pos]
           call gui_get_topleft
           mov  dx,GUI_BOX_BUTTON_UP
           call gui_draw_box

           ; draw the text
           movzx edx,word es:[EBDA_DATA->video_bpscanline]
           imul edx,3          ; drop down a few pixels
           add  edi,edx
           imul ecx,3          ; move to the right a few pixels
           add  edi,ecx
           mov  edx,GUI_BACKGROUND
           call gui_draw_text

           ; draw the check box part
           push si
           push bx
           mov  si,offset temp_rect
           ; calculate left side
           mov  ax,[bx+GUI_RECT->x_pos]
           add  ax,[bx+GUI_RECT->width]
           sub  ax,18
           mov  [si+GUI_RECT->x_pos],ax
           ; calculate top side
           mov  ax,[bx+GUI_RECT->y_pos]
           add  ax,4
           mov  [si+GUI_RECT->y_pos],ax
           mov  word [si+GUI_RECT->width],12
           mov  word [si+GUI_RECT->height],12
           mov  bx,si
           call gui_get_topleft
           mov  dx,GUI_BOX_BUTTON_DN
           call gui_draw_box
           pop  bx
           pop  si

           ; if the 'value' field is non-zero, we need to put another box in it
           push bx
           push si
           mov  si,offset temp_rect
           ; calculate left side
           mov  ax,[bx+GUI_RECT->x_pos]
           add  ax,[bx+GUI_RECT->width]
           sub  ax,16
           mov  [si+GUI_RECT->x_pos],ax
           ; calculate top side
           mov  ax,[bx+GUI_RECT->y_pos]
           add  ax,6
           mov  [si+GUI_RECT->y_pos],ax
           mov  word [si+GUI_RECT->width],7
           mov  word [si+GUI_RECT->height],8
           mov  bx,si
           call gui_get_topleft
           mov  dx,GUI_BOX_BUTTON_FILL
           pop  si
           
           mov  eax,GUI_BACKGROUND
           cmp  dword [si+GUI_OBJECT->value],0
           je   short @f
           mov  eax,GUI_BUTTON_DARK
@@:        call gui_draw_box

           pop  bx

           ret
gui_draw_checkbox endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; checkbox event handler
; on entry:
;  es = EBDA
;  fs = flat selected with base = 0, limit = max
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_checkbox_event proc near uses ax
           ; toggle the object's value
           xor  dword [si+GUI_OBJECT->value],1
           ; and then draw the object(s)
           call gui_mouse_cursor
           ret
gui_checkbox_event endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw an editbox
; on entry:
;  es = EBDA
;  fs = flat selected with base = 0, limit = max
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_draw_editbox proc near uses alld
           ; if the object is not marked visible, don't display it
           test byte [si+GUI_OBJECT->flags],GUI_OBJECT_VISIBLE
           jnz  short @f
           ret
           
           ; draw a box
@@:        lea  bx,[si+GUI_OBJECT->x_pos]
           call gui_get_topleft
           mov  dx,GUI_BOX_BUTTON_UP
           call gui_draw_box

           ; draw the edit box part
           push si
           push bx
           mov  si,offset temp_rect
           ; copy the rect
           mov  ecx,[bx+0]
           mov  [si+0],ecx
           mov  ecx,[bx+4]
           mov  [si+4],ecx
           ; 'shrink' the box
           inc  word [si+GUI_RECT->x_pos]
           inc  word [si+GUI_RECT->y_pos]
           sub  word [si+GUI_RECT->width],2
           sub  word [si+GUI_RECT->height],2
           mov  bx,si
           call gui_get_topleft
           mov  dx,GUI_BOX_BUTTON_FILL
           mov  eax,GUI_BUTTON_LIGHT
           call gui_draw_box
           pop  bx
           pop  si
           
           ; print some text?
           test byte [si+GUI_OBJECT->flags],GUI_EDITBOX_VALUE
           jz   short @f
           
           ; we need to fill the 'string' field with the 'value' field
           push si
           mov  eax,[si+GUI_OBJECT->value]
           lea  si,[si+GUI_OBJECT->string]
           call bin2dec
           pop  si

           ; draw the text
@@:        movzx edx,word es:[EBDA_DATA->video_bpscanline]
           imul edx,3          ; drop down a few pixels
           add  edi,edx
           imul ecx,3          ; move to the right a few pixels
           add  edi,ecx
           mov  edx,GUI_BUTTON_LIGHT
           call gui_draw_text

           ret
gui_draw_editbox endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw an editbox
; on entry:
;  es = EBDA
;  fs = flat selected with base = 0, limit = max
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_draw_incbox proc near uses alld
           ; if the object is not marked visible, don't display it
           test byte [si+GUI_OBJECT->flags],GUI_OBJECT_VISIBLE
           jnz  short @f
           ret
           
           ; calculate the x/y location from the 'parent'
@@:        mov  bx,[si+GUI_OBJECT->parent]
           
           mov  ax,[bx+GUI_OBJECT->x_pos]
           add  ax,[bx+GUI_OBJECT->width]
           add  ax,2
           mov  [si+GUI_OBJECT->x_pos],ax
           mov  ax,[bx+GUI_OBJECT->y_pos]
           test byte [si+GUI_OBJECT->flags],GUI_INCBOX_ISDOWN
           jz   short @f
           add  ax,[bx+GUI_OBJECT->height]
           sub  ax,10
@@:        mov  [si+GUI_OBJECT->y_pos],ax
           mov  word [si+GUI_OBJECT->width],10
           mov  word [si+GUI_OBJECT->height],10
           lea  bx,[si+GUI_OBJECT->x_pos]

           call gui_get_topleft
           mov  dx,GUI_BOX_BUTTON_UP
           call gui_draw_box
           
           ret
gui_draw_incbox endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; increment the byte/word/dword
; on entry:
;  ds:si -> object
;    low word of object->value is offset to value to inc
;    high word of object->value is size of value in bytes
;    limit is checked
; on return
;  nothing
; destroys nothing
gui_button_up_event proc near uses ax bx ecx
           ; inc the value pointed to by 'value'
           mov  bx,[si+GUI_OBJECT->value+0]
           mov  ax,[si+GUI_OBJECT->value+2]
           mov  ecx,[si+GUI_OBJECT->value1]
           cmp  al,1
           jne  short @f
           cmp  [bx],cl
           jnl  short @f
           inc  byte [bx]
@@:        cmp  al,2
           jne  short @f
           cmp  [bx],cx
           jnl  short @f
           inc  word [bx]
@@:        cmp  al,4
           jne  short @f
           cmp  [bx],ecx
           jnl  short @f
           inc  dword [bx]

           ; and then draw the object(s)
@@:        call gui_fill_time
           call gui_mouse_cursor
           ret
gui_button_up_event endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; decrement the byte/word/dword
; on entry:
;  ds:si -> object
;    low word of object->value is offset to value to dec
;    high word of object->value is size of value in bytes
;    limit is checked
; on return
;  nothing
; destroys nothing
gui_button_dn_event proc near uses ax bx ecx
           ; dec the value pointed to by 'value'
           mov  bx,[si+GUI_OBJECT->value+0]
           mov  ax,[si+GUI_OBJECT->value+2]
           mov  ecx,[si+GUI_OBJECT->value1]
           cmp  al,1
           jne  short @f
           cmp  [bx],cl
           jng  short @f
           dec  byte [bx]
@@:        cmp  al,2
           jne  short @f
           cmp  [bx],cx
           jng  short @f
           dec  word [bx]
@@:        cmp  al,4
           jne  short @f
           cmp  [bx],ecx
           jng  short @f
           dec  dword [bx]

           ; and then draw the object(s)
@@:        call gui_fill_time
           call gui_mouse_cursor
           ret
gui_button_dn_event endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw a button box
; on entry:
;  es = EBDA
;  fs = flat selected with base = 0, limit = max
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_draw_button proc near uses alld
           ; if the object is not marked visible, don't display it
           test byte [si+GUI_OBJECT->flags],GUI_OBJECT_VISIBLE
           jnz  short @f
           ret
           
           ; draw a box
@@:        lea  bx,[si+GUI_OBJECT->x_pos]
           call gui_get_topleft
           mov  dx,GUI_BOX_BUTTON_UP
           call gui_draw_box
           
           ; draw the text
           movzx edx,word es:[EBDA_DATA->video_bpscanline]
           imul edx,6          ; drop down a few pixels
           add  edi,edx
           imul ecx,3          ; move to the right a few pixels
           add  edi,ecx
           mov  edx,GUI_BACKGROUND
           call gui_draw_text
           
           ret
gui_draw_button endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw a frame box
; on entry:
;  es = EBDA
;  fs:edi -> current pixel location
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_draw_frame proc near uses alld
           ; if the object is not marked visible, don't display it
           test byte [si+GUI_OBJECT->flags],GUI_OBJECT_VISIBLE
           jnz  short @f
           ret

@@:        lea  bx,[si+GUI_OBJECT->x_pos]
           call gui_get_topleft
           push edi

           ; copy the rect
           mov  eax,[bx+0]
           mov  [temp_rect+0],eax
           mov  eax,[bx+4]
           mov  [temp_rect+4],eax
           sub  word temp_rect.height,6

           ; draw the box
           movzx eax,word es:[EBDA_DATA->video_bpscanline]
           imul eax,6
           add  edi,eax
           xor  dx,dx
           mov  bx,offset temp_rect
           call gui_draw_box

           pop  edi
           push ecx
           imul ecx,8
           add  edi,ecx
           pop  ecx
           mov  edx,GUI_BACKGROUND
           call gui_draw_text

           ;movzx edx,word es:[EBDA_DATA->video_bpscanline]
           ;movzx ebx,word [si+GUI_OBJECT->width]



           
           
           ret
gui_draw_frame endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw a box
; on entry:
;  es = EBDA
;  fs:edi -> current pixel location
;  eax = color of filled box
;  ds:bx -> rect struct
;  ecx = bytes per pixel
;  dx = flags
; on return
;  nothing
; destroys nothing
gui_draw_box proc near uses alld
           
           mov  bp,dx            ; save the flags
           mov  edx,ecx          ; save bytes per pixel in edx

           ; are we a filled box?
           test  bp,GUI_BOX_BUTTON_FILL
           jnz   short gui_draw_box_filled

           ; draw a button style box
           push edx
           push edi

           ; top horizontal first
           mov  cx,[bx+GUI_RECT->width]
           mov  eax,GUI_BUTTON_HI
           test bp,GUI_BOX_BUTTON_DN
           jz   short @f
           mov  eax,GUI_BUTTON_LO
@@:        call far es:[EBDA_DATA->vid_display_pixel]
           loop @b
           sub  edi,edx

           ; now the right vertical
           movzx edx,word es:[EBDA_DATA->video_bpscanline]
           mov  cx,[bx+GUI_RECT->height]
           dec  cx
@@:        add  edi,edx
           push edi
           call far es:[EBDA_DATA->vid_display_pixel]
           pop  edi
           loop @b

           pop  edi

           ; now the left vertical
           mov  cx,[bx+GUI_RECT->height]
           dec  cx
           mov  eax,GUI_BUTTON_HI
           test bp,GUI_BOX_BUTTON_DN
           jnz  short @f
           mov  eax,GUI_BUTTON_LO
@@:        add  edi,edx
           push edi
           call far es:[EBDA_DATA->vid_display_pixel]
           pop  edi
           loop @b

           pop  edx

           ; now bottom horizontal
           mov  cx,[bx+GUI_RECT->width]
           dec  cx
@@:        add  edi,edx
           push edi
           call far es:[EBDA_DATA->vid_display_pixel]
           pop  edi
           loop @b
           ret

           ; draw a filled box
gui_draw_box_filled:
           mov  cx,[bx+GUI_RECT->height]
gui_draw_box_filled_0:
           push ecx
           push edi
           mov  cx,[bx+GUI_RECT->width]
@@:        call far es:[EBDA_DATA->vid_display_pixel]
           loop @b
           pop  edi
           movzx ecx,word es:[EBDA_DATA->video_bpscanline]
           add  edi,ecx
           pop  ecx
           loop gui_draw_box_filled_0
           
           ret
gui_draw_box endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; draw a focus indicator 'around' the object that has focus
; on entry:
;  es = EBDA
;  fs:edi -> current pixel location
;  ecx = bytes per pixel
;  ds:bx -> rect struct
;  ds:si -> object
; on return
;  nothing
; destroys nothing
gui_draw_focus proc near uses alld

           ; if the object is not marked visible, don't display it
           test byte [si+GUI_OBJECT->flags],GUI_OBJECT_VISIBLE
           jnz  short @f
           ret

@@:        mov  edx,ecx          ; save bytes per pixel in edx
           
           push edx
           push edi

           ; dotted box color
           mov  eax,GUI_COLOR_FOCUS

           ; top horizontal first
           mov  cx,[bx+GUI_RECT->width]
@@:        call far es:[EBDA_DATA->vid_display_pixel]
           dec  cx
           jz   short @f
           add  edi,edx
           loop @b
@@:        sub  edi,edx
           
           ; now the right vertical
           movzx edx,word es:[EBDA_DATA->video_bpscanline]
           mov  cx,[bx+GUI_RECT->height]
           dec  cx
@@:        push edi
           call far es:[EBDA_DATA->vid_display_pixel]
           pop  edi
           add  edi,edx
           dec  cx
           jz   short @f
           add  edi,edx
           loop @b

@@:        pop  edi
           
           ; now the left vertical
           mov  cx,[bx+GUI_RECT->height]
           dec  cx
@@:        push edi
           call far es:[EBDA_DATA->vid_display_pixel]
           pop  edi
           add  edi,edx
           dec  cx
           jz   short @f
           add  edi,edx
           loop @b

@@:        pop  edx
           
           ; now bottom horizontal
           mov  cx,[bx+GUI_RECT->width]
@@:        call far es:[EBDA_DATA->vid_display_pixel]
           dec  cx
           jz   short @f
           add  edi,edx
           loop @b
           
@@:        ret
gui_draw_focus endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; copy an image to the screen
; on entry:
;  es = EBDA
;  fs:edi -> current pixel location
;  ecx = bytes per pixel
;  ds:bx -> rect struct
;  ds:dx -> pixel stream (32-bit pixels)
; on return
;  nothing
; destroys nothing
gui_blt_box proc near uses alld

           mov  si,dx            ; source pixel stream in si
           mov  edx,ecx          ; save bytes per pixel in edx
           mov  cx,[bx+GUI_RECT->height]
gui_blt_box_0:
           push ecx
           push edi
           mov  cx,[bx+GUI_RECT->width]
gui_blt_box_1:
           lodsd
           test eax,0xFF000000
           jnz  short @f
           push edi
           call far es:[EBDA_DATA->vid_display_pixel]
           pop  edi
@@:        add  edi,edx
           loop gui_blt_box_1
           pop  edi
           movzx ecx,word es:[EBDA_DATA->video_bpscanline]
           add  edi,ecx
           pop  ecx
           loop gui_blt_box_0

           ret
gui_blt_box endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; convert value to asciiz
; (we zero pad to the right 2 digits)
; on entry:
;  es = EBDA
;  eax = value
;  ds:si -> buffer to store string
; on return
;  nothing
; destroys nothing
bin2dec    proc near uses eax ecx edx si
           push 0xFFFF
           cmp  eax,9
           ja   short @f
           mov  byte [si],'0'
           inc  si
@@:        mov  ecx,10
@@:        xor  edx,edx
           div  ecx
           push dx
           or   eax,eax
           jnz  short @b

@@:        pop  dx
           cmp  dx,0xFFFF
           je   short @f
           add  dl,'0'
           mov  [si],dl
           inc  si
           jmp  short @b

@@:        mov  byte [si],0
           ret
bin2dec    endp

.end
