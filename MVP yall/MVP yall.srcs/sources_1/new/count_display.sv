`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////


module count_display
    import disk_pkg::*;     // POSITION_WIDTH, DEGREES_WIDTH, COUNTS_PER_REV, DEGREES_PER_REV
(
    input   logic                                sw10,              // switch
    input   logic signed [POSITION_WIDTH-1:0]    position,          // position
    input   logic        [DEGREES_WIDTH-1:0]     degree,            // degrees

    output  logic        [15:0]                  bin_val,           // creates the 16 bit binary to go into bin_to_bcd         
    output  logic        [3:0]                   blank_digit        // 4 digits wide, want thousands place to be empty
    
    );
    
    localparam int REV_BITS     = $clog2(COUNTS_PER_REV);    // 11 bits count 0..2047

    always_comb begin
        if (sw10 == 1) begin
            bin_val = {5'b00000, position[REV_BITS-1:0]};  // modulo 2048    refer to position_to_degrees for why this was chosen
            blank_digit = 4'b0;
        end
        
        else begin
            bin_val = 16'(degree);                        // force it to 16 bits
            blank_digit = 4'b1000;
        end
    end
endmodule
