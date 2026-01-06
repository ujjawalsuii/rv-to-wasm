#
# CMPUT 229 Public Materials License
# Version 1.0
#
# Copyright 2017 University of Alberta
# Copyright 2017 Kristen Newbury
# Copyright 2019 Abdulrahman Alattas
#
# This software is distributed to students in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the disclaimer below in the documentation
#    and/or other materials provided with the distribution.
#
# 2. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#-------------------------------
# WASM Translator - WASM Disassembler
# Author: Kristen Newbury
# Date: July 12 2017
# 
# RISC-V Modification
# Author: Abdulrahman Alattas
# Date: June 3, 2019
#
# Translates the code section of a .wasm file to
# a text representation (wast) format
#
# **uses a hardcoded index into the module
# for where to begin looking for the function body size**
#
# ends search on return opcode found - expectation that return is second last byte to print
#
#
#-------------------------------

.data
.align 2
 #for the representation of the provided .wasm file
binary:
    .space 5700

    addStr: .asciz "i32.add\n"
    orStr: .asciz "i32.or\n"
    andStr: .asciz "i32.and\n"
    subStr: .asciz "i32.sub\n"
    shlStr: .asciz "i32.shl\n"
    shrsStr: .asciz "i32.shr_s\n"
    shruStr: .asciz "i32.shr_u\n"
    eqStr: .asciz "i32.eq\n"
    gesStr: .asciz "i32.ge_s\n"
    constStr: .asciz "i32.const "
    loopStr: .asciz "loop "
    blockStr: .asciz "block "
    voidStr: .asciz "void\n"
    brifStr: .asciz "br_if "
    getlocalStr: .asciz "get_local "
    setlocalStr: .asciz "set_local "
    returnStr: .asciz "return\n"
    endStr: .asciz "end\n"
    unkStr: .asciz "???\n"

noFileStr:
.asciz "Couldn't open specified file.\n"
format:
.asciz "\n"

.text
main:

    lw      a0 0(a1)	# Put the filename pointer into a0
    li      a1 0		# Read Only
    li      a7 1024		# Open File

    ecall
    bltz	a0 main_err	# Negative means open failed

    # a0 contains the file descriptor
    la      a1 binary	# write into my binary space
    li      a2 2048	    # read a file of at max 2kb
    li      a7 63		# Read File Syscall
    ecall

    call    parseWASM

    j       main_done

main_err:
    la      a0 noFileStr
    li      a7 4
    ecall
main_done:

    li      a7 10      #exit program syscall
    ecall


#----------------------------------
#parseWASM:
#goes through all bytes and checks what they are and handles print logic
#
# input: a0: the number of bytes to loop over
#
# register usage:
#       s0: the pointer into the binary representation of the program
#       s1: return opcode, uses as sentinel for the rep of the program
#       s2: i32.const string address to do check for if we should print 1-4 following bytes
#       s3: the high bit of a byte interpreted as a literal, to check if we should keep searching for bytes to interpret as part of the literal
#       s4: max num of bytes to check to interpret as a literal for bytes following a i32.const opcode
#       s5: shift amount while gathering bytes from the literal following a i32.const
#       s6: each shifted byte in the rep of a literal as we gather its
#       s7: all of the bytes once gathered from the rep of the program that rep a literal
#
#----------------------------------
parseWASM:

    addi    sp sp -36
    sw      ra 0(sp)
    sw      s0 4(sp)
    sw      s1 8(sp)
    sw      s2 12(sp)
    sw      s3 16(sp)
    sw      s4 20(sp)
    sw      s5 24(sp)
    sw      s6 28(sp)
    sw      s7 32(sp)

    #parse all instructions
    la      s0 binary   #point at start of instructions
    #THIS IS HARDCODED AND MAY NEED TO CHANGE IF THE MODULE CONFIG(params ect) CHANGES
    addi    s0 s0 48    #skip the module statically provided bytes - 48 bytes are provided to students
    addi    s1 zero 0x0f

    mv      s3 zero
    la      s2 constStr    #for our check to gather next (!-4) bytes maybe
    li      s4 4           #safeguard against the number of bytes we will check to interpret as part of a literal following a i32.const

