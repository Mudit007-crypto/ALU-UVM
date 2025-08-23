module tbench_top;
    // Interface instance
    intf i_intf();
    // Instantiate test program
    test t1(i_intf);
    // DUT instantiation
    alu_comb dut (
        .in_a       (i_intf.in_a),
        .in_b       (i_intf.in_b),
        .in_opcode  (i_intf.in_opcode),
        .out_result     (i_intf.out_result),
        .out_zero       (i_intf.out_zero),
        .out_carry      (i_intf.out_carry),
        .out_overflow   (i_intf.out_overflow),
        .out_negative   (i_intf.out_negative),
        .out_div_by_zero(i_intf.out_div_by_zero)
    );
    // VCD dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
endmodule
