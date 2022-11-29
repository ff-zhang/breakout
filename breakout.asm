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

SCREEN_WIDTH:
	.word	128

PADDLE_DIM:
	.word	13, 1

WALL_WIDTH:
	.word	4

# x coordinates of the left and right wall (left wall x, right wall x) for paddle collisions
WALLS_X:
	.word	4, 111

BUFFER_HEIGHT:
	.word	5

BUFFER_COLOUR:
	.word	0xff88ff

# y coordinate of the top of the first row of bricks
BRICKS_Y:
	.word	12
	
BRICKS:	.word	6, 15			# require BRICKS[0] = COLOURS[0]

# (width, height)
BRICK_DIM:
	.word	8, 4

# array describing colour of each row, from top to bottom
COLOURS:				# require A[0] = A.length - 1
	.word	6, 0xff0000, 0xff8000, 0xffff00, 0x00ff00, 0x0000ff, 0x8000ff

##############################################################################
# Mutable Data
##############################################################################
PADDLE_COLOUR:
	.word	0xaaaaaa

BALL_COLOUR:
	.word	0xffffff

# (x, y) coordinates of the top left corner of the paddle
PADDLE_COORDS:
	.word	57, 55		# paddle x s.t. it is in the center of the scrren

# (x, y) coordinates of the ball
BALL_COORDS:
	.word	63, 54		# initlaly, BALL_COORDS[1} = PADDLE_COORDS[1] - 1 so the ball starts on top of paddle

DIRECTION:
	.word	2		# initially the ball goes straigt up

##############################################################################
# Code
##############################################################################
	.text
	.globl	main
	
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


# function
get_key:		
	lw 	$t9, ADDR_KBRD		# $t0 = base address for keyboard
    	lw 	$t4, 0($t9)		# load first word from keyboard
    	beqz 	$t4, n1			# if first word is 0, key was not pressed

key_in:	lw 	$a0, 4($t9)		# load input letter
	beq 	$a0, 0x78, end		# exit when x pressed
	beq 	$a0, 0x71, end		# exit when q pressed
	
n1:	addi	$sp, $sp, -4
	sw	$a0, 0($sp)		# return key pressed
    	jr	$ra
    	

# function
update_paddle:
	sw	$a0, 0($sp)		# return key pressed
	sw	$ra, 0($sp)		# overwrite it with return address
	
	beq 	$a0, 0x61, key_a	# move paddle left
	beq 	$a0, 0x64, key_d	# move paddle right
	j	e3

key_a:	jal	delete_paddle		# delete current paddle (paint past paddle position black)

	lw	$a0, PADDLE_COORDS	# load paddle x coordinate
	addi	$t0, $a0, -4		# create new paddle position (4 units left)  
	
left_paddle_collision:
	lw	$t1, WALLS_X		# load left wall boundary
	bge	$t0, $t1, next
	move	$t0, $t1		# next paddle position inside wall
	j	next

key_d:	jal	delete_paddle		# delete current paddle (paint past paddle position black)

	lw	$a0, PADDLE_COORDS	# load paddle x coordinate
	addi	$t0, $a0, 4		# create new paddle position (4 units right) 

right_paddle_collision:
	lw	$t1, WALLS_X+4		# load right wall boundary
	ble	$t0, $t1, next
	move	$t0, $t1		# next paddle position inside wall

next:	sw	$t0, PADDLE_COORDS	# move paddle by saving new x coordinate
	jal	draw_paddle		# draw new paddle in new position
	j	e3
	
e3:	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra


# function
check_collision:
# updates the direction if the ball would collide with another object
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	
	addi	$sp, $sp, -8
	lw	$a0, BALL_COORDS	# load x coordinate of ball
	sw	$a0, 0($sp)
	lw	$a1, BALL_COORDS+4	# load y coordinate of ball
	sw	$a1, 4($sp)
	jal	get_pixel_address
	lw	$s3, 0($sp)		# get memory address of current pixel
	addi	$sp, $sp, 4
	
