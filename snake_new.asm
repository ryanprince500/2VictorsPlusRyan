.data
foodLoc01: 	.word 0x00000076
foodCol01: 	.word 0x00000005
foodLoc02: 	.word 0x00000100
foodCol02: 	.word 0x00000004
foodLoc03: 	.word 0x00000029
foodCol03: 	.word 0x00000006
foodLoc04: 	.word 0x00000110
foodCol04: 	.word 0x00000001
foodLoc05: 	.word 0x00000012
foodCol05: 	.word 0x00000003
foodLoc06: 	.word 0x00000045
foodCol06: 	.word 0x00000001
foodLoc07: 	.word 0x00000093
foodCol07: 	.word 0x00000006
foodLoc08: 	.word 0x00000072
foodCol08: 	.word 0x00000005
foodLoc09: 	.word 0x00000057
foodCol09: 	.word 0x00000001
foodLoc10: 	.word 0x00000102
foodCol10: 	.word 0x00000005
foodLoc11: 	.word 0x00000006
foodCol11: 	.word 0x00000002

.text

main:

## Clear gridmem
jal clearGrid

## init all global registers
addi $r14, $r0, 0		# init random number location = 0

addi $r1, $r0, 1
sll $r15, $r1, 19		# init delay limit = 1<<19

addi $r19, $r0, 2		# init snake color = green
addi $r20, $r0, 0x95		# init snake head loc = 0x95 (x=9, y=7)
addi $r21, $r0, 9		# init snake head x=9
addi $r22, $r0, 7		# init snake head y=7
addi $r23, $r0, 3		# init snake length = 3
addi $r24, $r0, 4		# init snake direction = right

addi $r25, $r0, 0x75		# init up key value = 0x75	
addi $r26, $r0, 0x72		# init down key value = 0x72
addi $r27, $r0, 0x6b		# init left key value = 0x6b
addi $r28, $r0, 0x74		# init right key value = 0x74

addi $r30, $r0, 0xDFF		# init stack pointer = 0xDFF

## draw the snake body in gridmem
addi $r1, $r0, 1
addi $r2, $r0, 2
addi $r3, $r0, 3
sw $r3, 0xA00($r20)		# gridmem offset = 0xA00
sw $r2, 0x9FF($r20)
sw $r1, 0x9FE($r20)

## place the first food
jal placeFood			# the new food color and location are both determined in this procedure

## refresh the display before the good starts
jal updateDispmem

################
## first check keyboard input in a for loop that is also used for delay between each move
## the final value of the counter determines the amount of delay, and therefore should be
## a variable

gameloop:

jal checkInputDelay
jal moveSnake
jal updateDispmem
j gameloop

################################################################

checkInputDelay:
addi $r1, $r0, 0			# counter starting at 0
addi $r3, $r0, 1			# compare to the current snake direction
addi $r4, $r0, 2
addi $r5, $r0, 3
addi $r6, $r0, 4

checkInputDelayLoop:
beq $r1, $r15, checkInputDelayFinish
custj1 0				# put the keyboard input value into $r29
bne $r29, $r12, checkKeyInput	# only check the keyboard input if it’s different from last time

checkInputDelayLoopCont:
addi $r1, $r1, 1
j checkInputDelayLoop

checkInputDelayFinish:
beq $r7, $r0, notCopyDirection
addi $r24, $r7, 0		# copy the temporary direction into the snake direction register

notCopyDirection:
addi $r12, $r29, 0		# store the current keyboard input into the last keyboard input reg
jr $r31

################

checkKeyInput:
beq $r29, $r25, checkUpKey
beq $r29, $r26, checkDownKey
beq $r29, $r27, checkLeftKey
beq $r29, $r28, checkRightKey
j checkInputDelayLoopCont		# if the user accidentally hits some other key, nothing to do

checkUpKey:			
beq $r24, $r3, turnNotValid		# Up key press is only valid if the current snake
beq $r24, $r4, turnNotValid 	# direction is left or right
beq $r24, $r5, upTurnValid
beq $r24, $r6, upTurnValid
j checkUpKey				# $r24 must be 1-4 so program should not reach this line

checkDownKey:			
beq $r24, $r3, turnNotValid		# Down key press is only valid if the current snake
beq $r24, $r4, turnNotValid 	# direction is left or right
beq $r24, $r5, downTurnValid
beq $r24, $r6, downTurnValid
j checkDownKey				# $r24 must be 1-4 so program should not reach this line

checkLeftKey:
beq $r24, $r3, leftTurnValid	# Left key press is only valid if the current snake
beq $r24, $r4, leftTurnValid	# direction is up or down
beq $r24, $r5, turnNotValid
beq $r24, $r6, turnNotValid
j checkLeftKey				# $r24 must be 1-4 so program should not reach this line

checkRightKey:
beq $r24, $r3, rightTurnValid	# Right key press is only valid if the current snake
beq $r24, $r4, rightTurnValid	# direction is up or down
beq $r24, $r5, turnNotValid
beq $r24, $r6, turnNotValid
j checkRightKey				# $r24 must be 1-4 so program should not reach this line

################

upTurnValid:
add $r7, $r3, $r0			# copy temporary direction into register $r7
j checkInputDelayLoopCont

downTurnValid:
add $r7, $r4, $r0
j checkInputDelayLoopCont

leftTurnValid:
add $r7, $r5, $r0
j checkInputDelayLoopCont

rightTurnValid:
add $r7, $r6, $r0
j checkInputDelayLoopCont

turnNotValid:
j checkInputDelayLoopCont

################################################################

moveSnake:
addi $r30, $r30, -1
sw $r31, 0($r30)

jal updateSnakeHeadPos	# update snake head x, y, location
jal collisionDetection	# check if the new head location is part of the snake or the food
					# if part of the snake, game over; if food, snake length ++
beq $r13, $r0, subtractOne 	# previously “jal subtractOne”	

moveSnakeCont:
jal placeNewHead			# placing the new head at the updated Snake Head pos
					# after subtractOne so that the head can be distinguished
					# from the food
lw $r31, 0($r30)
addi $r30, $r30, 1
jr $r31

################

updateSnakeHeadPos:
# $r20: snake head location
# $r21: snake head x
# $r22: snake head y
# $r24: snake direction

## some constants that are needed
addi $r1, $r0, 1			
addi $r2, $r0, 2
addi $r3, $r0, 3
addi $r4, $r0, 4
addi $r5, $r0, 19
addi $r6, $r0, 14

## four cases
beq $r24, $r1, goingUp
beq $r24, $r2, goingDown
beq $r24, $r3, goingLeft
beq $r24, $r4, goingRight

updateComplete:

jr $r31


goingUp:
beq $r22, $r0, goingUpTopRow	# filter out cases where the snake head is on the 0th row
addi $r20, $r20, -20		# location = location - 20
addi $r22, $r22, -1		# y = y - 1
j updateComplete

goingDown:
beq $r22, $r6, goingDownBottomRow	# filter out cases where the snake head is on the 14th row
addi $r20, $r20, 20		# location = location + 20
addi $r22, $r22, 1		# y = y + 1
j updateComplete

goingLeft:
beq $r21, $r0, goingLeftLeftCol	# filter out cases where the head is on the left most col
addi $r20, $r20, -1		# location = location - 1
addi $r21, $r21, -1		# x = x - 1
j updateComplete

goingRight:
beq $r21, $r5, goingRightRightCol	# filter out cases where the head is on the right most col
addi $r20, $r20, +1		# location = location + 1
addi $r21, $r21, +1		# x = x + 1
j updateComplete


goingUpTopRow:
addi $r20, $r20, 280		# location = location + 280
addi $r22, $r22, 14		# y = y + 14
j updateComplete

goingDownBottomRow:
addi $r20, $r20, -280		# location = location - 280
addi $r22, $r22, -14		# y = y - 14
j updateComplete

goingLeftLeftCol:
addi $r20, $r20, 19		# location = location + 19
addi $r21, $r21, 19		# x = x + 19
j updateComplete

goingRightRightCol:
addi $r20, $r20, -19		# location = location - 19
addi $r21, $r21, -19		# x = x - 19
j updateComplete


################

collisionDetection:
# $r20: snake head location
# $r21: snake head x
# $r22: snake head y
# $r23: snake length

addi $r2, $r23, 1		# $r2 = snake length + 1 = food value

