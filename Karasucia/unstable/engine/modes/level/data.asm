; =================================================================
; ------------------------------------------------
; DMA art
; ------------------------------------------------

		cnop 0,$4000
Art_Player:	incbin	"engine/modes/level/data/objects/player/data/art.bin"
		even
artObj_EndFlag:	incbin	"engine/modes/level/data/objects/endflag/data/art.bin"
 		even
Art_AnimCoin:	incbin	"engine/modes/level/data/layouts/coin_art.bin"
		even

; =================================================================
; ------------------------------------------------
; Non-DMA art
; ------------------------------------------------
	
; ---------------------------
; Objects
; ---------------------------

		cnop 0,$800
Art_dadou:	incbin	"engine/modes/level/data/objects/dadou/data/art.bin"
art_dadou_end:
 		even
Art_pikudo:	incbin	"engine/modes/level/data/objects/pikudo/data/art.bin"
art_pikudo_end:
 		even
 		
artObj_Platform:
		incbin	"engine/modes/level/data/objects/platform/data/art.bin"
artObj_Platform_e:
 		even
artObj_Ball:	incbin	"engine/modes/level/data/objects/ball/data/art.bin"
artObj_Ball_e:	even
 		
; =================================================================
; ------------------------------------------------
; Other stuff
; ------------------------------------------------

; ---------------------------
; Player
; ---------------------------

Map_Player:	include	"engine/modes/level/data/objects/player/data/map.asm"
		even
DPLC_Player:	include	"engine/modes/level/data/objects/player/data/plc.asm"
		even
Pal_Player:	incbin	"engine/modes/level/data/objects/player/data/pal.bin"
Pal_Player_End:
		even

; ---------------------------
; Objects
; ---------------------------

Map_dadou:	include	"engine/modes/level/data/objects/dadou/data/map.asm"
 		even
Map_pikudo:	include	"engine/modes/level/data/objects/pikudo/data/map.asm"
 		even
Map_ball:	include	"engine/modes/level/data/objects/ball/data/map.asm"
 		even
objMap_Platform:include	"engine/modes/level/data/objects/platform/data/map.asm"
 		even
mapObj_EndFlag:	include	"engine/modes/level/data/objects/endflag/data/map.asm"
 		even
dplcObj_EndFlag:include	"engine/modes/level/data/objects/endflag/data/plc.asm"
		even
		
; ====================================================================
; -------------------------------------------------
; Level DATA
; -------------------------------------------------

LevelList:
		dc.l $01<<24|Lvl_Zone1		; Level data
		dc.l Pal_LvlMain_Gray		; Palette
		dc.w $20,$F0			; Player X/Y
		dc.w $1100,$78			; End flag X/Y
; 		dc.l $01<<24|Lvl_Zone2
; 		dc.l Pal_LvlMain_Gray
; 		dc.w $20,$D0
; 		dc.w 0,0
; 		dc.l Lvl_Zone3
; 		dc.l Pal_LvlMain_Gray
; 		dc.w $28,$250
; 		dc.w 0,0
; 		dc.l Lvl_Zone1
; 		dc.l Pal_LvlMain_Gray
; 		dc.w $10,0
; 		dc.w 0,0
; 		dc.l Lvl_Zone1
; 		dc.l Pal_LvlMain_Gray
; 		dc.w $10,0
; 		dc.w 0,0
; 		even
		
artdata_Level_Test:
 		dc.l art_dadou
		dc.w varVramDadou
 		dc.w ((art_dadou_end-art_dadou)/4)-1
  		dc.l artObj_Ball
		dc.w varVramBall
 		dc.w ((artObj_Ball_e-artObj_Ball)/4)-1
 		dc.l Art_pikudo
		dc.w varVramPikudo
 		dc.w ((Art_pikudo_end-Art_pikudo)/4)-1
 		
 		dc.l artObj_Platform
 		dc.w varVramPlatfrm
 		dc.w ((artObj_Platform_e-artObj_Platform)/4)-1
 		
 		dc.w -1
 		even
 		
; --------------------------------------------
; Levels
; --------------------------------------------

Lvl_Zone1:	dc.w 280,24
		dc.l @objects
		dc.l @FG_blk,-1			; Block VRAM / Prize VRAM (-1, use defaults) 
		dc.l @FG_lay_low,@FG_lay_hi	; Level layout hi/low
		dc.l @FG_col,@FG_prz		; Collision / Prizes
