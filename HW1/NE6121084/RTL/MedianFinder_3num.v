module MedianFinder_3num(
    input  [3:0]    num1    , 
    input  [3:0]    num2    , 
    input  [3:0]    num3    ,  
    output [3:0]    median  
);

///////////////////////////////
//	Write Your Design Here ~ //
///////////////////////////////
wire [3:0]stage1_min;//a
wire [3:0]stage1_max;
wire [3:0]stage2_min;//b

Comparator2 stage1(.A(num1), .B(num2), .min(stage1_min), .max(stage1_max));
Comparator2 stage2(.A(stage1_max), .B(num3), .min(stage2_min), .max());
Comparator2 stage3(.A(stage1_min), .B(stage2_min), .min(), .max(median));


endmodule
