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

PADDLE_DIM:
	.word	13, 1

BUFFER_HEIGHT:
	.word	5

##############################################################################
# Code
##############################################################################
	.text
	.globl	draw_paddle draw_ball draw_walls draw_bricks delete_paddle delete_ball update_brick get_pixel_address draw_heart1 draw_heart2 draw_heart3 delete_heart1 delete_heart2 delete_heart3
	.globl	draw_score
	
	li	$v0, 10 
	syscall

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
	lw	$t0, STATS_HEIGHT
	sub	$s2, $a0,$t0
	addi	$s2, $s2, -2		# set side wall height = paddle y - STATS_HEIGHT - 2
	
	addi	$sp, $sp, -4
	sw	$s0, 0($sp)		# push wall colour onto stack
	move	$a0, $zero
	lw	$t1, STATS_HEIGHT	# extra space for stats
	move	$a1, $t1
	move	$a2, $s1
	move	$a3, $s2
	jal	draw_rectangle		# draw left wall
	
	lw	$t0, SCREEN_WIDTH	# load screen width
	sub	$t0, $t0, $s1		# set right wall y coordinate = screen width - wall width
	addi	$sp, $sp, -4
	sw	$s0, 0($sp)		# push wall colour onto stack
	move	$a0, $t0
	lw	$t1, STATS_HEIGHT	# extra space for stats
	move	$a1, $t1
	move	$a2, $s1
	move	$a3, $s2
	jal	draw_rectangle		# draw right wall
	
	lw	$t0, SCREEN_WIDTH	# set ceiling width = screen width
	addi	$sp, $sp, -4
	sw	$s0, 0($sp)		# push wall colour onto stack
	move	$a0, $zero
	lw	$t1, STATS_HEIGHT	# extra space for stats
	move	$a1, $t1
	move	$a2, $t0
	move	$a3, $s1
	jal	draw_rectangle		# draw ceiling

	lw	$s0, BUFFER_COLOUR	# set buffer colour
	
	lw	$t2, BUFFER_HEIGHT	# load buffer height
	addi	$sp, $sp, -4
	sw	$s0, 0($sp)		# push buffer colour onto stack
	move	$a0, $zero
	lw	$t1, STATS_HEIGHT	# extra space for stats
	add	$a1, $s2, $t1
	move	$a2, $s1
	move	$a3, $t2
	jal	draw_rectangle		# draw left buffer
	
	lw	$t0, SCREEN_WIDTH	# load screen width
	sub	$t0, $t0, $s1		# set right buffer y coordinate = right wall y coordinate
	lw	$t1, BUFFER_HEIGHT	# load buffer height
	addi	$sp, $sp, -4
	sw	$s0, 0($sp)		# push buffer colour onto stack
	move	$a0, $t0
	lw	$t1, STATS_HEIGHT	# extra space for stats
	add	$a1, $s2, $t1
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


update_brick:
	lw	$a0, 0($sp)		# pop i from stack
	lw	$a1, 4($sp)		# pop j from stack
	addi	$sp, $sp, 8
	
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	
	lw	$t6, BRICKS_Y
	lw	$t7, WALL_WIDTH		# load wall width
	lw	$t8, BRICK_DIM		# load brick width
	lw	$t9, BRICK_DIM+4	# load brick height
	
	mulo	$t1, $a0, $t8
	add	$s0, $t1, $t7		# x coordinate of (i, j) brick
	mulo	$t2, $a1, $t9
	add	$s1, $t2, $t6		# y coordinate of (i, j) brick
	
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	sw	$s1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	lw	$v0, 0($v0)		# load colour of brick
	addi	$sp, $sp, 4
	
col1:	bne	$v0, 0xff0000, col2	# check if brick is red
	li	$t0, 0xaa0000
	j	draw
	
col2:	bne	$v0, 0x00ff00, col3	# check if brick is green
	li	$t0, 0x00aa00
	j	draw
	
col3:	bne	$v0, 0x0000ff, dstr	# check if brick is blue
	li	$t0, 0x0000aa
	j	draw
	
dstr:	move	$t0, $zero
	j	draw
	
