
module test_pattern (
    input  [9:0] pixel_x,
    input  [9:0] pixel_y,
    input        video_on,

    output reg [7:0] red,
    output reg [7:0] green,
    output reg [7:0] blue
);

    always @(*) begin
        // Default: black
        red   = 8'd0;
        green = 8'd0;
        blue  = 8'd0;

        if (video_on) begin
            if (pixel_x < 10'd80) begin
                // White
                red   = 8'hFF;
                green = 8'hFF;
                blue  = 8'hFF;
            end
            else if (pixel_x < 10'd160) begin
                // Yellow
                red   = 8'hFF;
                green = 8'hFF;
                blue  = 8'h00;
            end
            else if (pixel_x < 10'd240) begin
                // Cyan
                red   = 8'h00;
                green = 8'hFF;
                blue  = 8'hFF;
            end
            else if (pixel_x < 10'd320) begin
                // Green
                red   = 8'h00;
                green = 8'hFF;
                blue  = 8'h00;
            end
            else if (pixel_x < 10'd400) begin
                // Magenta
                red   = 8'hFF;
                green = 8'h00;
                blue  = 8'hFF;
            end
            else if (pixel_x < 10'd480) begin
                // Red
                red   = 8'hFF;
                green = 8'h00;
                blue  = 8'h00;
            end
            else if (pixel_x < 10'd560) begin
                // Blue
                red   = 8'h00;
                green = 8'h00;
                blue  = 8'hFF;
            end
            else begin
                // Black
                red   = 8'h00;
                green = 8'h00;
                blue  = 8'h00;
            end
        end
    end

endmodule
