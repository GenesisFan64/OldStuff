; ================================================================
; SMEG Karasucia
; Sound and Music Engine for Genesis (also MCD* and 32X**)
;
; (C)2013-2017 GF64
; 
; Reads patterns from a ImpulseTracker file (.it)
;
; Ticks:
; 150 - NTSC
; 120 - PAL
;
; uses assembler settings:
; MCD     - for building to MCD (All the driver must be aligned
;              to WordRAM or PRG-RAM)
; MARS       - for building to 32x (CODE and
;              DATA(Music/Sfx/Voices/Z80 samples) must be aligned to
;              the 32x standards, uses bank 0 only,
;              PWM Samples can be anywhere in ROM)
; SMEG_Z80   - Use Z80, set to 0 while running from PRGRAM
;                 
; Limtations:
; (Driver) - Effects: only volume and panning (Xxx) works
; 
; (MCD) - You cant use Z80 samples if your program is running
;            on PRG-RAM (Z80 cant access RAM), if your program is
;            running on WORD-RAM, set the permission to
;            MainCPU (2M Mode) (not recommended)
;            
; * requires respective SubCPU code
; ** requires respective SH2 code
; ================================================================

;NOTE: Format
; SONGFILE:
; 		dc.b 12,0		; Numof_blocks, loop_block (-1 dont loop)
; 		dc.l @pattern		; Pattern data
;      		dc.l @instruments	; Instrument set
;      		dc.w 8			; Number of channel settings
;       	dc.b FM_6,64,$80,$0F	; Example of one (Channel,Vol,Pan,Extra)		
;		...
;
; Extra:
; FM: %????KEYS KEYS: FM Keys (ignored if not FM)
; PSG: (not yet)
; PCM/PWM: not yet
; 
; @instruments:
; 		dc.w @ymha-@instruments
; 		dc.w @psg-@instruments
; 		dc.w @noise-@instruments
; 		dc.w @psmpl-@instruments
; 		even
; @ymha:
; 		;FM
; 		dc.w INSTNUM,0
; 		dc.l fmVoice_bass_ambient
;    		
;    		;FM3
;    		dc.w $40|INSTNUM,0
;    		dc.l fm_hatopen
;    		dc.w $0511|$2000,$0328|$2000
;    		dc.w $005E|$2000,$0328|$2000
;    		
;    		;Samples
;   		dc.w $80|INSTNUM,12	; NUM,Pitch
;   		dc.l wav_kick		; WAV Start
;  		dc.l wav_kick_e		; WAV End
;  		dc.l -1			; WAV Loop sample (0: start -1: none)
;  		
; 		dc.w -1			; ENDOFLIST
; 		even
; @psmpl:
; 		dc.w -1			; Later
; 		even
; @psg:
; 		dc.w -1			; Later
; 		even
; @noise:
;  		dc.w 3,%101		; INSTNUM, PSG Noise setting
;  		
;  		dc.w 5,%101
;  		dc.w 7,%100
;  		
; 		dc.w -1
; 		even


; GEMS style tick
; 		dc.l fmSfx_Coin
; 		dc.w $00AB|$3800,$0457|$3000
; 		dc.w $0511|$3000,$0336|$2000
;
;    		dc.l fm_hatopen
;    		dc.w $0511|$2000,$0328|$2000
;    		dc.w $005E|$2000,$0328|$2000
;
;    		dc.l fm_hatclosed
;    		dc.w $051C|$2000,$0328|$2000
;    		dc.w $005E|$2000,$0328|$2000
;
;    		dc.l fm_hatclosed
;    		dc.w $051C|$2000,$0328|$2000
;    		dc.w $005E|$2000,$0328|$2000	

; ================================================================

			rsreset
DrvStatus		rs.b 1		;Byte
snd_flags		rs.b 1		;Byte
PatternEnd		rs.b 1		;Byte
PatternLoop		rs.b 1		;Byte
SongRequest		rs.l 1 		;Long
SongStart		rs.l 1		;Long
SongRead		rs.l 1		;Long
snd_instr		rs.l 1		;Long
SongPcmSamp		rs.l 1		;Long
TicksRequest		rs.w 1		;Word
TicksRead		rs.w 1		;Word
TicksSet		rs.w 1		;Word
TempoRead 		rs.w 1		;Word
PattSize		rs.w 1		;Word
pattr_read		rs.w 1		;Word
CdOnlyFlags		rs.w 1		;Word
CurrPattern		rs.b 1		;Byte
PcmChnOnOff		rs.b 1		;Byte
PsgLast			rs.b 1		;Byte
snd_flagsBGM		rs.b 1		;Byte
LastPattChn		rs.b 1		;Byte
Psg_Vibrato		rs.b 1		;Byte
Psg_AutoVol		rs.b 1		;Byte
sizeof_SndBuff		rs.l 0

; --------------------------------------------
; Channel settings
; --------------------------------------------

			rsreset
Chn_Freq		rs.w 1		;Word
Chn_Effect		rs.w 1		;Word
Chn_Portam		rs.w 1		;Word
Chn_Type		rs.b 1		;Byte
Chn_ID			rs.b 1		;Byte
Chn_Inst		rs.b 1		;Byte
Chn_Vol			rs.b 1		;Byte
Chn_MainVol		rs.b 1		;Byte
Chn_Note		rs.b 1		;Byte
Chn_Pan			rs.b 1		;Byte
Chn_FM_Key		rs.b 1		;Byte
Chn_PCM_Pitch		rs.b 1		;Byte
; Chn_PSG_Vibrato		rs.b 1		;Byte
Chn_Timer		rs.b 1
sizeof_Chn		rs.l 0
 
 
			rsreset
instDYmha		rs.w 1
instDPsg		rs.w 1
instDNoise		rs.w 1
instDpsmpl		rs.w 1

; --------------------------------------------
; Bits
; --------------------------------------------

bitPriority		equ	0
bitSfxOn		equ	1
bitEnabled		equ	2

;Status
bitFmDac		equ	0
bitDacNote		equ	1
bitTone3		equ	2
bitSpecial3		equ	3

; --------------------------------------------
; Channel IDs
; --------------------------------------------

FM_1			equ	$00
FM_2			equ	$01
FM_3			equ	$02
FM_4			equ	$04
FM_5			equ	$05
FM_6			equ	$06
PSG_1			equ	$80
PSG_2			equ	$A0
PSG_3			equ	$C0
NOISE			equ	$E0
PCM_1			equ	$10
PCM_2			equ	$11
PCM_3			equ	$12
PCM_4			equ	$13
PCM_5			equ	$14
PCM_6			equ	$15
PCM_7			equ	$16
PCM_8			equ	$17
max_chnl		equ	18

; --------------------------------------------
; .IT request ($80+) format
; --------------------------------------------

bitNote			equ	0
bitInst			equ	1
bitVolume		equ	2
bitEffect		equ	3
bitSameNote		equ	4
bitSameInst		equ	5
bitSameVol		equ	6
bitSameEffect		equ	7

; --------------------------------------------
; RAM
; 
; MAX: $400
; --------------------------------------------

			rsset RAM_Audio
RAM_SMEG_Buffer		rs.b sizeof_SndBuff
RAM_SMEG_SfxBuff	rs.b sizeof_SndBuff
RAM_SMEG_PrioList	rs.b max_chnl
RAM_SMEG_Chnls_BGM	rs.b $10*max_chnl
RAM_SMEG_Chnls_SFX	rs.b $10*max_chnl
			if MCD
RAM_SMEG_PcmList	rs.l 64
			endif
			
sizeof_SMEG		rs.l 0
;      			inform 0,"SMEG Uses: %h",sizeof_SMEG-RAM_Audio
			
; ================================================================
; -------------------------------------------
; Macros
; -------------------------------------------

; -----------------------------------------

PCM_Entry	macro	cd_side,mars_side,loop,pitch
		
cdsize_size	= strlen(\cd_side)

		if MCD
		  if cdsize_size>$C
		    inform 2,"(SMEG) CD FILENAME TOO LONG"
		  elseif cdsize_size=$C
		    dc.b \cd_side
		  elseif cdsize_size<$C
		    dc.b \cd_side
		    rept $C-cdsize_size
		      dc.b 0
		    endr
		  elseif cdsize_size<=0
		    inform 2,"(SMEG) YOU FORGOT THE CD FILENAME"
		  endif
		  
		elseif MARS
		  dc.l mars_side
		endif
		
		dc.w loop
		dc.w pitch
		endm

; 		inform 0,"%h",RAM_SMEG_Buffer

; ================================================================
; -------------------------------------------
; External Calls
; -------------------------------------------

;SegaPCM
CdTask_LoadPcm		equ	$20
CdTask_SetAddr		equ	$21
CdTask_SetFreq		equ	$22
CdTask_SetPan		equ	$23
CdTask_SetEnv		equ	$24
CdTask_SetOnOff		equ	$25
CdTask_ClearAllPcm	equ	$26

;MARS
marscall_Play		equ	1
marscall_Stop		equ	2
marscall_SetSmpl	equ	3
marscall_SetVol		equ	4
marscall_SetEntry	equ	5
	
; ================================================================
; -------------------------------------------
; Init
; -------------------------------------------

Audio_Init:
		lea	(RAM_SMEG_Buffer),a0
		move.w	#$2FF,d0
@ClrAll:
		clr.l	(a0)+
		dbf	d0,@ClrAll
		
; -------------------------------------------
; Z80
; -------------------------------------------

SMEG_Z80_Init:
		move.w	#$100,($A11100).l
		move.w	#$100,($A11200).l
@WaitZ80:
		btst	#0,($A11100).l
		bne.s	@WaitZ80

		lea	($A00000).l,a0
		move.w	#$1FFF,d0
@cleanup:
		clr.b	(a0)+
		dbf	d0,@cleanup
		
		lea	Z80_Driver(pc),a0
		lea	($A00000).l,a1
		move.w	#Z80_DriverEnd-Z80_Driver,d1
@ToZ80:
		move.b	(a0)+,(a1)+
		dbf	d1,@ToZ80

; -----------------------------------

		move.w	#0,($A11200).l
		nop
		nop
		nop
		nop
		move.w	#$100,($A11200).l
		move.w	#0,($A11100).l
