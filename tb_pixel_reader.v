
`timescale 1ns/1ps

module tb_pixel_reader;

    reg clk;
    reg reset;
    reg video_on;
    reg [9:0] pixel_x;
    reg [9:0] pixel_y;

    wire [16:0] rd_addr;
    wire pixel_valid;

    integer errors;

    pixel_reader dut (
        .clk(clk),
        .reset(reset),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .rd_addr(rd_addr),
        .pixel_valid(pixel_valid)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    task check_address;
        input [9:0] x;
        input [9:0] y;
        input [16:0] expected;
        begin
            @(negedge clk);
            pixel_x = x;
            pixel_y = y;
            video_on = 1'b1;
            #1;

            if (rd_addr !== expected) begin
                $display("FAIL: x=%0d y=%0d expected=%0d got=%0d",
                         x, y, expected, rd_addr);
                errors = errors + 1;
            end
            else begin
                $display("PASS: x=%0d y=%0d address=%0d",
                         x, y, rd_addr);
            end
        end
    endtask

    initial begin
        $dumpfile("pixel_reader.vcd");
        $dumpvars(0, tb_pixel_reader);

        reset = 1'b1;
        video_on = 1'b0;
        pixel_x = 0;
        pixel_y = 0;
        errors = 0;

        repeat (2) @(negedge clk);
        reset = 1'b0;

        check_address(10'd0,   10'd0,   17'd0);
        check_address(10'd1,   10'd0,   17'd0);
        check_address(10'd2,   10'd0,   17'd1);
        check_address(10'd0,   10'd2,   17'd320);
        check_address(10'd639, 10'd479, 17'd76799);

        // Check blanking behavior
        @(negedge clk);
        video_on = 1'b0;
        #1;

        if (rd_addr !== 17'd0) begin
            $display("FAIL: Address should be zero during blanking");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Blanking address is zero");
        end

        if (errors == 0)
            $display("ALL PIXEL READER TESTS PASSED");
        else
            $display("PIXEL READER TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
