`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////


module tb_count_display;
    import disk_pkg::*;                                     // POSITION_WIDTH, COUNTS_PER_REV

    logic                                sw10 = 0;          // switch
    logic signed [POSITION_WIDTH-1:0]    position;          // position
    logic        [DEGREES_WIDTH-1:0]     degree;            // degrees

    logic        [15:0]                  bin_val;           // creates the 16 bit binary to go into bin_to_bcd         
    logic        [3:0]                   blank_digit;       // 4 digits wide, want thousands place to be empty

    int error = 0;
    
    count_display #(
    ) DUT (
        .bin_val(bcd_val),
        .sw10(display),                  // switch
        .position(position),            // position
        .degree(degrees),               // degrees
        .blank_digit(blank_digit)
    );



endmodule
