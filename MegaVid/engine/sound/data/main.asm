; ================================================================
; User data
; ================================================================
; ---------------------------------------------------
; Z80 Samples
; ---------------------------------------------------
	
		cnop 0,$1000
; samp_Ambient:	incbin	"engine/sound/data/instruments/samples/dac/ambient_1.wav",$38
; samp_Ambient_end:
;  		even
; samp_AmbientL:	incbin	"engine/sound/data/instruments/samples/dac/ambient_1_loop.wav",$38
; samp_AmbientL_end:
;  		even 		
samp_Kick:	incbin	"engine/sound/data/instruments/samples/dac/sauron_kick.wav",$2C
samp_Kick_end:
 		even
samp_Snare:	incbin	"engine/sound/data/instruments/samples/dac/snare.wav",$2C
samp_Snare_end:
 		even
samp_Tom:	incbin	"engine/sound/data/instruments/samples/dac/sauron_tom.wav",$2C
samp_Tom_end:
 		even
 		
; ================================================================	
; ---------------------------------------------------
; Voices
; ---------------------------------------------------

; ins_piano_80s:
;  		incbin	"engine/sound/data/instruments/voices/piano/piano_80s.bin"
;  		even
; ins_piano_generic:
;  		incbin	"engine/sound/data/instruments/voices/piano/piano_generic.bin"
;   		even
; ins_piano_real:
;    		incbin	"engine/sound/data/instruments/voices/piano/piano_real.bin"
;    		even
; ; ins_piano_small:
; ;  		incbin	"engine/sound/data/instruments/voices/piano/piano_small.bin"
; ;  		even
; ; ins_piano_rave:
; ;  		incbin	"engine/sound/data/instruments/voices/piano/piano_rave.bin"
; ;    		even
; ; 
; ; ; ----------------------------------------
; ; 
; ins_bass_techno:
;    		incbin	"engine/sound/data/instruments/voices/bass/bass_techno.bin"
;    		even
; ; ins_brass_funny:
; ;   		incbin	"engine/sound/data/instruments/voices/brass/brass_funny.bin"
; ;   		even
; ; ins_fmdrum_kick:
; ;  		incbin	"engine/sound/data/instruments/voices/drums/fm_kick.bin"
; ;  		even
; ins_fmdrum_closedhat:
;   		incbin	"engine/sound/data/instruments/voices/drums/fm_openhat.bin"
;   		even
; ;  		
; ; ; ----------------------------------------
; ; 
; ; ins_bell_test:
; ;  		incbin	"engine/sound/data/instruments/voices/bell/bell_xmas.bin"
; ;  		even
; ; 
; ; ; ----------------------------------------
; ; 
ins_fx_echo:
  		incbin	"engine/sound/data/instruments/voices/fx/ecco_thelagoon.bin"
  		even
	
ins_kid_1:  	incbin	"engine/sound/data/instruments/voices/old/kid/patch_01.smps"
  		even
ins_kid_2:  	incbin	"engine/sound/data/instruments/voices/old/kid/patch_02.smps"
  		even
  		
; ================================================================	
; ---------------------------------------------------
; Music
; ---------------------------------------------------
 	
