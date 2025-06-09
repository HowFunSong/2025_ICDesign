module  FFT (
	input clk,
	input rst,
	input [15:0] fir_d, 
	input fir_valid, 
	output fftr_valid, 
	output ffti_valid, 
	output done,
	output [15:0] fft_d0,
 	output [15:0] fft_d1, 
	output [15:0] fft_d2,
	output [15:0] fft_d3,
	output [15:0] fft_d4,
	output [15:0] fft_d5,
	output [15:0] fft_d6,
	output [15:0] fft_d7,
	output [15:0] fft_d8,
 	output [15:0] fft_d9,
	output [15:0] fft_d10,
	output [15:0] fft_d11,
	output [15:0] fft_d12,
	output [15:0] fft_d13,
	output [15:0] fft_d14,
	output [15:0] fft_d15
);

/////////////////////////////////
// Please write your code here //
/////////////////////////////////

// Twiddle 因子 (16.16 定點格式)
// imag part
parameter signed [31:0] W0_IMAG  = 32'h00000000 ;    //16.16
parameter signed [31:0] W1_IMAG  = 32'hFFFFCE0F ;     
parameter signed [31:0] W2_IMAG  = 32'hFFFF9E09 ;     
parameter signed [31:0] W3_IMAG  = 32'hFFFF71C6 ;     
parameter signed [31:0] W4_IMAG  = 32'hFFFF4AFC ;     
parameter signed [31:0] W5_IMAG  = 32'hFFFF2B25 ;     
parameter signed [31:0] W6_IMAG  = 32'hFFFF137D ;     
parameter signed [31:0] W7_IMAG  = 32'hFFFF04EB ;  
parameter signed [31:0] W8_IMAG  = 32'hFFFF0000 ;    //16.16
parameter signed [31:0] W9_IMAG  = 32'hFFFF04EB ;     
parameter signed [31:0] W10_IMAG = 32'hFFFF137D ;     
parameter signed [31:0] W11_IMAG = 32'hFFFF2B25 ;     
parameter signed [31:0] W12_IMAG = 32'hFFFF4AFC ;     
parameter signed [31:0] W13_IMAG = 32'hFFFF71C6 ;     
parameter signed [31:0] W14_IMAG = 32'hFFFF9E09 ;     
parameter signed [31:0] W15_IMAG = 32'hFFFFCE0F ;   

// real part
parameter signed [31:0] W0_REAL  = 32'h00010000 ;    //16.16
parameter signed [31:0] W1_REAL  = 32'h0000FB15 ;   
parameter signed [31:0] W2_REAL  = 32'h0000EC83 ;    
parameter signed [31:0] W3_REAL  = 32'h0000D4DB ;    
parameter signed [31:0] W4_REAL  = 32'h0000B504;   
parameter signed [31:0] W5_REAL  = 32'h00008E3A ;    
parameter signed [31:0] W6_REAL  = 32'h000061F7 ;     
parameter signed [31:0] W7_REAL  = 32'h000031F1 ;  
parameter signed [31:0] W8_REAL  = 32'h00000000 ;    //16.16
parameter signed [31:0] W9_REAL  = 32'hFFFFCE0F ;   
parameter signed [31:0] W10_REAL = 32'hFFFF9E09 ;    
parameter signed [31:0] W11_REAL = 32'hFFFF71C6 ;    
parameter signed [31:0] W12_REAL = 32'hFFFF4AFC ;   
parameter signed [31:0] W13_REAL = 32'hFFFF2B25 ;    
parameter signed [31:0] W14_REAL = 32'hFFFF137D ;     
parameter signed [31:0] W15_REAL = 32'hFFFF04EB ;  

// FSM 狀態定義
reg [2:0]state,next_state;

parameter IDLE=0,READ=1,CAL=2,DONE=3;
integer i;

reg signed [31:0] fir_data[0:31]; // 16.16
reg signed [31:0] fir_temp[0:31];
reg [4:0]counter;

always@(posedge clk or posedge rst) begin
	if (rst)begin
		for (i = 0 ; i < 32 ; i = i + 1)begin
			fir_temp[i] <= 32'd0; 
		end
	end else if (counter == 0) begin
		
		for (i = 0 ; i < 32 ; i = i + 1)begin
			fir_temp[i] <= fir_data[i]; 
		end
	end
end 
// S1階段蝶形運算暫存
reg signed [31:0]s1_real[0:31]; 
reg signed [31:0]s1_imag[0:31];
reg signed [31:0]s1_real_reg[0:31]; 
reg signed [31:0]s1_imag_reg[0:31];

