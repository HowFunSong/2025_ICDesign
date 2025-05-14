`timescale 1ns/10ps
`include "./include/define.v"

module ATCONV_Wrapper(
    input		                           bus_clk  ,
    input		                           bus_rst  ,
    input         [`BUS_DATA_BITS-1:0]     RDATA_M  ,
    input 	      					 	   RLAST_M  ,
    input 	      					 	   WREADY_M ,
    input 	      					 	   RREADY_M ,
    output reg    [`BUS_ID_BITS  -1:0]     ID_M	    ,
    output reg    [`BUS_ADDR_BITS-1:0]     ADDR_M	,
    output reg    [`BUS_DATA_BITS-1:0]     WDATA_M  ,
    output        [`BUS_LEN_BITS -1:0]     BLEN_M   ,
    output reg						 	   WLAST_M  ,
    output reg  						   WVALID_M ,
    output reg  						   RVALID_M ,
    output                                 done   
);

    //ROM       
    reg [`BUS_ADDR_BITS-1:0] iaddr_reg;
    //RAM0

    reg[`BUS_ADDR_BITS-1:0] layer0_A;
    reg[`BUS_DATA_BITS-1:0] layer0_D;
    reg[`BUS_DATA_BITS-1:0] layer0_Q;
    
    //RAM1
    reg[`BUS_ADDR_BITS-1:0] layer1_A;
    reg[`BUS_DATA_BITS-1:0] layer1_D;
    reg[`BUS_DATA_BITS-1:0] layer1_Q;       
          
    // 狀態編碼
    parameter [3:0]IDLE                    = 4'd0;
    parameter [3:0]WAIT_ROM_READ_READY     = 4'd1;
    parameter [3:0]LOAD_FROM_ROM           = 4'd2;
    parameter [3:0]PROCESS                 = 4'd3; // conv + relu
    parameter [3:0]WAIT_LAYER0_WRITE_READY = 4'd4;
    parameter [3:0]SAVE_TO_LAYER0          = 4'd5;
    parameter [3:0]WAIT_LAYER0_READ_READY  = 4'd6;
    parameter [3:0]LOAD_FROM_LAYER0        = 4'd7;
    parameter [3:0]MAXPOOLING              = 4'd8;
    parameter [3:0]WAIT_LAYER1_WRITE_READY = 4'd9;
    parameter [3:0]SAVE_TO_LAYER1          = 4'd10;
    parameter [3:0]DONE                    = 4'd11;

    // 狀態暫存
    reg [3:0] state, next_state;
    
    //====================================================
    // 1) AXI-like 主裝置握手訊號
    //====================================================
    reg [3:0] blen_reg;
    reg [3:0] transmit_cnt ;//比對傳送資料比數
    assign BLEN_M = blen_reg;
    always @(*) begin
        // 其他狀態維持預設
        WVALID_M = 1'b0;
        WLAST_M  = 1'b0;
        RVALID_M = 1'b0;
        ID_M     = 2'd3;
        ADDR_M  = 12'd0;
        blen_reg= 4'd1; 
        case(state)
            WAIT_ROM_READ_READY :begin
                RVALID_M = 1'd1;
                ID_M     = 2'd0;
                ADDR_M   = iaddr_reg;
                blen_reg = 4'b0001;
            end
            // 從 ROM 讀資料
            LOAD_FROM_ROM: begin
                RVALID_M = 1'd0;
                ID_M     = 2'd0;
                ADDR_M   = iaddr_reg;
                blen_reg = 4'b0001;
            end
            PROCESS: ;
            WAIT_LAYER0_WRITE_READY :begin//4
                WVALID_M = 1'd1;
                ID_M     = 2'd1;
                ADDR_M   = layer0_A;
                WDATA_M  = layer0_D;
                blen_reg = 4'b0001;
            end
            // 將卷積→ReLU 結果寫入 Layer0
            SAVE_TO_LAYER0: begin//5
                WVALID_M = 1'd0;
                ID_M     = 2'd1;
                ADDR_M   = layer0_A;
                WDATA_M  = layer0_D;
                blen_reg = 4'b0001;
                if (transmit_cnt == blen_reg - 1) begin
                    WLAST_M  = 1'b1;
                end
            end
            WAIT_LAYER0_READ_READY :begin
                RVALID_M = 1'd1;
                ID_M     = 2'd1; // 建立通道ID
                ADDR_M   = layer0_A;
                blen_reg = 4'b0001;
            end
            // 從 Layer0 讀資料（MaxPool）
            LOAD_FROM_LAYER0: begin
                RVALID_M = 1'd0;
                ID_M     = 2'd1; // 建立通道ID
                ADDR_M   = layer0_A;
                blen_reg = 4'b0001;
            end
            WAIT_LAYER1_WRITE_READY: begin
                WVALID_M = 1'd1;
                ID_M     = 2'd2;
                ADDR_M   = layer1_A;
                WDATA_M  = layer1_D;
                blen_reg = 4'b0001;
            end
            // 將 MaxPool→RoundUp 結果寫入 Layer1
            SAVE_TO_LAYER1: begin
                WVALID_M = 1'b0;
                ID_M     = 2'd2;
                ADDR_M   = layer1_A;
                WDATA_M  = layer1_D;
                blen_reg = 4'b0001;
                if (transmit_cnt == blen_reg - 1) begin
                    WLAST_M  = 1'b1;
                end

            end

            default: begin
                
            end
        endcase
    end

    ///////////////////////////////
    ///卷積操作暫存
    //////////////////////////////
    
    // 卷積核常數 (16-bit signed)
    parameter signed[15:0] k0   = 16'hFFFF; 
    parameter signed[15:0] k1   = 16'hFFFE; 
    parameter signed[15:0] k2   = 16'hFFFF; 
    parameter signed[15:0] k3   = 16'hFFFC; 
    parameter signed[15:0] k4   = 16'h0010; 
    parameter signed[15:0] k5   = 16'hFFFC;
    parameter signed[15:0] k6   = 16'hFFFF;
    parameter signed[15:0] k7   = 16'hFFFE;
    parameter signed[15:0] k8   = 16'hFFFF;
    parameter signed[31:0] bias = 32'hFFFFFFF4;

    // 卷積 kernel 參數
    reg [15:0] kernel [0:2][0:2];
    reg [3 :0] kernel_cnt    ;
    reg [12:0] kernel_center ;

    // 卷積計算結果
    reg signed [31:0] conv_result;   // 32 位的卷積結果
    reg signed [31:0] relu_result;   // 32 位的 ReLU 結果

    // 各乘法部分結果
    wire signed [31:0] t0, t1, t2, t3, t4, t5, t6, t7, t8;

    assign t0 = ($signed(kernel[0][0]) * k0) >>> 4;
    assign t1 = ($signed(kernel[0][1]) * k1) >>> 4;
    assign t2 = ($signed(kernel[0][2]) * k2) >>> 4;
    assign t3 = ($signed(kernel[1][0]) * k3) >>> 4;
    assign t4 = ($signed(kernel[1][1]) * k4) >>> 4;
    assign t5 = ($signed(kernel[1][2]) * k5) >>> 4;
    assign t6 = ($signed(kernel[2][0]) * k6) >>> 4;
    assign t7 = ($signed(kernel[2][1]) * k7) >>> 4;
    assign t8 = ($signed(kernel[2][2]) * k8) >>> 4;
    //////////////////////////////////
    // 組合電路: 卷積 + ReLU
    //////////////////////////////////
    always@(*)begin
    conv_result = t0 + t1 + t2 + t3 + t4 + t5 + t6 + t7 + t8 + bias;  // CONVOLUTION 操作，最後加上bias
    relu_result = (conv_result[31] == 1'b1) ? 32'd0 : conv_result;  // ReLU 操作：如果 conv_result 是負數則設為 0，否則保留原來的值
    end
    //////////////////////////////////
    ///MAXPOOL + ROUNDUP 操作暫存、參數
    /////////////////////////////////
    // 組合電路: maxpool 參數
    reg [15:0] pool_win [0:1][0:1];
    reg [1 :0] pool_read_cnt      ;
    reg [11:0] layer0_read_addr   ;

    reg [11:0] layer1_wrt_addr    ;
    reg [5:0]  layer0_row         ;
    reg [5:0]  layer0_col         ;

    reg [15:0] s0, s1, s2, s3, s4;
    reg [15:0] maxpooling_result;
    parameter [15:0] MASK_FRAC = 16'b0000_0000_0000_1111;
    parameter [15:0] MASK_INT  = 16'b1111_1111_1111_0000;

    // 組合電路 : 計算 maxpooling + roundup 
    always@(*)begin
    s0 = pool_win[0][0] > pool_win[0][1] ? pool_win[0][0] : pool_win[0][1];
    s1 = pool_win[1][0] > pool_win[1][1] ? pool_win[1][0] : pool_win[1][1];
    s2 = s0 > s1 ? s0 : s1;
    
    s3 = MASK_FRAC & s2;
    s4 = s2 & MASK_INT;
    maxpooling_result = s3 > 0 ? s4 + 16'd16 : s4 ;
    end


    // 組合電路: 下一狀態邏輯
    always@(*)begin
    case(state)
        IDLE                    : next_state = WAIT_ROM_READ_READY ; //0
        WAIT_ROM_READ_READY     : next_state = (RVALID_M && RREADY_M) ? LOAD_FROM_ROM : WAIT_ROM_READ_READY; //1
        LOAD_FROM_ROM           : next_state = (RLAST_M) ? (kernel_cnt == 8)? PROCESS : WAIT_ROM_READ_READY : LOAD_FROM_ROM  ;//2
        PROCESS                 : next_state = WAIT_LAYER0_WRITE_READY ;//3
        WAIT_LAYER0_WRITE_READY : next_state = (WVALID_M && WREADY_M) ? SAVE_TO_LAYER0 : WAIT_LAYER0_WRITE_READY ;//4
        SAVE_TO_LAYER0          : next_state = (kernel_center == 4095) ? WAIT_LAYER0_READ_READY : WAIT_ROM_READ_READY ;//5
        WAIT_LAYER0_READ_READY  : next_state = (RVALID_M && RREADY_M) ? LOAD_FROM_LAYER0 : WAIT_LAYER0_READ_READY;//6
        LOAD_FROM_LAYER0        : next_state = (pool_read_cnt == 3) ? MAXPOOLING : WAIT_LAYER0_READ_READY; //7
        MAXPOOLING              : next_state = WAIT_LAYER1_WRITE_READY;//8
        WAIT_LAYER1_WRITE_READY : next_state = (WVALID_M && WREADY_M) ? SAVE_TO_LAYER1 : WAIT_LAYER1_WRITE_READY;//9
        SAVE_TO_LAYER1          : next_state = (layer1_wrt_addr == 1023) ? DONE : WAIT_LAYER0_READ_READY;//10
        DONE                    : next_state = DONE ; //11
    endcase
    end

    parameter DILATION = 2; // 空洞大小 (2 表示跳過 1 格)

    // 拆解中心點 row/col
    wire signed[7:0] base_row = {2'b00, kernel_center[11:6]};
    wire signed[7:0] base_col = {2'b00, kernel_center[5:0]};

    // 組合電路: 卷積偏移設定
    reg signed [7:0] off_row, off_col;
    always @(*) begin
    case (kernel_cnt)
        4'd0: begin off_row = -DILATION; off_col = -DILATION; end
        4'd1: begin off_row = -DILATION; off_col =  0;        end
        4'd2: begin off_row = -DILATION; off_col =  DILATION; end
        4'd3: begin off_row =   0;       off_col = -DILATION; end
        4'd4: begin off_row =   0;       off_col =  0;        end
        4'd5: begin off_row =   0;       off_col =  DILATION; end
        4'd6: begin off_row =  DILATION; off_col = -DILATION; end
        4'd7: begin off_row =  DILATION; off_col =  0;        end
        4'd8: begin off_row =  DILATION; off_col =  DILATION; end
        default: begin off_row = 0;  off_col = 0; end
    endcase
    end

    // 限幅並計算地址
    wire signed [7:0] offset_row = base_row + off_row;
    wire signed [7:0] offset_col = base_col + off_col;
    wire [5:0] target_row = offset_row < 0 ? 6'd0 : offset_row > 63 ? 6'd63  : offset_row[5:0];
    wire [5:0] target_col = offset_col < 0 ? 6'd0 : offset_col > 63 ? 6'd63  : offset_col[5:0];

    // 組合電路: 最終讀取地址 = row * 64 + col = {row, col}
    
    always @(*) begin
    iaddr_reg = {target_row, target_col};
    end

    /////////////////////////////////////////////////////////////
    //第二部分: 讀取LAYER0 -> 處理MAXPOOL + ROUNDUP -> 寫入LAYER1 
    ////////////////////////////////////////////////////////////

    // 組合電路: maxpooling 偏移設定
    parameter [1:0] STRIDE = 2'd2;
    reg off_row_pool, off_col_pool;
    always @(*) begin
    case (pool_read_cnt)
        4'd0: begin off_row_pool = 1'd0; off_col_pool = 1'd0; end
        4'd1: begin off_row_pool = 1'd0; off_col_pool = 1'd1; end
        4'd2: begin off_row_pool = 1'd1; off_col_pool = 1'd0; end
        4'd3: begin off_row_pool = 1'd1; off_col_pool = 1'd1; end
        default: begin off_row_pool = 2'd0;  off_col_pool = 2'd0; end
    endcase
    end

    always@(*)begin
    layer0_row = {layer1_wrt_addr[9:5] , off_row_pool};
    layer0_col = {layer1_wrt_addr[4:0] , off_col_pool} ;
    layer0_read_addr = {layer0_row, layer0_col}; 
    end

    // 組合電路: Layer0 寫入讀取位置、資料
    always@(*)begin
    layer0_A = 12'd0;
    layer0_D = 16'd0;

    case (state)
        
        WAIT_LAYER0_WRITE_READY: begin
            layer0_A = kernel_center;
            layer0_D = relu_result[15:0];
        end

        WAIT_LAYER0_READ_READY: begin
            layer0_A = layer0_read_addr;
        end
        default: begin
        end
    endcase
    end

    // 組合電路: Layer1 寫入位置、資料
    always@(*)begin

        if(state == WAIT_LAYER1_WRITE_READY)begin
            layer1_A = layer1_wrt_addr;
            layer1_D = maxpooling_result;
        end
    end

    //序向電路: 狀態更新
    always@(posedge bus_clk, posedge bus_rst)begin
    if (bus_rst)begin
        state <= IDLE;      
    end else begin
        state <= next_state;
    end
    end

    //序向電路: 同步計數器與中心點更新
    always @(posedge bus_clk or posedge bus_rst) begin
        if (bus_rst) begin
            kernel_cnt       <=  4'd0;
            kernel_center    <= 12'd0; 
            pool_read_cnt    <=  2'd0;
            layer1_wrt_addr  <= 12'd0;
            transmit_cnt     <= 4'd0;
        end else if (state == WAIT_ROM_READ_READY)begin
        end else if (state == LOAD_FROM_ROM) begin
            kernel[kernel_cnt/3][kernel_cnt%3] <= RDATA_M;
            kernel_cnt <= kernel_cnt + 1;
        end else if (state == PROCESS) begin
            kernel_cnt <= 4'd0;  // 下一次 PROCESS 前重置
        end else if (state == WAIT_LAYER0_WRITE_READY)begin
        end else if (state == SAVE_TO_LAYER0)begin
            kernel_center <= kernel_center + 1;
        end else if (state == WAIT_LAYER0_READ_READY)begin
        end else if (state == LOAD_FROM_LAYER0)begin
            pool_win[off_row_pool][off_col_pool] <= RDATA_M;
            pool_read_cnt <= pool_read_cnt + 1;
        end else if (state == MAXPOOLING)begin
            pool_read_cnt <= 4'd0; // 下一次 POOL 前重置
        end else if (state == WAIT_LAYER1_WRITE_READY)begin
        end else if (state == SAVE_TO_LAYER1)begin     
            layer1_wrt_addr <= layer1_wrt_addr + 1;
        end
     
    end   

    assign done = (state == DONE) ? 1 : 0;          //結束程式

endmodule
