; =================================================================
; Player object
; =================================================================

; C2DD

obj_test:
		ld	a,(iy+obj_indx)
		sla	a
		ld	bc,0
		ld	c,a
		ld	hl,@list
 		add 	hl,bc
		jp	(hl)
; -------------------------------------------------

@list:
		jr	@init
		jr	@main
	
; =================================================================
; ------------------------------------------------
; Index $00: Main
; ------------------------------------------------

@init:
		xor	a
		ld	(iy+obj_x),a
		ld	(iy+obj_y),a
		
		ld	de,0101h
		ld	(iy+(obj_size)),d
		ld	(iy+(obj_size+1)),e
		
		ld	a,(iy+obj_indx)
		inc	a
		ld	(iy+obj_indx),a
		jp	@render
		
; =================================================================
; ------------------------------------------------
; Index $01: Main
; ------------------------------------------------

@main:
		ld	a,(ram_joypads+on_hold)
		bit 	bitJoy1,a
		jp	nz,@debug_mode

; ----------------------------------
; Player
; ----------------------------------

		bit	bitobj_air,(iy+obj_status)
		jp	z,@idleanim

		ld	h,(iy+(obj_y_spd+1))
		ld	l,(iy+(obj_y_spd))
		ld	a,h
		or	l
		jp	z,@idleanim
		bit 	7,h
		jp	nz,@idleanim

  		ld	a,3
   		ld	(iy+obj_anim_id),a
  		
@idleanim:

; ----------------------------------
; Player physics
; ----------------------------------

; ***************
; X Speed stuff
; ***************

		ld	h,(iy+(obj_x_spd+1))
		ld	l,(iy+(obj_x_spd))
		call	@Player_Friction
		call	@Player_Walk
		push	hl
		call	@update_xspd
		exx
		pop	bc
		exx
		call	@Collision_Wall
; 		call	@ObjCol_Wall
		
; ***************
; Y Speed stuff
; ***************

		ld	h,(iy+(obj_y_spd+1))
		ld	l,(iy+(obj_y_spd))
		call	@Player_Jump
		push	hl
		call	@update_yspd
		exx
		pop	de
 		ld	a,d
		exx
 		jp	m,@minusy
 		call	@Collision_Floor
; 		call	@ObjCol_Floor
@minusy:
		exx
 		ld	a,d
		exx
 		jp	z,@zeroy
		
    		call	@Collision_Ceiling
; 		call	@ObjCol_Ceiling
@zeroy:

; ***************
; Save them
; ***************

		exx
		ld	(iy+(obj_x_spd+1)),b
		ld	(iy+(obj_x_spd)),c
 		ld	(iy+(obj_y_spd+1)),d
 		ld	(iy+(obj_y_spd)),e
		exx
		
; ------------------------
; Animation ID
; ------------------------

 		bit	bitobj_air,(iy+obj_status)
 		jp	nz,@air
 		ld	c,1
 		ld	b,(iy+(obj_x_spd+1))
 		ld	a,(iy+(obj_x_spd))
 		or	b
 		jp	nz,@walking
 		ld	c,0
@walking:
 		ld	a,c
 		ld	(iy+obj_anim_id),a
@air:

		call	@plyr_camera
	
		jp	@render
		
; =================================================================
; ------------------------------------------------
; Render
; ------------------------------------------------

; TODO: NO USAR DIRECCIONES ODD AL VRAM
; estamos en 8x16

@render:
		ld	hl,ani_player
		call	object_animate
		
		ld	hl,map_player
		ld	d,0
		ld	e,(iy+obj_frame)
		call	object_show
		
		ld	hl,art_player
		ld	de,plc_player
		ld	b,0
  		ld	c,(iy+obj_frame)
		call	object_dplc
		ret
		
; =================================================================
; ------------------------------------------------
; Subs
; ------------------------------------------------

@update_xspd:
		ld	a,h
		ld	h,(iy+(obj_x+1))
		ld	l,(iy+obj_x)
 		ld	de,0
		bit 	7,a
		jp	z,@plusx
; 		cp	0FFh
;  		jp	z,@noupdx
;  		inc 	a
 		ld	de,-1