always@(*)begin // stage 1
	// real part
    s1_real[0]  = BU0_real(fir_temp[0],  fir_temp[16]);
    s1_real[1]  = BU0_real(fir_temp[1],  fir_temp[17]);
    s1_real[2]  = BU0_real(fir_temp[2],  fir_temp[18]);
    s1_real[3]  = BU0_real(fir_temp[3],  fir_temp[19]);
    s1_real[4]  = BU0_real(fir_temp[4],  fir_temp[20]);
    s1_real[5]  = BU0_real(fir_temp[5],  fir_temp[21]);
    s1_real[6]  = BU0_real(fir_temp[6],  fir_temp[22]);
    s1_real[7]  = BU0_real(fir_temp[7],  fir_temp[23]);
    s1_real[8]  = BU0_real(fir_temp[8],  fir_temp[24]);
    s1_real[9]  = BU0_real(fir_temp[9],  fir_temp[25]);
    s1_real[10] = BU0_real(fir_temp[10], fir_temp[26]);
    s1_real[11] = BU0_real(fir_temp[11], fir_temp[27]);
    s1_real[12] = BU0_real(fir_temp[12], fir_temp[28]);
    s1_real[13] = BU0_real(fir_temp[13], fir_temp[29]);
    s1_real[14] = BU0_real(fir_temp[14], fir_temp[30]);
    s1_real[15] = BU0_real(fir_temp[15], fir_temp[31]);

    s1_real[16] = BU1_real(fir_temp[0], 32'd0, fir_temp[16], 32'd0, W0_REAL,  W0_IMAG);
    s1_real[17] = BU1_real(fir_temp[1], 32'd0, fir_temp[17], 32'd0, W1_REAL,  W1_IMAG);
    s1_real[18] = BU1_real(fir_temp[2], 32'd0, fir_temp[18], 32'd0, W2_REAL,  W2_IMAG);
    s1_real[19] = BU1_real(fir_temp[3], 32'd0, fir_temp[19], 32'd0, W3_REAL,  W3_IMAG);
    s1_real[20] = BU1_real(fir_temp[4], 32'd0, fir_temp[20], 32'd0, W4_REAL,  W4_IMAG);
    s1_real[21] = BU1_real(fir_temp[5], 32'd0, fir_temp[21], 32'd0, W5_REAL,  W5_IMAG);
    s1_real[22] = BU1_real(fir_temp[6], 32'd0, fir_temp[22], 32'd0, W6_REAL,  W6_IMAG);
    s1_real[23] = BU1_real(fir_temp[7], 32'd0, fir_temp[23], 32'd0, W7_REAL,  W7_IMAG);
    s1_real[24] = BU1_real(fir_temp[8], 32'd0, fir_temp[24], 32'd0, W8_REAL,  W8_IMAG);
    s1_real[25] = BU1_real(fir_temp[9], 32'd0, fir_temp[25], 32'd0, W9_REAL,  W9_IMAG);
    s1_real[26] = BU1_real(fir_temp[10],32'd0, fir_temp[26], 32'd0, W10_REAL, W10_IMAG);
    s1_real[27] = BU1_real(fir_temp[11],32'd0, fir_temp[27], 32'd0, W11_REAL, W11_IMAG);
    s1_real[28] = BU1_real(fir_temp[12],32'd0, fir_temp[28], 32'd0, W12_REAL, W12_IMAG);
    s1_real[29] = BU1_real(fir_temp[13],32'd0, fir_temp[29], 32'd0, W13_REAL, W13_IMAG);
    s1_real[30] = BU1_real(fir_temp[14],32'd0, fir_temp[30], 32'd0, W14_REAL, W14_IMAG);
    s1_real[31] = BU1_real(fir_temp[15],32'd0, fir_temp[31], 32'd0, W15_REAL, W15_IMAG);

	// imag part
	s1_imag[0]  = BU0_imag(32'd0,  32'd0);
    s1_imag[1]  = BU0_imag(32'd0,  32'd0);
    s1_imag[2]  = BU0_imag(32'd0,  32'd0);
    s1_imag[3]  = BU0_imag(32'd0,  32'd0);
    s1_imag[4]  = BU0_imag(32'd0,  32'd0);
    s1_imag[5]  = BU0_imag(32'd0,  32'd0);
    s1_imag[6]  = BU0_imag(32'd0,  32'd0);
    s1_imag[7]  = BU0_imag(32'd0,  32'd0);
    s1_imag[8]  = BU0_imag(32'd0,  32'd0);
    s1_imag[9]  = BU0_imag(32'd0,  32'd0);
    s1_imag[10] = BU0_imag(32'd0, 32'd0);
    s1_imag[11] = BU0_imag(32'd0, 32'd0);
    s1_imag[12] = BU0_imag(32'd0, 32'd0);
    s1_imag[13] = BU0_imag(32'd0, 32'd0);
    s1_imag[14] = BU0_imag(32'd0, 32'd0);
    s1_imag[15] = BU0_imag(32'd0, 32'd0);

    s1_imag[16] = BU1_imag(fir_temp[0], 32'd0, fir_temp[16], 32'd0, W0_REAL,  W0_IMAG);
    s1_imag[17] = BU1_imag(fir_temp[1], 32'd0, fir_temp[17], 32'd0, W1_REAL,  W1_IMAG);
    s1_imag[18] = BU1_imag(fir_temp[2], 32'd0, fir_temp[18], 32'd0, W2_REAL,  W2_IMAG);
    s1_imag[19] = BU1_imag(fir_temp[3], 32'd0, fir_temp[19], 32'd0, W3_REAL,  W3_IMAG);
    s1_imag[20] = BU1_imag(fir_temp[4], 32'd0, fir_temp[20], 32'd0, W4_REAL,  W4_IMAG);
    s1_imag[21] = BU1_imag(fir_temp[5], 32'd0, fir_temp[21], 32'd0, W5_REAL,  W5_IMAG);
    s1_imag[22] = BU1_imag(fir_temp[6], 32'd0, fir_temp[22], 32'd0, W6_REAL,  W6_IMAG);
    s1_imag[23] = BU1_imag(fir_temp[7], 32'd0, fir_temp[23], 32'd0, W7_REAL,  W7_IMAG);
    s1_imag[24] = BU1_imag(fir_temp[8], 32'd0, fir_temp[24], 32'd0, W8_REAL,  W8_IMAG);
    s1_imag[25] = BU1_imag(fir_temp[9], 32'd0, fir_temp[25], 32'd0, W9_REAL,  W9_IMAG);
    s1_imag[26] = BU1_imag(fir_temp[10],32'd0, fir_temp[26], 32'd0, W10_REAL, W10_IMAG);
    s1_imag[27] = BU1_imag(fir_temp[11],32'd0, fir_temp[27], 32'd0, W11_REAL, W11_IMAG);
    s1_imag[28] = BU1_imag(fir_temp[12],32'd0, fir_temp[28], 32'd0, W12_REAL, W12_IMAG);
    s1_imag[29] = BU1_imag(fir_temp[13],32'd0, fir_temp[29], 32'd0, W13_REAL, W13_IMAG);
    s1_imag[30] = BU1_imag(fir_temp[14],32'd0, fir_temp[30], 32'd0, W14_REAL, W14_IMAG);
    s1_imag[31] = BU1_imag(fir_temp[15],32'd0, fir_temp[31], 32'd0, W15_REAL, W15_IMAG);
end

always@(posedge clk or posedge rst)begin
	if(rst)begin
		for(i=0;i<32;i=i+1)begin
			s1_real_reg[i]<=0;
			s1_imag_reg[i]<=0;
		end
	end
	else if(state==CAL)begin
		for(i=0;i<32;i=i+1)begin
			s1_real_reg[i]<=s1_real[i];
			s1_imag_reg[i]<=s1_imag[i];
		end
	end
end

