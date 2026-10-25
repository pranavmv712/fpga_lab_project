
module frame_buffer_test_top (
    input wire        wr_clk,
    input wire        wr_en,
    input wire [16:0] wr_addr,
    input wire [15:0] wr_data,

    input wire        rd_clk,
    input wire        reset,
    input wire        video_on,
    input wire [9:0]  pixel_x,
    input wire [9:0]  pixel_y,

    output wire [15:0] pixel_data,
    output wire        pixel_valid
);

    wire [16:0] rd_addr;

    pixel_reader u_pixel_reader (
        .clk(rd_clk),
        .reset(reset),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .rd_addr(rd_addr),
        .pixel_valid(pixel_valid)
    );

    frame_buffer u_frame_buffer (
        .wr_clk(wr_clk),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_clk(rd_clk),
        .rd_addr(rd_addr),
        .rd_data(pixel_data)
    );

endmodule
