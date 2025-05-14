module  FFTCAL (

    input [15:0] x0,
    input [15:0] x1,
    input [15:0] x2,
    input [15:0] x3,
    input [15:0] x4,
    input [15:0] x5,
    input [15:0] x6,
    input [15:0] x7,
    input [15:0] x8,
    input [15:0] x9,
    input [15:0] x10,
    input [15:0] x11,
    input [15:0] x12,
    input [15:0] x13,
    input [15:0] x14,
    input [15:0] x15,
    
    output [31:0] y_real_0,
    output [31:0] y_real_1,
    output [31:0] y_real_2,
    output [31:0] y_real_3,
    output [31:0] y_real_4,
    output [31:0] y_real_5,
    output [31:0] y_real_6,
    output [31:0] y_real_7,
    output [31:0] y_real_8,
    output [31:0] y_real_9,
    output [31:0] y_real_10,
    output [31:0] y_real_11,
    output [31:0] y_real_12,
    output [31:0] y_real_13,
    output [31:0] y_real_14,
    output [31:0] y_real_15,
 
    output [31:0] y_imag_0,
    output [31:0] y_imag_1,
    output [31:0] y_imag_2,
    output [31:0] y_imag_3,
    output [31:0] y_imag_4,
    output [31:0] y_imag_5,
    output [31:0] y_imag_6,
    output [31:0] y_imag_7,
    output [31:0] y_imag_8,
    output [31:0] y_imag_9,
    output [31:0] y_imag_10,
    output [31:0] y_imag_11,
    output [31:0] y_imag_12,
    output [31:0] y_imag_13,
    output [31:0] y_imag_14,
    output [31:0] y_imag_15
);
//00000000
//FFFFFFFF
parameter signed [31:0] W0_real = 32'h00010000;
parameter signed [31:0] W0_imag = 32'h00000000;
parameter signed [31:0] W1_real = 32'h0000EC83;
parameter signed [31:0] W1_imag = 32'hFFFF9E09;
parameter signed [31:0] W2_real = 32'h0000B504;
parameter signed [31:0] W2_imag = 32'hFFFF4AFC;
parameter signed [31:0] W3_real = 32'h000061F7;
parameter signed [31:0] W3_imag = 32'hFFFF137D;
parameter signed [31:0] W4_real = 32'h00000000;
parameter signed [31:0] W4_imag = 32'hFFFF0000;
parameter signed [31:0] W5_real = 32'hFFFF9E09;
parameter signed [31:0] W5_imag = 32'hFFFF137D;
parameter signed [31:0] W6_real = 32'hFFFF4AFC;
parameter signed [31:0] W6_imag = 32'hFFFF4AFC;
parameter signed [31:0] W7_real = 32'hFFFF137D;
parameter signed [31:0] W7_imag = 32'hFFFF9E09;

// ------------------------------
// Stage 0: sign‑extend + zero padding
// ------------------------------
reg [31:0] real_stage0 [0:15];
reg [31:0] imag_stage0 [0:15];

