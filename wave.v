module wavetop();

endmodule

module wave(clk, inc, out, reset);
	input clk;
	input inc;
	input reset;
	output reg [23:0] out;
	
	reg [28:0] timer;
	
	always @(posedge clk)
	begin
		if(reset == 1)
		begin
			timer <= 0;
			out <= 0;
		end
		if(out == 0)
			timer <= 0;
		else
			timer = timer + 1;
		if(timer[23] == 0)
			out <= out + inc;
		else
			out <= out - inc;
	end

endmodule