draw:	addi	$sp, $sp, -12
	sw	$t0, 0($sp)		# push brick colour onto stack
	sw	$s0, 4($sp)		# push x coordinate onto stack
	sw	$s1, 8($sp)		# push y coordinate onto stack
	jal	draw_brick
	
	lw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	addi	$sp, $sp, 12
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
	
	
# function
draw_score:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	lw	$t0, SCREEN_WIDTH
	addi	$a0, $t0, -6
	li	$a1, 2
	lw	$t0, SCORE
	rem	$a2, $t0, 10
	jal	draw_digit
	
	lw	$t0, SCREEN_WIDTH
	addi	$a0, $t0, -10
	li	$a1, 2
	lw	$t0, SCORE
	div	$t0, $t0, 10
	rem	$a2, $t0, 100
	jal	draw_digit
	
	lw	$t0, SCREEN_WIDTH
	addi	$a0, $t0, -14
	li	$a1, 2
	lw	$t0, SCORE
	div	$a2, $t0, 100
	jal	draw_digit
	
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
	
# parameters
#	($a0) x - top left corner x coordinate
# 	($a1) y - top left corner y coordinate
#	($a2) nnumber to draw
draw_digit:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
case0:	bne	$a2, 0, case1
	jal	draw_0
	j	dflt1
	
case1:	bne	$a2, 1, case2
	jal	draw_1
	j	dflt1
	
case2:	bne	$a2, 2, case3
	jal	draw_2
	j	dflt1
	
case3:	bne	$a2, 3, case4
	jal	draw_3
	j	dflt1
	
case4:	bne	$a2, 4, case5
	jal	draw_4
	j	dflt1
	
case5:	bne	$a2, 5, case6
	jal	draw_5
	j	dflt1
	
case6:	bne	$a2, 6, case7
	jal	draw_6
	j	dflt1
	
case7:	bne	$a2, 7, case8
	jal	draw_7
	j	dflt1
	
case8:	bne	$a2, 8, case9
	jal	draw_8
	j	dflt1
	
case9:	jal	draw_9
	j	dflt1
	
dflt1:	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

# parameters
#	($a0) x - top left corner x coordinate
# 	($a1) y - top left corner y coordinate
draw_0: addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	jal	clear_digit		# pass arguments from draw_0 to clear_digit
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	move	$a1, $s1
	li	$a2, 1
	li	$a3, 5
	jal	draw_rectangle
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	addi	$a0, $s0, 2
	move	$a1, $s1
	li	$a2, 1
	li	$a3, 5
	jal	draw_rectangle
	
	addi	$sp, $sp, -8
	addi	$t0, $s0, 1
	sw	$t0, 0($sp)
	sw	$s1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -8
	addi	$t0, $s0, 1
	sw	$t0, 0($sp)
	addi	$t1, $s1, 4
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

draw_1:	addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	jal	clear_digit		# pass arguments from draw_1 to clear_digit
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	addi	$a0, $s0, 1
	move	$a1, $s1
	li	$a2, 1
	li	$a3, 4
	jal	draw_rectangle
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	addi	$a1, $s1, 4
	li	$a2, 3
	li	$a3, 1
	jal	draw_rectangle
	
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

draw_2: addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	jal	clear_digit		# pass arguments from draw_2 to clear_digit
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	move	$a1, $s1
	li	$a2, 3
	li	$a3, 1
	jal	draw_rectangle
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	addi	$a1, $s1, 2
	li	$a2, 3
	li	$a3, 1
	jal	draw_rectangle
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	addi	$a1, $s1, 4
	li	$a2, 3
	li	$a3, 1
	jal	draw_rectangle
	
	addi	$sp, $sp, -8
	addi	$t0, $s0, 2
	sw	$t0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 3
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

draw_3: addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	jal	clear_digit		# pass arguments from draw_3 to clear_digit
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	move	$a1, $s1
	li	$a2, 3
	li	$a3, 1
	jal	draw_rectangle
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	addi	$a1, $s1, 2
	li	$a2, 3
	li	$a3, 1
	jal	draw_rectangle
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	addi	$a1, $s1, 4
	li	$a2, 3
	li	$a3, 1
	jal	draw_rectangle
	
	addi	$sp, $sp, -8
	addi	$t0, $s0, 2
	sw	$t0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -8
	addi	$t0, $s0, 2
	sw	$t0, 0($sp)
	addi	$t1, $s1, 3
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

draw_4: addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	jal	clear_digit		# pass arguments from draw_4 to clear_digit
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	move	$a1, $s1
	li	$a2, 1
	li	$a3, 3
	jal	draw_rectangle
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	addi	$a0, $s0, 2
	move	$a1, $s1
	li	$a2, 1
	li	$a3, 5
	jal	draw_rectangle
	
	addi	$sp, $sp, -8
	addi	$t0, $s0, 1
	sw	$t0, 0($sp)
	addi	$t1, $s1, 2
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

