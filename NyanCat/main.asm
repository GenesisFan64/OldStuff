                                        		dc.l $FFF800,Entrypoint,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l HBlank,ErrorTrap,VBlank,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap
		dc.l ErrorTrap,ErrorTrap,ErrorTrap,ErrorTrap

		dc.b "SEGA Genesis    "
		dc.b "(C)GF64 2011.???"
		dc.b "Nyan Cat MD                                     "
		dc.b "Nyan Cat                                        "
		dc.b "GM MK-NYAN!-01"
		dc.w 0
		dc.b "J               "
		dc.l 0
		dc.l 0
		dc.l $FF0000
		dc.l $FFFFFF
		dc.l $20202020
		dc.l $20202020
		dc.l $20202020
		dc.b "    LOL Bronies                                     "
		dc.b "JUE             "

; ===========================================================================
ErrorTrap:
		bra.s	*

; ===========================================================================

		include	"int.asm"
		even

; ===========================================================================

EntryPoint:
		cmp.l	#$08D30000,($FFFFC000).w
		bne	EntryPoint_OK
		cmp.l	#$BEB80100,($FFFFC004).w
		bne	EntryPoint_OK
		cmp.l	#$6722B8B8,($FFFFC008).w
		bne	EntryPoint_OK
		cmp.l	#$01006608,($FFFFC00C).w
		bne	EntryPoint_OK

		move.w	#$8144,($C00004)
		move.l	#$43960003,d5
                lea	(Str_Disclaimer),a1
                move.w	#$20,d3
                jsr	VDP_LoadStr
		move.l	#$000DFFFF,d0
EntryPoint_Delay:
		sub.l	#1,d0
		bne	EntryPoint_Delay

		move.l	#0,($FFFFC000).w
		move.l	#0,($FFFFC004).w
		move.l	#0,($FFFFC008).w
		move.l	#0,($FFFFC00C).w

EntryPoint_OK:
                jsr	sub_729B6

		move.b	($A10001),d0
		andi.b	#$0F,d0
		beq	version_0
		move.l	#'SEGA',$A14000
version_0:

		move.l	#$40000003,d0
		jsr	ClearPlane
		move.l	#$60000003,d0
		jsr	ClearPlane
		
		jsr	SetupVDP

		jsr	SoundDriverLoad
		jsr	JoypadInit
		move.w	#$2300,sr

                lea	($FFFFFE00),a1
                move.l	#0,(a1)+
                move.l	#0,(a1)+
                move.l	#0,(a1)+
                move.l	#0,(a1)+

		move.w	#0,($FFFFFFA0).w
		move.l	#$C0000000,($C00004).l
		move.w	#$3F,d0
GamePrg_ClearPal:
		move.w	#0,($C00000).l
		dbf	d0,GamePrg_ClearPal

                cmp.b	#JoyB+JoyC,(RAM_Control_1_Hold).w
                beq	GamePrg_Cheat

                move.l	#$44000000,($C00004).l
                lea	(Art_Cat),a2
                move.w	#$FB,d0
                bsr	VDP_LoadArt

                move.w	#$81,d0
                jsr	PlaySound
GamePrg:
		add.w	#1,($FFFFFFA0).w
		jsr	DelayProgram
		cmp.w	#$D3,($FFFFFFA0).w
		ble	GamePrg

		lea	(Pal_NyanCat),a1
		move.w	#$F,d0
		move.l	#$C0000000,($C00004).l
		jsr	LoadPal

                lea	($FFFFFE00),a1
                move.w	#$00E5,(a1)+
                move.w	#$0E01,(a1)+
                move.w	#$0020,(a1)+
                move.w	#$0105,(a1)+

                move.w	#$00E5,(a1)+
                move.w	#$0A02,(a1)+
                move.w	#$0020+$C,(a1)+
                move.w	#$0105+$20,(a1)+

GameProgram_Loop:
		jsr	DelayProgram
                jsr	NynaCat_Animate

		bra.s	GameProgram_Loop

; ======================================================

GamePrg_Cheat:
                move.l	#$40200000,($C00004).l
                lea	(GFX_IMG),a2
                move.w	#1185,d0
		jsr	VDP_LoadArt

		lea	(Maps_IMG),a1
		move.l	#$40000003,d0
		moveq	#39,d1
		moveq	#29,d2
		move.w	#1,d5
		jsr	VDP_LoadMaps
		
		lea	(Maps2_IMG),a1
		move.l	#$60000003,d0
		moveq	#39,d1
		moveq	#29,d2
		move.w	#$2001,d5
		jsr	VDP_LoadMaps

                move.w	#$82,d0
                jsr	PlaySound

                move.l	#$C0000000,($C00004).l
                lea	(Pal_IMG),a1
		move.w	#$1F,d0
		jsr	LoadPal
		
GamePrg_Cheat_Loop:
		jsr	DelayProgram

		bra.s	GamePrg_Cheat_Loop

; ======================================================
RAM_MsgBuffer	equ	$FFFFFDFE
RAM_Frame	equ	$FFFFFDFC
RAM_Timer	equ	$FFFFFDFE

NynaCat_Animate:
		subq.b	#1,(RAM_Timer).w
		bpl	NynaCat_Animate_Rts
                move.b  #$3,(RAM_Timer).w
                moveq	#0,d0
                move.w  (RAM_Frame).w,d0
		add.w	#1,(RAM_Frame).w
                lea     ($FFFFFE00),a2
                
                cmpi.w	#$107,4(a2)
                beq	NynaCat_Animate_Restart
		add.w   #$15,4(a2)
		add.w   #$15,$C(a2)

NynaCat_Animate_Rts:
                rts

NynaCat_Animate_Restart:
                move.w	#$0020,4(a2)
                move.w	#$0020+$C,$C(a2)
		move.w	#0,(RAM_Frame).w
		rts

; ======================================================

		include	"Subs/VDP.asm"
		even
		include	"Subs/PalHndl.asm"
		even
		include	"Subs/Pads.asm"
		even

; ======================================================
Pal_NyanCat:
		incbin "Data/Pal_Cat.bin"
		even
Art_Cat:
		incbin "Data/Art_Cat.bin"
		even

Str_Disclaimer:
		dc.b "   THIS GAME IS",$FF
		dc.b $FF
		dc.b "       NOT",0
		even

; ======================================================

Pal_IMG:
		incbin	"Data/Pal.bin"
		even
GFX_IMG:
		incbin	"Data/GFX.bin"
		even
Maps_IMG:
		incbin	"Data/Maps.bin"
		even
Maps2_IMG:
		incbin	"Data/Maps2.bin"
		even

; ======================================================

		include	"Snd/main.asm"
		
; ======================================================
