/*
##################################################################
Module Number
Module Name: tb_salsa_hash_interative_wrapper_zeros				
Author: Nisan Moshe Shlomov 			
final project 						
Date: 					
Description:



									column
[31:0] matrix [0:3][0:3] --> 		  0	      1	      2	      3
							row	0	[0,0]	[0,1]	[0,2]	[0,3]
										
								1	[1,0]	[1,1]	[1,2]	[1,3]
								
								2	[2,0]	[2,1]	[2,2]	[2,3]
								
								3	[3,0]	[3,1]	[3,2]	[3,3]	
##################################################################	
*/

`default_nettype none

module tb_salsa_hash_interative_wrapper_zeros ();


// Testbench signals
reg clk_tb;
reg rst_n_tb;
reg tb_start_hashing;
reg 			tb_key_select = 1'b1; // key with 256 bits 
reg [1:0]		tb_salsa_round_select = 2'b0; // salsa 20 --> 10 round
reg [63:0]		tb_two_nonce_word = 64'b0;
reg [63:0]		tb_two_counter_word = 64'b0;
reg [255:0]		tb_key_in = 256'b0;

wire [511:0]	tb_salsa_hashing_text;

wire tb_hashing_done;		// pulse
assign tb_hashing_done = dut.hashing_done;

wire [31:0] tb_mtx_hash_out [0:3][0:3];
assign tb_mtx_hash_out = dut.initial_hashing_out;

// Expected output 
reg [31:0] expected_hashing_matrix [0:3][0:3];

assign expected_hashing_matrix[0][0] = 32'h5bf6979a; assign expected_hashing_matrix[2][0] = 32'hdac0e93d;
assign expected_hashing_matrix[0][1] = 32'h1b724c9b; assign expected_hashing_matrix[2][1] = 32'h1ef9d72b;
assign expected_hashing_matrix[0][2] = 32'h21670a96; assign expected_hashing_matrix[2][2] = 32'h9b63b2bc;
assign expected_hashing_matrix[0][3] = 32'hd4a8fc45; assign expected_hashing_matrix[2][3] = 32'h25c689f9;
assign expected_hashing_matrix[1][0] = 32'hf9672ee3; assign expected_hashing_matrix[3][0] = 32'h38bf291b;
assign expected_hashing_matrix[1][1] = 32'h79a91e11; assign expected_hashing_matrix[3][1] = 32'hdc9b9ad3;
assign expected_hashing_matrix[1][2] = 32'h26489cce; assign expected_hashing_matrix[3][2] = 32'h4b5fc5e7;
assign expected_hashing_matrix[1][3] = 32'he6ee6a80; assign expected_hashing_matrix[3][3] = 32'h392ac12a;

// dut
salsa_hash_interative_wrapper dut(
	.clk					(clk_tb),
	.rst_n					(rst_n_tb),
	
	.key_select				(tb_key_select),
	.salsa_round_select		(tb_salsa_round_select[1:0]),
	.two_nonce_word			(tb_two_nonce_word[63:0]),
	.two_counter_word		(tb_two_counter_word[63:0]),
	.key_in					(tb_key_in[255:0]),
	.start_hashing			(tb_start_hashing),
	
	.salsa_hashing_text 	(tb_salsa_hashing_text[511:0])
);


// Clock generation
always #5 clk_tb = ~ clk_tb;	// F = 100MHz -> T = 10ns

initial begin
	clk_tb = 1'b0;
	rst_n_tb = 1'b0;
	tb_start_hashing = 1'b0;
	
	# 23 rst_n_tb = 1;  // Release reset
	
	# 100 tb_start_hashing = 1'b1;	// pulse input
	# 10 tb_start_hashing = 1'b0;
	
	// Checks whether the tb_mtx_hash_out matrix has changed as expected
	@(posedge tb_hashing_done);
	
	# 10;
	
	if (tb_mtx_hash_out !== expected_hashing_matrix) begin
		$display("❌ ERROR: Hash output does not match expected value!");
		$display("Expected: %p", expected_hashing_matrix);
		$display("Got     : %p", tb_mtx_hash_out);
	end else begin
		$display("✅ SUCCESS: Hash output matches expected value.");
	end
	
end

endmodule		// tb_salsa_hash_interative_wrapper_zeros