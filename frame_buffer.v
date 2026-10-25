
module frame_buffer (
    input wire        wr_clk,
    input wire        wr_en,
    input wire [16:0] wr_addr,
    input wire [15:0] wr_data,

    input wire        rd_clk,
    input wire [16:0] rd_addr,
    output reg [15:0] rd_data
);

    // 320 x 240 pixels, 16 bits per pixel (RGB565)
    localparam FRAME_SIZE = 76800;

    reg [15:0] memory [0:FRAME_SIZE-1];

    // Camera side: write one pixel on each enabled clock edge
    always @(posedge wr_clk) begin
        if (wr_en && wr_addr < FRAME_SIZE)
            memory[wr_addr] <= wr_data;
    end

    // Display side: synchronous memory read
    always @(posedge rd_clk) begin
        if (rd_addr < FRAME_SIZE)
            rd_data <= memory[rd_addr];
        else
            rd_data <= 16'h0000;
    end

endmodule
