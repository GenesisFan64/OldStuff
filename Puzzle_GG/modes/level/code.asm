; ====================================================================
; -------------------------------------------------
; Level
; -------------------------------------------------

; -------------------------------------------------
; Include
; -------------------------------------------------

; -------------------------------------------------
; Vars
; -------------------------------------------------

;ram_ponflags
pon_width		equ 	6
pon_height		equ 	9

bitFullField		equ	0
bitDecCur		equ	7

; -------------------------------------------------
; RAM
; -------------------------------------------------

			rsset ram_modebuffer
ram_scrltmr		rb 1					; scroll timer
ram_scrlspd		rb 1					; scroll speed
ram_scrlflag		rb 1					; scroll flag+timer (1x)		
ram_scrlpos		rb 1					; scroll position (00h-00Eh)
ram_ponrand		rb 1					; random 1
ram_ponrnd2		rb 1					; random 2
ram_ponflags		rb 1					; see Vars
ram_poncurpos		rb 1					; XY
ram_pontimeout		rb 1					; scroll timeout timer
ram_ponfield		rb (pon_width*pon_height)+(pon_width*2) ; 6*9 playfield, >10 are for reloading new lines

;EXTERNAL: ram_vintframes (frame counter from VBlank)

; -------------------------------------------------
; Init
; -------------------------------------------------

Level:
  		ld	b,ID_FadeOut
  		ld	de,1F00h
  		call	PalFade_Set
    		call	PalFade_Wait
    		
		di
		call	clearscreen
		bankdata BANK_level
		
		ld	hl,art_ingame			;  hl = 0208   where is data at
		ld	de,0				;  de = 0      where in VRAM to put data
		ld	bc,art_ingame_end		;  bc = 0380   how many times to write to vram
		call	WriteVRAM

; 		ld	ix,map_ingame
; 		ld	bc,201Ch
;  		ld	de,screen
;  		call	VDP_LoadMaps
		ld	hl,pal_ingame
		ld	b,32
		ld	c,0
 		call	PalFade_Load
 		
 		call	Pon_Init
 		
		ei
 		ld	b,ID_FadeIn
 		ld	de,1F00h
 		call	PalFade_Set
 		call	PalFade_Wait
         	
         	ld	a,7			;temproal thing
         	ld	(ram_scrlspd),a
         	
; -------------------------------------------------
; Loop
; -------------------------------------------------

@loop:
		call	VSync
		
		call	Pon_Controls
		call	Pon_Run
		
		ld	a,(ram_joypads+on_press)
		bit 	bitJoyStart,a
		jp	z,@Loop
		
		xor	a
		ld	(ram_gamemode),a
		ret

; -------------------------------------------------

; @end_this:
; 		ld	a,1
; 		ld	(ram_gamemode),a
; 		ret
	
; ====================================================================
; -------------------------------------------------
; Pon Engine
; -------------------------------------------------

; -------------------------
; Init
; -------------------------

Pon_Init:
 		ld	a,11001011b			; random values
 		ld	(ram_ponrand),a
		ld	a,64h
		ld	(ram_ponrnd2),a
		xor 	a
		ld	(ram_scrlpos),a			; clear position
		ld	(ram_scrlflag),a		; clear scroll flags
		ld	(ram_pontimeout),a		; clear timeout
		ld	(ram_ponflags),a		; clear pon flags
		
		ld	a,40h				; default cursor position
		ld	(ram_poncurpos),a
 		call	Pon_InitBg			; draw hud to layer
		call 	Pon_MakeHudSpr			; draw hud sprites
		call	Pon_Cursor			; draw cursor
		call	Pon_InitField			; init field
		jp	Pon_Refresh			; refresh

; ====================================================================
; -------------------------
; Run
; -------------------------

Pon_Run:
		ld	a,(ram_ponflags)
		bit 	bitFullField,a
		jp	nz,@end
		ld	a,(ram_pontimeout)
		dec 	a
		ld	(ram_pontimeout),a
		jp	p,@end 
		xor 	a
		ld	(ram_pontimeout),a
		
		call	Pon_Random
		
		ld	a,(ram_scrlspd)
		ld	b,a
		ld	a,(ram_scrltmr)
		inc 	a
		ld	(ram_scrltmr),a
		cp	b
		jp	c,@end
		xor	a
		ld	(ram_scrltmr),a
		
		;Scroll up
		ld	a,(ram_vscroll)		; scroll vertically
		inc	a
		ld	(ram_vscroll),a
 		
		ld	a,(ram_scrlflag)
		inc	a
		ld      (ram_scrlflag),a
		bit 	4,a
		jp	z,@end
		ld	a,(ram_scrlpos)		; inc field pos
		inc	a
		cp	0Eh
		jp	c,@lowpos
		xor	a
