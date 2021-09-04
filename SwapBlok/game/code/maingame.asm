; ================================================================
; ------------------------------------------------------------
; MAIN PUZZLE GAME MODE
; 
; some variables/structs are located at global.asm
; ------------------------------------------------------------

; NOTES:
; Window layer positions/registers
; Single screen:
; 9202
; 929A
; Split screen:
; 9201
; 928D
; 922F
; 929B

; ====================================================================
; ----------------------------------------------------------------
; Settings
; ----------------------------------------------------------------

PZMODE_MARATHON		equ 1
PZMODE_BATTLE		equ 2

SET_MAXBLKMTCH		equ 3			; MAX matching blocks (Vert/Horz)
SET_MAXUSERBLKS		equ 8			; MAX blocks to check for matching (starting from 1)
SET_STRTTRSHIDS		equ $0D			; Trash blocks start from this ID
SET_MAXTIMEOUT		equ 60*5		; 5 seconds

VRAMSET_CURSOR		equ $200
VRAMSET_BLOCKS		equ $2A0
VRAMSET_BOXBORDER	equ $400
VRAMSET_CELLHIDE	equ $780
VRAMSET_SPRSHDW		equ $790		; OR(|) $6000 in the sprite
VRAMSET_SPRHIGH		equ $7A0		; OR(|) $6000 in the sprite

; ***HARDCODED***
MAX_BOXWIDTH		equ 16*2		; value*2, blocks are WORD sized
MAX_BOXHEIGHT		equ 32*2		; Divided by BLOCKS and TRASH

BLKDEL_MIDANIM		equ $3E00		; midanimation
BLKDEL_TIMEOUT		equ $5000		; END

BLKROLL_STAY		equ $5100		; START
BLKROLL_FALL		equ $7000		; END

; ====================================================================
; ----------------------------------------------------------------
; Structs
; ----------------------------------------------------------------

; moved to global.asm
			
; ====================================================================
; ----------------------------------------------------------------
; Variables
; ----------------------------------------------------------------

blkflg_Draw		equ $8000		; Don't change
blkflg_Fall		equ $0040		; full value of bitBlkFlg_Match

bitBlkFlg_Match		equ 7			; $80
bitBlkFlg_Fall		equ 6			; $40
bitBlkFlg_Chain		equ 5			; $20

; ====================================================================
; ----------------------------------------------------------------
; RAM
; ----------------------------------------------------------------

			struct $FF0000
RAM_PGame_BlockData	ds.w (MAX_BOXWIDTH*MAX_BOXHEIGHT)*MAX_BOXES
			finish

			
			struct RAM_Local
RAM_PGame_YScrl_Main	ds.l 336/16
RAM_PGame_Yscrl_Sub	ds.l 336/16
RAM_PGame_XAnimBuff	ds.l 224
RAM_PGame_YAnimBuff	ds.l 336/16
RAM_PGame_GlblTimer	ds.l 1
RAM_PGame_BgScrlX	ds.w 1			; XXXX
RAM_PGame_BgScrlY	ds.w 1			; XXXX
RAM_PGame_SpriteData	ds.w 4*70
RAM_PGame_HintCount	ds.w 1
RAM_PGame_SplitMode	ds.w 1
RAM_PGame_StartCount	ds.w 1			; Countdown before starting
RAM_PGame_CursorFrame	ds.w 1			; 0 or 1
RAM_PGame_CursorTimer	ds.w 1
RAM_PGame_DbgColor	ds.w 1
RAM_PGame_VInt		ds.w 1
RAM_PGame_PlyrsOn	ds.w 1			; NUM of active players
RAM_PGame_MatchStrtTime	ds.w 1			; Timer before starting
RAM_PGame_GameMode	ds.w 1
RAM_PGame_Sound		ds.w 1
sizeof_PGame		ds.l 0
			finish

; 	if MOMPASS=1
; 	message "MainGame Screen uses: \{((sizeof_PGame-RAM_Local)&$FFFFFF)}"
; 	endif
	
; ====================================================================
; ----------------------------------------------------------------
; Init
; ----------------------------------------------------------------

MainGame_Init:
		move.w	#$2700,sr
		bsr	Video_Clear		; Clear ALL VRAM

		move.w	#$1111,d0			; 2cell border
		move.w	#(16*$40)-1,d1
		move.w	#VRAMSET_CELLHIDE*$20,d2
		bsr	Video_Fill
		move.w	#$EEEE,d0			; Shadow sprite tiles	
		move.w	#(16*$40)-1,d1
		move.w	#VRAMSET_SPRHIGH*$20,d2
		bsr	Video_Fill
		move.w	#$FFFF,d0			; Highlight sprite tiles	
		move.w	#(16*$40)-1,d1
		move.w	#VRAMSET_SPRSHDW*$20,d2
		bsr	Video_Fill
		moveq	#0,d0
		bsr	vid_PickLayer
		lea	(vdp_data),a6			; Fill HiPrio bit to all the FG layer
		move.l	d4,4(a6)
		move.l	#$80008000,d2
		move.w	#$7FF/2,d1
.hiprio:
		move.l	d2,(a6)
		dbf	d1,.hiprio
		move.l	#locate(2,0,0),d0		; Now to BG layer
		bsr	vid_PickLayer
		move.l	d4,4(a6)
		move.w	#$7FF/2,d1
.hiprio2:
		move.l	d2,(a6)
		dbf	d1,.hiprio2
		move.l	#$60000002,4(a6)		; HiPrio to splitscreen layer at $A000
		move.w	#$7FF/2,d1
.hiprio3:
		move.l	d2,(a6)
		dbf	d1,.hiprio3
		clr.l	(RAM_PGame_SpriteData).l
		clr.l	(RAM_PGame_SpriteData+4).l
		
		clr.l	(RAM_PGame_BgScrlX).l
		clr.l	(RAM_PGame_BgScrlY).l
		move.b	#%10001001,(RAM_VdpCache+$C).w		; H40 + shadow mode
		move.b	#$6F,(RAM_VdpCache+$A).w		; Hint value 1/2 screen
		move.l	#MainGame_HBlank,(RAM_GoToHBlnk+2).w
		tst.w	(RAM_PGame_SplitMode).w
		beq.s	.plyrloop
		or.b	#%00000110,(RAM_VdpCache+$C).w
		move.b	#$37,(RAM_VdpCache+$A).w		; Hint value 1/4 screen
		move.l	#MainGame_HBlank_2P,(RAM_GoToHBlnk+2).w
.plyrloop:
		move.l	#MainGame_VBlank,(RAM_GoToVBlnk+2).w
		or.b	#%00010000,(RAM_VdpCache).w		; Enable HBlank interrupt
		or.b	#%00100000,(RAM_VdpCache+1).w		; Enable VBlank interrupt
		move.b	#$00,(RAM_VdpCache+7).w			; BG color $30
		move.b	#%111,(RAM_VdpCache+$B).w		; Scroll type: Horz LINE, Vert 2CELL

		move.l	#Art_BlockPzes,d0
		move.w	#(Art_BlockPzes_e-Art_BlockPzes),d1
		move.w	#VRAMSET_BLOCKS,d2
		bsr	Video_LoadArt
		move.l	#Art_PlyrBorders,d0
		move.w	#(Art_PlyrBorders_e-Art_PlyrBorders),d1
		move.w	#VRAMSET_BOXBORDER,d2
		bsr	Video_LoadArt
		move.l	#Art_PlyrCursor,d0
		move.w	#(Art_PlyrCursor_e-Art_PlyrCursor),d1
		move.w	#VRAMSET_CURSOR,d2
		bsr	Video_LoadArt
		bsr	PzlGame_InitCursors
		bsr	PzlGame_MakeBoxes
		bsr	PzlGame_LoadScores
		bsr	PzlGame_AnimateBg_Init
		bsr	PzlGame_LoadBackgrnd
		move.w	#$100,(RAM_PGame_MatchStrtTime).w

		lea	Pal_BlockPzes(pc),a0
		moveq	#$10,d0
		move.w	#47,d1
		bsr	Video_LoadPal_Fade
		bsr	Video_Update				; Update VDP registers
		move.w	#$2000,sr
		moveq	#0,d0
		move.w	#64,d1
		move.w	#$10,d2
		bsr	Video_PalFade_In

; ====================================================================
; ----------------------------------------------------------------
; Loop
; ----------------------------------------------------------------

; ------------------------------------------------

MainGame_Loop:
		move.w	#1,(RAM_PGame_VInt).w
		bsr	System_Random
		bsr	PzlGame_AnimateBg
.loop:		tst.w	(RAM_PGame_Vint).w
		bne.s	.loop
		tst.w	(RAM_PGame_MatchStrtTime).w
		beq.s	.canrendr
		sub.w	#1,(RAM_PGame_MatchStrtTime).w
		bne.s	MainGame_Loop
.canrendr:
		bsr	PzlGame_PlayerInputs

; ------------------------------------------------
; While rendering
; ------------------------------------------------

		bsr	PzlGame_UpdateBoxes
		bsr	PzlGame_MkSwapAndSpr
		bra	MainGame_Loop

; ====================================================================
; ----------------------------------------------------------------
; VBlank
; ----------------------------------------------------------------

; ------------------------------------------------
; Inside VBlank
; ------------------------------------------------

MainGame_VBlank:
		movem.l	d0-a6,-(sp)
		move.w	#$2700,sr
		bsr	PzlGame_DefVBlank
; 		move.l	#$C0000000,(a6)
; 		move.w	#$080,(a5)

; ------------------------------------
; Draw requests
; ------------------------------------

		tst.w	(RAM_PGame_MatchStrtTime).w
		bne.s	.wait_match
		bsr	PzlGame_BcdTimer_Up
.wait_match:
		lea	(RAM_Glbl_PzlBoxes),a6			; *** Draw players blocks ***
		lea	vramList_MainBlocks(pc),a3
		bsr	PzlVint_PlyrDrwTasks
		adda 	#sizeof_Box,a6
		bsr	PzlVint_PlyrDrwTasks
		adda 	#sizeof_Box,a6
		bsr	PzlVint_PlyrDrwTasks
		adda 	#sizeof_Box,a6
		bsr	PzlVint_PlyrDrwTasks
		lea	(RAM_Glbl_PzlScores),a6
		bsr	PzlGame_UpdScores
		adda	#sizeof_ScorBox,a6
		bsr	PzlGame_UpdScores
		adda	#sizeof_ScorBox,a6
		bsr	PzlGame_UpdScores
		adda	#sizeof_ScorBox,a6
		bsr	PzlGame_UpdScores

		add.l	#1,(RAM_GlblFrameCnt).w		; Frame counter
		clr.w	(RAM_PGame_HintCount).w
		move.w	#0,(RAM_PGame_VInt).w
		move.w	#$2000,sr
		movem.l	(sp)+,d0-a6
		rte

; ------------------------------------
; MAIN Game modes
; ------------------------------------

; ------------------------------------
; Default visual tasks
; 
; a6 - vdp_ctrl
; a5 - vdp_data
; ------------------------------------

PzlGame_DefVBlank:
		bsr	System_Input			; Read input
		lea	(vdp_ctrl),a6
		lea	(vdp_data),a5
		move.w	#$9201,d4			; Return TOP Window
		tst.w	(RAM_PGame_SplitMode).w
		bne.s	.nowndwtop
		add.w	#1,d4				; $9202
.nowndwtop:
		move.w	d4,(a6)
		move.w	#$8230,(a6)			; VDP: Return PLANEA to $C000
		move.w	#$8100,d6
		move.b	(RAM_VdpCache+1),d5
		bset	#4,d5
		or.b	d5,d6
		move.w	#$0100,(z80_bus).l
		move.w	d6,(a6)
		move.l	#$94019318,(a6)			; Size $118
		move.l	#$96009500+((RAM_PGame_SpriteData<<7)&$FF0000)|((RAM_PGame_SpriteData>>1)&$FF),(a6)
		move.w	#$9700|((RAM_PGame_SpriteData>>17)&$7F),(a6)
		move.w	#$7800,(a6)
		move.w	#$0003|$80,-(sp)
.wait:		btst	#0,(z80_bus).l
		bne.s	.wait
		move.w	(sp)+,(a6)
		move.l	#$94009328,(a6)
		move.l	#$96009500+((RAM_PGame_YScrl_Main<<7)&$FF0000)|((RAM_PGame_YScrl_Main>>1)&$FF),(a6)
		move.w	#$9700|((RAM_PGame_YScrl_Main>>17)&$7F),(a6)
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
		rts

; ====================================================================
; ----------------------------------------------------------------
; Subs
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init player cursors
; --------------------------------------------------------

PzlGame_InitCursors:
		lea	(RAM_Glbl_PzlCursors),a6
		moveq	#0,d0
		move.w	#MAX_BOXES-1,d7
.clrcursors:
		clr.w	cursor_X(a6)
		clr.w	cursor_Y(a6)
		clr.w	cursor_SwapMode(a6)
		adda	#sizeof_Cursor,a6
		dbf	d7,.clrcursors
		rts

; --------------------------------------------------------
; Init block boxes
; --------------------------------------------------------

PzlGame_MakeBoxes:
		moveq	#0,d0
		lea	(RAM_PGame_YScrl_Main),a0
		lea	(RAM_PGame_Yscrl_Sub),a1
		lea	(RAM_PGame_YAnimBuff),a2
		move.w	#(336/16)-1,d1
.yloop:
		move.l	d0,(a0)+
		move.l	d0,(a1)+
		move.l	d0,(a2)+
		dbf	d1,.yloop
		lea	(RAM_PGame_XAnimBuff),a0
		lea	(RAM_HorScroll),a1
		move.w	#(224)-1,d1
.xloop:
		move.l	d0,(a0)+
		move.l	d0,(a1)+
		dbf	d1,.xloop

		lea	(RAM_Glbl_PzlBoxes),a0			; Draw box borders
		lea	(vdp_data),a3
		move.w	#MAX_BOXES-1,d3
.plyrloop:
		btst	#bitPlySt_Active,box_Status(a0)
		beq	.no_exupdwn
		moveq	#0,d0
		move.l	d0,box_YScrl(a0)
		move.l	d0,box_YScrl_old(a0)
		move.w	d0,box_YShake(a0)
		bclr	#bitPlySt_GameOver,box_Status(a0)
		bclr	#bitPlySt_MidSwapStop,box_Status(a0)
		clr.l	box_YScrl(a0)
		clr.w	box_NumMtchBlk(a0)
		clr.w	box_NumMtchAdd(a0)
		clr.w	box_TrshReq(a0)
		clr.w	box_ComboCntShow(a0)
		clr.l	box_YScrl(a0)
		clr.l	box_YScrl_old(a0)
		clr.w	box_YShake(a0)
		add.w	#1,(RAM_PGame_PlyrsOn).w
		
	; BIG routine to draw
	; player borders
		lea	Map_PlyrBrdr(pc),a4
		cmp.w	#15,box_BoardY(a0)
		bge	.do_double_res
.single_only:							; Single resolution mode
		move.l	#locate(2,0,0),d0
		move.w	box_BoardY(a0),d4
		sub.w	#1,d4
		btst	#2,(RAM_VdpCache+$C).l
		bne.s	.nodbleytp
		add.w	d4,d4
.nodbleytp:
		and.l	#$FF,d4
		or.l	d4,d0
		move.w	box_BoardX(a0),d4
		sub.w	#1,d4
		add.w	d4,d4
		lsl.w	#8,d4
		and.l	#$00FF00,d4
		or.l	d4,d0
		bsr	vid_PickLayer
		bsr	.brdr_dotopbotm
		move.l	#locate(2,0,0),d0
		move.w	box_BoardY(a0),d4
		add.w	box_Height(a0),d4
		sub.w	#1,d4
		btst	#2,(RAM_VdpCache+$C).l
		bne.s	.nodbleybt
		add.w	d4,d4
.nodbleybt:
		and.l	#$FF,d4
		or.l	d4,d0
		move.w	box_BoardX(a0),d4
		sub.w	#1,d4
		add.w	d4,d4
		lsl.w	#8,d4
		and.l	#$00FF00,d4
		or.l	d4,d0
		bsr	vid_PickLayer
		bsr	.brdr_dotopbotm

		moveq	#locate(0,0,0),d0		; Make LEFT/RIGHT borders
		move.w	box_BoardY(a0),d4
		move.w	box_Height(a0),d2
		btst	#2,(RAM_VdpCache+$C).l
		bne.s	.nodbley
		add.w	d4,d4
.nodbley:
		sub.w	#1,d2
		and.l	#$FF,d4
		or.l	d4,d0
		move.w	box_BoardX(a0),d4
		sub.w	#1,d4
		add.w	d4,d4
		lsl.w	#8,d4
		and.l	#$00FF00,d4
		or.l	d4,d0
		bsr	vid_PickLayer
		move.l	(a4)+,d0			; Top LEFT BOMB
		move.l	(a4)+,d1
		move.w	box_Height(a0),d2
		swap	d3
		sub.w	#2,d2
		move.w	d2,d3
		sub.w	#1,d3
		move.l	#$800000,d7
		btst	#2,(RAM_VdpCache+$C).w
		bne.s	.lftloop
		add.l	d7,d7
.lftloop:
; 		cmp.w	d3,d2
; 		bne.s	.lft_topbomb
; 		move.l	(a4)+,d0			; Top LEFT Middle
; 		move.l	(a4)+,d1
; .lft_topbomb
; 		tst.w	d2
; 		bne.s	.lft_botbomb
; 		move.l	(a4)+,d0			; Top LEFT BOMB
; 		move.l	(a4)+,d1		
; .lft_botbomb:
		bsr	.brdr_piece
		add.l	d7,d4				; Manual SIZE
		dbf	d2,.lftloop

		moveq	#locate(0,0,0),d0		; Make LEFT/RIGHT borders
		move.w	box_BoardY(a0),d4
		btst	#2,(RAM_VdpCache+$C).l
		bne.s	.nodbley2
		add.w	d4,d4
