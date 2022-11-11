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
	
PADDLE_WIDTH:
	.word	13

PADDLE_HEIGHT:
	.word	1
	
WALL_WIDTH:
	.word	4
	
BRICK_WIDTH:
	.word	8		# should evenly decide the width of the play space
	
BRICK_HEIGHT:
	.word	4		# needs to be larger than 2

##############################################################################
# Code
##############################################################################
	.text
	.globl draw_paddle draw_ball draw_walls draw_bricks
	j main

draw_paddle:
	lw	$a0, 0($sp)		# $t0 = x (left corner)
	lw	$a1, 4($sp)		# $t1 = y (left corner)
	addi	$sp, $sp, 8
	
	addi	$t0, $zero, 0xaaaaaa	# set paddle colour
	lw	$t1, PADDLE_WIDTH	# set paddle width
	lw	$t2, PADDLE_HEIGHT	# set paddle height
	
	addi	$sp, $sp, -24
	sw	$t0, 0($sp)		# push paddle colour onto stack
	sw	$a0, 4($sp)		# push x coordinate onto stack
	sw	$a1, 8($sp)		# push y coordinate onto stack
	sw	$t1, 12($sp)		# push paddle width onto stack
	sw	$t2, 16($sp)		# push paddle height onto stack
	sw	$ra, 20($sp)		# push return address onto stack
	
	jal	draw_rectangle
	
	lw	$ra, 0($sp)		# get return address from stack
	addi	$sp, $sp, 4
	
	jr	$ra			# return
	
draw_ball:
	lw	$a0, 0($sp)		# $t0 = x (left corner)
	lw	$a1, 4($sp)		# $t1 = y (left corner)
	addi	$sp, $sp, 8
	
	addi	$t0, $zero, 0xffffff	# set ball colour
	addi	$t1, $zero, 1		# set ball width and height
	
	addi	$sp, $sp, -24
	sw	$t0, 0($sp)		# push ball colour onto stack
	sw	$a0, 4($sp)		# push x coordinate onto stack
	sw	$a1, 8($sp)		# push y coordinate onto stack
	sw	$t1, 12($sp)		# push ball width onto stack
	sw	$t1, 16($sp)		# push ball height onto stack
	sw	$ra, 20($sp)		# push return address onto stack
	
	jal	draw_rectangle
	
	lw	$ra, 0($sp)		# get return address from stack
	addi	$sp, $sp, 4
	
	jr	$ra			# return
	
draw_walls:
	lw	$a0, 0($sp)		# pop paddle y coordinate from stack
	addi	$sp, $sp, 4
	
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	
	addi	$s0, $zero, 0xaaaaaa	# wall colour
	lw	$s1, WALL_WIDTH		# load wall width
	addi	$s2, $a0, -2		# side wall height
	
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push wall colour onto stack
	sw	$zero, 4($sp)		# push left wall x coordinate onto stack
	sw	$zero, 8($sp)		# push left wall y coordinate onto stack
	sw	$s1, 12($sp)		# push side wall width onto stack
	sw	$s2, 16($sp)		# push wall height onto stack
	jal	draw_rectangle		# draw left wall
	
	lw	$t0, SCREEN_WIDTH	# load screen width
	sub	$t0, $t0, $s1		# right wall y coordinate
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push wall colour onto stack
	sw	$t0, 4($sp)		# push right wall x coordinate onto stack
	sw	$zero, 8($sp)		# push right wall y coordinate onto stack
	sw	$s1, 12($sp)		# push side wall width onto stack
	sw	$s2, 16($sp)		# push side wall height onto stack
	jal	draw_rectangle		# draw right wall
	
	lw	$t0, SCREEN_WIDTH	# load screen width as ceiling width
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push wall colour onto stack
	sw	$zero, 4($sp)		# push ceiling x coordinate onto stack
	sw	$zero, 8($sp)		# push ceiling y coordinate onto stack
	sw	$t0, 12($sp)		# push ceiling width onto stack
	sw	$s1, 16($sp)		# push ceiling height onto stack
	jal	draw_rectangle		# draw ceiling

	addi	$s0, $zero, 0xff88ff	# buffer colour
	
	addi	$t0, $zero, 5		# buffer height
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push buffer colour onto stack
	sw	$zero, 4($sp)		# push left buffer x coordinate onto stack
	sw	$s2, 8($sp)		# push left buffer y coordinate onto stack
	sw	$s1, 12($sp)		# push wall width onto stack
	sw	$t0, 16($sp)		# push buffer height onto stack
	jal	draw_rectangle		# draw left buffer
	
	add	$t0, $zero, 128
	sub	$t0, $t0, $s1		# right buffer y coordinate
	addi	$t1, $zero, 5		# buffer height
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push buffer colour onto stack
	sw	$t0, 4($sp)		# push right buffer x coordinate onto stack
	sw	$s2, 8($sp)		# push right buffer y coordinate onto stack
	sw	$s1, 12($sp)		# push wall width onto stack
	sw	$t1, 16($sp)		# push buffer height onto stack
	jal	draw_rectangle		# draw right buffer
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
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
	add	$s1, $a1, 4		# ptr to first element of array
	add	$s2, $zero, $zero	# initialize loop variable i = 0
