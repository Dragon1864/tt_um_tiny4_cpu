import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


# ================================
# Helper: Load one byte serially
# ================================
async def load_byte(dut, data):
    for i in range(7, -1, -1):
        dut.ui_in[2].value = (data >> i) & 1  # DATA_IN
        dut.ui_in[1].value = 1               # LOAD_CLK rising edge
        await ClockCycles(dut.clk, 1)
        dut.ui_in[1].value = 0
        await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start Test")

    # Start clock (10us period)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # ================================
    # Reset
    # ================================
    dut._log.info("Resetting DUT")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # ================================
    # Enter LOAD MODE
    # ================================
    dut._log.info("Entering Load Mode")
    dut.ui_in[0].value = 1  # LOAD_MODE = 1

    # Program:
    # LDA 1
    # ADD 1
    # STA 2
    # JMP 1
    await load_byte(dut, 0b00100001)  # LDA [1]
    await load_byte(dut, 0b01100001)  # ADD [1]
    await load_byte(dut, 0b01000010)  # STA [2]
    await load_byte(dut, 0b10100001)  # JMP 1

    # Exit load mode
    dut.ui_in[0].value = 0

    dut._log.info("Program Loaded. Running CPU...")

    # ================================
    # Run CPU
    # ================================
    await ClockCycles(dut.clk, 50)

    # ================================
    # Check ACC behavior
    # ================================
    acc = dut.uo_out.value.integer & 0xF
    dut._log.info(f"Final ACC = {acc}")

    # Expect ACC > 1 (should be incrementing)
    assert acc > 1, f"ACC did not increment properly, got {acc}"

    dut._log.info("Test Passed ✅")
