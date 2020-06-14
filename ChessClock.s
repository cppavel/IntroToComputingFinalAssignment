;
; CS1022 Introduction to Computing II 2018/2019
; Chess Clock
;

T0IR		EQU	0xE0004000
T0TCR		EQU	0xE0004004
T0TC		EQU	0xE0004008
T0MR0		EQU	0xE0004018
T0MCR		EQU	0xE0004014
	
T1IR 		EQU 0xE0008000
T1TCR   	EQU 0xE0008004
T1TC		EQU	0xE0008008
T1MR0 		EQU 0xE0008018
T1MCR 		EQU	0xE0008014

PINSEL4		EQU	0xE002C010

FIO2DIR1	EQU	0x3FFFC041
FIO2PIN1	EQU	0x3FFFC055

EXTINT		EQU	0xE01FC140
EXTMODE		EQU	0xE01FC148
EXTPOLAR	EQU	0xE01FC14C

VICIntSelect	EQU	0xFFFFF00C
VICIntEnable	EQU	0xFFFFF010
VICIntEnClear 	EQU 0xFFFFF014
VICVectAddr0	EQU	0xFFFFF100
VICVectPri0	EQU	0xFFFFF200
VICVectAddr	EQU	0xFFFFFF00
	

VICVectT0	EQU	4
VICVectT1	EQU	5
	
VICVectEINT0	EQU	14
VICVectEINT1	EQU	15
VICVectEINT2	EQU	16

Irq_Stack_Size	EQU	0x80

Mode_USR        EQU     0x10
Mode_IRQ        EQU     0x12
I_Bit           EQU     0x80            ; when I bit is set, IRQ is disabled
F_Bit           EQU     0x40            ; when F bit is set, FIQ is disabled



	AREA	RESET, CODE, READONLY
	ENTRY

	; Exception Vectors

	B	Reset_Handler	; 0x00000000
	B	Undef_Handler	; 0x00000004
	B	SWI_Handler	; 0x00000008
	B	PAbt_Handler	; 0x0000000C
	B	DAbt_Handler	; 0x00000010
	NOP			; 0x00000014
	B	IRQ_Handler	; 0x00000018
	B	FIQ_Handler	; 0x0000001C

