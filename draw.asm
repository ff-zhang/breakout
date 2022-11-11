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
	
PADDLE_WIDTH:
	.word	13

PADDLE_HEIGHT:
	.word	1

##############################################################################
# Code
##############################################################################
	.text
	.globl draw_paddle draw_ball draw_walls
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
	
	j	end
	
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
	
	j	end
	
draw_walls:
	lw	$a0, 0($sp)		# pop paddle y coordinate from stack
	
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)		# push return address onto stack
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	
	addi	$s0, $zero, 0xaaaaaa	# wall colour
	
	addi	$s1, $zero, 4		# wall width
	addi	$s2, $a0, -2		# side wall height
	
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push wall colour onto stack
	sw	$zero, 4($sp)		# push left wall x coordinate onto stack
	sw	$zero, 8($sp)		# push left wall y coordinate onto stack
	sw	$s1, 12($sp)		# push side wall width onto stack
	sw	$s2, 16($sp)		# push wall height onto stack
	
	jal	draw_rectangle		# draw left wall
	
	add	$t0, $zero, 128
	sub	$t0, $t0, $s1		# right wall y coordinate
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push wall colour onto stack
	sw	$t0, 4($sp)		# push right wall x coordinate onto stack
	sw	$zero, 8($sp)		# push right wall y coordinate onto stack
	sw	$s1, 12($sp)		# push side wall width onto stack
	sw	$s2, 16($sp)		# push side wall height onto stack
	
	jal	draw_rectangle		# draw right wall
	
	add	$t0, $zero, 128		# set ceiling width
	addi	$sp, $sp, -20
	sw	$s0, 0($sp)		# push wall colour onto stack
	sw	$zero, 4($sp)		# push ceiling x coordinate onto stack
	sw	$zero, 8($sp)		# push ceiling y coordinate onto stack
	sw	$t0, 12($sp)		# push ceiling width onto stack
	sw	$s1, 16($sp)		# push ceiling height onto stack
	
	jal	draw_rectangle		# draw right wall
	
	lw	$ra, 0($sp)		# get return address from stack
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	addi	$sp, $sp, 16
	
	j	end

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
l1:	beq	$t0, $t1, end
	
	rem	$t2, $t0, $a2		# calulate x offset
	div	$t3, $t0, $a2		# calculate y offset
	mulo	$t3, $t3, 128		# use 128 as that is the width of the screen
	
	add	$t2, $t2, $t3		# distance from pixel (x, y) to pixel (x offset, y offset)
	add	$t2, $a1, $t2		# position of pixel (x', y') = (x, y) + (x offset, y offset)
	mulo	$t2, $t2, 4		# distnace memory address of pixel (x, y) to that of (x', y')
	add	$t2, $t2, $t9		# ptr to memory address of pixel (x', y')
	sw	$a0, 0($t2)		# store colour at (x', y')
	
update:	addi	$t0, $t0, 1		# i++
	j	l1

end:	jr	$ra			# return





