; =================================================================
; Object
; 
; Player
; =================================================================

; =================================================================
; ------------------------------------------------
; Variables
; ------------------------------------------------

varPlyrVRAM	equ	$6000|$780
varScrlHor	equ	320
varJumpTimer	equ	11
varHurtTimer	equ	96

varPlyAniJump	equ	2
varPlyrMdDead	equ	2

bitPlyrClimb	equ	5
bitPlyrCancelY	equ	6
bitPlyrBusy	equ	7

; =================================================================
; ------------------------------------------------
; RAM
; ------------------------------------------------

		rsset obj_ram
plyr_lvltrgt	rs.w	1
plyr_jumptmr	rs.w	1
plyr_hits	rs.w	1
plyr_hittime	rs.w	1
plyr_spccol	rs.b	1		; %00000LCR
plyr_status	rs.b	1		; %000000FB

; =================================================================
; ------------------------------------------------
; Code start
; ------------------------------------------------

Obj_Player:
 		moveq	#0,d0
 		move.b	obj_index(a6),d0
 		add.w	d0,d0
 		move.w	@Index(pc,d0.w),d1
 		jsr	@Index(pc,d1.w)
 		
 		;Render
 		moveq	#0,d0
    		move.w	#varPlyrVRAM,d0
		cmp.b	#varPlyrMdDead,obj_index(a6)
		bne.s	@dontforce
		or.w	#$8000,d0
@dontforce:
    		swap	d0
   		move.b	obj_frame(a6),d0
 		move.l	#ani_player,d1
		bsr	Object_Animate
		
		btst	#0,plyr_hittime+1(a6)
		bne.s	@return
		
   		move.b	obj_frame(a6),d0	
 		move.l	#map_player,d1
  		bsr	Object_Show
 		
   		move.l	#(varPlyrVRAM<<16),d0
   		move.b	obj_frame(a6),d0
		move.l	#dplc_player,d1
		move.l	#art_player,d2
		bra	Object_DPLC

@return:
		rts
		
; ------------------------------------------------

@Index:
		dc.w ObjPlyr_Init-@Index
		dc.w ObjPlyr_Main-@Index
		dc.w ObjPlyr_Die-@Index
		even

; =================================================================
; ------------------------------------------------
; Index $00: Init
; ------------------------------------------------

ObjPlyr_Init:
		add.b	#1,obj_index(a6)
		move.l	#$01010202,obj_size(a6)
; 		bset	#bitobj_flipV,obj_status(a6)
		
; 		tst.w	(RAM_P1_Hits)
; 		beq.s	@iszerohits
; 		bpl.s	@dontresthit
; @iszerohits:
		move.w	#3,(RAM_P1_Hits)
@dontresthit:
		clr.w	plyr_hittime(a6)
 		bset	#bitobj_hit,obj_status(a6)
 		
; =================================================================
; ------------------------------------------------
; Index $01: Main
; ------------------------------------------------

ObjPlyr_Main:
; 		btst	#bitJoyA,(RAM_Control_2+OnPress)
; 		beq.s	@NotDbg
; 		clr.l	obj_x(a6)
; 		clr.l	obj_y(a6)
; 		clr.l	obj_x_spd(a6)
; 		clr.l	obj_y_spd(a6)
; 		lea	(RAM_LvlPlanes),a5
; 		clr.w	lvl_x(a5)
; 		clr.w	lvl_y(a5)
; 		movem.l	a6,-(sp)
; 		bsr	Level_Draw
; 		movem.l	(sp)+,a6
; @NotDbg:
		btst	#bitJoyMode,(RAM_Control_1+ExOnHold)
		beq.s	@NotWnd
		bra	PlyrDebugMove
@NotWnd:

; 		btst	#bitJoyX,(RAM_Control_1+ExOnPress)
; 		beq.s	@NotWnd3
; 		bchg	#3,(RAM_VidRegs+$C)
; 		bchg	#bitobj_flipH,obj_status(a6)
; 		bsr	Video_Update
; @NotWnd3:
; 		btst	#bitJoyY,(RAM_Control_1+ExOnPress)
; 		beq.s	@NotWnd2
; 		bchg	#bitobj_flipV,obj_status(a6)
; @NotWnd2:

; ----------------------------------
; Falling frame
; ----------------------------------

; 		btst	#bitobj_air,obj_status(a6)
; 		beq.s	@idleanim
; 		tst.l	obj_y_spd(a6)
; 		beq.s	@idleanim
; 		bmi.s	@idleanim
; 		move.b	#3,obj_anim_id(a6)
; @idleanim:

		lea	(RAM_LvlPlanes),a5
		move.w	lvl_size_y(a5),d0		; Bottomless pit
		lsl.w	#4,d0
		move.w	obj_y(a6),d1
		moveq	#0,d2
		move.b	obj_size+2(a6),d2
		lsl.w	#3,d2
		sub.w	d2,d1
		cmp.w	d0,d1
		bgt	PlyrLevelReset
		
		tst.w	plyr_hittime(a6)
		bne.s	@counting
		btst	#bitobj_hurt,obj_status(a6)
		beq.s	@no_action
		
		tst.w	plyr_hittime(a6)
		bne.s	@ignore
		sub.w	#1,(RAM_P1_Hits)
		move.w	#varHurtTimer,plyr_hittime(a6)
		
		tst.w	(RAM_P1_Hits)
		bne.s	@counting
 		bclr	#bitobj_hit,obj_status(a6)
		bclr	#bitobj_flipH,obj_status(a6)
		move.b	#2,obj_index(a6)		; Mode $02: dead
		move.b	#5,obj_anim_id(a6)		; Animation $05
		move.l	#$10000,obj_x_spd(a6)
		move.l	#-$40000,obj_y_spd(a6)
@ignore:
		rts
		
@counting:
		sub.w	#1,plyr_hittime(a6)
		bne.s	@no_action
		bclr	#bitobj_hurt,obj_status(a6)
@no_action:
		bra	PlyrPhysics
		
; =================================================================
; ------------------------------------------------
; Index $01: Main
; ------------------------------------------------

ObjPlyr_Die:
		lea	(RAM_LvlPlanes),a5
		move.l	obj_x_spd(a6),d6
		move.l	obj_y_spd(a6),d7
		add.l	#$4000,d7
		
		add.l	d6,obj_x(a6)
		add.l	d7,obj_y(a6)
		
		move.w	lvl_size_y(a5),d0
		lsl.w	#4,d0
		move.w	obj_y(a6),d1
		moveq	#0,d2
		move.b	obj_size+2(a6),d2
		lsl.w	#3,d2
		sub.w	d2,d1
		cmp.w	d0,d1
		bgt.s	PlyrLevelReset
		
		move.l	d6,obj_x_spd(a6)
		move.l	d7,obj_y_spd(a6)
		rts
		
