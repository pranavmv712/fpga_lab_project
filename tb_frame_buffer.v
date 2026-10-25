
`timescale 1ns/1ps

module tb_frame_buffer;

    reg wr_clk;
    reg wr_en;
    reg [16:0] wr_addr;
    reg [15:0] wr_data;

    reg rd_clk;
    reg [16:0] rd_addr;
    wire [15:0] rd_data;

    integer errors;

    frame_buffer dut (
        .wr_clk(wr_clk),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_clk(rd_clk),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    // Write clock: 50 MHz
    initial begin
        wr_clk = 0;
        forever #10 wr_clk = ~wr_clk;
    end

    // Read clock: approximately 25 MHz
    initial begin
        rd_clk = 0;
        forever #20 rd_clk = ~rd_clk;
    end

    task write_pixel;
        input [16:0] address;
        input [15:0] data;
        begin
            @(negedge wr_clk);
            wr_addr = address;
            wr_data = data;
            wr_en = 1'b1;

            @(negedge wr_clk);
            wr_en = 1'b0;
        end
    endtask

    task check_pixel;
        input [16:0] address;
        input [15:0] expected;
        begin
            @(negedge rd_clk);
            rd_addr = address;

            @(posedge rd_clk);
            #1;

            if (rd_data !== expected) begin
                $display("FAIL: addr=%0d expected=%h got=%h",
                         address, expected, rd_data);
                errors = errors + 1;
            end
            else begin
                $display("PASS: addr=%0d data=%h",
                         address, rd_data);
            end
        end
    endtask

    initial begin
        $dumpfile("frame_buffer.vcd");
        $dumpvars(0, tb_frame_buffer);

        wr_en = 0;
        wr_addr = 0;
        wr_data = 0;
        rd_addr = 0;
        errors = 0;

        // Write test pixels
        write_pixel(17'd0,     16'hF800); // Red
        write_pixel(17'd1,     16'h07E0); // Green
        write_pixel(17'd2,     16'h001F); // Blue
        write_pixel(17'd76799, 16'hFFFF); // White, last pixel

        // Read them back
        check_pixel(17'd0,     16'hF800);
        check_pixel(17'd1,     16'h07E0);
        check_pixel(17'd2,     16'h001F);
        check_pixel(17'd76799, 16'hFFFF);

        if (errors == 0)
            $display("ALL FRAME BUFFER TESTS PASSED");
        else
            $display("FRAME BUFFER TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