; 		rts
		
; -------------------------------------------
; Stop ALL Sound
; -------------------------------------------

SMEG_StopSnd:
		move.b	#$2B,d0
		move.b	#$00,d1
		bsr	SMEG_Z80_Off
		bsr	FM_RegWrite_1
		bsr	SMEG_Z80_On
		bsr	Audio_Sample_Stop
		
		lea	(RAM_SMEG_Buffer),a6
		bclr	#bitEnabled,(a6)
	
		bsr	SMEG_FM_Reset
 		bsr	SMEG_PSG_Reset
		bra	SMEG_PCM_Reset
		
; -------------------------------------------
; Play Song
; -------------------------------------------

SMEG_PlaySong:
		lea	(RAM_SMEG_Buffer),a6
		bset	#bitEnabled,(a6)
		rts
		
; -------------------------------------------
; Load Song
;
; d0 - StartOfSong
; d1 - Ticks
; d2 - Type (0 - song, 1 - sfx)
; -------------------------------------------

Audio_Track_Play:
		tst.w	d2
		bne.s	@Sfx
		
		move.l	d0,(RAM_SMEG_Buffer+SongRequest)
		move.w	d1,(RAM_SMEG_Buffer+TicksRequest)
		rts
@Sfx:
; 		clr.w	(RAM_SMEG_SfxBuff+pattr_read)
; 		clr.w	(RAM_SMEG_SfxBuff+CurrPattern)
; 		move.l	(RAM_SMEG_SfxBuff+SongStart),(RAM_SMEG_SfxBuff+SongRead)
; 		cmp.l	(RAM_SMEG_SfxBuff+SongRequest),d0
; 		bne.s	@SameSfx
		
		move.l	d0,(RAM_SMEG_SfxBuff+SongRequest)
		move.w	d1,(RAM_SMEG_SfxBuff+TicksRequest)
@SameSfx:
		rts
		
; ================================================================
; -------------------------------------------
; Run
; -------------------------------------------

Audio_Run:
		lea	(RAM_SMEG_Buffer),a6
		bsr	@RequestSong
		bclr	#bitPriority,(a6)
                bsr	@ReadRow

  		lea	(RAM_SMEG_SfxBuff),a6
 		bsr	@RequestSfx
		bset	#bitPriority,(a6)
		bsr	@ReadRow
		
; -------------------------
; MARS ONLY
; Transfer 68k RAM using
; framebuffer (offside)
; -------------------------

; @marsturn:
; 		btst	#7,(marsreg)	
; 		bne.s	@busymars
; 		
; 		bchg	#0,($A1518B)
; @waitfb:	btst	#1,($A1518B)
; 		bne.s	@waitfb
; 		lea	(RAM_SMEG_Chnls_BGM),a0
; 		lea	(framebuffer+$14000),a1
; 		move.w	#$10*max_chnl,d0
; @copytomars:	
; 		move.b	(a0)+,(a1)+
; 		dbf	d0,@copytomars
; 		bchg	#0,($A1518B)
; @busymars:

; -------------------------

@Wait:
		rts

; -------------------------------------------
; Request song
; -------------------------------------------
	
@RequestSong:
		tst.l	SongRequest(a6)
		beq.s	@Same
		bclr	#bitEnabled,(a6)
 		bsr	SMEG_StopSnd			;d0-d1 are gone
 		tst.l	SongRequest(a6)
 		bmi.s	@Same
 		
		clr.b	CurrPattern(a6)
		clr.b	PatternEnd(a6)
		clr.w	PattSize(a6)
		clr.w	pattr_read(a6)
		lea	(RAM_SMEG_Chnls_BGM),a5
		clr.b	PcmChnOnOff(a6)
                clr.b	DrvStatus(a6)
		bsr	SMEG_Load_SetChnls
 		bsr	SMEG_Load_SetExtChnls
		bset	#bitEnabled,(a6)

		clr.w	TicksRequest(a6)
		clr.l	SongRequest(a6)
@Same:
		rts
		
; -------------------------------------------
; Request sfx
; -------------------------------------------

@RequestSfx:
		tst.l	SongRequest(a6)
		beq.s	@Same
		bmi.s	@Same
		
		bclr	#bitEnabled,(a6)
		clr.b	CurrPattern(a6)
		clr.b	PatternEnd(a6)
		clr.w	PattSize(a6)
		clr.w	pattr_read(a6)
		
		clr.b	PcmChnOnOff(a6)
                clr.b	DrvStatus(a6)
;                 bset	#bitSfxOn,(a6)
		lea	(RAM_SMEG_Chnls_SFX),a5
		bsr	SMEG_Load_SetChnls
		bsr	SMEG_Load_FixSfx
		bset	#bitEnabled,(a6)
		
		clr.w	TicksRequest(a6)
		clr.l	SongRequest(a6)
		rts
		
; -------------------------------------------
; Read row
; -------------------------------------------

@ReadRow:
		btst	#bitEnabled,(a6)
		beq	@Wait

		sub.w	#1,TicksRead(a6)
		bpl	@Wait
 		move.w	TicksSet(a6),TicksRead(a6)

@NewRow:
                movea.l	SongRead(a6),a4

; --------------------------------
; New pattern
; --------------------------------

@Next:
		moveq	#0,d5
		moveq	#0,d6
 		move.w	PattSize(a6),d6
  		sub.w	#1,d6
  		move.w	pattr_read(a6),d5
 		cmp.l	d5,d6
 		bcc.s	@NoNextRow
 		
		clr.w	pattr_read(a6)
		moveq	#0,d5
		moveq	#0,d6
		move.b	PatternEnd(a6),d6
		move.b	CurrPattern(a6),d5
		cmp.w	d5,d6
		bgt.s	@NotEnd
		
		cmp.b	#-1,PatternLoop(a6)
		beq.s	@exit
		
		movea.l	SongStart(a6),a4
		move.b	(a4)+,PattSize+1(a6)
 		move.b	(a4)+,PattSize(a6)
 		adda	#6,a4
		move.l	a4,SongRead(a6)
		move.b	PatternLoop(a6),CurrPattern(a6)
		clr.w	TicksRead(a6)
		rts
		
@exit:
		bclr	#bitEnabled,(a6)
		rts

; --------------------------------

@NotEnd:
		add.b	#1,CurrPattern(a6)
		moveq	#0,d0
		move.b	CurrPattern(a6),d0
		cmp.b	PatternLoop(a6),d0
		bne.s	@DontSaveLoop
		move.l	a4,SongStart(a6)
@DontSaveLoop:
		moveq	#0,d1
		move.b	(a4)+,d1
		move.b	(a4)+,d2
		lsl.w	#8,d2
		or	d2,d1
		move.w	d1,PattSize(a6)
		adda	#6,a4
		
; --------------------------------
; Current pattern
; --------------------------------

@NoNextRow:
		moveq	#0,d6
		moveq	#0,d0
		move.b	(a4)+,d0

		tst.w	d0
		bne.s	@ValidNote

		add.w	#1,pattr_read(a6)
		move.l	a4,SongRead(a6)
		rts

@ValidNote:
		tst.b	d0
		bpl.s	@Not80
		add.w	#1,pattr_read(a6)
		bclr	#7,d0
		move.b	(a4)+,d6
@Not80:
		add.w	#1,pattr_read(a6)
		sub.w	#1,d0
		move.b	d0,LastPattChn(a6)

		lea 	(RAM_SMEG_Chnls_BGM),a5
		btst 	#bitPriority,(a6)
		beq.s	@MusicPrio
		lea 	(RAM_SMEG_Chnls_SFX),a5	
@MusicPrio:
		mulu.w	#sizeof_Chn,d0
		adda	d0,a5
		
		tst.w	d6
		beq.s	@NotRest
		move.b	d6,Chn_Type(a5)
@NotRest:

; SFX: Mark used channel

		btst 	#bitPriority,(a6)
		beq.s	@MusicPrio2
		bsr	SMEG_FindPrioSlot
  		move.b	#1,(a3)
@MusicPrio2:
 
; -------------
; Note
; -------------

		btst	#bitSameNote,Chn_Type(a5)
		bne.s	@PlayOnly
		btst	#bitNote,Chn_Type(a5)
		beq.s	@NoNote

		clr.w	Chn_Portam(a5)
                move.b	(a4)+,Chn_Note(a5)
		add.w	#1,pattr_read(a6)

@PlayOnly:
; 		bsr	SMEG_ChannelRest

@NoNote:

; -------------
; Instrument
; -------------

 		btst	#bitSameInst,Chn_Type(a5)
		bne.s	@SameInst
		btst	#bitInst,Chn_Type(a5)
		beq.s	@NoInst

		move.b	(a4)+,Chn_Inst(a5)
		add.w	#1,pattr_read(a6)

@SameInst:
		bsr	SMEG_SetVoice
@NoInst:

; -------------
; Volume
; -------------

 		btst	#bitSameVol,Chn_Type(a5)
 		bne.s	@SameVol
		btst	#bitVolume,Chn_Type(a5)
		beq.s	@NoVolume

		moveq 	#0,d0
		move.b 	(a4)+,d0
		move.b	d0,chn_vol(a5)
		add.w 	#1,pattr_read(a6)
@NoVolume:
@SameVol:
 		bsr	@ChnVolume
 		
; -------------
; Effect
; -------------

 		btst	#bitSameEffect,Chn_Type(a5)
 		bne.s	@SameEffect
		btst	#bitEffect,Chn_Type(a5)
		beq.s	@NoEffect

		move.b	(a4)+,Chn_Effect(a5)
		add.w	#1,pattr_read(a6)
		move.b	(a4)+,Chn_Effect+1(a5)
		add.w	#1,pattr_read(a6)
@SameEffect:
		bsr	@ChannelEffects
@NoEffect:

; --------------
; Play the note
; --------------

 		btst	#bitSameNote,Chn_Type(a5)
 		bne.s	@SameNote
		btst	#bitNote,Chn_Type(a5)
		beq	@Next
@SameNote:
		bsr	@ChannelPlay
		bra	@Next

; ================================================================
; -------------------------------
; PCM Frequencies
; -------------------------------

		if MCD
