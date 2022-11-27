################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: , Student Number
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
	
SCREEN_WIDTH:
	.word	128		# display width in pixels divided by unit width in pixels
	
PADDLE_DIM:
	.word	13, 1
	
WALL_WIDTH:
	.word	4
	
BUFFER_HEIGHT:
	.word	5

# (width, height)
BRICK_DIM:
	.word	8, 4

##############################################################################
# Mutable Data
##############################################################################
# (x, y) coordinates of the top left corner of the paddle
PADDLE_COORDS:
	.word	57, 55

# (x, y) coordinates of the ball
BALL_COORDS:
	.word	63, 0
	
# 2-D array storing colour of each brick
BRICKS:	.space	368			# (number of rows * number of bricks per row + 2) * bytes per word

# array describing colour of each row, from top to bottom
COLOURS:				# require A[0] = A.length - 1
	.word	6, 0xff0000, 0xff8000, 0xffff00, 0x00ff00, 0x0000ff, 0x8000ff

# y coordinate of the top of the first row of bricks
BRICKS_Y:
	.word	12			# y coordinate of top row

##############################################################################
# Code
##############################################################################
	.text
	.globl	main
	
	# Run the Brick Breaker game.
main:	lw	$t0, COLOURS
	sw	$t0, BRICKS		# store number of rows in BRICKS[0]
	li	$t0, 15
	sw	$t0, BRICKS+4		# store number of bricks per row in BRICKS[1]
	
	li	$t0, 0			# initialize loop variable i = 0
	lw	$t1, BRICKS
	sll	$t1, $t1, 2		# loop condition is number of rows * 4
l1:	beq	$t0, $t1, draw
	li	$t2, 0			# initialize loop variable j = 0
	lw	$t3, BRICKS+4
	sll	$t3, $t3, 2		# loop condition is number of bricks per row

l2:	beq	$t2, $t3, u1
	mulo	$t5, $t0, $t3
	srl	$t5, $t5, 2		# $t5 = $t5 // 4
	add	$t5, $t2, $t5
	addi	$t5, $t5, 8		# index of (i, j) brick in BRICKS * 4
	la	$t5, BRICKS($t5)	# pointer to (i, j) brick
	lw	$t6, COLOURS+4($t0)	# load colour of ith row
	sw	$t6, 0($t5)		# store colour of ith row in (i, j) brick
u2:	addi	$t2, $t2, 4		# j += 4
	j	l2

u1:	addi	$t0, $t0, 4		# i += 4
	j	l1

draw:	lw	$t0, PADDLE_COORDS+4	# load paddle y coordinate
	addi	$t0, $t0, -1
	sw	$t0, BALL_COORDS+4	# ball initially starts on top the paddle

	la	$t0, PADDLE_COORDS	# ptr to paddle coordinates
	addi	$sp, $sp, -4
	sw	$t0, 0($sp)		# push paddle coordinates onto stack
	jal	draw_paddle		# draw paddle in the center of the screen
	
	la	$t0, BALL_COORDS	# ptr to ball coordinates
	addi	$sp, $sp, -4
	sw	$t0, 0($sp)		# push ptr to ball coordinates onto stack
	jal	draw_ball		# draw the ball on the center of the paddle
	
	lw	$t0, PADDLE_COORDS+4	# load paddle y coordinate
	addi	$sp, $sp, -4
	sw	$t0, 0($sp)		# push paddle y coordinate onto stack
	jal	draw_walls		# draw the walls around the play area
	
	lw	$t0, BRICKS_Y		# load y coordinate of first row of bricks
	la	$t1, BRICKS		# get ptr to array describing colour of each brick
	sw	$t0, 0($sp)		# push y coordinate of top row onto stack
	sw	$t1, 4($sp)		# push ptr to array of colours onto stack
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
	
##############################################################################
# DRAW FUNCTIONS
##############################################################################

# parameters
#	coords - pointer to the (x, y) coordinate of the top left corner of the paddle
draw_paddle:
	lw	$a0, 0($sp)		# ptr to paddle coordinates
	addi	$sp, $sp, 4
	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	li	$t0, 0xaaaaaa		# set paddle colour
	lw	$t1, 0($a0)		# load paddle x coordinate
	lw	$t2, 4($a0)		# load paddle y coordinate
	lw	$t3, PADDLE_DIM		# load paddle width
	lw	$t4, PADDLE_DIM+4	# load paddle height
	
	addi	$sp, $sp, -20
	sw	$t0, 0($sp)		# push colour onto stack
	sw	$t1, 4($sp)		# push x coordinate onto stack
	sw	$t2, 8($sp)		# push y coordinate onto stack
	sw	$t3, 12($sp)		# push width onto stack
	sw	$t4, 16($sp)		# push height onto stack
	jal	draw_rectangle		# draw paddle at (x, y)
	
	lw	$ra, 0($sp)		# load return address from stack
	addi	$sp, $sp, 4
	jr	$ra			# return

