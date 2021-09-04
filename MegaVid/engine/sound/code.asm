; ================================================================
; SMEG
; Sound and Music Engine for Genesis/SegaCD/32X
;
; (C)2013-2015 Kevin C.
; 
; ImpulseTracker
;
; Ticks:
; 150 - NTSC
; 120 - PAL
;
; uses assembler settings:
; SegaCD - for building to SegaCD (All the driver must be aligned to WordRAM or PRG-RAM)
;          requires SubCPU code for PCM Samples
; MARS   - for building to 32x (CODE and DATA(Music/Sfx/Voices/Z80 samples) must be aligned
;          to the 32x standards, uses bank 0 only, PWM Samples can be anywhere)
;          requires sh2 code for PWM Samples
;
; Limtations:
; Driver - doesnt support any kind of effects
;          only volume and panning (Xxx) works
; 
; SegaCD - You cant use Z80 samples if your program is running
;          on PRG-RAM (Z80 cant access RAM), if your program is
;          running on WORD-RAM, set the permission to
;          MainCPU (2M Mode) <-- SEGA didnt allow this
; ================================================================

			rsreset
DrvStatus		rs.b 1		;Byte
DrvSettings		rs.b 1		;Byte
PatternEnd		rs.b 1		;Byte
PatternLoop		rs.b 1		;Byte
ChannelList		rs.l 1		;Long
SongStart		rs.l 1		;Long
SongRead		rs.l 1		;Long
SongVoices		rs.l 1		;Long
SongSampl		rs.l 1		;Long
SongPcmSamp		rs.l 1		;Long
TicksRead		rs.w 1		;Word
TicksSet		rs.w 1		;Word
TempoRead 		rs.w 1		;Word
PattSize		rs.w 1		;Word
PattRead		rs.w 1		;Word
CurrPattern		rs.b 1		;Byte
PcmChnOnOff		rs.b 1		;Byte
PsgLast			rs.b 1		;Byte
DrvSettingsBGM		rs.b 1		;Byte
LastPattChn		rs.b 1		;Byte
Psg_Vibrato		rs.b 1		;Byte
Psg_AutoVol		rs.b 1		;Byte
UsedChnBuff		rs.b 18		;Array (Bytes)

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
Chn_DefVol		rs.b 1		;Byte
Chn_Note		rs.b 1		;Byte
Chn_Panning		rs.b 1		;Byte
Chn_FM_Key		rs.b 1		;Byte
Chn_PCM_Pitch		rs.b 1		;Byte
Chn_PSG_Vibrato		rs.b 1		;Byte
sizeof_Chn		rs.l 0
 
; --------------------------------------------
; Bits
; --------------------------------------------

bitPriority		equ	0
bitSfxOn		equ	1
bitDisabled		equ	2

;Status
bitDacOn		equ	0
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
MaxChannels		equ	18

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
; --------------------------------------------

			rsset RAM_SndDriver
RAM_SMEG_Buffer		rs.b $48
RAM_SMEG_SfxBuff	rs.b $48
RAM_SMEG_Chnls_BGM	rs.b $10*18
RAM_SMEG_Chnls_SFX	rs.b $10*18
			if SegaCD
RAM_SMEG_PcmList	rs.l 64
			endif
sizeof_SMEG		rs.l 0
; 			inform 0,"SMEG: %h",sizeof_SMEG-RAM_SndDriver
			
; ================================================================
; -------------------------------------------
; Macros
; -------------------------------------------

Z80_OFF		macro
		move.w	#$100,($A11100).l
@WaitZ80\@:
		btst	#0,($A11100).l
		bne.s	@WaitZ80\@
		endm

; -----------------------------------------

Z80_ON		macro
		move.b	#$2A,($A04000).l
		move.w	#0,($A11100).l
		endm

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

; -------------------------------------------

SMEG_CD_Call:
 		if SegaCD
		bra	SubCpu_Task_Wait
 		endif
		rts

SMEG_MARS_Call:
  		if MARS
 		bsr	Mars_Task_Slave
 		bra	Mars_Wait_Slave
  		endif
 		rts
		
; ================================================================
; -------------------------------------------
; Init
; -------------------------------------------

SMEG_Init:
		lea	(RAM_SMEG_Buffer),a0
		move.w	#$2FF,d0
@ClrAll:
		clr.l	(a0)+
		dbf	d0,@ClrAll

		bsr	SMEG_Z80_Init
		
; -------------------------------------------
; Stop ALL Sound
; -------------------------------------------

SMEG_StopSnd:
		move.b	#$2B,d0
		move.b	#$00,d1
		Z80_OFF
		bsr	FM_RegWrite_1
		Z80_ON
		
		lea	(RAM_SMEG_Buffer),a0
		bset	#bitDisabled,(a0)
		lea	(RAM_SMEG_SfxBuff),a0
		bset	#bitDisabled,(a0)
	
		bsr	SMEG_FM_Reset
		bsr	SMEG_PSG_Reset
		bra	SMEG_PCM_Reset

; -------------------------------------------
; Play Song
; -------------------------------------------

SMEG_PlaySong:
		lea	(RAM_SMEG_Buffer),a0
		bclr	#bitDisabled,(a0)
		rts
		
; -------------------------------------------
; Load SFX
;
; d0 - StartOfSong
; d1 - Ticks
; -------------------------------------------

SMEG_LoadSfx:
		movem.l	a4-a6,-(sp)
		lea	(RAM_SMEG_SfxBuff),a6
		lea	(RAM_SMEG_Chnls_SFX),a5
		clr.b	PcmChnOnOff(a6)
                clr.b	DrvStatus(a6)
                bset	#bitSfxOn,(a6)
		bsr	SMEG_Load_SetChnls
		movem.l	(sp)+,a4-a6
		rts

; -------------------------------------------
; Load Song
;
; d0 - StartOfSong
; d1 - Ticks
; -------------------------------------------

SMEG_LoadSong:
		move.l	d0,d6
		move.l	d1,d5
		bsr	SMEG_StopSnd			;d0-d1 are gone
		move.l	d6,d0
		move.l	d5,d1
		
		lea	(RAM_SMEG_Buffer),a6
		lea	(RAM_SMEG_Chnls_BGM),a5
		clr.b	PcmChnOnOff(a6)
                clr.b	DrvStatus(a6)
		bsr	SMEG_Load_SetChnls
		bsr	SMEG_Load_FixBgm
		bsr	SMEG_Load_SetExtChnls

; 		lea	(RAM_SMEG_Buffer),a6
; 		bset	#bitDisabled,(a6)
		rts
		
; -----------------------
; Setup channels
; -----------------------

SMEG_Load_SetChnls:
		movea.l	d0,a4				;a4 - Music data
		move.w	d1,TicksSet(a6)

; -----------------------
; Get instruments
; -----------------------

		move.l	(a4)+,SongVoices(a6)
		move.l	(a4)+,SongSampl(a6)
		move.l	(a4)+,SongPcmSamp(a6)
	
