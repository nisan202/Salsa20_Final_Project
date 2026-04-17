/*


*/

`default_nettype none

module salsa_xor_regs_tb();

// Testbench signals
reg tb_clk;
reg tb_rst_n;

// input from salsa_registers
reg [511:0]	tb_a = 512'h0;	// hashing
reg [511:0] tb_b = 512'h0;  // plain text
	
wire [511:0] tb_axorb;	// output to salsa_registers
	
reg tb_start_xor;		// pulse input from salsa_registers
wire tb_xor_is_valid;	// pulse output to salsa_registers


// Expected output 
reg [511:0] expected_xor_out_0 = 512'h5bf6979a1b724c9b21670a96d4a8fc45f9672ee379a91e1126489ccee6ee6a80dac0e93d1ef9d72b9b63b2bc25c689f938bf291bdc9b9ad34b5fc5e7392ac12a;
reg [511:0] expected_xor_out_1 = 512'hefd1b66e826a01dbd3eb5a5dc91418dbb56373333fa88f4dca089dcd687c160f02f4c8e55ebd368a8af8d140cf958846d49a51acc91da236f99174f42574ce1c;


// dut
salsa_xor_regs	dut(
	.clk			(tb_clk),
	.rst_n			(tb_rst_n),
	.a				(tb_a),
	.b				(tb_b),	
	.axorb			(tb_axorb),	
	.start_xor		(tb_start_xor),
	.xor_is_valid	(tb_xor_is_valid)
);


// Clock generation
always #5 tb_clk = ~ tb_clk;	// F = 100MHz -> T = 10ns

initial begin
	tb_clk = 1'b0;
	tb_rst_n = 1'b0;
	tb_start_xor = 1'b0;
	tb_a = 512'h0;
	
	# 23 tb_rst_n = 1;  // Release reset
	
	// TEST ZEROS
	
	// nonce,key,counter ZEROS + plain ZEROS
	# 20 tb_a = 512'h5bf6979a1b724c9b21670a96d4a8fc45f9672ee379a91e1126489ccee6ee6a80dac0e93d1ef9d72b9b63b2bc25c689f938bf291bdc9b9ad34b5fc5e7392ac12a;
	
	// pulse input
	# 100 tb_start_xor = 1'b1;
	# 10  tb_start_xor = 1'b0;
	
	// Checks whether the tb_axorb has changed as expected
	@(posedge tb_xor_is_valid);
	
	# 10;
	
	$display("Test number 1: zeros");
	$display("the hashing bus is: %0128h", tb_a);
	$display("the plain text bus is: %0128h", tb_b);
	$display("the xor between them is: %0128h", tb_axorb);
	
	if (tb_axorb !== expected_xor_out_0) begin
		$display("❌ ERROR: Hash output does not match expected value!");
		$display("Expected: %0128h", expected_xor_out_0);
		$display("Got     : %0128h", tb_axorb);
	end else begin
		$display("✅ SUCCESS: Hash output matches expected value.");
	end
	
	# 50;
	// TEST random1
	
	# 20 tb_a = 512'hb1d7f0cd23cdff19ec503d9d6358804165870a8281344401a52467a21a6661b34f2c882de23df1c0008171d5e706da3f62560c1cb2f9e80300761d1f131b2ee3;
		 tb_b = 512'h5e0646a3a1a7fec23fbb67c0aa4c989ad0e479b1be9ccb4c6f2cfa6f721a77bc4dd840c8bc80c74a8a79a09528935279b6cc5db07be44a35f9e769eb366fe0ff;

	// pulse input
	# 100 tb_start_xor = 1'b1;
	# 10  tb_start_xor = 1'b0;
	
	// Checks whether the tb_axorb has changed as expected
	@(posedge tb_xor_is_valid);
	
	# 10;
	
	$display("Test number 2: random1");
	$display("the hashing bus is: %0128h", tb_a);
	$display("the plain text bus is: %0128h", tb_b);
	$display("the xor between them is: %0128h", tb_axorb);
	
	if (tb_axorb !== expected_xor_out_1) begin
		$display("❌ ERROR: Hash output does not match expected value!");
		$display("Expected: %0128h", expected_xor_out_1);
		$display("Got     : %0128h", tb_axorb);
	end else begin
		$display("✅ SUCCESS: Hash output matches expected value.");
	end
	
	$display("Test number 2 is DONE");
	
end

endmodule		// tb_salsa_xor_regs