lw $r1, 0xA00($r20)		# load from gridmem the new head location
addi $r13, $r0, 0		# reset the flag in $r13 for subtract one
beq $r1, $r0, collisionDetectionReturn	# if the new head location has value 0, no collision
beq $r1, $r2, snakeGrowth	# if the new head location has value snake length + 1, which is a food
j gameover			# collision, game over

collisionDetectionReturn:
jr $r31

########

snakeGrowth:
addi $r30, $r30, -1		# jal to placeFood later, need to save $r31
sw $r31, 0($r30)

addi $r13, $r0, 1		# set a flag in $r13 for not subtract one
addi $r23, $r23, 1		# snake length ++
addi $r19, $r17, 0		# snake color = food color
jal placeFood

lw $r31, 0($r30)		# restore $r31
addi $r30, $r30, 1
jr $r31

########

placeFood:
# $r14: random number location

lw $r1, 0x0($r14)		# load from memory location $r14; this value might be used as the new food loc
lw $r2, 0xA00($r1)		# check if this new food loc is already occupied by part of the snake
beq $r2, $r0, placeFoodValid	# if the new loc has value 0, then the location is valid
addi $r14, $r14, 2		# if loc not valid, increment $r14 by two (skip the food color value)
j placeFood

placeFoodValid:
# $r16: food value (snake length + 1)
# $r17: food color (1-7)
# $r18: food location (000-12B)
# $r23: snake length

addi $r16, $r23, 1		# set food value to snake length + 1
addi $r18, $r1, 0		# the new food location is already stored in $r1
lw $r1, 0x1($r14)		# load the new food color into $r1, which is stored in memory right after loc
addi $r17, $r1, 0
sw $r16, 0xA00($r18)		# store the food value at food location in gridmem 

addi $r14, $r14, 2		# increment the random number counter by 2	
jr $r31

gameover:
halt

################

subtractOne:
# $r23: snake length

addi $r1, $r0, 0			# counter starting at 0
addi $r2, $r0, 0x12C		# final value of 300 (0-299)
addi $r4, $r23, 1		# current snake length + 1 = the food value

subtractOneLoop:		
beq $r1, $r2, subtractOneFinish
lw $r3, 0xA00($r1)		# load from gridmem with offset 0xA00
beq $r3, $r0, blockIsEmpty	# block is empty, do not subtract
beq $r3, $r4, blockIsFood	# the food block, do not subtract
addi $r3, $r3, -1		# otherwise, the block is part of the snake, subtract 1
sw $r3, 0xA00($r1)		# store to gridmem at offset 0xA00

subtractOneLoopCont:
addi $r1, $r1, 1
j subtractOneLoop

subtractOneFinish:
j moveSnakeCont


blockIsEmpty:
j subtractOneLoopCont

blockIsFood:
j subtractOneLoopCont

################

placeNewHead:
# $r20: snake head location
# $r23: snake length

sw $r23, 0xA00($r20)		# the snake head has the value of the snake length
jr $r31

################################################################

updateDispmem:
addi $r1, $r0, 0			# counter starting at 0
addi $r2, $r0, 0x12C		# final value of 300 (0-299)

updateDispmemLoop:		
beq $r1, $r2, updateDispmemFinish
lw $r3, 0xA00($r1)		# load from gridmem at offset 0xA00
beq $r3, $r0, drawBlank	# if the block has value zero, then write a zero (black) to dispmem
beq $r3, $r16, drawFood	# if the block has the food value, the write the food color to dispmem
j drawSnake			# otherwise, the block is part of the snake

updateDispmemLoopCont:
addi $r1, $r1, 1
j updateDispmemLoop

updateDispmemFinish:
jr $r31

################

drawBlank:
sw $r0, 0xE00($r1)
j updateDispmemLoopCont

drawFood:
sw $r17, 0xE00($r1)		# write the current food color to dispmem
j updateDispmemLoopCont

drawSnake:
sw $r19, 0xE00($r1)		# write the current snake color to dispmem
j updateDispmemLoopCont


################################################################

## Need to implement this procedure!!!
clearGrid:
addi $r1, $r0, 0			# counter starting at 0
addi $r2, $r0, 0x12C		# final value of 300 (0-299)

clearGridLoop:		
beq $r1, $r2, clearGridFinish
sw $r0, 0xA00($r1)
addi $r1, $r1, 1
j clearGridLoop

clearGridFinish:
jr $r31

################################################################