; 		dc.w -1
		
@FG_lay_low:	incbin	"engine/modes/level/data/layouts/main/1/fg_lay_low.bin"
 		even
@FG_lay_hi:	incbin	"engine/modes/level/data/layouts/main/1/fg_lay_hi.bin"
 		even	
@FG_col:	incbin	"engine/modes/level/data/layouts/main/1/fg_col.bin"
 		even
@FG_prz:	incbin	"engine/modes/level/data/layouts/main/1/fg_prz.bin"
 		even 
@FG_blk:	incbin	"engine/modes/level/data/layouts/main/lvl_blk.bin"
 		even
@objects:	include	"engine/modes/level/data/layouts/main/1/objlist.asm"
 		even

; --------------------------------------------

; Lvl_Zone2:	dc.w 228,14
; 		dc.l @objects
; 		dc.l @FG_blk,-1			;Block VRAM / Prize VRAM (-1, use defaults) 
; 		dc.l @FG_lay_low,@FG_lay_hi	;Level layout hi/low
; 		dc.l @FG_col,@FG_prz		;Collision / Prizes
; ; 		dc.w -1
; 		
; @FG_lay_low:	incbin	"engine/modes/level/data/layouts/main/2/fg_lay_low.bin"
;  		even
; @FG_lay_hi:	incbin	"engine/modes/level/data/layouts/main/2/fg_lay_hi.bin"
;  		even	
; @FG_col:	incbin	"engine/modes/level/data/layouts/main/2/fg_col.bin"
;  		even
; @FG_prz:	incbin	"engine/modes/level/data/layouts/main/2/fg_prz.bin"
;  		even 
; @FG_blk:	incbin	"engine/modes/level/data/layouts/main/lvl_blk.bin"
;  		even
; @objects:	include	"engine/modes/level/data/layouts/main/2/objlist.asm"
;  		even
 
; --------------------------------------------

; Lvl_Zone3:	dc.w 20,40
; 		dc.l @objects
; 		dc.l @FG_blk,-1			;Block VRAM / Prize VRAM (-1, use defaults) 
; 		dc.l @FG_lay_low,@FG_lay_hi	;Level layout hi/low
; 		dc.l @FG_col,@FG_prz		;Collision / Prizes
; ; 		dc.w -1
; 		
; @FG_lay_low:	incbin	"engine/modes/level/data/layouts/main/3/fg_lay_low.bin"
;  		even
; @FG_lay_hi:	incbin	"engine/modes/level/data/layouts/main/3/fg_lay_hi.bin"
;  		even	
; @FG_col:	incbin	"engine/modes/level/data/layouts/main/3/fg_col.bin"
;  		even
; @FG_prz:	incbin	"engine/modes/level/data/layouts/main/3/fg_prz.bin"
;  		even 
; @FG_blk:	incbin	"engine/modes/level/data/layouts/main/lvl_blk.bin"
;  		even
; @objects:	include	"engine/modes/level/data/layouts/main/3/objlist.asm"
;  		even

; --------------------------------------------

Pal_LvlMain_Gray:
		incbin	"engine/modes/level/data/layouts/main/lvl_pal.bin"
		incbin	"engine/modes/level/data/layouts/main/bg_pal.bin"
		even
		
Art_Lvl_Test:	incbin	"engine/modes/level/data/layouts/main/lvl_art.bin"
Art_Lvl_Test_e:	even

Art_LvlBG_Test:	incbin	"engine/modes/level/data/layouts/main/bg_art.bin"
Art_LvlBG_Test_e:
		even
Map_LvlBG_Test:	incbin	"engine/modes/level/data/layouts/main/bg_map.bin"
Map_LvlBG_Test_e:
		even
		
; --------------------------------------------

Art_LvlPrizes:	incbin	"engine/modes/level/data/layouts/prizes_art.bin"
		even
Art_LvlPrizes_e:

Pal_LvlCoinItms	incbin	"engine/modes/level/data/layouts/lvlitems_pal.bin"
		even
		
; ====================================================================
; -------------------------------------------------
; Sound data
; -------------------------------------------------

; --------------------------
; MUSIC level 1
; --------------------------

