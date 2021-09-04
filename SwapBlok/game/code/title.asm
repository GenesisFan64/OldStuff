; ================================================================
; ------------------------------------------------------------
; Your game code starts here
; 
; No restrictions unless porting to Sega CD or 32X
; ------------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; Variables
; ----------------------------------------------------------------

SET_MENUTOPLINE		equ 123
MAX_TITLOPT		equ 3

VRAMTTL_PUZTITLE	equ $0002
VRAMTTL_PUZFONT		equ $00E0
VRAMTTL_PUZBG		equ $0200
VRAMTTL_CELLHIDE	equ $0780

; ====================================================================
; ----------------------------------------------------------------
; RAM
; ----------------------------------------------------------------

			struct RAM_Local
RAM_Ttle_SpriteData	ds.w 4*70
RAM_Ttle_HorVal		ds.l 1
RAM_Ttle_VerVal		ds.l 1
RAM_Tite_VerBot		ds.l 1			; 0000.0000
RAM_Tite_VerBgMenu	ds.w 1
RAM_Ttle_VerBg		ds.w 1
RAM_Ttle_HorBg  	ds.w 1
RAM_Titl_UsrOpt		ds.w 1			; 0-2
			finish

; ====================================================================
; ----------------------------------------------------------------
; Init
; ----------------------------------------------------------------

TitleScreen_Init:
		move.w	#$2700,sr
		lea	(RAM_FadeTarget),a0
		move.w	#64-1,d0
.clrpal:
		clr.w	(a0)+
		dbf	d0,.clrpal
		lea	(RAM_HorScroll),a0
		move.w	#(224/4)-1,d0
.clrhor:
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		dbf	d0,.clrhor
		
		moveq	#0,d0				; Clear FG
		move.w	#((512*256)/8)-1,d1
		move.w	#$C000,d2
		bsr	Video_Fill
		move.w	#$E000,d2			; Clear BG
		bsr	Video_Fill
		moveq	#0,d0				; Clear Horizontal scroll
		move.w	#(224)-1,d1
		move.w	#$FC00,d2
		bsr	Video_Fill
		move.w	#$1111,d0			; 2cell border
		move.w	#(16*$40)-1,d1
		move.w	#VRAMTTL_CELLHIDE*$20,d2
		bsr	Video_Fill
		lea	(vdp_data),a6
		move.l	#$40000010,4(a6)		; Clear Vertical scroll
		move.l	#0,(a6)
		lea	(RAM_Local),a0
		move.w	#(MAX_LOCRAM/4)-1,d1
		moveq	#0,d0
.clrme:
		move.l	d0,(a0)+
		dbf	d1,.clrme
		move.b	#%00010100,(RAM_VdpCache).w
		move.b	#%01100100,(RAM_VdpCache+1).w
		move.b	#$30,(RAM_VdpCache+7).w
		move.b	#SET_MENUTOPLINE,(RAM_VdpCache+$A).w	; Hint line
		move.b	#%00000111,(RAM_VdpCache+$B).w	; Scroll: Hor FULL Vert FULL
		move.b	#%10000001,(RAM_VdpCache+$C).w	; H40
		move.l	#Title_VBlank,(RAM_GoToVBlnk+2).w
		move.l	#Title_HBlank,(RAM_GoToHBlnk+2).w
		move.l	#$91009200,(vdp_ctrl).l
		move.l	#$40000010,(vdp_ctrl).l
		move.l	#0,(vdp_data).l
		clr.w	(RAM_Titl_UsrOpt).w
		
		move.l	#Art_MenuFont,d0
		move.w	#(Art_MenuFont_e-Art_MenuFont),d1
		move.w	#VRAMTTL_PUZFONT,d2
		bsr	Video_LoadArt
		move.l	#Art_Title_BG,d0
		move.w	#(Art_Title_BG_e-Art_Title_BG),d1
		move.w	#VRAMTTL_PUZBG,d2
		bsr	Video_LoadArt
		lea	Map_Title_BG(pc),a0
		move.l	#locate(1,0,0),d0
		move.l	#mapsize(320,256),d1
		move.w	#VRAMTTL_PUZBG|$6000,d2
		bsr	Video_LoadMap
		move.l	#Art_Title_FG,d0
		move.w	#(Art_Title_FG_e-Art_Title_FG),d1
		move.w	#VRAMTTL_PUZTITLE,d2
		bsr	Video_LoadArt

	; Copyright on WINDOW Layer
