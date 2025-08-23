// ------------------------------------------------------------
// Non-pipelined ALU (combinational, no latency)
// Outputs update immediately when inputs change
// ------------------------------------------------------------
module alu_comb #(
  parameter int WIDTH = 32
)(
  input  logic [WIDTH-1:0]      in_a,
  input  logic [WIDTH-1:0]      in_b,
  input  logic [3:0]            in_opcode, 

  // opcode mapping:
  // 0000:add, 0001:sub, 0010:mul, 0011:divu,
  // 0100:and, 0101:or, 0110:xor,
  // 0111:sll, 1000:srl, 1001:sra,
  // 1010:rol, 1011:ror,
  // 1100:EQ, 1101:NEQ, 1110:GT, 1111:LT

  output logic [WIDTH-1:0]      out_result,
  output logic                  out_zero,
  output logic                  out_carry,
  output logic                  out_overflow,
  output logic                  out_negative,
  output logic                  out_div_by_zero
);

  // Opcode encoding
  localparam logic [3:0]
    OPC_ADD  = 4'b0000,
    OPC_SUB  = 4'b0001,
    OPC_MUL  = 4'b0010,
    OPC_DIVU = 4'b0011,
    OPC_AND  = 4'b0100,
    OPC_OR   = 4'b0101,
    OPC_XOR  = 4'b0110,
    OPC_SLL  = 4'b0111,
    OPC_SRL  = 4'b1000,
    OPC_SRA  = 4'b1001,
    OPC_ROL  = 4'b1010,
    OPC_ROR  = 4'b1011,
    OPC_EQ   = 4'b1100,
    OPC_NEQ  = 4'b1101,
    OPC_GT   = 4'b1110,
    OPC_LT   = 4'b1111;

  // Extended width for add/sub/mul
  logic [WIDTH:0] add_ext, sub_ext;
  logic [2*WIDTH-1:0] mul_full;

  // shift amount
  localparam int SHW = (WIDTH <= 1) ? 1 : $clog2(WIDTH);
  logic [SHW-1:0] shamt;

  always_comb begin
    // defaults
    out_result     = '0;
    out_zero       = 1'b0;
    out_carry      = 1'b0;
    out_overflow   = 1'b0;
    out_negative   = 1'b0;
    out_div_by_zero= 1'b0;

    add_ext = {1'b0, in_a} + {1'b0, in_b};
    sub_ext = {1'b0, in_a} - {1'b0, in_b};
    mul_full = in_a * in_b;
    shamt = in_b[SHW-1:0]; // shift amount from lower bits of B

    unique case (in_opcode)
      OPC_ADD: begin
        out_result   = add_ext[WIDTH-1:0];
        out_carry    = add_ext[WIDTH];
        out_overflow = (in_a[WIDTH-1] == in_b[WIDTH-1]) &&
                       (out_result[WIDTH-1] != in_a[WIDTH-1]);
      end

      OPC_SUB: begin
        out_result   = sub_ext[WIDTH-1:0];
        out_carry    = ~sub_ext[WIDTH]; //~borrow
        out_overflow = (in_a[WIDTH-1] != in_b[WIDTH-1]) &&
                       (out_result[WIDTH-1] != in_a[WIDTH-1]);
      end

      OPC_MUL: begin
        out_result   = mul_full[WIDTH-1:0];
        out_overflow = |mul_full[2*WIDTH-1:WIDTH];
      end

      OPC_DIVU: begin
        if (in_b == '0) begin
          out_result     = '0;
          out_div_by_zero= 1'b1;
        end else begin
          out_result     = in_a / in_b;
        end
      end

      // Logical
      OPC_AND: out_result = in_a & in_b;
      OPC_OR : out_result = in_a | in_b;
      OPC_XOR: out_result = in_a ^ in_b;

      // Shift / Rotate
      OPC_SLL: out_result = in_a << shamt;                            // shift left logical
      OPC_SRL: out_result = in_a >> shamt;                            // shift right logical
      OPC_SRA: out_result = $signed(in_a) >>> shamt;                  // shift right arithmetic
      OPC_ROL: out_result = (in_a << shamt) | (in_a >> (WIDTH - shamt)); // rotate left
      OPC_ROR: out_result = (in_a >> shamt) | (in_a << (WIDTH - shamt)); // rotate right

      // Comparisons (1-bit result in LSB, rest zero)
      OPC_EQ : out_result = (in_a == in_b);
      OPC_NEQ: out_result = (in_a != in_b);
      OPC_GT : out_result = ($signed(in_a) > $signed(in_b));
      OPC_LT : out_result = ($signed(in_a) < $signed(in_b));

      default: out_result = '0;
    endcase

    // Flags
    out_zero     = (out_result == '0);
    out_negative = out_result[WIDTH-1];
  end
endmodule
