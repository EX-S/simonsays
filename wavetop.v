module wavetop(SW,KEY,LEDR,CLOCK_50);
	input [9:0] SW;
	input [3:0] KEY;
	input CLOCK_50;
	output [9:0] LEDR;
	
	wire [23:0] out;
	
	wave w0(.clk(CLOCK_50),.inc(SW), .reset(KEY[0]), .out(out));
	assign LEDR[9:0] = out[9:0];
	
endmodule

module wave(clk, inc, out, reset);
	input clk;
	input [24:0] inc;
	input reset;
	output reg [23:0] out;
	
	reg [24:0] timer;
	
	always @(posedge clk)
	begin
		if(reset == 1'b1)
		begin
			timer <= 0;
			out <= 0;
		end
		else if(timer[24] == 1'b1)
			out <= out - inc;
		else
			out <= out - inc;
		timer <= timer + 1'b1;
	end

endmodule