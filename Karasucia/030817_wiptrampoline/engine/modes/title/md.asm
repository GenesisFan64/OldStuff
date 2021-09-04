; ====================================================================
; -------------------------------------------------
; Title
; -------------------------------------------------

; ====================================================================
; --------------------------------------------
; RAM
; --------------------------------------------

		rsset RAM_ModeBuffer
; this_counter	rs.l 1
model_buff	rs.b $20
test_val	rs.l 1

; ====================================================================
; --------------------------------------------
; Init
; --------------------------------------------

mode_Title:
		fade	out
		move.w	#$2700,sr
		bsr	Video_ClearAll
  		bsr	SMEG_StopSnd
  		
		move.l	#$50000003,(vdp_ctrl)
		lea	(Art_DebugFont),a0
		move.w	#((Art_DebugFont_e-Art_DebugFont)/4)-1,d0
@dbg_loop:
		move.l	(a0)+,(vdp_data)
		dbf	d0,@dbg_loop
 		lea	(RAM_PalFade),a1
		lea	(Pal_Title),a0
		move.w	#16-1,d0
@pal_loop2:
		move.w	(a0)+,(a1)+
		dbf	d0,@pal_loop2
		move.w	#$644,$1C(a1)
		move.w	#$EEE,$1E(a1)
		
; MARS: Model viewer
		
; 		if MARS
; 		
; 		lea	(Asc_MarsMdl),a0
; 		moveq	#0,d0
; 		move.l	#$00010001,d1
; 		move.w	#$580|$2000,d2
; 		bsr	Video_PrintText
; 		bsr	MarsMdl_Init
; 
; ; Else: Text
; 
;    		else
   		
		lea	(Asc_Karasucia),a0
		moveq	#0,d0
		move.l	#$00010001,d1
		move.w	#$680|$2000,d2
		bsr	Video_PrintText
		
; 		lea	(Map_Title),a0
;  		moveq	#0,d0
;  		move.l	#$00000000,d1
;    		move.l	#$0027001B,d2
;    		moveq	#1,d3
;    		bsr	Video_MakeMap
; 		move.l	#$40200000,(vdp_ctrl)
; 		lea	(Art_Title),a0
; 		move.w	#(Art_Title_End-Art_Title)/4,d0
; @art_loop:
; 		move.l	(a0)+,(vdp_data)
; 		dbf	d0,@art_loop
		
;     		endif
   		
  		move.b	#%111,(RAM_VidRegs+$B)
  		bsr	Video_Update
   		
;    		if MCD=0
;  		move.l	#TEST_IT,d0
;  		moveq 	#2,d1
;  		moveq	#0,d2
;   		bsr	Audio_Track_play
;   		endif
;   		move.l	#TEST_IT_2,d0
;   		move.w 	#2,d1
;   		moveq	#0,d2
;   		bsr	Audio_Track_play
		
;  		if MCD=0
; 		move.l	#TEST_WAV,d0
; 		move.l	#TEST_WAV_end,d1
; 		moveq	#0,d2
; 		move.w	#12*4,d3
; 		bsr	Audio_Sample_Set
; 		bsr	Audio_Sample_Play
;  		endif
		
 		move.w	#$2000,sr
 		fade	in
		
; --------------------------------------------
; Loop
; --------------------------------------------

; 		move.l	#$300000,(test_val)
@loop:
 		bsr	Video_vsync
		
;  		moveq	#0,d0
; 		move.l	#$00080008,d1
; 		move.l	(test_val),d2
; 		move.w	#$680|$2000,d3
; 		moveq	#6,d4
; 		bsr	Video_PrintVal
; 
;  		moveq	#0,d0
; 		move.l	#$00080009,d1
; 		move.l	(test_val),d2
; 		move.w	#$680|$2000,d3
; 		moveq	#2,d4
; 		bsr	Video_PrintVal
		
; 		add.l	#1,(test_val)

; 		if MARS
; 		bsr	MarsMdl_Upd
; 		endif

; ------------
; TESTING SFX
; ------------

		if MARS|MCD=0
		btst	#bitJoyA,(RAM_Control_1+OnPress)
 		beq.s	@nope
  		move.l	#Music_Level1,d0
  		moveq 	#1,d1
  		moveq	#0,d2
  		bsr	Audio_Track_play
@nope:
		endif
		
; ------------

		btst	#bitJoyStart,(RAM_Control_1+OnPress)
 		beq	@loop
 		clr.w	(RAM_CurrLevel)
		move.b	#1,(RAM_GameMode)
		rts
		
; ====================================================================
; --------------------------------------------
; Subs
; --------------------------------------------

BG_DEFORM:
		lea	(RAM_ScrlHor),a0
		move.w	d6,d3
		move.w	#224-1,d2