; MainTheme:
;  		dc.l @Voices,@Samples,@ExSampl
;   		dc.b 33,6
;  		dc.b  FM_1, FM_2, FM_3, FM_4, FM_5, FM_6
;  		dc.b PSG_1,PSG_2,PSG_3,NOISE
;  		dc.b PCM_1,PCM_2,PCM_3,PCM_4,PCM_5,PCM_6,PCM_7,PCM_8
;  		dcb.b $12,$00
;   		incbin "engine/sound/data/music/song1.it",$50+$2E53
;   		even
; @Voices:
;   		dc.w 4,0
;    		dc.l ins_fmdrum_closedhat
;    		dc.w 6,0
;    		dc.l ins_bass_techno
;    		dc.w 7,0
;   		dc.l ins_brass_funny
;     		dc.w 9,0
;     		dc.l ins_fx_echo 
;  		dc.w $FFFF
;  		even
; @Samples:
;   		dc.w 1,0
;   		dc.l samp_Kick
;   		dc.l samp_Kick_end
;   		dc.l samp_Kick
;   		dc.w 2,0
;   		dc.l samp_Snare
;   		dc.l samp_Snare_end
;   		dc.l samp_Snare
;   		dc.w 3,0
;   		dc.l samp_Tom
;   		dc.l samp_Tom_end
;   		dc.l samp_Tom
;  		dc.w $FFFF
;  		even
; 
; @ExSampl:
;  		if SegaCD
;   		dc.b "bras_1  "				;FIRST LIST	Hadagi filename
;   		dc.w 0					;		Sample loop | -1 = dont loop
;   		dc.w -11				;		Pitch
;  		dc.b "bassdsrt"	
;  		dc.w -1	
;  		dc.w -11
;   		dc.w $FFFF
;  		dc.b 10,1				;SECOND LIST
;   		dc.b 11,2
; 
;  		elseif MARS
;  		dc.l pcm_brass_1			;FIRST LIST     PWM Start
;  		dc.w 0					;		Sample loop | -1 = dont loop
;   		dc.w -11				;		Pitch
;  		dc.l pcm_bass_dsrt			;FIRST LIST     PWM Start
;  		dc.w -1					;		Sample loop | -1 = dont loop
;   		dc.w -11				;		Pitch	
;   		dc.w $FFFF
;  		dc.b 10,1				;SECOND LIST
;   		dc.b 11,2
;   		
;  		endif
;  		dc.w -1					;EndOfList
;  		even
;  		
; TestSong:
;  		dc.l @Voices,@Samples,@ExSampl
;   		dc.b 0,0
;  		dc.b  FM_1, FM_2, FM_3, FM_4, FM_5, FM_6
;  		dc.b PSG_1,PSG_2,PSG_3,NOISE
;  		dc.b PCM_1,PCM_2,PCM_3,PCM_4,PCM_5,PCM_6,PCM_7,PCM_8
;  		dcb.b $12,$00
;   		incbin "engine/sound/data/music/test.it",$50+$19DD+$28
;   		even
; @Voices:
;   		dc.w 4,0
;    		dc.l ins_fmdrum_closedhat
;    		dc.w 6,0
;    		dc.l ins_bass_techno
;    		dc.w 7,0
;   		dc.l ins_brass_funny
;     		dc.w 9,0
;     		dc.l ins_fx_echo 
;  		dc.w $FFFF
;  		even
; @Samples:
;   		dc.w 1,0
;   		dc.l samp_Kick
;   		dc.l samp_Kick_end
;   		dc.l samp_Kick
;   		dc.w 2,0
;   		dc.l samp_Snare
;   		dc.l samp_Snare_end
;   		dc.l samp_Snare
;   		dc.w 3,0
;   		dc.l samp_Tom
;   		dc.l samp_Tom_end
;   		dc.l samp_Tom
;  		dc.w $FFFF
;  		even
; 
; @ExSampl:
;  		if SegaCD
;   		dc.b "pia_rave"			;FIRST LIST	Hadagi filename
;   		dc.w -1				;		Sample loop | -1 = dont loop
;   		dc.w 0				;		Pitch
;  		dc.w $FFFF
;   		dc.b 1,1			;SECOND LIST
;   		dc.b 2,2		
; 
;  		elseif MARS
;   		dc.l pcm_brass_1		;FIRST LIST     PWM Start/End
;   		dc.w -1				;		Sample loop | -1 = dont loop
;    		dc.w 0				;		Pitch
;  		dc.w $FFFF
;   		dc.b 1,1			;SECOND LIST
;   		dc.b 2,2		
;  		endif
;  		
;  		dc.w $FFFF
;  		even
;  		
; ; ---------------------------------------------------
; 
TestSong:
  		dc.l @Voices,@Samples,@ExSampl
   		dc.b 8,3
  		dc.b FM_1,FM_2,FM_3,FM_4,FM_5,FM_6
  		dc.b PSG_1,PSG_2,PSG_3,-1
  		dc.b PCM_1,PCM_2,PCM_3,PCM_4,PCM_5,PCM_6,PCM_7,PCM_8
  		dcb.b $12,$00
   		incbin "engine/sound/data/music/kid.it",$50+$10BE
   		even
@Voices:
     		dc.w 1,0
     		dc.l ins_kid_1
        	dc.w 2,0
       		dc.l ins_kid_2
;      		dc.w 9,0
;      		dc.l ins_fx_echo 
  		dc.w $FFFF
  		even
