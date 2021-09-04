VarVsync	EQU	$00FFFFFC
VarHsync	EQU	$00FFFFF8

VBlank:
		lea	($C00000),a0
		lea	($FFFFFE00).w,a1
		move.l	#$78000003,4(a0)

		move.l	(a1)+,(a0)
		move.l	(a1)+,(a0)
		move.l	(a1)+,(a0)
		move.l	(a1)+,(a0)
		move.l	(a1)+,(a0)
		move.l	(a1)+,(a0)
		move.l	(a1)+,(a0)
		move.l	(a1)+,(a0)

		movem.l	a0-a1,-(sp)
		jsr	ReadJoypads
		movem.l	(sp)+,a0-a1

		addq.l	#1,(VarVsync)
		jsr	SndDrv_Update

		rte

; ===========================================================================
HBlank:

		rte