@plusx:	
		ld	e,a
		add 	hl,de
@noupdx:
		ld	(iy+(obj_x+1)),h
		ld	(iy+obj_x),l
		ret

; ---------------------------------

@update_yspd:
		ld	a,h
		ld	h,(iy+(obj_y+1))
		ld	l,(iy+obj_y)
 		ld	de,0
		bit 	7,a
		jp	z,@plusy
; 		cp	0FFh
;  		jp	z,@noupdy
 		ld	de,-1
@plusy:	
		ld	e,a
		add 	hl,de
@noupdy:
		ld	(iy+(obj_y+1)),h
		ld	(iy+obj_y),l
		ret
	
; **********************************
; Player Walk
; **********************************

@Player_Walk:

; --------------
; RIGHT
; --------------

   		ld	a,(ram_joypads+on_hold)
   		bit 	bitJoyRight,a
   		jp	z,@not_r
		ld	de,50h
		add	hl,de
		ld	a,h
		cp	3
		jp	c,@lowxr
		ld	h,3
@lowxr:
 		res	bitobj_dir,(iy+obj_status)
@not_r:

; --------------
; LEFT
; --------------

   		ld	a,(ram_joypads+on_hold)
   		bit 	bitJoyLeft,a
   		jp	z,@not_l
   		ld	d,(iy+(obj_x+1))
   		ld	a,(iy+(obj_x))
   		or	d
   		jp	z,@not_l
   		bit 	7,d
   		jp	nz,@not_l
   		
		ld	de,-50h
		add	hl,de

		ld	a,h
		cp	-3
		jp	nc,@lowxl
		ld	h,-3
@lowxl:
 		set	bitobj_dir,(iy+obj_status)
 		ret 
 		
@not_l:
; 		ld	hl,0
; 		xor	a
;    		ld	(iy+(obj_x+1)),a
;    		ld	(iy+(obj_x)),a
		ret
		
; **********************************
; Player friction
; **********************************

@Player_Friction:
 		ld	a,l
 		or	h
 		jp	z,@finespeed
		
   		bit	bitobj_dir,(iy+obj_status)
 		jp	nz,@left
 		ld	de,-30h		;original: 20h
 		add 	hl,de
 		bit 	7,h
 		jp	z,@finespeed
 		ld	hl,0
		ret
@left:
 		ld	de,30h		;original: 20h
 		add 	hl,de
 		bit 	7,h
 		jp	nz,@finespeed
 		ld	hl,0
@finespeed:
		ret
		
; **********************************
; Player Jump
; **********************************

@Player_Jump:
		ld	a,(ram_joypads+on_press)
		bit	bitJoy2,a
		jp	z,@NotJump
		
 		call 	object_FindCol_Floor
 		cp	0
 		jp	nz,@CanJump
 		call 	object_FindCol_FloorSides
 		ld	a,b
 		cp	0
 		jp	nz,@CanJump
 		ld	a,c
 		cp	0
 		jp	nz,@CanJump
 		
		jp	@NotJump
		
@CanJump:
		set	bitobj_air,(iy+obj_status)
		
  		ld	a,2
   		ld	(iy+obj_anim_id),a
		ld	hl,-600h
   		ret
   		
@NotJump:
 		ld	de,40h
 		add 	hl,de
 		
 		bit 	7,h
 		jp	nz,@return
		ld	a,h
		cp	10h
		jp	c,@low_fall
		ld	a,10h
@low_fall:
		ld	h,a
@return:
		ret
		
; --------------

@OLD:
		ld	hl,0
		
; --------------
; DOWn
; --------------

   		ld	a,(ram_joypads+on_hold)
   		bit 	bitJoyDown,a
   		jp	z,@not_d
		ld	de,100h
		add	hl,de
@not_d:

; --------------
; UP
; --------------

   		ld	a,(ram_joypads+on_hold)
   		bit 	bitJoyUp,a
   		jp	z,@not_u
   		ld	d,(iy+(obj_y+1))
   		ld	a,(iy+(obj_y))
   		or	d
   		jp	z,@not_u
		ld	de,-100h
		add	hl,de
