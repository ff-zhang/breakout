	.text
	.globl	update_ball

	j	main


update_ball:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	jal 	delete_ball
	
	## temporary, manually change direction
	addi	$sp, $sp, -4
	li	$t0, 1			# northeast
	sw	$t0, 0($sp)
	jal	move_ball
	
	jal 	draw_ball
	
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

move_ball:
	lw	$a0, 0($sp)		# pop direction from stack
	addi	$sp, $sp, 4
	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	
	lw	$t1, BALL_COORDS	# load x coordinate of ball
	lw	$t2, BALL_COORDS+4	# load y coordinate of ball
	
	beq	$a0, -1, move_NW	# ball goes northwest
	beq	$a0, 0, move_N		# ball goes straight up
	beq	$a0, 1, move_NE		# ball goes northeast

move_N:	addi	$t2, $t2, -1		# decrease y coordinate by 1 (ball goes up)
	j	end

move_NW:
	addi	$t1, $t1, -1		# decrease x coordinate by 1 (ball goes left)
	addi	$t2, $t2, -1		# decrease y coordinate by 1 (ball goes up)
	j	end

move_NE:
	addi	$t1, $t1, 1		# decrease x coordinate by 1 (ball goes right)
	addi	$t2, $t2, -1		# decrease y coordinate by 1 (ball goes up)\
	j	end
	
end:	sw	$t1, BALL_COORDS	# update x coordinate of ball
	sw	$t2, BALL_COORDS+4	# update y coordinate of ball
	
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