# parameters
#	coords - pointer to the (x, y) coordinate of the ball
draw_ball:
	lw	$a1, 0($sp)		# ptr to ball coordinates
	lw	$a0, 0($a1)		# load ball x coordinate
	lw	$a1, 4($a1)		# load ball y coordinate
	addi	$sp, $sp, 8
	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	li	$t0, 0xffffff		# set ball colour
	li	$t1, 1			# set ball width and height
	
	addi	$sp, $sp, -20
	sw	$t0, 0($sp)		# push colour onto stack
	sw	$a0, 4($sp)		# push x coordinate onto stack
	sw	$a1, 8($sp)		# push y coordinate onto stack
	sw	$t1, 12($sp)		# push width onto stack
	sw	$t1, 16($sp)		# push height onto stack
	jal	draw_rectangle		# draw ball at (x, y)
	
	lw	$ra, 0($sp)		# load return address from stack
	addi	$sp, $sp, 4
	jr	$ra			# return

# parameters
#	y coordinate of the paddle (used to draw the coloured boundaries)
draw_walls:
	lw	$a0, 0($sp)		# pop paddle y coordinate from stack
	addi	$sp, $sp, 4
	
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	sw	$s2, 12($sp)		# push old $s2 value on stack
	
	li	$s0, 0xaaaaaa		# set wall colour
	lw	$s1, WALL_WIDTH		# load wall width
	addi	$s2, $a0, -2		# set side wall height = paddle y - 2
	
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push wall colour onto stack
	sw	$zero, 4($sp)		# push left wall x coordinate onto stack
	sw	$zero, 8($sp)		# push left wall y coordinate onto stack
	sw	$s1, 12($sp)		# push wall width onto stack
	sw	$s2, 16($sp)		# push side wall height onto stack
	jal	draw_rectangle		# draw left wall
	
	lw	$t0, SCREEN_WIDTH	# load screen width
	sub	$t0, $t0, $s1		# set right wall y coordinate = screen width - wall width
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push wall colour onto stack
	sw	$t0, 4($sp)		# push right wall x coordinate onto stack
	sw	$zero, 8($sp)		# push right wall y coordinate onto stack
	sw	$s1, 12($sp)		# push wall width onto stack
	sw	$s2, 16($sp)		# push side wall height onto stack
	jal	draw_rectangle		# draw right wall
	
	lw	$t0, SCREEN_WIDTH	# set ceiling width = screen width
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push wall colour onto stack
	sw	$zero, 4($sp)		# push ceiling x coordinate onto stack
	sw	$zero, 8($sp)		# push ceiling y coordinate onto stack
	sw	$t0, 12($sp)		# push ceiling width onto stack
	sw	$s1, 16($sp)		# push ceiling height = wall width onto stack
	jal	draw_rectangle		# draw ceiling

	li	$s0, 0xff88ff		# set buffer colour
	
	lw	$t2, BUFFER_HEIGHT	# load buffer height
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push buffer colour onto stack
	sw	$zero, 4($sp)		# push left wall x coordinate onto stack
	sw	$s2, 8($sp)		# push left buffer y coordinate onto stack
	sw	$s1, 12($sp)		# push wall width onto stack
	sw	$t2, 16($sp)		# push buffer height onto stack
	jal	draw_rectangle		# draw left buffer
	
	lw	$t0, SCREEN_WIDTH	# load screen width
	sub	$t0, $t0, $s1		# set right buffer y coordinate = right wall y coordinate
	lw	$t1, BUFFER_HEIGHT	# load buffer height
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push buffer colour onto stack
	sw	$t0, 4($sp)		# push right wall x coordinate onto stack
	sw	$s2, 8($sp)		# push right buffer y coordinate onto stack
	sw	$s1, 12($sp)		# push wall width onto stack
	sw	$t1, 16($sp)		# push buffer height onto stack
	jal	draw_rectangle		# draw right buffer
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	lw	$s2, 12($sp)		# pop old $s2 value from stack
	addi	$sp, $sp, 16
	jr	$ra			# return


# parameters
#	y - y coordinate of the top of the first row of bricks
#	colours - pointer to array of row colours, ordered top to bottom
draw_bricks:
	lw	$a0, 0($sp)		# pop y coordinate of top row from stack
	lw	$a1, 4($sp)		# pop ptr to array of colours from stack
	addi	$sp, $sp, 8
	
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	sw	$s2, 12($sp)		# push old $s2 value on stack
	
	add	$s0, $zero, $a0		# store y coordinate of top row
	add	$s1, $a1, 8		# ptr to first brick colour element of array
	li	$s2, 0			# initialize loop variable k = 0
