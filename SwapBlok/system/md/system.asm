; ====================================================================
; ----------------------------------------------------------------
; System
; ----------------------------------------------------------------

; ASSEMBLER FLAGS USED:
; MCD  - Mega CD
; MARS - 32X

; --------------------------------------------------------
; Init System
; 
; Uses:
; a0-a2,d0-d1
; --------------------------------------------------------

System_Init:
		move.w	#$0100,(z80_bus).l	; $0100 - Stop Z80
.wait:
		btst	#0,(z80_bus).l		; Z80 stopped?
		bne.s	.wait			; If not, wait
		moveq	#%01000000,d0		; d0 = (TH=1), Init input ports
		move.b	d0,(sys_ctrl_1).l	; Port 1 = d0
		move.b	d0,(sys_ctrl_2).l	; Port 2 = d0
		move.b	d0,(sys_ctrl_3).l	; Modem  = d0
		move.w	#0,(z80_bus).l		; $0000 - Start Z80
		
		move.w	#$4EF9,(RAM_GoToHBlnk).l
		move.l	#MD_HBlank,(RAM_GoToHBlnk+2).l
		move.w	#$4EF9,(RAM_GoToVBlnk).l
		move.l	#MD_VBlank,(RAM_GoToVBlnk+2).l
		rts
		
; ====================================================================
; ----------------------------------------------------------------
; System subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; System_VSync
; 
; Waits for VBlank
; 
; Uses:
; d4
; --------------------------------------------------------

System_VSync:
		move.w	(vdp_ctrl),d4			; Read VDP Control to d4
		btst	#bitVBlnk,d4			; Test VBlank bit
		beq.s	System_VSync			; If FALSE (not inside VBlank), try again
		bsr	System_Input			; Read user input data
.wait:		move.w	(vdp_ctrl),d4			; d4 - Read VDP Control
		btst	#bitVBlnk,d4			; Test VBlank bit
		bne.s	.wait				; If TRUE (inside VBlank), wait for exit
		rts

; --------------------------------------------------------
; System_Random
; 
; Random number generator
; 
; Uses:
; d4-d6,a6
; --------------------------------------------------------

System_Random:
		move.l	(RAM_GlblRndSeeds).w,d5
		bne.s	.blank
		move.l	#$5A6A26D3,d5
.blank:
		move.l	d5,d4
		asl.l	#3,d5
		add.l	d4,d5
		asl.l	#2,d5
		add.l	d4,d5
		move.w	d5,d4
		swap	d5
		add.w	d5,d4
		move.w	d4,d5
		move.l	d5,(RAM_GlblRndSeeds).w
		rts

; --------------------------------------------------------
; System_SineWave
; 
; Uses:
; d4-d6,a4-a5
; --------------------------------------------------------

System_SineWave:
		andi.w	#$FF,d0
		add.w	d0,d0
		addi.w	#$80,d0
		move.w	.sine_data(pc,d0.w),d1
		subi.w	#$80,d0
		move.w	.sine_data(pc,d0.w),d0
		rts
.sine_data:
		binclude "system/md/data/sinewave.bin"
		align 2

; --------------------------------------------------------
; System_Input
; 
; WARNING: Don't call this outside of VBLANK
; (call System_VSync first)
; 
; Uses:
; d4-d6,a4-a5
; --------------------------------------------------------

System_Input:
; 		move.w	#$0100,(z80_bus).l	; $0100 - Stop Z80
; .wait:
; 		btst	#0,(z80_bus).l		; Z80 stopped?
; 		bne.s	.wait			; If not, wait
		lea	(sys_data_1),a4		; a4 - Port 1 input data from system
		lea	(RAM_InputData),a5	; a5 - Output data for reading
		bsr	.this_one		; read this input
		adda	#2,a4			; next port [$A10005]
		adda	#sizeof_input,a5	; next output slot
		bsr	.this_one		; read this input
; 		move.w	#0,(z80_bus).l		; $0000 - Start Z80
		rts

; --------------------------------------------------------	
; do port
; 
; a4 - Current port
; a5 - Output data
; --------------------------------------------------------

