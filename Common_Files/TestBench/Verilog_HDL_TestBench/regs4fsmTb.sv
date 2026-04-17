/*
##################################################################
Module Number 21			
Module Name: regs4fsmTb				
Author: Nisan Moshe Shlomov 			
final project 						
Date: 27.02.2025					
Description:
	
##################################################################	
*/

module regs4fsmTb (
	input clk,
	input rst_n,
	input hit,
	input wr1_rd0,
	input [3:0] ben,
	input [31:0] wdata,
	input [5:0] addr,
	output reg [31:0] rdata,
	//output reg [319:0] regs_db_bus
	output reg [31:0] regs_db [9:0]		// 10 registers - each one with width=32
);

reg [319:0] regs_db_bus;
//reg [31:0] regs_db [9:0];		// 10 registers - each one with width=32

integer i;

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		for (i=0; i<10; i=i+1) begin
			regs_db[i] <= 32'b0;
		end
	end
	else begin
		if (hit & wr1_rd0 & (addr[3:0] < 4'd10)) begin
			if (ben[0]) regs_db[addr[3:0]] [7:0]   <= wdata[7:0];
			if (ben[1]) regs_db[addr[3:0]] [15:8]  <= wdata[15:8];
			if (ben[2]) regs_db[addr[3:0]] [23:16] <= wdata[23:16];
			if (ben[3]) regs_db[addr[3:0]] [31:24] <= wdata[31:24];
		end 
	end
end

always @(*) begin
	rdata[31:0] = regs_db[addr[3:0]];
end


integer k;

always @(*) begin
	regs_db_bus = 320'b0;
	for (k=0; k<10; k=k+1) begin
		regs_db_bus[32*(k+1)-1 -: 32] = regs_db[k];
	end
end

endmodule