; =================================================================
; ----------------------------------
; Level reset
; ----------------------------------

PlyrLevelReset:
		move.b	#1,(RAM_ModeReset)
		
		sub.w	#1,(RAM_P1_Lives)
		tst.w	(RAM_P1_Lives)
		bne.s	@ignore
		;GAME OVER stuff goes here
		clr.b	(RAM_GameMode)
		
@ignore:
		rts
		
; ----------------------------------

PlyrDebugMove:
		bclr	#bitPlyrClimb,plyr_status(a6)
		bclr	#bitobj_hurt,obj_status(a6)
		clr.b	obj_col(a6)
		
		btst	#bitJoyRight,(RAM_Control_1+OnHold)
		beq.s	@DNotRight
		add.l	#$50000,obj_x(a6)
		bclr	#bitobj_flipH,obj_status(a6)
@DNotRight:
		btst	#bitJoyLeft,(RAM_Control_1+OnHold)
		beq.s	@DNotLeft
		sub.l	#$50000,obj_x(a6)
		bset	#bitobj_flipH,obj_status(a6)
@DNotLeft:
		btst	#bitJoyDown,(RAM_Control_1+OnHold)
		beq.s	@DNotDown
		add.l	#$50000,obj_y(a6)
@DNotDown:
		btst	#bitJoyUp,(RAM_Control_1+OnHold)
		beq.s	@DNotUp
		sub.l	#$50000,obj_y(a6)
@DNotUp:
		move.l	#1,obj_x_spd(a6)		;Temporal
		move.l	#1,obj_y_spd(a6)
		
  		bra	Plyr_LvlCamera
  		
; ----------------------------------
; Player physics
; ----------------------------------

PlyrPhysics:
		move.l	obj_x_spd(a6),d6
		move.l	obj_y_spd(a6),d7

; ------------------------
; Animation ID
; ------------------------

		btst	#bitPlyrClimb,plyr_status(a6)
		bne.s	@walking
		btst	#bitobj_air,obj_status(a6)
		bne.s	@walking

		move.b	#1,obj_anim_id(a6)
		tst.l	d6
		bne.s	@walking
		clr.b	obj_anim_id(a6)
@walking:

; ***************
; X Speed stuff
; ***************

		bsr	@Player_Friction
		bsr	@Player_Walk
		add.l	d6,obj_x(a6)			;X + X Speed
		bsr	PlyrColRead_Wall
		
; ***************
; Y Speed stuff
; ***************
; 
		bsr	@Player_Jump
		add.l	d7,obj_y(a6)			;Y + Y Speed
  		bsr	PlyrColRead_Ceiling
		bsr	PlyrColRead_Floor

; ***************
; Save them
; ***************

		move.l	d6,obj_x_spd(a6)
		move.l	d7,obj_y_spd(a6)
		
 		bra	Plyr_LvlCamera
	
; =================================================================
; ------------------------------------------------
; Subs
; ------------------------------------------------

; **********************************
; Player Walk
; **********************************

@Player_Walk:
		move.l	d6,d4
		btst	#bitJoyRight,(RAM_Control_1+OnHold)
		beq.s	@NotRight
		btst	#bitPlyrClimb,plyr_status(a6)
		bne.s	@NotMuchRight
		moveq	#0,d0
		move.w	(RAM_LvlPlanes+lvl_maxcam_x),d0
		lsl.w	#4,d0
		move.w	obj_x(a6),d1
		cmp.w	d0,d1
		bgt.s	@NotRight
	
; 		tst.l	d4
; 		bpl.s	@NotRunningR
		move.l	#$1E000,d0
 		btst	#bitJoyB,(RAM_Control_1+OnHold)
 		beq.s	@NotRunningR
 		move.l	#$28000,d0
@NotRunningR:

		add.l	#$4800,d6
		cmp.l	d0,d6
		blt.s	@NotMuchRight
		move.l	d0,d6
@NotMuchRight:
		bclr	#bitobj_flipH,obj_status(a6)

@NotRight:
		btst	#bitJoyLeft,(RAM_Control_1+OnHold)
		beq.s	@NotLeft
		btst	#bitPlyrClimb,plyr_status(a6)
		bne.s	@NotMuchLeft
		tst.l	obj_x(a6)
		beq.s	@NotLeft
		bmi.s	@NotLeft
		
; 		tst.l	d4
; 		bmi.s	@NotRunningL
		move.l	#-$20000,d0
 		btst	#bitJoyB,(RAM_Control_1+OnHold)
 		beq.s	@NotRunningL
 		move.l	#-$30000,d0
@NotRunningL:

		
		sub.l	#$4800,d6
		cmp.l	d0,d6
		bgt.s	@NotMuchLeft
		move.l	d0,d6
@NotMuchLeft:
		bset	#bitobj_flipH,obj_status(a6)
@NotLeft:		
		rts
		
; **********************************
; Player Friction
; **********************************

@Player_Friction:
		move.l	#$2400,d4			;Friction
		tst.l	d6
		beq.s	@FineSpeed
		btst	#bitobj_flipH,obj_status(a6)
		bne.s	@Left
		sub.l	d4,d6
		bpl.s	@FineSpeed
		clr.l	d6
		rts
@Left:
		add.l	d4,d6
		bmi.s	@FineSpeed
		
@ignoreR:
		clr.l	d6
@FineSpeed:	
		rts

; **********************************
; Player jump
; **********************************

@Player_Jump:
		btst	#bitPlyrClimb,plyr_status(a6)
		bne.s	@JumpFromLadder
		btst	#bitPlyrCancelY,plyr_status(a6)
		bne.s	@JumpFromLadder
		
		btst	#bitJoyC,(RAM_Control_1+OnHold)
		beq	@IsFalling
		
 		cmp.w	#varJumpTimer,plyr_jumptmr(a6)
 		bne.s	@onair
  		btst	#bitcol_obj,obj_col(a6)
    		bne.s	@onair
  		btst	#bitcol_floor,obj_col(a6)
    		beq.s	@IsFalling
@onair:

		sub.w	#1,plyr_jumptmr(a6)
		bmi.s	@IsFalling

 		btst	#bitobj_air,obj_status(a6)
 		bne.s	@onair2

 		move.b	#varPlyAniJump,obj_anim_id(a6)
		bset	#bitobj_air,obj_status(a6)
     		bclr	#bitcol_floor,obj_col(a6)
     		bclr	#bitcol_obj,obj_col(a6)
   		move.l	#-$42000,d7
   		move.l	d6,d0
   		asr.l	#2,d0
   		tst.l	d0
   		bmi.s	@dontnegx
   		neg.l	d0
