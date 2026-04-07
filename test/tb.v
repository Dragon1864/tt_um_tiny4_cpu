`timescale 1ns/1ps

module tb;

    reg clk;
    reg rst_n;
    reg ena;

    reg [7:0] ui_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg  [7:0] uio_in;

    // Instantiate DUT
    tiny4_cpu_loadable_optimized dut (
        .clk(clk),
        .rst_n(rst_n),
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .uio_in(uio_in),
        .ena(ena)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    // Task to shift one byte serially into instruction memory
    task load_byte(input [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                ui_in[2] = data[i];   // DATA_IN
                ui_in[1] = 1;         // LOAD_CLK rising edge
                #10;
                ui_in[1] = 0;
                #10;
            end
        end
    endtask

    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        ena = 0;
        ui_in = 0;
        uio_in = 0;

        // Reset
        #20;
        rst_n = 1;

        // ============================
        // ENTER LOAD MODE
        // ============================
        ui_in[0] = 1; // LOAD_MODE = 1

        // Load program:
        // LDA 1 → ADD 1 → STA 2 → JMP 0
        load_byte(8'b00100001); // LDA [1]
        load_byte(8'b01100001); // ADD [1]
        load_byte(8'b01000010); // STA [2]
        load_byte(8'b10100000); // JMP 0

        // ============================
        // EXIT LOAD MODE
        // ============================
        ui_in[0] = 0;

        ena = 1;

        // Run simulation
        #200;

        $finish;
    end

    // ============================
    // MONITOR SIGNALS
    // ============================
    initial begin
        $monitor("Time=%0t | ACC=%h | PC=%h | Z=%b | C=%b",
                 $time,
                 uo_out[3:0],
                 uio_out[2:0],
                 uio_out[3],
                 uio_out[4]);
    end

endmodule
