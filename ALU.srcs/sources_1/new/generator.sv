class generator;
    transaction trans_item;
    mailbox gen2driv=new();
    function new(mailbox gen2driv) ;
        this.gen2driv = gen2driv;
    endfunction
    task main();
        repeat (1)
            begin
                trans_item = new();
                trans_item.randomize();
                $display("--------------------------------------------------");
                trans_item.display("Generator");
                gen2driv.put(trans_item);
            end
    endtask
endclass