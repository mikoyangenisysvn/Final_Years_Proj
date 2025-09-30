module pwm_register #(
    parameter WIDTH = 16
)(
    input  wire              clk,
    input  wire              rst_n,        // reset active low

    // giao diện ghi/đọc (giả lập memory-mapped)
    input  wire              wr_en,        // write enable
    input  wire              rd_en,        // read enable
    input  wire [3:0]        addr,         // địa chỉ thanh ghi
    input  wire [WIDTH-1:0]  wr_data,      // dữ liệu ghi
    output reg  [WIDTH-1:0]  rd_data,      // dữ liệu đọc

    // output sang khối PWM
    output reg               en,
    output reg               mode,
    output reg  [WIDTH-1:0]  period,
    output reg  [WIDTH-1:0]  duty,
    output reg  [WIDTH-1:0]  prescaler_div
);

    // ghi register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en            <= 1'b0;
            mode          <= 1'b0;
            period        <= {WIDTH{1'b0}};
            duty          <= {WIDTH{1'b0}};
            prescaler_div <= {WIDTH{1'b0}};
        end 
        else if (wr_en) begin
            case (addr)
                4'h0: begin
                    en   <= wr_data[0];
                    mode <= wr_data[1];
                end
                4'h4: period        <= wr_data;
                4'h8: duty          <= wr_data;
                4'hC: prescaler_div <= wr_data;
            endcase
        end
    end

    // đọc register
    always @(*) begin
        if (rd_en) begin
            case (addr)
                4'h0: rd_data = { {WIDTH-2{1'b0}}, mode, en };
                4'h4: rd_data = period;
                4'h8: rd_data = duty;
                4'hC: rd_data = prescaler_div;
                default: rd_data = {WIDTH{1'b0}};
            endcase
        end 
        else begin
            rd_data = {WIDTH{1'b0}};
        end
    end

endmodule
