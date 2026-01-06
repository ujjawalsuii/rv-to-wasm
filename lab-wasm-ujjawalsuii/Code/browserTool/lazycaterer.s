#---------------------------------
# lazycaterer aka central polygon numbers
#
# calculates the maximum number of pieces that result from
# making n intersecting cuts to a disk
#
#
# input:
#   a0: n
# output:
#   a0 : (n^2 + n + 2) / 2
#
#---------------------------------
.text
caterer:
	#p = (n^2 + n + 2) / 2
	addi	t0 a0 0	    #copy input
	addi	t0 t0 -1    #pre-decrement loop counter to compensate for greater than/equal check
    addi    t1 zero 0   #reset t1

multLoop:                   #this loop calculates n^2 by doing repeated addition
        addi 	t0 t0 -1    #decrement loop counter
        add     t1 t1 a0    #result = result +n
        bge  	t0 zero multLoop #if loop counter >= 0: continue

	add     t1 t1 a0 	#n^2 + n
	addi	t1 t1 2     #n^2 + n + 2
	srli    t1 t1 1     #(n^2 + n + 2)/2
	
    addi	a0 t1 0     #place result in return register
    ret                 #you are NOT required to translate this instruction in the MIPS->WASM lab
