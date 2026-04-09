import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


# ================================
# LUT reference model
# ================================
def lut_eval(lut, a, b):
    idx = (b << 1) | a
    return (lut >> idx) & 1


@cocotb.test()
async def test_project(dut):

    dut._log.info("=== START 4-PLC GLS TEST ===")

    # ================================
    # Clock
    # ================================
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # ================================
    # Reset
    # ================================
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 2)
    await Timer(1, unit="ns")   # ⭐ important for GLS

    # ================================
    # TEST SET 1: XOR / AND
    # ================================
    dut._log.info("Test Set 1: XOR / AND")

    lut0 = 0b0110  # XOR
    lut1 = 0b1000  # AND

    dut.uio_in.value = (lut1 << 4) | lut0

    await ClockCycles(dut.clk, 2)
    await Timer(1, unit="ns")

    for i in range(4):

        val = (i << 2) | i
        dut.ui_in.value = val

        await ClockCycles(dut.clk, 1)
        await Timer(1, unit="ns")   # ⭐ GLS settle time

        # Extract inputs
        a0 = (val >> 0) & 1
        b0 = (val >> 1) & 1
        a1 = (val >> 2) & 1
        b1 = (val >> 3) & 1

        # Expected outputs
        p0 = lut_eval(lut0, a0, b0)
        p1 = lut_eval(lut1, a1, b1)
        p2 = lut_eval(lut0, p0, p1)
        p3 = lut_eval(lut1, p1, p2)

        out = dut.uo_out.value.integer

        dut._log.info(
            f"Input={i:02b} | OUT={out:04b} | EXP={p3}{p2}{p1}{p0}"
        )

        assert ((out >> 0) & 1) == p0, "PLC0 mismatch"
        assert ((out >> 1) & 1) == p1, "PLC1 mismatch"
        assert ((out >> 2) & 1) == p2, "PLC2 mismatch"
        assert ((out >> 3) & 1) == p3, "PLC3 mismatch"

    # ================================
    # TEST SET 2: OR / XOR
    # ================================
    dut._log.info("Test Set 2: OR / XOR")

    lut0 = 0b1110  # OR
    lut1 = 0b0110  # XOR

    dut.uio_in.value = (lut1 << 4) | lut0

    await ClockCycles(dut.clk, 2)
    await Timer(1, unit="ns")

    for i in range(4):

        val = (i << 2) | i
        dut.ui_in.value = val

        await ClockCycles(dut.clk, 1)
        await Timer(1, unit="ns")

        a0 = (val >> 0) & 1
        b0 = (val >> 1) & 1
        a1 = (val >> 2) & 1
        b1 = (val >> 3) & 1

        p0 = lut_eval(lut0, a0, b0)
        p1 = lut_eval(lut1, a1, b1)
        p2 = lut_eval(lut0, p0, p1)
        p3 = lut_eval(lut1, p1, p2)

        out = dut.uo_out.value.integer

        assert ((out >> 0) & 1) == p0
        assert ((out >> 1) & 1) == p1
        assert ((out >> 2) & 1) == p2
        assert ((out >> 3) & 1) == p3

    # ================================
    # TEST SET 3: EDGE CASES
    # ================================
    dut._log.info("Test Set 3: EDGE")

    lut0 = 0b0000  # always 0
    lut1 = 0b1111  # always 1

    dut.uio_in.value = (lut1 << 4) | lut0

    await ClockCycles(dut.clk, 2)
    await Timer(1, unit="ns")

    for i in range(4):

        val = (i << 2) | i
        dut.ui_in.value = val

        await ClockCycles(dut.clk, 1)
        await Timer(1, unit="ns")

        out = dut.uo_out.value.integer

        assert ((out >> 0) & 1) == 0, "PLC0 not zero"
        assert ((out >> 1) & 1) == 1, "PLC1 not one"

    dut._log.info("=================================")
    dut._log.info("ALL GLS TESTS PASSED ✅")
    dut._log.info("=================================")
