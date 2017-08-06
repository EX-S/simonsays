module noteplayer (CLOCK_50, CLOCK2_50, KEY, FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, 
		AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT, SW, LEDR);
		
		output [9:0] LEDR;
		input CLOCK_50, CLOCK2_50;
	input [1:0] KEY;
	// I2C Audio/Video config interface
	output FPGA_I2C_SCLK;
	inout FPGA_I2C_SDAT;
	// Audio CODEC
	output AUD_XCK;
	input AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK;
	input AUD_ADCDAT;
	output AUD_DACDAT;
	
	input [4:0] SW;
		wire [7:0] out;
		
		reg [27:0] d;
		wire [27:0] q;
		wire en;
		
  assign out[0] = (SW[4:2] == 3'd0) & en;
  assign out[1] = (SW[4:2] == 3'd1) & en;
  assign out[2] = (SW[4:2] == 3'd2) & en;
  assign out[3] = (SW[4:2] == 3'd3) & en;
  assign out[4] = (SW[4:2] == 3'd4) & en;
  assign out[5] = (SW[4:2] == 3'd5) & en;
  assign out[6] = (SW[4:2] == 3'd6) & en;
  assign out[7] = (SW[4:2] == 3'd7) & en;
		
	always @(*) begin
		if (~KEY[1]) begin
		case (SW[1:0])
			2'd0: d <= 28'd12499999;
			2'd1: d <= 28'd24999999;
			2'd2: d <= 28'd37499999;
			2'd3: d <= 28'd49999999;
		endcase
		end
	end
		
	ratedivider r0 (.clk(CLOCK_50), .reset_n(KEY), .d(d), .q(q), .en(en));
	
	assign en = ~KEY[1] | ~(q == d);
	assign LEDR[0] = en;
	
	
		audiotop a0 (
		.CLOCK_50(CLOCK_50), .CLOCK2_50(CLOCK2_50), .KEY(KEY[0]), .FPGA_I2C_SCLK(FPGA_I2C_SCLK), .FPGA_I2C_SDAT(FPGA_I2C_SDAT), .AUD_XCK(AUD_XCK), 
		.AUD_DACLRCK(AUD_DACLRCK), .AUD_ADCLRCK(AUD_ADCLRCK), .AUD_BCLK(AUD_BCLK), .AUD_ADCDAT(AUD_ADCDAT), .AUD_DACDAT(AUD_DACDAT), 
		.SW(out));
		
endmodule