.nodbley2:
		and.l	#$FF,d4
		or.l	d4,d0
		move.w	box_BoardX(a0),d4
		add.w	box_Width(a0),d4
		add.w	d4,d4
		lsl.w	#8,d4
		and.l	#$00FF00,d4
		or.l	d4,d0
		bsr	vid_PickLayer
		move.l	(a4)+,d0			; Top LEFT
		move.l	(a4)+,d1
		move.w	box_Height(a0),d2
		sub.w	#2,d2
		move.w	d2,d3
		sub.w	#1,d3
		move.l	#$800000,d7
		btst	#2,(RAM_VdpCache+$C).w
		bne.s	.rghtloop
		add.l	d7,d7
.rghtloop:
; 		cmp.w	d3,d2
; 		bne.s	.rght_topbomb
; 		move.l	(a4)+,d0			; Top LEFT Middle
; 		move.l	(a4)+,d1
; .rght_topbomb
; 		tst.w	d2
; 		bne.s	.rght_botbomb
; 		move.l	(a4)+,d0			; Top LEFT BOMB
; 		move.l	(a4)+,d1		
; .rght_botbomb:
		bsr	.brdr_piece
		add.l	d7,d4				; Manual SIZE
		dbf	d2,.rghtloop
		swap	d3
		bra	.no_exupdwn
; Double resolution mode
.do_double_res:						; Double resolution mode
		move.l	#locate(2,0,0),d0		; Window TOP/BOTTOM
		move.w	box_BoardY(a0),d4
		sub.w	#1,d4
		and.l	#$FF,d4
		or.l	d4,d0
		move.w	box_BoardX(a0),d4
		sub.w	#1,d4
		add.w	d4,d4
		lsl.w	#8,d4
		and.l	#$00FF00,d4
		or.l	d4,d0
		bsr	vid_PickLayer
		bsr	.brdr_dotopbotm
		move.l	#locate(2,0,0),d0
		move.w	box_BoardY(a0),d4
		add.w	box_Height(a0),d4
		sub.w	#1,d4
		and.l	#$FF,d4
		or.l	d4,d0
		move.w	box_BoardX(a0),d4
		sub.w	#1,d4
		add.w	d4,d4
		lsl.w	#8,d4
		and.l	#$00FF00,d4
		or.l	d4,d0
		bsr	vid_PickLayer
		bsr	.brdr_dotopbotm
		moveq	#locate(0,0,0),d0		; LEFT/RIGHT borders
		move.w	box_BoardY(a0),d4
		move.w	box_Height(a0),d2
		btst	#2,(RAM_VdpCache+$C).l
		bne.s	.nodbleydb
		add.w	d4,d4
.nodbleydb:
		sub.w	#1,d2
		and.l	#$FF,d4
		or.l	d4,d0
		move.w	box_BoardX(a0),d4
		sub.w	#1,d4
		add.w	d4,d4
		lsl.w	#8,d4
		and.l	#$00FF00,d4
		or.l	d4,d0
		bsr	puzlBotScr_SetPos
		swap	d3
		move.l	(a4)+,d0			; Top LEFT
		move.l	(a4)+,d1
		move.w	box_Height(a0),d2
		sub.w	#2,d2
		move.w	d2,d3
		sub.w	#1,d3

		move.l	#$800000,d7
		btst	#2,(RAM_VdpCache+$C).w
		bne.s	.lftloopdb
		add.l	d7,d7
.lftloopdb:
; 		cmp.w	d3,d2
; 		bne.s	.lftl_topbomb
; 		move.l	(a4)+,d0			; Top LEFT Middle
; 		move.l	(a4)+,d1
; .lftl_topbomb:
; 		tst.w	d2
; 		bne.s	.lftl_botbomb
; 		move.l	(a4)+,d0			; Top LEFT BOMB
; 		move.l	(a4)+,d1		
; .lftl_botbomb:
		bsr	.brdr_piece
		add.l	d7,d4				; Manual SIZE
		dbf	d2,.lftloopdb
		moveq	#locate(0,0,0),d0		; Make LEFT/RIGHT borders
		move.w	box_BoardY(a0),d4
		btst	#2,(RAM_VdpCache+$C).l
		bne.s	.nodbley2db
		add.w	d4,d4
.nodbley2db:
		and.l	#$FF,d4
		or.l	d4,d0
		move.w	box_BoardX(a0),d4
		add.w	box_Width(a0),d4
		add.w	d4,d4
		lsl.w	#8,d4
		and.l	#$00FF00,d4
		or.l	d4,d0
		bsr	puzlBotScr_SetPos
		move.l	(a4)+,d0			; Top LEFT
		move.l	(a4)+,d1
		move.w	box_Height(a0),d2
		sub.w	#2,d2
		move.w	d2,d3
		sub.w	#1,d3
		move.l	#$800000,d7
		btst	#2,(RAM_VdpCache+$C).w
		bne.s	.rghtloopdb
		add.l	d7,d7
.rghtloopdb:
; 		cmp.w	d3,d2
; 		bne.s	.rghtl_topbomb
; 		move.l	(a4)+,d0			; Top LEFT Middle
; 		move.l	(a4)+,d1
; .rghtl_topbomb:
; 		tst.w	d2
; 		bne.s	.rghtl_botbomb
; 		move.l	(a4)+,d0			; Top LEFT BOMB
; 		move.l	(a4)+,d1		
; .rghtl_botbomb:
		bsr	.brdr_piece
		add.l	d7,d4				; Manual SIZE
		dbf	d2,.rghtloopdb
		swap	d3
.no_exupdwn:
		adda 	#sizeof_Box,a0
		dbf	d3,.plyrloop

	; --------------------------------
	; Clear ALL buffer
	; --------------------------------
		lea	(RAM_Glbl_PzlBoxes),a6
		lea	(RAM_PGame_BlockData).l,a4
		move.w	#0,d4					; BLANK
		move.w	#(MAX_BOXWIDTH*MAX_BOXHEIGHT),d5
		move.w	#MAX_BOXES-1,d6
.grbg_player2:
		btst	#bitPlySt_Active,box_Status(a6)
		beq.s	.nobox_grbg2
		move.l	a4,box_BlockData(a6)
		move.l	a4,a2
		move.w	d5,d3
		sub.w	#1,d3
.clrall:
		move.w	d4,(a2)+
		dbf	d3,.clrall
		adda	d5,a4
.nobox_grbg2:
		adda 	#sizeof_Box,a6
		dbf	d6,.grbg_player2

	; --------------------------------
		move.l	(RAM_GlblRndSeeds).w,d2		; INIT trash blocks
		lea	(RAM_Glbl_PzlBoxes),a6
		move.w	#MAX_BOXES-1,d7
.grbg_player:
		btst	#bitPlySt_Active,box_Status(a6)
		beq	.nobox_grbg
		swap	d7
		
	; --------------------------------
	; Fill shadow BG
	; --------------------------------
		move.l	box_BlockData(a6),a4
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a4
		move.w	#blkflg_Draw,d5
		move.w	box_Height(a6),d7
		sub.w	#1,d7
.zerheight:
		move.w	box_Width(a6),d6
		sub.w	#1,d6
		movea.l	a4,a3
.zerwidth:
		move.w	d5,(a3)+
		dbf	d6,.zerwidth
		adda	#MAX_BOXWIDTH,a4
		dbf	d7,.zerheight

	; --------------------------------
	; Make First TRASH blocks
	; --------------------------------
		move.l	box_BlockData(a6),a4
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a4
		move.w	box_Height(a6),d4
		sub.w	#1,d4
		lsl.w	#5,d4
		adda	d4,a4
		move.l	a4,a5				; a5 - TOP check
		move.l	a4,a3				; *** Make FIRST row ***
		move.l	d2,d4
		move.w	box_Width(a6),d7
		sub.w	#1,d7
		moveq	#0,d5
		moveq	#0,d1
.clmn_first:
		bsr	box_GuessBlk
; 		ror.l	d2,d4
		cmp.b	d5,d0
		beq.s	.clmn_first
		cmp.b	#SET_MAXUSERBLKS,d0
		bge.s	.clmn_first
; 		cmp.b	#7,d0				; RED bomb?
; 		beq.s	.clmn_first		
; 		cmp.b	#8,d0				; BLUE bomb?
; 		beq.s	.clmn_first
		cmp.w	box_UserMaxIds(a6),d0		; MAX usable blocks (dificulty)
		bgt.s	.clmn_first
		move.b	d0,d5
		move.w	d0,d1
		or.w	#blkflg_Draw,d1
		move.w	d1,(a3)+
		dbf	d7,.clmn_first

	; Now the rest
	; of the lines
		moveq	#0,d1
		suba	#MAX_BOXWIDTH,a4
		move.w	box_UserLevel(a6),d6
		sub.w	#1,d6
		move.l	a4,a2
		move.l	a5,a3
.clmn_loop:
		move.w	box_Width(a6),d7
		sub.w	#1,d7
.clmn_next:
		bsr	box_GuessBlk
		ror.l	d2,d4
		cmp.b	d5,d0
		beq.s	.clmn_next
		move.w	(a5),d3
		and.w	#$FF,d3
		cmp.w	d3,d0
		beq.s	.clmn_next
		cmp.b	#SET_MAXUSERBLKS,d0
		bge.s	.clmn_next
; 		cmp.b	#7,d0				; RED bomb?
; 		beq.s	.clmn_next	
; 		cmp.b	#8,d0				; BLUE bomb?
; 		beq.s	.clmn_next
		cmp.w	box_UserMaxIds(a6),d0		; MAX usable blocks (dificulty)
		bgt.s	.clmn_next
		move.b	d0,d5
		move.w	d0,d1
		or.w	#blkflg_Draw,d1
		move.w	d1,(a4)
		adda 	#2,a4
		adda 	#2,a5
		dbf	d7,.clmn_next
		suba	#MAX_BOXWIDTH,a2
		suba	#MAX_BOXWIDTH,a3
		move.l	a2,a4
		move.l	a3,a5
		dbf	d6,.clmn_loop
		swap	d7
		bset	#bitPlySt_DrwAll,box_Status(a6)
		bset	#bitPlySt_DrwLine,box_Status(a6)
.nobox_grbg:
		adda 	#sizeof_Box,a6
		dbf	d7,.grbg_player
		rts

; ----------------------------------------
; make border piece
; ----------------------------------------

.brdr_dotopbotm:
		move.l	(a4)+,d0			; Top LEFT
		move.l	(a4)+,d1
		bsr	.brdr_piece
		add.l	#$40000,d4
		move.l	(a4)+,d0			; Top MID
		move.l	(a4)+,d1
		move.w	box_Width(a0),d2
		sub.w	#1,d2
.topmid:
		bsr	.brdr_piece
		add.l	#$40000,d4
		dbf	d2,.topmid
		move.l	(a4)+,d0			; Top BOT
		move.l	(a4)+,d1
		bsr	.brdr_piece
		add.l	#$40000,d4
		rts
.brdr_piece:
		move.l	d4,d5
		move.l	d0,d6
		move.w	box_UserBorder(a0),d7
		and.w	#%11,d7
		lsl.w	#5,d7
		add.w	#VRAMSET_BOXBORDER+$E000,d6
		add.w	d7,d6
		swap	d6
		add.w	#VRAMSET_BOXBORDER+$E000,d6
		add.w	d7,d6
		swap	d6

		btst	#2,(RAM_VdpCache+$C).l
		beq.s	.brdrdbl1
		move.l	d6,d5
		lsr.l	#1,d5
		and.l	#$07FF07FF,d5
		and.l	#$F800F800,d6
		or.l	d5,d6
.brdrdbl1:
		move.l	d4,4(a3)
		move.l	d6,(a3)
		btst	#2,(RAM_VdpCache+$C).l
		bne.s	.brdrdbl2
		move.l	d4,d5
		add.l	#$800000,d5
		move.l	d1,d6
		move.w	box_UserBorder(a0),d7
		and.w	#%11,d7
		lsl.w	#5,d7
		add.w	#VRAMSET_BOXBORDER+$E000,d6
		add.w	d7,d6
		swap	d6
		add.w	#VRAMSET_BOXBORDER+$E000,d6
		add.w	d7,d6
		swap	d6

		move.l	d5,4(a3)
		move.l	d6,(a3)
.brdrdbl2:
		rts

.boxbrdrlist:
		dc.l (VRAMSET_BOXBORDER+$00|$E000)<<16|VRAMSET_BOXBORDER+$00|$E000
		dc.l (VRAMSET_BOXBORDER+$20|$E000)<<16|VRAMSET_BOXBORDER+$20|$E000
		dc.l (VRAMSET_BOXBORDER+$40|$E000)<<16|VRAMSET_BOXBORDER+$40|$E000
		dc.l (VRAMSET_BOXBORDER+$60|$E000)<<16|VRAMSET_BOXBORDER+$60|$E000
		
; --------------------------------------------------------
; Init score boxes
; --------------------------------------------------------

; TODO: fix this for doubleres

PzlGame_LoadScores:
		lea	(RAM_Glbl_PzlScores),a6		; Draw box borders
		lea	(vdp_data),a1
		move.w	#MAX_SCORBOX-1,d7
.plyrloop:
		btst	#bitScorSt_Active,scorBox_Status(a6)
		beq	.no_exupdwn
		movea.l	scorBox_BoxAddr(a6),a5

		move.l	box_UserScore(a5),d0
		moveq	#0,d1
		tst.w	scorBox_Type(a6)
		beq.s	.doit
		move.l	(RAM_PGame_GlblTimer),d0
		moveq	#0,d1
.doit:
		bsr	.drwscor_label

.no_exupdwn:
		adda 	#sizeof_ScorBox,a6
		dbf	d7,.plyrloop
		rts
		
; Draw label and value
.drwscor_label:
		lea	Map_ScoreInfo(pc),a4
		move.w	scorBox_Type(a6),d2		; * $20
		lsl.w	#5,d2
		adda	d2,a4
		
		move.l	d1,d4
		moveq	#0,d5
		move.w	scorBox_Y(a6),d5
		swap	d4
		lsl.w	#7,d5
		add.w	d5,d5
		move.w	scorBox_X(a6),d6
		add.w	d4,d6
		add.w	d6,d6
		add.w	d6,d5
		swap	d5
		or.l	#$40000003,d5
		move.l	d5,d6
		add.l	#$800000,d6
		move.l	d5,d3
		move.l	d5,4(a1)
		move.l	(a4)+,d4
		add.l	#((VRAMSET_BOXBORDER+$A0)<<16)|VRAMSET_BOXBORDER+$A0|$80008000+$60006000,d4
		move.l	d4,(a1)
		move.l	d6,4(a1)
		move.l	(a4)+,d4
		add.l	#((VRAMSET_BOXBORDER+$A0)<<16)|VRAMSET_BOXBORDER+$A0|$80008000+$60006000,d4
		move.l	d4,(a1)
		add.l	#$40000,d5
		add.l	#$40000,d6
		move.l	d5,4(a1)
		move.l	(a4)+,d4
		add.l	#((VRAMSET_BOXBORDER+$A0)<<16)|VRAMSET_BOXBORDER+$A0|$80008000+$60006000,d4
		move.l	d4,(a1)
		move.l	d6,4(a1)
		move.l	(a4)+,d4
		add.l	#((VRAMSET_BOXBORDER+$A0)<<16)|VRAMSET_BOXBORDER+$A0|$80008000+$60006000,d4
		move.l	d4,(a1)
		add.l	#$40000,d5
		add.l	#$40000,d6
		move.l	d5,4(a1)
		move.w	(a4)+,d4
		adda	#2,a4
		add.w	#VRAMSET_BOXBORDER+$A0|$8000+$6000,d4
		move.w	d4,(a1)
		move.l	d6,4(a1)
		move.w	(a4)+,d4
		adda	#2,a4
		add.w	#VRAMSET_BOXBORDER+$A0|$8000+$6000,d4
		move.w	d4,(a1)

; 		move.l	d5,4(a1)
; 		move.l	(a4)+,d4
; 		add.w	#VRAMSET_BOXBORDER+$A0|$8000+$6000,d4
; 		move.w	d4,(a1)
; 		move.l	d6,4(a1)
; 		move.w	(a4)+,d4
; 		add.w	#VRAMSET_BOXBORDER+$A0|$8000+$6000,d4
; 		move.w	d4,(a1)

; 	; print numbers
; 		move.l	d3,d5
; 		add.l	#$1000000,d5
; 		move.l	d5,d6
; 		add.l	#$800000,d6
; 		tst.w	scorBox_Type(a6)
; 		bne.s	.show_time
; 		move.l	d0,d4
; 		rol.l	#8,d4
; 		move.w	#6-1,d2
; .nxtnmbr:
; 		rol.l	#4,d4
; 		move.b	d4,d0
; 		and.w	#$F,d0
; 		add.w	d0,d0
; 		add.w	#VRAMSET_BOXBORDER+$80|$8000+$6000,d0
; 		move.l	d5,4(a1)
; 		move.w	d0,(a1)
; 		add.w	#1,d0
; 		move.l	d6,4(a1)
; 		move.w	d0,(a1)		
; 		add.l	#$20000,d5
; 		add.l	#$20000,d6
; 		dbf	d2,.nxtnmbr
; 		rts

.show_time:
		rts

