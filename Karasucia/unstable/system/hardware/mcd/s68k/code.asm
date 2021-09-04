; =====================================================================
; Sub CPU
; =====================================================================

ThisCpu		=	$FF8000
BackupRam	equ 	$FE0000
numof_stamps	equ 	32

; -------------------------------------------
; Variables
; -------------------------------------------

		rsreset
;   Structure initialized in initGfxObject
;   Size is <= $A0 bytes
word_0		rs.w	1

;   Provided by main CPU
word_2		rs.w	1
word_4		rs.w	1
word_6		rs.w	1
word_8		rs.w	1				;Flip I guess
word_A		rs.w	1				;Rotate
word_C		rs.w	1				;True X
word_E		rs.w	1				;True Y

word_20		rs.w	1
word_22		rs.w	1
word_24		rs.w	1
word_26		rs.w	1
word_30		rs.w	1
word_32		rs.w	1
word_34		rs.w	1
word_36		rs.w	1
word_38		rs.w	1
word_3C		rs.w	1
word_40		rs.w	1
word_44		rs.w	1
long_48		rs.l 1
long_4C		rs.l 1
long_50		rs.l 1
long_54		rs.l 1
long_5C_div	rs.l 1
long_5C		rs.l 1
long_60		rs.l 1
sizeof_stamp	rs.l 0

; -------------------------------------------
; RAM
; -------------------------------------------

		rsset $10000
StampBuffer	rs.b sizeof_stamp*numof_stamps
Save_Data	rs.b $20

VBlankFlag	rs.w 1
BiosArgs	rs.l $20
BRAM_Buffer	rs.b $640
BRAM_Strings	rs.b $18
ISO_Files	rs.w ($800*$20)
StoredData	rs.b $20000			;$28100
endof_sub	rs.l 0
; 		inform 0,"CHECA AQUI: %h %h",BRAM_Buffer,BRAM_Strings
		
; -------------------------------------------
; Include
; -------------------------------------------

		include "system/hardware/mcd/s68k/incl/equs.asm"
		include "system/hardware/mcd/s68k/incl/cdbios.asm"
		
; =====================================================================
; -------------------------------------------
; Header
; -------------------------------------------

		obj $6000
		dc.b "MAIN       ",0
		dc.w 0,0
		dc.l 0
		dc.l 0
		dc.l $20
		dc.l 0
@Table:
		dc.w	SP_Init-@Table
		dc.w	SP_Main-@Table
		dc.w	SP_IRQ-@Table
		dc.w	0
		dc.w	0

; =====================================================================
; -------------------------------------------
; Init
; -------------------------------------------

SP_Init:
  		bclr	#bitWRamMode,(ThisCpu+MemoryMode+1)
		bsr	Init9660
		lea	(PCM),a0
		move.b	#$80,d3
		moveq	#$F,d5
@Next:
		move.b	d3,Ctrl(a0)
		bsr	PCM_Wait
		lea	($FF2001),a2
		move.w	#$FFF,d0
@loop1:
		move.b	#$FF,(a2)
		addq.l	#2,a2
		dbf	d0,@loop1
		move.b	d3,Ctrl(a0)
		bsr	PCM_Wait
		add.b	#1,d3
		dbf	d5,@Next

; 		move.w	#$2700,sr
; 		BSET	#1,$FF8033
; 		BSET	#2,$FF8033
; 		BCLR	#3,$FF8033
		
		clr.b	(ThisCpu+CommSub)			; SubCpu free
; 		move.w	#$2000,sr
		rts
		
; =====================================================================
; -------------------------------------------
; Main
; -------------------------------------------

SP_Main:	
		tst.b	(ThisCpu+CommMain)	; Check command
		bne	SP_Main			; If NOT clear, loop 
		move.b	#1,(ThisCpu+CommSub)	; Else, set status to ready
@loop:				
		tst.b	(ThisCpu+CommMain)	; Check command
		beq.s	@loop			; If none issued, loop

		lea	(ThisCpu+CommDataM),a6	; a6 - Input bytes
		lea	(ThisCpu+CommDataS),a5	; a5 - Output bytes
		moveq	#0,d0
		move.b	(ThisCpu+CommMain),d0
		add.w	d0,d0
		move.w	@Command(pc,d0.w),d1
		tst.w	d1
		beq.s	@Null
		jsr	@Command(pc,d1.w)
@Null:
		move.b	#0,(ThisCpu+CommSub)	; Done.
		bra.s	SP_Main			; Loop
		
; -------------------------------------------

