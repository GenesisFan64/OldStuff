; =================================================================
; Object
; 
; Player
; =================================================================

; =================================================================
; ------------------------------------------------
; Variables
; ------------------------------------------------

varPlyrVRAM	equ	($6000+$570)
varScrlHor	equ	320
varJumpTimer	equ	$C

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

  		bsr	Object_ShowPoints
 		
 		;Render
    		move.l	#(varPlyrVRAM<<16),d0
   		move.b	obj_frame(a6),d0
 		move.l	#ani_player,d1
		bsr	Object_Animate
		
   		move.b	obj_frame(a6),d0	
 		move.l	#map_player,d1
  		bsr	Object_Show
 		
   		move.l	#(varPlyrVRAM<<16),d0
   		move.b	obj_frame(a6),d0
		move.l	#dplc_player,d1
		move.l	#art_player,d2
		bra	Object_DPLC
		
; ------------------------------------------------

@Index:
		dc.w	ObjPlyr_Init-@Index
		dc.w	ObjPlyr_Main-@Index
		even

; =================================================================
; ------------------------------------------------
; Index $00: Init
; ------------------------------------------------

ObjPlyr_Init:
		add.b	#1,obj_index(a6)
		move.l	#$01010400,obj_size(a6)

; =================================================================
; ------------------------------------------------
; Index $01: Main
; ------------------------------------------------

ObjPlyr_Main:
		move.l	obj_x_spd(a6),d6
		move.l	obj_y_spd(a6),d7
		
		clr.l	d6
		clr.l	d7
		btst	#bitJoyRight,(RAM_Control_1+OnHold)
		beq.s	@no_right
		move.l	#$20000,d6
@no_right:
		btst	#bitJoyLeft,(RAM_Control_1+OnHold)
		beq.s	@no_left
		move.l	#-$20000,d6
@no_left:
		btst	#bitJoyDown,(RAM_Control_1+OnHold)
		beq.s	@no_down
		move.l	#$20000,d7
@no_down:
		btst	#bitJoyUp,(RAM_Control_1+OnHold)
		beq.s	@no_up
		move.l	#-$20000,d7
@no_up:

		add.l	d6,obj_x(a6)
		bsr	PlyrCol_Walls
		
		add.l	d7,obj_y(a6)
		bsr	PlyrCol_Floor
		bsr	PlyrCol_Ceiling
		
		move.l	d6,obj_x_spd(a6)
		move.l	d7,obj_y_spd(a6)
		rts
		
; =================================================================
; ------------------------------------------------
; Subs
; ------------------------------------------------

; --------------------------
; Floor collision
; --------------------------

PlyrCol_Floor:
		tst.l	d7
		bmi.s	@nope
		bsr	object_FindPrz_Floor
		tst.b	d0
		bne	@found_it
 		bsr 	object_FindPrz_FloorSides
		tst.b	d0
		bne	@found_it
		move.l	d1,d0
		tst.b	d0
		bne	@found_it
		
		bsr	object_FindCol_Floor
		tst.b	d0
		bne.s	@found_it
 		bsr 	object_FindCol_FloorSides
		tst.b	d0
		bne	@found_it
		move.l	d1,d0
		tst.b	d0
		bne	@found_it
@nope:
		rts
@found_it:
		and.l	#$FFF00000,obj_y(a6)
		clr.l	d7
		rts
	
; --------------------------
; Ceiling collision
; --------------------------

PlyrCol_Ceiling:
		tst.l	d7
		bpl.s	@nope
		bsr	object_FindPrz_Ceiling
		tst.b	d0
		bne	@found_it
 		bsr 	object_FindPrz_CeilingSides
		tst.b	d0
		bne	@found_it
		move.l	d1,d0
		tst.b	d0
		bne	@found_it
		
		bsr	object_FindCol_Ceiling
		tst.b	d0
		bne.s	@found_it
 		bsr 	object_FindCol_CeilingSides
		tst.b	d0
		bne	@found_it
		move.l	d1,d0
		tst.b	d0
		bne	@found_it
@nope:
		rts
@found_it:
 		and.l	#$FFF00000,obj_y(a6)
 		add.w	#$10,obj_y(a6)
		clr.l	d7
		rts
		
; --------------------------
; Floor collision
; --------------------------

PlyrCol_Walls:
		bsr	object_FindPrz_WallSides
		tst.b	d0
		bne	@wallsolid_r
		move.l	d1,d0
		tst.b	d0
		bne	@wallsolid_l
		
; 		bsr	object_FindCol_Wall
; 		tst.b	d0
; 		bne.s	@wallsolid_r
 		bsr 	object_FindCol_WallSides
		tst.b	d0
		bne	@wallsolid_r
		move.l	d1,d0
		tst.b	d0
		bne	@wallsolid_l
		rts

@wallsolid_l:
		add.w	#4,obj_x(a6)
@wallsolid_r:
		and.l	#$FFF80000,obj_x(a6)
		clr.l	d6
		rts

; =================================================================
; ------------------------------------------------
; External
; ------------------------------------------------

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
; Data
; ------------------------------------------------
		
Ani_Player:
		dc.w @Idle-Ani_Player
		dc.w @Walk-Ani_Player
		dc.w @Jump_1-Ani_Player
 		dc.w @Jump_2-Ani_Player
 		dc.w @ClimbMove-Ani_Player
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
		