Music_Level1:
		dc.b 11,2
		dc.l @notes
     		dc.l @ins
     		dc.w 10
      		dc.b FM_1,64,$80,$0F
      		dc.b FM_2,64,$80,$0F
      		dc.b FM_3,64,$80,$0F
		dc.b FM_4,64,$80,$0F
		dc.b FM_5,64,$80,$0F
 		dc.b FM_6,64,$80,$0F
 		dc.b PSG_1,64,$80,$0F
 		dc.b PSG_2,64,$80,$0F
 		dc.b PSG_3,64,$80,$0F
 		dc.b NOISE,64,$80,$0F
 		even
@notes:		incbin "engine/sound/music/level0.it",$50+$11B
      		even
@ins:		dc.w @ymha-@ins,-1,@noise-@ins
		even
		
@ymha: 		dc.w 1,0
		dc.l fmBass_jazz
		dc.w 2|$40,0
		dc.l fm3drum_tick
		dc.w $00AB|$3800,$0457|$3000
		dc.w $0511|$3000,$0336|$2000
  		dc.w 3|$80,-24
  		dc.l wav_stKick
 		dc.l wav_stKick_e
 		dc.l -1
  		dc.w 4|$80,-24
  		dc.l wav_stSnare
 		dc.l wav_stSnare_e
 		dc.l -1
		dc.w -1
		even

@noise: 	dc.w 5,%100
		dc.w -1
		even
	
; --------------------------
; SFX: 1up
; --------------------------

SndSfx_OneUp:	dc.b 0,-1
		dc.l @pattr
     		dc.l @ins
     		dc.w 2
      		dc.b PSG_2,64,$80,$F
      		dc.b PSG_3,64,$80,$F
@pattr:		incbin "engine/sound/sfx/oneup.it",$50+$DC
		even
@ins: 		dc.w -1,-1,-1,-1
		even
				
; --------------------------
; SFX: BONK
; --------------------------

SndSfx_BONK:	dc.b 0,-1
		dc.l @pattern
     		dc.l @instruments
     		dc.w 3
      		dc.b FM_5,64,$80,%1110
      		dc.b FM_6,64,$80,$F
      		dc.b PSG_2,64,$80,$F
@pattern:	incbin "engine/sound/sfx/bonk.it",$50+$FC+$28
      		even

@instruments: 	dc.w @ymha-@instruments
		dc.w -1
		dc.w @noise-@instruments
		dc.w -1
		even
		
@ymha: 		dc.w 2,0
   		dc.l FMSfx_Bump

   		dc.w $80|3,-16
   		dc.l WAVE_lwpnch
   		dc.l WAVE_lwpnch_e
   		dc.l -1
   		
		dc.w -1	;EOL
		even
@noise: 	dc.w 2,%101
		dc.w -1
		even
		
; --------------------------
; SFX: Bonk a coin
; --------------------------

SndSfx_BonkCoin:
		dc.b 0,-1
		dc.l @pattern
     		dc.l @instruments
     		dc.w 4
      		dc.b FM_5,64,$80,%1110
      		dc.b FM_6,64,$80,$F
      		dc.b PSG_2,64,$80,$F
      		dc.b PSG_3,64,$80,$F
@pattern:	incbin "engine/sound/sfx/bonkcoin.it",$50+$12C
      		even

@instruments: 	dc.w @ymha-@instruments
		dc.w -1
		dc.w @noise-@instruments
		dc.w -1
		even
		
@ymha: 		dc.w 2,0
   		dc.l FMSfx_Bump

   		dc.w $80|3,-16
   		dc.l WAVE_lwpnch
   		dc.l WAVE_lwpnch_e
   		dc.l -1
   		
		dc.w -1	;EOL
		even
@noise: 	dc.w 2,%101
		dc.w -1
		even
		
; --------------------------
; SFX: PUM
; --------------------------

SndSfx_PUM:
		dc.b 0,-1
		dc.l @pattern
     		dc.l @instruments
     		dc.w 3
      		dc.b FM_5,64,$80,$0F
      		dc.b NOISE,64,$80,$0F
      		dc.b FM_6,64,$80,$0F
@pattern:	incbin "engine/sound/sfx/blkbump.it",$F4+$50+$20
      		even

@instruments:	dc.w @ymha-@instruments
		dc.w -1
		dc.w @noise-@instruments
		even

@ymha: 		dc.w 1,0
   		dc.l FMSfx_Punch
   		
   		dc.w $80|3,0
   		dc.l WAVE_lwpnch
   		dc.l WAVE_lwpnch_e
   		dc.l -1
   		
		dc.w -1	;EOL
		even