@Command:
		; $00+ Generic stuff
		dc.w	0			; NULL
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	Cmd_04-@Command		; Load data to WordRAM from ISO Filesystem
		dc.w	Cmd_05-@Command
		dc.w	0
		dc.w	0
		dc.w	Cmd_08-@Command		; Set WordRAM for MainCPU
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		
		; $10+ CD Audio control
		dc.w	Cmd_10-@Command		; Play song, repeat
		dc.w	0			; Play song, once
		dc.w	0
		dc.w	0
		dc.w	Cmd_14-@Command		; Stop song
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0

		; $20+ PCM
		dc.w	Cmd_20-@Command		; Load Sample from disc
		dc.w	Cmd_21-@Command		; Set Channel Sample
		dc.w	Cmd_22-@Command		; Set Channel Frequency
		dc.w	Cmd_23-@Command		; Set Channel Panning
		dc.w	Cmd_24-@Command		; Set Channel Envelope
		dc.w	Cmd_25-@Command		; Set Channel ON/OFF
		dc.w	Cmd_26-@Command		; FULLY Clean the PCM Chip
		dc.w	0
		dc.w	0	
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0

		; $30+ Stamps
		dc.w	Cmd_30-@Command		; Init stamp system
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	Cmd_34-@Command		; Modify a stamp
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	Cmd_38-@Command		; Run ALL stamps
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		
		; $40+ BRAM (Save data)
		dc.w	Cmd_40-@Command		; BRAM Init
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0	
; 		
; 		; $50+ FMV
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0	
; 
; 		; $60+
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0	
; 
; 		; $70+
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
; 		dc.w	0
	
		even		

; =====================================================================
; -------------------------------------------
; $04 - Load Hadagi file to WordRAM
; 
; CommDataM:
; $00-$07 - Filename
; 
; CommDataS:
; $00 - -1 if failed
; -------------------------------------------

Cmd_04:
		movea.l	a6,a0			; Name pointer
		bsr	FindFile		; Find File returns params in the right format for ReadCD
		move.l	#$80000,a0		; Set destionation to WordRAM
		move.w	#$800,d2
		bra	ReadSector
	
; -------------------------------------------
; $05 - Load PRG-RAM from *Hadagi*
; 
; CommDataM:
; $00-$0B - Filename ($C must be $00)
; $0D     - What to do
; > $00 - Load full file to buffer
; > $01 - PRG-RAM to WordRAM for MAIN
; > $02 - Load WordRAM
;
; CommDataS:
; $00 - -1 if something failed
; -------------------------------------------

Cmd_05:
 		tst.b	$D(a6)
 		bne.s	@Tasks
 		movea.l	a6,a0
		bsr	FindFile
 		bmi	@Failed
 		lea	(StoredData),a0
 		move.w	#$800,d2
 		bra	ReadSector
@Tasks:
 		lea	(StoredData),a3
 		cmp.l	#"RAM ",(a3)
 		bne	@Failed
 		
 		cmp.b	#1,$D(a6)		;Step 1?
 		bne.s	@Not_1
 		move.l	8(a3),d3
  		move.l	$C(a3),d4
 		adda	d3,a3
 		lea	($80000),a4
@1_WordRam:
 		move.b	(a3)+,(a4)+
 		add.l	#1,d3
 		cmp.l	d4,d3
 		blt.s	@1_WordRam
 		
@Not_1:
 
; -------------------------------------------
 
  		cmp.b	#2,$D(a6)		;Step 2?
  		bne.s	@Not_3
 		move.l	$10(a3),d3
  		move.l	$14(a3),d4
 		adda	d3,a3
 		lea	($80000),a4
@2_WordRam:
 		move.b	(a3)+,(a4)+
 		add.l	#1,d3
 		cmp.l	d4,d3
 		blt.s	@2_WordRam
@Not_3:
 		rts
 
@Failed:
 		move.b	#-1,(a5)
		rts

; -------------------------------------------
; $08 - Return WordRAM to Main
; -------------------------------------------

Cmd_08:
		bset	#0,(ThisCpu+MemoryMode+1)		; Give WordRAM to Main CPU
		rts

; -------------------------------------------
; $10 - Play CD Track, Repeat
; 
; CommDataM:
; $00-$02 - Track
; -------------------------------------------

Cmd_10:
		movea.l	a6,a0
		BIOS_MSCPLAYR
		rts

; -------------------------------------------
; $14 - Stop CD Track
; 
; CommDataM:
; $00-$02 - Track
; -------------------------------------------

Cmd_14:
		BIOS_MSCSTOP
		rts
		
; -------------------------------------------
; $20 - PCM, load sample file from CD, .wav
;       format, auto-converted
; 
; CommDataM:
; $00-$0B - Filename ($C must be $00)
; $0D     - Wave bank to use (input: $01-$0F)
; 
; CommDataS:
; $00     - Next free bank to use
; $02     - Sample length
; -------------------------------------------

Cmd_20:
		lea	(PCM),a4
		move.b	#$FF,OnOff(a4)
		bsr	PCM_Wait

 		lea	(StoredData),a0
 		move.w	#$FFFF,d3
@cln_copy:
 		move.l	#-1,(a0)+
 		dbf	d3,@cln_copy

		movea.l	a6,a0
		bsr	FindFile
		lea	(StoredData),a0
		move.w	#$800,d2
		bsr	ReadSector
		
; ----------------------------------

		lea	(StoredData),a0
		adda 	#$28,a0
		moveq	#0,d2
		move.b	1(a0),d2
		lsl.w	#8,d2
		move.b	(a0),d2
 		sub.w	#1,d2
		and.l	#$FFFF,d2
		move.l	d2,d5
		move.w	d5,2(a5)
		adda 	#4,a0