; 		lea	str_Copyinfo(pc),a0
; 		move.l	#locate(2,23,26),d0
; 		move.w	#$6000|(VRAMTTL_PUZFONT-$20),d1
; 		bsr	ShowStr_custom
; 		move.w	#$9298,(vdp_ctrl).l
; 		lea	Map_MenuText(pc),a0		; CUSTOM map load
; 		move.l	#$60000002,d4
; 		move.l	#$800000,d6
; 		move.l	#mapsize(320,256),d1
; 		move.w	#VRAMTTL_PUZFONT,d2
; 		bsr	Video_LoadMap_Custom
		lea	Map_MenuText(pc),a0
		move.l	#locate(0,0,0),d0
		move.l	#mapsize(320,256),d1
		move.w	#VRAMTTL_PUZFONT,d2
		bsr	Video_LoadMap
		lea	Map_Title_FG(pc),a0
		move.l	#locate(0,10,1),d0
		move.l	#mapsize(176,112),d1
		move.w	#VRAMTTL_PUZTITLE,d2
		bsr	Video_LoadMap

; 		moveq	#1,d3				; 	Hide the broken 2cell
; 		lea	(RAM_Ttle_SpriteData),a4
; 		move.w	#$80,d0
; 		move.w	#$80,d1
; 		move.w	#VRAMTTL_CELLHIDE|$8000+$6000,d2
; 		move.w	#(224/32)-1,d5
; 		move.w	#$0700,d4
; 		or.w	d3,d4
; .nxtone:
; 		move.w	d0,(a4)+
; 		move.w	d4,(a4)+
; 		move.w	d2,(a4)+
; 		move.w	d1,(a4)+
; 		add.w	#1,d3
; 		add.w	#1,d4
; 		add.w	#$20,d0
; 		dbf	d5,.nxtone

		bsr	Video_Update
		bsr	Title_AnimateFg_Init
		move.w	#$2000,sr
		lea	Pal_Title_FG(pc),a0
		moveq	#0,d0
		move.w	#48-1,d1
		bsr	Video_LoadPal_Fade
		lea	Pal_Title_BG(pc),a0
		moveq	#$30,d0
		move.w	#16-1,d1
		bsr	Video_LoadPal_Fade
		moveq	#0,d0
		move.w	#64,d1
		move.w	#$80,d2
		bsr	Video_PalFade_In
		
; 		move.l	#(SfxData_Blk<<16)|SfxData_Pat,d0
; 		move.l	#($0000<<16)|SfxData_Ins,d1
; 		move.l	#$00020002,d2
; 		moveq	#0,d3
; 		bsr	Sound_SetTrack
; 		move.l	#Wav_Beibe,d0
; 		move.l	#Wav_Beibe_e,d1
; 		move.l	d0,d2
; 		move.w	#$100,d3
; 		bsr	Sound_PlayWav
		
; ====================================================================
; ----------------------------------------------------------------
; Loop
; ----------------------------------------------------------------
		
Title_Loop:
		move.w	(vdp_ctrl),d4
		btst	#bitVBlnk,d4
		beq.s	Title_Loop
		bsr	Title_AnimateFg
		bsr	System_Input
		bsr	System_Random
		add.l	#1,(RAM_GlblFrameCnt).w		; Frame counter
	
		move.w	(Controller_1+on_press).l,d4
		and.w	#JoyUp,d4
		beq.s	.no_up
		tst.w	(RAM_Titl_UsrOpt).w
		beq.s	.no_up
		add.w	#$10,(RAM_Tite_VerBot).w
		sub.w	#1,(RAM_Titl_UsrOpt).w
