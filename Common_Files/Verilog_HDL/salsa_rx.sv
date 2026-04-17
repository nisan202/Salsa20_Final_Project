/*
##################################################################
Module Number 			
Module Name: salsa_rx				
Author:  taken from git - need to fix and confrim to my code			
final project 						
Date: 09.01.2024 					
Description:
	
##################################################################
*/

//`include "3.Defines_file/salsa_defines.def"
`include "../3.Defines_file/salsa_defines.vh"


`default_nettype none

module salsa_rx #(
	parameter BIT_RATE = `BIT_RATE,
	parameter RATE_WIDTH = $clog2(`BIT_RATE))
	(
    input wire clk,				// Clock input
    input wire rst_n,     		// Active-low reset
    input wire rs232,     		// UART receive input
    output reg [7:0] rx_data,	// Received data
    output reg done       		// Reception done flag
);

//------------------------------------------------------------
//--------------------- Internal Signals ---------------------
//------------------------------------------------------------
reg [2:0] rs232_sync; 			// Sync registers to avoid metastability
reg [RATE_WIDTH-1:0] baud_cnt;  // Baud rate counter
//reg bit_flag;         			// Bit flag to signal bit reception
reg [3:0] bit_cnt;    			// Bit counter
reg state;            			// State of the receiver
wire start_bit_detected;		// start bit detected
reg sample_flag;				// pulse - Exactly in the middle of the time, when stable

//------------------------------------------------------------
//--------------------- Synchronize rs232 --------------------
//------------------------------------------------------------
// Synchronize the rs232 input to avoid metastability

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		rs232_sync <= 3'b111;
	end
	else begin 
		rs232_sync <= {rs232_sync[1:0], rs232};	// shift regs
	end
end

//------------------------------------------------------------
//--------------------- Detect start bit ---------------------
//------------------------------------------------------------

assign start_bit_detected = (rs232_sync[2:1] == 2'b10);

//------------------------------------------------------------
//----------------------- Baud rate --------------------------
//------------------------------------------------------------
// Baud rate counter logic

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		baud_cnt <= {RATE_WIDTH{1'b0}};
	end
	else if (state) begin
		if (baud_cnt == BIT_RATE) begin
			baud_cnt <= {RATE_WIDTH{1'b0}};
		end
		else begin
			baud_cnt <= baud_cnt + 1'b1;
		end
	end
	else begin
		baud_cnt <= {RATE_WIDTH{1'b0}};
	end
end

/*
//------------------------------------------------------------
//----------------------- Bit flag ---------------------------
//------------------------------------------------------------
// Bit flag logic

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		bit_flag <= 1'b0;
	end
	else if (baud_cnt == BIT_RATE) begin
		bit_flag <= 1'b1;
	end
	else begin
		bit_flag <= 1'b0;
	end
end
*/

//------------------------------------------------------------
//----------------------- Sample flag ------------------------
//------------------------------------------------------------
// Sample flag logic

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		sample_flag <= 1'b0;
	end
	else if (baud_cnt == BIT_RATE/2) begin
		sample_flag <= 1'b1;
	end
	else begin
		sample_flag <= 1'b0;
	end
end

//------------------------------------------------------------
//------------------------ FSM -------------------------------
//------------------------------------------------------------
// Main state and bit counter logic

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		state <= 1'b0;
		bit_cnt <= 4'd0;
		done <= 1'b0;
	end
	else if (start_bit_detected && !state) begin
		state <= 1'b1;
		bit_cnt <= 4'd0;
		done <= 1'b0;
	end
	else if (state && sample_flag) begin
		bit_cnt <= bit_cnt + 1'b1;
		if (bit_cnt == 4'd9) begin
			state <= 1'b0;
			done <= 1'b1;
		end
		else begin 
			done <= 1'b0;
		end
	end
end

//------------------------------------------------------------
//------------------------ UART ------------------------------
//------------------------------------------------------------
// UART reception logic

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		rx_data <= 8'b0;
	end
	else if (state && sample_flag) begin
		case (bit_cnt)
			4'd1: rx_data[0] <= rs232_sync[2];
			4'd2: rx_data[1] <= rs232_sync[2];
			4'd3: rx_data[2] <= rs232_sync[2];
			4'd4: rx_data[3] <= rs232_sync[2];
			4'd5: rx_data[4] <= rs232_sync[2];
			4'd6: rx_data[5] <= rs232_sync[2];
			4'd7: rx_data[6] <= rs232_sync[2];
			4'd8: rx_data[7] <= rs232_sync[2];
			default: rx_data <= rx_data;
		endcase
	end
end

//------------------------------------------------------------
//------------------------------------------------------------

endmodule	// salsa_rx