// S2階段蝶形運算暫存
reg signed [31:0]s2_real[0:31]; 
reg signed [31:0]s2_imag[0:31];
reg signed [31:0]s2_real_reg[0:31]; 
reg signed [31:0]s2_imag_reg[0:31];
always@(*)begin// stage 2
	// real part
	s2_real[0]=BU0_real(s1_real_reg[0],s1_real_reg[8]);		
	s2_real[1]=BU0_real(s1_real_reg[1],s1_real_reg[9]);	
	s2_real[2]=BU0_real(s1_real_reg[2],s1_real_reg[10]);		
	s2_real[3]=BU0_real(s1_real_reg[3],s1_real_reg[11]);
	s2_real[4]=BU0_real(s1_real_reg[4],s1_real_reg[12]);		
	s2_real[5]=BU0_real(s1_real_reg[5],s1_real_reg[13]);	
	s2_real[6]=BU0_real(s1_real_reg[6],s1_real_reg[14]);		
	s2_real[7]=BU0_real(s1_real_reg[7],s1_real_reg[15]);
	
	s2_real[8]=BU1_real(s1_real_reg[0],s1_imag_reg[0],s1_real_reg[8],s1_imag_reg[8],W0_REAL,W0_IMAG);			
	s2_real[9]=BU1_real(s1_real_reg[1],s1_imag_reg[1],s1_real_reg[9],s1_imag_reg[9],W2_REAL,W2_IMAG);	
	s2_real[10]=BU1_real(s1_real_reg[2],s1_imag_reg[2],s1_real_reg[10],s1_imag_reg[10],W4_REAL,W4_IMAG);				
	s2_real[11]=BU1_real(s1_real_reg[3],s1_imag_reg[3],s1_real_reg[11],s1_imag_reg[11],W6_REAL,W6_IMAG);	
	s2_real[12]=BU1_real(s1_real_reg[4],s1_imag_reg[4],s1_real_reg[12],s1_imag_reg[12],W8_REAL,W8_IMAG);			
	s2_real[13]=BU1_real(s1_real_reg[5],s1_imag_reg[5],s1_real_reg[13],s1_imag_reg[13],W10_REAL,W10_IMAG);	
	s2_real[14]=BU1_real(s1_real_reg[6],s1_imag_reg[6],s1_real_reg[14],s1_imag_reg[14],W12_REAL,W12_IMAG);				
	s2_real[15]=BU1_real(s1_real_reg[7],s1_imag_reg[7],s1_real_reg[15],s1_imag_reg[15],W14_REAL,W14_IMAG);	
	
	s2_real[16]=BU0_real(s1_real_reg[16],s1_real_reg[24]);		
	s2_real[17]=BU0_real(s1_real_reg[17],s1_real_reg[25]);	
	s2_real[18]=BU0_real(s1_real_reg[18],s1_real_reg[26]);		
	s2_real[19]=BU0_real(s1_real_reg[19],s1_real_reg[27]);	
	s2_real[20]=BU0_real(s1_real_reg[20],s1_real_reg[28]);		
	s2_real[21]=BU0_real(s1_real_reg[21],s1_real_reg[29]);	
	s2_real[22]=BU0_real(s1_real_reg[22],s1_real_reg[30]);		
	s2_real[23]=BU0_real(s1_real_reg[23],s1_real_reg[31]);	

	s2_real[24]=BU1_real(s1_real_reg[16],s1_imag_reg[16],s1_real_reg[24],s1_imag_reg[24],W0_REAL,W0_IMAG);			
	s2_real[25]=BU1_real(s1_real_reg[17],s1_imag_reg[17],s1_real_reg[25],s1_imag_reg[25],W2_REAL,W2_IMAG);	
	s2_real[26]=BU1_real(s1_real_reg[18],s1_imag_reg[18],s1_real_reg[26],s1_imag_reg[26],W4_REAL,W4_IMAG);				
	s2_real[27]=BU1_real(s1_real_reg[19],s1_imag_reg[19],s1_real_reg[27],s1_imag_reg[27],W6_REAL,W6_IMAG);
	s2_real[28]=BU1_real(s1_real_reg[20],s1_imag_reg[20],s1_real_reg[28],s1_imag_reg[28],W8_REAL,W8_IMAG);			
	s2_real[29]=BU1_real(s1_real_reg[21],s1_imag_reg[21],s1_real_reg[29],s1_imag_reg[29],W10_REAL,W10_IMAG);	
	s2_real[30]=BU1_real(s1_real_reg[22],s1_imag_reg[22],s1_real_reg[30],s1_imag_reg[30],W12_REAL,W12_IMAG);				
	s2_real[31]=BU1_real(s1_real_reg[23],s1_imag_reg[23],s1_real_reg[31],s1_imag_reg[31],W14_REAL,W14_IMAG);
	
	// imag part
	s2_imag[0]=BU0_imag(s1_imag_reg[0],s1_imag_reg[8]);		
	s2_imag[1]=BU0_imag(s1_imag_reg[1],s1_imag_reg[9]);	
	s2_imag[2]=BU0_imag(s1_imag_reg[2],s1_imag_reg[10]);		
	s2_imag[3]=BU0_imag(s1_imag_reg[3],s1_imag_reg[11]);
	s2_imag[4]=BU0_imag(s1_imag_reg[4],s1_imag_reg[12]);		
	s2_imag[5]=BU0_imag(s1_imag_reg[5],s1_imag_reg[13]);	
	s2_imag[6]=BU0_imag(s1_imag_reg[6],s1_imag_reg[14]);		
	s2_imag[7]=BU0_imag(s1_imag_reg[7],s1_imag_reg[15]);
	
	s2_imag[8]=BU1_imag(s1_real_reg[0],s1_imag_reg[0],s1_real_reg[8],s1_imag_reg[8],W0_REAL,W0_IMAG);			
	s2_imag[9]=BU1_imag(s1_real_reg[1],s1_imag_reg[1],s1_real_reg[9],s1_imag_reg[9],W2_REAL,W2_IMAG);	
	s2_imag[10]=BU1_imag(s1_real_reg[2],s1_imag_reg[2],s1_real_reg[10],s1_imag_reg[10],W4_REAL,W4_IMAG);				
	s2_imag[11]=BU1_imag(s1_real_reg[3],s1_imag_reg[3],s1_real_reg[11],s1_imag_reg[11],W6_REAL,W6_IMAG);	
	s2_imag[12]=BU1_imag(s1_real_reg[4],s1_imag_reg[4],s1_real_reg[12],s1_imag_reg[12],W8_REAL,W8_IMAG);			
	s2_imag[13]=BU1_imag(s1_real_reg[5],s1_imag_reg[5],s1_real_reg[13],s1_imag_reg[13],W10_REAL,W10_IMAG);	
	s2_imag[14]=BU1_imag(s1_real_reg[6],s1_imag_reg[6],s1_real_reg[14],s1_imag_reg[14],W12_REAL,W12_IMAG);				
	s2_imag[15]=BU1_imag(s1_real_reg[7],s1_imag_reg[7],s1_real_reg[15],s1_imag_reg[15],W14_REAL,W14_IMAG);	
	

	s2_imag[16]=BU0_imag(s1_imag_reg[16],s1_imag_reg[24]);		
	s2_imag[17]=BU0_imag(s1_imag_reg[17],s1_imag_reg[25]);	
	s2_imag[18]=BU0_imag(s1_imag_reg[18],s1_imag_reg[26]);	
	s2_imag[19]=BU0_imag(s1_imag_reg[19],s1_imag_reg[27]);	
	s2_imag[20]=BU0_imag(s1_imag_reg[20],s1_imag_reg[28]);		
	s2_imag[21]=BU0_imag(s1_imag_reg[21],s1_imag_reg[29]);	
	s2_imag[22]=BU0_imag(s1_imag_reg[22],s1_imag_reg[30]);	
	s2_imag[23]=BU0_imag(s1_imag_reg[23],s1_imag_reg[31]);	

	s2_imag[24]=BU1_imag(s1_real_reg[16],s1_imag_reg[16],s1_real_reg[24],s1_imag_reg[24],W0_REAL,W0_IMAG);			
	s2_imag[25]=BU1_imag(s1_real_reg[17],s1_imag_reg[17],s1_real_reg[25],s1_imag_reg[25],W2_REAL,W2_IMAG);	
	s2_imag[26]=BU1_imag(s1_real_reg[18],s1_imag_reg[18],s1_real_reg[26],s1_imag_reg[26],W4_REAL,W4_IMAG);				
	s2_imag[27]=BU1_imag(s1_real_reg[19],s1_imag_reg[19],s1_real_reg[27],s1_imag_reg[27],W6_REAL,W6_IMAG);
	s2_imag[28]=BU1_imag(s1_real_reg[20],s1_imag_reg[20],s1_real_reg[28],s1_imag_reg[28],W8_REAL,W8_IMAG);			
	s2_imag[29]=BU1_imag(s1_real_reg[21],s1_imag_reg[21],s1_real_reg[29],s1_imag_reg[29],W10_REAL,W10_IMAG);	
	s2_imag[30]=BU1_imag(s1_real_reg[22],s1_imag_reg[22],s1_real_reg[30],s1_imag_reg[30],W12_REAL,W12_IMAG);				
	s2_imag[31]=BU1_imag(s1_real_reg[23],s1_imag_reg[23],s1_real_reg[31],s1_imag_reg[31],W14_REAL,W14_IMAG);

end

always@(posedge clk or posedge rst)begin
	if(rst)begin
		for(i=0;i<32;i=i+1)begin
			s2_real_reg[i]<=0;
			s2_imag_reg[i]<=0;
		end
	end
	else if(state==CAL)begin
		for(i=0;i<32;i=i+1)begin
			s2_real_reg[i]<=s2_real[i];
			s2_imag_reg[i]<=s2_imag[i];
		end
	end
end


