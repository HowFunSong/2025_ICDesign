module FFT(
    input           clk,
    input           rst,
    input  [15:0]   fir_d,
    input           fir_valid,
    output          fft_valid,
    output          done,
    output [15:0]   fft_d0,
    output [15:0]   fft_d1,
    output [15:0]   fft_d2,
    output [15:0]   fft_d3,
    output [15:0]   fft_d4,
    output [15:0]   fft_d5,
    output [15:0]   fft_d6,
    output [15:0]   fft_d7,
    output [15:0]   fft_d8,
    output [15:0]   fft_d9,
    output [15:0]   fft_d10,
    output [15:0]   fft_d11,
    output [15:0]   fft_d12,
    output [15:0]   fft_d13,
    output [15:0]   fft_d14,
    output [15:0]   fft_d15
);

// 接收 16 筆 FIR 資料
reg [15:0] data_mem [0:31];
reg [3:0]  input_count;
reg        data_pass;
reg        buffer_idx;
reg        buffer_read;
// 傳給子模組

reg  [15:0] process_data[0:15];
wire [31:0] fft_real[0:15];
wire [31:0] fft_imag[0:15];

integer idx, idx_2;
reg  [4:0] buffer_rd;
always @(posedge clk) begin
    if (rst) begin
        input_count <= 4'd0;        
        for (idx = 0; idx < 32; idx = idx + 1)begin
            data_mem [idx] <= 16'd0;
        end
    end else if (fir_valid) begin
        buffer_rd = {buffer_idx, input_count};
        data_mem[buffer_rd] <= fir_d;
        
        input_count <= input_count + 4'd1;
    end
end

