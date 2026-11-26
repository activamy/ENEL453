`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: motor_interface_subsystem
//
// Purpose
//   uhhhhhh motor stuff
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


module motor_interface_subsystem 
    import disk_pkg::*;
    #(
    parameter int CLK_FREQ    = CLK_FREQ_HZ,        // 100 MHz
    parameter int PWM_FREQ    = PWM_FREQ_HZ        // 10 kHz
    )(
    input  logic                             clk,
    input  logic                             reset,
    
    input  logic                             arm,
    input  logic signed [COMMAND_WIDTH-1:0]  command,
    
    output logic                 motor_en,
    output logic                 motor_in1,
    output logic                 motor_in2
    );
    
    // Clock cycles between PWM counter steps. One PWM period is COMMAND_MAX =
    // 255 steps, so 100,000,000 / (10,000 x 255) = 39.2 -> 39, giving 10.06 kHz.
    localparam int PWM_TICK_PERIOD = CLK_FREQ / (PWM_FREQ * COMMAND_MAX);
    
    logic                             pwm_tick;
    
    //--------------------------------------------------------------------------
    // Clock-enable pulses
    //--------------------------------------------------------------------------

    // 2.56 MHz pulse: steps the PWM counter (255 steps = one 10 kHz period).
    downcounter #(
        .PERIOD(PWM_TICK_PERIOD)      // 39 cycles = 390 ns
    ) PWM_TICK_GEN (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .enable(1'b1),                // always counting
        .zero(pwm_tick)               // one-cycle pulse every 39 cycles
    );

    //--------------------------------------------------------------------------
    // The control loop: drive
    //--------------------------------------------------------------------------

    // Drive: command -> L298N direction and PWM signals.
    motor_drive MOTOR_DRIVE (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset: motor off
        .arm(arm),                    // sw[15]: 0 forces the motor off
        .pwm_tick(pwm_tick),          // sets the PWM frequency
        .command(command),            // signed motor command
        .motor_en(motor_en),          // to L298N ENB (PWM)
        .motor_in1(motor_in1),        // to L298N IN3 (forward)
        .motor_in2(motor_in2)         // to L298N IN4 (reverse)
    );
endmodule