; -----------------------
; Get the
; PatternEnd/PatternLoop
; numbers
; -----------------------

		move.b	(a4)+,PatternEnd(a6)
		move.b	(a4)+,PatternLoop(a6)

; -----------------------
; Setup the channel IDs
; -----------------------

		moveq	#(MaxChannels)-1,d4
@SetId:
		move.b	#1,Chn_Type(a5)
		move.b	(a4)+,Chn_ID(a5)
		clr.w	Chn_Freq(a5)
		
; 		tst.b	Chn_ID(a5)
; 		bmi.s	@NotFM
; 		cmp.b	#PCM_1,Chn_ID(a5)
; 		bge.s	@NotFM

; 		clr.b	Chn_FM_Key(a5)
; 		move.b	#%00001111,Chn_FM_Key(a5)
; 		move.b	#$C0,Chn_Panning(a5)
; 		bsr	SMEG_FM_SetPan

@NotFM:
		adda 	#sizeof_Chn,a5
		dbf	d4,@SetId

; -----------------------
; Master volumes
; -----------------------

		moveq	#(MaxChannels)-1,d0
@SetVol:
		move.b	(a4)+,Chn_DefVol(a5)
		adda 	#sizeof_Chn,a5
		dbf	d0,@SetVol

; -----------------------
; last steps
; -----------------------

		move.l	a4,SongStart(a6)
		move.b	(a4)+,PattSize+1(a6)
		move.b	(a4)+,PattSize(a6)
		clr.w	PattRead(a6)
		adda	#6,a4
		move.l	a4,SongRead(a6)
		rts
		
; -----------------------
; Exclusive features
; -----------------------

SMEG_Load_SetExtChnls:
		if SegaCD

 		moveq	#CdTask_ClearAllPcm,d0
 		bsr	SMEG_CD_Call
		
 		lea	(RAM_SMEG_Buffer),a6
 		tst.l	SongPcmSamp(a6)
 		beq	@Return
 		
 		movea.l	SongPcmSamp(a6),a5
 		moveq	#0,d1
 		lea	(RAM_SMEG_PcmList),a4
@NextSamp:
 		tst.w	(a5)
 		bmi.s	@Finish
 		move.b	d1,(a4)				;ST Address

 		move.w	$E(a5),d0
 		and.w	#$FF,d0
 		move.b	d0,1(a4)
 		move.l	(a5),(ThisCpu+CommDataM)	;\
 		move.l	4(a5),(ThisCpu+CommDataM+4)	; > Filename
 		move.l	8(a5),(ThisCpu+CommDataM+8)	;/
 		move.w	#0,(ThisCpu+CommDataM+$C)
 		move.b	d1,(ThisCpu+CommDataM+$D)	;Bank to use
 		moveq	#CdTask_LoadPcm,d0
  		bsr	SMEG_CD_Call
  		
  		moveq	#0,d2
  		moveq	#0,d3
 		move.w	(ThisCpu+CommDataS+2),d2
 		cmp.w	#$FFFF,$C(a5)
 		beq.s	@NotLoop
 		move.w	$C(a5),d2
@NotLoop:
; 		move.b	d1,d3
; 		and.w	#$7F,d3
; 		lsl.w	#8,d3
; 		lsl.w	#4,d3
; 		add.w 	d3,d2
		
 		move.w	d2,2(a4)			;Loop address
 		move.b	(ThisCpu+CommDataS),d1		;Next ST
 		
 		adda	#$10,a5
 		adda	#4,a4
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
   		moveq	#0,d5
@NextSamp:
    		tst.w	(a5)
    		bmi.s	@Finish

    		move.l	(a5)+,(marsreg+comm12)		;Sample addr (start/end)
    		move.w	(a5)+,(marsreg+comm10)		;Sample loop
    		move.w	(a5)+,d4
    		move.b	d4,(marsreg+comm2+1)		;Note transpose
    		move.b	d5,(marsreg+comm2)		;Sample slot
   		moveq	#marscall_SetEntry,d0
   		bsr	SMEG_MARS_Call
       		
        	add.w	#1,d5
 		bra.s	@NextSamp
@Finish:
  		adda	#2,a5
  		move.l	a5,SongPcmSamp(a6)		;Second list		
 		endif
		
@Return:
		rts

; -----------------------
; Fix stuff to BGM
; -----------------------

SMEG_Load_FixBgm:
		lea	(RAM_SMEG_Chnls_BGM),a5
		moveq	#(MaxChannels)-1,d4
@SetId:
		move.b	#$80,Chn_Panning(a5)

		tst.b	Chn_ID(a5)
		bmi.s	@NotFM
		cmp.b	#PCM_1,Chn_ID(a5)
		bge.s	@NotFM

		clr.b	Chn_FM_Key(a5)
		move.b	#%00001111,Chn_FM_Key(a5)
		move.b	#$C0,Chn_Panning(a5)
		bsr	SMEG_FM_SetPan

@NotFM:
		adda 	#sizeof_Chn,a5
		dbf	d4,@SetId
		rts
		
; ================================================================
; -------------------------------------------
; Run
; -------------------------------------------

SMEG_Upd:
		lea	(RAM_SMEG_Buffer),a6
		move.l	#RAM_SMEG_Chnls_BGM,ChannelList(a6)
		bset	#bitPriority,(a6)
                bsr	@ReadRow
                
 		lea	(RAM_SMEG_SfxBuff),a6
		bclr	#bitPriority,(a6)
                btst	#bitSfxOn,(a6)				;Want to play SFX?
                beq.s	@Wait
		move.l	#RAM_SMEG_Chnls_SFX,ChannelList(a6)
		bsr	@ReadRow
@Wait:
		rts

; -------------------------------------------
; Read row
; -------------------------------------------

@ReadRow:
		btst	#bitDisabled,(a6)
		bne.s	@Wait

		sub.w	#1,TicksRead(a6)
		bpl.s	@Wait
 		move.w	TicksSet(a6),TicksRead(a6)

                movea.l	SongRead(a6),a4
		moveq	#0,d5

; --------------------------------
; New pattern
; --------------------------------

@Next:
 		move.w	PattSize(a6),d1
  		sub.w	#1,d1
 		cmp.w	PattRead(a6),d1
 		bcc.s	@NoNextRow
		clr.w	PattRead(a6)

		move.b	PatternEnd(a6),d1
		move.b	CurrPattern(a6),d0
		cmp.b	d0,d1
		bgt.s	@NotEnd

		movea.l	SongStart(a6),a0
		move.b	(a0)+,PattSize+1(a6)
		move.b	(a0)+,PattSize(a6)
		adda	#6,a0
		move.l	a0,SongRead(a6)
		clr.w	PattRead(a6)
		move.b	PatternLoop(a6),CurrPattern(a6)
		clr.w	TicksRead(a6)
		bra 	@ReadRow

; --------------------------------

@NotEnd:
		add.b	#1,CurrPattern(a6)

		moveq	#0,d0
		move.b	CurrPattern(a6),d0
		cmp.b	PatternLoop(a6),d0
		bne.s	@DontSaveLoop
		move.l	a4,SongStart(a6)

