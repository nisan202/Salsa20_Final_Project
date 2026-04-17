/*
##################################################################
Module Number 20			
Module Name: fsm_tb				
Author: Nisan Moshe Shlomov 			
final project 						
Date: 27.02.2025					
Description:
	
##################################################################	
*/

`timescale 1 ns / 1 ps

`include "3.Defines_file/salsa_defines.def"

`default_nettype none

module fsm_tb ();

parameter ADDR_WIDTH = `ADDR_WIDTH_REGS;

// Testbench signals
reg 		clk;					// input
reg			rst_n;					// input

reg [31:0]	salsa_reg2fsm_rdata;	// input
reg 		salsa_fsm2reg_hit;		// output
wire		salsa_fsm2reg_wr1_rd0;	// output
wire [3:0]	salsa_fsm2reg_byte_en;	// output
wire [31:0]	salsa_fsm2reg_wdata;	// output
wire [ADDR_WIDTH-1:0]	salsa_fsm2reg_addr; 	// output
wire [31:0] regs_db [9:0];		// output

reg [7:0] 	rx2fsm_data;	// input
reg 		rx2fsm_done;	// input - pulse!

wire		fsm2tx_start;	// output - pulse!
wire [7:0]	fsm2tx_data;	// output
reg 		tx2fsm_done;	// input - pulse!
	

//----------------------------------------------------------------------------
// state definition:
typedef enum logic [3:0] {
	IDLE				   = 4'd0,
	RECEIVE_COMMAND	 	   = 4'd1,
	RECEIVE_ADDRESS	 	   = 4'd2,
	RECEIVE_DATA_TO_REGS   = 4'd3,
	BYTE_ENABLE			   = 4'd4,
	HIT_SAMPLE			   = 4'd5,
	WAIT_CYCLE			   = 4'd6,
	BYTE_COUNTER  		   = 4'd7,
	TX_START_PULSE		   = 4'd8,
	READ_LOOP              = 4'd9
	
} states;

states ps, ns;

//----------------------------------------------------------------------------
// External signals
assign ps = states'(fsm_dut.salsa_fsm_ps);
assign ns = states'(fsm_dut.salsa_fsm_ns);

wire command_sample;
assign command_sample = fsm_dut.command_sample;

wire addr_sample;
assign addr_sample = fsm_dut.addr_sample;

wire byte_sample;
assign byte_sample = fsm_dut.byte_sample;

wire ben_sample;
assign ben_sample = fsm_dut.ben_sample;

wire fsm_hit_sample;
assign fsm_hit_sample = fsm_dut.fsm_hit_sample;

reg idle_again;


//----------------------------------------------------------------------------
// salsa_fsm instance
salsa_fsm  fsm_dut(
	.clk(clk), .rst_n(rst_n), .salsa_reg2fsm_rdata(salsa_reg2fsm_rdata[31:0]),
	.salsa_fsm2reg_hit(salsa_fsm2reg_hit), .salsa_fsm2reg_wr1_rd0(salsa_fsm2reg_wr1_rd0),
	.salsa_fsm2reg_byte_en(salsa_fsm2reg_byte_en[3:0]), .salsa_fsm2reg_wdata(salsa_fsm2reg_wdata[31:0]),
	.salsa_fsm2reg_addr(salsa_fsm2reg_addr[ADDR_WIDTH-1:0]), .rx2fsm_data(rx2fsm_data[7:0]),
	.rx2fsm_done(rx2fsm_done), .fsm2tx_start(fsm2tx_start), .fsm2tx_data(fsm2tx_data[7:0]),
	.tx2fsm_done(tx2fsm_done));

//----------------------------------------------------------------------------
// regs4fsmTb instance
regs4fsmTb  regs4fsmTb_dut(
	.clk(clk), .rst_n(rst_n), .hit(salsa_fsm2reg_hit),
	.wr1_rd0(salsa_fsm2reg_wr1_rd0), .ben(salsa_fsm2reg_byte_en[3:0]),
	.wdata(salsa_fsm2reg_wdata[31:0]), .addr(salsa_fsm2reg_addr[ADDR_WIDTH-1:0]),
	.rdata(salsa_reg2fsm_rdata[31:0]), .regs_db(regs_db));

