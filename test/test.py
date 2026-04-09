import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):

    dut._log.info("Starting simple test (bypass)")

    # Clock
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # Apply some random stimulus
    dut.uio_in.value = 0b10000110  # some LUT config

    for i in range(4):
        dut.ui_in.value = i
        await ClockCycles(dut.clk, 5)

    dut._log.info("Test completed successfully ✅")
