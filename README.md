# ⚙️ RISC-V to WebAssembly Translator

![C](https://img.shields.io/badge/C-00599C?style=for-the-badge&logo=c&logoColor=white)
![WASM](https://img.shields.io/badge/WebAssembly-654FF0?style=for-the-badge&logo=webassembly&logoColor=white)
![Assembly](https://img.shields.io/badge/RISC--V-5E5E5E?style=for-the-badge&logo=risc-v&logoColor=white)

> **A low-level static binary translator that compiles RISC-V assembly directly into WebAssembly (WASM) bytecode.**

---

### 💡 Project Overview
Modern web browsers run WebAssembly, a stack-based virtual machine. However, most systems software is written for register-based architectures like RISC-V. This project bridges that gap by implementing a **One-Pass Compiler** that translates RISC-V instructions into equivalent WASM opcodes.

Unlike tools that rely on LLVM or Emscripten, this translator was built from scratch in **C**, requiring a deep understanding of binary encoding (LEB128), instruction set architectures (ISA), and virtual machine stack management.

---

### 🛠️ Technical Implementation

#### 1. Cross-Architecture Translation (Register vs. Stack)
The core challenge was mapping the **RISC-V Register Machine** (32 general-purpose registers) to the **WASM Stack Machine**.
* **Solution:** Developed a modular decoder to simulate a register file within WASM's linear memory.
* **Mechanism:** Every RISC-V instruction (e.g., `add t0, t1, t2`) is lowered into a sequence of WASM stack operations:
    1.  `local.get` (Load operand 1)
    2.  `local.get` (Load operand 2)
    3.  `i32.add` (Execute Opcode)
    4.  `local.set` (Store result)

#### 2. Data Compression (LEB128)
WebAssembly requires integers to be compressed using **Little Endian Base 128 (LEB128)** format.
* **Variable-Byte Encoding:** Architected a custom encoding engine to bit-pack instruction arguments dynamically during the translation pass, ensuring minimal binary size and memory efficiency.

#### 3. Control Flow Analysis
RISC-V uses arbitrary jumps (`j`, `bne`), whereas WASM uses structured control flow (`block`, `loop`, `br`).
* **Algorithm:** Implemented complex control flow analysis to map unstructured RISC-V branching (forward/backward jumps) into valid, nested WASM control blocks.

---

### 💻 Supported Instructions

| Instruction Type | RISC-V Examples | Mapped WASM Opcode |
| :--- | :--- | :--- |
| **Arithmetic** | `add`, `sub`, `mul` | `i32.add`, `i32.sub`, `i32.mul` |
| **Logical** | `and`, `or`, `xor`, `sll` | `i32.and`, `i32.or`, `i32.xor`, `i32.shl` |
| **Memory** | `lw`, `sw` | `i32.load`, `i32.store` |
| **Control Flow** | `bge`, `blt`, `beq` | `br_if` (Branching Logic) |

---

Translate a RISC-V assembly file:
./riscv2wasm input.s -o output.wasm

⚖️ Credits & Academic Context
This project was developed as part of the CMPUT 229: Computer Organization & Architecture coursework at the University of Alberta.

Base Framework: The initial skeleton code (file parsing, basic structs) was provided by the Course Staff (Prof. J. Nelson / Prof. Rob. Hackman).

Implementation: The core translation logic—including the LEB128 encoding, Stack-Register mapping, and Control Flow Analysis algorithms—was implemented by Ujjawal Pratap Singh.

<div align="center"> <b>Engineered by Ujjawal Pratap Singh</b> </div>