@dontnegx:
		add.l	d0,d7
		
  		move.l	#SndSfx_PlyrJump,d0
  		moveq 	#1,d1
  		moveq	#1,d2
  		bsr	Audio_Track_play
@onair2:
   		rts
  
; ----------------------------------

@JumpFromLadder:
		btst	#bitJoyC,(RAM_Control_1+OnPress)
		beq	@IsFalling
		
		bclr	#bitPlyrClimb,plyr_status(a6)
 		bset	#bitobj_air,obj_status(a6)
 		move.b	#2,obj_anim_id(a6)
   		clr.l	d6
   		clr.l	d7
 		rts
 		
; ----------------------------------

@IsFalling:
		btst	#bitPlyrClimb,plyr_status(a6)
		bne.s	@low_fall
   		btst	#bitcol_floor,obj_col(a6)
    		bne.s	@low_fall

 		add.l	#$4800,d7
		cmp.l	#$100000,d7
		blt.s	@low_fall
		move.l	#$100000,d7
@low_fall:
		rts
		
; **********************************
; Object to Level layout collision
; **********************************

; ----------------------------------
; floor collision
; ----------------------------------

PlyrColRead_Floor:
 		bclr	#bitcol_floor,obj_col(a6)
 		bclr	#bitobj_air,obj_status(a6)
 		
 		btst	#bitcol_obj,obj_col(a6)
 		bne.s	@dont
 		bset	#bitobj_air,obj_status(a6)
@dont:
 		bclr	#bitcol_obj,obj_col(a6)
 		
		tst.l	d7
		bmi.s	@going_up

; 		bsr	object_FindPrz_Floor		;TODO: no sirve en prizes
;  		btst	#7,d0
;  		beq.s	@cntrnrml
; 		clr.b	d0
; @cntrnrml:
; 		tst.b	d0
; 		bne	@przfloor_center

 		bsr 	object_FindPrz_FloorSides
 		
		tst.b	d0
		bne	@przfloor_right
		move.l	d1,d0
		tst.b	d0
		bne	@przfloor_left

		bsr	object_FindCol_Floor
		bsr	@center_special
		tst.b	d0
		bne.s	@found_center
 		bsr 	object_FindCol_FloorSides
		bsr	@right_special
		tst.b	d0
		bne	@found_sides
		move.l	d1,d0
		bsr	@left_special
		tst.b	d0
		bne	@found_sides
@going_up:

		rts
		
; ----------------------------------

@found_center:
		cmp.b	#1,d0
		beq	@floorsolid

		bra.s	@SlopeCenter
		
; ----------------------------------

@found_sides:
		cmp.b	#1,d0
		beq	@floorsolid
		rts

; ----------------------------------

@SlopeCenter:
   		tst.l	d7
   		bmi	@NoCol
   				
   		move.l	obj_y(a6),d1
   		move.l	d1,d2
  		lea	(col_SlopeData),a3
  		and.w	#$FF,d0
  		move.w	d0,d1
  		lsl.w	#4,d1
  		adda	d1,a3
 		move.l	obj_x(a6),d0
 		swap	d0
 		and.w	#$F,d0
 		move.b	(a3,d0.w),d0
    		and.w	#$F,d0
    		and.l	#$FFF00000,d1
  		swap	d0
  		and.l	#$FFFF0000,d0
 		add.l	d0,d1
 		
 		;TODO: no recuerdo pa que
 		;era este fix
 		; tambien ver que pedo
 		; porque dominou no
 		; se queda pegado a los slopes
 		
;  		move.l	obj_x_spd(a6),d0
;  		btst	#bitobj_flipH,obj_status(a6)
;  		beq.s	@right
;  		neg.l	d0
; @right:
; 		cmp.l	#$20000,d0
; 		bge.s	@dontchk
  		btst	#bitobj_air,obj_status(a6)
  		beq.s	@dontchk
  		cmp.l	d1,d2
  		blt.s	@NoCol
@dontchk:
 		move.l	#$50000,d7
  		move.l	d1,obj_y(a6)
   		bsr	@objFloorFlags
@NoCol:
		rts
		
; ----------------------------------
; Event block: on floor
; ----------------------------------

@center_special:
		btst	#6,d0
		beq.s	@return
		bsr	plyrColEntry
		move.w	(a4),d4
		bra	plyrColGo
		
@left_special:
		btst	#6,d0
		beq.s	@return
		bsr	plyrColEntry
		move.w	2(a4),d4
		bra	plyrColGo
		
@right_special:
		btst	#6,d0
		beq.s	@return
		bsr	plyrColEntry
		move.w	4(a4),d4
		bra	plyrColGo
@return:
		rts

; ----------------------------------
; Prizes on floor
; ----------------------------------

@przfloor_center:
@przfloor_left:
@przfloor_right:
		moveq	#1,d4
		
		cmp.b	#$20,d0
		beq.s	@trampoline
		
		cmp.b	#$40,d0		;> $40?
		blt.s	@a_coin
		and.b	#$3F,d0
		moveq	#1,d4
		tst.b	d0
		beq.s	@setcoin
		moveq	#5,d4
@setcoin:
		add.w	d4,(RAM_P1_Coins)
  		cmp.w	#100,(RAM_P1_Coins)
  		blt.s	@dontadd1up
  		clr.w	(RAM_P1_Coins)
  		add.w	#1,(RAM_P1_Lives)
@dontadd1up:

		bsr	Prize_Delete
		bsr	Level_HidePrize
		
  		move.l	#SndSfx_COIN,d0
  		moveq 	#2,d1
  		moveq	#1,d2
  		bsr	Audio_Track_play
		moveq	#0,d4
@a_coin:
		tst.w	d4
		bne.s	@floorsolid
		rts
		
; $20

@trampoline:
		bsr	goToTrampolineWhy
		
		move.l	#-$80000,d7
		moveq	#1,d4
		rts
		
; ----------------------------------

; @check_prz_id:
;    		bsr	Object_PrzActionCeil
;   		tst.w	d4
;   		bne	@ceilingsolid
; 		rts
		
;       	bsr	level_CheckPrize
;        	bne	@floorsolid
;        	rts

; ----------------------------------
		
@floorsolid:
		bsr	@objFloorFlags
 		and.l	#$FFF00000,obj_y(a6)
		clr.l	d7
		rts

; ----------------------------------

@objFloorFlags:
  		bset	#bitcol_floor,obj_col(a6)
		bclr	#bitobj_air,obj_status(a6)
		
		btst	#bitJoyC,(RAM_Control_1+OnHold)
		bne	@onhold
    		move.w	#varJumpTimer,plyr_jumptmr(a6)
