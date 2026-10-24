module ov7670_config (input clk,
                      input reset,
                      input write_done,
                      output write_start,
                      output [7:0] reg_addr,
                      output [7:0] reg_data,
                      output config_done );

    reg wire_start_t, config_done_t;
    reg [7:0] reg_addr_t, reg_data_t;

    reg [3:0] index;
    reg [1:0] state;

    assign write_start = wire_start_t;
    assign reg_addr = reg_addr_t;
    assign reg_data = reg_data_t;
    assign config_done = config_done_t;

    localparam IDLE = 2'b00;
    localparam START_WRITE = 2'b01;
    localparam WAIT_WRITE = 2'b10;
    localparam FINISHED = 2'b11;


    
always @(*) begin
        reg_addr = 8'h12;
        reg_data = 8'h80;

        case (index)
            0: begin 
                reg_addr = 8'h12;  //resetting all the reisters
                reg_data = 8'h80;
              end
            1: begin 
                reg_addr = 8'h12; 
                reg_data = 8'h04;   //selecting the RGB mode
               end
            2: begin 
                reg_addr = 8'h11;  //dividing the clock
                reg_data = 8'h01; 
               end
            3: begin 
                reg_addr = 8'h0C; //
                reg_data = 8'h00; 
               end
            4: begin 
                reg_addr = 8'h3E;  //division of pclk
                reg_data = 8'h00; 
               end
            5: begin 
                reg_addr = 8'h40; //selecting RGB565
                reg_data = 8'hD0;
               end
            6: begin 
                reg_addr = 8'h8C; //disabling rgb444
                reg_data = 8'h00; 
               end
            default: begin
                reg_addr = 8'h12;
                reg_data = 8'h04;
            end
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            index       <= 4'd0;
            write_start <= 1'b0;
            config_done <= 1'b0;
        end 

        else begin
            write_start <= 1'b0;

            case (state)
                IDLE: begin
                    index       <= 4'd0;
                    config_done <= 1'b0;
                    state       <= START_WRITE;
                end

                START_WRITE: begin
                    write_start <= 1'b1;
                    state       <= WAIT_WRITE;
                end
                

                WAIT_WRITE: begin
                    if (write_done) begin
                        if (index == 4'd6) begin
                            state <= FINISHED;
                        end else begin
                            index <= index + 1'b1;
                            state <= START_WRITE;
                        end
                    end
                end

                FINISHED: begin
                    config_done <= 1'b1;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule