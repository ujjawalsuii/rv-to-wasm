#
# CMPUT 229 Student Submission License
# Version 1.0
# Copyright 2019 <UJJAWAL PRATAP SINGH>
#
# Redistribution is forbidden in all circumstances. Use of this
# software without explicit authorization from the author or CMPUT 229
# Teaching Staff is prohibited.
#
# This software was produced as a solution for an assignment in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. This solution is confidential and remains confidential 
# after it is submitted for grading.
#
# Copying any part of this solution without including this copyright notice
# is illegal.
#
# If any portion of this software is included in a solution submitted for
# grading at an educational institution, the submitter will be subject to
# the sanctions for plagiarism at that institution.
#
# If this software is found in any public website or public repository, the
# person finding it is kindly requested to immediately report, including 
# the URL or other repository locating information, to the following email
# address:
#
#          cmput229@ualberta.ca
#
#---------------------------------------------------------------
# CCID:                 <upsingh>
# Lecture Section:      <LEC A1 - 51634>
# Instructor:           <Rob Hackman>
# Lab Section:          <LAB D04 - 54737>
# Teaching Assistant:   <    >
#---------------------------------------------------------------
# 

.include "common.s"

#----------------------------------
#        STUDENT SOLUTION
#----------------------------------

.data
    # Tables to store branch target counts
    # Max 2000 instructions * 1 byte per instruction is sufficient for counts < 255 and
    # We basically allocate 2048 bytes for alignment
fwd_counts: .space 2048
bwd_counts: .space 2048

.text

#-------------------------------------------------------------------------------
# RISCVtoWASM
#
# Translates the binary representation of a RISC-V program into 
# the binary representation of a WASM program
# 
# Arguments:
#   a0: pointer to RISC-V binary (ends with 0xFFFFFFFF)
#   a1: pointer to output WASM buffer
# Return:
#   a0: Number of bytes generated
#-------------------------------------------------------------------------------
RISCVtoWASM:
    addi    sp, sp, -28
    sw      ra, 0(sp)
    sw      s0, 4(sp)   # Total bytes written counter
    sw      s1, 8(sp)   # Current output pointer (a1)
    sw      s2, 12(sp)  # Current input pointer (a0)
    sw      s3, 16(sp)  # Start of input pointer (for index calc)
    sw      s4, 20(sp)  # Scratch
    sw      s5, 24(sp)  # Loop limit

    mv      s1, a1      # s1 =Output Pointer
    mv      s2, a0      # s2 = Input Pointer
    mv      s3, a0      # s3= Start of Input
    li      s0, 0       # Total bytes = 0
    li      s5, -1      # Sentinel 0xFFFFFFFF

    # 1. Generate Branch Target Tables
    jal     ra, generateTargetTable

    # 2. Translation Loop
translate_loop:
    lw      s4, 0(s2)           # Load instruction
    beq     s4, s5, translate_done # If sentinel, we basically finish

    # Step 1: Insert Control Flow Opcodes
    # Check if current instruction is a target
    mv      a0, s3              # Program start
    mv      a1, s2              # Current address
    
    # Check Forward Target
    li      a2, 1               # Forward flag
    jal     ra, readTargetCount
    mv      t0, a0              # t0=count
emit_ends:
    beq     t0, zero, check_loops
    li      a0, 0x0b            # WASM end opcode
    sb      a0, 0(s1)           # Write the byte
    addi    s1, s1, 1
    addi    s0, s0, 1
    addi    t0, t0, -1
    j       emit_ends

check_loops:
    # Check Backward Targets (needs loop)
    mv      a0, s3
    mv      a1, s2
    li      a2, 0               # backward flag
    jal     ra, readTargetCount
    mv      t0, a0
emit_loops:
    beq     t0, zero, decode_inst
    li      a0, 0x03            # WASM loop opcode
    sb      a0, 0(s1)
    addi    s1, s1, 1
    addi    s0, s0, 1
    li      a0, 0x40            # loop block type
    sb      a0, 0(s1)
    addi    s1, s1, 1
    addi    s0, s0, 1
    addi    t0, t0, -1
    j       emit_loops

    # Step B: Decode and Translate Instruction
