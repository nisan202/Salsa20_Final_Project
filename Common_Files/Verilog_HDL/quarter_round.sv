/*
##################################################################
Module Number 1				
Module Name: QuarterRound				
Author: Nisan Moshe Shlomov 			
final project 						
Date: 06.09.2024 					
Description:
	quarter_round function:
	z1 = y1 ^ ((y0 + y3) <<< rotate1)
	z2 = y2 ^ ((z1 + y0) <<< rotate2)
	z3 = y3 ^ ((z2 + z1) <<< rotate3)
	z0 = y0 ^ ((z3 + z2) <<< rotate4)
##################################################################	
*/
//`include "3.Defines_file/salsa_defines.def"
`include "../3.Defines_file/salsa_defines.vh"

`default_nettype none

module quarter_round #(
	// salsa default parameters
	parameter ROTATE1 = `ROTATE1,
	parameter ROTATE2 = `ROTATE2,
	parameter ROTATE3 = `ROTATE3,
	parameter ROTATE4 = `ROTATE4)
	(
	
// inputs - the function get 4 dw.
	input wire [31:0] dw0_in,
	input wire [31:0] dw1_in,
	input wire [31:0] dw2_in,
	input wire [31:0] dw3_in,
	
// outputs - the function get out 4 dw.
	output wire [31:0] dw0_out,
	output wire [31:0] dw1_out,
	output wire [31:0] dw2_out,
	output wire [31:0] dw3_out
);
//--------------------------------------------------------------------------------------
// We will use internal signals to do all the required math in a good and efficient way.
// also,to making sure the whole process works correctly.

// internal signals
wire [31:0] add_1;
wire [31:0] add_2; 
wire [31:0] add_3; 
wire [31:0] add_4; 

wire [31:0] temp_out_1;
wire [31:0] temp_out_2; 
wire [31:0] temp_out_3; 
wire [31:0] temp_out_4; 

//--------------------------------------------------------------------------------------
// the quarter_round implementation

// z1 = y1 ^ ((y0 + y3) <<< rotate1)
assign add_1[31:0] = (dw0_in[31:0] + dw3_in[31:0]) & 32'hFFFFFFFF;
assign temp_out_1[31:0] = dw1_in ^ ((add_1 << ROTATE1)|(add_1 >> (32-ROTATE1)));

// z2 = y2 ^ ((z1 + y0) <<< rotate2)
assign add_2[31:0] = (temp_out_1[31:0] + dw0_in[31:0]) & 32'hFFFFFFFF;
assign temp_out_2[31:0] = dw2_in ^ ((add_2 << ROTATE2)|(add_2 >> (32-ROTATE2)));

// z3 = y3 ^ ((z2 + z1) <<< rotate3)
assign add_3[31:0] = (temp_out_2[31:0] + temp_out_1[31:0]) & 32'hFFFFFFFF;
assign temp_out_3[31:0] = dw3_in ^ ((add_3 << ROTATE3)|(add_3 >> (32-ROTATE3)));

// z0 = y0 ^ ((z3 + z2) <<< rotate4)
assign add_4[31:0] = (temp_out_3[31:0] + temp_out_2[31:0]) & 32'hFFFFFFFF;
assign temp_out_4[31:0] =  dw0_in ^ ((add_4 << ROTATE4)|(add_4 >> (32-ROTATE4)));

//--------------------------------------------------------------------------------------
// assignment to the real outputs

assign dw1_out = temp_out_1;
assign dw2_out = temp_out_2;
assign dw3_out = temp_out_3;
assign dw0_out = temp_out_4;


endmodule		// end quarter_round