check:	jal	next_location
	lw	$s0, 0($sp)		# save predicted x coordinate
	lw	$s1, 4($sp)		# save predicted y coordinate
	
	bge	$s1, 64, end		# end if ball is off screen (screen height is 64)
	
	# next_location returns (x, y) on the stack but we can immideatly pass it to get_pixel_address
	jal	get_pixel_address
	lw	$t0, 0($sp)		# get memory address of predicted pixel
	addi	$sp, $sp, 4
	lw	$t1, 0($t0)		# get colour of predicted pixel
	lw	$t8, SCREEN_WIDTH
	lw	$t9, DIRECTION
	
	beqz	$t1, return
	# if predicted pixel is not black
	bltz	$t9, else1
		# if direction up (positive)
		sll	$t2, $t8, 2
		sub	$t2, $s3, $t2		# $s3 - (4 * DISPLAY_WIDTH) address of pixel above current location
		lw	$t3, 0($t2)		# get colour of pixel above current location
		addi	$t4, $s3, 4		# $s3 + 4 address of pixel to right of current location
		lw	$t5, 0($t4)		# get colour of pixel to right of current location
		
		beqz	$t3, else2a
			# if pixel above current location is not black (bounce off bottom)
		case1a:	bne	$t9, 1, case1b		# check if moving NW
			li	$t0, -3			# start moving SW
			sw	$t0, DIRECTION
			j	dflt

		case1b:	bne	$t9, 2, case1c		# check if moving N
			li	$t0, -2			# start moving S
			sw	$t0, DIRECTION
			j	dflt

		case1c:	bne	$t9, 3, dflt		# check if moving NE
			li	$t0, -1			# start moving SE
			sw	$t0, DIRECTION
			j	dflt
		
		# pixel above current location is black (bounce off side)
	else2a:	beqz	$t5, else2b
		# pixel to right is not black (bounce off left side) => moving NW
		li	$t0, 1			# start moving NE
		sw	$t0, DIRECTION
		j	dflt
		
		# pixel to right is black => pixel to left is not black (bounce of right side) => moving NE
	else2b:	li	$t0, 3			# start moving NW
		sw	$t0, DIRECTION
		j	dflt
	
	# direction down
else1:	lw	$t7, PADDLE_COORDS+4
	beq	$s1, $t7, paddle
	
		# collide with non-paddle object
		sll	$t2, $t8, 2
		# recall $t0 is memory address of predicted pixel
		add	$t2, $s3, $t2		# $s3 + (4 * DISPLAY_WIDTH) address of pixel below current location
		lw	$t3, 0($t2)		# get colour of pixel below current location
		addi	$t4, $s3, 4		# $s3 + 4 address of pixel to right of current location
		lw	$t5, 0($t4)		# get colour of pixel to right of current location
		
		beqz	$t3, else1a
			# if pixel below current location is not black (bounce off top)
		case2a:	bne	$t9, -3, case2b		# check if moving SW
			li	$t0, 1			# start moving NW
			sw	$t0, DIRECTION
			j	dflt

		case2b:	bne	$t9, -2, case2c		# check if moving S
			li	$t0, 2			# start moving N
			sw	$t0, DIRECTION
			j	dflt

		case2c:	bne	$t9, -1, dflt		# check if moving SE
			li	$t0, 3			# start moving NE
			sw	$t0, DIRECTION
			j	dflt
		
		# pixel below current location is black (bounce off side)
	else1a:	beqz	$t5, else1b
		# pixel to right is not black (bounce off right side) => moving SE
		li	$t0, -3			# start moving SW
		sw	$t0, DIRECTION
		j	dflt
		
		# pixel to right is black => pixel to left is not black (bounce of left side) => moving SW
	else1b:	li	$t0, -1			# start moving SE
		sw	$t0, DIRECTION
		j	dflt

	# collide with paddle
paddle:	lw	$t6, PADDLE_COORDS		# load x coordinate of paddle
	# recall $s0 is the predicted x coordinate
case3a:	addi	$t7, $t6, 5
	bgt	$s0, $t7, case3b
	# hit left third of paddle
	li	$t0, 1
	sw	$t0, DIRECTION
	j	dflt

case3b: addi	$t7, $t6, 8
	blt	$s0, $t7, case3c
	# hit right third of paddle
	li	$t0, 3
	sw	$t0, DIRECTION
	j	dflt
	
	# hit center of paddle
case3c:	li	$t0, 2
	sw	$t0, DIRECTION
	j	dflt

dflt:	lw	$t0, PADDLE_COLOUR
	beq	$t0, $t1, return	# predicted colour != wall / paddle colour
	lw	$t0, BUFFER_COLOUR
	beq	$t0, $t1, return	# predicted colour != buffer colour
	