.no_up:
		move.w	(Controller_1+on_press).l,d4
		and.w	#JoyDown,d4
		beq.s	.no_down
		cmp.w	#MAX_TITLOPT,(RAM_Titl_UsrOpt).w
		beq.s	.no_down
		sub.w	#$10,(RAM_Tite_VerBot).w
		add.w	#1,(RAM_Titl_UsrOpt).w
.no_down:
; 		tst.l	(RAM_Tite_VerBotAdd).w
; 		beq.s	.vaddover2
; 		move.l	(RAM_Tite_VerBotAdd).w,d4
; 		add.l	d4,(RAM_Tite_VerBot).l
; 		sub.l	#$1000,d4
; ; 		bpl.s	.vaddover
; ; 		clr.l	d4
; ; .vaddover:
; 		move.l	d4,(RAM_Tite_VerBotAdd).w
; .vaddover2:

	; Check START
		move.w	(Controller_1+on_press).l,d4
		and.w	#JoyStart,d4
		beq.s	.no_start
		moveq	#0,d0
		move.w	#64,d1
		move.w	#$140,d2
		bsr	Video_PalFade_Out
		bra	TitleScr_StartGame
.no_start:
		bra	Title_Loop
		
; ----------------------------------------------------------------
; Game start
; ----------------------------------------------------------------

TitleScr_StartGame:
		lea	(RAM_Glbl_PzlBoxes),a6
		moveq	#0,d0
		move.w	#((sizeof_Box*MAX_BOXES)/2)-1,d1
.clrboxes:
		move.w	d0,(a6)+
		dbf	d1,.clrboxes
		lea	(RAM_Glbl_PzlCursors),a6
		moveq	#0,d0
		move.w	#((sizeof_Cursor*MAX_BOXES)/2)-1,d1
.clrcursors:
		move.w	d0,(a6)+
		dbf	d1,.clrcursors

	; Make SCORE boxes
		lea	(RAM_Glbl_PzlScores),a6			; Box buffer
		lea	.score_boxes(pc),a5
		move.w	(RAM_Titl_UsrOpt).w,d7			; Menu option
		add.w	d7,d7
		move.w	(a5,d7.w),d7
		adda	d7,a5
		move.w	(a5)+,d7
.make_score:
		bset	#bitScorSt_Active,scorBox_Status(a6)
		move.l	(a5)+,scorBox_BoxAddr(a6)
		move.w	(a5)+,scorBox_X(a6)
		move.w	(a5)+,scorBox_Y(a6)		
		move.w	(a5)+,scorBox_Type(a6)
		adda	#sizeof_ScorBox,a6
		dbf	d7,.make_score
	
	; Make USERBLOCK boxes
		move.w	(a5)+,d7
.do_box:
		move.l	(a5)+,a6
		move.l	(a5)+,box_BlockTrsh(a6)
		move.l	(a5)+,box_BlockTrsh+4(a6)
		move.l	(a5)+,box_BlockTrsh+8(a6)
		move.w	(a5)+,box_BoardX(a6)			; Board X pos
		move.w	(a5)+,box_BoardY(a6)			; Board Y pos
		move.w	(a5)+,box_Width(a6)			; Box width
		move.w	(a5)+,box_Height(a6)			; Box Height (always $D)
		move.w	(a5)+,box_UserBorder(a6)		; USER border color
		move.l	#$1400,box_YSpd(a6)			; Start Y Speed
		move.w	#6,box_UserMaxIds(a6)			; Max blocks to use
		move.w	#4,box_UserLevel(a6)			; Max block level to start
		clr.w	box_Status(a6)
		bset	#bitPlySt_Active,box_Status(a6)		; Mark this box as active
		dbf	d7,.do_box

	; MAKE Cursors
		lea	(RAM_Glbl_PzlCursors),a6		; Cursor buffer
		move.w	(a5)+,d7