@not_u:
		ret
	
; **********************************
; Object to Level layout collision
; **********************************
; ----------------------------------
; floor collision
; ----------------------------------

@Collision_Floor:
		call	object_FindCol_Floor
		cp	0
		jp	nz,@found_center
		
 		call	object_FindCol_FloorSides
  		ld	a,b
  		cp	0
   		jp	nz,@found_sides
  		ld	a,c
  		cp	0
 		jp	nz,@found_sides
		ret
		
; ----------------------------------

@found_center:
		cp	1
		jp	z,@floorsolid
 		
		ld	e,(iy+(obj_y_spd+1))
		bit 	7,e
		jp	nz,@no_col

		ld	de,0
		ld	hl,col_SlopeData
		ld	d,a
		add 	a
		add 	a
		add 	a
		add 	a
		ld	e,a
  		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and 	00Fh
  		ld	d,a
  		
 		add 	hl,de
		ld	de,0
		ld	a,(iy+(obj_x))
		and 	00Fh
		ld	e,a
		add 	hl,de
		ld	a,(hl)
		and 	00Fh

		ld	de,0
		ld	e,a
		ld	a,(iy+(obj_y+1))
		and	0FFh
		ld	h,a
		ld	a,(iy+(obj_y))
		and	0F0h
		ld	l,a
		add	hl,de
		ld	b,h
		ld	c,l
		
; 		btst	#bitobj_air,obj_status(a6)
; 		beq.s	@dontchk
;   		add.l	d7,d3
;   		cmp.l	d1,d3
;   		blt.s	@NoCol
; @dontchk:	
		ld	(iy+(obj_y+1)),b
		ld	(iy+(obj_y)),c	
		
		res	bitobj_air,(iy+obj_status)
		exx
		ld	de,0
		ld	a,c
		or	b
		jp	z,@nodown
		ld	de,100h
@nodown:
 		exx
@NoCol:
		ret
		
; ----------------------------------

@found_sides:
		cp	1
		jp	z,@floorsolid
		ret		

; ----------------------------------
		
@floorsolid:
		res	bitobj_air,(iy+obj_status)
		ld	a,(iy+(obj_y+1))
		and	0FFh
		ld	(iy+(obj_y+1)),a
		ld	a,(iy+(obj_y))
		and	0F0h
		ld	(iy+(obj_y)),a	
		
		exx
		ld	de,0
		exx
		ret
		
@no_col:
 		ret
 		
; **********************************
; ceiling collision
; **********************************

@Collision_Ceiling:
		ret
		
; **********************************
; Wall collision
; **********************************

@Collision_Wall:
		call	object_FindCol_Wall
		cp	0
		jp	nz,@wall_center
		
 		call	object_FindCol_WallSides
  		ld	a,b
  		cp	0
   		jp	nz,@wall_right
  		ld	a,c
  		cp	0
 		jp	nz,@wall_left
		ret		

; ----------------------------------

@wall_center:
 		cp	1
 		jp	z,@wallsolid_slope

 		ld	d,a
 		ld	a,(iy+(obj_y))
 		and	00Fh
 		jp	nz,@NoCol_LR

		ld	hl,col_SlopeData
 		ld	a,d
		add 	a
		add 	a
		add 	a
		add 	a
		ld	e,a
  		ld	a,d
  		rrca
  		rrca
  		rrca
  		rrca
  		and 	00Fh
  		ld	d,a
 		add 	hl,de
 		
		ld	de,0
		ld	a,(iy+(obj_x))
		and 	00Fh
		ld	e,a
		add 	hl,de
		ld	de,0
		ld	a,(hl)
		and 	00Fh
		ld	e,a
		ld	h,(iy+(obj_y+1))
		ld	a,(iy+(obj_y))
		and	0F0h
		ld	l,a
		scf
		sbc	hl,de
		ld	(iy+(obj_y+1)),h
		ld	(iy+(obj_y)),l
		
		exx
		ld	a,c
		or	b
		jp	z,@ClrYSpd
		bit	7,d
		jp	nz,@return_xvel
