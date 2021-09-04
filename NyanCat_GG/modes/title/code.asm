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

		bankdata BANK_Cat
		ld	hl,art_cat			;  hl = 0208   where is data at
		ld	de,100h*20h			;  de = 0      where in VRAM to put data
		ld	bc,art_cat_end			;  bc = 0380   how many times to write to vram
		call	WriteVRAM
		
		bankdata BANK_Title
		call	clearscreen
		call	Mode_Cleanup
  		ld	a,(ram_vdpregs)
		set	bit_HscrlBar,a
; 		set 	4,a
		ld	(ram_vdpregs),a
		ld	a,80h
		ld	(ram_vdpregs+00Ah),a
		call	Vdp_Update
		
 		xor	a
 		ld	(ram_hscroll),a

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
 		ld	ix,ram_palbuffer
		ld	bc,0020h
 		call	PalFade_Load
 		
 		if MERCURY
 		xor	a
 		ld	(ram_palbuffer+20h),a
 		ld	(ram_palbuffer+21h),a		
 		else
 		xor	a
 		ld	(ram_palbuffer+10h),a
 		endif

 		xor	a
 		out	(Vcom),a
 		or	Vcolor
 		out	(Vcom),a
 		ld	a,32
 		if MERCURY
 		rlca
 		endif
 		ld	b,a
		ld	hl,ram_palbuffer
@next:
		ld	a,(hl)
		out 	(Vdata),a
		inc 	hl
		djnz	@next
		
		xor	a
  		out	(Vcom),a
  		ld	a,3Fh|40h
  		out	(Vcom),a
  		
     		ld	c,4Ch
     		ld	a,c
   		out     (Vdata),a
   		out     (Vdata),a		
   		out     (Vdata),a
   		out     (Vdata),a
   		out     (Vdata),a
		add	10h
   		out     (Vdata),a
   		out     (Vdata),a		
   		out     (Vdata),a
   		out     (Vdata),a
   		out     (Vdata),a
		add	10h
   		out     (Vdata),a
   		out     (Vdata),a		
   		out     (Vdata),a
   		out     (Vdata),a
   		out     (Vdata),a
   		
  		ld	bc,504Ch
  		ld	a,c
    		out     (Vdata),a
  		add	10h
    		out     (Vdata),a
  		add	10h
    		out     (Vdata),a	
    		
  		ld	a,c
    		out     (Vdata),a
  		add	10h
    		out     (Vdata),a
  		add	10h
    		out     (Vdata),a
    		
  		ld	a,c
    		out     (Vdata),a
  		add	10h
    		out     (Vdata),a 
  		add	10h
    		out     (Vdata),a
    		
; HOR AND CHR
; 
     		ld	hl,ram_modebuffer
     		ld	bc,5C01h
     		rept 3
     		rept 5
     		ld	a,b
   		ld	(hl),a
   		inc 	hl
     		add 	10h
     		ld	b,a
     		ld	a,c
   		ld	(hl),a
   		inc 	hl	
   		inc	c
   		endr
   		ld	b,5Ch
   		endr

  		ld	b,30h
  		ld	c,5Bh
   		rept 3
  		ld	a,b
   		ld	(hl),a
   		inc 	hl
   		ld	a,c
   		inc 	c
   		ld	(hl),a
   		inc 	hl
  		ld	a,b
   		ld	(hl),a
   		inc 	hl
   		ld	a,c
   		inc 	c
   		ld	(hl),a
   		inc 	hl
  		ld	a,b
   		ld	(hl),a
   		inc 	hl
   		ld	a,c
   		dec	c
   		dec	c
   		ld	(hl),a
   		inc 	hl
   		ld	a,b
   		add	10h
   		ld	b,a
   		endr
  		
  		ld	a,80h
  		out	(Vcom),a
  		ld	a,3Fh|40h
  		out	(Vcom),a
  		
     		ld	hl,ram_modebuffer
     		ld	b,30h
@again:
   		ld	a,(hl)
   		inc 	hl
   		out     (Vdata),a
   		djnz	@again
  		
   		if MERCURY
   		ld	c,11111111b
   		ld	a,c
   		out	(06h),a
   		endif
   		ld      a,81h			;write $01 to tone channel 0
   		out     (7Fh),a
   		xor	a
   		out     (7Fh),a
   		ld      a,0A1h			;write $01 to tone channel 1
   		out     (7Fh),a
   		xor	a
   		out     (7Fh),a
  		ld      a,0C1h			;write $01 to tone channel 2
  		out     (7Fh),a
  		xor	a
  		out     (7Fh),a
  		
  		ld	bc,0F0h
  		ld	a,c
  		ld	(ram_modebuffer+88h),a
  		ld	a,b
  		ld	(ram_modebuffer+89h),a
  		
   		ld	c,(BANK_WAVE>>14)&0FFh
    		ld	a,c
    		ld      (0FFFFh),a
  		ld      de,8000h
      		ld	hl,ram_modebuffer
		ei
	
; -------------------------------------------------
; Loop
; -------------------------------------------------

