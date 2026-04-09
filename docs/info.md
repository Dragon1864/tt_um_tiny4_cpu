# 4-PLC Configurable Logic Fabric

## What is this?
This project implements a compact configurable logic fabric using 4 programmable logic cells (PLCs), designed for Tiny Tapeout.

Each PLC is a 2-input lookup table (LUT) capable of implementing any Boolean function of two variables. The design supports chaining between PLCs, allowing construction of more complex logic functions.

The architecture is intentionally minimal and optimized for very low area (~70–100 standard cells).

---

## Key Features

- 4 programmable logic cells (PLCs)
- Each PLC implements a 2-input LUT (4-bit truth table)
- Supports combinational logic chaining between PLCs
- Fully configurable via input pins (no internal memory required)
- Extremely small area footprint
- Deterministic and easy to verify

---

## Architecture

The design consists of 4 PLCs connected as follows:
