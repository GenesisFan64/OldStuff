; =================================================================
; ------------------------------------------------
; SH2
; 
; Master jobs: Graphics / 3D
; Slave jobs: PWM Sound
; ------------------------------------------------

		include	"system/hardware/mars/sh2/include/map_sh2.asm"
		include	"system/hardware/mars/sh2/include/map_shared.asm"
		include	"system/hardware/mars/sh2/ram.asm"
		org CS3

; =================================================================
; ------------------------------------------------
; Master CPU
; ------------------------------------------------

		obj MasterEntry
SH2_Master:
		dc.l @Entry,M_STACK		; Cold PC,SP
		dc.l @Entry,M_STACK		; Manual PC,SP

		dc.l ErrorTrap			; Illegal instruction
		dc.l 0				; reserved
		dc.l ErrorTrap			; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l ErrorTrap			; CPU address error
		dc.l ErrorTrap			; DMA address error
		dc.l ErrorTrap			; NMI vector
		dc.l ErrorTrap			; User break vector

		dcb.l 19,0			; reserved

		dcb.l 32,ErrorTrap		; Trap vectors

 		dc.l master_irq			; Level 1 IRQ
		dc.l master_irq			; Level 2 & 3 IRQ's
		dc.l master_irq			; Level 4 & 5 IRQ's
		dc.l master_irq			; PWM interupt
		dc.l master_irq			; Command interupt
		dc.l master_irq			; H Blank interupt
		dc.l master_irq			; V Blank interupt
		dc.l master_irq			; Reset Button

; =================================================================
; ------------------------------------------------
; Master entry
; ------------------------------------------------

@Entry:
		mov.l	#_sysreg,r14
		ldc	r14,gbr

		mov 	#0,r0
		mov.w	r0,@(vintclr,gbr)
		mov.w	r0,@(vintclr,gbr)
		mov.w	r0,@(hintclr,gbr)	;clear IRQ ACK regs
		mov.w	r0,@(hintclr,gbr)
		mov.w	r0,@(cmdintclr,gbr)
		mov.w	r0,@(cmdintclr,gbr)
		mov.w	r0,@(pwmintclr,gbr)
		mov.w	r0,@(pwmintclr,gbr)
		mov.l	#_FRT,r1		; Set Free Run Timer
		mov	#$00,r0
		mov.b	r0,@(_TIER,r1)		;
		mov	#$E2,r0
		mov.b	r0,@(_TOCR,r1)		;
		mov	#$00,r0
		mov.b	r0,@(_OCR_H,r1)		;
		mov	#$01,r0
		mov.b	r0,@(_OCR_L,r1)		;
		mov	#0,r0
		mov.b	r0,@(_TCR,r1)		;
		mov	#1,r0
		mov.b	r0,@(_TCSR,r1)		;
		mov	#$00,r0
		mov.b	r0,@(_FRC_L,r1)		;
		mov.b	r0,@(_FRC_H,r1)		;

		mov	#$F2,r0			; reset setup
		mov.b	r0,@(_TOCR,r1)		;
		mov	#$00,r0
		mov.b	r0,@(_OCR_H,r1)		;
		mov	#$01,r0
		mov.b	r0,@(_OCR_L,r1)		;
		mov	#$E2,r0
		mov.b	r0,@(_TOCR,r1)		;
	
; ----------------------------------

@wait_md:
		mov.l	@(comm0,gbr),r0
		cmp/eq	#0,r0
		bf	@wait_md

; ----------------------------------	

		mov.l	#"SLAV",r1
@wait_slave:
		mov.l	@(comm8,gbr),r0		; wait for the slave to finish booting
		cmp/eq	r1,r0
		bf	@wait_slave
		mov	#0,r0
		mov.l	r0,@(comm8,gbr)
		
; =================================================================
; ------------------------------------------------
; Hotstart
; ------------------------------------------------

m_hotstart:
		mov.l	#M_STACK,r15
		mov.l	#_sysreg,r14
		ldc	r14,gbr
 		mov	#CMDIRQ_ON|VIRQ_ON,r0
    		mov.b	r0,@(intmask,gbr)
		
; ==================================================================
; ---------------------------------------------------
; Master start
; ---------------------------------------------------

master_start:
 		mov	#Audio_Init,r0
 		jsr	@r0
 		nop
		mov	#Video_Init,r0
		jsr	@r0
		nop
		
