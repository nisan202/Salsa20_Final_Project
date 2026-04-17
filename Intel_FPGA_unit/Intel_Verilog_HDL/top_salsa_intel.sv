/*
##################################################################			
Module Name: top_salsa_intel			
Author: Nisan Moshe Shlomov		
final project 						
Date: 14.11.2025 					
Description:
	
##################################################################	
*/

//`include "3.Defines_file/salsa_defines.def"
`include "../3.Defines_file/salsa_defines.vh"

`default_nettype none

module top_salsa_intel #(
	parameter ADDR_WIDTH = `ADDR_WIDTH_REGS)
	(
	// Inputs
	input wire			salsa_top_50mhz_clk,
	input wire			salsa_top_rst_n,
	input wire			rs232_rx_top,  // rx top
	
	// Outputs 
	output reg			rs_232_tx_top, // tx top
	output reg			hash_done_sticky_top,	// hash_done_sticky go to LD0 on MAX 10
	output reg			xor_valid_sticky_top,	// xor_valid_sticky go to LD1 on MAX 10
	
	output wire 		dp_set_top,
	output reg [6:0]	seven_seg_top
);

// Internal Signals

logic [3:0]				state2ssd_top;

logic 					hash_done_top;			// out from hashing_wrap --> in to regs
logic [511:0]			hashing_text_top;		// out from hashing_wrap --> in to regs & xor regs 
logic [31:0]			reg_rdata_top;			// out from regs --> in to salsa_fsm
logic [1:0] 			round_select_top;		// out from regs --> in to hashing_wrap
logic					key_select_top;			// out from regs --> in to hashing_wrap
logic [255:0] 			key_in_top;				// out from regs --> in to hashing_wrap
logic [63:0] 			two_nonce_word_top;		// out from regs --> in to hashing_wrap
logic [63:0]			two_counter_word_top; 	// out from regs --> in to hashing_wrap
logic [511:0]			plain_text_top;			// out from regs --> in to xor regs
logic					start_hashing_top;		// out from regs --> in to hashing_wrap
logic					start_xor_top;			// out from regs --> in to xor regs
logic [511:0]			cipher_text_top;		// out from xor regs --> in to regs
logic					xor_is_valid_top;		// out from xor regs --> in to regs
logic [7:0] 			rx_data_top;			// out from salsa_uart_rx --> in to salsa_fsm
logic 					rx_done_top;			// out from salsa_uart_rx --> in to salsa_fsm
logic 					tx_done_top;			// out from salsa_uart_tx --> in to salsa_fsm
logic 					reg_wr1_rd0_top;		// out from salsa_fsm --> in to regs
logic					reg_hit_top;			// out from salsa_fsm --> in to regs
logic [3:0]				reg_byte_en_top;		// out from salsa_fsm --> in to regs
logic [31:0]			reg_wdata_top;			// out from salsa_fsm --> in to regs
logic [ADDR_WIDTH-1:0]	reg_addr_top;			// out from salsa_fsm --> in to regs
logic					tx_start_top;			// out from salsa_fsm --> in to salsa_uart_tx
logic [7:0]				tx_data_top;			// out from salsa_fsm --> in to salsa_uart_tx


//--------------------- insatances --------------------------------

// instance of salsa_hash_interative_wrapper

salsa_hash_interative_wrapper u_salsa_hash_interative_wrapper (
// Inputs
	.clk					(salsa_top_50mhz_clk),
	.rst_n					(salsa_top_rst_n),
	.key_select				(key_select_top),
	.salsa_round_select		(round_select_top[1:0]),
	.two_nonce_word			(two_nonce_word_top[63:0]),
	.key_in					(key_in_top[255:0]),
	.two_counter_word		(two_counter_word_top[63:0]),
	.start_hashing			(start_hashing_top),	// pulse input from salsa regs
// Outputs
	.hash_done_to_regs		(hash_done_top),	// pulse output to salsa_regs
	.salsa_hashing_text		(hashing_text_top[511:0])
);
// -----------------------------------------
// instance of salsa_registers

salsa_registers u_salsa_registers(
// Inputs
	.clk						(salsa_top_50mhz_clk),	// general regs IF
	.rst_n						(salsa_top_rst_n),	// general regs IF
	.salsa_regs_wr1_rd0			(reg_wr1_rd0_top),	// general regs IF
	.salsa_regs_hit				(reg_hit_top),		// general regs IF
	.salsa_regs_byte_en			(reg_byte_en_top[3:0]),	// general regs IF
	.salsa_regs_wdata			(reg_wdata_top[31:0]),	// general regs IF
	.salsa_regs_addr			(reg_addr_top[ADDR_WIDTH-1:0]), // general regs IF
	.salsa_cipher_text			(cipher_text_top[511:0]),	// cipher input
	.salsa_hashing_text			(hashing_text_top[511:0]),	// hashing input
	.hash_done_recieved			(hash_done_top),	// hash_done IF
	.xor_valid_recieved			(xor_is_valid_top),	// Xor IF	
// Outputs salsa regs 
	.salsa_regs_rdata			(reg_rdata_top[31:0]),		// general regs IF
	.salsa_round_select			(round_select_top[1:0]),	// control output
	.key_select					(key_select_top),			// control output
	.salsa_key_in				(key_in_top[255:0]),		// key_in output
	.salsa_two_nonce_word		(two_nonce_word_top[63:0]),	// nonce output
	.salsa_two_counter_word		(two_counter_word_top[63:0]),// counter output
	.salsa_plain_text			(plain_text_top[511:0]),	// plain output
	.start_hashing				(start_hashing_top),	// hash_done IF & control reg
	.hash_done_sticky			(hash_done_sticky_top),	// hash_done IF
	.start_xor					(start_xor_top),		// Xor IF & control reg
	.xor_valid_sticky			(xor_valid_sticky_top)			// Xor IF
);

// -----------------------------------------
// instance of salsa_xor_regs

salsa_xor_regs u_salsa_xor_regs(
// Inputs
	.clk			(salsa_top_50mhz_clk),
	.rst_n			(salsa_top_rst_n),
	.start_xor	 	(start_xor_top),
	.a				(hashing_text_top[511:0]),
	.b				(plain_text_top[511:0]),
// Outputs
	.axorb			(cipher_text_top[511:0]),
	.xor_is_valid	(xor_is_valid_top)
);

// -----------------------------------------
// instance of salsa_uart_rx
// 14.09.2025 change to salsa_rx
salsa_rx u_salsa_rx(
// Inputs
	.clk		(salsa_top_50mhz_clk),       
    .rst_n		(salsa_top_rst_n),     
    .rs232		(rs232_rx_top),
// Outputs    
    .rx_data	(rx_data_top[7:0]), 
    .done		(rx_done_top)	  	//pulse! - say that the data is valid.     
);

// -----------------------------------------
// instance of salsa_uart_tx

salsa_uart_tx u_salsa_uart_tx(
// Inputs
	.clk		(salsa_top_50mhz_clk),
    .rst_n		(salsa_top_rst_n),
    .start		(tx_start_top),		// pulse to start transmit
    .data		(tx_data_top[7:0]),
// Outputs
    .rs232_tx	(rs_232_tx_top),
    .done		(tx_done_top)		// pulse! - finish the transmition
);

// -----------------------------------------
// instance of salsa_fsm

salsa_fsm u_salsa_fsm(
// Inputs
	.clk						(salsa_top_50mhz_clk),
    .rst_n						(salsa_top_rst_n),
	.salsa_reg2fsm_rdata		(reg_rdata_top[31:0]),
	.rx2fsm_data				(rx_data_top[7:0]),
	.rx2fsm_done				(rx_done_top),
	.tx2fsm_done				(tx_done_top),
// Outputs
	.salsa_fsm2reg_wr1_rd0		(reg_wr1_rd0_top),
	.salsa_fsm2reg_hit			(reg_hit_top),
	.salsa_fsm2reg_byte_en		(reg_byte_en_top[3:0]),
	.salsa_fsm2reg_wdata		(reg_wdata_top[31:0]),
	.salsa_fsm2reg_addr			(reg_addr_top[ADDR_WIDTH-1:0]),
	.fsm2tx_start				(tx_start_top),
    .fsm2tx_data				(tx_data_top[7:0]),
	.state2ssd					(state2ssd_top[3:0])
);

// -----------------------------------------
// instance of hex_to_SSD_Intel

hex_to_SSD_Intel u_hex_to_SSD_Intel(
// Inputs
	.hex_number		(state2ssd_top),
	.dp				(1'b1),
// Outputs
	.dp_set			(dp_set_top),
	.seven_seg		(seven_seg_top)
);

// -----------------------------------------

endmodule		// top_salsa_xilinx 