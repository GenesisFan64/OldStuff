; ===========================================================================
; Error screen
; ===========================================================================
		
MD_BusError:
		bsr	ErrorScr_Init
		lea	Asc_ErrBus(pc),a0
		bsr	ErrorScr_ShowMsg
		bra	ErrorScr_Loop

MD_AddrError:
		bsr	ErrorScr_Init
		lea	Asc_ErrAddr(pc),a0
		bsr	ErrorScr_ShowMsg
		bra.s	ErrorScr_Loop

MD_IllegalError:
		bsr	ErrorScr_Init
		lea	Asc_ErrIlle(pc),a0
		bsr	ErrorScr_ShowMsg
		bra.s	ErrorScr_Loop

MD_ZeroDivError:
		bsr	ErrorScr_Init
		lea	Asc_ErrZerDiv(pc),a0
		bsr	ErrorScr_ShowMsg
		bra.s	ErrorScr_Loop

MD_ChkError:
		bsr	ErrorScr_Init
		lea	Asc_ErrChk(pc),a0
		bsr	ErrorScr_ShowMsg
		bra.s	ErrorScr_Loop

MD_TrapVError:
		bsr	ErrorScr_Init
		lea	Asc_ErrTrapV(pc),a0
		bsr	ErrorScr_ShowMsg
		bra.s	ErrorScr_Loop

MD_PrivilegeError:
		bsr	ErrorScr_Init
		lea	Asc_ErrPriv(pc),a0
		bsr	ErrorScr_ShowMsg
		bra.s	ErrorScr_Loop

MD_TraceError:
		bsr	ErrorScr_Init
		lea	Asc_ErrTrace(pc),a0
		bsr	ErrorScr_ShowMsg
		bra.s	ErrorScr_Loop

MD_LineA_Error:
		bsr	ErrorScr_Init
		lea	Asc_ErrLineA(pc),a0
		bsr	ErrorScr_ShowMsg
		bra.s	ErrorScr_Loop

MD_LineF_Error:
		bsr	ErrorScr_Init
		lea	Asc_ErrLineF(pc),a0
		bsr	ErrorScr_ShowMsg

; ----------------------------------------------
; Loop
; ----------------------------------------------

ErrorScr_Loop:
		bsr	Pads_Read

		cmp.b	#JoyC,(RAM_Joypads+OnPress)
		beq.s	@View
		bra.s	ErrorScr_Loop

; ----------------------------------------------

@View:
		move.w	#$8124,($C00004)
		move.w	#$8C00,($C00004)
		move.l	#$9000927C,($C00004)
		move.w	#$927C,($C00004)
		move.w	#$8164,($C00004)
		bchg	#0,($FFFF7000)
		beq.s	ErrorScr_Loop

		move.w	#$8124,($C00004)
		move.l	#$8C019081,($C00004)
		move.w	#$9200,($C00004)
		move.w	#$8164,($C00004)
		bra.s	ErrorScr_Loop

; ===========================================================================
; ----------------------------------------------
; Init
; ----------------------------------------------

ErrorScr_Init:	
 		move.w	#$2700,sr
 		movem.l	d0-d7/a0-a7,($FFFF7000)
 		move.b	#0,(RAM_VdpRegs+vdpReg_PlnSize)
 		
 		move.l	#$81248C00,($C00004)
 		move.l	#$9000927C,($C00004)
		move.b	#$9F,($C00011)
 		move.b	#$BF,($C00011)
 		move.b	#$DF,($C00011)
 		move.b	#$FF,($C00011)

   		move.l	#$50000003,($C00004)
   		move.w	#$37F,d0
@ClrWinScr:
   		move.w	#$8580,($C00000)
   		dbf	d0,@ClrWinScr

 		lea	Asc_ErrScr(pc),a0
 		move.l	#Plane_WD+(vdp_Ypos_32*8)+(vdp_Xpos*3),d1
 		move.w	#$8560+$6000,d2
 		moveq	#0,d3
 		bsr	VDP_LoadAsc
 
  		lea	Art_DbgFont(pc),a0
  		move.w	#$580,d0
  		move.w	#((Art_DbgFont_End-Art_DbgFont)/4)-1,d1
  		bsr	VDP_SendData_L

 		lea	($FFFF7000),a1
 		move.l	#Plane_WD+(vdp_Ypos_32*8)+(vdp_Xpos*7),d3
 		moveq	#7,d5