; 		lea	(PcmToCopy),a1
@Convert:
		move.b	(a0),d4
		bsr	@ConvertWav
		move.b	d4,(a0)+
		dbf	d5,@Convert
		
; ----------------------------------

		lea	(StoredData),a0
		adda	#$2C,a0
		move.l	#$FF2001,d0
		move.b	$D(a6),d1
		and.b	#$F,d1
		bset	#7,d1
		move.b	d1,Ctrl(a4)
		bsr	PCM_Wait
@SendData:
		cmp.l	#$FF4001,d0
		blt.s	@Lower
		move.l	#$FF2001,d0
		add.b	#1,d1
		cmp.b	#$8F,d1
		blt.s	@Lower
		cmp.w	#$FFF,d5
		blt.s	@Lower
		move.w	#$FFF,d5
@Lower:
		move.b	d1,Ctrl(a4)
		bsr	PCM_Wait
		movea.l	d0,a1
		move.b	(a0)+,(a1)
		add.l	#2,d0
		dbf	d2,@SendData

		add.b	#1,d1
		cmp.b	#$8F,d1
		blt.s	@NotLast
		move.b	#$8F,d1
@NotLast:
		move.b	d1,(a5)
	
@Failed_PCM:
		rts

; -------------------------------------------
; Convert WAV data to PCM format
;
; d4 - wav input/pcm output (BYTE)
; -------------------------------------------

@ConvertWav:
		tst.b	d4
		bpl.s	@Plus
		and.w	#$7F,d4
		rts
@Plus:
		move.w	#$80,d3
		sub.b	d4,d3
		move.b	#$80,d4
		add.b	d3,d4
@Cont:
		cmp.b	#$FF,d4
		bne.s	@NoEnd
		move.b	#$FE,d4
@NoEnd:
		rts

; -------------------------------------------
; $21 - PCM, Sample address
;
; CommDataM:
; $00 - Channel ID ($00-$07)
; $01 - Channel data start ST ($00-$0F, auto leftshifted to $x000)
; $02 - Channel loop address ($xxyy)
; -------------------------------------------

Cmd_21:
		lea	(PCM),a4
		
		move	#0,d1
		move.b	(a6),d1
		and.w	#$F,d1
		or.w	#$C0,d1
		move.b	d1,Ctrl(a4)
		bsr	PCM_Wait

		move.b	1(a6),d2
		lsl.w	#4,d2
		move.b	d2,ST(a4)
		bsr	PCM_Wait

		move.w	2(a6),d0
		move.b	d0,LSL(a4)		;Loop address
		bsr	PCM_Wait
		lsr.w	#8,d0
		add.b	d2,d0
		move.b	d0,LSH(a4)
		bsr	PCM_Wait
		
		move.b	d1,Ctrl(a4)
		bra	PCM_Wait

; -------------------------------------------
; $22 - PCM, Set frequency
;
; CommDataM:
; $00 - Channel ID ($00-$07)
; $02 - Frequency value
; -------------------------------------------

Cmd_22:
		lea	(PCM),a4
		
		move.b	(a6),d1
		and.b	#$F,d1
		add.b	#$C0,d1
		move.b	d1,Ctrl(a4)
		bsr	PCM_Wait
		
		move.b	2(a6),FDH(a4)
		bsr	PCM_Wait
		move.b	3(a6),FDL(a4)
		bsr	PCM_Wait
		
		move.b	d1,Ctrl(a4)
		bra	PCM_Wait

; -------------------------------------------
; $23 - PCM, Panning
;
; CommDataM:
; $00 - Channel ID ($00-$07)
; $01 - Panning data
; -------------------------------------------

Cmd_23:
		lea	(PCM),a4
		move.b	(a6),d1
		and.w	#$F,d1
		or.b	#$C0,d1
		move.b	d1,Ctrl(a4)
		bsr	PCM_Wait
		
		move.b	1(a6),d2
		move.b	d2,PAN(a4)		;Panning
		bsr	PCM_Wait
		
		move.b	d1,Ctrl(a4)
		bra	PCM_Wait

; -------------------------------------------
; $24 - PCM, Envelope
;
; CommDataM:
; $00 - Channel ID ($00-$07)
; $01 - Envelope
; -------------------------------------------

Cmd_24:
		lea	(PCM),a4
		move.b	(a6),d1
		and.b	#$F,d1
		or.b	#$C0,d1
		move.b	d1,Ctrl(a4)
		bsr	PCM_Wait

		move.b	1(a6),ENV(a4)
		bsr	PCM_Wait
		
		move.b	d1,Ctrl(a4)
		bra	PCM_Wait
		
; -------------------------------------------
; $25 - PCM. On/Off
;
; CommDataM:
; $00 - Channel On/Off (swapped bits: 0 - Off, 1 - On)
; -------------------------------------------

