; =================================================================
; Object system
; =================================================================

; =================================================================
; ------------------------------------------------
; Settings
; ------------------------------------------------

max_objects	equ	16

; =================================================================
; ------------------------------------------------
; Variables
; ------------------------------------------------
	
		rsreset
obj_code	rw 1
obj_size	rb 4			; left/right/up/down
obj_x		rw 2
obj_y		rw 2
obj_x_spd	rw 1
obj_y_spd	rw 1
obj_frame	rw 1			; current/old
obj_indx	rb 1
obj_anim_next	rb 1
obj_anim_id	rb 1
obj_anim_id_old	rb 1
obj_anim_spd	rb 1
obj_status	rb 1
obj_col		rb 1			;%LLRRUUDD
sizeof_obj	rb 0

; --------------------------------
; obj_status
; --------------------------------

bitobj_dir	equ	0		; set for Left
bitobj_air	equ	1		; set for Jumping
bitobj_solid	equ	2		; set to make it solid

; =================================================================
; ------------------------------------------------
; Subs
; ------------------------------------------------

objects_init:
 		ld	a,0C3h
 		ld	(ram_objjmpto),a
 		
 		;TODO: clear objects
   		ret

; ------------------------------------------------

objects_run:
		ld	iy,ram_objbuffer
   		ld	b,max_objects
   		
@next_obj:
   		ld	d,(iy+obj_code)
   		ld	e,(iy+(obj_code+1))
   		ld	a,d
   		or	e
   		jp	z,@nothing
   		ld	a,d
   		ld	(ram_objjmpto+1),a
   		ld	a,e
   		ld	(ram_objjmpto+2),a
   		
   		push	bc
    		call	ram_objjmpto
   		pop	bc
@nothing:
   		ld	de,sizeof_obj
   		add	iy,de
   		djnz	@next_obj
		
   		ret
 
; =================================================================
; ------------------------------------------------
; Subs
; ---------------------------------------------

; --------------------------------
; object_dplc
; 
; hl - art data
; de - plc data
; bc - vram
; --------------------------------

object_dplc:
		push	hl
		push	bc
		ld	h,d
		ld	l,e
		ld	a,c
  		ld	bc,0
  		ld	c,a
  		add	hl,bc
  		ld	d,h
  		ld	e,l
  		pop	bc
  		pop	hl
  		
   		bit	bitobj_dir,(iy+obj_status)
   		jp	z,@right
   		inc 	hl
   		inc 	hl
@right:
   		ld	a,(hl)
   		inc 	hl
   		ld	h,(hl)
   		ld	l,a
   		
  		ld	a,(de)
  		rrca
  		rrca
  		rrca
  		and	11100000b
  		ld	c,a
  		ld	a,(de)
  		rrca
  		rrca
  		rrca
  		and	00011111b
  		ld	b,a
   		add	hl,bc
   		
   		inc 	de
  		ld	a,(de)
  		rrca
  		rrca
  		rrca
  		and	11100000b
  		ld	c,a
  		ld	a,(de)
  		rrca
  		rrca
  		rrca
  		and	00011111b
   		ld	b,a
		
		ld	de,ram_tilestovdp
		ld	bc,19Fh
		ldir
 		
@sameframe:
  		ret
  		
; 		; Start copying
; 		ld	a,(de)
; 		ld	b,a
; @next:
; 		call	@line
;  		djnz	@next
; 		ret
; 		
; @line:
; 		rept 8
; 		ld	c,(hl)		;this is litearly sonic1s tiledata-to-registers
; 		inc 	hl
; 		ld	d,(hl)
; 		inc 	hl
; 		ld	e,(hl)
; 		inc 	hl
; 		ld	a,c
; 		out     (Vdata),a
; 		ld	a,d
; 		out     (Vdata),a
; 		ld	a,e
; 		out     (Vdata),a
; 		ld	a,(hl)
; 		inc 	hl
; 		out     (Vdata),a
; 		endr
; 		ret
		
; --------------------------------
; object_show
; 
; hl - map data
; de - vram | frame
; --------------------------------

object_show:
		ld	a,e
		add 	a
		ld	bc,0
		ld	c,a
		add	hl,bc
		
		ld	b,(hl)
		inc 	hl
		ld	c,(hl)
		ld	h,c
		ld	l,b

		ld	ix,(RAM_SprControl)
		ld	b,(hl)
		inc 	hl
@next_piece:
		call	@dopiece
		djnz	@next_piece
		
		xor	a
		ld	(ix),a
		ld	(ix+2),a
		ld	(ix+3),a
		ld	(RAM_SprControl),ix
		ret

; ---------------

@dopiece:

; ---------------
; Y POS
; ---------------

		push	de
 		ld	a,(hl)
		ld	d,a
		ld	a,(RAM_VdpRegs+1)
		bit 	0,a
		jp	z,@norml_y
		sla	d
@norml_y:
		ld	a,d
 		inc	hl
 		push	hl
 		ld	hl,0
 		bit 	7,a
 		jp	z,@plusy
 		ld	hl,-1
@plusy:
 		ld	l,a
 		ld	d,(iy+(obj_y+1))
 		ld	e,(iy+obj_y)
 		inc 	de
 		add 	hl,de
 		ld	de,40h
 		add 	hl,de
 		ld	a,(RAM_LevelBuffer+(lvl_y+1))
 		ld	d,a
 		ld	a,(RAM_LevelBuffer+(lvl_y))
 		ld	e,a
 		scf
 		sbc 	hl,de
 		
  		ld	a,h
  		cp 	0
  		jp	z,@lower
  		ld	l,0
@lower:
		ld	a,l
		ld	(ix),a
		inc 	ix
		pop	hl
		
; ---------------
; X POS
; ---------------

		ld	a,(hl)
		ld	d,a
		ld	a,(RAM_VdpRegs+1)
		bit 	0,a
		jp	z,@norml_x
		sla	d
@norml_x:
		ld	a,d
 		inc	hl
 		push	hl
 		
 		bit	bitobj_dir,(iy+obj_status)
 		jp	z,@right
 		neg 	a
 		add 	8
@right:
  		ld	hl,0
  		bit 	7,a
		jp	p,@plus
  		ld	hl,-1
@plus:
 		ld	l,a
 		ld	d,(iy+(obj_x+1))
 		ld	e,(iy+obj_x)
 		add 	hl,de
 		ld	a,(RAM_LevelBuffer+(lvl_x+1))
 		ld	d,a
 		ld	a,(RAM_LevelBuffer+(lvl_x))
 		ld	e,a
 		scf
 		sbc 	hl,de

  		ld	a,h
  		cp 	0
  		jp	z,@notsame
  		ld	l,0
  		dec 	ix
  		xor	a
  		ld	(ix),a
  		inc 	ix
@notsame:
		
		ld	a,l
		ld	(ix),a
		inc 	ix
   		pop	hl
		pop	de
		
; ---------------
; CHAR
; ---------------

		ld	a,(hl)
		inc 	hl
		add	a,d
		ld	(ix),a
		inc 	ix

; ---------------
		ret


; ----------------------------------------------
; Object animation
; 
; Input
; hl - Animation data
; 
; Output
; a - Frame
; 
; Uses:
; c/de
; ----------------------------------------------
 
Object_Animate:
		ld	c,(iy+(obj_anim_id+1))
		ld	a,(iy+(obj_anim_id))
		cp	c
		jp	z,@SameThing
		ld	(iy+(obj_anim_id+1)),a
		xor	a
		ld	(iy+(obj_anim_next)),a
@SameThing:
		ld	a,(iy+(obj_anim_id))
		cp	-1
		jp	z,@Return
		add 	a
		ld	de,0
		ld	e,a
		add 	hl,de
		
		ld	a,(hl)
		inc 	hl
		ld	h,(hl)
		ld	l,a
 
		ld	a,(hl)
		inc 	hl
		ld	b,a
		ld	a,(iy+(obj_anim_spd))
		dec	a
		ld	(iy+(obj_anim_spd)),a
		jp	p,@Return
		ld	(iy+(obj_anim_spd)),b
			
		ld	de,0
		ld 	a,(iy+(obj_anim_next))
		ld	e,a
		ld	a,(hl)
		ld	c,a
		add 	hl,de
		
		ld	a,(hl)
		inc 	hl
		cp	0FFh
		jp	z,@NoAnim
		cp	0FEh
		jp	z,@GoToFrame
		cp	0FDh
		jp	z,@LastFrame

		ld	(iy+(obj_frame)),a
		inc 	(iy+(obj_anim_next))
@Return:
		ret 
  
@NoAnim:
		ld	a,1
		ld	(iy+(obj_anim_next)),a
		ld	a,c
		ld	(iy+(obj_frame)),a
		ret
		
@LastFrame:
		xor	a
		ld	(iy+(obj_anim_spd)),a
		ret 
		
@GoToFrame:
		xor	a
		ld	(iy+(obj_anim_next)),a
		inc 	hl
		ld	a,(hl)
		ld	(iy+(obj_anim_next+1)),a
		ret
		
; ----------------------------------------------
; Object Collision
; ----------------------------------------------

; ************************
; Find floor collision
; CENTER
; 
; Input:
; iy - Object
; ix - RAM_LevelBuffer
; hl - collision data
; 
; Output:
; a - CENTER
; ************************

