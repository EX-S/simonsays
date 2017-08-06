module part1 (CLOCK_50, CLOCK2_50, KEY, FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, 
		        AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT,
				  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, SW, LEDR);

	input CLOCK_50, CLOCK2_50;
	input [0:0] KEY;
	
	input [9:0] SW;
	output [9:0] LEDR;
	// I2C Audio/Video config interface
	output FPGA_I2C_SCLK;
	inout FPGA_I2C_SDAT;
	// Audio CODEC
	output AUD_XCK;
	input AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK;
	input AUD_ADCDAT;
	output AUD_DACDAT;
	// HEX display
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	output [6:0] HEX4;
	output [6:0] HEX5;
	
	// Local wires.
	wire read_ready, write_ready, read, write;
	wire [23:0] readdata_left, readdata_right;
	wire [23:0] writedata_left, writedata_right;
	wire reset = ~KEY[0];
	
	wire [27:0] rate;
	wire clk;
	
	reg [23:0] fre;
	reg [23:0] inc;
	reg [24:0] timer;
	
	reg [27:0] init;
	
	reg [23:0] hex_in;
	
	wire [7:0] sine,cos;
   reg [7:0] sine_r, cos_r;
	
	/////////////////////////////////
	// Your code goes here 
	/////////////////////////////////
	
	always @(*)
	begin
		case (SW[7:0])
			8'b0000_0001: init = 28'd23888;
			8'b0000_0010: init = 28'd21264;
			8'b0000_0100: init = 28'd18961;
			8'b0000_1000: init = 28'd17896;
			8'b0001_0000: init = 28'd15943;
			8'b0010_0000: init = 28'd14204;
			8'b0100_0000: init = 28'd12655;
			8'b1000_0000: init = 28'd11944;
			default: init = 28'b0;
		endcase
	end
	
	
	ratedivider r0 (.clk(CLOCK_50), .reset_n(KEY[0]), .d(init), .q(rate), .en(1'b1));
	
	assign clk = (rate == 0) ? 1 : 0;
	/*
	always @(posedge clk)
	begin
		hex_in <= readdata_left;
	end
	*/
	
   assign  sine = sine_r + {cos_r[7], cos_r[7], cos_r[7], cos_r[7:3]};
   assign  cos  = cos_r - {sine[7], sine[7], sine[7], sine[7:3]};
   always@(posedge clk or posedge reset)
     begin
         if (reset == 1) begin
             sine_r <= 0;
             cos_r <= 120;
         end else begin
              sine_r <= sine;
              cos_r <= cos;
         end
     end
	  
	always @(*)
	begin
		if(sine[7] == 0)
			fre[8:0] = {1'b1, sine};
		else
			fre[8:0] = {2'b00, sine[6:0]};
	end
	
	assign writedata_left = {{4'b000, fre[8:0]}, 11'b0};
	assign writedata_right = {{4'b000, fre[8:0]}, 11'b0};
	
	//assign writedata_left = readdata_left; // not shown
	//assign writedata_right = readdata_right; // not shown
	//assign writedata_left = fre;
	//assign writedata_right = fre;
	//assign read = 1'b1; // not shown
	assign read = 1'b0;
	assign write = 1'b1; // not shown
	
	decoder d0 (.num(hex_in[3:0]), .display(HEX0));
	decoder d1 (.num(hex_in[7:4]), .display(HEX1));
	decoder d2 (.num(hex_in[11:8]), .display(HEX2));
	decoder d3 (.num(hex_in[15:12]), .display(HEX3));
	decoder d4 (.num(hex_in[19:16]), .display(HEX4));
	decoder d5 (.num(hex_in[23:20]), .display(HEX5));
	
	//assign LEDR[0] = AUD_XCK;
	
/////////////////////////////////////////////////////////////////////////////////
// Audio CODEC interface. 
//
// The interface consists of the following wires:
// read_ready, write_ready - CODEC ready for read/write operation 
// readdata_left, readdata_right - left and right channel data from the CODEC
// read - send data from the CODEC (both channels)
// writedata_left, writedata_right - left and right channel data to the CODEC
// write - send data to the CODEC (both channels)
// AUD_* - should connect to top-level entity I/O of the same name.
//         These signals go directly to the Audio CODEC
// I2C_* - should connect to top-level entity I/O of the same name.
//         These signals go directly to the Audio/Video Config module
/////////////////////////////////////////////////////////////////////////////////
	clock_generator my_clock_gen(
		// inputs
		CLOCK2_50,
		reset,

		// outputs
		AUD_XCK
	);

	audio_and_video_config cfg(
		// Inputs
		CLOCK_50,
		reset,

		// Bidirectionals
		FPGA_I2C_SDAT,
		FPGA_I2C_SCLK
	);

	audio_codec codec(
		// Inputs
		CLOCK_50,
		reset,

		read,	write,
		writedata_left, writedata_right,

		AUD_ADCDAT,

		// Bidirectionals
		AUD_BCLK,
		AUD_ADCLRCK,
		AUD_DACLRCK,

		// Outputs
		read_ready, write_ready,
		readdata_left, readdata_right,
		AUD_DACDAT
	);

endmodule