@DontSaveLoop:
		move.b	(a4)+,PattSize+1(a6)
		move.b	(a4)+,PattSize(a6)
		adda	#6,a4

; --------------------------------
; Current pattern
; --------------------------------

@NoNextRow:
		moveq	#0,d6
		moveq	#0,d0
		move.b	(a4)+,d0

		tst.b	d0
		bne.s	@ValidNote

		add.w	#1,PattRead(a6)
		move.l	a4,SongRead(a6)
		rts

@ValidNote:
		tst.b	d0
		bpl.s	@Not80
		add.w	#1,PattRead(a6)
		bclr	#7,d0
		move.b	(a4)+,d6

@Not80:
		add.w	#1,PattRead(a6)

		sub.w	#1,d0
		move.b	d0,LastPattChn(a6)
		lea	UsedChnBuff(a6),a3
		adda 	d0,a3
		move.b	#1,(a3)

                movea.l	ChannelList(a6),a5
                tst.w	d0
                beq.s	@First
                sub.w	#1,d0
@NextChn:
		adda	#sizeof_Chn,a5
		dbf	d0,@NextChn
@First:
		
		tst.w	d6
		beq.s	@NotRest
		clr.b	Chn_Type(a5)
		move.b	d6,Chn_Type(a5)

@NotRest:

; -------------
; Note
; -------------

		btst	#bitSameNote,Chn_Type(a5)
		bne.s	@PlayOnly
		btst	#bitNote,Chn_Type(a5)
		beq.s	@NoNote

                move.b	(a4)+,Chn_Note(a5)
		add.w	#1,PattRead(a6)

@PlayOnly:
		bsr	SMEG_ChannelRest
		
; -------------
; Instrument
; -------------

@NoNote:
 		btst	#bitSameInst,Chn_Type(a5)
		bne.s	@SameInst
		btst	#bitInst,Chn_Type(a5)
		beq.s	@NoInst

		move.b	(a4)+,Chn_Inst(a5)
		add.w	#1,PattRead(a6)

		bsr	SMEG_SetVoice
@SameInst:

; -------------
; Volume
; -------------

@NoInst:
 		btst	#bitSameVol,Chn_Type(a5)
 		bne.s	@SameVol
		btst	#bitVolume,Chn_Type(a5)
		beq.s	@NoVolume

		clr.w	Chn_Portam(a5)
		clr.w	Chn_Effect(a5)
                moveq	#0,d0
		move.b	(a4)+,d0
		add.w	#1,PattRead(a6)
		sub.w	#64,d0
		neg.w	d0
                move.b	d0,Chn_Vol(a5)

@SameVol:
		bsr	@ChnVolume

; -------------
; Effect
; -------------

@NoVolume:
 		btst	#bitSameEffect,Chn_Type(a5)
 		bne.s	@SameEffect
		btst	#bitEffect,Chn_Type(a5)
		beq.s	@NoEffect

		move.b	(a4)+,Chn_Effect(a5)
		add.w	#1,PattRead(a6)
		move.b	(a4)+,Chn_Effect+1(a5)
		add.w	#1,PattRead(a6)

@SameEffect:
		bsr	@ChannelEffects

; --------------
; Play the note
; --------------

@NoEffect:
 		btst	#bitSameNote,Chn_Type(a5)
 		bne.s	@SameNote
		btst	#bitNote,Chn_Type(a5)
		beq	@Next
@SameNote:
		bsr	@ChannelPlay
		bra	@Next

; ================================================================
; -------------------------------
; Set Freq
; -------------------------------

@NoteFreq:
		cmp.w	#$FF,d0
		beq.s	@ResetFreq
		cmp.w	#$FE,d0
		beq.s	@ResetFreq
		
		cmp.b	#PCM_1,Chn_ID(a5)
		bge	@PCM_Freq
		
		tst.b	Chn_ID(a5)
		bmi.s	@PSG_Freq
                cmp.b	#FM_6,Chn_ID(a5)
                bne.s	@NoChk6
		btst	#bitDacOn,DrvSettings(a6)
		bne	@DAC_Set

@NoChk6:
                moveq	#0,d1
                move.b	d0,d1
                moveq	#0,d2
		add.w	d1,d1
		lea	@Notes_FM(pc),a0
		move.w	(a0,d1.w),Chn_Freq(a5)
		rts

@ResetFreq:
		clr.w	Chn_Freq(a5)
		rts
		
; -------------------------------
; PSG Freq
; -------------------------------

@PSG_Freq:
		cmp.b	#NOISE,Chn_ID(a5)
		bne.s	@NotNoise

		move.w	#1,Chn_Freq(a5)
		btst	#bitTone3,DrvSettings(a6)
		beq	@Disabled

@NotNoise:
                moveq	#0,d1
                move.b	d0,d1
		add.w	d1,d1
		lea	@Notes_PSG(pc),a2
		cmp.b	#NOISE,Chn_ID(a5)
		bne.s	@NotNoiseFix
		adda	#24,a2
@NotNoiseFix:
		lea	(a2,d1.w),a1
		move.w	(a1),Chn_Freq(a5)
		sub.w	#1,Chn_Freq(a5)
		rts

; -------------------------------
; Set DAC
; -------------------------------

@DAC_Set:
		clr.w	Chn_Freq(a5)
                move.b	d0,Chn_Freq(a5)
  		bra	SMEG_SetVoice_DAC
                ;rts

; -------------------------------
; Set Pcm
; -------------------------------

@PCM_Freq:
		if SegaCD
		
  		moveq	#0,d1
  		move.b	Chn_ID(a5),d1
  		and.b	#$F,d1
                moveq	#0,d1
                move.b	d0,d1
		add.b	Chn_PCM_Pitch(a5),d1
		lsl.w	#1,d1
		lea	@Notes_PCM(pc),a0
		move.w	(a0,d1.w),d1
 		add.w	#8,d1
		move.w	d1,Chn_Freq(a5)
		
		elseif MARS
		
		move.w	#1,Chn_Freq(a5)
		
		endif
		rts
		
; -------------------------------

@Notes_FM:
; 		dc.w $269
		dc.w $28d
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
		dc.w $28d
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
		dc.w $a8d
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
		dc.w $128d
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
		dc.w $1a8d
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
		dc.w $228d
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
		dc.w $2a8d
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
		dc.w $3269
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

@Notes_PSG:
		dc.w 0		;x-0
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
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0

		dc.w 0		;x-1
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
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w 0

		dc.w $3F8
                dc.w $3BF
                dc.w $389
		dc.w $356
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
                dc.w $1AB
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
                dc.w $D6
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
                dc.w $6B
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
		dc.w $36
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
                dc.w $1B
                dc.w $1A
                dc.w $18
                dc.w $17
                dc.w $16
                dc.w $15
                dc.w $13
                dc.w $12
		dc.w $11