.mkcursor:
		move.l	(a5)+,d4
		move.l	(a5)+,d5
		move.l	d4,cursor_Box(a6)
		move.l	d5,cursor_Control(a6)
		bset	#bitCurSt_Active,cursor_Status(a6)
		clr.w	cursor_Type(a6)
		btst	#0,(RAM_Titl_UsrOpt+1).w
		beq.s	.3pad
		move.w	#1,cursor_Type(a6)
.3pad:
		adda	#sizeof_Cursor,a6
		dbf	d7,.mkcursor
		move.w	(a5)+,d4
		move.b	d4,(RAM_Glbl_GameMtchFlags).w
		bra	MainGame_Init

; ----------------------------------------------------------------
; SETUP LIST FOR MENU ENTRIES

	; Types: 0 - SCORE
	;        1 - TIME (global)
	;        2 - CHAINS
	
; hardcoded if %01
.score_boxes:
		dc.w .1p_timed-.score_boxes
		dc.w .1p_timed-.score_boxes
		dc.w .vs_3pad-.score_boxes		
		dc.w .vs_3pad-.score_boxes
.1p_timed:
	; SCORE BOXES
		dc.w 2				; numof scoreboxes
		dc.l RAM_Glbl_PzlBoxes
		dc.w 28, 2, 0			; SCORE
		dc.l RAM_Glbl_PzlBoxes
		dc.w 28, 4, 1			; TIME
		dc.l RAM_Glbl_PzlBoxes
		dc.w 28, 6, 2			; CHAINS
	; USER BOXES
		dc.w 0				; numof plyrboxes
		dc.l RAM_Glbl_PzlBoxes		; BASE buffer
		dc.l 0				; TARGET trash buffer(s)
		dc.l 0
		dc.l 0
		dc.w $07,$01,$06,$0D		; Xpos, Ypos, Width, Height (ALWAYS $0D)
		dc.w 0				; BORDER color (0-3)
	; CURSORS
		dc.w 0
		dc.l RAM_Glbl_PzlBoxes		; CURSOR uses this box
		dc.l Controller_1		; Controller for this cursor
	; MATCH SETTINGS
		dc.w MtchFlg_ComboSpdUp
		

.vs_3pad:
	; SCORE BOXES
		dc.w 3-1
		dc.l RAM_Glbl_PzlBoxes
		dc.w $10,$02, 2				; CHAINS (left)
		dc.l RAM_Glbl_PzlBoxes+sizeof_Box
		dc.w $13,$04, 2				; CHAINS (right)
		dc.l 0
		dc.w $11,$07, 1				; TIME
	; USER BOXES
		dc.w 2-1				; numof plyrboxes
		dc.l RAM_Glbl_PzlBoxes			; BASE buffer
		dc.l RAM_Glbl_PzlBoxes+sizeof_Box	; TARGET trash buffer(s)
		dc.l 0
		dc.l 0
		dc.w $01,$01,$06,$0D			; Xpos, Ypos, Width, Height (ALWAYS $0D)
		dc.w 0					; BORDER color (0-3)
		dc.l RAM_Glbl_PzlBoxes+sizeof_Box	; BASE buffer
		dc.l RAM_Glbl_PzlBoxes			; TARGET trash buffer(s)
		dc.l 0
		dc.l 0
		dc.w $0D,$01,$06,$0D			; Xpos, Ypos, Width, Height (ALWAYS $0D)
		dc.w 0					; BORDER color (0-3)
	; CURSORS
		dc.w 2-1
		dc.l RAM_Glbl_PzlBoxes			; CURSOR uses this box
		dc.l Controller_1			; Controller for this cursor
		dc.l RAM_Glbl_PzlBoxes+sizeof_Box	; CURSOR uses this box
		dc.l Controller_2			; Controller for this cursor
	; MATCH SETTINGS
		dc.w MtchFlg_ComboSpdUp|MtchFlg_TrashEnbl
		