decode_inst:
    andi    t0, s4, 0x7F        # opcode (lowest 7 bits)
    
    # Check R-Type(0x33 = 51)
    li      t1, 51
    beq     t0, t1, handle_rtype

    # Check I-Type Arithmetic(0x13 = 19)
    li      t1, 19
    beq     t0, t1, handle_itype

    # Check Branch (0x63 = 99)
    li      t1, 99
    beq     t0, t1, handle_branch
    j       next_inst

handle_rtype:
    # Determine WASM opcode
    # rs1, rs2, rd logic handled in translateRType
    # We just need to pass the WASM opcode in a2
    
    srli    t2, s4, 12          
    andi    t2, t2, 0x7
    srli    t3, s4, 25          # funct7 is at bit 25
    andi    t3, t3, 0x7F
    
    # Map (funct3, funct7) -> WASM Opcode
    # Add: f3=0, f7=0 -> 0x6a (i32.add)
    # Sub: f3=0, f7=0x20 -> 0x6b (i32.sub)
    # Sll: f3=1, f7=0 -> 0x74 (i32.shl)
    # Slt: f3=2, f7=0 -> 0x48 (i32.lt_s)
    # Xor: f3=4, f7=0 -> 0x73 (i32.xor)
    # Srl: f3=5, f7=0 -> 0x76 (i32.shr_u)
    # Sra: f3=5, f7=0x20 -> 0x75 (i32.shr_s)
    # Or:  f3=6, f7=0 -> 0x72 (i32.or)
    # And: f3=7, f7=0 -> 0x71 (i32.and)
    # 

    li      a2, 0               # Default 0 (invalid)
    
    li      t4, 0
    beq     t2, t4, r_add_sub
    li      t4, 1
    beq     t2, t4, r_sll
    li      t4, 2
    beq     t2, t4, r_slt
    li      t4, 4
    beq     t2, t4, r_xor
    li      t4, 5
    beq     t2, t4, r_srl_sra
    li      t4, 6
    beq     t2, t4, r_or
    li      t4, 7
    beq     t2, t4, r_and
    j       call_rtype

r_add_sub:
    li      t4, 0x20
    beq     t3, t4, r_is_sub
    li      a2, 0x6a            # add
    j       call_rtype
r_is_sub:
    li      a2, 0x6b            # sub
    j       call_rtype

r_sll:
    li      a2, 0x74            # shl
    j       call_rtype

r_slt:
    li      a2, 0x48            # lt_s
    j       call_rtype

r_xor:
    li      a2, 0x73            # xor
    j       call_rtype

r_srl_sra:
    li      t4, 0x20
    beq     t3, t4, r_is_sra
    li      a2, 0x76            # shr_u (srl)
    j       call_rtype
r_is_sra:
    li      a2, 0x75            # shr_s (sra)
    j       call_rtype

r_or:
    li      a2, 0x72            # or
    j       call_rtype

r_and:
    li      a2, 0x71            # and
    j       call_rtype

call_rtype:
    mv      a0, s1
    mv      a1, s2
    # a2 already set
    jal     ra, translateRType
    add     s1, s1, a0          # Advance buffer
    add     s0, s0, a0          # Add count
    j       next_inst

handle_itype:
    # Determine WASM opcode based on funct3
    srli    t2, s4, 12
    andi    t2, t2, 0x7
    srli    t3, s4, 25          # funct7 (we basically needed for shifts)
    andi    t3, t3, 0x7F

    # Map funct3 -> WASM Opcode
    # Addi: f3=0 -> 0x6a (add)
    # Slti: f3=2 -> 0x48 (lt_s)
    # Xori: f3=4 -> 0x73 (xor)
    # Ori:  f3=6 -> 0x72 (or)
    # Andi: f3=7 -> 0x71 (and)
    # Slli: f3=1 -> 0x74 (shl)
    # Srli: f3=5, f7=0 -> 0x76 (shr_u)
    # Srai: f3=5, f7=0x20 -> 0x75 (shr_s)

    li      t4, 0
    beq     t2, t4, i_addi
    li      t4, 2
    beq     t2, t4, i_slti
    li      t4, 4
    beq     t2, t4, i_xori
    li      t4, 6
    beq     t2, t4, i_ori
    li      t4, 7
    beq     t2, t4, i_andi
    li      t4, 1
    beq     t2, t4, i_slli
    li      t4, 5
    beq     t2, t4, i_sr_sra
    j       next_inst

i_addi:
    li      a2, 0x6a
    j       call_itype
i_slti:
    li      a2, 0x48
    j       call_itype
i_xori:
    li      a2, 0x73
    j       call_itype
i_ori:
    li      a2, 0x72
    j       call_itype
i_andi:
    li      a2, 0x71
    j       call_itype
i_slli:
    li      a2, 0x74
    j       call_itype
i_sr_sra:
    li      t4, 0x20
    beq     t3, t4, i_is_srai
    li      a2, 0x76            # srli
    j       call_itype
i_is_srai:
    li      a2, 0x75            # srai
    j       call_itype

call_itype:
    mv      a0, s1
    mv      a1, s2
    # a2 set
    jal     ra, translateIType
    add     s1, s1, a0
    add     s0, s0, a0
    j       next_inst

handle_branch:
    # Map funct3 -> WASM Comparison Opcode
    srli    t2, s4, 12
    andi    t2, t2, 0x7
    
    # Beq: f3=0 -> 0x46 (eq)
    # Bne: f3=1 -> 0x47 (ne)
    # Blt: f3=4 -> 0x48 (lt_s)
    # Bge: f3=5 -> 0x4e (ge_s)
    
    li      t4, 0
    beq     t2, t4, b_beq
    li      t4, 1
    beq     t2, t4, b_bne
    li      t4, 4
    beq     t2, t4, b_blt
    li      t4, 5
    beq     t2, t4, b_bge
    j       next_inst

b_beq:
    li      a2, 0x46
    j       call_branch
b_bne:
    li      a2, 0x47
    j       call_branch
b_blt:
    li      a2, 0x48
    j       call_branch
b_bge:
    li      a2, 0x4e
    j       call_branch

call_branch:
    mv      a0, s1
    mv      a1, s2
    # a2 set
    jal     ra, translateBranch
    add     s1, s1, a0
    add     s0, s0, a0

next_inst:
    addi    s2, s2, 4           # Next instruction input
    j       translate_loop

translate_done:
    # Append return sequence, (return (get_local 0))
    # get_local 0
    li      t0, 0x20
    sb      t0, 0(s1)
    addi    s1, s1, 1
    li      t0, 0x00
    sb      t0, 0(s1)
    addi    s1, s1, 1
    # return
    li      t0, 0x0f
    sb      t0, 0(s1)
    addi    s1, s1, 1
    # end (module/func end)
    li      t0, 0x0b
    sb      t0, 0(s1)
    addi    s1, s1, 1
    
    addi    s0, s0, 4           # We just count these bytes

    mv      a0, s0              # Then we return total bytes
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    lw      s4, 20(sp)
    lw      s5, 24(sp)
    addi    sp, sp, 28
    ret


#-------------------------------------------------------------------------------
# Helper, map_reg_to_local
# Maps RISC-V register index to WASM local index
# Mapping,
# x10-x13 (a0-a3)-> 0, 1, 2, 3 (Parameters)
# x0-> -1 (Special case, use const 0)
# Others-> 4..30
# Input, a0 (RISC-V reg index 0-31)
# Output, a0 (WASM local index, or -1 if x0)
#-------------------------------------------------------------------------------
map_reg_to_local:
    beq     a0, zero, map_zero
    li      t0, 10
    beq     a0, t0, map_a0
    li      t0, 11
    beq     a0, t0, map_a1
    li      t0, 12
    beq     a0, t0, map_a2
    li      t0, 13
    beq     a0, t0, map_a3
    
    # Logic for others:
    # If reg < 10: local = reg + 3
    # If reg > 13: local = reg - 1
    li      t0, 10
    blt     a0, t0, map_low
    addi    a0, a0, -1
    ret
