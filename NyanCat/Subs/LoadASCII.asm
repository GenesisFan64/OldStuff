_Tab		equ	$09
_NewLine	equ	$0A
_Space		equ	$0D
_End		equ	$7D

; ---------------------------------------------------------------------------
LoadASCII:
		move.l	d5,($C00004).l
LoadText_Loop:
		tst.w	d4
		beq     LoadText_Loop_NoDelay
		move.w	d4,d0
		bsr	DelayProgram

LoadText_Loop_NoDelay:
		moveq	#0,d1
		move.b	(a1)+,d1
		move.b	d1,d2

		cmp.b	#_Tab,d2
		beq	LoadASCII_AddTab
		cmp.b	#_Space,d2
		beq	LoadASCII_AddSpace
		cmp.b	#_End,d2
		bne	LoadASCII_Print

		rts
; ---------------------------------------------------------------------------
VRAM_ASCII	equ	$580

LoadASCII_Print:
		cmp.b	#_NewLine,d2
		beq	LoadASCII_Fix

		move.b	d2,d1
		add.w	#VRAM_ASCII,d1
		move.w	d1,($C00000)
LoadASCII_Fix:
		bra	LoadText_Loop

LoadASCII_AddSpace:
		cmp.b	#_Tab,d2
		beq	LoadASCII_Fix

		add.l	#$800000,d5
		bra	LoadASCII

LoadASCII_AddTab:
		add.l	#$100000,d5
		bra	LoadASCII

LoadASCII_Test2:
		cmp.b	#_NewLine,d2
		beq	LoadASCII_Fix
		rts

; ===========================================================================
LoadASCII_OLD:
		move.l	d5,($C00004).l
LoadASCII_Original_Loop:
		moveq	#0,d1
		move.b	(a1)+,d1
		bmi.w	LoadASCII_Original_AddSpace	; if a1 = $FF, branch
		bne.w	LoadASCII_Original_Print
		rts
LoadASCII_Original_Print:
		add.w	d2,d1
		move.w	d1,($C00000)		;"print" la letra
		bra.w	LoadASCII_Original_Loop
LoadASCII_Original_AddSpace:
		add.l	#$800000,d5		;Espacio
		bra.w	LoadASCII_OLD