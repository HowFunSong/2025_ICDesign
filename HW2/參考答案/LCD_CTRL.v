module LCD_CTRL(
	input 			 clk	  ,
	input 			 rst	  ,
	input 	   [3:0] cmd      , 
	input 			 cmd_valid,
	input 	   [7:0] IROM_Q   ,
	output 			 IROM_rd  , 
	output reg [5:0] IROM_A   ,
	output 			 IRAM_ceb ,
	output 		  	 IRAM_web ,
	output reg [7:0] IRAM_D	  ,
	output reg [5:0] IRAM_A	  ,
	input 	   [7:0] IRAM_Q	  ,
	output 			 busy	  ,
	output 			 done
);

reg [3:0] curr_state, next_state; // for FSM
reg [7:0] img[0:7][0:7]; // for image storing
reg [2:0] x, y; // for operation point
reg [2:0] idx_wx,idx_wy; // index for img address

// FSM parameter
parameter IDLE     = 4'd0 ,
		  READ_IMG = 4'd1 ,
		  READ_CMD = 4'd2 ,
		  WRITE	   = 4'd3 ,
		  MOVE	   = 4'd4 ,
		  MAX	   = 4'd5 ,
		  MIN	   = 4'd6 ,
		  AVG	   = 4'd7 , 
		  DONE	   = 4'd15;

// Wire based on curr_state
assign busy = (curr_state == READ_CMD) ? 0 : 1;
assign IROM_rd = (curr_state == READ_IMG) ? 1 : 0;
assign IRAM_ceb = (curr_state == WRITE) ? 1 : 0;
assign IRAM_web = (curr_state == WRITE) ? 0 : 1;
assign done = (curr_state == DONE) ? 1 : 0;

// Get the value of pixels in the window
wire [7:0] win [0:15];
assign win[0]  = img[y-2][x-2];
assign win[1]  = img[y-2][x-1];
assign win[2]  = img[y-2][x];
assign win[3]  = img[y-2][x+1];
assign win[4]  = img[y-1][x-2];
assign win[5]  = img[y-1][x-1];
assign win[6]  = img[y-1][x];
assign win[7]  = img[y-1][x+1];
assign win[8]  = img[y][x-2];
assign win[9]  = img[y][x-1];
assign win[10] = img[y][x];
assign win[11] = img[y][x+1];
assign win[12] = img[y+1][x-2];
assign win[13] = img[y+1][x-1];
assign win[14] = img[y+1][x];
assign win[15] = img[y+1][x+1];

// Find average value
wire [11:0] sum;
assign sum = (win[0]  + win[1] + win[2] + win[3]  + win[4]  + win[5]  + win[6]  + 
			  win[7]  + win[8] + win[9] + win[10] + win[11] + win[12] + win[13] + 
			  win[14] + win[15]);
wire [7:0] average;
assign average = sum >> 4; // average =  sum / 16

reg [7:0] max, max1, max2, max3, max4, max5, max6, max7, max8, max9, max10, max11, max12, max13, max14;
reg [7:0] min, min1, min2, min3, min4, min5, min6, min7, min8, min9, min10, min11, min12, min13, min14;

// Pairwise comparison to find max value
always @(*) begin
	max1  = (win[0]  > win[1] ) ? win[0]   : win[1] ;
    max2  = (win[2]  > win[3] ) ? win[2]   : win[3] ;
    max3  = (win[4]  > win[5] ) ? win[4]   : win[5] ;
    max4  = (win[6]  > win[7] ) ? win[6]   : win[7] ;
    max5  = (win[8]  > win[9] ) ? win[8]   : win[9] ;
    max6  = (win[10] > win[11]) ? win[10]  : win[11];
    max7  = (win[12] > win[13]) ? win[12]  : win[13];
    max8  = (win[14] > win[15]) ? win[14]  : win[15];

    max9  = (max1 > max2) ? max1 : max2;
    max10 = (max3 > max4) ? max3 : max4;
    max11 = (max5 > max6) ? max5 : max6;
    max12 = (max7 > max8) ? max7 : max8;

    max13 = (max9  > max10) ? max9  : max10;
    max14 = (max11 > max12) ? max11 : max12;

    max   = (max13 > max14) ? max13 : max14;
end

// Pairwise comparison to find min value
always @(*) begin
    min1  = (win[0]  < win[1] ) ? win[0]  : win[1] ;
    min2  = (win[2]  < win[3] ) ? win[2]  : win[3] ;
    min3  = (win[4]  < win[5] ) ? win[4]  : win[5] ;
    min4  = (win[6]  < win[7] ) ? win[6]  : win[7] ;
    min5  = (win[8]  < win[9] ) ? win[8]  : win[9] ;
    min6  = (win[10] < win[11]) ? win[10] : win[11];
    min7  = (win[12] < win[13]) ? win[12] : win[13];
    min8  = (win[14] < win[15]) ? win[14] : win[15];

    min9  = (min1  < min2) ? min1  : min2;
    min10 = (min3  < min4) ? min3  : min4;
    min11 = (min5  < min6) ? min5  : min6;
    min12 = (min7  < min8) ? min7  : min8;

    min13 = (min9  < min10) ? min9  : min10;
    min14 = (min11 < min12) ? min11 : min12;

    min   = (min13 < min14) ? min13 : min14;
end

