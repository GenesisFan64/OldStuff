; ====================================================================
; -------------------------------------------------
; IRQ
; 
; AF is always saved
; -------------------------------------------------

		org     38h		; AT 38h: Interrupts
 		di
		push	af
		
		in      a,(Vcom)
		and	%10000000
		jr	nz,@its_vint
		
		;Save manually
		call	ram_hintjmpto
		jp	@cont_irq
@its_vint:
 		ld	a,(ram_vintwait)
 		res	bitFrameWait,a
 		ld	(ram_vintwait),a
		call	ram_vintjmpto
@cont_irq:
		pop     af
		ei
		retn

; ====================================================================
; -------------------------------------------------
; SMS PAUSE
; -------------------------------------------------

		org     66h		; SMS pause button
		retn	

; ====================================================================
; -------------------------------------------------
; VBlank
; -------------------------------------------------

VBlank_Default:	
		push	bc
		push	de
		push	hl
		push	ix
		push	iy

		call	palfade
		call	pads_read

; --------------------

		ld	hl,ram_tilestovdp
		xor	a
  		out 	(Vcom),a
  		ld	a,20h|WriteMask
    		out 	(Vcom),a
		ld	c,Vdata
		ld	b,0D0h
		otir

; --------------------

; --------------------
; Horizontal scroll
; --------------------

		ld	a,(ram_hscroll)
 		if MERCURY
  		add 	30h
  		else
  		ld	b,a
  		ld	a,(ram_vdpregs)
  		bit 	bit_HScrlBar,a		;horizontal bar?
  		jp	z,@itsfull
  		ld	a,b
  		add	8
  		ld	b,a
@itsfull:
 		ld	a,b
 		endif
		out     (Vcom),a
		ld      a,088h
		out     (Vcom),a

; --------------------
; Vertical scroll
; 
; WORD
; --------------------

		ld	bc,0
		ld	a,(ram_vscroll)
		srl	a
		srl	a
		srl	a
		ld	c,a
		ld	a,(ram_vscroll+1)
		and	111b
		sla	a
		sla	a
		sla	a
		sla	a
		sla	a
		or	c
		ld	c,a	
 		ld	a,(ram_vscroll+1)
 		and	11111000b
  		srl	a
  		srl	a
  		srl	a
  		and 	111b
  		ld	d,a
 		
		ld	a,(ram_vscroll+1)
		bit 	7,a
		jp	z,@down
		
 		dec 	bc
 		dec 	bc
 		dec 	bc
 		dec 	bc
		
@down:
		ld	hl,ver_table
		add 	hl,bc
		ld	a,(hl)
		ld	c,a
		
		ld	a,(ram_vscroll)
		and 	07h
		or	c
 		out     (Vcom),a
 		ld      a,089h
 		out     (Vcom),a

; --------------------
; Palette
; --------------------
 		
		xor 	a
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

		ld	hl,ram_tilestovdp+0D0h
		ld	a,0D0h
  		out 	(Vcom),a
  		ld	a,20h|WriteMask
    		out 	(Vcom),a
		ld	c,Vdata
		ld	b,0D0h
		otir

; --------------------

; --------------------------
; Sprites
;
; Y X Chr
; 
; MERCURY:
; X:
; $00-$9F Visible
; Y:
; $00-$3F Hidden
; $40-$CF Visible
; 
; MASTER SYSTEM:
; X:
; $00-$FF Visible
; (Cannot hide horizontally
;  without the border)
; Y:
; $00-$3F Hidden
; $40-$FF Visible
; --------------------------

		ld	de,ram_sprbuffer
		ld	b,03Fh
		ld	c,0
@next_spr:
		ld	a,c
		out	(Vcom),a
		ld	a,3Fh|40h
		out	(Vcom),a
		ld      a,(de)
		dec	a
		inc	de
		if MERCURY
		add 	18h-40h
		else
		sub 	40h
		endif
		out     (Vdata),a
		push    af
		pop     af
		
		ld	a,c
		sla	a
		or	80h
		out	(Vcom),a
		ld	a,3Fh|40h
		out	(Vcom),a
		ld      a,(de)
		inc	de
		if MERCURY
 		add 	28h
 		endif
		out     (Vdata),a
		push    af
		pop     af
		ld      a,(de)
		inc	de
		out     (Vdata),a
		push    af
		pop     af
		
		inc	c
		ld	a,(de)
		jp	z,@stop_spr
 		djnz	@next_spr
@stop_spr:

; --------------------
; VSync done
; --------------------
 		
 		call	SMEG_Upd

		pop	iy
		pop	ix
		pop	hl
		pop	de
		pop	bc
		ret

; -------------------------------------------------
; HBlank
; -------------------------------------------------

HBlank_Default:
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