; 		mov 	#CS1|$4C330,r1
; 		mov 	#CS1|$4C330+$1C8000,r2
; 		mov 	r1,r3
; 		mov 	#%10,r4
; 		mov 	#0,r5
; 		mov 	#Audio_Play,r0
; 		jsr 	@r0
; 		nop
; 		mov 	#CS1|$214334,r1
; 		mov 	#CS1|$214334+$1C8000,r2
; 		mov 	r1,r3
; 		mov 	#%01,r4
; 		mov 	#1,r5
; 		mov 	#Audio_Play,r0
; 		jsr 	@r0
; 		nop
		
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)

; 		mov 	#0,r0			; FB to MD
;   		mov.b	r0,@(adapter,gbr)

		mov	#CS1|$40000+4,r1
		mov	#0,r2
		mov	#Video_LoadTga,r0
		jsr	@r0
		nop
; 		mov	#CS1|$419B0+4,r1
; 		mov	#128*2,r2
; 		mov	#Video_LoadTga,r0
; 		jsr	@r0
; 		nop
; 		mov	#CS1|$532A0+4,r1
; 		mov	#192*2,r2
; 		mov	#Video_LoadTga,r0
; 		jsr	@r0
; 		nop
; 		
; 		mov	#$220265EC,r2
; 		bsr	Model_Set
; 		mov 	#2,r1
; 		mov	#0,r2
; 		mov 	#0,r3
; 		mov 	#-$180,r4
; 		bsr	Model_Pos
; 		mov 	#2,r1
; 	
; 		mov	#$220265EC,r2
; 		bsr	Model_Set
; 		mov 	#3,r1
; 		mov	#+192,r2
; 		mov 	#0,r3
; 		mov 	#-$180,r4
; 		bsr	Model_Pos
; 		mov 	#3,r1
; 		
; 		mov	#$220265EC,r2
; 		bsr	Model_Set
; 		mov 	#1,r1
; 		mov	#-192,r2
; 		mov 	#0,r3
; 		mov 	#-$180,r4
; 		bsr	Model_Pos
; 		mov 	#1,r1
		
		mov	#$20,r0
		ldc	r0,sr
		
; =================================================================
; ---------------------------------------------------
; Master loop
; ---------------------------------------------------


; 		bsr	Video_ClearFrame
; 		nop

		rept 2
		mov	#_DMASOURCE0,r1 	; _DMASOURCE = $ffffff80
		mov	#((CS1|$40000+4)+$312),r0
		mov	r0,@r1			; set source address
		mov	#_framebuffer+$200,r0
		mov	r0,@(4,r1)		; set destination address
 		mov	#((VIDEO_XSIZE)*256),r0
		mov	r0,@(8,r1)		; set length
		mov.l	#_DMAOPERATION,r3 	; _DMAOPERATION = $ffffffb0
		xor	r2,r2			; Zero.
		mov.l	r2,@r3
		xor	r2,r2
		mov.l	r2,@($c,r1)		; clear TE bit
 		mov	#$5000|$200|$F0|1,r0	; $5000
		mov.l	r0,@($c,r1)		; load mode
		add	#1,r2
		mov.l	r2,@r3
 		mov 	#Vsync,r0
 		jsr	@r0
 		nop
 		bsr	Video_Render
 		nop
 		endr
 		
master_loop:

; -----------------------
; Draw all polygons
; -----------------------
			
		mov	#Polygons_Read,r0
		jsr	@r0
		nop
		
; --------------------------------------
		
 		mov 	#Vsync,r0
 		jsr	@r0
 		nop
 		bsr	Video_Render
 		nop
		
		bra	master_loop
		nop
		align 4
		lits
		
; =================================================================
; ------------------------------------------------
; Master MD Requests
; ------------------------------------------------

master_tasks:
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		
; ----------------------------
; $10+
; Model system
; ----------------------------

		dc.l @Model_Set		; Set new model to slot
		dc.l 0			; Delete model from slot
		dc.l 0
		dc.l 0
		dc.l @Model_Move	; Model X/Y/Z position
		dc.l @Model_Rot		; Model X/Y/Z rotation
		dc.l 0			; World X/Y/Z position
		dc.l 0			; World X/Y/Z rotation
		dc.l 0
		dc.l 0
	
; --------------------------------------
; Task $10
; --------------------------------------

@Model_Set:
  		mov.l	@(comm4,gbr),r0
  		mov 	r0,r2
  		mov.w	@(comm8,gbr),r0
  		and	#$FF,r0
  		mov 	r0,r1
  		
		mov	pr,@-r15
		bsr	Model_Set
		nop
		mov	@r15+,pr
		rts
		nop
		