map_low:
    addi    a0, a0, 3
    ret
map_a0:
    li      a0, 0
    ret
map_a1:
    li      a0, 1
    ret
map_a2:
    li      a0, 2
    ret
map_a3:
    li      a0, 3
    ret
map_zero:
    li      a0, -1
    ret

#-------------------------------------------------------------------------------
# translateIType
# Translates I-Type instruction
# Logic, get_local(rs1) -> const(imm) -> opcode -> set_local(rd)
#-------------------------------------------------------------------------------
translateIType:
    addi    sp, sp, -20
    sw      ra, 0(sp)
    sw      s0, 4(sp)   # buffer
    sw      s1, 8(sp)   # wasm opcode
    sw      s2, 12(sp)  # inst
    sw      s3, 16(sp)  # byte count

    mv      s0, a0
    lw      s2, 0(a1)
    mv      s1, a2
    li      s3, 0

    # 1. Handle rs1 (get_local)
    srli    a0, s2, 15
    andi    a0, a0, 0x1F    # rs1
    jal     ra, map_reg_to_local
    li      t0, -1
    beq     a0, t0, i_rs1_zero
    
    # Emit get_local
    li      t1, 0x20
    sb      t1, 0(s0)
    addi    s0, s0, 1
    sb      a0, 0(s0)       # local index (assume < 127, 1 byte LEB)
    addi    s0, s0, 1
    addi    s3, s3, 2
    j       i_imm

i_rs1_zero:
    # Emit i32.const 0
    li      t1, 0x41
    sb      t1, 0(s0)
    addi    s0, s0, 1
    sb      zero, 0(s0)
    addi    s0, s0, 1
    addi    s3, s3, 2

i_imm:
    # 2. Handle Immediate (const)
    # Emit i32.const opcode
    li      t1, 0x41
    sb      t1, 0(s0)
    addi    s0, s0, 1
    addi    s3, s3, 1

    # Extract Immediate
    srli    a0, s2, 20     
    # Sign extend,,  
    # Current pos
    # We want them in 11:0 and sign extended
    srai    a0, s2, 20      # Arithmetic shift right moves them down and extends sign
    
    # Encode LEB128
    jal     ra, encodeLEB128
    
    # Write LEB bytes
    mv      t2, a1          # Count
    mv      t3, a0          # Bytes
i_leb_loop:
    beq     t2, zero, i_op
    andi    t4, t3, 0xFF
    sb      t4, 0(s0)
    addi    s0, s0, 1
    addi    s3, s3, 1
    srli    t3, t3, 8
    addi    t2, t2, -1
    j       i_leb_loop

i_op:
    # 3. Emit Operation Opcode
    sb      s1, 0(s0)
    addi    s0, s0, 1
    addi    s3, s3, 1

    # 4. Handle rd (set_local)
    srli    a0, s2, 7
    andi    a0, a0, 0x1F    # rd
    jal     ra, map_reg_to_local
    li      t0, -1
    beq     a0, t0, i_rd_zero   # If writing to x0 drop

    # Emit set_local
    li      t1, 0x21
    sb      t1, 0(s0)
    addi    s0, s0, 1
    sb      a0, 0(s0)
    addi    s0, s0, 1
    addi    s3, s3, 2
    j       i_done

i_rd_zero:
    # Emit drop (0x1A)
    li      t1, 0x1A
    sb      t1, 0(s0)
    addi    s0, s0, 1
    addi    s3, s3, 1

i_done:
    mv      a0, s3
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    addi    sp, sp, 20
    ret

