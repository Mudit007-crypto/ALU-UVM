class generator;
    transaction trans_item;
    mailbox gen2driv;
    function new(mailbox gen2driv);
        this.gen2driv = gen2driv;
    endfunction

    task main();
        transaction trans_item;
        repeat(1) begin
            trans_item = new();
            trans_item.randomize();
            $display("--------------------------------------------------");
            trans_item.display($sformatf("Generator @%0t", $time));
            gen2driv.put(trans_item); // blocking, exactly one per clk
        end
    endtask
endclass
