; ====================================================================
; MARS PWM
; ====================================================================

; -------------------------------------------------
; Variables
; -------------------------------------------------

max_channels	equ	8

; --------------

		rsreset
chn_start	rs.l 1
chn_end		rs.l 1
chn_loop	rs.l 1
chn_read	rs.l 1

chn_pan		rs.l 1
chn_wav		rs.l 1
chn_vol		rs.l 1
chn_enable	rs.l 1

chn_note	rs.l 1
chn_timer	rs.l 1
chn_free1 	rs.l 1
chn_free2	rs.l 1

chn_free3 	rs.l 1
chn_free4	rs.l 1
chn_free5 	rs.l 1
chn_free6	rs.l 1

sizeof_pwm	rs.l 0

; --------------
; chn_pan
; --------------

bitLeft		equ	%00000010
bitRight	equ	%00000001

; ====================================================================
; -------------------------------------------------
; RAM
; -------------------------------------------------

		rsset RAM_Audio
pwmstructs	rs.b max_channels*sizeof_pwm
sizeof_audio	rs.l 0
; 		inform 0,"MARS SH2 Audio size: %h",(sizeof_audio-RAM_Audio)
		
; ====================================================================
; -------------------------------------------------
; Init
; -------------------------------------------------

Audio_Init:
		mov	#((((23011361<<1)/32000+1)>>1)+1),r0
		mov.w	r0,@(cycle,gbr)
		mov	#$0105,r0
		mov.w	r0,@(timerctl,gbr)

		mov	#1,r0
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
	
		rts
		nop
		align 4
		lits

; -------------------------------------------------
; Run
; -------------------------------------------------

Audio_Run:
		mov	#pwmstructs,r8
		mov	#max_channels,r9
		mov	#$80,r6
		mov 	#$80,r7
@channelloop:
		mov	@(chn_enable,r8),r0	; is channel on?
		cmp/eq	#0,r0
		bt	@next_chnl

		mov	@(chn_read,r8),r1	; get the next pcm byte
		mov	@(chn_end,r8),r2
 		cmp/ge	r2,r1
 		bf	@cont_read

 		mov 	#0,r0
 		bra	@next_chnl
 		mov 	r0,@(chn_enable,r8)
 		
@cont_read:
 		mov	#0,r0
 		mov.b	@r1,r0
 		add	#1,r1			; +1 wav byte
 		
 		mov	@(chn_timer,r8),r2
 		add 	#1,r2
		mov 	#$3F,r3
 		and	r3,r2
 		mov 	r2,@(chn_timer,r8)
 		
 		mov	r1,@(chn_read,r8)
		and 	#$FF,r0
		mov 	@(chn_vol,r8),r1
		mulu	r1,r0
		mov 	macl,r0
		cmp/eq	#0,r0
		bf	@notzro
		or	#1,r0
@notzro:
		mov 	r0,r1
  		shll	r1

 		mov	@(chn_pan,r8),r0
 		tst	#bitLeft,r0
 		bt	@not_l
		add	r1,r6
@not_l:
 		tst	#bitRight,r0
 		bt	@next_chnl
		add	r1,r7
@next_chnl:
		add	#sizeof_pwm,r8
		dt	r9
		bf	@channelloop
	
; ----------------------------------
  
@tryagain:
 		mov.l	r6,r0
 		mov.w	r0,@(lchwidth,gbr)
 		mov.l	r7,r0
 		mov.w	r0,@(rchwidth,gbr)
 		
  		mov.w	@(monowidth,gbr),r0
  		shlr8	r0
 		tst	#$80,r0
 		bt	@tryagain
		rts
		nop
		align 4
		lits
		
; ====================================================================
; -------------------------------------------------
; Subs
; -------------------------------------------------

; -------------------------------
; Play channel
;
; Input:
; r1 - Start
; r2 - End
; r3 - Loop
; r4 - Panning (%000000LR)
; r5 - Channel
; -------------------------------

Audio_Play:
		mov.l	#pwmstructs,r8
		shll2	r5
		shll2	r5
		shll2	r5		;Size $20
		add	r5,r8

		mov 	r1,@(chn_start,r8)
		mov	r1,@(chn_read,r8)
		mov 	r2,@(chn_end,r8)
		mov 	r3,@(chn_loop,r8)
		
		mov 	r4,@(chn_pan,r8)
		
		mov 	#1,r0
		mov 	r0,@(chn_enable,r8)
		mov 	#1,r0
		mov 	r0,@(chn_vol,r8)
@done_pwm:
		rts
		nop
		align 4
		lits
	