@ShowDdata:
 		movem.l	d3,-(sp)
                moveq	#0,d0
                move.l	(a1),d0
                move.l	d3,d1
                move.w	#$8560+$6000+"0",d2
                bsr	VDP_ShowVal_Long
                movem.l	(sp)+,d3
 
                add.l	#$400000,d3
                adda	#4,a1
 		dbf	d5,@ShowDdata

 		lea	($FFFF7020),a1
 		move.l	#Plane_WD+(vdp_Ypos_32*8)+(vdp_Xpos*20),d3
 		moveq	#7,d5
@ShowAdata:
 		movem.l	d3,-(sp)
                moveq	#0,d0
                move.l	(a1),d0
                move.l	d3,d1
                move.w	#$8560+$6000+"0",d2
                bsr	VDP_ShowVal_Long
                movem.l	(sp)+,d3

                add.l	#$400000,d3
                adda	#4,a1
		dbf	d5,@ShowAdata
 
  		clr.b	($FFFF7000)

 		move.w	#$8164,($C00004)
		rts

; ----------------------------------------------
; Show error text
; ----------------------------------------------

ErrorScr_ShowMsg:
		move.l	#$51060003,d1
		move.w	#$8560+$6000,d2
		moveq	#0,d3
		bra	VDP_LoadAsc

; ===========================================================================

Asc_ErrScr:
		dc.b "D0 $00000000 A0 $",$A
		dc.b "D1 $00000000 A1 $",$A
		dc.b "D2 $00000000 A2 $",$A
		dc.b "D3 $00000000 A3 $",$A
		dc.b "D4 $00000000 A4 $",$A
		dc.b "D5 $00000000 A5 $",$A
		dc.b "D6 $00000000 A6 $",$A
		dc.b "D7 $00000000 SP $00000000",$A
		dc.b $A
		dc.b "Press C to see the last",$A
		dc.b "frame moment           ",$A
		dc.b "(without WINDOW layer) ",$A
		dc.b 0
		even

Asc_ErrBus:	dc.b "BUS ERROR                ",$A
		dc.b $A
		dc.b "Beep beep...             ",0
		even
		
Asc_ErrAddr:	dc.b "ADDRESS ERROR            ",$A
		dc.b $A
		dc.b "Genesis doesnt like ODD  ",0
		even
		
Asc_ErrIlle:	dc.b "ILLEGAL Instruction      ",$A
		dc.b $A
		dc.b "YOU ARE UNDER ARREST     ",0
		even
		
Asc_ErrZerDiv:	dc.b "ZERO DIVIDE              ",$A
		dc.b $A
		dc.b "BOOM (>*_*)>              ",0
		even
		
Asc_ErrChk:	dc.b "CHK INSTRUCTION          ",$A
		dc.b $A
		dc.b "CHKate esta .l.          ",0
		even
		
Asc_ErrTrapV:	dc.b "TRAPV ERROR              ",$A
		dc.b $A
		dc.b "ITS A TRAP               ",0
		even
		
Asc_ErrPriv:	dc.b "PRIVILEGE ERROR          ",$A
		dc.b $A
		dc.b "Voto por Voto            ",0
		even
		
Asc_ErrTrace:	dc.b "TRACE                    ",$A
		dc.b $A
		dc.b "TRACEd >_>               ",0
		even
		
Asc_ErrLineA:	dc.b "LINEA ERROR              ",$A
		dc.b $A
		dc.b "Hi Fusion or Gens        ",0
		even
		
Asc_ErrLineF:	dc.b "LINEF ERROR              ",$A
		dc.b $A
		dc.b "STOP LOOKING AT HERE TCRF",0
		even
		
Art_DbgFont:	incbin	"engine/shared/data/art_dbgfont.bin",0,($20*96)
Art_DbgFont_End:

 		even