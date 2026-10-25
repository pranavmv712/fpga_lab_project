
`timescale 1ns/1ps

module tb_vga_controller;

    reg clk_pix;
    reg reset;

    wire hsync;
    wire vsync;
    wire video_on;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    integer i;
    integer active_pixels;
    integer active_lines;

    vga_controller dut (
        .clk_pix(clk_pix),
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // 25 MHz pixel clock: period = 40 ns
    initial begin
        clk_pix = 1'b0;
        forever #20 clk_pix = ~clk_pix;
    end

    initial begin
        $dumpfile("vga_controller.vcd");
        $dumpvars(0, tb_vga_controller);

        reset = 1'b1;
        active_pixels = 0;
        active_lines = 0;

        repeat (5) @(posedge clk_pix);
        @(negedge clk_pix);
        reset = 1'b0;

        // Wait for one complete frame
        for (i = 0; i < (800 * 525); i = i + 1) begin
            @(negedge clk_pix);

            if (video_on)
                active_pixels = active_pixels + 1;
        end

        $display("Active pixels counted: %0d", active_pixels);
        $display("Expected active pixels: %0d", 640 * 480);

        if (active_pixels == (640 * 480))
            $display("PASS: Visible pixel count is correct.");
        else
            $display("FAIL: Visible pixel count is incorrect.");

        $finish;
    end

endmodule