; --------------------------------------------------------
; custom version of vid_PickLayer but for setting coords
; at the bottom section of doubleres mode
; 
; d0 - locate(0,x,y)
; 
; d4 - VDP position result
; d6 - next line
; --------------------------------------------------------

; vid_PickLayer:
puzlBotScr_SetPos:
		move.b	#$28,d4			; FG	
		move.w	d4,d5
		lsr.w	#4,d5
		andi.w	#%11,d5
		swap	d4
		move.w	d5,d4
		swap	d4
		andi.w	#%00001110,d4
		lsl.w	#8,d4
		lsl.w	#2,d4
		ori.w	#$4000,d4
		move.w	d0,d5			; Y start pos
		andi.w	#$FF,d5			; Y only
		lsl.w	#6,d5			
		move.b	(RAM_VdpCache+$10).w,d6
		andi.w	#%11,d6
		beq.s	.thissz
		add.w	d5,d5			; H64
		andi.w	#%10,d6
		beq.s	.thissz
		add.w	d5,d5			; H128		
.thissz:
		add.w	d5,d4
		move.w	d0,d5
		andi.w	#$FF00,d5		; X only
		lsr.w	#7,d5
		add.w	d5,d4			; X add
		swap	d4
		moveq	#0,d6
		move.w	#$40,d6			; Set jump size
		move.b	(RAM_VdpCache+$10).w,d5
		andi.w	#%11,d5
		beq.s	.thisszj
		add.w	d6,d6			; H64
		andi.w	#%10,d5
		beq.s	.thisszj
		add.w	d6,d6			; H128		
.thisszj:
		swap	d6
; 		bra.s	*
		rts

; --------------------------------------------------------
; Load background
; --------------------------------------------------------

PzlGame_LoadBackgrnd:
		move.l	#Art_Backgrd00,d0
		move.w	#(Art_Backgrd00_e-Art_Backgrd00),d1
		move.w	#2,d2
		bsr	Video_LoadArt

		lea	Map_Backgrd00(pc),a0
		move.l	#locate(1,0,0),d0
		move.l	#mapsize(320,256),d1
		move.w	#$0002,d2
		bsr	Video_LoadMap_Vert
		btst	#2,(RAM_VdpCache+$C).l
		beq.s	.isdble
		lea	Map_Backgrd00(pc),a0
		move.l	#locate(1,0,16),d0
		move.l	#mapsize(320,256),d1
		move.w	#$0002,d2
		bsr	Video_LoadMap_Vert
.isdble:
		lea	Pal_Backgrd00(pc),a0
		moveq	#0,d0
		move.w	#15,d1
		bra	Video_LoadPal_Fade
		rts
		
; --------------------------------------------
; Draw ALL blocks request
; 
; VBLANK ONLY, CPU HEAVY
; --------------------------------------------

PzlVint_PlyrDrwTasks:
		btst	#bitPlySt_Active,box_Status(a6)
		beq	.no_plyr
		bclr	#bitPlySt_DrwAll,box_Status(a6)
		beq	.no_drwall
		bsr	.drw_all
.no_drwall:
		bclr	#bitPlySt_DrwLine,box_Status(a6)
		beq	.no_plyr
		bsr	PzlVint_PlyrDrwLine
.no_plyr:
		rts
	
; --------------------------------------

.drw_all:
		moveq	#0,d5
		moveq	#0,d6
		movea.l	box_BlockData(a6),a4
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a4
		btst	#2,(RAM_VdpCache+$C).l
		bne	.dblemode
		
; --------------------------------------
; Normal res
; --------------------------------------

		move.w	box_BoardY(a6),d6
		lsl.w	#7,d6
		move.w	box_YScrl(a6),d2
		and.w	#$F0,d2
		lsl.w	#3,d2
		add.w	d2,d6
		add.w	d6,d6
		move.l	#$40000003,d4
		move.w	box_BoardX(a6),d2
		lsl.w	#2,d2
		add.w	d2,d6
		and.w	#$0FFF,d6
		swap	d6
		or.l	d4,d6
		move.w	box_Height(a6),d7
		sub.w	#1+1,d7
.nxt_row:
		swap	d7
		move.l	a4,a2
		move.w	box_Width(a6),d5
		sub.w	#1,d5
		move.l	d6,d3
.nxt_clmn:
		swap	d5
		moveq	#0,d1
		moveq	#0,d2
		move.w	(a2),d0
		btst	#bitPlySt_GameOver,box_Status(a6)
		bne	.force_drw
		tst.w	d0
		bpl	.no_drwflg
		move.w	d0,d5
		and.w	#$7FFF,d0
		move.w	d0,(a2)
.force_drw:
		and.w	#$1F,d0
		beq	.writeblk
		move.w	d0,d4
		sub.w	#1,d0
		lsl.w	#3,d0
		move.l	(a3,d0.w),d1
		move.l	4(a3,d0.w),d2
		add.l	#((VRAMSET_BLOCKS+$2000)<<16)|VRAMSET_BLOCKS+$2000,d1
		add.l	#((VRAMSET_BLOCKS+$2000)<<16)|VRAMSET_BLOCKS+$2000,d2
		btst	#bitPlySt_GameOver,box_Status(a6)
		bne	.writeblk
		and.w	#$7F00,d5
		cmp.w	#BLKROLL_STAY,d5
		bge.s	.blkbrght
		tst.w	d5
		beq.s	.blkbrght
		cmp.w	#SET_STRTTRSHIDS,d4
		bge.s	.trshblk
		cmp.w	#BLKDEL_MIDANIM,d5
		blt.s	.flashme
		move.w	d5,d7
		sub.w	#BLKDEL_MIDANIM,d7
		lsr.w	#4,d7
		and.w	#$3E0,d7
		cmp.w	#$20*4,d7
		bge.s	.shdwzero
		add.l	#(($80)<<16)|$80,d1
		add.l	#(($80)<<16)|$80,d2
		add.w	d7,d1
		add.w	d7,d2
		swap	d1		
		swap	d2
		add.w	d7,d1
		add.w	d7,d2
		swap	d1		
		swap	d2
		bra.s	.blkbrght
.blnkme:
		moveq	#0,d1
		moveq	#0,d2
		bra.s	.writeblk
.trshblk:
		move.l	#(((VRAMSET_BLOCKS+$2C)|$6000)<<16)|((VRAMSET_BLOCKS+$2E)|$6000),d1
		move.l	#(((VRAMSET_BLOCKS+$2D)|$6000)<<16)|((VRAMSET_BLOCKS+$2F)|$6000),d2

.flashme:
		and.w	#$100,d5
		bne.s	.writeblk
.blkbrght:
		add.l	#$80008000,d1
		add.l	#$80008000,d2
		bne.s	.writeblk		
.shdwzero:		
		moveq	#0,d1
		moveq	#0,d2		
.writeblk:
		move.l	d6,d4
		add.l	#$800000,d4
		move.l	d6,4(a5)
		move.l	d1,(a5)
		move.l	d4,4(a5)
		move.l	d2,(a5)
.no_drwflg:
		adda	#2,a2
		add.l	#$40000,d6
		swap	d5
		dbf	d5,.nxt_clmn
		move.l	d3,d6
		add.l	#$1000000,d6
		and.l	#$0FFF0000,d6
		or.l	#$40000003,d6
		adda	#MAX_BOXWIDTH,a4
		swap	d7
		dbf	d7,.nxt_row
.no_plyr_drwall:
		rts

; --------------------------------------
; Double res
; --------------------------------------

.dblemode:
		move.w	box_BoardY(a6),d6
		lsl.w	#7,d6
		move.w	box_YScrl(a6),d2
		and.w	#$1F0,d2
		lsl.w	#3,d2
		add.w	d2,d6
		move.l	#$40000003,d4
		cmp.w	#15,box_BoardY(a6)
		blt.s	.top_half
		move.l	#$60000002,d4
.top_half:
		move.l	#$1000000,d3
		move.w	box_BoardX(a6),d2
		lsl.w	#2,d2
		add.w	d2,d6
		and.w	#$0FFF,d6
		swap	d6
		or.l	d4,d6
		move.w	box_Height(a6),d7
		sub.w	#1+1,d7
.nxt_row_dbl:
		swap	d7
		move.l	d6,d3
		move.l	a4,a2
		move.w	box_Width(a6),d5
		sub.w	#1,d5
.nxt_clmn_dbl:
		swap	d5
		moveq	#0,d2
		move.w	(a4),d0
		btst	#bitPlySt_GameOver,box_Status(a6)
		bne	.force_drw_dbl
		tst.w	d0
		bpl	.skip_write_dbl
		move.w	d0,d5
		and.w	#$7FFF,d0
		move.w	d0,(a4)
.force_drw_dbl:
		and.w	#$1F,d0
; 		tst.b	d0
		beq	.writeblk_dble
		move.w	d0,d1
		swap	d1
		sub.w	#1,d0
		lsl.w	#3,d0
		move.w	(a3,d0.w),d2
		move.w	d2,d1
		and.w	#$F800,d1
		lsr.w	#1,d2
		and.w	#$7FF,d2
		or.w	d1,d2
		add.w	#((VRAMSET_BLOCKS)/2)+$2000,d2
		swap	d2
		move.w	2(a3,d0.w),d2
		move.w	d2,d1
		and.w	#$F800,d1
		lsr.w	#1,d2
		and.w	#$7FF,d2
		or.w	d1,d2
		swap	d1
		add.w	#((VRAMSET_BLOCKS)/2)+$2000,d2
		btst	#bitPlySt_GameOver,box_Status(a6)
		bne	.writeblk_dble
		and.w	#$7F00,d5
		cmp.w	#BLKROLL_STAY,d5
		beq.s	.blkbrght_dble
		tst.w	d5
		beq.s	.blkbrght_dble
		
		cmp.w	#$4000,d5
		blt.s	.flashme_dble
		cmp.w	#BLKDEL_TIMEOUT,d5
		beq.s	.blnkme_dble
		cmp.w	#BLKDEL_MIDANIM,d5
		blt.s	.flashme_dble
		cmp.w	#SET_STRTTRSHIDS,d1
		bge.s	.writeblk_dble
		move.w	d5,d7
		sub.w	#BLKDEL_MIDANIM,d7
		lsr.w	#4,d7
		and.w	#$3E0,d7
		cmp.w	#$20*4,d7
		bge.s	.shdwzero_dble
		lsr.w	#1,d7
		add.l	#(($30)<<16)|$30,d2
		add.w	d7,d2		
		swap	d2
		add.w	d7,d2		
		swap	d2
		bra.s	.blkbrght_dble
.blnkme_dble:
		moveq	#0,d2
		bra.s	.writeblk_dble
.flashme_dble:
		and.w	#$100,d5
		bne.s	.writeblk_dble
.blkbrght_dble:
		add.l	#$80008000,d2
		bra.s	.writeblk_dble
.shdwzero_dble:
		moveq	#0,d2
.writeblk_dble:
		move.l	d6,4(a5)
		move.l	d2,(a5)
.skip_write_dbl:
		adda	#2,a4
		add.l	#$40000,d6
		swap	d5
		dbf	d5,.nxt_clmn_dbl
		move.l	d3,d6
		add.l	#$800000,d6
		and.l	#$0FFF0000,d6
		or.l	d4,d6
		move.l	a2,a4
		adda	#MAX_BOXWIDTH,a4
		swap	d7
		dbf	d7,.nxt_row_dbl
		rts

; --------------------------------------------
; Draw single line from the BOTTOM
; --------------------------------------------

PzlVint_PlyrDrwLine:
		moveq	#0,d5
		moveq	#0,d6
		movea.l	box_BlockData(a6),a4
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a4
		move.w	box_Height(a6),d5
		sub.w	#1,d5
		move.w	d5,d6
		lsl.w	#5,d6
		adda	d6,a4
		btst	#2,(RAM_VdpCache+$C).l
		bne	.dblemode
		
; --------------------------------------
; Normal res
; --------------------------------------

		move.w	box_BoardY(a6),d6
		add.w	d5,d6
		lsl.w	#7,d6
		move.w	box_YScrl(a6),d5
		and.w	#$F0,d5
		lsl.w	#3,d5
		add.w	d5,d6
		add.w	d6,d6
		move.l	#$40000003,d4
		or.l	d6,d4

		move.l	#$1000000,d3
		move.w	box_BoardX(a6),d2
		lsl.w	#2,d2
		add.w	d2,d6
		move.w	d6,d5
		sub.w	#$0100,d5
		and.w	#$0FFF,d5
		and.w	#$0FFF,d6
		swap	d6
		swap	d5
		or.l	d4,d6
		or.l	d4,d5
		move.w	box_Width(a6),d7
		sub.w	#1,d7
.nxt_one:
		move.w	(a4),d0
		sub.w	#1,d0
		and.w	#%1111,d0
		lsl.w	#3,d0
		move.l	(a3,d0.w),d2
		add.l	#(((VRAMSET_BLOCKS+$2000))<<16)|(VRAMSET_BLOCKS+$2000),d2
		move.l	4(a3,d0.w),d1
		add.l	#(((VRAMSET_BLOCKS+$2000))<<16)|(VRAMSET_BLOCKS+$2000),d1
		move.l	d6,d4
		add.l	#$800000,d4
		move.l	d6,4(a5)
		move.l	d2,(a5)
		move.l	d4,4(a5)
		move.l	d1,(a5)

		move.l	d5,d4
		add.l	#$800000,d4		; Unshadow next one
		move.l	d5,d2
		move.l	d4,d1
		and.l	#$3FFF000F,d2
		and.l	#$3FFF000F,d1
		move.l	d2,4(a5)		
		move.l	(a5),d0
		or.l	#$80008000,d0
		move.l	d5,4(a5)
		move.l	d0,(a5)
		move.l	d1,4(a5)		
		move.l	(a5),d0
		or.l	#$80008000,d0
		move.l	d4,4(a5)
		move.l	d0,(a5)
		
		add.l	#$40000,d6
		add.l	#$40000,d5
		adda	#2,a4
		dbf	d7,.nxt_one
.no_plyr_drwl:
		rts

; --------------------------------------
; Double res
; --------------------------------------

.dblemode:
		move.w	box_Height(a6),d6
		sub.w	#1,d6
		add.w	box_BoardY(a6),d6
		lsl.w	#7,d6
		move.w	box_YScrl(a6),d2
		and.w	#$1F0,d2
		lsl.w	#3,d2
		add.w	d2,d6
		move.l	#$40000003,d4
		cmp.w	#15,box_BoardY(a6)
		blt.s	.top_half
		move.l	#$60000002,d4
.top_half:
		move.l	#$1000000,d3
		move.w	box_BoardX(a6),d2
		lsl.w	#2,d2
		add.w	d2,d6
		move.w	d6,d5
		sub.w	#$0080,d5
		and.w	#$0FFF,d5
		and.w	#$0FFF,d6
		swap	d6
		swap	d5
		or.l	d4,d6
		or.l	d4,d5
		move.w	box_Width(a6),d7
		sub.w	#1,d7
.nxt_one_d:
		move.w	(a4),d0
		sub.w	#1,d0
		and.w	#%1111,d0
		lsl.w	#3,d0
		move.w	(a3,d0.w),d2
		move.w	d2,d1
		and.w	#$F800,d1
		lsr.w	#1,d2
		and.w	#$7FF,d2
		or.w	d1,d2
		add.w	#((VRAMSET_BLOCKS)/2)+$2000,d2
		swap	d2
		move.w	2(a3,d0.w),d2
		move.w	d2,d1
		and.w	#$F800,d1
		lsr.w	#1,d2
		and.w	#$7FF,d2
		or.w	d1,d2
		add.w	#((VRAMSET_BLOCKS)/2)+$2000,d2
		move.l	d5,d4
		move.l	d5,d3
		and.l	#$3FFF0003,d3
		move.l	d6,4(a5)
		move.l	d2,(a5)
		move.l	d3,4(a5)
		move.l	(a5),d0
		or.l	#$80008000,d0
		move.l	d5,4(a5)
		move.l	d0,(a5)
		add.l	#$40000,d6
		add.l	#$40000,d5
		adda	#2,a4
		dbf	d7,.nxt_one_d
		rts

; --------------------------------------------------------
; Update scores
; 
; VBLANK ONLY
; --------------------------------------------------------

PzlGame_UpdScores:
		btst	#bitScorSt_Active,scorBox_Status(a6)
		beq	.no_plyr
; 		movea.l	scorBox_BoxAddr(a6),a3
; 		move.l	box_UserScore(a3),d0
; 		tst.w	scorBox_Type(a6)
; 		beq.s	.doit
; 		move.l	(RAM_PGame_GlblTimer),d0
; ; 		moveq	#0,d1
; .doit:
; 		bsr	.drwscor_label


; ------------------------------------------------

.drwscor_label:
		movea.l	scorBox_BoxAddr(a6),a3
		moveq	#0,d1
		move.l	d1,d4
		moveq	#0,d5
		move.w	scorBox_Y(a6),d5
		add.w	d4,d5
		swap	d4
		lsl.w	#7,d5
		add.w	d5,d5
		move.w	scorBox_X(a6),d6
		add.w	d4,d6
		add.w	d6,d6
		add.w	d6,d5
		swap	d5
		or.l	#$40000003,d5
		move.l	d5,d6
		add.l	#$800000,d6

		add.l	#$1000000,d5
		move.l	d5,d6
		add.l	#$800000,d6
		
		move.w	scorBox_Type(a6),d2
		beq	.show_score
		cmp.w	#2,d2
		beq	.show_combo
		
