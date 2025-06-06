module MCH (
    input               clk,
    input               reset,
    input       [ 7:0]  X,
    input       [ 7:0]  Y,
    output              Done,
    output reg  [16:0]  area
);

localparam [3:0] IDLE = 4'd0;
localparam [3:0] READ = 4'd1;
localparam [3:0] SWAP = 4'd2;
localparam [3:0] SORT = 4'd3;
localparam [3:0] SCAN = 4'd4;
localparam [3:0] AREA = 4'd5;
localparam [3:0] DONE = 4'd6;

reg [3:0] state, next_state ; 

// -------------------------------------------------------------------------
// READ 階段：累積讀入 20 個點，並一路找出「最下且最左」的 pivot
// -------------------------------------------------------------------------
reg [7:0] x_coord[0:19];
reg [7:0] y_coord[0:19];
reg [4:0] idx_min  ;
reg [4:0] read_cnt;

// -------------------------------------------------------------------------
// SORT 階段：計算相對向量、SRA 近似長度、cos，再做 odd-even bubble sort
// -------------------------------------------------------------------------
reg [4:0] sort_cycles;    
reg       sort_idx;      // 偶 phase / 奇 phase 的切換
reg signed [8:0] dx [1:19];
reg signed [8:0] dy [1:19];
reg signed [17:0] cross_product[1:9];

// -------------------------------------------------------------------------
// SCAN 階段：Graham Scan，把點推入／彈出 stack，最終留下 convex hull
// -------------------------------------------------------------------------
reg [4:0] stack_ptr;       // 指向下一個可 push 的位置 (stack_ptr=堆疊大小)
reg [4:0] cur_index;       // 目前正要處理的點索引 (1..19)

// 用於計算當前要處理點和 stack 上兩點之間的外積
reg signed [8:0] cx, cy;   // cur point
reg signed [8:0] x1, y1;  // stack_ptr-2
reg signed [8:0] x2, y2;  // stack_ptr-1
reg signed [17:0] crs;

// -------------------------------------------------------------------------
// AREA 階段：計算 convex hull 面積 (Shoelace / 三角形拆分累加)
//  - 用 comb_acc 暫存 twice_area，再除 2 得 area
// -------------------------------------------------------------------------
reg signed [19:0] comb_acc;  // 累加器