Cmd_25:
		move.b	(a6),d0
		not.b	d0
		move.b	d0,(PCM+OnOff)
		bra	PCM_Wait

; -------------------------------------------
; $26 - FULLY Clear the PCM chip
; -------------------------------------------

Cmd_26:
 		move.b	#$FF,(PCM+OnOff)
		bsr	PCM_Wait
 		move.b	#$FF,(PCM+PAN)
		bsr	PCM_Wait
		
		lea	(PCM),a0
		move.b	#$80,d3
		moveq	#$F,d5
@Next:
		move.b	d3,Ctrl(a0)
		bsr	PCM_Wait
		lea	($FF2001),a2
		move.w	#$FFF,d0
@loop1:
		move.b	#$FF,(a2)
		addq.l	#2,a2
		dbf	d0,@loop1
		move.b	d3,Ctrl(a0)
		bsr	PCM_Wait
		add.b	#1,d3
		dbf	d5,@Next
		rts
		
; -------------------------------------------
; $30 - Rotation init
; -------------------------------------------

Cmd_30:
		lea	@fs_stampart(pc),a0
		bsr	FindFile
		lea	($80000),a0
		move.w	#$800,d2
		bsr	ReadSector
		
; 		lea	(Map_StampsTest),a0
; 		lea	($80000+$3FE00),a1
; 		moveq	#0,d0
; 		move.w	(a0)+,d0
; @StampMap:
; 		move.w	(a0)+,d1
; 		and	#$1FFF,d1
; 		move.w	d1,(a1)+
; 		dbf	d0,@StampMap
		
		move.w	#%000,($FF8058).l		; Stamp data size: 16x16 dot | 1x1 screen | RPT
		move.w	#(($3FE00)>>2),($FF805A).l	; Stamp map base address
		move.w	#(($38E00)>>2),($FF805E).l	; Image buffer start address
		move.w	#0,($FF8060).l			; Image buffer offset
		move.w	#(((224)>>3)-1),($FF805C).l	; Image buffer V cell size
	
		lea	(StampBuffer),a0
		move.w	#(numof_stamps)-1,d0
@next_stamp:
		move.w	 #$80,word_0(a0)
		move.w	 #0,word_2(a0)
		move.w	 #0,word_4(a0)
		move.w	 #0,word_6(a0)
		move.w	 #0,word_8(a0)
		move.w	 #0,word_A(a0)
		
		adda	#sizeof_stamp,a0
		dbf	d0,@next_stamp	
		rts

@fs_stampart:	dc.b "STAMPART.BIN",0
		even
		
; -------------------------------------------
; $31 - Modify stamp: XY move / scale
;
; CommDataM:
; $00 - Stamp ID
; $02 - X Start
; $04 - Y Start
; $06 - X scale
; $08 - Y scale
; -------------------------------------------

Cmd_31:
; 		lea	(StampBuffer),a0
; 		move.w	(a6),d0
; 		mulu.w	#sizeof_stamp,d0
; 		adda	d0,a0
; 		
; 		move.w	2(a6),d0
;  		lsl.w	#3,d0
; 		neg.w	d0
; 		move.w	d0,stamp_x(a0)
; 		move.w	4(a6),d0
;  		lsl.w	#3,d0
; 		neg.w	d0
; 		move.w	d0,stamp_y(a0)
; 		
; 		move.w	6(a6),d0
;  		lsl.w	#4,d0
; 		add.w	#256*8,d0
; 		swap	d0
; 		move.w	8(a6),d0
;  		lsl.w	#4,d0
; 		add.w	#256*8,d0
; 		move.w	d0,stamp_yd(a0)
; 		swap	d0
; 		move.w	d0,stamp_xd(a0)
		rts
		
; -------------------------------------------
; $34 - Modify stamp: Rotate
;
; CommDataM:
; $00 - Stamp ID
; $02 - X Start
; $04 - Y Start
; $06 - X scale
; $08 - Y scale
; $0A - Rotate
; -------------------------------------------

Cmd_34:
		lea	(StampBuffer),a0
		move.w	(a6),d0
		mulu.w	#sizeof_stamp,d0
		adda	d0,a0

		move.w	2(a6),d0
		neg.w	d0
		move.w	d0,word_2(a0)
		move.w	4(a6),d0
		neg.w	d0
		move.w	d0,word_4(a0)
		
 		move.w	6(a6),d0
 		lsl.w	#1,d0
 		move.w	d0,word_6(a0)
 		move.w	8(a6),d0
 		lsl.w	#1,d0
 		move.w	d0,word_8(a0)
   		move.w	$A(a6),d0
 		lsl.w	#1,d0
 		move.w	d0,word_A(a0)
		rts
		