#-------------------------------------------------------------------------------
# translateRType
# Translates R-Type instruction.
# Logic, get_local(rs1) -> get_local(rs2) -> opcode -> set_local(rd)
#-------------------------------------------------------------------------------
translateRType:
    addi    sp, sp, -20
    sw      ra, 0(sp)
    sw      s0, 4(sp)
    sw      s1, 8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)

    mv      s0, a0
    lw      s2, 0(a1)
    mv      s1, a2
    li      s3, 0

    # 1. rs1
    srli    a0, s2, 15
    andi    a0, a0, 0x1F
    jal     ra, map_reg_to_local
    li      t0, -1
    beq     a0, t0, r_rs1_zero
    li      t1, 0x20
    sb      t1, 0(s0)
    sb      a0, 1(s0)
    addi    s0, s0, 2
    addi    s3, s3, 2
    j       r_rs2
r_rs1_zero:
    li      t1, 0x41        # const
    sb      t1, 0(s0)
    sb      zero, 1(s0)     # 0
    addi    s0, s0, 2
    addi    s3, s3, 2

r_rs2:
    # 2. rs2
    srli    a0, s2, 20
    andi    a0, a0, 0x1F
    jal     ra, map_reg_to_local
    li      t0, -1
    beq     a0, t0, r_rs2_zero
    li      t1, 0x20
    sb      t1, 0(s0)
    sb      a0, 1(s0)
    addi    s0, s0, 2
    addi    s3, s3, 2
    j       r_op
r_rs2_zero:
    li      t1, 0x41
    sb      t1, 0(s0)
    sb      zero, 1(s0)
    addi    s0, s0, 2
    addi    s3, s3, 2

r_op:
    # 3. Opcode
    sb      s1, 0(s0)
    addi    s0, s0, 1
    addi    s3, s3, 1

    # 4. rd
    srli    a0, s2, 7
    andi    a0, a0, 0x1F
    jal     ra, map_reg_to_local
    li      t0, -1
    beq     a0, t0, r_rd_zero
    li      t1, 0x21        # set_local
    sb      t1, 0(s0)
    sb      a0, 1(s0)
    addi    s0, s0, 2
    addi    s3, s3, 2
    j       r_done
r_rd_zero:
    li      t1, 0x1A        # drop
    sb      t1, 0(s0)
    addi    s0, s0, 1
    addi    s3, s3, 1

r_done:
    mv      a0, s3
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    addi    sp, sp, 20
    ret

#-------------------------------------------------------------------------------
# translateBranch
# Translates Branch instruction.
# Forward, block ... [cmp] br_if 0
# Backward, [cmp] br_if 0 ... end
# This function only outputs, [get rs1] [get rs2] [cmp op] [br_if 0]
#-------------------------------------------------------------------------------
translateBranch:
    addi    sp, sp, -24
    sw      ra, 0(sp)
    sw      s0, 4(sp)
    sw      s1, 8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)
    sw      s4, 20(sp)  # Direction flag

    mv      s0, a0
    lw      s2, 0(a1)   # Instruction
    mv      s1, a2      # WASM Cmp Opcode
    li      s3, 0

    # Calculate Branch Offset to determine direction
    # B-Type Imm,
    # bit 31 ->12
    # bit 7 ->11
    # bit 3025-> 10:5
    # bit 11:8 -> 4:1
    
    srli    t0, s2, 31          # bit 31 (sign)
    slli    t0, t0, 12
    
    srli    t1, s2, 7
    andi    t1, t1, 1
    slli    t1, t1, 11
    or      t0, t0, t1
    
    srli    t1, s2, 25
    andi    t1, t1, 0x3F
    slli    t1, t1, 5
    or      t0, t0, t1
    
    srli    t1, s2, 8
    andi    t1, t1, 0xF
    slli    t1, t1, 1
    or      t0, t0, t1
    
    # Sign extend t0 from 13 bits
    slli    t0, t0, 19
    srai    t0, t0, 19      # t0=signed offset
    
    # Direction if offset<0 Backward (0) Else Forward (1)
    blt     t0, zero, b_backward
    li      s4, 1           # Forward
    j       b_start
