module i2c_slave_interface #(
    parameter SLAVE_ADDR = 7'h50 // Địa chỉ 7-bit của slave
)(
    input  wire clk,
    input  wire rst_n,

    inout  wire SDA_bus,
    input  wire SCL_bus,

    // --- Interface với logic bên ngoài ---
    output reg  [6:0] addr_out,  // địa chỉ nhận được từ master
    output reg  [7:0] i2c_rx_data,   // dữ liệu nhận từ master
    output wire        send_rx,  // 1 xung khi nhận xong 1 byte

    input  wire [7:0] i2c_tx_data,   // dữ liệu cần gửi cho master
    output  wire       get_tx,  // dữ liệu hợp lệ cho lần truyền tiếp theo

    output wire        addr_match, // 1 khi địa chỉ khớp
    output reg         inframe,
    output reg         sr_start,
    output reg          rw_bit,
    output wire         edge_detect
);

    // --- Tín hiệu từ module phát hiện START/STOP ---
    wire start_detected, stop_detected;

    reg SDA_buf;
    reg SCL_buf;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            SDA_buf<= 1;
            SCL_buf <= 1;
        end
        else begin
            SDA_buf <= SDA_bus;
            SCL_buf <= SCL_bus;
        end

    end

    i2c_start_stop_detect i2c_start_stop_detect_inst(
        .clk(clk),
        .rst_n(rst_n),
        .sda_in(SDA_buf),
        .scl_in(SCL_buf),
        .start_detected(start_detected),
        .stop_detected(stop_detected),
        .edge_detect(edge_detect)
    );

    // --- State Machine ---
    localparam IDLE          = 4'd0;
    localparam ADDR          = 4'd1;
    localparam RW            = 4'd2;
    localparam ACK_ADDR      = 4'd3;
    localparam RECEIVE       = 4'd4;
    localparam ACK_RECEIVE   = 4'd5;
    localparam TRANSMIT      = 4'd6;
    localparam ACK_TRANSMIT  = 4'd7;    
    localparam STOP          = 4'd8;
    localparam GET_TRANSMIT  = 4'd9;


    reg [3:0] state, next_state;
    reg [3:0] bit_cnt;
    reg sda_out_en;

    assign SDA_bus = sda_out_en ? 1'b0 : 1'bz; // open-drain behavior
    assign get_tx = (state == GET_TRANSMIT) ? 1'b1 : 1'b0;

    always @(posedge clk or negedge rst_n)begin
        if (!rst_n) begin
            inframe <= 1'b0;
            sr_start <= 1'b0;
        end else begin
            if(inframe)begin
                if(start_detected) sr_start <= 1'b1;
                else if (stop_detected) begin
                    inframe <= 1'b0;
                    sr_start <= 1'b0;
                end
                else inframe<= inframe;
            end
            else if(start_detected) inframe <= 1'b1;
            else inframe <= inframe;
        end
    end

    // --- FSM đồng bộ ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            i2c_rx_data    <= 8'd0;
            bit_cnt    <= 0;
            addr_out   <= 7'd0;
            rw_bit     <= 0;
        end else begin
            state <= next_state;
            if(state != ADDR && state != RECEIVE && state != TRANSMIT) bit_cnt <= 0;
            if(start_detected || stop_detected) bit_cnt <= 0;
            if (edge_detect) begin
                case (state)

                    ADDR: begin
                        addr_out <= {addr_out[5:0], SDA_bus};
                        bit_cnt   <= bit_cnt + 1'b1;
                    end

                    RECEIVE: begin
                        i2c_rx_data <= {i2c_rx_data[6:0], SDA_bus};
                        bit_cnt   <= bit_cnt + 1'b1;
                    end

                    TRANSMIT: begin
                        bit_cnt   <= bit_cnt + 1'b1;
                    end

                    RW: begin
                        rw_bit <= SDA_bus;
                    end
                default:bit_cnt <= 0;

                endcase
            end
        end
    end

    assign addr_match = (addr_out[6:0] == SLAVE_ADDR)? 1 :0 ;

    always @(negedge SCL_bus or negedge rst_n)begin
        if (!rst_n) begin
            sda_out_en = 1'b0;
        end else
            case (state)
                ACK_ADDR: begin
                    sda_out_en =  (addr_match)? 1'b1 : 1'b0; // ACK
                end

                TRANSMIT: begin
                    sda_out_en <= ~i2c_tx_data[7-bit_cnt[2:0]];
                end

                ACK_RECEIVE: begin
                    sda_out_en = 1'b1;
                end

                default: sda_out_en = 1'b0;
            endcase
    
    end
assign send_rx = (state == RECEIVE && bit_cnt == 4'd8)? 1'b1 : 1'b0;
    // --- Next state logic ---
    always @(*) begin
        if (!rst_n) begin
            next_state = IDLE;
        end
        else if (stop_detected) next_state = IDLE;
        else if (start_detected) next_state = ADDR;
        else begin
            
            // get_tx = (next_state == TRANSMIT && bit_cnt == 4'd0)? 1'b1 : 1'b0;
            case (state)
                IDLE: begin
                    next_state = IDLE;
                end

                ADDR: begin
                    if (bit_cnt == 4'd7) begin
                        next_state= RW;
                    end
                    else next_state = ADDR;
                end

                RW: begin
                    if (edge_detect) next_state= ACK_ADDR;
                    else next_state = RW;
                end

                ACK_ADDR: begin
                    if (edge_detect) begin
                        if (addr_match) next_state = (rw_bit) ? GET_TRANSMIT : RECEIVE;
                        else next_state = STOP;
                    end
                    else next_state = ACK_ADDR;
                end

                RECEIVE: begin
                    if (bit_cnt == 4'd8 ) next_state= ACK_RECEIVE;
                    else next_state = RECEIVE;
                end

                ACK_RECEIVE: begin
                    if (edge_detect) next_state = RECEIVE;
                    else next_state = ACK_RECEIVE;
                end

                GET_TRANSMIT: begin
                    if(get_tx) next_state = TRANSMIT;
                    else next_state = GET_TRANSMIT;
                end

                TRANSMIT: begin
                    if (bit_cnt == 4'd8 ) next_state= ACK_TRANSMIT;
                    else next_state = TRANSMIT;
                end

                ACK_TRANSMIT: begin
                    if (edge_detect) begin
                       if(SDA_bus) next_state = STOP;
                       else next_state = GET_TRANSMIT;
                    end
                    else next_state = ACK_TRANSMIT;
                end

                STOP: begin
                    if (stop_detected) next_state = IDLE;
                    else next_state = STOP;
                end
            
                default: next_state = IDLE;
            endcase
        end
    end

endmodule
