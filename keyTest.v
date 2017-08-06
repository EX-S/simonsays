module keyTest(
  input PS2_DAT,
  input PS2_CLK,
  input CLOCK_50,
  input [0:0] KEY,
  output [7:0] LEDR
);
  wire keyPressed;
  wire [2:0] keyCode;
  
  keypressLUT l0 (.CLOCK_50(CLOCK_50), .PS2_DAT(PS2_DAT), .PS2_CLK(PS2_CLK),
  .reset(~KEY[0]), .keyPressed(keyPressed), .keyCode(keyCode));
  
  assign LEDR[0] = (keyCode == 3'd0) & keyPressed;
  assign LEDR[1] = (keyCode == 3'd1) & keyPressed;
  assign LEDR[2] = (keyCode == 3'd2) & keyPressed;
  assign LEDR[3] = (keyCode == 3'd3) & keyPressed;
  assign LEDR[4] = (keyCode == 3'd4) & keyPressed;
  assign LEDR[5] = (keyCode == 3'd5) & keyPressed;
  assign LEDR[6] = (keyCode == 3'd6) & keyPressed;
  assign LEDR[7] = (keyCode == 3'd7) & keyPressed;
endmodule

module keypressLUT(
  input PS2_DAT,
  input PS2_CLK,
  input CLOCK_50,
  input reset,
  output reg [2:0] keyCode,
  output reg keyPressed,
  output reg spacePressed
);

wire valid;
wire makeBreak;
wire [7:0] outCode;

keyboard_press_driver kp0(.CLOCK_50(CLOCK_50), .PS2_DAT(PS2_DAT), .PS2_CLK(PS2_CLK),
  .reset(reset), .valid(valid), .makeBreak(makeBreak), .outCode(outCode));

always @(*) begin
  if (reset == 1'b1) begin
     keyPressed <= 1'b0;
     keyCode <= 3'b0;
  end
  else if (valid == 1'b1 && makeBreak == 1'b1) begin
     keyPressed <= 1'b1;
     keyCode <= 3'd0;
	  spacePressed <= 1'b0;
     case(outCode)
        8'h1C: keyCode <= 3'd0;
        8'h1B: keyCode <= 3'd1;
        8'h23: keyCode <= 3'd2;
        8'h2B: keyCode <= 3'd3;
        8'h34: keyCode <= 3'd4;
        8'h33: keyCode <= 3'd5;
        8'h3B: keyCode <= 3'd6;
        8'h42: keyCode <= 3'd7;
		  8'h29: spacePressed <= 1'b1;
        default: keyPressed <= 1'b0;
      endcase
  end
  else if (valid == 1'b1 && makeBreak == 1'b0) begin
     keyPressed <= 1'b0;
     keyCode <= 3'b0;
  end
end

endmodule