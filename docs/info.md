# 4-bit Tiny CPU

## What is this?
This project implements a simple 4-bit accumulator-based CPU designed for Tiny Tapeout.

It includes:
- 4-bit accumulator
- 4-bit program counter
- Instruction memory (16 x 8)
- Data memory (16 x 4)
- FSM-based control unit
- ALU supporting arithmetic and branching

---

## How it works
The CPU operates using a simple fetch-execute-writeback cycle:

1. **Fetch**: Instruction is read from instruction memory using the program counter (PC)
2. **Execute**: Instruction is decoded and operation is performed
3. **Writeback**: Results are stored and PC is updated

Supported instructions:
- `LDA` – Load accumulator from memory
- `STA` – Store accumulator to memory
- `ADD` – Add memory value to accumulator
- `SUB` – Subtract memory value from accumulator
- `JMP` – Unconditional jump
- `JZ`  – Jump if zero flag is set
- `JC`  – Jump if carry flag is set

The default program increments a value stored in memory continuously.

---

## How to test
The CPU runs automatically after reset.

- Apply clock and release reset
- Observe `uo_out[3:0]` → accumulator value
- Observe `uio_out` → program counter and flags

The accumulator should increment over time as the program executes.

---

## External hardware
No external hardware is required.
