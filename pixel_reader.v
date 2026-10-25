
module pixel_reader (
    input wire        clk,
    input wire        reset,

    input wire        video_on,
    input wire [9:0]  pixel_x,
    input wire [9:0]  pixel_y,

    output reg [16:0] rd_addr,
    output reg        pixel_valid
);

    wire [8:0] src_x;
    wire [7:0] src_y;
    wire [16:0] row_offset;

    // Scale 640x480 coordinates down to 320x240.
    assign src_x = pixel_x[9:1];
    assign src_y = pixel_y[8:1];

    // 320 * src_y = (256 * src_y) + (64 * src_y)
    assign row_offset = ({9'd0, src_y} << 8)
                      + ({9'd0, src_y} << 6);

    // Generate the address for the synchronous frame buffer.
    always @(*) begin
        if (video_on)
            rd_addr = row_offset + src_x;
        else
            rd_addr = 17'd0;
    end

    // Delay validity by one clock to match frame-buffer read latency.
    always @(posedge clk or posedge reset) begin
        if (reset)
            pixel_valid <= 1'b0;
        else
            pixel_valid <= video_on;
    end

endmodule
