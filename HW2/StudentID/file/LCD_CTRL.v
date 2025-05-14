module LCD_CTRL(
    input           clk,
    input           rst,
    input  [3:0]    cmd, 
    input           cmd_valid, 
    input  [7:0]    IROM_Q,    // Receive image data from IROM
    output reg      IROM_rd,   // IROM read enable
    output reg [5:0] IROM_A,    // IROM address
    output reg      IRAM_ceb,  // IRAM enable (active high)
    output reg      IRAM_web,  // IRAM read/write selection (0: write, 1: read)
    output reg [7:0] IRAM_D,    // Data to be written to IRAM
    output reg [5:0] IRAM_A,    // IRAM address
    input  [7:0]    IRAM_Q,    // Data read from IRAM
    output          busy,
    output          done
);

/////////////////////////////////
// State Definitions
/////////////////////////////////
parameter IDLE        = 0;
parameter READY       = 1; 
parameter FETCH       = 2;
parameter OFFSET_ORGN = 3;
parameter PROCESS     = 4;
parameter UPDATE      = 5; 
parameter SAVE_TORAM  = 6;
parameter DONE        = 7;

reg [3:0] current_state, next_state; // 4-bit state registers

//-----------------------------------------
// Internal cache: 使用未打包的 64 個 8 位元記憶單元
//-----------------------------------------
reg [7:0] CACHE [0:63];

//-----------------------------------------
// Internal registers and counters
//-----------------------------------------
reg [6:0] rom_addr_cnt;      // IROM read address during FETCH state (0~63)
reg [6:0] cache_write_addr;
reg [6:0] ram_sw_counter;    // IRAM write address during SAVE_TORAM state (0~63)
reg [6:0] cache_read_addr;

//-----------------------------------------
// Operation point (default (4,4))
// 假設 x, y 範圍為 0 到 7，有效操作區域約在 2 到 6
//-----------------------------------------
reg [3:0] op_x, op_y;

//-----------------------------------------
// Temporary computation result (from PROCESS state calculations)
//-----------------------------------------
reg [7:0] kernel_result;

// done 與 busy 訊號
assign done = (current_state == DONE);
assign busy = (current_state != OFFSET_ORGN);

