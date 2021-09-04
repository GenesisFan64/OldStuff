; ================================================================
; SMEG Junior
; Sound and Music Engine for Game Gear/Master System
;
; (C)2015 Kevin C.
; 
; ImpulseTracker
;
; Ticks:
; 150 - NTSC
; 120 - PAL
; ================================================================

			rsreset
DrvStatus		rb 1		;Byte
DrvSettings		rb 1		;Byte
CurrPattern		rb 1		;Byte
PatternEnd		rb 1		;Byte
PatternLoop		rb 1		;Byte


PattSize		rw 1		;Word
PattRead		rw 1		;Word
SongStart		rw 1		;Word
SongRead		rw 1		;Word


TicksRead		rb 1		;Byte
TicksSet		rb 1		;Byte
PsgLast			rb 1		;Byte
DrvSettingsBGM		rb 1		;Byte
Psg_Vibrato		rb 1		;Byte
Psg_AutoVol		rb 1		;Byte

CurrChan		rb 1
CurrChanType		rb 1
UsedChnBuff		rb 4		;Array (Bytes)

; --------------------------------------------
; Channel settings
; --------------------------------------------

			rsreset
Chn_Type		rb 1		;Byte
Chn_ID			rb 1		;Byte
Chn_Inst		rb 1		;Byte
Chn_Vol			rb 1		;Byte

Chn_Freq		rw 1		;Word
Chn_Effect		rw 1		;Word		;TODO: its backwards
Chn_Portam		rw 1		;Word
Chn_DefVol		rb 1		;Byte
Chn_Note		rb 1		;Byte
Chn_Panning		rb 1		;Byte
Chn_PSG_Vibrato		rb 1		;Byte
Chn_Unused		rb 2
sizeof_Chn		rw 0
 
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

PSG_1			equ	080h
PSG_2			equ	0A0h
PSG_3			equ	0C0h
NOISE			equ	0E0h
MaxChannels		equ	4

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

			rsset ram_sounddriver
RAM_SMEG_Buffer		rb 48h
RAM_SMEG_SfxBuff	rb 48h
RAM_SMEG_Chnls_BGM	rb 10h*4
RAM_SMEG_Chnls_SFX	rb 10h*4
sizeof_SMEG		rb 0

; ================================================================
; -------------------------------------------
; Init
; -------------------------------------------

SMEG_Init:
		ld	hl,RAM_SMEG_Buffer
		ld	b,0FFh
		xor	a
@clrall:	
		ld	(hl),a
		inc	hl
		djnz	@clrall
		
		xor	a
		set 	bitDisabled,a
		ld	(RAM_SMEG_Buffer),a
		ret
		
; -------------------------------------------
; Stop ALL Sound
; -------------------------------------------

SMEG_StopSnd:
		ld	hl,RAM_SMEG_Buffer
		ld	a,(hl)
		set 	bitDisabled,a
		ld	(hl),a
		ld	hl,RAM_SMEG_SfxBuff
		ld	a,(hl)
		set 	bitDisabled,a
		ld	(hl),a
		
		ld	a,09Fh
		out	(7Fh),a
		ld	a,0BFh
		out	(7Fh),a
		ld	a,0DFh
		out	(7Fh),a
		ld	a,0FFh
		out	(7Fh),a
		ret

; -------------------------------------------
; Play Song
; -------------------------------------------

SMEG_PlaySong:
		ld	hl,RAM_SMEG_Buffer
		ld	a,(hl)
		res 	bitDisabled,a
		ld	(hl),a
		ret
		
; -------------------------------------------
; Load SFX
;
; d0 - StartOfSong
; d1 - Ticks
; -------------------------------------------

SMEG_LoadSfx:
; 		movem.l	a4-a6,-(sp)
; 		lea	(RAM_SMEG_SfxBuff),a6
; 		lea	(RAM_SMEG_Chnls_SFX),a5
; 		clr.b	PcmChnOnOff(a6)
;                 clr.b	DrvStatus(a6)
;                 bset	#bitSfxOn,(a6)
; 		bsr	SMEG_Load_SetChnls
; 		movem.l	(sp)+,a4-a6
		ret

; -------------------------------------------
; Load Song
;
; hl - StartOfSong
; b - Ticks
; -------------------------------------------

