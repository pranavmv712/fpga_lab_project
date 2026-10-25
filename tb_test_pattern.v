
`timescale 1ns/1ps

module tb_test_pattern;

    reg [9:0] pixel_x;
    reg [9:0] pixel_y;
    reg video_on;

    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;

    integer errors;

    test_pattern dut (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_on(video_on),
        .red(red),
        .green(green),
        .blue(blue)
    );

    task check_color;
        input [9:0] x;
        input [7:0] expected_red;
        input [7:0] expected_green;
        input [7:0] expected_blue;
        begin
            pixel_x = x;
            #10;

            if ((red !== expected_red) ||
                (green !== expected_green) ||
                (blue !== expected_blue)) begin
                $display("FAIL x=%0d RGB=%h %h %h",
                         x, red, green, blue);
                errors = errors + 1;
            end
            else begin
                $display("PASS x=%0d RGB=%h %h %h",
                         x, red, green, blue);
            end
        end
    endtask

    initial begin
        $dumpfile("test_pattern.vcd");
        $dumpvars(0, tb_test_pattern);

        pixel_x = 0;
        pixel_y = 0;
        video_on = 1;
        errors = 0;

        check_color(10'd40,  8'hFF, 8'hFF, 8'hFF); // White
        check_color(10'd120, 8'hFF, 8'hFF, 8'h00); // Yellow
        check_color(10'd200, 8'h00, 8'hFF, 8'hFF); // Cyan
        check_color(10'd280, 8'h00, 8'hFF, 8'h00); // Green
        check_color(10'd360, 8'hFF, 8'h00, 8'hFF); // Magenta
        check_color(10'd440, 8'hFF, 8'h00, 8'h00); // Red
        check_color(10'd520, 8'h00, 8'h00, 8'hFF); // Blue
        check_color(10'd600, 8'h00, 8'h00, 8'h00); // Black

        video_on = 0;
        #10;

        if ((red !== 8'h00) ||
            (green !== 8'h00) ||
            (blue !== 8'h00)) begin
            $display("FAIL: Blanking output is not black.");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Blanking output is black.");
        end

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
