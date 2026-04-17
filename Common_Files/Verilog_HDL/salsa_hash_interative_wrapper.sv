/*
#######################################################################
Module Number: replace number 7		
Module Name: salsa_hash_interative_wrapper				
Author: Nisan Moshe Shlomov 			
final project 						
Date: 13.09.2024 					
Description:
	The purpose of the module is to unite everything
	related to the functionality of hashing.
	
									column
[31:0] matrix [0:3][0:3] --> 		  0	      1	      2	      3
							row	0	[0,0]	[0,1]	[0,2]	[0,3]
										
								1	[1,0]	[1,1]	[1,2]	[1,3]
								
								2	[2,0]	[2,1]	[2,2]	[2,3]
								
								3	[3,0]	[3,1]	[3,2]	[3,3]

Note: this file replace the "roling" implemntation "salsa_hashing_wrap"
#######################################################################	
*/

`default_nettype none

module salsa_hash_interative_wrapper
	(
	input wire			clk,
	input wire			rst_n,
	input wire 			key_select,
	input wire [1:0]	salsa_round_select,
	input wire [63:0]	two_nonce_word,
	input wire [63:0]	two_counter_word,
	input wire [255:0]	key_in,
	input wire			start_hashing,		// pulse input from salsa regs
	
	output reg			hash_done_to_regs,	// pulse to salsa_regs
	output reg [511:0]	salsa_hashing_text
);

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
// Internal Signals

wire 		hashing_done;	// pulse from hash_func
wire [31:0] initial_matrix_in [0:3][0:3];
wire [31:0] initial_hashing_out [0:3][0:3];
wire [127:0] constant_bus;

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		hash_done_to_regs <= 1'b0;
	end
	else begin
		if (hashing_done) begin
			hash_done_to_regs <= 1'b1;
		end
		else begin
			hash_done_to_regs <= 1'b0;
		end
	end
end

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
		
assign initial_matrix_in[0][0] = constant_bus[31:0]; 		// constant_0
assign initial_matrix_in[0][1] = key_in[31:0];				// key_0
assign initial_matrix_in[0][2] = key_in[63:32];				// key_1
assign initial_matrix_in[0][3] = key_in[95:64];				// key_2
assign initial_matrix_in[1][0] = key_in[127:96];			// key_3 
assign initial_matrix_in[1][1] = constant_bus[63:32]; 		// constant_1
assign initial_matrix_in[1][2] = two_nonce_word[31:0]; 		// nonce_0
assign initial_matrix_in[1][3] = two_nonce_word[63:32];		// nonce_1
assign initial_matrix_in[2][0] = two_counter_word[31:0]; 	//count_0
assign initial_matrix_in[2][1] = two_counter_word[63:32]; 	//count_1
assign initial_matrix_in[2][2] = constant_bus[95:64]; 		// constant_2
assign initial_matrix_in[2][3] = key_in[159:128];			// key_4
assign initial_matrix_in[3][0] = key_in[191:160];			// key_5
assign initial_matrix_in[3][1] = key_in[223:192];			// key_6
assign initial_matrix_in[3][2] = key_in[255:224];			// key_7
assign initial_matrix_in[3][3] = constant_bus[127:96]; 		// constant_3

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
// Hashing_out_bus
integer r,c;	// r=row ,c=column

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_hashing_text[511:0] <= 512'b0;
	end
	else if (hashing_done) begin
		for (r=0; r<4; r=r+1) begin 
			for(c=0; c<4; c=c+1) begin
				salsa_hashing_text[511 - 32*(r*4 + c) -: 32] = initial_hashing_out[r][c];
			end
		end
	end
end

// --------------------------------------------------
// ---------- constatnt select instance -------------
// --------------------------------------------------
 
constant_select u_constant_select(
	.select_32_or_16 	(key_select),
	.constant_bus		(constant_bus)
);

// --------------------------------------------------
// ----- hash_interative_with_d_r_c instance --------
// --------------------------------------------------

hash_interative_with_d_r_c	u_hash_interative_with_d_r_c(
	// Inputs
	.clk					(clk),
	.rst_n					(rst_n),
	.salsa_dw_matrix_in		(initial_matrix_in),
	.salsa_round_select		(salsa_round_select),
	.start					(start_hashing),
	// Outputs
	.salsa_dw_matrix_out	(initial_hashing_out),
	.hashing_done			(hashing_done)
);


/*
// --------------------------------------------------
// ----- salsa_hash_interative_func instance --------
// --------------------------------------------------

salsa_hash_interative_func u_salsa_hash_interative_func(
	// Inputs
	.clk					(clk),
	.rst_n					(rst_n),
	.salsa_dw_matrix_in		(initial_matrix_in),
	.salsa_round_select		(salsa_round_select),
	.start					(start_hashing),
	// Outputs
	.salsa_dw_matrix_out	(initial_hashing_out),
	.hashing_done			(hashing_done)
);
*/
// --------------------------------------------------

endmodule	// salsa_hash_interative_wrapper