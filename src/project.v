`default_nettype none

module tt_um_4plc (

    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    // -----------------------------
    // LUT configs
    // -----------------------------
    wire [3:0] lut0 = uio_in[3:0];   // PLC0
    wire [3:0] lut1 = uio_in[7:4];   // PLC1

    wire [3:0] lut2 = lut0;          // reuse
    wire [3:0] lut3 = lut1;          // reuse

    // -----------------------------
    // Inputs
    // -----------------------------
    wire a0 = ui_in[0];
    wire b0 = ui_in[1];

    wire a1 = ui_in[2];
    wire b1 = ui_in[3];

    // -----------------------------
    // LUT function
    // -----------------------------
    function [0:0]lut2_func;
        input [3:0] lut;
        input a, b;
        begin
            case ({b,a})
                2'b00: lut2_func = lut[0];
                2'b01: lut2_func = lut[1];
                2'b10: lut2_func = lut[2];
                2'b11: lut2_func = lut[3];
                default: lut2_func = 1'b0;
            endcase
        end
    endfunction

    // -----------------------------
    // PLC0 & PLC1
    // -----------------------------
    wire p0 = lut2_func(lut0, a0, b0);
    wire p1 = lut2_func(lut1, a1, b1);

    // -----------------------------
    // PLC2
    // -----------------------------
    wire p2 = lut2_func(lut2, p0, p1);

    // -----------------------------
    // PLC3
    // -----------------------------
    wire p3 = lut2_func(lut3, p1, p2);

    // -----------------------------
    // Output
    // -----------------------------
    assign uo_out = {4'b0, p3, p2, p1, p0};

endmodule

`default_nettype wire