l3:	lw	$t0, -4($s1)		# loop condition = number of rows
	beq	$s2, $t0, n3
	
	sll	$t0, $s2, 2		# offset of ptr to row $s0 colour from row 0 colour
	add	$t0, $s1, $t0		# ptr to row $s0 colour
	lw	$t0, 0($t0)		# load row $s0 colour
	lw	$t1, BRICK_HEIGHT	# load brick height
	mulo	$t1, $s2, $t1
	add	$t1, $s0, $t1		# y coordinate of row $s0
	
	addi	$sp, $sp, -8
	sw	$t0, 0($sp)		# push row $s0 colour onto stack
	sw	$t1, 4($sp)
	jal	draw_row

u3:	addi	$s2, $s2, 1
	j	l3

n3:	lw	$ra, 0($sp)		# pop return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	lw	$s2, 12($sp)		# push old $s2 value on stack
	addi	$sp, $sp, 16
	
	jr	$ra			# return\

draw_row:
	lw	$a0, 0($sp)		# pop colour of bricks from stack
	lw	$a1, 4($sp)		# y location of the top of the row
	addi	$sp, $sp, 8

	addi	$sp, $sp, -20
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)		# push old $s0 value on stack
	sw	$s1, 8($sp)		# push old $s1 value on stack
	sw	$s2, 12($sp)		# push old $s2 value on stack
	sw	$s3, 16($sp)		# push old $s2 value on stack
		
	add	$s0, $zero, $a0		# store brick colour in $s0
	add	$s1, $zero, $a1		# store y location of row in $s1
	
	add	$s2, $zero, $zero	# initialize loop variable i = 0
	lw	$t0, SCREEN_WIDTH	# load screen width
	lw	$t1, WALL_WIDTH		# load wall width
	lw	$t2, BRICK_WIDTH	# load brick width
	mulo	$t1, $t1, 2
	sub	$t0, $t0, $t1		# width of play space
	div	$s3, $t0, $t2		# loop condition = number of bricks per row
l2:	beq	$s2, $s3, n2
	addi	$sp, $sp, -12
	
	sw	$s0, 0($sp)		# push brick colour onto stack
	lw	$t0, BRICK_WIDTH	# load brick width
	lw	$t1, WALL_WIDTH		# load wall width
	mulo	$t0, $t0, $s2
	add	$t0, $t0, $t1
	sw	$t0, 4($sp)		# x coordinate of brick = brick width * i + wall width
	sw	$s1, 8($sp)
	jal	draw_brick		# draw brick

u2:	addi	$s2, $s2, 1
	j	l2

n2:	lw	$ra, 0($sp)		# pop return address from stack
	lw	$s0, 4($sp)		# pop old $s0 value from stack
	lw	$s1, 8($sp)		# pop old $s1 value from stack
	lw	$s2, 12($sp)		# pop old $s1 value from stack
	lw	$s3, 16($sp)		# pop old $s1 value from stack
	addi	$sp, $sp, 20
	jr	$ra			# return
	
draw_brick:
	lw	$a0, 0($sp)		# pop $a0 = brick colour from stack
	lw	$a1, 4($sp)		# pop $a1 = x (left corner) from stack
	lw	$a2, 8($sp)		# pop $a2 = y (left corner) from stack
	addi	$sp, $sp, 12
	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)		# push return address onto stack
	
	lw	$t0, BRICK_WIDTH	# store brick width in $s3
	lw	$t1, BRICK_HEIGHT	# store brick height in $s4
	
	addi	$sp, $sp, -20
	sw	$a0, 0($sp)		# push brick colour on stack
	sw	$a1, 4($sp)		# push brick x coordinate onto stack
	sw	$a2, 8($sp)		# push brick y coordinate onto stack
	sw	$t0, 12($sp)		# push brick width onto stack
	sw	$t1, 16($sp)		# push brick height onto stack
	jal	draw_rectangle
	
	lw	$ra, 0($sp)		# pop return address from stack
	addi	$sp, $sp, 4
	
	jr	$ra			# return

draw_rectangle:
	lw 	$a0, 0($sp)		# $a0 = colour
	lw	$t0, 4($sp)		# $t0 = x (top left corner)
	lw	$t1, 8($sp)		# $t1 = y (top left corner)
	mulo	$t1, $t1, 128		# $t1 is leftmost pixel of row y
	add	$a1, $t0, $t1		# $a1 is position of pixel (x, y)
	lw	$a2, 12($sp)		# $t0 = width of rectangle
	lw	$a3, 16($sp)		# $t1 = height of rectangle
	addi	$sp, $sp, 20
	
	lw	$t9, ADDR_DSPL		# $t9 is ptr to display memory location
	
	add	$t0, $zero, $zero	# loop variable i = 0
	mulo	$t1, $a2, $a3		# loop condition is number of pixels in the rectangle
l1:	beq	$t0, $t1, n1
	rem	$t2, $t0, $a2		# calulate x offset
	div	$t3, $t0, $a2		# calculate y offset
	mulo	$t3, $t3, 128		# use 128 as that is the width of the screen
	
	add	$t2, $t2, $t3		# distance from pixel (x, y) to pixel (x offset, y offset)
	add	$t2, $a1, $t2		# position of pixel (x', y') = (x, y) + (x offset, y offset)
	mulo	$t2, $t2, 4		# distnace memory address of pixel (x, y) to that of (x', y')
	add	$t2, $t2, $t9		# ptr to memory address of pixel (x', y')
	sw	$a0, 0($t2)		# store colour at (x', y')
	
u1:	addi	$t0, $t0, 1		# i++
	j	l1

n1:	jr	$ra			# return