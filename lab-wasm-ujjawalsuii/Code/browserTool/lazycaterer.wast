get_local 0
i32.const 0
i32.add
set_local 22
get_local 22
i32.const -1
i32.add
set_local 22
i32.const 0
i32.const 0
i32.add
set_local 23
loop void
get_local 22
i32.const -1
i32.add
set_local 22
get_local 23
get_local 0
i32.add
set_local 23
get_local 22
i32.const 0
i32.ge_s
br_if 0
end
get_local 23
get_local 0
i32.add
set_local 23
get_local 23
i32.const 2
i32.add
set_local 23
get_local 23
i32.const 1
i32.shr_u
set_local 23
get_local 23
i32.const 0
i32.add
set_local 0
get_local 0
return
end
