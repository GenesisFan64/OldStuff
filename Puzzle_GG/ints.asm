; ====================================================================
; -------------------------------------------------
; IRQ
; -------------------------------------------------

		org     38h		; AT 38h: Vblank interrupt
		di
		exx
		push    af
		push	bc
		push	de
		exx
		push	af
		push	bc
		push	de
		push	hl
		push	ix
		push	iy
		
		in      a,(Vcom)
		and	%10000000
		jr	nz,@its_vint
		call	HBlank
		jr	@cont_irq
@its_vint:
		call	VBlank
@cont_irq:
		pop	iy
		pop	ix
		pop	hl
		pop	de
		pop	bc
		pop     af
		exx
		pop	de
		pop	bc
		pop     af
		exx
		ei
		retn

; ====================================================================
; -------------------------------------------------
; SMS PAUSE
; -------------------------------------------------

		org     66h		; SMS pause button
		push	af
		ld	a,(ram_joypads+on_hold)
		set 	bitJoyStart,a
		ld	(ram_joypads+on_hold),a
		ld	a,(ram_joypads+on_press)
		set 	bitJoyStart,a
		ld	(ram_joypads+on_press),a
		pop	af
		retn	

; ====================================================================
; -------------------------------------------------
; VBlank
; -------------------------------------------------

VBlank:		
		call	palfade
		call	pads_read
		
; --------------------
; Horizontal scroll
; --------------------

		ld      hl,ram_hscroll
		ld	a,(hl)
 		if MERCURY
  		add 	30h
  		else
  		add	8h		;TODO: nah, luego pensarlo
 		endif
		out     (Vcom),a
		ld      a,088h
		out     (Vcom),a
		
; --------------------
; GG Ver Scroll
; --------------------

   		if MERCURY
   		
    		;DOWN scroll
 		ld      hl,ram_vscroll
 		ld	a,(ram_vintwait)
    		bit 	bitVerDir,a
    		jp	nz,@gg_verup
 		ld      a,(hl)
   		sub 	38h
   		cp	0E0h
   		jp	c,@dontfix
   		xor	a
   		ld	b,a
     		ld	a,38h
    		ld	(hl),a
    		ld	a,b
@dontfix:
 		jr	@cont_ggver
 	
; --------------------
    		;UP scroll
@gg_verup:
 		ld      hl,ram_vscroll
 		ld      a,(hl)
   		sub 	38h
    		cp	0E0h
    		jp	c,@dontfix2
      		ld	a,0E0h
    		ld	b,a
     		ld	a,38h-21h
      		ld	(hl),a
     		ld	a,b
@dontfix2:
 		nop
 		
@cont_ggver:
 		else
		
; --------------------
; SMS Ver Scroll
; --------------------

		ld      hl,ram_vscroll
 		ld	a,(ram_vintwait)
    		bit 	bitVerDir,a
    		jp	nz,@ms_verup
		ld      a,(hl)
		cp	0E0h
		jp	c,@dontfix_u
		xor	a
		ld	(hl),a
@dontfix_u:
		jr	@cont_msver
@ms_verup:
		ld      a,(hl)
		cp	0E0h
		jp	c,@dontfix_u
		ld	a,0DFh
		ld	(hl),a
@cont_msver:

; --------------------

   		endif
   		
		out     (Vcom),a
		ld      a,089h
		out     (Vcom),a
	
; --------------------
; Palette
; --------------------
 		
		ld	a,0
 		out     (Vcom),a
 		ld      a,Vcolor
 		out     (Vcom),a
		ld	hl,ram_palbuffer
		if MERCURY
		ld	b,32*2
		else
		ld	b,32
		endif
 		ld 	c,Vdata	
 		otir	

; --------------------
; Sprites
; --------------------

		ld	hl,ram_sprbuffer
		ld	b,03Fh
		ld	c,0
@next_spr:
		xor	a			;Vertical data
		add 	c
		out	(Vcom),a
		ld	a,3Fh|40h
		out	(Vcom),a
		ld      a,(hl)
		dec	a
		inc	hl
		out     (Vdata),a
		push    af
		pop     af
		
		ld	a,80h			;Horizontal and char data
		add 	c
		add 	c
		out	(Vcom),a
		ld	a,3Fh|40h
		out	(Vcom),a
		ld      a,(hl)
		inc	hl
		out     (Vdata),a
		push    af
		pop     af
		ld      a,(hl)
		inc	hl
		out     (Vdata),a
		push    af
		pop     af
		
		;Options
; 		ld	a,(hl)
; 		inc	hl
		inc	c
 		djnz	@next_spr
	
; --------------------
; Frame count
; --------------------

 		ld	a,(ram_vintframes)
 		inc 	a
 		ld	(ram_vintframes),a
 		
; --------------------
; VSync done
; --------------------
 		
 		ld	a,(ram_vintwait)
 		res	bitFrameWait,a
 		ld	(ram_vintwait),a
 		
 		call	SMEG_Upd
		retn

; -------------------------------------------------
; HBlank
; -------------------------------------------------

HBlank:
		retn
		