// img address
always @(*) begin
	if(curr_state == WRITE) begin
		if(IRAM_A[2:0] == 3'd7)begin
			idx_wx = 3'd0;
			idx_wy = IRAM_A[5:3] + 3'd1;
		end
		else begin
			idx_wx = IRAM_A[2:0] + 3'd1;
			idx_wy = IRAM_A[5:3];
		end
	end	
	else begin
		idx_wx = 3'd0;
		idx_wy = 3'd0;
	end
end

// Get data for IRAM_D from img
always @(posedge clk or posedge rst) begin
	if(rst) begin
		IRAM_D <= 8'd0;
	end	
	else if(next_state == WRITE) begin
		IRAM_D <= img[idx_wy][idx_wx];
	end	
	else begin
		IRAM_D <= 8'd0;
	end
end

// RAM Address to write
always @(posedge clk or posedge rst) begin
	if(rst)begin
		IRAM_A <= 6'd0;
	end	
	else if(curr_state == WRITE)begin
		IRAM_A <= IRAM_A + 6'd1;
	end	
	else begin
		IRAM_A <= 6'd0;
	end
end

// Update the value in window
integer i_x, i_y;
always @(posedge clk or posedge rst) begin
	if(rst) begin
		for(i_x=0; i_x<8; i_x=i_x+1) begin
			for(i_y=0; i_y<8; i_y=i_y+1) begin
				img[i_x][i_y] <= 8'd0;
			end
		end
	end
	else if(curr_state == READ_IMG) begin
		img[IROM_A[5:3]][IROM_A[2:0]] <= IROM_Q;
	end
	else if(curr_state == MAX) begin
		img[y-2][x-2] <= max;
		img[y-2][x-1] <= max;
		img[y-2][x  ] <= max;
		img[y-2][x+1] <= max;
		img[y-1][x-2] <= max;
		img[y-1][x-1] <= max;
		img[y-1][x  ] <= max;
		img[y-1][x+1] <= max;
		img[y  ][x-2] <= max;
		img[y  ][x-1] <= max;
		img[y  ][x  ] <= max;
		img[y  ][x+1] <= max;
		img[y+1][x-2] <= max;
		img[y+1][x-1] <= max;
		img[y+1][x  ] <= max;
		img[y+1][x+1] <= max;

	end	
	else if(curr_state == MIN) begin
		img[y-2][x-2] <= min;
		img[y-2][x-1] <= min;
		img[y-2][x  ] <= min;
		img[y-2][x+1] <= min;
		img[y-1][x-2] <= min;
		img[y-1][x-1] <= min;
		img[y-1][x  ] <= min;
		img[y-1][x+1] <= min;
		img[y  ][x-2] <= min;
		img[y  ][x-1] <= min;
		img[y  ][x  ] <= min;
		img[y  ][x+1] <= min;
		img[y+1][x-2] <= min;
		img[y+1][x-1] <= min;
		img[y+1][x  ] <= min;
		img[y+1][x+1] <= min;
	end
	else if(curr_state == AVG) begin
		img[y-2][x-2] <= average;
		img[y-2][x-1] <= average;
		img[y-2][x  ] <= average;
		img[y-2][x+1] <= average;
		img[y-1][x-2] <= average;
		img[y-1][x-1] <= average;
		img[y-1][x  ] <= average;
		img[y-1][x+1] <= average;
		img[y  ][x-2] <= average;
		img[y  ][x-1] <= average;
		img[y  ][x  ] <= average;
		img[y  ][x+1] <= average;
		img[y+1][x-2] <= average;
		img[y+1][x-1] <= average;
		img[y+1][x  ] <= average;
		img[y+1][x+1] <= average;
	end
end		

// Move the operation point
always@(posedge clk or posedge rst)begin
	if(rst) begin
		x <= 3'd4;
		y <= 3'd4;
	end	
	else if(curr_state == MOVE) begin
		case(cmd)
			4'd1 : y <= (y == 3'd2) ? 3'd2 : (y - 3'd1);
			4'd2 : y <= (y == 3'd6) ? 3'd6 : (y + 3'd1);
			4'd3 : x <= (x == 3'd2) ? 3'd2 : (x - 3'd1);
			4'd4 : x <= (x == 3'd6) ? 3'd6 : (x + 3'd1);
		endcase 
	end
end

// READ from ROM
always@(posedge clk or posedge rst)begin
	if(rst) begin
		IROM_A <= 6'd0;
	end
	else if(curr_state == READ_IMG) begin
		IROM_A <= IROM_A + 6'd1;
	end
	else begin
		IROM_A <= 6'd0;
	end
end

// FSM
always @(*) begin
	case(curr_state)
		IDLE : 
			next_state = READ_IMG;
		READ_IMG : 
			next_state = (IROM_A == 6'd63) ? READ_CMD : READ_IMG;
		READ_CMD : begin
			case(cmd)
				4'd0 : next_state = WRITE;
				4'd1, 4'd2, 4'd3, 4'd4 : next_state = MOVE;
				4'd5 : next_state = MAX;
				4'd6 : next_state = MIN;
				4'd7 : next_state = AVG;
				default : next_state = READ_CMD;
			endcase
		end
		WRITE : 
			next_state = (IRAM_A == 6'd63) ? DONE : WRITE;
		MOVE : 
			next_state = READ_CMD;
		MAX : 
			next_state = READ_CMD;
		MIN : 
			next_state = READ_CMD;
		AVG : 
			next_state = READ_CMD;
		DONE : 
			next_state = DONE;
		default : 
			next_state = IDLE;
	endcase
end

always@(posedge clk or posedge rst)begin
	if(rst)
		curr_state <= IDLE;
	else
		curr_state <= next_state;
end

endmodule