@Notes_PCM:
 		dc.w     0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0	;0
 		dc.w     0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0	;1
		dc.w     0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0	;2
		dc.w $00F6,$0104,$0113,$0124,$0135,$0148,$015B,$0170,$0186,$019D,$01B5,$01D0	;3
		dc.w $01EB,$0208,$0228,$0248,$026B,$0291,$02B8,$02E1,$030E,$033C,$036E,$03A3	;4 16000hz
		dc.w $03DA,$0415,$0454,$0497,$04DD,$0528,$0578,$05CB,$0625,$0684,$06E8,$0753	;5
		dc.w $07C4,$083B,$08B0,$093D,$09C7,$0A60,$0AF8,$0BA8,$0C55,$0D10,$0DE2,$0EBE	;6
		dc.w $0FA4,$107A,$1186,$1280,$1396,$14CC,$1624,$1746,$18DE,$1A38,$1BE0,$1D94	;7
		dc.w $1F65,$20FF,$2330,$2526,$2753,$29B7,$2C63,$2F63,$31E0,$347B,$377B,$3B41	;8
		dc.w $3EE8,$4206,$4684,$4A5A,$4EB5,$5379,$58E1,$5DE0,$63C0,$68FF,$6EFF,$783C	;9
		dc.w $7FC2,$83FC,$8D14,$9780,$9D80,$AA5D,$B1F9,$BBBA,$CC77,$D751,$E333,$F0B5
		dc.w     0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0
		even
		
		endif
		
; ================================================================
; -------------------------------
; Set Volume
; -------------------------------

@ChnVolume:
		cmp.b	#-1,Chn_ID(a5)
		beq	@Return

		btst	#bitPriority,(a6)
		bne.s	@SFX_ModeV
		bsr	SMEG_FindPrioSlot
  		tst.b	(a3)
  		bne	@Return
@SFX_ModeV:

		tst.b	Chn_ID(a5)
		bmi	@ChnVol_PSG
		cmp.b	#PCM_1,Chn_ID(a5)
		bge	@ChnVol_PCM
		
		cmp.b	#FM_6,Chn_ID(a5)
		bne.s	@NotSmplChk
		btst	#bitFmDac,snd_flags(a6)
		bne	@Return
@NotSmplChk:

; -------------------------------
; FM Volume
; -------------------------------

		bsr	ChnlFM_srchIns
		move.l	#$7F7F7F7F,d1
		cmp.w	#-1,d2
		beq	@ForceOff
 		btst	#7,d2
 		bne	@ForceOff
 		
;  		cmp.b	#64,chn_vol(a5)
;  		bge	@Return
	
 		adda.w	#4,a3
		movea.l	(a3),a3
  		adda	#$15,a3
		
		move.l	#$4C444840,d0
 		moveq	#0,d1
 		moveq	#0,d2
 		moveq	#0,d3
 		move.b	chn_id(a5),d3
 		and.w	#%11,d3

 		;TODO: checar bien los TL
 		move.b	3(a3),d1
 		move.b	chn_vol(a5),d2
 		sub.b	#64,d2
 		sub.b	d2,d1
 		lsl.l	#8,d1
 		
 		move.b	2(a3),d1
 		move.b	chn_vol(a5),d2
 		sub.b	#64,d2
 		sub.b	d2,d1
  		lsl.l	#8,d1
  		
 		move.b	1(a3),d1
 		move.b	chn_vol(a5),d2
 		sub.b	#64,d2
 		sub.b	d2,d1
  		lsl.l	#8,d1
  		
 		move.b	(a3),d1
 		move.b	chn_vol(a5),d2
 		sub.b	#64,d2
 		sub.b	d2,d1

@ForceOff:
 		bsr	SMEG_Z80_OFF
;  		or.b	d3,d0
;  		bsr	SMEG_FM_FindWrite	;oops.
 		lsr.l	#8,d0
 		lsr.l	#8,d1
 		or.b	d3,d0
  		bsr	SMEG_FM_FindWrite
 		lsr.l	#8,d0
 		lsr.l	#8,d1
;  		or.b	d3,d0
;   		bsr	SMEG_FM_FindWrite
 		lsr.l	#8,d0
 		lsr.l	#8,d1
 		or.b	d3,d0
 		bsr	SMEG_FM_FindWrite
 		bra	SMEG_Z80_On
 	
; -------------------------------
; PSG Volume
; -------------------------------

@ChnVol_PSG:
		move.b	Chn_ID(a5),d3
		or.w	#$1F,d3
		move.b	chn_note(a5),d0
		cmp.b	#-2,d0
		beq	ChnPsg_Rest
		cmp.b	#-1,d0
		beq	ChnPsg_Rest
		bra	ChnPsg_SetVol
@Return:
		rts

; -------------------------------
; PCM Volume
; -------------------------------

@ChnVol_PCM:
		if MCD
		
 		moveq	#0,d2
 		moveq	#0,d1
 		move.b	#$FF,d2				;$xx00
;     		move.b	Chn_MainVol(a5),d1
;       	lsr.w	#4,d1
;      		lsl.w	#4,d1
;    		sub.b	d1,d2
    		move.b	Chn_Vol(a5),d1
      		lsr.w	#4,d1
     		lsl.w	#4,d1
    		sub.b	d1,d2
   		
 		moveq	#0,d1
 		move.b	Chn_ID(a5),d1
 		and.w	#$F,d1
 		move.b	d1,($A12000+CommDataM)
 		move.b	d2,($A12000+CommDataM+1)
 		moveq	#CdTask_SetEnv,d0
 		bsr	SMEG_CD_Call

 		elseif MARS
   		
 		move.b	Chn_Vol(a5),d2
  		lsr.w	#3,d2
;  		and.w	#%11111110,d2
;  		moveq	#0,d1
;     		move.b	Chn_MainVol(a5),d1
;       	lsr.w	#4,d1
;      		lsl.w	#4,d1
;    		sub.b	d1,d2
;     		move.b	Chn_Vol(a5),d1
;       		lsr.w	#4,d1
;     		sub.b	d1,d2
    		
    		moveq	#0,d1
    		move.b	Chn_ID(a5),d1
    		and.w	#$F,d1
    		move.b	d1,(marsreg+comm2)
   		move.b	d2,(marsreg+comm2+1)
  		moveq 	#marscall_SetVol,d0
  		bsr	SMEG_MARS_Call
 		
		endif
		rts
		
; ================================================================
; -------------------------------
; Channel effect
; -------------------------------

@ChannelEffects:
		cmp.b	#-1,Chn_ID(a5)
		beq	@Null
; 		btst 	#bitPriority,(a6)
; 		bne.s	@SFX_Eff
; 		bsr	SMEG_FindPrioSlot
;   		tst.b	(a3)
;   		bne	@Return
; @SFX_Eff:

		moveq	#0,d0
		move.b	Chn_Effect(a5),d0
		add.w	d0,d0
		move.w	@EffectList(pc,d0.w),d1
		jmp	@EffectList(pc,d1.w)
		
; -------------------------------

@EffectList:	dc.w	@Null-@EffectList
		dc.w	@Flag_A-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Flag_D-@EffectList
		dc.w	@Flag_E-@EffectList
		dc.w	@Flag_F-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Flag_M-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Flag_X-@EffectList
		dc.w	@Null-@EffectList
		dc.w	@Flag_Z-@EffectList
		even

; -------------------------------
; Null effect
; -------------------------------

@Null:
		rts

; -------------------------------
; Flag A - Set Tick rate
; -------------------------------

@Flag_A:
		moveq	#0,d0
		clr.w	TicksSet(a6)
		move.b	Chn_Effect+1(a5),d0
		sub.w	#1,d0
		move.b	d0,TicksSet+1(a6)
		rts

; -------------------------------
; Flag D - Volume slide
; -------------------------------

@Flag_D:
 rts
; 		moveq	#0,d0
; 		moveq	#0,d1
; 		move.b	Chn_Effect+1(a5),d0
; 		tst.b	Chn_ID(a5)
; 		bpl	@NotPSG
; 		lsl.w	#4,d0
; @NotPSG:
; 		move.b	Chn_Vol(a5),d1
; 		add.b	d0,d1
; 		move.b	d1,Chn_Vol(a5)
; 		bra	@ChnVolume

; -------------------------------
; Flag E - Portametro down
; -------------------------------

@Flag_E:
		moveq	#0,d0
		move.b	Chn_Effect+1(a5),d0
		add.w	#1,d0
		neg.w	d0
		bra.s	@DoPortam

; -------------------------------
; Flag F - Portametro up
; -------------------------------

@Flag_F:
		moveq	#0,d0
		move.b	Chn_Effect+1(a5),d0
		add.w	#1,d0
		
; ---------------------

@DoPortam:
		move.w	Chn_Portam(a5),d4
		tst.w	d4
		beq	@return
		
		tst.b	Chn_ID(a5)
		bmi.s	@psg_mode
		cmp.b	#PCM_1,Chn_ID(a5)
		bge.s	@pcm_mode
		
		lsl.w	#2,d0
		add.w	d0,d4
		move.w	d4,Chn_Portam(a5)
		bra	SMEG_SetFreqFM
		
@psg_mode:
		add.w	d0,d0
		sub.w	d0,d4
		move.w	d4,Chn_Portam(a5)
		move.w	d4,d0
		move.b	Chn_ID(a5),d1
		bra	ChnPsg_NoteFreq
		
@pcm_mode:
		rts
		
; -------------------------------
; Flag M - Set Channel Volume
; -------------------------------

@Flag_M:
 rts
 
; 		moveq	#0,d0
; 		move.b	Chn_Effect+1(a5),d0
; 	;	tst.b	Chn_ID(a5)
; 	;	bpl	@NotPSG_H
; 
; 		neg.w	d0
; 		sub.w	#$D0,d0
; ;@NotPSG_H:
; 		move.b	d0,Chn_MainVol(a5)
; 		bra	@ChnVolume

; -------------------------------
; Flag X - Stereo
; -------------------------------

@Flag_X:
; 		tst.b	Chn_ID(a5)
; 		bmi	@Null
; 		cmp.b	#PCM_1,Chn_ID(a5)
; 		bge	@PCM_Pan
		
		move.b	Chn_Effect+1(a5),Chn_Pan(a5)
		rts
		
