; ====================================================================
; -------------------------------------------------
; Level
; -------------------------------------------------

; -------------------------------------------------
; Include
; -------------------------------------------------

		include	"modes/level/subs/level.asm"

; -------------------------------------------------
; Vars
; -------------------------------------------------

; -------------------------------------------------
; RAM
; -------------------------------------------------

			rsset ram_modebuffer
ram_levelbuffer		rb (20h*2)

; -------------------------------------------------
; Init
; -------------------------------------------------

Level:
  		ld	b,ID_FadeOut
  		ld	de,1F00h
  		call	PalFade_Set
    		call	PalFade_Wait
 		
 		di
		call    screenoff
		call	VDP_ClearLayer
		
		bankdata BANK_Level
		
		ld      hl,pal_level_test
		ld	b,32
		ld	c,0
 		call	PalFade_Load
		ld	hl,art_level_test
		ld	de,0
		ld	bc,100h*20h
		call	WriteVRAM
		
		call	level_init
		ld	hl,test_level
		ld	bc,0
		ld	de,0
		call	level_load
		call	level_draw
		call    screenon
		ei

  		ld	b,ID_FadeIn
  		ld	de,1F00h
  		call	PalFade_Set
   		call	PalFade_Wait
   		
; -------------------------------------------------
; Loop
; -------------------------------------------------

level_loop:
		call    vsync
  		
		ld	iy,ram_levelbuffer

; --------------	
; RIGHT
; --------------

		ld	a,(ram_joypads+on_hold)
		bit 	bitJoyRight,a
		jr      z,@NotRight
 		ld      b,(iy+(lvl_x+1))
 		ld      c,(iy+(lvl_x))
 		inc	bc
 		
 		ld	a,(iy+(lvl_x_size))
 		srl	a
 		srl	a
 		srl	a
 		srl	a
 		ld	h,a
  		ld	a,(iy+(lvl_x_size+1))
  		and 	0F0h
  		ld	l,a
  		if MERCURY
 		ld	de,(160)-1
 		else
 		ld	de,(256-8)-1
 		endif
 		sbc	hl,de
   		ld	a,h
    		cp	b
    		jp	nz,@cont_x_r
   		ld	a,l
    		cp	c
    		jp	nz,@cont_x_r 		
    		jr	@NotRight
@cont_x_r:
 		ld      (iy+(lvl_x+1)),b
 		ld      (iy+(lvl_x)),c
		ld	a,(iy+(lvl_drawdir))
 		set 	bit_drw_r,a
		ld	(iy+(lvl_drawdir)),a
 		
		ld      a,(ram_hscroll)
		dec     a			; move right
		ld      (ram_hscroll),a 
@NotRight:

; --------------	
; LEFT
; --------------

		ld	a,(ram_joypads+on_hold)
		bit 	bitJoyLeft,a
		jr      z,@NotLeft
 		ld      b,(iy+(lvl_x+1))
 		ld      c,(iy+(lvl_x))
 		ld	a,c
 		or	b
 		jp	z,@NotLeft
 		dec	bc
 		ld      (iy+(lvl_x+1)),b
 		ld      (iy+(lvl_x)),c
		ld	a,(iy+(lvl_drawdir))
 		set 	bit_drw_l,a
		ld	(iy+(lvl_drawdir)),a
		
		ld      a,(ram_hscroll)
		inc     a			; move left
		ld      (ram_hscroll),a 
@NotLeft:

; --------------	
; DOWN
; --------------

		ld      hl,ram_vscroll
		
		ld	a,(ram_joypads+on_hold)
		bit 	bitJoyDown,a
		jr      z,@NotDown
 		ld      b,(iy+(lvl_y+1))
 		ld      c,(iy+(lvl_y))
 		inc	bc
 		
   		ld	a,(iy+(lvl_y_size))
   		if MERCURY
   		sub 	9
   		else
   		sub 	0Ch
   		endif
   		sla	a
   		sla	a
   		sla	a
   		sla	a
   		cp	c
   		jp	c,@NotDown
   		
 		ld      (iy+(lvl_y+1)),b
 		ld      (iy+(lvl_y)),c
		ld	a,(iy+(lvl_drawdir))
 		set 	bit_drw_d,a
		ld	(iy+(lvl_drawdir)),a
		
		ld      a,(hl)
		inc     a			; move down
		ld      (hl),a
 		ld	a,(ram_vintwait)
 		res 	bitVerDir,a
 		ld	(ram_vintwait),a
@NotDown:

; --------------	
; UP
; --------------

		ld	a,(ram_joypads+on_hold)
		bit 	bitJoyUp,a
		jr      z,@NotUp
 		ld      b,(iy+(lvl_y+1))
 		ld      c,(iy+(lvl_y))
 		ld	a,c
 		or	b
 		jp	z,@NotUp
 		dec	bc
 		ld      (iy+(lvl_y+1)),b
 		ld      (iy+(lvl_y)),c
		ld	a,(iy+(lvl_drawdir))
 		set 	bit_drw_u,a
		ld	(iy+(lvl_drawdir)),a
		
		ld      a,(hl)
		dec     a			; move up
		ld      (hl),a
 		ld	a,(ram_vintwait)
 		set 	bitVerDir,a
 		ld	(ram_vintwait),a
@NotUp:

; --------------
		
@ContScroll:
		call	level_run
		jp      level_loop		; loop

; -------------------------------------------------
; Subs
; -------------------------------------------------

RightPressed:

		ld      a,(hl)              ; a = value of horiz. shift
		dec     a                   ; dec by 1 to scroll right
		ld      (hl),a              ; save value
		ret
		
UpPressed:
		ld      hl,ram_vscroll       ; address of variable
		ld      a,(hl)              ; a = value of horiz. shift
		inc     a                   ; dec by 1 to scroll right
		ld      (hl),a              ; save value
		ret
		