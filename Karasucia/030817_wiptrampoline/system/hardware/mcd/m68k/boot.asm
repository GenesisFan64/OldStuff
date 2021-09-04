; =====================================================================
; Main CPU
; =====================================================================
; -------------------------------------------
; Variables
; -------------------------------------------

ThisCpu		= $A12000
CD_PrgRamMode	= 0

RAM_McdLoop	equ $FFFF8800

; =====================================================================
; -------------------------------------------
; Include
; -------------------------------------------

; =====================================================================
; -------------------------------------------
; Init
; -------------------------------------------

;  		obj $FFFF0600
		bset	#1,($A12003)			; Give WordRAM to Sub CPU
@initloop:		
		tst.b	($A1200F)			; Has sub CPU finished init?
		bne	@initloop			; if not, branch

		move.w	#$2700,sr
 		
 		move.l	#$00000020,(vdp_ctrl)		;Copy CRAM to PalBuffer
 		lea	(RAM_Palette),a1
 		move.w	#$3F,d0
@CopyPal:
 		move.w	(vdp_data),(a1)+
 		dbf	d0,@CopyPal
 		move.l	#$40000010,(vdp_ctrl).l
 		clr.l	(vdp_data).l
 		
    		lea	MD_RAM_LOOP(pc),a0
    		lea	(RAM_McdLoop),a1
    		move.w	#(MD_RAM_LOOP_e-MD_RAM_LOOP),d0
@ClrWaitRam:
   		move.b	(a0)+,(a1)+
    		dbf	d0,@ClrWaitRam
		
    		move.l	#RAM_McdLoop,($FFFFFD08)
     		move.b	#$74,(RAM_VidRegs+1)

;   		move.w	#$2000,sr
;  		fade	out

 		move.w	#$2700,sr
;  		move.l	#vdp_data00,(vdp_ctrl)
;  		move.w	#$0E0,(vdp_data)
;  		bra.s	*
 		
		jmp	MD_Main
 		
; =====================================================================
; -------------------------------------------
; RAM Loop
; -------------------------------------------

MD_RAM_LOOP:
		obj $FFFF8800
		include	"engine/mcd.asm"
 		inform 0,"RAM-LOOP ENDS AT: %h",*
		objend
MD_RAM_LOOP_e:

; =====================================================================