; 		moveq	#0,d0
; 		move.w	#$C0,d0
;                 cmp.b	#$80,Chn_Effect+1(a5)
;                 beq.s	@SetPan
; 		tst.b	Chn_Effect+1(a5)
; 		bmi.s	@Right
; 		bpl.s	@Left
; @SetPan:
; 		move.b	d0,Chn_Pan(a5)
; 		rts
; @Left:
; 		move.w	#$80,d0
; 		bra.s	@SetPan
; @Right:
; 		move.w	#$40,d0
; 		bra.s	@SetPan

; ; -------------------------------
; ; PCM Panning
; ; -------------------------------
; 
; @PCM_Pan:
; 		if MCD
; 		
; 		moveq	#0,d0
; 		move.b	#%11001100,d0				;TODO: dejarlo así
; 		cmp.b	#$80,Chn_Effect+1(a5)
; 		beq.s	@Return2
;                  
;  		tst.b	Chn_Effect+1(a5)
;  		bmi.s	@Right2
; 		bpl.s	@Left2
; 		bra	@Return2
; @Right2:
;  		move.b	#%10000000,d0
;  		bra	@Return2
; @Left2:
; 		move.b	#%00001000,d0
; @Return2:
; 		move.b	d0,Chn_Pan(a5)
; 
; ; -------------------------------------------------
; 
;  		elseif MARS
;  
; 		move.w	#%11000000,d0
; 		cmp.b	#$80,Chn_Effect+1(a5)
; 		beq	@Cont
;  		tst.b	Chn_Effect+1(a5)
;  		bmi.s	@pwmRight
; 		bpl.s	@pwmLeft
; 		bra	@Cont
;  		
; @pwmRight:
;  		move.w	#%01000000,d0
;  		bra.s	@Cont
; @pwmLeft:
; 		move.w	#%10000000,d0
; 
; @Cont:
; 		move.b	d0,Chn_Pan(a5)   		
; 		endif
; 		rts

; ======================================================
; -------------------------------
; Flag Z
; -------------------------------

@Flag_Z:
		moveq	#0,d0
		move.b	Chn_Effect+1(a5),d0
		lsr.w	#4,d0
		add.w	d0,d0
		move.w	@HashList(pc,d0.w),d1
		move.b	Chn_Effect+1(a5),d0		;d0 - $0-$F argument
		and.b	#$F,d0
		jmp	@HashList(pc,d1.w)

@HashList:	dc.w	@Null-@HashList		;$00
		dc.w	@FM_Key-@HashList		;$10 - FM Keys ON/OFF
		dc.w	@Null-@HashList			;$20
		dc.w	@Null-@HashList			;$30
		dc.w	@PSG-@HashList			;$40 - PSG Settings
		dc.w	@Null-@HashList			;$50
		dc.w	@Null-@HashList			;$60
		dc.w	@Null-@HashList			;$70
		dc.w	@Null-@HashList			;$80
		dc.w	@Null-@HashList			;$90
		dc.w	@Null-@HashList			;$A0
		dc.w	@Null-@HashList			;$B0
		dc.w	@Null-@HashList			;$C0
		dc.w	@Null-@HashList			;$D0
		dc.w	@Null-@HashList			;$E0
		dc.w	@FixSfx-@HashList		;$F0 - Finish SFX flag (SFX only)
		even

; -------------------------------

@DacStatus:
 rts

; -------------------------------

@FM_Key:
		and.w	#$F,d0
		lsl.w	#4,d0
		move.b	d0,Chn_FM_Key(a5)
		rts

; -------------------------------

@PSG:
 rts

; -------------------------------

@FixSfx:
;    		btst	#bitPriority,(a6)
;   		bne	@Return
		
;  		lea	(RAM_SMEG_Buffer),a3
;  		move.b	snd_flagsBGM(a3),snd_flags(a3)
; 		moveq 	#0,d0
;  		move.b	PsgLast(a3),d0
; 		add.w	#$E0,d0
; 		bsr	@PutPSG

;  		moveq	#0,d0
;  		move.b	LastPattChn(a6),d0
; 		bsr	SMEG_FindPrioSlot
;   		bclr	#0,(a3)
 		
;   		bclr	#bitSfxOn,(a6)				;SFX finished playing
		rts
		
; ================================================================
; -------------------------------
; Channel play
; -------------------------------

@ChannelPlay:	
		cmp.b	#-1,Chn_ID(a5)
		beq	@Disabled
		
;                 moveq	#0,d0
; 		move.b	Chn_Note(a5),d0
; 		sub.w	#1,Chn_Portam(a5)
; 		tst.b	Chn_Portam(a5)
; 		beq.s	@NoUp
; 		add.b	Chn_Portam(a5),d0
; 		bra.s	@NoDown
; @NoUp:
; 		tst.b	Chn_Portam+1(a5)
; 		beq.s	@NoDown
; 		sub.b	Chn_Portam+1(a5),d0
; @NoDown:

; --------------------------------

; BGM: Block channel

		btst 	#bitPriority,(a6)
		bne.s	@SFX_Check
		bsr	SMEG_FindPrioSlot
  		tst.b	(a3)
  		bne	@Return
  		
; --------------------------------

; SFX: Check NoteOff/NoteCut
; then clear flag

@SFX_Check:
		btst 	#bitPriority,(a6)
		beq.s	@NotSFX
; 		cmp.b	#-1,chn_note(a5)
; 		beq	@DoIt
		cmp.b	#-2,chn_note(a5)
		bne	@NotSFX
@DoIt:
		bsr	SMEG_FindPrioSlot
  		clr.b	(a3)
@NotSFX:

; --------------------------------

		tst.b	Chn_ID(a5)
		bmi	Chnl_PSG
		cmp.b	#PCM_1,Chn_ID(a5)
		bge	@ChannelPlay_PCM
		cmp.b	#FM_3,Chn_ID(a5)
		beq	@Chn3_ChkSpecial
		cmp.b	#FM_6,Chn_ID(a5)
		beq	@Chn6_ChkSmpl
		bra	@ChnPlay_FM
		
; -------------------------------
; Play FM6 or DAC sample
; -------------------------------

@Chn6_ChkSmpl:
		btst	#bitFmDac,snd_flags(a6)
		beq	@ChnPlay_FM6
		cmp.b	#-1,chn_note(a5)
		beq	@StopSmpl
		cmp.b	#-2,chn_note(a5)
		beq	@StopSmpl
		
		moveq	#$28,d0
		moveq	#6,d1
 		bsr	SMEG_Z80_Off
		bsr	FM_RegWrite_1
		bsr	SMEG_FM_SetPan
		bsr	SMEG_Z80_On
		
; 		btst 	#bitPriority,(a6)
; 		beq.s	@MusicPrio3
; 		bsr	SMEG_FindPrioSlot
;   		btst	#0,(a3)
;   		bne	@return
; @MusicPrio3:
		bra	Audio_Sample_Play

; Stop

@StopSmpl:
; 		btst 	#bitPriority,(a6)
; 		bne.s	@NotSfxDAC
; 		bsr	SMEG_FindPrioSlot
;   		bclr	#0,(a3)
; @NotSfxDAC:
		bra	Audio_Sample_Stop
		
; -------------------------------
; Play FM6 Normally
; -------------------------------

@ChnPlay_FM6:
		move.b	#$2B,d0
		move.b	#$00,d1
		bsr	SMEG_Z80_Off
		bsr	FM_RegWrite_1
		bsr	SMEG_Z80_On
		bsr	Audio_Sample_Stop
		bra	@ChnPlay_FM
		
; -------------------------------
; Play FM3 Normally
; -------------------------------

@Chn3_ChkSpecial:
		bsr	SMEG_Z80_Off
		bsr	SMEG_FM_SetPan
		bsr	SMEG_Z80_On
		
		btst	#bitSpecial3,snd_flags(a6)
		beq	@NoSpecial3
		
		bsr	ChnlFM_srchIns
		cmp.w	#-1,d2
		beq	@NoSpecial3
 		btst	#6,d2
 		beq	@NoSpecial3
		
;   		moveq	#$22,d0
;  		move.w	#%00001011,d1
; 		bsr	FM_RegWrite_1
		
  		moveq	#$27,d0		;CH3 enable
 		move.w	#%01000000,d1
 		bsr	SMEG_Z80_Off
		bsr	FM_RegWrite_1
		bsr	SMEG_Z80_On
		
 		move.l	#$A9ADAAAE,d0
 		move.w	$E(a3),d1
 		ror.w	#8,d1
 		bsr	SMEG_Z80_Off
		bsr	FM_RegWrite_1
		lsr.l	#8,d0
		lsr.l	#8,d1
		bsr	FM_RegWrite_1
		lsr.l	#8,d0
 		move.w	$C(a3),d1
 		ror.w	#8,d1
		bsr	FM_RegWrite_1
		lsr.l	#8,d0
		lsr.l	#8,d1
		bsr	FM_RegWrite_1	
  		bsr	SMEG_Z80_On
  		
 		move.l	#$A2A6A8AC,d0
 		move.w	$A(a3),d1
 		ror.w	#8,d1
 		bsr	SMEG_Z80_Off
		bsr	FM_RegWrite_1
		lsr.l	#8,d0
		lsr.l	#8,d1
		bsr	FM_RegWrite_1
		lsr.l	#8,d0
 		move.w	8(a3),d1
 		ror.w	#8,d1
		bsr	FM_RegWrite_1
		lsr.l	#8,d0
		lsr.l	#8,d1
		bsr	FM_RegWrite_1
		bsr	SMEG_Z80_On
		
		moveq	#$28,d0
		moveq	#0,d1
		move.b	Chn_FM_Key(a5),d1
		or.b	Chn_ID(a5),d1
		bsr	SMEG_Z80_Off
		bsr	FM_RegWrite_1
 		bra	SMEG_Z80_On
 		
@NoSpecial3:
		moveq	#0,d1
  		moveq	#$27,d0
 		bsr	SMEG_Z80_Off
		bsr	FM_RegWrite_1
 		bsr	SMEG_Z80_On
		
; -------------------------------
; Play FM1-FM5 normally
; -------------------------------