; 		lea	(StampBuffer),a0
; 		move.w	(a6),d0
; 		mulu.w	#sizeof_stamp,d0
; 		adda	d0,a0
; 		
; 		move.w	2(a6),d0
;  		lsl.w	#3,d0
; 		neg.w	d0
; 		move.w	d0,stamp_x(a0)
; 		move.w	4(a6),d0
;  		lsl.w	#3,d0
; 		neg.w	d0
; 		move.w	d0,stamp_y(a0)
; 		
; 		move.w	6(a6),d0
;  		lsl.w	#4,d0
; 		add.w	#256*8,d0
; 		swap	d0
; 		move.w	8(a6),d0
;  		lsl.w	#4,d0
; 		add.w	#256*8,d0
; 		move.w	d0,stamp_yd(a0)
; 		swap	d0
; 		move.w	d0,stamp_xd(a0)
; 		
; 		move.w	$A(a6),d0
; 		move.w	d0,stamp_rot(a0)	
; 		rts
		
; -------------------------------------------
; $38 - Rotation run
; -------------------------------------------

Cmd_38:
		move.w	 #256,($FF8062).l		; Image buffer H dot size
		move.w	 #224,($FF8064).l		; Image buffer V dot size
		move.w	 #(($38700)>>2),($FF8066).l	; Image trace vector base address
		bclr	#3,($FF8003).l			;
		bclr	#4,($FF8003).l			; Stamp: Write mode (00: Normal 01: Underwrite 10: Overwrite)
		
		lea	(StampBuffer),a4
		lea	($80000+$38700),a1
 		bsr	@ScrewStamp
	
 		rts
; 		
@ScrewStamp:
; 		move.w	 word_1CA0(a6),d0
; 		lsl.w	  #2,d0
; 		movem.w	word_7D02(pc, d0.w), d2/d6

		move.w	#$FF68,d1
		move.w	#$FF98,d2
		
		bsr.w	sub_7E94
		bsr.w	sub_7D22

		move.w	#224-1,d6
@loc_7CF2:
		bsr.w	calculateGfxDivisor
		bsr.w	generateTraceVector
		addq.w	#1,d2
		dbf	d6,@loc_7CF2
		rts
		
; -------------------------------------------

; =============== S U B R O U T I N E =======================================


sub_7D22:
		move.w	word_0(a4),d0
		add.w	word_6(a4),d0
		muls.w	word_22(a4),d0
		move.w	word_4(a4),d3
		muls.w	word_20(a4),d3
		add.l	d3,d0
		asr.l	#8,d0
		move.w	d0,word_30(a4)

		move.w	word_2(a4),d0
		muls.w	word_20(a4),d0
		asr.l	#8,d0
		move.w	d0,word_32(a4)
		
		move.w	word_2(a4), d0
		muls.w	word_22(a4), d0
		asr.l	#8,d0
		move.w	d0,word_34(a4)

		move.w	word_0(a4), d0
		muls.w	word_22(a4), d0
		asr.l  #8, d0
		move.w	d0,word_36(a4)
		
		move.w	word_30(a4), d0
		muls.w	word_26(a4), d0
		asr.l  #8, d0
		move.w	d0,word_38(a4)

		move.w	word_30(a4), d0
		muls.w	word_24(a4), d0
		asr.l  #8, d0
		move.w	d0,word_3C(a4)

		move.w	word_0(a4), d0
		add.w	 word_6(a4), d0
		muls.w	word_24(a4), d0
		move.w	word_32(a4), d3
		muls.w	word_26(a4), d3
		sub.l  d3, d0
		asr.l  #8, d0
		move.w	d0,word_40(a4)

		move.w	word_0(a4), d0
		add.w	 word_6(a4), d0
		muls.w	word_26(a4), d0
		move.w	word_32(a4), d3
		muls.w	word_24(a4), d3
		add.l  d3, d0
		asr.l  #8, d0
		move.w	d0,word_44(a4)

		move.w	word_34(a4), d0
		muls.w	word_26(a4), d0
		move.w	word_4(a4), d3
		muls.w	word_24(a4), d3
		add.l  d3, d0
		asr.l  #8, d0
		muls.w	word_0(a4), d0
		move.l d0,long_48(a4)

		move.w	word_34(a4), d0
		muls.w	word_24(a4), d0
		move.w	word_4(a4), d3
		muls.w	word_26(a4), d3
		sub.l  d3, d0
		asr.l  #8, d0
		muls.w	word_0(a4), d0
		move.l d0,long_4C(a4)

		move.w	word_38(a4), d0
		muls.w	d1, d0
		move.l d0,long_50(a4)

		move.w	word_3C(a4), d0
		muls.w	d1, d0
		move.l d0,long_54(a4)

		move.w	word_38(a4), d0
		ext.l  d0
		asl.l  #8, d0
		move.l d0,long_5C(a4)

		move.w	word_3C(a4), d0
		neg.w	 d0
		ext.l  d0
		asl.l  #8, d0
		move.l d0,long_60(a4)

		rts


; =============== S U B R O U T I N E =======================================


calculateGfxDivisor:
		move.w	word_20(a4),d0
		muls.w	d2,d0
		asr.l	#8,d0

		move.w	word_36(a4),d3
		sub.w	d0,d3
		bne.s	@loc_7E36
		moveq	#1,d3			; Prevent possible divide-by-zero
@loc_7E36:
		move.w	d3,long_5C_div(a4)
		rts


