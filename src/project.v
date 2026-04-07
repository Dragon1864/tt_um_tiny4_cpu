`timescale 1ns / 1ps

// ============================================================
// TOP WRAPPER
// ============================================================
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

    tiny4_cpu cpu (
        .clk(clk),
        .rst_n(rst_n),
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .uio_in(uio_in),
        .ena(ena)
    );

endmodule


// ============================================================
// CPU CORE
// ============================================================
module tiny4_cpu (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire [7:0] uio_in,
    input  wire       ena
);

    // ================= INPUT DECODE =================
    wire load_mode = ui_in[0];
    wire load_clk  = ui_in[1];
    wire data_in   = ui_in[2];

    // ================= MEMORIES =================
    reg [7:0] instr_mem [0:7];
    reg [3:0] data_mem  [0:15];

    // ================= LOADER =================
    reg [7:0] load_shift_reg;
    reg [2:0] load_bit_count;
    reg [2:0] load_addr;
    reg       load_clk_prev;

    // ================= CPU REGISTERS =================
    reg [3:0] acc;
    reg [2:0] pc;
    reg       flag_z;
    reg       flag_c;
    reg [7:0] ir;
    reg [1:0] state;

    // ✅ REGISTERED MEMORY READ (FIXED WITH RESET)
    reg [3:0] mem_data;

    // ================= FSM STATES =================
    localparam FETCH = 2'b00;
    localparam EXEC  = 2'b01;
    localparam WB    = 2'b10;

    // ================= OPCODES =================
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
    // INSTRUCTION MEMORY + LOADER
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_mem[0] <= 8'b00100000;
            instr_mem[1] <= 8'b01100001;
            instr_mem[2] <= 8'b01000000;
            instr_mem[3] <= 8'b10100000;
            instr_mem[4] <= 0;
            instr_mem[5] <= 0;
            instr_mem[6] <= 0;
            instr_mem[7] <= 0;

            load_shift_reg <= 0;
            load_bit_count <= 0;
            load_addr <= 0;
            load_clk_prev <= 0;

        end else begin
            load_clk_prev <= load_clk;

            if (load_mode) begin
                if (load_clk && !load_clk_prev) begin
                    load_shift_reg <= {load_shift_reg[6:0], data_in};
                    load_bit_count <= load_bit_count + 1;

                    if (load_bit_count == 3'd7) begin
                        instr_mem[load_addr] <= {load_shift_reg[6:0], data_in};
                        load_addr <= load_addr + 1;
                        load_bit_count <= 0;
                    end
                end
            end else begin
                load_bit_count <= 0;
                load_addr <= 0;
            end
        end
    end

    // ============================================================
    // DATA MEMORY (SINGLE DRIVER)
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_mem[0]  <= 4'h0;
            data_mem[1]  <= 4'h1;
            data_mem[2]  <= 4'h0;
            data_mem[3]  <= 4'h0;
            data_mem[4]  <= 4'h0;
            data_mem[5]  <= 4'h0;
            data_mem[6]  <= 4'h0;
            data_mem[7]  <= 4'h0;
            data_mem[8]  <= 4'h0;
            data_mem[9]  <= 4'h0;
            data_mem[10] <= 4'h0;
            data_mem[11] <= 4'h0;
            data_mem[12] <= 4'h0;
            data_mem[13] <= 4'h0;
            data_mem[14] <= 4'h0;
            data_mem[15] <= 4'h0;
        end else if (ena && !load_mode) begin
            if (state == EXEC && opcode == STA) begin
                data_mem[operand] <= acc;
            end
        end
    end

    // ============================================================
    // ✅ FIXED MEMORY READ (NO X PROPAGATION)
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mem_data <= 0;
        else
            mem_data <= data_mem[operand];
    end

    // ============================================================
    // ALU
    // ============================================================
    wire [4:0] alu_result =
        (opcode == ADD) ? (acc + mem_data) :
        (opcode == SUB) ? (acc - mem_data) :
        5'b0;

    wire [3:0] alu_out = alu_result[3:0];
    wire       alu_carry = alu_result[4];

    // ============================================================
    // CPU FSM
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 0;
            pc <= 0;
            flag_z <= 0;
            flag_c <= 0;
            ir <= 0;
            state <= FETCH;

        end else if (ena && !load_mode) begin
            case (state)

                FETCH: begin
                    ir <= instr_mem[pc];
                    state <= EXEC;
                end

                EXEC: begin
                    case (opcode)

                        NOP: pc <= pc + 1;

                        LDA: begin
                            acc <= mem_data;
                            pc <= pc + 1;
                        end

                        STA: pc <= pc + 1;

                        ADD: begin
                            acc <= alu_out;
                            flag_c <= alu_carry;
                            flag_z <= (alu_out == 0);
                            pc <= pc + 1;
                        end

                        SUB: begin
                            acc <= alu_out;
                            flag_c <= alu_carry;
                            flag_z <= (alu_out == 0);
                            pc <= pc + 1;
                        end

                        JMP: pc <= operand[2:0];

                        JZ: pc <= flag_z ? operand[2:0] : pc + 1;

                        JC: pc <= flag_c ? operand[2:0] : pc + 1;

                        default: pc <= pc + 1;

                    endcase

                    state <= WB;
                end

                WB: state <= FETCH;

                default: state <= FETCH;

            endcase
        end
    end

    // ============================================================
    // OUTPUTS (NO X VALUES)
    // ============================================================
    assign uo_out  = rst_n ? {4'b0, acc} : 8'b0;
    assign uio_out = {3'b0, flag_c, flag_z, pc};
    assign uio_oe  = 8'hFF;

endmodule