@ClrYSpd:
		res	bitobj_air,(iy+obj_status)
		ld	de,0
@return_xvel:
		exx
@NoCol_LR:
		ret

; ----------------------------------

@wall_right:
 		bit 	bitobj_dir,(iy+obj_status)
 		jp	nz,@return
  		ld	a,b
  		cp	2
  		jp	nc,@return
 		cp	1
 		jp	z,@wallsolid
 		ret
@wall_left:
 		bit 	bitobj_dir,(iy+obj_status)
 		jp	z,@return
  		ld	a,c
  		
		ld	h,(iy+(obj_x+1))
		ld	l,(iy+(obj_x))
		ld	a,(iy+(obj_size))
		add 	a
		add 	a
		add 	a
		ld	d,0
		ld	e,a
		scf
		sbc	hl,de
		jp	m,@return
		
   		ld	a,c
  		cp	2
  		jp	nc,@return
		cp	1
		jp	z,@wallsolid
		ret
		
@wallsolid:
		exx
		ld	bc,0
		exx
		
@wallsolid_slope:
		ld	a,(iy+(obj_x+1))
		and	0FFh
		ld	(iy+(obj_x+1)),a
		ld	a,(iy+(obj_x))
		and	0F8h
		ld	(iy+(obj_x)),a
		
		bit 	bitobj_dir,(iy+obj_status)
		jp	z,@right_w
		ld	h,(iy+(obj_x+1))
		ld	l,(iy+(obj_x))
		ld	de,8
		add 	hl,de
		ld	(iy+(obj_x+1)),h
		ld	(iy+(obj_x)),l
		
@right_w:
		ld	a,(iy+(obj_x+1))
		and	0FFh
		ld	(iy+(obj_x+1)),a
		ld	a,(iy+(obj_x))
		and	0F8h
		ld	(iy+(obj_x)),a
		
		ret
		
; 		cmp.w	#1,d0
;  		beq	@wallsolid_slope
; 		
;    		move.l	obj_y(a6),d2
;     		swap	d2
;      		and.w	#$F,d2
;      		bne.s	@NoCol_LR
;      		
;     		lea	(col_SlopeData),a3
;     		and.l	#$FF,d0
;     		move.w	d0,d3
;     		lsl.w	#4,d3
;     		adda	d3,a3
;     		move.l	obj_x(a6),d0
;     		swap	d0
;     		and.w	#$F,d0
;     		move.b	(a3,d0.w),d0
;     		and.w	#$F,d0
;     		and.l	#$FFF00000,obj_y(a6)
;   		swap	d0
;   		and.l	#$FFFF0000,d0
; 
;  		sub.l	d0,obj_y(a6)
;   		tst.l	d6
;   		beq.s	@ClrYSpd
;   		tst.l	d7
;   		bmi.s	@NoCol_LR
; @ClrYSpd:
;   		bclr	#bitobj_air,obj_status(a6)
;            	clr.l	d7
; @NoCol_LR:
; 		rts
		
; **********************************
; Move level camera
; **********************************

@plyr_camera:
 		ld	ix,ram_levelbuffer
 		
; --------------	
; LEFT/RIGHT
; --------------

  		ld      h,(iy+(lvl_x_size+1))
  		ld      l,(iy+(lvl_x_size))
  		ld	de,-(256<<4)
  		add 	hl,de
  		jp	c,@end_x_lvl
		
  		ld      h,(iy+(obj_x+1))
  		ld      l,(iy+(obj_x))
  		ld	a,h
  		or	l
  		jp	z,@end_x_lvl
  		

  		if MERCURY
  		ld	de,((160/2))+1
  		else
  		ld	de,(248/2)+1
  		endif
  		scf			;todo: checar si se mueve un pixel delante
  		sbc	hl,de
  		jp	m,@start_x
  		jp	c,@start_x
  		
   		ld	b,h
   		ld	c,l
   		ld	d,(ix+(lvl_x_size+1))
   		ld	e,(ix+(lvl_x_size))
    		ld	a,e
    		rrca
    		rrca
    		rrca
    		rrca
    		and	0F0h
    		ld	l,a
   		ld	a,e
    		rrca
    		rrca
    		rrca
    		rrca
    		and	00Fh
   		ld	h,a
   		ld	a,d
   		rrca
   		rrca
   		rrca
   		rrca
   		and	0F0h
   		ld	h,a
   		
   		ld	hl,0800h
   		if MERCURY
   		ld	de,-(161)
   		else
    		ld	de,-(249)
    		endif
    		add 	hl,de
   		ld	a,b
   		cp	h
   		jp	c,@nope
     		ld	a,c
     		cp	l
     		jp	c,@nope
    		
    		ld	b,h
    		ld	c,l