; =============== S U B R O U T I N E =======================================


; Inputs:
;   a1: Address to put trace vector

generateTraceVector:
		move.w	word_40(a4),d0
		muls.w	d2,d0
		add.l	long_50(a4),d0
		add.l	long_48(a4),d0
		divs.w	long_5C_div(a4),d0
		asl.w	#3,d0
		addi.w	#(((256/2)+24)<<3),d0
		move.w	d0,(a1)+			; Write X start position

		move.w	word_44(a4),d0
		muls.w	d2,d0
		sub.l	long_54(a4),d0
		sub.l	long_4C(a4),d0
		divs.w	long_5C_div(a4),d0
		asl.w	#3,d0
    		addi.w	#(((256/2)-16)<<3),d0		; TODO: this defines VERTICAL center
		tst.w	d0
		bpl.s	@on_x
		cmp.w	#256,d0
		blt.s	@on_x
		move.w	#-1,d0
@on_x:
		move.w	d0,(a1)+			; Y pos

		move.l	long_5C(a4),d0
		divs.w	long_5C_div(a4), d0
		asl.w	#3,d0
		move.w	d0,(a1)+			; Write X delta

		move.l	long_60(a4),d0
		divs.w	long_5C_div(a4),d0
		asl.w	#3,d0
		move.w	d0,(a1)+			; Write Y delta
		rts


; =============== S U B R O U T I N E =======================================


sub_7E94:
		andi.w	#$1FF,word_8(a4)
		move.w	word_8(a4),d7
		move.w	d7,d0
		andi.w	#$80,d0
		cmpi.w	#$80,d0
		bne.s	@loc_7EAC
		addq.w	#1,d7
@loc_7EAC:
		move.w	d7, d5
		bsr.s	SineWave
		move.w	d7,word_20(a4)
		move.w	d5,d7
		bsr.s	CosSineWave
		move.w	d7,word_22(a4)

		andi.w	#$1FF,word_A(a4)
		move.w	word_A(a4),d7
		move.w	d7,d0
		andi.w	#$80,d0
		cmpi.w	#$80,d0
		bne.s	@loc_7ED4
		addq.w	#1,d7
@loc_7ED4:
		move.w	d7,d5
		bsr.s	SineWave
		move.w	d7,word_24(a4)
		move.w	d5,d7
		bsr.s	CosSineWave
		move.w	d7,word_26(a4)
		rts
	
; -------------------------------------------

CosSineWave:               ; CODE XREF: sub_7E94+22p sub_7E94+4Ap
	addi.w	 #$80, d7

SineWave:               ; CODE XREF: sub_7E94+1Ap sub_7E94+42p
	move.l  d6, -(sp)

	andi.w	 #$1FF, d7
	move.w	 d7, d6

	btst    #7, d7
	beq.s   @loc_7EFA

	not.w	  d6

@loc_7EFA:
	andi.w	 #$7F, d6
	lsl.w	  #1, d6
	move.w	 word_7F12(pc, d6.w), d6

	btst    #8, d7
	beq.s   @loc_7F0C

	neg.w	  d6

@loc_7F0C:
	move.w	 d6, d7

	move.l  (sp)+, d6
	rts
	
; -------------------------------------------

word_7F12:
		incbin "system/hardware/mcd/s68k/word_7F12.bin"
	
; 		lea	(StampBuffer),a0
; 		lea     ($80000+$38700).l,a1
; 		moveq	#0,d4
; 		moveq	#0,d5
; 		moveq	#0,d6
; 		move.w	stamp_x(a0),d4
; 		move.w	stamp_y(a0),d5			; Ystart
; 		swap	d5
;  		move.w	stamp_yd(a0),d6
;  		lsl.l	#8,d6
;  		move.w	stamp_rot(a0),d3
;  		lsl.l	#3,d3
; 		move.w	#(224)-1,d7
; 		move.w	stamp_xd(a0),d2
; 		swap	d2
; @TraceLoop:
; 		swap	d5
; 		swap	d2
; 		
; 		move.w	d4,d0
; ; 		sub.w	d3,d0
; 		move.w	d0,(a1)+			; X pos
; 
; 
; 		move.w	d5,d0
;   		sub.w	d3,d0
; 		move.w	d0,(a1)+			; Y pos
; 
; 		
; 		move.w	stamp_xd(a0),(a1)+		; X texture
; 		
; 		move.w	d3,d0
;  		add.w	d0,d0
; 		move.w	d0,(a1)+			; Y texture
; 		
; 		swap	d5
;  		add.l	d6,d5
; 		dbf     d7,@TraceLoop
		rts
	
; -------------------------------------------
; $40 - BRAM Init
; -------------------------------------------

Cmd_40:
		lea	(BRAM_Buffer),a0
		lea	(BRAM_Strings),a1
		BIOS_BRMINIT

 		lea	@SaveName(pc),a0
 		BIOS_BRMSERCH
 		bcc.s	@DontInitAgain
		
		lea	@SaveName(pc),a0
		lea	(Save_Data),a1
		BIOS_BRMWRITE
		