@loop_hor:
		move.w	d3,d0
		bsr	CalcSine
		lsr.w	#4,d0
		move.w	d0,(a0)
		adda	#4,a0
		add.w	#1,d3
		dbf	d2,@loop_hor
		
		lea	(RAM_ScrlVer),a0
		move.w	d6,d3
		move.w	#(320/16)-1,d2
@loop_ver:
		move.w	d3,d0
		bsr	CalcSine
		lsr.w	#4,d0
		move.w	d0,(a0)
		adda	#4,a0
		add.w	#2,d3
		dbf	d2,@loop_ver
		
		add.w	#1,d6
		rts
	
; ; --------------------------------------------
; ; MARS ONLY
; ; 
; ; 3d test
; ; --------------------------------------------
; 
; 		if MARS
; MarsMdl_Init:
; 		clr.w	(model_buff+$10)
; 		bsr	MarsMdl_Set
; 
; ; ------------------
; ; Loop
; ; ------------------
; 
; MarsMdl_Upd:
; 		move.b	(RAM_Control_1+ExOnHold),d4
; 		btst	#bitJoyX,d4
;  		beq.s	@not_X
;  		add.w	#1,(model_buff+4)
; @not_X:
; 		btst	#bitJoyY,d4
;  		beq.s	@not_Y
;  		sub.w	#1,(model_buff+4)
; @not_Y:
; 		move.b	(RAM_Control_1+OnHold),d4
; 		btst	#bitJoyRight,d4
;  		beq.s	@not_right
;  		sub.w	#1,(model_buff)
; @not_right:
; 		btst	#bitJoyLeft,d4
;  		beq.s	@not_left
;  		add.w	#1,(model_buff)
; @not_left:
; 		btst	#bitJoyDown,d4
;  		beq.s	@not_down
;  		sub.w	#1,(model_buff+2)
; @not_down:
; 		btst	#bitJoyUp,d4
;  		beq.s	@not_up
;  		add.w	#1,(model_buff+2)
; @not_up:
; 
; 
; 		move.b	(RAM_Control_1+OnPress),d4
; 		btst	#bitJoyB,d4
;  		beq.s	@not_B
;  		add.w	#1,(model_buff+$10)
;  		bsr	MarsMdl_Set
; @not_B:
; 		btst	#bitJoyA,d4
;  		beq.s	@not_A
;  		sub.w	#1,(model_buff+$10)
;  		bsr	MarsMdl_Set
; @not_A:
; 		btst	#bitJoyC,d4
;  		beq.s	@not_C
;  		clr.w	(model_buff)
;  		clr.w	(model_buff+2)
;  		move.w	#0,(model_buff+4)
;  		clr.w	(model_buff+6)
;  		clr.w	(model_buff+8)
;  		clr.w	(model_buff+$A)
; @not_C:
; 
; ; Contoller 2
; 
; 		move.b	(RAM_Control_2+OnHold),d4
; 		btst	#bitJoyRight,d4
;  		beq.s	@not_right2
;  		add.w	#1,(model_buff+8)
; @not_right2:
; 		btst	#bitJoyLeft,d4
;  		beq.s	@not_left2
;  		sub.w	#1,(model_buff+8)
; @not_left2:
; 		btst	#bitJoyDown,d4
;  		beq.s	@not_down2
;  		add.w	#1,(model_buff+6)
; @not_down2:
; 		btst	#bitJoyUp,d4
;  		beq.s	@not_up2
;  		sub.w	#1,(model_buff+6)
; @not_up2:
; 
; 		btst	#bitJoyB,d4
;  		beq.s	@not_B2
;  		add.w	#1,(model_buff+$A)
; @not_B2:
; 		btst	#bitJoyA,d4
;  		beq.s	@not_A2
;  		sub.w	#1,(model_buff+$A)
; @not_A2:
; 
; ; ------------------------
; ; Show values
; ; ------------------------
; 
; 		lea	(model_buff),a1
; 		moveq	#2,d6
; 		move.l	#$00050002,d7
; @next3:
; 		moveq	#0,d0
; 		move.l	d7,d1
; 		move.w	(a1)+,d2
; 		move.w	#$2000|$580,d3
; 		moveq	#1,d4
; 		bsr	Video_PrintVal
; 		add.l	#$00050000,d7
; 		dbf	d6,@next3
; 		
; 		lea	(model_buff+6),a1
; 		moveq	#2,d6
; 		move.l	#$00050003,d7
; @next4:
; 		moveq	#0,d0
; 		move.l	d7,d1
; 		move.w	(a1)+,d2
; 		move.w	#$2000|$580,d3
; 		moveq	#1,d4
; 		bsr	Video_PrintVal
; 		add.l	#$00050000,d7
; 		dbf	d6,@next4
; 		
; 		moveq	#0,d0
; 		move.l	#$0008001A,d1
; 		move.w	(marsreg+comm14),d2
; 		move.w	#$2000|$580,d3
; 		moveq	#1,d4
; 		bsr	Video_PrintVal
; 
; ; 		lea	(marsreg+comm0),a1
; ; 		moveq	#3,d6
; ; 		move.l	#$00010019,d7
; ; @next:
; ; 		moveq	#0,d0
; ; 		move.l	d7,d1
; ; 		move.w	(a1)+,d2
; ; 		move.w	#$2000|$580,d3
; ; 		moveq	#1,d4
; ; 		bsr	Video_PrintVal
; ; 		add.l	#$00050000,d7
; ; 		dbf	d6,@next
; ; 		
; ; 		lea	(marsreg+comm8),a1
; ; 		moveq	#3,d6
; ; 		move.l	#$0001001A,d7
; ; @next2:
; ; 		moveq	#0,d0
; ; 		move.l	d7,d1
; ; 		move.w	(a1)+,d2
; ; 		move.w	#$2000|$580,d3
; ; 		moveq	#1,d4
; ; 		bsr	Video_PrintVal
; ; 		add.l	#$00050000,d7
; ; 		dbf	d6,@next2
; 		
; ; ------------------------
; ; Send data
; ; ------------------------
; 
; @busy:		tst.b	(marsreg+comm0+1)
; 		bne.s	@busy
; 		clr.l	(marsreg+comm4)
; 		clr.l	(marsreg+comm8)
; 		move.w	#$14,(marsreg+comm0)
; 		lea	(marsreg+comm4),a0
; 		move.w	#0,(a0)+
; 		move.w	(model_buff),(a0)+
; 		move.w	(model_buff+2),(a0)+
; 		move.w	(model_buff+4),(a0)+
;  		bset	#0,(marsreg+intctl)
;  		
; @busy2:		tst.b	(marsreg+comm0+1)
; 		bne.s	@busy2
; 		clr.l	(marsreg+comm4)
; 		clr.l	(marsreg+comm8)
; 		move.w	#$15,(marsreg+comm0)
; 		lea	(marsreg+comm4),a0
; 		move.w	#0,(a0)+
; 		move.w	(model_buff+6),(a0)+
; 		move.w	(model_buff+8),(a0)+
; 		move.w	(model_buff+$A),(a0)+
;  		bset	#0,(marsreg+intctl)
; 		rts
; 		
; ; ------------------------------------
; 
; MarsMdl_Set:
; 		btst	#0,(marsreg+intctl)
; 		bne.s	@busyinit
; 		move.w	#$10,(marsreg+comm0)
; 		lea	(marsreg+comm4),a0
; 		move.w	(model_buff+$10),d0
; 		lsl.w	#4,d0
; 		move.l	List_Models(pc,d0.w),(a0)+
; 		move.w	#0,(a0)+
;  		bset	#0,(marsreg+intctl)
;  		
;  		clr.l	(model_buff)
;  		move.w	#0,(model_buff+4)
;  		
;  		clr.l	(model_buff+6)
; 		clr.w	(model_buff+$A)
; 		
; ; 		move.w	(model_buff+$10),d0
; ; 		lsl.w	#4,d0
; ;  		lea 	List_Models+4(pc,d0.w),a0
; ; 		moveq	#0,d0
; ; 		move.l	#$00170001,d1
; ; 		move.w	#$580|$2000,d2
; ; 		bsr	Video_PrintText
;  		
; @busyinit:
; 		rts
; 		
; 		endif
		
