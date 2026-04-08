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

    // ================= INPUTS =================
    wire load_mode = ui_in[0];
    wire load_clk  = ui_in[1];
    wire data_in   = ui_in[2];

    // ================= MEMORIES =================
    reg [7:0] instr_mem [0:7];
    reg [3:0] data_mem  [0:15];

    // ================= LOADER =================
    reg [7:0] shift_reg;
    reg [2:0] bit_count;
    reg [2:0] load_addr;
    reg       load_clk_prev;

    // ================= CPU =================
    reg [3:0] acc;
    reg [2:0] pc;
    reg       flag_z, flag_c;
    reg [7:0] ir;
    reg [1:0] state;

    // FSM states
    localparam FETCH = 2'b00;
    localparam EXEC  = 2'b01;
    localparam WB    = 2'b10;

    // Decode
    wire [2:0] opcode  = ir[7:5];
    wire [3:0] operand = ir[3:0];

    // Opcodes
    localparam NOP = 3'b000;
    localparam LDA = 3'b001;
    localparam STA = 3'b010;
    localparam ADD = 3'b011;
    localparam SUB = 3'b100;
    localparam JMP = 3'b101;
    localparam JZ  = 3'b110;
    localparam JC  = 3'b111;

    // ============================================================
    // INITIALIZATION - DEFAULT PROGRAM
    // This must be in a separate always block from the loader
    // to avoid synthesis conflicts
    // ============================================================
    integer i;
    reg init_done;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            init_done <= 0;
        end else if (!init_done && !load_mode) begin
            // Load default program only once after reset
            instr_mem[0] <= 8'b00100000;  // LDA [0]
            instr_mem[1] <= 8'b01100001;  // ADD [1]
            instr_mem[2] <= 8'b01000000;  // STA [0]
            instr_mem[3] <= 8'b10100000;  // JMP 0
            instr_mem[4] <= 8'b00000000;  // NOP
            instr_mem[5] <= 8'b00000000;  // NOP
            instr_mem[6] <= 8'b00000000;  // NOP
            instr_mem[7] <= 8'b00000000;  // NOP
            init_done <= 1;
        end
    end

    // ============================================================
    // SERIAL LOADER
    // Separate from initialization to avoid conflicts
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0;
            bit_count <= 3'b0;
            load_addr <= 3'b0;
            load_clk_prev <= 1'b0;
        end else begin
            load_clk_prev <= load_clk;

            if (load_mode && init_done) begin  // Only load after init
                if (load_clk && !load_clk_prev) begin
                    shift_reg <= {shift_reg[6:0], data_in};
                    bit_count <= bit_count + 3'b1;

                    if (bit_count == 3'd7) begin
                        instr_mem[load_addr] <= {shift_reg[6:0], data_in};
                        load_addr <= load_addr + 3'b1;
                        bit_count <= 3'b0;
                    end
                end
            end else if (!load_mode) begin
                // Reset counters when not in load mode
                bit_count <= 3'b0;
                load_addr <= 3'b0;
            end
        end
    end

    // ============================================================
    // DATA MEMORY - SINGLE ALWAYS BLOCK
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize all data memory locations explicitly
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
        end else if (ena && !load_mode && state == WB && opcode == STA) begin
            data_mem[operand] <= acc;
        end
    end

    // ============================================================
    // ALU - REGISTERED OUTPUTS TO AVOID GLITCHES
    // ============================================================
    reg [3:0] alu_out;
    reg       alu_carry;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_out <= 4'b0;
            alu_carry <= 1'b0;
        end else if (ena && !load_mode && state == EXEC) begin
            case (opcode)
                ADD: begin
                    {alu_carry, alu_out} <= acc + data_mem[operand];
                end
                SUB: begin
                    {alu_carry, alu_out} <= acc - data_mem[operand];
                end
                default: begin
                    alu_out <= 4'b0;
                    alu_carry <= 1'b0;
                end
            endcase
        end
    end

    // ============================================================
    // CPU FSM - SINGLE ALWAYS BLOCK
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 4'b0;
            pc <= 3'b0;
            flag_z <= 1'b0;
            flag_c <= 1'b0;
            ir <= 8'b0;
            state <= FETCH;

        end else if (ena && !load_mode && init_done) begin
            case (state)

                FETCH: begin
                    ir <= instr_mem[pc];
                    state <= EXEC;
                end

                EXEC: begin
                    // Update PC based on instruction type
                    case (opcode)
                        JMP: pc <= operand[2:0];
                        JZ:  pc <= flag_z ? operand[2:0] : (pc + 3'b1);
                        JC:  pc <= flag_c ? operand[2:0] : (pc + 3'b1);
                        default: pc <= pc + 3'b1;
                    endcase
                    state <= WB;
                end

                WB: begin
                    // Update registers based on instruction
                    case (opcode)
                        LDA: begin
                            acc <= data_mem[operand];
                        end

                        ADD: begin
                            acc <= alu_out;
                            flag_c <= alu_carry;
                            flag_z <= (alu_out == 4'b0);
                        end

                        SUB: begin
                            acc <= alu_out;
                            flag_c <= alu_carry;
                            flag_z <= (alu_out == 4'b0);
                        end

                        default: begin
                            // NOP, STA, JMP, JZ, JC - no register updates in WB
                        end
                    endcase
                    state <= FETCH;
                end

                default: begin
                    state <= FETCH;
                end

            endcase
        end
    end

    // ============================================================
    // OUTPUTS - GUARANTEED NO X VALUES
    // ============================================================
    assign uo_out  = {4'b0000, acc};
    assign uio_out = {3'b000, flag_c, flag_z, pc};
    assign uio_oe  = 8'hFF;

endmodule
