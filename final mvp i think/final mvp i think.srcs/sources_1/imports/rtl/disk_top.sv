`timescale 1ns / 1ps
//==============================================================================
// Module: disk_top  (top level)
//
// Purpose
//   Position control of a rotating disk with the Basys3. A DC motor turns the
//   disk; a quadrature encoder on the shaft measures its angle. The FPGA runs
//   a proportional (P) controller that drives the motor, through an L298N
//   H-bridge, until the disk sits at the commanded angle (the setpoint).
//
//   This file only connects modules together (it is "structural"): all the
//   logic lives in the modules it instantiates.
//
// What the user sees and does
//   btnC (reset_button)      : reset. Position and setpoint both become 0,
//                              so the disk holds wherever it is now.
//   btnR (step_up_button)    : move the setpoint +90 degrees
//   btnL (step_down_button)  : move the setpoint -90 degrees
//   sw[3:0] (kp_switches)    : proportional gain Kp, 0 to 15 (try 2 first)
//   sw[15] (arm_switch)      : up = motor allowed to run, down = motor off
//   7-segment display        : disk angle within one revolution, " 000"-" 359"
//   led[3:0]                 : Kp
//   led[8], led[9]           : encoder channels A and B (flicker when turning)
//   led[14], led[13]         : motor direction, forward / reverse
//   led[15]                  : motor armed
//
// Block diagram
//
//                 +--------------+  encoder_a,b  +--------------+  position
//   ch_a, ch_b -->| synchronizer |-------------->| quad_decoder |-----------+
//                 +--------------+               +--------------+           |
//                                                                           v
//                 +----------+  step_up,  +------------------+  setpoint  +--------------+
//   btnR, btnL -->| debounce |----------->| setpoint_control |----------->|              |
//                 |   (x2)   | step_down  +------------------+            | p_controller |
//                 +----------+                                            |              |
//                 +--------------+  kp                                    |  command =   |
//   sw[3:0] ----->| synchronizer |--------------------------------------->| Kp x error   |
//                 +--------------+                                        +--------------+
//                 +-------------+ control_tick (100 Hz) ------------------------^    |
//                 | downcounter |                                                    | command
//                 +-------------+                                                    v
//                 +--------------+  arm                                   +-------------+
//   sw[15] ------>| synchronizer |--------------------------------------->|             |--> motor_en
//                 +--------------+                                        | motor_drive |--> motor_in1
//                 +-------------+ pwm_tick (2.56 MHz -> 10 kHz PWM) ----->|             |--> motor_in2
//                 | downcounter |                                         +-------------+
//                 +-------------+
//
//   position --> position_to_degrees --> bin_to_bcd --> seven_segment_display_subsystem
//                    (0-359 degrees)     (BCD digits)    --> CA..CG, DP, AN1..AN4
//
//   btnC --> synchronizer --> reset (to every module that has a reset)
//
// Clocking and reset
//   Every flip-flop runs on the one 100 MHz clock, clk. Slower actions (the
//   100 Hz controller, the 10 kHz PWM) use one-cycle clock-enable pulses from
//   downcounter modules, never a second clock.
//   reset is synchronous and active high everywhere. It comes from btnC
//   through a synchronizer, so it changes in step with the clock.
//
// Signal flow, step by step
//   1. The encoder channels are synchronized, then decoded into "position"
//      (2048 counts per revolution; 1 count is about 0.18 degrees).
//   2. The step buttons are debounced; each press moves "setpoint" by
//      +/-512 counts (90 degrees).
//   3. 100 times per second, p_controller computes
//          command = Kp x (setpoint - position), limited to +/-255.
//   4. motor_drive turns the command into a direction (motor_in1/in2) and a
//      10 kHz PWM duty cycle (motor_en) for the L298N.
//   5. The display shows the angle: position -> degrees -> BCD digits.
//
// Parameters (defaults come from disk_pkg; the closed-loop testbench
// overrides them with a slower clock so that simulation runs quickly)
//   CLK_FREQ    : system clock frequency, Hz        (CLK_FREQ_HZ      = 100 MHz)
//   CTRL_FREQ   : controller sample rate, Hz        (CONTROL_FREQ_HZ  = 100 Hz)
//   PWM_FREQ    : motor PWM frequency, Hz, approx.  (PWM_FREQ_HZ      = 10 kHz)
//   DEBOUNCE_MS : push-button debounce time, ms     (DEBOUNCE_TIME_MS = 50 ms)
//
// Constants (from disk_pkg)
//   POSITION_WIDTH = 16, KP_WIDTH = 4, COMMAND_WIDTH = 9, DEGREES_WIDTH = 9,
//   COMMAND_MAX = 255 (also the number of PWM steps in one period)
//
// Inputs
//   clk              : 100 MHz clock from the Basys3 oscillator (pin W5)
//   reset_button     : btnC, 1 while pressed
//   step_up_button   : btnR, 1 while pressed
//   step_down_button : btnL, 1 while pressed
//   kp_switches      : sw[3:0], the gain Kp
//   arm_switch       : sw[15], 1 = motor allowed to run
//   ch_a, ch_b       : encoder channels A and B (Pmod JB1, JB2)
//
// Outputs
//   motor_en         : PWM to the L298N ENB input (Pmod JC3)
//   motor_in1        : direction to the L298N IN3 input (Pmod JC1)
//   motor_in2        : direction to the L298N IN4 input (Pmod JC2)
//   led              : the 16 LEDs above the switches
//   CA..CG, DP       : 7-segment segment outputs (active low)
//   AN1..AN4         : 7-segment anode outputs (active low, AN1 = rightmost)
//
// Internal signals
//   reset        : synchronized reset, active high
//   encoder_a,b  : synchronized encoder channels
//   kp           : synchronized gain switches, 0 to 15
//   arm          : synchronized arm switch
//   step_up      : debounced btnR level
//   step_down    : debounced btnL level
//   control_tick : 100 Hz clock-enable pulse for the controller
//   pwm_tick     : clock-enable pulse that steps the PWM counter
//   position     : measured disk position, counts (signed)
//   setpoint     : desired disk position, counts (signed)
//   command      : motor command, -255 to +255
//   degrees      : disk angle within one revolution, 0 to 359
//   degrees_bcd  : the angle as four BCD digits, for the display
//==============================================================================

module disk_top
    import disk_pkg::*;                             // shared constants and widths
#(
    parameter int CLK_FREQ    = CLK_FREQ_HZ,        // 100 MHz
    parameter int CTRL_FREQ   = CONTROL_FREQ_HZ,    // 100 Hz
    parameter int PWM_FREQ    = PWM_FREQ_HZ,        // 10 kHz
    parameter int DEBOUNCE_MS = DEBOUNCE_TIME_MS    // 50 ms
) (
    input  logic                 clk,
    input  logic                 reset_button,
    input  logic                 step_up_button,
    input  logic                 step_down_button,
    input  logic [KP_WIDTH-1:0]  kp_switches,
    input  logic                 arm_switch,    
    input  logic                 ch_a,
    input  logic                 ch_b,
    output logic                 motor_en,
    output logic                 motor_in1,
    output logic                 motor_in2,
    output logic [15:0]          led,
    output logic                 CA, CB, CC, CD, CE, CF, CG,
    output logic                 DP,
    output logic                 AN1, AN2, AN3, AN4,
    
    
    
    //added
    input  logic                 display_sw
    );

//    // Clock cycles between controller samples: 100,000,000 / 100 = 1,000,000.
//    localparam int CTRL_PERIOD     = CLK_FREQ / CTRL_FREQ;
//    // Clock cycles between PWM counter steps. One PWM period is COMMAND_MAX =
//    // 255 steps, so 100,000,000 / (10,000 x 255) = 39.2 -> 39, giving 10.06 kHz.
//    localparam int PWM_TICK_PERIOD = CLK_FREQ / (PWM_FREQ * COMMAND_MAX);

    logic                             reset;
    logic                             encoder_a;
    logic                             encoder_b;
    logic        [KP_WIDTH-1:0]       kp;
    logic                             arm;    
    logic                             step_up;
    logic                             step_down;
//    logic                             control_tick;
//    logic                             pwm_tick;
    logic signed [POSITION_WIDTH-1:0] position;
    logic signed [POSITION_WIDTH-1:0] setpoint;
    logic signed [COMMAND_WIDTH-1:0]  command;
//    logic        [DEGREES_WIDTH-1:0]  degrees;
    logic        [15:0]               degrees_bcd;
    
    // Added
    logic                             display;
//    logic        [15:0]               bcd_val;
    logic        [3:0]                blank_digit;


    //--------------------------------------------------------------------------
    // Inputs: synchronize the switches, encoder and reset button; debounce the
    // step buttons.
    //--------------------------------------------------------------------------
    input_conditioning_subsystem #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    )INPUT_CONDITIONING (
        .clk(clk),
        .reset_button(reset_button),
        .step_up_button(step_up_button),
        .step_down_button(step_down_button),
        .kp_switches(kp_switches),
        .arm_switch(arm_switch),    
        .ch_a(ch_a),
        .ch_b(ch_b),
        .display_sw(display_sw),
        
        .reset(reset),
        .encoder_a(encoder_a),
        .encoder_b(encoder_b),
        .kp(kp),
        .arm(arm),
        .step_up(step_up),
        .step_down(step_down),
        .display(display)
    );
    
    
    //--------------------------------------------------------------------------
    // Position Controller subsystem 
    //--------------------------------------------------------------------------
    position_controller_subsystem #(
        .CLK_FREQ(CLK_FREQ),
        .CTRL_FREQ(CTRL_FREQ)
    )POSITION_CONTROLLER (
        .clk(clk),
        .reset(reset),
        .encoder_a(encoder_a),
        .encoder_b(encoder_b),
        .kp(kp),
        .step_up(step_up),
        .step_down(step_down),
        .position(position),
        .setpoint(setpoint),
        .command(command)      
    );
    
 
    //--------------------------------------------------------------------------
    // Motor Interface Subsystem
    //--------------------------------------------------------------------------
    motor_interface_subsystem #(
        .CLK_FREQ(CLK_FREQ),
        .PWM_FREQ(PWM_FREQ)
    )MOTOR_INTERFACE (
        .clk(clk),
        .reset(reset),
        .arm(arm),
        .command(command),
        .motor_en(motor_en),
        .motor_in1(motor_in1),
        .motor_in2(motor_in2)
    );
    

    seven_segment_display_subsystem SEVEN_SEGMENT_DISPLAY (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .digit1(degrees_bcd[3:0]),    // ones of degrees (rightmost digit)
        .digit2(degrees_bcd[7:4]),    // tens of degrees
        .digit3(degrees_bcd[11:8]),   // hundreds of degrees
        .digit4(degrees_bcd[15:12]),  // thousands: always 0, blanked (leftmost)
        .decimal_point(4'b0000),      // no decimal points
        .digit_blank(blank_digit),    // leftmost digit dark: shows " 090" or "0090"
        .CA(CA),                      // segment outputs (active low)
        .CB(CB),
        .CC(CC),
        .CD(CD),
        .CE(CE),
        .CF(CF),
        .CG(CG),
        .DP(DP),                      // decimal point output (active low)
        .AN1(AN1),                    // anode outputs (active low)
        .AN2(AN2),
        .AN3(AN3),
        .AN4(AN4)
    ); 

    angle_display_subsystem ANGLE_DISPLAY (
        .clk(clk),                    // system clock
        .reset(reset),
        .position(position),
        .display(display),
        
        .blank_digit(blank_digit),
        .degrees_bcd(degrees_bcd)
    );
    //--------------------------------------------------------------------------
    // LEDs: status at a glance
    //--------------------------------------------------------------------------
    assign led[3:0]   = kp;           // gain Kp, in binary
    assign led[7:4]   = 4'b0000;      // unused
    assign led[8]     = encoder_a;    // encoder channel A (flickers when turning)
    assign led[9]     = encoder_b;    // encoder channel B (flickers when turning)
    assign led[12:10] = 3'b000;       // unused
    assign led[13]    = motor_in2;    // motor driving in reverse
    assign led[14]    = motor_in1;    // motor driving forward
    assign led[15]    = arm;          // motor armed

endmodule