@Loop:
    		nop 

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
     		
     		ld      b,08h
     		djnz    *
   		
 		inc     de
 		ld	a,d
 		cp	0C0h
  		jp	c,@Loop
  		ld	d,80h
  		inc 	c
		ld	a,c
		ld      (0FFFFh),a
 		jp	@Loop
 		
 	
; -------------------------------------------------
; Hint
; -------------------------------------------------

hblank:
     		ld	hl,ram_modebuffer
  		ld	a,80h
  		out	(Vcom),a
  		ld	a,3Fh|40h
  		out	(Vcom),a

  		rept 20h*2
   		ld	a,(hl)
   		inc 	hl
   		out     (Vdata),a
      		endr
   		
		pop     af
		ei
		retn
	
; -------------------------------------------------
; Vint
; -------------------------------------------------

vblank:
		push	bc
		ld	a,(ram_modebuffer+08Ah)
		cp	1
		jp	z,@keep
		ld	a,(ram_modebuffer+88h)
		ld	c,a
		ld	a,(ram_modebuffer+89h)
		ld	b,a
		dec	bc
		ld	a,c
		ld	(ram_modebuffer+88h),a
		ld	a,b
		ld	(ram_modebuffer+89h),a
		
		ld	a,c
		or	b
		jp	nz,@exit
		
		ld	a,1
		ld	(ram_modebuffer+08Ah),a
		ld	a,11100001b
		out 	(Vcom),a
		ld	a,81h
		out 	(Vcom),a
		
		if MERCURY
		
 		ld	a,20h
 		out	(Vcom),a
 		or	Vcolor
 		out	(Vcom),a
 		ld	a,40h
 		out 	(Vdata),a
 		ld	a,08h
 		out 	(Vdata),a
 		
		else
		
 		ld	a,10h
 		out	(Vcom),a
 		or	Vcolor
 		out	(Vcom),a
 		ld	a,24h
 		out 	(Vdata),a
 		
 		endif
 		
 		ld	a,e
 		ld	(ram_modebuffer+090h),a
 		ld	a,d
 		ld	(ram_modebuffer+091h),a
 		
@keep:

		ld	a,(ram_hscroll)
		dec	a
		ld	(ram_hscroll),a	
		out     (Vcom),a
		ld      a,088h
		out     (Vcom),a
		
		ld	a,(ram_modebuffer+80h)
		dec	a
 		jp	p,@plus
 		
 		ld	a,(ram_modebuffer+81h)
 		inc 	a
 		cp	6
 		jp	c,@last
 		xor	a
@last:
		ld	(ram_modebuffer+81h),a

 		push	bc
 		add	a
 		add	a
 		add	a
 		add	a
 		add	a
 		ld	bc,0
 		ld	c,a
 		ld	ix,ram_modebuffer+1
 		ld	iy,kitty_anim
 		add	iy,bc
  		pop	bc
  		
  		rept (5*3)+9
  		ld	a,(iy)
  		ld	(ix),a
  		inc	ix
  		inc	ix
  		inc	iy
  		endr
  	
  		ld	a,4
@plus:
		ld	(ram_modebuffer+80h),a
	
@exit:
		pop	bc
		pop     af
		ei
		retn
		
kitty_anim:
		db 001h,002h,003h,004h,005h,006h,007h,008h,009h,00Ah,00Bh,00Ch,00Dh,00Eh,00Fh
 		db 05Eh,05Fh,060h,05Bh,05Ch,05Dh,05Eh,05Fh,060h,  -1,  -1,  -1,  -1,  -1,  -1, -1, -1
		db 010h,011h,012h,013h,014h,015h,016h,017h,018h,019h,01Ah,01Bh,01Ch,01Dh,01Eh
		db 05Eh,05Fh,060h,05Bh,05Ch,05Dh,05Eh,05Fh,060h,  -1,  -1,  -1,  -1,  -1,  -1, -1, -1
		db 01Fh,020h,021h,022h,023h,024h,025h,026h,027h,028h,029h,02Ah,02Bh,02Ch,02Dh
 		db 05Eh,05Fh,060h,05Bh,05Ch,05Dh,05Eh,05Fh,060h,  -1,  -1,  -1,  -1,  -1,  -1, -1, -1
		db 02Eh,02Fh,030h,031h,032h,033h,034h,035h,036h,037h,038h,039h,03Ah,03Bh,03Ch
 		db 05Bh,05Ch,05Dh,05Eh,05Fh,060h,05Bh,05Ch,05Dh,  -1,  -1,  -1,  -1,  -1,  -1, -1, -1
		db 03Dh,03Eh,03Fh,040h,041h,042h,043h,044h,045h,046h,047h,048h,049h,04Ah,04Bh
 		db 05Bh,05Ch,05Dh,05Eh,05Fh,060h,05Bh,05Ch,05Dh,  -1,  -1,  -1,  -1,  -1,  -1, -1, -1
		db 04Ch,04Dh,04Eh,04Fh,050h,051h,052h,053h,054h,055h,056h,057h,058h,059h,05Ah
 		db 05Bh,05Ch,05Dh,05Eh,05Fh,060h,05Bh,05Ch,05Dh,  -1,  -1,  -1,  -1,  -1,  -1, -1, -1
		