SMEG_LoadSong:
		push	hl
		push	bc
		call	SMEG_StopSnd			;hl and b are gone
		pop	bc
		pop	hl
		
		ld	ix,RAM_SMEG_Buffer		;a6
		ld	iy,RAM_SMEG_Chnls_BGM		;a5
		xor	a
		ld	(ix+DrvStatus),a
		call	SMEG_Load_SetChnls
		jp	SMEG_Load_FixBgm
		
; -----------------------
; Setup channels
; 
; hl - Song
; b  - Ticks
; -----------------------

SMEG_Load_SetChnls:
		ld	(ix+TicksSet),b
		
; -----------------------
; Get instruments
; -----------------------

		inc	hl			;Probably not making PSG instruments
		inc	hl

; -----------------------
; Get the
; PatternEnd/PatternLoop
; numbers
; -----------------------

		ld	a,(hl)
		inc	hl
		ld	(ix+PatternEnd),a
		ld	a,(hl)
		inc	hl
		ld	(ix+PatternLoop),a

; -----------------------
; Setup the channel IDs
; -----------------------

		ld	b,MaxChannels
@SetId:
		ld	a,1
		ld	(iy+Chn_Type),a
		ld	a,(hl)
		inc	hl
		ld	(iy+Chn_ID),a
		xor	a
		ld	(iy+(Chn_Freq+1)),a
		ld	(iy+Chn_Freq),a
		
		ld	de,sizeof_Chn
		add 	iy,de
		djnz	@SetId

; -----------------------
; Master volumes
; -----------------------

		; (Removed in this driver)
		
; -----------------------
; last steps
; -----------------------
 
 		ld	(ix+(SongStart+1)),h
 		ld	(ix+SongStart),l
 		ld	a,(hl)
 		inc	hl
 		ld	(ix+PattSize),a
 		ld	a,(hl)
 		inc	hl
 		ld	(ix+(PattSize+1)),a	
 		xor	a
 		ld	(ix+(PattRead+1)),a
 		ld	(ix+PattRead),a
 		inc	hl
  		inc	hl
  		inc	hl
 		inc	hl
  		inc	hl
  		inc	hl
 		ld	(ix+(SongRead+1)),h
 		ld	(ix+SongRead),l
 		
;  		ld	a,1
;  		ld	(ix+CurrPattern),a
		ret
		
; -----------------------
; Fix stuff to BGM
; -----------------------

SMEG_Load_FixBgm:
; 		lea	(RAM_SMEG_Chnls_BGM),a5
; 		moveq	#(MaxChannels)-1,d4
; @SetId:
; 		move.b	#$80,Chn_Panning(a5)
; 
; 		tst.b	Chn_ID(a5)
; 		bmi.s	@NotFM
; 		cmp.b	#PCM_1,Chn_ID(a5)
; 		bge.s	@NotFM
; 
; 		clr.b	Chn_FM_Key(a5)
; 		move.b	#%00001111,Chn_FM_Key(a5)
; 		move.b	#$C0,Chn_Panning(a5)
; 		bsr	SMEG_FM_SetPan
; 
; @NotFM:
; 		adda 	#sizeof_Chn,a5
; 		dbf	d4,@SetId
		ret
		
; ================================================================
; -------------------------------------------
; Run
; -------------------------------------------

SMEG_Upd:
		ld	ix,RAM_SMEG_Buffer
		ld	a,(ix)
		set 	bitPriority,a
		ld	(ix),a
		call	@ReadRow
		
		ld	ix,RAM_SMEG_SfxBuff
		ld	a,(ix)
		res 	bitPriority,a
		ld	(ix),a
		bit 	bitSfxOn,a
		jp	z,@Wait
		call	@ReadRow
		
@Wait:
		ret

; -------------------------------------------
; Read row
; -------------------------------------------

@ReadRow:
		ld	a,(ix)
		bit 	bitDisabled,a
		jp	nz,@Wait
		
		dec 	(ix+TicksRead)
		ld	a,(ix+TicksRead)
		jp	p,@Wait
		ld	a,(ix+TicksSet)
		ld	(ix+TicksRead),a
		
		ld	d,(ix+(SongRead+1))
		ld	e,(ix+SongRead)	
	