; 		dc.w $10 ;Custom...
; 		dc.w $9
; 		dc.w $8
; 		dc.w $7
; 		dc.w $6
; 		dc.w $5
; 		dc.w $4
; 		dc.w $3
; 		dc.w $2
; 		dc.w $1
;                 dc.w 0
		even

		if SegaCD
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
		cmp.b	#$FF,Chn_ID(a5)
		beq	@Return

		cmp.b	#PCM_1,Chn_ID(a5)
		bge	@ChnVol_PCM
		tst.b	Chn_ID(a5)
		bmi	@ChnVol_PSG

		lea	SMEG_RegSetVol-1(pc),a2

		movea.l	SongVoices(a6),a1
		moveq	#0,d0
		move.b	Chn_Inst(a5),d0

@FindNext:
		tst.w	(a1)
		bmi	@Return
		moveq	#0,d1
		move.w	2(a1),d1
		cmp.w	(a1),d0
		beq.s	@Found
 		adda.w	#8,a1
		bra.s	@FindNext

@Found:
		adda.w	#4,a1
		movea.l	(a1),a1
		tst.w	d1
		beq.s	@Nothing
@FindNext2:
		adda	#$19,a1
		dbf	d1,@FindNext2
@Nothing:
		adda	#$18,a1

		move.b	#$28,d0
		moveq	#0,d1
		add.b	Chn_ID(a5),d1
		Z80_OFF
		bsr	FM_RegWrite_1
		Z80_ON

		moveq	#1,d7
@TryNext:
		moveq	#0,d1
		move.b	(a1),d1
		add.b	Chn_DefVol(a5),d1
		add.b	Chn_Vol(a5),d1

                moveq	#0,d3
                move.b	Chn_ID(a5),d3
                moveq	#0,d0
                move.b	(a2),d0
                cmp.b	#$4C,d0
		beq.s	@Is4C
		tst.b	(a1)
		bne.s	@Return

@Is4C:
                suba	#2,a2
                suba	#2,a1

                cmp.b	#FM_4,Chn_ID(a5)
                bge.s	@FM456_2
		add.b	d3,d0

		Z80_OFF
		bsr	FM_RegWrite_1
		Z80_ON
		dbf	d7,@TryNext
		rts

@FM456_2:
		sub.w	#4,d3
		add.b	d3,d0

		Z80_OFF
		bsr	FM_RegWrite_2
		Z80_ON
		dbf	d7,@TryNext

@Return:
		rts

; -------------------------------

@ChnVol_PSG:
		moveq	#0,d1
		move.b	Chn_Vol(a5),d1
		move.w	#$F,d0
		tst.w	d1
		beq.s	@DontFix

		sub.w	#64,d1
		neg.w	d1
		lsr.w	#2,d1
		move.w	d1,d0

	;	move.b	Chn_DefVol(a5),d3
	;	lsr.w	#2,d3
	;	add.w	d3,d0
	;	moveq	#$F,d0
	;	sub.w	d2,d0
	;	cmp.w	#$F,d0
	;	beq.s	@DontFix
	;	sub.w	#1,d0
	
@DontFix:
		moveq	#0,d1
		move.b	Chn_ID(a5),d1
		bclr	#7,d1
		lsr.w	#5,d1
		
		and.b	#$F,d0
		and.b	#$3,d1
		moveq	#0,d2
		move.b	#$F,d2
		sub.b	d0,d2
		or.b	#%10010000,d2
		lsl.b	#$5,d1
		or.b	d1,d2
		move.b	d2,($C00011).l	;$90+channel<<5+($f-vol)
		rts

; -------------------------------

@ChnVol_PCM:
		if SegaCD
		
 		moveq	#0,d2
 		moveq	#0,d1
 		move.b	#$F0,d2				;$xx00
    		move.b	Chn_DefVol(a5),d1
      		lsr.w	#4,d1
     		lsl.w	#4,d1
   		sub.b	d1,d2
    		move.b	Chn_Vol(a5),d1
      		lsr.w	#4,d1
     		lsl.w	#4,d1
    		sub.b	d1,d2
   		
 		moveq	#0,d1
 		move.b	Chn_ID(a5),d1
 		and.w	#$F,d1
 		move.b	d1,(ThisCpu+CommDataM)
 		move.b	d2,(ThisCpu+CommDataM+1)
 		moveq	#CdTask_SetEnv,d0
 		bsr	SMEG_CD_Call

 		elseif MARS
   		
    		moveq	#0,d1
    		move.b	Chn_ID(a5),d1
    		and.w	#$F,d1
    		moveq	#1,d2			;TODO: TEMPORAL
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
; Flag D - Change Vol
; -------------------------------

@Flag_D:
		moveq	#0,d0
		move.b	Chn_Effect+1(a5),d0
		tst.b	Chn_ID(a5)
		bpl	@NotPSG
		lsl.w	#4,d0
@NotPSG:
		add.b	d0,Chn_Vol(a5)
		bra	@ChnVolume

; -------------------------------
; Flag E - Portametro down
; -------------------------------

@Flag_E:
		moveq	#0,d0
		move.b	Chn_Effect+1(a5),d0
		clr.b	Chn_Portam(a5)
		add.b	d0,Chn_Portam+1(a5)
		rts

; -------------------------------
; Flag F - Portametro up
; -------------------------------

@Flag_F:
		moveq	#0,d0
		move.b	Chn_Effect+1(a5),d0
		clr.b	Chn_Portam+1(a5)
		add.b	d0,Chn_Portam(a5)
		rts

; -------------------------------
; Flag M - Set Channel Volume
; -------------------------------

@Flag_M:
		moveq	#0,d0
		move.b	Chn_Effect+1(a5),d0
	;	tst.b	Chn_ID(a5)
	;	bpl	@NotPSG_H

		neg.w	d0
		sub.w	#$D0,d0
;@NotPSG_H:
		move.b	d0,Chn_DefVol(a5)
		bra	@ChnVolume

; -------------------------------
; Flag X - Stereo
; -------------------------------

@Flag_X:
		tst.b	Chn_ID(a5)
		bmi.s	@Null
		cmp.b	#PCM_1,Chn_ID(a5)
		bge	@PCM_Pan
		
		moveq	#0,d0
		move.w	#$C0,d0
                cmp.b	#$80,Chn_Effect+1(a5)
                beq.s	@SetPan
		tst.b	Chn_Effect+1(a5)
		bmi.s	@Right
		bpl.s	@Left
@SetPan:
		move.b	d0,Chn_Panning(a5)
		rts
@Left:
		move.w	#$80,d0
		bra.s	@SetPan
@Right:
		move.w	#$40,d0
		bra.s	@SetPan

; -------------------------------
; PCM Panning
; -------------------------------

@PCM_Pan:
		if SegaCD
		
		moveq	#0,d0
		move.b	#%11001100,d0				;TODO: dejarlo así
		cmp.b	#$80,Chn_Effect+1(a5)
		beq.s	@Return2
                 
 		tst.b	Chn_Effect+1(a5)
 		bmi.s	@Right2
		bpl.s	@Left2
		bra	@Return2
