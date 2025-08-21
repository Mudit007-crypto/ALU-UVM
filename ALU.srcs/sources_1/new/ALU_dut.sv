// ------------------------------------------------------------
// Non-pipelined ALU (combinational, no latency)
// Outputs update immediately when inputs change
// ------------------------------------------------------------
module alu_comb #(
  parameter int WIDTH = 32
)(
  input  logic [WIDTH-1:0]      in_a,
  input  logic [WIDTH-1:0]      in_b,
  input  logic [2:0]            in_opcode, // 000:add, 001:sub, 010:mul, 011:divu, 100:and, 101:or, 110:xor, 111:sll

  output logic [WIDTH-1:0]      out_result,
  output logic                  out_zero,
  output logic                  out_carry,
  output logic                  out_overflow,
  output logic                  out_negative,
  output logic                  out_div_by_zero
);

  // Opcode encoding
  localparam logic [2:0]
    OPC_ADD  = 3'b000,
    OPC_SUB  = 3'b001,
    OPC_MUL  = 3'b010,
    OPC_DIVU = 3'b011,
    OPC_AND  = 3'b100,
    OPC_OR   = 3'b101,
    OPC_XOR  = 3'b110,
    OPC_SLL  = 3'b111;

  // Extended width for add/sub
  logic [WIDTH:0] add_ext, sub_ext;
  logic [2*WIDTH-1:0] mul_full;
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
    shamt = in_b[SHW-1:0];

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

      OPC_AND: out_result = in_a & in_b;
      OPC_OR : out_result = in_a | in_b;
      OPC_XOR: out_result = in_a ^ in_b;
      OPC_SLL: out_result = in_a << shamt;

      default: out_result = '0;
    endcase

    out_zero     = (out_result == '0);
    out_negative = out_result[WIDTH-1];
  end

endmodule
