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

##############################################################################
# Code
##############################################################################
	.text
	.globl	update_ball get_key check_collision

end:	li	$v0, 10 
	syscall
	
get_key:
	li	$v0, 12			# 32 char
	# li	$a0, 1			# 1 char
	syscall
		
	lw 	$t9, ADDR_KBRD          # $t0 = base address for keyboard
    	lw 	$t4, 0($t9)             # Load first word from keyboard
    	beq 	$t4, 1, key_in      	# If first word 1, key is pressed
    	
    	jr	$ra

key_in:	lw 	$a0, 4($t7)		# load input letter

	beq 	$a0, 0x78, end		# exit when x pressed
	beq 	$a0, 0x71, end		# exit when q pressed
	# beq 	$a0, 0x61, press_a	# move paddle left
	# beq 	$a0, 0x64, press_d	# move paddle right
	
	jr	$ra


check_collision:
# updates the direction if the ball would collide with another object
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)

	lw	$t0, BALL_COORDS	# load x coordinate of ball
	lw	$t1, BALL_COORDS+4	# load y coordinate of ball
	
	jal	next_location
	lw	$s0, 0($sp)		# save predicted x coordinate
	lw	$s1, 4($sp)		# save predicted y coordinate
	# next_location returns (x, y) on the stack but we can immideatly pass it to get_pixel_address
	
	jal	get_pixel_address
	lw	$t0, 0($sp)		# get memory address of predicted pixel
	addi	$sp, $sp, 4
	
	lw	$t1, 0($t0)		# get colour of predicted pixel
	beqz	$t1, return
	
	lw	$t2, PADDLE_COLOUR	# check if collide with wall or paddle
	beq	$t1, $t2, bounce_wp
	j	bounce_brick		# if didn't collide with wall or paddle, must collide with birck
	
bounce_wp:				# bounce off wall or paddle
	li	$t0, 0
	sw	$t0, DIRECTION
	j	return
	
bounce_brick:
	lw	$t0, DIRECTION
	beq	$t0, 0, change_S
	
change_S:
	li	$t0, 2
	sw	$t0, DIRECTION
	j	c2
	
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
	
return:	lw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	addi	$sp, $sp, 12
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
	
	beq	$a0, -1, move_NW	# ball goes northwest
	beq	$a0, 0, move_N		# ball goes straight up
	beq	$a0, 1, move_NE		# ball goes northeast
	
	beq	$a0, 2, move_S

move_S:	addi	$t2, $t2, 1
	j	c1

move_N:	addi	$t2, $t2, -1		# decrease y coordinate by 1 (ball goes up)
	j	c1

move_NW:
	addi	$t1, $t1, -1		# decrease x coordinate by 1 (ball goes left)
	addi	$t2, $t2, -1		# decrease y coordinate by 1 (ball goes up)
	j	c1

move_NE:
	addi	$t1, $t1, 1		# decrease x coordinate by 1 (ball goes right)
	addi	$t2, $t2, -1		# decrease y coordinate by 1 (ball goes up)\
	j	c1
	
c1:	addi	$sp, $sp, -8
	sw	$t1, 0($sp)
	sw	$t2, 4($sp)
	
	jr	$ra
