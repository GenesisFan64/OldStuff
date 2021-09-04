; ====================================================================
; -------------------------------------------------
; Title Screen
; -------------------------------------------------

segalogo:
  		ld	b,ID_FadeOut
  		ld	de,1F00h
  		call	PalFade_Set
    		call	PalFade_Wait
    		
		di
		call	clearscreen
		bankdata BANK_Title
		
		ld	hl,art_title			;  hl = 0208   where is data at
		ld	de,0				;  de = 0      where in VRAM to put data
		ld	bc,art_title_end		;  bc = 0380   how many times to write to vram
		call	WriteVRAM

		ld	ix,map_title
		ld	bc,1412h
 		ld	de,screen
 		call	VDP_LoadMaps
		ld	hl,pal_title
		ld	b,16
		ld	c,0
 		call	PalFade_Load
 		
;       	ld	hl,SmegSong_Test
;       	ld	b,1
;        	call	Smeg_LoadSong

		ei
 		ld	b,ID_FadeIn
 		ld	de,1F00h
 		call	PalFade_Set
 		call	PalFade_Wait
		
;  		di
;     		bankdata BANK_WAVE
;            	call	PlayPCM
;             	ei
         	
; -------------------------------------------------
; Loop
; -------------------------------------------------

@loop:
		call	VSync
		
		ld	a,(ram_joypads+on_hold)
		bit 	bitJoy1,a
		jr      nz,@end_this
		jp	@loop

; -------------------------------------------------

@end_this:
		ld	a,1
		ld	(ram_gamemode),a
		ret
		