; --------------------------------
; New pattern
; --------------------------------

@Next:
		ld	b,(ix+(PattRead+1))
		ld	a,(ix+(PattSize+1))
		cp	b
		jp	nz,@NoNextRow
		ld	b,(ix+PattRead)
		ld	a,(ix+PattSize)
		dec 	a
		cp	b
		jp	nc,@NoNextRow
		
		xor	a
		ld	(ix+(PattRead+1)),a
		ld	(ix+PattRead),a
		
  		ld	a,(ix+PatternEnd)
  		ld	b,(ix+CurrPattern)
   		cp	b
  		jp	nz,@NotEnd
 		
 		; Restart
 		ld	h,(ix+(SongStart+1))
 		ld	l,(ix+(SongStart))
 		ld	a,(hl)
 		inc	hl
 		ld	(ix+(PattSize)),a
 		ld	a,(hl)
 		inc	hl
 		ld	(ix+(PattSize+1)),a
 		inc	hl
  		inc	hl
  		inc	hl
 		inc	hl
  		inc	hl
  		inc	hl
  		ld	(ix+(SongRead+1)),h
  		ld	(ix+SongRead),l
		
		xor	a
		ld	(ix+(PattRead+1)),a
		ld	(ix+PattRead),a
 		ld	a,(ix+PatternLoop)
		ld	(ix+CurrPattern),a

		xor	a
		ld	(ix+TicksRead),a
		ld	(ix+CurrPattern),a
 		jr 	@ReadRow

; --------------------------------

@NotEnd:
 		ld	a,(ix+CurrPattern)
 		inc	a
 		ld	(ix+CurrPattern),a
 		
 		ld	a,(ix+CurrPattern)
 		ld	b,(ix+PatternLoop)
 		cp	b
 		jp	nz,@DontSaveLoop
 		ld	(ix+(SongStart+1)),d
 		ld	(ix+(SongStart)),e
		
@DontSaveLoop:	
 		ld	a,(de)
 		inc	de
 		ld	(ix+PattSize),a
 		ld	a,(de)
 		inc	de
 		ld	(ix+(PattSize+1)),a	
 		xor	a
 		ld	(ix+(PattRead+1)),a
 		ld	(ix+PattRead),a
		inc	de
		inc	de
		inc	de
		inc	de
		inc	de
		inc	de
		
; --------------------------------
; Current pattern
; --------------------------------
 
@NoNextRow:
		ld	a,(de)
 		inc	de
 		ld	(ix+CurrChan),a
 		cp	0
		jp	nz,@ValidNote
		
		ld	b,(ix+(PattRead+1))
		ld	c,(ix+(PattRead))
		inc	bc
		ld	(ix+(PattRead+1)),b
		ld	(ix+(PattRead)),c
		
		ld	(ix+(SongRead+1)),d
		ld	(ix+(SongRead)),e
		ret
		
@ValidNote:
 		ld	a,(ix+CurrChan)
 		bit 	7,a
		jp	z,@Not80
		
		ld	b,(ix+(PattRead+1))
		ld	c,(ix+(PattRead))
		inc	bc
		ld	(ix+(PattRead+1)),b
		ld	(ix+(PattRead)),c
		res 	7,a
		ld	(ix+CurrChan),a

 		ld	a,(de)
 		inc	de
 		ld	(ix+CurrChanType),a
		
@Not80:
		ld	b,(ix+(PattRead+1))
		ld	c,(ix+(PattRead))
		inc	bc
		ld	(ix+(PattRead+1)),b
		ld	(ix+(PattRead)),c
		
		sub 	a
		;channel_on flags goes here
		
		ld	iy,RAM_SMEG_Chnls_BGM
		ld	a,(ix)
		bit 	bitPriority,a
		jp	nz,@BgmPrio
		ld	iy,RAM_SMEG_Chnls_SFX		
@BgmPrio:
		ld	a,(ix+CurrChan)
		cp	1
		jp	z,@First
		dec 	a
@NextChn:
 		ld	bc,sizeof_Chn
   		add 	iy,bc
   		dec	a
   		jp	nz,@NextChn
@First:

 		ld	a,(ix+CurrChanType)
 		cp	0
		jp	z,@NotRest
 		ld	a,(ix+CurrChanType)
		ld	(iy+Chn_Type),a

