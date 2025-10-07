module i2c_frame_bridge(
    input wire clk, rst_n,
    input wire [7:0] rx_data,
    input wire rx_valid,
    
    input wire tx_valid,
    output reg [7:0] tx_data,

    input wire sr_start,
    input wire inframe,
    input wire rw_bit, addr_match,

    output reg [15:0] addr,
    output wire wr_en,
    output wire rd_en,
    output reg [31:0] wdata,
    input wire [31:0] rdata,

    input wire edge_detect
);

    reg [31:0] rdata_buf;

localparam  IDLE = 4'd0,
            ADDR_MATCH = 4'd1,
            ADDR_REG = 4'd2,
            WRITE = 4'd4,
            REG_WRITE = 4'd5,
            READ = 4'd6,
            REG_READ = 4'd7,
            STOP = 4'd8;

    reg [3:0] state, next_state;
    reg [3:0] count;

    assign wr_en = (state == REG_WRITE) ? 1'b1 : 1'b0;
    assign rd_en = (state == REG_READ) ? 1'b1 : 1'b0;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            addr <= 0;
            wdata <= 0;
            count <= 0;
        end 
        else begin
            state <= next_state;
//            rd_en <= 0;
//            wr_en <= 0;
            case (state)
                ADDR_REG : begin
                    if(rx_valid) begin
                        addr <= {addr[7:0],rx_data};
                        count <= count + 1'b1;
                    end
                    else addr <= addr;
                end 

                WRITE : begin
//                    wr_en <= 1;
                    if(rx_valid) begin
                        wdata <= {wdata[23:0],rx_data};
                        count <= count + 1'b1;
                    end
                    else wdata <= wdata;
                end

                READ : begin                   
                    if(tx_valid) begin
                        count <= count + 1'b1;
                    end
                    else count <= count;
                end
                REG_READ  : begin
                    rdata_buf <= rdata;
                    count <= 0;
                end

                default: count <= 0;
            endcase
        end
    end


    always @(*) begin
        case (count)
            4: tx_data = rdata_buf[7:0];
            3: tx_data = rdata_buf[15:8];
            2: tx_data = rdata_buf[23:16];
            1: tx_data = rdata_buf[31:24];
            default: tx_data = 8'h00;
        endcase
    end 


    always @(*) begin
        if (!rst_n) begin
            next_state = IDLE;
        end else if(!inframe)next_state = IDLE;
        else begin
            case (state)
                IDLE : begin
                    if(inframe) next_state = ADDR_MATCH;
                    else next_state = IDLE;
                end

                ADDR_MATCH : begin
                    if(addr_match) next_state = ADDR_REG;
                    else next_state = ADDR_MATCH;
                end

                ADDR_REG : begin
                    if (count == 2) begin
                        next_state = WRITE;
                    end else begin
                        next_state = ADDR_REG;                  
                    end
                end

                WRITE : begin
                    if(sr_start) next_state = REG_READ;
                    else if (count == 6) next_state = REG_WRITE;
                    else  next_state =  WRITE;                  
                end

                REG_WRITE : begin
                    if (edge_detect) next_state = WRITE;
                    else  next_state =  REG_WRITE;                  
                end

                READ : begin
                    if (count == 6) next_state = REG_READ;
                    else  next_state =  READ;                  
                end

                REG_READ : begin
                    if (edge_detect) next_state = READ;
                    else  next_state =  REG_READ;                  
                end

                STOP:begin
                    if(edge_detect) begin
                        if(!inframe) next_state = IDLE;
                        else  next_state =  STOP; 
                    end
                    else  next_state =  STOP; 
                end
                default:  next_state =  IDLE;
            endcase
        end
    end

endmodule