`timescale 1ns/1ps

module tb;

    reg clk;
    reg rst_n;
    reg ena;

    reg [7:0] ui_in;
    reg [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    tt_um_4plc dut (
        .clk(clk),
        .rst_n(rst_n),
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .uio_in(uio_in),
        .ena(ena)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        ena   = 1;
        ui_in = 0;
        uio_in = 0;

        #20;
        rst_n = 1;

        // simple stimulus
        uio_in = 8'b10000110; // AND + XOR config
        ui_in  = 8'b00001111;

        #100;

        $finish;
    end

endmodule
