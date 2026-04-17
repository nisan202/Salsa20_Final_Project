/*
##################################################################
Module Number 13			
Module Name: salsa_fsm			
Author: Nisan Moshe Shlomov		
final project 						
Date: 09.01.2025 - Updated and corrected in: 16.02.2025				
Description:
	
##################################################################	
*/
//`include "3.Defines_file/salsa_defines.def"
`include "../3.Defines_file/salsa_defines.vh"


`default_nettype none

module salsa_fsm #(
	parameter ADDR_WIDTH	= 	`ADDR_WIDTH_REGS,
	parameter HEAD_MESSAGE 	= 	`HEAD_MESSAGE,
	parameter WRITE_CMD		=	`WRITE_CMD,
	parameter READ_CMD		=	`READ_CMD)
	(
	input wire		clk,
	input wire		rst_n,
	
	// IF with 'salsa_registers'
	input wire [31:0]				salsa_reg2fsm_rdata,
	
	output reg						salsa_fsm2reg_wr1_rd0,
	output reg						salsa_fsm2reg_hit,
	output reg 	[3:0]				salsa_fsm2reg_byte_en,
	output reg 	[31:0]				salsa_fsm2reg_wdata,
	output reg 	[ADDR_WIDTH-1:0]	salsa_fsm2reg_addr,
	
	
	// IF with 'salsa_uart_rx'
	input wire [7:0] 		rx2fsm_data,	// 8 bits received
	input wire				rx2fsm_done, 	// pulse! - say that the data is valid.
	
	// IF with 'salsa_uart_tx'
	output reg 				fsm2tx_start,	// pulse! - pulse to start transmit
    output reg [7:0] 		fsm2tx_data,	// 8 bits to transmit
	input wire				tx2fsm_done,	// pulse! - finish the transmition
	
	output wire [3:0]		state2ssd
	
);
// ----------------------------------------------------------------------
// ----------------------------------------------------------------------

/* ##### STATES CODING #####
0. 	IDLE
1.	RECEIVE_ADDRESS
2.	RECEIVE_COMMAND
3.	RECEIVE_DATA_TO_REGS
4.	BYTE_ENABLE
5.  HIT_SAMPLE
6.  WAIT_CYCLE
7.  BYTE_COUNTER
8.  TX_START_PULSE
9.	READ_LOOP
*/

typedef enum logic [3:0] {
	IDLE				   = 4'd0,
	RECEIVE_ADDRESS	 	   = 4'd1,
	RECEIVE_COMMAND	 	   = 4'd2,
	RECEIVE_DATA_TO_REGS   = 4'd3,
	BYTE_ENABLE			   = 4'd4,
	HIT_SAMPLE			   = 4'd5,
	WAIT_CYCLE			   = 4'd6,
	BYTE_COUNTER  		   = 4'd7,
	TX_START_PULSE		   = 4'd8, 
	READ_LOOP              = 4'd9
	
} states;

states salsa_fsm_ps, salsa_fsm_ns, fsm_prev_state;

/* ---------------------------------------------------------------------------
------------------------ INTERNAL SIGNALS ------------------------------------
----------------------------------------------------------------------------*/

reg 		addr_sample;
reg			byte_sample;
reg 		ben_sample;
reg 		fsm_hit_sample;
reg 		inc_byte_counter;
reg 		rst_byte_counter;
reg [1:0]	byte_counter;
reg 		tx_start_sample;
reg 		write_next;
reg			read_next;
reg 		prev_rx_done;
wire		rx_done_posedge;

/* ---------------------------------------------------------------------------
---------------------- SALSA FINITE-STATE MACHINE ----------------------------
------------------------------------------------------------------------------
"unique case" = A statement that all cases cover
all possibilities and there are not un-addressed situations.
*/

