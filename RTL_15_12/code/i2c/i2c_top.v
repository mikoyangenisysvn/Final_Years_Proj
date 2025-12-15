module i2c_top (
    //----------------------------------------------------------------------
    // Clock & Reset
    //----------------------------------------------------------------------
    input  wire        clk_i,
    input  wire        rst_n_i,

    //----------------------------------------------------------------------
    // I2C bus
    //----------------------------------------------------------------------
    inout  wire        sda_io,          // SDA open-drain
    input  wire        scl_i,           // SCL input

    //----------------------------------------------------------------------
    // Address configuration (DIP switch)
    //----------------------------------------------------------------------
    input  wire [2:0]  address_set_pin_i,

    //----------------------------------------------------------------------
    // Bridge interface output
    //----------------------------------------------------------------------
    output wire [7:0]  addr_o,
    output wire [15:0] wdata_o,
    input  wire [15:0] rdata_i,
    output wire        wr_en_o,
    output wire        rd_en_o
);

    //----------------------------------------------------------------------
    // Internal wires
    //----------------------------------------------------------------------
    wire [7:0]  rx_data_w;
    wire [7:0]  tx_data_w;

    wire        rd_req_w,  wr_req_w;
    wire        rd_allow_w, wr_allow_w;

    // wire        addr_match_w;
    wire        rw_bit_w;
    wire [6:0]  slave_addr_w;

    wire        sda_out_w;
    wire        sda_filt_w, scl_filt_w;

    wire        start_detected_w;
    wire        stop_detected_w;
    wire        edge_detect_w;

    //----------------------------------------------------------------------
    // SDA open-drain behavior
    //----------------------------------------------------------------------
    assign sda_io = sda_out_w ? 1'b0 : 1'bz;

    //----------------------------------------------------------------------
    // Input filter
    //----------------------------------------------------------------------
    i2c_input_filter u_filter (
        .clk_i     (clk_i),
        .rst_n_i   (rst_n_i),
        .sda_i     (sda_io),
        .scl_i     (scl_i),
        .sda_filt_o(sda_filt_w),
        .scl_filt_o(scl_filt_w)
    );

    //----------------------------------------------------------------------
    // Address configuration
    //----------------------------------------------------------------------
    i2c_address_config #(
        .DELAY_CYCLES(3)
    ) u_i2c_addr_cfg (
        .clk_i            (clk_i),
        .rst_n_i          (rst_n_i),
        .address_set_pin_i(address_set_pin_i),
        .slave_address_o  (slave_addr_w)
    );

    //----------------------------------------------------------------------
    // Start / Stop detection
    //----------------------------------------------------------------------
    i2c_start_stop_detect u_start_stop_detect (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        .sda_i          (sda_filt_w),
        .scl_i          (scl_filt_w),
        .start_detected_o(start_detected_w),
        .stop_detected_o (stop_detected_w),
        .edge_detect_o   (edge_detect_w)
    );

    //----------------------------------------------------------------------
    // I2C slave logic
    //----------------------------------------------------------------------
    i2c_slave_interface u_slave (
        .clk_i       (clk_i),
        .rst_n_i     (rst_n_i),

        .slave_address_i(slave_addr_w),

        .sda_i       (sda_filt_w),
        .scl_i       (scl_filt_w),
        .sda_out_o   (sda_out_w),

        .start_detected_i(start_detected_w),
        .stop_detected_i (stop_detected_w),
        .edge_detect_i   (edge_detect_w),

        .addr_match_o (addr_match_w),
        .rw_bit_o     (rw_bit_w),

        .i2c_tx_data_i    (tx_data_w),
        .wr_req_o     (wr_req_w),
        .wr_allow_i   (wr_allow_w),

        .i2c_rx_data_o    (rx_data_w),
        .rd_allow_i   (rd_allow_w),
        .rd_req_o     (rd_req_w)
    );

    //----------------------------------------------------------------------
    // Frame bridge to external interface
    //----------------------------------------------------------------------
    i2c_frame_bridge u_bridge (
        //-----------------------------------------------------------------
        // Clock & Reset
        //-----------------------------------------------------------------
        .clk_i            (clk_i),
        .rst_n_i          (rst_n_i),

        //-----------------------------------------------------------------
        // I2C interface
        //-----------------------------------------------------------------
        .i2c_rx_data_i    (rx_data_w),
        .wr_req_i         (wr_req_w),
        .rd_req_i         (rd_req_w),
        .wr_allow_o       (wr_allow_w),
        .rd_allow_o       (rd_allow_w),
        .i2c_tx_data_o    (tx_data_w),
        .rw_bit_i         (rw_bit_w),
        .addr_match_i     (addr_match_w),

        //-----------------------------------------------------------------
        // Register interface
        //-----------------------------------------------------------------
        .addr_o           (addr_o),
        .wr_en_o          (wr_en_o),
        .rd_en_o          (rd_en_o),
        .wdata_o          (wdata_o),
        .rdata_i          (rdata_i),

        //-----------------------------------------------------------------
        // Control signals
        //-----------------------------------------------------------------
        .start_detected_i (start_detected_w),
        .stop_detected_i  (stop_detected_w),
        .edge_detect_i    (edge_detect_w)
    );


endmodule
