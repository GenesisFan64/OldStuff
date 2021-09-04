; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; 
; SOUND
; ------------------------------------------------------------

; TYPES:
;  -1 - ignore
;   0 - FM normal
;   1 - FM special
;   2 - FM sample
; $80 - PSG
; $E0 - PSG noise

insFM		equ 0
insFM3		equ 1
insFM6		equ 2
insPSG		equ $80
insPBass0	equ $E0
insPBass1	equ $E1
insPBass2	equ $E2
insPBass3	equ $E3		; Grabs PSG3 frequency
insPNoise0	equ $E4
insPNoise1	equ $E5
insPNoise2	equ $E6
insPNoise3	equ $E7		; Grabs PSG3 frequency

instrSlot	macro TYPE,OPT,LABEL
	if TYPE=-1
		dc.b -1,-1,-1,-1
	else
		dc.b TYPE,OPT
		dc.b LABEL&$FF,((LABEL>>8)&$FF)
	endif
		endm

instrSmpl	macro FLAGS,LABEL1,LABEL2,LABEL3
		dc.b LABEL1&$FF,LABEL1>>8&$7F|$80,((LABEL1>>15)&$FF)
		dc.b LABEL2&$FF,LABEL2>>8&$7F|$80,((LABEL2>>15)&$FF)
		dc.b LABEL3&$FF,LABEL3>>8&$7F|$80,((LABEL3>>15)&$FF)
		dc.b FLAGS
		endm

; ----------------------------------------------------
; Sound bank for Z80
; ----------------------------------------------------
		align $8000				; Align to bank
ZSnd_MusicBank:
		phase $8000
		dc.b "ROM MUSIC DATA"


; MusicBlk_Tronik:
; 		binclude "game/sound/music/track0_blk.bin"		; BLOCKS data
; MusicPat_Tronik:
; 		binclude "game/sound/music/track0_patt.bin"		; PATTERN data
; MusicIns_Tronik:
; ; 		instrSlot -1
; ; 		instrSlot -1
; 		instrSlot insFM6,0,.smpl0
; 		instrSlot insFM6,0,.smpl1
; 		instrSlot insFM,-36,FmIns_DrumKick
; 		instrSlot insFM,-54,FmIns_DrumSnare
; 		instrSlot insFM,0,FmIns_Bass_ambient
; 		instrSlot insFM3,0,FmIns_Fm3_OpenHat
; 		instrSlot insFM3,0,FmIns_Fm3_ClosedHat
; 		
; ; insFM6 pointers
; .smpl0:		instrSmpl 0,WavIns_adae1,WavIns_adae1_e,0
; .smpl1:		instrSmpl 0,WavIns_adae2,WavIns_adae2_e,0

; ; ------------------------------------
; ; Track JackRab
; ; ------------------------------------
; 
; MusicBlk_JackRab:
; 		binclude "game/sound/music/jackrab_blk.bin"		; BLOCKS data
; MusicPat_JackRab:
; 		binclude "game/sound/music/jackrab_patt.bin"		; PATTERN data
; MusicIns_JackRab:
; 		instrSlot -1
; 		instrSlot insFM,0,FmIns_Ambient_spook
; 		instrSlot insFM6,+12,.tom
; 		instrSlot insFM6,+12,.kick
; 		instrSlot insPNoise0,0,PsgIns_02
; 		instrSlot insFM,0,FmIns_bass_synth
; 		instrSlot insFM6,+6,.cuban
; 		instrSlot insFM,0,FmIns_piano_m1
; 		instrSlot insFM6,-17,.middle
; 		instrSlot insFM,0,FmIns_Bass_3		; 10
; 		instrSlot insPSG,0,PsgIns_01
; 		instrSlot insFM,0,FmIns_ambient_dark
; 		instrSlot insPNoise1,0,PsgIns_00
; 		instrSlot insFM,0,FmIns_Ding_toy
; 		instrSlot insPSG,0,PsgIns_01
; 		instrSlot insFM6,+12,.snare
; 		instrSlot -1
; 		instrSlot insFM,0,FmIns_Trumpet_2
; 		instrSlot insPNoise0,0,PsgIns_00
; 		instrSlot insPSG,0,PsgIns_00		; 20
; 		instrSlot -1
; 		instrSlot -1
; 		instrSlot -1
; 		instrSlot -1
; .kick:		instrSmpl 0,WavIns_CLASIC02,WavIns_CLASIC02_e,WavIns_CLASIC02
; .snare:		instrSmpl 0,WavIns_SNOWD2,WavIns_SNOWD2_e,WavIns_SNOWD2
; .tom:		instrSmpl 0,WavIns_AFRICA2,WavIns_AFRICA2_e,WavIns_AFRICA2
; .cuban:		instrSmpl 0,WavIns_CUBAN,WavIns_CUBAN_e,WavIns_CUBAN
; .middle		instrSmpl 0,WavIns_MIDDLE,WavIns_MIDDLE_e,WavIns_MIDDLE

; ------------------------------------

		dephase		; close bank
		
; ----------------------------------------------------
; Sample data
; 
; can be anywhere in ROM
; ----------------------------------------------------

		align $8000
		dc.b "SAMPLE DATA"
; WavIns_PumpKick:
; 		binclude "game/sound/instr/dac/pump_kick.wav",$2C
; WavIns_PumpKick_e:
; 
; WavIns_PumpClap:
; 		binclude "game/sound/instr/dac/pump_clap.wav",$2C
; WavIns_PumpClap_e:
; WavIns_adae1:
; 		binclude "game/sound/instr/dac/adaebeat_1.wav",$2C
; WavIns_adae1_e:
; 
; WavIns_adae2:
; 		binclude "game/sound/instr/dac/adaebeat_2.wav",$2C
; WavIns_adae2_e:

; Wav_Beibe: 	binclude "game/sound/beibe.wav",$2C;,$3C0000
; Wav_Beibe_e:
