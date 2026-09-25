`timescale 1ns / 1ps

module lab_2_top_level_tb();

    // Parameters
    parameter CLK_PERIOD = 10; // 10ns for 100MHz clock

    // Signals
    logic [15:0] switches_inputs;

    logic [15:0] led;
    logic        CA, CB, CC, CD, CE, CF, CG, DP; // segment outputs (active-low)
    logic        AN1, AN2, AN3, AN4; // anode outputs
    logic clk;
    logic reset;
    logic select;
    // Instantiate the Unit Under Test (UUT)
    lab_2_top_level uut (
        .switches_inputs(switches_inputs),
        .led(led),
        .AN1(AN1), .AN2(AN2), .AN3(AN3), .AN4(AN4),
        .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG),
        .DP(DP),
        .clk(clk),
        .reset(reset),
        .select(select)
    );

    always begin
        clk = 0;
        #(CLK_PERIOD/2);
        clk=1;
        #(CLK_PERIOD/2);
    end


    // Test stimulus
    initial begin
        // Initialize inputs
        reset = 0; 
        select = 0;
        switches_inputs = 16'h0000;
        #(CLK_PERIOD / 4);

        // Apply Reset
        reset = 1;
        #(5 * CLK_PERIOD);
        reset = 0;
        #CLK_PERIOD;

        // Test case 1:
        //switches_inputs = 16'b0000_0000_0000_0000; #CLK_PERIOD;
         
        // Test case 2:

        // Test case 3:
        //switches_inputs = 16'b1010_1010_1010_1010; #CLK_PERIOD;
        
        // Test case 4:
        //switches_inputs = 16'b1100_1100_1100_1100; #CLK_PERIOD;
        
        // Test case 5:
        //switches_inputs = 16'b0011_0011_0011_0011; #CLK_PERIOD;
        switches_inputs = 16'd0;
        #(30 * CLK_PERIOD);

        switches_inputs = 16'd1;
        #(30 * CLK_PERIOD);

        switches_inputs = 16'd1234;
        #(30 * CLK_PERIOD);

        switches_inputs = 16'd9999;
        #(30 * CLK_PERIOD);

        switches_inputs = 16'd10000;
        #(30 * CLK_PERIOD);

//$stop;
        
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