;
; Reset Exception Handler
;
Reset_Handler

	;
	; Initialize Stack Pointers (SP) for each mode we are using
	;

	; Stack Top
	LDR	R0, =0x40010000

	; Enter irq mode and set initial SP
	MSR     CPSR_c, #Mode_IRQ:OR:I_Bit:OR:F_Bit
	MOV     SP, R0
	SUB     R0, R0, #Irq_Stack_Size

	; Enter user mode and set initial SP
	MSR     CPSR_c, #Mode_USR
	MOV	SP, R0
	
	;TIMERS
	
	; Stop and reset TIMER0 using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	; Set bit 1 of TCR to 1 to reset TIMER
	LDR	R5, =T0TCR
	LDR	R6, =0x2
	STRB	R6, [R5]
	
	; Stop and reset TIMER1 using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	; Set bit 1 of TCR to 1 to reset TIMER
	LDR	R5, =T1TCR
	LDR	R6, =0x2
	STRB	R6, [R5]
	
	; Clear any previous TIMER0 interrupt by writing 0xFF to the TIMER0
	; Interrupt Register (T0IR)
	LDR	R5, =T0IR
	LDR	R6, =0xFF
	STRB	R6, [R5]
	
	; Clear any previous TIMER0 interrupt by writing 0xFF to the TIMER1
	; Interrupt Register (T1IR)
	LDR	R5, =T1IR
	LDR	R6, =0xFF
	STRB	R6, [R5]
	
	; IRQ on match using Match Control Register
	; Set bit 0 of MCR to 1 to turn on interrupts
	; Set bit 1 of MCR to 1 to reset counter to 0 after every match
	; Set bit 2 of MCR to 1 to disable the counter after match
	LDR	R4, =T0MCR
	LDR	R5, =0x07
	STRH	R5, [R4]
	
	; IRQ on match using Match Control Register
	; Set bit 0 of MCR to 1 to turn on interrupts
	; Set bit 1 of MCR to 1 to reset counter to 0 after every match
	; Set bit 2 of MCR to 1 to disable the counter after match
	LDR	R4, =T1MCR
	LDR	R5, =0x07
	STRH	R5, [R4]
	
	;
	; Configure VIC for TIMER0 interrupts
	;

	; Useful VIC vector numbers and masks for following code
	LDR	R3, =VICVectT0		; vector 4
	LDR	R4, =(1 << VICVectT0) 	; bit mask for vector 4
	
	LDR	R5, =VICVectT1		; vector 5
	LDR	R6, =(1 << VICVectT1) 	; bit mask for vector 5
	
	; VICIntSelect - Clear bits 4, 5 of VICIntSelect register to cause
	; channels 4, 5 to raise IRQs (not FIQs)
	LDR	R7, =VICIntSelect	; addr = VICVectSelect;
	LDR	R8, [R7]		; tmp = Memory.Word(addr);
	BIC	R8, R8, R4		; Clear bit for Vector 4
	BIC	R8, R8, R6		; Clear bit for Vector 5
	STR	R8, [R7]		; Memory.Word(addr) = tmp;
	
	; Set Priority for VIC channels 4, 5 to lowest (15)

	LDR	R7, =VICVectPri0	; addr = VICVectPri0;
	MOV	R8, #15			; pri = 15;
	STR	R8, [R7, R3, LSL #2]	; Memory.Word(addr + vector * 4) = pri;
	STR	R8, [R7, R5, LSL #2]	; Memory.Word(addr + vector * 4) = pri;
	
	; Set Handler routine address for VIC channels 4, 5

	LDR	R7, =VICVectAddr0	; addr = VICVectAddr0;
	LDR	R8, =Timer_1	; handler = address of TimerHandler;
	STR	R8, [R7, R3, LSL #2]	; Memory.Word(addr + vector * 4) = handler

	LDR	R8, =Timer_2	; handler = address of TimerHandler;
	STR	R8, [R7, R5, LSL #2]	; Memory.Word(addr + vector * 5) = handler
	
	; Enable VIC channels 4, 5 by writing a 1 to bits 4,5 of VICIntEnable
	LDR	R7, =VICIntEnable	; addr = VICIntEnable;
	ORR R8, R4, R6; configurating the value
	STR	R8, [R7]		; enable interrupts for vector 4, 5	

	;BUTTONS
	
	;we configure P2.10, P2.11, P2.12, for GPIO
	
	LDR	R4, =PINSEL4
	LDR	R5, [R4]		; read current value
	BIC	R5, #(0x03 << 20)	; clear bits 21:20
	ORR	R5, #(0x01 << 20)	; set bits 21:20 to 01
	BIC	R5, #(0x03 << 22)	; clear bits 23:22
	ORR	R5, #(0x01 << 22)	; set bits 23:22 to 01
	BIC	R5, #(0x03 << 24)	; clear bits 25:24
	ORR	R5, #(0x01 << 24)	; set bits 25:24 to 01
	STR	R5, [R4]		; write new value
	
	; Set edge-sensitive mode for EINT0, EINT1, EINT2
	LDR	R4, =EXTMODE
	LDR	R5, [R4]		; read
	ORR	R5, #7			; modify
	STRB R5, [R4]		; write
	
	; Set falling-edge mode for EINT0, EINT1, EINT2
	LDR	R4, =EXTPOLAR
	LDR	R5, [R4]		; read
	BIC	R5, #7			; modify
	STRB R5, [R4]		; write
	
	; Reset EINT0, EINT1, EINT2
	LDR	R4, =EXTINT
	MOV	R5, #7
	STRB R5, [R4]
	
	;Useful VIC vector numbers and masks for following code
	
	LDR R4, =VICVectEINT0		;vector 14
	LDR R5, =(1<<VICVectEINT0)	;bit mask for vector 14
	
	LDR R6, =VICVectEINT1		;vector 15
	LDR R7, =(1<<VICVectEINT1)	;bit mask for vector 15
	
	LDR R8, =VICVectEINT2		;vector 16
	LDR R9, =(1<<VICVectEINT2)	;bit mask for vector 16
	
	; VICIntSelect - Clear bits 14, 15, 16 of VICIntSelect register to cause
	; channels 14, 15, 16 to raise IRQs (not FIQs)
	LDR	R10, =VICIntSelect	; addr = VICVectSelect;
	LDR	R11, [R10]		; tmp = Memory.Word(addr);
	BIC	R11, R11, R5		; Clear bit for Vector 14
	BIC	R11, R11, R7		; Clear bit for Vector 15
	BIC	R11, R11, R9		; Clear bit for Vector 16
	STR	R11, [R10]		; Memory.Word(addr) = tmp;
	
	; Set Priority for VIC channels 14, 15, 16 to lowest (15) by setting VICVectPrio to 15
	LDR	R10, =VICVectPri0	; addr = VICVectPri0;
	MOV	R11, #15			; pri = 15;
	STR	R11, [R10, R4, LSL #2]	; Memory.Word(addr + vector * 4) = pri;
	STR R11, [R10, R6, LSL #2] 	; Memory.Word(addr + vector * 4) = pri;
	STR	R11, [R10, R8, LSL #2]	; Memory.Word(addr + vector * 4) = pri;

	
	; Set Handler routine addresses for VIC channels 14, 15, 16
	
	LDR	R10, =VICVectAddr0	; addr = VICVectAddr0;
	
	LDR	R11, =Button_1	; handler ;
	STR	R11, [R10, R4, LSL #2]	; Memory.Word(addr + vector * 4) = handler
	
	LDR	R11, =Reset_Button	; handler ;
	STR	R11, [R10, R6, LSL #2]	; Memory.Word(addr + vector * 4) = handler
	
	LDR	R11, =Button_2	; handler ;
	STR	R11, [R10, R8, LSL #2]	; Memory.Word(addr + vector * 4) = handler
	
	
	; Enable VIC channels 14, 15, 16 by writing a 1 to bits 14, 15, 16 of VICIntEnable
	LDR	R10, =VICIntEnable	; addr = VICIntEnable;
	
	; configurating a value to store
	ORR R11, R5, R7	
	ORR R11, R11, R9
	
	STR	R11, [R10]		; enable interrupts for vectors 14, 15, 16
	
	LDR R10, =time_interval
	LDR R11, =30000000 ; 30 seconds
	STR R11, [R10]
	
	LDR R10, = reset_state
	LDR R11, =1			;initially we are in reset state
	STR R11, [R10]
	
	LDR R10, = run_out_of_time_player
	LDR R11, =-1
	STR R11, [R10] 		;initially no player ran out of time
	

	
	
	

stop	B	stop


;
; TOP LEVEL EXCEPTION HANDLERS
;

;
; Software Interrupt Exception Handler
;
Undef_Handler
	B	Undef_Handler

;
; Software Interrupt Exception Handler
;
SWI_Handler
	B	SWI_Handler

;
; Prefetch Abort Exception Handler
;
PAbt_Handler
	B	PAbt_Handler

;
; Data Abort Exception Handler
;
DAbt_Handler
	B	DAbt_Handler

;
; Interrupt ReQuest (IRQ) Exception Handler (top level - all devices)
;
IRQ_Handler
	SUB	lr, lr, #4	; for IRQs, LR is always 4 more than the
				; real return address
	STMFD	sp!, {r0-r3,lr}	; save r0-r3 and lr

	LDR	r0, =VICVectAddr; address of VIC Vector Address memory-
				; mapped register

	MOV	lr, pc		; can’t use BL here because we are branching
	LDR	pc, [r0]	; to a different subroutine dependant on device
				; raising the IRQ - this is a manual BL !!

	LDMFD	sp!, {r0-r3, pc}^ ; restore r0-r3, lr and CPSR

;
; Fast Interrupt reQuest Exception Handler
;
FIQ_Handler
	B	FIQ_Handler

Timer_1
	
	PUSH {R4-R7, lr}
	
	
	; Reset TIMER0 interrupt by writing 0xFF to T0IR
	LDR	R4, =T0IR
	MOV	R5, #0xFF
	STRB	R5, [R4]
	
	; Stop and reset second timer using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	; Set bit 1 of TCR to 1 to reset TIMER
	LDR	R4, =T1TCR
	LDR	R5, =0x2
	STRB	R5, [R4]
	
	;Since there is a bug in uVision, we have to force the counter back to 0
	LDR	R4, =T1TC
	LDR	R5, =0x0
	STR	R5, [R4]
	
	LDR R4, = run_out_of_time_player
	LDR R5, = 1 ; first player ran out of time
	STR R5, [R4]
	
	LDR R4, =(1<<VICVectEINT0)	;bit mask for vector 14
	
	LDR R5, =(1<<VICVectEINT2)	;bit mask for vector 16
	
	LDR R6, = VICIntEnClear
	
	ORR R7, R4, R5 ; configurating value to store
	
	STR R7, [R6] ; disable button 1 and button 2
	
	; Clear source of interrupt by writing 0 to VICVectAddr
	LDR	R4, =VICVectAddr
	MOV	R5, #0
	STR	R5, [R4]

	
	POP {R4-R7, pc}
	
Timer_2

	PUSH {R4-R7, lr}
	
	; Reset TIMER1 interrupt by writing 0xFF to T0IR
	LDR	R4, =T1IR
	MOV	R5, #0xFF
	STRB	R5, [R4]
	
	; Stop and reset first timer using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	; Set bit 1 of TCR to 1 to reset TIMER
	LDR	R4, =T0TCR
	LDR	R5, =0x2
	STRB	R5, [R4]
	
	;Since there is a bug in uVision, we have to force the counter back to 0
	LDR	R4, =T0TC
	LDR	R5, =0x0
	STR	R5, [R4]
	
	LDR R4, = run_out_of_time_player
	LDR R5, = 2 ; second player ran out of time
	STR R5, [R4]
	
	LDR R4, =(1<<VICVectEINT0)	;bit mask for vector 14
	
	LDR R5, =(1<<VICVectEINT2)	;bit mask for vector 16
	
	LDR R6, = VICIntEnClear
	
	ORR R7, R4, R5 ; configurating value to store
	
	STR R7, [R6] ; disable button 1 and button 2
	
	; Clear source of interrupt by writing 0 to VICVectAddr
	LDR	R4, =VICVectAddr
	MOV	R5, #0
	STR	R5, [R4]
	
	POP {R4-R7, pc}

Button_1

	PUSH{R4-R9, lr}
	
	; Reset EINT0 and EINT2 interrupt by writing 5 to EXTINT register
	; We also need to reset EINT2 in case the button 2 was pressed, while the interrupt channel was disabled. 
	; If we do not do this, when the channel is enabled again the exception will be raised, which can result incorrect behaviour, 
	; since pressing button 2 should not make any impact after the interrupt channel is disabled
	LDR	R4, =EXTINT
	MOV	R5, #5
	STRB	R5, [R4]
	
	LDR R4, = reset_state
	LDR R5, [R4] ; the value of reset state
	
	CMP R5, #1
	BNE Button_1_NotResetState
	LDR R6, = time_interval
	LDR R7, [R6] 
	LDR R8, = 1000000
	CMP R7, R8
	BLE Button_1_Impossible_To_Decrease
	;decreasing the interval
	SUB R7, R7, R8 
	STR R7, [R6]
Button_1_Impossible_To_Decrease
	B Button_1_End
Button_1_NotResetState
	
	;stop timer 1
	
	LDR	R4, =T0TCR
	LDR	R5, =0x0
	STRB	R5, [R4]
	
	;start timer 2
	LDR	R4, =T1TCR
	LDR	R5, =0x01
	STRB	R5, [R4]
	
	LDR R4, = VICIntEnClear
	LDR	R9, = VICIntEnable	
	
	LDR R5, =(1<<VICVectEINT0)	;bit mask for vector 14
	
	LDR R6, =(1<<VICVectEINT2)	;bit mask for vector 16
	
	STR R5, [R4] ; disabling EINT0
	STR R6, [R9] ; enabling EINT2
	
Button_1_End


	; Clear source of interrupt by writing 0 to VICVectAddr
	LDR	R4, =VICVectAddr
	MOV	R5, #0
	STR	R5, [R4]

	POP{R4-R9,pc}


Button_2

	PUSH{R4-R9, lr}	

	; Reset EINT0 and EINT2 interrupt by writing 5 to EXTINT register
	; We also need to reset EINT0 in case the button 1 was pressed, while the interrupt channel was disabled. 
	; If we do not do this, when the channel is enabled again the exception will be raised, which can result incorrect behaviour, 
	; since pressing button 1 should not make any impact after the interrupt channel is disabled
	LDR	R4, =EXTINT
	MOV	R5, #5
	STRB	R5, [R4]
	
	
	LDR R4, = reset_state
	LDR R5, [R4] ; the value of reset state
	
	CMP R5, #1
	BNE Button_2_NotResetState
	LDR R6, = time_interval
	LDR R7, [R6] 
	LDR R8, = 1000000
	ADD R7, R7, R8 	;increasing the interval
	STR R7, [R6]
	B Button_2_End
Button_2_NotResetState
	
	;stop timer 2
	
	LDR	R4, =T1TCR
	LDR	R5, =0x0
	STRB	R5, [R4]
	
	;start timer 1
	LDR	R4, =T0TCR
	LDR	R5, =0x01
	STRB	R5, [R4]
	
	LDR R4, = VICIntEnClear
	LDR	R9, = VICIntEnable	
	
	LDR R5, =(1<<VICVectEINT0)	;bit mask for vector 14
	
	LDR R6, =(1<<VICVectEINT2)	;bit mask for vector 16
	
	STR R6, [R4] ; disabling EINT2
	STR R5, [R9] ; enabling EINT0
	
Button_2_End


	; Clear source of interrupt by writing 0 to VICVectAddr
	LDR	R4, =VICVectAddr
	MOV	R5, #0
	STR	R5, [R4]
	
	POP{R4-R9,pc}

Reset_Button

	PUSH {R4-R5, lr}
	
	; Reset EINT1 interrupt by writing 1 to EXTINT register
	LDR	R4, =EXTINT
	MOV	R5, #2
	STRB	R5, [R4]
	
	LDR R4, = reset_state
	LDR R5, [R4]
	
	CMP R5, #1
	BEQ Reset_Button_Already_In_Reset
	
	; Stop and reset first timer using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	; Set bit 1 of TCR to 1 to reset TIMER
	LDR	R4, =T0TCR
	LDR	R5, =0x2
	STRB	R5, [R4]
	
	;Since there is a bug in uVision, we have to force the counter back to 0
	LDR	R4, =T0TC
	LDR	R5, =0x0
	STR	R5, [R4]
	
	; Stop and reset second timer using Timer Control Register
	; Set bit 0 of TCR to 0 to stop TIMER
	; Set bit 1 of TCR to 1 to reset TIMER
	LDR	R4, =T1TCR
	LDR	R5, =0x2
	STRB	R5, [R4]
	
	;Since there is a bug in uVision, we have to force the counter back to 0
	LDR	R4, =T1TC
	LDR	R5, =0x0
	STR	R5, [R4]

	LDR R4, = reset_state
	LDR R5, = 1 
	STR R5, [R4] ; going to reset state
	LDR R4, = run_out_of_time_player
	LDR R5, = -1
	STR R5, [R4] ; no player ran out of time
	
	B Reset_Button_End
Reset_Button_Already_In_Reset
	;not in reset state anymore
	
	
	;specified number of secs
	
	LDR R6, =time_interval
	LDR	R5, [R6]
	
	; Set match register for specified number of secs using Match Register

	LDR	R4, =T0MR0
	STR	R5, [R4]
	
	; Set match register for specified number of secs using Match Register 
	LDR	R4, =T1MR0
	STR	R5, [R4]
	
	LDR R4, = reset_state
	LDR R5, =0
	STR R5, [R4] 
	
Reset_Button_End

	LDR R4, =(1<<VICVectEINT0)	;bit mask for vector 14
	
	LDR R5, =(1<<VICVectEINT2)	;bit mask for vector 16
	
	LDR R6, = VICIntEnable
	
	ORR R7, R4, R5 ; configurating value to store
	
	STR R7, [R6] ; enable button 1 and button 2


	; Clear source of interrupt by writing 0 to VICVectAddr
	LDR	R4, =VICVectAddr
	MOV	R5, #0
	STR	R5, [R4]
	
	POP {R4-R5, pc}
	
	AREA Variables, DATA, READWRITE
		
reset_state SPACE 4
time_interval SPACE 4
run_out_of_time_player SPACE 4


	END