draw_5: addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	jal	clear_digit		# pass arguments from draw_5 to clear_digit
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	move	$a1, $s1
	li	$a2, 3
	li	$a3, 1
	jal	draw_rectangle
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	addi	$a1, $s1, 2
	li	$a2, 3
	li	$a3, 1
	jal	draw_rectangle
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	addi	$a1, $s1, 4
	li	$a2, 3
	li	$a3, 1
	jal	draw_rectangle
	
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -8
	addi	$t0, $s0, 2
	sw	$t0, 0($sp)
	addi	$t1, $s1, 3
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

draw_6: addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	jal	draw_5
	
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 3
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

draw_7: addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	jal	clear_digit		# pass arguments from draw_7 to clear_digit
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	move	$a0, $s0
	move	$a1, $s1
	li	$a2, 3
	li	$a3, 1
	jal	draw_rectangle
	
	addi	$sp, $sp, -4
	li	$t0, 0xffffff
	sw	$t0, 0($sp)		# push colour white onto stack
	addi	$a0, $s0, 2
	addi	$a1, $s1, 1
	li	$a2, 1
	li	$a3, 4
	jal	draw_rectangle
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

draw_8: addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	jal	draw_6
	
	addi	$sp, $sp, -8
	addi	$t0, $s0, 2
	sw	$t0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

draw_9: addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	jal	draw_4
	
	addi	$sp, $sp, -8
	addi	$t0, $s0, 1
	sw	$t0, 0($sp)
	sw	$s1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xffffff
	sw	$t1, 0($v0)
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra


# parameters
#	($a0) x - top left corner x coordinate
# 	($a1) y - top left corner y coordinate
clear_digit:
	addi	$sp, $sp, -8
	sw	$ra, 4($sp)		# push return address onto stack
	sw	$zero, 0($sp)		# push colour black onto stack
	li	$a2, 3			# digit is 3 pixels wide
	li	$a3, 5			# digit is 5 pixels tall
	jal	draw_rectangle
	
	lw	$ra, 0($sp)		# pop return address off stack
	addi	$sp, $sp, 4
	jr	$ra


# DO NOT CHANGE ANY ARGUMENT REGISTERS
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


draw_heart1:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	lw	$t0, SCREEN_WIDTH
	addi	$a0, $t0, 4
	li	$a1, 1
	
	# row 1
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	move	$a0, $s0		# x position
	move	$a1, $s1		# y position
	li	$a2, 5			# 5 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle	
	
	# paint black on top
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0x000000		# load colour black
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0x000000
	sw	$t0, 0($sp)		# push black onto stack
	addi	$a0, $s0, 1		# x position - move right 1 coordinate
	move	$a1, $s1		# y position
	li	$a2, 3			# 3 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 2
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	addi	$a0, $s0, -1		# x position - move left 1 coordinate
	addi	$a1, $s1, 1		# y position - move down 1 coordinate
	li	$a2, 7			# 7 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# black out pixel
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0x000000		# load colour black
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0x000000
	sw	$t0, 0($sp)		# push black onto stack
	addi	$a0, $s0, 2		# x position - move right 1 coordinate
	addi	$a1, $s1, 1		# y position
	li	$a2, 1			# 1 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 3
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	move	$a0, $s0		# x position - move left 1 coordinate
	addi	$a1, $s1, 2		# y position - move down 2 coordinates
	li	$a2, 5			# 5 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 4
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	addi	$a0, $s0, 1		# x position - move right 1 coordinate
	addi	$a1, $s1, 3		# y position - move down 3 coordinates
	li	$a2, 3			# 3 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 5
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	addi	$a0, $s0, 2		# x position - move right 1 coordinate
	addi	$a1, $s1, 4		# y position - move down 3 coordinates
	li	$a2, 1			# 1 pixel long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
		
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

draw_heart2:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	lw	$t0, SCREEN_WIDTH
	addi	$a0, $t0, 12
	li	$a1, 1
	
	# row 1
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	move	$a0, $s0		# x position
	move	$a1, $s1		# y position
	li	$a2, 5			# 5 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle	
	
	# paint black on top
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0x000000		# load colour black
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0x000000
	sw	$t0, 0($sp)		# push black onto stack
	addi	$a0, $s0, 1		# x position - move right 1 coordinate
	move	$a1, $s1		# y position
	li	$a2, 3			# 3 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 2
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	addi	$a0, $s0, -1		# x position - move left 1 coordinate
	addi	$a1, $s1, 1		# y position - move down 1 coordinate
	li	$a2, 7			# 7 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# black out pixel
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0x000000		# load colour black
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0x000000
	sw	$t0, 0($sp)		# push black onto stack
	addi	$a0, $s0, 2		# x position - move right 1 coordinate
	addi	$a1, $s1, 1		# y position
	li	$a2, 1			# 1 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 3
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	move	$a0, $s0		# x position - move left 1 coordinate
	addi	$a1, $s1, 2		# y position - move down 2 coordinates
	li	$a2, 5			# 5 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 4
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	addi	$a0, $s0, 1		# x position - move right 1 coordinate
	addi	$a1, $s1, 3		# y position - move down 3 coordinates
	li	$a2, 3			# 3 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 5
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	addi	$a0, $s0, 2		# x position - move right 1 coordinate
	addi	$a1, $s1, 4		# y position - move down 3 coordinates
	li	$a2, 1			# 1 pixel long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
		
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

