/*
##################################################################
Module Number 8			
Module Name: salsa_registers 				
Author: Nisan Moshe Shlomov 			
final project 						
Date: 23.12.2024 					
Description:
	description and implementation of salsa control, status,
	and data registers.
##################################################################
*/
//`include "3.Defines_file/salsa_defines.def"
`include "../3.Defines_file/salsa_defines.vh"

`default_nettype none

module salsa_registers #(
	// registers default parameters
	parameter ADDR_WIDTH = `ADDR_WIDTH_REGS)
	(
	// general registers IF
	input wire		clk,
	input wire		rst_n,
	
	input wire					salsa_regs_wr1_rd0,
	input wire					salsa_regs_hit,
	input wire [3:0]			salsa_regs_byte_en,
	input wire [31:0]			salsa_regs_wdata,
	input wire [ADDR_WIDTH-1:0]	salsa_regs_addr,
	
	output reg [31:0]			salsa_regs_rdata,
	
	// cipher
	input wire [511:0]			salsa_cipher_text,
	// hashing 
	input wire [511:0]			salsa_hashing_text,
	input wire					hash_done_recieved, // pulse from hash_func_wrapper to sticky
	output wire					start_hashing,		// pulse to hash_func_wrapper
	output reg					hash_done_sticky,	// clear by writing 1
	// control
	output wire [1:0]			salsa_round_select,
	output wire 				key_select,
	// xor_valid & start
	output wire					start_xor,
	input wire					xor_valid_recieved,	// pulse to sticky
	output reg 					xor_valid_sticky,	// clear by writing 1
	// key_in
	output wire [255:0] 		salsa_key_in,
	// nonce
	output wire [63:0]			salsa_two_nonce_word,
	// counter
	output wire [63:0]			salsa_two_counter_word,
	// plain
	output wire [511:0]			salsa_plain_text
);

//---------------------------------------------------------------------------------------------

/*------------------------ CONTROL Regs --------------------------
----------------------- 1 dw control regs ------------------------
------------------------------------------------------------------
*/

logic [31:0]	salsa_control_reg;

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_control_reg <= 32'b0;
	end
	else begin
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_CONTROL_REG))) begin
			if (salsa_regs_byte_en[0]) salsa_control_reg[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_control_reg[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_control_reg[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_control_reg[31:24] <= salsa_regs_wdata[31:24];
		end
		else begin // RW/V fields
			salsa_control_reg[8] <= 1'b0;
			salsa_control_reg[16] <= 1'b0;
		end
	end
end

// field name assigns:
// byte 0 (7-0)
assign salsa_round_select[1:0] = salsa_control_reg[1:0];
assign key_select = salsa_control_reg[2];
// byte 1 (15-8)
assign start_hashing = salsa_control_reg[8];
// byte 2 (23-16)
assign start_xor = salsa_control_reg[16];


/*------------------------ STATUS Reg --------------------------
----------------------- 1 dw status reg ------------------------
--------------------------- RW/1C/V ----------------------------
*/

logic [31:0]	salsa_status_reg;
logic 			clear_xor_valid;
logic			clear_hash_done;

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_status_reg <= 32'b0;
	end
	else begin
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_STATUS_REG))) begin
			if (salsa_regs_byte_en[0]) salsa_status_reg[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_status_reg[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_status_reg[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_status_reg[31:24] <= salsa_regs_wdata[31:24];
		end
	end
end

assign clear_hash_done = salsa_status_reg[0];
assign clear_xor_valid = salsa_status_reg[1];

// hash_done_sticky
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		hash_done_sticky <= 1'b0;
	end
	else if (hash_done_recieved) begin
		hash_done_sticky <= 1'b1;
	end
	else if (clear_hash_done) begin
		hash_done_sticky <= 1'b0;
	end
end

// xor_valid_sticky
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		xor_valid_sticky <= 1'b0;
	end
	else if (xor_valid_recieved) begin
		xor_valid_sticky <= 1'b1;
	end
	else if (clear_xor_valid) begin
		xor_valid_sticky <= 1'b0;
	end
end

//---------------------------------------------------------------------------------------------

/*------------------------ RW Registers --------------------------
---------------- plain text & key_in & nonce ---------------------
*/
/* ---------------------------------------------------------------
--------------------- SALSA_PLAIN_TEXT_REGS ----------------------
------------------------------------------------------------------
-- 16 RW dw - the plain text input , the messege for encryption --
------------------------------------------------------------------
*/
// internal salsa_plain_text_regs 16 dw 

logic [31:0]	salsa_plain_text_regs_0;
logic [31:0]	salsa_plain_text_regs_1;
logic [31:0]	salsa_plain_text_regs_2;
logic [31:0]	salsa_plain_text_regs_3;
logic [31:0]	salsa_plain_text_regs_4;
logic [31:0]	salsa_plain_text_regs_5;
logic [31:0]	salsa_plain_text_regs_6;
logic [31:0]	salsa_plain_text_regs_7;
logic [31:0]	salsa_plain_text_regs_8;
logic [31:0]	salsa_plain_text_regs_9;
logic [31:0]	salsa_plain_text_regs_10;
logic [31:0]	salsa_plain_text_regs_11;
logic [31:0]	salsa_plain_text_regs_12;
logic [31:0]	salsa_plain_text_regs_13;
logic [31:0]	salsa_plain_text_regs_14;
logic [31:0]	salsa_plain_text_regs_15;

//------------- the writing process ---------------- 

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_plain_text_regs_0[31:0] <= 32'b0;
		salsa_plain_text_regs_1[31:0] <= 32'b0;
		salsa_plain_text_regs_2[31:0] <= 32'b0;
		salsa_plain_text_regs_3[31:0] <= 32'b0;
		salsa_plain_text_regs_3[31:0] <= 32'b0;
		salsa_plain_text_regs_4[31:0] <= 32'b0;
		salsa_plain_text_regs_5[31:0] <= 32'b0;
		salsa_plain_text_regs_6[31:0] <= 32'b0;
		salsa_plain_text_regs_7[31:0] <= 32'b0;
		salsa_plain_text_regs_8[31:0] <= 32'b0;
		salsa_plain_text_regs_9[31:0] <= 32'b0;
		salsa_plain_text_regs_10[31:0] <= 32'b0;
		salsa_plain_text_regs_11[31:0] <= 32'b0;
		salsa_plain_text_regs_12[31:0] <= 32'b0;
		salsa_plain_text_regs_13[31:0] <= 32'b0;
		salsa_plain_text_regs_14[31:0] <= 32'b0;
		salsa_plain_text_regs_15[31:0] <= 32'b0;
	end
	else begin 
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_0))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_0[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_0[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_0[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_0[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_1))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_1[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_1[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_1[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_1[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_2))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_2[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_2[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_2[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_2[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_3))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_3[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_3[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_3[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_3[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_4))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_4[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_4[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_4[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_4[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_5))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_5[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_5[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_5[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_5[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_6))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_6[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_6[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_6[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_6[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_7))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_7[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_7[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_7[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_7[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_8))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_8[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_8[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_8[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_8[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_9))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_9[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_9[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_9[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_9[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_10))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_10[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_10[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_10[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_10[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_11))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_11[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_11[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_11[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_11[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_12))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_12[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_12[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_12[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_12[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_13))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_13[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_13[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_13[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_13[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_14))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_14[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_14[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_14[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_14[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_PLAIN_TEXT_REGS_15))) begin
			if (salsa_regs_byte_en[0]) salsa_plain_text_regs_15[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_plain_text_regs_15[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_plain_text_regs_15[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_plain_text_regs_15[31:24] <= salsa_regs_wdata[31:24];
		end
	end
end

// salsa_plain_text output assign
assign salsa_plain_text[511:0] = {salsa_plain_text_regs_15[31:0],salsa_plain_text_regs_14[31:0],salsa_plain_text_regs_13[31:0],salsa_plain_text_regs_12[31:0],
									salsa_plain_text_regs_11[31:0],salsa_plain_text_regs_10[31:0],salsa_plain_text_regs_9[31:0],salsa_plain_text_regs_8[31:0],
									salsa_plain_text_regs_7[31:0],salsa_plain_text_regs_6[31:0],salsa_plain_text_regs_5[31:0],salsa_plain_text_regs_4[31:0],
									salsa_plain_text_regs_3[31:0],salsa_plain_text_regs_2[31:0],salsa_plain_text_regs_1[31:0],salsa_plain_text_regs_0[31:0]};

//---------------------------------------------------------------------------------------------

/* ---------------------------------------------------------------
--------------------- SALSA_KEY_IN -------------------------------
------------------------------------------------------------------
------------ 8 RW dw - the key input , 256 bits ------------------
------------------------------------------------------------------
*/

// internal salsa_key_in 8 dw 
logic [31:0]	salsa_key_in_0;
logic [31:0]	salsa_key_in_1;
logic [31:0]	salsa_key_in_2;
logic [31:0]	salsa_key_in_3;
logic [31:0]	salsa_key_in_4;
logic [31:0]	salsa_key_in_5;
logic [31:0]	salsa_key_in_6;
logic [31:0]	salsa_key_in_7;

//------------- the writing process ----------------

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_key_in_0[31:0] <= 32'b0;
		salsa_key_in_1[31:0] <= 32'b0;
		salsa_key_in_2[31:0] <= 32'b0;
		salsa_key_in_3[31:0] <= 32'b0;
		salsa_key_in_4[31:0] <= 32'b0;
		salsa_key_in_5[31:0] <= 32'b0;
		salsa_key_in_6[31:0] <= 32'b0;
		salsa_key_in_7[31:0] <= 32'b0;
	end
	else begin 
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_KEY_IN_0))) begin
			if (salsa_regs_byte_en[0]) salsa_key_in_0[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_key_in_0[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_key_in_0[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_key_in_0[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_KEY_IN_1))) begin
			if (salsa_regs_byte_en[0]) salsa_key_in_1[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_key_in_1[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_key_in_1[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_key_in_1[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_KEY_IN_2))) begin
			if (salsa_regs_byte_en[0]) salsa_key_in_2[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_key_in_2[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_key_in_2[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_key_in_2[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_KEY_IN_3))) begin
			if (salsa_regs_byte_en[0]) salsa_key_in_3[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_key_in_3[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_key_in_3[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_key_in_3[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_KEY_IN_4))) begin
			if (salsa_regs_byte_en[0]) salsa_key_in_4[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_key_in_4[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_key_in_4[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_key_in_4[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_KEY_IN_5))) begin
			if (salsa_regs_byte_en[0]) salsa_key_in_5[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_key_in_5[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_key_in_5[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_key_in_5[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_KEY_IN_6))) begin
			if (salsa_regs_byte_en[0]) salsa_key_in_6[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_key_in_6[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_key_in_6[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_key_in_6[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_KEY_IN_7))) begin
			if (salsa_regs_byte_en[0]) salsa_key_in_7[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_key_in_7[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_key_in_7[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_key_in_7[31:24] <= salsa_regs_wdata[31:24];
		end
	end
end

// salsa_key_in output assign
assign salsa_key_in[255:0] = {salsa_key_in_7[31:0],salsa_key_in_6[31:0],salsa_key_in_5[31:0],salsa_key_in_4[31:0],
								salsa_key_in_3[31:0],salsa_key_in_2[31:0],salsa_key_in_1[31:0],salsa_key_in_0[31:0]};

//---------------------------------------------------------------------------------------------

/* ---------------------------------------------------------------
--------------------- SALSA_NONCE_IN ------------------------------
------------------------------------------------------------------
------------ 2 RW dw - the 2 nonce word , 64 bits ----------------
------------------------------------------------------------------
*/

// internal salsa_nonce_in 2 dw 
logic [31:0]	salsa_nonce_in_0;
logic [31:0]	salsa_nonce_in_1;

//------------- the writing process ----------------

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_nonce_in_0[31:0] <= 32'b0;
		salsa_nonce_in_1[31:0] <= 32'b0;
	end
	else begin 
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_NONCE_IN_0))) begin
			if (salsa_regs_byte_en[0]) salsa_nonce_in_0[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_nonce_in_0[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_nonce_in_0[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_nonce_in_0[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_NONCE_IN_1))) begin
			if (salsa_regs_byte_en[0]) salsa_nonce_in_1[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_nonce_in_1[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_nonce_in_1[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_nonce_in_1[31:24] <= salsa_regs_wdata[31:24];
		end
	end
end

// salsa_two_nonce_word output assign
assign salsa_two_nonce_word[63:0] = {salsa_nonce_in_1[31:0], salsa_nonce_in_0[31:0]};


/* ---------------------------------------------------------------
--------------------- SALSA_COUNTER_IN ---------------------------
------------------------------------------------------------------
------------ 2 RW dw - the 2 counter word , 64 bits --------------
------------------------------------------------------------------
*/

// internal salsa_counter_in 2 dw 
logic [31:0]	salsa_counter_in_0;
logic [31:0]	salsa_counter_in_1;

//------------- the writing process ----------------

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_counter_in_0[31:0] <= 32'b0;
		salsa_counter_in_1[31:0] <= 32'b0;
	end
	else begin 
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_COUNTER_IN_0))) begin
			if (salsa_regs_byte_en[0]) salsa_counter_in_0[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_counter_in_0[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_counter_in_0[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_counter_in_0[31:24] <= salsa_regs_wdata[31:24];
		end
		if (salsa_regs_wr1_rd0 & (salsa_regs_hit & (salsa_regs_addr[ADDR_WIDTH-1:0] == `SALSA_COUNTER_IN_1))) begin
			if (salsa_regs_byte_en[0]) salsa_counter_in_1[7:0] <= salsa_regs_wdata[7:0];
			if (salsa_regs_byte_en[1]) salsa_counter_in_1[15:8] <= salsa_regs_wdata[15:8];
			if (salsa_regs_byte_en[2]) salsa_counter_in_1[23:16] <= salsa_regs_wdata[23:16];
			if (salsa_regs_byte_en[3]) salsa_counter_in_1[31:24] <= salsa_regs_wdata[31:24];
		end
	end