; --------------------------------------
; Task $14
; --------------------------------------

@Model_Move:
  		mov.w	@(comm4,gbr),r0
  		mov 	#$FFFF,r1
  		and 	r1,r0
  		mov 	r0,r1
  		mov.w	@(comm6,gbr),r0
  		exts	r0,r0
  		mov 	r0,r2
   		mov.w	@(comm8,gbr),r0
  		exts	r0,r0
  		mov 	r0,r3
   		mov.w	@(comm10,gbr),r0
  		exts	r0,r0
  		mov 	r0,r4
  		
		mov	pr,@-r15
		bsr	Model_Pos
		nop
		mov	@r15+,pr
		rts
		nop
		
; --------------------------------------
; Task $15
; --------------------------------------

@Model_Rot:
  		mov.w	@(comm4,gbr),r0
  		mov 	#$FFFF,r1
  		and 	r1,r0
  		mov 	r0,r1
  		mov.w	@(comm6,gbr),r0
  		exts	r0,r0
  		mov 	r0,r2
   		mov.w	@(comm8,gbr),r0
  		exts	r0,r0
  		mov 	r0,r3
   		mov.w	@(comm10,gbr),r0
  		exts	r0,r0
  		mov 	r0,r4
  		
		mov	pr,@-r15
		bsr	Model_Rot
		nop
		mov	@r15+,pr
		rts
		nop
		
; =================================================================
; ------------------------------------------------
; Error
; ------------------------------------------------

ErrorTrap:
		bra	ErrorTrap
		nop
 		align 4
		lits

; =================================================================
; ------------------------------------------------
; Subs 
; ------------------------------------------------

		include "system/hardware/mars/sh2/subs/video.asm"
		include "system/hardware/mars/sh2/subs/audio.asm"
		include "system/hardware/mars/sh2/subs/polygons.asm"
		
; =================================================================
; ------------------------------------------------
; irq
; 
; r0-r9 only
; ------------------------------------------------

master_irq:
		mov.l	r0,@-r15
		mov.l	r1,@-r15
		mov.l	r2,@-r15
		mov.l	r3,@-r15
		mov.l	r4,@-r15
		mov.l	r5,@-r15
		mov.l	r6,@-r15
		mov.l	r7,@-r15
		mov.l	r8,@-r15
		mov.l	r9,@-r15
		mov.l	macl,@-r15
		mov.l	mach,@-r15
		
		sts.l	pr,@-r15
	
		stc	sr,r0
		shlr2	r0
		and	#$3C,r0
		mov.l	#@list,r1
		add	r1,r0
		mov.l	@r0,r1
		jsr	@r1
		nop
		
		lds.l	@r15+,pr
		mov.l	@r15+,mach
		mov.l	@r15+,macl
		mov.l	@r15+,r9
		mov.l	@r15+,r8
		mov.l	@r15+,r7
		mov.l	@r15+,r6
		mov.l	@r15+,r5
		mov.l	@r15+,r4
		mov.l	@r15+,r3
		mov.l	@r15+,r2
		mov.l	@r15+,r1
		mov.l	@r15+,r0
		rte
		nop
		lits

; ------------------------------------------------
; irq list
; ------------------------------------------------

		align	4
@list:
		dc.l @invalid_irq,@invalid_irq
		dc.l @invalid_irq,@invalid_irq
		dc.l @invalid_irq,@invalid_irq
		dc.l @pwm_irq,@pwm_irq
		dc.l @cmd_irq,@cmd_irq
		dc.l @h_irq,@h_irq
		dc.l @v_irq,@v_irq
		dc.l @vres_irq,@vres_irq

; =================================================================
; ------------------------------------------------
; Unused
; ------------------------------------------------

@invalid_irq:
		rts
		nop
		cnop 0,4
		lits
	
; =================================================================
; ------------------------------------------------
; Master | PWM Interrupt
; ------------------------------------------------

@pwm_irq:
		
; ----------------------------------

		mov	#1,r0
		mov.w	r0,@(pwmintclr,gbr)
		nop
		nop
		nop
		
		rts
		nop
		cnop 0,4
		lits

; =================================================================
; ------------------------------------------------
; Master | CMD Interrupt
; ------------------------------------------------

@cmd_irq:

