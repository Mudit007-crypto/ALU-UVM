class environment;
    generator gen;
    driver driv;
    monitor mon;
    scoreboard scb;
    mailbox ml, m2;
    virtual intf vif;
    function new(virtual intf vif);
        this.vif = vif;
        ml = new();
        m2 = new();
        gen = new (ml);
        driv = new (vif,ml);
        mon = new (vif,m2);
        scb = new (m2) ;
    endfunction
    task test();
        fork
            gen.main();
            driv.main();
            mon.main();
            scb.main();
        join
    endtask
    task run;
    repeat(10) begin
        test();
        end
    endtask
endclass
