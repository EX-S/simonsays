module audiotop (CLOCK_50, CLOCK2_50, KEY, FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, 
		AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT, SW, en);
	
	input CLOCK_50, CLOCK2_50;
	input [0:0] KEY;

	input [7:0] SW;

	// I2C Audio/Video config interface
	output FPGA_I2C_SCLK;
	inout FPGA_I2C_SDAT;
	// Audio CODEC
	output AUD_XCK;
	input AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK;
	input AUD_ADCDAT;
	output AUD_DACDAT;
	input en;

	// Local wires.
	wire read_ready, write_ready, read, write;
	wire [23:0] readdata_left, readdata_right;
	wire [23:0] writedata_left, writedata_right;
	wire reset = ~KEY[0];
	
	wire [23:0] out;

	reg [2:0] note;
	//reg en;

	always @(*)
	begin
		//en = 1'b1;
		case (SW[7:0])
			8'b0000_0001: note = 3'b000;
			8'b0000_0010: note = 3'b001;
			8'b0000_0100: note = 3'b010;
			8'b0000_1000: note = 3'b011;
			8'b0001_0000: note = 3'b100;
			8'b0010_0000: note = 3'b101;
			8'b0100_0000: note = 3'b110;
			8'b1000_0000: note = 3'b111;
			default: begin
				//en = 1'b0;
				note = 3'b000;
			end
		endcase
	end

	audio a0 (.clk(CLOCK_50), .en(en), .note(note), .reset(reset), .out(out));

	assign writedata_left = out;
	assign writedata_right = out;

	assign read = 1'b0;
	assign write = 1'b1;


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

module sinewave (clk, reset, out);
	input clk;
	input reset;
	output reg [7:0] out;
	
	wire [7:0] sine, cos;
	reg [7:0] sine_r, cos_r;

	assign  sine = sine_r + {cos_r[7], cos_r[7], cos_r[7], cos_r[7:3]};
	assign  cos  = cos_r - {sine[7], sine[7], sine[7], sine[7:3]};

	always @(posedge clk or posedge reset)
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
			out = {1'b1, sine[6:0]};
		else
			out = ~sine;
	end

endmodule

module audio (clk, reset, note, out, en);
	input clk;
	input reset;
	input en;
	input [2:0] note;
	output [23:0] out;
	
	reg [27:0] d;
	wire [27:0] q;
	wire myclk;
	wire [7:0] sine;

	ratedivider r0 (.clk(clk), .reset_n(~reset), .d(d), .en(en), .newclk(myclk));
	
	//assign myclk = (q == 28'b0) ? 1'b1 : 1'b0;
	
	always @(*)
	begin
		case (note)
			3'b000: d = 28'd23888;
			3'b001: d = 28'd21264;
			3'b010: d = 28'd18961;
			3'b011: d = 28'd17896;
			3'b100: d = 28'd15943;
			3'b101: d = 28'd14204;
			3'b110: d = 28'd12655;
			3'b111: d = 28'd11944;
			default: d = 28'd0;
		endcase
	end
	
	sinewave s0 (.clk(myclk), .reset(reset), .out(sine));
		
	assign out = {{8'b0, sine}, 8'b0} * 10;

endmodule