.show_time:
		move.l	(RAM_PGame_GlblTimer),d0
		move.l	d0,d4
		rol.l	#8,d4

		rol.l	#4,d4
		move.b	d4,d0
		and.w	#$F,d0
		add.w	d0,d0
		add.w	#VRAMSET_BOXBORDER+$80|$8000+$6000,d0		; VRAM Points to numbers
		move.l	d5,4(a5)
		move.w	d0,(a5)
		add.w	#1,d0
		move.l	d6,4(a5)
		move.w	d0,(a5)		
		add.l	#$20000,d5
		add.l	#$20000,d6
		rol.l	#4,d4
		move.b	d4,d0
		and.w	#$F,d0
		add.w	d0,d0
		add.w	#VRAMSET_BOXBORDER+$80|$8000+$6000,d0		; VRAM Points to numbers
		move.l	d5,4(a5)
		move.w	d0,(a5)
		add.w	#1,d0
		move.l	d6,4(a5)
		move.w	d0,(a5)
		add.l	#$20000,d5
		add.l	#$20000,d6
		
	; :
		move.l	d5,4(a5)
		move.w	#VRAMSET_BOXBORDER+$94|$8000+$6000,d0		; VRAM Points to " : "
		move.w	d0,(a5)
		add.w	#1,d0
		move.l	d6,4(a5)
		move.w	d0,(a5)	
		add.l	#$20000,d5
		add.l	#$20000,d6

		rol.l	#4,d4
		move.b	d4,d0
		and.w	#$F,d0
		add.w	d0,d0
		add.w	#VRAMSET_BOXBORDER+$80|$8000+$6000,d0		; VRAM Points to numbers
		move.l	d5,4(a5)
		move.w	d0,(a5)
		add.w	#1,d0
		move.l	d6,4(a5)
		move.w	d0,(a5)		
		add.l	#$20000,d5
		add.l	#$20000,d6
		rol.l	#4,d4
		move.b	d4,d0
		and.w	#$F,d0
		add.w	d0,d0
		add.w	#VRAMSET_BOXBORDER+$80|$8000+$6000,d0		; VRAM Points to numbers
		move.l	d5,4(a5)
		move.w	d0,(a5)
		add.w	#1,d0
		move.l	d6,4(a5)
		move.w	d0,(a5)
.no_plyr:
		rts

; ----------------------------------------

.show_score:
		move.l	box_UserScore(a3),d4
; 		bra.s	*
		rol.l	#8,d4
		move.w	#6-1,d2
.nxtnmbr:
		rol.l	#4,d4
		move.b	d4,d0
		and.w	#$F,d0
		add.w	d0,d0
		add.w	#VRAMSET_BOXBORDER+$80|$8000+$6000,d0		; VRAM Points to numbers
		move.l	d5,4(a5)
		move.w	d0,(a5)
		add.w	#1,d0
		move.l	d6,4(a5)
		move.w	d0,(a5)		
		add.l	#$20000,d5
		add.l	#$20000,d6
		dbf	d2,.nxtnmbr
		rts

; ----------------------------------------

.show_combo:
		move.w	box_ComboCntShow(a3),d4
		rol.l	#8,d4
		move.w	#2-1,d2
.nxtnmbr2:
		rol.w	#4,d4
		move.b	d4,d0
		and.w	#$F,d0
		add.w	d0,d0
		add.w	#VRAMSET_BOXBORDER+$80|$8000+$6000,d0		; VRAM Points to numbers
		move.l	d5,4(a5)
		move.w	d0,(a5)
		add.w	#1,d0
		move.l	d6,4(a5)
		move.w	d0,(a5)		
		add.l	#$20000,d5
		add.l	#$20000,d6
		dbf	d2,.nxtnmbr2
		rts

; --------------------------------------------------------
; Move players
; --------------------------------------------------------

PzlGame_UpdateBoxes:
		btst	#bitMtch_Pause,(RAM_Glbl_GameMtchFlags).w
		bne	.box_paused
		lea	(RAM_Glbl_PzlBoxes),a6
		move.w	#MAX_BOXES-1,d7
		move.l	(RAM_GlblRndSeeds).w,d2
.this_plyr:
		swap	d7
		btst	#bitPlySt_Active,box_Status(a6)
		beq	.no_plyr
; 		btst	#bitPlySt_Pause,box_Status(a6)
; 		bne	.no_plyr

	; --------------------------------------

	; TODO: checking this way, 1P looses first if not moving at all
		btst	#bitMtch_MatchOver,(RAM_Glbl_GameMtchFlags).w
		bne	.upd_vscrl
		btst	#bitPlySt_GameOver,box_Status(a6)
		bne	.upd_vscrl
		btst	#bitPlySt_MidSwapStop,box_Status(a6)
		bne	.upd_vscrl
		bclr	#bitPlySt_ChkMatch,box_Status(a6)
		beq	.no_mtchchk

	; --------------------------------------
	; Horizontal match
	; --------------------------------------
		movea.l	box_BlockData(a6),a4
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a4
		move.l	a4,a3
		move.w	box_Height(a6),d6
		sub.w	#1+1,d6
.horz_clmn:
		swap	d6
		move.w	box_Width(a6),d6
		sub.w	#1,d6
		move.l	a4,a2
.horz_new:
		moveq	#1,d3
		moveq	#0,d1
.horz_row:
 		move.w	(a2),d0
 		move.w	d0,d5
		and.w	#$1F,d0
		beq.s	.hz_check
		cmp.b	#SET_MAXUSERBLKS,d0
		bgt.s	.hz_next4
		move.w	d5,d7
		and.w	#$7F00,d7
		beq.s	.hz_next2
.hz_next3:
		cmp.w	#SET_MAXBLKMTCH,d3
		bge.s	.hz_next2
.hz_next4:
		moveq	#1,d3
		moveq	#0,d1
		bra.s	.hz_next
.hz_next2:
		cmp.b	d1,d0
		bne.s	.hz_check
; 		btst	#bitBlkFlg_Fall,d5		; HZ only
; 		beq.s	.hz_check2
; 		btst	#bitBlkFlg_Match,d5
; 		beq.s	.hz_check		
.hz_check2:
		move.w	d5,d7
		and.w	#$7F00,d7
		bne.s	.hz_check
		add.w	#1,d3
		bra.s	.hz_next
.hz_check:
		move.w	d3,d4
		moveq	#1,d3
		cmp.w	#SET_MAXBLKMTCH,d4
		blt.s	.hz_save
		bsr	.hz_delblocks
.hz_save:
		move.b	d0,d1
.hz_next:
		adda	#2,a2
		dbf	d6,.horz_row
		move.w	d3,d4
		cmp.w	#SET_MAXBLKMTCH,d3
		blt.s	.hz_last
		bsr	.hz_delblocks
.hz_last:
		adda	#MAX_BOXWIDTH,a4
		swap	d6
		dbf	d6,.horz_clmn
		bra.s	.hz_exit
.hz_delblocks:
		swap	d1
		swap	d0
		clr.w	d0
		move.w	d4,d1
		sub.w	#1,d1
		move.l	a2,a1
.hz_delloop:
		move.w	-(a1),d4
		or.w	d4,d0
		and.w	#$1F,d4
		bset	#bitBlkFlg_Match,d4
		move.w	d4,(a1)
		dbf	d1,.hz_delloop
		move.w	d0,d4
		swap	d1
		swap	d0
		add.w	#1,box_MatchCount(a6)
		clr.l	box_BoardTimeOut(a6)
		btst	#bitBlkFlg_Chain,d4
		beq.s	.hz_nocomb
		
		moveq	#0,d4
		move.w	box_ComboCntShow(a6),d4
		move.w	#1,d1
 		abcd	d1,d4
 		move.w	d4,box_ComboCntShow(a6)
		add.w	#1,box_ComboCount(a6)
		bra.s	.hz_settrsh
.hz_nocomb:
; 		clr.w	box_ComboCount(a6)
		clr.w	box_ComboCntShow(a6)
.hz_settrsh:
		tst.w	box_ComboCount(a6)
		beq.s	.hz_noreq
		bset	#0,box_TrshReq(a6)
.hz_noreq:
		rts

.hz_exit:

	; --------------------------------------
	; Vertical match
	; --------------------------------------
		move.l	a3,a4
		move.w	box_Width(a6),d6
		sub.w	#1,d6
.vert_clmn:
		swap	d6
		move.w	box_Height(a6),d6
		sub.w	#1+1,d6
		move.l	a4,a2
.vert_new:
		moveq	#1,d3
		moveq	#0,d1
.vert_row:
 		move.w	(a2),d0
 		move.w	d0,d5
		and.w	#$1F,d0
		beq.s	.vt_check
		cmp.b	#SET_MAXUSERBLKS,d0
		bgt.s	.vt_next4
		move.w	d5,d7
		and.w	#$7F00,d7
		beq.s	.vt_next2
		cmp.w	#SET_MAXBLKMTCH,d3
		bge.s	.vt_next2
.vt_next4:
		moveq	#1,d3
		moveq	#0,d1
		bra.s	.vt_next
.vt_next2:
		cmp.b	d1,d0
		bne.s	.vt_check
		move.w	d5,d7
		and.w	#$7F00,d7
		bne.s	.vt_check
		add.w	#1,d3
		bra.s	.vt_next
.vt_check:
		move.w	d3,d4
		moveq	#1,d3
		cmp.w	#SET_MAXBLKMTCH,d4
		blt.s	.vt_save
		bsr	.vt_delblocks
		bra.s	.vert_new
.vt_save:
		move.b	d0,d1
.vt_next:
		adda	#MAX_BOXWIDTH,a2
		dbf	d6,.vert_row
		move.w	d3,d4
		cmp.w	#SET_MAXBLKMTCH,d3
		blt.s	.vt_last
		bsr	.vt_delblocks
.vt_last:
		adda	#2,a4
		swap	d6
		dbf	d6,.vert_clmn
		bra.s	.vt_exit
.vt_delblocks:
		swap	d1
		swap	d0
		clr.w	d0
		move.w	d4,d1
		sub.w	#1,d1
		move.l	a2,a1
		suba	#MAX_BOXWIDTH,a1
.vt_delloop:
		move.w	(a1),d4
		or.w	d4,d0
		and.w	#$1F,d4
		bset	#bitBlkFlg_Match,d4
		move.w	d4,(a1)
		suba	#MAX_BOXWIDTH,a1
		dbf	d1,.vt_delloop
		move.w	d0,d4
		swap	d1
		swap	d0
		btst	#bitBlkFlg_Match,d4
		bne.s	.vt_nocomb
		btst	#bitBlkFlg_Chain,d4
		beq.s	.vt_onlymtch
		moveq	#0,d4
		move.w	box_ComboCntShow(a6),d4
		move.w	#1,d1
 		abcd	d1,d4
 		move.w	d4,box_ComboCntShow(a6)
		add.w	#1,box_ComboCount(a6)
		bra.s	.vt_settrsh
.vt_onlymtch:
		add.w	#1,box_MatchCount(a6)
		clr.l	box_BoardTimeOut(a6)
.vt_nocomb:
; 		clr.w	box_ComboCount(a6)
		clr.w	box_ComboCntShow(a6)
.vt_settrsh:
		tst.w	box_ComboCount(a6)
		beq.s	.vz_noreq
		bset	#0,box_TrshReq(a6)
.vz_noreq:
		rts
.vt_exit:

	; exit
		bclr	#bitPlySt_SpdUp,box_Status(a6)
.no_mtchchk:
		btst	#bitMtch_Timeout,(RAM_Glbl_GameMtchFlags).w
		bne	.force_gameover
		
	; --------------------------------------
	; MAIN BLOCK CHECK ROUTINE
	; CPU HEAVY
	; 
	; Fall blocks, check matches, fall
	; trash blocks, etc.
	; 
	; Right to left, bottom to top
	; --------------------------------------
		clr.w	d7
		movea.l	box_BlockData(a6),a5
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a5
		move.l	a5,a4
		move.w	box_Height(a6),d6
		move.w	box_Width(a6),d5
		sub.w	#1,d5
		move.w	d6,d4
		sub.w	#1,d4
		lsl.w	#5,d4
		move.w	d5,d3
		add.w	d3,d3
		add.w	d3,d4
		adda	d4,a4
		move.l	a4,a3
		suba	#MAX_BOXWIDTH,a3
		moveq	#0,d0
		moveq	#0,d1

	; d0 - freeblock counter | block flags
	; d1 - reroll lastblock  | trash counter
	; 
	; d0 bits:
	; 0 - PAUSE      | force scroll stop
	; 1 - TRSHSTOP   | stop current trashblock
	; 2 - TRSHMTCH   | merge matches to trashblock
	; 3 - TRSHSHAKE  | screenshake request
	; 4 - TRSHGEN    | generate random block to current trshblock
	; 5 - TRSHADD    | extra Trash checking mode (bypass box_Height-1)
	; 7 - TRSHFREE   | set if a entire line is free
	
.blkfll_row:
		bclr	#5,d0
		bclr	#1,d0			; TRSHSTOP reset
		bclr	#2,d0			; TRSHMTCH reset
		move.l	a4,a2
		move.l	a3,a1
		swap	d6
		move.w	d5,d6
		swap	d5
.blkfll_clmn:
		move.w	(a1),d3			; TOP block
		move.w	(a2),d4			; BOT block

	; --------------------------------------
	; Check if BOT == 0
	;          BOT == blkflg_Fall
	;          BOT == BLKDEL_TIMEOUT
	; --------------------------------------
		move.w	d4,d7
		move.w	d4,d5
		and.w	#$7F00,d5			; get TIMER and ID bits
		cmp.w	#BLKDEL_TIMEOUT,d5		; Timerdone block?
		beq.s	.blkfll_ovrwrt			; Overwrite on fall
		move.w	d4,d7
		and.w	#$007F,d7
		cmp.w	#blkflg_Fall,d7			; If BOT == zero + fallbit
		beq.s	.blkfll_ovrwrt
		tst.w	d7				; If BOT != 0?
		bne	.blkfll_botactv

	; --------------------------------------
	; BOT == $0000
	; BOT == blank|fall ($0040)
	; BOT == BLKDEL_TIMEOUT
	; --------------------------------------
.blkfll_ovrwrt:
		swap	d0
		add.w	#1,d0
		swap	d0
		btst	#bitBlkFlg_Fall,d3		; TOP has fall request
		bne	.blkfll_canfall
		move.w	d3,d7
		and.w	#$7F00,d7
		bne	.blkfll_next2
		move.w	d3,d7
		and.w	#$1F,d7
		beq	.blkfll_topblnk
		cmp.w	#SET_STRTTRSHIDS,d7
		bge	.blkfll_trshchn

		move.w	d4,d7
		move.w	d4,d5
		and.w	#$7F00,d7
		cmp.w	#BLKDEL_TIMEOUT,d7
		beq	.blkfll_setfll
; 		cmp.w	#blkflg_Fall,d5			; TODO: ignoring this
; 		bne	.blkfll_next
.blkfll_setfll:
		bset	#bitBlkFlg_Fall,d3
		bset	#bitBlkFlg_Chain,d3
		move.w	d3,(a1)
		bra	.blkfll_next
		
.blkfll_next2:
		move.w	d3,d5
		move.w	d3,d7
		and.w	#$1F,d7
		and.w	#$7F00,d5
		cmp.w	#BLKROLL_FALL,d5
		bne.s	.blkfll_nottrsh2
		and.w	#$1F,d3
		or.w	#blkflg_Draw|blkflg_Fall,d3
		move.w	d3,(a1)
		bra	.blkfll_next
.blkfll_nottrsh2:
		cmp.w	#SET_STRTTRSHIDS,d7
		blt	.blkfll_next
		cmp.w	#BLKDEL_MIDANIM,d5
		blt	.blkfll_next
		sub.w	#SET_STRTTRSHIDS,d7
		and.w	#%11,d7
		beq.s	.blkfll_canset2
		cmp.w	#%01,d7
		bne	.blkfll_next
.blkfll_canset2:
		bset	#bitBlkFlg_Match,d3
		move.w	d3,(a1)
		bra	.blkfll_next

	; Trashchain fall manual check 1
	; if trashblock was stopped
.blkfll_trshchn:
		sub.w	#SET_STRTTRSHIDS,d7
		move.w	d7,d5
		and.w	#%11,d5
		cmp.w	#2,d5
		beq.s	.blkfll_next4
		bset	#5,d0
.blkfll_next4:

		btst	#3,d7				; MID?
		bne	.blkfll_trshmcnt
		btst	#2,d7				; TL?
		beq	.blkfll_trshtr
		clr.w	d1
		bclr	#1,d0				; TRSHSTOP reset
		bclr	#2,d0				; TRSHMTCH reset
		bra.s	.blkfll_trshmcnt
.blkfll_trshtr:
		clr.w	d5
		btst	#1,d0
		bne.s	.blkfll_nofllbt			; No change
		bset	#bitBlkFlg_Fall,d5
.blkfll_nofllbt:
		move.l	a1,a0
		btst	#2,d0
		beq.s	.trshidl_set
		bset	#bitBlkFlg_Match,d5
.trshidl_set:
		move.w	(a0),d7
		or.w	d5,d7
		move.w	d7,(a0)
		adda	#2,a0
		dbf	d1,.trshidl_set
		clr.w	d1
		bclr	#2,d0
		bclr	#1,d0
		bra	.blkfll_topblnk
.blkfll_trshmcnt:
		add.w	#1,d1				; Incrmnt fall length

.blkfll_topblnk:
		cmp.w	#blkflg_Fall,d4
		bne.s	.blkfll_decmonly
		move.w	#blkflg_Draw,(a2)
		bset	#bitPlySt_DrwAll,box_Status(a6)
		
