/*
##################################################################
Module Number			
Module Name: d_r_c_round_interative 				
Author: Nisan Moshe Shlomov 			
final project 						
Date: 17.06.2025 					
Description:
	Run the column round function
	on input matrix and on that 
	run the row round function.
	double_round = row_round(column_round(matrix in)

The index in the matrix:
[31:0] matrix [0:3][0:3] -->
	column	  0		  1		  2		  3
	row	0	[0,0]	[0,1]	[0,2]	[0,3]
	
		1	[1,0]	[1,1]	[1,2]	[1,3]
		
		2	[2,0]	[2,1]	[2,2]	[2,3]
		
		3	[3,0]	[3,1]	[3,2]	[3,3]

The dw assign in the matrix:
[31:0] matrix [0:3][0:3] --> 
	column	0	   1	   2	  3
	row	0	X0	  X1	  X2	  X3
	
		1	X4	  X5	  X6	  X7
		
		2	X8	  X9	  X10	  X11
		
		3	X12	  X13	  X14	  X15

column_0 = quarter_round(X0,X4,X8,X12)
column_1 = quarter_round(X5,X9,X13,X1)
column_2 = quarter_round(X10,X14,X2,X6)
column_3 = quarter_round(X15,X3,X7,X11)

row_0 = quarter_round(X0,X1,X2,X3)
row_1 = quarter_round(X5,X6,X7,X4)
row_2 = quarter_round(X10,X11,X8,X9)
row_3 = quarter_round(X15,X12,X13,X14)

##################################################################	
*/