@nope:
  		ld	a,c
  		cpl
  		ld      (ram_hscroll),a
 		ld      (ix+(lvl_x+1)),b
  		ld      (ix+(lvl_x)),c
  		
  		ld	a,c
  		and	00001000b
  		ld	h,(ix+(lvl_past_x))
  		cp	h
  		jp	z,@end_x_lvl
  		ld	(ix+(lvl_past_x)),a
  		
  		bit 	7,(iy+(obj_x_spd+1))
  		jp	nz,@leftscrl	
  		bit 	bitobj_dir,(iy+(obj_status))
  		jp	nz,@leftscrl
  		
  		set 	bit_drw_r,(ix+(lvl_drawdir))
  		jp	@end_x_lvl
@leftscrl:
  		set 	bit_drw_l,(ix+(lvl_drawdir))
  		jp	@end_x_lvl
  		
@start_x:
		xor	a
 		ld      (ix+(lvl_x+1)),a
  		ld      (ix+(lvl_x)),a
  		ld      (ram_hscroll),a
@end_x_lvl:

; --------------	
; UP/DOWN
; --------------

  		ld      h,(iy+(obj_y+1))
  		ld      l,(iy+(obj_y))
  		ld	a,h
  		or	l
  		jp	z,@end_y_lvl
  		
  		ld      h,(iy+(obj_y+1))
  		ld      l,(iy+(obj_y))
  		if MERCURY
  		ld	de,(144/2)+10h
  		else
  		ld	de,(192/2)+8h
  		endif
  		scf
  		sbc	hl,de
  		jp	m,@start_y
  		jp	c,@start_y

  		ld	b,h
  		ld	c,l
      		
      		ld	a,(ix+(lvl_y_size+1))
      		add	a
      		add	a
      		add	a
      		add	a
      		and	0F0h
      		ld	h,a
      		ld	a,(ix+(lvl_y_size))
      		rrca
      		rrca
      		rrca
      		rrca
      		and	00Fh
      		or	h
      		ld	h,a
      		ld	a,(ix+(lvl_y_size))
      		add	a
      		add	a
      		add	a
      		add	a
      		ld	l,a
      		
       		if MERCURY
      		ld	de,-090h
       		else
      		ld	de,-0C0h
       		endif

      		add	hl,de
       		ld	a,b
       		cp	h
      		jp	c,@topok_y      		
       		ld	a,c
       		cp	l
      		jp	nc,@end_y
@topok_y:

  		ld	h,b
  		ld	l,c
 		ld      (ix+(lvl_y+1)),h
  		ld      (ix+(lvl_y)),l
 		ld      a,h
  		ld      (ram_vscroll+1),a
  		ld      a,l
  		ld      (ram_vscroll),a
  		
  		ret
@start_y:
		xor	a
 		ld      (ix+(lvl_y+1)),a
  		ld      (ix+(lvl_y)),a
  		ld      (ram_vscroll+1),a
  		ld      (ram_vscroll),a	
  		ret
@end_y:
		ld	de,0
		ld	a,(ix+(lvl_y_size))
      		if MERCURY
      		sub 	9
      		else
      		sub 	0Ch
      		endif
		add 	a
		add	a
		add	a
		add	a
		ld	e,a
		
 		ld      (ix+(lvl_y+1)),d
  		ld      (ix+(lvl_y)),e
  		
		ld	a,d	
   		ld      (ram_vscroll+1),a
		ld	a,e
   		ld      (ram_vscroll),a	
  		ret
  		
