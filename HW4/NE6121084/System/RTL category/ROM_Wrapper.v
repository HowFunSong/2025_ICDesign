`timescale 1ns/10ps
`include "./include/define.v"

module ROM_Wrapper(
	input     						bus_clk ,//bus
	input     						bus_rst ,
	input      [`BUS_ADDR_BITS-1:0] ADDR_S  ,
	input      [`BUS_LEN_BITS -1:0] BLEN_S  ,
	input     						RVALID_S,
	output reg [`BUS_DATA_BITS-1:0] RDATA_S ,
	output reg 						RLAST_S ,
	output reg						RREADY_S,
	output reg						ROM_rd  ,//rom
	output reg [`BUS_ADDR_BITS-1:0] ROM_A  	,
	input 	   [`BUS_DATA_BITS-1:0] ROM_Q 
);
    //////////////////////////////////
    // 雙端口 Wrappper，對ROM支援讀操作
    //////////////////////////////////

    // 狀態編碼
    localparam IDLE = 2'd0, READ = 2'd1;
    reg [1:0] state, next_state;
    reg [`BUS_LEN_BITS-1:0] beat_cnt;  // 已讀拍數(讀)

    // 狀態轉移（組合邏輯）
    always @(*) begin
        case (state)
            IDLE: next_state = RVALID_S ? READ : IDLE;
            READ: next_state = (beat_cnt == BLEN_S - 1) ? IDLE : READ;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge bus_clk or posedge bus_rst) begin
        if (bus_rst)begin 
            state <= IDLE ;
        end else begin
            state <= next_state;
        end
    end

    // 時序電路：狀態、拍數、輸出訊號
    always @(posedge bus_clk or posedge bus_rst) begin
        if (bus_rst) begin
            // 重置所有訊號
            beat_cnt <= {`BUS_LEN_BITS{1'b0}};
            RREADY_S <= 1'b0;
            ROM_rd   <= 1'b0;
            ROM_A    <= {`BUS_ADDR_BITS{1'b0}};
            RDATA_S  <= {`BUS_DATA_BITS{1'b0}};
            RLAST_S  <= 1'b0;
        end else begin
            case (state)
                //////////////////////////////////////
                // IDLE：等待 Bus 發起讀請求
                //////////////////////////////////////
                IDLE: begin
                    RLAST_S <= 1'b0;         // 清除上次 LAST
                    beat_cnt <= 0;           // 計數清零
                    RREADY_S <= 1'b0;
                    ROM_rd   <= 1'b0;
                    if (RVALID_S) begin
                        // 握手開始
                        RREADY_S <= 1'b1;    // 告訴 Bus 可以讀ROM
                        ROM_rd   <= 1'b1;    // 啟動 ROM 讀
                        ROM_A    <= ADDR_S;  // 對ROM 設定第一次讀的地址
                    end 
                end

                READ: begin
                    RDATA_S <= ROM_Q;
                    RREADY_S <= 1'b0;
                    if (beat_cnt == BLEN_S - 1) begin
                        RLAST_S  <= 1'b1;
                        ROM_rd   <= 1'b0;
                    end else begin
                        beat_cnt <= beat_cnt + 1;
                        ROM_A    <= ROM_A + 1;  // 地址 +1
                        ROM_rd   <= 1'b1;       
                        
                    end
                end
            endcase
        end
    end

endmodule