; ====================================================================
; --------------------------------------------
; VBlank
; --------------------------------------------

; ====================================================================		
; --------------------------------------------
; HBlank
; --------------------------------------------
		
; ====================================================================		
; --------------------------------------------
; Data
; --------------------------------------------

		if MARS
List_Models:
		dc.l mdldata_cube
		dc.b "TextureCube",0
		dc.l mdldata_sphere
		dc.b "Ico sphere ",0
		dc.l mdldata_monkey
		dc.b "Monkey     ",0
		dc.l mdldata_field
		dc.b "Small field",0
		dc.l mdldata_world
		dc.b "Big field  ",0
		even
		
		endif
		
Asc_MarsMdl:	dc.b "Obj -X-  -Y-  -Z-  Wld -X-  -Y-  -Z- ",$A
		dc.b "  P 0000 0000 0000   P 0000 0000 0000",$A
		dc.b "  R 0000 0000 0000   R 0000 0000 0000",$A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b "Faces: 0000",$A
		dc.b 0
		even
		
Asc_Karasucia:
		dc.b "Karasucia-MD game engine",$A
		dc.b $A
		dc.b "Project: Dominoe Adventures",$A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b $A
		dc.b "(C)GF64 2017"
		dc.b 0
		even
		
Art_DebugFont:	incbin "engine/shared/dbgfont.bin"
Art_DebugFont_e:
		even
		
