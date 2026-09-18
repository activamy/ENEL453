`timescale 1ns / 1ps

module lab_1b_top_level_tb();

    // Parameters
    parameter CLK_PERIOD = 10; // 10ns for 100MHz clock
    parameter RESET_DURATION = 5 * CLK_PERIOD;
    parameter CONVERSION_TIME = 20 * CLK_PERIOD;
    parameter QUARTER_CYCLE = CLK_PERIOD / 4;

    // Signals
    logic [15:0] switches_inputs;
    logic [15:0] led;
    
    logic clk;
    logic reset;
    logic CA, CB, CC, CD, CE, CF, CG, DP;
    logic AN1, AN2, AN3, AN4;

    // Instantiate the Unit Under Test (UUT)
    lab_1b_top_level uut (
        .switches_inputs(switches_inputs),
        .led(led),
        
        .clk(clk),
        .reset(reset),
        .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG), .DP(DP),
        .AN1(AN1), .AN2(AN2), .AN3(AN3), .AN4(AN4)
    );
    
    // Clock Generation
    always begin
        clk = 0;
        #(CLK_PERIOD/2);
        clk = 1;
        #(CLK_PERIOD/2);

    end

    // Test stimulus
    initial begin
        // Initialize inputs
        reset = 0;
        
        // Apply Reset
        reset = 0;
        #RESET_DURATION;
        reset = 1;
        #CLK_PERIOD;
        reset = 0;
        #RESET_DURATION;
        
        // Test case 1:
        switches_inputs = 16'b0000_0000_0000_0000; #CLK_PERIOD;
        
        // Test case 2:
        switches_inputs = 16'b1111_1111_1111_1111; #CLK_PERIOD;

        // Test case 2:
        switches_inputs = 16'b0101_0101_0101_0101; #CLK_PERIOD;

        // Test case 3:
        switches_inputs = 16'b1010_1010_1010_1010; #CLK_PERIOD;
        
        // Test case 4:
        switches_inputs = 16'b1100_1100_1100_1100; #CLK_PERIOD;
        
        // Test case 5:
        switches_inputs = 16'b0011_0011_0011_0011; #CLK_PERIOD;
        
        // End simulation
        #(5 * CLK_PERIOD);
        $stop;
    end

    // Optional: Monitor changes
    initial begin
        $monitor("Time = %0t: switches_inputs = %b, led = %b", 
                 $time, switches_inputs, led);
    end

endmodule