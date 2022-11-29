################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       4
# - Unit height in pixels:      4
# - Display width in pixels:    512
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

	.data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
	.word	0x10008000

# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
	.word	0xffff0000

.extern	SCREEN_WIDTH	32

.extern PADDLE_COLOUR	32

.extern BALL_COLOUR	32

.extern	WALL_WIDTH	32

.extern BUFFER_COLOUR	32

# (width, height)
.extern	BRICK_DIM	64

##############################################################################
# Mutable Data
##############################################################################
# (x, y) coordinates of the top left corner of the paddle
.extern	PADDLE_COORDS	64	# size of two words

# (x, y) coordinates of the ball
.extern BALL_COORDS	64	# size of two words

.extern	DIRECTION	32	# size of one word

# y coordinate of the top of the first row of bricks
.extern	BRICKS_Y	32	# size of one word
	
# 2-D array storing colour of each brick
.extern BRICKS		368			# (number of rows * number of bricks per row + 2) * bytes per word

# array describing colour of each row, from top to bottom
COLOURS:				# require A[0] = A.length - 1
	.word	6, 0xff0000, 0xff8000, 0xffff00, 0x00ff00, 0x0000ff, 0x8000ff

##############################################################################
# Code
##############################################################################
	.text
	.globl	main
	
initialize:
	li	$t0, 128
	sw	$t0, SCREEN_WIDTH	# display width in pixels divided by unit width in pixels

	li	$t0, 57
	li	$t1, 55
	sw	$t0, PADDLE_COORDS	# paddle x s.t. it is in the center of the scrren
	sw	$t1, PADDLE_COORDS+4
	
	li	$t0, 0xaaaaaa
	sw	$t0, PADDLE_COLOUR
	
	li	$t0, 57 # 63
	sw	$t0, BALL_COORDS
	lw	$t0, PADDLE_COORDS+4	# load paddle y coordinate
	addi	$t0, $t0, -1
	sw	$t0, BALL_COORDS+4	# ball initially starts on top the paddle
	
	li	$t0, 0xffffff
	sw	$t0, BALL_COLOUR
	li	$t0, 2
	sw	$t0, DIRECTION		# initially the ball goes straigt up
	
	li	$t0, 4
	sw	$t0, WALL_WIDTH
	
	li	$t0, 0xff88ff
	sw	$t0, BUFFER_COLOUR
	
	li	$t0, 8
	li	$t1, 4
	sw	$t0, BRICK_DIM
	sw	$t1, BRICK_DIM+4
	
	li	$t0, 12
	sw	$t0, BRICKS_Y

	lw	$t0, COLOURS
	li	$t1, 15
	sw	$t0, BRICKS		# store the number of bricks in BRICKS[0]
	sw	$t1, BRICKS+4		# store the number of bricks per row in BRICKS[1]
	
	# initializes the colour of each brick
	li	$t0, 0			# initialize loop variable i = 0
	lw	$t1, BRICKS
	sll	$t1, $t1, 2		# loop condition is number of rows * 4
l1:	beq	$t0, $t1, e1
	li	$t2, 0			# initialize loop variable j = 0
	lw	$t3, BRICKS+4
	sll	$t3, $t3, 2		# loop condition is number of bricks per row
l2:	beq	$t2, $t3, u1
	mulo	$t5, $t0, $t3
	sra	$t5, $t5, 2		# $t5 = $t5 // 4
	add	$t5, $t2, $t5
	addi	$t5, $t5, 8		# index of (i, j) brick in BRICKS * 4
	la	$t5, BRICKS($t5)	# pointer to (i, j) brick
	lw	$t6, COLOURS+4($t0)	# load colour of ith row
	sw	$t6, 0($t5)		# store colour of ith row in (i, j) brick
	
u2:	addi	$t2, $t2, 4		# j += 4
	j	l2

u1:	addi	$t0, $t0, 4		# i += 4
	j	l1
	
