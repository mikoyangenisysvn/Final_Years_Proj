`timescale 1ns/1ps

module tb_counter();

  // Tham số
  localparam WIDTH = 8; // dùng 8-bit cho dễ quan sát
  reg clk;
  reg cnt_rst;
  reg PWM_EN;
  reg mode;  
  reg [WIDTH-1:0] period;
  wire [WIDTH-1:0] cnt_val;

  // Khởi tạo DUT
  counter #(.WIDTH(WIDTH)) uut (
    .clk(clk),
    .cnt_rst(cnt_rst),
    .PWM_EN(PWM_EN),
    .mode(mode),
    .period(period),
    .cnt_val(cnt_val)
  );

  // Clock 10ns (100 MHz)
  always #5 clk = ~clk;

  initial begin
    // Dump file VCD cho waveform (dùng GTKWave / EDA Playground)
    $dumpfile("counter_tb.vcd");
    $dumpvars(0, tb_counter);

    // Monitor giá trị
    $monitor("T=%0t | rst=%b en=%b mode=%b cnt_val=%0d", 
              $time, cnt_rst, PWM_EN, mode, cnt_val);

    // Khởi tạo tín hiệu
    clk = 0;
    cnt_rst = 1;
    PWM_EN = 0;
    mode = 0;
    period = 8'd10;

    // Reset
    #20 cnt_rst = 0;

    // Test case 1: UP MODE
    $display("==== Test UP mode ====");
    PWM_EN = 1;
    mode = 0;
    #200;

    // Test case 2: tắt PWM_EN
    $display("==== Disable counter ====");
    PWM_EN = 0;
    #40;

    // Test case 3: UP-DOWN MODE
    $display("==== Test UP-DOWN mode ====");
    PWM_EN = 1;
    mode = 1;
    #400;

    $stop;
  end

endmodule