parseLoop:

    lbu     a0 0(s0)
    beq     s1 a0 parseDone       #ends on return opcode found
    addi    s0 s0 1

    call    checkOpcode             #check which opcode this was
    li      a7 4                    #print the returned str for the found opcode

    ecall
    beq     a0 s2 gatherLiteral     #if this was the const opcode, print it then possibly gather next 1-4 bytes
    bne     a1 zero printNext     #for the set/get_local and br_if instr's we know the next is a variable/break depth, so print it
    j       parseLoop

prepParseLoop:
    mv      a0 s7
    call    convertLEBtoDec
    mv      a0 a0           #print the result
    li      a7 1
    ecall
    la      a0 format       #print a newline
    li      a7 4
    ecall

    li      s4 4            #reset the safeguard counter
    mv      s7 zero         #clear regs used to gather the literal
    mv      s5 zero
    j       parseLoop

gatherLiteral:
    #we expect a literal to follow a i32.const opcode, so we do that check here
    #guaranteed to interpret at least 1 byte following an i32.const as a literal
    lbu     a0 0(s0)
    andi    s3 a0 0x80    #examine the highest bit to check for 'next indication'
    addi    s4 s4 -1
    sll     s6 a0 s5     #move the byte over
    addi    s5 s5 8
    or      s7 s7 s6

    addi    s0 s0 1
    bne     s3 zero gatherLiteral
    beq     s4 zero prepParseLoop     #safeguard in case the bytecode is incorrectly set, won't get stuck trying to look for literal bytes for forever - looks for max 4 following a i32.const
    j       prepParseLoop

printNext:
    #for instructions like get/set_local and br_if we will want to print the next byte as well
    lb      a0 0(s0)  #print the byte
    li      a7 1
    ecall
    la      a0 format  #print a newline
    li      a7 4
    ecall
    addi    s0 s0 1
    j       parseLoop

parseDone:
    #finishes on return - so prints this and one last next byte - (expected) end opcode.
    la      a0 returnStr
    li      a7 4
    ecall
    addi    s0 s0 1       #look for one more byte here
    lbu     s1 0(s0)
    li      s0 0x0b        #end
    la      a0 unkStr      #prematurely assume that this is not end opcode
    bne     s0 s1 lastNotEnd
    la      a0 endStr      #correct for if it actually was
lastNotEnd:
    li      a7 4
    ecall
    lw      ra 0(sp)
    lw      s0 4(sp)
    lw      s1 8(sp)
    lw      s2 12(sp)
    lw      s3 16(sp)
    lw      s4 20(sp)
    lw      s5 24(sp)
    lw      s6 28(sp)
    lw      s7 32(sp)
    addi    sp sp 36
    ret

#----------------------------------
#checkOpcode:
#checks opcode and returns the corresponding str address to print
#
# input:
#       a0: the byte to check opcode of
#
# register usage:
#       s0: opcode for the WASM instruction, used to check what this one is.
#
# output:
#       a0: the address of the string to print for this opcode
#       a1: flag for whether to print the next byte or not (for set/get_local and br_if instrs)
#----------------------------------
checkOpcode:
    addi    sp sp -4
    sw      s0 0(sp)

    mv      a1 zero

    li      s0 0x6a        #i32.add
    bne     s0 a0 notAdd
    la      a0 addStr
    j       opcodeDone

notAdd:
    li      s0 0x72        #i32.or
    bne     s0 a0 notOr
    la      a0 orStr
    j       opcodeDone

notOr:
    li      s0 0x71         #i32.and
    bne     s0 a0 notAnd
    la      a0 andStr
    j       opcodeDone

notAnd:
    li      s0 0x6b         #i32.sub
    bne     s0 a0 notSub
    la      a0 subStr
    j       opcodeDone

notSub:
    li      s0 0x74        #i32.shl
    bne     s0 a0 notShl
    la      a0 shlStr
    j       opcodeDone

notShl:
    li      s0 0x75         #i32.shr_s
    bne     s0 a0 notShrs
    la      a0 shrsStr
    j       opcodeDone

notShrs:
    li      s0 0x76         #i32.shr_u
    bne     s0 a0 notShru
    la      a0 shruStr
    j       opcodeDone

