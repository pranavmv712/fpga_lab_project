module sccb_master #(
    parameter HALF_DIV = 250
)(
    input        clk,          // 50 MHz FPGA clock
    input        reset,        // Active-high reset
    input        write_start,  // Start one register write
    input  [7:0] reg_addr,     // Camera register address
    input  [7:0] reg_data,     // Value to write

    output reg   sioc,         // SCCB serial clock
    inout        siod,         // SCCB bidirectional data
    output reg   busy,
    output reg   write_done
);

    // Open-drain data interface:
    // Drive LOW or release the line. Never drive HIGH.
    reg siod_drive_low;

    assign siod = siod_drive_low ? 1'b0 : 1'bz;

    reg [31:0] divider;
    reg [3:0] state;

    reg [7:0] tx_byte;
    reg [3:0] bit_count;
    reg [1:0] byte_index;

    localparam IDLE        = 4'd0;
    localparam START       = 4'd1;
    localparam BIT_LOW     = 4'd2;
    localparam BIT_HIGH    = 4'd3;
    localparam ACK_LOW     = 4'd4;
    localparam ACK_HIGH    = 4'd5;
    localparam STOP_SETUP  = 4'd6;
    localparam STOP_HIGH   = 4'd7;
    localparam STOP_RELEASE= 4'd8;

    // One timing tick every HALF_DIV FPGA clock cycles.
    // With 50 MHz and HALF_DIV=250, SIOC is approximately 100 kHz.
    wire tick = (divider == HALF_DIV - 1);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            divider <= 0;
        end else if (!busy || tick) begin
            divider <= 0;
        end else begin
            divider <= divider + 1'b1;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state          <= IDLE;
            sioc           <= 1'b1;
            siod_drive_low <= 1'b0;
            busy           <= 1'b0;
            write_done     <= 1'b0;
            tx_byte        <= 8'h00;
            bit_count      <= 0;
            byte_index     <= 0;
        end else begin
            // Completion is a one-clock pulse.
            write_done <= 1'b0;

            case (state)

                IDLE: begin
                    sioc           <= 1'b1;
                    siod_drive_low <= 1'b0;
                    busy           <= 1'b0;

                    if (write_start) begin
                        busy       <= 1'b1;
                        byte_index <= 0;
                        bit_count  <= 0;
                        tx_byte    <= 8'h42; // OV7670 address + write
                        state      <= START;
                    end
                end

                START: begin
                    if (tick) begin
                        // Start condition: SIOD falls while SIOC is high.
                        sioc           <= 1'b1;
                        siod_drive_low <= 1'b1;
                        state          <= BIT_LOW;
                    end
                end

                BIT_LOW: begin
                    if (tick) begin
                        sioc <= 1'b0;

                        // Present the next data bit while clock is low.
                        if (tx_byte[7])
                            siod_drive_low <= 1'b0;
                        else
                            siod_drive_low <= 1'b1;

                        state <= BIT_HIGH;
                    end
                end

                BIT_HIGH: begin
                    if (tick) begin
                        sioc <= 1'b1;

                        // After eight bits, enter the ninth-bit slot.
                        if (bit_count == 4'd7) begin
                            bit_count <= 0;
                            state     <= ACK_LOW;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                            tx_byte   <= {tx_byte[6:0], 1'b0};
                            state     <= BIT_LOW;
                        end
                    end
                end

                ACK_LOW: begin
                    if (tick) begin
                        sioc           <= 1'b0;
                        siod_drive_low <= 1'b0; // Release SIOD
                        state          <= ACK_HIGH;
                    end
                end

                ACK_HIGH: begin
                    if (tick) begin
                        sioc <= 1'b1;

                        // SCCB's ninth bit is treated as a don't-care
                        // phase here; we do not require an I2C-style ACK.
                        if (byte_index == 2'd0) begin
                            byte_index <= 1;
                            tx_byte    <= reg_addr;
                            state      <= BIT_LOW;
                        end else if (byte_index == 2'd1) begin
                            byte_index <= 2;
                            tx_byte    <= reg_data;
                            state      <= BIT_LOW;
                        end else begin
                            state <= STOP_SETUP;
                        end
                    end
                end

                STOP_SETUP: begin
                    if (tick) begin
                        sioc           <= 1'b0;
                        siod_drive_low <= 1'b1;
                        state          <= STOP_HIGH;
                    end
                end

                STOP_HIGH: begin
                    if (tick) begin
                        sioc  <= 1'b1;
                        state <= STOP_RELEASE;
                    end
                end

                STOP_RELEASE: begin
                    if (tick) begin
                        // Stop condition: release SIOD while SIOC is high.
                        siod_drive_low <= 1'b0;
                        busy           <= 1'b0;
                        write_done     <= 1'b1;
                        state          <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule