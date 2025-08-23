`timescale 1ns/1ps
// -----------------------------
// Testbench: exhaustive scan for WIDTH=4
// -----------------------------
module tb_exhaustive;

  // parameters
  localparam int WIDTH = 8;

  // DUT wires
  logic [WIDTH-1:0] in_a, in_b;
  logic [2:0]       in_opcode;
  logic [WIDTH-1:0] out_result;
  logic             out_zero, out_carry, out_overflow, out_negative, out_div_by_zero;

  // instantiate DUT
  alu_comb #(.WIDTH(WIDTH)) dut (
    .in_a(in_a),
    .in_b(in_b),
    .in_opcode(in_opcode),
    .out_result(out_result),
    .out_zero(out_zero),
    .out_carry(out_carry),
    .out_overflow(out_overflow),
    .out_negative(out_negative),
    .out_div_by_zero(out_div_by_zero)
  );

  // reference model task (same semantics)
  function automatic void ref_model(
      input  logic [WIDTH-1:0] a,
      input  logic [WIDTH-1:0] b,
      input  logic [2:0]       opcode,
      output logic [WIDTH-1:0] r_res,
      output logic             r_zero,
      output logic             r_carry,
      output logic             r_ovf,
      output logic             r_neg,
      output logic             r_div0
  );
    logic [WIDTH:0] add_e, sub_e;
    logic [2*WIDTH-1:0] mul_f;
    localparam int SHW = (WIDTH <= 1) ? 1 : $clog2(WIDTH);
    logic [SHW-1:0] shamt_local;
    begin
      r_res = '0;
      r_zero = 1'b0;
      r_carry = 1'b0;
      r_ovf = 1'b0;
      r_neg = 1'b0;
      r_div0 = 1'b0;

      add_e = {1'b0, a} + {1'b0, b};
      sub_e = {1'b0, a} - {1'b0, b};
      mul_f = a * b;
      shamt_local = b[SHW-1:0];

      case (opcode)
        3'b000: begin // ADD
          r_res = add_e[WIDTH-1:0];
          r_carry = add_e[WIDTH];
          r_ovf = (a[WIDTH-1] == b[WIDTH-1]) && (r_res[WIDTH-1] != a[WIDTH-1]);
        end
        3'b001: begin // SUB
          r_res = sub_e[WIDTH-1:0];
          r_carry = ~sub_e[WIDTH];
          r_ovf = (a[WIDTH-1] != b[WIDTH-1]) && (r_res[WIDTH-1] != a[WIDTH-1]);
        end
        3'b010: begin
          r_res = mul_f[WIDTH-1:0];
          r_ovf = |mul_f[2*WIDTH-1:WIDTH];
        end
        3'b011: begin
          if (b == '0) begin
            r_res = '0;
            r_div0 = 1'b1;
          end else begin
            r_res = a / b;
          end
        end
        3'b100: r_res = a & b;
        3'b101: r_res = a | b;
        3'b110: r_res = a ^ b;
        3'b111: r_res = a << shamt_local;
        default: r_res = '0;
      endcase

      r_zero = (r_res == '0);
      r_neg  = r_res[WIDTH-1];
    end
  endfunction

  // counters
  integer pass_count = 0;
  integer fail_count = 0;

  // store up to first N failures (for debug)
  localparam int MAX_SAVE_FAILS = 16;
  typedef struct {
    int a; int b; int opcode;
    logic [WIDTH-1:0] dut_res;
    logic [WIDTH-1:0] ref_res;
    logic dut_zero, ref_zero;
    logic dut_carry, ref_carry;
    logic dut_ovf, ref_ovf;
    logic dut_neg, ref_neg;
    logic dut_div0, ref_div0;
  } fail_t;

  fail_t failures[$];

  // test procedure
  initial begin
    integer a_i, b_i, op_i;
    logic [WIDTH-1:0] r_res, d_res;
    logic r_zero, r_carry, r_ovf, r_neg, r_div0;
    logic d_zero, d_carry, d_ovf, d_neg, d_div0;

    // initialize
    pass_count = 0;
    fail_count = 0;
    failures.delete();

    // Exhaustive loops
    for (a_i = 0; a_i < (1<<WIDTH); a_i = a_i + 1) begin
      for (b_i = 0; b_i < (1<<WIDTH); b_i = b_i + 1) begin
        for (op_i = 0; op_i < 8; op_i = op_i + 1) begin

          // drive inputs (combinational DUT, so no clock needed)
          in_a = a_i;
          in_b = b_i;
          in_opcode = op_i;

          // small delay to let combinational logic settle
          #1;

          // sample DUT outputs
          d_res = out_result;
          d_zero = out_zero;
          d_carry = out_carry;
          d_ovf = out_overflow;
          d_neg = out_negative;
          d_div0 = out_div_by_zero;

          // compute reference
          ref_model(in_a, in_b, in_opcode, r_res, r_zero, r_carry, r_ovf, r_neg, r_div0);

          // compare all relevant fields
          if ((d_res !== r_res) ||
              (d_zero !== r_zero) ||
              (d_carry !== r_carry) ||
              (d_ovf !== r_ovf) ||
              (d_neg !== r_neg) ||
              (d_div0 !== r_div0)) begin
            // fail
            fail_count = fail_count + 1;
            if (failures.size() < MAX_SAVE_FAILS) begin
              failures.push_back('{a: a_i, b: b_i, opcode: op_i,
                                  dut_res: d_res, ref_res: r_res,
                                  dut_zero:d_zero, ref_zero:r_zero,
                                  dut_carry:d_carry, ref_carry:r_carry,
                                  dut_ovf:d_ovf, ref_ovf:r_ovf,
                                  dut_neg:d_neg, ref_neg:r_neg,
                                  dut_div0:d_div0, ref_div0:r_div0});
            end
          end else begin
            pass_count = pass_count + 1;
          end

        end
      end
    end

    // final summary
    $display("");
    $display("===================================================");
    $display("Exhaustive test complete (WIDTH=%0d)", WIDTH);
    $display("Total vectors tested : %0d", pass_count + fail_count);
    $display("Passed               : %0d", pass_count);
    $display("Failed               : %0d", fail_count);
    $display("===================================================");

    if (fail_count > 0) begin
      $display("First %0d failures (if any):", failures.size());
      foreach (failures[i]) begin
        $display(" FAIL[%0d] a=%0d b=%0d opcode=%0d | DUT_res=%0d REF_res=%0d | DUT_c=%0b REF_c=%0b DUT_ovf=%0b REF_ovf=%0b DUT_div0=%0b REF_div0=%0b",
                 i, failures[i].a, failures[i].b, failures[i].opcode,
                 failures[i].dut_res, failures[i].ref_res,
                 failures[i].dut_carry, failures[i].ref_carry,
                 failures[i].dut_ovf, failures[i].ref_ovf,
                 failures[i].dut_div0, failures[i].ref_div0);
      end
    end

    $finish;
  end

endmodule