b_backward:
    li      s4, 0           # Backward

b_start:
    # If Forward, Emit block (0x02)+type (0x40)
    beq     s4, zero, b_operands
    li      t1, 0x02
    sb      t1, 0(s0)
    addi    s0, s0, 1
    li      t1, 0x40
    sb      t1, 0(s0)
    addi    s0, s0, 1
    addi    s3, s3, 2

b_operands:
    # 1. rs1
    srli    a0, s2, 15
    andi    a0, a0, 0x1F
    jal     ra, map_reg_to_local
    li      t0, -1
    beq     a0, t0, b_rs1_zero
    li      t1, 0x20
    sb      t1, 0(s0)
    sb      a0, 1(s0)
    addi    s0, s0, 2
    addi    s3, s3, 2
    j       b_rs2
b_rs1_zero:
    li      t1, 0x41
    sb      t1, 0(s0)
    sb      zero, 1(s0)
    addi    s0, s0, 2
    addi    s3, s3, 2

b_rs2:
    # 2. rs2
    srli    a0, s2, 20
    andi    a0, a0, 0x1F
    jal     ra, map_reg_to_local
    li      t0, -1
    beq     a0, t0, b_rs2_zero
    li      t1, 0x20
    sb      t1, 0(s0)
    sb      a0, 1(s0)
    addi    s0, s0, 2
    addi    s3, s3, 2
    j       b_op
b_rs2_zero:
    li      t1, 0x41
    sb      t1, 0(s0)
    sb      zero, 1(s0)
    addi    s0, s0, 2
    addi    s3, s3, 2

b_op:
    # 3. Compare Opcode
    sb      s1, 0(s0)
    addi    s0, s0, 1
    addi    s3, s3, 1
    
    # 4. br_if 0
    li      t1, 0x0D    # br_if
    sb      t1, 0(s0)
    addi    s0, s0, 1
    sb      zero, 0(s0) # depth 0
    addi    s0, s0, 1
    addi    s3, s3, 2
    
    # 5. If Backward Emit 'end' (0x0b)
    bne     s4, zero, b_done
    li      t1, 0x0b
    sb      t1, 0(s0)
    addi    s0, s0, 1
    addi    s3, s3, 1

b_done:
    mv      a0, s3
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    lw      s4, 20(sp)
    addi    sp, sp, 24
    ret

#-------------------------------------------------------------------------------
# encodeLEB128
# Converts 12-bit twos complement to LEB128.
# Input, a0 (value)
# Output, a0 (LEB bytes packed), a1 (count)
#-------------------------------------------------------------------------------
encodeLEB128:
    addi    sp, sp, -4
    sw      s0, 0(sp)
    
    # Sign extend 12-bit just in case input is not 32-bit clean
    slli    a0, a0, 20
    srai    a0, a0, 20
    
    mv      t0, a0      # value
    li      t1, 0       # result word
    li      t2, 0       # count
    li      t3, 0       # shift for result packing

leb_loop:
    andi    t4, t0, 0x7F    # byte = val & 0x7F
    srai    t0, t0, 7       # val >>= 7
    
    # Check if done:
    # if (val == 0 && (byte & 0x40) == 0) -> done
    # if (val == -1 && (byte & 0x40) != 0) -> done
    
    beq     t0, zero, check_pos
    li      t5, -1
    beq     t0, t5, check_neg
    j       leb_cont

check_pos:
    andi    t6, t4, 0x40
    beq     t6, zero, leb_done_clean
    j       leb_cont

check_neg:
    andi    t6, t4, 0x40
    bne     t6, zero, leb_done_clean
    j       leb_cont

leb_cont:
    ori     t4, t4, 0x80    # set high bit (more bytes)
    sll     t5, t4, t3
    or      t1, t1, t5
    addi    t3, t3, 8
    addi    t2, t2, 1
    j       leb_loop

