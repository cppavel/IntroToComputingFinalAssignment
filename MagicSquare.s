;
; CS1022 Introduction to Computing II 2018/2019
; Magic Square
;
;There are 3 magic squares available for testing (n=3,n=5,n=9)
;There are 7 matrices that are not magic squares, which can be used to check how the program handles different cases

	AREA	RESET, CODE, READONLY
	ENTRY

	; initialize system stack pointer (SP)
	LDR	SP, =0x40010000
	
	;MAGIC SQUARES

	;magic square n = 3
	LDR	R1, =arr1
	LDR	R4, =size1
	LDR	R2, [R4]
	
	BL isMagic
	
	;magic square n = 5
	LDR	R1, =arr2
	LDR	R4, =size2
	LDR	R2, [R4]
	
	BL isMagic
	
	;magic square n = 9
	LDR	R1, =arr3
	LDR	R4, =size3
	LDR	R2, [R4]
	
	BL isMagic
	
	;NOT MAGIC SQUARES
	
	;There exists an element which is larger than n^2
	LDR	R1, =arr4
	LDR	R4, =size4
	LDR	R2, [R4]
	
	BL isMagic
	
	;There exists an element which is smaller than 1
	LDR	R1, =arr5
	LDR	R4, =size5
	LDR	R2, [R4]
	
	BL isMagic
	
	;There is an element that is repeated
	
	LDR	R1, =arr6
	LDR	R4, =size6
	LDR	R2, [R4]
	
	BL isMagic
	
	;I found semimagic squares on https://mathworld.wolfram.com/SemimagicSquare.html
	;Semimagic square when main diagonal (i=j) has a correct sum, but the other has an incorrect sum
	
	LDR	R1, =arr7
	LDR	R4, =size7
	LDR	R2, [R4]
	
	BL isMagic
	
	;Semimagic square when main diagonal (i = n - j - 1) has a correct sum, but the other has an incorrect sum
	
	LDR	R1, =arr8
	LDR	R4, =size8
	LDR	R2, [R4]
	
	BL isMagic
	
	;A matrix which has the correct row sums and diagonal sums, however all of the column sums are not correct.
	
	LDR	R1, =arr9
	LDR	R4, =size9
	LDR	R2, [R4]
	
	BL isMagic
	
	;A matrix which has the correct column sums and diagonal sums, however all of the row sums are not correct.
	
	LDR	R1, =arr10
	LDR	R4, =size10
	LDR	R2, [R4]
	
	BL isMagic
	
stop	B	stop

;subroutine which checks, whether a given matrix is a magic square:
;	1. all elements are unique numbers from 1,...,n^2
;	2. sum of columns, rows and main diagonal is equal to magic constant: (n^2 + 1)*n/2
		;I found the idea of magic constant on the 
			;https://mathworld.wolfram.com/MagicSquare.html webpage.
;Parameters:
;R0 - result, 0 - if the matrix is not a magic square, 1 - if the matrix is a magic square 
;R1 - start address of the array
;R2 - size of the square matrix

isMagic

	PUSH{R4-R12,lr}
	
	;first we make sure the matrix is valid, so we call a checkValid subroutine
	
	
	;I have to push the registers on to the stack because the subroutine will need to use R4-R12, 
	;so I do not have 2 spare registers to put the values of R1 and R2 to. 
	
	PUSH{R1-R2};save the parameters in case they are modified
	
	BL checkValid
	
	POP{R1-R2}; save the parameters in case they are modified
	
	;if the matrix is invalid it is definitely not a magic square
	CMP R0, #0
	BEQ isMagicEnd
	
	;first we need to calculate the magic constant, it is going to be stored in R4
	
	MUL R4, R2, R2; n^2
	ADD R4, R4, #1; n^2 + 1
	MUL R4, R2, R4; (n^2 + 1)*n
	MOV R4, R4, LSR #1; (n^2 + 1)*n/2
	
	; now we need to check whether the sum of each row, each column and main diagonal is equal to magic constant
	
	MOV R5, #0 ; row index
	;R6 column index
	;R7 main diagonal sum (i = j)
	;R12 main diagonal sum (i = n - j - 1)
	;R8 row sum
	;R9 column sum
	
	;setting diagonals sum to zero
	MOV R7, #0
	MOV R12, #0
	
