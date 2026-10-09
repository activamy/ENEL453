module lab_3_top_level (
    input  logic [15:0] switches_inputs, // slide switches (0 towards Basys3 board edge, 1 towards board center)
    output logic [15:0] led, // mapped to the LEDs above the slide switches, LEDs: write a 1 to light LED, 0 to turn it off
    input logic         clk,
    input logic         reset,
    output logic        CA, CB, CC, CD, CE, CF, CG, DP, // segment outputs (active-low)
    output logic        AN1, AN2, AN3, AN4, // anode outputs for digit selection (active-low)
    input logic         bin_bcd_select,
    input logic         store_en,
    input logic         show_store_select
);

    // Internal signal declarations

    logic [15:0] switches_outputs;
    logic [15:0] bcd_value_cur;
    logic [15:0] bcd_value_store;
    logic [15:0] mux_val_cur;
    logic [15:0] mux_val_store;
    logic        select;
    logic [15:0] store_val;
    logic [15:0] disp_val;
    logic        store_enable;
    logic [15:0] switches;
    
    
    // Instantiate components

    switch_logic SWITCHES (
         .switches_inputs( switches_inputs),
         .switches_outputs(switches_outputs)
    );
    
    
     synchronizer SYNC (
        .clk(clk),
        .d(switches_inputs),
        .q(switches)
    );
    
    bin_to_bcd BCD_CUR (
        .clk(clk),
        .reset(reset),
        .bin_in(switches),
        .bcd_out(bcd_value_cur)
    );
    bin_to_bcd BCD_STORE (
        .clk(clk),
        .reset(reset),
        .bin_in(store_val),
        .bcd_out(bcd_value_store)
    );
    
    mux2 MUX_BINBCD (
    .switches_inputs(switches),
    .bcd_out(bcd_value_cur),
    .bin_bcd_select(select),
    .disp_bus(mux_val_cur)
   );
   
   mux2 MUX_STORE (
    .switches_inputs(store_val),
    .bcd_out(bcd_value_store),
    .bin_bcd_select(select),
    .disp_bus(mux_val_store)
   );
   
    mux2 MUX_DISPLAY (
    .switches_inputs(mux_val_store),
    .bcd_out(mux_val_cur),
    .bin_bcd_select(show_store_select),
    .disp_bus(disp_val)
   );

    debounce DEBOUNCE_BINBCD (
    .clk(clk),
    .reset(reset),
    .button(bin_bcd_select),
    .result(select)
    );
       
    debounce DEBOUNCE_STORE (
    .clk(clk),
    .reset(reset),
    .button(store_en),
    .result(store_enable)
    );
    
    register REGISTER (
    .clk(clk),
    .reset(reset),
    .en(store_enable),
    .d(switches),
    .q(store_val)
    );    
    

    seven_segment_display_subsystem DISPLAY (
        .clk(clk), .reset(reset),
        .sec_dig1(disp_val[3:0]),
        .sec_dig2(disp_val[7:4]),
        .min_dig1(disp_val[11:8]),
        .min_dig2(disp_val[15:12]),
        .AN1(AN1), .AN2(AN2), .AN3(AN3), .AN4(AN4),
        .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG),
        .DP(DP)   
    );

    assign led = switches_outputs;

endmodule
