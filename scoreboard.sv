class scoreboard;
    mailbox mon2scb;

    function new(mailbox mon2scb);
        this.mon2scb = mon2scb;
    endfunction

    // Reference model (golden ALU)
    function void ref_model(input transaction tr_in, output transaction tr_exp);
        tr_exp = new();
        tr_exp.in_a      = tr_in.in_a;
        tr_exp.in_b      = tr_in.in_b;
        tr_exp.in_opcode = tr_in.in_opcode;
    
        tr_exp.out_result      = 0;
        tr_exp.out_zero        = 0;
        tr_exp.out_carry       = 0;
        tr_exp.out_overflow    = 0;
        tr_exp.out_negative    = 0;
        tr_exp.out_div_by_zero = 0;
    
        case(tr_in.in_opcode)
            4'b0000: begin // ADD
                {tr_exp.out_carry, tr_exp.out_result} = tr_in.in_a + tr_in.in_b;
                tr_exp.out_overflow = (tr_in.in_a[31] == tr_in.in_b[31]) &&
                                      (tr_exp.out_result[31] != tr_in.in_a[31]);
            end
            4'b0001: begin // SUB
                logic [32:0] sub_ext;
                sub_ext = {1'b0, tr_in.in_a} - {1'b0, tr_in.in_b};
                tr_exp.out_result   = sub_ext[31:0];
                tr_exp.out_carry    = ~sub_ext[32]; // carry = ~borrow
                tr_exp.out_overflow = (tr_in.in_a[31] != tr_in.in_b[31]) &&
                                      (tr_exp.out_result[31] != tr_in.in_a[31]);
            end
            4'b0010: tr_exp.out_result = tr_in.in_a * tr_in.in_b; // MUL
            4'b0011: begin // DIV
                if (tr_in.in_b == 0) begin
                    tr_exp.out_result = 0;
                    tr_exp.out_div_by_zero = 1;
                end else begin
                    tr_exp.out_result = tr_in.in_a / tr_in.in_b;
                end
            end
            4'b0100: tr_exp.out_result = tr_in.in_a & tr_in.in_b; // AND
            4'b0101: tr_exp.out_result = tr_in.in_a | tr_in.in_b; // OR
            4'b0110: tr_exp.out_result = tr_in.in_a ^ tr_in.in_b; // XOR
            4'b0111: tr_exp.out_result = tr_in.in_a << tr_in.in_b[4:0]; // SLL
            4'b1000: tr_exp.out_result = tr_in.in_a >> tr_in.in_b[4:0]; // SRL (logical right shift)
            4'b1001: tr_exp.out_result = $signed(tr_in.in_a) >>> tr_in.in_b[4:0]; // SRA (arith right shift)
            4'b1010: begin // ROL (rotate left)
                tr_exp.out_result = (tr_in.in_a << tr_in.in_b[4:0]) |
                                    (tr_in.in_a >> (32 - tr_in.in_b[4:0]));
            end
            4'b1011: begin // ROR (rotate right)
                tr_exp.out_result = (tr_in.in_a >> tr_in.in_b[4:0]) |
                                    (tr_in.in_a << (32 - tr_in.in_b[4:0]));
            end
            4'b1100: tr_exp.out_result = (tr_in.in_a == tr_in.in_b);
            4'b1101: tr_exp.out_result = (tr_in.in_a != tr_in.in_b);
            4'b1110: tr_exp.out_result = ($signed(tr_in.in_a) > $signed(tr_in.in_b));
            4'b1111: tr_exp.out_result = ($signed(tr_in.in_a) < $signed(tr_in.in_b));
            default: tr_exp.out_result = 0;
        endcase
    
        tr_exp.out_zero     = (tr_exp.out_result == 0);
        tr_exp.out_negative = tr_exp.out_result[31];
    endfunction
    // Main comparison loop
    task main;
        transaction tr_in;
        transaction tr_exp;

        repeat(1) begin
            // Get transaction from monitor (observed DUT output)
            mon2scb.get(tr_in);

            // Compute reference model
            ref_model(tr_in, tr_exp);

            // Direct compare (no pipeline delay anymore)
            if (tr_in.out_result     !== tr_exp.out_result    ||
                tr_in.out_zero       !== tr_exp.out_zero      ||
                tr_in.out_carry      !== tr_exp.out_carry     ||
                tr_in.out_overflow   !== tr_exp.out_overflow  ||
                tr_in.out_negative   !== tr_exp.out_negative  ||
                tr_in.out_div_by_zero!== tr_exp.out_div_by_zero) begin

                $display("--------------------------------------------------");
                $display("[SCOREBOARD] MISMATCH!");
                $display("INPUT : a=%0d, b=%0d, opcode=%0d",
                          tr_in.in_a, tr_in.in_b, tr_in.in_opcode);
                $display("DUT    : result=%0d zero=%0b carry=%0b ovf=%0b neg=%0b div0=%0b",
                          tr_in.out_result, tr_in.out_zero, tr_in.out_carry,
                          tr_in.out_overflow, tr_in.out_negative, tr_in.out_div_by_zero);
                $display("REF    : result=%0d zero=%0b carry=%0b ovf=%0b neg=%0b div0=%0b",
                          tr_exp.out_result, tr_exp.out_zero,
                          tr_exp.out_carry, tr_exp.out_overflow,
                          tr_exp.out_negative, tr_exp.out_div_by_zero);
                $display("--------------------------------------------------");
            end else begin
                $display("[SCOREBOARD] PASS for opcode=%0d, a=%0d, b=%0d, result=%0d",
                          tr_in.in_opcode, tr_in.in_a, tr_in.in_b, tr_in.out_result);
                $display("--------------------------------------------------");
            end
        end
    endtask
endclass