`default_nettype none

module d_r_c_round_interative
	(
	input wire	clk,
	input wire	rst_n,
	
	input wire [31:0] double_dw_matrix_in [0:3][0:3],
	input wire start_double_round,		// pulse input
	
	output reg [31:0] double_dw_matrix_out [0:3][0:3],
	output reg double_round_done_valid		// pulse output
);

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------

/* ##### STATES CODING #####
0.	IDLE     -->> wait to start_double_round pulse.
1.  SAMPLE_INPUT 
2.  QR_SET
3.  SET_MTX
4.  DELAY
5.  QR_COUNTER
6.  SAMPLE_OUTPUT
7.	DONE
*/

typedef enum logic [2:0] {
	IDLE			= 3'd0,			 
	SAMPLE_INPUT	= 3'd1,
	QR_SET			= 3'd2,
	SET_MTX			= 3'd3,
	DELAY			= 3'd4,
	QR_COUNTER		= 3'd5,
	SAMPLE_OUTPUT	= 3'd6,
	DONE			= 3'd7
	
} states;

states d_r_c_fsm_ps, d_r_c_fsm_ns;

/* ---------------------------------------------------------------------------
------------------------ INTERNAL SIGNALS ------------------------------------
----------------------------------------------------------------------------*/
reg	[31:0]	qr_0_in;
reg	[31:0]	qr_1_in;
reg	[31:0]	qr_2_in;
reg	[31:0]	qr_3_in;

reg	[31:0]	qr_0_out;
reg	[31:0]	qr_1_out;
reg	[31:0]	qr_2_out;
reg	[31:0]	qr_3_out;

reg [31:0] matrix_in_sample [0:3][0:3];
reg [31:0] matrix_after_col [0:3][0:3];
reg [31:0] matrix_after_row [0:3][0:3];
reg [2:0]  qr_cntr;

reg sample_input;
reg qr_set;
reg set_mtx;
reg increase_cntr;
reg reset_cntr;
reg sample_output;

/* ---------------------------------------------------------------------------
---------------------- FINITE-STATE MACHINE ----------------------------
------------------------------------------------------------------------------
"unique case" = A statement that all cases cover
all possibilities and there are not un-addressed situations.
*/
always @(*) begin
	sample_input = 1'b0;
	qr_set = 1'b0;
	set_mtx = 1'b0;
	increase_cntr = 1'b0;
	reset_cntr = 1'b0;
	sample_output = 1'b0;
	double_round_done_valid = 1'b0;
	
	d_r_c_fsm_ns = d_r_c_fsm_ps;
	
	unique case (d_r_c_fsm_ps)
		IDLE: begin
			if (start_double_round) begin
				d_r_c_fsm_ns = SAMPLE_INPUT;
				sample_input = 1'b1;
			end
		end
		
		SAMPLE_INPUT: begin
			d_r_c_fsm_ns = QR_SET;
		end
		
		QR_SET: begin
			qr_set = 1'b1;
			d_r_c_fsm_ns = SET_MTX;			
		end
		
		SET_MTX: begin
			set_mtx = 1'b1;
			d_r_c_fsm_ns = DELAY;
		end
		
		DELAY: begin
			d_r_c_fsm_ns = QR_COUNTER;
		end
		
		QR_COUNTER: begin
			if (qr_cntr < 3'd7) begin
				increase_cntr = 1'b1;
				d_r_c_fsm_ns = QR_SET;
			end
			else begin
				reset_cntr = 1'b1;
				sample_output = 1'b1;
				d_r_c_fsm_ns = SAMPLE_OUTPUT;
			end
		end
		
		SAMPLE_OUTPUT: begin
			d_r_c_fsm_ns = DONE;
		end
		
		DONE: begin 
			double_round_done_valid = 1'b1;
			d_r_c_fsm_ns = IDLE;
		end
	endcase
end	
/* ---------------------------------------------------------------------------
------------------------ STATE TRANSITIONS -----------------------------------
----------------------------------------------------------------------------*/

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		d_r_c_fsm_ps <= IDLE;
	end
	else begin
		d_r_c_fsm_ps <= d_r_c_fsm_ns;
	end
end

/* ---------------------------------------------------------------------------
------------------------ SAMPLE INPUT ----------------------------------------
----------------------------------------------------------------------------*/

always @(posedge clk or negedge rst_n) begin
	for (int i=0; i<4; i=i+1) begin
		for (int j=0; j<4; j=j+1) begin
			// ~rst_n
			if (~rst_n) begin
				matrix_in_sample[i][j] <= 32'b0;
				double_dw_matrix_out[i][j] <= 32'b0;
			end
			else begin
				// sample_initial_mtx
				if (sample_input) begin
					matrix_in_sample[i][j] <= double_dw_matrix_in[i][j];
				end
				if (sample_output) begin
					double_dw_matrix_out[i][j] <= matrix_after_row[i][j];
				end
			end
		end
	end
end

/* ---------------------------------------------------------------------------
------------------------ QR_COUNTER ------------------------------------------
----------------------------------------------------------------------------*/

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		qr_cntr[2:0] <= 3'b0;
	end
	else begin
		if (increase_cntr) begin
			qr_cntr[2:0] <= qr_cntr[2:0] + 1'b1;
		end
		else if (reset_cntr) begin
			qr_cntr[2:0] <= 3'b0;
		end
	end
end

/* ---------------------------------------------------------------------------
---------------------------------- QR_SET ------------------------------------
----------------------------------------------------------------------------*/

//always @(*) begin
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		qr_0_in[31:0] <= 32'b0;
		qr_1_in[31:0] <= 32'b0;
		qr_2_in[31:0] <= 32'b0;
		qr_3_in[31:0] <= 32'b0;
	end
	else if (qr_set) begin
		case (qr_cntr[2:0])
			//  0 -> 3 : column
			3'b000: begin // col_0: 0,4,8,12
				qr_0_in[31:0] = matrix_in_sample[0][0];	// 0
				qr_1_in[31:0] = matrix_in_sample[1][0];	// 4
				qr_2_in[31:0] = matrix_in_sample[2][0];	// 8
				qr_3_in[31:0] = matrix_in_sample[3][0];	// 12
			end
			
			3'b001: begin // col_1: 5,9,13,1
				qr_0_in[31:0] = matrix_in_sample[1][1];	// 5
				qr_1_in[31:0] = matrix_in_sample[2][1];	// 9
				qr_2_in[31:0] = matrix_in_sample[3][1];	// 13
				qr_3_in[31:0] = matrix_in_sample[0][1];	// 1
			end
			
			3'b010: begin // col_2: 10,14,2,6
				qr_0_in[31:0] = matrix_in_sample[2][2];	// 10
				qr_1_in[31:0] = matrix_in_sample[3][2];	// 14
				qr_2_in[31:0] = matrix_in_sample[0][2];	// 2
				qr_3_in[31:0] = matrix_in_sample[1][2];	// 6
			end
			
			3'b011: begin // col_3: 15,3,7,11
				qr_0_in[31:0] = matrix_in_sample[3][3];	// 15
				qr_1_in[31:0] = matrix_in_sample[0][3];	// 3
				qr_2_in[31:0] = matrix_in_sample[1][3];	// 7
				qr_3_in[31:0] = matrix_in_sample[2][3];	// 11
			end
			
			3'b100: begin // row_0: 0,1,2,3
				qr_0_in[31:0] = matrix_after_col[0][0];	// 0
				qr_1_in[31:0] = matrix_after_col[0][1];	// 1
				qr_2_in[31:0] = matrix_after_col[0][2];	// 2
				qr_3_in[31:0] = matrix_after_col[0][3];	// 3
			end

			3'b101: begin // row_1: 5,6,7,4
				qr_0_in[31:0] = matrix_after_col[1][1];	// 5
				qr_1_in[31:0] = matrix_after_col[1][2];	// 6
				qr_2_in[31:0] = matrix_after_col[1][3];	// 7
				qr_3_in[31:0] = matrix_after_col[1][0];	// 4
			end
			
			3'b110: begin // row_2: 10,11,8,9
				qr_0_in[31:0] = matrix_after_col[2][2];	// 10
				qr_1_in[31:0] = matrix_after_col[2][3];	// 11
				qr_2_in[31:0] = matrix_after_col[2][0];	// 8
				qr_3_in[31:0] = matrix_after_col[2][1];	// 9
			end
			
			3'b111: begin // row_3: 15,12,13,14
				qr_0_in[31:0] = matrix_after_col[3][3];	// 15
				qr_1_in[31:0] = matrix_after_col[3][0];	// 12
				qr_2_in[31:0] = matrix_after_col[3][1];	// 13
				qr_3_in[31:0] = matrix_after_col[3][2];	// 14
			end
		endcase
	end
end

/* ---------------------------------------------------------------------------
------------------------------------ SET_MTX ---------------------------------
----------------------------------------------------------------------------*/

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		for (int i=0; i<4; i=i+1) begin
			for (int j=0; j<4; j=j+1) begin
				matrix_after_col[i][j] <= 32'b0;
				matrix_after_row[i][j] <= 32'b0;
			end
		end
	end
	else if (set_mtx) begin
		if (~qr_cntr[2]) begin // cloumn matrix
			case (qr_cntr[1:0])
				//  0 -> 3 : column
				2'b00: begin // col_0: 0,4,8,12
					matrix_after_col[0][0] <= qr_0_out;	// 0
					matrix_after_col[1][0] <= qr_1_out;	// 4
					matrix_after_col[2][0] <= qr_2_out;	// 8
					matrix_after_col[3][0] <= qr_3_out;	// 12
				end
				
				2'b01: begin // col_1: 5,9,13,1
					matrix_after_col[1][1] <= qr_0_out;	// 5
					matrix_after_col[2][1] <= qr_1_out;	// 9
					matrix_after_col[3][1] <= qr_2_out;	// 13
					matrix_after_col[0][1] <= qr_3_out;	// 1
				end
				
				2'b10: begin // col_2: 10,14,2,6
					matrix_after_col[2][2] <= qr_0_out;	// 10
					matrix_after_col[3][2] <= qr_1_out;	// 14
					matrix_after_col[0][2] <= qr_2_out;	// 2
					matrix_after_col[1][2] <= qr_3_out;	// 6
				end
				
				2'b11: begin // col_3: 15,3,7,11
					matrix_after_col[3][3] <= qr_0_out;	// 15
					matrix_after_col[0][3] <= qr_1_out;	// 3
					matrix_after_col[1][3] <= qr_2_out;	// 7
					matrix_after_col[2][3] <= qr_3_out;	// 11
				end
			endcase
		end
		else if (qr_cntr[2]) begin // row matrix
			case (qr_cntr[1:0])
				2'b00: begin // row_0: 0,1,2,3
					matrix_after_row[0][0] <= qr_0_out;	// 0
					matrix_after_row[0][1] <= qr_1_out;	// 1
					matrix_after_row[0][2] <= qr_2_out;	// 2
					matrix_after_row[0][3] <= qr_3_out;	// 3
				end

				2'b01: begin // row_1: 5,6,7,4
					matrix_after_row[1][1] <= qr_0_out;	// 5
					matrix_after_row[1][2] <= qr_1_out;	// 6
					matrix_after_row[1][3] <= qr_2_out;	// 7
					matrix_after_row[1][0] <= qr_3_out;	// 4
				end
				
				2'b10: begin // row_2: 10,11,8,9
					matrix_after_row[2][2] <= qr_0_out;	// 10
					matrix_after_row[2][3] <= qr_1_out;	// 11
					matrix_after_row[2][0] <= qr_2_out;	// 8
					matrix_after_row[2][1] <= qr_3_out;	// 9
				end
				
				2'b11: begin // row_3: 15,12,13,14
					matrix_after_row[3][3] <= qr_0_out;	// 15
					matrix_after_row[3][0] <= qr_1_out;	// 12
					matrix_after_row[3][1] <= qr_2_out;	// 13
					matrix_after_row[3][2] <= qr_3_out;	// 14
				end
			endcase
		end
	end
end

/* ---------------------------------------------------------------------------
--------------------------------- INSATNCE ----------------------------------
----------------------------------------------------------------------------*/

quarter_round u_quarter_round(
	.dw0_in		(qr_0_in),
	.dw1_in		(qr_1_in),
	.dw2_in		(qr_2_in),
	.dw3_in		(qr_3_in),
	.dw0_out	(qr_0_out),
	.dw1_out	(qr_1_out),
	.dw2_out	(qr_2_out),
	.dw3_out	(qr_3_out)
);

// ----------------------------------------------------------------------
endmodule	// d_r_c_round_interative