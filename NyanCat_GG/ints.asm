; ====================================================================
; -------------------------------------------------
; IRQ
; 
; AF and HL are always saved
; -------------------------------------------------

		org     38h		; AT 38h: Interrupts
 		di
		push	af
		
		in      a,(Vcom)
		and	%10000000
		jp	nz,@its_vint
		
; -------------------------------------------------
; HBlank
; -------------------------------------------------

; 		pop	af
; 		ei
; 		retn
; 		
		jp	hblank
		
; -------------------------------------------------
; VBlank
; -------------------------------------------------

@its_vint:
		jp	vblank

; ====================================================================
; -------------------------------------------------
; SMS PAUSE
; -------------------------------------------------

		org     66h		; SMS pause button
		retn	

; ====================================================================


VBlank_Default:	
		exx
		push	ix
		push	iy
		


; 		call	palfade
; 		call	pads_read

; --------------------
; Palette
; --------------------
 		
; 		xor 	a
;  		out     (Vcom),a
;  		ld      a,Vcolor
;  		out     (Vcom),a
;  		
; 		ld	hl,ram_palbuffer
; 		if MERCURY
; 		ld	b,32*2
; 		else
; 		ld	b,32
; 		endif
;  		ld 	c,Vdata	
;  		otir	

; --------------------
; VSync done
; --------------------
 		
		pop	iy
		pop	ix
		exx
		ret

; -------------------------------------------------
; HBlank
; -------------------------------------------------

HBlank_Default:
		exx
		
		ld	a,(ram_modebuffer)
		ld	e,a
		ld	a,(ram_modebuffer+1)
		ld	d,a
		
 		ld      a,(de)
 		rrca
 		rrca
 		rrca
  		rrca
   		and     %00001111
   		or      90h;+40h
    		out     (7Fh),a
     		add	20h
     		out     (7Fh),a
     		add	20h
     		out     (7Fh),a
     		
		inc 	de
		
 		ld	a,d
 		cp	0C0h
  		jp	c,@keep
  		ld	d,80h
		ld	a,(ram_modebuffer+2)
		inc 	a
    		ld      (0FFFFh),a
		ld	(ram_modebuffer+2),a
		
@keep:
		ld	a,e
		ld	(ram_modebuffer),a
		ld	a,d
		ld	(ram_modebuffer+1),a
		
		exx
 		ret
		
; -------------------------------------------------
; Data
; -------------------------------------------------

ver_table:
		if MERCURY
		incbin "subs/vertblm.bin"
		else
		incbin "subs/vertbl.bin"
		endif