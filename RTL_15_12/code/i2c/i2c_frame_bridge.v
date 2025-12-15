//=====================================================================
// Module: i2c_frame_bridge
// Description:
//   Bridges I2C data between I2C slave interface and register interface.
//   Handles write/read sequencing with start/stop detection.
//
// Author: [Your Name]
// Standard: ARM / Intel / Xilinx HDL Naming Convention
//=====================================================================

module i2c_frame_bridge (
    //-----------------------------------------------------------------
    // Clock & Reset
    //-----------------------------------------------------------------
    input  wire        clk_i,
    input  wire        rst_n_i,

    //-----------------------------------------------------------------
    // I2C interface
    //-----------------------------------------------------------------
    input  wire [7:0]  i2c_rx_data_i,
    input  wire        wr_req_i,
    input  wire        rd_req_i,
    output wire        wr_allow_o,
    output wire        rd_allow_o,
    output reg  [7:0]  i2c_tx_data_o,
    input  wire        rw_bit_i,
    input  wire        addr_match_i,

    //-----------------------------------------------------------------
    // Register interface
    //-----------------------------------------------------------------
    output reg  [7:0]  addr_o,
    output wire        wr_en_o,
    output wire        rd_en_o,
    output reg  [15:0] wdata_o,
    input  wire [15:0] rdata_i,

    //-----------------------------------------------------------------
    // Control signals
    //-----------------------------------------------------------------
    input  wire        edge_detect_i,
    input  wire        start_detected_i,
    input  wire        stop_detected_i
);

    //----------------------------------------------------------
    // Internal registers and wires
    //----------------------------------------------------------
    reg [15:0] rdata_buf_r;
    reg [3:0]  state_r, next_state_r;
    reg [3:0]  count_r;

    assign wr_allow_o = 1'b1;
    assign rd_allow_o = 1'b1;

    //----------------------------------------------------------
    // State encoding
    //----------------------------------------------------------
    localparam IDLE       = 4'd0,
               ADDR_REG   = 4'd2,
               WRITE      = 4'd4,
               REG_WRITE  = 4'd5,
               READ       = 4'd6,
               REG_READ   = 4'd7,
               STOP       = 4'd8;

    //----------------------------------------------------------
    // Output enables
    //----------------------------------------------------------
    assign wr_en_o = (state_r == REG_WRITE) ? 1'b1 : 1'b0;
    assign rd_en_o = (state_r == REG_READ)  ? 1'b1 : 1'b0;

    //----------------------------------------------------------
    // Sequential logic: State machine and data registers
    //----------------------------------------------------------
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_r     <= IDLE;
            addr_o      <= 8'd0;
            wdata_o     <= 16'd0;
            count_r     <= 4'd0;
            rdata_buf_r <= 16'd0;
        end else begin
            if (stop_detected_i) begin
                state_r <= IDLE;
            end else begin
                state_r <= next_state_r;
                case (state_r)

                    ADDR_REG : begin
                        if (wr_req_i) addr_o <= i2c_rx_data_i;
                    end

                    WRITE : begin
                        if (wr_req_i) begin
                            wdata_o <= {wdata_o[7:0], i2c_rx_data_i};
                            count_r <= count_r + 1'b1;
                        end
                    end

                    READ : begin
                        if (rd_req_i)
                            count_r <= count_r + 1'b1;
                    end

                    REG_READ : begin
                        rdata_buf_r <= rdata_i;
                        count_r     <= 4'd0;
                    end

                    default: begin
                        count_r <= 4'd0;
                    end
                endcase
            end
        end
    end

    //----------------------------------------------------------
    // Output data multiplexer
    //----------------------------------------------------------
    always @(*) begin
        case (count_r)
            0: i2c_tx_data_o = rdata_buf_r[7:0];
            1: i2c_tx_data_o = rdata_buf_r[15:8];
            default: i2c_tx_data_o = 8'h00;
        endcase
    end

    //----------------------------------------------------------
    // Next state logic
    //----------------------------------------------------------
    always @(*) begin
        if (!rst_n_i)
            next_state_r = IDLE;
        else begin
            case (state_r)
                IDLE : begin
                    if (addr_match_i) next_state_r = ADDR_REG;  
                    else              next_state_r = IDLE;
                end

                ADDR_REG : begin
                    if (wr_req_i) next_state_r = WRITE;
                    else          next_state_r = ADDR_REG;
                end

                WRITE : begin
                    if (start_detected_i)       next_state_r = REG_READ;
                    else if (count_r == 4'd2)  next_state_r = REG_WRITE;
                    else                        next_state_r = WRITE;
                end

                REG_WRITE : begin
                    next_state_r = WRITE;
                end

                READ : begin
                    if (count_r == 4'd2) next_state_r = REG_READ;
                    else                 next_state_r = READ;
                end

                REG_READ : begin
                    next_state_r = READ;
                end

                STOP : begin
                    if (stop_detected_i) next_state_r = IDLE;
                    else                 next_state_r = STOP;
                end

                default: next_state_r = IDLE;
            endcase
        end
    end

endmodule