always @(*) begin
	// initial statment
	addr_sample      = 1'b0;
	byte_sample	 	 = 1'b0;
	ben_sample		 = 1'b0;
	fsm_hit_sample   = 1'b0;
	inc_byte_counter = 1'b0;
	rst_byte_counter = 1'b0;
	tx_start_sample  = 1'b0;
	write_next	 	 = 1'b0;
	read_next		 = 1'b0;
	
	salsa_fsm_ns = salsa_fsm_ps;
	
	unique case (salsa_fsm_ps)
		IDLE: begin
			if (rx_done_posedge && (rx2fsm_data[7:0] == `HEAD_MESSAGE)) begin
				salsa_fsm_ns = RECEIVE_ADDRESS;
			end
			else begin
				salsa_fsm_ns = IDLE;
			end
		end
		
		RECEIVE_ADDRESS: begin
			if (rx_done_posedge) begin
				addr_sample = 1'b1;
				salsa_fsm_ns = RECEIVE_COMMAND;
			end
			else begin
				salsa_fsm_ns = RECEIVE_ADDRESS;
			end
		end
		
		RECEIVE_COMMAND: begin
			if (rx_done_posedge) begin
				if (rx2fsm_data[1:0] == `WRITE_CMD) begin
					write_next = 1'b1;
					salsa_fsm_ns = RECEIVE_DATA_TO_REGS;
				end
				else if (rx2fsm_data[1:0] == `READ_CMD) begin
					read_next = 1'b1;
					salsa_fsm_ns = TX_START_PULSE;
				end
				else begin
					salsa_fsm_ns = RECEIVE_COMMAND;
				end
			end
		end
		
		RECEIVE_DATA_TO_REGS: begin
			if (rx_done_posedge) begin
				byte_sample = 1'b1;
				salsa_fsm_ns = BYTE_ENABLE;
			end	
		end
		
		BYTE_ENABLE: begin
			ben_sample = 1'b1;
			salsa_fsm_ns = HIT_SAMPLE;
		end
		
		HIT_SAMPLE: begin
			fsm_hit_sample = 1'b1;
			salsa_fsm_ns = WAIT_CYCLE;
		end
		
		WAIT_CYCLE: begin
			unique case (fsm_prev_state)
				HIT_SAMPLE: begin
					// prev = HIT -> ps = WAIT -> ns = BYTE_COUNTER
					salsa_fsm_ns = BYTE_COUNTER;
				end
				TX_START_PULSE: begin
					// prev = TX_START_PULSE -> ps = WAIT -> ns = READ_LOOP
					salsa_fsm_ns = READ_LOOP;
				end
				READ_LOOP: begin
					// prev = READ -> ps = WAIT -> ns = TX_START_PULSE
					salsa_fsm_ns = TX_START_PULSE;
				end
				default: begin
					salsa_fsm_ns = IDLE;
				end
			endcase
		end

		BYTE_COUNTER: begin
			if (byte_counter[1:0] < 2'd3) begin
				inc_byte_counter = 1'b1;
				salsa_fsm_ns = RECEIVE_DATA_TO_REGS;
			end
			else if (byte_counter[1:0] == 2'd3) begin
				rst_byte_counter = 1'b1;
				salsa_fsm_ns = IDLE;
			end
		end
		
		TX_START_PULSE: begin
			tx_start_sample = 1'b1;
			salsa_fsm_ns = WAIT_CYCLE;
		end

		READ_LOOP: begin
			if (tx2fsm_done) begin
				if (byte_counter[1:0] < 2'd3) begin
					inc_byte_counter = 1'b1;
					salsa_fsm_ns = WAIT_CYCLE;
				end
				else if (byte_counter[1:0] == 2'd3) begin
					rst_byte_counter = 1'b1;
					salsa_fsm_ns = IDLE;
				end
			end
		end
	endcase
end

/* ---------------------------------------------------------------------------
------------------------ STATE TRANSITIONS -----------------------------------
----------------------------------------------------------------------------*/

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_fsm_ps <= IDLE;
	end
	else begin
		salsa_fsm_ps <= salsa_fsm_ns;
	end
end

// ************** state2ssd **************
assign state2ssd[3:0] = salsa_fsm_ps[3:0];

// ************** fsm_prev_state **************
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        fsm_prev_state <= IDLE;
    end
    else if (salsa_fsm_ps != WAIT_CYCLE && salsa_fsm_ns == WAIT_CYCLE) begin
		// Just at the moment of transition to WAIT_CYCLE
        fsm_prev_state <= salsa_fsm_ps;
    end
end

/* ---------------------------------------------------------------------------
------------------------ rx_done_posedge  -----------------------------------
----------------------------------------------------------------------------*/
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		prev_rx_done <= 1'b0;
	end
	else begin
		prev_rx_done <= rx2fsm_done;
	end
end

assign rx_done_posedge = rx2fsm_done & ~prev_rx_done;

/* ---------------------------------------------------------------------------
------------------------ COMMAND SAMPLE ----------------------------------------
----------------------------------------------------------------------------*/
/*
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_fsm2reg_wr1_rd0 <= 1'b0;
	end
	else begin
        if (command_sample) begin
			if (rx2fsm_data[1:0] == `WRITE_CMD) begin	// 8'h01 = write
				salsa_fsm2reg_wr1_rd0 <= 1'b1; 
			end
			else if (rx2fsm_data[1:0] == `READ_CMD) begin // 8'h11 = read
				salsa_fsm2reg_wr1_rd0 <= 1'b0;
			end
        end
	end
end
*/

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_fsm2reg_wr1_rd0 <= 1'b0;
	end
	else begin
        if (write_next) begin
			salsa_fsm2reg_wr1_rd0 <= 1'b1; 
		end
		else if (read_next) begin
			salsa_fsm2reg_wr1_rd0 <= 1'b0;
		end
    end
end


/* ---------------------------------------------------------------------------
------------------------ ADDR SAMPLE ----------------------------------------
----------------------------------------------------------------------------*/
// atantion : I take only 6 bits from rx data - if WIDTH > 8 this always needes to be fix
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_fsm2reg_addr <= {ADDR_WIDTH{1'b0}};
	end
	else begin
		if (addr_sample) begin
			salsa_fsm2reg_addr[ADDR_WIDTH-1:0] <= rx2fsm_data[ADDR_WIDTH-1:0];
		end
	end
end

/* ---------------------------------------------------------------------------
------------------------ BYTE LOOP WRITING -----------------------------------
------------------------------------------------------------------------------
 wdata,byte_en,hit. wr1_rd0 alredy set. 
*/

// salsa_fsm2reg_wdata
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_fsm2reg_wdata[31:0] <= 32'b0;
	end
	else if (byte_sample) begin
		case (byte_counter[1:0]) 
			2'b00: salsa_fsm2reg_wdata[7:0]   <= rx2fsm_data[7:0];	// byte 0 
			2'b01: salsa_fsm2reg_wdata[15:8]  <= rx2fsm_data[7:0];  // byte 1
			2'b10: salsa_fsm2reg_wdata[23:16] <= rx2fsm_data[7:0];  // byte 2
			2'b11: salsa_fsm2reg_wdata[31:24] <= rx2fsm_data[7:0];  // byte 3
		endcase
	end
end

// salsa_fsm2reg_byte_en
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_fsm2reg_byte_en[3:0] <= 4'b0;
	end
	else if (ben_sample) begin
		case (byte_counter[1:0]) 
			2'b00: salsa_fsm2reg_byte_en[3:0] <= 4'b0001;	// 1 --> byte 0
			2'b01: salsa_fsm2reg_byte_en[3:0] <= 4'b0010;   // 2 --> byte 1
			2'b10: salsa_fsm2reg_byte_en[3:0] <= 4'b0100;	// 4 --> byte 2
			2'b11: salsa_fsm2reg_byte_en[3:0] <= 4'b1000;	// 8 --> byte 3
		endcase
	end
end

// salsa_fsm2reg_hit - pulse!
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		salsa_fsm2reg_hit <= 1'b0;
	end
	else if (fsm_hit_sample) begin		
		salsa_fsm2reg_hit <= 1'b1;
	end
	else begin
		salsa_fsm2reg_hit <= 1'b0;
	end
end


/* ---------------------------------------------------------------------------
------------------------ BYTE COUNTER ----------------------------------------
----------------------------------------------------------------------------*/

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		byte_counter[1:0] <= 2'b0;
	end
	else begin
		if (inc_byte_counter) begin
			byte_counter[1:0] <= byte_counter[1:0] + 1;
		end
		else if (rst_byte_counter) begin
			byte_counter[1:0] <= 2'b0;
		end
	end
end

/* ---------------------------------------------------------------------------
------------------------ BYTE LOOP READING - TRANSMIT ------------------------
----------------------------------------------------------------------------*/

// fsm2tx_start	- pulse!
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		fsm2tx_start <= 1'b0;
	end
	else if (tx_start_sample) begin
		fsm2tx_start <= 1'b1;
	end
	else begin
		fsm2tx_start <= 1'b0;
	end
end

// fsm2tx_data
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		fsm2tx_data[7:0] <= 8'b0;
	end
	else if (tx_start_sample) begin
		case (byte_counter[1:0])
			2'b00: fsm2tx_data[7:0] <= salsa_reg2fsm_rdata[7:0];
			2'b01: fsm2tx_data[7:0] <= salsa_reg2fsm_rdata[15:8];
			2'b10: fsm2tx_data[7:0] <= salsa_reg2fsm_rdata[23:16];
			2'b11: fsm2tx_data[7:0] <= salsa_reg2fsm_rdata[31:24];
		endcase
	end
end


// ---------------------------------------------------------------------------

endmodule		// salsa_fsm 