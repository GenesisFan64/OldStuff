; ====================================================================
; -------------------------------------------------
; Level
; 
; CODE ONLY
; -------------------------------------------------

; --------------------------------------------
; RAM
; --------------------------------------------

		rsset RAM_ModeBuffer
;Prize data: $FF0000-$FF87FF
RAM_Level	rs.b $440
RAM_ObjectSys	rs.b $1B80
sizeof_lvl	rs.l 0
;       		inform 0,"Level mode uses: %h",(sizeof_lvl-RAM_ModeBuffer)
		
; --------------------------------------------
; Init
; --------------------------------------------

mode_Level:
		fade	out
		move.w	#$2700,sr
		clr.w	(RAM_CurrLevel)
		bsr	Video_ClearAll
		
; --------------
; Load resources
; --------------

		lea	(Pal_LvlCoinItms),a0
		lea	(RAM_PalFade+$40),a1
		move.w	#16-1,d0
@copyextpal:
		move.w	(a0)+,(a1)+
		dbf	d0,@copyextpal
		
		lea	(Pal_Player),a0
		move.w	#16-1,d0
@copychrpal:
		move.w	(a0)+,(a1)+
		dbf	d0,@copychrpal
		
		;Same art for everything
		lea	(Art_Lvl_Test),a0
		move.l	#$40000000,(vdp_ctrl)
		move.w	#((Art_Lvl_Test_e-Art_Lvl_Test)/4)-1,d0
@copy_art:
		move.l	(a0)+,(vdp_data)
		dbf	d0,@copy_art
		
		lea	(Art_LvlBG_Test),a0
		move.l	#$78000000,(vdp_ctrl)
		move.w	#((Art_LvlBG_Test_e-Art_LvlBG_Test)/4)-1,d0
@dobgart:
		move.l	(a0)+,(vdp_data)
		dbf	d0,@dobgart
   				
		bsr	Level_Init
   		lea	(artdata_Level_Test),a1
   		bsr	Level_LoadArtList

; **************
; DEBUG ONLY
; **************

		move.l	#$50000003,(vdp_ctrl)
		lea	(Art_DebugFont),a0
		move.w	#((Art_DebugFont_e-Art_DebugFont)/4)-1,d0
@dbg_loop:
		move.l	(a0)+,(vdp_data)
		dbf	d0,@dbg_loop
		
;    		move.l	#$40800001,(vdp_ctrl)		
;    		move.l	#$17100000,(vdp_data)
;    		move.l	#$71700000,(vdp_data)
;    		move.l	#$17100000,(vdp_data)
;      		move.w	#1,(RAM_CurrLevel)
     		
;      		if MCD=0
;  		move.l	#TEST_IT,d0
;  		moveq 	#7,d1
;  		moveq	#0,d2
;   		bsr	Audio_Track_play
;   		endif
		
; --------------
; Restart
; --------------

@restart:
		bsr	Video_ClearScroll
		bsr	Video_ClearSprites
  		bsr	Objects_Init
		bsr	Level_FromList
  		bsr	Level_Draw
   		bsr	Level_Run
   		
		lea	(Map_LvlBG_Test),a0
 		moveq	#1,d0
 		move.l	#$00000000,d1
   		move.l	#$003F001F,d2
   		move.w	#$21C0,d3
   		bsr	Video_MakeMap
   		
  		move.l	#Music_Level1,d0
  		moveq 	#1,d1
  		moveq	#0,d2
  		bsr	Audio_Track_play
  		
 		move.w	#$2000,sr
 		
  		bsr	Objects_Run
; 		bsr	Level_DbgInit
 		fade	in
 		
; --------------------------------------------
; Loop
; --------------------------------------------

@loop:
 		bsr	Video_vsync
 		
   		bsr	Level_BlockUpd	
  		bsr	Objects_Run
   		bsr	Level_Run
;    		bsr	Level_Debug
		
; -----------------------------------------

		btst	#bitJoyStart,(RAM_Control_1+OnPress)
 		beq.s	@ignore_st
 		clr.b	(RAM_GameMode)
 		rts
