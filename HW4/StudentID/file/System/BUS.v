`timescale 1ns/10ps
`include "./include/define.v"

module BUS(
    input                           bus_clk  ,
    input                           bus_rst  ,

    // MASTER 介面
    input   [`BUS_ID_BITS  -1:0]    ID_M0    ,
    input   [`BUS_ADDR_BITS-1:0]    ADDR_M0  ,
    input   [`BUS_DATA_BITS-1:0]    WDATA_M0 ,
    input   [`BUS_LEN_BITS -1:0]    BLEN_M0  ,
    input                           WLAST_M0 ,
    input                           WVALID_M0,
    input                           RVALID_M0,
    output reg [`BUS_DATA_BITS-1:0] RDATA_M0 ,
    output reg                      RLAST_M0 ,
    output                          WREADY_M0,
    output                          RREADY_M0,

    // SLAVE 0 (ROM) 介面
    output  [`BUS_ADDR_BITS-1:0]    ADDR_S0  ,
    output  [`BUS_LEN_BITS -1:0]    BLEN_S0  ,
    output                          RVALID_S0,
    input   [`BUS_DATA_BITS-1:0]    RDATA_S0 ,
    input                           RLAST_S0 ,
    input                           RREADY_S0,

    // SLAVE 1 (SRAM0) 介面
    output  [`BUS_ADDR_BITS-1:0]    ADDR_S1  ,
    output reg [`BUS_DATA_BITS-1:0] WDATA_S1 ,
    output  [`BUS_LEN_BITS -1:0]    BLEN_S1  ,
    output reg                      WLAST_S1 ,
    output                          WVALID_S1,
    output                          RVALID_S1,
    input   [`BUS_DATA_BITS-1:0]    RDATA_S1 ,
    input                           RLAST_S1 ,
    input                           WREADY_S1,
    input                           RREADY_S1,

    // SLAVE 2 (SRAM1) 介面
    output  [`BUS_ADDR_BITS-1:0]    ADDR_S2  ,
    output reg [`BUS_DATA_BITS-1:0] WDATA_S2 ,
    output  [`BUS_LEN_BITS -1:0]    BLEN_S2  ,
    output reg                      WLAST_S2 ,
    output                          WVALID_S2,
    output                          RVALID_S2,
    input   [`BUS_DATA_BITS-1:0]    RDATA_S2 ,
    input                           RLAST_S2 ,
    input                           WREADY_S2,
    input                           RREADY_S2
);

    //--------------------------------------------------------------------------
    // 1) Address & Length 永遠由 master 直接驅動到所有 slave
    //--------------------------------------------------------------------------
    assign ADDR_S0 = ADDR_M0;
    assign ADDR_S1 = ADDR_M0;
    assign ADDR_S2 = ADDR_M0;

    assign BLEN_S0 = BLEN_M0;
    assign BLEN_S1 = BLEN_M0;
    assign BLEN_S2 = BLEN_M0;

    //--------------------------------------------------------------------------
    // 2) VALID ：只有當 master RVALID/M WVALID 拉起，且 ID 對應的那支 slave 
    //    才把 VALID 送到該 slave，其它 slave 都拉低
    //--------------------------------------------------------------------------
    assign RVALID_S0 = RVALID_M0 && (ID_M0 == 2'd0);
    assign RVALID_S1 = RVALID_M0 && (ID_M0 == 2'd1);
    assign RVALID_S2 = RVALID_M0 && (ID_M0 == 2'd2);

    assign WVALID_S1 = WVALID_M0 && (ID_M0 == 2'd1);
    assign WVALID_S2 = WVALID_M0 && (ID_M0 == 2'd2);

    //--------------------------------------------------------------------------
    // 3) READY 回覆：只要對應的 slave READY，就直接回傳給 master
    //--------------------------------------------------------------------------
    assign RREADY_M0 =
          (ID_M0 == 2'd0 && RREADY_S0)
        || (ID_M0 == 2'd1 && RREADY_S1)
        || (ID_M0 == 2'd2 && RREADY_S2);

    assign WREADY_M0 =
          (ID_M0 == 2'd1 && WREADY_S1)
        || (ID_M0 == 2'd2 && WREADY_S2);

    //--------------------------------------------------------------------------
    // 4) Data/Last Blocking Channel
    //--------------------------------------------------------------------------
    always @(*) begin
        // 清零
        RDATA_M0 = {`BUS_DATA_BITS{1'b0}};
        RLAST_M0 = 1'b0;
        WDATA_S1 = {`BUS_DATA_BITS{1'b0}};
        WLAST_S1 = 1'b0;
        WDATA_S2 = {`BUS_DATA_BITS{1'b0}};
        WLAST_S2 = 1'b0;

        // 根據 ID_M0 選擇要建立Master/slave 的 data/last
        case (ID_M0)
            2'd0: begin
                // 讀 ROM
                RDATA_M0 = RDATA_S0;
                RLAST_M0 = RLAST_S0;
            end
            2'd1: begin
                // 讀 S -> M
                RDATA_M0 = RDATA_S1;
                RLAST_M0 = RLAST_S1;
                //寫 M -> S 
                WDATA_S1 = WDATA_M0;
                WLAST_S1 = WLAST_M0;
            end
            2'd2: begin
                // 讀 S -> M
                RDATA_M0 = RDATA_S2;
                RLAST_M0 = RLAST_S2;
                //寫 M -> S 
                WDATA_S2 = WDATA_M0;
                WLAST_S2 = WLAST_M0;
            end
            default: begin
                // do nothing
            end
        endcase
    end


endmodule