// S3階段蝶形運算暫存
reg signed [31:0]s3_real[0:31]; 
reg signed [31:0]s3_imag[0:31];
reg signed [31:0]s3_real_reg[0:31]; 
reg signed [31:0]s3_imag_reg[0:31];
always@(*)begin// stage 3
	// real part
	s3_real[0]=BU0_real(s2_real_reg[0],s2_real_reg[4]);		
	s3_real[1]=BU0_real(s2_real_reg[1],s2_real_reg[5]);
	s3_real[2]=BU0_real(s2_real_reg[2],s2_real_reg[6]);		
	s3_real[3]=BU0_real(s2_real_reg[3],s2_real_reg[7]);		
	
	s3_real[4]=BU1_real(s2_real_reg[0],s2_imag_reg[0],s2_real_reg[4],s2_imag_reg[4],W0_REAL,W0_IMAG);			
	s3_real[5]=BU1_real(s2_real_reg[1],s2_imag_reg[1],s2_real_reg[5],s2_imag_reg[5],W4_REAL,W4_IMAG);	
	s3_real[6]=BU1_real(s2_real_reg[2],s2_imag_reg[2],s2_real_reg[6],s2_imag_reg[6],W8_REAL,W8_IMAG);			
	s3_real[7]=BU1_real(s2_real_reg[3],s2_imag_reg[3],s2_real_reg[7],s2_imag_reg[7],W12_REAL,W12_IMAG);	
	
	s3_real[8]=BU0_real(s2_real_reg[8],s2_real_reg[12]);		
	s3_real[9]=BU0_real(s2_real_reg[9],s2_real_reg[13]);
	s3_real[10]=BU0_real(s2_real_reg[10],s2_real_reg[14]);		
	s3_real[11]=BU0_real(s2_real_reg[11],s2_real_reg[15]);
	
	s3_real[12]=BU1_real(s2_real_reg[8],s2_imag_reg[8],s2_real_reg[12],s2_imag_reg[12],W0_REAL,W0_IMAG);				
	s3_real[13]=BU1_real(s2_real_reg[9],s2_imag_reg[9],s2_real_reg[13],s2_imag_reg[13],W4_REAL,W4_IMAG);	
	s3_real[14]=BU1_real(s2_real_reg[10],s2_imag_reg[10],s2_real_reg[14],s2_imag_reg[14],W8_REAL,W8_IMAG);				
	s3_real[15]=BU1_real(s2_real_reg[11],s2_imag_reg[11],s2_real_reg[15],s2_imag_reg[15],W12_REAL,W12_IMAG);	
	
	s3_real[16]=BU0_real(s2_real_reg[16],s2_real_reg[20]);		
	s3_real[17]=BU0_real(s2_real_reg[17],s2_real_reg[21]);		
	s3_real[18]=BU0_real(s2_real_reg[18],s2_real_reg[22]);		
	s3_real[19]=BU0_real(s2_real_reg[19],s2_real_reg[23]);		

	s3_real[20]=BU1_real(s2_real_reg[16],s2_imag_reg[16],s2_real_reg[20],s2_imag_reg[20],W0_REAL,W0_IMAG);			
	s3_real[21]=BU1_real(s2_real_reg[17],s2_imag_reg[17],s2_real_reg[21],s2_imag_reg[21],W4_REAL,W4_IMAG);	
	s3_real[22]=BU1_real(s2_real_reg[18],s2_imag_reg[18],s2_real_reg[22],s2_imag_reg[22],W8_REAL,W8_IMAG);			
	s3_real[23]=BU1_real(s2_real_reg[19],s2_imag_reg[19],s2_real_reg[23],s2_imag_reg[23],W12_REAL,W12_IMAG);	
	
	s3_real[24]=BU0_real(s2_real_reg[24],s2_real_reg[28]);		
	s3_real[25]=BU0_real(s2_real_reg[25],s2_real_reg[29]);
	s3_real[26]=BU0_real(s2_real_reg[26],s2_real_reg[30]);		
	s3_real[27]=BU0_real(s2_real_reg[27],s2_real_reg[31]);
	

	s3_real[28]=BU1_real(s2_real_reg[24],s2_imag_reg[24],s2_real_reg[28],s2_imag_reg[28],W0_REAL,W0_IMAG);				
	s3_real[29]=BU1_real(s2_real_reg[25],s2_imag_reg[25],s2_real_reg[29],s2_imag_reg[29],W4_REAL,W4_IMAG);
	s3_real[30]=BU1_real(s2_real_reg[26],s2_imag_reg[26],s2_real_reg[30],s2_imag_reg[30],W8_REAL,W8_IMAG);				
	s3_real[31]=BU1_real(s2_real_reg[27],s2_imag_reg[27],s2_real_reg[31],s2_imag_reg[31],W12_REAL,W12_IMAG);
	

	// imag part
	s3_imag[0]=BU0_imag(s2_imag_reg[0],s2_imag_reg[4]);		
	s3_imag[1]=BU0_imag(s2_imag_reg[1],s2_imag_reg[5]);
	s3_imag[2]=BU0_imag(s2_imag_reg[2],s2_imag_reg[6]);		
	s3_imag[3]=BU0_imag(s2_imag_reg[3],s2_imag_reg[7]);		
	
	s3_imag[4]=BU1_imag(s2_real_reg[0],s2_imag_reg[0],s2_real_reg[4],s2_imag_reg[4],W0_REAL,W0_IMAG);			
	s3_imag[5]=BU1_imag(s2_real_reg[1],s2_imag_reg[1],s2_real_reg[5],s2_imag_reg[5],W4_REAL,W4_IMAG);	
	s3_imag[6]=BU1_imag(s2_real_reg[2],s2_imag_reg[2],s2_real_reg[6],s2_imag_reg[6],W8_REAL,W8_IMAG);			
	s3_imag[7]=BU1_imag(s2_real_reg[3],s2_imag_reg[3],s2_real_reg[7],s2_imag_reg[7],W12_REAL,W12_IMAG);	
	
	s3_imag[8]=BU0_imag(s2_imag_reg[8],s2_imag_reg[12]);		
	s3_imag[9]=BU0_imag(s2_imag_reg[9],s2_imag_reg[13]);
	s3_imag[10]=BU0_imag(s2_imag_reg[10],s2_imag_reg[14]);		
	s3_imag[11]=BU0_imag(s2_imag_reg[11],s2_imag_reg[15]);
	
	s3_imag[12]=BU1_imag(s2_real_reg[8],s2_imag_reg[8],s2_real_reg[12],s2_imag_reg[12],W0_REAL,W0_IMAG);				
	s3_imag[13]=BU1_imag(s2_real_reg[9],s2_imag_reg[9],s2_real_reg[13],s2_imag_reg[13],W4_REAL,W4_IMAG);	
	s3_imag[14]=BU1_imag(s2_real_reg[10],s2_imag_reg[10],s2_real_reg[14],s2_imag_reg[14],W8_REAL,W8_IMAG);				
	s3_imag[15]=BU1_imag(s2_real_reg[11],s2_imag_reg[11],s2_real_reg[15],s2_imag_reg[15],W12_REAL,W12_IMAG);	
	
	s3_imag[16]=BU0_imag(s2_imag_reg[16],s2_imag_reg[20]);		
	s3_imag[17]=BU0_imag(s2_imag_reg[17],s2_imag_reg[21]);		
	s3_imag[18]=BU0_imag(s2_imag_reg[18],s2_imag_reg[22]);		
	s3_imag[19]=BU0_imag(s2_imag_reg[19],s2_imag_reg[23]);		

	s3_imag[20]=BU1_imag(s2_real_reg[16],s2_imag_reg[16],s2_real_reg[20],s2_imag_reg[20],W0_REAL,W0_IMAG);			
	s3_imag[21]=BU1_imag(s2_real_reg[17],s2_imag_reg[17],s2_real_reg[21],s2_imag_reg[21],W4_REAL,W4_IMAG);	
	s3_imag[22]=BU1_imag(s2_real_reg[18],s2_imag_reg[18],s2_real_reg[22],s2_imag_reg[22],W8_REAL,W8_IMAG);			
	s3_imag[23]=BU1_imag(s2_real_reg[19],s2_imag_reg[19],s2_real_reg[23],s2_imag_reg[23],W12_REAL,W12_IMAG);	
	
	s3_imag[24]=BU0_imag(s2_imag_reg[24],s2_imag_reg[28]);		
	s3_imag[25]=BU0_imag(s2_imag_reg[25],s2_imag_reg[29]);
	s3_imag[26]=BU0_imag(s2_imag_reg[26],s2_imag_reg[30]);		
	s3_imag[27]=BU0_imag(s2_imag_reg[27],s2_imag_reg[31]);
	
	s3_imag[28]=BU1_imag(s2_real_reg[24],s2_imag_reg[24],s2_real_reg[28],s2_imag_reg[28],W0_REAL,W0_IMAG);				
	s3_imag[29]=BU1_imag(s2_real_reg[25],s2_imag_reg[25],s2_real_reg[29],s2_imag_reg[29],W4_REAL,W4_IMAG);
	s3_imag[30]=BU1_imag(s2_real_reg[26],s2_imag_reg[26],s2_real_reg[30],s2_imag_reg[30],W8_REAL,W8_IMAG);				
	s3_imag[31]=BU1_imag(s2_real_reg[27],s2_imag_reg[27],s2_real_reg[31],s2_imag_reg[31],W12_REAL,W12_IMAG);

