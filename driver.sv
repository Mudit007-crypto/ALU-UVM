class driver;
    virtual intf vif;
    mailbox gen2driv;

    function new(virtual intf vif, mailbox gen2driv);
        this.vif = vif;
        this.gen2driv = gen2driv;
    endfunction

    task main;
        repeat(1) begin
            transaction trans_item;
            gen2driv.get(trans_item);
    
            // Drive DUT inputs
            vif.in_a      <= trans_item.in_a;
            vif.in_b      <= trans_item.in_b;
            vif.in_opcode <= trans_item.in_opcode;
    
            // optional: add a small delay so monitor sees updated values
            #1;
    
            trans_item.display("Driver");
        end
    endtask
endclass
