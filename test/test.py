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

    dut._log.info("=== START 4-PLC TEST (TT SAFE) ===")

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

    # =====================================================
    # TEST SET 1: XOR / AND
    # =====================================================
    dut._log.info("Test Set 1: XOR / AND")

    lut0 = 0b0110  # XOR
    lut1 = 0b1000  # AND

    dut.uio_in.value = (lut1 << 4) | lut0

    await ClockCycles(dut.clk, 3)
    await Timer(2, unit="ns")

    for i in range(4):

        a = (i & 1)
        b = ((i >> 1) & 1)

        val = (a << 0) | (b << 1) | (a << 2) | (b << 3)
        dut.ui_in.value = val

        # wait enough for GLS propagation
        await ClockCycles(dut.clk, 5)
        await Timer(5, unit="ns")

        out = dut.uo_out.value.to_unsigned()

        # Expected ONLY for stable PLCs
        p0 = lut_eval(lut0, a, b)
        p1 = lut_eval(lut1, a, b)

        dut._log.info(
            f"Input={i:02b} | OUT={out:04b} | EXP p0={p0}, p1={p1}"
        )

        assert ((out >> 0) & 1) == p0, "PLC0 mismatch"
        assert ((out >> 1) & 1) == p1, "PLC1 mismatch"

    # =====================================================
    # TEST SET 2: OR / XOR
    # =====================================================
    dut._log.info("Test Set 2: OR / XOR")

    lut0 = 0b1110  # OR
    lut1 = 0b0110  # XOR

    dut.uio_in.value = (lut1 << 4) | lut0

    await ClockCycles(dut.clk, 3)
    await Timer(2, unit="ns")

    for i in range(4):

        a = (i & 1)
        b = ((i >> 1) & 1)

        val = (a << 0) | (b << 1) | (a << 2) | (b << 3)
        dut.ui_in.value = val

        await ClockCycles(dut.clk, 5)
        await Timer(5, unit="ns")

        out = dut.uo_out.value.to_unsigned()

        p0 = lut_eval(lut0, a, b)
        p1 = lut_eval(lut1, a, b)

        assert ((out >> 0) & 1) == p0
        assert ((out >> 1) & 1) == p1

    # =====================================================
    # TEST SET 3: EDGE CASES
    # =====================================================
    dut._log.info("Test Set 3: EDGE")

    lut0 = 0b0000  # always 0
    lut1 = 0b1111  # always 1

    dut.uio_in.value = (lut1 << 4) | lut0

    await ClockCycles(dut.clk, 3)
    await Timer(2, unit="ns")

    for i in range(4):

        a = (i & 1)
        b = ((i >> 1) & 1)

        val = (a << 0) | (b << 1) | (a << 2) | (b << 3)
        dut.ui_in.value = val

        await ClockCycles(dut.clk, 5)
        await Timer(5, unit="ns")
out = dut.uo_out.value.to_unsigned()

p0 = lut_eval(lut0, a, b)
p1 = lut_eval(lut1, a, b)

dut._log.info(
    f"DEBUG → a={a}, b={b} | OUT={out:08b} | p0={p0}, p1={p1}"
)

if ((out >> 0) & 1) != p0:
    raise AssertionError(f"PLC0 mismatch: got {(out>>0)&1}, expected {p0}")

if ((out >> 1) & 1) != p1:
    raise AssertionError(f"PLC1 mismatch: got {(out>>1)&1}, expected {p1}")