end

always@(posedge clk or posedge rst)begin
	if(rst)begin
		for(i=0;i<32;i=i+1)begin
			s3_real_reg[i]<=0;
			s3_imag_reg[i]<=0;
		end
	end
	else if(state==CAL)begin
		for(i=0;i<32;i=i+1)begin
			s3_real_reg[i]<=s3_real[i];
			s3_imag_reg[i]<=s3_imag[i];
		end
	end
end


// S4階段蝶形運算暫存
reg signed [31:0]s4_real[0:31]; 
reg signed [31:0]s4_imag[0:31];
reg signed [31:0]s4_real_reg[0:31]; 
reg signed [31:0]s4_imag_reg[0:31];

always@(*)begin// stage 4
	// real part
	s4_real[0]=BU0_real(s3_real_reg[0],s3_real_reg[2]);		
	s4_real[1]=BU0_real(s3_real_reg[1],s3_real_reg[3]);		

	s4_real[2]=BU1_real(s3_real_reg[0],s3_imag_reg[0],s3_real_reg[2],s3_imag_reg[2],W0_REAL,W0_IMAG);
	s4_real[3]=BU1_real(s3_real_reg[1],s3_imag_reg[1],s3_real_reg[3],s3_imag_reg[3],W8_REAL,W8_IMAG);
	
	s4_real[4]=BU0_real(s3_real_reg[4],s3_real_reg[6]);		
	s4_real[5]=BU0_real(s3_real_reg[5],s3_real_reg[7]);		

	s4_real[6]=BU1_real(s3_real_reg[4],s3_imag_reg[4],s3_real_reg[6],s3_imag_reg[6],W0_REAL,W0_IMAG);
	s4_real[7]=BU1_real(s3_real_reg[5],s3_imag_reg[5],s3_real_reg[7],s3_imag_reg[7],W8_REAL,W8_IMAG);
	
	s4_real[8]=BU0_real(s3_real_reg[8],s3_real_reg[10]);		
	s4_real[9]=BU0_real(s3_real_reg[9],s3_real_reg[11]);	

	s4_real[10]=BU1_real(s3_real_reg[8],s3_imag_reg[8],s3_real_reg[10],s3_imag_reg[10],W0_REAL,W0_IMAG);
	s4_real[11]=BU1_real(s3_real_reg[9],s3_imag_reg[9],s3_real_reg[11],s3_imag_reg[11],W8_REAL,W8_IMAG);
	
	s4_real[12]=BU0_real(s3_real_reg[12],s3_real_reg[14]);		
	s4_real[13]=BU0_real(s3_real_reg[13],s3_real_reg[15]);		
	
	s4_real[14]=BU1_real(s3_real_reg[12],s3_imag_reg[12],s3_real_reg[14],s3_imag_reg[14],W0_REAL,W0_IMAG);
	s4_real[15]=BU1_real(s3_real_reg[13],s3_imag_reg[13],s3_real_reg[15],s3_imag_reg[15],W8_REAL,W8_IMAG);
	
	s4_real[16]=BU0_real(s3_real_reg[16],s3_real_reg[18]);		
	s4_real[17]=BU0_real(s3_real_reg[17],s3_real_reg[19]);		
	
	s4_real[18]=BU1_real(s3_real_reg[16],s3_imag_reg[16],s3_real_reg[18],s3_imag_reg[18],W0_REAL,W0_IMAG);
	s4_real[19]=BU1_real(s3_real_reg[17],s3_imag_reg[17],s3_real_reg[19],s3_imag_reg[19],W8_REAL,W8_IMAG);
	
	s4_real[20]=BU0_real(s3_real_reg[20],s3_real_reg[22]);		
	s4_real[21]=BU0_real(s3_real_reg[21],s3_real_reg[23]);		
	
	s4_real[22]=BU1_real(s3_real_reg[20],s3_imag_reg[20],s3_real_reg[22],s3_imag_reg[22],W0_REAL,W0_IMAG);
	s4_real[23]=BU1_real(s3_real_reg[21],s3_imag_reg[21],s3_real_reg[23],s3_imag_reg[23],W8_REAL,W8_IMAG);
	
	s4_real[24]=BU0_real(s3_real_reg[24],s3_real_reg[26]);		
	s4_real[25]=BU0_real(s3_real_reg[25],s3_real_reg[27]);		

	s4_real[26]=BU1_real(s3_real_reg[24],s3_imag_reg[24],s3_real_reg[26],s3_imag_reg[26],W0_REAL,W0_IMAG);
	s4_real[27]=BU1_real(s3_real_reg[25],s3_imag_reg[25],s3_real_reg[27],s3_imag_reg[27],W8_REAL,W8_IMAG);
	
	s4_real[28]=BU0_real(s3_real_reg[28],s3_real_reg[30]);		
	s4_real[29]=BU0_real(s3_real_reg[29],s3_real_reg[31]);		

	s4_real[30]=BU1_real(s3_real_reg[28],s3_imag_reg[28],s3_real_reg[30],s3_imag_reg[30],W0_REAL,W0_IMAG);
	s4_real[31]=BU1_real(s3_real_reg[29],s3_imag_reg[29],s3_real_reg[31],s3_imag_reg[31],W8_REAL,W8_IMAG);
	

	// imag part
	s4_imag[0]=BU0_imag(s3_imag_reg[0],s3_imag_reg[2]);		
	s4_imag[1]=BU0_imag(s3_imag_reg[1],s3_imag_reg[3]);
			
	s4_imag[2]=BU1_imag(s3_real_reg[0],s3_imag_reg[0],s3_real_reg[2],s3_imag_reg[2],W0_REAL,W0_IMAG);
	s4_imag[3]=BU1_imag(s3_real_reg[1],s3_imag_reg[1],s3_real_reg[3],s3_imag_reg[3],W8_REAL,W8_IMAG);
	
	s4_imag[4]=BU0_imag(s3_imag_reg[4],s3_imag_reg[6]);		
	s4_imag[5]=BU0_imag(s3_imag_reg[5],s3_imag_reg[7]);

	s4_imag[6]=BU1_imag(s3_real_reg[4],s3_imag_reg[4],s3_real_reg[6],s3_imag_reg[6],W0_REAL,W0_IMAG);
	s4_imag[7]=BU1_imag(s3_real_reg[5],s3_imag_reg[5],s3_real_reg[7],s3_imag_reg[7],W8_REAL,W8_IMAG);

	s4_imag[8]=BU0_imag(s3_imag_reg[8],s3_imag_reg[10]);		
	s4_imag[9]=BU0_imag(s3_imag_reg[9],s3_imag_reg[11]);		

	s4_imag[10]=BU1_imag(s3_real_reg[8],s3_imag_reg[8],s3_real_reg[10],s3_imag_reg[10],W0_REAL,W0_IMAG);
	s4_imag[11]=BU1_imag(s3_real_reg[9],s3_imag_reg[9],s3_real_reg[11],s3_imag_reg[11],W8_REAL,W8_IMAG);
	
	s4_imag[12]=BU0_imag(s3_imag_reg[12],s3_imag_reg[14]);		
	s4_imag[13]=BU0_imag(s3_imag_reg[13],s3_imag_reg[15]);		
	s4_imag[14]=BU1_imag(s3_real_reg[12],s3_imag_reg[12],s3_real_reg[14],s3_imag_reg[14],W0_REAL,W0_IMAG);
	s4_imag[15]=BU1_imag(s3_real_reg[13],s3_imag_reg[13],s3_real_reg[15],s3_imag_reg[15],W8_REAL,W8_IMAG);
	
	s4_imag[16]=BU0_imag(s3_imag_reg[16],s3_imag_reg[18]);		
	s4_imag[17]=BU0_imag(s3_imag_reg[17],s3_imag_reg[19]);		
	s4_imag[18]=BU1_imag(s3_real_reg[16],s3_imag_reg[16],s3_real_reg[18],s3_imag_reg[18],W0_REAL,W0_IMAG);
	s4_imag[19]=BU1_imag(s3_real_reg[17],s3_imag_reg[17],s3_real_reg[19],s3_imag_reg[19],W8_REAL,W8_IMAG);
	
	s4_imag[20]=BU0_imag(s3_imag_reg[20],s3_imag_reg[22]);		
	s4_imag[21]=BU0_imag(s3_imag_reg[21],s3_imag_reg[23]);		
	s4_imag[22]=BU1_imag(s3_real_reg[20],s3_imag_reg[20],s3_real_reg[22],s3_imag_reg[22],W0_REAL,W0_IMAG);
	s4_imag[23]=BU1_imag(s3_real_reg[21],s3_imag_reg[21],s3_real_reg[23],s3_imag_reg[23],W8_REAL,W8_IMAG);
	
	s4_imag[24]=BU0_imag(s3_imag_reg[24],s3_imag_reg[26]);		
	s4_imag[25]=BU0_imag(s3_imag_reg[25],s3_imag_reg[27]);		
	s4_imag[26]=BU1_imag(s3_real_reg[24],s3_imag_reg[24],s3_real_reg[26],s3_imag_reg[26],W0_REAL,W0_IMAG);
	s4_imag[27]=BU1_imag(s3_real_reg[25],s3_imag_reg[25],s3_real_reg[27],s3_imag_reg[27],W8_REAL,W8_IMAG);
	
	s4_imag[28]=BU0_imag(s3_imag_reg[28],s3_imag_reg[30]);		
	s4_imag[29]=BU0_imag(s3_imag_reg[29],s3_imag_reg[31]);		
	s4_imag[30]=BU1_imag(s3_real_reg[28],s3_imag_reg[28],s3_real_reg[30],s3_imag_reg[30],W0_REAL,W0_IMAG);
	s4_imag[31]=BU1_imag(s3_real_reg[29],s3_imag_reg[29],s3_real_reg[31],s3_imag_reg[31],W8_REAL,W8_IMAG);