@lowpos:
		ld      (ram_scrlpos),a
		call	Pon_Random		; generate new random
		call	Pon_DelNewLine		; scroll field and make new line
 		call	Pon_CheckBlocks		; check blocks
		call	Pon_Refresh		; refresh
		
		ld	a,(ram_ponflags)
		set 	bitDecCur,a
		ld      (ram_ponflags),a
		
		xor	a			; reset flag timer
		ld	(ram_scrlflag),a
@end:
; 		call	Pon_RotBg
		ret

; -------------------------

Pon_Controls:
		ld	a,(ram_joypads+on_press)
		ld	d,a
		
; ----------------
; RIGHT
; ----------------

		bit 	bitJoyRight,d
		jp	z,@not_right
		ld	a,(ram_poncurpos)
		inc 	a
		and 	0Fh
		cp	5
		jp	z,@not_right
		ld	b,a
		ld	a,(ram_poncurpos)
		and 	0F0h
		or	b
		ld	(ram_poncurpos),a
@not_right:

; ----------------
; LEFT
; ----------------

		bit 	bitJoyLeft,d
		jp	z,@not_left
		ld	a,(ram_poncurpos)
		dec	a
		and 	0Fh
		cp	0Fh
		jp	z,@not_left
		ld	b,a
		ld	a,(ram_poncurpos)
		and 	0F0h
		or	b
		ld	(ram_poncurpos),a
@not_left:

; ----------------
; UP
; ----------------

		bit 	bitJoyUp,d
		jp	z,@not_up
		ld	a,(ram_poncurpos)
		ld	b,a
		sub	10h
		ld	(ram_poncurpos),a
		ld	a,b
		and 	0F0h
		cp	0
		jp	nz,@not_up
		ld	a,b
		and	0Fh
		ld	(ram_poncurpos),a
@not_up:

; ----------------
; DOWN
; ----------------

		bit 	bitJoyDown,d
		jp	z,@not_down
		ld	a,(ram_poncurpos)
		add 	10h
		ld	b,a
		ld	c,080h
 		ld	a,(ram_ponflags)
 		bit 	bitFullField,a
 		jp	nz,@dont_inc
 		ld	a,c
 		add 	10h
 		ld	c,a
@dont_inc:
		ld	a,(ram_poncurpos)
		and	0F0h
		cp	c
		jp	z,@not_down
		
		ld	a,b
		ld	(ram_poncurpos),a
		ld	a,(ram_ponflags)
		res 	bitDecCur,a
		ld	(ram_ponflags),a
@not_down:
		call	Pon_Cursor

; ----------------

; ----------------
; Joy1
; ----------------

		ld	a,(ram_joypads+on_hold)
		bit 	bitJoy1,a
		jp	z,@not_Joy1
		xor 	a
		ld	(ram_pontimeout),a
		
@not_Joy1:
		ld	a,(ram_joypads+on_press)
		bit 	bitJoy2,a
		jp	z,@not_Joy2
		call	Pon_SwapBlocks
 		call	Pon_CheckBlocks
		call	Pon_Refresh
@not_Joy2:
		ret
		
; ====================================================================
; -------------------------
; Subs
; -------------------------

; -------------------------
;
; -------------------------

Pon_InitField:	
		ld	ix,ram_ponfield
		
		ld	b,6*8			;cleanup
@loop_1:
		ld	a,0
		ld	(ix),a
 		inc 	ix
 		djnz	@loop_1
 		
 		ld	c,3			;HEIGHT
@loop_3:
		ld	b,6			;WIDTH
		ld	d,0
@loop_2:
		ld	a,(ram_vintframes)
 		ld	e,a
 		ld	a,(ram_ponrand)
 		add 	e
 		ld	e,a
 		ld	a,(ram_ponrnd2)
 		rrca	a
 		inc 	a
 		ld	(ram_ponrnd2),a
 		add 	e
 		ld	(ram_ponrand),a
 		
 		and	7
 		jp	z,@loop_2
 		cp	6
 		jp	nc,@loop_2
 		cp	d
 		jp	z,@loop_2
 		ld	d,a
 		
		ld	(ix),a
 		inc 	ix
 		djnz	@loop_2
 		
		ld	a,(ram_vintframes)
		and	1Fh
 		ld	e,a
 		ld	a,(ram_ponrand)
 		add 	e
 		inc 	a
 		rrca	
 		ld	e,a
 		ld	a,(ram_ponrnd2)
 		rrca	a
 		inc 	a
 		ld	(ram_ponrnd2),a
 		add 	e
 		dec 	c
 		jp	nz,@loop_3
 		
 		ld	a,(ram_vintwait)	; we are scrolling down
 		res 	bitVerDir,a
 		ld	(ram_vintwait),a
		ret
		
