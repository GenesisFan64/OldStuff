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
; VSync
; --------------------------------------------

vsync:
		halt
		ret
        