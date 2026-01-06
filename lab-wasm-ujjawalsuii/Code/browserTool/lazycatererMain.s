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
input1: .word 1
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