@ChnPlay_FM:
		bsr	SMEG_Z80_Off
		bsr	SMEG_FM_SetPan
		bsr	SMEG_Z80_On
		
 		moveq	#0,d0
		move.b	chn_note(a5),d0
		cmp.b	#-1,d0
		beq	SMEG_FM_KeysOff
		cmp.b	#-2,d0
		beq	SMEG_FM_TotLvlOff
		
		bsr	SMEG_FM_KeysOff
		
		moveq	#0,d0
		moveq	#0,d1
		move.b	chn_note(a5),d0
		add.w	d0,d0
 		lea	(FreqList_FM),a2
		move.w	(a2,d0.w),d4
		move.w	d4,Chn_Portam(a5)
		bra	SMEG_SetFreqFM
@Disabled:
		rts

; -------------------------------
; Play PCM
; -------------------------------

@ChannelPlay_PCM:	
; 		if MCD
; 		
; 		tst.l	SongPcmSamp(a6)
; 		beq.s	@ReturnPCM
; 		bmi.s	@ReturnPCM
; 		
;  		moveq	#0,d1
;  		move.b	Chn_ID(a5),d1
;    		and.w	#$F,d1
;  		move.b	d1,($A12000+CommDataM)
;  		move.b	Chn_Pan(a5),d1
;  		move.b	d1,($A12000+CommDataM+1)
;  		moveq	#CdTask_SetPan,d0
;  		bsr	SMEG_CD_Call
;  		
; 		moveq	#0,d1
; 		move.b	Chn_ID(a5),d1
; 		and.b	#$F,d1
; 		move.b	d1,($A12000+CommDataM)
; 		move.w	Chn_Freq(a5),($A12000+CommDataM+2)
; 		moveq	#CdTask_SetFreq,d0
; 		bsr	SMEG_CD_Call
; 		bset	d1,PcmChnOnOff(a6)
; 		move.b	PcmChnOnOff(a6),($A12000+CommDataM)
; 		moveq	#CdTask_SetOnOff,d0
; 		bsr	SMEG_CD_Call
; 		
; @ReturnPCM:
;  		elseif MARS
; 
; 		tst.l	SongPcmSamp(a6)
; 		beq.s	@ReturnPCM
; 		bmi.s	@ReturnPCM
; 		
;   		moveq	#0,d1
;   		moveq	#0,d2
;        		move.b	Chn_ID(a5),d1
;      		and.w	#$F,d1
;       		or.b	Chn_Pan(a5),d1
;       		move.b	Chn_Note(a5),d2
;   		move.b	d1,(marsreg+comm2)			; Pan+Channel set
;   		move.b	d2,(marsreg+comm2+1)			; Note
;   		moveq 	#marscall_Play,d0
;   		bsr	SMEG_MARS_Call
; @ReturnPCM:
;  		endif
 		
		rts

; --------------------------
; Set FM Frequency
; autodetected channel
; 
; d4 - Freq
; --------------------------

SMEG_SetFreqFM:
		moveq	#0,d5
		move.b	Chn_ID(a5),d5
		cmp.b	#4,d5
		blt.s	@FirstFM
		sub.b	#4,d5
@FirstFM:
		move.w	#$A4,d0
		add.b	d5,d0
		moveq	#0,d1
		rol.w	#8,d4
		move.b	d4,d1
		
		bsr	SMEG_Z80_Off
		bsr	SMEG_FM_FindWrite
		move.w	#$A0,d0
		add.b	d5,d0
		moveq	#0,d1
		rol.w	#8,d4
		move.b	d4,d1
		bsr	SMEG_FM_FindWrite

		moveq	#$28,d0
		moveq	#0,d1
		move.b	Chn_FM_Key(a5),d1
		or.b	Chn_ID(a5),d1
		bsr	FM_RegWrite_1
		bra	SMEG_Z80_On
		
; Turn Total Level (the volume) off 

SMEG_FM_TotLvlOff:
 		move.b	chn_id(a5),d3
 		and.w	#%11,d3
		move.l	#$4C444840,d0
		move.w	#$7F,d1
 		bsr	SMEG_Z80_OFF
 		or.b	d3,d0
 		bsr	SMEG_FM_FindWrite	;oops.
 		lsr.l	#8,d0
 		or.b	d3,d0
  		bsr	SMEG_FM_FindWrite
 		lsr.l	#8,d0
 		or.b	d3,d0
  		bsr	SMEG_FM_FindWrite
 		lsr.l	#8,d0
 		or.b	d3,d0
 		bsr	SMEG_FM_FindWrite
 		bsr	SMEG_Z80_On
 		
; Turn FM Keys off

SMEG_FM_KeysOff:
		moveq	#$28,d0
		moveq	#0,d1
		add.b	Chn_ID(a5),d1
 		bsr	SMEG_Z80_Off
		bsr	FM_RegWrite_1
		bra	SMEG_Z80_On
		
; ----------------------------
; PSG Channels
; ----------------------------

Chnl_PSG:
		move.b	Chn_ID(a5),d1
		cmp.b	#NOISE,Chn_ID(a5)
		beq.s	Chnl_Noise

		move.w	d1,d3
		or.w	#$1F,d3
		move.b	chn_note(a5),d0
		cmp.b	#-2,d0
		beq.s	ChnPsg_Rest
		cmp.b	#-1,d0
		beq.s	ChnPsg_Rest
		
		lea	(FreqList_PSG),a2
		add.w	d0,d0
		move.w	(a2,d0.w),d0
		move.w	d0,Chn_Portam(a5)
		bsr	ChnPsg_NoteFreq
		
ChnPsg_SetVol:
		or.w	#$10,d3
		or.w	#$F,d3
		tst.b	chn_vol(a5)
		beq.s	ChnPsg_DoVol
		and.w	#$F0,d3
		cmp.b	#64,chn_vol(a5)
  		bge.s	ChnPsg_DoVol
  		moveq	#0,d0
   		move.b	chn_vol(a5),d0
 		neg.w	d0
   		lsr.w	#2,d0
  		and.w	#%1111,d0
  		or.w	d0,d3


ChnPsg_DoVol:
 		move.b	d3,(sound_psg)
Chnl_Return:
		rts
		
ChnPsg_Rest:
 		bsr.s	ChnPsg_DoVol
; 		btst 	#bitPriority,(a6)
; 		bne.s	Chnl_Return
; 		bsr	SMEG_FindPrioSlot
;   		bclr	#0,(a3)
  		rts
  		
; ----------------------------
; PSG Noise channel
; ----------------------------

Chnl_NOISE:
		movea.l	snd_instr(a6),a2
		move.w	instDNoise(a2),d0
		adda	d0,a2
		
 		move.w	#%000,d0
@next:
		tst.w	(a2)
		bmi.s	@default
		moveq	#0,d2
		move.b	chn_inst(a5),d2
		cmp.w	(a2),d2
		beq.s	@found
		adda	#4,a2
		bra.s	@next
@found:
 		move.w	2(a2),d0

@default:
		move.w	#$E0,d1
		move.w	d1,d3
		or.w	#$1F,d3

		move.b	chn_note(a5),d2
		cmp.b	#-1,d2
		beq.s	ChnPsg_Rest
		cmp.b	#-2,d2
		beq.s	ChnPsg_Rest
		
		bclr	#bitTone3,snd_flags(a6)
		cmp.w	#%011,d0
		beq.s	@valdnoise
		cmp.w	#%111,d0
		bne.s	@deftone
@valdnoise:
		bset	#bitTone3,snd_flags(a6)
		move.b	#$C0|$1F,(sound_psg)
		or.w	d0,d1
		move.b	d1,(sound_psg)
		
		move.b	chn_note(a5),d0
		cmp.b	#-1,d0
		beq	ChnPsg_Rest
		cmp.b	#-2,d0
		beq	ChnPsg_Rest
		add.w	#12,d0		; TODO: checar
		move.w	#$C0,d1		; PSG3 freq
		
		lea	(FreqList_PSG),a2
		add.w	d0,d0
		move.w	(a2,d0.w),d0
		move.w	d0,Chn_Portam(a5)
		bra	ChnPsg_NoteFreq
		
; 		move.w	#$E0,d3		; NOISE volume
; 		bra	ChnPsg_SetVol
		
@deftone:
		move.w	d1,d3
		move.w	d0,d2
		and.w	#%111,d2
		or.w	d2,d1
		move.b	d1,(sound_psg)
		rts
		
; 		move.w	#$E0,d3
; 		bra	ChnPsg_SetVol
		
; ----------------------------
; PSG Noise channel Tone 3
; 
; input:
; d0 - freq
; d1 - channel
; 
; returns:
; d3 - last psg freq | channel
; ----------------------------

ChnPsg_NoteFreq:
		move.w	d1,d3
		move.w	d0,d2
		and.w	#%1111,d2
		or.w	d2,d1
		move.b	d1,(sound_psg)
		lsr.w	#4,d0
		and.w	#%00111111,d0
		move.b	d0,(sound_psg)
		rts

; -------------------------------
; PSG Frequencies
; -------------------------------

FreqList_PSG:
		dc.w 0		;C-0 $0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		
		dc.w 0		;C-1 $C
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		
		dc.w 0		;C-2 $18
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0

		dc.w 0		;C-3 $24
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w $3F8
                dc.w $3BF
                dc.w $389
                
		dc.w $356	;C-4 $30
                dc.w $326
                dc.w $2F9
                dc.w $2CE
                dc.w $2A5
                dc.w $280
                dc.w $25C
                dc.w $23A
                dc.w $21A
		dc.w $1FB
                dc.w $1DF
                dc.w $1C4
                
                dc.w $1AB	;C-5 $3C
                dc.w $193
                dc.w $17D
                dc.w $167
                dc.w $153
                dc.w $140
		dc.w $12E
                dc.w $11D
                dc.w $10D
                dc.w $FE
                dc.w $EF
                dc.w $E2
                
                dc.w $D6	;C-6 $48
                dc.w $C9
                dc.w $BE
                dc.w $B4
		dc.w $A9
                dc.w $A0
                dc.w $97
                dc.w $8F
                dc.w $87
                dc.w $7F
                dc.w $78
                dc.w $71
                
                dc.w $6B	;C-7 $54
                dc.w $65
		dc.w $5F
                dc.w $5A
                dc.w $55
                dc.w $50
                dc.w $4B
                dc.w $47
                dc.w $43
                dc.w $40
                dc.w $3C
                dc.w $39
                
		dc.w $36	;C-8 $60
                dc.w $33
                dc.w $30
                dc.w $2D
                dc.w $2B
                dc.w $28
                dc.w $26
                dc.w $24
                dc.w $22
                dc.w $20
		dc.w $1F
                dc.w $1D
                
                dc.w $1B	;C-9 $6C
                dc.w $1A
                dc.w $18
                dc.w $17
                dc.w $16
                dc.w $15
                dc.w $13
                dc.w $12
		dc.w $11
 		dc.w $10 ;Custom...
 		dc.w $9
 		dc.w $8

		even
		