@onhold:
 		bclr	#bitPlyrClimb,plyr_status(a6)
		bclr	#bitPlyrCancelY,plyr_status(a6)
		rts
		
; ----------------------------------
; ceiling collision
; ----------------------------------

PlyrColRead_Ceiling:
		bclr	#bitcol_ceiling,obj_col(a6)
		tst.l	d7
		bpl.s	@doing_down
		
 		bsr 	object_FindCol_CeilingSides
 		move.l	d0,d2
 		move.l	d1,d3
 		bsr 	object_FindPrz_CeilingSides
		tst.b	d0
		bne	@przceil_right
		move.l	d2,d0
		bsr	@right_special
		tst.b	d0
 		bne	@ceiling_sides
		move.l	d1,d0
		tst.b	d0
		bne	@przceil_left
		move.l	d3,d0
		bsr	@left_special
		tst.b	d0
		bne	@ceiling_sides
		
		bsr	object_FindPrz_Ceiling
		tst.b	d0
		bne	@przceil_center
		bsr	object_FindCol_Ceiling
		bsr	@center_special
		tst.b	d0
		bne.s	@ceiling_center
		
@doing_down:
		rts

; ----------------------------------

@ceiling_center:
; 		cmp.b	#1,d0
;  		beq.s	@ceilingsolid
;  		rts

; ----------------------------------

@ceiling_sides:
		cmp.b	#1,d0
		beq.s	@ceilingsolid
		rts

; ----------------------------------

@ceilingsolid:
		bset	#bitobj_air,obj_status(a6)
 		bset	#bitcol_ceiling,obj_col(a6)
		move.w	#-1,plyr_jumptmr(a6)
; 		move.l	#$10000,d7
;         	add.w	#$10,obj_y(a6)
;       	and.l	#$FFF80000,obj_y(a6)

; 		move.l	d0,d1
; 		lsr.l	#4,d1
; 		and.w	#$FFF0,d1
; 		add.w	#$10,d1
; 		add.w	#$20,d1
; 		move.w	d1,obj_y(a6)
		
 		rts
		
; ----------------------------------
; Event block: ceiling
; ----------------------------------

@center_special:
		btst	#6,d0
		beq.s	@return
		bsr	plyrColEntry
		move.w	$C(a4),d4
		bra	plyrColGo
		
@left_special:
		btst	#6,d0
		beq.s	@return
		bsr	plyrColEntry
		move.w	$E(a4),d4
		bra	plyrColGo
		
@right_special:
		btst	#6,d0
		beq.s	@return
		bsr	plyrColEntry
		move.w	$10(a4),d4
		bra	plyrColGo
		
@return:
		rts
		
; ----------------------------------

@przceil_center:
@przceil_left:
@przceil_right:
   		bsr	Object_PrzActionCeil
  		tst.w	d4
  		bne	@ceilingsolid
		rts
		
; ----------------------------------
; d0 - LEFT
; d1 - RIGHT
; d2 - CENTER
; ----------------------------------

; @prizes_ceiling:
; 		move.l	d0,d3
; 		btst	#bitobj_flipH,obj_status(a6)
; 		beq.s	@itsleft
; 		exg.l	d1,d3
; @itsleft:
; 
;    		move.l	d2,d0
;    		tst.b	d0
;    		beq.s	@przc_no_c
;   		bsr	Object_PrzActionCeil
;  		tst.w	d4
;  		bne	@ceilingsolid
; @przc_no_c:
; 
; 		move.l	d1,d0
; 		tst.b	d0
; 		beq.s	@przc_no_r
; 		bsr	Object_PrzActionCeil
; 		tst.w	d4
; 		bne	@ceilingsolid
; @przc_no_r:
;  		move.l	d3,d0
;  		tst.b	d0
;  		beq.s	@przc_no_l
;  		bsr	Object_PrzActionCeil
; 		tst.w	d4
; 		bne	@ceilingsolid
; @przc_no_l:
; 		rts
		
; **********************************
; Wall collision
; **********************************

PlyrColRead_Wall:
		bclr	#bitcol_wall_r,obj_col(a6)
		bclr	#bitcol_wall_l,obj_col(a6)
		
		; Ignorar PRIZEs si Player esta
		; en modo escalera
 		btst	#bitPlyrClimb,plyr_status(a6)
 		bne.s	@okaydntchk
		bsr	object_FindPrz_Wall
		move.l	d0,d2
		bsr	object_FindPrz_WallSides
 		btst	#7,d0
 		beq.s	@righthidn
 		clr.b	d0
@righthidn:
		tst.b	d0
		bne	@przwall_right
		move.l	d1,d0
 		btst	#7,d0
 		beq.s	@lefthidn
 		clr.b	d0
@lefthidn:
		tst.b	d0
		bne	@przwall_left
@okaydntchk:

		bsr	object_FindCol_Wall
		bsr	@center_special
		tst.b	d0
		bne.s	@wall_center
		
 		bsr 	object_FindCol_WallSides
		bsr	@right_special
		tst.b	d0
		bne	@wall_right
		
		move.l	d1,d0
		bsr	@left_special
		tst.b	d0
		bne	@wall_left
		rts
		
; ----------------------------------

@wall_center:
		cmp.w	#1,d0
 		beq	@wallsolid_slope
		
		tst.l	d7
		bmi.s	@NoCol_LR
   		btst	#bitobj_air,obj_status(a6)
   		bne.s	@NoCol_LR
    		clr.l	d7	
    		bclr	#bitobj_air,obj_status(a6)
    		
		move.w	obj_y(a6),d1
		sub.w	#1,d1
		move.w	d1,d3
		and.w	#$FFF0,d1 		
     		lea	(col_SlopeData),a3
      		and.w	#$FF,d0
     		lsl.w	#4,d0
      		adda	d0,a3
      		move.w	obj_x(a6),d0
      		and.w	#$F,d0
      		move.b	(a3,d0.w),d2
      		and.w	#$F,d2
      		add.w	d2,d1
      		
 		btst	#bitobj_air,obj_status(a6)
		beq.s	@dontchkLR
  		cmp.w	d1,d3
  		blt.s	@NoCol_LR
@dontchkLR:
   		move.w	d1,obj_y(a6)

@NoCol_LR:
		rts

; ----------------------------------
; Prizes on walls
; ----------------------------------	

@przwall_left:
		bsr	@check_wll_prz
   		tst.w	d4
   		bne	@wallsolid_l
		rts
@przwall_right:
		bsr	@check_wll_prz
   		tst.w	d4
   		bne	@wallsolid_r
		rts
	
; ----------------------------------

