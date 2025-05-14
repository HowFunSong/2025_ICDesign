module MedianFinder_7num(
    input  	[3:0]  	num1  , 
	input  	[3:0]  	num2  , 
	input  	[3:0]  	num3  , 
	input  	[3:0]  	num4  , 
	input  	[3:0]  	num5  , 
	input  	[3:0]  	num6  , 
	input  	[3:0]  	num7  ,  
    output 	[3:0] 	median  
);

///////////////////////////////
//	Write Your Design Here ~ //
///////////////////////////////

wire [3:0] stage1_cmp1_min;
wire [3:0] stage1_cmp1_max;
wire [3:0] stage1_cmp2_min;
wire [3:0] stage1_cmp2_max;
wire [3:0] stage1_cmp3_min;
wire [3:0] stage1_cmp3_max;

wire [3:0] temp;
wire [3:0] stage2_num1;
wire [3:0] stage2_num2;

wire [3:0] temp2;
wire [3:0] stage2_num3;
wire [3:0] stage2_num4;
//step1 : exclude num1~6  min/max 
Comparator2 stage1_cmp1(.A(num1), .B(num2), .min(stage1_cmp1_min), .max(stage1_cmp1_max));
Comparator2 stage1_cmp2(.A(num3), .B(num4), .min(stage1_cmp2_min), .max(stage1_cmp2_max));
Comparator2 stage1_cmp3(.A(num5), .B(num6), .min(stage1_cmp3_min), .max(stage1_cmp3_max));

Comparator2 stage2_cmp1(.A(stage1_cmp1_min), .B(stage1_cmp2_min), .min(temp), .max(stage2_num1));
Comparator2 stage2_cmp2(.A(temp)           , .B(stage1_cmp3_min), .min(), .max(stage2_num2));

Comparator2 stage2_cmp3(.A(stage1_cmp1_max), .B(stage1_cmp2_max), .min(stage2_num3), .max(temp2));
Comparator2 stage2_cmp4(.A(temp2)           , .B(stage1_cmp3_max), .min(stage2_num4), .max());

//step2 : take 4 num from step1 + num7, use median5 to find median
MedianFinder_5num med5(.num1(stage2_num1), .num2(stage2_num2), .num3(stage2_num3), .num4(stage2_num4), .num5(num7), .median(median));

endmodule
