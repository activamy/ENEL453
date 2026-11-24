`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: angle_display_subsystem
//
// Purpose
//   angle mode stuff
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


module angle_display_subsystem
    import disk_pkg::*;                             // shared constants and widths
    (
    input  logic                             clk,
    input  logic                             reset,
    input  logic signed [POSITION_WIDTH-1:0] position,
    input  logic                             display,
    
    output logic        [15:0]               degrees_bcd,
    output logic        [3:0]                blank_digit
    );
    
    logic        [15:0]               bcd_val;
    logic        [DEGREES_WIDTH-1:0]  degrees;
    
    //--------------------------------------------------------------------------
    // Display: position -> degrees -> BCD digits -> 7-segment display
    //--------------------------------------------------------------------------

    position_to_degrees POSITION_TO_DEGREES (
        .position(position),          // signed position, counts
        .degrees(degrees)             // angle within one revolution, 0 to 359
    );

    bin_to_bcd BIN_TO_BCD (
        .clk(clk),                    // system clock
        .reset(reset),                // synchronous reset
        .bin_in(bcd_val),             // 9-bit angle, zero-extended to 16 bits
        .bcd_out(degrees_bcd)         // four BCD digits, e.g. 0359
    );
    
    count_display COUNT_DISPLAY (
        .bin_val(bcd_val),
        .sw10(display),                  // switch
        .position(position),            // position
        .degree(degrees),               // degrees
        .blank_digit(blank_digit)
    );
endmodule
