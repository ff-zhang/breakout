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
# Code
##############################################################################
	.text
	.globl draw_paddle draw_ball draw_walls draw_bricks
	j main

draw_paddle:
	lw	$a0, 0($sp)		# ptr to paddle coordinates
	addi	$sp, $sp, 4
	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	li	$t0, 0xaaaaaa		# set paddle colour
	lw	$t1, 0($a0)		# load paddle x coordinate
	lw	$t2, 4($a0)		# load paddle x coordinate
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

draw_bricks:
	lw	$a0, 0($sp)		# pop y coordinate of top row from stack
	lw	$a1, 4($sp)		# pop ptr to array of row colours from stack
	addi	$sp, $sp, 8
	
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	sw	$s2, 12($sp)		# push old $s2 value on stack
	
	add	$s0, $zero, $a0
	add	$s1, $a1, 4		# ptr to first colour element of array
	li	$s2, 0			# initialize loop variable i = 0
l3:	lw	$t0, -4($s1)		# loop condition = number of rows
	beq	$s2, $t0, n3
	
	sll	$t0, $s2, 2		# get offset of ptr to row $s0 colour from row 0 colour
	add	$t0, $s1, $t0		# set ptr to row $s0 colour
	lw	$t0, 0($t0)		# load row $s0 colour
	lw	$t1, BRICK_DIM+4	# load brick height
	mulo	$t1, $s2, $t1
	add	$t1, $s0, $t1		# load y coordinate of row $s0 = brick heigh * i + top row y coordinate
	
	addi	$sp, $sp, -8
	sw	$t0, 0($sp)		# push row $s0 colour onto stack
	sw	$t1, 4($sp)		# push y coordinate onto stack
	jal	draw_row

u3:	addi	$s2, $s2, 1		# i++
	j	l3

n3:	lw	$ra, 0($sp)		# pop return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	lw	$s2, 12($sp)		# pop old $s2 value on stack
	addi	$sp, $sp, 16
	jr	$ra			# return

draw_row:
	lw	$a0, 0($sp)		# pop colour of bricks from stack
	lw	$a1, 4($sp)		# pop y coordinate of the top of the row
	addi	$sp, $sp, 8

	addi	$sp, $sp, -20
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value onto stack
	sw	$s1, 8($sp)		# push old $s1 value onto stack
	sw	$s2, 12($sp)		# push old $s2 value onto stack
	sw	$s3, 16($sp)		# push old $s3 value onto stack
		
	move	$s0, $a0		# store brick colour in $s0
	move	$s1, $a1		# store y location of row in $s1
	
	li	$s2, 0			# initialize loop variable i = 0
	lw	$t0, SCREEN_WIDTH	# load screen width
	lw	$t1, WALL_WIDTH		# load wall width
	lw	$t2, BRICK_DIM		# load brick width
	mulo	$t1, $t1, 2
	sub	$t0, $t0, $t1		# width of play space = screen width - 2 * wall width
	div	$s3, $t0, $t2		# loop condition = number of bricks per row
l2:	beq	$s2, $s3, n2
	lw	$t0, BRICK_DIM		# load brick width
	lw	$t1, WALL_WIDTH		# load wall width
	mulo	$t0, $t0, $s2
	add	$t0, $t0, $t1		# set x coordinate of brick = brick width * i + wall width
	
	addi	$sp, $sp, -12
	sw	$s0, 0($sp)		# push brick colour onto stack
	sw	$t0, 4($sp)		# push x coordinate onto stack
	sw	$s1, 8($sp)		# push y coordinate onto stack
	jal	draw_brick		# draw brick at (x, y)

u2:	addi	$s2, $s2, 1		# i++
	j	l2

n2:	lw	$ra, 0($sp)		# pop return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	lw	$s2, 12($sp)		# pop old $s1 value from stack
	lw	$s3, 16($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 20
	jr	$ra			# return
	
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
