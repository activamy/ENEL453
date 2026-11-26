`timescale 1ns / 1ps
//==============================================================================
// Module: position_controller_subsystem
//
// Purpose
//   Deals with the controller modules --> anything that helps measure the position of the disk
//   and calculate the gains to affect the controller
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


module position_controller_subsystem
    import disk_pkg::*;                             // shared constants and widths
#(
    parameter int CLK_FREQ    = CLK_FREQ_HZ,        // 100 MHz
    parameter int CTRL_FREQ   = CONTROL_FREQ_HZ     // 100 Hz
 )(
    input  logic                             clk,
    input  logic                             reset,                                      
    input  logic                             encoder_a,
    input  logic                             encoder_b,
    input  logic        [KP_WIDTH-1:0]       kp,
    input  logic                             step_up,
    input  logic                             step_down,
    
    output logic signed [POSITION_WIDTH-1:0] position,
    output logic signed [POSITION_WIDTH-1:0] setpoint,
    output logic signed [COMMAND_WIDTH-1:0]  command
    );
    
    // Clock cycles between controller samples: 100,000,000 / 100 = 1,000,000.
    localparam int CTRL_PERIOD     = CLK_FREQ / CTRL_FREQ;
    
    logic                             control_tick;
    
    //--------------------------------------------------------------------------
    // Clock-enable pulse
    //--------------------------------------------------------------------------
    
    // 100 Hz pulse: tells the controller when to take a sample.
    downcounter #(
        .PERIOD(CTRL_PERIOD)          // 1,000,000 cycles = 10 ms
    ) CONTROL_TICK_GEN (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .enable(1'b1),                // always counting
        .zero(control_tick)           // one-cycle pulse every 10 ms
    );
    
    
    //--------------------------------------------------------------------------
    // The control loop: measure, compare
    //--------------------------------------------------------------------------

    // Measure: encoder channels -> position in counts.
    quad_decoder QUAD_DECODER (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset: position = 0
        .a(encoder_a),                // synchronized channel A
        .b(encoder_b),                // synchronized channel B
        .position(position)           // signed position, counts
    );

    // Setpoint: +/-90 degrees per button press.
    setpoint_control SETPOINT_CONTROL (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset: setpoint = 0
        .step_up(step_up),            // debounced btnR
        .step_down(step_down),        // debounced btnL
        .setpoint(setpoint)           // desired position, counts
    );

    // Compare: command = Kp x (setpoint - position), limited to +/-255.
    // p_controller knows nothing about the disk (it is written to be reused
    // unchanged, for example inside a PI controller), so the disk's sizes and
    // limits are given to it here, as parameters.
    p_controller #(
        .IN_WIDTH(POSITION_WIDTH),    // setpoint and position: 16 bits
        .KP_WIDTH(KP_WIDTH),          // kp: 4 bits, 0 to 15
        .FRAC_BITS(0),                // Kp is a whole number
        .OUT_WIDTH(COMMAND_WIDTH),    // command: 9 bits
        .OUT_MAX(COMMAND_MAX),        // +255: full power forward
        .OUT_MIN(-COMMAND_MAX)        // -255: full power reverse
    ) P_CONTROLLER (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset: command = 0
        .sample_tick(control_tick),   // update 100 times per second
        .reference(setpoint),         // desired position, counts
        .measured(position),          // measured position, counts
        .kp(kp),                      // gain from sw[3:0]
        .error(),                     // setpoint - position: not needed here
        .p_action(command)            // -255 (full reverse) to +255 (full forward)
    );
endmodule
