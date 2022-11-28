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

PADDLE_COLOUR:
	.word	0xaaaaaa

WALL_WIDTH:
	.word	4

BALL_COLOUR:
	.word	0xffffff

BUFFER_HEIGHT:
	.word	5

# (width, height)
BRICK_DIM:
	.word	8, 4

##############################################################################
# Code
##############################################################################
	.text
	.globl	draw_paddle draw_ball draw_walls draw_bricks delete_paddle delete_ball

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
	lw	$a0, BALL_COORDS	# load ball x coordinate
	lw	$a1, BALL_COORDS+4	# load ball y coordinate
	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	lw	$t0, BALL_COLOUR	# load ball colour
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
	lw	$a0, BRICKS_Y		# pop y coordinate of top row from stack
	la	$a1, BRICKS		# pop ptr to array of colours from stack
	
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	sw	$s2, 12($sp)		# push old $s2 value on stack
	
	add	$s0, $zero, $a0		# store y coordinate of top row
	add	$s1, $a1, 8		# ptr to first brick colour element of array
	li	$s2, 0			# initialize loop variable k = 0
l2:	lw	$t8, -8($s1)		# load number of rows
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
l1:	beq	$t0, $t1, n1
	rem	$t2, $t0, $a2		# calulate x offset
	div	$t3, $t0, $a2		# calculate y offset
	mulo	$t3, $t3, $t8		# calculate leftmost pixel of row y
	
	add	$t2, $t2, $t3		# calculate distance from pixel (x, y) to pixel (x offset, y offset)
	add	$t2, $a1, $t2		# calculate position of pixel (x', y') = (x, y) + (x offset, y offset)
	mulo	$t2, $t2, 4		# calculate distnace memory address of pixel (x, y) to that of (x', y')
	add	$t2, $t2, $t9		# set ptr to memory address of pixel (x', y')
	sw	$a0, 0($t2)		# store colour at memory address of pixel (x', y')
	
u1:	addi	$t0, $t0, 1		# i++
	j	l1

n1:	jr	$ra			# return