@DontInitAgain:
		rts
			
@SaveName:	dc.b "_SAVE_NAME_",0
		dc.w	$0001
		even
		
; =====================================================================
; -------------------------------------------
; Level 2 IRQ
; -------------------------------------------

SP_IRQ:
		clr.b	(VBlankFlag)
		rts

; =====================================================================
; Subs
; =====================================================================

; -------------------------------------------
; PCM_Wait
; -------------------------------------------

PCM_Wait:
		movem.l	d0,-(sp)
		move.w	#6,d0
@WaitLoop:
		dbf	d0,@WaitLoop
		movem.l	(sp)+,d0
		rts  
		
; -------------------------------------------
; ReadSector
; 
; Input:
; a0 - Destination
; d0 - Sector start
; d1 - Number of sectors
; d2 - Destination increment ($0 or $800)
; -------------------------------------------

ReadSector:
		movem.l	d3-d6,-(sp)
		and.w	#$FFFF,d0
		and.w	#$FFFF,d1
		move.l	d0,(BiosArgs)
		move.l	d1,(BiosArgs+4)
		movea.l	a0,a2
		BIOS_CDCSTOP			; Stop disc
		lea	(BiosArgs),a0
		BIOS_ROMREADN			; Start from this sector
@waitSTAT:
 		BIOS_CDCSTAT			; Ready?
 		bcs.s	@waitSTAT
@waitREAD:
		BIOS_CDCREAD			; Read data
		bcc.s	@waitREAD		; If not done, branch
@WaitTransfer:
		movea.l	a2,a0			; Set destination address
		lea	(BiosArgs+$10),a1	; Set head buffer
		BIOS_CDCTRN			; Transfer sector
		bcc.s	@waitTransfer		; If not done, branch
		BIOS_CDCACK			; Acknowledge transfer

		adda	d2,a2

		add.l	#1,(BiosArgs)
		sub.l	#1,(BiosArgs+4)
		bne.s	@waitSTAT
		movem.l	(sp)+,d3-d6
		rts

; -------------------------------------------
;  ISO9660 Driver
; -------------------------------------------

Init9660:
		movem.l	d0-d7/a0-a6,-(a7)
						; Load Volume VolumeDescriptor

		moveq	#$10,d0			; Start Sector
		moveq	#$20,d1			; Size in sector
		lea	(ISO_Files),a0		; Destination
		move.w	#$800,d2
		bsr	ReadSector		; Read Data

						; Load Root Directory
		lea	(ISO_Files),a0		; Get pointer to sector buffer
		lea.l	$9C(a0),a1		; Get root directory record
		
		move.b	6(a1),d0		; Get first part of Sector address
		lsl.l	#8,d0			; bitshift
		move.b	7(a1),d0		; Get next part of sector address
		lsl.l	#8,d0			; bitshift
		move.b	8(a1),d0		; get next part of sector address
		lsl.l	#8,d0			; bitshift
		move.b	9(a1),d0		; get final part of sector address.
						; d0 now contains start sector address
		move.l	#$20, d1		; Size ($20 Sectors)
		move.w	#$800,d2
		bsr	ReadSector
		
		movem.l	(a7)+,d0-d7/a0-a6	; Restore all registers		
		rts
		
; -------------------------------------------
;  Find File (ISO9660)
;  Input:  a0.l - Pointer to filename
;  Output: d0.l - Start sector
;		 d1.l - Number of sectors
;          d2.l - Filesize
; -------------------------------------------

FindFile:
		movem.l	a1/a2/a6,-(a7)

		lea	(ISO_Files),a1		; Get sector buffer
@ReadFilenameStart:
		movea.l	a0,a6			; Store filename pointer
		move.b	(a6)+,d0		; Read character from filename
@findFirstChar:
		movea.l	a1,a2			; Store Sector buffer pointer
		cmp.b	(a1)+,d0		; Compare with first letter of filename and increment
		bne.b	@findFirstChar		; If not matched, branch
@checkChars:
		move.b	(a6)+,d0		; Read next charactor of filename and increment
		beq.s	@getInfo		; If all characters were matched, branch			
		cmp.b	(a1)+,d0		; Else, check next character
		bne.b	@ReadFilenameStart	; If not matched, find next file
		bra.s	@checkChars		; else, check next character
	
@getInfo:
		sub.l	#$21,a2			; Move to beginning of directory entry
		move.b	6(a2),d0		; Get first part of Sector address
		lsl.l	#8,d0			; bitshift
		move.b	7(a2),d0		; Get next part of sector address
		lsl.l	#8,d0			; bitshift
		move.b	8(a2),d0		; get next part of sector address
		lsl.l	#8,d0			; bitshift
		move.b	9(a2),d0		; get final part of sector address.
						; d0 now contains start sector address

		move.b	$E(a2),d1		; Same as above, but for FileSize
		lsl.l	#8,d1
		move.b	$F(a2),d1
		lsl.l	#8,d1
		move.b	$10(a2),d1
		lsl.l	#8,d1
		move.b	$11(a2),d1
		
		move.l	d1,d2
		lsr.l	#8,d1			; Bitshift filesize (to get sector count)
		lsr.l	#3,d1
	
		movem.l	(a7)+,a1/a2/a6		; Restore used registers	
		rts
		
