; =====================================================
; ----------------------------------------
; MARS
; ----------------------------------------

; 			if MARS
RAM_SMEG_Buffer		rs.b	$40
RAM_SMEG_SfxBuff	rs.b	$40
RAM_SMEG_Chnls_BGM	rs.b	$10*18
RAM_SMEG_Chnls_SFX	rs.b	$10*18
RAM_SMEG_PcmList	rs.b	$200

; ; ----------------------------------------
; ; CD
; ; ----------------------------------------
; 
; 			elseif SegaCD
; RAM_SMEG_Buffer		rs.b	$40
; RAM_SMEG_SfxBuff	rs.b	$40
; RAM_SMEG_Chnls_BGM	rs.b	$10*18
; RAM_SMEG_Chnls_SFX	rs.b	$10*18
; 
;    			
; ; ----------------------------------------
; ; MD
; ; ----------------------------------------
; 
; 			else
; RAM_SMEG_Buffer		rs.b	$40
; RAM_SMEG_SfxBuff	rs.b	$40
; RAM_SMEG_Chnls_BGM	rs.b	$10*18
; RAM_SMEG_Chnls_SFX	rs.b	$10*18
; 
; ; ----------------------------------------
;    			endif