`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////


module tb_count_display;
    import disk_pkg::*;                                     // POSITION_WIDTH, COUNTS_PER_REV

    logic                                sw10;              // switch
    logic signed [POSITION_WIDTH-1:0]    position;          // position
    logic        [DEGREES_WIDTH-1:0]     degree;            // degrees

    logic        [15:0]                  bin_val;           // creates the 16 bit binary to go into bin_to_bcd         
    logic        [3:0]                   blank_digit;       // 4 digits wide, want thousands place to be empty

    int error = 0;
    
    count_display DUT (
        .bin_val(bin_val),
        .sw10(sw10),                  // switch
        .position(position),            // position
        .degree(degree),               // degrees
        .blank_digit(blank_digit)
    );


    // test functions
    task automatic check(logic [15:0] expected_display, logic [3:0] expected_digit, string todo);
        // wait 1 to let combinational logic happen
        #1;
        
        // check if its position or degrees selected
        if (bin_val !== expected_display) begin
            error++;
            $display("FAIL: %s: bcd value = %0d, expected = %0d", todo, bin_val, expected_display);
        end
        
        // check the left mosted digit
        if (blank_digit !== expected_digit) begin
            error++;                
            $display("FAIL: %s: leftmost digit is %d, expected is %d", todo, blank_digit, expected_digit);
        end    
    endtask

    initial begin
        // case 1: Switch down, display is in degrees, position is ignored and first digit is blank
        sw10 = 0; position = 345; degree = 10;
        check(16'd10, 4'b1000, "10 degrees");
        
        sw10 = 0; position = -234; degree = 345;
        check(16'd345, 4'b1000, "345 degrees");
        
        // case 2: Switch up, display is position, degrees is ignored and first digit exist
        sw10 = 1; position = 345; degree = 10;
        check(16'd345, 4'b0000, "Position = 345");
        
        // case 3: Switch up, position wraps after 2047
        sw10 = 1; position = 2450; degree = 25;
        check(16'd402, 4'b0000, "Position = 2450");
        
        // case 4: Switch up, negative positions works (goes backwards from 2047)
        sw10 = 1; position = -45; degree = 359;
        check(16'd2003, 4'b0000, "Position = -45");
        
        // case 5: switching back to degrees
        sw10 = 0; position = -45; degree = 359;
        check(16'd359, 4'b1000, "Degrees = 359");
       
       if (error == 0) $display("PASS tb_count_display");
       else            $display("FAIL tb_count_display: %0d errors", error);
       $finish; 
    end
endmodule
