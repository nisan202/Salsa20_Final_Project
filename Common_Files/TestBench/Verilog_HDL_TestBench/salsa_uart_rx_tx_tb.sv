/*
##################################################################
Module Number 			
Module Name: salsa_uart_rx_tx_tb				
Author: Nisan Moshe Shlomov 			
final project 						
Date: 29.08.2025					
Description:
	
##################################################################	
*/

`timescale 1 ns / 1 ps

`include "3.Defines_file/salsa_defines.def"

`default_nettype none

module salsa_uart_rx_tx_tb();

// Testbench signals
reg 		clk;	// Input Clk
reg			rst_n;	// Input Rst_n

//rx signals
reg rx_rs232_pc2fpga;   // Input UART receive - from PC to FPGA
wire [7:0] rx_data; 	// Output Received data
wire rx_done;       	// Output Reception done flag => pulse! - say that the data is valid.

// tx signals
reg tx_start;      		// Input Start signal => pulse to start transmit
reg [7:0] tx_data; 		// Input Data to be transmitted
wire tx_rs232_fpga2pc;  // Output UART transmit - from FPGA to PC
wire tx_done;       	// Output Transmission done flag => pulse! - finish the transmition

// debug tx
reg [7:0] tx_received_data;
// pc_data
reg [7:0] pc_data;

//

parameter BIT_TIME_NS = 1_000_000_000 / `BAUD_RATE;

//-------------------------------------------------------------
// Instance
// RX
/*
salsa_uart_rx	pc_2_fpga(
	.clk		(clk),
	.rst_n		(rst_n),
	.rs232		(rx_rs232_pc2fpga),
	.rx_data	(rx_data),
	.done		(rx_done)
);
*/
salsa_rx	pc_2_fpga(
	.clk		(clk),
	.rst_n		(rst_n),
	.rs232		(rx_rs232_pc2fpga),
	.rx_data	(rx_data),
	.done		(rx_done)
);

//TX
salsa_uart_tx	fpga_2_pc(
	.clk		(clk),		
	.rst_n		(rst_n),
	.start		(tx_start),
	.data		(tx_data),
	.rs232_tx	(tx_rs232_fpga2pc),
	.done		(tx_done)
);

//-------------------------------------------------------------
integer i;

//-------------------------------------------------------------
// send from pc to fpga
//-------------------------------------------------------------

	task send_from_pc_to_fpga(input [7:0] byte_in);
		begin
			i = 0;
			rx_rs232_pc2fpga = 0;  // Start bit
			#(BIT_TIME_NS);
		
			for (i = 0; i < 8; i = i + 1) begin
				rx_rs232_pc2fpga = byte_in[i];
				#(BIT_TIME_NS);
			end

			rx_rs232_pc2fpga = 1;  // Stop bit
			#(BIT_TIME_NS);
		end
	endtask

//-------------------------------------------------------------
// send from fpga to pc
//-------------------------------------------------------------
	
	task send_from_fpga_to_pc(input uart_line,output reg [7:0] received_byte);
		begin
			i = 0;
			// Wait for start bit
			//wait (uart_line == 0);
			//$display ("%h = 0",uart_line);
			//#(BIT_TIME_NS/2); // ← דוגם באמצע הביט הראשון // Wait 1 bit time
			#(BIT_TIME_NS + BIT_TIME_NS/2);
			
			for (i = 0; i < 8; i = i + 1) begin
				received_byte[i] = uart_line;
				$display("  bit[%0d] sampled = %b", i, uart_line);
				#(BIT_TIME_NS);
			end
			
			$display("<<< task completed, received_byte = %02h", received_byte);
			#(BIT_TIME_NS); // stop bit
		end
	endtask

//-------------------------------------------------------------
time start_time, end_time;
time duration;

// Clock generation
always #5 clk = ~ clk;	// F = 100MHz -> T = 10ns

initial begin
	clk = 1'b0;
	rst_n = 1'b0;
	rx_rs232_pc2fpga = 1'b1;
	tx_start = 1'b0;
	pc_data[7:0] = 8'h3c;
	tx_received_data[7:0] = 8'h0;
	tx_data = 8'h0;
	
	# 23 rst_n = 1'b1;  // Release reset
	
	// pc2fpga:
	$display("\n====== UART RX TEST ======\n");
	# 10000;
	$display("\n--- Sending byte 0x3C from PC to FPGA RX ---\n");
	start_time = $time;
	send_from_pc_to_fpga(pc_data[7:0]);
	end_time = $time;
    
    duration = end_time - start_time;
	
	$display("Transmission time (PC->FPGA): %0t ns", duration);
    if (duration == 10 * BIT_TIME_NS)
        $display("✅ Timing correct for RX");
    else
        $display("❌ Timing mismatch for RX! Expected %0d ns", 10 * BIT_TIME_NS);
		
	
	wait(rx_done);
	if (rx_data !== pc_data[7:0])
		$display("❌ RX ERROR: expected 0x3C, got 0x%02X", rx_data);
	else
		$display("✅ RX OK: received 0x%02X", rx_data);
	
	
	// fpga2pc:
	$display("\n====== UART TX TEST ======\n");
	# 10000;
	$display("\n--- Sending byte 0x7E from FPGA TX to PC ---\n");
	
	tx_data = 8'h7E;
    tx_start = 1'b1;
    # 10;
    tx_start = 1'b0;
	
	@(negedge tx_rs232_fpga2pc);
	start_time = $time;
	send_from_fpga_to_pc(tx_rs232_fpga2pc, tx_received_data);
	end_time = $time;
    
    duration = end_time - start_time;
	
	$display("Transmission time (FPGA->PC): %0t ns", duration);
    if (duration == 10 * BIT_TIME_NS)
        $display("✅ Timing correct for TX");
    else
        $display("❌ Timing mismatch for TX! Expected %0d ns", 10 * BIT_TIME_NS);
	
	if (tx_received_data !== 8'h7E)
		$display("❌ TX ERROR: expected 0x7E, got 0x%02X", tx_received_data);
	else
		$display("✅ TX OK: received 0x%02X", tx_received_data);

	#10000;
	
	#(BIT_TIME_NS * 15);  // המתנה אחרי השידור האחרון
end

endmodule