; =================================================================
; Level system
; =================================================================

; ------------------------------------------------
; Variables
; ------------------------------------------------

max_lvlprz	equ	500h
max_lvlobj	equ	64

; -----------------------

			rsreset
lvl_x			rw	1
lvl_y			rw	1
lvl_x_size		rw	1
lvl_y_size		rw	1
lvl_past_x		rb	1
lvl_past_y		rb	1
lvl_layout		rw	1
lvl_blocks		rw	1
lvl_collision		rw	1
lvl_prizes		rw	1
lvl_objects		rw	1
lvl_drawdir		rb	1
lvl_prio		rb	1
sizeof_level		rb	0

; -----------------------

; lvl_prio
bit_split		equ	0

; -----------------------

; lvl_drawdir
bit_drw_r		equ	0
bit_drw_l		equ	1
bit_drw_d		equ	2
bit_drw_u		equ	3
; bit_drw_r_2p		equ	4
; bit_drw_l_2p		equ	5
; bit_drw_d_2p		equ	6
; bit_drw_u_2p		equ	7

; ; ------------------------------------------------
; ; RAM
; ; ------------------------------------------------
	
; ram_levelbuffer	rs.b (sizeof_level*2)

; =================================================================
; ------------------------------------------------
; Subs
; ------------------------------------------------

; ------------------------------------------------
; Level_load
;
; Set a level
; 
; Input:
; 
; [NORMAL]
; hl - level data
;	dw @floor
;	dw @interblocks
;	dw @collision
;	dw @objects
;	dw x_size
;	dw y_size
;	db settings
;	db 0
;	db (layout_data)
; bc - start at X position
; de - start at Y position
;
; [ALTERNATE]
; (nothing)
; ------------------------------------------------

level_load:
		ld	iy,ram_levelbuffer
		
		ld	(iy+(lvl_x+1)),b
		ld	(iy+(lvl_x)),c
		ld	(iy+(lvl_y+1)),d
		ld	(iy+(lvl_y)),e
		
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_blocks)),a
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_blocks+1)),a
		
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_collision)),a
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_collision+1)),a
	
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_prizes)),a
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_prizes+1)),a
		
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_objects)),a
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_objects+1)),a
		
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_x_size)),a
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_x_size+1)),a
		
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_y_size)),a
		ld	a,(hl)
		inc	hl
		ld	(iy+(lvl_y_size+1)),a
		
		ld	(iy+(lvl_layout+1)),h
		ld	(iy+(lvl_layout)),l	
		ret
		
; ----------------------------------	
; Redraw the level
; 
; Uses:
; iy
; ----------------------------------

level_draw:
		ld	a,(ram_levelbuffer+lvl_x)
		neg	a
		ld	(ram_hscroll),a
		ld	a,(ram_levelbuffer+lvl_y)
		ld	(ram_vscroll),a
		ld	a,(ram_vintwait)
		res	bitVerDir,a
		ld	(ram_vintwait),a
		
; ----------------------------------

		ld	ix,(ram_levelbuffer+lvl_layout)
		
		exx
		ld	hl,screen
		ld	bc,0
		ld	a,(ram_levelbuffer+lvl_x)
		sla	a
		ld	c,a
		add	hl,bc		;+X
		ld	bc,0
		ld	a,(ram_levelbuffer+lvl_y)
		sla	a
		sla	a
		sla	a
		sla	a
		sla	a
		sla	a
		ld	c,a
		add	hl,bc		;+Y
		ld	bc,0
		ld	b,h
		ld	c,l
		exx
		
		ld	c,10h
@x_loop:
		push	ix
		ld	b,0Eh
@y_loop:
 		ld	iy,(ram_levelbuffer+lvl_blocks)
 		ld	de,0
 		ld	a,(ix)
 		and	11100000b
 		srl	a
 		srl	a
 		srl	a
 		srl	a
 		srl	a
 		ld	d,a
 		ld	a,(ix)
 		sla	a
 		sla	a
 		sla	a
 		ld	e,a
 		add	iy,de

		exx
 		ld	a,l
  		out	(Vcom),a
  		ld	a,h
  		or	Writemask
  		out	(Vcom),a
  		ld	de,40h
   		add	hl,de
		exx
 		ld	a,(iy)
 		inc	iy
  		out	(Vdata),a
 		ld	a,(iy)
 		inc	iy
  		out	(Vdata),a
		inc	iy
		inc	iy
 		ld	a,(iy)
 		inc	iy
  		out	(Vdata),a
 		ld	a,(iy)
 		inc	iy
  		out	(Vdata),a
		dec 	iy
		dec	iy
		dec	iy
		dec	iy
		
		exx
 		ld	a,l
  		out	(Vcom),a
  		ld	a,h
  		or	Writemask
  		out	(Vcom),a
  		ld	de,40h
   		add	hl,de
		exx
 		ld	a,(iy)
 		inc	iy
  		out	(Vdata),a
 		ld	a,(iy)
 		inc	iy
  		out	(Vdata),a
		inc	iy
		inc	iy
 		ld	a,(iy)
 		inc	iy
  		out	(Vdata),a
 		ld	a,(iy)
 		inc	iy
  		out	(Vdata),a
  		
  		ld	de,(ram_levelbuffer+lvl_x_size)
  		add	ix,de
  		
		dec	b
  		jp	nz,@y_loop
  		pop	ix
  		ld	de,1
  		add	ix,de
  		
		exx
		inc	bc
		inc	bc
		inc	bc
		inc	bc
		ld	h,b
		ld	l,c
		exx
		dec	c
  		jp	nz,@x_loop
  		
