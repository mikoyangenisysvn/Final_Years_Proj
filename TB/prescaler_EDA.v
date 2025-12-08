`timescale 1ns/1ps

module tb_pwm_prescaler;

    localparam WIDTH = 16;

    // DUT signals
    reg                     clk_psc_i;
    reg                     rst_n_i;
    reg                     cen_i;
    reg  [WIDTH-1:0]        psc_preload_i;

    wire                    ck_cnt_o;

    // Instantiate DUT
    pwm_prescaler #(
        .PSC_WIDTH(WIDTH)
    ) dut (
        .clk_psc_i     (clk_psc_i),
        .rst_n_i       (rst_n_i),
        .cen_i         (cen_i),
        .psc_preload_i (psc_preload_i),
        .ck_cnt_o      (ck_cnt_o)
    );

   // EPWave dumpfile
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_pwm_prescaler);
    end
    //----------------------------------------
    // Clock: 10ns period
    //----------------------------------------
    always #5 clk_psc_i = ~clk_psc_i;

    //----------------------------------------
    // TEST
    //----------------------------------------
    initial begin
        $display("=== PWM PRESCALER TESTBENCH START ===");

        clk_psc_i = 0;
        rst_n_i   = 0;
        cen_i     = 0;
        psc_preload_i = 4;

        // TESTCASE 1: RESET
        #10;
        rst_n_i = 1;
        #10;

        // TESTCASE 2: CEN=0 (counter disabled)
        cen_i = 0;
        #30;

        // Enable counting
        cen_i = 1;
        #60;

        // TESTCASE 3: preload = 0 (bypass mode)
        psc_preload_i = 0;
        #40;

        // Restore preload
        psc_preload_i = 4;
        #50;

        // TESTCASE 4: normal counting with preload=4
        #100;

        // TESTCASE 5: dynamic change preload
        psc_preload_i = 10;
        #200;

        $display("=== PWM PRESCALER TESTBENCH FINISHED ===");
        $finish;
    end

endmodule