.blkfll_decmonly:
		move.w	d4,d7
		and.w	#$7F00,d7
		cmp.w	#BLKDEL_TIMEOUT,d7
		bne	.blkfll_next
		bsr	.blkfll_dectmout
		move.w	#0,(a2)
		bra	.blkfll_next

.blkfll_dectmout:
		move.w	d4,d7				; copy BOT to d7
		and.w	#$7F00,d7
		cmp.w	#BLKDEL_TIMEOUT,d7		; TIMERDONE block?
		bne.s	.blkfll_timedel
		sub.w	#1,box_NumMtchBlk(a6)		; Decrement active blocks
		bne.s	.blkfll_timedel
		btst	#bitMtch_TrashEnbl,(RAM_Glbl_GameMtchFlags).w
		beq.s	.no_trshreq
; 		btst	#0,box_TrshReq(a6)
; 		bne.s	.no_trshreq
		bset	#1,box_TrshReq(a6)
.no_trshreq:
		clr.w	box_MatchCount(a6)
.blkfll_timedel:
		rts

	; --------------------------------------
	; TOP has falling request
	; --------------------------------------
.blkfll_canfall:
		bsr.s	.blkfll_dectmout
		move.w	d3,d7
		and.w	#$1F,d7
		beq	.blkfll_next
		cmp.w	#SET_STRTTRSHIDS,d7
		blt.s	.blkfll_normlblock
		
	; trashchain fall manual check 2
	; 
	; if the fallbits are set BUT the
	; TRSHSTOP flag is set
		sub.w	#SET_STRTTRSHIDS,d7
		move.w	d7,d5
		and.w	#%11,d5
		cmp.w	#2,d5
		beq.s	.blkfll_next5
		bset	#5,d0
.blkfll_next5:

		btst	#3,d7			; MIDL?
		bne.s	.blkfll_trshincr
		btst	#2,d7			; TR?
		bne.s	.blkfll_resincrm
		btst	#1,d0
		bne	.blkfll_clrinstd
		
		move.l	a2,a0
		move.w	#blkflg_Draw,d7
.trshexfall:
		move.w	(a1),d4
		or.w	d7,d4
		move.w	d4,(a2)
		move.w	d7,(a1)
		adda	#2,a2
		adda	#2,a1
		dbf	d1,.trshexfall
		move.l	a0,a2
		move.l	a0,a1
		suba	#MAX_BOXWIDTH,a1
		bset	#0,d0				; FLAG: Pause scroll
		bset	#bitPlySt_DrwAll,box_Status(a6)
		bra	.blkfll_resincrm
		
; clear fall bits instead
.blkfll_clrinstd:
		move.l	a1,a0
.trshidl_clrlp:
		move.w	(a0),d7
		bclr	#bitBlkFlg_Fall,d7
		move.w	d7,(a0)
		adda	#2,a0
		dbf	d1,.trshidl_clrlp
.blkfll_resincrm:
		clr.w	d1
		bclr	#1,d0
		bclr	#2,d0				; TODO: QUITAR si sale algo mal
.blkfll_trshincr:
		add.w	#1,d1				; Incrmt fall lenght
		bra	.blkfll_next
		
	; normal fall
.blkfll_normlblock:
		move.w	d3,d4				; move TOP block to BOT
		move.w	#blkflg_Draw,d7			; TODO: checarlo si sale algo mal
		or.w	d7,d4				; Set Draw flag on TOP
		bset	#bitBlkFlg_Fall,d4		; set as falling

.blkfll_fromtrsh:
		move.w	d4,(a2)
		move.w	d7,(a1)
		bset	#0,d0				; FLAG: Pause scroll
		bset	#bitPlySt_DrwAll,box_Status(a6)
		bra	.blkfll_next

	; --------------------------------------
	; BOT != $0000
	; BOT != $0040 (zero + fallbit)
	; BOT != BLKDEL_TIMEOUT
	; --------------------------------------
.blkfll_botactv:
		swap	d0
		clr.w	d0
		swap	d0

	; Check for block matches
		move.w	d4,d7
		move.w	d4,d5
		and.w	#$7F00,d7
		bne	.blkfll_cntup
		btst	#bitBlkFlg_Match,d4
		beq	.blkfll_notimer
		and.w	#$1F,d5
		cmp.w	#SET_STRTTRSHIDS,d5
		bge.s	.blkfll_skipscore
		add.w	#1,box_NumMtchAdd(a6)
		movem.l	d0-d1,-(sp)
		move.l	box_UserScore(a6),d0
		move.l	#$10,d1			; Points per block
		tst.w	box_ComboCount(a6)
		beq.s	.blkfllsc_noex
		add.l	#$80,d1
.blkfllsc_noex:
		bsr	PzlGame_BcdScore_Add
		move.l	d0,box_UserScore(a6)
		movem.l	(sp)+,d0-d1
.blkfll_skipscore:
		and.w	#$001F,d4
		move.w	d3,d7
		and.w	#$1F,d7
		cmp.w	#SET_STRTTRSHIDS,d7
		blt.s	.blkfll_cntup
		bset	#2,d0
		move.w	d4,d7
		cmp.w	#SET_STRTTRSHIDS,d7
		blt.s	.blkfll_cntup
		sub.w	#SET_STRTTRSHIDS,d7
		and.w	#%111,d7
		cmp.w	#2,d7
		beq.s	.blkfll_mrgeskip
		tst.w	d7
		bne.s	.blkfll_cntup
.blkfll_mrgeskip:
		bclr	#2,d0
.blkfll_cntup:
		move.w	d4,d7
		move.w	d4,d5
		and.w	#$1F,d7
		and.w	#$7F00,d5
		
		cmp.w	#SET_STRTTRSHIDS,d7
		blt.s	.blkfll_nrmlincrm
		cmp.w	#BLKDEL_MIDANIM,d5
		blt.s	.blkfll_nrmlincrm
		btst	#bitBlkFlg_Match,d4			; BIT alternate mode
		bne.s	.blkfll_exroll
		and.w	#$1F,d4
		or.w	#blkflg_Draw,d4
		move.w	d4,(a2)
		bra.s	.blkfll_notimer
.blkfll_exroll:
		bsr	.blkfll_guessblk
		rol.l	#2,d2
		move.w	d3,d7
		and.w	#$1F,d7
		cmp.w	#SET_STRTTRSHIDS,d7
		blt.s	.blkfll_dontrestr
		move.w	d7,d5
		sub.w	#SET_STRTTRSHIDS,d5
		and.w	#%11,d5
		sub.w	#2,d7
		or.w	#blkflg_Draw,d7
		move.w	d7,(a1)
.blkfll_dontrestr:
		bset	#bitPlySt_DrwAll,box_Status(a6)	
		bra.s	.blkfll_notimer

; Normal increment + rolltimer check
.blkfll_nrmlincrm:
		cmp.w	#BLKROLL_FALL,d5
		bge.s	.blkfll_notimer
		add.w	#$100,d4
.blkfll_setnow:
		or.w	#blkflg_Draw,d4
		move.w	d4,(a2)
		bset	#bitPlySt_DrwAll,box_Status(a6)
.blkfll_notimer:

		move.w	d3,d7
		and.w	#$1F,d7
		cmp.w	#SET_STRTTRSHIDS,d7
		blt	.blkfll_next3
		sub.w	#SET_STRTTRSHIDS,d7
		and.w	#%11,d7
		cmp.w	#2,d7
		beq.s	.blkfll_next3
		bset	#5,d0
.blkfll_next3:
		move.w	d3,d7					; TOP has timers?
		and.w	#$7F00,d7
		bne	.blkfll_trshcntfall
		
		btst	#bitBlkFlg_Fall,d4			; BOT is falling?
		bne	.blkfll_settopfll
		btst	#bitBlkFlg_Fall,d3			; TOP is falling?
		beq	.blkfll_break
		move.w	d3,d7
		and.w	#$1F,d7
		beq	.blkfll_trshcntfall
		cmp.w	#SET_STRTTRSHIDS,d7
		blt.s	.blkfll_notrshshk
		btst	#3,d0
		bne.s	.blkfll_notrshshk
		move.w	#$100,box_YShake(a6)
		bset	#3,d0					; TRSHSHAKE
		move.w	#2,(RAM_PGame_Sound).w			; SFX: heavy fall

.blkfll_notrshshk:
		and.w	#$001F|$0020,d3				; Allow ID + Chain bit
		move.w	d3,(a1)
		bset	#bitPlySt_ChkMatch,box_Status(a6)
		bset	#0,d0					; FLAG: Pause scroll
		
	; SFX normal punch
		btst	#3,d0
		bne.s	.blkfll_trshcntfall
		move.w	#1,(RAM_PGame_Sound).w			; SFX: normal fall
		bra.s	.blkfll_trshcntfall

.blkfll_guessblk:
		move.l	d2,d4		
		movem.l	d0/d3-d4,-(sp)
		swap	d1
.blkfll_reroll:
		bsr	box_GuessBlk
		cmp.w	box_UserMaxIds(a6),d0
		bgt.s	.blkfll_reroll
		cmp.w	d1,d0
		beq.s	.blkfll_reroll
; 		cmp.w	d5,d0
; 		beq.s	.blkfll_reroll
		move.w	d0,d1
		or.w	#blkflg_Draw|BLKROLL_STAY,d0
		move.w	d0,(a2)
		swap	d1
		movem.l	(sp)+,d0/d3-d4
		rts

; break chain
.blkfll_break:
		bclr	#bitBlkFlg_Chain,d3		; Break chain
		move.w	d3,(a1)
.blkfll_trshcntfall:
		move.w	d3,d7
		move.w	d3,d5
		and.w	#$7F00,d5
		cmp.w	#BLKROLL_FALL,d5
		bne.s	.blkfll_nottrsh
		and.w	#$1F,d3
		or.w	#blkflg_Draw,d3
		move.w	d3,(a1)
		bra	.blkfll_next
.blkfll_nottrsh:
		and.w	#$1F,d7
		cmp.w	#SET_STRTTRSHIDS,d7
		blt	.blkfll_next
.blkfll_canchk:
		cmp.w	#BLKDEL_MIDANIM,d5
		blt.s	.blkfll_noguess
		sub.w	#SET_STRTTRSHIDS,d7
		and.w	#%11,d7
		beq.s	.blkfll_canset
		cmp.w	#%01,d7
		bne.s	.blkfll_next
.blkfll_canset:
		bset	#bitBlkFlg_Match,d3
		move.w	d3,(a1)
		bra	.blkfll_next

.blkfll_noguess:
		sub.w	#SET_STRTTRSHIDS,d7
		btst	#3,d7
		bne.s	.blkfll_trshmid		; MID
		btst	#2,d7
		bne.s	.blkfll_trshcnttr	; TR
		move.l	a1,a0
		clr.w	d5
		btst	#2,d0
		beq.s	.blkfll_cpymtch		; TRSHMTCH enabled?
		bset	#bitBlkFlg_Match,d5
.blkfll_cpymtch:
		move.w	(a0),d7
		and.w	#$FF1F,d7
		or.w	d5,d7
		move.w	d7,(a0)
		adda	#2,a0
		dbf	d1,.blkfll_cpymtch
		bclr	#2,d0			; TRSHMTCH reset
.blkfll_trshcnttr:
		clr.w	d1
.blkfll_trshmid:
		add.w	#1,d1
		bset	#1,d0			; TRSHSTOP flag
.blkfll_mtchexit:
		bra.s	.blkfll_next

; Chainfall columns
.blkfll_settopfll:
		bclr	#bitBlkFlg_Fall,d3
		move.w	d3,d7
		and.w	#$1F,d7
		beq.s	.blkfll_mrgefall
		and.w	#$1F,d4
		cmp.w	#SET_STRTTRSHIDS,d4
		bge.s	.blkfll_forcefall
		cmp.w	#SET_STRTTRSHIDS,d7
		bge.s	.blkfll_mrgefall
.blkfll_forcefall:
		bset	#bitBlkFlg_Fall,d3
.blkfll_mrgefall:
		move.w	d3,(a1)

.blkfll_next:
		suba	#2,a2
		suba	#2,a1
		dbf	d6,.blkfll_clmn
		suba	#MAX_BOXWIDTH,a4
		suba	#MAX_BOXWIDTH,a3
		swap	d5
		swap	d6
		tst.w	d6
		bne.s	.blkfll_finish
		btst	#5,d0
		beq	.blkfll_finish
		add.w	#1,d6
.blkfll_finish:		
		dbf	d6,.blkfll_row

	; Punishes for 4+ blocks
	; Speedup and/or TrashFall
		tst.w	box_NumMtchAdd(a6)	; Add NEW matching blocks
		beq.s	.blkfll_exadd
		move.w	box_NumMtchAdd(a6),d4
		cmp.w	#SET_MAXBLKMTCH,d4
		ble.s	.mtch_trshadd
		btst	#bitMtch_ComboSpdUp,(RAM_Glbl_GameMtchFlags).w
		beq.s	.mtch_trshspdup
		moveq	#0,d5
		move.w	box_NumMtchAdd(a6),d5
		lsl.l	#4,d5
		add.l	d5,box_YSpd(a6)
.mtch_trshspdup:
		btst	#bitMtch_TrashEnbl,(RAM_Glbl_GameMtchFlags).w
		beq	.mtch_trshadd
		movem.l	d0-d4,-(sp)
		move.l	d2,d4				; Random seed
		move.w	box_NumMtchAdd(a6),d7
		sub.w	#SET_MAXBLKMTCH,d7
		move.w	box_Width(a6),d5
		cmp.w	d5,d7
		blt.s	.mtchtrsh_roll
		clr.w	d0
		move.w	d5,d1
		sub.w	#1,d1
		bra.s	.mtchtrsh_full
.mtchtrsh_roll:	
		bsr	box_GuessBlk
		rol.l	#5,d4
		ror.w	#3,d4
		sub.w	#1,d0
		bmi.s	.mtchtrsh_roll
		cmp.w	d5,d0
		bge.s	.mtchtrsh_roll
		move.w	d0,d1
		add.w	d7,d1
		cmp.w	d5,d1
		bge.s	.mtchtrsh_roll
.mtchtrsh_full:
		move.w	d0,box_TrshSmlReq(a6)
		move.w	d1,box_TrshSmlReq+2(a6)
		movem.l	(sp)+,d0-d4
.mtch_trshadd:
		move.w	d4,box_NumMtchLast(a6)
		add.w	d4,box_NumMtchBlk(a6)
		clr.w	box_NumMtchAdd(a6)

.blkfll_exadd:

	; --------------------------------------
	; Scroll
	; --------------------------------------
		
		movea.l	box_BlockData(a6),a5
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a5
		bsr	box_CheckLine				; Get boxfull flag (returns d3)
		btst	#0,d0					; Pause request from Blockfalling section?
		bne	.upd_vscrl
		tst.w	box_NumMtchBlk(a6)			; Block matches != 0?
		bne	.upd_vscrl
	; Box timeout
		tst.w	d3					; Boxfull flag?
		beq	.incrmt_tout
		and.l	#$FFF00000,d4
		move.l	box_YSpd(a6),d4
		add.l	d4,box_BoardTimeOut(a6)
		cmp.w	#$10,box_BoardTimeOut(a6)		; MAX time for full box
		blt.s	.count_tmout
.force_gameover:
		move.w	#$200,box_YShake(a6)
		
		bset	#bitMtch_MatchOver,(RAM_Glbl_GameMtchFlags).w
		bset	#bitPlySt_GameOver,box_Status(a6)
		bset	#bitPlySt_DrwAll,box_Status(a6)

		move.w	#3,(RAM_PGame_Sound).w			; SFX: box full
; 		movem.l	d0-d4,-(sp)
; 		move.l	#(SfxData_Blk<<16)|SfxData_Pat,d0
; 		move.l	#($0000<<16)|SfxData_Ins,d1
; 		move.l	#$00020002,d2
; 		moveq	#0,d3
; 		bsr	Sound_SetTrack
; 		movem.l	(sp)+,d0-d4
		
	; *** TEMPORAL, FOR THE DEMO ****

; 		sub.w	#1,(RAM_PGame_PlyrsOn).w
; 		bne.s	.count_tmout
; 		clr.w	(RAM_PGame_PlyrsOn).w
		bra.s	.count_tmout
.incrmt_tout:
		tst.w	box_BoardTimeOut(a6)
		beq.s	.count_tmout
		clr.w	box_BoardTimeOut(a6)
.count_tmout:
		tst.w	box_YShake(a6)
		bne	.upd_vscrl
		move.l	box_YScrl(a6),d4		; YScrl + YSpd
		move.l	d4,d5
		and.l	#$FFF00000,d4
		tst.w	d3
		bne	.keep_rise2
.keep_rise3:
		move.l	box_YSpd(a6),d3
		bclr	#bitPlySt_SpdUp,box_Status(a6)
		beq.s	.keep_rise2
		lsl.l	#4,d3
.keep_rise2:
		add.l	d3,d5
		move.l	d5,d4
.keep_rise:

	; TRASH request checks
		btst	#bitMtch_TrashEnbl,(RAM_Glbl_GameMtchFlags).w
		beq.s	.no_combochng
		bclr	#1,box_TrshReq(a6)
		beq.s	.no_smltrsh
		tst.l	box_TrshSmlReq(a6)
		beq.s	.no_smltrsh
		movem.l	a1-a3/d0-d6,-(sp)
		move.w	box_TrshSmlReq(a6),d0
		move.w	box_TrshSmlReq+2(a6),d1
		move.w	#0,d2
		bsr	box_SendTrash
		clr.l	box_TrshSmlReq(a6)
		movem.l	(sp)+,a1-a3/d0-d6
.no_smltrsh:
		bclr	#0,box_TrshReq(a6)
		beq.s	.no_combochng
		move.w	box_ComboCount(a6),d2
		sub.w	#1,d2
		bmi.s	.no_combochng
		move.w	#0,d0			; X start
		move.w	box_Width(a6),d1	; X end
		sub.w	#1,d1
		movem.l	d4-d5,-(sp)
		bsr	box_SendTrash
		movem.l	(sp)+,d4-d5
		bra.s	.alrdyclr
.no_combochng:
		tst.w	box_ComboCount(a6)
		beq.s	.alrdyclr
		btst	#bitMtch_ComboSpdUp,(RAM_Glbl_GameMtchFlags).w
		beq.s	.no_combospdup
		moveq	#0,d5
		move.w	box_ComboCount(a6),d5
		lsl.l	#8,d5
		lsl.l	#1,d5
		add.l	d5,box_YSpd(a6)
.no_combospdup:
		bset	#0,box_TrshReq(a6)
		
.alrdyclr:
		clr.w	box_ComboCntShow(a6)
		clr.w	box_ComboCount(a6)
		
	; Yscroll set
		move.l	d4,box_YScrl(a6)
		and.l	#$FFF00000,d4			; Check for new row
		cmp.l	box_YScrl_old(a6),d4
		beq	.upd_vscrl
		move.l	d4,box_YScrl_old(a6)

	; --------------------------------------
	; Make NEW blocks from bottom
	; --------------------------------------	
		move.w	box_Width(a6),d6		; Move UP blocks
		sub.w	#1,d6
		bmi.s	.ranout_wdth
		movea.l	box_BlockData(a6),a5
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a5
		move.w	box_Width(a6),d5
		add.w	d5,d5
		adda	d5,a5
		move.l	a5,a4
		adda	#MAX_BOXWIDTH,a4
		move.w	box_Height(a6),d6
		sub.w	#1,d6
.nxt_clmn:
		move.l	a5,a3
		move.l	a4,a2
		move.w	box_Width(a6),d5
		sub.w	#1,d5
.mv_blk:
		move.w	-(a2),-(a3)
		dbf	d5,.mv_blk
		adda	#MAX_BOXWIDTH,a5
		adda	#MAX_BOXWIDTH,a4
		dbf	d6,.nxt_clmn
.ranout_wdth:
		move.l	a3,a2
		suba	#MAX_BOXWIDTH,a2
		move.w	box_Width(a6),d6
		sub.w	#1,d6
		moveq	#0,d5
		move.l	d2,d4				; d2 - BASE random value
.mk_rndm:
		bsr	box_GuessBlk
		cmp.w	(a2),d0
		beq.s	.mk_rndm
		cmp.b	d5,d0
		beq.s	.mk_rndm
		cmp.w	box_UserMaxIds(a6),d0		; MAX usable blocks (dificulty)
		bgt.s	.mk_rndm
.mk_allow:
		move.b	d0,d5
		move.w	d0,(a3)+
		adda	#2,a2
		dbf	d6,.mk_rndm

		bset	#bitPlySt_DrwLine,box_Status(a6)
		bset	#bitPlySt_ChkMatch,box_Status(a6)
; 		sub.w	#1,box_BlkBombBotCntr(a6)
; 		bpl.s	.upd_vscrl
; 		move.w	box_BlkBombBotSet(a6),box_BlkBombBotCntr(a6)
		
	; --------------------------------------
	; Set VScroll values
	; --------------------------------------
.upd_vscrl:
		lea	(RAM_PGame_YScrl_Main),a5
		cmp.w	#15,box_BoardY(a6)
		blt.s	.toplwr
		lea	(RAM_PGame_Yscrl_Sub),a5
.toplwr:
		move.w	box_YScrl(a6),d4
		btst	#1,box_FrameTimer+1(a6)
		beq.s	.dontshake
		move.w	box_YShake(a6),d5
		beq.s	.dontshake
		lsr.w	#6,d5
		add.w	d5,d4
		sub.w	#$10,box_YShake(a6)
.dontshake:
		move.w	box_BoardX(a6),d5
		lsl.w	#2,d5
		adda 	d5,a5
		move.w	box_Width(a6),d5
		sub.w	#1,d5
		bmi.s	.badv
.vloop:
		move.w	d4,(a5)
		adda	#4,a5
		dbf	d5,.vloop
.badv:
		add.w	#1,box_FrameTimer(a6)

	; --------------------------------------
	; Current player status
	; --------------------------------------
		btst	#bitPlySt_GameOver,box_Status(a5)
		bne	.no_plyr
		move.l	box_UserTime(a6),d4
 		cmp.l	#$999900,d4
 		beq.s	.nel2t
		move.l	#1,d5
 		abcd	d5,d4
		cmp.b	#$60,d4
		blt.s	.nel2t
		clr.b	d4
		ror.l	#8,d4
 		abcd	d5,d4
		cmp.b	#$60,d4
 		blt.s	.nel3t
		clr.b	d4
 		ror.l	#8,d4		
 		abcd	d5,d4
		cmp.b	#$60,d4
 		blt.s	.nel4t
 		move.l	#$999900,d4
 		bra.s	.nel2t
.nel4t:
 		rol.l	#8,d4
.nel3t:
 		rol.l	#8,d4
.nel2t:
		move.l	d4,box_UserTime(a6)
		
	; --------------------------------------

.no_plyr:
		asl.l	#3,d2
		ror.w	#4,d2
		adda 	#sizeof_Box,a6
		swap	d7
		dbf	d7,.this_plyr
.box_paused:

		move.w	(RAM_PGame_Sound).w,d2
		beq.s	.no_sound
		sub.w	#1,d2
		swap	d2
		move.l	#(SfxData_Blk<<16)|SfxData_Pat,d0
		move.l	#($0000<<16)|SfxData_Ins,d1
		move.w	#$0002,d2
		moveq	#0,d3
		bsr	Sound_SetTrack
		clr.w	(RAM_PGame_Sound).w
.no_sound:
		rts

; --------------------------------------------------------
; Player inputs and Trash events
; --------------------------------------------------------

PzlGame_PlayerInputs:
		btst	#bitMtch_Pause,(RAM_Glbl_GameMtchFlags).w
		bne.s	.tmroff
		sub.w	#1,(RAM_PGame_CursorTimer).w
		bpl.s	.tmroff
		move.w	#$10,(RAM_PGame_CursorTimer).w		; MAX TIMER for cursor animation
		move.w	(RAM_PGame_CursorFrame).w,d4
		add.w	#1,d4
		and.w	#1,d4
		move.w	d4,(RAM_PGame_CursorFrame).w
.tmroff:

		lea	(RAM_Glbl_PzlCursors),a6
		move.w	#MAX_BOXES-1,d7
.this_plyr:
		swap	d7
		btst	#bitCurSt_Active,cursor_Status(a6)
		beq	.box_off
		btst	#bitCurSt_MidSwapLock,cursor_Status(a6)
		bne	.box_off

	; User input
		movea.l	cursor_Box(a6),a5
		movea.l	cursor_Control(a6),a4
	
; 	; Pause menu
; 		move.w	on_hold(a4),d6
; 		and.w	#JoyStart+JoyA+JoyB+JoyC,d6
; 		cmp.w	#JoyStart+JoyA+JoyB+JoyC,d6
; 		bne.s	.not_out
; 		moveq	#0,d0
; 		move.w	#64,d1
; 		move.w	#4,d2
; 		bsr	Video_PalFade_Out
; 		bra	TitleScreen_Init
; .not_out:

		btst	#bitMtch_MatchOver,(RAM_Glbl_GameMtchFlags).w
		beq	.normal_pause
		move.w	on_press(a4),d6
		move.w	d6,d5
		and.w	#JoyB,d6
		bne	.return_menu
		and.w	#JoyC,d5
		bne	.restart_game
		bra	.box_off
.normal_pause:
		move.w	on_press(a4),d6
		cmp.w	#JoyStart,d6
		bne.s	.not_out2
		btst	#bitPlySt_GameOver,box_Status(a5)
		bne	.return_menu
		bchg	#bitMtch_Pause,(RAM_Glbl_GameMtchFlags).w
		beq.s	.not_out2
		move.w	on_hold(a4),d6
		move.w	d6,d5
		and.w	#JoyA+JoyB+JoyC,d6
		bne	.return_menu
.not_out2:
		btst	#bitMtch_Pause,(RAM_Glbl_GameMtchFlags).w
		bne	.box_off

		btst	#bitCurSt_Active,box_Status(a5)
		beq	.box_off
; 		btst	#bitPlySt_Pause,box_Status(a5)		; leftover
; 		bne	.box_off
		btst	#bitPlySt_GameOver,box_Status(a5)
		bne	.box_off

	; OLD AUTODETECTION, SET THIS MANUALLY
; 		moveq	#0,d4
; 		move.b	pad_ver(a4),d4
; 		move.w	d4,cursor_Type(a6)
; 		cmp.w	cursor_TypeOld(a6),d4
; 		beq.s	.no_lrge	
; 		tst.w	d4
; 		beq.s	.no_lrge
; 		move.w	cursor_Y(a6),d5
; 		move.w	box_Height(a5),d6
; 		sub.w	#1,d6
; 		cmp.w	d6,d5
; 		blt.s	.no_lrge
; 		sub.w	#1,cursor_Y(a6)
; 		move.w	cursor_Type(a6),cursor_TypeOld(a6)
; .no_lrge:

		move.w	cursor_SpdUpTmr(a6),d5
		move.w	on_press(a4),d6
		clr.w	d4
		move.w	on_hold(a4),d2
		beq.s	.press_once
		add.w	#1,d5
		cmp.w	#$10,d5
		blt.s	.keep_count
		move.w	#$10,d5
		move.w	d2,d6
.keep_count:
		move.w	d5,d4
.press_once:
		move.w	d4,cursor_SpdUpTmr(a6)

		move.w	#0,d3
		move.w	d6,d0
		and.w	#JoyRight,d0
		beq.s	.not_right
		move.w	box_Width(a5),d5
		sub.w	#3,d5
		move.w	cursor_X(a6),d4
		cmp.w	d5,d4
		bge.s	.not_right
		add.w	#1,cursor_X(a6)
		clr.w	cursor_SwapMode(a6)
		move.w	#1,d3
		move.w	#1,d3
.not_right:
		move.w	d6,d0
		and.w	#JoyLeft,d0
		beq.s	.not_left
		tst.w	cursor_X(a6)
		beq.s	.not_left
		sub.w	#1,cursor_X(a6)
		clr.w	cursor_SwapMode(a6)
		move.w	#1,d3
.not_left:
		move.w	d6,d0
		and.w	#JoyDown,d0
		beq.s	.not_down
		move.w	box_Height(a5),d5
		sub.w	#1+1,d5
		tst.w	cursor_Type(a6)
		beq.s	.type3
		sub.w	#1,d5
		move.w	#1,d3
.type3:
		move.w	cursor_Y(a6),d4
		cmp.w	d5,d4
		bge.s	.not_down
		add.w	#1,cursor_Y(a6)
		clr.w	cursor_SwapMode(a6)
		move.w	#1,d3
.not_down:
		move.w	d6,d0
		and.w	#JoyUp,d0
		beq.s	.not_up
		tst.w	cursor_Y(a6)
		beq.s	.not_up
		sub.w	#1,cursor_Y(a6)
		clr.w	cursor_SwapMode(a6)
		move.w	#1,d3
.not_up:

		tst.w	d3
		beq.s	.nah
; 		tst.w	box_TrshReq(a5)
; 		bne.s	.nah
		move.w	#4,(RAM_PGame_Sound).w
; 		movem.l	d0-d4/a4,-(sp)
; 		move.l	#(SfxData_Blk<<16)|SfxData_Pat,d0
; 		move.l	#($0000<<16)|SfxData_Ins,d1
; 		move.l	#$00030001,d2
; 		moveq	#0,d3
; 		bsr	Sound_SetTrack
; 		movem.l	(sp)+,d0-d4/a4
.nah:

; ----------------------------------------
; ABCXYZ mechanics
; ----------------------------------------

; 		tst.w	(RAM_Glbl_GameMtchFlags).w
; 		bne	.no_spdup
		tst.w	cursor_SwapMode(a6)
		beq.s	.no_prelock
		btst	#bitPlySt_ChkMatch,box_Status(a5)
		bne	.box_off
		move.w	cursor_SwapSrcPos+2(a6),d5
		move.w	cursor_SwapSrcPos(a6),d4
		add.w	d4,d4
		lsl.w	#5,d5
		add.w	d5,d4
		movea.l	box_BlockData(a5),a3
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a3
		adda	d4,a3
		move.w	(a3),d4
		cmp.w	cursor_SwapSrcId(a6),d4
		beq.s	.no_prelock
		move.w	d4,d5
		and.w	#$7FC0,d5
		bne.s	.clr_zero
		tst.b	d4
		beq.s	.clr_zero
		btst	#bitBlkFlg_Fall,d4
		beq.s	.no_fallpr
.clr_zero:
		clr.w	cursor_SwapMode(a6)
.no_fallpr:
		move.w	d4,cursor_SwapSrcId(a6)
.no_prelock:
		move.w	on_press(a4),d6
		bsr	.chktrggr_pos
		beq.s	.no_pick
		bsr	.pick_block
.no_pick:
		
; ----------------------------------------
; Speed up board using free space
; ----------------------------------------

		movea.l	cursor_Control(a6),a4
		move.w	on_hold(a4),d6
		move.w	d6,d5
		move.w	#JoyA+JoyB+JoyC,d2
		tst.w	cursor_Type(a6)
		beq.s	.oldtrggr
		move.w	#JoyX+JoyY+JoyZ,d2
.oldtrggr:
		and.w	d2,d5
		beq.s	.lastchk
		move.w	cursor_Y(a6),d5
		move.w	cursor_X(a6),d4
		add.w	d4,d4
		lsl.w	#5,d5
		add.w	d5,d4
		movea.l	box_BlockData(a5),a1
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a1
		adda	d4,a1
		move.w	(a1)+,d4
		tst.b	d4
		bne	.no_spdup
		move.w	(a1)+,d4
		tst.b	d4
		bne	.no_spdup		
		move.w	(a1)+,d4
		tst.b	d4
		bne	.no_spdup
		bra.s	.type0_spdup
.lastchk:
		tst.w	cursor_Type(a6)
		beq.s	.no_spdup
		move.w	d6,d5
		and.w	#JoyA+JoyB+JoyC,d5
		beq	.no_spdup
		move.w	cursor_Y(a6),d5
		move.w	cursor_X(a6),d4
		add.w	#1,d5
		add.w	d4,d4
		lsl.w	#5,d5
		add.w	d5,d4
		movea.l	box_BlockData(a5),a1
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a1
		adda	d4,a1
		move.w	(a1)+,d4
		tst.b	d4
		bne	.no_spdup
		move.w	(a1)+,d4
		tst.b	d4
		bne	.no_spdup
		move.w	(a1)+,d4
		tst.b	d4
		bne	.no_spdup
.type0_spdup:
		bset	#bitPlySt_SpdUp,box_Status(a5)
.no_spdup:

; ----------------------------------------

.box_off:
		adda	#sizeof_Cursor,a6
		swap	d7
		dbf	d7,.this_plyr
.no_res:
		rts

; ----------------------------------------

.restart_game:
		moveq	#0,d0
		move.w	#64,d1
		move.w	#$80,d2
		bsr	Video_PalFade_Out
		bclr	#bitMtch_MatchOver,(RAM_Glbl_GameMtchFlags).w
		bclr	#bitMtch_Timeout,(RAM_Glbl_GameMtchFlags).w
		clr.l	(RAM_PGame_GlblTimer).w
		bra	MainGame_Init
		
.return_menu:
		moveq	#0,d0
		move.w	#64,d1
		move.w	#4,d2
		bsr	Video_PalFade_Out
		bra	TitleScreen_Init
		
; ----------------------------------------

.chktrggr_pos:
	; X Y Z check
		clr.w	d5
		moveq	#0,d1
		moveq	#0,d2
		tst.w	cursor_Type(a6)
		beq.s	.abconly
.type0:
		move.w	d6,d0
		and.w	#JoyX,d0
		beq.s	.not_x
		move.w	#1,d5
		moveq	#0,d1
		bra.s	.not_c
.not_x:
		move.w	d6,d0
		and.w	#JoyY,d0
		beq.s	.not_y
		move.w	#1,d5
		moveq	#1,d1
		bra.s	.not_c
.not_y:
		move.w	d6,d0
		and.w	#JoyZ,d0
		beq.s	.not_z
		move.w	#1,d5
		moveq	#2,d1
		bra.s	.not_c
.not_z:
		add.w	#1,d2

.abconly:
	; A B C check
		move.w	on_press(a4),d6
		move.w	d6,d0
		and.w	#JoyA,d0
		beq.s	.not_a
		moveq	#1,d5
		moveq	#0,d1
.not_a:
		move.w	d6,d0
		and.w	#JoyB,d0
		beq.s	.not_b
		moveq	#1,d5
		moveq	#1,d1
.not_b:
		move.w	d6,d0
		and.w	#JoyC,d0
		beq.s	.not_c
		moveq	#1,d5
		moveq	#2,d1
.not_c:
		tst.w	d5
		rts
		
; ----------------------------------------
; Pick / Swap block
; 
; d1 - X pos
; d2 - Y pos
; ----------------------------------------

.pick_block:
		btst	#bitCurSt_MidSwapLock,cursor_Status(a6)
		bne	.ignore
		tst.w	cursor_SwapMode(a6)
		bne	.mode_1