end

// salsa_two_counter_word output assign
assign salsa_two_counter_word[63:0] = {salsa_counter_in_1[31:0], salsa_counter_in_0[31:0]};




//---------------------------------------------------------------------------------------------
/*---------------------------------------------------------------------------------------------
------------------------ RO/V Registers -------------------------------------------------------
------------------- hashing & cipher text -----------------------------------------------------
*/
/*----------------------------------------------------------------
--------------------- SALSA_HASHING_TEXT -------------------------
------------------------------------------------------------------
--------------- 16 RO/V dw - the hashing resualt -----------------
------------------------------------------------------------------
*/

logic [511:0] salsa_hashing_text_ff;

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_hashing_text_ff <= 512'b0;
	end
	else begin
		if (hash_done_recieved) begin
			salsa_hashing_text_ff <= salsa_hashing_text;
		end
	end
end

// internal dw:
logic [31:0] salsa_hashing_text_0;
logic [31:0] salsa_hashing_text_1;
logic [31:0] salsa_hashing_text_2;
logic [31:0] salsa_hashing_text_3;
logic [31:0] salsa_hashing_text_4;
logic [31:0] salsa_hashing_text_5;
logic [31:0] salsa_hashing_text_6;
logic [31:0] salsa_hashing_text_7;
logic [31:0] salsa_hashing_text_8;
logic [31:0] salsa_hashing_text_9;
logic [31:0] salsa_hashing_text_10;
logic [31:0] salsa_hashing_text_11;
logic [31:0] salsa_hashing_text_12;
logic [31:0] salsa_hashing_text_13;
logic [31:0] salsa_hashing_text_14;
logic [31:0] salsa_hashing_text_15;

