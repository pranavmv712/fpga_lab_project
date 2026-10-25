
module vga_controller (
    input wire clk_pix,
    input wire reset,

    output wire hsync,
    output wire vsync,
    output wire video_on,

    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y
);

    // 640 x 480 VGA timing
    // Horizontal: 640 active + 16 front + 96 sync + 48 back = 800
    // Vertical:   480 active + 10 front +  2 sync + 33 back = 525

    localparam H_ACTIVE = 640;
    localparam H_FRONT  = 16;
    localparam H_SYNC   = 96;
    localparam H_BACK   = 48;
    localparam H_TOTAL  = 800;

    localparam V_ACTIVE = 480;
    localparam V_FRONT  = 10;
    localparam V_SYNC   = 2;
    localparam V_BACK   = 33;
    localparam V_TOTAL  = 525;

    // Visible area starts after sync and back porch
    localparam H_START = H_SYNC + H_BACK;  // 144
    localparam V_START = V_SYNC + V_BACK;  // 35

    reg [9:0] h_count;
    reg [9:0] v_count;

    // Horizontal and vertical counters
    always @(posedge clk_pix or posedge reset) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end
        else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;

                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 1'b1;
            end
            else begin
                h_count <= h_count + 1'b1;
            end
        end
    end

    // VGA sync signals are active LOW
    assign hsync = ~((h_count < H_SYNC));
    assign vsync = ~((v_count < V_SYNC));

    // True only during the visible image area
    assign video_on =
        (h_count >= H_START) &&
        (h_count < H_START + H_ACTIVE) &&
        (v_count >= V_START) &&
        (v_count < V_START + V_ACTIVE);

    // Coordinates are meaningful when video_on is high
    assign pixel_x = h_count - H_START;
    assign pixel_y = v_count - V_START;

endmodule