@end_y_lvl:
		ret
	
; --------------	
; debug mode
; --------------

@debug_mode:
		ld	bc,0
		ld	de,0
		
; --------------	
; RIGHT
; --------------

		ld	a,(ram_joypads+on_hold)
		bit 	bitJoyRight,a
		jr      z,@NotRight
		
		ld	bc,400h
 		res	bitobj_dir,(iy+obj_status)
@NotRight:

; --------------	
; LEFT
; --------------

		ld	a,(ram_joypads+on_hold)
		bit 	bitJoyLeft,a
		jr      z,@NotLeft

		ld	bc,-400h
 		set	bitobj_dir,(iy+obj_status)
@NotLeft:

; --------------	
; DOWN
; --------------

		ld	a,(ram_joypads+on_hold)
		bit 	bitJoyDown,a
		jr      z,@NotDown

		ld	de,400h
@NotDown:

; --------------	
; UP
; --------------

		ld	a,(ram_joypads+on_hold)
		bit 	bitJoyUp,a
		jr      z,@NotUp
		
		ld	de,-400h
		
@NotUp:
		ld	(iy+(obj_x_spd+1)),b
		ld	(iy+(obj_x_spd)),c
		ld	(iy+(obj_y_spd+1)),d
		ld	(iy+(obj_y_spd)),e
		
		ld	h,(iy+(obj_x_spd+1))
		call	@update_xspd
		ld	h,(iy+(obj_y_spd+1))
		call	@update_yspd
		call	@plyr_camera
		jp 	@Render
		
; =================================================================
; ------------------------------------------------
; Data
; ------------------------------------------------
		
ani_player:
		dw @Idle
		dw @Walk
		dw @Jump_1
		dw @Jump_2
@Idle:
 		db 5
 		db 0
		db 0FFh
@Jump_1:	
 		db 4
 		db 7
		db 0FFh
@Jump_2:	
 		db 4
 		db 8
		db 0FFh
@Walk:
 		db 3
 		db 1,2,3,4,5,6
		db 0FFh
		
; --------------	
; LEFT/RIGHT
; --------------