end


always@(posedge clk or posedge rst)begin
	if(rst)begin
		for(i=0;i<32;i=i+1)begin
			s4_real_reg[i]<=0;
			s4_imag_reg[i]<=0;
		end
	end
	else if(state==CAL)begin
		for(i=0;i<32;i=i+1)begin
			s4_real_reg[i]<=s4_real[i];
			s4_imag_reg[i]<=s4_imag[i];
		end
	end
end


// S5階段蝶形運算暫存
// S5階段蝶形運算暫存
reg signed [31:0] s5_real[0:31];
reg signed [31:0] s5_imag[0:31];
always @(*) begin // stage 5
    // real part
    s5_real[0 ] = BU0_real(s4_real_reg[0 ], s4_real_reg[1 ]);
    s5_real[1 ] = BU1_real(s4_real_reg[0 ], s4_imag_reg[0 ], s4_real_reg[1 ], s4_imag_reg[1 ], W0_REAL, W0_IMAG);
    s5_real[2 ] = BU0_real(s4_real_reg[2 ], s4_real_reg[3 ]);
    s5_real[3 ] = BU1_real(s4_real_reg[2 ], s4_imag_reg[2 ], s4_real_reg[3 ], s4_imag_reg[3 ], W0_REAL, W0_IMAG);
    s5_real[4 ] = BU0_real(s4_real_reg[4 ], s4_real_reg[5 ]);
    s5_real[5 ] = BU1_real(s4_real_reg[4 ], s4_imag_reg[4 ], s4_real_reg[5 ], s4_imag_reg[5 ], W0_REAL, W0_IMAG);
    s5_real[6 ] = BU0_real(s4_real_reg[6 ], s4_real_reg[7 ]);
    s5_real[7 ] = BU1_real(s4_real_reg[6 ], s4_imag_reg[6 ], s4_real_reg[7 ], s4_imag_reg[7 ], W0_REAL, W0_IMAG);
    s5_real[8 ] = BU0_real(s4_real_reg[8 ], s4_real_reg[9 ]);
    s5_real[9 ] = BU1_real(s4_real_reg[8 ], s4_imag_reg[8 ], s4_real_reg[9 ], s4_imag_reg[9 ], W0_REAL, W0_IMAG);
    s5_real[10] = BU0_real(s4_real_reg[10], s4_real_reg[11]);
    s5_real[11] = BU1_real(s4_real_reg[10], s4_imag_reg[10], s4_real_reg[11], s4_imag_reg[11], W0_REAL, W0_IMAG);
    s5_real[12] = BU0_real(s4_real_reg[12], s4_real_reg[13]);
    s5_real[13] = BU1_real(s4_real_reg[12], s4_imag_reg[12], s4_real_reg[13], s4_imag_reg[13], W0_REAL, W0_IMAG);
    s5_real[14] = BU0_real(s4_real_reg[14], s4_real_reg[15]);
    s5_real[15] = BU1_real(s4_real_reg[14], s4_imag_reg[14], s4_real_reg[15], s4_imag_reg[15], W0_REAL, W0_IMAG);
    s5_real[16] = BU0_real(s4_real_reg[16], s4_real_reg[17]);
    s5_real[17] = BU1_real(s4_real_reg[16], s4_imag_reg[16], s4_real_reg[17], s4_imag_reg[17], W0_REAL, W0_IMAG);
    s5_real[18] = BU0_real(s4_real_reg[18], s4_real_reg[19]);
    s5_real[19] = BU1_real(s4_real_reg[18], s4_imag_reg[18], s4_real_reg[19], s4_imag_reg[19], W0_REAL, W0_IMAG);
    s5_real[20] = BU0_real(s4_real_reg[20], s4_real_reg[21]);
    s5_real[21] = BU1_real(s4_real_reg[20], s4_imag_reg[20], s4_real_reg[21], s4_imag_reg[21], W0_REAL, W0_IMAG);
    s5_real[22] = BU0_real(s4_real_reg[22], s4_real_reg[23]);
    s5_real[23] = BU1_real(s4_real_reg[22], s4_imag_reg[22], s4_real_reg[23], s4_imag_reg[23], W0_REAL, W0_IMAG);
    s5_real[24] = BU0_real(s4_real_reg[24], s4_real_reg[25]);
    s5_real[25] = BU1_real(s4_real_reg[24], s4_imag_reg[24], s4_real_reg[25], s4_imag_reg[25], W0_REAL, W0_IMAG);
    s5_real[26] = BU0_real(s4_real_reg[26], s4_real_reg[27]);
    s5_real[27] = BU1_real(s4_real_reg[26], s4_imag_reg[26], s4_real_reg[27], s4_imag_reg[27], W0_REAL, W0_IMAG);
    s5_real[28] = BU0_real(s4_real_reg[28], s4_real_reg[29]);
    s5_real[29] = BU1_real(s4_real_reg[28], s4_imag_reg[28], s4_real_reg[29], s4_imag_reg[29], W0_REAL, W0_IMAG);
    s5_real[30] = BU0_real(s4_real_reg[30], s4_real_reg[31]);
    s5_real[31] = BU1_real(s4_real_reg[30], s4_imag_reg[30], s4_real_reg[31], s4_imag_reg[31], W0_REAL, W0_IMAG);

    // imag part
    s5_imag[0 ] = BU0_imag(s4_imag_reg[0 ], s4_imag_reg[1 ]);
    s5_imag[1 ] = BU1_imag(s4_real_reg[0 ], s4_imag_reg[0 ], s4_real_reg[1 ], s4_imag_reg[1 ], W0_REAL, W0_IMAG);
    s5_imag[2 ] = BU0_imag(s4_imag_reg[2 ], s4_imag_reg[3 ]);
    s5_imag[3 ] = BU1_imag(s4_real_reg[2 ], s4_imag_reg[2 ], s4_real_reg[3 ], s4_imag_reg[3 ], W0_REAL, W0_IMAG);
    s5_imag[4 ] = BU0_imag(s4_imag_reg[4 ], s4_imag_reg[5 ]);
    s5_imag[5 ] = BU1_imag(s4_real_reg[4 ], s4_imag_reg[4 ], s4_real_reg[5 ], s4_imag_reg[5 ], W0_REAL, W0_IMAG);
    s5_imag[6 ] = BU0_imag(s4_imag_reg[6 ], s4_imag_reg[7 ]);
    s5_imag[7 ] = BU1_imag(s4_real_reg[6 ], s4_imag_reg[6 ], s4_real_reg[7 ], s4_imag_reg[7 ], W0_REAL, W0_IMAG);
    s5_imag[8 ] = BU0_imag(s4_imag_reg[8 ], s4_imag_reg[9 ]);
    s5_imag[9 ] = BU1_imag(s4_real_reg[8 ], s4_imag_reg[8 ], s4_real_reg[9 ], s4_imag_reg[9 ], W0_REAL, W0_IMAG);
    s5_imag[10] = BU0_imag(s4_imag_reg[10], s4_imag_reg[11]);
    s5_imag[11] = BU1_imag(s4_real_reg[10], s4_imag_reg[10], s4_real_reg[11], s4_imag_reg[11], W0_REAL, W0_IMAG);
    s5_imag[12] = BU0_imag(s4_imag_reg[12], s4_imag_reg[13]);
    s5_imag[13] = BU1_imag(s4_real_reg[12], s4_imag_reg[12], s4_real_reg[13], s4_imag_reg[13], W0_REAL, W0_IMAG);
    s5_imag[14] = BU0_imag(s4_imag_reg[14], s4_imag_reg[15]);
    s5_imag[15] = BU1_imag(s4_real_reg[14], s4_imag_reg[14], s4_real_reg[15], s4_imag_reg[15], W0_REAL, W0_IMAG);
    s5_imag[16] = BU0_imag(s4_imag_reg[16], s4_imag_reg[17]);
    s5_imag[17] = BU1_imag(s4_real_reg[16], s4_imag_reg[16], s4_real_reg[17], s4_imag_reg[17], W0_REAL, W0_IMAG);
    s5_imag[18] = BU0_imag(s4_imag_reg[18], s4_imag_reg[19]);
    s5_imag[19] = BU1_imag(s4_real_reg[18], s4_imag_reg[18], s4_real_reg[19], s4_imag_reg[19], W0_REAL, W0_IMAG);
    s5_imag[20] = BU0_imag(s4_imag_reg[20], s4_imag_reg[21]);
    s5_imag[21] = BU1_imag(s4_real_reg[20], s4_imag_reg[20], s4_real_reg[21], s4_imag_reg[21], W0_REAL, W0_IMAG);
    s5_imag[22] = BU0_imag(s4_imag_reg[22], s4_imag_reg[23]);
    s5_imag[23] = BU1_imag(s4_real_reg[22], s4_imag_reg[22], s4_real_reg[23], s4_imag_reg[23], W0_REAL, W0_IMAG);
    s5_imag[24] = BU0_imag(s4_imag_reg[24], s4_imag_reg[25]);
    s5_imag[25] = BU1_imag(s4_real_reg[24], s4_imag_reg[24], s4_real_reg[25], s4_imag_reg[25], W0_REAL, W0_IMAG);
    s5_imag[26] = BU0_imag(s4_imag_reg[26], s4_imag_reg[27]);
    s5_imag[27] = BU1_imag(s4_real_reg[26], s4_imag_reg[26], s4_real_reg[27], s4_imag_reg[27], W0_REAL, W0_IMAG);
    s5_imag[28] = BU0_imag(s4_imag_reg[28], s4_imag_reg[29]);
    s5_imag[29] = BU1_imag(s4_real_reg[28], s4_imag_reg[28], s4_real_reg[29], s4_imag_reg[29], W0_REAL, W0_IMAG);
    s5_imag[30] = BU0_imag(s4_imag_reg[30], s4_imag_reg[31]);
    s5_imag[31] = BU1_imag(s4_real_reg[30], s4_imag_reg[30], s4_real_reg[31], s4_imag_reg[31], W0_REAL, W0_IMAG);