; -------------------------------
; FM Frequencies
; -------------------------------

FreqList_FM:
; 		dc.w $269	;NULL
		dc.w $28d	;C-0 $00
		dc.w $2b4
		dc.w $2dd
		dc.w $309
		dc.w $337
		dc.w $368
		dc.w $39c
		dc.w $3d3
		dc.w $40d
		dc.w $44b
		dc.w $48c
		dc.w $269
		dc.w $28d	;C-1 $0C
		dc.w $2b4
		dc.w $2dd
		dc.w $309
		dc.w $337
		dc.w $368
		dc.w $39c
		dc.w $3d3
		dc.w $40d
		dc.w $44b
		dc.w $48c
		dc.w $a69
		dc.w $a8d	;C-2 $18
		dc.w $ab4
		dc.w $add
		dc.w $b09
		dc.w $b37
		dc.w $b68
		dc.w $b9c
		dc.w $bd3
		dc.w $c0d
		dc.w $c4b
		dc.w $c8c
		dc.w $1269
		dc.w $128d	;C-3 $24
		dc.w $12b4
		dc.w $12dd
		dc.w $1309
		dc.w $1337
		dc.w $1368
		dc.w $139c
		dc.w $13d3
		dc.w $140d
		dc.w $144b
		dc.w $148c
		dc.w $1a69
		dc.w $1a8d	;C-4 $30
		dc.w $1ab4
		dc.w $1add
		dc.w $1b09
		dc.w $1b37
		dc.w $1b68
		dc.w $1b9c
		dc.w $1bd3
		dc.w $1c0d
		dc.w $1c4b
		dc.w $1c8c
		dc.w $2269
		dc.w $228d	;C-5 $3C
		dc.w $22b4
		dc.w $22dd
		dc.w $2309
		dc.w $2337
		dc.w $2368
		dc.w $239c
		dc.w $23d3
		dc.w $240d
		dc.w $244b
		dc.w $248c
		dc.w $2a69
		dc.w $2a8d	;C-6 $48
		dc.w $2ab4
		dc.w $2add
		dc.w $2b09
		dc.w $2b37
		dc.w $2b68
		dc.w $2b9c
		dc.w $2bd3
		dc.w $2c0d
		dc.w $2c4b
		dc.w $2c8c
		dc.w $3269	;C-7 $54
		dc.w $328d
		dc.w $32b4
		dc.w $32dd
		dc.w $3309
		dc.w $3337
		dc.w $3368
		dc.w $339c
		dc.w $33d3
		dc.w $340d
		dc.w $344b
		dc.w $348c
		even
		
; ; -------------------------------
; ; Mute/Rest channel
; ; -------------------------------
; 
; SMEG_ChannelRest:
; 		cmp.b	#$FF,Chn_ID(a5)
; 		beq	@Return
; 		
; ; 		btst	#bitPriority,(a6)
; ; 		beq.s	@SFX_Mode
; ; 		btst	#bitSfxOn,(RAM_SMEG_SfxBuff)
; ; 		beq.s	@SFX_Mode
; ;  		lea	(RAM_SMEG_PrioList),a3
; ;  		moveq	#0,d1
; ;  		move.b	LastPattChn(a6),d1
; ; 		btst	#0,(a3,d1.w)
; ; 		bne	@Return
; ; @SFX_Mode:
; 
; 		tst.b	Chn_ID(a5)
; 		bmi.s	@PSG_Rest
; 
;                 cmp.b	#6,Chn_ID(a5)
;                 bne.s	@NoChk6
; 		btst	#bitFmDac,snd_flags(a6)
; 		bne.s	@DAC_Rest
; 
; @NoChk6:
; 		cmp.b	#PCM_1,Chn_ID(a5)
; 		bge	@PCM_Rest
; 		
; 		moveq	#$28,d0
;                 moveq	#0,d1
; 		move.b	Chn_ID(a5),d1
; 		bsr	SMEG_Z80_Off
; 		bsr	FM_RegWrite_1
; 		bsr	SMEG_Z80_On
; 
; @Return:
; 		rts
; 
; ; -------------------------------
; ; PSG Rest
; ; -------------------------------
; 
; @PSG_Rest:
; 		moveq	#0,d0
; 		move.b	Chn_ID(a5),d0
; 		add.b	#$1F,d0
; 		move.b	d0,($C00011)
; 
; @Disabled:
; 		rts
; 
; ; -------------------------------
; ; DAC Rest
; ; -------------------------------
; 
; @DAC_Rest:
;   		bsr	SMEG_Z80_Off
; 		moveq	#$2B,d0
;                 moveq	#0,d1
;   		bsr	FM_RegWrite_1
; 
; 		moveq	#0,d0
; 		move.b	d0,($A001E0+$D)
; 		bsr	SMEG_Z80_On
; 		rts
; 
; ; -------------------------------
; ; PCM Rest
; ; -------------------------------
; 
; @PCM_Rest:
;  		if MCD
;  		
; 		tst.l	SongPcmSamp(a6)
; 		beq.s	@ReturnPCM
; 		bmi.s	@ReturnPCM
; 		
; 		moveq	#0,d1
; 		move.b	Chn_ID(a5),d1
; 		and.b	#$F,d1
; 		bclr	d1,PcmChnOnOff(a6)
; 		move.b	PcmChnOnOff(a6),($A12000+CommDataM)
; 		moveq	#CdTask_SetOnOff,d0
; 		bsr	SMEG_CD_Call
; 		
;  		elseif MARS
;  		
; 		tst.l	SongPcmSamp(a6)
; 		beq.s	@ReturnPCM
; 		bmi.s	@ReturnPCM
; 		
;   		moveq	#0,d0
;   		move.b	Chn_ID(a5),d0
;   		and.w	#$F,d0
;   		move.b	d0,(marsreg+comm2)
;   		moveq	#marscall_Stop,d0
;   		bsr	SMEG_MARS_Call
;     		
; 		endif
; @ReturnPCM:
; 		rts
		
; ================================================================
; Subs
; ================================================================

; -------------------------------------------
; Extra channels communication
; -------------------------------------------

SMEG_CD_Call:
 		if MCD
; 		bra	SubCpu_Task_Wait
 		endif
		rts

SMEG_MARS_Call:
  		if MARS
;  		bsr	Mars_Task_Slave
;  		bra	Mars_Wait_Slave
  		endif
 		rts
 		
; -------------------------------------------
; Set instrument
; -------------------------------------------

SMEG_SetVoice:
		cmp.b	#-1,Chn_ID(a5)
		beq	@Return
		
		btst	#bitPriority,(a6)
		bne.s	@SFX_ModeV
		bsr	SMEG_FindPrioSlot
  		tst.b	(a3)
  		bne	@Return
@SFX_ModeV:


		tst.l	snd_instr(a6)
		beq	@Return
		
		tst.b	Chn_ID(a5)
		bmi.s	@Return
		cmp.b	#PCM_1,Chn_ID(a5)
		bge	SMEG_SetVoice_PCM
		cmp.b	#FM_6,Chn_ID(a5)
		beq	SMEG_SetVoice_DAC
		
 		bra	SetVoice_FM
@Return:
 		rts
		
; -------------------------------------------
; Send DAC
; -------------------------------------------

SMEG_SetVoice_DAC:
		bsr	ChnlFM_srchIns
		cmp.w	#-1,d2
		beq.s	@Return
		
 		btst	#7,d2
 		bne.s	@Sample_Mode
		bclr	#bitFmDac,snd_flags(a6)
		bra	SetVoice_FM
 		
@Sample_Mode:
		bset	#bitFmDac,snd_flags(a6)
		move.l	4(a3),d0
		move.l	8(a3),d1
		sub.l	#1,d1
		move.l	$C(a3),d2
		moveq	#0,d3
		move.b	chn_note(a5),d3
 		add.w	2(a3),d3
 		bra	Audio_Sample_Set
@Return:
		rts
		
; -------------------------------------------
; Send FM
; -------------------------------------------

SetVoice_FM:
		bsr	ChnlFM_srchIns
		bclr	#bitSpecial3,snd_flags(a6)
		cmp.w	#-1,d2
		beq	@Return
 		btst	#7,d2
 		bne	@Return
 		btst	#6,d2
 		beq.s	@notFM3
 		bset	#bitSpecial3,snd_flags(a6)
@notFM3:

;  		adda.w	#4,a3
		movea.l	4(a3),a3
		moveq	#0,d0
		move.b	Chn_ID(a5),d0
		cmp.b	#4,d0
		blt.s	@Low3
		sub.b	#4,d0
@Low3:

		swap	d0
		move.w	#$28,d0
		moveq	#0,d1
		move.b	Chn_ID(a5),d1
		bsr	SMEG_Z80_Off
		bsr	FM_RegWrite_1
		swap	d0

		lea	SMEG_FM_RegList(pc),a2
		move.w	d0,d6
		moveq	#$18,d4
@Next:
		move.w	d6,d5
		move.b	(a2)+,d0
		move.w	d0,d3
		add.w	d5,d0
		move.b	(a3)+,d1

		cmp.b	#4,Chn_ID(a5)
		bge.s	@Chn456
		bsr	FM_RegWrite_1
		dbf	d4,@Next
		bra.s	@BackZ80

@Chn456:
		bsr	FM_RegWrite_2
		dbf	d4,@Next
