`timescale 1ns / 1ps

module tt_um_tiny4_cpu (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ================= CPU STATE =================
    reg [3:0] acc;
    reg [2:0] pc;
    reg       flag_z;
    reg       flag_c;
    reg [7:0] ir;
    reg [1:0] state;

    // ================= MEMORY =================
    reg [7:0] instr_mem [0:7];
    reg [3:0] data_mem  [0:15];

    // Registered memory read
    reg [3:0] mem_data;

    // FSM states
    localparam FETCH = 2'b00;
    localparam EXEC  = 2'b01;
    localparam WB    = 2'b10;

    // Opcodes
    wire [2:0] opcode  = ir[7:5];
    wire [3:0] operand = ir[3:0];

    localparam NOP = 3'b000;
    localparam LDA = 3'b001;
    localparam STA = 3'b010;
    localparam ADD = 3'b011;
    localparam SUB = 3'b100;
    localparam JMP = 3'b101;
    localparam JZ  = 3'b110;
    localparam JC  = 3'b111;

    // ============================================================
    // RESET + MEMORY INIT
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 0;
            pc <= 0;
            flag_z <= 0;
            flag_c <= 0;
            ir <= 0;
            state <= FETCH;
            mem_data <= 0;

            // program
            instr_mem[0] <= 8'b00100000;
            instr_mem[1] <= 8'b01100001;
            instr_mem[2] <= 8'b01000000;
            instr_mem[3] <= 8'b10100000;
            instr_mem[4] <= 0;
            instr_mem[5] <= 0;
            instr_mem[6] <= 0;
            instr_mem[7] <= 0;

            // data memory
            data_mem[0] <= 0;
            data_mem[1] <= 1;
            data_mem[2] <= 0;
            data_mem[3] <= 0;
            data_mem[4] <= 0;
            data_mem[5] <= 0;
            data_mem[6] <= 0;
            data_mem[7] <= 0;
            data_mem[8] <= 0;
            data_mem[9] <= 0;
            data_mem[10] <= 0;
            data_mem[11] <= 0;
            data_mem[12] <= 0;
            data_mem[13] <= 0;
            data_mem[14] <= 0;
            data_mem[15] <= 0;

        end else if (ena) begin

            case (state)

                // ================= FETCH =================
                FETCH: begin
                    ir <= instr_mem[pc];
                    state <= EXEC;
                end

                // ================= EXEC =================
                EXEC: begin
                    mem_data <= data_mem[operand]; // SAFE: operand valid

                    case (opcode)

                        JMP: pc <= operand[2:0];

                        JZ: pc <= flag_z ? operand[2:0] : pc + 1;

                        JC: pc <= flag_c ? operand[2:0] : pc + 1;

                        default: pc <= pc + 1;

                    endcase

                    state <= WB;
                end

                // ================= WRITEBACK =================
                WB: begin
                    case (opcode)

                        LDA: acc <= mem_data;

                        STA: data_mem[operand] <= acc;

                        ADD: begin
                            {flag_c, acc} <= acc + mem_data;
                            flag_z <= ((acc + mem_data) == 0);
                        end

                        SUB: begin
                            {flag_c, acc} <= acc - mem_data;
                            flag_z <= ((acc - mem_data) == 0);
                        end

                        default: ;

                    endcase

                    state <= FETCH;
                end

                default: state <= FETCH;

            endcase
        end
    end

    // ================= OUTPUTS =================
    assign uo_out  = {4'b0000, acc};
    assign uio_out = {3'b000, flag_c, flag_z, pc};
    assign uio_oe  = 8'hFF;

endmodule