isMagicFor1
	CMP R5, R2
	BEQ isMagicEndFor1
	
	;setting column index, row and columns sums to zero
	MOV R6, #0
	MOV R8, #0
	MOV R9, #0
	
isMagicalFor2
	CMP R6, R2
	BEQ isMagicalEndFor2
	
	MUL R10, R5, R2; i*N
	ADD R10, R10, R6; i*N + j
	LDR R11, [R1, R10, LSL #2]; loading the row element
	ADD R8, R8, R11; adding the element to row sum
	
	SUB R10, R2, R6  ; n - j 
	SUB R10, R10, #1 ; n - j - 1
	
	CMP R10, R5
	BNE isMagicalNotDiagonal1
	ADD R12, R12, R11
isMagicalNotDiagonal1
	
	MUL R10, R6, R2; j*N
	ADD R10, R10, R5; j*N + i 
	LDR R11, [R1, R10, LSL #2]; loading the column element
	ADD R9, R9, R11; adding the element to column sum
	
	CMP R5, R6
	BNE isMagicalNotDiagonal2
	ADD R7, R7, R11; adding the element to diagonal sum (i=j)
isMagicalNotDiagonal2

	ADD R6, R6, #1 
	B isMagicalFor2
isMagicalEndFor2

	CMP R8, R4 		;checking whether the current row sum is equal to magic constant
	BEQ isMagicalRowSumOk
	MOV R0, #0 ; matrix is not a magic square
	B isMagicEnd
isMagicalRowSumOk

	CMP R9, R4		;checking whether the current column sum is equal to magic constant
	BEQ isMagicalColumnSumOk
	MOV R0, #0; matrix is not a magic square
	B isMagicEnd
isMagicalColumnSumOk
	
	ADD R5, R5, #1
	B isMagicFor1
isMagicEndFor1
	
	CMP R7, R4 ; checking if main diagonal sum is equal to the magic constant (i = j)
	BEQ isMagicNotIf
	MOV R0, #0 ;matrix is invalid	
isMagicNotIf	
	CMP R12, R4; checking if main diagonal sum is equal to the magic constant (i = n - j - 1)
	BEQ isMagicEnd
	MOV R0, #0 ;matrix is invalid
isMagicEnd

	POP{R4-R12, pc}

;subroutine which checks, that the matrix contains valid numbers:
;1,...,n^2, and each number occurs in matrix only once

;The approach is to have an array of length n^2, where each element represents
;the number of times the respective number occurred.
;If at some point the number of occurences for a given number turns out to be
;greater than one, there is no need to continue checking.


;Parameters:
;R0 - result, 0 - if the square is invalid, 1 - if the square is valid
;R1 - start address of the array
;R2 - size of the square matrix

checkValid
	PUSH{R4-R10, lr}
	
	MOV R0, #1 ;initially we consider matrix to be valid
	
	;We need to allocate the memory for the counter array inside the stack. The best idea is to use the 0x40000000, 
	;since it is the first address in read/write memory, which means that the array will have to be quite large
	;to overwrite the variables we save on the stack. In fact it will have to be approximately 2^14 elements long,
	;which is 16384 and corresponds to the matrix of size 2^7 = 128. However, from now on we have to always keep the size
	;of matrix in mind. 
	
	LDR R4, =0x40000000
	
	;before using the counters array, we need to zero all of its elements
	;we can treat it as matrix, using row index and column index
	
	MOV R5, #0; row index 
	MOV R7, #0; zero to store in the counters array
	
checkValidFor1
	CMP R5, R2
	BEQ checkValidEndFor1
	
	MOV R6, #0; column index

checkValidFor2
	CMP R6, R2
	BEQ checkValidEndFor2
	
	;calculating the index of the array
	
	MUL R8, R5, R2 
	ADD R8, R8, R6
	
	;storing a zero here
	STR R7,[R4, R8, LSL #2]
	
	ADD R6, R6, #1 
	B checkValidFor2
checkValidEndFor2

	ADD R5, R5, #1
	B checkValidFor1
checkValidEndFor1

	;now we can calculate the counters
	
	MOV R5, #0; row index 
	
checkValidFor3
	CMP R5, R2
	BEQ checkValidEndFor3
	
	MOV R6, #0; column index

checkValidFor4
	CMP R6, R2
	BEQ checkValidEndFor4
	
	;calculating the index of the array
	
	MUL R8, R5, R2 
	ADD R8, R8, R6
	
	;getting the value from the matrix
	
	LDR R9, [R1, R8, LSL #2]
	
	MUL R8, R2, R2 ; n^2
	
	;here we check whether the element is in range 1,...,n^2, if it is not, the matrix is invalid
	
	CMP R9, R8
	BLE checkValidElementValid1
	
	MOV R0, #0; matrix is invalid
	B checkValidEndFor3
	
checkValidElementValid1
	CMP R9, #1
	BGE checkValidElementValid2
	
	MOV R0, #0; matrix is invalid
	B checkValidEndFor3
	
checkValidElementValid2
	
	;getting the value from counters array
	
	SUB R9, R9, #1 ; subtracting one, so that counter of 1's is stored at postion 0 and etc.
	
	LDR R10, [R4, R9, LSL #2]
	
	ADD R10, R10, #1 ;incrementing it
	
	CMP R10, #1
	BLE checkValidCounterOk
	
	MOV R0, #0; matrix is invalid
	B checkValidEndFor3
	
checkValidCounterOk
	
	;storing it back
	
	STR R10, [R4, R9, LSL #2]
	
	ADD R6, R6, #1
	B checkValidFor4
checkValidEndFor4

	ADD R5, R5, #1
	B checkValidFor3
checkValidEndFor3


	POP{R4-R10, pc}

;MAGIC SQUARES 3,5,9 (https://en.wikipedia.org/wiki/Magic_square#A_method_for_constructing_a_magic_square_of_odd_order)

size1	DCD	3		
arr1	DCD	8,1,6		
	DCD	3,5,7
	DCD 4,9,2

size2 	DCD 5
arr2	DCD 17, 24,1,8,15  
	DCD 23,5,7,14,16 
	DCD 4,6,13,20,22 
	DCD 10,12,19,21,3
	DCD	11,18,25,2,9
size3 	DCD 9
arr3 	DCD 47,	58,	69,	80,	1,	12,	23,	34,	45
	DCD 57,	68,	79,	9,	11,	22,	33,	44,	46
	DCD 67,	78,	8,	10,	21,	32,	43,	54,	56
	DCD 77,	7,	18,	20,	31,	42,	53,	55,	66
	DCD 6,	17,	19,	30,	41,	52,	63,	65,	76
	DCD 16,	27,	29,	40,	51,	62,	64,	75,	5
	DCD 26,	28,	39, 50	,61	,72	,74	,4,	15
	DCD 36,	38,	49,	60,	71,	73,	3, 14,	25
	DCD 37,	48,	59,	70,	81,	2,	13,	24,	35

;EXAMPLES OF MATRICES THAT ARE NOT VALID MAGIC SQUARES

;1. There exists an element which is larger than n^2

size4	DCD	3		
arr4	DCD	8,1,6		
	DCD	3,5,7
	DCD 4,120,2
;2. There exists an element which is smaller than 1

size5	DCD	3		
arr5	DCD	8,1,0		
	DCD	3,5,7
	DCD 4,9,2
		
;3. There is an element that is repeated

size6	DCD	3		
arr6	DCD	8,1,1		
	DCD	3,5,7
	DCD 4,9,2

; I found semimagic squares on https://mathworld.wolfram.com/SemimagicSquare.html
;4. Semimagic square when main diagonal (i=j) has a correct sum, but the other has an incorrect sum


size7	DCD	3		
arr7	DCD	2,4,9		
	DCD	6,8,1
	DCD 7,3,5
;5. Semimagic square when main diagonal (i = n - j - 1) has a correct sum, but the other has an incorrect sum
size8	DCD	3	
arr8	DCD	3,7,5		
	DCD	8,6,1
	DCD 4,2,9
;6. A matrix which has the correct row sums and diagonal sums, however all of the column sums are not correct.
size9 	DCD 3
arr9 	DCD	6,1,8		
	DCD	2,4,9
	DCD 3,7,5
;7. A matrix which has the correct column sums and diagonal sums, however all of the row sums are not correct.
;Basically, a transpose of the previous matrix.
size10 	DCD 3
arr10	DCD	6,2,3		
	DCD	1,4,7
	DCD 8,9,5


	END
