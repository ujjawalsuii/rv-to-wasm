#-------------------------------
# exponentMain
#
# Calls exponent subroutine, providing the args, and then prints the result
#
# input: x, y
# output: x^y
#
#-------------------------------
.data
#default inputs for this program so that it will not crash if exponent is manually pasted into it
input1: .word 1
input2: .word 1
.text
main:
        #provide args to subroutine exponent via script that places command line ints into spim .data segment
        lw      a0 input1
	    lw      a1 input2
        call    exponent        #call subroutine exponent

        add     a0 zero a0      #print the return value from exponent subroutine
	    addi	a7 zero 1
	    ecall

        addi    a0 zero 0x0a     #newline char
	    addi	a7 zero 11
	    ecall

        addi	a7 zero 10      #exit program syscall
	    ecall
