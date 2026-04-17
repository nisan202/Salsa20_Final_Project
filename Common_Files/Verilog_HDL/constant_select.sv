/*
##################################################################
Module Number 6				
Module Name: constant_select 				
Author: Nisan Moshe Shlomov 			
final project 						
Date: 13.09.2024 					
Description: 
The select changes according to the bit width of the key that the system receives.
select_32_or_16:										                                         
 = 1:constant= "expand 32-byte k" - from key with 256 bit				                     	 
 = 0:constant= "expand 16-byte k" - from key with 128 bit
 
We will convert the constant text strings into four words according to "small byte order",	 
a total of four letters per word. ("e"= 0x65)
											                                               
expand 32-byte k:										                                         
		z0=(65,78,70,61), z1=(6E,64,20,33), z2=(32,2D,62,79), z3=(74,65,20,6B)		            
in "LITLE ENDIAN" we get: z0=32'h61707865, z1=32'h3320646E, z2=32'h79622D32, z3=32'h6B206574	 
											                                                 	
expand 16-byte k:								                                         		 
		z0=(65,78,70,61), z1=(6E,64,20,31), z2=(36,2D,62,79), z3=(74,65,20,6B)	            	
in "LITLE ENDIAN" we get: z0=32'h61707865, z1=32'h3120646E, z2=32'h79622D36, z3=32'h6B206574	 
##################################################################
*/

`default_nettype none

module constant_select
	(
	input wire 		select_32_or_16,
	output wire [127:0]	constant_bus
);

// internal signals

reg [31:0]	constant1; 
reg [31:0]	constant2;
reg [31:0]	constant3;
reg [31:0]	constant4;

//------------------------------------------
//select which constant we need acording to select_32_or_16

always @(*) begin
	if (select_32_or_16) begin
		constant1 = 32'h61707865;
		constant2 = 32'h3320646E;
		constant3 = 32'h79622D32;
		constant4 = 32'h6B206574;
	end
	else begin 			//select_32_or_16 = 0
		constant1 = 32'h61707865;
		constant2 = 32'h3120646E;
		constant3 = 32'h79622D36;
		constant4 = 32'h6B206574;
	end
end 

//------------------------------------------
// assign the output constant_bus

assign constant_bus[127:0] = {constant4[31:0], constant3[31:0], constant2[31:0], constant1[31:0]}; 


endmodule	// end constant_select
