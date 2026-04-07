// Tiny4 - Minimal 4-bit CPU for Tiny Tapeout
// LOADABLE VERSION - OPTIMIZED for <1000 gates
// Reduced to 8 instructions to save gates
// Harvard Architecture with 8-bit instructions

module tt_um_tiny4_cpu (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] ui_in,      // Input pins for loading and control
    output wire [7:0] uo_out,     // Output: {4'b0, accumulator}
    output wire [7:0] uio_out,    // Bidirectional as output: {5'b0, flags, PC[2:0]}
    output wire [7:0] uio_oe,     // Enable outputs
    input  wire [7:0] uio_in,     // Not used
    input  wire       ena         // Enable
);

    // ============================================================================
    // EXTERNAL LOADING INTERFACE
    // ============================================================================
    // ui_in[0] - LOAD_MODE: When high, enter instruction loading mode
    // ui_in[1] - LOAD_CLK:  Clock for shifting in data
    // ui_in[2] - DATA_IN:   Serial data input
    
    wire load_mode = ui_in[0];
    wire load_clk = ui_in[1];
    wire data_in = ui_in[2];
    
    // ============================================================================
    // INSTRUCTION MEMORY - 8 instructions (reduced from 16)
    // ============================================================================
    reg [7:0] instr_mem [0:7];  // Only 8 instructions (saves ~100 gates)
    
    // Default program (counter, fits in 4 instructions)
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_mem[0] <= 8'b00100000;  // LDA [0]
            instr_mem[1] <= 8'b01100001;  // ADD [1]
            instr_mem[2] <= 8'b01000000;  // STA [0]
            instr_mem[3] <= 8'b10100000;  // JMP 0
            for (i = 4; i < 8; i = i + 1)
                instr_mem[i] <= 8'b00000000;  // NOP
        end
    end
    
    // ============================================================================
    // LOADING STATE MACHINE
    // ============================================================================
    reg [7:0] load_shift_reg;
    reg [2:0] load_bit_count;
    reg [2:0] load_addr;          // Only 3 bits for 8 addresses
    reg       load_clk_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_shift_reg <= 8'b0;
            load_bit_count <= 3'b0;
            load_addr <= 3'b0;
            load_clk_prev <= 1'b0;
        end else if (load_mode) begin
            load_clk_prev <= load_clk;
            
            if (load_clk && !load_clk_prev) begin
                load_shift_reg <= {load_shift_reg[6:0], data_in};
                load_bit_count <= load_bit_count + 1'b1;
                
                if (load_bit_count == 3'd7) begin
                    instr_mem[load_addr] <= {load_shift_reg[6:0], data_in};
                    load_addr <= load_addr + 1'b1;
                    load_bit_count <= 3'b0;
                end
            end
        end else begin
            load_bit_count <= 3'b0;
            load_addr <= 3'b0;
        end
    end
    
    // ============================================================================
    // DATA RAM
    // ============================================================================
    reg [3:0] data_mem [0:15];
    
    initial begin
        data_mem[0] = 4'h0;
        data_mem[1] = 4'h1;
        for (i = 2; i < 16; i = i + 1)
            data_mem[i] = 4'h0;
    end
    
    // ============================================================================
    // CPU CORE
    // ============================================================================
    reg [3:0] acc;
    reg [2:0] pc;           // Only 3 bits for 8 instructions
    reg       flag_z;
    reg       flag_c;
    reg [7:0] ir;
    
    reg [1:0] state;
    localparam FETCH    = 2'b00;
    localparam EXECUTE  = 2'b01;
    localparam WRITEBACK = 2'b10;
    
    wire [2:0] opcode = ir[7:5];
    wire [3:0] operand = ir[3:0];
    
    localparam NOP  = 3'b000;
    localparam LDA  = 3'b001;
    localparam STA  = 3'b010;
    localparam ADD  = 3'b011;
    localparam SUB  = 3'b100;
    localparam JMP  = 3'b101;
    localparam JZ   = 3'b110;
    localparam JC   = 3'b111;
    
    wire [4:0] alu_result;
    wire [3:0] alu_out;
    wire       alu_carry;
    
    assign alu_result = (opcode == ADD) ? (acc + data_mem[operand]) :
                        (opcode == SUB) ? (acc - data_mem[operand]) :
                        5'b0;
    assign alu_out = alu_result[3:0];
    assign alu_carry = alu_result[4];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 4'b0;
            pc <= 3'b0;
            flag_z <= 1'b0;
            flag_c <= 1'b0;
            ir <= 8'b0;
            state <= FETCH;
        end else if (ena && !load_mode) begin
            case (state)
                FETCH: begin
                    ir <= instr_mem[pc];
                    state <= EXECUTE;
                end
                
                EXECUTE: begin
                    case (opcode)
                        NOP: pc <= pc + 1'b1;
                        
                        LDA: begin
                            acc <= data_mem[operand];
                            pc <= pc + 1'b1;
                        end
                        
                        STA: begin
                            data_mem[operand] <= acc;
                            pc <= pc + 1'b1;
                        end
                        
                        ADD: begin
                            acc <= alu_out;
                            flag_c <= alu_carry;
                            flag_z <= (alu_out == 4'b0);
                            pc <= pc + 1'b1;
                        end
                        
                        SUB: begin
                            acc <= alu_out;
                            flag_c <= alu_carry;
                            flag_z <= (alu_out == 4'b0);
                            pc <= pc + 1'b1;
                        end
                        
                        JMP: pc <= operand[2:0];  // Only use lower 3 bits
                        
                        JZ: begin
                            if (flag_z)
                                pc <= operand[2:0];
                            else
                                pc <= pc + 1'b1;
                        end
                        
                        JC: begin
                            if (flag_c)
                                pc <= operand[2:0];
                            else
                                pc <= pc + 1'b1;
                        end
                    endcase
                    
                    state <= WRITEBACK;
                end
                
                WRITEBACK: begin
                    state <= FETCH;
                end
            endcase
        end
    end
    
    // ============================================================================
    // OUTPUTS
    // ============================================================================
    assign uo_out = {4'b0, acc};
    assign uio_out = {3'b0, flag_c, flag_z, pc};  // PC is now only 3 bits
    assign uio_oe = 8'hFF;
    
endmodule