@Right2:
 		move.b	#%10000000,d0
 		bra	@Return2
@Left2:
		move.b	#%00001000,d0
@Return2:
		move.b	d0,Chn_Panning(a5)

; -------------------------------------------------

 		elseif MARS
 
		move.w	#%11000000,d0
		move.b	d0,Chn_Panning(a5)
		cmp.b	#$80,Chn_Effect+1(a5)
		beq	@Return
 		tst.b	Chn_Effect+1(a5)
 		bmi.s	@pwmRight
		bpl.s	@pwmLeft
		bra	@Cont
 		
@pwmRight:
 		move.w	#%01000000,d0
 		bra.s	@Cont
@pwmLeft:
		move.w	#%10000000,d0

@Cont:
		move.b	d0,Chn_Panning(a5)   		
		endif
		rts

; ======================================================
; ; -------------------------------------
; ; FM
; ; -------------------------------------
; 
; @FmChn3On:
; 		moveq	#$27,d0
; 		moveq	#0,d1
; 		move.w	#%01000000,d1
; 		Z80_OFF
; 		bsr	FM_RegWrite_1
; 		Z80_ON
; 		rts
; 
; @FmChn3Off:
; 		moveq	#$27,d0
; 		moveq	#0,d1
; 		Z80_OFF
; 		bsr	FM_RegWrite_1
; 		Z80_ON
; 		rts
;

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

@HashList:	dc.w	@DacStatus-@HashList		;$00 - Status
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
		and.w	#3,d0
		move.b	d0,DrvSettings(a6)
		
		Z80_OFF
		move.b	d0,d1
		and.w	#1,d1
		lsl.w	#7,d1
		moveq	#$2B,d0
		bsr	FM_RegWrite_1
		Z80_ON
		
		bra	SMEG_SetVoice_DAC

; -------------------------------

@FM_Key:
		and.w	#$F,d0
		move.b	d0,Chn_FM_Key(a5)
		rts

; -------------------------------

@PSG:
		bset	#bitTone3,DrvSettings(a6)
		cmp.b	#3,d0
		beq.s	@Tone3
		cmp.b	#7,d0
		beq.s	@Tone3
		bclr	#bitTone3,DrvSettings(a6)
@Tone3:
 		btst	#bitPriority,(a6)
 		beq.s	@IsPsg
 		lea	(RAM_SMEG_Buffer),a3
		move.b	DrvSettings(a3),DrvSettingsBGM(a3)
		move.b	d0,PsgLast(a3)
@IsPsg:
		add.w	#$E0,d0
		bra	@PutPSG

; -------------------------------

@FixSfx:
  		btst	#bitPriority,(a6)
  		bne	@Return
		
 		lea	(RAM_SMEG_Buffer),a3
		move.b	DrvSettingsBGM(a3),DrvSettingsBGM(a3)
		moveq 	#0,d0
 		move.b	PsgLast(a3),d0
  		bclr	#bitSfxOn,(a6)				;SFX finished playing
		add.w	#$E0,d0
		bra	@PutPSG

; -------------------------------

@PutPSG:
		move.b	d0,($C00011)
		rts
		
; ================================================================
; -------------------------------
; Channel play
; -------------------------------

@ChannelPlay:
		cmp.b	#$FF,Chn_ID(a5)
		beq	@Disabled

                moveq	#0,d0
		move.b	Chn_Note(a5),d0
		tst.b	Chn_Portam(a5)
		beq.s	@NoUp
		add.b	Chn_Portam(a5),d0
		bra.s	@NoDown
@NoUp:
		tst.b	Chn_Portam+1(a5)
		beq.s	@NoDown
		sub.b	Chn_Portam+1(a5),d0
@NoDown:
		bsr	@NoteFreq

@Continue:
		move.w	Chn_Freq(a5),d4
		beq	SMEG_ChannelRest
		tst.w	d4
		bmi	SMEG_ChannelRest

		cmp.b	#PCM_1,Chn_ID(a5)
		bge	@ChannelPlay_PCM
                cmp.b	#6,Chn_ID(a5)
                bne	@NoChk6_play
		btst	#bitDacOn,DrvSettings(a6)
		bne	@ChannelPlay_DAC

@NoChk6_play:

		tst.b	Chn_ID(a5)
		bmi	@ChannelPlay_PSG

		bsr	SMEG_FM_SetPan

		moveq	#$28,d0
		moveq	#0,d1
		add.b	Chn_ID(a5),d1
		Z80_OFF
		bsr	FM_RegWrite_1
		Z80_ON

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
		lsl.w	#4,d1
		add.b	Chn_ID(a5),d1
		Z80_OFF
		bsr	FM_RegWrite_1
		Z80_ON

@Disabled:
		rts

; -------------------------------
; Play PSG
; -------------------------------

@ChannelPlay_PSG:
		cmp.b	#$E0,Chn_ID(a5)
		beq.s	@PlayNoise

                cmp.b	#$C0,Chn_ID(a5)
                bne.s	@NotPsg3
		btst	#bitTone3,DrvSettings(a6)
		beq.s	@NotPsg3
		move.b	#$DF,($C00011).l
                rts

@NotPsg3:
		moveq	#0,d1
		move.w	Chn_Freq(a5),d0
		move.b	Chn_ID(a5),d1
		bclr	#7,d1
		lsr.w	#5,d1
		bra	@SetFreq

@PlayNoise:
		btst	#bitTone3,DrvSettings(a6)
		beq.s	@Disabled

		move.w	Chn_Freq(a5),d0
		moveq	#2,d1

;---------------------
; Set frequency
;
; d0 - frequency (0-$3ff)
; d1 - channel (0, 1, 2)
;---------------------

@SetFreq:
		move.b	d0,d2
		and.b	#$F,d2
		add.b	#$80,d2
		and.b	#$3,d1
		lsl.b	#$5,d1
		or.b	d1,d2
		move.b	d2,($C00011).l	;$80+channel<<5+(freq&$f)
		lsr.w	#$4,d0
		move.b	d0,($C00011).l	;freq>>4
		rts
		
; -------------------------------
; Play DAC
; -------------------------------

@ChannelPlay_DAC:
; 		btst	#bitDacNote,DrvSettings(a6)
; 		bne	@FoundIt

		moveq	#0,d1
		moveq 	#0,d2
		move.b	Chn_Note(a5),d1
  		move.b 	Chn_PCM_Pitch(a5),d2
  		add.w	d2,d1
      		sub.w	#12,d1
		lsl.w	#6,d1
		lea	SMEG_DacNoteList(pc),a0
		lea	(a0,d1.w),a1
@FoundIt:
		Z80_OFF
		lea	($A00200),a2
		moveq	#$3F,d2
@copy:
		move.b	(a1)+,(a2)+
		dbf	d2,@copy
		
		moveq	#0,d0				;TODO: Loop flag
		lsl.b	#1,d0
		bset	#0,d0
		move.b	d0,($A00180+$D)
		Z80_ON
		rts

