/*
##################################################################
Module Number		
Module Name: tb_salsa_hash_interative_wrapper_random1				
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

module tb_salsa_hash_interative_wrapper_random1 ();


// Testbench signals
reg clk_tb;
reg rst_n_tb;
reg tb_start_hashing;
reg 			tb_key_select = 1'b1; // key with 256 bits 
reg [1:0]		tb_salsa_round_select = 2'b0; // salsa 20 --> 10 round
reg [63:0]		tb_two_nonce_word = {32'h5d0d0cf2, 32'h40c9920b};
reg [63:0]		tb_two_counter_word = {32'h309a086f, 32'hc3b1eaa2};
reg [255:0]		tb_key_in = {32'h548daa7d, 32'hee85f8c3, 32'hb6263445,32'h3e8b656a,
							32'hb61b140e, 32'hfe9bd78a, 32'h26acfb77, 32'h43099f48};

wire [511:0]	tb_salsa_hashing_text;

wire tb_hashing_done;		// pulse
assign tb_hashing_done = dut.hashing_done;

wire [31:0] tb_mtx_hash_out [0:3][0:3];
assign tb_mtx_hash_out = dut.initial_hashing_out;

// Expected output 
reg [31:0] expected_hashing_matrix [0:3][0:3];

assign expected_hashing_matrix[0][0] = 32'hb1d7f0cd; assign expected_hashing_matrix[2][0] = 32'h4f2c882d;
assign expected_hashing_matrix[0][1] = 32'h23cdff19; assign expected_hashing_matrix[2][1] = 32'he23df1c0;
assign expected_hashing_matrix[0][2] = 32'hec503d9d; assign expected_hashing_matrix[2][2] = 32'h008171d5;
assign expected_hashing_matrix[0][3] = 32'h63588041; assign expected_hashing_matrix[2][3] = 32'he706da3f;
assign expected_hashing_matrix[1][0] = 32'h65870a82; assign expected_hashing_matrix[3][0] = 32'h62560c1c;
assign expected_hashing_matrix[1][1] = 32'h81344401; assign expected_hashing_matrix[3][1] = 32'hb2f9e803;
assign expected_hashing_matrix[1][2] = 32'ha52467a2; assign expected_hashing_matrix[3][2] = 32'h00761d1f;
assign expected_hashing_matrix[1][3] = 32'h1a6661b3; assign expected_hashing_matrix[3][3] = 32'h131b2ee3;

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
	
	.salsa_hashing_text 	(tb_salsa_hashing_text[511:0])	// bus
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

endmodule		// tb_salsa_hash_interative_wrapper_random1