# Tiny4 CPU with Serial Loader

## What is this?
This project implements a compact 4-bit accumulator-based CPU designed for Tiny Tapeout.

It features a minimal Harvard architecture with a serial instruction loading interface, optimized for area efficiency (~170 standard cells).

### Key Features
- 4-bit accumulator (ACC)
- 3-bit program counter (8 instructions)
- Instruction memory (8 × 8)
- Data memory (16 × 4)
- FSM-based control unit (Fetch–Execute–Writeback)
- ALU with arithmetic and branching support
- Serial instruction loader (runtime programmability)

---

## Instruction Set

The CPU supports the following 8 instructions:

| Opcode | Instruction | Description |
|--------|------------|-------------|
| 000    | NOP        | No operation |
| 001    | LDA addr   | Load ACC from memory |
| 010    | STA addr   | Store ACC to memory |
| 011    | ADD addr   | ACC = ACC + memory |
| 100    | SUB addr   | ACC = ACC - memory |
| 101    | JMP addr   | Unconditional jump |
| 110    | JZ addr    | Jump if zero flag is set |
| 111    | JC addr    | Jump if carry flag is set |

---

## How it works

The CPU operates in a 3-stage cycle:

1. **Fetch**  
   Instruction is fetched from instruction memory using the program counter (PC)

2. **Execute**  
   Instruction is decoded and the ALU or control logic performs the operation

3. **Writeback**  
   Results are stored, flags are updated, and PC is modified

---

## Programming the CPU (Serial Loader)

Instructions are loaded serially using the input pins:

- `ui[0]` → LOAD_MODE  
  - `1`: Load instructions  
  - `0`: Execute program  

- `ui[1]` → LOAD_CLK  
  - Rising edge shifts in data  

- `ui[2]` → DATA_IN  
  - Serial instruction bit (MSB first)

### Loading Process
1. Set `LOAD_MODE = 1`
2. Shift 8 bits per instruction using `LOAD_CLK`
3. Instructions are stored sequentially in memory
4. Set `LOAD_MODE = 0` to begin execution

---

## Outputs

- `uo_out[3:0]` → Accumulator (ACC)
- `uio_out`:
  - `[2:0]` → Program Counter (PC)
  - `[3]` → Zero flag
  - `[4]` → Carry flag

---

## Default Behavior

After reset:
- Memory is initialized with a simple program
- The CPU executes continuously
- Example behavior: incrementing values in memory

---

## How to test

1. Apply clock and release reset  
2. Optionally load a custom program using the serial interface  
3. Observe:
   - ACC on `uo_out[3:0]`
   - PC and flags on `uio_out`

The accumulator should update based on the loaded program.

---

## External hardware

No external hardware is required.

---

## Design Notes

- Designed to fit within Tiny Tapeout constraints
- Synthesized size: ~170 standard cells
- Optimized instruction memory (8 entries) to reduce area
- Minimal control logic using a compact FSM

---

## Why this project?

This project demonstrates:
- Custom CPU design from scratch  
- Instruction set architecture (ISA) design  
- FSM-based control unit implementation  
- Hardware optimization for strict area constraints  

All within a highly constrained silicon environment.