@check_wll_prz:
		moveq	#1,d4
		
		cmp.b	#$20,d0
		beq.s	@trampolinewll
		
		cmp.b	#$40,d0		;> $40?
		blt.s	@notcoin
		and.b	#$3F,d0
		moveq	#1,d4
		tst.b	d0
		beq.s	@setcoin
		moveq	#5,d4
@setcoin:
		add.w	d4,(RAM_P1_Coins)
  		cmp.w	#100,(RAM_P1_Coins)
  		blt.s	@dontadd1up2
  		clr.w	(RAM_P1_Coins)
  		add.w	#1,(RAM_P1_Lives)
@dontadd1up2:

		bsr	Prize_Delete
		bsr	Level_HidePrize
; 		move.l	d0,(RAM_LvlPlanes+lvl_przreq)
; 		bset	#bitLvlHidePrz,(RAM_LvlPlanes+lvl_flags)

  		move.l	#SndSfx_COIN,d0
  		moveq 	#2,d1
  		moveq	#1,d2
  		bsr	Audio_Track_play
		moveq	#0,d4
		
@notcoin:
		rts
		
@trampolinewll:
		bsr	goToTrampolineWhy

		and.w	#$FFF8,obj_x(a6)
		
		move.l	#-$80000,d0
; 		btst	#bitobj_flipH,obj_status(a6)
; 		bne.s	@lefty
; 		tst.l	d6
; 		bpl.s	@righy
; @lefty:
; 		neg.l	d0
; @righy:
		move.l	d0,d6
		moveq	#0,d4
		rts
		
; ----------------------------------

@wall_right:
; 		btst	#bitobj_flipH,obj_status(a6)
; 		bne.s	@return_w
  		cmp.b	#2,d0
  		bge.s	@return_w
 		cmp.b	#1,d0
  		beq.s	@wallsolid_r
  		rts
  		
@wall_left:
; 		btst	#bitobj_flipH,obj_status(a6)
; 		beq.s	@return_w
  		cmp.b	#2,d0
  		bge.s	@return_w
  		cmp.b	#1,d0
  		beq.s	@wallsolid_l
@return_w:
		rts
		
; ----------------------------------

@wallsolid_r:
		and.w	#$FFF8,obj_x(a6)
		
		clr.l	d6
		bset	#bitcol_wall_r,obj_col(a6)
		rts

; ----------------------------------

@wallsolid_l:
		add.w	#4,obj_x(a6)
		and.w	#$FFF8,obj_x(a6)
		
; 		moveq	#0,d4
; 		move.b	obj_size(a6),d4
; 		lsl.w	#3,d4
; 		move.w	obj_x(a6),d5
; 		sub.w	#1,d5
; 		sub.w	d4,d5
; 		tst.w	d5
; 		bpl.s	@noleftlvl
; 		
; 		moveq	#0,d0
; 		add.w	d4,d0
; 		move.w	d0,obj_x(a6)
; 		bra.s	@leftend
; @noleftlvl:
; 		move.l	d0,d2
; 		swap	d2
; 		and.w	#$FFF0,d2
; 		add.w	#$10,d2
; 		add.w	#8,d2
; 		move.w	d2,obj_x(a6)
; @leftend:
		clr.l	d6
		bset	#bitcol_wall_l,obj_col(a6)
		rts

; ----------------------------------

@wallsolid_slope:
     		btst	#bitobj_flipH,obj_status(a6)
		bne.s	@wllflg_l
		bset	#bitcol_wall_r,obj_col(a6)
		rts
@wllflg_l:
		bset	#bitcol_wall_l,obj_col(a6)
		rts
 		
; ----------------------------------
; Event block: on wall
; ----------------------------------

@center_special:
		btst	#6,d0
		beq.s	@return
		bsr	plyrColEntry
		move.w	6(a4),d4
		bra	plyrColGo
		
@left_special:
		btst	#6,d0
		beq.s	@return
		bsr	plyrColEntry
		move.w	8(a4),d4
		bra	plyrColGo
		
@right_special:
		btst	#6,d0
		beq.s	@return
		bsr	plyrColEntry
		move.w	$A(a4),d4
		bra	plyrColGo
		
@return:
		rts
		
; ---------------------------------------------
; EVENT BLOCKS ($80+)
; ---------------------------------------------

plyrColEntry:
		move.l	d0,d4
		and.w	#$3F,d4
		mulu.w	#$12,d4
		lea	plyEvnList(pc),a4
		adda	d4,a4
		rts
plyrColGo:
		and.l	#$FFFF,d4
		add.l	#plyEvnList,d4
		movea.l	d4,a4
		jmp	(a4)
	
; ---------------------------------------------
;   Floor Center |   Floor Left |   Floor Right
;    Wall Center |    Wall Left |    Wall Right
; Ceiling Center | Ceiling Left | Ceiling Right
; 
; d0 - Return collision (xpos|ypos|byte)
; DO NOT USE d1 WHILE CHECKING SIDES
; ---------------------------------------------

