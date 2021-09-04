; ====================================================================
; -------------------------------------------------
; VDP
; -------------------------------------------------

bit_HscrlBar	equ	5

; Resolutions:
; MS: 256x192
; GG: 160x144 (center)

; GG SPRITES AT TOP SCREEN:
; Y 17h X 30h

Vcom            equ     0BFh    ; ADDRESS SETUP FOR VDP REGISTERS
Vdata           equ     0BEh    ; WRITE OR READ DATA ADDRESS FOR VDP REGISTERS
Writemask       equ     040h    ; SETS VRAM TO WRITE MODE
Vcolor          equ     0C0h    ; VALUE OF 2nd BYTE FOR COLOR VRAM WRITE
Vreg            equ     080h    ; STARTING LOCATION OF VDP REGISTERS (0 - 10)
sprites         equ     2000h   ; START ADDRESS OF SPRITE GENERATOR TABLE
spritevert      equ     3F00h   ; START ADDRESS OF SPRITE ATTRIBUTE TABLE,
				; VERTICAL POSITION
spritehori      equ     3F80h   ; START ADDRESS OF SPRITE ATTRIBUTE TABLE,
				; HORIZONTAL POSITION
patterns        equ     0000h   ; START ADDRESS OF PATTERN GENERATOR TABLE

; START ADDRESS OF PATTERN NAME TABLE, | topleft    hl = 38CCh
; OR SCROLL SCREEN

screen		equ     3800h
screen_gg	equ	38CCh	

celllength      equ     32
numcolors       equ     64
screenlength    equ     1440

; -------------------------------------------------

VDPWrite:
;****************************************************
; Inserts a quantity of a number in VRAM
;        e: holds the number to be written
;       bc: holds the quantity to be written
;       hl: holds the VRAM destination to start at
;****************************************************

	; set up an initial address in VRAM to write to

	ld      a,l            ;1st 8 bits
	out     (Vcom),a
	ld      a,h            ; 2nd 8 bits
	or      Writemask      ; set write mode
	out     (Vcom),a

	; insert the number into VRAM a quantity of times

VDPWriteLoop:
	ld      a,e            ; load data to 3rd byte
	out     (Vdata),a      ; write to VRAM
	dec     bc             ; dec # of times to write by 1
	or      c              ; or c with a
	jr      nz,VDPWriteLoop; continue loop if or != 0

	ret


VDP_Init:
;****************************************************
; initialize the VDP registers and VRAM
;****************************************************

	ld      hl,VDPregSet    ; address of register initialize table
	ld	de,ram_vdpregs
	ld      b,11            ; number of registers to initialize
	ld      c,80h           ; register = 0

	; read register settings from hl, outputting them to the VDP registers

VDPinitLoop:
	ld	a,(hl)
	ld	(de),a
	inc 	hl
	inc 	de
	djnz    VDPinitLoop     ; dec b, jump if b != 0

	call	VDP_update

	; set up VDP to clear VRAM
	xor     a
	out     (Vcom),a        ; a is all zeros
	ld      a,Writemask     ; 0100 0000
	out     (Vcom),a        ; setting write mode
	ld      bc,4000h        ; how many times to write to VRAM
BlankLoop:
	xor     a               ; a = 0
	out     (Vdata),a       ; data is zero
	dec     bc              ; dec bc by 1
	ld      a,b
	or      c               ; or a with c
	jr      nz,BlankLoop    ; continue blanking until bc = 0

	ret
	
WriteVRAM:
;****************************************************
; Write to VRAM
;       hl: address of source bytes to load in VRAM
;       de: destination address in VRAM
;       bc: number of bytes to write
;****************************************************

	push    hl
	push    de              ; save values
	push    bc

	; let a.b = number of bytes to write
	ld      a,b
	ld      b,c

	push    af              ; save copy of high byte value for # of bytes
				;  to write
				;  to write to VRAM
	ld      a,e             ; dest address in vram to write to
	out     (Vcom),a
	ld      a,d             ; 2nd byte of dest address
	or      Writemask       ; writemode
	out     (Vcom),a

	ld      c,Vdata         ; data write address in vram, needed for OUTI

	ld      a,b             ; low byte of # of times to write to vram
	and     a
	jr      nz,WriteLoop    ; jump if a not zero

	pop     af              ; high byte of # of times to write to vram
	dec     a               ; dec high byte

OuterLoop:
	push    af              ; save value of high byte

	; write values to VRAM until b, reaches zero
Writeloop:
	outi                    ; write (hl) to (c), dec b, inc hl

	jr      nz,WriteLoop    ; jump if b != 0

	pop     af              ; high byte of # of times to write to vram

	; go to writeloop until a reaches zero
	dec     a
	jp      p,OuterLoop     ; jump until a = 0

	pop     bc
	pop     de              ; restore values
	pop     hl
	ret


