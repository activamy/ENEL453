module lab_1b_top_level (
    input  logic [15:0] switches_inputs, // slide switches (0 towards Basys3 board edge, 1 towards board center)
    output logic [15:0] led, // mapped to the LEDs above the slide switches, LEDs: write a 1 to light LED, 0 to turn it off
    input logic         clk,
    input logic         reset,
    output logic        CA, CB, CC, CD, CE, CF, CG, DP, // segment outputs (active-low)
    output logic        AN1, AN2, AN3, AN4 // anode outputs for digit selection (active-low)
);

    // Internal signal declarations

    logic [15:0] switches_outputs;

    // Instantiate components

    switch_logic SWITCHES (
         .switches_inputs( switches_inputs),
         .switches_outputs(switches_outputs)
    );

    seven_segment_display_subsystem DISPLAY (
        .clk(clk), .reset(reset),
        .sec_dig1(switches_inputs[3:0]),
        .sec_dig2(switches_inputs[7:4]),
        .min_dig1(switches_inputs[11:8]),
        .min_dig2(switches_inputs[15:12]),
        .AN1(AN1), .AN2(AN2), .AN3(AN3), .AN4(AN4),
        .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG),
        .DP(DP)
    );

    assign led = switches_outputs;

endmodule