plyEvnList:
	; $40 - Exit level (old)
	dc.w @event40-plyEvnList,@event40-plyEvnList,@event40-plyEvnList
	dc.w @event40-plyEvnList,@event40-plyEvnList,@event40-plyEvnList
	dc.w @event40-plyEvnList,@event40-plyEvnList,@event40-plyEvnList
	; $41 - Ladder (climbing mode)
	dc.w @event41_flr-plyEvnList,@event41_flrsd-plyEvnList,@event41_flrsd-plyEvnList
	dc.w @event41_wll-plyEvnList,       @unused-plyEvnList,       @unused-plyEvnList
	dc.w      @unused-plyEvnList,       @unused-plyEvnList,       @unused-plyEvnList
	; $42 - Spikes (Up)
	dc.w @event42-plyEvnList,@event42-plyEvnList,@event42-plyEvnList
	dc.w @event_solid-plyEvnList,@event_solid-plyEvnList,@event_solid-plyEvnList
	dc.w @event_solid-plyEvnList,@event_solid-plyEvnList,@event_solid-plyEvnList
	;$83
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$84
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$85
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$86
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$87
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$88
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$89
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$8A
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$8B
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$8C
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$8D
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$8E
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$8F
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	
	;$90
	dc.w @event50_check-plyEvnList,@event50_check-plyEvnList,@event50_check-plyEvnList
	dc.w @event50_check-plyEvnList,@event50_check-plyEvnList,@event50_check-plyEvnList
	dc.w @event50_check-plyEvnList,@event50_check-plyEvnList,@event50_check-plyEvnList
	;$91
	dc.w @event51_check-plyEvnList,@event51_check-plyEvnList,@event51_check-plyEvnList
	dc.w @event51_check-plyEvnList,@event51_check-plyEvnList,@event51_check-plyEvnList
	dc.w @event51_check-plyEvnList,@event51_check-plyEvnList,@event51_check-plyEvnList
	;$92
	dc.w @event52_check-plyEvnList,@event52_check-plyEvnList,@event52_check-plyEvnList
	dc.w @event52_check-plyEvnList,@event52_check-plyEvnList,@event52_check-plyEvnList
	dc.w @event52_check-plyEvnList,@event52_check-plyEvnList,@event52_check-plyEvnList
	;$93
	dc.w @event53_check-plyEvnList,@event53_check-plyEvnList,@event53_check-plyEvnList
	dc.w @event53_check-plyEvnList,@event53_check-plyEvnList,@event53_check-plyEvnList
	dc.w @event53_check-plyEvnList,@event53_check-plyEvnList,@event53_check-plyEvnList
	;$94
	dc.w @event_solid-plyEvnList,@event_solid-plyEvnList,@event_solid-plyEvnList
	dc.w @event_solid-plyEvnList,@event_solid-plyEvnList,@event_solid-plyEvnList
	dc.w @event54_cei-plyEvnList,@event54_cei-plyEvnList,@event54_cei-plyEvnList
	;$95
	dc.w @event_solid-plyEvnList,@event_solid-plyEvnList,@event_solid-plyEvnList
	dc.w @event_solid-plyEvnList,@event_solid-plyEvnList,@event_solid-plyEvnList
	dc.w @event55_cei-plyEvnList,@event55_cei-plyEvnList,@event55_cei-plyEvnList
	;$96
	dc.w @event_solid-plyEvnList,@event_solid-plyEvnList,@event_solid-plyEvnList
	dc.w @event_solid-plyEvnList,@event_solid-plyEvnList,@event_solid-plyEvnList
	dc.w @event56_cei-plyEvnList,@event56_cei-plyEvnList,@event56_cei-plyEvnList
	;$97
	dc.w @event_solid-plyEvnList,@event_solid-plyEvnList,@event_solid-plyEvnList
	dc.w @event_solid-plyEvnList,@event_solid-plyEvnList,@event_solid-plyEvnList
	dc.w @event57_cei-plyEvnList,@event57_cei-plyEvnList,@event57_cei-plyEvnList
	;$98
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$99
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$9A
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$9B
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$9C
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$9D
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$9E
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$9F
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList

	;$A0
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$A1
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$A2
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$A3
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$A4
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$A5
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$A6
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$A7
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$A8
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$A9
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$AA
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$AB
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$AC
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$AD
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$AE
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	;$AF
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
	dc.w @unused-plyEvnList,@unused-plyEvnList,@unused-plyEvnList
		
; ----------------------------------
; EVENT $80
; ----------------------------------

@event40:
		clr.b	d0
		tst.b	(RAM_ModeReset)
		bne.s	@already
  		add.w	#1,(RAM_CurrLevel)
		move.b	#1,(RAM_ModeReset)
@already:
		rts
		
; ----------------------------------
; EVENT $41
; ----------------------------------

@event41_flr:
		clr.l	d2
		bsr	object_FindCol_Center
		cmp.b	#$41,d0
		beq	@unused_flag
		moveq	#1,d2	
@notclimb:

		
		btst	#bitJoyDown,(RAM_Control_1+OnHold)
		beq	@unused_flag
		
		move.l	d0,d2
		bsr	object_FindCol_FloorSides
		cmp.b	#$41,d0
		beq.s	@usethis
		move.l	d1,d0
		cmp.b	#$41,d0
		beq.s	@usethis
		move.l	d2,d0
@usethis:
		clr.l	d6
		clr.l	d7
		and.l	#$FFF00000,d0
		add.l	#$80000,d0
		move.l	d0,obj_x(a6)
		bset	#bitPlyrClimb,plyr_status(a6)
		bclr	#bitcol_floor,obj_col(a6)
  		move.b	#4,obj_anim_id(a6)
 		move.b	#12,obj_frame(a6)		;FRAME 12
		add.w	#8,obj_y(a6)
		move.w	#-1,plyr_jumptmr(a6)

; 		clr.l	d0
		rts
 		
; --------------------

@event41_flrsd:
; 		clr.l	d0
; 		rts
		
; --------------------

@event41_cei:
		clr.l	d0
		rts
		
; --------------------

@event41_wll:
;  		clr.l	d0
		btst	#bitPlyrClimb,plyr_status(a6)
		beq.s	@notwaitclmb
 		move.b	#-1,obj_anim_id(a6)
		clr.l	d6
		clr.l	d7
@notwaitclmb:
; 		move.l	d0,d2
 		btst	#bitJoyUp,(RAM_Control_1+OnHold)
 		beq.s	@dontclimb
  		move.b	#4,obj_anim_id(a6)
 		btst	#bitPlyrClimb,plyr_status(a6)
 		bne.s	@alrdup
 		
  		bsr	object_FindCol_Center
 		cmp.b	#$41,d0
 		beq.s	@canclimb
   		bsr	object_FindCol_Floor
 		cmp.b	#$41,d0
 		bne.s	@dontclimb
@canclimb:
 		and.l	#$FFF00000,d0
  		add.l	#$80000,d0
 		move.l	d0,obj_x(a6)
 		
@alrdup:
 		sub.l	#$16000,obj_y(a6)
 		clr.l	d6
 		clr.l	d7
  		bset	#bitPlyrClimb,plyr_status(a6)
		move.w	#-1,plyr_jumptmr(a6)
 
@dontclimb:
		btst	#bitJoyDown,(RAM_Control_1+OnHold)
		beq.s	@dontclimbd
		
		btst	#bitPlyrClimb,plyr_status(a6)
		bne.s	@alrddwn
		bsr	object_FindCol_Center
		cmp.b	#$41,d0
		bne.s	@dontclimbd
		and.l	#$FFF00000,d0
 		add.l	#$80000,d0
		move.l	d0,obj_x(a6)
@alrddwn:
		add.l	#$16000,obj_y(a6)
		clr.l	d6
		clr.l	d7
 		bset	#bitPlyrClimb,plyr_status(a6)
 		move.b	#4,obj_anim_id(a6)
		move.w	#-1,plyr_jumptmr(a6)
@dontclimbd:

		clr.l	d0
		rts

; --------------------

@unused_flag:
 		move.b	d2,d0
 		rts

; ----------------------------------
; EVENT $82
; ----------------------------------

@event42:
		bset	#bitobj_hurt,obj_status(a6)
		
		move.b	#1,d0
		rts
		
; ----------------------------------
; EVENT $90
;
; CHECKS COLOR
; ----------------------------------