// assigns: 
assign salsa_hashing_text_0[31:0] = salsa_hashing_text_ff[31:0];
assign salsa_hashing_text_1[31:0] = salsa_hashing_text_ff[63:32];
assign salsa_hashing_text_2[31:0] = salsa_hashing_text_ff[95:64];
assign salsa_hashing_text_3[31:0] = salsa_hashing_text_ff[127:96];
assign salsa_hashing_text_4[31:0] = salsa_hashing_text_ff[159:128];
assign salsa_hashing_text_5[31:0] = salsa_hashing_text_ff[191:160];
assign salsa_hashing_text_6[31:0] = salsa_hashing_text_ff[223:192];
assign salsa_hashing_text_7[31:0] = salsa_hashing_text_ff[255:224];
assign salsa_hashing_text_8[31:0] = salsa_hashing_text_ff[287:256];
assign salsa_hashing_text_9[31:0] = salsa_hashing_text_ff[319:288];
assign salsa_hashing_text_10[31:0] = salsa_hashing_text_ff[351:320];
assign salsa_hashing_text_11[31:0] = salsa_hashing_text_ff[383:352];
assign salsa_hashing_text_12[31:0] = salsa_hashing_text_ff[415:384];
assign salsa_hashing_text_13[31:0] = salsa_hashing_text_ff[447:416];
assign salsa_hashing_text_14[31:0] = salsa_hashing_text_ff[479:448];
assign salsa_hashing_text_15[31:0] = salsa_hashing_text_ff[511:480];