c2:	lw	$t0, WALL_WIDTH
	sub	$s0, $s0, $t0		# get predicted x offset from left wall
	lw	$t0, BRICKS_Y
	sub	$s1, $s1, $t0		# get predicted y offset from top left corner of bricks
	
	lw	$t0, BRICK_DIM
	lw	$t1, BRICK_DIM+4
	div	$s0, $s0, $t0
	div	$s1, $s1, $t1		# calculate position (i, j) of brick in array that ball collided with
	
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	sw	$s1, 4($sp)
	jal	delete_brick
	
	j	return
	
return:	jal	next_location
	jal	get_pixel_address
	lw	$t0, 0($sp)		# get memory address of predicted pixel
	addi	$sp, $sp, 4
	lw	$t1, 0($t0)		# get colour of predicted pixel
	bnez	$t1, check
	
	lw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	addi	$sp, $sp, 16
	jr	$ra


# function
update_ball:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack

	jal 	delete_ball
	
	jal	next_location
	lw	$t1, 0($sp)
	lw	$t2, 4($sp)
	addi	$sp, $sp, 8
	
	sw	$t1, BALL_COORDS
	sw	$t2, BALL_COORDS+4
	
	jal 	draw_ball
	
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra


# function
next_location:
	lw	$a0, DIRECTION
	
	lw	$t1, BALL_COORDS	# load x coordinate of ball
	lw	$t2, BALL_COORDS+4	# load y coordinate of ball
	
	beq	$a0, -3, move_SW
	beq	$a0, -2, move_S
	beq	$a0, -1, move_SE
	beq	$a0, 1, move_NW		# ball goes northwest
	beq	$a0, 2, move_N		# ball goes straight up
	beq	$a0, 3, move_NE		# ball goes northeast
	
move_SW:
	addi	$t1, $t1, -1		# decrease x coordinate by 1 (ball goes left)
	addi	$t2, $t2, 1		# decrease y coordinate by 1 (ball goes up)
	j	c1

move_S:	addi	$t2, $t2, 1
	j	c1

move_SE:
	addi	$t1, $t1, 1		# decrease x coordinate by 1 (ball goes right)
	addi	$t2, $t2, 1		# decrease y coordinate by 1 (ball goes up)
	j	c1

move_NW:
	addi	$t1, $t1, -1		# decrease x coordinate by 1 (ball goes left)
	addi	$t2, $t2, -1		# decrease y coordinate by 1 (ball goes up)
	j	c1

move_N:	addi	$t2, $t2, -1		# decrease y coordinate by 1 (ball goes up)
	j	c1
	
move_NE:
	addi	$t1, $t1, 1		# decrease x coordinate by 1 (ball goes right)
	addi	$t2, $t2, -1		# decrease y coordinate by 1 (ball goes up)
	j	c1
	
c1:	addi	$sp, $sp, -8
	sw	$t1, 0($sp)
	sw	$t2, 4($sp)
	
	jr	$ra
	
	
# parameters
#	coords - pointer to the (x, y) coordinate of the top left corner of the paddle
draw_paddle:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	lw	$t0, PADDLE_COLOUR	# load paddle colour
	lw	$t1, PADDLE_COORDS	# load paddle x coordinate
	lw	$t2, PADDLE_COORDS+4	# load paddle y coordinate
	lw	$t3, PADDLE_DIM		# load paddle width
	lw	$t4, PADDLE_DIM+4	# load paddle height
	
	addi	$sp, $sp, -4
	sw	$t0, 0($sp)		# push colour onto stack
	move	$a0, $t1
	move	$a1, $t2
	move	$a2, $t3
	move	$a3, $t4
	jal	draw_rectangle		# draw paddle at (x, y)
	
	li	$t0, 0xaaaaaa
	sw	$t0, PADDLE_COLOUR
	
	lw	$ra, 0($sp)		# load return address from stack
	addi	$sp, $sp, 4
	jr	$ra			# return


# parameters
#	coords - pointer to the (x, y) coordinate of the top left corner of the paddle
delete_paddle:				# same thing as draw_paddle but colour is black
	addi	$sp, $sp, -8
	sw	$ra, 0($sp)		# push return address onto stack
	lw	$t0, PADDLE_COLOUR
	sw	$t0, 4($sp)		# push paddle colour onto stack
	
	li	$t0, 0
	sw	$t0, PADDLE_COLOUR
	jal	draw_paddle		# colour the paddle black
	
	lw	$ra, 0($sp)		# load return address from stack
	addi	$sp, $sp, 8
	jr	$ra			# return


