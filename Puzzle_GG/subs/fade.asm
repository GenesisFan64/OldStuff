; ====================================================================
; ---------------------------------------
; Equs
; ---------------------------------------

ID_FadeOut		equ	01h
ID_FadeIn		equ	02h
ID_ToWhite		equ	03h
ID_FadeWhite		equ	04h

; ---------------------------------------

PalFadeFlags		equ	1
PalFadeStart		equ	2
PalFadeEnd		equ	3
PalFadeTmr		equ	4
PalFadeSource		equ	8

; -------------------------------------------------
; FadeIn/FadeOut
; -------------------------------------------------

PalFade:
		ld	ix,ram_runfadecol
		ld	a,(ix)
		bit	7,a
		jp	z,@run_tasks
  		ld	a,(ix+(PalFadeTmr+1))
  		dec	a
  		ld	(ix+(PalFadeTmr+1)),a
 		jp	p,@Return
		ld	a,(ix+PalFadeTmr)
		ld	(ix+(PalFadeTmr+1)),a
		xor	a
		ld	(ix),a
@Return:
		ret
		
@run_tasks:
 		sla	a
 		ld	bc,0
 		ld	c,a
		ld	hl,@task_list
 		add 	hl,bc
		jp	(hl)

; -------------------------------------------------

@task_list:
		jr	@Return
		jr	Pal_FadeOut
		jr	Pal_FadeIn
		jr	@Return
		jr	@Return
	
; -------------------------------------------------
; FADEIN
; -------------------------------------------------

Pal_FadeIn:	
		ld	a,(ix+(PalFadeTmr+1))
		dec	a
		ld	(ix+(PalFadeTmr+1)),a
		jp	p,@wait
		ld	a,(ix+(PalFadeTmr))
		ld	(ix+(PalFadeTmr+1)),a
		
 		ld	iy,ram_palfadebuff
		ld	hl,ram_palbuffer
		
		ld	de,0
		ld	bc,0
		ld	b,(ix+(PalFadeEnd))
		ld	e,b
		inc 	b

; --------------------
; MERCURY
; --------------------

 		if MERCURY
  		sla	e
@next_entry:
		ld	a,(iy)
		and	00001111b
		ld	c,a
		ld	a,(hl)		;RED
		and	00001111b
		cp	c
		ld	a,(hl)
		jp	nc,@cont_red
		inc	a
		set 	0,d
@cont_red:
  		ld	(hl),a
  		
		ld	a,(iy)
		and	11110000b
		ld	c,a
		ld	a,(hl)		;GREEN
		and	11110000b
		cp	c
		ld	a,(hl)
		jp	nc,@cont_gre
		add 	a,10h
		set 	1,d
@cont_gre:
  		ld	(hl),a
  		
  		ld	a,d
  		cp	00000011b
  		jp	nc,@redgreend
 		dec	e
@redgreend:
		inc	hl
		inc	iy
		
		ld	a,(hl)		;BLUE
		ld	c,(iy)
		cp	c
		inc	a
		jp	c,@cont_blue
		dec 	e
		ld	a,(iy)
@cont_blue:
		ld	(hl),a
		inc	hl
		inc	iy
		djnz	@next_entry
		
; --------------------
; MASTER SYSTEM
; 
; (GG Colors to MS)
; --------------------

 		else
@next_entry:
		ld	a,(iy)
		and	00000011b
		ld	c,a
		ld	a,(hl)		;RED
		and	00000011b
		cp	c
		ld	a,(hl)
		jp	nc,@cont_red
		inc	a
		set 	0,d
@cont_red:
  		ld	(hl),a
  		
		ld	a,(iy)
		and	00001100b
		ld	c,a
		ld	a,(hl)		;GREEN
		and	00001100b
		cp	c
		ld	a,(hl)
		jp	nc,@cont_green
		add 	a,4
		set 	1,d
@cont_green:
  		ld	(hl),a
  		
		ld	a,(iy)
		and	00110000b
		ld	c,a
		ld	a,(hl)		;BLUE
		and	00110000b
		cp	c
		ld	a,(hl)
		jp	nc,@cont_blue
		add 	a,10h
		set 	2,d
@cont_blue:
  		ld	(hl),a
  		
  		ld	a,d
  		cp	00000111b
  		jp	nc,@redgreend
 		dec	e
@redgreend:
		inc	hl
		inc	iy
 		djnz	@next_entry
 		
; --------------------

 		endif
 		
		ld	a,e
		jp	p,@wait
		
		ld 	a,(ix)
		set 	7,a
		ld	(ix),a
@wait:
		ret

; -------------------------------------------------
; FADEOUT
; -------------------------------------------------

Pal_FadeOut:	
 		ld	a,(ix+(PalFadeTmr+1))
 		dec	a
 		ld	(ix+(PalFadeTmr+1)),a
 		jp	p,@wait
 		ld	a,(ix+(PalFadeTmr))
 		ld	(ix+(PalFadeTmr+1)),a
 		
  		ld	iy,ram_palfadebuff
 		ld	hl,ram_palbuffer
 		
 		ld	de,0
 		ld	bc,0
 		ld	b,(ix+(PalFadeEnd))
 		ld	e,b
 		inc 	b
 		