@NotRest:

; -------------
; Note
; -------------

		ld	a,(iy+Chn_Type)
		bit 	bitSameNote,a
		jp	nz,@PlayOnly
		bit 	bitNote,a
		jp	z,@NoNote

		ld	a,(de)
		inc 	de
		ld	(iy+Chn_Note),a
		ld	b,(ix+(PattRead+1))
		ld	c,(ix+(PattRead))
		inc	bc
		ld	(ix+(PattRead+1)),b
		ld	(ix+(PattRead)),c

@PlayOnly:
 		call	SMEG_ChannelRest
		
; -------------
; Instrument
; -------------

@NoNote:
		ld	a,(iy+Chn_Type)
 		bit 	bitSameInst,a
 		jp	nz,@SameInst
		bit 	bitInst,a
		jp	z,@NoInst
		
		inc	(iy+Chn_DefVol)
		
		ld	a,(de)
		inc 	de
		ld	(iy+Chn_Inst),a
		ld	b,(ix+(PattRead+1))
		ld	c,(ix+(PattRead))
		inc	bc
		ld	(ix+(PattRead+1)),b
		ld	(ix+(PattRead)),c

; 		bsr	SMEG_SetVoice
@SameInst:

; -------------
; Volume
; -------------

@NoInst:
		ld	a,(iy+Chn_Type)
		bit 	bitSameVol,a
		jp	nz,@SameVol
		bit 	bitVolume,a
		jp	z,@NoVolume
 
 		xor	a
		ld	(iy+(Chn_Portam+1)),a
		ld	(iy+Chn_Portam),a
		ld	(iy+(Chn_Effect+1)),a
		ld	(iy+Chn_Effect),a
		ld	a,(de)
		inc 	de
		ld	b,(ix+(PattRead+1))
		ld	c,(ix+(PattRead))
		inc	bc
		ld	(ix+(PattRead+1)),b
		ld	(ix+(PattRead)),c
		
  		sub 	64
  		neg 	a
		ld	(iy+Chn_Vol),a
		
@SameVol:
  		call	@ChnVolume

; -------------
; Effect
; -------------
 
@NoVolume:
		ld	a,(iy+Chn_Type)
		bit 	bitSameEffect,a
		jp	nz,@SameEffect
		bit 	bitEffect,a
		jp	z,@NoEffect

		ld	a,(de)
		ld	(iy+(Chn_Effect+1)),a
		inc 	de
		ld	b,(ix+(PattRead+1))
		ld	c,(ix+(PattRead))
		inc	bc
		ld	(ix+(PattRead+1)),b
		ld	(ix+(PattRead)),c
		
		ld	a,(de)
		ld	(iy+Chn_Effect),a
		inc 	de
		ld	b,(ix+(PattRead+1))
		ld	c,(ix+(PattRead))
		inc	bc
		ld	(ix+(PattRead+1)),b
		ld	(ix+(PattRead)),c

@SameEffect:
		call	@ChannelEffects
 
; --------------
; Play the note
; --------------
; 
@NoEffect:
		ld	a,(iy+Chn_Type)
		bit 	bitSameNote,a
		jp	nz,@SameNote
		bit 	bitNote,a
		jp	z,@Next
		
@SameNote:
 		call	@ChannelPlay	
 		jp	@Next

; ================================================================
; -------------------------------
; Set Volume
; -------------------------------

@ChnVolume:
		ld	a,(iy+Chn_ID)
		cp	0FFh
		jp	z,@Disabled
		
		ld	c,00h
  		ld	a,(iy+Chn_Vol)
    		jp	z,@Full
    		sub 	64
    		sra 	a
    		sra	a
@Full:
 		and 	00001111b
 		ld	b,a
 		ld	a,(iy+Chn_ID)
 		and	11100000b
 		set 	4,a
 		or	b
 		out	(7Fh),a
		ret 
		
; -------------------------------
; Set Freq
; -------------------------------

@NoteFreq:	
		ld	a,(iy+Chn_Note)
		cp	0FFh
		jp	z,@ResetFreq
		cp	0FEh
		jp	z,@ResetFreq
		
		ld	a,(iy+Chn_ID)
		cp	NOISE
		jp	nz,@NotNoise
		
		xor	a
		ld	(iy+(Chn_Freq+1)),a
		inc	a
		ld	(iy+Chn_Freq),a

		ld	a,(ix+DrvSettings)
		bit	bitTone3,a
		jp	z,@Disabled