//----------------------------------------------------------------------------
// task : release from idle
	task release_from_idle(input [7:0] head);
		begin
			# 80000	rx2fsm_done = 1'b1;		// 8 bits - each one 10,000 ns
			rx2fsm_data[7:0] = head[7:0];	// need to be 8'hAA
			# 10 rx2fsm_done = 1'b0;
			if (head[7:0] != 8'hAA) begin
				$display("Time %0t: Error: Expected 0xAA to release, got 0x%h",$time ,head);
				if (ns == RECEIVE_COMMAND)
					$display("Time %0t: Error: Expected ps stay in idle, but it will moved to RECEIVE_COMMAND", $time);
				if (ns == IDLE)
					$display("Time %0t: As we expected, the ps remains in IDLE", $time);
			end
			else if (head[7:0] == 8'hAA) begin
				$display("Time %0t: As we expected, got 0x%h in head data", $time,head);
				if (ns == RECEIVE_COMMAND)
					$display("Time %0t: As we expected, the ps will moved to RECEIVE_COMMAND", $time);
				if (ns == IDLE)
					$display("Time %0t: Error: Expected moved to RECEIVE_COMMAND, but stay in IDLE", $time);
			end
		end
	endtask

//----------------------------------------------------------------------------
// task : recieve command
	task recieve_command(input [7:0] command);
		begin
			# 80000 rx2fsm_done = 1'b1;		// 8 bits - each one 10,000 ns
			rx2fsm_data[7:0] = command[7:0];	// 0 - read, 1 - write
			# 2;
			
			if (command_sample)
				$display("Time %0t: Pass: command_sample rose to 1 as Expected", $time);
			else
				$display("Time %0t: Error: command_sample = 0x%h", $time,command_sample);

			# 8 rx2fsm_done = 1'b0;
			
		end
	endtask

//----------------------------------------------------------------------------
// task : recieve addr
	task recieve_addr(input [7:0] addr);	// range: 6'h00 <= addr <= 6'h0A 
		begin
			# 80000 rx2fsm_done = 1'b1;		// 8 bits - each one 10,000 ns
			rx2fsm_data[7:0] = addr[7:0];	// for this TB we have only 10 regs ("regs4fsmTb.sv")
			# 2;
			
			if (addr_sample)
				$display("Time %0t: Pass: addr_sample rose to 1 as Expected", $time);
			else
				$display("Time %0t: Error: addr_sample = 0x%h",$time,addr_sample);
			
			# 8 rx2fsm_done = 1'b0;
			
		end
	endtask

//----------------------------------------------------------------------------
// task : recieve byte
	task recieve_byte(input [7:0] data);
		begin
			# 80000 rx2fsm_done = 1'b1;		// 8 bits - each one 10,000 ns
			rx2fsm_data[7:0] = data[7:0];	
			# 10 rx2fsm_done = 1'b0;
			# 10;			// in this time ps=write_loop 
		end
	endtask

//----------------------------------------------------------------------------
// task : read reg
	task read_byte();
		begin
			# 80000 tx2fsm_done = 1'b1;
			# 10 tx2fsm_done = 1'b0;
		end
	endtask

//----------------------------------------------------------------------------
// task : check wr1_rd0
	task check_wr1_rd0(input expected_wr1_rd0);
		begin
			if (salsa_fsm2reg_wr1_rd0 == expected_wr1_rd0)
				$display("Time %0t: Pass: Expected salsa_fsm2reg_wr1_rd0 0x%h, got 0x%h ", $time,expected_wr1_rd0,salsa_fsm2reg_wr1_rd0);
			else
				$display("Time %0t: Error: Expected salsa_fsm2reg_wr1_rd0 0x%h, got 0x%h ", $time,expected_wr1_rd0,salsa_fsm2reg_wr1_rd0);
		end
	endtask

//----------------------------------------------------------------------------
// task : check addr
	task check_addr(input [7:0] expected_addr);
		begin
			if (salsa_fsm2reg_addr == expected_addr[7:0])
				$display("Time %0t: Pass: Expected salsa_fsm2reg_addr 0x%h, got 0x%h ",$time,expected_addr,salsa_fsm2reg_addr);
			else
				$display("Time %0t: Error: Expected salsa_fsm2reg_addr 0x%h, got 0x%h ",$time,expected_addr,salsa_fsm2reg_addr);
		end
	endtask

//----------------------------------------------------------------------------
// task : check writing
	// addr[3:0] --> we have 10 regs in regs4fsmTb (0-9)
	// expected_data[31:0] --> the expected value in this addr
	task check_writing(input [3:0] addr, input [31:0] expected_data);
		begin
			if (regs_db[addr[3:0]] == expected_data[31:0])begin
				$display("Time %0t: The required information has been successfully entered.", $time);
				$display("Time %0t: ----- Write Test Completed: SUCCESS -----\n",$time);
			end
			else begin
				$display("Time %0t: Error! The required information not entered.", $time);
				$display("Time %0t: Error! ----- Write Test Completed: FAILURE -----\n",$time);
			end
		end
	endtask

//----------------------------------------------------------------------------
// task : check read correct byte
	// byte_index: 4 bytes --> 0-3
	// expected_value
	task check_read_correct_byte(input [1:0] byte_index, input [7:0] expected_value, output reg pass);
		begin
			if (fsm2tx_data[7:0] == expected_value[7:0]) begin
				$display("Time %0t: Byte 0x%h, has been successfully transmit.", $time,byte_index);
				$display("Time %0t: Pass: Expected 0x%h, transferred 0x%h ", $time,expected_value,fsm2tx_data);
				pass = 1'b1;
			end
			else begin
				$display("Time %0t: Byte 0x%h, not transferred successfully.", $time,byte_index);
				$display("Time %0t: Error: Expected 0x%h, transferred 0x%h ", $time,expected_value,fsm2tx_data);
				pass = 1'b0;
			end
		end
	endtask

//----------------------------------------------------------------------------
// task : check idle again
	task check_idle();
		begin
			if (ps==IDLE) begin
				$display("Time %0t: ps is IDLE again\n", $time);
			end
			else begin 
				$display("Time %0t: ps is not IDLE yet\n", $time);
			end
		end
	endtask

//----------------------------------------------------------------------------
// 
	task test_write_register(input [7:0] addr, input [31:0] data);
		begin
			$display("Time %0t: \n----- Starting Write Test: Addr=0x%h, Data=0x%h -----", $time,addr, data);
		
			release_from_idle(8'hAA);
			# 10;
			recieve_command(8'h01);
			# 10;
			check_wr1_rd0(1'b1);
			# 10;
			recieve_addr(addr);
			# 10;
			check_addr(addr);
			# 10;
			recieve_byte(data[7:0]);
			# 10;
			recieve_byte(data[15:8]);
			# 10;
			recieve_byte(data[23:16]);
			# 10;
			recieve_byte(data[31:24]);
			# 10;
		end
	endtask

//----------------------------------------------------------------------------
// 
	task test_read_register(input [7:0] addr, input [7:0] expected0, input [7:0] expected1, input [7:0] expected2 ,input [7:0] expected3);
		
		reg pass0, pass1, pass2, pass3;
		reg test_passed;
		
		begin
			$display("Time %0t: \n----- Starting Read Test: Addr=0x%h -----", $time,addr);
		
			release_from_idle(8'hAA);
			# 10;
			recieve_command(8'h00);
			# 10;
			check_wr1_rd0(1'b0);
			# 10;
			recieve_addr(addr);
			# 10;
			check_addr(addr);
			# 10;
			read_byte();
			check_read_correct_byte(2'd0,expected0,pass0);
			# 10;
			read_byte();
			check_read_correct_byte(2'd1,expected1,pass1);
			# 10;
			read_byte();
			check_read_correct_byte(2'd2,expected2,pass2);
			# 10;
			read_byte();
			check_read_correct_byte(2'd3,expected3,pass3);
			# 10;
			
			test_passed = (pass0 & pass1 & pass2 & pass3);
			
			if (test_passed) begin
				$display("Time %0t: ----- Read Test Completed: SUCCESS -----\n", $time);
			end
			else begin
				$display("Time %0t: ----- Read Test Completed: FAILURE -----\n", $time);
			end
			
			# 10;
		end
	endtask
	

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
/* Test 1: write 3 registers
1. addr: 8'h03 --> data: 32'hA2B2C2D2
2. addr: 8'h05 --> data: 32'hF1234567
3. addr: 8'h08 --> data: 32'h5AF45A85
*/
	task test_1();
		begin
			$display("Time %0t:-------------------- Test_1 --------------------\n", $time);
			
			$display("Time %0t:----- Write Register Number 1: Write 32'hA2B2C2D2 to addr 8'h03\n", $time);
			test_write_register(8'h03,32'hA2B2C2D2);
			# 20;
			check_writing(4'd3,32'hA2B2C2D2);
			# 100;
		
			$display("Time %0t:----- Write Register Number 2: Write 32'hF1234567 to addr 8'h05\n", $time);
			test_write_register(8'h05,32'hF1234567);
			# 20;
			check_writing(4'd5,32'hF1234567);
			# 100;
		
			$display("Time %0t:----- Write Register Number 3: Write 32'h5AF45A85 to addr 8'h08\n", $time);
			test_write_register(8'h08,32'h5AF45A85);
			# 20;
			check_writing(4'd8,32'h5AF45A85);
			# 100;
		
			$display("Time %0t:-------------------- Test_1 Finish --------------------\n", $time);
		end
	endtask

			
//----------------------------------------------------------------------------
/* Test 1: read 4 registers
1. addr: 8'h03 --> expected data: 32'hA2B2C2D2
2. addr: 8'h05 --> expected data: 32'hF1234567
3. addr: 8'h08 --> expected data: 32'h5AF45A85
4. addr: 8'h00 --> expected data: 32'h00000000
*/		
	task test_2();
		begin
			$display("Time %0t:------------------------- Test_2 -------------------------\n", $time);	
			
			$display("Time %0t:----- Read Register Number 1: Read addr 8'h03,expected data: 32'hA2B2C2D2 \n", $time);
			test_read_register(8'h03,8'hD2,8'hC2,8'hB2,8'hA2);
			# 40;
			
			$display("Time %0t:----- Read Register Number 2: Read addr 8'h05,expected data: 32'hF1234567 \n", $time);
			test_read_register(8'h05,8'h67,8'h45,8'h23,8'hF1);
			# 40;
			
			$display("Time %0t:----- Read Register Number 3: Read addr 8'h08,expected data: 32'h5AF45A85 \n", $time);
			test_read_register(8'h08,8'h85,8'h5A,8'hF4,8'h5A);
			# 40;
			
			$display("Time %0t:----- Read Register Number 4: Read addr 8'h00,expected data: 32'h00000000 \n", $time);
			test_read_register(8'h00,8'h00,8'h00,8'h00,8'h00);
			# 40;
			
			$display("Time %0t:-------------------- Test_2 Finish --------------------\n", $time);
		end
	endtask

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
// Clock generation
always #5 clk = ~ clk;	// F = 100MHz -> T = 10ns

initial begin
	clk = 1'b0;
	rst_n = 1'b0;
	rx2fsm_data[7:0] = 8'b0;
	rx2fsm_done  = 1'b0;
	tx2fsm_done = 1'b0;
	
	
	# 23 rst_n = 1;  // Release reset
	
	# 22;	// =45 ,need to be aligned to the clk --> rising edge: 5,15,25,35,45... 
	
	// TEST_1:
	test_1();
	# 20;
	check_idle();
	
	// wait between tests
	# 300;
	
	// TEST_2:
	test_2();
	# 20;
	check_idle();

	end
endmodule