@ignore_st:
; 		btst	#bitJoyA,(RAM_Control_2+OnHold)
;  		beq.s	@ignore_d
;  		move.b	#1,(RAM_ModeReset)
;   		add.w	#1,(RAM_CurrLevel)
; 
; @ignore_d:
		tst.b	(RAM_ModeReset)
		beq	@loop
		clr.b	(RAM_ModeReset)
		
		tst.w	(RAM_P1_Lives)
		beq.s	@gameover
 		fade	out
 		move.w	#$2700,sr
 		bra	@Restart

; --------------------------------------------
; Game Over
; --------------------------------------------

@gameover:
		clr.b	(RAM_GameMode)
		rts
		
; ====================================================================
; --------------------------------------------
; Subs
; --------------------------------------------

Level_DbgInit:
; 		move.w	#$EEE,(RAM_PalFade+$42)
		lea	ascDebugTop(pc),a0
		moveq	#2,d0
		move.l	#$00000000,d1
		move.w	#$680,d2
		bsr	Video_PrintText
		
		move.l	#$91009201,(vdp_ctrl)
		
Level_Debug:
;  		moveq	#2,d0
; 		move.l	#$00060000,d1
; 		moveq	#0,d2
; 		move.w	(RAM_P1_Coins),d2
; 		move.w	#$680,d3
; 		moveq	#4,d4
; 		bsr	Video_PrintVal
; 
;  		moveq	#2,d0
; 		move.l	#$000F0000,d1
; 		moveq	#0,d2
; 		move.w	(RAM_P1_Hits),d2
; 		move.w	#$680,d3
; 		moveq	#4,d4
; 		bsr	Video_PrintVal

 		moveq	#2,d0
		move.l	#$001B0000,d1
		move.l	(RAM_ObjBuffer+obj_y_spd),d2
		move.w	#$680,d3
		moveq	#2,d4
		bsr	Video_PrintVal
		
 		moveq	#2,d0
		move.l	#$00180000,d1
		moveq	#0,d2
		move.b	(RAM_ObjBuffer+obj_col),d2
		move.w	#$680,d3
		moveq	#0,d4
		bsr	Video_PrintVal
		
 		moveq	#2,d0
		move.l	#$000C0000,d1
		moveq	#0,d2
		move.b	(RAM_ObjBuffer+obj_status),d2
		move.w	#$680,d3
		moveq	#0,d4
		bra	Video_PrintVal
		
; -----------------------

Level_FromList:
		move.w	(RAM_CurrLevel),d0
		lsl.w	#4,d0
		lea	(LevelList),a4
		movea.l	(a4,d0.w),a0
		bsr	Level_Load
		lea	(RAM_LvlPlanes),a1
		move.b	(a4,d0.w),lvl_type(a1)
		
		lea	(Pal_LvlMain_Gray),a0
		lea	(RAM_PalFade),a1
		moveq	#0,d0
		move.w	#32-1,d0
@copy_pal:
		move.w	(a0)+,(a1)+
		dbf	d0,@copy_pal
		
		move.w	(RAM_CurrLevel),d1
		lsl.w	#4,d1
		
		moveq	#0,d0
 		move.w	8(a4,d1.w),d0
 		swap	d0
   		move.w	$A(a4,d1.w),d0
    		clr.b	(RAM_ObjBuffer+obj_index)
    		move.l	#Obj_Player,(RAM_ObjBuffer)
    		bsr	Plyr_SetStartPos
		
		move.w	(RAM_CurrLevel),d1
		lsl.w	#4,d1
		lea	(RAM_ObjBuffer+(sizeof_obj*4)),a1
 		move.w	$C(a4,d1.w),obj_x(a1)
   		move.w	$E(a4,d1.w),obj_y(a1)
		move.l	#Obj_EndFlag,obj_code(a1)
		lea	(RAM_ObjBuffer+(sizeof_obj*6)),a1	
		move.l	#Obj_HudInfo,obj_code(a1)
		move.w	#0,obj_x(a1)
		move.w	#0,obj_y(a1)
		rts
		
ascDebugTop:	dc.b "obj_status: 00 obj_col: 00              ",0
; 		dc.b "                              00000000",0
		even
		
; --------------------------------------------

		include	"engine/modes/level/subs/level.asm"
		include	"engine/modes/level/subs/objects.asm"
		
; ====================================================================
; --------------------------------------------
; VBlank
; --------------------------------------------

; ====================================================================		
; --------------------------------------------
; HBlank
; --------------------------------------------
		
; ====================================================================
