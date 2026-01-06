get_local 11
i32.const 1
i32.add
set_local 11
block void
get_local 1
i32.const 0
i32.eq
br_if 0
get_local 0
i32.const 0
i32.add
set_local 11
get_local 0
i32.const 0
i32.add
set_local 12
get_local 0
get_local 0
i32.sub
set_local 0
loop void
i32.const 0
get_local 11
i32.add
set_local 10
get_local 10
i32.const -1
i32.add
set_local 10
get_local 1
i32.const -1
i32.add
set_local 1
get_local 11
get_local 11
i32.sub
set_local 11
loop void
get_local 10
i32.const -1
i32.add
set_local 10
get_local 11
get_local 0
i32.add
set_local 11
get_local 10
i32.const 0
i32.ge_s
br_if 0
end
i32.const 0
get_local 12
i32.add
set_local 0
get_local 1
i32.const 0
i32.ge_s
br_if 0
end
end
i32.const 0
get_local 11
i32.add
set_local 0
get_local 0
return
end
