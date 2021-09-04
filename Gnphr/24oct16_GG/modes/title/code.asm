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
		bankdata BANK_Title
		
		call	clearscreen
		call	Mode_Cleanup
  		ld	a,(ram_vdpregs)
		res	bit_HscrlBar,a
		set 	4,a
		ld	(ram_vdpregs),a
		call	Vdp_Update
		
		ld	hl,art_title			;  hl = 0208   where is data at
		ld	de,0				;  de = 0      where in VRAM to put data
		ld	bc,art_title_end		;  bc = 0380   how many times to write to vram
		call	WriteVRAM
		ld	ix,map_title
		ld	bc,1412h
 		ld	de,screen
 		call	VDP_LoadMaps
 		
		ld	bc,VBlank_Default
		ld	(ram_vintaddr),bc
		ld	bc,HBlank_Default
		ld	(ram_hintaddr),bc
		
		ld	hl,pal_title
 		ld	ix,ram_palfadebuff
		ld	bc,0010h
 		call	PalFade_Load
 		
;     		ld	hl,SmegSong_Test
;     		ld	b,2h
;      		call	Smeg_LoadSong
		ei
		
 		ld	b,ID_FadeIn
 		ld	de,1F00h
 		call	PalFade_Set
 		call	PalFade_Wait
 		
;    		di
;              	call	PlayPCM
;                 ei
      
; 		ld	a,01h
; 		ld	(ram_modebuffer),a
		
; -------------------------------------------------
; Loop
; -------------------------------------------------

@loop:
		call	VSync
		
		ld	a,(ram_joypads+on_hold)
		bit 	bitJoy2,a
		jr      nz,@end_this
		jp	@loop

; -------------------------------------------------

@end_this:
		ld	a,1
		ld	(ram_gamemode),a
		ret
	
; -------------------------------------------------
; HBlank
; -------------------------------------------------
		
; -------------------------------------------------
; VBlank
; -------------------------------------------------
