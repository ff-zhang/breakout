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

# x coordinates of the left and right wall (left wall x, right wall x) for paddle collisions
WALLS_X:
	.word	4, 111

##############################################################################
# Code
##############################################################################
	.text
	.globl	update_ball get_key key_in check_collision update_paddle pause

end:	li	$v0, 10 
	syscall


# pause loop
pause:	li	$v0, 32	
	li	$a1, 100		# add  delay
	syscall
	
	lw 	$t9, ADDR_KBRD		# $t0 = base address for keyboard
    	lw 	$t4, 0($t9)		# load first word from keyboard
    	beqz 	$t4, pause	# if first word is 0, key was not pressed so repeat loop
	
	lw 	$t0, 4($t9)		# load input letter
	
	addi	$sp, $sp, -4
	sw	$a0, 0($sp)		# return key pressed
    	jr	$ra	


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
