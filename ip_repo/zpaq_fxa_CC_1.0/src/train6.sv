`include "./zpaq_define.sv"
/*CMTable are read/write from ddr*/
//`define DEBUG_DDR


module train6
  import ZPAQDefines::*;
#(
  parameter CM_TW = 20,
  parameter CM_COUNT_LIMIT = 1020,
  parameter CM_DW = 32,
  parameter IN_DW = 1,
  parameter COUNT_DT_LEN = 1024,
  parameter COUNT_DT_DW = 32,
  parameter CMTable_BaseAddr = 32'h8000_0000,
  parameter AXI_DWByte = 8,
  parameter AXI_IDW = 2,
  parameter AXI_AW = 32,
  parameter AXI_AWUSER = 8,
  parameter AXI_ARUSER = 8,
  parameter AXI_WUSER = 8,
  parameter AXI_RUSER = 8,
  parameter AXI_BUSER = 8
  
)(
  input wire clk,
  input wire rst,
  input wire [CM_TW-1:0]train_cxt,
  input wire [CM_TW-1:0]lu_cxt,
  input wire wr_b,
  input wire Start,
  input wire [IN_DW-1:0]y,
  input wire inputValid,
  input wire [CM_DW-1:0]TrainCrCm,
  output logic inputReady,
  output logic trainFinish,
  output logic TalbeInitFinish,
  output logic [CM_DW-1:0]cr_cm,
  output logic crcmValid,
  Axi4FullIf.master_wr CMTableWrite,
  Axi4FullIf.master_rd CMTableRead
);
/****************Global Variable****************/
  localparam S_Idle = 7'b0000001;
  localparam S_InitTable = 7'b0000010;
  localparam S_SetIn = 7'b0000100;
  localparam S_ComputeError = 7'b0001000;
  localparam S_ComputeCM = 7'b0010000;
  localparam S_UpdateCM_WriteAddr = 7'b0100000;
  localparam S_UpdateCM_WaitResp = 7'b1000000;
  localparam CM_LEN = 2**CM_TW; 
  logic [6:0]state,nxt_state;
  logic [IN_DW-1:0]Yreg;
  logic [CM_TW-1:0]CxtReg;
  wire InputEn = inputValid & inputReady;
  logic [COUNT_DT_DW-1:0]DtOut;
/****************AXI Variable****************/
  localparam AXI_DW = 8 * AXI_DWByte;
  localparam MAX_BURSTCNT = CM_LEN * 4 / (256 * AXI_DWByte);
  localparam MAXIWR_INIT_WAITADDR = 2'b00;
  localparam MAXIWR_INIT_TRANSMIT = 2'b01;
  localparam MAXIWR_INIT_FINISH = 2'b10;

  logic [1:0]M_AXI_WRState;
  logic [$clog2(MAX_BURSTCNT):0]InitAddrBurstCnt;
  logic[$clog2(4096 / AXI_DWByte):0]HandShakeCnt;
/****************Train Variable****************/
  localparam CM_DATA_NUM = AXI_DW / 32;
  logic [$clog2(CM_COUNT_LIMIT)-1:0]count;
  logic signed[CM_DW-1:0] error;
  logic CountAddEn;
  logic[CM_DW-1:0]TrainData;
  logic[CM_DW-1:0]cr_cm_reg;
  logic signed[2*CM_DW-1:0]error_map;
  logic MulWaitDelay;
