`timescale 1ns / 1ps
//==============================================================================
// Module: input_conditioning_subsystem
//
// Purpose
//   To put all the synchronizer and debounce files into a subsystem to clean the top file up
//
// Block diagram
//
//   reset_button     --> [synchronizer] --> reset
//   ch_a             --> [synchronizer] --> encoder_a
//   ch_b             --> [synchronizer] --> encoder_b
//   kp_switches      --> [synchronizer] --> kp
//   arm_switch       --> [synchronizer] --> arm
//   display_sw       --> [synchronizer] --> display
//
//   step_up_button   --> [debounce] ----+--> step_up
//                            ^
//                            |
//   step_down_button --> [debounce] ----+--> step_down
//                            ^
//                            |
//                          reset
//
// Inputs
//   clk                    : System clock
//   reset_button           : raw reset button (btnC), 1 while pressed
//   step_up_button         : raw step up button (btnR), 1 while pressed
//   step_down_button       : raw step down button (btnL), 1 while pressed
//   kp_switches            : raw proportional gain switched (sw[3:0])
//   arm_switch             : raw arm switch (sw15), 1 to let motor run
//   ch_a, ch_b             : raw encoder a and b channels (Pmod JB1, JB2)
//   display_sw             : raw display mode switch (sw10)
//
// Parameters
//   CLK_FREQ               :
//   DEBOUNCE_MS            :
//
// Outputs
//   reset                  :
//   encoder_a, encoder_b   :
//   kp                     :
//   arm                    :
//   step_up                :
//   step_down              :
//   display                :
//
//////////////////////////////////////////////////////////////////////////////////


module input_conditioning_subsystem
    import disk_pkg::*;                             // shared constants and widths
    #(
    parameter int CLK_FREQ    = CLK_FREQ_HZ,        // 100 MHz
    parameter int DEBOUNCE_MS = DEBOUNCE_TIME_MS    // 50 ms
)(
    input  logic                 clk,
    input  logic                 reset_button,
    input  logic                 step_up_button,
    input  logic                 step_down_button,
    input  logic [KP_WIDTH-1:0]  kp_switches,
    input  logic                 arm_switch,    
    input  logic                 ch_a,
    input  logic                 ch_b,
    
    input  logic                 display_sw,
    
    
    output logic                             reset,
    output logic                             encoder_a,
    output logic                             encoder_b,
    output logic        [KP_WIDTH-1:0]       kp,
    output logic                             arm,
    output logic                             step_up,
    output logic                             step_down,

    output logic                             display
    );
    
    
    // Reset button. The synchronizer has no reset of its own, so it can
    // synchronize the reset button itself.
    synchronizer #(
        .WIDTH(1)
    ) RESET_SYNC (
        .clk(clk),                    // system clock
        .d(reset_button),             // btnC, asynchronous
        .q(reset)                     // synchronized reset for the whole design
    );

    // Encoder channel A.
    synchronizer #(
        .WIDTH(1)
    ) ENCODER_A_SYNC (
        .clk(clk),                    // system clock
        .d(ch_a),                     // encoder channel A, from Pmod JB1
        .q(encoder_a)                 // synchronized channel A
    );

    // Encoder channel B.
    synchronizer #(
        .WIDTH(1)
    ) ENCODER_B_SYNC (
        .clk(clk),                    // system clock
        .d(ch_b),                     // encoder channel B, from Pmod JB2
        .q(encoder_b)                 // synchronized channel B
    );

    // Gain switches, all four bits in one synchronizer.
    synchronizer #(
        .WIDTH(KP_WIDTH)               // 4 switches
    ) KP_SYNC (
        .clk(clk),                    // system clock
        .d(kp_switches),              // sw[3:0]
        .q(kp)                        // synchronized gain, 0 to 15
    );

    // Arm switch.
    synchronizer #(
        .WIDTH(1)
    ) ARM_SYNC (
        .clk(clk),                    // system clock
        .d(arm_switch),               // sw[15]
        .q(arm)                       // synchronized: 1 = motor allowed to run
    );
    
    // Count Display Switch
    synchronizer # (
        .WIDTH(1)
    ) DISPLAY_SYNC (
        .clk(clk),                   // clock
        .d(display_sw),              // sw[10]
        .q(display)                  // synchronized display switch
    );
 

    // Step-up button (btnR).
    debounce #(
        .CLK_FREQ(CLK_FREQ),          // system clock frequency, Hz
        .STABLE_TIME_MS(DEBOUNCE_MS)  // button must be steady this long
    ) STEP_UP_DEBOUNCE (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .button(step_up_button),      // raw btnR
        .result(step_up)              // debounced: 1 while held
    );

    // Step-down button (btnL).
    debounce #(
        .CLK_FREQ(CLK_FREQ),          // system clock frequency, Hz
        .STABLE_TIME_MS(DEBOUNCE_MS)  // button must be steady this long
    ) STEP_DOWN_DEBOUNCE (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .button(step_down_button),    // raw btnL
        .result(step_down)            // debounced: 1 while held
    );

endmodule
