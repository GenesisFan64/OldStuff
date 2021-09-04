; =================================================================
; Object
; 
; A Ball
; =================================================================

; =================================================================
; ------------------------------------------------
; Variables
; ------------------------------------------------

varVramBall	equ	$4000|$4B8

; =================================================================
; ------------------------------------------------
; Code start
; ------------------------------------------------

Obj_Ball:
 		moveq	#0,d0
 		move.b	obj_index(a6),d0
 		add.w	d0,d0
 		move.w	@Index(pc,d0.w),d1
 		jsr	@Index(pc,d1.w)
 		bsr	Object_OffCheck
 		
		move.l	#(varVramBall<<16),d0
		move.b	obj_frame(a6),d0
		move.l	#map_Ball,d1
 		bra	Object_Show
 		
; ------------------------------------------------

@Index:
		dc.w	@Init-@Index
		dc.w	@Main-@Index
		even
		
; =================================================================
; ------------------------------------------------
; Index $00: Init
; ------------------------------------------------

@Init:
		add.b	#1,obj_index(a6)
		move.l	#$01010101,obj_size(a6)
		move.l	#$6000,obj_y_spd(a6)
		clr.b	obj_frame(a6)
		clr.b	obj_anim_spd(a6)
		move.l	#-$18000,obj_x_spd(a6)
		
; =================================================================
; ------------------------------------------------                  
; Index $01: Main
; ------------------------------------------------

@Main:
; 		bsr.s	@move_ball
; 		bra	@check_touch
		
; =================================================================
; ------------------------------------------------
; Subs
; ------------------------------------------------

@move_ball:
 		move.l	obj_x_spd(a6),d6
 		move.l	obj_y_spd(a6),d7
 		add.l	d6,obj_x(a6)
 		add.l	d7,obj_y(a6)
 		
 		tst.l	obj_x(a6)
 		bpl.s	@fine_x
 		clr.l	obj_x(a6)
		move.l	#$20000,d6
@fine_x:
		moveq	#0,d0
		move.w	(RAM_LvlPlanes+lvl_size_x),d0
		lsl.w	#4,d0
		swap	d0
		move.l	obj_x(a6),d1
		cmp.l	d0,d1
		blt.s	@fine_x_r
		move.l	#-$20000,d6
@fine_x_r:
	
; ----------------------------------

 		add.l	#$4000,d7
 		cmp.l	#$80000,d7
 		blt.s	@low_y
 		move.l	#$80000,d7
@low_y:
 		
 		tst.l	d7
 		bpl.s	@Freec
		bsr	object_FindPrz_Ceiling
		tst.b	d0
		bne.s	@FndCeilPrz
		bsr	object_FindPrz_CeilingSides
		tst.b	d0
		bne.s	@FndCeilPrz
		move.l	d1,d0
		tst.b	d0
		bne.s	@FndCeilPrz
		
		bsr	object_FindCol_Ceiling
		btst	#6,d0
		bne.s	@Freec
		tst.b	d0
		bne.s	@FoundCeiling
		bsr	object_FindCol_CeilingSides
		tst.b	d0
		bne.s	@FoundCeiling
		move.l	d1,d0
		tst.b	d0
		bne.s	@FoundCeiling
		bra.s	@Freec
@FndCeilPrz:
		btst	#7,d0
		bne.s	@Freec
@FoundCeiling:
		btst	#6,d0
		bne.s	@Freec
		
		bsr	object_SetCol_Ceiling
		
; ----------------------------------

@Freec:	
 		tst.l	d7
 		bmi.s	@Free
 	
		bsr	object_FindPrz_Floor
		btst	#7,d0
		bne.s	@Free
		btst	#6,d0
		bne.s	@Free
		tst.b	d0
		bne.s	@przflr
		
		bsr	object_FindCol_Floor
		btst	#6,d0
		bne.s	@Free
		tst.b	d0
		beq.s	@Free

@przflr:
		bsr	object_SetCol_Floor
 		move.l	#-$60000,d7

  		move.l	#SndSfx_PING,d0
  		moveq 	#2,d1
  		moveq	#1,d2
  		bsr	Audio_Track_play
@Free:

; ----------------------------------------

;  		bsr	object_FindPrz_WallSides
; ;  		tst.l	d6
; ;  		bmi.s	@to_left
; 		btst	#7,d0
; 		bne.s	@FreeWall2
; 		btst	#6,d0
; 		bne.s	@FreeWall2
; 		tst.b	d0
; 		bne.s	@FoundW
; 		bra.s	@FreeWall2
; @to_left:
; ; 		tst.l	d6
; ; 		bpl.s	@FreeWall2
; 		btst	#7,d1
; 		bne.s	@FreeWall2
; 		btst	#6,d1
; 		bne.s	@FreeWall2
; 		tst.b	d1
; 		bne.s	@FoundW
; 		
; @FreeWall2:
		bsr	object_FindCol_WallSides
		tst.l	d6
		bmi.s	@dontlft
 		tst.b	d0
 		bne.s	@FoundW
@dontlft:
		tst.l	d6
		bpl.s	@FreeWall
		move.l	d1,d0
  		tst.b	d0
 		bne.s	@FoundW
		bra.s	@FreeWall

@FoundW:
		cmp.b	#2,d0
		bge.s	@FreeWall
; 		bsr	object_SetCol_Wall
		neg.l	d6
		bchg	#bitobj_flipH,obj_status(a6)
@FreeWall:

; ------------------------------------

 		sub.b	#1,obj_anim_spd(a6)
 		bpl.s	@plusanim
 		move.b	#7,obj_anim_spd(a6)
  		add.b	#1,obj_frame(a6)
 		and.b	#%11,obj_frame(a6)
@plusanim:

; ------------------------------------

 		move.l	d6,obj_x_spd(a6)
 		move.l	d7,obj_y_spd(a6)
; 		rts
		
; =================================================================
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
		bne.s	@touch_flag
		swap	d0
		tst.b	d0
		bne.s	@touch_flag
		rts
		
; -----------------------------------

@touch_flag:
		bsr	objPlyrHurtKill
		beq.s	@return
   		move.w	#varVramBall,d1
 		move.b	obj_frame(a6),d2
		move.l	#map_Ball,d0
		move.l	a4,d3
		bsr	objAction_SetStomp
		bra	Object_IsGone
@return:
		rts
