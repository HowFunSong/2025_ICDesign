module MedianFinder_5num(
    input  [3:0] 	num1  , 
	input  [3:0] 	num2  , 
	input  [3:0] 	num3  , 
	input  [3:0] 	num4  , 
	input  [3:0] 	num5  ,  
    output [3:0] 	median  
);

///////////////////////////////
//	Write Your Design Here ~ //
///////////////////////////////
wire [3:0] stage1_cmp1_min;
wire [3:0] stage1_cmp1_max;
wire [3:0] stage1_cmp2_min;
wire [3:0] stage1_cmp2_max;

wire [3:0] stage2_cmp1_max;
wire [3:0] stage2_cmp2_min;

Comparator2 stage1_cmp1(.A(num1), .B(num2), .min(stage1_cmp1_min), .max(stage1_cmp1_max));
Comparator2 stage1_cmp2(.A(num3), .B(num4), .min(stage1_cmp2_min), .max(stage1_cmp2_max));
Comparator2 stage2_cmp1(.A(stage1_cmp1_min), .B(stage1_cmp2_min), .min(), .max(stage2_cmp1_max));
Comparator2 stage2_cmp2(.A(stage1_cmp1_max), .B(stage1_cmp2_max), .min(stage2_cmp2_min), .max());

MedianFinder_3num med3(.num1(stage2_cmp1_max),
					   .num2(stage2_cmp2_min),
					   .num3(num5),
					   .median(median));

endmodule
