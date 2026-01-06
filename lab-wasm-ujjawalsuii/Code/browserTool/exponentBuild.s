.data
input1: .word 2
input2: .word 5
input3: .word 0
input4: .word 0
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
#---------------------------------
# exponent
#
# calculates an exponent using repeated addition
# idea:
# do each left most multiplication first and then next
# multiplication pair will be result term * next term on the right
#
# ex: x * x * x
#
# == (x * x) * x
# == (x^2) * x
#
#
# inputs:
#   a0: x
#   a1: y
# output:
#   a0: x^y
#
#---------------------------------
.text
exponent:

    addi    s5 s5 1
    beq     a1 zero done    #if input == x^0: return 1

	addi	s5 a0 0         #copy orig input val to use for additions
    addi	s6 a0 0         #copy orig input val so first loop doesnt calc a val
    sub     a0 a0 a0        #clear the input, only for the first outer loop iteration though

outerLoop:

        add     s4 zero s5      #reset the inner loop counter
        addi	s4 s4 -1        #pre-decrement inner loop counter to compensate for greater than/equal check
        addi	a1 a1 -1        #decrement outer loop counter
        sub 	s5 s5 s5        #reset the accumulator value

    seriesLoop:
        addi	s4 s4 -1        #decrement inner loop counter
        add     s5 s5 a0        #new-a0 <- orig-a0 + orig-a0
        bge 	s4 zero seriesLoop   #if s4 >= 0: continue

        add     a0 zero s6      #only want to start gathering results on loops past this point
        bge 	a1 zero outerLoop    #if a1 >= 0: continue
done:
    add     a0 zero s5      #place result in return register
    jalr    zero ra 0
