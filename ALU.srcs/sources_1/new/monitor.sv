class monitor;
    virtual intf vif;
    mailbox mon2scb;
    function new(virtual intf vif, mailbox mon2scb) ;
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction
    task main;
        repeat(1) begin
            transaction trans_item;
            trans_item = new();
            #1;
            trans_item.in_a               = vif.in_a;
            trans_item.in_b               = vif.in_b;
            trans_item.in_opcode          = vif.in_opcode;
            trans_item.out_result         = vif.out_result;
            trans_item.out_zero           = vif.out_zero;
            trans_item.out_carry          = vif.out_carry;
            trans_item.out_overflow       = vif.out_overflow;
            trans_item.out_negative       = vif.out_negative;
            trans_item.out_div_by_zero    = vif.out_div_by_zero;
    
            mon2scb.put(trans_item);
            trans_item.display("Monitor");
        end
    endtask
endclass