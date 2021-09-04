; =================================================================
; Object
; 
; Pikudo
; =================================================================

; =================================================================
; ------------------------------------------------
; Variables
; ------------------------------------------------

varVramPikudo	equ	$4D0
varTimerWait	equ	170
varTimerAttck	equ	30

; =================================================================
; ------------------------------------------------
; RAM
; ------------------------------------------------

		rsset Obj_Ram
timerpik1	rs.w 1
timerpik2	rs.w 1
lastx		rs.w 1
lasty		rs.w 1

; =================================================================
; ------------------------------------------------
; Code start
; ------------------------------------------------

Obj_Pikudo:
 		moveq	#0,d0
 		move.b	obj_index(a6),d0
 		add.w	d0,d0
 		move.w	@Index(pc,d0.w),d1
 		jsr	@Index(pc,d1.w)
 		
 		bsr	Object_OffCheck
   		move.l	#(varVramPikudo<<16),d0
 		move.l	#ani_pikudo,d1
		bsr	Object_Animate
		
    		move.l	#(varVramPikudo<<16),d0
 		move.b	obj_frame(a6),d0
		move.l	#map_pikudo,d1
 		bra	Object_Show
 		
; ------------------------------------------------

@Index:
		dc.w @Init-@Index
		dc.w @Stand-@Index
		dc.w @Attack-@Index
		even
		
; =================================================================
; ------------------------------------------------
; Index $00: Init
; ------------------------------------------------

@Init:
		add.b	#1,obj_index(a6)
		clr.b	obj_anim_id(a6)
		clr.b	obj_frame(a6)
		move.l	#$01010202,obj_size(a6)
		clr.l	obj_x_spd(a6)
		move.w	#varTimerWait,timerpik1(a6)
		move.w	obj_x(a6),lastx(a6)
		move.w	obj_y(a6),lasty(a6)
		
; =================================================================
; ------------------------------------------------                  
; Index $01: Stand
; ------------------------------------------------

@Stand:
		lea	(RAM_ObjBuffer),a4
		bclr	#bitobj_flipH,obj_status(a6)
		move.w	obj_x(a4),d0
		cmp.w	obj_x(a6),d0
		blt.s	@leftside
		bset	#bitobj_flipH,obj_status(a6)
@leftside:

		bsr	object_FindCol_Ceiling
		tst.b	d0
		bne.s	@ignore
		bsr	object_FindCol_CeilingSides
		tst.b	d0
		bne.s	@ignore	
		tst.b	d1
		bne.s	@ignore
		
		move.w	obj_y(a6),d0
		cmp.w	lasty(a6),d0
		ble.s	@ignore
		
; 		
; 		bsr	object_FindPrz_CeilingSides
; 		move.l	d0,d2
; 		bsr	object_FindPrz_CeilingSides
; 		or.l	d1,d0
; 		or.l	d2,d0
; 		btst	#7,d0
; 		bne.s	@cont2
; 		btst	#6,d0
; 		bne.s	@cont2
; 		tst.b	d0
; 		bne.s	@ignore
; @cont2:

		sub.w	#1,obj_y(a6)
@ignore:

		sub.w	#1,timerpik1(a6)
		bpl.s	@waitpik1
		
  		move.l	#SndSfx_BEEBUZZ,d0
  		moveq 	#2,d1
  		moveq	#1,d2
  		bsr	Audio_Track_play
  		
		move.b	#2,obj_index(a6)
		move.w	#varTimerAttck,timerpik1(a6)
		move.b	#1,obj_anim_id(a6)
		move.l	#-$1F000,obj_x_spd(a6)
		move.l	#$20000,obj_y_spd(a6)
		btst	#bitobj_flipH,obj_status(a6)
		beq.s	@waitpik1
		neg.l	obj_x_spd(a6)

@waitpik1:
		bra	@check_touch
		
; =================================================================
; ------------------------------------------------                  
; Index $02: Attack
; ------------------------------------------------

