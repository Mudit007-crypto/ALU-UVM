interface intf #(parameter WIDTH = 32);
  // -------------------------------
  // Input (request) channel
  // -------------------------------
  logic [WIDTH-1:0]      in_a;
  logic [WIDTH-1:0]      in_b;
  logic [2:0]            in_opcode;
  // -------------------------------
  // Output (response) channel
  // -------------------------------
  logic [WIDTH-1:0]      out_result;
  logic                  out_zero;
  logic                  out_carry;
  logic                  out_overflow;
  logic                  out_negative;
  logic                  out_div_by_zero;
  // -------------------------------
  // Modports
  // -------------------------------
  // DUT modport (direction as seen by DUT)
  modport dut (
    input  in_a, in_b, in_opcode,
    output out_zero, out_carry, out_overflow, out_negative, out_div_by_zero
  );
  // Driver modport (stimulus side)
  modport drv (
    output in_a, in_b, in_opcode,
    input  out_result, out_zero, out_carry, out_overflow, out_negative, out_div_by_zero
  );
  // Monitor modport (passive observation)
  modport mon (
    input in_a, in_b, in_opcode,
    input out_result, out_zero, out_carry, out_overflow, out_negative, out_div_by_zero
  );
endinterface