; 		lea	(RAM_Glbl_PzlBoxes),a6			; Box buffer
; 		lea	(RAM_Glbl_PzlCursors),a5		; Cursor buffer
; 		lea	(RAM_Glbl_PzlScores),a4
; 		lea	(Controller_1),a3			; First controller data
; 		move.l	a6,box_BlockTrsh(a6)			; Box target(s) to get trash (this user)
; 		move.w	#6,box_Width(a6)			; Box width
; 		move.w	#$D,box_Height(a6)			; Box Height (always $D)
; 		move.w	#7,box_BoardX(a6)			; Board X pos
; 		move.w	#1,box_BoardY(a6)			; Board Y pos
; 		move.l	#$1400,box_YSpd(a6)			; Start Y Speed
; 		move.w	#6,box_UserMaxIds(a6)			; Max blocks to use
; 		move.w	#4,box_UserLevel(a6)			; Max block level to start
; 		move.w	#0,box_UserBorder(a6)			; USER border color
; 		clr.w	box_Status(a6)
; 		bset	#bitPlySt_Active,box_Status(a6)		; Mark this box as active
; 		move.l	a6,cursor_Box(a5)
; 		move.l	a3,cursor_Control(a5)
; 		clr.w	cursor_X(a5)
; 		clr.w	cursor_Y(a5)
; 		bset	#bitCurSt_Active,cursor_Status(a5)
; ; 		move.l	#$030000,(RAM_PGame_GlblTimer).w
; ; 		bset	#bitMtch_TimerDir,(RAM_Glbl_GameMtchFlags).w
; 		bset	#bitMtch_ComboSpdUp,(RAM_Glbl_GameMtchFlags).w
; ; 		bset	#bitMtch_TrashEnbl,(RAM_Glbl_GameMtchFlags).w

; ====================================================================
; ----------------------------------------------------------------
; Subs
; ----------------------------------------------------------------

; ------------------------------------------------
; Animate title
; ------------------------------------------------

Title_AnimateFg_Init:
; 		lea	(RAM_HorScroll+(SET_MENUTOPLINE*4)),a5
; 		move.w	#8-1,d7
; 		move.w	#0,d4
; .hnext:
; 		move.w	d4,d0
; 		bsr	System_SineWave
; 		asr.l	#2,d0
; 		sub.w	#$90,d0
; 		move.w	d0,(a5)
; ; 		neg.w	d0
; ; 		move.w	d0,4(a5)		
; 		add.w	#8,d4
; 		adda	#4,a5
; 		dbf	d7,.hnext
; 		lea	(RAM_HorScroll+((SET_MENUTOPLINE+65)*4)),a5
; 		move.w	#16-1,d7
; 		move.w	#$40,d4
; .hnext2:
; 		move.w	d4,d0
; 		bsr	System_SineWave
; 		asr.l	#3,d0
; 		sub.w	#$20,d0
; 		move.w	d0,(a5)
; 		add.w	#4,d4
; 		adda	#4,a5
; 		dbf	d7,.hnext2

; 		lea	(RAM_HorScroll+(SET_MENUTOPLINE*4)),a5
; 		move.w	#16-1,d7
; 		move.w	#0,d4
; .hnext:
; 		move.w	d4,d0
; 		bsr	System_SineWave
; 		asr.l	#3,d0
; 		sub.w	#$20,d0
; 		move.w	d0,(a5)
; 		add.w	#4,d4
; 		adda	#4,a5
; 		dbf	d7,.hnext
; 		lea	(RAM_HorScroll+((SET_MENUTOPLINE+65)*4)),a5
; 		move.w	#16-1,d7
; 		move.w	#$40,d4
; .hnext2:
; 		move.w	d4,d0
; 		bsr	System_SineWave
; 		asr.l	#3,d0
; 		sub.w	#$20,d0
; 		move.w	d0,(a5)
; 		add.w	#4,d4
; 		adda	#4,a5
; 		dbf	d7,.hnext2
		
