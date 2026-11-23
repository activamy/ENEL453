`timescale 1ns / 1ps
//==============================================================================
// Module: input_conditioning_subsystem
//
// Purpose
//   To put all the synchronizer and debounce files into a subsystem to clean the top file up
//
// Block diagram
//
//   someone plz make it :(
//
// Inputs
//   no
// Outputs
//   no
// 
//////////////////////////////////////////////////////////////////////////////////


module input_conditioning
    import disk_pkg::*;                             // shared constants and widths
    #(
    parameter int CLK_FREQ    = CLK_FREQ_HZ,        // 100 MHz
    parameter int CTRL_FREQ   = CONTROL_FREQ_HZ,    // 100 Hz
    parameter int PWM_FREQ    = PWM_FREQ_HZ,        // 10 kHz
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
    
    input  logic                 display_sw
    );
    
    logic                             reset;
    logic                             encoder_a;
    logic                             encoder_b;
    logic        [KP_WIDTH-1:0]       kp;
    logic                             arm;

    logic                             display;
    

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
    
    
    // added
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