; ----------------------------------

		mov.w	@(comm0,gbr),r0
		and	#$FF,r0
		cmp/eq	#0,r0
		bt	@no_task
		
		shll2	r0
		mov.l	#master_tasks,r1
		add	r1,r0
		mov.l	@r0,r1
		mov	pr,@-r15
		jsr	@r1
		nop
		mov	@r15+,pr
		
		mov.w	@(comm0,gbr),r0
		mov 	#$FF00,r1
		and	r1,r0
		mov.w	r0,@(comm0,gbr)
@no_task:
		
; ----------------------------------

		mov	#1,r0
		mov.w	r0,@(cmdintclr,gbr)
		nop
		nop
		nop
		
		rts
		nop
		cnop 0,4
		lits
	
; =================================================================
; ------------------------------------------------
; Master | VRES Interrupt
; ------------------------------------------------

@vres_irq:

; ----------------------------------

		mov	#1,r0
		mov.w	r0,@(vresintclr,gbr)
		nop
		nop
		nop
		
		rts
		nop
		cnop 0,4
		lits

; =================================================================
; ------------------------------------------------
; Master | HBlank
; ------------------------------------------------

@h_irq:

; ----------------------------------

		mov	#1,r0
		mov.w	r0,@(hintclr,gbr)
		nop
		nop
		nop
		
		rts
		nop
		cnop 0,4
		lits

; =================================================================
; ------------------------------------------------
; Master | VBlank
; ------------------------------------------------

@v_irq:

; ----------------------------------

		mov 	#0,r0
		mov 	#frame_wait,r1
		mov	r0,@r1
		mov	#frame_count_m,r1
		mov	@r1,r0
		add 	#1,r0
		mov	r0,@r1
		
		mov	#1,r0
		mov.w	r0,@(vintclr,gbr)
		nop
		nop
		nop
		
		rts
		nop
		cnop 0,4
		lits

; =================================================================
		
		objend
		inform 0,"MARS SH2 MASTER SIZE: %h",*-SH2_Master;,(SlaveEntry-CS3)
		cnop 0,(SlaveEntry-CS3)
		
; =================================================================
; ------------------------------------------------
; Slave CPU
; ------------------------------------------------

		obj SlaveEntry
SH2_Slave:
		dc.l @Entry,S_STACK		; Cold PC,SP
		dc.l @Entry,S_STACK		; Manual PC,SP

		dc.l ErrorTrap			; Illegal instruction
		dc.l 0				; reserved
		dc.l ErrorTrap			; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l ErrorTrap			; CPU address error
		dc.l ErrorTrap			; DMA address error
		dc.l ErrorTrap			; NMI vector
		dc.l ErrorTrap			; User break vector

		dcb.l 19,0			; reserved

		dcb.l 32,ErrorTrap		; Trap vectors

 		dc.l slave_irq			; Level 1 IRQ
		dc.l slave_irq			; Level 2 & 3 IRQ's
		dc.l slave_irq			; Level 4 & 5 IRQ's
		dc.l slave_irq			; PWM interupt
		dc.l slave_irq			; Command interupt
		dc.l slave_irq			; H Blank interupt
		dc.l slave_irq			; V Blank interupt
		dc.l slave_irq			; Reset Button

; =================================================================
; ------------------------------------------------
; Slave entry
; ------------------------------------------------

@Entry:
		mov.l	#_sysreg,r14
		ldc	r14,gbr
@wait_md:
		mov.l	@(comm0,gbr),r0
		cmp/eq	#0,r0
		bf	@wait_md
	
		mov.l	#"SLAV",r0
		mov.l	r0,@(comm8,gbr)

; =================================================================
; ------------------------------------------------
; Hotstart
; ------------------------------------------------

		mov.l	#S_STACK,r15
		mov.l	#_sysreg,r14
		ldc	r14,gbr
 		mov	#CMDIRQ_ON|PWMIRQ_ON,r0
    		mov.b	r0,@(intmask,gbr)
    		
; ==================================================================
; ---------------------------------------------------
; Start
; ---------------------------------------------------

slave_start:
		mov	#$20,r0
		ldc	r0,sr
		
; =================================================================
; ---------------------------------------------------
; Slave loop
; ---------------------------------------------------

slave_loop:
		mov	#Polygons_slave,r0
		jsr	@r0
		nop
		
; 		mov	#SomeVar,r1
; 		mov	@r1,r0
; 		cmp/eq	#1,r0
; 		bf	@wait
; 		mov	#0,r0
		
;  		mov 	#Vsync,r0
;  		jsr	@r0
;  		nop
		bra	slave_loop
		nop
	
; =================================================================
; ------------------------------------------------
; irq
; 
; r0-r9 only
; ------------------------------------------------