@NotNoise:
		ld	bc,0
		ld	c,(iy+Chn_Note)
		sla	c
		push	hl
		ld	hl,@Notes_PSG
 		ld	a,(iy+Chn_ID)
  		cp	NOISE
  		jp	nz,@NotNoiseFix
		ld	hl,@Notes_PSG+(32*2)		
@NotNoiseFix:
		add 	hl,bc
		ld	a,(hl)
		ld	(iy+(Chn_Freq)),a
		inc	hl
		ld	a,(hl)
		ld	(iy+Chn_Freq+1),a
		pop	hl
		ret 

@ResetFreq:
		xor	a
		ld	(iy+(Chn_Freq+1)),a
		ld	(iy+Chn_Freq),a
		
@Disabled:
 		ret
		
; -------------------------------
; Channel play
; -------------------------------

@ChannelPlay:
		ld	a,(iy+Chn_ID)
		cp	0FFh
		jp	z,@Disabled
		
		;Portametro later
		call	@NoteFreq
			
		ld	a,(iy+(Chn_Freq+1))
		ld	b,(iy+(Chn_Freq))
		or	b
 		jp	z,SMEG_ChannelRest
		
		ld	a,(iy+Chn_ID)
		cp	NOISE
		jp	z,@PlayNoise
		
		cp	PSG_3
		jp	nz,@NotPsg3
		ld	a,(ix+DrvSettings)
		bit	bitTone3,a
		jp	z,@NotPsg3
		
		ld	a,0DFh
		out	(7Fh),a
		ret 

@NotPsg3:
 		ld	a,(iy+Chn_ID)
 		ld	c,a
 		jp	@SetFreq
		
; ------------------------------------

@PlayNoise:
		ld	a,(ix+DrvSettings)
		bit 	bitTone3,a
		jp	z,@Disabled
		ld	c,11000000b
@SetFreq:
 		ld	a,(iy+(Chn_Freq))
 		and 	00001111b
 		ld	b,a
 		ld	a,c
 		and	11100000b
 		or	b
		out	(7Fh),a
 		ld	a,(iy+(Chn_Freq))
 		sra	a
 		sra	a
 		sra	a
 		sra	a
 		and 	00001111b
 		ld	b,a
 		ld	a,(iy+(Chn_Freq+1))
  		sla	a
 		sla	a
 		sla	a
 		sla	a
 		and 	00110000b
 		or	b
 		out	(7Fh),a
		ret
		
; -------------------------------

@Notes_PSG:
		dw 0		;x-0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0

		dw 0		;x-1
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0

		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0

		dw 3F8h
                dw 3BFh
                dw 389h
		dw 356h
                dw 326h
                dw 2F9h
                dw 2CEh
                dw 2A5h
                dw 280h
                dw 25Ch
                dw 23Ah
                dw 21Ah
		dw 1FBh
                dw 1DFh
                dw 1C4h
                dw 1ABh
                dw 193h
                dw 17Dh
                dw 167h
                dw 153h
                dw 140h
		dw 12Eh
                dw 11Dh
                dw 10Dh
                dw 0FEh
                dw 0EFh
                dw 0E2h
                dw 0D6h
                dw 0C9h
                dw 0BEh
                dw 0B4h
		dw 0A9h
                dw 0A0h
                dw 97h
                dw 8Fh
                dw 87h
                dw 7Fh
                dw 78h
                dw 71h
                dw 6Bh
                dw 65h
		dw 5Fh
                dw 5Ah
                dw 55h
                dw 50h
                dw 4Bh
                dw 47h
                dw 43h
                dw 40h
                dw 3Ch
                dw 39h
		dw 36h
                dw 33h
                dw 30h
                dw 2Dh
                dw 2Bh
                dw 28h
                dw 26h
                dw 24h
                dw 22h
                dw 20h
		dw 1Fh
                dw 1Dh
                dw 1Bh
                dw 1Ah
                dw 18h
                dw 17h
                dw 16h
                dw 15h
                dw 13h
                dw 12h
		dw 11h
		
