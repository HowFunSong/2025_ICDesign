module BU(
	input signed [31:0] a,
	input signed [31:0] b,
	input signed [31:0] c,
	input signed [31:0] d,
	input signed [31:0] W_real,
	input signed [31:0] W_imag,
	
	output signed [31:0] result0_real,
	output signed [31:0] result0_imag,
	output signed [31:0] result1_real,
	output signed [31:0] result1_imag
);

/////////////////////////////////
// Please write your code here //
/////////////////////////////////
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

reg signed [31:0]re0_real; 
reg signed [31:0]re0_imag; 
reg signed [31:0]re1_real; 
reg signed [31:0]re1_imag; 

always @(*) begin
	re0_real = BU0_real(a, c);
	re0_imag = BU0_imag(b, d);
	re1_real = BU1_real(a, b, c, d, W_real, W_imag);
    re1_imag = BU1_imag(a, b, c, d, W_real, W_imag);
end


assign result0_real = re0_real;
assign result0_imag = re0_imag;
assign result1_real = re1_real;
assign result1_imag = re1_imag;



endmodule