@Attack:
		move.l	obj_x_spd(a6),d6
		move.l	obj_y_spd(a6),d7
		
		add.l	d6,obj_x(a6)
		add.l	d7,obj_y(a6)
		
; Check for floor or walls

		bsr	object_FindCol_Floor
		tst.b	d0
		bne.s	@forceend
		bsr	object_FindPrz_Floor
		btst	#7,d0
		bne.s	@cont
		btst	#6,d0
		bne.s	@cont	
		tst.b	d0
		bne.s	@forceend
@cont:

		bsr	object_FindCol_Wall
		tst.b	d0
		bne.s	@ignore
		bsr	object_FindCol_WallSides
		tst.b	d0
		bne	@ignore		
		tst.b	d1
		bne	@ignore
		
		bsr	object_FindPrz_WallSides
		move.l	d0,d2
		bsr	object_FindPrz_WallSides
		or.l	d1,d0
		or.l	d2,d0
		btst	#7,d0
		bne.s	@cont3
		btst	#6,d0
		bne.s	@cont3
		tst.b	d0
		bne.s	@forceend
@cont3:

		sub.w	#1,timerpik1(a6)
		bpl.s	@waitpik2
		bra.s	@end2
@forceend:
		sub.w	#8,lasty(a6)
@end2:

		move.b	#1,obj_index(a6)
		move.w	#varTimerWait,timerpik1(a6)
		clr.b	obj_anim_id(a6)
		clr.l	d6
		clr.l	d7
@waitpik2:

		move.l	d6,obj_x_spd(a6)
		move.l	d7,obj_y_spd(a6)
		bra	@check_touch
		
; =================================================================
; ------------------------------------------------
; Subs
; ------------------------------------------------

; @Go_Stand:
; 		clr.l	obj_x_spd(a6)
; 		clr.b	obj_anim_id(a6)
; 		move.b	#1,obj_index(a6)
; 		rts
; 	
; ; --------------------------------------
; 
; @Go_Walk:
; 		move.l	#$4000,obj_x_spd(a6)
; 		btst	#bitobj_flipH,obj_status(a6)
; 		bne.s	@right
; 		move.l	#-$4000,obj_x_spd(a6)
; @right:
; 		move.b	#1,obj_anim_id(a6)
; 		move.b	#2,obj_index(a6)
; 		rts
; 	
; ; ------------------------------------------------
; ; Pyhsics
; ; ------------------------------------------------
; 
; @Pyhsics:
; 		lea	(RAM_LvlPlanes),a5
;  		move.l	obj_x_spd(a6),d6
;  		move.l	obj_y_spd(a6),d7
;  		
;  		add.l	d6,obj_x(a6)
;  		bsr	@WallCheck
; 		
; ; ----------------------------------
; 
;   		add.l	#$8000,d7
;   		cmp.l	#$40000,d7
;   		blt.s	@low_y
;   		move.l	#$40000,d7
; @low_y:
;   		add.l	d7,obj_y(a6)
;   		
; ; 		lea	(RAM_LvlPlanes),a5
; ; 		move.w	lvl_size_y(a5),d0
; ; 		lsl.w	#4,d0
; ; 		move.w	obj_y(a6),d1
; ; 		moveq	#0,d2
; ; 		move.b	obj_size+2(a6),d2
; ; 		lsl.w	#3,d2
; ; 		sub.w	d2,d1
; ; 		cmp.w	d0,d1
; ; 		bge	@delete
; ; 		
;   		tst.l	d7
;   		bmi.s	@no_floor
;   
; 		bsr	object_FindPrz_Floor
; 		move.l	d0,d2
; 		tst.b	d0
; 		bne.s	@from_prize
;  		bsr 	object_FindPrz_FloorSides
; 		tst.b	d0
; 		bne	@from_prize;@swap_dir_wl
; 		move.l	d1,d0
; 		tst.b	d0
; 		bne	@from_prize
; 		
; 		bsr	object_FindCol_Floor
; 		move.l	d0,d2
; 		tst.b	d0
; 		bne.s	@set_floor
;  		bsr 	object_FindCol_FloorSides
; 		tst.b	d0
; 		bne	@set_floor;@swap_dir_wl
; 		move.l	d1,d0
; 		tst.b	d0
; 		beq	@no_floor
; 		
; 		bra.s	@set_floor
; ; @swap_dir_wl:
; ; 		neg.l	d6
; ; 		bchg	#bitobj_flipH,obj_status(a6)
; ; 		bra.s	@no_floor
; 
; @from_prize:
; 		cmp.b	#$40,d0
; 		bge.s	@set_floor
; 		move.b	#1,d0
; 		
; @set_floor:
;   		bsr 	object_SetCol_Floor
;   		
; @no_floor:
; 
;  		move.l	d6,obj_x_spd(a6)
;  		move.l	d7,obj_y_spd(a6)
 		