@event50_check:
		cmp.w	#$00E,(RAM_Palette+$26)
		beq	@event_solid
		bra	@unused

; ----------------------------------
; EVENT $91
;
; CHECKS COLOR
; ----------------------------------

@event51_check:
		cmp.w	#$E00,(RAM_Palette+$2C)
		beq	@event_solid
		bra	@unused
		
; ----------------------------------
; EVENT $92
;
; CHECKS COLOR
; ----------------------------------

@event52_check:
		cmp.w	#$0E0,(RAM_Palette+$32)
		beq	@event_solid
		bra	@unused

; ----------------------------------
; EVENT $93
;
; CHECKS COLOR
; ----------------------------------

@event53_check:
		cmp.w	#$0EE,(RAM_Palette+$38)
		beq	@event_solid
		bra	@unused
		
; ----------------------------------
; EVENT $94
; 
; CHECKS COLOR
; ----------------------------------

@event54_cei:
		move.l	#$03231102,d2
		cmp.w	#$00E,(RAM_Palette+$26)
		bne.s	@fade_this
		move.l	#$04231102,d2
@fade_this:
		tst.b	(RAM_PalFadeSys+$18)
		bne.s	@busy_pal
		move.l	d2,(RAM_PalFadeSys+$18)
@busy_pal:
		move.b	#1,d0
		rts

; ----------------------------------
; EVENT $95
; 
; CHECKS COLOR
; ----------------------------------

@event55_cei:
		move.l	#$03831402,d2
		cmp.w	#$E00,(RAM_Palette+$2C)
		bne.s	@fade_this_b
		move.l	#$04831402,d2
@fade_this_b:
		tst.b	(RAM_PalFadeSys+$18)
		bne.s	@busy_pal_b
		move.l	d2,(RAM_PalFadeSys+$18)
@busy_pal_b:
		move.b	#1,d0
		rts
	
; ----------------------------------
; EVENT $96
; 
; CHECKS COLOR
; ----------------------------------

@event56_cei:
		move.l	#$03431702,d2
		cmp.w	#$0E0,(RAM_Palette+$32)
		bne.s	@fade_this_g
		move.l	#$04431702,d2
@fade_this_g:
		tst.b	(RAM_PalFadeSys+$18)
		bne.s	@busy_pal_g
		move.l	d2,(RAM_PalFadeSys+$18)
@busy_pal_g:
		move.b	#1,d0
		rts

; ----------------------------------
; EVENT $97
; 
; CHECKS COLOR
; ----------------------------------

@event57_cei:
		move.l	#$03631A02,d2
		cmp.w	#$0EE,(RAM_Palette+$38)
		bne.s	@fade_this_y
		move.l	#$04631A02,d2
@fade_this_y:
		tst.b	(RAM_PalFadeSys+$18)
		bne.s	@busy_pal_y
		move.l	d2,(RAM_PalFadeSys+$18)
@busy_pal_y:
		move.b	#1,d0
		rts
		
; ----------------------------------
; Full solid
; ----------------------------------

@event_solid:
		move.b	#1,d0
		rts
		
; ----------------------------------
; Return
; ----------------------------------

@unused:
		clr.l	d0
		rts
		
; ---------------------------------------------
; Move level camera
; ---------------------------------------------

Plyr_LvlCamera:
 		lea	(RAM_LvlPlanes),a5
 		
; 		move.b	lvl_settings(a5),d0
; 		and.w	#$F,d0
; 		add.w	d0,d0
; 		move.w	@ScrollTypes(pc,d0.w),d1
; 		jmp	@ScrollTypes(pc,d1.w)
; 		
; ; -----------------------------------
; 
; @ScrollTypes:
; 		dc.w @Scrl_Normal-@ScrollTypes
; 		dc.w @Scrl_Section-@Scrolltypes
; 		dc.w 0
; 		dc.w 0
; 		dc.w 0
; 		dc.w 0
; 		dc.w 0
; 		dc.w 0
; 		dc.w 0
	
; -----------------------------------
; Default scroll
; 
; Autochecks the level size
; -----------------------------------

@Scrl_Normal:
		moveq	#0,d2
		moveq	#0,d3
		
		move.w	#320,d4
		move.b	(RAM_VidRegs+$C),d0
		and.w	#%10000001,d0
		bne.s	@normal_hor
		move.w	#256,d4
@normal_hor:
		move.w	d4,d0
		lsr.w	#4,d0
		move.w	lvl_maxcam_x(a5),d1
		cmp.w	d0,d1
		ble.s	@DontScrollHor
		
		move.w	obj_x(a6),d0
		moveq	#0,d5
		move.w	d4,d1
		lsr.w	#1,d1
		sub.w	d1,d0
		bmi.s	@Wait_X
		move.w	d0,d5
		
 		move.w	lvl_x(a5),d1
 		cmp.w	d5,d1
 		beq.s	@Wait_X		
 		moveq	#bitLvlDirR,d0
  		cmp.w	d1,d5
  		bgt.s	@RightDir
  		moveq	#bitLvlDirL,d0	
@RightDir:
  		bset	d0,lvl_flags(a5)
 		
@Wait_X:
		move.w	lvl_maxcam_x(a5),d1
		move.w	d4,d0
		lsr.w	#4,d0
		sub.w	d0,d1
		move.w	d5,d0
		sub.w	#1,d0
		lsl.w	#4,d1
		cmp.w	d1,d0
		blt.s	@NotEnd_X
		move.w	d1,d5
@NotEnd_X:
		move.w	d5,d0
		lsr.w	#4,d0
		move.w	d5,lvl_x(a5)

@DontScrollHor:

; ------------------------
; Update Vertical
; scrolling
; ------------------------

 		cmp.w	#(224/16),lvl_maxcam_y(a5)
 		ble	@single_Y
 		
  		move.w	lvl_y(a5),d5
  		move.w	obj_y(a6),d4
  		sub.w	lvl_y(a5),d4
  		
  		cmp.w	#(224/2)-8,d4
  		blt.s	@Do_Up
  		cmp.w	#(224/2)+14,d4
  		ble.s	@Set_Y
  		
		move.w	obj_y(a6),d0
		sub.w	#(224/2)+14,d0
		move.w	d0,d5
      		bset	#bitLvlDirD,lvl_flags(a5)
      		bra.s	@Set_Y
      		
@Do_Up:
		move.w	obj_y(a6),d0
		sub.w	#(224/2)-8,d0
		move.w	d0,d5
      		bset	#bitLvlDirU,lvl_flags(a5)
      		
		bra.s	@Set_Y
		
