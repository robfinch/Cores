;------------------------------------------------------------------------------
; Parameters:
;		a0 = address of semaphore
;		a1 = retry count
; Returns:
;		v0 = 1 if successful, 0 otherwise
;------------------------------------------------------------------------------

LockSemaphore:
	ldi		t1,#128
	call	GetCurrentTid
.0001:
  ble   a1,x0,.0004
  sub		a1,a1,#1  
  lr  	t1,[a0]
  beq   t1,v0,.0002			; test if already locked by this task
  add		t1,t1,#1
  bne   t1,x0,.0001     ; branch if not free
.0003:
  sc   	v1,v0,[a0]      ; try and lock it
  bne		$v1,$x0,.0001		; lock failed, go try again
.0002:
  ldi   v0,#1
  ret
.0004:
  ldi		v0,#0
	ret

;------------------------------------------------------------------------------
; Parameters:
;		a0 = address of semaphore
; Returns:
;		none
;------------------------------------------------------------------------------

UnlockSemaphore:
	ldi		$v0,#-1
	sw		$v0,[$a0]
	ret