.this_one:
		bsr	.find_id			; Grab ID, returns at d4
		move.b	d4,pad_id(a5)			; Save ID to output
		cmp.w	#$F,d4				; Disconnected?
		beq.s	.exit				; If yes, exit this
		and.w	#$F,d4				; Clear other bits, keep right 4 bits
		add.w	d4,d4				; multiply by 2 for this list
		move.w	.list(pc,d4.w),d5		; d5 = list+(inputid*2)
		jmp	.list(pc,d5.w)			; jump to list+jumpresult

; ------------------------------------------------

.exit:
		clr.b	pad_ver(a5)			; Clear output pad version
		rts

; --------------------------------------------------------
; Grab ID
; --------------------------------------------------------

.list:		dc.w .exit-.list	; $00
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $04
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .id_07-.list
		dc.w .exit-.list	; $08
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $0C
		dc.w .id_0D-.list
		dc.w .exit-.list
		dc.w .exit-.list

; --------------------------------------------------------
; ID $07
; 
; SEGA Multitap
; --------------------------------------------------------

.id_07:
		move.b	#$60,6(a4)	; CTRL
		move.b	#$60,(a4)	; DATA
    
		bra.s	*

; --------------------------------------------------------
; ID $0D
; 
; Normal controller, Old or New
; --------------------------------------------------------

.id_0D:
		move.b	#$40,(a4)	; Show CB|RLDU
		nop
		nop
		move.b	#$00,(a4)	; Show SA|RLDU
		nop
		nop
		move.b	#$40,(a4)	; Show CB|RLDU
		nop
		nop
		move.b	#$00,(a4)	; Show SA|RLDU
		nop
		nop
		move.b	#$40,(a4)	; 6 button responds
		nop
		nop
		move.b	(a4),d4		; Grab ??|MXYZ
 		move.b	#$00,(a4)
  		nop
  		nop
 		move.b	(a4),d6		; Type: $03 old, $0F new
 		move.b	#$40,(a4)
;  		nop
;  		nop
		clr.b	pad_ver(a5)
		and.w	#$F,d6
		lsr.w	#2,d6
		and.w	#1,d6
		beq.s	.oldpad
		not.b	d4
 		and.w	#%1111,d4
		move.b	on_hold(a5),d5
		eor.b	d4,d5
		move.b	d4,on_hold(a5)
		and.b	d4,d5
		move.b	d5,on_press(a5)
.oldpad:
		move.b	d6,pad_ver(a5)
		
		move.b	#$00,(a4)	; Show SA??|RLDU
		nop
		nop
		move.b	(a4),d4
		lsl.b	#2,d4
		and.b	#%11000000,d4
		move.b	#$40,(a4)	; Show ??CB|RLDU
		nop
		nop
		move.b	(a4),d5
		and.b	#%00111111,d5
		or.b	d5,d4
		not.b	d4
		move.b	on_hold+1(a5),d5
		eor.b	d4,d5
		move.b	d4,on_hold+1(a5)
		and.b	d4,d5
		move.b	d5,on_press+1(a5)
		rts
		
; --------------------------------------------------------
; Grab ID
; --------------------------------------------------------

.find_id:
		moveq	#0,d4
		move.b	#%01110000,(a4)	; TH=1,TR=1,TL=1
		nop
		nop
		bsr.s	.get_id
		move.b	#%00110000,(a4)	; TH=0,TR=1,TL=1
		nop
		nop
		add.w	d4,d4
.get_id:
		move.b	(a4),d5
		move.b	d5,d6
		and.b	#$C,d6
		beq.s	.step_1
		addq.w	#1,d4
.step_1:
		add.w	d4,d4
		move.b	d5,d6
		and.w	#3,d6
		beq.s	.step_2
		addq.w	#1,d4
.step_2:
		rts
; ====================================================================
; ----------------------------------------------------------------
; Default VBlank
; ----------------------------------------------------------------

MD_VBlank:
		rte

; ====================================================================
; ----------------------------------------------------------------
; System data
; ----------------------------------------------------------------