l02:	lw	$t8, -8($s1)		# load number of rows
	lw	$t9, -4($s1)		# load number of bricks per row
	mulo	$t0, $t8, $t9		# loop condition = number of elements
	beq	$s2, $t0, n2
	
	sll	$t0, $s2, 2		# i * 4
	add	$t0, $s1, $t0		# ptr to ith element of array
	lw	$t0, 0($t0)		# load colour of brick
	rem	$t1, $s2, $t9
	div	$t2, $s2, $t9		# ($t1, $t2) = (i, j) location of k in 2-D array

	lw	$t7, WALL_WIDTH		# load wall width
	lw	$t8, BRICK_DIM		# load brick width
	lw	$t9, BRICK_DIM+4	# load brick height
	
	mulo	$t1, $t1, $t8
	add	$t1, $t1, $t7		# x coordinate of (i, j) brick
	mulo	$t2, $t2, $t9
	add	$t2, $t2, $s0		# y coordinate of (i, j) brick
	
	addi	$sp, $sp, -12
	sw	$t0, 0($sp)		# push brick colour onto stack
	sw	$t1, 4($sp)		# push x coordinate onto stack
	sw	$t2, 8($sp)		# push y coordinate onto stack
	jal	draw_brick

u02:	addi	$s2, $s2, 1		# k++
	j	l02

n2:	lw	$ra, 0($sp)		# pop return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	lw	$s2, 12($sp)		# pop old $s2 value on stack
	addi	$sp, $sp, 16
	jr	$ra			# return

# parameters
#	colour - colour of the brick to draw
#	x - x coordinate of the top left corner of the brick
#	y - y coordinate of the top left corner of the brick
draw_brick:
	lw	$a0, 0($sp)		# pop brick colour from stack
	lw	$a1, 4($sp)		# pop x from stack
	lw	$a2, 8($sp)		# pop y from stack
	addi	$sp, $sp, 12
	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	lw	$t0, BRICK_DIM		# load brick width
	lw	$t1, BRICK_DIM+4	# load brick height
	
	addi	$sp, $sp, -20
	sw	$a0, 0($sp)		# push brick colour on stack
	sw	$a1, 4($sp)		# push x coordinate onto stack
	sw	$a2, 8($sp)		# push y coordinate onto stack
	sw	$t0, 12($sp)		# push width onto stack
	sw	$t1, 16($sp)		# push height onto stack
	jal	draw_rectangle		# draw brick at (x, y)
	
	lw	$ra, 0($sp)		# pop return address from stack
	addi	$sp, $sp, 4
	
	jr	$ra			# return

# parameters
#	colour - colour of the rectangle to draw
#	x - x coordinate of the top left corner of the brick
#	y - y coordinate of the top left corner of the brick
#	width - the width of the rectangle
#	height - the height of the rectangle
draw_rectangle:
	lw 	$a0, 0($sp)		# pop colour from stack
	lw	$t0, 4($sp)		# pop x from stack
	lw	$t1, 8($sp)		# pop y from stack
	mulo	$t1, $t1, 128		# set leftmost pixel of row y
	add	$a1, $t0, $t1		# set position of pixel (x, y)
	lw	$a2, 12($sp)		# load width of rectangle
	lw	$a3, 16($sp)		# load height of rectangle
	addi	$sp, $sp, 20
	
	lw	$t8, SCREEN_WIDTH	# load screen width
	lw	$t9, ADDR_DSPL		# load ptr to display memory location
	
	add	$t0, $zero, $zero	# initialize loop variable i = 0
	mulo	$t1, $a2, $a3		# set loop condition = number of pixels in the rectangle
l01:	beq	$t0, $t1, n1
	rem	$t2, $t0, $a2		# calulate x offset
	div	$t3, $t0, $a2		# calculate y offset
	mulo	$t3, $t3, $t8		# calculate leftmost pixel of row y
	
	add	$t2, $t2, $t3		# calculate distance from pixel (x, y) to pixel (x offset, y offset)
	add	$t2, $a1, $t2		# calculate position of pixel (x', y') = (x, y) + (x offset, y offset)
	mulo	$t2, $t2, 4		# calculate distnace memory address of pixel (x, y) to that of (x', y')
	add	$t2, $t2, $t9		# set ptr to memory address of pixel (x', y')
	sw	$a0, 0($t2)		# store colour at memory address of pixel (x', y')
	
u01:	addi	$t0, $t0, 1		# i++
	j	l01

n1:	jr	$ra			# return