; -------------------------------
; Play PCM
; -------------------------------

@ChannelPlay_PCM:
		if SegaCD
		
 		moveq	#0,d1
 		move.b	Chn_ID(a5),d1
   		and.w	#$F,d1
 		move.b	d1,(ThisCpu+CommDataM)
 		move.b	Chn_Panning(a5),d1
 		move.b	d1,(ThisCpu+CommDataM+1)
 		moveq	#CdTask_SetPan,d0
 		bsr	SMEG_CD_Call
 		
		moveq	#0,d1
		move.b	Chn_ID(a5),d1
		and.b	#$F,d1
		move.b	d1,(ThisCpu+CommDataM)
		move.w	Chn_Freq(a5),(ThisCpu+CommDataM+2)
		moveq	#CdTask_SetFreq,d0
		bsr	SMEG_CD_Call
		bset	d1,PcmChnOnOff(a6)
		move.b	PcmChnOnOff(a6),(ThisCpu+CommDataM)
		moveq	#CdTask_SetOnOff,d0
		bsr	SMEG_CD_Call
		
 		elseif MARS

  		moveq	#0,d1
  		moveq	#0,d2
       		move.b	Chn_ID(a5),d1
     		and.w	#$F,d1
      		add.b	Chn_Panning(a5),d1
      		move.b	Chn_Note(a5),d2
  		move.b	d1,(marsreg+comm2)			; Pan+Channel set
  		move.b	d2,(marsreg+comm2+1)			; Note
  		moveq 	#marscall_Play,d0
  		bsr	SMEG_MARS_Call
  		
 		endif
 		
		rts

; -------------------------------
; Mute/Rest channel
; -------------------------------

SMEG_ChannelRest:
		cmp.b	#$FF,Chn_ID(a5)
		beq.s	@Return
; 		cmp.b	#$FF,Chn_ForceMute(a5)
; 		beq.s	@Return

		moveq	#0,d0
		move.b	LastPattChn(a6),d0
		lea	UsedChnBuff(a6),a3
		adda	d0,a3
		clr.b	(a3)

		tst.b	Chn_ID(a5)
		bmi.s	@PSG_Rest

                cmp.b	#6,Chn_ID(a5)
                bne.s	@NoChk6
		btst	#bitDacOn,DrvSettings(a6)
		bne.s	@DAC_Rest

@NoChk6:
		cmp.b	#PCM_1,Chn_ID(a5)
		bge	@PCM_Rest
		
		moveq	#$28,d0
                moveq	#0,d1
		move.b	Chn_ID(a5),d1
		Z80_OFF
		bsr	FM_RegWrite_1
		Z80_ON

@Return:
		rts

; -------------------------------
; PSG Rest
; -------------------------------

@PSG_Rest:
		moveq	#0,d0
		move.b	Chn_ID(a5),d0
		add.b	#$1F,d0
		move.b	d0,($C00011)

@Disabled:
		rts

; -------------------------------
; DAC Rest
; -------------------------------

@DAC_Rest:
		moveq	#$2B,d0
                moveq	#0,d1
  		Z80_OFF
  		bsr	FM_RegWrite_1
; 		bset	#0,($A00140)
		Z80_ON
		rts

; -------------------------------
; PCM Rest
; -------------------------------

@PCM_Rest:
 		if SegaCD
 		
		moveq	#0,d1
		move.b	Chn_ID(a5),d1
		and.b	#$F,d1
		bclr	d1,PcmChnOnOff(a6)
		move.b	PcmChnOnOff(a6),(ThisCpu+CommDataM)
		moveq	#CdTask_SetOnOff,d0
		bsr	SMEG_CD_Call
		
 		elseif MARS
 		
  		moveq	#0,d0
  		move.b	Chn_ID(a5),d0
  		and.w	#$F,d0
  		move.b	d0,(marsreg+comm2)
  		moveq	#marscall_Stop,d0
  		bsr	SMEG_MARS_Call
    		
		endif
		rts
		
; ================================================================
; Subs
; ================================================================

; -------------------------------------------
; Set instrument
; -------------------------------------------

SMEG_SetVoice:
; 		cmp.b	#$FF,Chn_ForceMute(a5)
; 		beq	@Return

		tst.b	Chn_ID(a5)
		bmi	@IsPsg

                cmp.b	#6,Chn_ID(a5)
                bne.s	@NoChk6_Voice
		btst	#bitDacOn,DrvSettings(a6)
		bne	SMEG_SetVoice_DAC
@NoChk6_Voice:
		cmp.b	#PCM_1,Chn_ID(a5)
		bge	SMEG_SetVoice_PCM
		
		moveq	#0,d0
		move.b	Chn_ID(a5),d0
		cmp.b	#4,d0
		blt.s	@Low3
		sub.b	#4,d0
@Low3:
		movea.l	SongVoices(a6),a3
		moveq	#0,d6
		move.b	Chn_Inst(a5),d6
@FindNext:
		tst.w	(a3)
		bmi	@Return
		moveq	#0,d1
		move.w	2(a3),d1
		cmp.w	(a3),d6
		beq.s	@Found
 		adda.w	#8,a3
		bra.s	@FindNext

@Found:
		adda.w	#4,a3

		movea.l	(a3),a3
		tst.w	d1
		beq.s	@Nothing
		sub.w	#1,d1
@NextFM:
		adda	#$19,a3
		dbf	d1,@NextFM

@Nothing:
		swap	d0
		move.w	#$28,d0
		moveq	#0,d1
		move.b	Chn_ID(a5),d1
		Z80_OFF
		bsr	FM_RegWrite_1
		Z80_ON
		swap	d0

		lea	SMEG_FM_RegList(pc),a1
		move.w	d0,d6
		moveq	#$18,d4
@Next:
		move.w	d6,d5
		move.b	(a1)+,d0
		move.w	d0,d3
		add.w	d5,d0
		move.b	(a3)+,d1

		cmp.b	#4,Chn_ID(a5)
		bge.s	@Chn456
		Z80_OFF
		bsr	FM_RegWrite_1
		Z80_ON
		dbf	d4,@Next
		rts

@Chn456:
		Z80_OFF
		bsr	FM_RegWrite_2
		Z80_ON
		dbf	d4,@Next
@Return:
		rts

; ---------------------------------

@IsPsg:
		rts

; -------------------------------------------------
; Set FM panning
; -------------------------------------------------

SMEG_FM_SetPan:
		tst.b	Chn_ID(a5)
		bmi.s	@Return
		
		move.w	#$B4,d0
		moveq	#0,d2
		move.b	Chn_ID(a5),d2
		moveq	#0,d1
		move.b	Chn_Panning(a5),d1

		cmp.b	#3,d2
		bgt.s	@SecondFM

		add.w	d2,d0
		Z80_OFF
		bsr	FM_RegWrite_1
		Z80_ON
@Return:
		rts