always @(*) begin
    real_stage0[0]  = { {8{x0[15]}},  x0,  8'd0 }; imag_stage0[0]  = 32'd0;
    real_stage0[1]  = { {8{x1[15]}},  x1,  8'd0 }; imag_stage0[1]  = 32'd0;
    real_stage0[2]  = { {8{x2[15]}},  x2,  8'd0 }; imag_stage0[2]  = 32'd0;
    real_stage0[3]  = { {8{x3[15]}},  x3,  8'd0 }; imag_stage0[3]  = 32'd0;
    real_stage0[4]  = { {8{x4[15]}},  x4,  8'd0 }; imag_stage0[4]  = 32'd0;
    real_stage0[5]  = { {8{x5[15]}},  x5,  8'd0 }; imag_stage0[5]  = 32'd0;
    real_stage0[6]  = { {8{x6[15]}},  x6,  8'd0 }; imag_stage0[6]  = 32'd0;
    real_stage0[7]  = { {8{x7[15]}},  x7,  8'd0 }; imag_stage0[7]  = 32'd0;
    real_stage0[8]  = { {8{x8[15]}},  x8,  8'd0 }; imag_stage0[8]  = 32'd0;
    real_stage0[9]  = { {8{x9[15]}},  x9,  8'd0 }; imag_stage0[9]  = 32'd0;
    real_stage0[10] = { {8{x10[15]}}, x10, 8'd0 }; imag_stage0[10] = 32'd0;
    real_stage0[11] = { {8{x11[15]}}, x11, 8'd0 }; imag_stage0[11] = 32'd0;
    real_stage0[12] = { {8{x12[15]}}, x12, 8'd0 }; imag_stage0[12] = 32'd0;
    real_stage0[13] = { {8{x13[15]}}, x13, 8'd0 }; imag_stage0[13] = 32'd0;
    real_stage0[14] = { {8{x14[15]}}, x14, 8'd0 }; imag_stage0[14] = 32'd0;
    real_stage0[15] = { {8{x15[15]}}, x15, 8'd0 }; imag_stage0[15] = 32'd0;
end

// ------------------------------
// Stage 1: butterfly 0↔8, 1↔9, …, 7↔15
// ------------------------------
reg [31:0] real_stage1 [0:15];
reg [31:0] imag_stage1 [0:15];

// 暫存 a,b 以及乘法結果
reg signed [31:0] a1, b1, c1;
reg signed [63:0] m1, n1;

always @(*) begin
    // pair 0 & 8
    real_stage1[0]  = real_stage0[0] + real_stage0[8];
    imag_stage1[0]  = imag_stage0[0] + imag_stage0[8];

    a1 = $signed(real_stage0[0]) - $signed(real_stage0[8]);
    b1 = $signed(imag_stage0[0]) - $signed(imag_stage0[8]);
    c1 = $signed(imag_stage0[8]) - $signed(imag_stage0[0]);

    m1 = a1*W0_real + c1*W0_imag;
    n1 = a1*W0_imag + b1*W0_real;
    real_stage1[8] = m1 >>>16;
    imag_stage1[8] = n1 >>>16;

    // pair 1 & 9
    real_stage1[1]  = real_stage0[1] + real_stage0[9];
    imag_stage1[1]  = imag_stage0[1] + imag_stage0[9];

    a1 = $signed(real_stage0[1]) - $signed(real_stage0[9]);
    b1 = $signed(imag_stage0[1]) - $signed(imag_stage0[9]);
    c1 = $signed(imag_stage0[9]) - $signed(imag_stage0[1]);

    m1 = a1*W1_real + c1*W1_imag;
    n1 = a1*W1_imag + b1*W1_real;
    real_stage1[9] = m1 >>>16;
    imag_stage1[9] = n1 >>>16;
    
    // pair 2 & 10
    real_stage1[2]  = real_stage0[2] + real_stage0[10];
    imag_stage1[2]  = imag_stage0[2] + imag_stage0[10];

    a1 = $signed(real_stage0[2]) - $signed(real_stage0[10]);
    b1 = $signed(imag_stage0[2]) - $signed(imag_stage0[10]);
    c1 = $signed(imag_stage0[10]) - $signed(imag_stage0[2]);

    m1 = a1*W2_real + c1*W2_imag;
    n1 = a1*W2_imag + b1*W2_real;
    real_stage1[10] = m1 >>> 16;
    imag_stage1[10] = n1 >>> 16;

    // pair 3 & 11
    real_stage1[3]  = real_stage0[3] + real_stage0[11];
    imag_stage1[3]  = imag_stage0[3] + imag_stage0[11];

    a1 = $signed(real_stage0[3]) - $signed(real_stage0[11]);
    b1 = $signed(imag_stage0[3]) - $signed(imag_stage0[11]);
    c1 = $signed(imag_stage0[11]) - $signed(imag_stage0[3]);

    m1 = a1*W3_real + c1*W3_imag;
    n1 = a1*W3_imag + b1*W3_real;
    real_stage1[11] = m1 >>>16;
    imag_stage1[11] = n1 >>>16;

    // pair 4 & 12
    real_stage1[4]  = real_stage0[4] + real_stage0[12];
    imag_stage1[4]  = imag_stage0[4] + imag_stage0[12];

    a1 = $signed(real_stage0[4]) - $signed(real_stage0[12]);
    b1 = $signed(imag_stage0[4]) - $signed(imag_stage0[12]);
    c1 = $signed(imag_stage0[12]) - $signed(imag_stage0[4]);

    m1 = a1*W4_real + c1*W4_imag;
    n1 = a1*W4_imag + b1*W4_real;
    real_stage1[12] = m1 >>>16;
    imag_stage1[12] = n1 >>>16;
    
    // pair 5 & 13
    real_stage1[5]  = real_stage0[5]  + real_stage0[13];
    imag_stage1[5]  = imag_stage0[5]  + imag_stage0[13];

    a1 = $signed(real_stage0[5]) - $signed(real_stage0[13]);
    b1 = $signed(imag_stage0[5]) - $signed(imag_stage0[13]);
    c1 = $signed(imag_stage0[13]) - $signed(imag_stage0[5]);

    m1 = a1*W5_real + c1*W5_imag;
    n1 = a1*W5_imag + b1*W5_real;
    real_stage1[13] = m1 >>>16;
    imag_stage1[13] = n1 >>>16;


    // pair 6 & 14
    real_stage1[6]  = real_stage0[6] + real_stage0[14];
    imag_stage1[6]  = imag_stage0[6] + imag_stage0[14];

    a1 = $signed(real_stage0[6]) - $signed(real_stage0[14]);
    b1 = $signed(imag_stage0[6]) - $signed(imag_stage0[14]);
    c1 = $signed(imag_stage0[14]) - $signed(imag_stage0[6]);

    m1 = a1*W6_real + c1*W6_imag;
    n1 = a1*W6_imag + b1*W6_real;
    real_stage1[14] = m1 >>> 16;
    imag_stage1[14] = n1 >>> 16;

    // pair 7 & 15
    real_stage1[7]  = real_stage0[7] + real_stage0[15];
    imag_stage1[7]  = imag_stage0[7] + imag_stage0[15];

    a1 = $signed(real_stage0[7]) - $signed(real_stage0[15]);
    b1 = $signed(imag_stage0[7]) - $signed(imag_stage0[15]);
    c1 = $signed(imag_stage0[15]) - $signed(imag_stage0[7]);

    m1 = a1*W7_real + c1*W7_imag;
    n1 = a1*W7_imag + b1*W7_real;
    real_stage1[15] = m1 >>> 16;
    imag_stage1[15] = n1 >>> 16;

end

// ------------------------------
// Stage 2: stride = 4, pairs (0,4),(1,5),(2,6),(3,7),(8,12),(9,13),(10,14),(11,15)
// ------------------------------
reg [31:0] real_stage2[0:15], imag_stage2[0:15];

// 暫存 a,b 以及乘法結果
reg signed [31:0] a2, b2, c2;
reg signed [63:0] m2, n2;

always @(*) begin
    // pair 0 & 4
    real_stage2[0]  = real_stage1[0]  + real_stage1[4];
    imag_stage2[0]  = imag_stage1[0]  + imag_stage1[4];

    a2 = $signed(real_stage1[0]) - $signed(real_stage1[4]);
    b2 = $signed(imag_stage1[0]) - $signed(imag_stage1[4]);
    c2 = $signed(imag_stage1[4]) - $signed(imag_stage1[0]);

    m2 = a2*W0_real + c2*W0_imag;
    n2 = a2*W0_imag + b2*W0_real;
    real_stage2[4]  = m2 >>> 16;
    imag_stage2[4]  = n2 >>> 16;

    // pair 1 & 5
    real_stage2[1]  = real_stage1[1]  + real_stage1[5];
    imag_stage2[1]  = imag_stage1[1]  + imag_stage1[5];

    a2 = $signed(real_stage1[1]) - $signed(real_stage1[5]);
    b2 = $signed(imag_stage1[1]) - $signed(imag_stage1[5]);
    c2 = $signed(imag_stage1[5]) - $signed(imag_stage1[1]);

    m2 = a2*W2_real + c2*W2_imag;
    n2 = a2*W2_imag + b2*W2_real;
    real_stage2[5]  = m2 >>> 16;
    imag_stage2[5]  = n2 >>> 16;

    // pair 2 & 6
    real_stage2[2]  = real_stage1[2]  + real_stage1[6];
    imag_stage2[2]  = imag_stage1[2]  + imag_stage1[6];

    a2 = $signed(real_stage1[2]) - $signed(real_stage1[6]);
    b2 = $signed(imag_stage1[2]) - $signed(imag_stage1[6]);
    c2 = $signed(imag_stage1[6]) - $signed(imag_stage1[2]);

    m2 = a2*W4_real + c2*W4_imag;
    n2 = a2*W4_imag + b2*W4_real;
    real_stage2[6]  = m2 >>> 16;
    imag_stage2[6]  = n2 >>> 16;

    // pair 3 & 7
    real_stage2[3]  = real_stage1[3]  + real_stage1[7];
    imag_stage2[3]  = imag_stage1[3]  + imag_stage1[7];

    a2 = $signed(real_stage1[3]) - $signed(real_stage1[7]);
    b2 = $signed(imag_stage1[3]) - $signed(imag_stage1[7]);
    c2 = $signed(imag_stage1[7]) - $signed(imag_stage1[3]);

    m2 = a2*W6_real + c2*W6_imag;
    n2 = a2*W6_imag + b2*W6_real;
    real_stage2[7]  = m2 >>> 16;
    imag_stage2[7]  = n2 >>> 16;

    // pair 8 & 12
    real_stage2[8]   = real_stage1[8]   + real_stage1[12];
    imag_stage2[8]   = imag_stage1[8]   + imag_stage1[12];

    a2 = $signed(real_stage1[8]) - $signed(real_stage1[12]);
    b2 = $signed(imag_stage1[8]) - $signed(imag_stage1[12]);
    c2 = $signed(imag_stage1[12]) - $signed(imag_stage1[8]);

    m2 = a2*W0_real + c2*W0_imag;
    n2 = a2*W0_imag + b2*W0_real;
    real_stage2[12]  = m2 >>> 16;
    imag_stage2[12]  = n2 >>> 16;

    // pair 9 & 13
    real_stage2[9]   = real_stage1[9] + real_stage1[13];
    imag_stage2[9]   = imag_stage1[9] + imag_stage1[13];
    
    a2 = $signed(real_stage1[9]) - $signed(real_stage1[13]);
    b2 = $signed(imag_stage1[9]) - $signed(imag_stage1[13]);
    c2 = $signed(imag_stage1[13]) - $signed(imag_stage1[9]);

    m2 = a2*W2_real + c2*W2_imag;
    n2 = a2*W2_imag + b2*W2_real;
    real_stage2[13]  = m2 >>> 16;
    imag_stage2[13]  = n2 >>> 16;

    // pair 10 & 14
    real_stage2[10]  = real_stage1[10]  + real_stage1[14];
    imag_stage2[10]  = imag_stage1[10]  + imag_stage1[14];

    a2 = $signed(real_stage1[10]) - $signed(real_stage1[14]);
    b2 = $signed(imag_stage1[10]) - $signed(imag_stage1[14]);
    c2 = $signed(imag_stage1[14]) - $signed(imag_stage1[10]);

    m2 = a2*W4_real + c2*W4_imag;
    n2 = a2*W4_imag + b2*W4_real;
    real_stage2[14]  = m2 >>> 16;
    imag_stage2[14]  = n2 >>> 16;

    // pair 11 & 15
    real_stage2[11]  = real_stage1[11]  + real_stage1[15];
    imag_stage2[11]  = imag_stage1[11]  + imag_stage1[15];

    a2 = $signed(real_stage1[11]) - $signed(real_stage1[15]);
    b2 = $signed(imag_stage1[11]) - $signed(imag_stage1[15]);
    c2 = $signed(imag_stage1[15]) - $signed(imag_stage1[11]);

    m2 = a2*W6_real + c2*W6_imag;
    n2 = a2*W6_imag + b2*W6_real;
    real_stage2[15]  = m2 >>> 16;
    imag_stage2[15]  = n2 >>> 16;
end


// ------------------------------
// Stage 3: stride = 2, pairs (0,2),(1,3),(4,6),(5,7),(8,10),(9,11),(12,14),(13,15)
// ------------------------------
reg [31:0] real_stage3[0:15], imag_stage3[0:15];
// 暫存 a,b 以及乘法結果
reg signed [31:0] a3, b3, c3;
reg signed [63:0] m3, n3;

always @(*) begin
    // pair 0 & 2
    real_stage3[0]  = real_stage2[0]  + real_stage2[2];
    imag_stage3[0]  = imag_stage2[0]  + imag_stage2[2];

    a3 = $signed(real_stage2[0]) - $signed(real_stage2[2]);
    b3 = $signed(imag_stage2[0]) - $signed(imag_stage2[2]);
    c3 = $signed(imag_stage2[2]) - $signed(imag_stage2[0]);

    m3 = a3*W0_real + c3*W0_imag;
    n3 = a3*W0_imag + b3*W0_real;
    real_stage3[2]  = m3 >>> 16;
    imag_stage3[2]  = n3 >>> 16;

    // pair 1 & 3
    real_stage3[1]  = real_stage2[1]  + real_stage2[3];
    imag_stage3[1]  = imag_stage2[1]  + imag_stage2[3];

    a3 = $signed(real_stage2[1]) - $signed(real_stage2[3]);
    b3 = $signed(imag_stage2[1]) - $signed(imag_stage2[3]);
    c3 = $signed(imag_stage2[3]) - $signed(imag_stage2[1]);

    m3 = a3*W4_real + c3*W4_imag;
    n3 = a3*W4_imag + b3*W4_real;
    real_stage3[3]  = m3 >>> 16;
    imag_stage3[3]  = n3 >>> 16;

    // pair 4 & 6
    real_stage3[4]  = real_stage2[4]  + real_stage2[6];
    imag_stage3[4]  = imag_stage2[4]  + imag_stage2[6];

    a3 = $signed(real_stage2[4]) - $signed(real_stage2[6]);
    b3 = $signed(imag_stage2[4]) - $signed(imag_stage2[6]);
    c3 = $signed(imag_stage2[6]) - $signed(imag_stage2[4]);

    m3 = a3*W0_real + c3*W0_imag;
    n3 = a3*W0_imag + b3*W0_real;
    real_stage3[6]  = m3 >>> 16;
    imag_stage3[6]  = n3 >>> 16;

    // pair 5 & 7
    real_stage3[5]  = real_stage2[5]  + real_stage2[7];
    imag_stage3[5]  = imag_stage2[5]  + imag_stage2[7];

    a3 = $signed(real_stage2[5]) - $signed(real_stage2[7]);
    b3 = $signed(imag_stage2[5]) - $signed(imag_stage2[7]);
    c3 = $signed(imag_stage2[7]) - $signed(imag_stage2[5]);

    m3 = a3*W4_real + c3*W4_imag;
    n3 = a3*W4_imag + b3*W4_real;
    real_stage3[7]  = m3 >>> 16;
    imag_stage3[7]  = n3 >>> 16;

    // pair 8 & 10
    real_stage3[8]  = real_stage2[8]  + real_stage2[10];
    imag_stage3[8]  = imag_stage2[8]  + imag_stage2[10];

    a3 = $signed(real_stage2[8]) - $signed(real_stage2[10]);
    b3 = $signed(imag_stage2[8]) - $signed(imag_stage2[10]);
    c3 = $signed(imag_stage2[10]) - $signed(imag_stage2[8]);

    m3 = a3*W0_real + c3*W0_imag;
    n3 = a3*W0_imag + b3*W0_real;
    real_stage3[10] = m3 >>> 16;
    imag_stage3[10] = n3 >>> 16;

    // pair 9 & 11
    real_stage3[9]  = real_stage2[9]  + real_stage2[11];
    imag_stage3[9]  = imag_stage2[9]  + imag_stage2[11];

    a3 = $signed(real_stage2[9]) - $signed(real_stage2[11]);
    b3 = $signed(imag_stage2[9]) - $signed(imag_stage2[11]);
    c3 = $signed(imag_stage2[11]) - $signed(imag_stage2[9]);

    m3 = a3*W4_real + c3*W4_imag;
    n3 = a3*W4_imag + b3*W4_real;
    real_stage3[11] = m3 >>> 16;
    imag_stage3[11] = n3 >>> 16;

    // pair 12 & 14
    real_stage3[12] = real_stage2[12] + real_stage2[14];
    imag_stage3[12] = imag_stage2[12] + imag_stage2[14];

    a3 = $signed(real_stage2[12]) - $signed(real_stage2[14]);
    b3 = $signed(imag_stage2[12]) - $signed(imag_stage2[14]);
    c3 = $signed(imag_stage2[14]) - $signed(imag_stage2[12]);

    m3 = a3*W0_real + c3*W0_imag;
    n3 = a3*W0_imag + b3*W0_real;
    real_stage3[14] = m3 >>> 16;
    imag_stage3[14] = n3 >>> 16;

    // pair 13 & 15
    real_stage3[13] = real_stage2[13] + real_stage2[15];
    imag_stage3[13] = imag_stage2[13] + imag_stage2[15];

    a3 = $signed(real_stage2[13]) - $signed(real_stage2[15]);
    b3 = $signed(imag_stage2[13]) - $signed(imag_stage2[15]);
    c3 = $signed(imag_stage2[15]) - $signed(imag_stage2[13]);

    m3 = a3*W4_real + c3*W4_imag;
    n3 = a3*W4_imag + b3*W4_real;
    real_stage3[15] = m3 >>> 16;
    imag_stage3[15] = n3 >>> 16;
end


// ------------------------------
// Stage 4: stride = 1, pairs (0,1),(2,3),(4,5),(6,7),(8,9),(10,11),(12,13),(14,15)
// ------------------------------
reg [31:0] real_stage4[0:15], imag_stage4[0:15];
// 暫存 a,b 以及乘法結果
reg signed [31:0] a4, b4, c4;
reg signed [63:0] m4, n4;

always @(*) begin
    // pair 0 & 1
    real_stage4[0]  = real_stage3[0]  + real_stage3[1];
    imag_stage4[0]  = imag_stage3[0]  + imag_stage3[1];

    a4 = $signed(real_stage3[0]) - $signed(real_stage3[1]);
    b4 = $signed(imag_stage3[0]) - $signed(imag_stage3[1]);
    c4 = $signed(imag_stage2[1]) - $signed(imag_stage2[0]);

    m4 = a4*W0_real + c4*W0_imag;
    n4 = a4*W0_imag + b4*W0_real;
    real_stage4[1]  = m4 >>> 16;
    imag_stage4[1]  = n4 >>> 16;

    // pair 2 & 3
    real_stage4[2]  = real_stage3[2]  + real_stage3[3];
    imag_stage4[2]  = imag_stage3[2]  + imag_stage3[3];

    a4 = $signed(real_stage3[2]) - $signed(real_stage3[3]);
    b4 = $signed(imag_stage3[2]) - $signed(imag_stage3[3]);
    c4 = $signed(imag_stage2[3]) - $signed(imag_stage2[2]);

    m4 = a4*W0_real + c4*W0_imag;
    n4 = a4*W0_imag + b4*W0_real;
    real_stage4[3]  = m4 >>> 16;
    imag_stage4[3]  = n4 >>> 16;

    // pair 4 & 5
    real_stage4[4]  = real_stage3[4]  + real_stage3[5];
    imag_stage4[4]  = imag_stage3[4]  + imag_stage3[5];

    a4 = $signed(real_stage3[4]) - $signed(real_stage3[5]);
    b4 = $signed(imag_stage3[4]) - $signed(imag_stage3[5]);
    c4 = $signed(imag_stage2[5]) - $signed(imag_stage2[4]);
    
    m4 = a4*W0_real + c4*W0_imag;
    n4 = a4*W0_imag + b4*W0_real;
    real_stage4[5]  = m4 >>> 16;
    imag_stage4[5]  = n4 >>> 16;

    // pair 6 & 7
    real_stage4[6]  = real_stage3[6]  + real_stage3[7];
    imag_stage4[6]  = imag_stage3[6]  + imag_stage3[7];

    a4 = $signed(real_stage3[6]) - $signed(real_stage3[7]);
    b4 = $signed(imag_stage3[6]) - $signed(imag_stage3[7]);
    c4 = $signed(imag_stage2[7]) - $signed(imag_stage2[6]);

    m4 = a4*W0_real + c4*W0_imag;
    n4 = a4*W0_imag + b4*W0_real;
    real_stage4[7]  = m4 >>> 16;
    imag_stage4[7]  = n4 >>> 16;

    // pair 8 & 9
    real_stage4[8]  = real_stage3[8]  + real_stage3[9];
    imag_stage4[8]  = imag_stage3[8]  + imag_stage3[9];

    a4 = $signed(real_stage3[8]) - $signed(real_stage3[9]);
    b4 = $signed(imag_stage3[8]) - $signed(imag_stage3[9]);
    c4 = $signed(imag_stage2[9]) - $signed(imag_stage2[8]);

    m4 = a4*W0_real + c4*W0_imag;
    n4 = a4*W0_imag + b4*W0_real;
    real_stage4[9]  = m4 >>> 16;
    imag_stage4[9]  = n4 >>> 16;

    // pair 10 & 11
    real_stage4[10] = real_stage3[10] + real_stage3[11];
    imag_stage4[10] = imag_stage3[10] + imag_stage3[11];

    a4 = $signed(real_stage3[10]) - $signed(real_stage3[11]);
    b4 = $signed(imag_stage3[10]) - $signed(imag_stage3[11]);
    c4 = $signed(imag_stage2[11]) - $signed(imag_stage2[10]);

    m4 = a4*W0_real + c4*W0_imag;
    n4 = a4*W0_imag + b4*W0_real;
    real_stage4[11] = m4 >>> 16;
    imag_stage4[11] = n4 >>> 16;

    // pair 12 & 13
    real_stage4[12] = real_stage3[12] + real_stage3[13];
    imag_stage4[12] = imag_stage3[12] + imag_stage3[13];

    a4 = $signed(real_stage3[12]) - $signed(real_stage3[13]);
    b4 = $signed(imag_stage3[12]) - $signed(imag_stage3[13]);
    c4 = $signed(imag_stage2[13]) - $signed(imag_stage2[12]);

    m4 = a4*W0_real + c4*W0_imag;
    n4 = a4*W0_imag + b4*W0_real;
    real_stage4[13] = m4 >>> 16;
    imag_stage4[13] = n4 >>> 16;

    // pair 14 & 15
    real_stage4[14] = real_stage3[14] + real_stage3[15];
    imag_stage4[14] = imag_stage3[14] + imag_stage3[15];

    a4 = $signed(real_stage3[14]) - $signed(real_stage3[15]);
    b4 = $signed(imag_stage3[14]) - $signed(imag_stage3[15]);
    c4 = $signed(imag_stage2[15]) - $signed(imag_stage2[14]);

    m4 = a4*W0_real + c4*W0_imag;
    n4 = a4*W0_imag + b4*W0_real;
    real_stage4[15] = m4 >>> 16;
    imag_stage4[15] = n4 >>> 16;
end


// ------------------------------
// Final output assignments
// ------------------------------
assign y_real_0   = real_stage4[0];
assign y_imag_0   = imag_stage4[0];
assign y_real_1   = real_stage4[1];
assign y_imag_1   = imag_stage4[1];
assign y_real_2   = real_stage4[2];
assign y_imag_2   = imag_stage4[2];
assign y_real_3   = real_stage4[3];
assign y_imag_3   = imag_stage4[3];
assign y_real_4   = real_stage4[4];
assign y_imag_4   = imag_stage4[4];
assign y_real_5   = real_stage4[5];
assign y_imag_5   = imag_stage4[5];
assign y_real_6   = real_stage4[6];
assign y_imag_6   = imag_stage4[6];
assign y_real_7   = real_stage4[7];
assign y_imag_7   = imag_stage4[7];
assign y_real_8   = real_stage4[8];
assign y_imag_8   = imag_stage4[8];
assign y_real_9   = real_stage4[9];
assign y_imag_9   = imag_stage4[9];
assign y_real_10  = real_stage4[10];
assign y_imag_10  = imag_stage4[10];
assign y_real_11  = real_stage4[11];
assign y_imag_11  = imag_stage4[11];
assign y_real_12  = real_stage4[12];
assign y_imag_12  = imag_stage4[12];
assign y_real_13  = real_stage4[13];
assign y_imag_13  = imag_stage4[13];
assign y_real_14  = real_stage4[14];
assign y_imag_14  = imag_stage4[14];
assign y_real_15  = real_stage4[15];
assign y_imag_15  = imag_stage4[15];



endmodule