draw_heart3:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	lw	$t0, SCREEN_WIDTH
	addi	$a0, $t0, 20
	li	$a1, 1
	
	# row 1
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	move	$a0, $s0		# x position
	move	$a1, $s1		# y position
	li	$a2, 5			# 5 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle	
	
	# paint black on top
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0x000000		# load colour black
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0x000000
	sw	$t0, 0($sp)		# push black onto stack
	addi	$a0, $s0, 1		# x position - move right 1 coordinate
	move	$a1, $s1		# y position
	li	$a2, 3			# 3 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 2
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	addi	$a0, $s0, -1		# x position - move left 1 coordinate
	addi	$a1, $s1, 1		# y position - move down 1 coordinate
	li	$a2, 7			# 7 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# black out pixel
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0x000000		# load colour black
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0x000000
	sw	$t0, 0($sp)		# push black onto stack
	addi	$a0, $s0, 2		# x position - move right 1 coordinate
	addi	$a1, $s1, 1		# y position
	li	$a2, 1			# 1 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 3
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	move	$a0, $s0		# x position - move left 1 coordinate
	addi	$a1, $s1, 2		# y position - move down 2 coordinates
	li	$a2, 5			# 5 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 4
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	addi	$a0, $s0, 1		# x position - move right 1 coordinate
	addi	$a1, $s1, 3		# y position - move down 3 coordinates
	li	$a2, 3			# 3 pixels long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
	
	# row 5
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	addi	$t1, $s1, 1
	sw	$t1, 4($sp)
	jal	get_pixel_address
	lw	$v0, 0($sp)
	addi	$sp, $sp, 4
	li	$t1, 0xff0000
	sw	$t1, 0($v0)
	
	addi	$sp, $sp, -4
	li	$t0, 0xff0000
	sw	$t0, 0($sp)		# push colour red onto stack
	addi	$a0, $s0, 2		# x position - move right 1 coordinate
	addi	$a1, $s1, 4		# y position - move down 3 coordinates
	li	$a2, 1			# 1 pixel long
	li	$a3, 1			# 1 pixel high
	jal	draw_rectangle
		
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

delete_heart1:
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	lw	$t0, SCREEN_WIDTH
	addi	$a0, $t0, 3
	li	$a1, 1
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	addi	$sp, $sp, -4
	li	$t0, 0x000000
	sw	$t0, 0($sp)		# push colour red onto stack
	move	$a0, $s0		# x position
	move	$a1, $s1		# y position
	li	$a2, 8
	li	$a3, 5
	jal	draw_rectangle	
	
	li	$t1, 0
	sw	$t1, LIVES
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra

delete_heart2:
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	lw	$t0, SCREEN_WIDTH
	addi	$a0, $t0, 11
	li	$a1, 1
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	addi	$sp, $sp, -4
	li	$t0, 0x000000
	sw	$t0, 0($sp)		# push colour red onto stack
	move	$a0, $s0		# x position
	move	$a1, $s1		# y position
	li	$a2, 8
	li	$a3, 5
	jal	draw_rectangle	
		
	li	$t1, 0
	sw	$t1, LIVES
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra


delete_heart3:
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	
	lw	$t0, SCREEN_WIDTH
	addi	$a0, $t0, 19
	li	$a1, 1
	
	move	$s0, $a0		# store x coordinate
	move	$s1, $a1		# store y coordinate
	
	addi	$sp, $sp, -4
	li	$t0, 0x000000
	sw	$t0, 0($sp)		# push colour red onto stack
	move	$a0, $s0		# x position
	move	$a1, $s1		# y position
	li	$a2, 8
	li	$a3, 5
	jal	draw_rectangle	
		
	li	$t1, 1
	sw	$t1, LIVES
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 12
	jr	$ra