



`default_nettype none

module tb_hash_interative_with_d_r_c ();

reg tb_clk;
reg tb_rst_n;
reg [31:0] tb_salsa_dw_matrix_in [0:3][0:3];
reg tb_salsa_round_select = 2'b0;
reg tb_start;	// pulse

wire [31:0] tb_salsa_dw_matrix_out [0:3][0:3];
wire tb_hashing_done;
	
assign tb_salsa_dw_matrix_in[0][0] = 32'h61707865; 	// constant_0
assign tb_salsa_dw_matrix_in[0][1] = 32'h0;			// key_0
assign tb_salsa_dw_matrix_in[0][2] = 32'h0;			// key_1
assign tb_salsa_dw_matrix_in[0][3] = 32'h0;			// key_2
assign tb_salsa_dw_matrix_in[1][0] = 32'h0;			// key_3 
assign tb_salsa_dw_matrix_in[1][1] = 32'h3320646E; 	// constant_1
assign tb_salsa_dw_matrix_in[1][2] = 32'h0; 			// nonce_0
assign tb_salsa_dw_matrix_in[1][3] = 32'h0;			// nonce_1
assign tb_salsa_dw_matrix_in[2][0] = 32'h0; 			//count_0
assign tb_salsa_dw_matrix_in[2][1] = 32'h0; 			//count_1
assign tb_salsa_dw_matrix_in[2][2] = 32'h79622D32; 	// constant_2
assign tb_salsa_dw_matrix_in[2][3] = 32'h0;			// key_4
assign tb_salsa_dw_matrix_in[3][0] = 32'h0;			// key_5
assign tb_salsa_dw_matrix_in[3][1] = 32'h0;			// key_6
assign tb_salsa_dw_matrix_in[3][2] = 32'h0;			// key_7
assign tb_salsa_dw_matrix_in[3][3] = 32'h6B206574; 	// constant_3


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

hash_interative_with_d_r_c	dut (
	// Inputs
	.clk					(tb_clk),
	.rst_n					(tb_rst_n),
	.salsa_dw_matrix_in		(tb_salsa_dw_matrix_in), 
	.salsa_round_select		(tb_salsa_round_select),
	.start					(tb_start),	// pulse input
	// Outputs
    .salsa_dw_matrix_out	(tb_salsa_dw_matrix_out),
	.hashing_done			(tb_hashing_done)	// pulse output
);
	
	
// Clock generation
always #5 tb_clk = ~ tb_clk;	// F = 100MHz -> T = 10ns

initial begin
	tb_clk = 1'b0;
	tb_rst_n = 1'b0;
	tb_start = 1'b0;
	
	# 23 tb_rst_n = 1'b1;  // Release reset
	
	# 100 tb_start = 1'b1;	// pulse input
	# 10 tb_start = 1'b0;
	
	// Checks whether the tb_salsa_dw_matrix_out has changed as expected
	@(posedge tb_hashing_done);
	
	# 10;
	
	if (tb_salsa_dw_matrix_out !== expected_hashing_matrix) begin
		$display("❌ ERROR: Hash output does not match expected value!");
		$display("Expected: %p", expected_hashing_matrix);
		$display("Got     : %p", tb_salsa_dw_matrix_out);
	end else begin
		$display("✅ SUCCESS: Hash output matches expected value.");
		$display("Expected: %p", expected_hashing_matrix);
		$display("Got     : %p", tb_salsa_dw_matrix_out);
	end
	
end

endmodule		// tb_hash_interative_with_d_r_c