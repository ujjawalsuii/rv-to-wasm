#-----------------------
#calculates a power of 2, 1 shift at a time
# a0: input arg
# a0: result
#-----------------------
main:
	srli    x5 x5 16	# 0 register x5
	srli    x5 x5 16	# 0 register x5
	srli    x6 x5 1	    # 0 register x6
	add     x7 x5 x10	#calculating 2^input arg
    addi	x7 x7 -1
	addi	x5 x5 1
loop:
	slli    x5 x5 1
	addi	x7 x7 -1
    bge 	x7 zero loop	#when $t0>=0, not done
done:
    addi    x10 x5 0
    ret
