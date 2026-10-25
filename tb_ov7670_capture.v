
`timescale 1ns/1ps

module tb_ov7670_capture;

    reg pclk = 0;
    reg reset = 1;
    reg vsync = 1;
    reg href = 0;
    reg [7:0] data_in = 0;

    wire pixel_valid;
    wire [15:0] pixel_data;
    wire [16:0] pixel_addr;
    wire frame_done;

    integer received = 0;
    integer errors = 0;

    ov7670_capture #(
        .IMAGE_WIDTH(4),
        .IMAGE_HEIGHT(2)
    ) dut (
        .pclk(pclk),
        .reset(reset),
        .vsync(vsync),
        .href(href),
        .data_in(data_in),
        .pixel_valid(pixel_valid),
        .pixel_data(pixel_data),
        .pixel_addr(pixel_addr),
        .frame_done(frame_done)
    );

    always #10 pclk = ~pclk;

    // Check the registered output after nonblocking assignments settle.
    always @(posedge pclk) begin
        #1;
        if (pixel_valid) begin
            $display("Pixel %0d: addr=%0d data=%h",
                     received, pixel_addr, pixel_data);

            case (received)
                0: if (pixel_data !== 16'hF800) errors = errors + 1;
                1: if (pixel_data !== 16'h07E0) errors = errors + 1;
                2: if (pixel_data !== 16'h001F) errors = errors + 1;
                3: if (pixel_data !== 16'hFFFF) errors = errors + 1;
                4: if (pixel_data !== 16'h0000) errors = errors + 1;
                5: if (pixel_data !== 16'hF800) errors = errors + 1;
                6: if (pixel_data !== 16'h07E0) errors = errors + 1;
                7: if (pixel_data !== 16'h001F) errors = errors + 1;
                default: errors = errors + 1;
            endcase

            if (pixel_addr !== received)
                errors = errors + 1;

            received = received + 1;
        end
    end

    task send_byte;
        input [7:0] value;
        begin
            @(negedge pclk);
            data_in = value;
        end
    endtask

    task send_pixel;
        input [15:0] value;
        begin
            send_byte(value[15:8]);
            send_byte(value[7:0]);
        end
    endtask

    
task send_line;
    input [15:0] p0, p1, p2, p3;
    begin
        // Assert HREF before the first byte is presented.
        @(negedge pclk);
        href = 1'b1;
        data_in = p0[15:8];

        @(negedge pclk);
        data_in = p0[7:0];

        @(negedge pclk);
        data_in = p1[15:8];

        @(negedge pclk);
        data_in = p1[7:0];

        @(negedge pclk);
        data_in = p2[15:8];

        @(negedge pclk);
        data_in = p2[7:0];

        @(negedge pclk);
        data_in = p3[15:8];

        @(negedge pclk);
        data_in = p3[7:0];

        @(negedge pclk);
        href = 1'b0;
    end
endtask


    
always @(posedge pclk) begin
    $display("t=%0t href=%b data=%h phase=%b high=%h valid=%b pixel=%h",
             $time, href, data_in, dut.byte_phase,
             dut.high_byte, pixel_valid, pixel_data);
end


    initial begin
        repeat (4) @(negedge pclk);
        reset = 0;

        // Start frame with VSYNC falling edge.
        repeat (2) @(negedge pclk);
        vsync = 0;

        send_line(16'hF800, 16'h07E0, 16'h001F, 16'hFFFF);
        send_line(16'h0000, 16'hF800, 16'h07E0, 16'h001F);

        repeat (3) @(negedge pclk);

        $display("Received=%0d Errors=%0d frame_done=%b",
                 received, errors, frame_done);

        if (received == 8 && errors == 0 && frame_done)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");

        $finish;
    end

endmodule
