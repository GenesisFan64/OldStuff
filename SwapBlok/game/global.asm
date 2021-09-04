; ====================================================================
; ----------------------------------------------------------------
; Put your global structs/values here
; ----------------------------------------------------------------

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_BOXES		equ 4
MAX_SCORBOX		equ 5 			; score and time boxes

; ====================================================================
; --------------------------------------------------------
; Structures
; --------------------------------------------------------

; Box
			struct 0
box_BlockTrsh		ds.l MAX_BOXES-1	; box pointer(s) to attack
box_BlockData		ds.l 1			; MAIN block pointer
box_YScrl		ds.l 1			; YYYY.0000
box_YScrl_old		ds.l 1
box_YSpd		ds.l 1			; 0000.0000
box_BoardTimeOut	ds.l 1			; TIMER before getting game over on full box
box_TrshSmlReq		ds.l 1			; Small trash request (if 4+ blocks)
box_Status		ds.w 1			; bitstatus
box_BoardX		ds.w 1			; Board X pos
box_BoardY		ds.w 1			; Board Y pos
box_Width		ds.w 1			; Width (MAX 16)
box_Height		ds.w 1			; Height (currently hardcoded to $000D)
box_MatchCount		ds.w 1			; Number of matches
box_NumMtchAdd		ds.w 1			; Add blocks to match
box_NumMtchLast		ds.w 1			; Last maximum of matches
box_NumMtchBlk		ds.w 1			; Number of blocks flashing
box_ComboCount		ds.w 1			; Number of combos
box_ComboCntShow	ds.w 1			; Same thing but in BCD
box_YShake		ds.w 1			; 0.000
box_FrameTimer		ds.w 1			; (Used by shake)
box_TrshReq		ds.w 1			; Trash request bits

box_UserScore		ds.l 1			; 000000
box_UserTime		ds.l 1			; 00:00.00 (milisecs hidden)
box_UserBorder		ds.w 1			; border color
box_UserLevel		ds.w 1			; START fill level
box_UserMaxIds		ds.w 1			; MAX usable blocks to grab
box_UserWins		ds.w 1			; WIN points
box_UserLoses		ds.w 1			; LOSE points
sizeof_Box		ds.l 0
			finish

; Cursor
			struct 0
cursor_Control		ds.l 1			; RAM address for current controller
cursor_Box		ds.l 1			; RAM address for block box
cursor_SwapSrcPos	ds.w 2			; X / Y piece src position
cursor_SwapDstPos	ds.w 2			; X / Y piece dest position
cursor_SwapSrcShdw	ds.w 2			; Xpos | Ypos
cursor_SwapDstShdw	ds.w 2			; Xpos | Ypos
cursor_SwapSrcId	ds.w 1			; ID
cursor_SwapDstId	ds.w 1			; ID
cursor_SwapSrcSpr	ds.l 2			; Xpos.0000 | Ypos.0000
cursor_SwapSrcSprOld	ds.l 2			; Xpos.0000 | Ypos.0000
cursor_SwapSrcSprSpd	ds.l 2			; Xpos.0000 | Ypos.0000
cursor_SwapDstSpr	ds.l 2			; Xpos.0000 | Ypos.0000
cursor_SwapDstSprOld	ds.l 2			; Xpos.0000 | Ypos.0000
cursor_SwapDstSprSpd	ds.l 2			; Xpos.0000 | Ypos.0000
cursor_SwapMode		ds.w 1			; Current swap mode
cursor_Type		ds.w 1			; 0 - 3blocks | 1 - 6blocks
cursor_TypeOld		ds.w 1
cursor_X		ds.w 1
cursor_Y		ds.w 1
cursor_Frame		ds.w 1
cursor_Status		ds.w 1
cursor_SpdUpTmr		ds.w 1
sizeof_Cursor		ds.l 0
			finish

			struct 0
scorBox_BoxAddr		ds.l 1
scorBox_Status		ds.w 1
scorBox_X		ds.w 1
scorBox_Y		ds.w 1
scorBox_Width		ds.w 1
scorBox_Height		ds.w 1
scorBox_Type		ds.w 1
sizeof_ScorBox		ds.l 0
			finish
			
; ====================================================================
; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; cursor_Status
bitCurSt_Active		equ 7
bitCurSt_MidSwapLock	equ 6

; box_Status
bitPlySt_Active		equ 7
bitPlySt_DrwAll		equ 5
bitPlySt_DrwLine	equ 4
bitPlySt_ChkMatch	equ 3
bitPlySt_GameOver	equ 2
bitPlySt_SpdUp		equ 1
bitPlySt_MidSwapStop	equ 0

; box_Status
bitScorSt_Active	equ 7

; RAM_PGame_GlblMtchFlags
MtchFlg_ComboSpdUp	equ $0004
MtchFlg_TrashEnbl	equ $0002
MtchFlg_TimerDown	equ $0001
bitMtch_Pause		equ 7
bitMtch_MatchOver	equ 6
bitMtch_Timeout		equ 5
bitMtch_ComboSpdUp	equ 2
bitMtch_TrashEnbl	equ 1
bitMtch_TimerDown	equ 0

; ====================================================================
; --------------------------------------------------------
; RAM
; --------------------------------------------------------

; ds.b numof_bytes
; ds.w numof_words (2 bytes)
; ds.l numof_longs (4 bytes)
			struct RAM_Global
RAM_HorScroll		ds.l 224
RAM_VerScroll		ds.l 336/16
RAM_Glbl_PzlScores	ds.b sizeof_ScorBox*MAX_SCORBOX
RAM_Glbl_PzlBoxes	ds.b sizeof_Box*MAX_BOXES
RAM_Glbl_PzlCursors	ds.b sizeof_Cursor*MAX_BOXES
RAM_Glbl_NumPlayers	ds.w 1
RAM_Glbl_NumBoxes	ds.w 1
RAM_Glbl_GameMtchFlags	ds.w 1			; Match flags (for everyone)
RAM_GlblRndSeeds	ds.l 2
RAM_GlblFrameCnt	ds.l 1
RAM_PuzlGameMode	ds.w 1
sizeof_global		ds.l 0
			finish
