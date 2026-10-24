`timescale 1ns/1ps

module tb_sccb_master;

    reg clk;
    reg reset;
    reg write_start;
    reg [7:0] reg_addr;
    reg [7:0] reg_data;

    wire sioc;
    wire busy;
    wire write_done;

    // Pull-up behavior for the released open-drain data line.
    tri1 siod;

    sccb_master #(
        .HALF_DIV(4)
    ) dut (
        .clk(clk),
        .reset(reset),
        .write_start(write_start),
        .reg_addr(reg_addr),
        .reg_data(reg_data),
        .sioc(sioc),
        .siod(siod),
        .busy(busy),
        .write_done(write_done)
    );

    // 50 MHz clock: 20 ns period.
    initial clk = 0;
    always #10 clk = ~clk;

    initial begin

        $dumpfile("sccb.vcd");
        $dumpvars(0, tb_sccb_master);

        reset       = 1;
        write_start = 0;
        reg_addr    = 8'h12;
        reg_data    = 8'h04;

        #100;
        reset = 0;

        #100;
        @(negedge clk);
        write_start = 1;

        @(negedge clk);
        write_start = 0;

        wait(write_done == 1'b1);
        $display("SCCB transaction completed at time %0t", $time);

        #100;
        $finish;
    end

    initial begin
        $monitor(
            "t=%0t SIOC=%b SIOD=%b busy=%b done=%b",
            $time, sioc, siod, busy, write_done
        );
    end

endmodule