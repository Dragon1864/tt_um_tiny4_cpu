`default_nettype none
`timescale 1ns / 1ps

module tb ();

  // Dump waveform
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
  end

  // Signals
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Instantiate YOUR CPU
  tt_um_tiny4_cpu dut (
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .ui_in(ui_in),
      .uo_out(uo_out),
      .uio_in(uio_in),
      .uio_out(uio_out),
      .uio_oe(uio_oe),
      .ena(ena),
      .clk(clk),
      .rst_n(rst_n)
  );

  // Clock generation (10ns period)
  always #5 clk = ~clk;

  // Monitor signals (VERY useful)
  initial begin
    $display("Time\tPC\tACC\tZ\tC");
    $monitor("%0t\t%0d\t%0d\t%b\t%b",
        $time,
        uio_out[3:0],   // PC
        uo_out[3:0],    // ACC
        uio_out[4],     // Z
        uio_out[5]      // C
    );
  end

  // Test sequence
  initial begin
    // Init
    clk = 0;
    rst_n = 0;
    ena = 1;
    ui_in = 0;     // NOT USED in your design
    uio_in = 0;    // NOT USED

    // Apply reset
    #20;
    rst_n = 1;

    // Run CPU for some cycles
    #500;

    // Finish
    $finish;
  end

endmodule