@BackZ80:
		bsr	SMEG_Z80_On
@Return:
		rts

; -------------------------------------------
; Set FM panning
; -------------------------------------------

SMEG_FM_SetPan:
		tst.b	Chn_ID(a5)
		bmi	@Return
		
		moveq	#0,d1
  		move.b	chn_pan(a5),d1
  		lsr.w	#6,d1
  		and.w	#%11,d1
  		move.b	@list(pc,d1.w),d1
  		and.w	#%11000000,d1
  		move.w	#$B4,d0
  		move.b	chn_id(a5),d2
  		and.w	#%11,d2
  		or.w	d2,d0
 		bra	SMEG_FM_FindWrite
		
@list:		dc.b $80,$80,$C0,$40
		even
		
		
		move.w	#$B4,d0
		moveq	#0,d2
		move.b	Chn_ID(a5),d2
		moveq	#0,d1
		move.b	Chn_Pan(a5),d1

		bsr	SMEG_Z80_Off
		cmp.b	#3,d2
		bgt.s	@SecondFM
		add.w	d2,d0
		bsr	FM_RegWrite_1
		bra.s	@BackZ80
@SecondFM:
		sub.w	#4,d2
		add.w	d2,d0
		bsr	FM_RegWrite_2
@BackZ80:
		bsr	SMEG_Z80_On
@Return:
		rts

; ---------------------

ChnlFM_srchIns:
		movea.l	snd_instr(a6),a3
 		move.w	instDYmha(a3),d0
 		adda	d0,a3
@next:
		swap	d1
		tst.w	(a3)
 		bmi	@NoteOff
 		moveq	#0,d0
		move.b	chn_inst(a5),d0
		move.w	(a3),d1
		move.w	d1,d2
		and.w	#$3F,d1
		cmp.w	d1,d0
		beq.s	@found
		adda	#8,a3		;inst,oct,firstlong
		btst	#7,d2
		bne.s	@doit
		btst	#6,d2
		beq.s	@next
@doit:
		adda	#8,a3		;scndlong,thrdlong
		bra.s	@next
@NoteOff:
		swap	d1
		moveq	#-1,d2
@found:
		rts
		
; --------------------------------------------
; Play a sample
;
; Input:
; d0 | LONG - Start
; d1 | LONG - End
; d2 | LONG - Loop point
;              0 = From start
;             -1 = No loop
; d3 | WORD - Note ($3C - default)
; --------------------------------------------

Audio_Sample_Set:
		bsr	SMEG_Z80_Off
		
		lea	($A00180),a0
		rol.l	#8,d0
		move.b	d0,(a0)+
		rol.l	#8,d0
		move.b	d0,(a0)+		
		rol.l	#8,d0
		move.b	d0,(a0)+
		rol.l	#8,d0
		move.b	d0,(a0)+
		
 		sub.l	#1,d1
		rol.l	#8,d1
		move.b	d1,(a0)+
		rol.l	#8,d1
		move.b	d1,(a0)+		
		rol.l	#8,d1
		move.b	d1,(a0)+
		rol.l	#8,d1
		move.b	d1,(a0)+
		
		moveq	#0,d1
		move.l	d0,d4
		cmp.l	#-1,d2
		beq.s	@no_loop
		moveq	#2,d1
		move.l	d0,d4
		add.l	d2,d4
@no_loop:
		rol.l	#8,d4
		move.b	d4,(a0)+
		rol.l	#8,d4
		move.b	d4,(a0)+		
		rol.l	#8,d4
		move.b	d4,(a0)+
		rol.l	#8,d4
		move.b	d4,(a0)+

		move.b	d1,(a0)
		
		move.w	d3,d0
		bra	AudioSmplNote_go

; --------------------------------------------
; Stop the current sample
; --------------------------------------------

Audio_Sample_Play:
		bsr	SMEG_Z80_Off
		
		move.b	($A0018C).l,d0
		bset	#0,d0
		move.b	d0,($A0018C).l
 		
		move.w	#0,($A11100).l
		rts
		
; --------------------------------------------
; Stop the current sample
; --------------------------------------------

Audio_Sample_Stop:
		bsr	SMEG_Z80_Off
		
		move.b	#$40,($A0018C).l
 		
		move.w	#0,($A11100).l
		rts
		
; --------------------------------------------
; Modify sample note
;
; d3 | WORD - Note
; --------------------------------------------

Audio_Sample_Note:
		bsr	SMEG_Z80_Off
		
AudioSmplNote_go:
; 		sub.w	#24,d0			; skip 2 octaves
		lsl.w	#6,d0
 		add.w	#$1C0,d0
		move.b	d0,($A000DC)		; ld bc,(NEW ADDRESS)
		lsr.w	#8,d0			;
 		move.b	d0,($A000DD)		;
 		
		move.w	#0,($A11100).l
		rts

; -------------------------------------------
; Send PCM/PWM
; -------------------------------------------

SMEG_SetVoice_PCM:
		if MCD
   		
		moveq	#0,d1
   		moveq	#0,d2
		tst.l	SongPcmSamp(a6)
		beq.s	@FinishList
		bmi.s	@FinishList
		movea.l	SongPcmSamp(a6),a3
		move.b	Chn_Inst(a5),d1
@NextPcm:
		tst.w	(a3)
		bmi.s	@GiveUp
		move.b	(a3),d2
		cmp.b	d1,d2
		beq.s	@FoundPcm
		adda	#2,a3
		bra.s	@NextPcm
@FoundPcm:
		moveq	#0,d1
		move.b	1(a3),d1
@GiveUp:
		sub.w	#1,d1
		lsl.w	#2,d1
		lea	(RAM_SMEG_PcmList),a3
		adda	d1,a3
   		
		move.b	1(a3),Chn_PCM_Pitch(a5)
		move.b	Chn_ID(a5),($A12000+CommDataM)
		move.b	(a3),($A12000+CommDataM+1)
		move.w	2(a3),($A12000+CommDataM+2)
		moveq	#CdTask_SetAddr,d0
		bsr	SMEG_CD_Call

; ---------------------------------

		elseif MARS
   		
		tst.l	SongPcmSamp(a6)
		beq.s	@FinishList
		bmi.s	@FinishList
		
    		moveq	#0,d1
   		moveq	#0,d2
     		movea.l	SongPcmSamp(a6),a3
    		move.b	Chn_Inst(a5),d1
@NextPcm:
     		tst.w	(a3)
     		bmi.s	@GiveUp
     		move.b	(a3),d2
     		cmp.b	d1,d2
     		beq.s	@FoundPcm
     		adda	#2,a3
     		bra.s	@NextPcm
@FoundPcm:
  		move.b	1(a3),d1
@GiveUp:
   		sub.w	#1,d1
   		moveq	#0,d2
   		move.b	Chn_ID(a5),d2
   		and.w	#$F,d2
   		move.b	d2,(marsreg+comm2)
  		move.b	d1,(marsreg+comm2+1)
 		moveq 	#marscall_SetSmpl,d0
 		bsr	SMEG_MARS_Call
  		
		endif
@FinishList:
		rts
		
; -------------------------------------------
; Reset FM
; -------------------------------------------

SMEG_FM_Reset:
		bsr	SMEG_Z80_Off

		moveq	#$28,d0
		moveq	#0,d1
		bsr	FM_RegWrite_1
		moveq	#$28,d0
		moveq	#1,d1
		bsr	FM_RegWrite_1
		moveq	#$28,d0
		moveq	#2,d1
		bsr	FM_RegWrite_1
		moveq	#$28,d0
		moveq	#4,d1
		bsr	FM_RegWrite_1
		moveq	#$28,d0
		moveq	#5,d1
		bsr	FM_RegWrite_1
		moveq	#$28,d0
		moveq	#6,d1
		bsr	FM_RegWrite_1

		bra	SMEG_Z80_On

; -------------------------------------------
; Find FM
; -------------------------------------------

SMEG_FM_FindWrite:
		cmp.b	#4,Chn_ID(a5)
		bge.s	@Second
		bra	FM_RegWrite_1
@Second:
		bra	FM_RegWrite_2

; -------------------------------------------
; Write to FM register
; -------------------------------------------

FM_RegWrite_1:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	FM_RegWrite_1
		move.b	d0,($A04000).l
@Loop:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	@Loop
		move.b	d1,($A04001).l
		rts

FM_RegWrite_2:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	FM_RegWrite_2
		move.b	d0,($A04002).l
@Loop:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	@Loop
		move.b	d1,($A04003).l
		rts
		
SMEG_Z80_Off:
		move.w	#$100,($A11100).l
@WaitZ80;\@:
		btst	#0,($A11100).l
		bne.s	@WaitZ80;\@
		rts
		
; USES d2

SMEG_Z80_On:
		move.b	($A0018C),d2
		btst	#7,d2
		beq.s	@stopped;\@
@busywait;\@:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	@busywait;\@
		move.b	#$2A,(sound_ym_1)
		move.b	($A0018F),d2
		move.b	d2,(sound_ym_2)
@stopped;\@:
		move.w	#0,($A11100).l
		rts
		
; -----------------------
; Setup channels
; -----------------------

SMEG_Load_SetChnls:
		movea.l	SongRequest(a6),a4				;a4 - Music data
		move.w	TicksRequest(a6),TicksSet(a6)

; -----------------------
; Get the
; PatternEnd/PatternLoop
; numbers
; -----------------------

		move.b	(a4)+,PatternEnd(a6)
		move.b	(a4)+,PatternLoop(a6)
		
; -----------------------
; Get instruments
; -----------------------

		move.l	(a4)+,SongStart(a6)
		move.l	(a4)+,snd_instr(a6)

; -----------------------
; Setup the channel IDs
; -----------------------

		move.w	#max_chnl-1,d0
		move.w	(a4)+,d2
		sub.w	#1,d2
@SetId:
		move.b	#1,Chn_Type(a5)
		move.b	#-1,Chn_ID(a5)
		tst.w	d2
		bmi.s	@Disabled
		sub.w	#1,d2
		move.b	(a4)+,Chn_ID(a5)
 		move.b	(a4)+,Chn_Vol(a5)
 		move.b	(a4)+,Chn_Pan(a5)
 		move.b	(a4)+,d3
 		tst.b	chn_id(a5)
 		bmi.s	@is_psg
 		cmp.b	#PCM_1,chn_id(a5)
 		bge.s	@is_pcm
 		
 		lsl.w	#4,d3
 		move.b	d3,Chn_FM_Key(a5)
		bra.s	@Disabled