@noise:
 		dc.w 2,%110
		dc.w -1
		even

; --------------------------
; SFX: PING
; --------------------------

SndSfx_PING:
		dc.b 0,-1
		dc.l @notes
     		dc.l @ins
     		dc.w 2
      		dc.b NOISE,64,$80,$0F
      		dc.b FM_6,64,$80,$0F
@notes:		incbin "engine/sound/sfx/pingball.it",$50+$DC
      		even
@ins: 		dc.w @ymha-@ins
		dc.w -1
		dc.w @noise-@ins
		even
@noise:
 		dc.w 1,%100
		dc.w -1
		even
@ymha:
		dc.w $80|1,0
		dc.l WAVE_sfxBall
		dc.l WAVE_sfxBall_e
		dc.l -1
		
		dc.w -1
		even
		
; --------------------------
; SFX: COIN
; --------------------------

SndSfx_COIN:
		dc.b 0,-1
		dc.l @notes
     		dc.l @ins
     		dc.w 2
      		dc.b PSG_1,64,$80,$F
      		dc.b PSG_2,64,$80,$F
@notes:		incbin "engine/sound/sfx/coin.it",$50+$D4+8
      		even
@ins: 		dc.w -1
		dc.w -1
		dc.w -1
		even
		
; --------------------------
; SFX: COIN
; --------------------------

SndSfx_BEEBUZZ:
		dc.b 0,-1
		dc.l @notes
     		dc.l @ins
     		dc.w 1
      		dc.b FM_5,64,$80,$F
@notes:		incbin "engine/sound/sfx/beebuzz.it",$50+$D4
      		even
@ins: 		dc.w @ymha-@ins
		dc.w -1
		dc.w -1
		even
@ymha:
		dc.w 1,0
		dc.l fmSfx_BUZZ
		dc.l -1
		
		dc.w -1
		even
		
; --------------------------
; SFX: COIN
; --------------------------

SndSfx_PlyrJump:
		dc.b 0,-1
		dc.l @notes
     		dc.l @ins
     		dc.w 1
      		dc.b NOISE,64,$80,$F
@notes:		incbin "engine/sound/sfx/plyrjump.it",$50+$DC
      		even
@ins:		dc.w -1,-1,@noise-@ins
@noise:		dc.w 1,%100
		even
   
; --------------------------
; SFX: COIN
; --------------------------

SndSfx_HitEnemy:
		dc.b 0,-1
		dc.l @notes
		dc.l @ins
		dc.w 2
		dc.b FM_6,64,$80,$F
		dc.b NOISE,64,$80,$F
@notes:		incbin "engine/sound/sfx/bumpenemy.it",$50+$D4
		even
@ins:		dc.w @ymha-@ins,-1,@noise-@ins
@ymha:		dc.w 1,0
		dc.l FMSfx_Punch
@noise:		dc.w 2,%110
		
; --------------------------
; instruments
; --------------------------

fmBass_jazz:	incbin	"engine/sound/instruments/FM/bass/bass_jazz.bin"
		even
fm3drum_tick: 	incbin	"engine/sound/instruments/fm/drums/fm3_tick.bin"
		even
		
FMSfx_Punch:	incbin	"engine/sound/instruments/FM/fmsfx_boomlong.bin"
		even
FMSfx_Bump:	incbin	"engine/sound/instruments/FM/fmsfx_bump.bin"
		even
fmSfx_BUZZ:	incbin	"engine/sound/instruments/FM/old/socket_voiceset.bin",$19*18,$19
		even
		
WAVE_lwbonk:	incbin	"engine/sound/instruments/DAC/sfxbonk.wav",$2C
WAVE_lwbonk_e:	even
WAVE_lwpnch:	incbin	"engine/sound/instruments/DAC/sfxhithard.wav",$2C
WAVE_lwpnch_e:	even
WAVE_sfxBall:	incbin	"engine/sound/instruments/DAC/sfxBallTick.wav",$2C
WAVE_sfxBall_e:	even
wav_stKick:	incbin	"engine/sound/instruments/DAC/stKick.wav",$2C
wav_stKick_e:	even
wav_stSnare:	incbin	"engine/sound/instruments/DAC/stSnare.wav",$2C
wav_stSnare_e:	even
