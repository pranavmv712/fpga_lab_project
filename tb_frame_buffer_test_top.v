
`timescale 1ns/1ps

module tb_frame_buffer_test_top;

    reg wr_clk, rd_clk, reset;
    reg wr_en, video_on;
    reg [16:0] wr_addr;
    reg [15:0] wr_data;
    reg [9:0] pixel_x, pixel_y;

    wire [15:0] pixel_data;
    wire pixel_valid;
    integer errors;

    frame_buffer_test_top dut (
        .wr_clk(wr_clk),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_clk(rd_clk),
        .reset(reset),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid)
    );

    initial begin
        wr_clk = 0;
        forever #10 wr_clk = ~wr_clk;
    end

    initial begin
        rd_clk = 0;
        forever #20 rd_clk = ~rd_clk;
    end

    task write_pixel;
        input [16:0] addr;
        input [15:0] data;
        begin
            @(negedge wr_clk);
            wr_addr = addr;
            wr_data = data;
            wr_en = 1;
            @(negedge wr_clk);
            wr_en = 0;
        end
    endtask

    task check_pixel;
        input [9:0] x;
        input [9:0] y;
        input [15:0] expected;
        begin
            @(negedge rd_clk);
            pixel_x = x;
            pixel_y = y;
            video_on = 1;

            // Pixel reader and frame buffer use the same read clock.
            @(posedge rd_clk);
            #1;

            if (pixel_data !== expected) begin
                $display("FAIL: (%0d,%0d) expected=%h got=%h",
                         x, y, expected, pixel_data);
                errors = errors + 1;
            end
            else begin
                $display("PASS: (%0d,%0d) pixel=%h",
                         x, y, pixel_data);
            end
        end
    endtask

    initial begin
        $dumpfile("frame_buffer_test_top.vcd");
        $dumpvars(0, tb_frame_buffer_test_top);

        reset = 1;
        wr_en = 0;
        wr_addr = 0;
        wr_data = 0;
        video_on = 0;
        pixel_x = 0;
        pixel_y = 0;
        errors = 0;

        repeat (3) @(negedge rd_clk);
        reset = 0;

        write_pixel(17'd0,   16'hF800); // Red
        write_pixel(17'd1,   16'h07E0); // Green
        write_pixel(17'd320, 16'h001F); // Blue

        check_pixel(10'd0, 10'd0, 16'hF800);
        check_pixel(10'd2, 10'd0, 16'h07E0);
        check_pixel(10'd0, 10'd2, 16'h001F);

        if (errors == 0)
            $display("ALL FRAME BUFFER INTEGRATION TESTS PASSED");
        else
            $display("INTEGRATION TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