notShru:
    li      s0 0x46         #i32.eq
    bne     s0 a0 notEq
    la      a0 eqStr
    j       opcodeDone

notEq:
    li      s0 0x4e         #i32.ge_s
    bne     s0 a0 notGes
    la      a0 gesStr
    j       opcodeDone

notGes:
    li      s0 0x03         #loop
    bne     s0 a0 notLoop
    la      a0 loopStr
    j       opcodeDone

notLoop:
    li      s0 0x02         #block
    bne     s0 a0 notBlock
    la      a0 blockStr
    j       opcodeDone

notBlock:
    li      s0 0x40         #void
    bne     s0 a0 notVoid
    la      a0 voidStr
    j       opcodeDone

notVoid:
    li      s0 0x0d         #br_if
    bne     s0 a0 notBrIf
    la      a0 brifStr
    li      a1 1
    j       opcodeDone

notBrIf:
    li      s0 0x41         #i32.const
    bne     s0 a0 notConst
    la      a0 constStr
    j      opcodeDone

notConst:
    li      s0 0x20         #get_local
    bne     s0 a0 notGetLocal
    la      a0 getlocalStr
    li      a1 1
    j       opcodeDone

notGetLocal:
    li      s0 0x21         #set_local
    bne     s0 a0 notSetLocal
    la      a0 setlocalStr
    li      a1 1
    j       opcodeDone

notSetLocal:
    li      s0 0x0f         #return
    bne     s0 a0 notReturn
    la      a0 returnStr
    j       opcodeDone

notReturn:
    li      s0 0x0b         #end
    bne     s0 a0 notEnd
    la      a0 endStr
    j       opcodeDone

notEnd:
    la      a0 unkStr      #unknown

opcodeDone:
    lw      s0 0(sp)
    addi    sp sp 4
    ret
    
#----------------------------------
#convertLEBToDec:
#converts variable number of bytes in a word to decimal
# input:
#       a0: word, currently LEB128 format bytes
#
# register usage:
#       s0: the shift amount for the result bytes
#       s1: result
#       s2: high order bit of the byte, to check if we keep parsing or not
#       s3: low order 7 bits of each parsed byte
#       s4: LEB representation to be converted, bytes are 'chopped' off from here
#       s5: size of the input in number of (relevant)bytes
#       s6: single byte from the input value
#
# input:
#       a0: word, decimal representation to be printed ect.
#----------------------------------
convertLEBtoDec:
    addi    sp sp -28
    sw      s0 0(sp)
    sw      s1 4(sp)
    sw      s2 8(sp)
    sw      s3 12(sp)
    sw      s4 16(sp)
    sw      s5 20(sp)
    sw      s6 24(sp)

    mv      s4 a0
    mv      s0 zero   #shift = 0
    mv      s1 zero   #result = 0
    mv      s5 zero   #in order to find how many relevant bits this came in as, also use to align bytes of result (== size)

convertLEBLoop:
    andi    s6 s4 0xff    #byte
    srli    s4 s4 8
    andi    s3 s6 0x7f    #get low order 7 bits of byte
    andi    s2 s6 0x80    #get high order bit of byte
    sll     s3 s3 s0 
    or      s1 s1 s3
    addi    s0 s0 7
    addi    s5 s5 8
    bne     s2 zero convertLEBLoop
    sub     s2 s5 s0     #size - shift
    blez    s2 convertDone
    #((shift <size) && (sign bit of byte is set))
    andi    s6 s6 0x40
    beq     s6 zero convertDone
    #result = result | ((1 << 31) >>arithmetic (32 - numBits occupied by LEBresult))
    li      s2 32
    sub     s5 s2 s0
    li      s3 1
    slli    s3 s3 31
    sra     s3 s3 s5
    or      s1 s1 s3
convertDone:
    mv      a0 s1

    lw      s0 0(sp)
    lw      s1 4(sp)
    lw      s2 8(sp)
    lw      s3 12(sp)
    lw      s4 16(sp)
    lw      s5 20(sp)
    lw      s6 24(sp)
    addi    sp sp 28
    ret