; @movelevel:
;   		ld	a,(ram_joypads+on_press)
;   		bit 	bitJoyStart,a
;   		jp	z,@DontExit
; 		ld	a,0
; 		ld	(ram_gamemode),a
; 		ret
; @DontExit:
; 		ld	ix,ram_levelbuffer
; 
; ; --------------	
; ; RIGHT
; ; --------------
; 
; 		ld	a,(ram_joypads+on_hold)
; 		bit 	bitJoyRight,a
; 		jr      z,@NotRight
;  		ld      b,(ix+(lvl_x+1))
;  		ld      c,(ix+(lvl_x))
;  		inc	bc
;  		
;  		ld	a,(ix+(lvl_x_size))
;  		srl	a
;  		srl	a
;  		srl	a
;  		srl	a
;  		ld	h,a
;   		ld	a,(ix+(lvl_x_size+1))
;   		and 	0F0h
;   		ld	l,a
;   		if MERCURY
;  		ld	de,(160)-1
;  		else
;  		ld	de,(256-8)-1
;  		endif
;  		sbc	hl,de
;    		ld	a,h
;     		cp	b
;     		jp	nz,@cont_x_r
;    		ld	a,l
;     		cp	c
;     		jp	nz,@cont_x_r 		
;     		jr	@NotRight
; @cont_x_r:
;  		ld      (ix+(lvl_x+1)),b
;  		ld      (ix+(lvl_x)),c
; 
;  		ld	a,(ix+(lvl_drawdir))	;draw right
;   		set 	bit_drw_r,a
;  		ld	(ix+(lvl_drawdir)),a
; @notdrw_r:
; 
; 		ld      a,(ram_hscroll)
; 		dec     a			; move right
; 		ld      (ram_hscroll),a 
; @NotRight:
; 
; ; --------------	
; ; LEFT
; ; --------------
; 
; 		ld	a,(ram_joypads+on_hold)
; 		bit 	bitJoyLeft,a
; 		jr      z,@NotLeft
;  		ld      b,(ix+(lvl_x+1))
;  		ld      c,(ix+(lvl_x))
;  		ld	a,c
;  		or	b
;  		jp	z,@NotLeft
;  		dec	bc
;  		ld      (ix+(lvl_x+1)),b
;  		ld      (ix+(lvl_x)),c
;  		ld	a,(ix+(lvl_drawdir))	; draw left
;   		set 	bit_drw_l,a
;  		ld	(ix+(lvl_drawdir)),a
; 		
; 		ld      a,(ram_hscroll)
; 		inc     a			; move left
; 		ld      (ram_hscroll),a 
; @NotLeft:
; 
; ; --------------	
; ; DOWN
; ; --------------
; 
; 		ld      hl,ram_vscroll
; 		
; 		ld	a,(ram_joypads+on_hold)
; 		bit 	bitJoyDown,a
; 		jr      z,@NotDown
;  		ld      b,(ix+(lvl_y+1))
;  		ld      c,(ix+(lvl_y))
;  		inc	bc
;  		
;    		ld	a,(ix+(lvl_y_size))
;    		if MERCURY
;    		sub 	9
;    		else
;    		sub 	0Ch
;    		endif
;    		sla	a
;    		sla	a
;    		sla	a
;    		sla	a
;    		cp	c
;    		jp	c,@NotDown
;    		
;  		ld      (ix+(lvl_y+1)),b
;  		ld      (ix+(lvl_y)),c
; 		ld	a,(ix+(lvl_drawdir))
;  		set 	bit_drw_d,a
; 		ld	(ix+(lvl_drawdir)),a
; 		
; 		ld      a,(hl)
; 		inc     a			; move down
; 		ld      (hl),a
;  		ld	a,(ram_vintwait)
;  		res 	bitVerDir,a
;  		ld	(ram_vintwait),a
; @NotDown:
; 
; ; --------------	
; ; UP
; ; --------------
; 
; 		ld	a,(ram_joypads+on_hold)
; 		bit 	bitJoyUp,a
; 		jr      z,@NotUp
;  		ld      b,(ix+(lvl_y+1))
;  		ld      c,(ix+(lvl_y))
;  		ld	a,c
;  		or	b
;  		jp	z,@NotUp
;  		dec	bc
;  		ld      (ix+(lvl_y+1)),b
;  		ld      (ix+(lvl_y)),c
; 		ld	a,(ix+(lvl_drawdir))
;  		set 	bit_drw_u,a
; 		ld	(ix+(lvl_drawdir)),a
; 		
; 		ld      a,(hl)
; 		dec     a			; move up
; 		ld      (hl),a
;  		ld	a,(ram_vintwait)
;  		set 	bitVerDir,a
;  		ld	(ram_vintwait),a
; @NotUp:
; 		ret
		
		
; 		call	@movelevel
		
;  ;LEFT/RIGHT
; 		ld	b,(iy+obj_x+1)
; 		ld	c,(iy+obj_x)
;   		ld	a,(ram_joypads+on_hold)
;   		bit 	bitJoyRight,a
;   		jp	z,@not_r
; 		inc	bc
; 		res	bitobj_dir,(iy+obj_status)
; @not_r:
;   		ld	a,(ram_joypads+on_hold)
;   		bit 	bitJoyLeft,a
;   		jp	z,@not_l
; 		dec	bc
; 		set	bitobj_dir,(iy+obj_status)
; @not_l:
; 		ld	(iy+obj_x+1),b
; 		ld	(iy+obj_x),c
; 		
;  ;UP/DOWN
; 		ld	b,(iy+obj_y+1)
; 		ld	c,(iy+obj_y)
;   		ld	a,(ram_joypads+on_hold)
;   		bit 	bitJoyDown,a
;   		jp	z,@not_d
; 		inc	bc
; @not_d:
;   		ld	a,(ram_joypads+on_hold)
;   		bit 	bitJoyUp,a
;   		jp	z,@not_u
; 		dec	bc
; @not_u:
; 		ld	(iy+obj_y+1),b
; 		ld	(iy+obj_y),c