class driver;
    virtual intf vif;
    mailbox gen2driv;
    function new (virtual intf vif, mailbox gen2driv);
        this.vif = vif;
        this.gen2driv = gen2driv;
    endfunction
    task main;
        repeat(1) begin
            transaction trans_item;
            gen2driv.get(trans_item);
            vif.in_a <= trans_item.in_a;
            vif.in_b <= trans_item.in_b;
            vif.in_opcode <= trans_item.in_opcode;
            trans_item.out_result   = vif.out_result;
            trans_item.out_zero     = vif.out_zero;
            trans_item.out_carry    = vif.out_carry;
            trans_item.out_overflow = vif.out_overflow;
            trans_item.out_negative = vif.out_negative;
            trans_item.out_div_by_zero = vif.out_div_by_zero;
            #1;
            trans_item.display("Driver");
        end
    endtask
endclass