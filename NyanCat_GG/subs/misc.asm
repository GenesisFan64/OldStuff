;****************************************************
; initialize the system
;****************************************************

initsys:
		if MERCURY
		ld      a,0FFh    	; all ones
		out     (02h),a   	; set i/o port 2h (read/write) to all ones
		xor     a         	; set a to zero
		out     (01h),a   	; set i/o port 1h (read/write from ext
			       	  	;  connector) to zero
		out     (05h),a   	; set i/o port 5h (read/write serial comm)
			      	  	;  to zero
			      	  	
                ld	a,0FFh
                out 	(06h),a
                endif

		xor     a         	; set a to zero
		ld      (0FFFCh),a	; set bank control register to all zeros
		ld      (0FFFDh),a	; set bank reg #0 to all zeros
		inc	a
		ld      (0FFFEh),a	; set bank reg #1 to 0001
		inc	a
		ld      (0FFFFh),a	; set bank reg #2 to 0010
		
		ld      hl,0C000h  	; zero system RAM
		ld      de,0C001h  	; C000h to DFF0h
		ld      bc,01FF0h  	; number of times to write
		ld      (hl),0
		ldir               	; load (de) with (hl). inc de, inc hl, dec bc
					; continue until bc = 0
					
		ret

;****************************************************
; clear the screen data area
;****************************************************

clearscreen:
		ld      hl,screen  	; start at VRAM address 3800h
		ld      e,0        	; number to place in VRAM
		ld      bc,768*2   	; number of times to write to VRAM
		jp      VDPWrite

; --------------------------------------------
; HexToBCD
; --------------------------------------------

HexToBCD:
		ld	c,a		; Original (hex) number
		ld	b,8		; How many bits
		xor	a		; Output (BCD) number, starts at 0
@rept:		sla	c		; shift c into carry
		adc	a,a
		daa			; Decimal adjust a, so shift = BCD x2 plus carry
		djnz	@rept		; Repeat for 8 bits
		ret
		
; --------------------------------------------
; Mode cleanup
; --------------------------------------------
		
Mode_Cleanup:
		ld	bc,0
		ld	(ram_hscroll),bc
		ld	(ram_vscroll),bc
		ret

; ====================================================================
; ---------------------------------------------
; Sprites system
; ---------------------------------------------

; TODO: talvez moverlo

		rsreset
sprite_free	rw	1
sprite_used	rb	1

; ---------------------------------------------
; Sprites_Reset
; ---------------------------------------------

Sprites_Reset:
; 		lea	(RAM_SprControl),a6
; 		movea.l	sprite_free(a6),a5
; 		cmpa	#((RAM_SprBuffer)&$FFFF),a5
; 		blt.s	@Full
; @NextEntry:
; ; 		tst.l	(a5)
; ; 		beq.s	@Full
; ; 		tst.l	4(a5)
; ; 		beq.s	@Full
;  		cmpa	#((RAM_SprBuffer+$280)&$FFFF),a5
;  		bgt.s	@Full
;  		clr.l	(a5)+
;   		clr.l	(a5)+
;   		cmpa	#((RAM_SprBuffer+$280)&$FFFF),a5
;   		blt.s	@NextEntry
; @Full:
		ld	bc,RAM_SprBuffer
		ld	(RAM_SprControl),bc
; 		move.w	#1,sprite_link(a6)
; @Return:
		ret
	
; ---------------------------------------------
; Sprites_CopyTiles
; 
; since i dont have DMA here
; lets use RAM-to-VDP
; ---------------------------------------------

Sprites_CopyTiles:
		ld	hl,ram_tilestovdp
		
		xor	a
  		out 	(Vcom),a
  		ld	a,20h
  		or	WriteMask
    		out 	(Vcom),a
		ld	c,Vdata
		
; 		ld	a,(ram_vdpregs+1)
; 		res 	6,a
; 		out 	(Vcom),a
; 		ld	a,81h
; 		out 	(Vcom),a
; 		
		ld	b,0
		otir
		ld	b,0
		otir
		ld	b,0
		otir
		ld	b,0
		otir
		
; 		ld	a,(ram_vdpregs+1)
; 		out 	(Vcom),a
; 		ld	a,81h
; 		out 	(Vcom),a
		ret 
		