@old_yscrl:
  		move.w	obj_y(a6),d5			; Old
 		move.w	#(224/2)+$10,d4
 		sub.w	d4,d5
     		bset	#bitLvlDirD,lvl_flags(a5)
     		bset	#bitLvlDirU,lvl_flags(a5)
     		
;  		sub.w	#((224/2)+$10),d5
;  		move.w	obj_y(a6),d0			; New
;  		sub.w	#((224/2)+$20),d0
;  		add.w	lvl_y(a5),d0
;  		asr.w	#3,d0
;  		add.w	d0,d0
;  		move.w	d0,d5
 		
;  		moveq	#bitLvlDirD,d2
;    		cmp.w	d5,d1
;    		bgt.s	@drwydown
;    		bset	#bitLvlDirU,d2
; @drwydown:

;     		bset	#bitLvlDirD,lvl_flags(a5)
;     		bset	#bitLvlDirU,lvl_flags(a5)
   		
; --------------------------------
 	
@Set_Y:
 		tst.w	d5
 		bpl.s	@onyplus
 		clr.w	d5
@onyplus:
		moveq	#0,d1
  		move.w	lvl_maxcam_y(a5),d1
  		sub.w	#(224/16),d1
  		lsl.w	#4,d1
;   		swap	d1
  		cmp.w	d1,d5
  		blt.s	@notbotmd
  		move.w	d1,d5
@notbotmd:
		move.w	d5,lvl_y(a5)
		
@single_Y:
		rts
; 		
; ; -----------------------------------
; ; Dungeon Scroll
; ; -----------------------------------
; 
; @Scrl_Section:
; 		btst	#bitobj_flipH,obj_status(a6)
; 		bne.s	@LeftCheck
; 		
; ; RIGHT
; 
;  		btst	#0,plyr_status(a6)
;  		bne.s	@MoveRight
;  		
; 		move.w	obj_x(a6),d1
; 		move.w	#320,d0
; 		move.w	d0,d2
; 		add.w	lvl_x(a5),d2
; 		move.w	d2,plyr_lvltrgt(a6)
; 		add.w	#8,d0
;  		add.w	lvl_x(a5),d0
;  		cmp.w	d0,d1
; 		blt.s	@UpDownChk
;  		
;  		bset	#0,plyr_status(a6)
;  		clr.l	obj_x_spd(a6)
;  		clr.l	obj_y_spd(a6)
; 
; @MoveRight:
;   		move.w	lvl_x(a5),d1
;  		lea	(RAM_ScrlHor),a4
;  		move.w	#224-1,d3
; @doline2:
;  		move.w	d1,d0
;  		neg.w	d0
;  		move.w	d0,(a4)+
;  		asr.w	#4,d0
;  		move.w	d0,(a4)+
;  		dbf	d3,@doline2
;  		
;   		move.w	plyr_lvltrgt(a6),d0
;   		move.w	lvl_x(a5),d1
;   		cmp.w 	d0,d1
;   		bcs.s	@KeepScrlR
;  		bclr	#0,plyr_status(a6)
;   		move.w	d1,lvl_x(a5)
; 		rts
; @KeepScrlR:
;  		add.w	#4,lvl_x(a5)
;       		bset	#bitLvlDirR,lvl_flags(a5)
;        		rts
; 		
; @LeftCheck:
;        		
; 		
; @UpDownChk:
;  		bclr	#0,plyr_status(a6)
; 		rts
		
; =================================================================
; 
Plyr_SetStartPos:
  		lea	(RAM_ObjBuffer),a6
 		lea	(RAM_LvlPlanes),a5
 		
 		move.w	d0,obj_y(a6)
 		swap	d0
 		move.w	d0,obj_x(a6)
 		
; ----------------------------------------
 
		move.w	#320,d4
; 		btst	#bit_hortype,lvl_prio(a5)
; 		beq.s	@normal_hor
; 		move.w	#256,d4
; @normal_hor:
		move.w	d4,d0
		lsr.w	#4,d0
		move.w	lvl_maxcam_x(a5),d1
		cmp.w	d0,d1
		ble.s	@DontScrollHor
		
		move.w	obj_x(a6),d3
		moveq	#0,d2
		move.w	d4,d1
		lsr.w	#1,d1
		sub.w	d1,d3
		bmi.s	@Wait_X
		move.w	d3,d2
@Wait_X:
		move.w	lvl_maxcam_x(a5),d1
		move.w	d4,d0
		lsr.w	#4,d0
		sub.w	d0,d1
		move.w	d2,d0
		sub.w	#1,d0
		lsl.w	#4,d1
		cmp.w	d1,d0
		blt.s	@NotEnd_X
		move.w	d1,d2
@NotEnd_X:
		move.w	d2,d0
		lsr.w	#4,d0
		move.w	d2,lvl_x(a5)

@DontScrollHor:

; ----------------------------------------

		clr.w	lvl_y(a5)
 		cmp.w	#(224/16),lvl_maxcam_y(a5)
 		ble.s	@Return
		move.w	obj_y(a6),d3
		moveq	#0,d2
		sub.w	#((224/2)+$14),d3	;aprox
		bmi.s	@Wait_Y
		move.w	d3,d2
@Wait_Y:
 		move.w	lvl_maxcam_y(a5),d1
 		sub.w	#(224/16),d1
 		move.w	d2,d0
 		sub.w	#1,d0
 		lsl.w	#4,d1
 		cmp.w	d1,d0
 		blt.s	@NotEnd_Y
 		move.w	d1,d2
@NotEnd_Y:
		move.w	d2,lvl_y(a5)
 		
@Return:
 		rts

; =================================================================
; ------------------------------------------------
; EXTERNAL Routines for the player
; ------------------------------------------------

; TODO

; =================================================================
; ------------------------------------------------
; Data
; ------------------------------------------------
		
Ani_Player:
		dc.w @Idle-Ani_Player		;$00
		dc.w @Walk-Ani_Player
		dc.w @Jump_1-Ani_Player
 		dc.w @Jump_2-Ani_Player
 		dc.w @ClimbMove-Ani_Player	;$04
 		dc.w @Die-Ani_Player
		even
@Idle:
 		dc.b 6
 		dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
		dc.b -1
		even
@Jump_1:	
 		dc.b 4
 		dc.b $A
		dc.b -1
		even
@Jump_2:	
 		dc.b 4
  		dc.b $B
 		dc.b -1
 		even
@Walk:
 		dc.b 3
 		dc.b 2,3,4,5,6,7,8,9
		dc.b -1
		even
@ClimbMove:
		dc.b 4
		dc.b 12,13,14,15,14,13
		dc.b -1
		even	
@Die:
		dc.b 4
		dc.b 16
		dc.b -1
		even
