module counter #(
  parameter WIDTH = 64
)(
  input  wire              clk,        // slow_clk
  input  wire              rst_n,    // reset active high
  input  wire              PWM_EN,     // enable
  input  wire              mode,       // 0: up, 1: up-down
  input  wire [WIDTH-1:0]  AAR,     // giá trị chu kỳ
  output reg  [WIDTH-1:0]  cnt_val     // giá trị counter
);

  reg dir; // 0 = up, 1 = down (chỉ dùng khi mode=1)

  always @(posedge clk or posedge cnt_rst) begin
    if (cnt_rst) begin
      cnt_val <= {WIDTH{1'b0}};
      dir     <= 1'b0;
    end 
    else if (!PWM_EN) begin
      cnt_val <= {WIDTH{1'b0}};
      dir     <= 1'b0;
    end 
    else begin
      if (mode == 1'b0) begin
        // --------- UP MODE ---------
        if (cnt_val >= period)
          cnt_val <= {WIDTH{1'b0}};
        else
          cnt_val <= cnt_val + 1;
      end 
      else begin
        // --------- UP-DOWN MODE ---------
        if (dir == 1'b0) begin
          // đang đếm lên
          if (cnt_val >= period) begin
            dir     <= 1'b1;        // đổi chiều
            cnt_val <= cnt_val - 1; // quay xuống
          end
          else
            cnt_val <= cnt_val + 1;
        end
        else begin
          // đang đếm xuống
          if (cnt_val == 0) begin
            dir     <= 1'b0;        // đổi chiều
            cnt_val <= cnt_val + 1; // quay lên
          end
          else
            cnt_val <= cnt_val - 1;
        end
      end
    end
  end

endmodule
