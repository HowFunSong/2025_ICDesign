`timescale 1ns/10ps
`include "./include/define.v"

module SRAM_Wrapper(
	input 	   						bus_clk ,//bus
	input 	   						bus_rst ,
	input      [`BUS_ADDR_BITS-1:0] ADDR_S  ,
	input      [`BUS_DATA_BITS-1:0] WDATA_S ,
	input      [`BUS_LEN_BITS -1:0] BLEN_S  ,
	input      						WLAST_S ,
	input      						WVALID_S,
	input      						RVALID_S,
	output  reg[`BUS_DATA_BITS-1:0] RDATA_S ,
	output  reg						RLAST_S ,
	output  reg						WREADY_S,
	output  reg						RREADY_S,
	output 	reg[`BUS_DATA_BITS-1:0] SRAM_D  ,//sram
	output 	reg[`BUS_ADDR_BITS-1:0] SRAM_A  ,
	input	   [`BUS_DATA_BITS-1:0] SRAM_Q  ,
	output	    					SRAM_ceb,
	output	 	     				SRAM_web		
);  
    ////////////////////////////////////
    // 雙端口 Wrappper，對RAM支援讀寫操作
	////////////////////////////////////

    // 狀態編碼
    localparam [1:0] IDLE = 2'd0, READ = 2'd1, WRITE = 2'd2;
    reg [1:0] state, next_state;
    reg [`BUS_LEN_BITS-1:0] beat_cnt;  // 已讀拍數(讀)

    // 狀態轉移（組合邏輯）
    always @(*) begin
        case (state)
            IDLE: next_state = RVALID_S ? READ : WVALID_S? WRITE: IDLE;
            READ: next_state = (beat_cnt == BLEN_S - 1) ? IDLE : READ;
            WRITE: next_state = WLAST_S ? IDLE : WRITE; // WLAST = 1 代表已經此次的寫入結束
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
            beat_cnt  <= {`BUS_LEN_BITS{1'b0}};
            WREADY_S  <= 1'b0;
            RREADY_S  <= 1'b0;
            SRAM_A    <= {`BUS_ADDR_BITS{1'b0}};
            SRAM_D    <= {`BUS_DATA_BITS{1'b0}};
            RDATA_S   <= {`BUS_DATA_BITS{1'b0}};
            RLAST_S   <= 1'b0;
        end else begin
            
            case (state)
                //////////////////////////////////////
                // IDLE：等待 Bus 發起讀寫請求
                //////////////////////////////////////
                IDLE: begin
                    RLAST_S <= 1'b0;        // 清除上次 LAST
                    beat_cnt  <= 0; 
                    if (RVALID_S) begin
                        // 握手開始
                        RREADY_S <= 1'b1;     // 告訴 Bus 目前可讀RAM
                        SRAM_A    <= ADDR_S;  // 對RAM 設定第一次讀的地址
                    end else if (WVALID_S) begin
                        WREADY_S  <= 1'b1;    // 告訴 Bus 目前可寫RAM
                        SRAM_A    <= ADDR_S;  // 對RAM 設定第一次寫的地址
                        SRAM_D    <= WDATA_S;
                    end else begin
                        RREADY_S <= 1'b0;
                    end
                end

                READ: begin
                    RDATA_S <= SRAM_Q;
                    RREADY_S <= 1'b0;
                    if (beat_cnt == BLEN_S - 1) begin        
                        RLAST_S   <= 1'b1;//讀取結束
                    end else begin
                        beat_cnt  <= beat_cnt + 1;
                        SRAM_A    <= SRAM_A + 1;
                    end
                end
                WRITE : begin
                    SRAM_D <= WDATA_S ;
                    WREADY_S <= 1'b0;
                    if (beat_cnt == BLEN_S - 1) begin
                    end else begin
                        beat_cnt  <= beat_cnt + 1;  
                        SRAM_A    <= SRAM_A + 1;          
                    end
                end
            endcase
        end
    end

    assign SRAM_ceb = (state == READ) || (state == WRITE);
    assign SRAM_web = ~(state == WRITE);

endmodule
