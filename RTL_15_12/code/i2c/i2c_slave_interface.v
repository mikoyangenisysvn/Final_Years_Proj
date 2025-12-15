//=====================================================================
// Module: i2c_slave_interface
// Description:
//   I2C slave interface including address detection, read/write
//   data handling, ACK generation and state machine.
//
// Author: [Your Name]
// Standard: ARM / Intel / Xilinx HDL Naming Convention
//=====================================================================

module i2c_slave_interface (
    //-----------------------------------------------------------------
    // Clock & Reset
    //-----------------------------------------------------------------
    input  wire        clk_i,
    input  wire        rst_n_i,

    //-----------------------------------------------------------------
    // I2C signals (filtered externally)
    //-----------------------------------------------------------------
    input  wire        sda_i,
    input  wire        scl_i,
    output reg         sda_out_o,

    //-----------------------------------------------------------------
    // Configuration
    //-----------------------------------------------------------------
    input  wire [6:0]  slave_address_i,

    //-----------------------------------------------------------------
    // External register interface
    //-----------------------------------------------------------------
    output reg  [7:0]  i2c_rx_data_o,      // Data received from master
    input  wire [7:0]  i2c_tx_data_i,      // Data transmitted to master

    output wire        wr_req_o,           // Write to register request
    output wire        rd_req_o,           // Read from register request
    input  wire        wr_allow_i,
    input  wire        rd_allow_i,

    output wire        addr_match_o,       // 1 when address matches
    output reg         rw_bit_o,           // 0=write, 1=read

    //-----------------------------------------------------------------
    // Start/Stop/Edge detect signals (from I2C detector)
    //-----------------------------------------------------------------
    input  wire        edge_detect_i,
    input  wire        start_detected_i,
    input  wire        stop_detected_i
);

    //-----------------------------------------------------------------
    // State Machine Encoding
    //-----------------------------------------------------------------
    localparam IDLE            = 4'd0;
    localparam ADDR            = 4'd1;
    localparam RW              = 4'd2;
    localparam ACK_ADDR        = 4'd3;
    localparam MASTER_TX       = 4'd4;
    localparam ACK_MASTER_TX   = 4'd5;
    localparam MASTER_RX       = 4'd6;
    localparam ACK_MASTER_RX   = 4'd7;
    localparam REG_RX          = 4'd8;
    localparam REG_TX          = 4'd9;
    localparam STOP            = 4'd10;

    //-----------------------------------------------------------------
    // Internal registers
    //-----------------------------------------------------------------
    reg [3:0] state_q, next_state;
    reg [3:0] bit_cnt_q;
    reg [6:0] slave_addr_shift_q;
    reg [15:0] i2c_tx_data_q;
    //-----------------------------------------------------------------
    // Assign outputs
    //-----------------------------------------------------------------
    assign rd_req_o    = (state_q == REG_RX);
    assign wr_req_o    = (state_q == REG_TX);
    assign addr_match_o = (slave_addr_shift_q == slave_address_i);

    //-----------------------------------------------------------------
    // Sequential logic
    //-----------------------------------------------------------------
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_q             <= IDLE;
            i2c_rx_data_o       <= 8'd0;
            bit_cnt_q           <= 4'd0;
            slave_addr_shift_q  <= 7'd0;
            rw_bit_o            <= 1'b0;
        end 
        else begin
            state_q <= next_state;

            if (start_detected_i || stop_detected_i)
                bit_cnt_q <= 4'd0;

            if (edge_detect_i) begin
                case (state_q)

                    ADDR: begin
                        slave_addr_shift_q <= {slave_addr_shift_q[5:0], sda_i};
                        bit_cnt_q          <= bit_cnt_q + 1'b1;
                    end

                    MASTER_TX: begin
                        i2c_rx_data_o      <= {i2c_rx_data_o[6:0], sda_i};
                        bit_cnt_q          <= bit_cnt_q + 1'b1;
                    end

                    MASTER_RX: begin
                        bit_cnt_q          <= bit_cnt_q + 1'b1;
                    end

                    RW: begin
                        rw_bit_o <= sda_i;
                    end

                    REG_RX:begin
                        i2c_tx_data_q <= i2c_tx_data_i;
                    end

                default: begin
                    bit_cnt_q          <= 4'd0;
                    slave_addr_shift_q <= 7'd0;
                end

                endcase
            end
        end
    end

    //-----------------------------------------------------------------
    // SDA output control (on falling edge of SCL)
    //-----------------------------------------------------------------
    always @(negedge scl_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            sda_out_o <= 1'b0;
        end else begin
            case (state_q)

                ACK_ADDR: begin
                    sda_out_o <= (addr_match_o) ? 1'b1 : 1'b0;   // ACK/NACK
                end

                MASTER_RX: begin
                    sda_out_o <= ~i2c_tx_data_q[7 - bit_cnt_q[2:0]];
                end

                ACK_MASTER_TX: begin
                    sda_out_o <= wr_allow_i;
                end

                default:
                    sda_out_o <= 1'b0;
            endcase
        end
    end

    //-----------------------------------------------------------------
    // Next State Logic
    //-----------------------------------------------------------------
    always @(*) begin
        if (!rst_n_i) begin
            next_state = IDLE;
        end
        else if (stop_detected_i) begin
            next_state = IDLE;
        end 
        else if (start_detected_i) begin
            next_state = ADDR;
        end 
        else begin
            case (state_q)

                IDLE: next_state = IDLE;

                ADDR:
                    next_state = (bit_cnt_q == 4'd7) ? RW : ADDR;

                RW:
                    next_state = (edge_detect_i) ? ACK_ADDR : RW;

                ACK_ADDR: begin
                    if (edge_detect_i) begin
                        next_state = (addr_match_o) ?
                            (rw_bit_o ? REG_RX : MASTER_TX) :
                            STOP;
                    end else
                        next_state = ACK_ADDR;
                end

                MASTER_TX:
                    next_state = (bit_cnt_q == 4'd8) ? REG_TX : MASTER_TX;

                REG_TX:
                    next_state = (bit_cnt_q == 4'd8) ? ACK_MASTER_TX : REG_TX;

                ACK_MASTER_TX:
                    next_state = (edge_detect_i) ? MASTER_TX : ACK_MASTER_TX;

                REG_RX:
                    next_state = (rd_req_o) ? MASTER_RX : REG_RX;

                MASTER_RX:
                    next_state = (bit_cnt_q == 4'd8) ? ACK_MASTER_RX : MASTER_RX;

                ACK_MASTER_RX:
                    next_state = (edge_detect_i) ?
                                (sda_i ? STOP : REG_RX) :
                                ACK_MASTER_RX;

                STOP:
                    next_state = stop_detected_i ? IDLE : STOP;

                default:
                    next_state = IDLE;
            endcase
        end
    end

endmodule
