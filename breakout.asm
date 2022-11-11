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

# Y coordinate of the paddle
PADDLE_Y:
	.word	55

##############################################################################
# Mutable Data
##############################################################################
# (x, y) coordinate of the paddle
PADDLE_X:
	.word	57

# X coordinate of the ball
BALL_X:	.word	63

# Y coordinate of the ball
BALL_Y:	.word	0

# array describing colour of each row, top downwards
BRICK_COLOURS:				# require A[0] = A.length - 1
	.word	6, 0xff0000, 0xff8000, 0xffff00, 0x00ff00, 0x0000ff, 0x8000ff

# Y coordinate of the first row of bricks
BRICKS_Y:
	.word	12			# y coordinate of top row

##############################################################################
# Code
##############################################################################
	.text
	.globl	main
	
	# Run the Brick Breaker game.
main:	lw	$t0, PADDLE_Y		# load paddle y coordinate
	addi	$t0, $t0, -1
	sw	$t0, BALL_Y		# ball initially starts on top the paddle

	lw	$t0, PADDLE_X		# load paddle x coordinate
	lw	$t1, PADDLE_Y		# load paddle y coordinate
	addi	$sp, $sp, -8
	sw	$t0, 0($sp)		# push x coordinate onto stack
	sw	$t1, 4($sp)		# push y coordinate onto stack
	jal	draw_paddle		# draw paddle in the center of the screen
	
	lw	$t0, BALL_X		# load ball x coordinate
	lw	$t1, BALL_Y		# load ball y coordinate
	addi	$sp, $sp, -8
	sw	$t0, 0($sp)		# push x coordinate onto stack
	sw	$t1, 4($sp)		# push y coordinate onto stack
	jal	draw_ball		# draw the ball on the center of the paddle
	
	lw	$t0, PADDLE_Y		# load paddle y coordinate
	addi	$sp, $sp, -4
	sw	$t0, 0($sp)		# push paddle y coordinate onto stack
	jal	draw_walls		# draw the walls around the play area
	
	lw	$t0, BRICKS_Y		# load y coordinate of first row of bricks
	la	$t1, BRICK_COLOURS	# get ptr to array describing colour of each row
	sw	$t0, 0($sp)		# push y coordinate of top row onto stack
	sw	$t1, 4($sp)		# push ptr to array of row colours onto stack
	jal	draw_bricks

game_loop:
	j	end
	# 1a. Check if key has been pressed
    	# 1b. Check which key has been pressed
	# 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
	b	game_loop
	
end:	li	$v0, 10 
	syscall				# exit program gracefully