; 		ld	ix,(ram_levelbuffer+lvl_layout)
; 		ld	hl,screen
; 	
; 		ld	c,1Ch
; @y_loop:
; 		push	hl
; 		push	ix
; 		ld	b,20h
; @x_loop:		
;  		ld	a,l
;  		out	(Vcom),a
;  		ld	a,h
;  		or	Writemask
;  		out	(Vcom),a
;  		
; 		ld	iy,(ram_levelbuffer+lvl_blocks)
; 		ld	a,(ix)
; 		sla	a
; 		sla	a
; 		sla	a		;*8
; 		ld	de,0
; 		ld	e,a
; 		add	iy,de
; 		
; 		bit 	0,c
; 		jp	z,@even_y
; 		inc	iy
; 		inc	iy
; @even_y:
; 
; 		bit 	0,b
; 		jp	z,@even_x
; 		ld	de,4
; 		add	iy,de
;  		inc	ix
; @even_x:
; 		ld	a,(iy)
; 		inc	iy
;  		out	(Vdata),a
; 		ld	a,(iy)
; 		inc	iy
;  		out	(Vdata),a
;  		
;  		inc	hl
;  		inc	hl
; 		djnz	@x_loop
; 		
; 		pop	ix
;   		pop	hl
;   		
;    		bit 	0,c
;    		jp	z,@odd_y
;    		ld	de,(ram_levelbuffer+lvl_x_size)
;    		add	ix,de
; @odd_y:
;   		ld	de,40h
;   		add	hl,de
;   		
; 		dec	c
; 		jp	nz,@y_loop
		
		ret
	
; =================================================================
; ------------------------------------------------
; Init
; ------------------------------------------------

level_init:
		ret
		
; =================================================================
; ------------------------------------------------
; Run
; ------------------------------------------------

level_run:
		ld	iy,ram_levelbuffer
		
; ----------------------------------		
; draw right
; ----------------------------------

		ld	a,(iy+(lvl_drawdir))
		bit 	bit_drw_r,a
		jp	z,@no_right
		res	bit_drw_r,a
		ld	(iy+(lvl_drawdir)),a
		
  		ld	a,(iy+(lvl_x+1))
  		ld	h,a
  		ld	a,(iy+(lvl_x))
  		ld	l,a
  		ld	de,8
  		add	hl,de
  		ld	d,h
  		ld	e,l
		
		ld	ix,(ram_levelbuffer+lvl_layout)
 		ld	bc,0Fh
 		add	ix,bc
 		
 		ld	bc,0
  		ld	a,d
  		srl	a
 		srl	a
  		srl	a
  		srl	a
  		ld	b,a
  		ld	a,d
  		and	0Fh
  		sla	a
  		sla	a
  		sla	a
  		sla	a
  		ld	c,a
   		ld	a,e
  		srl	a
  		srl	a
  		srl	a
  		srl	a
   		or	c
  		ld	c,a
  		add	ix,bc
		
		;VDP
		ld	hl,screen+3Eh
 		ld	a,(iy+(lvl_x))
 		srl	a
 		srl	a
 		srl	a
 		and	1Fh
 		sla	a
 		ld	bc,0
 		ld	c,a
 		add	hl,bc
 		ld	a,l
 		and	3Fh
 		ld	l,a
 		
		;ix - layout id

		ld	b,0Eh
@next_y_r:
		push	bc
		push	hl
 		ld	hl,(ram_levelbuffer+lvl_blocks)
 		ld	de,0
 		ld	a,(ix)
 		and	11100000b
 		srl	a
 		srl	a
 		srl	a
 		srl	a
 		srl	a
 		ld	d,a
 		ld	a,(ix)
 		sla	a
 		sla	a
 		sla	a
 		ld	e,a
 		add	hl,de

		ld	a,(ram_levelbuffer+(lvl_x))
		bit 	3,a
		jp	nz,@left_r
		ld	de,4
		add	hl,de
@left_r:
 		ld	b,h
 		ld	c,l
 		pop	hl
 		
		rept 2			;two times
 		ld	a,l
 		out	(Vcom),a
 		ld	a,h
   		or	Writemask
 		out	(Vcom),a
  		ld	a,(bc)
  		inc	bc
   		out	(Vdata),a
  		ld	a,(bc)
  		inc	bc
   		out	(Vdata),a
 		ld	de,40h
 		add	hl,de
 		endr
   		
   		ld	de,(ram_levelbuffer+lvl_x_size)
   		add	ix,de
  		
  		pop	bc
		djnz	@next_y_r
		