slave_irq:
		mov.l	r0,@-r15
		mov.l	r1,@-r15
		mov.l	r2,@-r15
		mov.l	r3,@-r15
		mov.l	r4,@-r15
		mov.l	r5,@-r15
		mov.l	r6,@-r15
		mov.l	r7,@-r15
		mov.l	r8,@-r15
		mov.l	r9,@-r15
		mov.l	macl,@-r15
		mov.l	mach,@-r15
		sts.l	pr,@-r15

		stc	sr,r0
		shlr2	r0
		and	#$3C,r0
		mov.l	#@inttable,r1
		add	r1,r0
		mov.l	@r0,r1
		jsr	@r1
		nop

		lds.l	@r15+,pr
		mov.l	@r15+,mach
		mov.l	@r15+,macl
		mov.l	@r15+,r9
		mov.l	@r15+,r8
		mov.l	@r15+,r7
		mov.l	@r15+,r6
		mov.l	@r15+,r5
		mov.l	@r15+,r4
		mov.l	@r15+,r3
		mov.l	@r15+,r2
		mov.l	@r15+,r1
		mov.l	@r15+,r0
	
		rte
		nop
		lits

; ------------------------------------------------
; irq list
; ------------------------------------------------

		align	4
@inttable:
		dc.l @invalid_irq,@invalid_irq
		dc.l @invalid_irq,@invalid_irq
		dc.l @invalid_irq,@invalid_irq
		dc.l @pwm_irq,@pwm_irq
		dc.l @cmd_irq,@cmd_irq
		dc.l @h_irq,@h_irq
		dc.l @v_irq,@v_irq
		dc.l @vres_irq,@vres_irq

; =================================================================
; ------------------------------------------------
; Unused
; ------------------------------------------------

@invalid_irq:
		rts
		nop
		cnop 0,4
		lits

; =================================================================
; ------------------------------------------------
; Slave | CMD Interrupt
; ------------------------------------------------

@cmd_irq:

; ----------------------------------

		mov.w	@(comm2,gbr),r0
		and	#$FF,r0
		cmp/eq	#0,r0
		bt	@no_task
		bsr	@do_task
		nop
@no_task:
		
; ----------------------------------

		mov	#1,r0
		mov.w	r0,@(cmdintclr,gbr)
		nop
		nop
		nop
		
		rts
		nop
		cnop 0,4
		lits
		
; ----------------------------------
; Task list
; ----------------------------------

@do_task:
		rts
		nop
		align 4
		lits
		
; =================================================================
; ------------------------------------------------
; Slave | PWM Interrupt
; ------------------------------------------------

@pwm_irq:
		mov.l	@(monowidth,gbr),r0
		mov 	r0,r1
		mov.b	@r1,r0				;is pwm fifo full?
		tst	#$80,r0
		bf	@exit

		mov 	pr,@-r15
		mov	#Audio_Run,r0
		jsr	@r0
		nop
		mov 	@r15+,pr
@exit:

; ----------------------------------

		mov	#1,r0
		mov.w	r0,@(pwmintclr,gbr)
		nop
		nop
		nop
		
		rts
		nop
		cnop 0,4
		lits
		
; =================================================================
; ------------------------------------------------
; Slave | HBlank
; ------------------------------------------------

@h_irq:

; ----------------------------------

		mov	#1,r0
		mov.w	r0,@(hintclr,gbr)
		nop
		nop
		nop
		
		rts
		nop
		cnop 0,4
		lits
	
; =================================================================
; ------------------------------------------------
; Slave | VBlank
; ------------------------------------------------

@v_irq:


		
; ----------------------------------

		mov	#frame_count_s,r1
		mov	@r1,r0
		add 	#1,r0
		mov	r0,@r1
		
		mov	#1,r0
		mov.w	r0,@(vintclr,gbr)
		nop
		nop
		nop
		
		rts
		nop
		cnop 0,4
		lits
		
; =================================================================
; ------------------------------------------------
; Slave | VRES Interrupt
; ------------------------------------------------

@vres_irq:

; ----------------------------------

		mov	#1,r0
		mov.w	r0,@(vresintclr,gbr)
		nop
		nop
		nop
		
		rts
		nop
		cnop 0,4
		lits
		
; ====================================================================

		objend
		inform 0,"MARS SH2 SLAVE SIZE: %h",*-SH2_Slave;,(Sh2_CodeEnd-CS3)
 		
; ====================================================================
		
; 		cnop 0,$200
 		inform 0,"MARS SH2 CODE ENDS AT: %h",*