; -------------------------
;
; -------------------------

Pon_DelNewLine:
		ld	ix,ram_ponfield
		ld	iy,ram_ponfield+6
		ld	c,10
@next_y:
		ld	b,6
@next_x:
		ld	a,(iy)
		ld	(ix),a
		inc 	ix
		inc 	iy
		djnz	@next_x
		dec 	c
		jp	nz,@next_y
		
		ld	iy,ram_ponfield+(6*10)
		;make new line
		ld	b,6
		ld	d,0
@newext_x:
 		ld	a,(ram_vintframes)
 		ld	c,a
 		ld	a,(ram_ponrand)
 		rlca
 		add 	c
 		ld	c,a
 		ld	a,(ram_ponrnd2)
 		rrca
 		add 	c
 		ld	(ram_ponrnd2),a
 		add 	c
 		ld	(ram_ponrand),a
 		
 		and	7
 		jp	z,@newext_x
 		cp	6
 		jp	nc,@newext_x
 		cp	d
 		jp	z,@newext_x
 		ld	d,a
 		
 		ld	a,(iy)
 		cp	d
 		jp	z,@newext_x
 		
 		ld	a,d
		ld	(ix),a
		inc 	ix
		inc 	iy
		djnz	@newext_x
		ret
	
; -------------------------
;
; -------------------------

Pon_Random:
		ld	a,(ram_vintframes)
		ld	b,a
		ld	a,(ram_ponrand)
		add 	b
		ld	(ram_ponrand),a
		ret
		
; -------------------------
;
; -------------------------

Pon_Refresh:
		di				;TODO: no mames. mejorar esto despues
		ld	ix,ram_ponfield
		ld	bc,0
		ld	de,0
		ld	a,(ram_scrlpos)
		sla	a
		sla	a
		sla	a
		sla	a
		sla	a
		sla	a
		sla	a
		ld	l,a
  		ld	a,(ram_scrlpos)
  		srl	a
  		and 	7
  		or	38h
  		ld	h,a
		
		ld	c,11
@next_y:
		push	hl
		ld	b,6
@next_x:
		ld	a,(ix)
		and 	7Fh
		ld	e,a
		inc	ix
		push	bc
		push	hl
		call	draw_block
		pop	hl
		ld	de,4
		add 	hl,de
		pop	bc
		djnz	@next_x
		
		pop	hl
		ld	de,80h
		add 	hl,de
		ld	a,h
		cp	3Fh
		jp	nz,@not_top
		ld	a,38h
@not_top:
 		ld	h,a
		dec 	c
		jp	nz,@next_y
		ei				;TODO: no mames. mejorar esto despues
		ret
		
; -------------------------

draw_block:
		ld	d,08h		;xx00 pal 2
		ld	a,e
		cp	0
		jp	nz,@notzero
		ld	d,0
@notzero:
		sla	a
		sla	a
		or	80h		;at xx80h
		ld	e,a
		
		;TOP PIECES
		ld      a,l
		out     (Vcom),a
		ld      a,h
		or      Writemask
		out     (Vcom),a
		ld      a,e		;X-
		out     (Vdata),a
		ld      a,d
		out     (Vdata),a
		inc 	de
		ld      a,e		;X-
		out     (Vdata),a
		ld      a,d
		out     (Vdata),a
		inc 	de
		
		;BOTTOM PIECES
		ld	bc,40h
		add	hl,bc
		ld	a,h
		and	3Fh
		ld	h,a
		
		ld      a,l            ; 1st 8 bits
		out     (Vcom),a
		ld      a,h            ; 2nd 8 bits
		or      Writemask      ; set write mode
		out     (Vcom),a
		ld      a,e		;X-
		out     (Vdata),a
		ld      a,d
		out     (Vdata),a
		inc 	de
		ld      a,e		;X-
		out     (Vdata),a
		ld      a,d
		out     (Vdata),a
		inc 	de
		ret
		
; -------------------------
;
; -------------------------

Pon_Cursor:
		ld	ix,ram_sprbuffer
		ld	c,0A4h
		ld	a,(ram_poncurpos)
		ld	b,a
		and 	0F0h
		add 	18h
		ld	d,a
		ld	a,b
		and	0F0h