end

reg [15:0]imag_temp[0:31];
// counter==4: 输出 s5_real[0..15]
// counter==5: 输出 s5_real[16..31]
// counter==6: 输出 imag_temp[0..15]
// counter==7: 输出 imag_temp[16..31]
// 其它情况全 0

assign fft_d0  = (state==CAL && counter==5) ? s5_real[0] [23:8] :
                 (state==CAL && counter==6) ? s5_real[16][23:8] :
                 (state==CAL && counter==7) ? imag_temp[0]   :
                 (state==CAL && counter==8) ? imag_temp[16]  : 16'd0;

assign fft_d1  = (state==CAL && counter==5) ? s5_real[1] [23:8] :
                 (state==CAL && counter==6) ? s5_real[17][23:8] :
                 (state==CAL && counter==7) ? imag_temp[1]   :
                 (state==CAL && counter==8) ? imag_temp[17]  : 16'd0;

assign fft_d2  = (state==CAL && counter==5) ? s5_real[2] [23:8] :
                 (state==CAL && counter==6) ? s5_real[18][23:8] :
                 (state==CAL && counter==7) ? imag_temp[2]   :
                 (state==CAL && counter==8) ? imag_temp[18]  : 16'd0;

assign fft_d3  = (state==CAL && counter==5) ? s5_real[3] [23:8] :
                 (state==CAL && counter==6) ? s5_real[19][23:8] :
                 (state==CAL && counter==7) ? imag_temp[3]   :
                 (state==CAL && counter==8) ? imag_temp[19]  : 16'd0;