@SecondFM:
		sub.w	#4,d2
		add.w	d2,d0
		Z80_OFF
		bsr	FM_RegWrite_2
		Z80_ON
		rts
		
; ---------------------------------
; Send DAC
; ---------------------------------

SMEG_SetVoice_DAC:
		movea.l	SongSampl(a6),a0
		moveq	#0,d1
		move.b	Chn_Inst(a5),d1

@FindSample:
		tst.w	(a0)
		bmi.s	@Return
		cmp.w	(a0),d1
		beq.s	@Found
 		adda	#$10,a0
		bra.s	@FindSample

@Found:
		adda.w	#2,a0

		Z80_OFF
		bsr.s	@Z80_LoadWav
		Z80_ON

@Return:
		rts

; ---------------------------------

@Z80_LoadWav:
		lea	($A00180),a1
		moveq	#0,d0
		move.w	(a0)+,d0
  		move.b 	d0,Chn_PCM_Pitch(a5)
		move.l	(a0)+,d0
		move.l	(a0)+,d1
		move.l	(a0)+,d2
  		
		;Start
		moveq	#0,d4
		tst.w	d0
		bpl.s	@plus_s
		move.w	#$81,d4
@plus_s:
		swap	d0
		swap	d4
		move.b	d0,d4
		swap	d4
		swap	d0
		move.b	d4,(a1)+		;start Bank	+$8000
		swap	d4
		move.b	d4,(a1)+		;		$xx0000
		swap	d4
		move.b	d0,(a1)+		;start Addr	$00xx
		lsr.w	#8,d0
		move.b	d0,(a1)+		;		$xx00
		
		;Loop
		moveq	#0,d4
		tst.w	d1
		bpl.s	@plus_e
		move.w	#$81,d4
@plus_e:
		swap	d1
		swap	d4
		move.b	d1,d4
		swap	d4
		swap	d1
		move.b	d4,(a1)+		;start Bank	+$8000
		swap	d4
		move.b	d4,(a1)+		;		$xx0000
		swap	d4
		move.b	d1,(a1)+		;start Addr	$00xx
		lsr.w	#8,d1
		move.b	d1,(a1)+		;		$xx00
		
		;End
		moveq	#0,d4
		tst.w	d2
		bpl.s	@plus_l
		move.w	#$81,d4
@plus_l:
		swap	d2
		swap	d4
		move.b	d2,d4
		swap	d4
		swap	d2
		move.b	d4,(a1)+		;start Bank	+$8000
		swap	d4
		move.b	d4,(a1)+		;		$xx0000
		swap	d4
		move.b	d2,(a1)+		;start Addr	$00xx
		lsr.w	#8,d2
		move.b	d2,(a1)+		;		$xx00
		
		rts

; ---------------------------------
; Send PCM/PWM
; ---------------------------------

SMEG_SetVoice_PCM:
		if SegaCD
   		
		movea.l	SongPcmSamp(a6),a0
		moveq	#0,d1
		move.b	Chn_Inst(a5),d1
@NextPcm:
		tst.w	(a0)
		bmi.s	@FinishList
		move.b	(a0),d2
		cmp.b	d1,d2
		beq.s	@FoundPcm
		adda	#2,a0
		bra.s	@NextPcm

@FoundPcm:
		lea	(RAM_SMEG_PcmList),a1
		moveq	#0,d1
		move.b	1(a0),d1
		sub.w	#1,d1
		lsl.w	#2,d1
		adda	d1,a1
		
		move.b	1(a1),Chn_PCM_Pitch(a5)
		move.b	Chn_ID(a5),(ThisCpu+CommDataM)
		move.b	(a1),(ThisCpu+CommDataM+1)
		move.w	2(a1),(ThisCpu+CommDataM+2)
		moveq	#CdTask_SetAddr,d0
		bra	SMEG_CD_Call
		
; ---------------------------------

		elseif MARS
   		
    		moveq	#0,d1
   		moveq	#0,d2
   		moveq	#0,d3
     		movea.l	SongPcmSamp(a6),a0
    		move.b	Chn_Inst(a5),d1
@NextPcm:
     		tst.w	(a0)
     		bmi.s	@GiveUp
     		move.b	(a0),d2
     		cmp.b	d1,d2
     		beq.s	@FoundPcm
     		adda	#2,a0
     		bra.s	@NextPcm
   
@FoundPcm:
  		move.b	1(a0),d1
  
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
		
; ---------------------
; Reset FM
; ---------------------

SMEG_FM_Reset:
		Z80_OFF

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

		Z80_ON
		rts

; ---------------------
; Find FM
; ---------------------

SMEG_FM_FindWrite:
		cmp.b	#4,Chn_ID(a5)
		bge.s	@Second
		Z80_OFF
		bsr	FM_RegWrite_1
		Z80_ON
		rts
@Second:
		Z80_OFF
		bsr	FM_RegWrite_2
		Z80_ON
		rts

;-----------------------
; Write to FM register
;-----------------------

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
		bne.s	FM_RegWrite_1
		move.b	d0,($A04002).l
@Loop:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	@Loop
		move.b	d1,($A04003).l
		rts
		
; ---------------------
; Reset PSG
; ---------------------

SMEG_PSG_Reset:
		move.b	#$9F,($C00011).l
		move.b	#$BF,($C00011).l
		move.b	#$DF,($C00011).l
		move.b	#$FF,($C00011).l
		rts

; ---------------------
; Reset PCM
; ---------------------

SMEG_PCM_Reset:
		if SegaCD
		
		lea	(RAM_SMEG_Buffer),a0
		clr.b	PcmChnOnOff(a0)
		move.b	PcmChnOnOff(a0),(ThisCpu+CommDataM)
		moveq	#CdTask_SetOnOff,d0
		bra	SMEG_CD_Call
		
		elseif MARS
		
		;TODO: PWM RESET Here
		
		endif
		rts

; ================================================================
; Z80
; ================================================================

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
		
		lea	Z80Driver(pc),a0
		lea	($A00000).l,a1
		move.w	#Z80DriverEnd-Z80Driver,d1
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
		rts
		
; ================================================================
; -------------------------------------------------
; Data
; -------------------------------------------------

SMEG_FM_RegList:
		dc.b $B0
		dc.b $30,$38,$34,$3C
		dc.b $50,$58,$54,$5C
		dc.b $60,$68,$64,$6C
		dc.b $70,$78,$74,$7C
		dc.b $80,$88,$84,$8C
		dc.b $40,$48,$44,$4C
SMEG_RegSetVol:
		even

; ---------------------------------------------------