; 		cp	0
; 		jp	z,@zeroy
		
		ld	a,(ram_ponflags)
		bit 	bitDecCur,a
		jp	z,@dont_dec
		ld	a,(ram_poncurpos)
		cp	0
		jp	z,@itsonz
		sub 	10h
		ld	(ram_poncurpos),a
@itsonz:
		and 	0F0h
		add 	18h
		ld	d,a
		ld	a,(ram_ponflags)
		res 	bitDecCur,a
		ld	(ram_ponflags),a
@dont_dec:
		
 		ld	a,(ram_scrlflag)
 		cpl
 		ld	b,a
 		ld	a,d
 		add 	b
 		ld	d,a
;  		cp	18h
;  		jp	nc,@zeroy
;  		ld	a,(ram_poncurpos)
;  		and 	00Fh
;  		ld	(ram_poncurpos),a
;  		ld	d,18h
@zeroy:

		ld	a,(ram_poncurpos)
		sla	a
		sla	a
		sla	a
		sla	a
		add 	30h
		ld	e,a
		
		ld	a,d
		ld	(ix),a
		ld	a,e
		ld	(ix+1),a
		ld	a,c
		ld	(ix+2),a
		inc 	ix
		inc	ix
		inc 	ix
		ld	a,d
		ld	(ix),a
		ld	a,e
		add 	18h
		ld	(ix+1),a
		ld	a,c
		inc 	a
		ld	(ix+2),a
		inc 	ix
		inc	ix
		inc 	ix
		
		ld	a,d
		add 	8h
		ld	(ix),a
		ld	a,e
		ld	(ix+1),a
		ld	a,c
		add 	2
		ld	(ix+2),a
		inc 	ix
		inc	ix
		inc 	ix
		ld	a,d
		add 	8h
		ld	(ix),a
		ld	a,e
		add 	18h
		ld	(ix+1),a
		ld	a,c
		add 	3
		ld	(ix+2),a
		inc 	ix
		inc	ix
		inc 	ix
		
		ret
		
; -------------------------
;
; -------------------------

Pon_SwapBlocks:
		ld	ix,ram_ponfield
		ld	de,0
		ld	a,(ram_poncurpos)
		and 	00Fh
		ld	e,a
		add 	ix,de
		ld	a,(ram_poncurpos)
		rrca
		rrca
		rrca
		rrca
		and 	00Fh
		jp	z,@nxtzero
		ld	c,a
@nxtline_y:
		ld	b,6
@nxtline_x:
		inc 	ix
		djnz	@nxtline_x
		dec 	c
		jp	nz,@nxtline_y
@nxtzero:

		ld	a,(ix)
		ld	b,a
		ld	a,(ix+1)
		ld	(ix),a
		ld	a,b
		ld	(ix+1),a
		ret

; -------------------------
;
; -------------------------

Pon_CheckBlocks:

		;horizontally
			
 		ld	ix,ram_ponfield
 		ld	iy,ram_ponfield+1
  		ld 	c,9
@next_line_x:
		push 	ix
		push 	iy
 		ld	b,6-1
@nxt_first:
		push 	iy
 		ld	e,(ix)
 		ld	a,e
 		cp	0
 		jp	z,@not_equ
@equ_next:
 		ld	d,(iy)
 		ld	a,e
 		cp	d
 		jp	nz,@not_equ
 		
 		ld	a,(ix)
 		set 	7,a
 		ld	(ix),a
 		ld	a,(iy)
 		set 	7,a
 		ld	(iy),a

 		inc 	iy
 		ld 	a,b
 		cp	1
 		jp	z,@not_equ
 		jp	@equ_next 		
@not_equ:
 		inc 	ix
 		pop	iy
 		inc 	iy
		djnz 	@nxt_first
		
		pop 	iy
		pop	ix
		ld 	de,6
		add 	ix,de
		add 	iy,de
		dec 	c
		jp	nz,@next_line_x
	
; -------------------------

;   		;vertically
  		ld	ix,ram_ponfield
  		ld	iy,ram_ponfield+6		;+width
  		ld 	c,6
@next_line_y:
		push 	ix
		push 	iy
  		ld	b,(9)-1
@nxtv_first:
  		push	iy
		ld	e,(ix)
		ld	a,e
 		cp	0
 		jp	z,@not_equv
@equv_next:
 		ld	d,(iy)
 		ld	a,e
 		cp	d
 		jp	nz,@not_equv
 		
 		ld	a,(ix)
 		set 	7,a
 		ld	(ix),a
 		ld	a,(iy)
 		set 	7,a
 		ld	(iy),a
 		
  		push	de
 		ld	de,6
 		add 	iy,de
 		pop	de
    		ld 	a,b
    		cp	1
    		jp	z,@not_equv
  		jp	@equv_next