Title_AnimateFg:

	; Later...
; 		lea	(RAM_HorScroll+(SET_MENUTOPLINE*4)),a5
; 		move.w	#64,d7
; 		move.l	(RAM_Tite_HorBot),d4
; 		swap	d4
; .hnextmn:
; 		move.w	d4,(a5)
; 		adda	#4,a5
; 		dbf	d7,.hnextmn

		lea	(RAM_HorScroll),a5
		move.w	#224-1,d7
		move.w	(RAM_Ttle_HorBg).w,d4
		lsr.w	#2,d4
		neg.w	d4
.hnextfg:
		move.w	d4,2(a5)
		adda	#4,a5
		dbf	d7,.hnextfg

		lea	(RAM_HorScroll),a5
		move.w	#SET_MENUTOPLINE-1,d7
		move.w	(RAM_Ttle_HorVal).w,d4
.hnext:
		move.w	d4,d0
		bsr	System_SineWave
		asr.l	#6,d0
		move.w	d0,(a5)
		adda	#4,a5
		add.w	#3,d4
		dbf	d7,.hnext
		
		lea	(RAM_VerScroll),a5
		move.w	#(320/16)-1,d7
		move.w	(RAM_Ttle_VerBg).w,d3
		lsr.w	#2,d3
		move.w	d3,(RAM_Tite_VerBgMenu).w
		move.w	(RAM_Ttle_VerVal).w,d4
.vnext:
		move.w	d4,d0
		bsr	System_SineWave
		asr.l	#6,d0
		neg.w	d0
		move.w	d0,(a5)
		move.w	d3,2(a5)
		adda	#4,a5
		add.w	#3,d4
		dbf	d7,.vnext

; 		add.w	#1,(RAM_Ttle_HorBg).w
; 		add.w	#1,(RAM_Ttle_VerBg).w
		
		add.w	#2,(RAM_Ttle_HorVal).w
		add.w	#2,(RAM_Ttle_VerVal).w
		rts

; ------------------------------------------------

ShowStr_custom:
		bsr	vid_PickLayer
		lea	(vdp_data),a6
.renew:
		move.l	d4,4(a6)
.loop:
		moveq	#0,d5
		move.b	(a0)+,d5
		tst.b	d5
		beq.s	.exit
		cmp.b	#$A,d5
		beq.s	.line
		add.w	d1,d5
		move.w	d5,(a6)
		bra.s	.loop
.line:
		add.l	d6,d4
		bra.s	.renew
		
.exit:
		rts

ShowVal_custom:
		bsr	vid_PickLayer
		lea	(vdp_data),a6
		move.l	d4,4(a6)

		move.w	d2,d5
		move.w	#3,d6
.lupn:
		rol.w	#4,d5
		move.w	d5,d4
		and.w	#%1111,d4
		cmp.w	#10,d4
		bcs.s	.lowa
		add.w	#7,d4
.lowa:
		add.w	d1,d4
		move.w	d4,(a6)
		dbf	d6,.lupn
		rts

; SndTest_PlaySound:
; 		lea	list_TrackData(pc),a0
; 		move.l	(a0)+,d0
; 		move.l	(a0)+,d1
; 		move.l	(a0)+,d2
; 		moveq	#0,d3
; 		bra	Sound_SetTrack

; ====================================================================
; ----------------------------------------------------------------
; Interrupts
; ----------------------------------------------------------------

Title_HBlank:
		move.w	#$2700,sr