SMEG_DacNoteList:
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C-0
;      		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C#0
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;D-0
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;D#0
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;E-0
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;F-0
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;F#0
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;G-0
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;G#0
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;A-0
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;A#0
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;B-0
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C-1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C#1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;D-1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;D#1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;E-1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;F-1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;F#1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;G-1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;G#1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;A-1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;A#1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;B-1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C-2
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C#2
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;D-2
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;D#2
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;E-2
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;F-2
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;F#2
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;G-2
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;G#2
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;A-2
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;A#2
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;B-2
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C-3
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C#3
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;D-3
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;D#3
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;E-3
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;F-3
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;F#3
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;G-3
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;G#3
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;A-3
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;     		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;A#3
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;B-3
;   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C-4
    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C#4
   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;D-4
   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;D#4
   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;E-4
   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;F-4
   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;F#4
   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
   		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;G-4
    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;G#4
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;A-4
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;A#4
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;B-4
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
   		dc.b 1,0,1,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,0,1,0,1,0,1,0,0,1,0,1,0,1,0		;C-5 8000hz
    		dc.b 0,1,0,1,0,1,0,0,1,0,1,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,0,1,0,0
  		dc.b 1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0,0,1,0,1,0,1,0		;C#5
   		dc.b 0,1,0,1,0,1,0,0,1,0,1,1,0,1,0,1,1,1,0,1,1,0,1,0,1,0,1,0,0,1,0,0
  		dc.b 1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,0,1,0,1,0,1,0		;D-5
   		dc.b 0,1,0,1,0,1,1,0,1,0,1,1,0,1,0,1,1,1,0,1,1,0,1,0,1,0,1,0,0,1,0,0
  		dc.b 1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,1,1,0,0,1,0,1,0,1,0		;D#5
   		dc.b 0,1,0,1,0,1,1,0,1,0,1,1,0,1,0,1,1,1,0,1,1,0,1,0,1,0,1,0,0,1,0,0
  		dc.b 1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,1,1,0,0,1,0,1,1,1,0		;E-5
   		dc.b 0,1,1,1,0,1,1,0,1,0,1,1,0,1,0,1,1,1,0,1,1,0,1,0,1,1,1,0,0,1,0,0
  		dc.b 1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,1,0,1,1,1,1,0,1,0,1,1,1,0		;F-5
   		dc.b 0,1,1,1,0,1,1,0,1,0,1,1,0,1,0,1,1,1,0,1,1,0,1,0,1,1,1,0,0,1,0,1
  		dc.b 1,0,1,1,0,1,1,1,0,1,1,0,1,1,1,0,1,1,0,1,0,1,1,1,1,0,1,0,1,1,1,0		;F#5
   		dc.b 0,1,1,1,0,1,1,0,1,0,1,1,0,1,0,1,1,1,0,1,1,0,1,0,1,1,1,0,0,1,0,1
   		dc.b 1,0,1,1,0,1,1,1,0,1,1,0,1,1,1,0,1,1,0,1,0,1,1,1,1,0,1,0,1,1,1,0		;G-5
    		dc.b 1,1,1,1,0,1,1,0,1,0,1,1,0,1,0,1,1,1,0,1,1,0,1,1,1,1,1,0,1,1,0,1
    		dc.b 1,0,1,1,0,1,1,1,0,1,1,0,1,1,1,0,1,1,0,1,0,1,1,1,1,1,1,0,1,1,1,0		;G#5
  		dc.b 1,1,1,1,0,1,1,0,1,0,1,1,1,1,0,1,1,1,0,1,1,0,1,1,1,1,1,0,1,1,0,1
    		dc.b 1,0,1,1,1,1,1,1,0,1,1,0,1,1,1,0,1,1,0,1,0,1,1,1,1,1,1,0,1,1,1,0		;A-5
  		dc.b 1,1,1,1,0,1,1,0,1,1,1,1,1,1,0,1,1,1,0,1,1,0,1,1,1,1,1,0,1,1,0,1
    		dc.b 1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,0		;A#5
  		dc.b 1,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,0,1,1,0,1,1,1,1,1,0,1,1,0,1
  		dc.b 1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1		;B-5
  		dc.b 1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,1,0,1
  		dc.b 1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C-6 16000hz
  		dc.b 1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1
  		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;C#6
       		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  		dc.b 1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;D-6
       		dc.b 1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1
  		dc.b 1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1		;D#6
       		dc.b 1,1,1,2,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1	
  		dc.b 1,1,2,1,1,1,1,2,1,1,1,2,1,1,1,1,2,1,1,1,2,1,1,1,1,2,1,1,1,1,1,1		;E-6
       		dc.b 1,1,1,2,1,1,1,1,2,1,1,1,1,1,2,1,1,1,1,1,1,2,1,1,1,1,1,2,1,1,1,1
  		dc.b 1,1,2,1,1,1,1,2,1,1,1,2,1,1,1,1,2,1,1,1,2,1,1,1,1,2,1,1,1,2,1,1		;F-6
       		dc.b 1,2,1,2,1,1,1,1,2,1,1,1,1,1,2,1,1,1,2,1,1,2,1,1,1,1,1,2,1,1,1,2
  		dc.b 1,1,2,1,1,2,1,2,1,1,1,2,1,1,1,1,2,1,1,1,2,1,1,2,1,2,1,1,1,2,1,1		;F#6
       		dc.b 1,2,1,2,1,1,2,1,2,1,1,2,1,1,2,1,1,1,2,1,1,2,1,1,2,1,1,2,1,1,1,2
  		dc.b 1,1,2,2,1,2,1,2,1,1,2,1,2,1,1,1,2,1,2,1,2,1,1,2,1,2,1,1,1,2,1,1		;G-6
       		dc.b 1,2,1,2,1,1,2,1,2,1,1,2,1,2,1,2,1,1,2,1,1,2,1,1,2,1,1,2,1,2,1,2
  		dc.b 1,2,1,2,1,2,1,2,1,1,2,1,2,1,2,1,2,1,2,1,2,1,1,2,1,2,1,2,1,2,1,2		;G#6
       		dc.b 1,2,1,2,1,1,2,1,2,1,1,2,1,2,1,2,1,2,2,1,2,1,2,1,2,1,2,1,2,1,2,1 
  		dc.b 1,2,1,2,1,2,1,2,1,1,2,1,2,2,2,1,2,1,2,1,2,2,1,2,1,2,1,2,1,2,1,2		;A-6
       		dc.b 1,2,1,2,2,1,2,1,2,2,1,2,1,2,1,2,1,2,2,1,2,1,2,2,2,1,2,1,2,1,2,1 
  		dc.b 1,2,1,2,1,2,2,2,1,2,2,1,2,2,2,1,2,1,2,1,2,2,1,2,2,2,1,2,2,2,1,2		;A#6
       		dc.b 1,2,2,1,2,1,2,1,2,2,2,2,1,2,2,2,1,2,2,1,2,1,2,2,2,1,2,2,2,1,2,1  
  		dc.b 1,2,2,2,1,2,2,2,1,2,2,2,1,2,2,1,2,2,2,1,2,2,1,2,2,2,1,2,2,2,2,2		;B-6
       		dc.b 1,2,2,2,2,1,2,1,2,2,2,2,1,2,2,2,2,2,2,1,2,2,2,2,2,1,2,2,2,1,2,2 
		even

; ---------------------------------------------------

Z80Driver:	incbin	"engine/sound/data/z80/main.bin"
Z80DriverEnd:
		even