assign fft_d4  = (state==CAL && counter==5) ? s5_real[4] [23:8] :
                 (state==CAL && counter==6) ? s5_real[20][23:8] :
                 (state==CAL && counter==7) ? imag_temp[4]   :
                 (state==CAL && counter==8) ? imag_temp[20]  : 16'd0;

assign fft_d5  = (state==CAL && counter==5) ? s5_real[5] [23:8] :
                 (state==CAL && counter==6) ? s5_real[21][23:8] :
                 (state==CAL && counter==7) ? imag_temp[5]   :
                 (state==CAL && counter==8) ? imag_temp[21]  : 16'd0;

assign fft_d6  = (state==CAL && counter==5) ? s5_real[6] [23:8] :
                 (state==CAL && counter==6) ? s5_real[22][23:8] :
                 (state==CAL && counter==7) ? imag_temp[6]   :
                 (state==CAL && counter==8) ? imag_temp[22]  : 16'd0;

assign fft_d7  = (state==CAL && counter==5) ? s5_real[7] [23:8] :
                 (state==CAL && counter==6) ? s5_real[23][23:8] :
                 (state==CAL && counter==7) ? imag_temp[7]   :
                 (state==CAL && counter==8) ? imag_temp[23]  : 16'd0;

assign fft_d8  = (state==CAL && counter==5) ? s5_real[8] [23:8] :
                 (state==CAL && counter==6) ? s5_real[24][23:8] :
                 (state==CAL && counter==7) ? imag_temp[8]   :
                 (state==CAL && counter==8) ? imag_temp[24]  : 16'd0;

assign fft_d9  = (state==CAL && counter==5) ? s5_real[9] [23:8] :
                 (state==CAL && counter==6) ? s5_real[25][23:8] :
                 (state==CAL && counter==7) ? imag_temp[9]   :
                 (state==CAL && counter==8) ? imag_temp[25]  : 16'd0;

assign fft_d10 = (state==CAL && counter==5) ? s5_real[10][23:8] :
                 (state==CAL && counter==6) ? s5_real[26][23:8] :
                 (state==CAL && counter==7) ? imag_temp[10]  :
                 (state==CAL && counter==8) ? imag_temp[26]  : 16'd0;

assign fft_d11 = (state==CAL && counter==5) ? s5_real[11][23:8] :
                 (state==CAL && counter==6) ? s5_real[27][23:8] :
                 (state==CAL && counter==7) ? imag_temp[11]  :
                 (state==CAL && counter==8) ? imag_temp[27]  : 16'd0;

assign fft_d12 = (state==CAL && counter==5) ? s5_real[12][23:8] :
                 (state==CAL && counter==6) ? s5_real[28][23:8] :
                 (state==CAL && counter==7) ? imag_temp[12]  :
                 (state==CAL && counter==8) ? imag_temp[28]  : 16'd0;

assign fft_d13 = (state==CAL && counter==5) ? s5_real[13][23:8] :
                 (state==CAL && counter==6) ? s5_real[29][23:8] :
                 (state==CAL && counter==7) ? imag_temp[13]  :
                 (state==CAL && counter==8) ? imag_temp[29]  : 16'd0;

assign fft_d14 = (state==CAL && counter==5) ? s5_real[14][23:8] :
                 (state==CAL && counter==6) ? s5_real[30][23:8] :
                 (state==CAL && counter==7) ? imag_temp[14]  :
                 (state==CAL && counter==8) ? imag_temp[30]  : 16'd0;

assign fft_d15 = (state==CAL && counter==5) ? s5_real[15][23:8] :
                 (state==CAL && counter==6) ? s5_real[31][23:8] :
                 (state==CAL && counter==7) ? imag_temp[15]  :
                 (state==CAL && counter==8) ? imag_temp[31]  : 16'd0;


// 輸出控制訊號
assign fftr_valid=(state==CAL&&(counter==5||counter==6 ));
assign ffti_valid=(state==CAL&&(counter==7||counter==8 ));
assign done=(state==DONE);

always@(posedge clk or posedge rst)begin
	if(rst)begin
		for(i=0;i<32;i=i+1)
			imag_temp[i]<=0;
	end		
	else if(state==CAL)begin
		if(counter==5)begin
			for(i=0;i<32;i=i+1)
				imag_temp[i]<=s5_imag[i][23:8];
		end
	end
end

//--------------------------------
// 輸入資料計數器
//--------------------------------
always@(posedge clk or posedge rst)begin
	if(rst)	
		counter<=0;
	else if(next_state==READ||next_state==CAL)
		counter<=counter+1;
end

//--------------------------------
// 輸入資料收集與 FSM 狀態轉移
//--------------------------------
always@(posedge clk or posedge rst)begin
	if(rst)begin
		for(i=0;i<32;i=i+1)
			fir_data[i]<=0;
	end		
	else if(next_state==READ||state==READ)begin
		fir_data[counter]<={{8{fir_d[15]}},fir_d,{8{1'b0}}};
	end	
	else if(state==CAL)begin
		fir_data[counter]<={{8{fir_d[15]}},fir_d,{8{1'b0}}};
	end	
end

always@(*)begin
	case(state)
		IDLE : next_state=(fir_valid)?READ:IDLE;
		READ : next_state=(&counter)?CAL:READ;  // counter == 15
		CAL : next_state=(counter==8&&!fir_valid)?DONE:CAL;
		DONE : next_state=DONE;
		default : next_state=IDLE;
	endcase
end

always@(posedge clk or posedge rst)begin
	if(rst)
		state<=IDLE;
	else
		state<=next_state;
end


//--------------------------------
// 蝶形單元函式定義
//--------------------------------
function [31:0] BU0_real;
    input signed[31:0] a;
    input signed[31:0] c;

    begin 
        BU0_real = a+c;
    end
endfunction

function [31:0] BU0_imag;
    input signed[31:0] b;
    input signed[31:0] d;

    begin 
        BU0_imag = b+d;
    end
endfunction

function [31:0] BU1_real;
    input signed[31:0] a;
    input signed[31:0] b;
	input signed[31:0] c;
    input signed[31:0] d;
	input signed[31:0] W_real;
    input signed[31:0] W_imag;
	
	reg signed[63:0] temp;
    begin 
		temp = ((a-c)*W_real+(d-b)*W_imag);
        BU1_real = temp[47:16];
    end
endfunction

function [31:0] BU1_imag;
    input signed[31:0] a;
    input signed[31:0] b;
	input signed[31:0] c;
    input signed[31:0] d;
	input signed[31:0] W_real;
    input signed[31:0] W_imag;
	
	reg signed[63:0] temp;
    begin 
		temp = ((a-c)*W_imag+(b-d)*W_real);
        BU1_imag = temp[47:16];
    end
endfunction


endmodule