/*----------------------------------------------------------------
--------------------- SALSA_CIPHER_TEXT --------------------------
------------------------------------------------------------------
--------------- 16 RO/V dw - the final cipher text ---------------
------------------------------------------------------------------
*/

// internal dw:
logic [31:0] salsa_cipher_text_0;
logic [31:0] salsa_cipher_text_1;
logic [31:0] salsa_cipher_text_2;
logic [31:0] salsa_cipher_text_3;
logic [31:0] salsa_cipher_text_4;
logic [31:0] salsa_cipher_text_5;
logic [31:0] salsa_cipher_text_6;
logic [31:0] salsa_cipher_text_7;
logic [31:0] salsa_cipher_text_8;
logic [31:0] salsa_cipher_text_9;
logic [31:0] salsa_cipher_text_10;
logic [31:0] salsa_cipher_text_11;
logic [31:0] salsa_cipher_text_12;
logic [31:0] salsa_cipher_text_13;
logic [31:0] salsa_cipher_text_14;
logic [31:0] salsa_cipher_text_15;

// assigns: 
assign salsa_cipher_text_0[31:0] = salsa_cipher_text[31:0];
assign salsa_cipher_text_1[31:0] = salsa_cipher_text[63:32];
assign salsa_cipher_text_2[31:0] = salsa_cipher_text[95:64];
assign salsa_cipher_text_3[31:0] = salsa_cipher_text[127:96];
assign salsa_cipher_text_4[31:0] = salsa_cipher_text[159:128];
assign salsa_cipher_text_5[31:0] = salsa_cipher_text[191:160];
assign salsa_cipher_text_6[31:0] = salsa_cipher_text[223:192];
assign salsa_cipher_text_7[31:0] = salsa_cipher_text[255:224];
assign salsa_cipher_text_8[31:0] = salsa_cipher_text[287:256];
assign salsa_cipher_text_9[31:0] = salsa_cipher_text[319:288];
assign salsa_cipher_text_10[31:0] = salsa_cipher_text[351:320];
assign salsa_cipher_text_11[31:0] = salsa_cipher_text[383:352];
assign salsa_cipher_text_12[31:0] = salsa_cipher_text[415:384];
assign salsa_cipher_text_13[31:0] = salsa_cipher_text[447:416];
assign salsa_cipher_text_14[31:0] = salsa_cipher_text[479:448];
assign salsa_cipher_text_15[31:0] = salsa_cipher_text[511:480];