; ================================================================
; -------------------------------
; Channel effect
; -------------------------------

@ChannelEffects:
		ld	bc,0
		ld	c,(iy+(Chn_Effect+1))
		sla	c
		ld	hl,@EffectList
		add 	hl,bc
		jp	(hl)

; -------------------------------

@EffectList:
		jr	@Null		;(Nothing)
		jr	@Null		;A	
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Flag_X
		jr	@Null
		jr	@Flag_Z

; -------------------------------
; Null effect
; -------------------------------

@Null:
		ret
		
; -------------------------------
; Flag X - Stereo
; -------------------------------

@Flag_X:
		if MERCURY
		;GG ONLY
		nop 
		
		endif
		ret
		
; ======================================================
; -------------------------------
; Flag Z
; -------------------------------

@Flag_Z:	
 		ld	bc,0
 		ld	a,(iy+(Chn_Effect))
 		sra	a
 		sra	a
 		sra	a
 		ld	c,a
 		ld	hl,@HashList
 		add 	hl,bc
		jp	(hl)

@HashList:
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@PSG
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		jr	@Null
		
; -------------------------------

@PSG:
		ld	b,(ix+DrvSettings)
  		res	bitTone3,b
   		ld	a,(iy+(Chn_Effect))
   		and	111b
   		cp	3
   		jp	z,@SetIt3
   		cp	7
    		jp	z,@SetIt3
    		jr	@Tone3
@SetIt3:
   		set 	bitTone3,b
@Tone3:
		ld	(ix+DrvSettings),b
; 		bit 	bitPriority,b
;  		jp	z,@IsPsg
;  		
;  		ld	a,(RAM_SMEG_Buffer+DrvSettings)
;  		ld	(RAM_SMEG_Buffer+DrvSettingsBGM),a
;  		ld	a,(iy+(Chn_Effect))
;  		and 	00000111b
;  		ld	(RAM_SMEG_Buffer+PsgLast),a
; 		
; @IsPsg:
		ld	a,(iy+(Chn_Effect))
		and	111b
		ld	b,a
		ld	a,0E0h
		or	b
		out	(7Fh),a
		ret	
		
; ================================================================
; -------------------------------
; Mute/Rest channel
; -------------------------------

SMEG_ChannelRest:
		ld	a,(iy+Chn_ID)
		cp	0FFh
		jp	z,@Return
		
		ld	a,(iy+Chn_ID)
		and 	11100000b
		ld	b,a
		ld	a,00011111b
		or	b
		out	(7Fh),a
@Return:
		ret
		
; ================================================================
; -------------------------------
; Play PCM sample
; -------------------------------

PlayPCM:
; 		ld	h,(BANK_WAVE>>14)&0FFh
;  		ld	a,h
;  		ld      (0FFFEh),a
;  		ld      l,06h
;  		ld      de,4000h
 	
;  		if MERCURY
;  		ld	c,01100011b
;  		ld	a,c
;  		out	(06h),a
;  		endif
 		ld      a,81h			;write $01 to tone channel 0
 		out     (7Fh),a
 		xor	a
 		out     (7Fh),a
 		ld      a,0A1h			;write $01 to tone channel 1
 		out     (7Fh),a
 		xor	a
 		out     (7Fh),a
 		ld      a,0C1h			;write $01 to tone channel 2
 		out     (7Fh),a
 		xor	a
 		out     (7Fh),a
 
@Loop:
		in      a,(pad)
		xor     0FFh
		jp	nz,@escape
 		nop 
 		nop 
 		
 		ld      a,(de)
 		rrca
 		rrca
 		rrca
 		rrca
   		and     %00001111
		di
   		or      90h
   		out     (7Fh),a
   		add	a,20h
   		out     (7Fh),a
   		add	a,20h
   		out     (7Fh),a
   		ld      b,l
   		djnz    *
   		
 		inc     de
  		bit 	7,d
  		jp	z,@Loop
  		res 	7,d
  		set 	6,d
  		inc 	h
		ld	a,h
		ld      (0FFFEh),a
   		ei
 		jp	@Loop
 		
 		ld      a,c
 		or      b
 		jp      nz,@Loop
  
@escape:
;  		pop     hl
;  		pop     de
;  		pop     bc
 		ret
		