# parameters
#	coords - pointer to the (x, y) coordinate of the ball
draw_ball:
	lw	$t8, BALL_COORDS	# load ball x coordinate
	lw	$t9, BALL_COORDS+4	# load ball y coordinate
	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	lw	$t0, BALL_COLOUR	# load ball colour
	li	$t1, 1			# set ball width and height
	
	addi	$sp, $sp, -4
	sw	$t0, 0($sp)		# push colour onto stack
	move	$a0, $t8
	move	$a1, $t9
	move	$a2, $t1
	move	$a3, $t1
	jal	draw_rectangle		# draw ball at (x, y)
	
	lw	$ra, 0($sp)		# load return address from stack
	addi	$sp, $sp, 4
	jr	$ra			# return


# parameters
#	coords - pointer to the (x, y) coordinate of the ball
delete_ball:
	addi	$sp, $sp, -8
	sw	$ra, 0($sp)		# push return address onto stack
	lw	$t0, BALL_COLOUR
	sw	$t0, 4($sp)		# push ball colour onto stack
	
	li	$t0, 0
	sw	$t0, BALL_COLOUR
	jal	draw_ball		# colour the ball black
	
	lw	$ra, 0($sp)		# load return address from stack
	lw	$t0, 4($sp)
	sw	$t0, BALL_COLOUR	# restore original ball colour
	addi	$sp, $sp, 8
	jr	$ra			# return


# parameters
#	y coordinate of the paddle (used to draw the coloured boundaries)
draw_walls:
	lw	$a0, PADDLE_COORDS+4	# get paddle y coordinate
	
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	sw	$s2, 12($sp)		# push old $s2 value on stack
	
	li	$s0, 0xaaaaaa		# set wall colour
	lw	$s1, WALL_WIDTH		# load wall width
	addi	$s2, $a0, -2		# set side wall height = paddle y - 2
	
	addi	$sp, $sp, -4
	sw	$s0, 0($sp)		# push wall colour onto stack
	move	$a0, $zero
	move	$a1, $zero
	move	$a2, $s1
	move	$a3, $s2
	jal	draw_rectangle		# draw left wall
	
	lw	$t0, SCREEN_WIDTH	# load screen width
	sub	$t0, $t0, $s1		# set right wall y coordinate = screen width - wall width
	addi	$sp, $sp, -4
	sw	$s0, 0($sp)		# push wall colour onto stack
	move	$a0, $t0
	move	$a1, $zero
	move	$a2, $s1
	move	$a3, $s2
	jal	draw_rectangle		# draw right wall
	
	lw	$t0, SCREEN_WIDTH	# set ceiling width = screen width
	addi	$sp, $sp, -4
	sw	$s0, 0($sp)		# push wall colour onto stack
	move	$a0, $zero
	move	$a1, $zero
	move	$a2, $t0
	move	$a3, $s1
	jal	draw_rectangle		# draw ceiling

	lw	$s0, BUFFER_COLOUR	# set buffer colour
	
	lw	$t2, BUFFER_HEIGHT	# load buffer height
	addi	$sp, $sp, -4
	sw	$s0, 0($sp)		# push buffer colour onto stack
	move	$a0, $zero
	move	$a1, $s2
	move	$a2, $s1
	move	$a3, $t2
	jal	draw_rectangle		# draw left buffer
	
	lw	$t0, SCREEN_WIDTH	# load screen width
	sub	$t0, $t0, $s1		# set right buffer y coordinate = right wall y coordinate
	lw	$t1, BUFFER_HEIGHT	# load buffer height
	addi	$sp, $sp, -4
	sw	$s0, 0($sp)		# push buffer colour onto stack
	move	$a0, $t0
	move	$a1, $s2
	move	$a2, $s1
	move	$a3, $t1
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
	lw	$a0, BRICKS_Y		# load y coordinate of top row from stack
	
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	sw	$s2, 12($sp)		# push old $s2 value on stack
	
	add	$s0, $zero, $a0		# store y coordinate of top row
	li	$s2, 0			# initialize loop variable k = 0