@Samples:
;   		dc.w 3,0
;     		dc.l samp_Kick
;     		dc.l samp_Kick_end
;     		dc.l samp_Kick
;    		dc.w 6,0
;     		dc.l samp_Snare
;     		dc.l samp_Snare_end
;     		dc.l samp_Snare
;     		dc.w 4,0
;     		dc.l samp_Tom
;     		dc.l samp_Tom_end
;     		dc.l samp_Tom
;    		dc.w 18,0
;    		dc.l samp_Tom
;    		dc.l samp_Tom_end
;    		dc.l samp_Tom
 		dc.w $FFFF
  		even
 
@ExSampl:
 		if SegaCD
       		dc.b "PIANRAVE.BIN"		;FIRST LIST	Hadagi filename
       		dc.w -1				;		Sample loop | -1 = dont loop
       		dc.w 0				;		Pitch
       		dc.b "CHOR.BIN",0,0,0,0
       		dc.w 0	
       		dc.w -11
    		dc.w $FFFF
      		dc.b 2,1			;SECOND LIST
       		dc.b 12,2		
 
   		elseif MARS
     		dc.l pcm_piano			;FIRST LIST     PWM Start/End
    		dc.w -1				;		Sample loop | -1 = dont loop
     		dc.w 0				;		Pitch
   		dc.l pcm_brass_1
    		dc.w 0
     		dc.w -11
   		dc.w $FFFF
    		dc.b 2,1			;SECOND LIST
    		dc.b 12,2		
   		endif
  		
  		dc.w $FFFF
  		even
 		
SmegSong_Title:
 		dc.l @Voices,@Samples,@ExSampl
   		dc.b 1,1
  		dc.b FM_1,FM_2,FM_3,FM_4,FM_5,FM_6
  		dc.b PSG_1,PSG_2,PSG_3,NOISE	
   		dc.b PCM_1,PCM_2,PCM_3,PCM_4,PCM_5,PCM_6,PCM_7,PCM_8
  		dcb.b $12,$00
   		incbin "engine/sound/data/music/title.it",$50+$1677+8
   		even
@Voices:
;     		dc.w 8,0
;      		dc.l ins_fmdrum_closedhat
;     		dc.w 3,0
;      		dc.l ins_bass_techno
;      		dc.w 1,0
;     		dc.l ins_piano_real
     		dc.w 1,0
      		dc.l ins_fx_echo 
  		dc.w $FFFF
  		even
@Samples:
   		dc.w 4,0
    		dc.l samp_Kick
    		dc.l samp_Kick_end
    		dc.l samp_Kick
    		dc.w 1,0
    		dc.l samp_Snare
    		dc.l samp_Snare_end
    		dc.l samp_Snare
    		dc.w 16,0
    		dc.l samp_Tom
    		dc.l samp_Tom_end
    		dc.l samp_Tom
    		dc.w 18,0
    		dc.l samp_Tom
    		dc.l samp_Tom_end
    		dc.l samp_Tom
  		dc.w $FFFF
  		even
 
@ExSampl:
 		if SegaCD
       		dc.b "BRASEPIC.WAV"	;FIRST LIST	Hadagi filename
       		dc.w -1			;		Sample loop | -1 = dont loop
      		dc.w +12		;		Pitch
       		dc.b "PIANO__1.WAV"
       		dc.w -1
       		dc.w +12
    		dc.w $FFFF
      		dc.b 1,1		;SECOND LIST
       		dc.b 12,2		
 
   		elseif MARS
   		dc.l pcm_brass_1
    		dc.w 0
     		dc.w -11
   		dc.w $FFFF
    		dc.b 1,1		;SECOND LIST
    		dc.b 12,2	
   		endif
  		
  		dc.w $FFFF
  		even
 		
; ================================================================
; ---------------------------------------------------
; SFX
; ---------------------------------------------------

TestSfx:
		dc.l 0,0,0
 		dc.b 1,1
		dc.b FM_1,FM_2,FM_3,FM_4,FM_5,FM_6,PSG_1,PSG_2,PSG_3,NOISE,PCM_1,PCM_2,PCM_3,PCM_4,PCM_5,PCM_6,PCM_7,PCM_8
		dcb.b $12,$00

		incbin	"engine/sound/data/sfx/genny_jump.it",0x37F
		even