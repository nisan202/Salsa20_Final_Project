/*
##################################################################
Module Number 15			
Module Name: quarter_round_tb				
Author: Nisan Moshe Shlomov 			
final project 						
Date: 21.01.2025					
Description:
	
##################################################################	
*/

`default_nettype none

module quarter_round_tb ();


// Testbench signals
reg [31:0] tb_dw0_in = 32'b1;
reg [31:0] tb_dw1_in = 32'b0;
reg [31:0] tb_dw2_in = 32'b0;
reg [31:0] tb_dw3_in = 32'b0;
reg [31:0] tb_dw0_out;
reg [31:0] tb_dw1_out;
reg [31:0] tb_dw2_out;
reg [31:0] tb_dw3_out;


// dut
quarter_round dut(
	.dw0_in		(tb_dw0_in),
	.dw1_in		(tb_dw1_in),
	.dw2_in		(tb_dw2_in),
	.dw3_in		(tb_dw3_in),
	.dw0_out	(tb_dw0_out),
	.dw1_out	(tb_dw1_out),
	.dw2_out	(tb_dw2_out),
	.dw3_out	(tb_dw3_out)
);
endmodule