// 當收滿 16 筆時拉高一次
always @(posedge clk ) begin
    if (rst)begin
        data_pass <= 1'b0;
        buffer_idx  <= 1'd0;
        buffer_read <= 1'd0;
    end
    else begin
        if (fir_valid && input_count == 4'd15) begin
            data_pass <= 1'b1;
            buffer_read <= buffer_idx;
            buffer_idx <=  buffer_idx^1 ;   // 只在收滿的那拍才翻
        end 
        else begin
            data_pass <= 1'b0;
            buffer_idx <=  buffer_idx;
        end
    end
end

// FSM 狀態定義
parameter IDLE     = 3'd0,
          LOAD     = 3'd1,
          LOAD2    = 3'd2, 
          PROCESS  = 3'd3,
          OUTPUT_R = 3'd4,
          OUTPUT_I = 3'd5,
          DONE     = 3'd6;

reg [2:0] state, next_state;



// 子模組實例
FFTCAL u_fftcal (
    .x0 (process_data[0])   , .x1 (process_data[1])   , .x2 (process_data[2])   , .x3 (process_data[3])   ,
    .x4 (process_data[4])   , .x5 (process_data[5])   , .x6 (process_data[6])   , .x7 (process_data[7])   ,
    .x8 (process_data[8])   , .x9 (process_data[9])   , .x10(process_data[10])  , .x11(process_data[11])  ,
    .x12(process_data[12])  , .x13(process_data[13])  , .x14(process_data[14])  , .x15(process_data[15])  ,

    .y_real_0 (fft_real[0]) , .y_real_1 (fft_real[1]) , .y_real_2 (fft_real[2]) , .y_real_3 (fft_real[3]) ,
    .y_real_4 (fft_real[4]) , .y_real_5 (fft_real[5]) , .y_real_6 (fft_real[6]) , .y_real_7 (fft_real[7]) ,
    .y_real_8 (fft_real[8]) , .y_real_9 (fft_real[9]) , .y_real_10(fft_real[10]), .y_real_11(fft_real[11]),
    .y_real_12(fft_real[12]), .y_real_13(fft_real[13]), .y_real_14(fft_real[14]), .y_real_15(fft_real[15]),
    
    .y_imag_0 (fft_imag[0]) , .y_imag_1 (fft_imag[1]) , .y_imag_2 (fft_imag[2]) , .y_imag_3 (fft_imag[3]) ,
    .y_imag_4 (fft_imag[4]) , .y_imag_5 (fft_imag[5]) , .y_imag_6 (fft_imag[6]) , .y_imag_7 (fft_imag[7]) ,
    .y_imag_8 (fft_imag[8]) , .y_imag_9 (fft_imag[9]) , .y_imag_10(fft_imag[10]), .y_imag_11(fft_imag[11]),
    .y_imag_12(fft_imag[12]), .y_imag_13(fft_imag[13]), .y_imag_14(fft_imag[14]), .y_imag_15(fft_imag[15])
);

reg     [3:0] process_cycle;

// FSM 轉移
always @(*) begin
    case (state)
        IDLE    : next_state = data_pass  ? LOAD  : IDLE;
        LOAD    : next_state = LOAD2;
        LOAD2    : next_state = PROCESS;
        PROCESS :  next_state = process_cycle  == 8 ? OUTPUT_R : PROCESS;
        OUTPUT_R: next_state = OUTPUT_I;
        OUTPUT_I: next_state = fir_valid  ? IDLE     : DONE;
        DONE    : next_state = DONE;
        default:    next_state = IDLE;
    endcase
end


// FSM 狀態更新
always @(posedge clk) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end

// 控制流程
reg    [15:0] data_cache[0:15];
reg    [15:0] out_data[0:15];
reg    [4:0]  buffer_addr;
reg    fft_valid_reg, done_reg;
assign fft_valid = fft_valid_reg;
assign done      = done_reg;

integer i;
always @(posedge clk) begin
    if (rst) begin
        fft_valid_reg <= 1'b0;
        done_reg      <= 1'b0;
        for (i = 0; i < 16; i = i + 1) begin
            data_cache[i]      <= 16'd0;
            process_data[i] <= 16'd0;
            out_data[i]     <= 16'd0;
        end
    end else begin
        case (state)
            IDLE :begin
                fft_valid_reg <= 1'b0;
                process_cycle <= 4'b0;
            end
            LOAD : begin
                
                for (i = 0; i < 16; i = i + 1)begin
                        buffer_addr = (buffer_read << 4) + i;
                        data_cache[i] <= data_mem[buffer_addr];
                end
            end
            LOAD2 : begin
                for (i = 0; i < 16; i = i + 1)
                    process_data[i] <=  data_cache[i];
            end
            PROCESS: begin
                fft_valid_reg <= 1'b0;    
                process_cycle <= process_cycle + 1;
            end
            OUTPUT_R: begin
                fft_valid_reg <= 1'b1;    
                for (i = 0; i < 16; i = i + 1)
                    out_data[i] <= fft_real[i][23:8];
                
            end
            OUTPUT_I: begin
                fft_valid_reg <= 1'b1;
                for (i = 0; i < 16; i = i + 1)
                    out_data[i] <= fft_imag[i][23:8];
                
            end
            DONE: begin
                fft_valid_reg <= 1'b0;
                done_reg      <= 1'b1;
            end
            default: begin
                fft_valid_reg <= 1'b0;
                done_reg      <= 1'b0;
            end
        endcase
    end
end

// 連接輸出
assign fft_d0   = out_data[0];
assign fft_d8   = out_data[1];
assign fft_d4   = out_data[2];
assign fft_d12  = out_data[3];
assign fft_d2   = out_data[4];
assign fft_d10  = out_data[5];
assign fft_d6   = out_data[6];
assign fft_d14  = out_data[7];
assign fft_d1   = out_data[8];
assign fft_d9   = out_data[9];
assign fft_d5   = out_data[10];
assign fft_d13  = out_data[11];
assign fft_d3   = out_data[12];
assign fft_d11  = out_data[13];
assign fft_d7   = out_data[14];
assign fft_d15  = out_data[15];

endmodule
