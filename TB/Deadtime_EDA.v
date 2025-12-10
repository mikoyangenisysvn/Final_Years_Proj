`timescale 1ns/1ps

module tb_pwm_oc_deadtime;

    localparam WIDTH = 8;

    // DUT signals
    reg                  clk_psc_i;
    reg                  rst_n_i;
    reg                  update_event_i;
    reg                  pwm_in_i;
    reg  [WIDTH-1:0]     dtg_preload_i;

    wire                 pwm_high_o;
    wire                 pwm_low_o;

    // Instantiate DUT
    pwm_oc_deadtime #(
        .WIDTH(WIDTH)
    ) dut (
        .clk_psc_i     (clk_psc_i),
        .rst_n_i       (rst_n_i),
        .update_event_i(update_event_i),
        .pwm_in_i      (pwm_in_i),
        .dtg_preload_i (dtg_preload_i),
        .pwm_high_o    (pwm_high_o),
        .pwm_low_o     (pwm_low_o)
    );

    //------------------------------------------------------------
    // Clock generation: 20ns period
    //------------------------------------------------------------
    always #10 clk_psc_i = ~clk_psc_i;

    //------------------------------------------------------------
    // EPWave dumpfile
    //------------------------------------------------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_pwm_oc_deadtime);
    end

    //------------------------------------------------------------
    // Stimulus
    //------------------------------------------------------------
    initial begin
        $display("=== PWM DEADTIME TEST START ===");

        // Default init
        clk_psc_i      = 0;
        rst_n_i        = 0;
        update_event_i = 0;
        pwm_in_i       = 0;
        dtg_preload_i  = 0;

        //--------------------------------------------------------
        // TC1: RESET
        //--------------------------------------------------------
        #25;
        rst_n_i = 1;
        $display("TC1: RESET released");

        //--------------------------------------------------------
        // TC2: Load deadtime preload = 3
        //--------------------------------------------------------
        dtg_preload_i  = 8'd3;
        update_event_i = 1;
        #20;
        update_event_i = 0;
        $display("TC2: Deadtime preload set to 3");

        //--------------------------------------------------------
        // TC3: Rising edge on pwm_in_i
        //--------------------------------------------------------
        #40;
        pwm_in_i = 1;
        $display("TC3: Rising edge on pwm_in_i, expect delayed pwm_high_o after 3 cycles");

        #100;

        //--------------------------------------------------------
        // TC4: Falling edge on pwm_in_i
        //--------------------------------------------------------
        pwm_in_i = 0;
        $display("TC4: Falling edge on pwm_in_i, expect delayed pwm_low_o after 3 cycles");

        #100;

        //--------------------------------------------------------
        // TC5: Change deadtime preload dynamically
        //--------------------------------------------------------
        dtg_preload_i  = 8'd5;
        update_event_i = 1;
        #20;
        update_event_i = 0;
        $display("TC5: Deadtime preload updated to 5");

        // Apply another rising edge
        pwm_in_i = 1;
        $display("TC5: Rising edge with new deadtime preload = 5");

        #200;

        //--------------------------------------------------------
        // TC6: Bypass mode (deadtime = 0)
        //--------------------------------------------------------
        dtg_preload_i  = 0;
        update_event_i = 1;
        #20;
        update_event_i = 0;
        $display("TC6: Deadtime preload = 0 (bypass mode)");

        pwm_in_i = 0;
        #40;
        pwm_in_i = 1;
        $display("TC6: pwm_in_i toggles, outputs should follow immediately");

        #100;

        $display("=== PWM DEADTIME TEST END ===");
        $finish;
    end

endmodule
