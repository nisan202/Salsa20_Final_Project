/*
##################################################################
Module Number 			
Module Name: hex_to_SSD_Intel			
Author: Nisan Moshe Shlomov		
final project 						
Date: 29.06.2025			
Description:
##################################################################	
*/

`default_nettype none

module hex_to_SSD_Intel(
	input wire	[3:0]	hex_number,
	input wire			dp,
	
	output wire			dp_set,
	output reg	[6:0]	seven_seg
);


// common anode: 1'b0 - turn on

 always @(*) begin
    case (hex_number[3:0])
		4'h0: seven_seg = 7'b1000000; // '0'
		4'h1: seven_seg = 7'b1111001; // '1'
		4'h2: seven_seg = 7'b0100100; // '2'
		4'h3: seven_seg = 7'b0110000; // '3'
		4'h4: seven_seg = 7'b0011001; // '4'
		4'h5: seven_seg = 7'b0010010; // '5'
		4'h6: seven_seg = 7'b0000010; // '6'
		4'h7: seven_seg = 7'b1111000; // '7'
		4'h8: seven_seg = 7'b0000000; // '8'
		4'h9: seven_seg = 7'b0010000; // '9'
		4'hA: seven_seg = 7'b0001000; // 'A'
		4'hB: seven_seg = 7'b0000011; // 'b'
		4'hC: seven_seg = 7'b1000110; // 'C'
		4'hD: seven_seg = 7'b0100001; // 'd'
		4'hE: seven_seg = 7'b0000110; // 'E'
		4'hF: seven_seg = 7'b0001110; // 'F'
		default: seven_seg = 7'b1111111;
	endcase
end

assign dp_set = ~dp;


endmodule