/*
##################################################################
Module Number 10			
Module Name: salsa_xor_regs 				
Author: Nisan Moshe Shlomov 			
final project 						
Date: 05.01.2025 					
Description: 
	xor 512 bit.    c = a^b
	We divide the xor into 16 parts, each dw in one clock cycle.
##################################################################
*/

`default_nettype none

module salsa_xor_regs
	(
	input wire 				clk,
	input wire				rst_n,
	
	input wire [511:0]		a,	// input from salsa_registers
	input wire [511:0] 		b,	// input from salsa_registers
	
	output reg [511:0]  	axorb,	// output to salsa_registers
	
	input wire 				start_xor,		// pulse input from salsa_registers
	output reg 				xor_is_valid	// pulse output to salsa_registers
);

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
// Internal Signals
reg [3:0] xor_cntr;	// 0-15
reg [511:0] result;
reg processing;
reg valid;
reg output_delay;

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
// The XOR Operation

// result[base +: width] ==> result[base + width - 1 : base]


always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		xor_cntr[3:0]	<= 4'b0;
		result[511:0] 	<= 512'b0;
		processing 	  	<= 1'b0;
		valid 			<= 1'b0;
	end
	else begin
		if (start_xor && ~processing) begin
			xor_cntr[3:0]	<= 4'b0;
			result[511:0] 	<= 512'b0;
			processing 	  	<= 1'b1;
			valid 			<= 1'b0;
		end
		else if (processing) begin
			result[xor_cntr*32 +: 32] <= a[xor_cntr*32 +: 32] ^ b[xor_cntr*32 +: 32];
			
			if (xor_cntr == 15) begin
                xor_cntr   		<= 0;
				valid			<= 1;
				processing 		<= 0;
			end
			else begin
				xor_cntr <= xor_cntr + 1;
			end
		end
		else begin
			valid <= 0; // pulse 
        end
	end
end

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
// axorb & xor_is_valid

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		axorb[511:0] <= 512'b0;
		output_delay <= 1'b0;
	end
	else if (valid) begin
		axorb <= result;
		output_delay <= 1'b1;
	end
	else begin
		output_delay <= 1'b0;
	end
end


always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		xor_is_valid <= 1'b0;
	end
	else if (output_delay) begin
		xor_is_valid <= 1'b1;
	end
	else begin
		xor_is_valid <= 1'b0;
	end
end
// ----------------------------------------------------------------------

endmodule		// end salsa_xor_regs 