@no_right:

; ----------------------------------		
; draw left
; 
; TODO: this is the old
; render
; ----------------------------------

		ld	a,(ram_levelbuffer+(lvl_drawdir))
		bit 	bit_drw_l,a
		jp	z,@no_left
		res	bit_drw_l,a
		ld	(ram_levelbuffer+(lvl_drawdir)),a
			
 		; MASTER SYSTEM LEFT SCROLL
 		ld	ix,(ram_levelbuffer+lvl_layout)
  		ld	bc,0
  		
   		ld	a,(ram_levelbuffer+(lvl_x+1))
   		srl	a
  		srl	a
   		srl	a
   		srl	a
   		ld	b,a 		
   		ld	a,(ram_levelbuffer+(lvl_x+1))
   		and	0Fh
   		sla	a
   		sla	a
   		sla	a
   		sla	a
   		ld	c,a
    		ld	a,(ram_levelbuffer+(lvl_x))
   		srl	a
   		srl	a
   		srl	a
   		srl	a
    		or	c
   		ld	c,a
   		add	ix,bc
 		
 		;VDP
 		ld	hl,screen;+3Eh
  		ld	a,(ram_levelbuffer+(lvl_x))
  		dec	a
  		rrca
  		rrca
  		rrca
  		and	1Fh
  		sla	a
  		ld	b,0
  		ld	c,a
  		add	hl,bc
  		ld	a,l
  		and	3Fh
  		ld	l,a
  		
 		;ix - layout id
 
		push	iy
 		ld	b,0Eh
@next_y_l:
  		ld	iy,(ram_levelbuffer+lvl_blocks)
  		ld	de,0
  		ld	a,(ix)
  		and	11100000b
  		srl	a
  		srl	a
  		srl	a
  		srl	a
  		srl	a
  		ld	d,a
  		ld	a,(ix)
  		sla	a
  		sla	a
  		sla	a
  		ld	e,a
  		add	iy,de
  		
 		ld	a,(ram_levelbuffer+(lvl_x))
 		bit 	3,a
 		jp	z,@left_l
 		inc	iy
 		inc	iy
 		inc	iy
 		inc	iy
@left_l:
 		ld	a,l
  		out	(Vcom),a
  		ld	a,h
    		or	Writemask
  		out	(Vcom),a
  		ld	de,40h
  		add	hl,de
  		
   		ld	a,(iy)
   		inc	iy
    		out	(Vdata),a
   		ld	a,(iy)
   		inc	iy
    		out	(Vdata),a
  		
  		ld	a,l
  		out	(Vcom),a
  		ld	a,h
    		or	Writemask
  		out	(Vcom),a
  		ld	de,40h
  		add	hl,de
  		
   		ld	a,(iy)
   		inc	iy
    		out	(Vdata),a
   		ld	a,(iy)
   		inc	iy
    		out	(Vdata),a
    		
    		ld	de,(ram_levelbuffer+lvl_x_size)
    		add	ix,de
   		
 		djnz	@next_y_l
		pop	iy
@no_left:

		
; ----------------------------------		
; draw down
; ----------------------------------

		ld	a,(iy+(lvl_drawdir))
		bit 	bit_drw_d,a
		jp	z,@no_down
		res	bit_drw_d,a
		ld	(iy+(lvl_drawdir)),a
@no_down:

; ----------------------------------		
; draw up
; ----------------------------------

		ld	a,(iy+(lvl_drawdir))
		bit 	bit_drw_u,a
		jp	z,@no_up
		res	bit_drw_u,a
		ld	(iy+(lvl_drawdir)),a
@no_up:
 		
; ----------------------------------

   		ret
   
; =================================================================
; ------------------------------------------------
; Subs
; ------------------------------------------------
     		
; =================================================================
; ------------------------------------------------
; Data
; ------------------------------------------------

col_SlopeData:
		db 000h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
		db 000h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
		db 00Fh,0Eh,0Dh,0Ch,0Bh,0Ah,09h,08h,07h,06h,05h,04h,03h,02h,01h,00h	;02
		db 000h,01h,02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh
		db 00Fh,0Fh,0Eh,0Eh,0Dh,0Dh,0Ch,0Ch,0Bh,0Bh,0Ah,0Ah,09h,09h,08h,08h
		db 007h,07h,06h,06h,05h,05h,04h,04h,03h,03h,02h,02h,01h,01h,00h,00h
		db 008h,08h,09h,09h,0Ah,0Ah,0Bh,0Bh,0Ch,0Ch,0Dh,0Dh,0Eh,0Eh,0Fh,0Fh
		db 000h,00h,01h,01h,02h,02h,03h,03h,04h,04h,05h,05h,06h,06h,07h,07h
		
		db 001h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h
		db 001h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h
		db 001h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h
		db 001h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h
		db 001h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h
		db 001h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h
		db 001h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h
		db 001h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h

		