object_FindPrz_Floor:
		push	hl
		ld	ix,ram_levelbuffer
		ld	hl,RAM_LevelPrizes
		call	objSearchCol_Floor
		pop	hl
		ret
		
object_FindCol_Floor:
		push	hl
		ld	ix,ram_levelbuffer
		ld	h,(ix+(lvl_collision+1))
		ld	l,(ix+(lvl_collision))
		call	objSearchCol_Floor
		pop	hl
		ret
		
objSearchCol_Floor:
; 		Y-pos
		ld	bc,0
 		ld	a,(iy+(obj_y))
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	c,a
 		ld	d,(iy+(obj_y+1))
		xor	a
		bit 	7,d
		jp	nz,@no_col
		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0F0h
  		or	c
  		ld	c,a
		
 		ld	d,(ix+(lvl_x_size+1))
		ld	e,(ix+(lvl_x_size))
@county:
   		add	hl,de
 		dec	c
 		jp	nz,@county
		
; 		X-pos
		xor	a
 		ld	d,(iy+(obj_x+1))
  		bit 	7,d
  		jp	nz,@no_col
 		ld	a,(iy+(obj_x))
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	e,a
 		ld	a,(iy+(obj_x+1))
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0F0h
  		or	e
  		ld	e,a
 		ld	a,(iy+(obj_x+1))
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	d,a
		add 	hl,de
		;Return
 		ld	a,(hl)
@no_col:
 		ret 

; ************************
; Find wall collision
; CENTER
; 
; Input:
; iy - Object
; ix - RAM_LevelBuffer
; hl - collision data
; 
; Output:
; a - CENTER
; ************************

object_FindPrz_Wall:
		push	hl
		ld	ix,ram_levelbuffer
		ld	hl,RAM_LevelPrizes
		call	objSearchCol_Wall
		pop	hl
		ret
		
object_FindCol_Wall:
		push	hl
		ld	ix,ram_levelbuffer
		ld	h,(ix+(lvl_collision+1))
		ld	l,(ix+(lvl_collision))
		call	objSearchCol_Wall
		pop	hl
		ret
		
objSearchCol_Wall:
; 		Y-pos
		ld	bc,0
 		ld	d,(iy+(obj_y+1))
 		ld	e,(iy+(obj_y))
 		dec	de
 		ld	a,1
 		bit 	7,d
 		jp	nz,@no_col
 		ld	a,e
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	c,a
		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0F0h
  		or	c
  		ld	c,a
		
 		ld	d,(ix+(lvl_x_size+1))
		ld	e,(ix+(lvl_x_size))
@county:
   		add	hl,de
 		dec	c
 		jp	nz,@county
		
; 		X-pos
  		ld	a,1
 		ld	d,(iy+(obj_x+1))
  		bit 	7,d
  		jp	nz,@no_col
 		ld	a,(iy+(obj_x))
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	e,a
 		ld	a,(iy+(obj_x+1))
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0F0h
  		or	e
  		ld	e,a
 		ld	a,(iy+(obj_x+1))
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	d,a
		add 	hl,de
		;Return
 		ld	a,(hl)
@no_col:
 		ret 
 		
; ************************
; Find floor collision
; LEFT/RIGHT
;
; Input:
; iy - Object
; ix - RAM_LevelBuffer
; hl - collision data
; 
; Output:
; b | RIGHT
; c | LEFT
; 
; Uses:
; Stack, EXX
; ************************

object_FindPrz_FloorSides:
		push	hl
		ld	ix,ram_levelbuffer
		ld	hl,RAM_LevelPrizes
		call	objSearchCol_FloorSides
		pop	hl
		ret
		
object_FindCol_FloorSides:
		push	hl
		ld	ix,ram_levelbuffer
		ld	h,(ix+(lvl_collision+1))
		ld	l,(ix+(lvl_collision))
		call	objSearchCol_FloorSides
		pop	hl
		ret
		
objSearchCol_FloorSides:
; 		Y-pos
		ld	bc,0
 		ld	a,(iy+(obj_y))
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	c,a
 		ld	d,(iy+(obj_y+1))
		xor	a
		bit 	7,d
		jp	nz,@no_col
		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0F0h
  		or	c
  		ld	c,a
  		
 		ld	d,(ix+(lvl_x_size+1))
		ld	e,(ix+(lvl_x_size))
@county:
   		add	hl,de
 		dec	c
 		jp	nz,@county
		
