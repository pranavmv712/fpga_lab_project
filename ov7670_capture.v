
module ov7670_capture #(
    parameter IMAGE_WIDTH  = 320,
    parameter IMAGE_HEIGHT = 240
) (
    input wire        pclk,
    input wire        reset,
    input wire        vsync,
    input wire        href,
    input wire [7:0]  data_in,

    output reg        pixel_valid,
    output reg [15:0] pixel_data,
    output reg [16:0] pixel_addr,
    output reg        frame_done
);

    reg [7:0] high_byte;
    reg       byte_phase;

    reg [8:0] x_count;
    reg [7:0] y_count;

    reg capturing;
    reg vsync_d;
    reg href_d;

    wire frame_start = vsync_d && !vsync;
    wire line_end    = href_d && !href;

    always @(posedge pclk or posedge reset) begin
        if (reset) begin
            high_byte   <= 8'd0;
            byte_phase  <= 1'b0;
            x_count     <= 9'd0;
            y_count     <= 8'd0;

            pixel_valid <= 1'b0;
            pixel_data  <= 16'd0;
            pixel_addr  <= 17'd0;
            frame_done  <= 1'b0;

            capturing   <= 1'b0;
            vsync_d     <= 1'b1;
            href_d      <= 1'b0;
        end
        else begin
            vsync_d     <= vsync;
            href_d      <= href;
            pixel_valid <= 1'b0;

            if (frame_start && !frame_done) begin
                capturing  <= 1'b1;
                byte_phase <= 1'b0;
                x_count    <= 9'd0;
                y_count    <= 8'd0;
            end
            else if (capturing) begin

                // End of an active camera line.
                if (line_end) begin
                    byte_phase <= 1'b0;
                    x_count    <= 9'd0;

                    if (y_count < IMAGE_HEIGHT)
                        y_count <= y_count + 1'b1;
                end

                // Process camera bytes only during active video.
                if (href && y_count < IMAGE_HEIGHT) begin
                    if (!byte_phase) begin
                        high_byte  <= data_in;
                        byte_phase <= 1'b1;
                    end
                    else begin
                        byte_phase <= 1'b0;

                        if (x_count < IMAGE_WIDTH) begin
                            pixel_data  <= {high_byte, data_in};
                            pixel_addr  <= y_count * IMAGE_WIDTH + x_count;
                            pixel_valid <= 1'b1;

                            if ((x_count == IMAGE_WIDTH - 1) &&
                                (y_count == IMAGE_HEIGHT - 1)) begin
                                capturing  <= 1'b0;
                                frame_done <= 1'b1;
                            end
                            else begin
                                x_count <= x_count + 1'b1;
                            end
                        end
                    end
                end
            end
        end
    end

endmodule
