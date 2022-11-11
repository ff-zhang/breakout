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

PADDLE_Y:
	.word	59

##############################################################################
# Mutable Data
##############################################################################
PADDLE_X:
	.word	57
	
BALL_X:	.word	63

BALL_Y:	.word	58

##############################################################################
# Code
##############################################################################
	.text
	.globl	main

	# Run the Brick Breaker game.
main:	lw	$t0, PADDLE_X
	lw	$t1, PADDLE_Y
	addi	$sp, $sp, -8
	sw	$t0, 0($sp)		# push x coordinate onto stack
	sw	$t1, 4($sp)		# push y coordinate onto stack
	jal	draw_paddle
	
	lw	$t0, BALL_X
	lw	$t1, BALL_Y
	addi	$sp, $sp, -8
	sw	$t0, 0($sp)		# push x coordinate onto stack
	sw	$t1, 4($sp)		# push y coordinate onto stack
	jal	draw_ball
	
	lw	$t0, PADDLE_X
	addi	$sp, $sp, -4
	sw	$t0, 0($sp)		# push paddle y coordinate onto stack
	jal	draw_walls
	
	# jal	draw_bricks

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
	
end:
