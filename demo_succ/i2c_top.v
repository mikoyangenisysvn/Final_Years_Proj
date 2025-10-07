module i2c_top #(
    parameter SLAVE_ADDR = 7'h50 // Địa chỉ 7-bit của slave
)(
    input  wire clk,
    input  wire rst_n,

    inout  wire SDA_bus,
    input  wire SCL_bus,

    output wire [15:0] addr,
    output wire [31:0] wdata,
    input  wire [31:0] rdata,
    output wire wr_en, rd_en
);

    wire [6:0] addr_out;
    wire [7:0] rx_data;
    wire rx_valid;
    wire addr_match;
    wire sr_start,inframe;
    wire rw_bit;
    wire edge_detect;
    wire tx_valid;
    wire [7:0] tx_data;
    

    // --- I2C Slave Instance ---
    i2c_slave_interface #(
        .SLAVE_ADDR(SLAVE_ADDR)
    ) i2c_slave_interface_inst(
        .clk(clk),
        .rst_n(rst_n),
        .SDA_bus(SDA_bus),
        .SCL_bus(SCL_bus),
        .addr_out(addr_out),

        .addr_match(addr_match),
        .sr_start(sr_start),
        .inframe(inframe),
        .rw_bit(rw_bit),
        .edge_detect(edge_detect),

        .get_tx(tx_valid),
        .i2c_tx_data(tx_data),
        .send_rx(rx_valid),
        .i2c_rx_data(rx_data)
    );

    i2c_frame_bridge i2c_frame_bridge_inst(
        .clk(clk),
        .rst_n(rst_n),
        .rx_data(rx_data),
        .rx_valid(rx_valid),

        .tx_valid(tx_valid),
        .tx_data(tx_data),

        .sr_start(sr_start),
        .inframe(inframe),
        .rw_bit(rw_bit),
        .addr_match(addr_match),
        .edge_detect(edge_detect),

        .rdata(rdata),
        .addr(addr),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wdata(wdata)
    );


endmodule