; ; -------------------------------------------
; ; CalcSine
; ;
; ; Input:
; ; d0 | WORD
; ;
; ; Output:
; ; d0 | WORD
; ; d1 | WORD
; ; -------------------------------------------
; 
; CalcSine:
; 		and.w	#$FF,d0
; 		add.w	d0,d0
; 		add.w	#$80,d0
; 		move.w	Sine_Data(pc,d0.w),d1
; 		sub.w	#$80,d0
; 		move.w	Sine_Data(pc,d0.w),d0
; 		rts	
; 
; Sine_Data:
; 		dc.w	0,	6, $C, $12, $19, $1F, $25, $2B,	$31, $38, $3E
; 		dc.w	$44, $4A, $50, $56, $5C, $61, $67,	$6D, $73, $78
; 		dc.w	$7E, $83, $88, $8E, $93, $98, $9D,	$A2, $A7, $AB
; 		dc.w	$B0, $B5, $B9, $BD, $C1, $C5, $C9,	$CD, $D1, $D4
; 		dc.w	$D8, $DB, $DE, $E1, $E4, $E7, $EA,	$EC, $EE, $F1
; 		dc.w	$F3, $F4, $F6, $F8, $F9, $FB, $FC,	$FD, $FE, $FE
; 		dc.w	$FF, $FF, $FF, $100, $FF, $FF, $FF, $FE, $FE, $FD
; 		dc.w	$FC, $FB, $F9, $F8, $F6, $F4, $F3,	$F1, $EE, $EC
; 		dc.w	$EA, $E7, $E4, $E1, $DE, $DB, $D8,	$D4, $D1, $CD
; 		dc.w	$C9, $C5, $C1, $BD, $B9, $B5, $B0,	$AB, $A7, $A2
; 		dc.w	$9D, $98, $93, $8E, $88, $83, $7E,	$78, $73, $6D
; 		dc.w	$67, $61, $5C, $56, $50, $4A, $44,	$3E, $38, $31
; 		dc.w	$2B, $25, $1F, $19, $12, $C, 6, 0,	-6, -$C, -$12
; 		dc.w	-$19, -$1F, -$25, -$2B, -$31, -$38, -$3E, -$44, -$4A
; 		dc.w	-$50, -$56, -$5C, -$61, -$67, -$6D, -$75, -$78, -$7E
; 		dc.w	-$83, -$88, -$8E, -$93, -$98, -$9D, -$A2, -$A7, -$AB
; 		dc.w	-$B0, -$B5, -$B9, -$BD, -$C1, -$C5, -$C9, -$CD, -$D1
; 		dc.w	-$D4, -$D8, -$DB, -$DE, -$E1, -$E4, -$E7, -$EA, -$EC
; 		dc.w	-$EE, -$F1, -$F3, -$F4, -$F6, -$F8, -$F9, -$FB, -$FC
; 		dc.w	-$FD, -$FE, -$FE, -$FF, -$FF, -$FF, -$100,	-$FF, -$FF
; 		dc.w	-$FF, -$FE, -$FE, -$FD, -$FC, -$FB, -$F9, -$F8, -$F6
; 		dc.w	-$F4, -$F3, -$F1, -$EE, -$EC, -$EA, -$E7, -$E4, -$E1
; 		dc.w	-$DE, -$DB, -$D8, -$D4, -$D1, -$CD, -$C9, -$C5, -$C1
; 		dc.w	-$BD, -$B9, -$B5, -$B0, -$AB, -$A7, -$A2, -$9D, -$98
; 		dc.w	-$93, -$8E, -$88, -$83, -$7E, -$78, -$75, -$6D, -$67
; 		dc.w	-$61, -$5C, -$56, -$50, -$4A, -$44, -$3E, -$38, -$31
; 		dc.w	-$2B, -$25, -$1F, -$19, -$12, -$C,	-6, 0, 6, $C, $12
; 		dc.w	$19, $1F, $25, $2B, $31, $38, $3E,	$44, $4A, $50
; 		dc.w	$56, $5C, $61, $67, $6D, $73, $78,	$7E, $83, $88
; 		dc.w	$8E, $93, $98, $9D, $A2, $A7, $AB,	$B0, $B5, $B9
; 		dc.w	$BD, $C1, $C5, $C9, $CD, $D1, $D4,	$D8, $DB, $DE
; 		dc.w	$E1, $E4, $E7, $EA, $EC, $EE, $F1,	$F3, $F4, $F6
; 		dc.w	$F8, $F9, $FB, $FC, $FD, $FE, $FE,	$FF, $FF, $FF
; 		even
		
; =====================================================================

; Map_StampsTest:	dc.w	((@End-Map_StampsTest)/2)
; 		incbin	"engine/misc/stamptest/map.bin"
; @End:
; 		even
		
		objend
