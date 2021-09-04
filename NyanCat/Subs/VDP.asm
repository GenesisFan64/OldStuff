; ======================================================================
; Rutinas para controlar el VDP (paletas, GFX, etc.)
; ======================================================================

; Colores
VDP_Color_Red			equ	$000E
VDP_Color_Green			equ	$00E0
VDP_Color_Blue			equ	$0E00
VDP_Color_Cyan			equ	$0EE0
VDP_Color_Yellow		equ	$00EE
VDP_Color_Pink			equ	$0E0E

; ======================================================================

SetupVDP:
		move.w	#$8014,($C00004).l	;???, HIntEnable
		move.w	#$8174,($C00004).l	;DisplayEnable, VIntEnable, V28
		move.w	#$8230,($C00004).l	;Zona de escritura del FG ($C000)
		move.w	#$8334,($C00004).l	;Zona de escritura del Window ($D000)
		move.w	#$8407,($C00004).l	;Zona de escritura del BG ($E000)
		move.w	#$857C,($C00004).l	;Zona de escritura de los Sprites ($F800)
		move.w	#$8600,($C00004).l	;???
		move.w	#$8700,($C00004).l	;Color de fondo
		move.w	#$8800,($C00004).l	;???
		move.w	#$8900,($C00004).l	;???
		move.w	#$8A02,($C00004).l	;Valor H-Int
		move.w	#$8B00,($C00004).l	;Tipo de scrolling ($00 = Todo normal)
		move.w	#$8C01,($C00004).l	;Resolucion
		move.w	#$8D3D,($C00004).l	;Zona del scrolling horizontal ($F400)
		move.w	#$8E00,($C00004).l	;???
		move.w	#$8F02,($C00004).l	;Auto incremento (siempre $2)
		move.w	#$9001,($C00004).l	;Tipo de pantalla (predeterminado $1)
		move.w	#$9100,($C00004).l	;Window
		move.w	#$9200,($C00004).l	;Window
		move.w	#$9300,($C00004).l	;DMA
		move.w	#$9400,($C00004).l	;DMA
		move.w	#$9500,($C00004).l	;DMA
		move.w	#$9600,($C00004).l	;DMA
		move.w	#$9700,($C00004).l	;DMA
		rts

; ======================================================================
ClearPlane:
		moveq	#$27,d1		;X-pos
		moveq	#$3F,d2		;Y-pos
		lea	($C00000).l,a1
		move.l	#$800000,d4

ClearPlane_1:
		move.l	d0,4(a1)
		move.w	d1,d3

ClearPlane_2:
		move.w	#0,(a1)
		dbf	d3,ClearPlane_2
		add.l	d4,d0
		dbf	d2,ClearPlane_1
		rts

; ======================================================================

ClearVRAM:
		move.w	#$2700,sr
		
		lea	($C00000).l,a1
		move.l	#$40000000,($C00004).l
		moveq	#0,d1
		move.w	#$7F, d0

ClearVRAM_Loop:
		move.l	d1,(a1)
		move.l	d1,(a1)
		move.l	d1,(a1)
		move.l	d1,(a1)
		move.l	d1,(a1)
		move.l	d1,(a1)
		move.l	d1,(a1)
		move.l	d1,(a1)
		dbf	d0, ClearVRAM_Loop

		move.w	#$2300,sr
		rts

; ======================================================================

VDP_LoadArt:
		move.w	#$2700,sr

		lea	($C00000), a1
LoadArt_Loop:
		move.l	(a2)+,(a1)
		move.l	(a2)+,(a1)
		move.l	(a2)+,(a1)
		move.l	(a2)+,(a1)
		move.l	(a2)+,(a1)
		move.l	(a2)+,(a1)
		move.l	(a2)+,(a1)
		move.l	(a2)+,(a1)
		dbf	d0,LoadArt_Loop

		move.w	#$2300,sr
		rts

; ======================================================================

;LoadFont:
;		move.w	#$5A,d3
;		move.l	#$74000002,($C00004).l
;		lea	(DbgFont),a2
;		jmp	VDP_LoadArt

; ======================================================================

LoadPal_RAM:
		move.w	(a1)+,(a0)+
		dbf	d0,LoadPal_RAM
		rts

LoadPal:
		lea	($C00000),a0
		
LoadPal_Loop:
		move.w	(a1)+,(a0)
		dbf	d0,LoadPal_Loop
		rts

; ======================================================================

VDP_LoadMaps:
		move.w	#$2700,sr

		lea	($C00000).l,a6
		move.l	#$800000,d4

ShowVDPGraphics_LineLoop:
		move.l	d0,4(a6)
		move.w	d1,d3

ShowVDPGraphics_TileLoop:
		move.w	(a1)+,d6
                add.w	d5,d6
                move.w	d6,(a6)
		dbf	d3,ShowVDPGraphics_TileLoop
		add.l	d4,d0
		dbf	d2,ShowVDPGraphics_LineLoop

		move.w	#$2300,sr
		rts

; ======================================================================
; VDP_LoadStr
; Muestra texto (o GFX) en pantalla
;
; d5 - Control VDP, por
; ======================================================================

VDP_LoadStr:
		move.l	d5,($C00004).l
LoadText_Loop:
		moveq	#0,d1
		move.b	(a1)+,d1
		bmi.w	LoadASCII_AddSpace	; if a1 = $FF, branch
		bne.w	LoadASCII_Print
		rts
LoadASCII_Print:
		tst.w	d3
		beq	LoadASCII_Print_2
		add.w	d3,d1
LoadASCII_Print_2:
		move.w	d1,($C00000)		;"print" la letra
		bra.w	LoadText_Loop
LoadASCII_AddSpace:
		add.l	#$800000,d5		;Espacio
		bra.w	VDP_LoadStr

; ======================================================================

VDP_ShowByte:
		move.b	d0,d2
		lsr.b	#4,d0
		bsr	sub_3808_4
		move.b	d2,d0
sub_3808_4:
		andi.w	#$F,d0
		cmpi.b	#$A,d0
		bcs	loc_3816_4
		addi.b	#7,d0
loc_3816_4:
		add.w	d3,d0
		move.w	d0,($C00000)
		rts
		
; ======================================================================
		
DelayProgram:
		move.w	($C00004),d0
		btst	#3,d0
		bne	DelayProgram
WaitOneFrame1:
		move.w	($C00004),d0
		btst	#3,d0
		beq	WaitOneFrame1
		rts