@is_pcm:
		nop 
		bra.s	@Disabled
		
@is_psg:
		move.b	Chn_ID(a5),d1
		or.b	#$1F,d1
		move.b	d1,(sound_psg)
 		
@Disabled:
		adda 	#sizeof_Chn,a5
		dbf	d0,@SetId
 		
; ; -----------------------
; ; Master volumes
; ; -----------------------
; 
; 		moveq	#(max_chnl)-1,d0
; @SetVol:
; 		move.b	(a4)+,Chn_MainVol(a5)
; 		adda 	#sizeof_Chn,a5
; 		dbf	d0,@SetVol

; -----------------------
; last steps
; -----------------------

		movea.l	SongStart(a6),a4
		move.b	(a4)+,PattSize+1(a6)
		move.b	(a4)+,PattSize(a6)
		clr.w	pattr_read(a6)
		adda	#6,a4
		move.l	a4,SongRead(a6)
		rts
		
; -----------------------
; Search used slot
; 
; Uses d3
; -----------------------

SMEG_FindPrioSlot:
 		lea	(RAM_SMEG_PrioList),a3
;  		inform 0,"%h",RAM_SMEG_PrioList
 		
 		moveq	#0,d3
 		move.b	Chn_ID(a5),d3
 		btst	#7,d3
 		bne.s	@PSG_slots
 		cmp.b	#PCM_1,d3
 		bge.s	@PCM_Slots
 		cmp.b	#4,d3
 		blt.s	@leftFM
 		sub.w	#1,d3
@leftFM:
		bra.s	@set_slot

@PSG_slots:
		lsr.w	#5,d3
		and.w	#%11,d3
		add.w	#6,d3
		bra.s	@set_slot

@PCM_Slots:
		sub.w	#PCM_1,d3
@set_slot:
		add.w	d3,a3
		rts
		
; -----------------------
; Turn off the unused
; channels
; -----------------------

SMEG_Load_FixSfx:
 		lea	(RAM_SMEG_PrioList),a3
 		
; FM Check

 		moveq	#6-1,d3
 		moveq	#$28,d0
 		moveq	#0,d1
@chknextfm1:
		tst.b	(a3)
		beq.s	@off_fm
		clr.b	(a3)
		
		cmp.b	#6,d1
		bne.s	@notdac
		btst	#bitFmDac,snd_flags(a6)
		beq.s	@notdac
		
		bsr	Audio_Sample_Stop
		bra.s	@off_fm
		
@notdac:
		bsr	SMEG_Z80_Off
		bsr	FM_RegWrite_1
		bsr	SMEG_Z80_On
@off_fm:
		adda 	#1,a3

		add.w	#1,d1
		cmp.w	#3,d1
		bne.s	@nope
		add.w	#1,d1
@nope:
		dbf	d3,@chknextfm1
		
; PSG check

		move.w	#$9F,d1
		move.w	#4-1,d0
@chknextpsg:
		tst.b	(a3)
		beq.s	@off_psg
		clr.b	(a3)
		move.b	d1,(sound_psg)
@off_psg:
		adda	#1,a3
		add.w	#$20,d1
		dbf	d0,@chknextpsg
		
; TODO: PCM check

; 		lea	(RAM_SMEG_Chnls_BGM),a5
; 		moveq	#(max_chnl)-1,d4
; @SetId:
; 		move.b	#$80,Chn_Pan(a5)
; 
; 		tst.b	Chn_ID(a5)
; 		bmi.s	@NotFM
; 		cmp.b	#PCM_1,Chn_ID(a5)
; 		bge.s	@NotFM
; 
; 		clr.b	Chn_FM_Key(a5)
; 		move.b	#%00001111,Chn_FM_Key(a5)
; 		move.b	#$C0,Chn_Pan(a5)
; 		bsr	SMEG_FM_SetPan
; @NotFM:
; 		adda 	#sizeof_Chn,a5
; 		dbf	d4,@SetId
		
; 		bsr	SMEG_Z80_Off
; 		moveq	#$2B,d0
;                 moveq	#0,d1
;   		bsr	FM_RegWrite_1
;   		
; 		moveq	#0,d0
; 		move.b	d0,($A001E0+$D)
; 		bsr	SMEG_Z80_On
		
		rts
		
; -----------------------
; Exclusive features
;
; TODO: creo que es
; mala idea hacer esperar
; al VBlank ya que moví
; la rutina esta
; -----------------------

SMEG_Load_SetExtChnls:
		if MCD

 		moveq	#CdTask_ClearAllPcm,d0
 		bsr	SMEG_CD_Call
		
 		lea	(RAM_SMEG_Buffer),a6
 		tst.l	SongPcmSamp(a6)
 		beq	@Return
 		bmi	@Return
 		
 		movea.l	SongPcmSamp(a6),a5
 		moveq	#0,d1
 		lea	(RAM_SMEG_PcmList),a3
@NextSamp:
 		tst.w	(a5)
 		bmi.s	@Finish
 		move.b	d1,(a3)				;ST Address

 		move.w	$E(a5),d0
 		and.w	#$FF,d0
 		move.b	d0,1(a3)
 		move.l	(a5),($A12000+CommDataM)	;\
 		move.l	4(a5),($A12000+CommDataM+4)	; > Filename
 		move.l	8(a5),($A12000+CommDataM+8)	;/
  		move.w	#0,($A12000+CommDataM+$C)
 		move.b	d1,($A12000+CommDataM+$D)	;Bank to use
 		moveq	#CdTask_LoadPcm,d0
  		bsr	SMEG_CD_Call
  		
  		moveq	#0,d2
  		moveq	#0,d3
 		move.w	($A12000+CommDataS+2),d2
 		cmp.w	#$FFFF,$C(a5)
 		beq.s	@NotLoop
 		move.w	$C(a5),d2
@NotLoop:
; 		move.b	d1,d3
; 		and.w	#$7F,d3
; 		lsl.w	#8,d3
; 		lsl.w	#4,d3
; 		add.w 	d3,d2
		
 		move.w	d2,2(a3)			;Loop address
 		move.b	($A12000+CommDataS),d1		;Next ST
 		
 		adda	#$10,a5
 		adda	#4,a3
 		bra.s	@NextSamp
@Finish:
 		adda	#2,a5
 		move.l	a5,SongPcmSamp(a6)		;Second list
		
; -----------------------

 		elseif MARS
		
  		lea	(RAM_SMEG_Buffer),a6
  		tst.l	SongPcmSamp(a6)
   		beq.s	@Return
  		
   		movea.l	SongPcmSamp(a6),a5
   		moveq	#0,d1
@NextSamp:
    		tst.w	(a5)
    		bmi.s	@Finish

    		move.l	(a5)+,(marsreg+comm12)		;Sample addr (start/end)
    		move.w	(a5)+,(marsreg+comm10)		;Sample loop
    		move.w	(a5)+,d0
    		move.b	d0,(marsreg+comm2+1)		;Note transpose
    		move.b	d1,(marsreg+comm2)		;Sample slot
   		moveq	#marscall_SetEntry,d0
   		bsr	SMEG_MARS_Call
       		
        	add.w	#1,d1
 		bra.s	@NextSamp
@Finish:
  		adda	#2,a5
  		move.l	a5,SongPcmSamp(a6)		;Second list		
 		endif
		
@Return:
		rts
		
; -------------------------------------------
; Reset PSG
; -------------------------------------------

SMEG_PSG_Reset:
		move.b	#$9F,($C00011).l
		move.b	#$BF,($C00011).l
		move.b	#$DF,($C00011).l
		move.b	#$FF,($C00011).l
		rts

; -------------------------------------------
; Reset PCM
; -------------------------------------------

SMEG_PCM_Reset:
		tst.l	SongPcmSamp(a6)
		beq.s	@NoResetPCM
		bmi	@NoResetPCM
		
		if MCD
		
		clr.b	PcmChnOnOff(a6)
		move.b	PcmChnOnOff(a6),($A12000+CommDataM)
		moveq	#CdTask_SetOnOff,d0
		bra	SMEG_CD_Call
		
		elseif MARS
		
  		move.b	#0,(marsreg+comm2)
  		moveq	#marscall_Stop,d0
  		bsr	SMEG_MARS_Call
  		move.b	#1,(marsreg+comm2)
  		moveq	#marscall_Stop,d0
  		bsr	SMEG_MARS_Call
  		move.b	#2,(marsreg+comm2)
  		moveq	#marscall_Stop,d0
  		bsr	SMEG_MARS_Call
   		move.b	#3,(marsreg+comm2)
  		moveq	#marscall_Stop,d0
  		bsr	SMEG_MARS_Call
   		move.b	#4,(marsreg+comm2)
  		moveq	#marscall_Stop,d0
  		bsr	SMEG_MARS_Call
  		move.b	#5,(marsreg+comm2)
  		moveq	#marscall_Stop,d0
  		bsr	SMEG_MARS_Call
  		move.b	#6,(marsreg+comm2)
  		moveq	#marscall_Stop,d0
  		bsr	SMEG_MARS_Call
  		move.b	#7,(marsreg+comm2)
  		moveq	#marscall_Stop,d0
  		bsr	SMEG_MARS_Call
  		
		endif

@NoResetPCM:
		rts

; ================================================================
; -------------------------------------------------
; Data
; -------------------------------------------------

; -------------------------------
; FM Register list
; -------------------------------

SMEG_FM_RegList:
		dc.b $B0
		dc.b $30,$38,$34,$3C
		dc.b $50,$58,$54,$5C
		dc.b $60,$68,$64,$6C
		dc.b $70,$78,$74,$7C
		dc.b $80,$88,$84,$8C
		dc.b $40,$48,$44,$4C
		even
	
; -------------------------------
; Z80 Driver
; -------------------------------

Z80_Driver:	incbin	"system/sound/z80/main.bin"
Z80_DriverEnd:
		even
		
; ---------------------------------------------------
