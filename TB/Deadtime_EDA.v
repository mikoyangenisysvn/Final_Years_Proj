`timescale 1ns/1ps

module tb_pwm_oc;

    // Clock & reset
    reg clk;
    reg rst_n;

    // Comparator flags
    reg cmp_start_eq;
    reg cmp_start_gt;
    reg cmp_end_eq;
    reg cmp_end_gt;

    // Controls
    reg oc_mode;
    reg dtg_src_sel;
    reg update_event;
    reg [7:0] dtg_preload;

    reg [1:0] oc_main_sel;
    reg [1:0] oc_comp_sel;
    reg oc_main_pol;
    reg oc_comp_pol;

    // Outputs
    wire oc_main;
    wire oc_comp;

    // DUT
    pwm_oc #(.DEADTIME_WIDTH(8)) dut (
        .clk_psc_i(clk),
        .rst_n_i(rst_n),
        .cmp_start_eq_i(cmp_start_eq),
        .cmp_start_gt_i(cmp_start_gt),
        .cmp_end_eq_i(cmp_end_eq),
        .cmp_end_gt_i(cmp_end_gt),
        .oc_mode_i(oc_mode),
        .dtg_src_sel_i(dtg_src_sel),
        .update_event_i(update_event),
        .dtg_preload_i(dtg_preload),
        .oc_main_sel_i(oc_main_sel),
        .oc_comp_sel_i(oc_comp_sel),
        .oc_main_pol_i(oc_main_pol),
        .oc_comp_pol_i(oc_comp_pol),
        .oc_main_o(oc_main),
        .oc_comp_o(oc_comp)
    );

    // Clock
    always #5 clk = ~clk;

    // Task: set CNT flags
    task set_cnt(input integer CNT);
        begin
            cmp_start_eq = (CNT == 3);
            cmp_start_gt = (CNT > 3);
            cmp_end_eq   = (CNT == 7);
            cmp_end_gt   = (CNT > 7);
        end
    endtask

    // Simulation
    integer i;

    initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_pwm_oc);

    clk = 0;
    rst_n = 0;
    cmp_start_eq = 0;
    cmp_start_gt = 0;
    cmp_end_eq   = 0;
    cmp_end_gt   = 0;

    oc_mode = 0;
    dtg_src_sel = 0;
    update_event = 0;
    dtg_preload = 5;

    oc_main_sel = 2'b01; // chọn oc_ref A
    oc_comp_sel = 2'b01; // chọn oc_ref B
    oc_main_pol = 0;
    oc_comp_pol = 0;

    $display("=== PWM_OC TESTBENCH START ===");

    // RESET
    $display("TC1: RESET");
    #20 rst_n = 1;

    // Kích update event để load deadtime preload
    $display("TC2: Load deadtime preload = %0d", dtg_preload);
    #20 update_event = 1;
    #10 update_event = 0;

    // Sweep CNT 0 → 12
      $display("TC3: Sweep CNT 0 -> 12");
    for (i = 0; i < 12; i = i + 1) begin
        set_cnt(i);
        $display("  CNT=%0d | start_eq=%b start_gt=%b end_eq=%b end_gt=%b | oc_main=%b oc_comp=%b",
                  i, cmp_start_eq, cmp_start_gt, cmp_end_eq, cmp_end_gt, oc_main, oc_comp);
        #20;
    end

    // Mode đảo
    $display("TC4: oc_mode=1");
    oc_mode = 1;
    #50;
    $display("   oc_main=%b oc_comp=%b", oc_main, oc_comp);

    $display("=== PWM_OC TESTBENCH FINISHED ===");
 

        $finish;
    end

endmodule