; --------------------
; MERCURY
; --------------------

 		if MERCURY
    		sla	e		
@next_entry:
    		ld	a,(hl)
    		ld	d,a
    		and 	00001111b
   		cp	0
   		jp	z,@red_done
    		dec	a
    		and 	00001111b
    		ld	d,a
@red_done:
		ld	a,(hl)
		and	11110000b
		or	d
 		ld	(hl),a
 		
 		ld	a,(hl)
 		ld	d,a
 		and	11110000b
 		cp	0
 		jp	z,@green_done
 		sub	a,10h
 		ld	d,a
  		ld	a,(hl)
  		ld	c,a
  		and	00001111b
  		ld	c,a
  		ld	a,d
  		or	c
@green_done:
		ld	a,(hl)
		and	00001111b
		or	d
 		ld	(hl),a
 		
 		ld	a,(hl)
 		cp	0
 		jp	nz,@not_zero
   		dec	e
@not_zero:
 		inc	hl
 		inc	iy
 		
   		ld	a,(hl)
   		and	00001111b
  		cp	0
  		jp	z,@blue_done
   		dec	a
@blue_done:
		jp	nz,@setb_done
 		dec	e
@setb_done:
 		ld	(hl),a
		
 		inc	hl
 		inc	iy
 		djnz	@next_entry
 		
; --------------------
; MASTER SYSTEM
; --------------------

 		else
@next_entry:
    		ld	a,(hl)
    		ld	d,a
    		and 	00000011b
   		cp	0
   		jp	z,@red_done
    		dec	a
    		and 	00000011b
    		ld	d,a
@red_done:
		ld	a,(hl)
		and	00111100b
		or	d
 		ld	(hl),a
 		
     		ld	a,(hl)
     		ld	d,a
     		and	00001100b
     		cp	0
     		jp	z,@green_done
      		sub	a,4
     		ld	d,a
      		ld	a,(hl)
      		and	00110011b
      		ld	c,a
      		ld	a,d
      		or	c
@green_done:
		ld	a,(hl)
		and	00110011b
		or	d
 		ld	(hl),a
 	
     		ld	a,(hl)
     		ld	d,a
     		and	00110000b
     		cp	0
     		jp	z,@blue_done
      		sub	a,10h
     		ld	d,a
      		ld	a,(hl)
      		and	00001111b
      		ld	c,a
      		ld	a,d
      		or	c
@blue_done:
		ld	a,(hl)
      		and	00001111b
		or	d
 		ld	(hl),a
 		
 		ld	a,(hl)
 		cp	0
 		jp	nz,@not_zero
   		dec	e
@not_zero:
		inc	hl
 		djnz	@next_entry
 		
; --------------------

 		endif
 		
 		ld	a,e
 		jp	p,@wait
		
		ld 	a,(ix)
		set 	7,a
  		ld	(ix),a
@wait:
		ret
		
; -------------------------------------------------
; PalFade_Set
;
; b -  Command
; de - NumOfColors|Speed
; -------------------------------------------------

PalFade_Set:
		ld	ix,ram_runfadecol
		ld	c,b
		
		ld	b,c
		ld	a,d
		ld	(ix+(PalFadeEnd)),a
		ld	a,e
		if MERCURY=0
		inc	a	;slow down on MS
		inc	a
		endif
		ld	(ix+(PalFadeTmr)),a
		ld	a,b
		ld	(ix),b
		
		ld	c,b
		ret
		
; -------------------------------------------------
; PalFade_Load
; 
; normal:
; b - Num of colors
; c - Start from
; 
; uses:
; bc,d,hl
; 
; uses stack
; -------------------------------------------------

PalFade_Load:
 		if MERCURY
		sla	b
		sla	c
 		endif
		ld	a,c
		ld	ix,ram_palfadebuff
; 		out     (Vcom),a        ; color ram address
; 		ld      a,Vcolor        ; sets required C0h for a color write
; 		out     (Vcom),a

@color_loop:
		if MERCURY		; GAME GEAR colors
		ld	a,(hl)
		else
		
		ld	e,0		; GG to SMS colors
		ld	a,(hl)		; read GGs GREEN+RED
		sra	a
		sra	a
		and 	00000011b
		ld	e,a
		ld	a,(hl)
		sra	a
		sra	a
		sra	a
		sra	a
		and	00001100b
		or	e
		ld	e,a
		inc 	hl
 		ld	a,(hl)		; read GGs BLUE
 		sla	a
 		sla	a
 		and	00110000b
 		ld	d,a
 		ld	a,e
 		or	d
 		and	00111111b
		endif
		
		ld	(ix),a
		inc	ix
		inc 	hl
		
		djnz	@color_loop
		ret
		
; -------------------------------------------------

PalFade_Wait:
   		call	VSync
   		
     		ld	a,(ram_runfadecol)
     		cp	0
     		jp	nz,PalFade_Wait
		ret
		