
module vga_test_top (
    input  clk_pix,
    input  reset,

    output  hsync,
    output  vsync,

    output  [7:0] red,
    output  [7:0] green,
    output  [7:0] blue
);

    wire video_on;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    vga_controller u_vga_controller (
        .clk_pix(clk_pix),
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    test_pattern u_test_pattern (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_on(video_on),
        .red(red),
        .green(green),
        .blue(blue)
    );

endmodule
