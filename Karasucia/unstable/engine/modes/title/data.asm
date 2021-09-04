; ====================================================================
; -------------------------------------------------
; Title DATA
; -------------------------------------------------
		
Pal_Title:	incbin	"engine/modes/title/data/pal.bin"
		even
Map_Title:	incbin	"engine/modes/title/data/map.bin"
		even
Art_Title:	incbin	"engine/modes/title/data/art.bin"
Art_Title_End:	even

; Pal_Gen3:	incbin	"engine/modes/title/data/pal_2.bin"
; 		even
; Map_Gen3:	incbin	"engine/modes/title/data/map_2.bin"
; 		even
; Art_Gen3:	incbin	"engine/modes/title/data/art_2.bin"
; Art_Gen3_End:	even

; -------------------------------------------------
				
; --------------------------
; SFX: COIN
; --------------------------

Snd_TestNotes:
		dc.b 0,-1
		dc.l @notes
     		dc.l @ins
     		dc.w 1
      		dc.b FM_3,64,$80,$F
@notes:		incbin "engine/sound/testins.bin"
      		even
@ins:		dc.w @ymha-@ins,-1,@noise-@ins 
@ymha:		dc.w 1,0
		dc.l test_fm
		dc.w 2,0
		dc.l test_fm+$19
		dc.w 3,0
		dc.l test_fm
		dc.w 4,0
		dc.l test_fm
		dc.w 5,0
		dc.l test_fm
		dc.w 6,0
		dc.l test_fm
	
@noise:		dc.w 1,%100
		even

test_fm:	incbin	"engine/sound/instruments/FM/bass/bass_jazz.bin"
		incbin	"engine/sound/instruments/FM/brass/brass_trumpet.bin"
		even
		
; -------------------------------------------------

fmVoice_bell_1:
		incbin	"engine/sound/instruments/fm/bell/bell_xmas.bin"
		even
fmVoice_piano_rave:
		incbin	"engine/sound/instruments/fm/piano/piano_rave_old.bin"
		even
fmVoice_bass_ambient:
		incbin	"engine/sound/instruments/fm/bass/bass_ambient.bin"
		even
fmVoice_bass_2:
		incbin	"engine/sound/instruments/fm/bass/bass_low.bin"
		even
fmVoice_belllow:
		incbin	"engine/sound/instruments/fm/brass/brass_funny.bin"
		even
fmVoice_flaute_2:
		incbin	"engine/sound/instruments/fm/ding_1.bin"
		even
fmVoice_brass_trumpet:
		incbin	"engine/sound/instruments/fm/brass/brass_trumpet.bin"
		even
fmVoice_bell_low:
		incbin	"engine/sound/instruments/fm/bell/bell_low.bin"
		even
		
fm_hatopen:
		incbin	"engine/sound/instruments/fm/drums/fm3_openhat.bin"
		even
fm_hatclosed:
		incbin	"engine/sound/instruments/fm/drums/fm3_closedhat.bin"
		even

fmVoice_dolp_wha:
		incbin	"engine/sound/instruments/fm/fx/dolphin_wah.bin"
		even
fmVoice_openhat:
		incbin	"engine/sound/instruments/fm/wsb95_bullpen.bin"
		even
; 		
; 		cnop 0,$8000
; wav_yobeats:	incbin	"engine/sound/instruments/dac/beat_yo.wav",$2C
; wav_yobeats_e:	even
; 
; hrdcbyte:	incbin	"engine/sound/instruments/dac/hrdcbyte.wav",$2C
; hrdcbyte_e:	even
; 
; dnceheye:	incbin	"engine/sound/instruments/dac/dnceheye.wav",$2C
; dnceheye_e:	even

; 		if MCD|MARS=0
; TEST_WAV:	incbin "ideas/test.wav",$2C,$200000
; TEST_WAV_end:	even
; 		endif

wav_kick:	incbin	"engine/sound/instruments/dac/sauron_kick.wav",$2C
wav_kick_e:
wav_tom:	incbin	"engine/sound/instruments/dac/sauron_tom.wav",$2C
wav_tom_e:
wav_snare:	incbin	"engine/sound/instruments/dac/snare.wav",$2C
wav_snare_e:
		even
		
