// Tiny4 - Minimal 4-bit CPU for Tiny Tapeout
// Target: < 1000 gates
// Harvard Architecture with 8-bit instructions

module tt_um_tiny4_cpu (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] ui_in,      // Instruction input (for Tiny Tapeout)
    output wire [7:0] uo_out,     // Output: {4'b0, accumulator}
    output wire [7:0] uio_out,    // Bidirectional as output: {4'b0, flags, PC[1:0]}
    output wire [7:0] uio_oe,     // Enable outputs
    input  wire [7:0] uio_in,     // Not used
    input  wire       ena         // Enable
);

    // Instruction ROM (16 instructions x 8 bits)
    // Pre-loaded with a simple test program
    reg [7:0] instr_mem [0:15];
    
    // Data RAM (16 locations x 4 bits)
    reg [3:0] data_mem [0:15];
    
    // CPU Registers
    reg [3:0] acc;          // Accumulator
    reg [3:0] pc;           // Program Counter
    reg       flag_z;       // Zero flag
    reg       flag_c;       // Carry flag
    
    // Instruction Register
    reg [7:0] ir;           // Current instruction
    
    // State Machine
    reg [1:0] state;
    localparam FETCH    = 2'b00;
    localparam EXECUTE  = 2'b01;
    localparam WRITEBACK = 2'b10;
    
    // Instruction decode
    wire [2:0] opcode = ir[7:5];
    wire [3:0] operand = ir[3:0];
    
    // Opcodes
    localparam NOP  = 3'b000;
    localparam LDA  = 3'b001;
    localparam STA  = 3'b010;
    localparam ADD  = 3'b011;
    localparam SUB  = 3'b100;
    localparam JMP  = 3'b101;
    localparam JZ   = 3'b110;
    localparam JC   = 3'b111;
    
    // ALU
    wire [4:0] alu_result;
    wire [3:0] alu_out;
    wire       alu_carry;
    
    assign alu_result = (opcode == ADD) ? (acc + data_mem[operand]) :
                        (opcode == SUB) ? (acc - data_mem[operand]) :
                        5'b0;
    assign alu_out = alu_result[3:0];
    assign alu_carry = alu_result[4];
    
    // Initialize instruction memory with a test program
    // Program: Count from 0 to 15 in memory location 0
    initial begin
        // Simple counter program
        instr_mem[0]  = 8'b00100000;  // LDA [0]   - Load counter
        instr_mem[1]  = 8'b01100001;  // ADD [1]   - Add 1
        instr_mem[2]  = 8'b01000000;  // STA [0]   - Store back
        instr_mem[3]  = 8'b10100000;  // JMP 0     - Loop
        instr_mem[4]  = 8'b00000000;  // NOP
        instr_mem[5]  = 8'b00000000;  // NOP
        instr_mem[6]  = 8'b00000000;  // NOP
        instr_mem[7]  = 8'b00000000;  // NOP
        instr_mem[8]  = 8'b00000000;  // NOP
        instr_mem[9]  = 8'b00000000;  // NOP
        instr_mem[10] = 8'b00000000;  // NOP
        instr_mem[11] = 8'b00000000;  // NOP
        instr_mem[12] = 8'b00000000;  // NOP
        instr_mem[13] = 8'b00000000;  // NOP
        instr_mem[14] = 8'b00000000;  // NOP
        instr_mem[15] = 8'b00000000;  // NOP
        
        // Initialize data memory
        data_mem[0] = 4'h0;  // Counter value
        data_mem[1] = 4'h1;  // Constant 1
        data_mem[2] = 4'h0;
        data_mem[3] = 4'h0;
        data_mem[4] = 4'h0;
        data_mem[5] = 4'h0;
        data_mem[6] = 4'h0;
        data_mem[7] = 4'h0;
        data_mem[8] = 4'h0;
        data_mem[9] = 4'h0;
        data_mem[10] = 4'h0;
        data_mem[11] = 4'h0;
        data_mem[12] = 4'h0;
        data_mem[13] = 4'h0;
        data_mem[14] = 4'h0;
        data_mem[15] = 4'h0;
    end
    
    // Main CPU logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset
            acc <= 4'b0;
            pc <= 4'b0;
            flag_z <= 1'b0;
            flag_c <= 1'b0;
            ir <= 8'b0;
            state <= FETCH;
        end else if (ena) begin
            case (state)
                FETCH: begin
                    // Fetch instruction from instruction memory
                    ir <= instr_mem[pc];
                    state <= EXECUTE;
                end
                
                EXECUTE: begin
                    // Execute instruction
                    case (opcode)
                        NOP: begin
                            // No operation
                            pc <= pc + 1'b1;  // Increment PC for non-jump
                        end
                        
                        LDA: begin
                            // Load from memory to accumulator
                            acc <= data_mem[operand];
                            pc <= pc + 1'b1;  // Increment PC for non-jump
                        end
                        
                        STA: begin
                            // Store accumulator to memory
                            data_mem[operand] <= acc;
                            pc <= pc + 1'b1;  // Increment PC for non-jump
                        end
                        
                        ADD: begin
                            // Add memory to accumulator
                            acc <= alu_out;
                            flag_c <= alu_carry;
                            flag_z <= (alu_out == 4'b0);
                            pc <= pc + 1'b1;  // Increment PC for non-jump
                        end
                        
                        SUB: begin
                            // Subtract memory from accumulator
                            acc <= alu_out;
                            flag_c <= alu_carry;
                            flag_z <= (alu_out == 4'b0);
                            pc <= pc + 1'b1;  // Increment PC for non-jump
                        end
                        
                        JMP: begin
                            // Unconditional jump - set PC to target
                            pc <= operand;
                        end
                        
                        JZ: begin
                            // Jump if zero
                            if (flag_z)
                                pc <= operand;
                            else
                                pc <= pc + 1'b1;
                        end
                        
                        JC: begin
                            // Jump if carry
                            if (flag_c)
                                pc <= operand;
                            else
                                pc <= pc + 1'b1;
                        end
                    endcase
                    
                    state <= WRITEBACK;
                end
                
                WRITEBACK: begin
                    // Just transition back to FETCH
                    // PC was already updated in EXECUTE
                    state <= FETCH;
                end
            endcase
        end
    end
    
    // Outputs for Tiny Tapeout
    assign uo_out = {4'b0, acc};                    // Output accumulator value
    assign uio_out = {2'b0, flag_c, flag_z, pc};    // Output flags and PC
    assign uio_oe = 8'hFF;                           // All bidirectional pins as outputs
    
endmodule