; ----------------------------------
; Check if touched
; ----------------------------------

@check_touch:
		bsr	objTouch_Top
		tst.b	d0
		bne.s	@touch_flag
		bsr	objTouch_Bottom
		tst.b	d0
		bne.s	@touch_flag
		
		bsr	objTouch_Sides
		tst.b	d0
		bne.s	@touch_flag;_side
		swap	d0
		tst.b	d0
		bne.s	@touch_flag;_side
		rts
		
; -----------------------------------

@touch_flag:
		bsr	objPlyrHurtKill
		beq.s	@return
		
		bclr	#bitobj_hurt,obj_status(a4)
   		move.w	#varVramPikudo,d1
 		move.b	obj_frame(a6),d2
		move.l	#map_pikudo,d0
		move.l	a4,d3
		bsr	objAction_SetStomp
		bra	Object_IsGone
@return:
		rts
		
; =================================================================

@WallCheck:
   		bsr	object_FindPrz_Wall
   		tst.b	d0
   		bne.s	@foundprzwl
  		bsr	object_FindCol_Wall
  		tst.b	d0
  		beq.s	@chk_right
@foundprzwl:
  		btst	#6,d0
  		bne.s	@chk_right
;    		cmp.b	#2,d0
;    		blt.s	@chk_right
  		bsr	object_SetCol_Wall
;    		bra.s	@endchk
@chk_right:

		;TODO: Prize check
;   		bsr	object_FindPrz_WallSides
;   		tst.b	d0
;   		bne.s	@przrotx
;   		move.l	d1,d0
;   		tst.b	d0
;   		bne.s	@przrotx

  		bsr	object_FindCol_WallSides
  		btst	#6,d0
  		bne.s	@endchk
  		btst	#6,d1
  		bne.s	@endchk
  		tst.b	d0
  		bne.s	@leftws
  		tst.b	d1
  		bne.s	@rightws
   		bra.s	@endchk
@przrotx:
	
@leftws:
		cmp.b	#2,d1
		bge.s	@endchk
		btst	#bitobj_flipH,obj_status(a6)
		beq.s	@endchk
		bra.s	@rotatex
@rightws:
		cmp.b	#2,d1
		bge.s	@endchk
		btst	#bitobj_flipH,obj_status(a6)
		bne.s	@endchk
@rotatex:
 		neg.l	d6
 		bchg	#bitobj_flipH,obj_status(a6)
@endchk:
		rts

; ------------------------------------------------
; Data
; ------------------------------------------------
		
; ----------------------------------------

ani_pikudo:
		dc.w @Idle-ani_pikudo
		dc.w @Attack-ani_pikudo
		even
@Idle:
 		dc.b 3
 		dc.b 0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,2
 		dc.b 1,0,1,0,1,0,1,0,1,0,1
		dc.b $FF
		even
@Attack:
 		dc.b 2
 		dc.b 3,4
		dc.b $FF
		even
