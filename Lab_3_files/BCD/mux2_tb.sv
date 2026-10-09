`timescale 1ns / 1ps

module mux2_tb();

    // Parameters
    parameter CLK_PERIOD = 10; // 10 ns

    // Testbench signals
    logic [15:0] switches_inputs;
    logic [15:0] bcd_out;
    logic        bin_bcd_select;
    logic [15:0] disp_bus;

    // Instantiate the Unit Under Test (UUT)
    mux2 uut (
        .switches_inputs(switches_inputs),
        .bcd_out        (bcd_out),
        .bin_bcd_select (bin_bcd_select),
        .disp_bus       (disp_bus)
    );
    
    // Test stimulus
    initial begin
        // Initialize inputs
        switches_inputs = 16'h0000;
        bcd_out         = 16'h0000;
        bin_bcd_select  = 1'b0;
        #(30 * CLK_PERIOD);

        // Test Case 1: Select = 0 
        bin_bcd_select  = 1'b0;
        switches_inputs = 16'b0101_0101_0101_0101;
        bcd_out         = 16'b1010_1010_1010_1010;
        #(10 * CLK_PERIOD);

        // Test Case 2: Select = 1 
        bin_bcd_select  = 1'b1;
        switches_inputs = 16'b0101_0101_0101_0101;
        bcd_out         = 16'b1010_1010_1010_1010;
        #(10 * CLK_PERIOD);

        // Test Case 3: Select = 0 and test for no changes when changing switch_input
        bin_bcd_select  = 1'b0;
        switches_inputs = 16'b0101_0101_0101_0101;
        bcd_out         = 16'b1010_1010_1010_1010;
        #(10 * CLK_PERIOD);

        switches_inputs = 16'h0000;
        #(10 * CLK_PERIOD);

        // Test Case 4: Select = 0 an test for no changes when bcd_out changes
        bin_bcd_select  = 1'b1;
        switches_inputs = 16'b1010_1010_1010_1010;
        bcd_out         = 16'b0101_0101_0101_0101;
        #(10 * CLK_PERIOD);

        bcd_out         = 16'h1111;
        #(10 * CLK_PERIOD);

        // Test Case 5
        switches_inputs = 16'hFFFF;
        bcd_out         = 16'h0000;
        
        bin_bcd_select  = 1'b0;
        #(10 * CLK_PERIOD);

        bin_bcd_select  = 1'b1; 
        #(10 * CLK_PERIOD);

        // End simulation
        #(5 * CLK_PERIOD);
        $stop;
    end

    // Monitor changes
    initial begin
        $monitor("Time = %0t | sel = %b | sw = 0x%04h | bcd = 0x%04h | disp_bus = 0x%04h",
                 $time, bin_bcd_select, switches_inputs, bcd_out, disp_bus);
    end

endmodule