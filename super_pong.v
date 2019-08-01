`timescale 1ns / 1ns

//------------------------------------------------------------------------------
//
//Welcome to super pong!
//Here are the controls:
//Player 1 controls the left and right paddle
//SW 0 for right, SW 1 for left
//Player 2 controls the top and bottom paddle
//SW 16 for bottom, SW 17 for top
//
//The 2 players are to co-op to reach a high score! The level of the game will in crease
//based on how much score you accumilated, and the difficulty will increase with each level
//adding new tricks!
//
//The 7 segment displays shows you the current level, your life left, and your score respectively
//
//KEY0 is the reset button, after gameover, you can reset the game and start again
//
//Good luck and have fun!
//
//-------------------------------------------------------------------------------
module super_pong
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
      KEY,
      SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,						//	VGA Blue[9:0]
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		HEX4,
		HEX5,
		HEX6,
		HEX7
	);

	input			CLOCK_50;				//	50 MHz
	input   [17:0]   SW;
	input   [3:0]   KEY;

	//VGA Adapter 
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	output [6:0] HEX4;
	output [6:0] HEX5;
	output [6:0] HEX6;
	output [6:0] HEX7;
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;



	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
		
	wire [11:0] final_score;
	wire [11:0] final_life;
	wire [11:0] final_level;
	wire [6:0] temp;
	wire [6:0] temp1;
	wire [6:0] temp2;
	wire [6:0] temp3;

	//main game module
	main m0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.SW(SW [17:0]),
		.KEY(KEY[3:0]),
		.x(x),
		.y(y),
		.colour(colour),
		.final_score(final_score),
		.final_life(final_life),
		.final_level(final_level)
	); 
	
	score_decoder s0(
		.score(final_score),
		.seg0(HEX0),
		.seg1(HEX1),
		.seg2(HEX2),
		.seg3(HEX3)
		);
	score_decoder s1(
		.score(final_life),
		.seg0(HEX4),
		.seg1(HEX5),
		.seg2(temp),
		.seg3(temp1)
		);
	score_decoder s2(
		.score(final_level),
		.seg0(HEX6),
		.seg1(HEX7),
		.seg2(temp2),
		.seg3(temp3)
		);
		
endmodule

module main(
	input clk,
	input resetn,
	input [17:0] SW,
   input [3:0]  KEY,
	
	output reg [7:0] x,
	output reg [6:0] y,
	output reg [2:0] colour,
	output reg [11:0] final_score,
	output reg [11:0] final_life,
	output reg [11:0] final_level
	);
	
	// declare any variable needed for gameplay logic
	
	integer paddle_length = 25; 
	integer paddle_left = 47;
	integer paddle_right = 47;
	integer paddle_top = 67;
	integer paddle_bottom = 67;
	integer End;
	integer End2;
	integer i;
	integer j;
	integer toward_left = 0; 
	integer toward_right = 1;
   integer toward_up =1; 
	integer toward_down = 0;
	integer toward_left2 = 0; 
	integer toward_right2 = 1;
   integer toward_up2 =1; 
	integer toward_down2 = 0;
	integer ball_x = 80;
	integer ball_y = 60;
	integer ball_x2 = 80;
	integer ball_y2 = 60;
	integer life = 15;
	integer score = 0;
	integer level = 1;
	integer gameover = 0;
	wire enable, pol;
   	
	
	//rate devider to select speed
	RateDivider rate(
        .switch(1'b1),
        .clock(clk),
        .Enable(enable),
        .clear_b(1'b1));
		  
	wire plot;
	
	always @(posedge clk)
	begin
	//gameplay logic here
	
	if (enable)
	begin
				//reset
				if (resetn == 1'b0)
					begin
						paddle_left = 47;
						paddle_right = 47;
						paddle_top = 67;
						paddle_bottom = 67;
						toward_left = 0; 
						toward_right = 1;
						toward_up =1; 
						toward_down = 0;
						toward_left2 = 0; 
						toward_right2 = 1;
						toward_up2 =1; 
						toward_down2 = 0;
						ball_x = 80;
						ball_y = 60;
						ball_x2 = 80;
						ball_y2 = 60;
						life = 15;
						score = 0;
						level = 1;
						gameover = 0;
					end
				if (score == 100)
					level = 2;
				if (score == 200)
					level = 3;

				//move ball based on their direction
				if(toward_left == 1)
                ball_x = ball_x - 1;
            else if(toward_right == 1)
                ball_x = ball_x + 1;
            if(toward_up == 1)
                ball_y = ball_y - 1;				
            else if(toward_down == 1)
                ball_y = ball_y + 1;
					
				if (level >= 2)
				begin
					if(toward_left2 == 1)
						 ball_x2 = ball_x2 - 1;
					else if(toward_right2 == 1)
						 ball_x2 = ball_x2 + 1;
					if(toward_up2 == 1)
						 ball_y2 = ball_y2 - 1;				
					else if(toward_down2 == 1)
						 ball_y2 = ball_y2 + 1;
				end
				
            // ball touches left side of screen and left paddle
            if(ball_x == 6 && ball_y <= paddle_left + 25 && ball_y >= paddle_left)       
                begin
                    toward_right = 1;       // bounce to right, game continues...
                    toward_left = 0;		
						  ball_x = ball_x + 2;
						  if(gameover == 0)
							score = score + 10;
					end
            else if(ball_x <= 1)
                End = 1;

            // ball touches right side of screen
            if(ball_x == 154 && ball_y <= paddle_right + 25 && ball_y >= paddle_right)     
                begin
                    toward_left = 1;        // bounce to left
                    toward_right = 0;
						  ball_x = ball_x - 2;
						  if(gameover == 0)
							score = score + 10;
					end	
            else if(ball_x >= 158)
                End = 1;
				
				// ball touches top of screen
            if(ball_y == 6 && ball_x >= paddle_top && ball_x <= paddle_top  +25)       
                begin
                    toward_down = 1;;
                    toward_up = 0;
						  ball_y = ball_y + 2;
						  if(gameover == 0)
						  score = score + 10;
					end
				else if(ball_y <= 1)
                End = 1;
				// ball touches bottom of screen
				if(ball_y == 114 && ball_x >= paddle_bottom  && ball_x <= paddle_bottom + 25)     
						 begin
							  toward_up = 1;
							  toward_down = 0;
							  ball_y = ball_y - 2;
							  if(gameover == 0)
							  score = score + 10;
						end
					else if (ball_y >= 119)
						 End = 1;
            
            
				//if we hit level 2, add another ball
				if (level >= 2)
				begin
				// ball touches left side of screen and left paddle
					if(ball_x2 == 6 && ball_y2 <= paddle_left + 25 && ball_y2 >= paddle_left)       
						begin
							toward_right2 = 1;
							toward_left2 = 0;
							ball_x2 = ball_x2 + 2;
							if(gameover == 0)
							  score = score + 10;
						end
					else if(ball_x2 <= 1)
						End2 = 1;

					// ball touches right side of screen
					if(ball_x2 == 154 && ball_y2 <= paddle_right + 25 && ball_y2 >= paddle_right)     
						begin
							  toward_left2 = 1;        //; bounce to left
							  toward_right2 = 0;
							  ball_x2 = ball_x2 - 2;
							  if(gameover == 0)
							  score = score + 10;
						end
					else if(ball_x2 >= 158)
						 End2 = 1;
					
					// ball touches top of screen
					if(ball_y2 == 6 && ball_x2 >= paddle_top && ball_x2 <= paddle_top  +25)       
						 begin
							  toward_down2 = 1;
							  toward_up2 = 0;
							  ball_y2 = ball_y2 + 2;
							  if(gameover == 0)
							  score = score + 10;
						end
					else if(ball_y2 <= 1)
						End2 = 1;
					// ball touches bottom of screenpaddle_left
					if(ball_y2 == 114 && ball_x2 >= paddle_bottom  && ball_x2 <= paddle_bottom + 25)     
						 begin
							  toward_up2 = 1;
							  toward_down2 = 0;
							  ball_y2 = ball_y2 - 2;
							  if(gameover == 0)
							  score = score + 10;
						end
					else if (ball_y2 >= 119)
						 End2 = 1;
					end
				
				
			// ball hits the barriers from right
			if(level == 3)
			begin
			if ((ball_x == 41 && ball_y <= 21 && ball_y >= 19) || (ball_x == 121 && ball_y <= 40 && ball_y >= 20) || (ball_x == 31 && ball_y <= 100 && ball_y >= 80) || (ball_x == 131 && ball_y <= 91 && ball_y >= 89))
				begin
					toward_right = 1'b1;        // bounce back to right
					toward_left = 1'b0;
				end

			// hits from left
			if ((ball_x == 19 && ball_y <= 21 && ball_y >= 19) || (ball_x == 119 && ball_y <= 40 && ball_y >= 20) || (ball_x == 29 && ball_y <= 100 && ball_y >= 80) || (ball_x == 109 && ball_y <= 91 && ball_y >= 89))
				begin
					toward_left = 1'b1;         
					toward_right = 1'b1;
				end

			// hits from top
			if ((ball_y == 19 && ball_x <= 40 && ball_x >= 20) || (ball_y == 19 && ball_x <= 121 && ball_x >= 119) || (ball_y == 79 && ball_x <= 31 && ball_x >= 29) || (ball_y == 89 && ball_x <= 130 && ball_x >= 110))
				begin  
					toward_up = 1'b1;          // bounce back to top
					toward_down = 1'b0;
				end
                
			// hits from bottom
			if ((ball_y == 21 && ball_x <= 40 && ball_x >= 20) || (ball_y == 41 && ball_x <= 121 && ball_x >= 119) || (ball_y == 101 && ball_x <= 31 && ball_x >= 29) || (ball_y == 91 && ball_x <= 130 && ball_x >= 110))
				begin   
					toward_down = 1'b1;
					toward_up = 1'b0;
				end
			end
			
			if (level == 3)
			begin
			// ball hits the barriers from right
				if ((ball_x2 == 41 && ball_y2 <= 21 && ball_y2 >= 19) || (ball_x2 == 121 && ball_y2 <= 40 && ball_y2 >= 20) || (ball_x2 == 31 && ball_y2 <= 100 && ball_y2 >= 80) || (ball_x2 == 131 && ball_y2 <= 91 && ball_y2 >= 89))
					begin
						toward_right2 = 1'b1;        // bounce back to right
						toward_left2 = 1'b0;
					end

				// hits from left
				if ((ball_x2 == 19 && ball_y2 <= 21 && ball_y2 >= 19) || (ball_x2 == 119 && ball_y2 <= 40 && ball_y2 >= 20) || (ball_x2 == 29 && ball_y2 <= 100 && ball_y2 >= 80) || (ball_x2 == 109 && ball_y2 <= 91 && ball_y2 >= 89))
					begin
						toward_left2 = 1'b1;         
						toward_right2 = 1'b1;
					end

				// hits from top
				if ((ball_y2 == 19 && ball_x2 <= 40 && ball_x2 >= 20) || (ball_y2 == 19 && ball_x2 <= 121 && ball_x2 >= 119) || (ball_y2 == 79 && ball_x2 <= 31 && ball_x2 >= 29) || (ball_y2 == 89 && ball_x2 <= 130 && ball_x2 >= 110))
					begin  
						toward_up2 = 1'b1;          // bounce back to top
						toward_down2 = 1'b0;
					end
						 
				// hits from bottom
				if ((ball_y2 == 21 && ball_x2 <= 40 && ball_x2 >= 20) || (ball_y2 == 41 && ball_x2 <= 121 && ball_x2 >= 119) || (ball_y2 == 101 && ball_x2 <= 31 && ball_x2 >= 29) || (ball_y2 == 91 && ball_x2 <= 130 && ball_x2 >= 110))
					begin   
						toward_down2 = 1'b1;
						toward_up2 = 1'b0;
					end
			end
			
		final_score = score;
		final_life = life;
		final_level = level;
		
		//end game conditions
		if ((End == 1) && (life>0))
			begin
				ball_x = 80;
				ball_y = 60;
				life = life - 1;
				End = 0;
			end
		if ((End2 == 1) && (life>0))
			begin
				ball_x2 = 80;
				ball_y2 = 60;
				End2 = 0;
				life = life -1;
			end
		if (life == 0)
			gameover = 1;
			
		//controls
		
		if (SW[1] == 1'b1 && paddle_left >= 5)
			paddle_left = paddle_left - 4;
		else if (SW[1] == 1'b0 && paddle_left <=90)
			paddle_left = paddle_left + 4;
			
		if (SW[0] == 1'b1 && paddle_right >= 5)
			paddle_right = paddle_right - 4;
		else if (SW[0] == 1'b0 && paddle_right <=90)
			paddle_right = paddle_right + 4;

		if (SW[17] == 1'b1 && paddle_top <= 133)
			paddle_top = paddle_top + 4;
		else if (SW[17] == 1'b0 && paddle_top >= 5)
			paddle_top = paddle_top - 4;
			
		if (SW[16] == 1'b1 && paddle_bottom <=133)
			paddle_bottom = paddle_bottom + 4;
		else if (SW[16] == 1'b0 && paddle_bottom >= 5)
			paddle_bottom = paddle_bottom - 4;

	end

	// determine the colour based on where the index is right now
	//disclaimer: this section of the code was written with reference of another group's project
	//https://github.com/Hunter833838/B58-Pong


	if (x == ball_x && y == ball_y)
		colour = 3'b111;
	else if (x == ball_x2 && y == ball_y2 && level >= 2)
		colour = 3'b111;
	else if(paddle_left < y && y < paddle_left + 25 && x <= 5 && x >= 0)
		colour = 3'b111;
	else if(paddle_right < y && y < paddle_right+ 25 && x >= 155 && x <= 160)
		colour = 3'b111;
	else if(paddle_top < x && x < paddle_top + 25 && y <  6)
		colour = 3'b111;
	else if(paddle_bottom < x && x < paddle_bottom+ 25 && y >= 113 && y <= 118)
		colour = 3'b111;
	else if (x >= 20 && x <= 40 && y == 20 && level ==3)       // obstable 1
        colour = 3'b011;
   else if(x == 120 && y >= 20 && y <= 40 && level ==3)   // obstacle 2
        colour = 3'b011;
   else if(x == 30 && y >= 80 && y <= 100 && level ==3)   // obstacle 3
        colour = 3'b011;
   else if(x >= 110 && x <= 130 && y == 90 && level ==3) // obstacle 4
        colour = 3'b011;
	else if (gameover == 1)
		colour = 3'b111; 
	else
		colour = 3'b000; 

	//determine next pixel to draw, increment y every time
	//if y reaches the bottom, then reset y and increment x by 1
	//disclaimer: this section of the code was written with reference of another group's project
	//https://github.com/Hunter833838/B58-Pong
	
	j = j + 1;
	y = y + 1'b1;
	if (j == 120)
	begin
		i = i + 1;
		x = x + 1'b1;

		j = 2;
		y = 2;	 
	end		
	if (i ==160)
	begin
		i =0;
		x = 1'b0;
	end
	end
endmodule

module RateDivider (switch,clock, Enable, clear_b);
	 input [1:0] switch;    // select the speed
	 input clock,clear_b;
	 reg [30:0] q;
	 reg [30:0] d;
	 reg Enable;
	 output Enable;
	 
	 
    always @(posedge clock)
    begin 
		  // --------------------need to modify-------------------------
        case(switch[1:0])
            2'b00: d = 1'b1;
            2'b01: d = 26'b10111110101111000010000000/6'b001111 - 1'b1; //30 fps
            2'b10: d = 26'b10111110101111000010000000/6'b011110 - 1'b1;//40 fps
            2'b11: d = 26'b10111110101111000010000000/6'b101000 - 1'b1;//50 fps, good luck
            default: d = 1'b1;
		  endcase
		  //-------------------------------------------------------------
			
		if (clear_b == 1'b0)
			q <= 0;
			
      if (q == 1'b0)
			q <= d;
				 // reset q to max counter value
      else
			q <= q - 1'b1; //decrement q
		
		Enable = (q == 1'b0) ? 1 : 0;
    end
endmodule

module score_decoder(
	input [11:0] score,
	output reg [6:0] seg0,
	output reg [6:0] seg1,
	output reg [6:0] seg2,
	output reg [6:0] seg3);
	
	integer i;
	reg [3:0] Thousands;
	reg [3:0] Hundreds;
	reg [3:0] Tens;
	reg [3:0] Ones;
	always @(score)
	begin
		Thousands = 4'd0;
		Hundreds = 4'd0;
		Tens = 4'd0;
		Ones = 4'd0;
		
		for (i=11; i>=0; i=i-1)
		begin
			if (Thousands >= 5)
				Thousands = Thousands + 3;
			if (Hundreds >= 5)
				Hundreds = Hundreds + 3;
			if (Tens >= 5)
				Tens = Tens + 3;
			if (Ones >= 5)
				Ones = Ones + 3;
				
			Thousands = Thousands << 1;
			Thousands[0] = Hundreds[3];
			Hundreds = Hundreds << 1;
			Hundreds[0] = Tens[3];
			Tens = Tens << 1;
			Tens[0] = Ones[3];
			Ones = Ones << 1;
			Ones[0] = score[i];
		end
		
		case (Ones[3:0])
			0:		seg0 = 7'b1000000;
			1:		seg0 = 7'b1111001;
			2:		seg0 = 7'b0100100;
			3:		seg0 = 7'b0110000;
			4:		seg0 = 7'b0011001;
			5:		seg0 = 7'b0010010;
			6:		seg0 = 7'b0000010;
			7:		seg0 = 7'b1111000;
			8:		seg0 = 7'b0000000;
			9:		seg0 = 7'b0011000;
			default:	seg0 = 7'b1000000;
		endcase
		
		case (Tens[3:0])
			0:		seg1 = 7'b1000000;
			1:		seg1 = 7'b1111001;
			2:		seg1 = 7'b0100100;
			3:		seg1 = 7'b0110000;
			4:		seg1 = 7'b0011001;
			5:		seg1 = 7'b0010010;
			6:		seg1 = 7'b0000010;
			7:		seg1 = 7'b1111000;
			8:		seg1 = 7'b0000000;
			9:		seg1 = 7'b0011000;
			default:	seg1 = 7'b1000000;
		endcase
		
		case (Hundreds[3:0])
			0:		seg2 = 7'b1000000;
			1:		seg2 = 7'b1111001;
			2:		seg2 = 7'b0100100;
			3:		seg2 = 7'b0110000;
			4:		seg2 = 7'b0011001;
			5:		seg2 = 7'b0010010;
			6:		seg2 = 7'b0000010;
			7:		seg2 = 7'b1111000;
			8:		seg2 = 7'b0000000;
			9:		seg2 = 7'b0011000;
			default:	seg2 = 7'b1000000;
		endcase
		
		case (Thousands[3:0])
			0:		seg3 = 7'b1000000;
			1:		seg3 = 7'b1111001;
			2:		seg3 = 7'b0100100;
			3:		seg3 = 7'b0110000;
			4:		seg3 = 7'b0011001;
			5:		seg3 = 7'b0010010;
			6:		seg3 = 7'b0000010;
			7:		seg3 = 7'b1111000;
			8:		seg3 = 7'b0000000;
			9:		seg3 = 7'b0011000;
			default:	seg3 = 7'b1000000;
		endcase
	end
endmodule

module decoder(c0,c1,c2,c3,outp);
		input c0;
		input c1;
		input c2;
		input c3;
		output [6:0] outp;
		
		//wire hex0_0,hex0_1,hex0_2,hex0_3,hex0_4,hex0_5,hex0_6;
		
		assign outp[0]= ~c0 & ~c1 & ~c2 & c3 | ~c0 & c1 & ~c2 & ~c3 | c0 & ~c1 & c2 & c3 | c0 & c1 & ~c2 & c3;
		
		assign outp[1] = c0 & c2 & c3 |  c1 & c2 & ~c3 | c0 & c1 & ~c3 | ~c0 & c1 & ~c2 & c3;
		
		assign outp[2] = ~c0 & ~c1 & c2 & ~c3 | c0 & c1 & c2 | c0 & c1 & ~c3;
		
		assign outp[3] = ~c0 & ~c1 & ~c2 & c3 | ~c0 & c1 & ~c2 & ~c3 | c1 & c2 & c3 | c0 & ~c1 & c2 & ~c3;
		
		assign outp[4] = ~c0 & c3 | ~c0 & c1 & ~c2 | ~c1 & ~c2 & c3;
		
		assign outp[5] = ~c0 & ~c1 & c3 | ~c0 & ~c1 & c2 | ~c0 & c2 & c3 | c0 & c1 & ~c2 & c3;
		
		assign outp[6] = ~c0 & ~c1 & ~c2 | ~c0 & c1 & c2 & c3 | c0 & c1 & ~c2 & ~c3;
		
		//assign m = hex0_0 | hex0_1 | hex0_2 | hex0_3 | hex0_4 | hex0_5 | hex0_6
		
		
endmodule 

module segment7(
     bcd,
     seg
    );
     
     //Declare inputs,outputs and internal variables.
     input [3:0] bcd;
     output [6:0] seg;
     reg [6:0] seg;

//always block for converting bcd digit into 7 segment format
    always @(bcd)
    begin
        case (bcd) //case statement
            0 : seg = 7'b0000001;
            1 : seg = 7'b1001111;
            2 : seg = 7'b0010010;
            3 : seg = 7'b0000110;
            4 : seg = 7'b1001100;
            5 : seg = 7'b0100100;
            6 : seg = 7'b0100000;
            7 : seg = 7'b0001111;
            8 : seg = 7'b0000000;
            9 : seg = 7'b0000100;
            //switch off 7 segment character when the bcd digit is not a decimal number.
            default : seg = 7'b1111111; 
        endcase
    end
    
endmodule
