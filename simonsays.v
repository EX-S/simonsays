module simonsays(KEY, CLOCK_50, LEDR, SW, HEX0, HEX1, HEX5, HEX4, HEX2, HEX3, 
 CLOCK2_50, FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, 
		AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT, PS2_DAT, PS2_CLK);
	input [3:0] KEY;
	input CLOCK_50;
	input [9:0] SW;
	input PS2_DAT;
	input PS2_CLK;
	output [9:0] LEDR;
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX5;
	input CLOCK2_50;
		output [6:0] HEX4;
		output [6:0] HEX2;
		output [6:0] HEX3;
	
	// I2C Audio/Video config interface
	output FPGA_I2C_SCLK;
	inout FPGA_I2C_SDAT;
	// Audio CODEC
	output AUD_XCK;
	input AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK;
	input AUD_ADCDAT;
	output AUD_DACDAT;

	//assign go = ~KEY[1];
	
	wire [1:0] aud_sel;
	wire timer, more_notes, load_n, get_time, get_key, check_key, get_release, check_time, playdone;
	wire [7:0] out;
	wire aud_en;
	wire [3:0] state;
	wire [2:0] signal;
	wire [3:0] current_note;
	wire temp;
	wire [1:0] play_length;
	wire [2:0] play_note;
	assign temp = signal[0] | signal[1];
	wire keyPressed;
	wire [7:0] score;
	wire inc;
	
	control c0 (.clk(CLOCK_50), .reset_n(~KEY[0]), .go(go&keyPressed), .timer(timer), .more_notes(more_notes), 
	.keyPressed(keyPressed), .correct(correct), .correct_time(correct_time), .aud_sel(aud_sel),
	.load_n(load_n), .get_time(get_time), .get_key(get_key), .check_key(check_key), .get_release(get_release),
	.check_time(check_time), .current_state(state), .signal(signal), .play_done(playdone), .inc(inc));
	
	data_path d0 (.clk(CLOCK_50), .reset_n(~KEY[0]), .timer(timer), .more_notes(more_notes),
	.keyPressed(keyPressed), .correct(correct), .correct_time(correct_time), .aud_sel(aud_sel),
	.load_n(~temp), .get_time(get_time), .get_key(get_key), .check_key(check_key), .get_release(get_release),
	.check_time(check_time), .out(out), .aud_en(aud_en), .round(LEDR), .signal(signal), .current_note(current_note),
	.SW(SW[7:0]),.play_length(play_length),.play_note(play_note), .play_done(playdone), .score(score), .inc(inc),
	.PS2_DAT(PS2_DAT), .PS2_CLK(PS2_CLK), .go(go));
	
	audiotop a0 (
		.CLOCK_50(CLOCK_50), .CLOCK2_50(CLOCK2_50), .KEY(KEY), .FPGA_I2C_SCLK(FPGA_I2C_SCLK), .FPGA_I2C_SDAT(FPGA_I2C_SDAT), .AUD_XCK(AUD_XCK), 
		.AUD_DACLRCK(AUD_DACLRCK), .AUD_ADCLRCK(AUD_ADCLRCK), .AUD_BCLK(AUD_BCLK), .AUD_ADCDAT(AUD_ADCDAT), .AUD_DACDAT(AUD_DACDAT), .SW(out), .en(aud_en));
	
	decoder u0 (.num(state), .display(HEX0));
	decoder u1 (.num({1'b0,signal}), .display(HEX1));
//	decoder u5 (.num({3'b0, correct_time}), .display(HEX5));
//	decoder u4 (.num({3'b0, correct}), .display(HEX4));
	decoder u5 (.num(score/10), .display(HEX5));
	decoder u4 (.num(score%10), .display(HEX4));
//	decoder u5 (.num({1'b0, keyPressed}), .display(HEX5));
	decoder u2 (.num({2'b0, play_length}), .display(HEX2));
	decoder u3 (.num({1'b0, play_note}+1), .display(HEX3));
	
	//assign LEDR[0]
	//assign LEDR[7:0] = out[7:0];
	//assign LEDR[0] = timer;
	//assign LEDR[1] = more_notes;
		
endmodule

module control(
	input clk,
	input reset_n,
	input go,
	input timer,
	input more_notes,
	input keyPressed,
	input correct,
	input correct_time,
	input play_done,
	output reg [1:0] aud_sel,
	output reg load_n,
	output reg get_time,
	output reg get_key,
	output reg check_key,
	output reg get_release,
	output reg check_time,
	output reg [3:0] current_state,
	output reg [2:0] signal,
	output reg delay,
	output reg delay_go,
	output reg inc);
	
	//reg [3:0] current_state, next_state;
	reg [3:0] next_state;
	
	localparam  WAIT        = 4'd0,
               START   		= 4'd1,
               BEGINROUND	= 4'd2,
               LOAD	   	= 4'd3,
               LOAD_1      = 4'd4,
               LOAD_2   	= 4'd5,
               LOAD_3      = 4'd6,
               CHECKEMPTY  = 4'd7,
               PLAY        = 4'd8,
               USERSTART   = 4'd9,
               FAIL      	= 4'd10,
					TIME			= 4'd11,
					USERLOAD 	= 4'd12,
					USERPLAY		= 4'd13,
					KEYCHECK		= 4'd14,
					TIMECHECK	= 4'd15;
					
	always @(negedge clk)
	begin: state_table
		case (current_state)
			WAIT: next_state = go ? START : WAIT;
			START: next_state = go ? START : BEGINROUND;
			BEGINROUND : next_state = LOAD;
			LOAD: next_state = TIME;
			TIME: next_state = PLAY;
			PLAY: next_state = timer ? (more_notes ? TIME : USERLOAD) : PLAY;
			USERLOAD: next_state = CHECKEMPTY;
			CHECKEMPTY: next_state = play_done ? WAIT : USERSTART;
			USERSTART: next_state = keyPressed ? LOAD_2 : USERSTART;
			LOAD_2: next_state = LOAD_3; //go ? LOAD_3 : LOAD_2;
			LOAD_3: next_state = timer ? KEYCHECK : LOAD_3;
			//LOAD_3: next_state = go ? LOAD_3 : KEYCHECK;
			KEYCHECK: next_state = correct ? LOAD_1 : FAIL;
			LOAD_1: next_state = USERPLAY;
			USERPLAY: next_state = (keyPressed & correct_time) ? USERPLAY : TIMECHECK;
			TIMECHECK: next_state = correct_time ? USERLOAD : FAIL;
			FAIL: next_state = FAIL;
			default: next_state = WAIT;
		endcase
		
	end
	
	always @(negedge clk)
	begin: outputs		
		aud_sel = 2'b0;
		load_n = 1'b0;
		get_time = 1'b0;
		get_key = 1'b0;
		check_key = 1'b0;
		get_release = 1'b0;
		check_time = 1'b0;
		signal = 3'b11;
		delay = 1'b0;
		delay_go = 1'b0;
		inc <= 1'b0;
		
		case (current_state)
		CHECKEMPTY: inc <= 1'b1;
		LOAD: signal <= 3'd0; //load_n = 1'b1;
		TIME: signal <= 3'd1; //get_time <= 1'b1;
		PLAY: begin
			signal <= 3'd2;
			aud_sel = 2'b1;
		end
		USERLOAD: signal <= 3'd4; //get_key = 1'b1;
		KEYCHECK: begin
			check_key = 1'b1;
			aud_sel = 2'b10;
		end
		USERPLAY: begin 
			aud_sel = 2'b10;
			get_release = 1'b0;
		end
		TIMECHECK: check_time = 1'b1;
		LOAD_2: delay = 1'b1;
		LOAD_3: begin
			delay_go = 1'b1;
			aud_sel = 2'b10;
		end
		endcase
	end
	
	always @(posedge clk) 
   begin: state_FFs
        if (reset_n)
            current_state <= WAIT;
        else
            current_state <= next_state;
    end
endmodule

module data_path(
	input [7:0] SW,
	input clk,
	input reset_n,
	input [1:0] aud_sel,
	input load_n,
	input get_time,
	input get_key,
	input check_key,
	input get_release,
	input check_time,
	input PS2_DAT,
	input PS2_CLK,
	input [2:0] signal,
	input delay,
	input delay_go,
	input inc,
	output timer,
	output more_notes,
	output keyPressed,
	output correct,
	output reg correct_time,
	output play_done,
	output [7:0] out,
	output aud_en,
	output [9:0] round,
	output reg [2:0] current_note,
	output [2:0] play_note,
	output [1:0] play_length,
	output reg [7:0] score,
	output go
);
	
	wire [9:0] rng;
	wire bit;
	reg [99:0] roundinfo;
	reg [99:0] thisround;
	reg [99:0] playcheck;
	
	assign round = playcheck[9:0];
	
	//wire [2:0] key_pressed;
	reg [2:0] correct_note;
	
	reg [2:0] t;
	
	wire [23:0] out_aud;
	reg [27:0] d;
	//wire [27:0] q;
	wire [2:0] keyCode;
	reg timer_reset;
	reg [27:0] ideal_time;
	reg [27:0] time_held;
	reg [4:0] current_play;
	reg temp;
	
	lfsr l0 (.regi(rng), .load(~reset_n), .load_val(10'd412), .clk(clk), .out(bit));
	
	ratedivider r0 (.clk(clk), .reset_n(timer_reset), .d(d), .en(1'b1), .newclk(timer));
	assign play_note = current_play[4:2];
	assign play_length = current_play[1:0];
	keypressLUT k0 (.spacePressed(go), .CLOCK_50(clk), .PS2_DAT(PS2_DAT), .PS2_CLK(PS2_CLK), .reset(reset_n), .keyCode(keyCode), .keyPressed(keyPressed));
	//assign keyPressed = |{SW[7:0]};
//	always @(posedge clk) begin
//		case(SW[7:0])
//			8'b0000_0001: begin
//				keyCode <= 3'd0;
//				keyPressed <= 1'b1;
//			end
//			8'b0000_0010: begin
//				keyCode <= 3'd1;
//				keyPressed <= 1'b1;
//			end
//			8'b0000_0100: begin
//				keyCode <= 3'd2;
//				keyPressed <= 1'b1;
//			end
//			8'b0000_1000: begin
//				keyCode <= 3'd3;
//				keyPressed <= 1'b1;
//			end
//			8'b0001_0000: begin
//				keyCode <= 3'd4;
//				keyPressed <= 1'b1;
//			end
//			8'b0010_0000: begin
//				keyCode <= 3'd5;
//				keyPressed <= 1'b1;
//			end
//			8'b0100_0000: begin
//				keyCode <= 3'd6;
//				keyPressed <= 1'b1;
//			end
//			8'b1000_0000: begin
//				keyCode <= 3'd7;
//				keyPressed <= 1'b1;
//			end
//			default: begin
//				keyCode <= 3'b0;
//				keyPressed <= 1'b0;
//			end
//		endcase
//	end
	
	//assign timer = (q == 0);
	assign more_notes = (thisround != 100'b0);
	assign correct = keyCode == current_play[4:2];
	assign play_done = (playcheck == 100'b0) & (current_play == 5'b0);
	
	always @(*) begin
		
		case(aud_sel)
		2'b0: current_note <= 3'b0;
		2'b1: current_note <= correct_note;
		2'b10: current_note <= keyCode;
		endcase
		case(current_play[1:0])
		2'd0: ideal_time <= 28'd24999999;
		2'd1: ideal_time <= 28'd49999999;
		2'd2: ideal_time <= 28'd99999999;
		2'd3: ideal_time <= 28'd149999999;
		endcase
		case (t)
				3'b000: d <= 28'd24999999;
				3'b001: d <= 28'd49999999;
				3'b010: d <= 28'd99999999;
				3'd011: d <= 28'd149999999;
				default: d <= 28'd500000;
		endcase
	end

	always @(*)
	begin
		if (keyPressed == 1 && (time_held[27:0] <= (ideal_time[27:0] + 28'd12499999))) correct_time = 1'b1;
		else if (keyPressed == 0 && (ideal_time[27:0] <= (time_held[27:0] + 28'd19999999))) correct_time = 1'b1;
		else correct_time = 1'b0;
	end

	always @(posedge clk) begin
		t <= 3'b100;
		if (reset_n == 1) begin
			temp <= 1;
			roundinfo <= 0;
			thisround <= 0;
			playcheck <= 0;
			current_play <= 0;
			correct_note <= 0;
			score <= 0;
		end
		else if (delay == 1'b1) begin
			timer_reset <= 1'b0;
		end
		else if (delay_go == 1'b1) begin
			timer_reset <= 1'b1;
		end
		else if (signal == 3'd2) begin//aud_sel[0] == 1) begin
			timer_reset <= 1'b1;
		end
		else if (signal == 3'd4) begin //get_key == 1'b1) begin
				current_play <= playcheck[4:0];
				playcheck <= playcheck >> 5;
		end
		else if (signal == 3'd0) begin//load_n == 1'b1) begin
			roundinfo <= {roundinfo[94:0], rng[2:1], temp, 1'b0, rng[0:0]};
			thisround <= roundinfo;
			playcheck <= roundinfo;
			temp <= ~temp;
			current_play <= 0;
			correct_note <= 0;
//			score <= (play_done == 1'b1) ? score : score+1;
		end
		else if (signal == 3'd1) begin//get_time == 1) begin
			t <= thisround[1:0];
			correct_note <= thisround[4:2];
			thisround <= thisround >> 5;
			timer_reset <= 1'b0;
//			score <= score + 1;
		end
		else if(inc == 1'b1)
			score <= (play_done == 1'b1) ? score + 1 : score;
	end

	always @(posedge clk) begin
		if (check_key == 1'b1) time_held <= 0;
		else if (aud_sel == 2'b10) time_held <= time_held+1;
		
	end
	
	  assign out[0] = (current_note == 3'd0);
	  assign out[1] = (current_note == 3'd1);
	  assign out[2] = (current_note == 3'd2);
	  assign out[3] = (current_note == 3'd3);
	  assign out[4] = (current_note == 3'd4);
	  assign out[5] = (current_note == 3'd5);
	  assign out[6] = (current_note == 3'd6);
	  assign out[7] = (current_note == 3'd7);
	  assign aud_en = (aud_sel != 0);
endmodule