.mode_0:
		move.w	cursor_X(a6),d4
		add.w	d1,d4
		add.w	d4,d4
		move.w	cursor_Y(a6),d5
		add.w	d2,d5
		lsl.w	#5,d5
		add.w	d5,d4
		movea.l	box_BlockData(a5),a1
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a1
		adda	d4,a1
		move.w	(a1),d4
		beq	.ignore
		move.w	d4,d5
		and.w	#%11100000,d5
		bne	.ignore
		move.w	d4,d5
		and.w	#$7F00,d5
		bne	.ignore
		cmp.w	#SET_STRTTRSHIDS,d4
		bge	.ignore

		add.w	#1,cursor_SwapMode(a6)
		move.w	d4,cursor_SwapSrcId(a6)
		move.w	cursor_X(a6),d4
		add.w	d1,d4
		move.w	d4,cursor_SwapSrcPos(a6)
		add.w	box_BoardX(a5),d4
		lsl.w	#4,d4
		move.w	d4,cursor_SwapSrcSpr(a6)
		move.w	d4,cursor_SwapSrcShdw(a6)
		move.w	cursor_Y(a6),d4
		add.w	d2,d4
		move.w	d4,cursor_SwapSrcPos+2(a6)
		add.w	box_BoardY(a5),d4
		lsl.w	#4,d4
		move.w	d4,cursor_SwapSrcSpr+4(a6)
		move.w	d4,cursor_SwapSrcShdw+2(a6)
		rts

; Grab DST
.mode_1:
		move.l	cursor_SwapSrcPos(a6),d5
		move.w	cursor_X(a6),d4
		add.w	d1,d4
		swap	d4
		move.w	cursor_Y(a6),d4
		add.w	d2,d4
		cmp.l	d5,d4
		bne.s	.new_block
		clr.w	cursor_SwapMode(a6)
		rts
		
; Set DESTINATION and swap blocks
; TODO: SRC check if the block changed
.new_block:
		move.w	cursor_X(a6),d4
		add.w	d1,d4
		add.w	d4,d4
		move.w	cursor_Y(a6),d5
		add.w	d2,d5
; 		tst.w	cursor_Type(a6)
; 		beq.s	.normlcurs
; 		tst.w	d5
; 		beq.s	.ignore
; .normlcurs:
		lsl.w	#5,d5
		add.w	d5,d4
		movea.l	box_BlockData(a5),a1
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a1
		adda	d4,a1
		
		move.w	(a1),d4
		move.w	d4,d5
; 		and.w	#BLKDEL_MIDSWAP,d5
; 		cmp.w	#BLKDEL_MIDSWAP,d5
; 		bge.s	.allowit
		move.w	d4,d5
		and.w	#$7F00,d5
		bne	.ignore
		move.w	d4,d5
		and.w	#%11100000,d5
		bne	.ignore
		cmp.w	#SET_STRTTRSHIDS,d4
		bge.s	.ignore
.allowit:

		add.w	#1,cursor_SwapMode(a6)
; 		and.w	#%1111,d4
		move.w	d4,cursor_SwapDstId(a6)
		move.w	cursor_X(a6),d4
		add.w	d1,d4
		move.w	d4,cursor_SwapDstPos(a6)
		add.w	box_BoardX(a5),d4
		lsl.w	#4,d4
		move.w	d4,cursor_SwapDstSpr(a6)
		move.w	d4,cursor_SwapDstShdw(a6)
		move.w	cursor_Y(a6),d4
		add.w	d2,d4
		move.w	d4,cursor_SwapDstPos+2(a6)
		add.w	box_BoardY(a5),d4
		lsl.w	#4,d4
		move.w	d4,cursor_SwapDstSpr+4(a6)
		move.w	d4,cursor_SwapDstShdw+2(a6)
		rts
.ignore:
		rts

; --------------------------------------------------------
; Make SPRITES here before rendering them
; 
; d3 - Current LINK
; --------------------------------------------------------

PzlGame_MkSwapAndSpr:
		lea	(RAM_PGame_SpriteData),a4
		moveq	#1,d3

; ----------------------------------------

		lea	(RAM_Glbl_PzlCursors),a6
		move.w	#MAX_BOXES-1,d7
.next:
		btst	#bitCurSt_Active,cursor_Status(a6)
		beq	.no_box
		move.l	cursor_Box(a6),d0
		beq	.no_box
		movea.l	d0,a5
		btst	#bitPlySt_GameOver,box_Status(a5)
		bne	.no_box

		btst	#bitPlySt_DrwLine,box_Status(a5)
		beq.s	.dont_decr
		sub.l	#1,cursor_SwapSrcPos(a6)
		sub.l	#1,cursor_SwapDstPos(a6)
		sub.l	#$100000,cursor_SwapSrcSpr+4(a6)
		sub.l	#$100000,cursor_SwapDstSpr+4(a6)
		sub.w	#$10,cursor_SwapSrcShdw+2(a6)
		sub.w	#$10,cursor_SwapDstShdw+2(a6)
		tst.w	cursor_Y(a6)
		beq.s	.fix_cursor
		sub.w	#1,cursor_Y(a6)
		bra.s	.dont_decr
.fix_cursor:
		clr.w	cursor_SwapMode(a6)
.dont_decr:
		tst.w	cursor_SwapMode(a6)
		beq	.boxoff_blk
		move.w	cursor_SwapMode(a6),d6
		sub.w	#1,d6
		add.w	d6,d6
		lea	.swapmode_script(pc),a0
		move.w	(a0,d6.w),d6
		jsr	(a0,d6.w)
.boxoff_blk:

	; Make cursor
		move.w	box_BoardY(a5),d0
		add.w	cursor_Y(a6),d0
		lsl.w	#4,d0
		move.w	box_YScrl(a5),d5
		and.w	#$F,d5
		sub.w	d5,d0
		move.w	box_BoardX(a5),d1
		add.w	cursor_X(a6),d1
		lsl.w	#4,d1
		add.w	#$80-8,d0
		add.w	#$80-8,d1
		move.b	(RAM_VdpCache+$C).l,d5
		and.w	#%100,d5
		lsr.w	#1,d5
		move.w	cursor_Type(a6),d4
		and.w	#1,d4
		add.w	d5,d4
		add.w	d4,d4
		lea	.sprcursor_list(pc),a0
		move.w	(a0,d4.w),d4
		jsr	(a0,d4.w)
.no_box:

	; Shadow blocks
		tst.w	cursor_SwapMode(a6)
		beq	.boxoff_shd
		move.w	#VRAMSET_SPRSHDW,d2
		move.l	#$00000500,d6
		btst	#2,(RAM_VdpCache+$C).l
		beq.s	.norml
		lsr.w	#1,d2
		move.l	#$00800400,d6
.norml:
		or.w	#$6000|$8000,d2
		move.w	cursor_SwapSrcShdw(a6),d4
		move.w	cursor_SwapSrcShdw+2(a6),d5
		swap	d6
		move.w	#$80,d0
		add.w	d6,d0
		move.w	#$80,d1
		add.w	d4,d1
		add.w	d5,d0
		move.w	box_YScrl(a5),d5
		and.w	#$F,d5
		sub.w	d5,d0
		swap	d6
		move.w	d6,d4
		or.w	d3,d4
	; TODO: sprite oob check
		move.w	d0,(a4)+
		move.w	d4,(a4)+
		move.w	d2,(a4)+
		move.w	d1,(a4)+
		add.w	#1,d3
		cmp.w	#2,cursor_SwapMode(a6)
		ble.s	.boxoff_shd
		move.w	cursor_SwapDstShdw(a6),d4
		move.w	cursor_SwapDstShdw+2(a6),d5
		swap	d6
		move.w	#$80,d0
		add.w	d6,d0
		move.w	#$80,d1
		add.w	d4,d1
		add.w	d5,d0
		move.w	box_YScrl(a5),d5
		and.w	#$F,d5
		sub.w	d5,d0
		or.w	#$6000|$8000,d2
		swap	d6
		move.w	d6,d4
		or.w	d3,d4
	; TODO: sprite oob check
		move.w	d0,(a4)+
		move.w	d4,(a4)+
		move.w	d2,(a4)+
		move.w	d1,(a4)+
		add.w	#1,d3
.boxoff_shd:

		adda	#sizeof_Cursor,a6
		dbf	d7,.next
		
; ; ----------------------------------------
; ; Hide the broken 2cell
; ; ----------------------------------------
; 
; 		btst	#2,(RAM_VdpCache+$C).w
; 		bne.s	.hidedble
; 		move.w	#$80,d0
; 		move.w	#$80,d1
; 		move.w	#VRAMSET_CELLHIDE|$8000+$6000,d2
; 		move.w	#(224/32)-1,d5
; 		move.w	#$0700,d4
; 		or.w	d3,d4
; .nxtone:
; 	; TODO: sprite oob check
; 		move.w	d0,(a4)+
; 		move.w	d4,(a4)+
; 		move.w	d2,(a4)+
; 		move.w	d1,(a4)+
; 		add.w	#1,d3
; 		add.w	#1,d4
; 		add.w	#$20,d0
; 		dbf	d5,.nxtone
; 		bra.s	.hidecont
; .hidedble:
; 		move.w	#$100,d0
; 		move.w	#$80,d1
; 		move.w	#VRAMSET_CELLHIDE>>1|$8000+$6000,d2
; 		move.w	#(448/32)-1,d5
; 		move.w	#$0500,d4
; 		or.w	d3,d4
; .nxtone2:
; 	; TODO: sprite oob check
; 		move.w	d0,(a4)+
; 		move.w	d4,(a4)+
; 		move.w	d2,(a4)+
; 		move.w	d1,(a4)+
; 		add.w	#1,d3
; 		add.w	#1,d4
; 		add.w	#$20,d0
; 		dbf	d5,.nxtone2
; .hidecont:

; ----------------------------------------

		cmp.b	#70,d3
		bge.s	.finishspr
		move.l	#0,(a4)+
		move.l	#0,(a4)+
.finishspr:
		rts

; ------------------------------------------------
; Animation scripts for blocks on cursors
; ------------------------------------------------

.swapmode_script:
		dc.w	.script_1-.swapmode_script
		dc.w	.script_2-.swapmode_script
		dc.w	.script_3-.swapmode_script
		dc.w	.script_4-.swapmode_script
.script_1:
		move.w	cursor_SwapSrcId(a6),d2
		move.l	cursor_SwapSrcSpr(a6),d4
		move.l	cursor_SwapSrcSpr+4(a6),d5
		bra	.showblk_cursor
.script_2:
		move.l	cursor_SwapSrcSpr(a6),cursor_SwapSrcSprOld(a6)
		move.l	cursor_SwapSrcSpr+4(a6),cursor_SwapSrcSprOld+4(a6)
		move.l	cursor_SwapDstSpr(a6),cursor_SwapDstSprOld(a6)
		move.l	cursor_SwapDstSpr+4(a6),cursor_SwapDstSprOld+4(a6)

		move.w	#2,d5				; ASR this much
		move.l	cursor_SwapDstSpr(a6),d4	; X SRC spd calc
		sub.l	cursor_SwapSrcSpr(a6),d4
		asr.l	d5,d4
		move.l	d4,cursor_SwapSrcSprSpd(a6)
		move.l	cursor_SwapSrcSpr(a6),d4
		sub.l	cursor_SwapDstSpr(a6),d4
		asr.l	d5,d4
		move.l	d4,cursor_SwapDstSprSpd(a6)
		move.l	cursor_SwapDstSpr+4(a6),d4	; Y SRC spd calc
		sub.l	cursor_SwapSrcSpr+4(a6),d4
		asr.l	d5,d4
		move.l	d4,cursor_SwapSrcSprSpd+4(a6)
		move.l	cursor_SwapSrcSpr+4(a6),d4
		sub.l	cursor_SwapDstSpr+4(a6),d4
		asr.l	d5,d4
		move.l	d4,cursor_SwapDstSprSpd+4(a6)		
		add.w	#1,cursor_SwapMode(a6)
		bset	#bitCurSt_MidSwapLock,cursor_Status(a6)
		bset	#bitPlySt_MidSwapStop,box_Status(a5)

.script_3:
		move.w	cursor_SwapSrcId(a6),d2
		move.l	cursor_SwapSrcSpr(a6),d4
		move.l	cursor_SwapSrcSpr+4(a6),d5
		bsr	.showblk_cursor
		move.w	cursor_SwapDstId(a6),d2
		beq.s	.zerdest
		move.w	d2,d4
; 		and.w	#BLKDEL_MIDSWAP,d4
; 		cmp.w	#BLKDEL_MIDSWAP,d4
; 		bge.s	.zerdest
		move.l	cursor_SwapDstSpr(a6),d4
		move.l	cursor_SwapDstSpr+4(a6),d5
		bsr	.showblk_cursor
.zerdest:

		moveq	#0,d1
	; SRC X/Y
		move.l	cursor_SwapSrcSpr(a6),d2
		move.l	cursor_SwapSrcSprSpd(a6),d6
		move.l	cursor_SwapDstSprOld(a6),d4
		move.l	cursor_SwapSrcSpr(a6),d5
		bsr	.animate_coord
		move.l	d2,cursor_SwapSrcSpr(a6)
		move.l	cursor_SwapSrcSpr+4(a6),d2
		move.l	cursor_SwapSrcSprSpd+4(a6),d6
		move.l	cursor_SwapDstSprOld+4(a6),d4
		move.l	cursor_SwapSrcSpr+4(a6),d5
		bsr	.animate_coord
		move.l	d2,cursor_SwapSrcSpr+4(a6)
	; DST X/Y
		move.l	cursor_SwapDstSpr(a6),d2
		move.l	cursor_SwapDstSprSpd(a6),d6
		move.l	cursor_SwapSrcSprOld(a6),d4
		move.l	cursor_SwapDstSpr(a6),d5
		bsr	.animate_coord
		move.l	d2,cursor_SwapDstSpr(a6)
		move.l	cursor_SwapDstSpr+4(a6),d2
		move.l	cursor_SwapDstSprSpd+4(a6),d6
		move.l	cursor_SwapSrcSprOld+4(a6),d4
		move.l	cursor_SwapDstSpr+4(a6),d5
		bsr	.animate_coord
		move.l	d2,cursor_SwapDstSpr+4(a6)
		cmp.w	#4,d1
		blt.s	.boxoff_blk2
		add.w	#1,cursor_SwapMode(a6)
.boxoff_blk2:
		rts
		
.script_4:

		movea.l	box_BlockData(a5),a1
		adda	#MAX_BOXWIDTH*(MAX_BOXHEIGHT/2),a1
		movea.l	a1,a2
		move.w	cursor_SwapSrcPos(a6),d4
		add.w	d4,d4
		move.w	cursor_SwapSrcPos+2(a6),d5
		lsl.w	#5,d5
		add.w	d5,d4
		adda	d4,a1
		move.w	cursor_SwapDstPos(a6),d4
		add.w	d4,d4
		move.w	cursor_SwapDstPos+2(a6),d5
		lsl.w	#5,d5
		add.w	d5,d4
		adda	d4,a2
	; a1 - src
	; a2 - dest 
		move.w	(a1),d0
		move.w	(a2),d1
; 		move.w	d1,d4
; 		and.w	#$7F00,d4
; 		cmp.w	#BLKDEL_MIDSWAP,d4
; 		blt.s	.dstismtch
; 		clr.w	d1
; 		sub.w	#1,box_NumMtchBlk(a5)
; 		bpl.s	.dstismtch
; 		bra.s	*				; TODO: SI LLEGO AQUI algo esta mal
; 		clr.w	box_NumMtchBlk(a5)
; .dstismtch:
		and.w	#$1F,d0
		and.w	#$1F,d1
; 		bset	#bitBlkFlg_Fall,d1
; 		bset	#bitBlkFlg_Fall,d0
		or.w	#blkflg_Draw,d0
		or.w	#blkflg_Draw,d1
		move.w	d0,(a2)
		move.w	d1,(a1)
		move.w	#0,cursor_SwapSrcId(a6)
		move.w	#0,cursor_SwapDstId(a6)
		bset	#bitPlySt_DrwAll,box_Status(a5)
		bset	#bitPlySt_ChkMatch,box_Status(a5)
		bclr	#bitPlySt_MidSwapStop,box_Status(a5)
		bclr	#bitCurSt_MidSwapLock,cursor_Status(a6)
		clr.w	cursor_SwapMode(a6)
		rts

; ------------------------------------------------
; Animate points
; d1 - fini
; d2 - base
; d4 - X or Y start
; d5 - X or Y target
; d6 - X or Y speed
; ------------------------------------------------

.animate_coord:
		tst.l	d6
		bmi.s	.srcxmvleft
		cmp.l	d4,d5
		bge.s	.srcxlowr
		bra.s	.setxsrcspd
.srcxmvleft:
		cmp.l	d4,d5
		ble.s	.srcxlowr	
.setxsrcspd:
		add.l	d6,d2
		rts
.srcxlowr:
		add.w	#1,d1
		rts

; d2 - ID
; d4 - Xpos.0000
; d5 - Ypos.0000
.showblk_cursor:
		lea	vramList_MainBlocks(pc),a2
		and.w	#$1F,d2
		sub.w	#1,d2
		lsl.w	#3,d2
		move.w	(a2,d2.w),d2
		add.w	#VRAMSET_BLOCKS+$2000|$8000,d2
		move.w	#$80-4,d0
		move.w	#$80-4,d1
		swap	d4
		swap	d5
		add.w	d4,d1
		add.w	d5,d0
		move.w	box_YScrl(a5),d5
		and.w	#$F,d5
		sub.w	d5,d0

		move.w	#$0500,d4
		btst	#2,(RAM_VdpCache+$C).w
		beq.s	.nodble
		move.w	d2,d4
		and.w	#$F800,d2
		lsr.w	#1,d4
		and.w	#$7FF,d4
		add.w	d4,d2
		add.w	#$80,d0
		move.w	#$0400,d4
