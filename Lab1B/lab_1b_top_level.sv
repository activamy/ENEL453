module lab_1b_top_level (
    input  logic [15:0] switches_inputs, // slide switches (0 towards Basys3 board edge, 1 towards board center)
    input logic         clk,
    input logic         reset,
    
    output logic [15:0] led, // mapped to the LEDs above the slide switches, LEDs: write a 1 to light LED, 0 to turn it off
    output logic        AN1, AN2, AN3, AN4,
    output logic        CA, CB, CC, CD, CE, CF, CG,
    output logic        DP
);

    // Internal signal declarations

    logic [15:0] switches_outputs;
    
    // Seven Segment Display Declarations
    seven_segment_display_subsystem SEVEN_SEGMENT_DISPLAY (  // assigning things tgt so they don't change
        .clk(       clk),
        .reset(     reset),
        .sec_dig1(  switches_inputs[3:0]),
        .sec_dig2(  switches_inputs[7:4]),
        .min_dgi1(  switches_inputs[11:8]),
    );
    
    // Instantiate components

    switch_logic SWITCHES (
         .switches_inputs( switches_inputs),
         .switches_outputs(switches_outputs)
    );
      
    assign led = switches_outputs;

endmodule