; ------------------------
; X check
; LEFT
; ------------------------

 		push	hl
 		push	hl
 		
 		ld	h,(iy+(obj_x+1))
  		ld	l,(iy+(obj_x))
  		ld	de,1
  		add	hl,de
 		ld	a,(iy+(obj_size))
 		add 	a
 		add 	a
 		add 	a
  		ld	e,a
  		scf
 		sbc	hl,de
 		bit 	7,h
 		jp	nz,@bad_left
 		
  		ld	d,h
   		ld	e,l
  		
 		ld	a,e
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	l,a
 		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0F0h
  		or	l
  		ld	l,a
 		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	h,a
  		
  		ld	d,h
  		ld	e,l
  		pop	hl
 		add	hl,de
		
 		ld	a,(hl)
 		ld	c,a
 		jr	@good_left

@bad_left:
		ld	c,0
		pop	hl

@good_left:

; ------------------------
; X check
; RIGHT
; ------------------------
  		
 		ld	h,(iy+(obj_x+1))
 		ld	l,(iy+(obj_x))
 		dec	hl
 		ld	de,0
 		ld	a,(iy+(obj_size+1))
 		add 	a
 		add 	a
 		add 	a
  		ld	e,a
 		add	hl,de
  		ld	d,h
  		ld	e,l
 		bit 	7,h
 		jp	nz,@bad_right
 		
 		ld	a,e
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	l,a
 		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0F0h
  		or	l
  		ld	l,a
 		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	h,a
  		
  		ld	d,h
  		ld	e,l
  		pop	hl
		add 	hl,de
		
 		ld	a,(hl)
 		ld	b,a
 		ret 
 		
@bad_right:
		ld	b,0
  		pop	hl
  		
; ------------------------

@no_col:
		ret
		
		
; ************************
; Find wall collision
;
; Input:
; iy - Object
; ix - RAM_LevelBuffer
; hl - collision data
; 
; Output:
; b | RIGHT
; c | LEFT
; 
; Uses:
; Stack, EXX
; ************************

object_FindPrz_WallSides:
		push	hl
		ld	ix,ram_levelbuffer
		ld	hl,RAM_LevelPrizes
		call	objSearchCol_WallSides
		pop	hl
		ret
		
object_FindCol_WallSides:
		push	hl
		ld	ix,ram_levelbuffer
		ld	h,(ix+(lvl_collision+1))
		ld	l,(ix+(lvl_collision))
		call	objSearchCol_WallSides
		pop	hl
		ret
		
objSearchCol_WallSides:
; 		Y-pos
		ld	bc,0
 		ld	a,(iy+(obj_y))
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
 		ld	d,(iy+(obj_y+1))
		bit 	7,d
		jp	nz,@no_col
  		ld	c,a
		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0F0h
  		or	c
  		ld	c,a
  		dec 	c
  		
 		ld	d,(ix+(lvl_x_size+1))
		ld	e,(ix+(lvl_x_size))
@county:
   		add	hl,de
 		dec	c
 		jp	nz,@county
		
; ------------------------
; X check
; LEFT
; ------------------------

 		push	hl
 		push	hl
 		
 		ld	h,(iy+(obj_x+1))
  		ld	l,(iy+(obj_x))
  		ld	a,(iy+(obj_size))
  		add 	a
  		add 	a
  		add 	a
  		cpl
  		ld	d,-1
   		ld	e,a
   		inc 	de
 		add	hl,de
 		bit 	7,h
 		jp	nz,@bad_left
  		ld	d,h
   		ld	e,l
  		
 		ld	a,e
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	l,a
 		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0F0h
  		or	l
  		ld	l,a
 		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	h,a
  		
  		ld	d,h
  		ld	e,l
  		pop	hl
 		add	hl,de
		
 		ld	a,(hl)
 		ld	c,a
 		jr	@good_left

@bad_left:
		ld	c,1
		pop	hl

@good_left:

; ------------------------
; X check
; RIGHT
; ------------------------
  		
 		ld	h,(iy+(obj_x+1))
 		ld	l,(iy+(obj_x))
 		ld	de,0
 		ld	a,(iy+(obj_size+1))
 		add 	a
 		add 	a
 		add 	a
  		ld	e,a
 		add	hl,de
 		bit 	7,h
 		jp	nz,@bad_right
  		ld	d,h
  		ld	e,l
 		
 		ld	a,e
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	l,a
 		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0F0h
  		or	l
  		ld	l,a
 		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and	0Fh
  		ld	h,a
  		
  		ld	d,h
  		ld	e,l
  		pop	hl
		add 	hl,de
		
 		ld	a,(hl)
 		ld	b,a
 		ret 
 		
@bad_right:
		ld	b,1
  		pop	hl
  		
; ------------------------

@no_col:
		ret
		
; =================================================================
; ------------------------------------------------
; Includes
; ------------------------------------------------

		include	"modes/level/data/object/player/code.asm"
		