WriteSprite:
;****************************************************
; change the attribute table values for a sprite
;       b: the sprite number (0-63)
;       c: the character number in sprite table
;       d: the sprite's x location on screen
;       e: the sprite's y location on screen
;****************************************************

	ld      hl,spritevert      ; start of sprite attrib. table, vert pos.
	ld      a,l                ; low part of sprite vert. address
	add     a,b                ; index into table
	out     (Vcom),a           ; 1st byte of Write address
	ld      a,h                ; high part of sprite vert. address
	or      Writemask          ; set write mode
	out     (Vcom),a           ; 2nd byte of Write address

	ld      a,e                ; new sprite y, vertical, position
	out     (Vdata),a          ; write new vertical position
	push    af
	pop     af                 ; delay for vram write

	ld      hl,spritehori      ; start of sprite attrib. table, horiz pos
	ld      a,l                ; low part of sprite horiz address
	add     a,b                ; skip over horizontal data
	add     a,b                ; skip over character data
	out     (Vcom),a           ; 1st byte of Write address
	ld      a,h                ; high part of sprite horiz address
	or      Writemask          ; writemode
	out     (Vcom),a           ; 2nd byte of Write address

	ld      a,d                ; new sprite x, horiz, position
	out     (Vdata),a          ; write new horizontal position
	push    af
	pop     af                 ; delay for Vram write
	ld      a,c                ; character number
	out     (Vdata),a          ; write new char. number
	push    af
	pop     af                 ; delay for Vram write

	ret


screenoff:
;****************************************************
; De-activates the screen from being drawn
;****************************************************

	;set BLANK bit of VDP register 1 to zero

	ld      a,0A0h          ; 1010 0000
	out     (Vcom),a
	ld      a,Vreg+1        ; register 1
	out     (Vcom),a        ; set blank bit to zero

	ret


screenon:
;****************************************************
;Re-activates the screen
;****************************************************

	ld      a,0E0h          ; 1110 0000
	out     (Vcom),a
	ld      a,Vreg+1        ; register 1
	out     (Vcom),a        ; set blank bit to 1, screen on

	ret
	
; -------------------------------------------------
; VDP_LoadMaps
; 
; normal:
; bc - X size, Y size
; ix - mappings
; hl - vdp address
; 
; uses stack
; -------------------------------------------------

VDP_LoadMaps:
		ld	h,d
		ld	l,e
		push	bc
@X_draw:
		ld	a,l		; VDP: address
		out	(Vcom),a
		ld	a,h
		or	Writemask
		out	(Vcom),a
		
		ld	a,(ix)
		out	(Vdata),a	; VDP: read
		inc 	ix
		ld	a,(ix)
; 		and 	111b
		out	(Vdata),a
		inc 	ix
		
		inc	hl
		inc	hl
		djnz	@X_draw

		ld	h,d		;Next line
		ld	l,e
		ld	bc,40h		
		add 	hl,bc
		ld	d,h
		ld	e,l
		
		pop	bc
		dec	c
		ld	a,c
 		jp	nz,VDP_LoadMaps
		ret
		
; -------------------------------------------------
; VDP_ClearLayer
;
; uses:
; bc,hl
; -------------------------------------------------

VDP_ClearLayer:
		ld	hl,screen
	
		ld	c,1Ch
@y_loop:
		ld	b,20h
@x_loop:		
 		ld	a,l
 		out	(Vcom),a
 		ld	a,h
 		or	Writemask
 		out	(Vcom),a
 		
 		xor	a
 		out	(Vdata),a
 		out	(Vdata),a
 		
 		inc	hl
 		inc	hl
		djnz	@x_loop
		
		dec	c
		jp	nz,@y_loop
		ret
		
; -------------------------------------------------
; VDP_LoadPal
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

VDP_LoadPal:
 		if MERCURY
		sla	b
		sla	c
 		endif
		ld	a,c
		ld	ix,ram_palbuffer
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
		
 		push    af
 		pop     af		; delay for writing to ram
		djnz	@color_loop
		ret
	
; ; -------------------------------------------------
; ; VDP_GrabPal
; ; 
; ; Copy the palette from RAM to VDP
; ; -------------------------------------------------
; 
; VDP_GrabPal:

; -------------------------------------------------
; VDP_Update
; -------------------------------------------------

VDP_update:
		ld	hl,ram_vdpregs
		ld	b,7		; 80h-87h
		ld	c,80h
@nextreg:
		ld      a,(hl)          ; initial  register configs
		out     (Vcom),a        ; data out to 1st byte
		inc     hl              ; next reg in table
		ld      a,c             ; register number
		out     (Vcom),a        ; write data to register
		inc     c               ; next register
		djnz	@nextreg
		
		ld      a,(ram_vdpregs+00Ah) ;08Ah
		out     (Vcom),a
		ld      a,08Ah
		out     (Vcom),a
		ret
		
; -------------------------------------------------
; Data
; -------------------------------------------------

VDPregSet:
		db      00000110b       ;reg 0 (???H???? HBLANK)
		db      11100010b       ;1 SPRITES 8x16
		db      11111111b       ;2
		db      11111111b       ;3
		db      11111111b       ;4
		db      11111111b       ;5
		db      00000100b       ;bit 2: Sprite characters $0x00 ($00xx,$01xx)
		db      00000000b       ;7
		db      00000000b       ;8 X
		db      00000000b       ;9 Y
		db      00000000b       ;10 HInt counter
		
; --------------------------------------------
; VSync
; --------------------------------------------

vsync:
 		ld	a,(ram_vintwait)
 		set	bitFrameWait,a
 		ld	(ram_vintwait),a
@loop:
  		ld	a,(ram_vintwait)
 		bit	bitFrameWait,a
 		jp	nz,@loop
		ret
		
		