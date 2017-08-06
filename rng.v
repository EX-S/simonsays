module rng(SW, LEDR, KEY);
	input [9:0] SW;
	input [3:0] KEY;
	output [9:0] LEDR;
	wire out;
	lfsr l0(.regi(LEDR[9:0]), .load(KEY[0]), .load_val(SW[9:0]), .clk(~KEY[3]));
	

endmodule

module lfsr(regi, load, load_val, clk, out);
	input load;
	input [9:0] load_val;
	input clk;
	output reg [9:0] regi;
	output reg out;
	
	always @(negedge load, posedge clk)
	begin
		if (~load) regi <= load_val;
		else begin
			out <= regi[9];
			regi <= {regi[8:0], (regi[4] ^ regi[7]) ^ regi[3]};
		end
	
	end
	
endmodule 