class transaction;
    rand bit [31:0] in_a, in_b;
    rand bit [3:0] in_opcode;
    constraint opcode_c {
        in_opcode >= 4'b0000;
        in_opcode <= 4'b1111;
    }
    // Outputs
    bit [31:0] out_result;
    bit out_zero, out_carry, out_overflow, out_negative, out_div_by_zero;

    function void display(string tag);
        $display("[%s] A=%0d, B=%0d, opcode=%0d, result=%0d", 
                  tag, in_a, in_b, in_opcode, out_result);
    endfunction
endclass