//---------------------------------------------------------------------------------------------

/*---------------------------------------------------------------------------------------------
-------------------------------------------- READ MUX -----------------------------------------
-----------------------------------------------------------------------------------------------*/

always @(*) begin
	case (salsa_regs_addr[ADDR_WIDTH-1:0])
	
		`SALSA_CONTROL_REG:		salsa_regs_rdata[31:0] = {15'b0,start_xor,7'b0,start_hashing,5'b0
															,key_select, salsa_round_select[1:0]};
		`SALSA_STATUS_REG:		salsa_regs_rdata[31:0] = {29'b0, xor_valid_sticky,hash_done_sticky};
		
		`SALSA_PLAIN_TEXT_REGS_0:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_0[31:0];
		`SALSA_PLAIN_TEXT_REGS_1:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_1[31:0];
		`SALSA_PLAIN_TEXT_REGS_2:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_2[31:0];
		`SALSA_PLAIN_TEXT_REGS_3:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_3[31:0];
		`SALSA_PLAIN_TEXT_REGS_4:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_4[31:0];
		`SALSA_PLAIN_TEXT_REGS_5:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_5[31:0];
		`SALSA_PLAIN_TEXT_REGS_6:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_6[31:0];
		`SALSA_PLAIN_TEXT_REGS_7:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_7[31:0];
		`SALSA_PLAIN_TEXT_REGS_8:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_8[31:0];
		`SALSA_PLAIN_TEXT_REGS_9:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_9[31:0];
		`SALSA_PLAIN_TEXT_REGS_10:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_10[31:0];
		`SALSA_PLAIN_TEXT_REGS_11:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_11[31:0];
		`SALSA_PLAIN_TEXT_REGS_12:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_12[31:0];
		`SALSA_PLAIN_TEXT_REGS_13:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_13[31:0];
		`SALSA_PLAIN_TEXT_REGS_14:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_14[31:0];
		`SALSA_PLAIN_TEXT_REGS_15:	salsa_regs_rdata[31:0] = salsa_plain_text_regs_15[31:0];

		
		`SALSA_KEY_IN_0: 		salsa_regs_rdata[31:0] = salsa_key_in_0[31:0];
		`SALSA_KEY_IN_1: 		salsa_regs_rdata[31:0] = salsa_key_in_1[31:0];
		`SALSA_KEY_IN_2: 		salsa_regs_rdata[31:0] = salsa_key_in_2[31:0];
		`SALSA_KEY_IN_3: 		salsa_regs_rdata[31:0] = salsa_key_in_3[31:0];
		`SALSA_KEY_IN_4: 		salsa_regs_rdata[31:0] = salsa_key_in_4[31:0];
		`SALSA_KEY_IN_5: 		salsa_regs_rdata[31:0] = salsa_key_in_5[31:0];
		`SALSA_KEY_IN_6: 		salsa_regs_rdata[31:0] = salsa_key_in_6[31:0];
		`SALSA_KEY_IN_7: 		salsa_regs_rdata[31:0] = salsa_key_in_7[31:0];


		`SALSA_NONCE_IN_0:		salsa_regs_rdata[31:0] = salsa_nonce_in_0[31:0];
		`SALSA_NONCE_IN_1:		salsa_regs_rdata[31:0] = salsa_nonce_in_1[31:0];
		
		`SALSA_COUNTER_IN_0:		salsa_regs_rdata[31:0] = salsa_counter_in_0[31:0];
		`SALSA_COUNTER_IN_1:		salsa_regs_rdata[31:0] = salsa_counter_in_1[31:0];


		`SALSA_HASHING_TEXT_0:	salsa_regs_rdata[31:0] = salsa_hashing_text_0[31:0];
		`SALSA_HASHING_TEXT_1:	salsa_regs_rdata[31:0] = salsa_hashing_text_1[31:0];
		`SALSA_HASHING_TEXT_2:	salsa_regs_rdata[31:0] = salsa_hashing_text_2[31:0];
		`SALSA_HASHING_TEXT_3:	salsa_regs_rdata[31:0] = salsa_hashing_text_3[31:0];
		`SALSA_HASHING_TEXT_4:	salsa_regs_rdata[31:0] = salsa_hashing_text_4[31:0];
		`SALSA_HASHING_TEXT_5:	salsa_regs_rdata[31:0] = salsa_hashing_text_5[31:0];
		`SALSA_HASHING_TEXT_6:	salsa_regs_rdata[31:0] = salsa_hashing_text_6[31:0];
		`SALSA_HASHING_TEXT_7:	salsa_regs_rdata[31:0] = salsa_hashing_text_7[31:0];
		`SALSA_HASHING_TEXT_8:	salsa_regs_rdata[31:0] = salsa_hashing_text_8[31:0];
		`SALSA_HASHING_TEXT_9:	salsa_regs_rdata[31:0] = salsa_hashing_text_9[31:0];
		`SALSA_HASHING_TEXT_10:	salsa_regs_rdata[31:0] = salsa_hashing_text_10[31:0];
		`SALSA_HASHING_TEXT_11:	salsa_regs_rdata[31:0] = salsa_hashing_text_11[31:0];
		`SALSA_HASHING_TEXT_12:	salsa_regs_rdata[31:0] = salsa_hashing_text_12[31:0];
		`SALSA_HASHING_TEXT_13:	salsa_regs_rdata[31:0] = salsa_hashing_text_13[31:0];
		`SALSA_HASHING_TEXT_14:	salsa_regs_rdata[31:0] = salsa_hashing_text_14[31:0];
		`SALSA_HASHING_TEXT_15:	salsa_regs_rdata[31:0] = salsa_hashing_text_15[31:0];


		`SALSA_CIPHER_TEXT_0:	salsa_regs_rdata[31:0] = salsa_cipher_text_0[31:0];
		`SALSA_CIPHER_TEXT_1:	salsa_regs_rdata[31:0] = salsa_cipher_text_1[31:0];
		`SALSA_CIPHER_TEXT_2:	salsa_regs_rdata[31:0] = salsa_cipher_text_2[31:0];
		`SALSA_CIPHER_TEXT_3:	salsa_regs_rdata[31:0] = salsa_cipher_text_3[31:0];
		`SALSA_CIPHER_TEXT_4:	salsa_regs_rdata[31:0] = salsa_cipher_text_4[31:0];
		`SALSA_CIPHER_TEXT_5:	salsa_regs_rdata[31:0] = salsa_cipher_text_5[31:0];
		`SALSA_CIPHER_TEXT_6:	salsa_regs_rdata[31:0] = salsa_cipher_text_6[31:0];
		`SALSA_CIPHER_TEXT_7:	salsa_regs_rdata[31:0] = salsa_cipher_text_7[31:0];
		`SALSA_CIPHER_TEXT_8:	salsa_regs_rdata[31:0] = salsa_cipher_text_8[31:0];
		`SALSA_CIPHER_TEXT_9:	salsa_regs_rdata[31:0] = salsa_cipher_text_9[31:0];
		`SALSA_CIPHER_TEXT_10:	salsa_regs_rdata[31:0] = salsa_cipher_text_10[31:0];
		`SALSA_CIPHER_TEXT_11:	salsa_regs_rdata[31:0] = salsa_cipher_text_11[31:0];
		`SALSA_CIPHER_TEXT_12:	salsa_regs_rdata[31:0] = salsa_cipher_text_12[31:0];
		`SALSA_CIPHER_TEXT_13:	salsa_regs_rdata[31:0] = salsa_cipher_text_13[31:0];
		`SALSA_CIPHER_TEXT_14:	salsa_regs_rdata[31:0] = salsa_cipher_text_14[31:0];
		`SALSA_CIPHER_TEXT_15:	salsa_regs_rdata[31:0] = salsa_cipher_text_15[31:0];
		
		default: salsa_regs_rdata[31:0] = 32'b0;
	endcase
end

//----------------------------------------------------------------------------------------------------

endmodule		// end salsa_registers module