//---------------------------------------------------------------------
// State Machine: Combinational Logic (Determining Next State)
//---------------------------------------------------------------------
always @(*) begin
    case(current_state)
        IDLE : next_state = READY;
        READY: next_state = FETCH;
        FETCH: begin
            if (rom_addr_cnt == 7'd65)
                next_state = OFFSET_ORGN;
            else
                next_state = FETCH;
        end
        OFFSET_ORGN: begin
            if (cmd_valid) begin
                case(cmd)
                    4'd0: next_state = SAVE_TORAM;  // SAVE command
                    4'd1: next_state = OFFSET_ORGN; // SHIFT commands remain in this state
                    4'd2: next_state = OFFSET_ORGN;
                    4'd3: next_state = OFFSET_ORGN;
                    4'd4: next_state = OFFSET_ORGN;
                    4'd5: next_state = PROCESS;     // Max
                    4'd6: next_state = PROCESS;     // Min
                    4'd7: next_state = PROCESS;     // Average
                    default: next_state = OFFSET_ORGN;
                endcase
            end else begin
                next_state = OFFSET_ORGN;
            end
        end
        PROCESS: next_state = UPDATE;
        UPDATE: next_state = OFFSET_ORGN;
        SAVE_TORAM: begin
            if (ram_sw_counter == 7'd65)
                next_state = DONE;
            else
                next_state = SAVE_TORAM;
        end
        DONE: next_state = DONE;
        default: next_state = READY;
    endcase
end

//---------------------------------------------------------------------
// State Machine: Sequential Logic (Positive Edge Triggered)
//---------------------------------------------------------------------
integer idx;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= IDLE;
    end 
    else begin
        current_state <= next_state;
    end
end

reg [7:0] temp;
reg [15:0] sum;
integer i, j, idx_local;


always @(posedge clk or posedge rst) begin
    if (rst) begin
        rom_addr_cnt     <= 7'd0;
        cache_write_addr <= 7'd0;
        cache_read_addr  <= 7'd0;
        op_x             <= 4'd4;
        op_y             <= 4'd4;
        kernel_result    <= 8'd0;
        ram_sw_counter   <= 7'd0;
        for (idx = 0; idx < 64; idx = idx + 1) begin
            CACHE[idx] <= 8'd0;
        end
        IROM_rd   <= 1'b0;
        IROM_A    <= 6'd0;
        IRAM_ceb  <= 1'b0;
        IRAM_web  <= 1'b1;  // 預設讀取模式
        IRAM_D    <= 8'd0;
        IRAM_A    <= 6'd0;
    end else begin
        
        case(current_state)
            IDLE : ;
            READY: begin
                IROM_rd <= 1'b1;
            end

            FETCH: begin
                IROM_A  <= rom_addr_cnt;
                cache_write_addr <= rom_addr_cnt;
            end

            OFFSET_ORGN: begin
                IROM_rd <= 1'b0; // 結束 FETCH
                // 處理偏移命令（Shift 操作）
                case(cmd)
                    4'd1: if (op_y > 4'd2) op_y <= op_y - 1; // Shift Up
                    4'd2: if (op_y < 4'd6) op_y <= op_y + 1; // Shift Down
                    4'd3: if (op_x > 4'd2) op_x <= op_x - 1; // Shift Left
                    4'd4: if (op_x < 4'd6) op_x <= op_x + 1; // Shift Right
                    default: ;
                endcase
            end

            PROCESS: begin
                // 這裡的 kernel 區域為 4x4，索引從 (op_x-2, op_y-2) 到 (op_x+1, op_y+1)

                case(cmd)
                    4'd5: begin // 計算最大值
                        temp = CACHE[(op_y - 2)*8 + (op_x - 2)];
                        for (j = -2; j < 2; j = j + 1) begin
                            for (i = -2; i < 2; i = i + 1) begin
                                idx_local = (op_y + j)*8 + (op_x + i);
                                if (CACHE[idx_local] > temp)
                                    temp = CACHE[idx_local];
                            end
                        end
                        kernel_result <= temp;
                    end
                    4'd6: begin // 計算最小值
                        temp = CACHE[(op_y - 2)*8 + (op_x - 2)];
                        for (j = -2; j < 2; j = j + 1) begin
                            for (i = -2; i < 2; i = i + 1) begin
                                idx_local = (op_y + j)*8 + (op_x + i);
                                if (CACHE[idx_local] < temp)
                                    temp = CACHE[idx_local];
                            end
                        end
                        kernel_result <= temp;
                    end
                    4'd7: begin // 計算平均值
                        sum = 0;
                        for (j = -2; j < 2; j = j + 1) begin
                            for (i = -2; i < 2; i = i + 1) begin
                                idx_local = (op_y + j)*8 + (op_x + i);
                                sum = sum + CACHE[idx_local];
                            end
                        end
                        kernel_result <= sum / 16;
                    end
                    default: kernel_result <= 8'd0;
                endcase
            end

            UPDATE: begin
                // 將 kernel_result 更新到 kernel 區域 (4x4 區域)
                for (j = -2; j < 2; j = j + 1) begin
                    for (i = -2; i < 2; i = i + 1) begin
                        CACHE[(op_y + j)*8 + (op_x + i)] <= kernel_result;
                    end
                end
            end

            SAVE_TORAM: begin
                IRAM_ceb <= 1'b1;
                IRAM_web <= 1'b0; // 進入寫入模式
                if (ram_sw_counter-1 < 64) begin
                    IRAM_A   <= ram_sw_counter-1;
                    IRAM_D   <= CACHE[ram_sw_counter-1];
                end
            end

            DONE: begin
                IRAM_ceb <= 1'b0;
                IRAM_web <= 1'b1; // 恢復讀取模式
            end

            default: ;
        endcase
    end
end

//---------------------------------------------------------------------
// Negative Edge Triggered: Read data from IROM into CACHE
//---------------------------------------------------------------------
always @(negedge clk) begin
    if (current_state == FETCH && IROM_rd && (cache_write_addr > 0)) begin
        CACHE[cache_write_addr-1] <= IROM_Q;
        //$display("[load] index :%d, val : %d", (cache_write_addr-1), IROM_Q);
    end

    if (current_state == FETCH && IROM_rd)
        rom_addr_cnt <= rom_addr_cnt + 1;
end

//---------------------------------------------------------------------
// Negative Edge Triggered: Write data from CACHE to IRAM
//---------------------------------------------------------------------
always @(negedge clk) begin
    if (current_state == SAVE_TORAM) begin
        ram_sw_counter <= ram_sw_counter + 1;
    end
end

endmodule