reg [2:0] area_cycles;
// -------------------------------------------------------------------------
// 狀態轉換 (combinational)
// -------------------------------------------------------------------------
always @(*)begin
    case(state)
        READ : next_state = (read_cnt == 19)? SWAP : READ;
        SWAP : next_state = SORT;
        SORT : next_state = (sort_cycles == 20)? SCAN : SORT;
        SCAN : next_state = (cur_index == 5'd20 ) ? AREA : SCAN;
        AREA : next_state = (area_cycles == 4'd1) ? DONE : AREA;
        DONE : next_state = READ;
        default : next_state = READ;
    endcase
end

// -------------------------------------------------------------------------
// 狀態更新 (sequential)
// -------------------------------------------------------------------------
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= READ;
    end else begin
        state <= next_state;
    end
end

integer i;  


function automatic signed [17:0] cross_res;
  input signed [8:0] x1, y1;
  input signed [8:0] x2, y2;
  begin
    cross_res = x1 * y2 - x2 * y1;
  end
endfunction

wire signed [8:0] sel_dx1, sel_dy1,  sel_dx2,  sel_dy2;
wire signed [8:0] sel_dx3, sel_dy3,  sel_dx4,  sel_dy4;
wire signed [8:0] sel_dx5, sel_dy5,  sel_dx6,  sel_dy6;
wire signed [8:0] sel_dx7, sel_dy7,  sel_dx8,  sel_dy8;
wire signed [8:0] sel_dx9, sel_dy9,  sel_dx10, sel_dy10;
wire signed [8:0] sel_dx11, sel_dy11, sel_dx12, sel_dy12;
wire signed [8:0] sel_dx13, sel_dy13, sel_dx14, sel_dy14;
wire signed [8:0] sel_dx15, sel_dy15, sel_dx16, sel_dy16;
wire signed [8:0] sel_dx17, sel_dy17, sel_dx18, sel_dy18;

assign sel_dx1  = (sort_idx == 1'b0) ? dx[1]  : dx[2];
assign sel_dy1  = (sort_idx == 1'b0) ? dy[1]  : dy[2];
assign sel_dx2  = (sort_idx == 1'b0) ? dx[2]  : dx[3];
assign sel_dy2  = (sort_idx == 1'b0) ? dy[2]  : dy[3];

assign sel_dx3  = (sort_idx == 1'b0) ? dx[3]  : dx[4];
assign sel_dy3  = (sort_idx == 1'b0) ? dy[3]  : dy[4];
assign sel_dx4  = (sort_idx == 1'b0) ? dx[4]  : dx[5];
assign sel_dy4  = (sort_idx == 1'b0) ? dy[4]  : dy[5];

assign sel_dx5  = (sort_idx == 1'b0) ? dx[5]  : dx[6];
assign sel_dy5  = (sort_idx == 1'b0) ? dy[5]  : dy[6];
assign sel_dx6  = (sort_idx == 1'b0) ? dx[6]  : dx[7];
assign sel_dy6  = (sort_idx == 1'b0) ? dy[6]  : dy[7];

assign sel_dx7  = (sort_idx == 1'b0) ? dx[7]  : dx[8];
assign sel_dy7  = (sort_idx == 1'b0) ? dy[7]  : dy[8];
assign sel_dx8  = (sort_idx == 1'b0) ? dx[8]  : dx[9];
assign sel_dy8  = (sort_idx == 1'b0) ? dy[8]  : dy[9];

assign sel_dx9  = (sort_idx == 1'b0) ? dx[9]  : dx[10];
assign sel_dy9  = (sort_idx == 1'b0) ? dy[9]  : dy[10];
assign sel_dx10 = (sort_idx == 1'b0) ? dx[10] : dx[11];
assign sel_dy10 = (sort_idx == 1'b0) ? dy[10] : dy[11];

assign sel_dx11 = (sort_idx == 1'b0) ? dx[11] : dx[12];
assign sel_dy11 = (sort_idx == 1'b0) ? dy[11] : dy[12];
assign sel_dx12 = (sort_idx == 1'b0) ? dx[12] : dx[13];
assign sel_dy12 = (sort_idx == 1'b0) ? dy[12] : dy[13];

assign sel_dx13 = (sort_idx == 1'b0) ? dx[13] : dx[14];
assign sel_dy13 = (sort_idx == 1'b0) ? dy[13] : dy[14];
assign sel_dx14 = (sort_idx == 1'b0) ? dx[14] : dx[15];
assign sel_dy14 = (sort_idx == 1'b0) ? dy[14] : dy[15];

assign sel_dx15 = (sort_idx == 1'b0) ? dx[15] : dx[16];
assign sel_dy15 = (sort_idx == 1'b0) ? dy[15] : dy[16];
assign sel_dx16 = (sort_idx == 1'b0) ? dx[16] : dx[17];
assign sel_dy16 = (sort_idx == 1'b0) ? dy[16] : dy[17];

assign sel_dx17 = (sort_idx == 1'b0) ? dx[17] : dx[18];
assign sel_dy17 = (sort_idx == 1'b0) ? dy[17] : dy[18];
assign sel_dx18 = (sort_idx == 1'b0) ? dx[18] : dx[19];
assign sel_dy18 = (sort_idx == 1'b0) ? dy[18] : dy[19];

// -------------------------------------------------------------------------
// 組合邏輯SORT：計算 dx[], dy[], cross_product[]
// -------------------------------------------------------------------------
always @(*) begin

    dx[1] = $signed({1'b0, x_coord[1]}) - $signed({1'b0, x_coord[0]});
    dy[1] = $signed({1'b0, y_coord[1]}) - $signed({1'b0, y_coord[0]});
    dx[2] = $signed({1'b0, x_coord[2]}) - $signed({1'b0, x_coord[0]});
    dy[2] = $signed({1'b0, y_coord[2]}) - $signed({1'b0, y_coord[0]});
    dx[3] = $signed({1'b0, x_coord[3]}) - $signed({1'b0, x_coord[0]});
    dy[3] = $signed({1'b0, y_coord[3]}) - $signed({1'b0, y_coord[0]});
    dx[4] = $signed({1'b0, x_coord[4]}) - $signed({1'b0, x_coord[0]});
    dy[4] = $signed({1'b0, y_coord[4]}) - $signed({1'b0, y_coord[0]});
    dx[5] = $signed({1'b0, x_coord[5]}) - $signed({1'b0, x_coord[0]});
    dy[5] = $signed({1'b0, y_coord[5]}) - $signed({1'b0, y_coord[0]});
    dx[6] = $signed({1'b0, x_coord[6]}) - $signed({1'b0, x_coord[0]});
    dy[6] = $signed({1'b0, y_coord[6]}) - $signed({1'b0, y_coord[0]});
    dx[7] = $signed({1'b0, x_coord[7]}) - $signed({1'b0, x_coord[0]});
    dy[7] = $signed({1'b0, y_coord[7]}) - $signed({1'b0, y_coord[0]});
    dx[8] = $signed({1'b0, x_coord[8]}) - $signed({1'b0, x_coord[0]});
    dy[8] = $signed({1'b0, y_coord[8]}) - $signed({1'b0, y_coord[0]});
    dx[9] = $signed({1'b0, x_coord[9]}) - $signed({1'b0, x_coord[0]});
    dy[9] = $signed({1'b0, y_coord[9]}) - $signed({1'b0, y_coord[0]});
    dx[10] = $signed({1'b0, x_coord[10]}) - $signed({1'b0, x_coord[0]});
    dy[10] = $signed({1'b0, y_coord[10]}) - $signed({1'b0, y_coord[0]});
    dx[11] = $signed({1'b0, x_coord[11]}) - $signed({1'b0, x_coord[0]});
    dy[11] = $signed({1'b0, y_coord[11]}) - $signed({1'b0, y_coord[0]});
    dx[12] = $signed({1'b0, x_coord[12]}) - $signed({1'b0, x_coord[0]});
    dy[12] = $signed({1'b0, y_coord[12]}) - $signed({1'b0, y_coord[0]});
    dx[13] = $signed({1'b0, x_coord[13]}) - $signed({1'b0, x_coord[0]});
    dy[13] = $signed({1'b0, y_coord[13]}) - $signed({1'b0, y_coord[0]});
    dx[14] = $signed({1'b0, x_coord[14]}) - $signed({1'b0, x_coord[0]});
    dy[14] = $signed({1'b0, y_coord[14]}) - $signed({1'b0, y_coord[0]});
    dx[15] = $signed({1'b0, x_coord[15]}) - $signed({1'b0, x_coord[0]});
    dy[15] = $signed({1'b0, y_coord[15]}) - $signed({1'b0, y_coord[0]});
    dx[16] = $signed({1'b0, x_coord[16]}) - $signed({1'b0, x_coord[0]});
    dy[16] = $signed({1'b0, y_coord[16]}) - $signed({1'b0, y_coord[0]});
    dx[17] = $signed({1'b0, x_coord[17]}) - $signed({1'b0, x_coord[0]});
    dy[17] = $signed({1'b0, y_coord[17]}) - $signed({1'b0, y_coord[0]});
    dx[18] = $signed({1'b0, x_coord[18]}) - $signed({1'b0, x_coord[0]});
    dy[18] = $signed({1'b0, y_coord[18]}) - $signed({1'b0, y_coord[0]});
    dx[19] = $signed({1'b0, x_coord[19]}) - $signed({1'b0, x_coord[0]});
    dy[19] = $signed({1'b0, y_coord[19]}) - $signed({1'b0, y_coord[0]});

    cross_product[1] = cross_res(sel_dx1,  sel_dy1,
                                 sel_dx2,  sel_dy2);
    cross_product[2] = cross_res(sel_dx3,  sel_dy3,
                                 sel_dx4,  sel_dy4);
    cross_product[3] = cross_res(sel_dx5,  sel_dy5,
                                 sel_dx6,  sel_dy6);
    cross_product[4] = cross_res(sel_dx7,  sel_dy7,
                                 sel_dx8,  sel_dy8);
    cross_product[5] = cross_res(sel_dx9,  sel_dy9,
                                 sel_dx10, sel_dy10);
    cross_product[6] = cross_res(sel_dx11, sel_dy11,
                                 sel_dx12, sel_dy12);
    cross_product[7] = cross_res(sel_dx13, sel_dy13,
                                 sel_dx14, sel_dy14);
    cross_product[8] = cross_res(sel_dx15, sel_dy15,
                                 sel_dx16, sel_dy16);
    cross_product[9] = cross_res(sel_dx17, sel_dy17,
                                 sel_dx18, sel_dy18);

    // 這時候所有 dx[]、dy[] 都是最新值，才計算 cross_product
    // cross_product[1]  = dx[1]  * dy[2]  - dx[2]  * dy[1];
    // cross_product[2]  = dx[2]  * dy[3]  - dx[3]  * dy[2];
    // cross_product[3]  = dx[3]  * dy[4]  - dx[4]  * dy[3];
    // cross_product[4]  = dx[4]  * dy[5]  - dx[5]  * dy[4];
    // cross_product[5]  = dx[5]  * dy[6]  - dx[6]  * dy[5];
    // cross_product[6]  = dx[6]  * dy[7]  - dx[7]  * dy[6];
    // cross_product[7]  = dx[7]  * dy[8]  - dx[8]  * dy[7];
    // cross_product[8]  = dx[8]  * dy[9]  - dx[9]  * dy[8];
    // cross_product[9]  = dx[9]  * dy[10] - dx[10] * dy[9];
    // cross_product[10] = dx[10] * dy[11] - dx[11] * dy[10];
    // cross_product[11] = dx[11] * dy[12] - dx[12] * dy[11];
    // cross_product[12] = dx[12] * dy[13] - dx[13] * dy[12];
    // cross_product[13] = dx[13] * dy[14] - dx[14] * dy[13];
    // cross_product[14] = dx[14] * dy[15] - dx[15] * dy[14];
    // cross_product[15] = dx[15] * dy[16] - dx[16] * dy[15];
    // cross_product[16] = dx[16] * dy[17] - dx[17] * dy[16];
    // cross_product[17] = dx[17] * dy[18] - dx[18] * dy[17];
    // cross_product[18] = dx[18] * dy[19] - dx[19] * dy[18];

end

// -------------------------------------------------------------------------
// 組合邏輯SCAN：計算 comb_acc = twice_area（Pivot 三角形拆分累加）
// -------------------------------------------------------------------------
always @(*) begin
    // 注意：cur_index 與 stack_ptr 
    cx   = cur_index < 5'd20   ? $signed({1'b0, x_coord[cur_index]})   : 9'sd0;
    cy   = cur_index < 5'd20   ? $signed({1'b0, y_coord[cur_index]})   : 9'sd0;
    x1   = (stack_ptr >= 5'd2) ? $signed({1'b0, x_coord[stack_ptr-2]}) : 9'sd0;
    y1   = (stack_ptr >= 5'd2) ? $signed({1'b0, y_coord[stack_ptr-2]}) : 9'sd0;
    x2   = (stack_ptr >= 5'd1) ? $signed({1'b0, x_coord[stack_ptr-1]}) : 9'sd0;
    y2   = (stack_ptr >= 5'd1) ? $signed({1'b0, y_coord[stack_ptr-1]}) : 9'sd0;
    crs = (x2 - x1) * (cy - y2) - (y2 - y1) * (cx - x2);
end

// -------------------------------------------------------------------------
// 組合邏輯AREA：計算 comb_acc = twice_area（Pivot 三角形拆分累加）
// -------------------------------------------------------------------------

reg [19:0] temp1, temp2, temp3 ,temp4 ,temp5 ,temp6, temp7 ,temp8 ,temp9 ,temp10;
reg [19:0] temp11, temp12, temp13 ,temp14 ,temp15 ,temp16, temp17 ,temp18 ,temp19, last_wrap;

always @(*) begin
    // 預設為 0
    comb_acc = 20'sd0; temp1 = 20'sd0; temp2 = 20'sd0;
    temp3 = 20'sd0; temp4 = 20'sd0; temp5 = 20'sd0;
    temp6 = 20'sd0; temp7 = 20'sd0; temp8 = 20'sd0;
    temp9 = 20'sd0; temp10 = 20'sd0; temp11 = 20'sd0;
    temp12 = 20'sd0; temp13 = 20'sd0; temp14 = 20'sd0;
    temp15 = 20'sd0; temp16 = 20'sd0; temp17 = 20'sd0;
    temp18 = 20'sd0; temp19 = 20'sd0; last_wrap = 20'sd0;
    // 只有在 state==AREA、且堆疊點數 > 2 時才計算
    if (state == AREA) begin

        // i = 0 -> 1
        temp1 = (stack_ptr > 1) ?
            ( $signed({1'b0, x_coord[0]}) * $signed({1'b0, y_coord[1]})
            - $signed({1'b0, y_coord[0]}) * $signed({1'b0, x_coord[1]}) )
            : 20'sd0;

        // i = 1 -> 2
        temp2 = (stack_ptr > 2) ?
            ( $signed({1'b0, x_coord[1]}) * $signed({1'b0, y_coord[2]})
            - $signed({1'b0, y_coord[1]}) * $signed({1'b0, x_coord[2]}) )
            : 20'sd0;

        // i = 2 -> 3
        temp3 = (stack_ptr > 3) ?
            ( $signed({1'b0, x_coord[2]}) * $signed({1'b0, y_coord[3]})
            - $signed({1'b0, y_coord[2]}) * $signed({1'b0, x_coord[3]}) )
            : 20'sd0;

        // i = 3 -> 4
        temp4 = (stack_ptr > 4) ?
            ( $signed({1'b0, x_coord[3]}) * $signed({1'b0, y_coord[4]})
            - $signed({1'b0, y_coord[3]}) * $signed({1'b0, x_coord[4]}) )
            : 20'sd0;

        // i = 4 -> 5
        temp5 = (stack_ptr > 5) ?
            ( $signed({1'b0, x_coord[4]}) * $signed({1'b0, y_coord[5]})
            - $signed({1'b0, y_coord[4]}) * $signed({1'b0, x_coord[5]}) )
            : 20'sd0;

        // i = 5 -> 6
        temp6 = (stack_ptr > 6) ?
            ( $signed({1'b0, x_coord[5]}) * $signed({1'b0, y_coord[6]})
            - $signed({1'b0, y_coord[5]}) * $signed({1'b0, x_coord[6]}) )
            : 20'sd0;

        // i = 6 -> 7
        temp7 = (stack_ptr > 7) ?
            ( $signed({1'b0, x_coord[6]}) * $signed({1'b0, y_coord[7]})
            - $signed({1'b0, y_coord[6]}) * $signed({1'b0, x_coord[7]}) )
            : 20'sd0;

        // i = 7 -> 8
        temp8 = (stack_ptr > 8) ?
            ( $signed({1'b0, x_coord[7]}) * $signed({1'b0, y_coord[8]})
            - $signed({1'b0, y_coord[7]}) * $signed({1'b0, x_coord[8]}))
            : 20'sd0;

        // i = 8 -> 9
        temp9 = (stack_ptr > 9) ?
            ( $signed({1'b0, x_coord[8]}) * $signed({1'b0, y_coord[9]})
            - $signed({1'b0, y_coord[8]}) * $signed({1'b0, x_coord[9]}) )
            : 20'sd0;

        // i = 9 -> 10
        temp10 = (stack_ptr > 10) ?
            ( $signed({1'b0, x_coord[9]})  * $signed({1'b0, y_coord[10]})
            - $signed({1'b0, y_coord[9]})  * $signed({1'b0, x_coord[10]}) )
            : 20'sd0;

        // i = 10 -> 11
        temp11 = (stack_ptr > 11) ?
            ( $signed({1'b0, x_coord[10]}) * $signed({1'b0, y_coord[11]})
            - $signed({1'b0, y_coord[10]}) * $signed({1'b0, x_coord[11]}) )
            : 20'sd0;

        // i = 11 -> 12
        temp12 = (stack_ptr > 12) ?
            ( $signed({1'b0, x_coord[11]}) * $signed({1'b0, y_coord[12]})
            - $signed({1'b0, y_coord[11]}) * $signed({1'b0, x_coord[12]}) )
            : 20'sd0;

        // i = 12 -> 13
        temp13 = (stack_ptr > 13) ?
            ( $signed({1'b0, x_coord[12]}) * $signed({1'b0, y_coord[13]})
            - $signed({1'b0, y_coord[12]}) * $signed({1'b0, x_coord[13]}) )
            : 20'sd0;

        // i = 13 -> 14
        temp14 = (stack_ptr > 14) ?
            ( $signed({1'b0, x_coord[13]}) * $signed({1'b0, y_coord[14]})
            - $signed({1'b0, y_coord[13]}) * $signed({1'b0, x_coord[14]}) )
            : 20'sd0;

        // i = 14 -> 15
        temp15 = (stack_ptr > 15) ?
            ( $signed({1'b0, x_coord[14]}) * $signed({1'b0, y_coord[15]})
            - $signed({1'b0, y_coord[14]}) * $signed({1'b0, x_coord[15]}) )
            : 20'sd0;

        // i = 15 -> 16
        temp16 = (stack_ptr > 16) ?
            ( $signed({1'b0, x_coord[15]}) * $signed({1'b0, y_coord[16]})
            - $signed({1'b0, y_coord[15]}) * $signed({1'b0, x_coord[16]}) )
            : 20'sd0;

        // i = 16 -> 17
        temp17 = (stack_ptr > 17) ?
            ( $signed({1'b0, x_coord[16]}) * $signed({1'b0, y_coord[17]})
            - $signed({1'b0, y_coord[16]}) * $signed({1'b0, x_coord[17]}) )
            : 20'sd0;

        // i = 17 -> 18
        temp18 = (stack_ptr > 18) ?
            ( $signed({1'b0, x_coord[17]}) * $signed({1'b0, y_coord[18]})
            - $signed({1'b0, y_coord[17]}) * $signed({1'b0, x_coord[18]}) )
            : 20'sd0;

        // i = 18 -> 19
        temp19 = (stack_ptr > 19) ?
            ( $signed({1'b0, x_coord[18]}) * $signed({1'b0, y_coord[19]})
            - $signed({1'b0, y_coord[18]}) * $signed({1'b0, x_coord[19]}) )
            : 20'sd0;

        // 最後一段：把最後一個頂點 (index = stack_ptr-1) wrap 回第 0 頂點
        last_wrap = (stack_ptr >= 2) ?
            ( $signed({1'b0, x_coord[stack_ptr-1]}) * $signed({1'b0, y_coord[0]})
              - $signed({1'b0, y_coord[stack_ptr-1]}) * $signed({1'b0, x_coord[0]}))
            : 20'sd0;

        // 把所有 temp1…temp20 加總，即得到 twice_area（comb_acc）
        comb_acc = temp1  + temp2  + temp3  + temp4  + temp5  +
                   temp6  + temp7  + temp8  + temp9  + temp10 +
                   temp11 + temp12 + temp13 + temp14 + temp15 +
                   temp16 + temp17 + temp18 + + temp19 + last_wrap;
    end else begin
        comb_acc = 18'sd0;
    end
end

function comp;

    input signed [17:0]cross_product;
    input signed [8:0]dx1;
    input signed [8:0]dy1;
    input signed [8:0]dx2;
    input signed [8:0]dy2;

    if (cross_product[17] == 1'd1
        || (cross_product == 18'sd0 && dx1 > dx2)
        || (cross_product == 18'sd0 && dx1 == dx2 && dy1 > dy2)
    )begin
        comp = 1'd1;
    end else begin
        comp = 1'd0;
    end
endfunction



always @(posedge clk or posedge reset)begin
    if (reset) begin
        read_cnt    <= 5'd0;
        sort_cycles <= 5'd0;
        sort_idx    <= 1'b0;

        idx_min     <= 5'd0;

        stack_ptr   <= 5'd0;
        cur_index   <= 5'd0;

        area_cycles <= 3'd0;
        
        for (i = 0; i < 20; i = i + 1) begin
            x_coord[i] <= 8'd0;
            y_coord[i] <= 8'd0;
        end

    end else if (state == READ)begin
        // -------------------------------------------------------------------------
        // READ 階段 (時序區塊)
        //  - 累積讀入 20 個點到 x_coord[], y_coord[]
        //  - 同時計算 pivot(最低 y、最左 x)
        // -------------------------------------------------------------------------
        
        x_coord[read_cnt]  <= X;
        y_coord[read_cnt]  <= Y;

        if (Y < y_coord[idx_min] || (Y == y_coord[idx_min] && X < x_coord[idx_min]))begin
            idx_min <= read_cnt; 
        end

        read_cnt <= read_cnt + 5'd1 ; 
    end else if (state == SWAP)begin
        // ---------------------------------------------------------------------
        // SWAP 階段 (時序區塊)
        //  - 把 pivot (idx_min) 和 index 0 交換
        // ---------------------------------------------------------------------

        x_coord[0]       <= x_coord[idx_min];
        y_coord[0]       <= y_coord[idx_min];
        x_coord[idx_min] <= x_coord[0];
        y_coord[idx_min] <= y_coord[0];
    end else if (state == SORT) begin
        
        // ---------------------------------------------------------------------
        // SORT 階段：進行 odd-even bubble sort (時序區塊)
        //  - sort_idx = 0 時做偶 phase (i=1,3,5…)，sort_idx=1 做奇 phase (i=2,4,6…)
        // ---------------------------------------------------------------------

        if (sort_idx == 1'b0) begin
            // i = 1 vs i+1 = 2
            if (comp(cross_product[1], dx[1], dy[1], dx[2], dy[2])) begin
                x_coord[1] <= x_coord[2];
                x_coord[2] <= x_coord[1];
                y_coord[1] <= y_coord[2];
                y_coord[2] <= y_coord[1];
            end
            
            // i = 3 vs i+1 = 4
            if (comp(cross_product[2], dx[3], dy[3], dx[4], dy[4])) begin
                x_coord[3] <= x_coord[4];
                x_coord[4] <= x_coord[3];
                y_coord[3] <= y_coord[4];
                y_coord[4] <= y_coord[3];
            end
            
            // i = 5 vs i+1 = 6
            if (comp(cross_product[3], dx[5], dy[5], dx[6], dy[6])) begin
                x_coord[5] <= x_coord[6];
                x_coord[6] <= x_coord[5];
                y_coord[5] <= y_coord[6];
                y_coord[6] <= y_coord[5];
            end
            
            // i = 7 vs i+1 = 8
            if (comp(cross_product[4], dx[7], dy[7], dx[8], dy[8])) begin
                x_coord[7] <= x_coord[8];
                x_coord[8] <= x_coord[7];
                y_coord[7] <= y_coord[8];
                y_coord[8] <= y_coord[7];
            end
            
            // i = 9 vs i+1 = 10
            if (comp(cross_product[5], dx[9], dy[9], dx[10], dy[10])) begin
                x_coord[9]  <= x_coord[10];
                x_coord[10] <= x_coord[9];
                y_coord[9]  <= y_coord[10];
                y_coord[10] <= y_coord[9];
            end
            
            // i = 11 vs i+1 = 12
            if (comp(cross_product[6], dx[11], dy[11], dx[12], dy[12])) begin
                x_coord[11] <= x_coord[12];
                x_coord[12] <= x_coord[11];
                y_coord[11] <= y_coord[12];
                y_coord[12] <= y_coord[11];
            end
            
            // i = 13 vs i+1 = 14
            if (comp(cross_product[7], dx[13], dy[13], dx[14], dy[14])) begin
                x_coord[13] <= x_coord[14];
                x_coord[14] <= x_coord[13];
                y_coord[13] <= y_coord[14];
                y_coord[14] <= y_coord[13];
            end
            
            // i = 15 vs i+1 = 16
            if (comp(cross_product[8], dx[15], dy[15], dx[16], dy[16])) begin
                x_coord[15] <= x_coord[16];
                x_coord[16] <= x_coord[15];
                y_coord[15] <= y_coord[16];
                y_coord[16] <= y_coord[15];
            end
            
            // i = 17 vs i+1 = 18
            if (comp(cross_product[9], dx[17], dy[17], dx[18], dy[18])) begin
                x_coord[17] <= x_coord[18];
                x_coord[18] <= x_coord[17];
                y_coord[17] <= y_coord[18];
                y_coord[18] <= y_coord[17];
            end
        end else begin
            // 奇 phase：比較 i=2,4,6,...,18
            // i = 2 vs i+1 = 3
            if (comp(cross_product[1], dx[2], dy[2], dx[3], dy[3])) begin
                x_coord[2] <= x_coord[3];
                x_coord[3] <= x_coord[2];
                y_coord[2] <= y_coord[3];
                y_coord[3] <= y_coord[2];
            end
            
            // i = 4 vs i+1 = 5
            if (comp(cross_product[2], dx[4], dy[4], dx[5], dy[5])) begin
                x_coord[4] <= x_coord[5];
                x_coord[5] <= x_coord[4];
                y_coord[4] <= y_coord[5];
                y_coord[5] <= y_coord[4];
            end
            
            // i = 6 vs i+1 = 7
            if (comp(cross_product[3], dx[6], dy[6], dx[7], dy[7])) begin
                x_coord[6] <= x_coord[7];
                x_coord[7] <= x_coord[6];
                y_coord[6] <= y_coord[7];
                y_coord[7] <= y_coord[6];
            end
            
            // i = 8 vs i+1 = 9
            if (comp(cross_product[4], dx[8], dy[8], dx[9], dy[9])) begin
                x_coord[8] <= x_coord[9];
                x_coord[9] <= x_coord[8];
                y_coord[8] <= y_coord[9];
                y_coord[9] <= y_coord[8];
            end
            
            // i = 10 vs i+1 = 11
            if (comp(cross_product[5], dx[10], dy[10], dx[11], dy[11])) begin
                x_coord[10] <= x_coord[11];
                x_coord[11] <= x_coord[10];
                y_coord[10] <= y_coord[11];
                y_coord[11] <= y_coord[10];
            end
            
            // i = 12 vs i+1 = 13
            if (comp(cross_product[6], dx[12], dy[12], dx[13], dy[13])) begin
                x_coord[12] <= x_coord[13];
                x_coord[13] <= x_coord[12];
                y_coord[12] <= y_coord[13];
                y_coord[13] <= y_coord[12];
            end
            
            // i = 14 vs i+1 = 15
            if (comp(cross_product[7], dx[14], dy[14], dx[15], dy[15])) begin
                x_coord[14] <= x_coord[15];
                x_coord[15] <= x_coord[14];
                y_coord[14] <= y_coord[15];
                y_coord[15] <= y_coord[14];
            end
            
            // i = 16 vs i+1 = 17
            if (comp(cross_product[8], dx[16], dy[16], dx[17], dy[17])) begin
                x_coord[16] <= x_coord[17];
                x_coord[17] <= x_coord[16];
                y_coord[16] <= y_coord[17];
                y_coord[17] <= y_coord[16];
            end
            
            // i = 18 vs i+1 = 19
            if (comp(cross_product[9], dx[18], dy[18], dx[19], dy[19])) begin
                x_coord[18] <= x_coord[19];
                x_coord[19] <= x_coord[18];
                y_coord[18] <= y_coord[19];
                y_coord[19] <= y_coord[18];
            end
        end

        sort_idx <= ~sort_idx;
        sort_cycles <= sort_cycles + 1'b1;
        
    end else if (state == SCAN) begin
        // ---------------------------------------------------------------------
        // SCAN 階段 (時序區塊)
        //  - Graham Scan: 根據向量外積決定推入/彈出 stack
        // ---------------------------------------------------------------------

        if (cur_index == 5'd0) begin
            // 第一次進到 SCAN：先把設定起始點

            stack_ptr   <= 5'd2;
            cur_index   <= 5'd2; 
        end else if (cur_index <= 5'd19) begin
         
            if (crs > 18'sd0) begin
                // 向左轉：push
                x_coord[stack_ptr] <= x_coord[cur_index];
                y_coord[stack_ptr] <= y_coord[cur_index];
                stack_ptr          <= stack_ptr + 5'd1;
                // 下一個要處理的 cur_index + 1
                cur_index          <= cur_index + 5'd1;
            end else begin
                // 否則 (crs ≤ 0)：彈出 stack_ptr-1，再重新判斷
                if (stack_ptr > 5'd1) begin
                    // pop 頂部
                    stack_ptr <= stack_ptr - 5'd1;
                    // cur_index 不動，下一個時鐘再對新的 top 兩個點重算
                end else begin
                    // 若 stack_ptr == 1 (只有1個點)，直接 push
                    x_coord[stack_ptr] <= x_coord[cur_index];
                    y_coord[stack_ptr] <= y_coord[cur_index];
                    stack_ptr          <= stack_ptr + 5'd1;
                    cur_index          <= cur_index + 5'd1;
                end
            end
        end
    end else if (state == AREA) begin
        // ---------------------------------------------------------------------
        // AREA 階段 (時序區塊)
        //  - area = comb_acc / 2（此處假設 comb_acc 已經是 twice_area）
        // ---------------------------------------------------------------------
        area        <= comb_acc;
        area_cycles <= area_cycles + 3'd1;

    end else if (state == DONE)begin
        // ---------------------------------------------------------------------
        // DONE 階段 (時序區塊)
        //  - 清除各種pointer、stack、idx_min，等待下一輪
        // ---------------------------------------------------------------------
        read_cnt    <= 5'd0;
        idx_min     <= 5'd0;
        stack_ptr   <= 5'd0;
        cur_index   <= 5'd0;
        sort_cycles <= 5'd0;
        sort_idx    <= 1'd0;
        for (i = 0; i < 20; i = i + 1) begin
            x_coord[i] <= 8'd0;
            x_coord[i] <= 8'd0;
        end
    end 

end 

assign Done = (state == DONE) ? 1'd1 : 1'd0;



endmodule


