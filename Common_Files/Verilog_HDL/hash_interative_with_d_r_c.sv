/*
#######################################################################
Module Number: replace number 5			
Module Name: hash_interative_with_d_r_c			
Author: Nisan Moshe Shlomov 			
final project 						
Date: 19.6.2025 					
Description: 
	the hashing module.
	Takes the input matrix and runs the double round 
	function on it several times as required (10/6/4).
	The output matrix will be what we got plus the input matrix.

	salsa_hash_function = matrix in + double_round(N)(matrix in) 

									column
[31:0] matrix [0:3][0:3] --> 		  0	      1	      2	      3
							row	0	[0,0]	[0,1]	[0,2]	[0,3]
										
								1	[1,0]	[1,1]	[1,2]	[1,3]
								
								2	[2,0]	[2,1]	[2,2]	[2,3]
								
								3	[3,0]	[3,1]	[3,2]	[3,3]

Note: this file replace the "roling" implemntation "salsa_hash_function"								
#########################################################################
*/

`default_nettype none

module hash_interative_with_d_r_c
	(
	input wire		clk,
	input wire		rst_n,
	
	input wire [31:0] salsa_dw_matrix_in [0:3][0:3], 
	input wire [1:0] salsa_round_select,
	input wire start,			// pulse input
	
    output reg [31:0] salsa_dw_matrix_out [0:3][0:3],
	output reg hashing_done		// pulse output
);

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------

/* ##### STATES CODING #####
0. 	IDLE
1.  SAMPLE_INITIAL
2.	SET_MTX
3.	COMBO_CYCLE
4.  WAIT2DOUBLE_DONE
5.	SAMPLE_DOB_OUT
6.  ROUND_CNTR
7.  DONE
*/

typedef enum logic [3:0] {
	IDLE				= 4'd0,
	SAMPLE_INITIAL		= 4'd1,
	SET_MTX	 	   		= 4'd2,
	COMBO_CYCLE			= 4'd3,
	WAIT2DOUBLE_DONE 	= 4'd4,
	SAMPLE_DOB_OUT		= 4'd5,
	ROUND_CNTR			= 4'd6,
	DONE				= 4'd7
	
} states;

states fsm_ps, fsm_ns;

/* ---------------------------------------------------------------------------
------------------------ INTERNAL SIGNALS ------------------------------------
----------------------------------------------------------------------------*/
reg [3:0] round_cntr;
reg [3:0] target_round;	// 10 round max --> 4 bits

reg sample_initial_mtx;
reg	set_mtx_to_double;
reg set_start_double;
reg	sample_double_out;
reg	increase_cntr;
reg	reset_cntr;
reg	done_rounds;
reg start_double;
reg double_done;

/* ---------------------------------------------------------------------------
---------------------- FINITE-STATE MACHINE ----------------------------
------------------------------------------------------------------------------
"unique case" = A statement that all cases cover
all possibilities and there are not un-addressed situations.
*/
always @(*) begin
	sample_initial_mtx = 1'b0;
	set_mtx_to_double = 1'b0;
	set_start_double = 1'b0;
	sample_double_out = 1'b0;
	increase_cntr = 1'b0;
	reset_cntr = 1'b0;
	done_rounds = 1'b0;
	
	fsm_ns = fsm_ps;
	
	unique case (fsm_ps)
		IDLE: begin
			if (start && (~hashing_done)) begin
				fsm_ns = SAMPLE_INITIAL;
			end
		end
		
		SAMPLE_INITIAL: begin
			sample_initial_mtx = 1'b1;
			fsm_ns = SET_MTX;
		end
		
		SET_MTX: begin
			set_mtx_to_double = 1'b1;
			fsm_ns = COMBO_CYCLE;
		end
		
		COMBO_CYCLE: begin
			set_start_double = 1'b1;
			fsm_ns = WAIT2DOUBLE_DONE;
		end
		
		WAIT2DOUBLE_DONE: begin
			if (double_done) begin
				sample_double_out = 1'b1;
				fsm_ns = SAMPLE_DOB_OUT;
			end
		end
		SAMPLE_DOB_OUT: begin
			fsm_ns = ROUND_CNTR;
		end
		
		ROUND_CNTR: begin
			if (round_cntr[3:0] < (target_round[3:0] - 1'b1)) begin
				increase_cntr = 1'b1;
				fsm_ns = SET_MTX;
			end
			else begin
				reset_cntr = 1'b1;
				fsm_ns = DONE;
			end
		end
		
		DONE: begin
			done_rounds = 1'b1;
			fsm_ns = IDLE;
		end
	endcase
end

/* ---------------------------------------------------------------------------
------------------------ STATE TRANSITIONS -----------------------------------
----------------------------------------------------------------------------*/

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		fsm_ps <= IDLE;
	end
	else begin
		fsm_ps <= fsm_ns;
	end
end

/*--------------------------------------------------------------
------- target_round mux according salsa_round_select ----------
---------------------------------------------------------------*/

always @(*) begin
    case (salsa_round_select[1:0])
        2'b00: target_round[3:0] = 4'd10;  	// double round x 10 = salsa20
        2'b01: target_round[3:0] = 4'd4;  	// double round x 4 = salsa8
        2'b10: target_round[3:0] = 4'd6;  	// double round x 6 = salsa12
        default: target_round[3:0] = 4'd10;	// double round x 10 = salsa20
    endcase
end

/* ---------------------------------------------------------------------------
----------------------------- START_DOUBLE -----------------------------------
----------------------------------------------------------------------------*/

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		start_double <= 1'b0;
	end
	else if (set_start_double) begin
		start_double <= 1'b1;
	end
	else begin
		start_double <= 1'b0;
	end
end

/* ---------------------------------------------------------------------------
------------------------ ROUND CNTR ------------------------------------------
----------------------------------------------------------------------------*/

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		round_cntr[3:0] <= 4'b0;
	end
	else begin
		if (increase_cntr) begin
			round_cntr[3:0] <= round_cntr[3:0] + 1'b1;
		end
		else if (reset_cntr) begin
			round_cntr[3:0] <= 4'b0;
		end
	end
end

/* ---------------------------------------------------------------------------
------------------------------------------------------------------------------
----------------------------------------------------------------------------*/

reg [31:0] initial_mtx_sample [0:3][0:3];
reg [31:0] matrix_in2_duouble [0:3][0:3];
reg [31:0] matrix_out_of_duouble [0:3][0:3];
reg [31:0] matrix_out_of_duouble_sample [0:3][0:3];


always @(posedge clk or negedge rst_n) begin
	for (int i=0; i<4; i=i+1) begin
		for (int j=0; j<4; j=j+1) begin
			// ~rst_n
			if (~rst_n) begin
				initial_mtx_sample[i][j] <= 32'b0;
				matrix_in2_duouble[i][j] <= 32'b0;
				matrix_out_of_duouble_sample[i][j] <= 32'b0;
				salsa_dw_matrix_out[i][j] <= 32'b0;
			end
			else begin
				// sample_initial_mtx
				if (sample_initial_mtx) begin
					initial_mtx_sample[i][j] <= salsa_dw_matrix_in[i][j];
				end
				// set_mtx_to_double:
					// (round_cntr[3:0] == 4'b0) --> the first loop
				else if (set_mtx_to_double && (round_cntr[3:0] == 4'b0)) begin
					matrix_in2_duouble[i][j] <= initial_mtx_sample[i][j];
				end
					// --> NOT the first loop
				else if (set_mtx_to_double) begin
					matrix_in2_duouble[i][j] <= matrix_out_of_duouble[i][j];
				end
				// sample_double_out
				else if (sample_double_out) begin
					matrix_out_of_duouble_sample[i][j] <= matrix_out_of_duouble[i][j];
				end
				// done_rounds
				else if (done_rounds) begin
					salsa_dw_matrix_out[i][j] <= matrix_out_of_duouble_sample[i][j] + initial_mtx_sample[i][j];
				end
			end
		end
	end
end

// hashing_done pulse!
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		hashing_done <= 1'b0;
	end
	else if (done_rounds) begin
		hashing_done <= 1'b1;
	end
	else begin
		hashing_done <= 1'b0;
	end
end

// --------------------------------------------------
// ------- d_r_c_round_interative instance ----------
// --------------------------------------------------

d_r_c_round_interative	u_d_r_c_round_interative(
	// Inputs
	.clk						(clk),
	.rst_n						(rst_n),
	.double_dw_matrix_in		(matrix_in2_duouble),
	.start_double_round			(start_double),	// pulse
	// Outputs
	.double_dw_matrix_out		(matrix_out_of_duouble),
	.double_round_done_valid	(double_done)	// pulse
);

// --------------------------------------------------

endmodule	// hash_interative_with_d_r_c
