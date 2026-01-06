.data
input1: .word 6
input2: .word 0
input3: .word 0
input4: .word 0
#-------------------------------
# lazycatererMain
#
# Calls lazycaterer subroutine, providing the args, and then prints the result
#
# input: number of cuts to make on a disk
# output: number of sections that result from performing x number of intersecting cuts on the disk
#
#-------------------------------
.data
#default input for this program so that it will not crash if lazycaterer is manually pasted into it
.text	
main:

    lw      a0 input1       #provide arg to caterer
    call    caterer         #call subroutine caterer

	addi	a7 zero 1
	ecall

    addi    a0 zero 0x0a    #print newline
    addi	a7 zero 11
	ecall

	addi	a7 zero 10      #exit program syscall
	ecall
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
