# run.sh
# Author: Kristen Newbury
# Date: August 23 2017
#
# usage:
#        ./run.sh SUBROUTINE_FILENAME MAIN_FILENAME [1st parameter] [2nd parameter] [3rd parameter] [4th parameter]
#
#
# all parameters are optional. If not specified, their default value is 0.
#
# Takes a subroutine(in a file by itself -no main label) and
# a main file that calls the subroutine (in its own separate file) and provides the result with input
# input is supplied via the command line
# run.sh result: generates functioning RISC-V program by concatenating the two provided files
# as well as the inputs(-> which becomes word(s) in the .data segment that the main program may access)
#
#

#checks to see if any parameters were supplied, for any that were not, set to default values of 0
if [ -z "$3" ]; then
    a=0
else
    a=$3
fi
if [ -z "$4" ]; then
    b=0
else
    b=$4
fi
if [ -z "$5" ]; then
    c=0
else
    c=$5
fi
if [ -z "$6" ]; then
    d=0
else
    d=$6
fi

# places all input args into program, even if they are 0's/not necessary
# it will be the program's responsibility to use/not use these, but to keep this generic, up to 4 args
# may optionally be provided
echo ".data" > ${1%.s}Build.s
echo "input1: .word $a" >> ${1%.s}Build.s
echo "input2: .word $b" >> ${1%.s}Build.s
echo "input3: .word $c" >> ${1%.s}Build.s
echo "input4: .word $d" >> ${1%.s}Build.s
cat $2  | sed '/input1: .word/d' | sed '/input2: .word/d'>> ${1%.s}Build.s
cat $1 >> ${1%.s}Build.s

rars ${1%.s}Build.s nc | sed '$d' | sed '$d'