e1:	j	main	
	
	# Run the Brick Breaker game.
main:	jal	draw_paddle		# draw paddle in the center of the screen
	jal	draw_ball		# draw the ball on the center of the paddle
	jal	draw_walls		# draw the walls around the play area
	jal	draw_bricks	


game_loop:
	# 1a. Check if key has been pressed
    	# 1b. Check which key has been pressed
    	# jal get_key
    	# j press_a
    	# j press_d
    	
	# 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	jal	check_collision
    	jal	update_ball
	
	# 4. Sleep
	li	$v0, 32
	li	$a0, 20		# add 1/3 ms delay
	syscall

    	#5. Go back to 1
	b	game_loop

end:	li	$v0, 10 
	syscall				# exit program gracefully

press_a:
	lw	$a0, PADDLE_COORDS	# load paddle coordinates
	addi	$t1, $a0, -1		# create new paddle position (2 units left)  
	  
	addi	$sp, $sp, -4
	sw	$t1, 0($sp)
	jal left_paddle_col
	
	# delete previous paddle
	la	$t0, PADDLE_COORDS	# load paddle coordinate address
	addi	$sp, $sp, -4		# allocate memory
	sw	$t0, 0($sp)		# push x coordinate onto stack
	jal	delete_paddle		# delete paddle (paint past paddle position black)
	
	# move paddle left (new position)
	lw	$a0, PADDLE_COORDS	# load paddle coordinates
	addi	$t1, $a0, -1		# create new paddle position (2 units left)  
	la	$a0, PADDLE_COORDS	# load paddle coordinate address
	sw	$t1, 0($a0)		# save new x coordinate
	
	# draw paddle		
	la	$t0, PADDLE_COORDS	# load paddle address
	addi	$sp, $sp, -4		# allocate memory
	sw	$t0, 0($sp)		# push x coordinate onto stack
	jal	draw_paddle		# draw new paddle (in new position)
	
	b game_loop	

press_d:
	lw	$a0, PADDLE_COORDS	# load paddle coordinates
	addi	$t1, $a0, 1		# create new paddle position (2 units left) 
	  
	addi	$sp, $sp, -4
	sw	$t1, 0($sp)
	jal right_paddle_col

	# delete previous paddle
	la	$t0, PADDLE_COORDS	# load paddle coordinate address
	addi	$sp, $sp, -4		# allocate memory
	sw	$t0, 0($sp)		# push x coordinate onto stack
	jal	delete_paddle		# delete paddle (paint past paddle position black)
	
	# move paddle right
	lw	$a0, PADDLE_COORDS	# load paddle coordinates
	addi	$t1, $a0, 1		# create new paddle position (2 units left)  
	la	$a0, PADDLE_COORDS	# load paddle coordinate address
	sw	$t1, 0($a0)		# save new x coordinate
	
	# draw paddle		
	la	$t0, PADDLE_COORDS	# load paddle address
	addi	$sp, $sp, -4		# allocate memory
	sw	$t0, 0($sp)		# push x coordinate onto stack
	jal	draw_paddle		# draw new paddle (in new position)
	
	b game_loop
	
left_paddle_col:
	lw	$t0, 0($sp)			# load next paddle position
	
	li	$t1, 4				# load left wall boundary
	
	addi	$sp, $sp, -4			# allocate memory
	sw	$ra, 0($sp)			# push return address onto stack
	
	bge	$t0, $t1, valid_col_check	# left wall check
	
	# j check_key

right_paddle_col:
	lw	$t0, 0($sp)			# load next paddle position
		
	li	$t1, 111			# load right wall boundary
	
	addi	$sp, $sp, -4			# allocate memory
	sw	$ra, 0($sp)			# push return address onto stack
	
	ble	$t0, $t1, valid_col_check	# right wall check
	
	# j check_key

valid_col_check:
	lw	$ra, 0($sp)		# load return address from stack
	addi	$sp, $sp, 4
	jr	$ra			# return