//  logic signed[2*CM_DW-1:0]error_map_reg;
  /********************************Assignment process********************************/
  
  /****************Global Assignment****************/
  always_ff @(posedge clk) begin : proc_state
    if(rst) begin
        state <= S_Idle;
    end 
    else begin
        state <= nxt_state;
    end
  end
  always_comb begin : Comb_State
    nxt_state = state;
    case(state)
      S_Idle:begin
        if(rst)nxt_state = S_Idle;
        else if(Start)begin
          nxt_state = S_InitTable;
        end
      end
      S_InitTable:begin
        if(rst)nxt_state = S_Idle;
        else if(TalbeInitFinish)begin
          nxt_state = S_SetIn;
        end
      end
      S_SetIn:begin
        if(rst)nxt_state = S_Idle;
        else if(InputEn)begin
          nxt_state = S_ComputeError;
        end
      end
      S_ComputeError:begin
        if(rst)nxt_state = S_Idle;
        else nxt_state = S_ComputeCM;
      end
      S_ComputeCM:begin
        if(rst)nxt_state = S_Idle;
        else if(MulWaitDelay)nxt_state = S_ComputeCM;
        else nxt_state = S_UpdateCM_WriteAddr;
      end
      S_UpdateCM_WriteAddr:begin
        if(rst)nxt_state = S_Idle;
        else if(CMTableWrite.awvalid & CMTableWrite.awready)nxt_state = S_UpdateCM_WaitResp;
        else nxt_state = S_UpdateCM_WriteAddr;
      end
      S_UpdateCM_WaitResp:begin
        if(rst)nxt_state = S_Idle;
        else if(CMTableWrite.bready & CMTableWrite.bvalid & (CMTableWrite.bresp == 2'b00))nxt_state = S_SetIn;
        else nxt_state = S_UpdateCM_WaitResp;
      end
    endcase
  end
  
  always_ff@(posedge clk)begin : Reg_Y
    if(rst)Yreg <= '0;
    else begin
      case(state)
        S_SetIn:begin
          if(InputEn) Yreg <= y;
        end
      endcase
    end
  end
  
  always_ff@(posedge clk)begin : Reg_cxt
    if(rst)CxtReg <= '0;
    else begin
      case(state)
        S_SetIn:begin
          if(InputEn) CxtReg <= train_cxt;
        end
      endcase
    end
  end
  
  always_ff@(posedge clk)begin
    if(rst)cr_cm_reg <= '0;
    else begin
      case(state)
        S_SetIn:begin
          if(InputEn) cr_cm_reg <= TrainCrCm;
        end
      endcase
    end
  end
  
  /****************Train Assignment****************/
  always_ff@(posedge clk)begin : Compute_Error
    if(rst)error <= '0;
    else begin
      case(state)
        S_ComputeError:begin
          error <= ((Yreg)? 32'sd32767 : 32'sd0) - (cr_cm_reg >> 17);
        end
      endcase
    end 
  end
  
//  always_comb error_map = (2*CM_DW)'(error) * (2*CM_DW)'(DtOut);
  always_ff@(posedge clk)begin : ComputeErrorMap
    error_map <= (2*CM_DW)'(error) * (2*CM_DW)'(DtOut);
  end
  
  always_ff@(posedge clk)begin  : WaitMul
    if(rst)MulWaitDelay <= 0;
    else begin
      if(MulWaitDelay)MulWaitDelay <= '0;
      else if(nxt_state == S_ComputeCM && state == S_ComputeError)MulWaitDelay <= 1;
    end
  end
  
  always_ff@(posedge clk)begin : Compute_CM
    if(rst)TrainData <= 32'h80000000;
    else begin
      case(state)
        S_ComputeCM:begin
          if(nxt_state == S_UpdateCM_WriteAddr && state == S_ComputeCM)
            TrainData <= cr_cm_reg + (error_map[CM_DW-1:0] & 32'hFFFF_FC00) + CountAddEn;
        end
      endcase
    end 
  end
  
  count_dt1#(COUNT_DT_LEN,COUNT_DT_DW)theDt(
    .clk(clk),
    .Aw(count),
    .dt_out(DtOut) 
  );
  
  always_comb begin : CombTrainIf
    trainFinish = (state == S_UpdateCM_WaitResp) & (nxt_state == S_SetIn); 
    inputReady = state == S_SetIn;
  end
  
  always_comb begin : CombTrain
    count = cr_cm_reg & 32'h000003FF;
    CountAddEn = count < CM_COUNT_LIMIT;
  end
  /****************Train Assignment****************/
  
  /*********AXI_Read*******/
  always_comb begin : M_AXI_RD
    CMTableRead.arid = '0;
    CMTableRead.arsize = 3'd2;   //read 2^asize byte per hand-shake
    CMTableRead.arlock = 1'b0;
    CMTableRead.arcache = 4'b1111;
    CMTableRead.arqos = 4'b0;
    CMTableRead.arregion = 4'b0;
    CMTableRead.aruser = '0;
    CMTableRead.arprot = 3'b000; 
    CMTableRead.arlen = 8'd0;     //no burst
    CMTableRead.arburst = 2'b01;   //INCR
  end

  always_ff@(posedge clk)begin : axi_raddr
    if(rst)begin 
      CMTableRead.araddr <= (AXI_AW)'(CMTable_BaseAddr);
      CMTableRead.arvalid <= '0;
    end
    else begin
      if(wr_b)begin
        CMTableRead.araddr <= ((AXI_AW)'(CMTable_BaseAddr) + ((AXI_AW)'(lu_cxt) << 2));
        CMTableRead.arvalid <= 1;
      end
      else if(CMTableRead.arvalid & CMTableRead.arready)begin
        CMTableRead.arvalid <= 0;
      end
    end
  end

  always_ff@(posedge clk)begin : axi_rdata
    if(rst)begin
      cr_cm <= '0;
      CMTableRead.rready <= '0;
      crcmValid <= '0;
    end
    else begin
      if(CMTableRead.arvalid & CMTableRead.arready)begin
        CMTableRead.rready <= '1;
      end
      else if(CMTableRead.rready & CMTableRead.rvalid)begin
        CMTableRead.rready <= '0;
      end
      
      if(CMTableRead.rready & CMTableRead.rvalid & (CMTableRead.rresp == 2'b00))begin
        cr_cm <= CMTableRead.araddr[$clog2(AXI_DWByte)-1:0]? CMTableRead.rdata[AXI_DW-1:AXI_DW-CM_DW] : CMTableRead.rdata[CM_DW-1:0];   //64bit or higer bit wide
        crcmValid <= 1;
      end
      else begin
        cr_cm <= cr_cm;
        crcmValid <= crcmValid;
      end
      
      if(crcmValid)crcmValid <= '0;   //???????????????compressbyte????????????????
    end
  end

/*********AXI_Write*******/
  always_comb begin
    CMTableWrite.awprot = 3'b0;
    CMTableWrite.awid = '0;
    CMTableWrite.awlock = 1'b0;
    CMTableWrite.awcache = 4'b1111;
    CMTableWrite.awqos = 4'b0;
    CMTableWrite.awregion = 4'b0;
    CMTableWrite.awuser = '0;
    CMTableWrite.wid = '0;
    CMTableWrite.wuser = '0;
  end

  always_ff@(posedge clk) TalbeInitFinish <= InitAddrBurstCnt == MAX_BURSTCNT & (M_AXI_WRState == MAXIWR_INIT_FINISH);

  always_ff@(posedge clk)begin : axi_waddr
    if(rst)begin
      CMTableWrite.awlen <= 8'b0;
      CMTableWrite.awsize <= 3'd2;
      CMTableWrite.awburst <= 2'b01;
      CMTableWrite.awaddr <= (AXI_AW)'(CMTable_BaseAddr);
      CMTableWrite.awvalid <= '0;
      M_AXI_WRState <= '0;
      InitAddrBurstCnt <= '0;
    end
    else begin
      case(state)
        S_InitTable:begin
          case(M_AXI_WRState)
            MAXIWR_INIT_WAITADDR:begin
              if(InitAddrBurstCnt < MAX_BURSTCNT)begin
    //            if(CMTableWrite.awready & (~CMTableWrite.awvalid))begin     //????
                if((~CMTableWrite.awvalid))begin     //????
                  CMTableWrite.awvalid <= 1;
                  CMTableWrite.awlen <= 8'd255;
                  CMTableWrite.awsize <= 3'd3;                              //2KB per burst;2^20 total;2^11 times burst
                  CMTableWrite.awburst <= 2'b01;                            //INCR
                  CMTableWrite.awaddr <= ((AXI_AW)'(CMTable_BaseAddr) + ((AXI_AW)'(InitAddrBurstCnt) << 11)); // *2048
                end
                else if(CMTableWrite.awready & CMTableWrite.awvalid)begin   // Addr enable
                  CMTableWrite.awvalid <= 0;
                  M_AXI_WRState <= 1;
                  InitAddrBurstCnt++;
                end
              end
              else begin
                CMTableWrite.awlen <= 8'b0;
                CMTableWrite.awsize <= 3'd2;
                CMTableWrite.awburst <= 2'b00;
              end
            end   //case 0
            MAXIWR_INIT_TRANSMIT:begin                                                       //wait for write finish
              if(InitAddrBurstCnt == MAX_BURSTCNT)begin
                if(CMTableWrite.bresp == 2'b00 & CMTableWrite.bvalid & CMTableWrite.bready)begin
                  M_AXI_WRState <= 2;   
                end
              end
              else if(CMTableWrite.bresp == 2'b00 & CMTableWrite.bvalid & CMTableWrite.bready)begin
                M_AXI_WRState <= 0;
              end
            end
            MAXIWR_INIT_FINISH:begin                                                       //INIT Finish
              
            end
          endcase
        end
        S_ComputeCM:begin
          if(nxt_state == S_UpdateCM_WriteAddr)begin
            CMTableWrite.awlen <= 8'b0;
            CMTableWrite.awsize <= 3'd2;
            CMTableWrite.awburst <= 2'b01;
            CMTableWrite.awaddr <= ((AXI_AW)'(CMTable_BaseAddr) + ((AXI_AW)'(CxtReg) << 2));
            CMTableWrite.awvalid <= '1;
          end
        end 
        S_UpdateCM_WriteAddr:begin
          if(CMTableWrite.awvalid & CMTableWrite.awready)begin
            CMTableWrite.awvalid <= '0;
          end
        end
      endcase
    end
  end

  always_ff@(posedge clk)begin : axi_bresp
    if(rst)begin
      CMTableWrite.bready <= '0;
    end
    else begin
      case(state)
        S_InitTable:begin
          if(CMTableWrite.wlast & CMTableWrite.wvalid & CMTableWrite.wready & (~CMTableWrite.bready))begin
            CMTableWrite.bready <= '1;
          end
          else if(CMTableWrite.bready & CMTableWrite.bvalid & (CMTableWrite.bresp == 2'b00))begin
            CMTableWrite.bready <= '0;
          end
        end
//        S_UpdateCM_WriteAddr:begin
//          if(CMTableWrite.wvalid & CMTableWrite.wready & CMTableWrite.wlast & (~CMTableWrite.bready))begin
//            CMTableWrite.bready <= 1;
//          end
//        end
        S_UpdateCM_WaitResp:begin
          if(CMTableWrite.wvalid & CMTableWrite.wready & CMTableWrite.wlast & (~CMTableWrite.bready))begin
            CMTableWrite.bready <= 1;
          end
          else if(CMTableWrite.bready & CMTableWrite.bvalid & (CMTableWrite.bresp == 2'b00))begin
            CMTableWrite.bready <= '0;
          end
        end
      endcase
    end
  end
  
  always_ff@(posedge clk)begin : axi_wdata
    if(rst)begin
      CMTableWrite.wdata <= '0;
      CMTableWrite.wstrb <= '0;
      CMTableWrite.wvalid <= '0;
      CMTableWrite.wlast <= '0;
      HandShakeCnt <= '0;
    end
    else begin
      case(state)
        S_InitTable:begin
          if((CMTableWrite.wvalid & CMTableWrite.wready & CMTableWrite.wlast) | CMTableWrite.bready)begin
//            CMTableWrite.wdata <= (AXI_DW)'({CM_DATA_NUM{32'h8000_0000}});
            CMTableWrite.wvalid <= '0;
            CMTableWrite.wstrb <= (AXI_DWByte)'(0);  
          end
          else if(CMTableWrite.awvalid & CMTableWrite.awready)begin
            CMTableWrite.wdata <= (AXI_DW)'({CM_DATA_NUM{32'h8000_0000}});
            CMTableWrite.wvalid <= '1;
            CMTableWrite.wstrb <= (AXI_DWByte)'(-1);
          end
          
          
          if(CMTableWrite.wvalid & CMTableWrite.wready & (HandShakeCnt == 255))begin
            CMTableWrite.wlast <= '0;
            HandShakeCnt <= 0;
          end
          else if(CMTableWrite.wvalid & CMTableWrite.wready & (HandShakeCnt == 254))begin
            CMTableWrite.wlast <= '1;
            HandShakeCnt++;
          end
          else if(CMTableWrite.wvalid & CMTableWrite.wready)begin
            HandShakeCnt++;
          end
        end
        S_UpdateCM_WriteAddr:begin
          if(~CMTableWrite.wvalid)begin
`ifdef DEBUG_DDR
            if(CMTableWrite.awaddr[$clog2(AXI_DWByte)-1:0] > 0)begin           
              CMTableWrite.wdata <= TrainData << (AXI_DWByte*4);
              CMTableWrite.wstrb <= 8'b11110000;
           	end
           	else begin
              CMTableWrite.wdata <= TrainData;
              CMTableWrite.wstrb <= 8'b00001111;
         	  end
`else 
//            CMTableWrite.wdata <= TrainData << (CMTableWrite.awaddr[$clog2(AXI_DWByte)-1:0] << 3);
            CMTableWrite.wdata <= TrainData << (CMTableWrite.awaddr[$clog2(AXI_DWByte)-1:0]? 32 : 0);
            CMTableWrite.wstrb <= (((AXI_DWByte+1)'(1) << (($clog2(AXI_DWByte)+1)'(1) << CMTableWrite.awsize))
                                 - (AXI_DWByte+1)'(1)) << CMTableWrite.awaddr[$clog2(AXI_DWByte)-1:0];
`endif
            CMTableWrite.wvalid <= '1;
            CMTableWrite.wlast <= '1;
          end
          else if(CMTableWrite.wvalid & CMTableWrite.wready)begin
//            CMTableWrite.wdata <= '0;
            CMTableWrite.wvalid <= '0;
            CMTableWrite.wlast <= '0;
            CMTableWrite.wstrb <= 8'b00000000;
          end
        end
        S_UpdateCM_WaitResp:begin
          if(CMTableWrite.wvalid & CMTableWrite.wready)begin
//            CMTableWrite.wdata <= '0;
            CMTableWrite.wvalid <= '0;
            CMTableWrite.wlast <= '0;
            CMTableWrite.wstrb <= 8'b00000000;
          end
        end
        default:begin
          CMTableWrite.wdata <= CMTableWrite.wdata;
          CMTableWrite.wstrb <= '0;
          CMTableWrite.wvalid <= '0;
          CMTableWrite.wlast <= '0;
        end
      endcase
    end
  end

endmodule