; 		move.w	#$8228,(vdp_ctrl).l
		move.l	#$40000010,(vdp_ctrl).l
		
	; Third 2cell is cursor
		move.w	#0,(vdp_data).l
		move.w	(RAM_Tite_VerBgMenu),(vdp_data).l
		move.w	#0,(vdp_data).l
		move.w	(RAM_Tite_VerBgMenu),(vdp_data).l
		move.w	(RAM_Tite_VerBot),(vdp_data).l
		move.w	(RAM_Tite_VerBgMenu),(vdp_data).l		
	rept (320/16)-3
		move.w	#0,(vdp_data).l
		move.w	(RAM_Tite_VerBgMenu),(vdp_data).l
	endm
		rte
		
Title_VBlank:
		movem.l	d0-a6,-(sp)
		lea	(vdp_ctrl),a6
		move.l	#$8B078234,(a6)
		move.w	#$8100,d6
		move.b	(RAM_VdpCache+1),d5
		bset	#4,d5
		or.b	d5,d6
		move.w	#$0100,(z80_bus).l
		move.w	d6,(a6)

		move.l	#$94019318,(a6)			; Size $118
		move.l	#$96009500+((RAM_Ttle_SpriteData<<7)&$FF0000)|((RAM_Ttle_SpriteData>>1)&$FF),(a6)
		move.w	#$9700|((RAM_Ttle_SpriteData>>17)&$7F),(a6)
		move.w	#$7800,(a6)
		move.w	#$0003|$80,-(sp)
.wait:		btst	#0,(z80_bus).l
		bne.s	.wait
		move.w	(sp)+,(a6)
		move.l	#$94009328,(a6)
		move.l	#$96009500+((RAM_VerScroll<<7)&$FF0000)|((RAM_VerScroll>>1)&$FF),(a6)
		move.w	#$9700|((RAM_VerScroll>>17)&$7F),(a6)
		move.w	#$4000,(a6)
		move.w	#$0010|$80,-(sp)
		move.w	(sp)+,(a6)
		move.l	#$940193C0,(a6)
		move.l	#$96009500+((RAM_HorScroll<<7)&$FF0000)|((RAM_HorScroll>>1)&$FF),(a6)
		move.w	#$9700|((RAM_HorScroll>>17)&$7F),(a6)
		move.w	#$7C00,(a6)
		move.w	#$0003|$80,-(sp)
		move.w	(sp)+,(a6)
		move.l	#$94009340,(a6)
		move.l	#$96009500|(RAM_FadeTarget<<7&$FF0000)+(RAM_FadeTarget>>1&$FF),(a6)
		move.w	#$9700|(RAM_FadeTarget>>17&$7F),(a6)
		move.w	#$C000,(a6)
		move.w	#$0000|$80,-(sp)
		move.w	(sp)+,(a6)

		move.w	#0,(z80_bus).l
		move.w	#$8100,d6
		or.b	(RAM_VdpCache+1),d6
		move.w	d6,(a6)
		movem.l	(sp)+,d0-a6
		rte

; ====================================================================
; ----------------------------------------------------------------
; Small data
; ----------------------------------------------------------------

str_Copyinfo:	dc.b "2020 GF64/@_gf64",0
		align 2

Pal_Title_FG:
		binclude "game/graphics/title/title_pal.bin"
		align 2
Map_Title_FG:
		binclude "game/graphics/title/title_map.bin"
		align 2
Pal_Title_BG:
		binclude "game/graphics/title/bg_pal.bin"
		align 2
Map_Title_BG:
		binclude "game/graphics/title/bg_map.bin"
		align 2
Map_MenuText:
		binclude "game/graphics/title/menu_map.bin"
		align 2
		
; list_TrackData:
; 		dc.w MusicBlk_Tronik&$FFFF
; 		dc.w MusicPat_Tronik&$FFFF
; 		dc.w MusicIns_Tronik&$FFFF
; 		dc.w (ZSnd_MusicBank>>15)
; 		dc.b 0,0,0,1
; 		dc.l 0