.nodble:
		or.w	d3,d4
	; TODO: sprite oob check
		move.w	d0,(a4)+
		move.w	d4,(a4)+
		move.w	d2,(a4)+
		move.w	d1,(a4)+
		add.w	#1,d3
		rts

; d0 - Y pos
; d1 - X pos
; d2 - VRAM top
; d3 - Current LINK
.sprcursor_list:
		dc.w .cursor0-.sprcursor_list
		dc.w .cursor1-.sprcursor_list
		dc.w .cursor2-.sprcursor_list
		dc.w .cursor3-.sprcursor_list
		
; 3 block cursor
.cursor0:
		move.w	#VRAMSET_CURSOR|$8000+$2000,d2
		tst.w	(RAM_PGame_CursorFrame).w
		beq.s	.cursor0_1
		btst	#2,(RAM_VdpCache+$C).l
		bne.s	.cursor0_1
		add.w	#$20,d2
.cursor0_1:
		move.w	#$0F00,d6
		move.w	d3,d4
		or.w	d6,d4
		move.w	d0,(a4)+
		move.w	d4,(a4)+
		move.w	d2,(a4)+
		move.w	d1,(a4)+
		add.w	#$20,d1
		add.w	#1,d4
		add.w	#$10,d2
		move.w	d0,(a4)+
		move.w	d4,(a4)+
		move.w	d2,(a4)+
		move.w	d1,(a4)+
		add.w	#$10,d2
		add.w	#2,d3
		rts

; 6 block cursor
.cursor1:
		move.w	#VRAMSET_CURSOR+$40|$8000+$2000,d2
		tst.w	(RAM_PGame_CursorFrame).w
		beq.s	.frame0_6
		add.w	#$30,d2
.frame0_6:
		bsr.s	.cursor0_1
		add.w	#$20,d0
		sub.w	#$20,d1
		move.w	d3,d4
		add.w	#$0D00,d4
		move.w	d0,(a4)+
		move.w	d4,(a4)+
		move.w	d2,(a4)+
		move.w	d1,(a4)+
		add.w	#8,d2
		add.w	#$20,d1
		add.w	#1,d4
		move.w	d0,(a4)+
		move.w	d4,(a4)+
		move.w	d2,(a4)+
		move.w	d1,(a4)+
		add.w	#2,d3
		add.w	#8,d2
		rts

; 3 block cursor, double res
.cursor2:
		move.w	#(VRAMSET_CURSOR/2)|$8000+$2000,d2
		tst.w	(RAM_PGame_CursorFrame).w
		beq.s	.cursor2_1
		add.w	#$10,d2
.cursor2_1:
		add.w	#$80,d0
		move.w	#$0D00,d6
		move.w	d3,d4
		or.w	d6,d4		
		move.w	d0,(a4)+
		move.w	d4,(a4)+
		move.w	d2,(a4)+
		move.w	d1,(a4)+
		add.w	#$20,d1
		add.w	#1,d4
		add.w	#8,d2
		move.w	d0,(a4)+
		move.w	d4,(a4)+
		move.w	d2,(a4)+
		move.w	d1,(a4)+
		add.w	#2,d3
		add.w	#8,d2
		rts
		
; 6 block cursor, double res
.cursor3:
		move.w	#((VRAMSET_CURSOR+$40)/2)|$8000+$2000,d2
		tst.w	(RAM_PGame_CursorFrame).w
		beq.s	.frame0_6db
		add.w	#$18,d2
.frame0_6db:
		bsr.s	.cursor2_1
		sub.w	#$20,d1
		add.w	#$20,d0
; 		add.w	#4,d2
		move.w	#$0C00,d6
		move.w	d3,d4
		or.w	d6,d4
		move.w	d0,(a4)+
		move.w	d4,(a4)+
		move.w	d2,(a4)+
		move.w	d1,(a4)+
		add.w	#$20,d1
		add.w	#1,d4
		add.w	#4,d2
		move.w	d0,(a4)+
		move.w	d4,(a4)+
		move.w	d2,(a4)+
		move.w	d1,(a4)+
		add.w	#2,d3
		rts

; --------------------------------------------------------
; Guess next block ID
; --------------------------------------------------------

; d4 - current SEED
; 
; d0 - Result
; 
; Uses:
; d3,d4

box_GuessBlk:
		move.l	d4,d3
		ror.l	#4,d4
		rol.l	#5,d3
		add.l	d3,d4
		swap	d4
		ror.w	#3,d4
		swap	d4
		move.w	d4,d0
		and.w	#%1111,d0
		add.w	#1,d0
		rts

; --------------------------------------
; Check FULL line
; 
; Input:
; a6 - box buffer (width)
; a5 - box block data

; Output:
; d3 - $00 free | $01 full
; 
; Uses:
; d5-d6
; --------------------------------------

box_CheckLine:
		move.w	box_Width(a6),d6
		sub.w	#1,d6
		moveq	#0,d3
.chk_top:
		move.w	(a5),d5
		tst.b	d5
		beq.s	.no_blk
		add.w	#1,d3
.no_blk:
		adda	#2,a5
		dbf	d6,.chk_top
		rts

; --------------------------------------
; box_SendTrash
; 
; a6 - current Box
; d0 - X start
; d1 - X end (MAX: boxwidth-1)
; d2 - Height
; 
; Uses:
; d4-d6
; --------------------------------------

box_SendTrash:
	; TODO: more checks
		movea.l	box_BlockTrsh(a6),a3
		movea.l	box_BlockData(a3),a3
		adda	#MAX_BOXWIDTH*((MAX_BOXHEIGHT/2)-1),a3
		move.l	a3,a2
		move.w	d0,d4		; Set TL
		add.w	d4,d4
		adda	d4,a3
		move.w	d1,d4		; Set TR
		add.w	d4,d4
		adda	d4,a2
		move.w	#(MAX_BOXHEIGHT/2)-1,d6
.find_free:
		move.w	(a3),d5
		or.w	(a2),d5
		and.w	#$7FFF,d5
		beq.s	.use_this
		suba	#MAX_BOXWIDTH,a3
		suba	#MAX_BOXWIDTH,a2
		dbf	d6,.find_free
		rts
.use_this:
		move.l	#((SET_STRTTRSHIDS+4)<<16)+SET_STRTTRSHIDS|$00400040,d5
; 		move.l	#((SET_STRTTRSHIDS+4)<<16)+SET_STRTTRSHIDS,d5
		tst.w	d2
		beq.s	.trsh_mkline
		move.w	d6,d4
		sub.w	d2,d4
		bmi.s	.trsh_exit
		add.l	#$00010001,d5
		bsr	.trsh_mkline
		cmp.w	#1,d2
		beq.s	.trsh_mktop
		add.l	#$00020002,d5
		move.w	d2,d6
		sub.w	#2,d6
.trsh_midlp:
		bsr	.trsh_mkline
		dbf	d6,.trsh_midlp
		sub.l	#$00020002,d5
.trsh_mktop:
		add.l	#$00010001,d5
		bsr	.trsh_mkline
.trsh_exit:
		rts

; d5 - TL | TR
.trsh_mkline:
		swap	d6
		move.l	a3,a1
		move.w	d5,d4
		add.w	#8,d4
		move.w	d5,(a1)+
		swap	d5
		move.w	d1,d7
		sub.w	d0,d7
		sub.w	#2,d7
		bmi.s	.wdthzero
; 		sub.w	#1,d7
.wdthadd:
		move.w	d4,(a1)+
		dbf	d7,.wdthadd
.wdthzero:
		move.w	d5,(a1)+
		swap	d5
		swap	d6
		suba	#MAX_BOXWIDTH,a3
		rts

; --------------------------------------------------------
; Add points to the SCORE (WARNING: not stable)
; 
; d0 - input
; d1 - increment by
; --------------------------------------------------------

PzlGame_BcdScore_Add:
		abcd	d1,d0
		ror.l	#8,d0
		ror.l	#8,d1
		
		abcd	d1,d0
		ror.l	#8,d0
		ror.l	#8,d1
		
		abcd	d1,d0
		ror.l	#8,d0
		ror.l	#8,d1
		
		abcd	d1,d0
		ror.l	#8,d0
		ror.l	#8,d1


;  		bcc.s	.digt1
;  		bra.s	*
;  		ror.l	#8,d0
; 		ror.l	#8,d1
; 		move.w	d1,d4
; 		and.w	#$FF,d4
; 		abcd	d4,d0
;  		bcc.s	.nel4
;  		move.l	#$999999,d0
;  		bra.s	.nel2
; .nel4:
;  		rol.l	#8,d0
; .digt1:
;  		rol.l	#8,d0
.digt0:
		rts

; --------------------------------------------------------
; Increment or Decrement timer (BCD)
; 
; d4 - Timer value (LONG)
; --------------------------------------------------------

PzlGame_BcdTimer_Up:
		btst	#bitMtch_MatchOver,(RAM_Glbl_GameMtchFlags).w
		bne	.time_done
		tst.w	(RAM_PGame_PlyrsOn).w
		beq	.time_done
		btst	#bitMtch_Pause,(RAM_Glbl_GameMtchFlags).w
		bne	.time_done

		btst	#bitMtch_TimerDown,(RAM_Glbl_GameMtchFlags).w
		beq.s	.timer_up
.timer_down:
		move.l	(RAM_PGame_GlblTimer),d4
		beq.s	.time_done
		moveq	#1,d5
 		sbcd	d5,d4
		bcc.s	.nel2d
		moveq	#0,d5
		move.b	#$59,d4
		ror.l	#8,d4
 		sbcd	d5,d4
 		bcc.s	.nel3d
		move.b	#$59,d4
 		ror.l	#8,d4		
 		sbcd	d5,d4
 		bne.s	.nel4d
 		clr.l	d4
 		bra.s	.nel2d
.nel4d:
 		rol.l	#8,d4
.nel3d:
 		rol.l	#8,d4
.nel2d:
		move.l	d4,(RAM_PGame_GlblTimer)
		and.l	#$00FFFF00,d4
		bne.s	.timer_actv
		bset	#bitMtch_Timeout,(RAM_Glbl_GameMtchFlags).w
.timer_actv:
		rts

.timer_up:
		move.l	(RAM_PGame_GlblTimer),d4
 		cmp.l	#$999900,d4
 		beq.s	.nel2t
		moveq	#1,d5
 		abcd	d5,d4
		cmp.b	#$60,d4
		blt.s	.nel2t
		clr.b	d4
		ror.l	#8,d4
 		abcd	d5,d4
		cmp.b	#$60,d4
 		blt.s	.nel3t
		clr.b	d4
 		ror.l	#8,d4		
 		abcd	d5,d4
		cmp.b	#$60,d4
 		blt.s	.nel4t
 		move.l	#$999900,d4
 		bra.s	.nel2t
.nel4t:
 		rol.l	#8,d4
.nel3t:
 		rol.l	#8,d4
.nel2t:
		move.l	d4,(RAM_PGame_GlblTimer)
.time_done:
		rts

; --------------------------------------------------------
; Animate backgrounds
; 
; d3 - Current LINK
; --------------------------------------------------------

PzlGame_AnimateBg_Init:
		lea	(RAM_HorScroll),a5
		move.w	#224-1,d7
		moveq	#0,d4
.hnext:
		move.w	d4,d0
		bsr	System_SineWave
		add.w	#2,d4
		asr.l	#6,d0
		move.w	d0,2(a5)
		adda	#4,a5
		dbf	d7,.hnext
		rts

PzlGame_AnimateBg:
		btst	#2,(RAM_VdpCache+$C).l
		bne	.cant_deform

		lea	(RAM_PGame_YAnimBuff),a6
		lea	(RAM_PGame_YScrl_Main),a5
		lea	(RAM_PGame_YScrl_Sub),a4
		lea	.animate_incrmt(pc),a3
		move.w	#((336/16)/4)-1,d7
.next:
	rept 4
		move.l	(a6),d6
		move.l	(a3)+,d5
		btst	#2,(RAM_VdpCache+$C).l
		beq.s	.nodble
		add.l	d5,d5
.nodble:
		add.l	d5,d6
		swap	d6
		move.w	d6,2(a5)
		move.w	d6,2(a4)
		swap	d6
		move.l	d6,(a6)+
		adda	#4,a5
		adda	#4,a4
	endm	
		dbf	d7,.next
.cant_deform:
		rts
		
.animate_incrmt:
		dc.l $3200
		dc.l $3200
		dc.l $3200
		dc.l $3200
		dc.l $3200
		
		dc.l $2A00
		dc.l $2A00
		dc.l $2A00
		dc.l $2A00
		dc.l $2A00

		dc.l $3800
		dc.l $3800
		dc.l $3800
		dc.l $3800
		dc.l $3800

		dc.l $2C00
		dc.l $2C00
		dc.l $2C00
		dc.l $2C00
		dc.l $2C00
		dc.l $2C00

; --------------------------------------------------------
; HBlank
; --------------------------------------------------------

MainGame_HBlank:
		move.w	#$2700,sr
		move.w	#$929A,(vdp_ctrl).l		; Set WINDOW Bottom
		rte

MainGame_HBlank_Huge:
		move.w	#$2700,sr
		move.w	#$929B,(vdp_ctrl).l		; Set WINDOW Bottom
		rte		

MainGame_HBlank_2P:
		movem.l	d4-d6/a4-a5,-(sp)
		lea	(vdp_data),a5
		move.w	(RAM_PGame_HintCount).w,d4
		sub.w	#1,d4
		bmi.s	.step1
		sub.w	#1,d4
		bmi.s	.step2
		sub.w	#1,d4
		bmi.s	.step3
		clr.w	(RAM_PGame_HintCount).w
		bra.s	.clr
.exit:
		add.w	#1,(RAM_PGame_HintCount).w
.clr:
		movem.l	(sp)+,d4-d6/a4-a5
		rte
; Half top screen
.step1:
		move.w	#$928D,4(a5)		; Set WINDOW position 2
		bra.s	.exit
; Lower bottom screen
.step3:
		move.w	#$929B,4(a5)		; Set WINDOW position 3
		bra	.exit
; Middle screen
.step2:
		move.w	#$922F,4(a5)		; Set WINDOW position 3
		move.w	#$8228,4(a5)		; VDP MANUAL: PLANEA at $A000
		move.l	#$40000010,4(a5)
		lea	(RAM_PGame_Yscrl_Sub),a4
	rept (336/16)
		move.l	(a4)+,(a5)
	endm
		bra	.exit

; ====================================================================
; ----------------------------------------------------------------
; Small data
; ----------------------------------------------------------------

Pal_BlockPzes:	binclude "game/graphics/ingame/blocks_pal.bin"
		align 2
Pal_Backgrd00:	binclude "game/graphics/ingame/backg00_pal.bin"
		align 2

vramList_MainBlocks:
		dc.w $0000,$0002,$0001,$0003	; $01 red
		dc.w $0004,$0006,$0005,$0007	; $02 yellow
		dc.w $0008,$000A,$0009,$000B	; $03 green
		dc.w $200C,$200E,$200D,$200F	; $04 blue
		dc.w $2010,$2012,$2011,$2013	; $05 pink
		dc.w $2014,$2016,$2015,$2017	; $06 cyan
		dc.w $0018,$001A,$0019,$001B	; $07 RED bomb
		dc.w $201C,$201E,$201D,$201F	; $08 BLUE bomb	
		dc.w $4020,$4022,$4021,$4023	; >$09 Trash blocks
		dc.w $4024,$4026,$4025,$4027	;
		dc.w $4028,$402A,$4029,$402B	;
		dc.w $402C,$402E,$402D,$402F	;
		
		dc.w $4030,$4032,$4031,$4033	;
		dc.w $4034,$4036,$4035,$4037	;
		dc.w $4038,$403A,$4039,$403B	;
		dc.w $403C,$403E,$403D,$403F	;

		dc.w $4040,$4042,$4041,$4043	;
		dc.w $4044,$4046,$4045,$4047	;
		dc.w $4048,$404A,$4049,$404B	;
		dc.w $404C,$404E,$404D,$404F	;
		
		dc.w $4050,$4052,$4051,$4053	;
		dc.w $4054,$4056,$4055,$4057	;
		dc.w $4058,$405A,$4059,$405B	;
		dc.w $405C,$405E,$405D,$405F	;
		align 2
		
Map_PlyrBrdr:
		dc.w $0000,$0002,$0001,$0003
		dc.w $0004,$0006,$0005,$0007
		dc.w $0008,$000A,$0009,$000B
		dc.w $000C,$000E,$000D,$000F
		dc.w $0010,$0012,$0011,$0013
		dc.w $0014,$0016,$0015,$0017
Map_PlyrBrdr_LR:
		dc.w $0018,$001A,$0019,$001B
		dc.w $001C,$001E,$001D,$001F
		align 2
		
Map_ScoreInfo:
		dc.w $0000,$0002,$0001,$0003
		dc.w $0004,$0006,$0005,$0007
		dc.w $0008,$000A,$0009,$000B
		dc.w 0,0,0,0
		dc.w $000A,$000C,$000B,$000D
		dc.w $000E,$0010,$000F,$0011
		dc.w $0012,$0014,$0013,$0015
		dc.w 0,0,0,0
		dc.w $0014,$0016,$0015,$0017
		dc.w $0018,$001A,$0019,$001B
		dc.w $001C,$001E,$001D,$001F
		dc.w $0020,$0022,$0021,$0023
		align 2
