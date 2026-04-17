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

module tb_d_r_c_interative_zeros ();

reg tb_clk;
reg tb_rst_n;
reg [31:0] tb_double_dw_matrix_in [0:3][0:3];
reg tb_start_double_round;	// pulse 

wire [31:0] tb_double_dw_matrix_out [0:3][0:3];
wire tb_double_round_done_valid; // pulse 


assign tb_double_dw_matrix_in[0][0] = 32'h61707865; 	// constant_0
assign tb_double_dw_matrix_in[0][1] = 32'h0;			// key_0
assign tb_double_dw_matrix_in[0][2] = 32'h0;			// key_1
assign tb_double_dw_matrix_in[0][3] = 32'h0;			// key_2
assign tb_double_dw_matrix_in[1][0] = 32'h0;			// key_3 
assign tb_double_dw_matrix_in[1][1] = 32'h3320646E; 	// constant_1
assign tb_double_dw_matrix_in[1][2] = 32'h0; 			// nonce_0
assign tb_double_dw_matrix_in[1][3] = 32'h0;			// nonce_1
assign tb_double_dw_matrix_in[2][0] = 32'h0; 			//count_0
assign tb_double_dw_matrix_in[2][1] = 32'h0; 			//count_1
assign tb_double_dw_matrix_in[2][2] = 32'h79622D32; 	// constant_2
assign tb_double_dw_matrix_in[2][3] = 32'h0;			// key_4
assign tb_double_dw_matrix_in[3][0] = 32'h0;			// key_5
assign tb_double_dw_matrix_in[3][1] = 32'h0;			// key_6
assign tb_double_dw_matrix_in[3][2] = 32'h0;			// key_7
assign tb_double_dw_matrix_in[3][3] = 32'h6B206574; 	// constant_3


reg [31:0] expected_1_double [0:3][0:3];

assign expected_1_double[0][0] = 32'hf1e35811; assign expected_1_double[2][0] = 32'hacdd42de;
assign expected_1_double[0][1] = 32'ha40114dd; assign expected_1_double[2][1] = 32'h1b6b1a1b;
assign expected_1_double[0][2] = 32'h218dc5bd; assign expected_1_double[2][2] = 32'hc8248ce8;
assign expected_1_double[0][3] = 32'h4b61e284; assign expected_1_double[2][3] = 32'hbb3717eb;
assign expected_1_double[1][0] = 32'hbe4befd4; assign expected_1_double[3][0] = 32'heeb3332a;
assign expected_1_double[1][1] = 32'h3fdfeb9f; assign expected_1_double[3][1] = 32'h68c62f5b;
assign expected_1_double[1][2] = 32'h7b756e86; assign expected_1_double[3][2] = 32'h9d4633d3;
assign expected_1_double[1][3] = 32'h6faac538; assign expected_1_double[3][3] = 32'h0c8bdd57;


// dut
d_r_c_round_interative dut(
	// Inputs
	.clk						(tb_clk),
	.rst_n						(tb_rst_n),
	.double_dw_matrix_in		(tb_double_dw_matrix_in),
	.start_double_round			(tb_start_double_round),
	//Outputs
	.double_dw_matrix_out		(tb_double_dw_matrix_out),
	.double_round_done_valid	(tb_double_round_done_valid)
);


// Clock generation
always #5 tb_clk = ~ tb_clk;	// F = 100MHz -> T = 10ns

initial begin
	tb_clk = 1'b0;
	tb_rst_n = 1'b0;
	tb_start_double_round = 1'b0;
	
	# 23 tb_rst_n = 1;  // Release reset
	
	# 100 tb_start_double_round = 1'b1;	// pulse input
	# 10 tb_start_double_round = 1'b0;
	
	
	// Checks whether the tb_mtx_hash_out matrix has changed as expected
	@(posedge tb_double_round_done_valid);
	
	# 10;
	
	if (tb_double_dw_matrix_out !== expected_1_double) begin
		$display("❌ ERROR: Hash output does not match expected value!");
		$display("Expected: %p", expected_1_double);
		$display("Got     : %p", tb_double_dw_matrix_out);
	end else begin
		$display("✅ SUCCESS: Hash output matches expected value.");
		$display("Expected: %p", expected_1_double);
		$display("Got     : %p", tb_double_dw_matrix_out);
	end
	
end

endmodule		// tb_d_r_c_interative_zeros
