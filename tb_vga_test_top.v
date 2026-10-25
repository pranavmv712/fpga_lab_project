
`timescale 1ns/1ps

module tb_vga_test_top;

    reg clk_pix;
    reg reset;

    wire hsync;
    wire vsync;
    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;

    integer i;
    integer active_pixels;
    integer errors;
    reg sample_checked;

    vga_test_top dut (
        .clk_pix(clk_pix),
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .red(red),
        .green(green),
        .blue(blue)
    );

    // 25 MHz pixel clock
    initial begin
        clk_pix = 1'b0;
        forever #20 clk_pix = ~clk_pix;
    end

    initial begin
        $dumpfile("vga_test_top.vcd");
        $dumpvars(0, tb_vga_test_top);

        reset = 1'b1;
        active_pixels = 0;
        errors = 0;
        sample_checked = 0;

        repeat (5) @(posedge clk_pix);
        @(negedge clk_pix);
        reset = 1'b0;

        // Check one complete VGA frame
        for (i = 0; i < (800 * 525); i = i + 1) begin
            @(negedge clk_pix);

            if (dut.video_on)
                active_pixels = active_pixels + 1;

            // x=40 lies in the white bar.
            // y=10 lies within the visible image.
            if (dut.video_on &&
                dut.pixel_x == 10'd40 &&
                dut.pixel_y == 10'd10) begin

                sample_checked = 1;

                if ((red !== 8'hFF) ||
                    (green !== 8'hFF) ||
                    (blue !== 8'hFF)) begin
                    $display("FAIL: Expected white at (40,10)");
                    errors = errors + 1;
                end
            end
        end

        if (active_pixels == 307200)
            $display("PASS: Correct visible pixel count");
        else begin
            $display("FAIL: Active pixel count = %0d",
                     active_pixels);
            errors = errors + 1;
        end

        if (sample_checked)
            $display("PASS: White-bar sample checked");
        else begin
            $display("FAIL: Sample coordinate was not reached");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ALL INTEGRATION TESTS PASSED");
        else
            $display("INTEGRATION TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
