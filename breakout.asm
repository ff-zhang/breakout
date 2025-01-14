################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Felix Zhang, 1007650212
# Student 2: Janssen Myer Rambaud, 1008107004
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
.extern	PADDLE_COORDS	64	# size of 2 words

# (x, y) coordinates of the ball
.extern BALL_COORDS	64	# size of two words

.extern	DIRECTION	32	# size of 1 word

# y coordinate of the top of the first row of bricks
.extern	BRICKS_Y	32	# size of 1 word
	
# 2-D array storing colour of each brick
#.extern BRICKS		368			# (number of rows * number of bricks per row + 2) * bytes per word
.extern BRICKS		64

# array describing colour of each row, from top to bottom
.extern	COLOURS		224	# size of 7 words (1 for array length, 6 for elements)
# COLOURS:				# require A[0] = A.length - 1
#	.word	6, 0xff0000, 0xff8000, 0xffff00, 0x00ff00, 0x0000ff, 0x8000ff

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
	
	li	$t0, 63
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
	
	li	$t0, 6
	sw	$t0, COLOURS
	li	$t1, 0xff0000
	sw	$t1, COLOURS+4
	li	$t2, 0xff8000
	sw	$t2, COLOURS+8
	li	$t3, 0xffff00
	sw	$t3, COLOURS+12
	li	$t4, 0x00ff00
	sw	$t4, COLOURS+16
	li	$t5, 0x0000ff
	sw	$t5, COLOURS+20
	li	$t6, 0x8000ff
	sw	$t6, COLOURS+24

	lw	$t0, COLOURS
	sw	$t0, BRICKS		# store the number of bricks in BRICKS[0]
	li	$t1, 15
	sw	$t1, BRICKS+4		# store the number of bricks per row in BRICKS[1]
	j	main	
	
	# Run the Brick Breaker game.
main:	jal	draw_paddle		# draw paddle in the center of the screen
	jal	draw_ball		# draw the ball on the center of the paddle
	jal	draw_walls		# draw the walls around the play area
	jal	draw_bricks	


game_loop:
	# 1a. Check if key has been pressed
    	# 1b. Check which key has been pressed
    	jal	get_key			# returns key pressed which we leave on the stack
    	
	# 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	jal	update_paddle
	jal	check_collision
    	jal	update_ball
	
	# 4. Sleep
	li	$v0, 32
	li	$a0, 40		# add 2/3 ms delay
	syscall

    	#5. Go back to 1
	b	game_loop

end:	li	$v0, 10 
	syscall				# exit program gracefully