@not_equv:
 		ld	de,6
 		add 	ix,de
 		pop	iy
 		add 	iy,de
 		djnz 	@nxtv_first
		
		pop 	iy
		pop	ix
		inc 	ix
		inc 	iy
		dec 	c
		jp	nz,@next_line_y
		
; -------------------------

		;check top 
		
		ld	hl,ram_ponfield
		ld	b,6
		ld	a,(ram_ponflags)
		ld	c,a
		ld	a,(ram_scrlflag)
		ld	d,a
		res 	bitFullField,c
@next:
		ld	a,(hl)
		cp	0
		jp	z,@dont_set
		set 	bitFullField,c
		ld	b,0
		ld	a,d
		xor	a
		ld	d,a
@dont_set:
		inc 	hl
   		djnz	@next
		
		ld	a,c
		ld	(ram_ponflags),a
		ld	a,d
		ld	(ram_scrlflag),a
		
; -------------------------

		;delete the ones set
		
		ld	hl,ram_ponfield
		ld	b,6*9
@nextvalid:
		ld	a,(hl)
		bit 	7,a
		jp	z,@stay
		xor 	a
		ld	(hl),a
		ld	a,7Fh
		ld	(ram_pontimeout),a
@stay:
		inc 	hl
		djnz 	@nextvalid
		
; -------------------------

		ret
		
; -------------------------
;
; -------------------------

Pon_InitBg:
		ld	hl,screen+18h
		ld	de,40h
		ld	c,1Ch
@loop_y:
		push	hl
		
		ld	a,l
		out 	(Vcom),a
		ld	a,h
		or	Writemask
		out 	(Vcom),a
		ld	a,0AEh
		out 	(Vdata),a
		xor	a
		out 	(Vdata),a
		
		ld	de,0Eh
		add 	hl,de
		
		ld	a,l
		out 	(Vcom),a
		ld	a,h
		or	Writemask
		out 	(Vcom),a
		ld	a,0AFh
		out 	(Vdata),a
		xor	a
		out 	(Vdata),a
		
		pop	hl
		ld	de,40h
		add 	hl,de
		
		dec	c
		jp	nz,@loop_y
 		ret
	
; -------------------------
;
; -------------------------

Pon_RotBg:
		ld	a,(ram_scrlflag)
		and	7
		sla	a
		sla	a
		sla	a
		sla	a
		sla	a
		ld	de,0
		ld	e,a
		
		ld	hl,1400h;1400h
		ld	a,l
		out 	(Vcom),a
		ld	a,h
		or	Writemask
		out 	(Vcom),a
		
		ld	ix,art_ponbg
		add 	ix,de
		ld	b,20h
@loop:
		ld	a,(ix)
		out 	(Vdata),a
		inc 	ix
		djnz	@loop
		
		ret
		
; -------------------------
; Pon_MakeHudSpr
; 
; hl - data
; -------------------------

Pon_MakeHudSpr:
		ld	ix,ram_sprbuffer+4*3
		
;  		ld	hl,data_topbrd
;  		ld	de,9018h	
;  		call	@print_spr
;  		ld	hl,data_botbrd
;  		ld	de,90A0h	
;  		call	@print_spr
		
		ld	hl,str_score
		ld	de,9828h
		call	@print_spr
		ld	hl,str_time
		ld	de,9858h
		call	@print_spr
		
  		ld	hl,str_zeros
  		ld	de,9838h	
  		call	@print_spr
  		ld	hl,str_zerot
		ld	de,9868h	
;   		call	@print_spr
; 		ret
		
		
@print_spr:
		ld	a,(hl)
		cp 	0
		jp	z,@end
		ld	b,a
		ld	a,e
		ld	(ix),a
		ld	a,d
		ld	(ix+1),a
		ld	a,b
		ld	(ix+2),a
		inc 	ix
		inc 	ix
		inc 	ix
		inc 	hl
		ld	a,d
		add 	8
		ld	d,a
		jp	@print_spr
@end
		ret
		
; ====================================================================
; -------------------------
; Data
; -------------------------

str_score:	db "SCORE",0
str_time:	db "TIME",0
str_zeros:	db "000000",0
str_zerot:	db "00:00",0

data_topbrd:	db 0A8h,0A9h,0A9h,0A9h,0A9h,0A9h,0A9h,0AAh,0
data_botbrd:	db 0ABh,0ACh,0ACh,0ACh,0ACh,0ACh,0ACh,0ADh,0
