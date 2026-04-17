/*
##################################################################
Module Number 12		
Module Name: salsa_uart_tx				
Author:  taken from git - need to fix and confrim to my code			
final project 						
Date: 09.01.2024 					
Description:
	
##################################################################	
*/

//`include "3.Defines_file/salsa_defines.def"
`include "../3.Defines_file/salsa_defines.vh"


`default_nettype none

module salsa_uart_tx #(
	parameter BIT_RATE = `BIT_RATE,
	parameter RATE_WIDTH = $clog2(`BIT_RATE))
	(
    input wire clk,       // Clock input
    input wire rst_n,     // Active-low reset
    input wire start,     // Start signal
    input wire [7:0] data, // Data to be transmitted
    output reg rs232_tx,  // UART transmit output
    output reg done       // Transmission done flag
);

    // Internal registers
    reg [7:0] r_data;      // Data register
    reg state;             // State of the transmitter
    reg [RATE_WIDTH-1:0] baud_cnt;   // Baud rate counter
    reg bit_flag;          // Bit flag to signal bit transmission
    reg [3:0] bit_cnt;     // Bit counter

    // Baud rate counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            baud_cnt <= {RATE_WIDTH{1'b0}};
        else if (state) begin
            if (baud_cnt == BIT_RATE) // Assuming a baud rate of 9600 with 50MHz clock
                baud_cnt <= {RATE_WIDTH{1'b0}};
            else 
                baud_cnt <= baud_cnt + 1'b1;
        end else 
            baud_cnt <= {RATE_WIDTH{1'b0}};
    end

    // Bit flag logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            bit_flag <= 1'b0;
        else if (baud_cnt == BIT_RATE) 
            bit_flag <= 1'b1;
        else 
            bit_flag <= 1'b0;
    end

    // Main state and bit counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 1'b0;
            bit_cnt <= 4'd0;
            done <= 1'b0;
        end else if (start && !state) begin
            state <= 1'b1;
            r_data <= data;
            bit_cnt <= 4'd0;
            done <= 1'b0;
        end else if (state && bit_flag) begin
            bit_cnt <= bit_cnt + 1'b1;
            if (bit_cnt == 4'd9) begin
                state <= 1'b0;
                done <= 1'b1;
            end else 
                done <= 1'b0;
        end
    end

    // UART transmission logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            rs232_tx <= 1'b1; // Idle state for UART is high
        else if (state) begin
            case (bit_cnt)
                4'd0: rs232_tx <= 1'b0; // Start bit
                4'd1: rs232_tx <= r_data[0];
                4'd2: rs232_tx <= r_data[1];
                4'd3: rs232_tx <= r_data[2];
                4'd4: rs232_tx <= r_data[3];
                4'd5: rs232_tx <= r_data[4];
                4'd6: rs232_tx <= r_data[5];
                4'd7: rs232_tx <= r_data[6];
                4'd8: rs232_tx <= r_data[7];
                4'd9: rs232_tx <= 1'b1; // Stop bit
                default: rs232_tx <= 1'b1; 
            endcase
        end else 
            rs232_tx <= 1'b1; // Idle state
    end

endmodule