l2:	lw	$t8, BRICKS		# load number of rows
	lw	$t9, BRICKS+4		# load number of bricks per row
	mulo	$t0, $t8, $t9		# loop condition = number of elements
	beq	$s2, $t0, n2
	
	rem	$t1, $s2, $t9
	div	$t2, $s2, $t9		# ($t1, $t2) = (i, j) location of k in 2-D array
	sll	$t0, $t2, 2
	la	$t7, COLOURS+4		# ptr to first colour of COLOURS
	add	$t0, $t0, $t7
	lw	$t0, 0($t0)		# load ith element of COLOURS

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

u2:	addi	$s2, $s2, 1		# k++
	j	l2

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
	
	addi	$sp, $sp, -4
	sw	$a0, 0($sp)		# push brick colour on stack
	move	$a0, $a1
	move	$a1, $a2
	move	$a2, $t0
	move	$a3, $t1
	jal	draw_rectangle		# draw brick at (x, y)
	
	lw	$ra, 0($sp)		# pop return address from stack
	addi	$sp, $sp, 4
	jr	$ra			# return


delete_brick:
	lw	$a0, 0($sp)		# pop i from stack
	lw	$a1, 4($sp)		# pop j from stack
	addi	$sp, $sp, 8
	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	
	lw	$t6, BRICKS_Y
	lw	$t7, WALL_WIDTH		# load wall width
	lw	$t8, BRICK_DIM		# load brick width
	lw	$t9, BRICK_DIM+4	# load brick height
	
	mulo	$t1, $a0, $t8
	add	$t1, $t1, $t7		# x coordinate of (i, j) brick
	mulo	$t2, $a1, $t9
	add	$t2, $t2, $t6		# y coordinate of (i, j) brick
	
	addi	$sp, $sp, -12
	li	$t0, 0
	sw	$t0, 0($sp)		# push brick colour onto stack
	sw	$t1, 4($sp)		# push x coordinate onto stack
	sw	$t2, 8($sp)		# push y coordinate onto stack
	jal	draw_brick
	
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra	


# parameters
#	colour - colour of the rectangle to draw
#	($a0) x - x coordinate of the top left corner of the brick
#	($a1) y - y coordinate of the top left corner of the brick
#	($a2) width - the width of the rectangle
#	($a3) height - the height of the rectangle
draw_rectangle:
	lw 	$t7, 0($sp)		# pop colour from stack
	addi	$sp, $sp, 4
	
	lw	$t8, SCREEN_WIDTH	# load screen width
	lw	$t9, ADDR_DSPL		# load ptr to display memory location

	addi	$sp, $sp, -12
	sw	$t7, 0($sp)		# store colour of pixel on stack
	sw	$ra, 4($sp)		# store return address on stack
	sw	$s0, 8($sp)		# store old $s0 on stack
	
	add	$s0, $zero, $zero	# initialize loop variable i = 0
l1:	mulo	$t1, $a2, $a3		# set loop condition = number of pixels in the rectangle
	beq	$s0, $t1, n1a
	rem	$t2, $s0, $a2		# calculate x offset
	add	$t2, $a0, $t2		# calculate x'
	div	$t3, $s0, $a2		# calculate y offset
	add	$t3, $a1, $t3		# calculate y'
	
	addi	$sp, $sp, -8
	sw	$t2, 0($sp)
	sw	$t3, 4($sp)

	jal	get_pixel_address

	lw	$t4, 0($sp)
	addi	$sp, $sp, 4

	lw	$t7, 0($sp)
	sw	$t7, 0($t4)		# store colour at memory address of pixel (x', y')
	
	
u1:	addi	$s0, $s0, 1		# i++
	j	l1

n1a:	lw	$ra, 4($sp)
	lw	$s0, 8($sp)		# restore $s0 value
	addi	$sp, $sp, 12
	jr	$ra			# return


# DO NOT CHANGE ANY ADDRESS REGISTERS
get_pixel_address:
	lw	$t0, SCREEN_WIDTH	# load screen width
	lw	$t1, ADDR_DSPL

	lw	$t2, 0($sp)		# pop x from stack
	lw	$t3, 4($sp)		# pop y from stack
	addi	$sp, $sp, 8

	mulo	$t3, $t0, $t3		# find position of leftmost pixel of row y
	add	$t2, $t2, $t3		# find position of pixel (x, y)
	sll	$t2, $t2, 2		# calculate offset of pixel (x, y) memory address from base
	add 	$t2, $t1, $t2		# get ptr to memory address of pixel (x', y')
	
	addi	$sp, $sp, -4
	sw	$t2, 0($sp)
	jr	$ra
	