leb_done_clean:
    sll     t5, t4, t3
    or      t1, t1, t5
    addi    t2, t2, 1
    
    mv      a0, t1
    mv      a1, t2
    lw      s0, 0(sp)
    addi    sp, sp, 4
    ret

#-------------------------------------------------------------------------------
# Target Table Functions
# Scans the entire RISC-V program to find all branch instructions
# For each branch it calculates the target address and determines if it 
# is a forward or backward jump then populates the fwd_counts and bwd_counts  
# Arguments,
#   a0, Pointer to the binary representation of the RISC-V program.
# Return,
#   None as it populates global tables as a side effect
#-------------------------------------------------------------------------------

# generateTargetTable
# Loops through program, finds branches, updates counts
generateTargetTable:
    addi    sp, sp, -16
    sw      ra, 0(sp)
    sw      s0, 4(sp)   # Current Ptr
    sw      s1, 8(sp)   # Start Ptr
    sw      s2, 12(sp)  # Sentinel

    mv      s1, a0      # Save Start
    mv      s0, a0      # Current
    li      s2, -1

gt_loop:
    lw      t0, 0(s0)
    beq     t0, s2, gt_done

    andi    t1, t0, 0x7F
    li      t2, 99
    bne     t1, t2, gt_next

    # Decode Offset (Expanded to one instruction per line)
    # 1. Sign bit (31) -> 12
    srli    t3, t0, 31
    slli    t3, t3, 12
    
    # 2. Bit 7 -> 11
    srli    t4, t0, 7
    andi    t4, t4, 1
    slli    t4, t4, 11
    or      t3, t3, t4
    
    # 3. Bits 30:25 -> 10:5
    srli    t4, t0, 25
    andi    t4, t4, 0x3F
    slli    t4, t4, 5
    or      t3, t3, t4
    
    # 4. Bits 11:8 -> 4:1
    srli    t4, t0, 8
    andi    t4, t4, 0xF
    slli    t4, t4, 1
    or      t3, t3, t4
    
    # 5. Sign Extend
    slli    t3, t3, 19
    srai    t3, t3, 19

    # Calculate Target and Call Helper
    add     a1, s0, t3  # Target Address
    mv      a0, s1      # Start Address

    blt     t3, zero, gt_bwd
    li      a2, 1       # Forward
    j       gt_call
gt_bwd:
    li      a2, 0       # Backward

gt_call:
    jal     ra, incrTargetCount

gt_next:
    addi    s0, s0, 4
    j       gt_loop

gt_done:
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    addi    sp, sp, 16
    ret


# incrTargetCount
# a0, Start Ptr, a1, Target Addr, a2, Type (1=Fwd, 0=Bwd)
incrTargetCount:
    # Calculate Index, (Target-Start)/4
    sub     t0, a1, a0
    srli    t0, t0, 2
    
    # Check bounds
    li      t1, 2048
    bge     t0, t1, incr_err
    blt     t0, zero, incr_err

    beq     a2, zero, incr_bwd
    
    # Forward
    la      t1, fwd_counts
    add     t1, t1, t0
    lb      t2, 0(t1)
    addi    t2, t2, 1
    sb      t2, 0(t1)
    ret

incr_bwd:
    la      t1, bwd_counts
    add     t1, t1, t0
    lb      t2, 0(t1)
    addi    t2, t2, 1
    sb      t2, 0(t1)
    ret
incr_err:
    ret

# readTargetCount
# a0, Start Ptr, a1, Target Addr, a2, Type
readTargetCount:
    sub     t0, a1, a0
    srli    t0, t0, 2
    
    li      t1, 2048
    bge     t0, t1, read_zero
    blt     t0, zero, read_zero

    beq     a2, zero, read_bwd
    
    la      t1, fwd_counts
    add     t1, t1, t0
    lb      a0, 0(t1)
    ret
read_bwd:
    la      t1, bwd_counts
    add     t1, t1, t0
    lb      a0, 0(t1)
    ret
read_zero:
    li      a0, 0
    ret

