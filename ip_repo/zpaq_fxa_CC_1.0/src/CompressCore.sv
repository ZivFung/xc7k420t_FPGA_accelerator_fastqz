`include "./zpaq_define.sv"

module CompressCore
  import ZPAQDefines::*;
#(
  parameter integer AXIS_DW = 8,
  /* ZPAQ PARAMETER*/
  parameter integer CM_TW = 20,
  parameter integer CM_COUNT_LIMIT = 1020,
  parameter integer CMTable_BaseAddr = 32'h8000_0000,
  /* Other PARAMETER*/
  parameter integer NumberPerBlock = 4096,
  /* AXI_FULL PARAMETER*/
  parameter integer AXI_DWByte = 8,
  parameter integer AXI_IDW = 2,
  parameter integer AXI_AW = 32,
  parameter integer AXI_AWUSER = 8,
  parameter integer AXI_ARUSER = 8,
  parameter integer AXI_WUSER = 8,
  parameter integer AXI_RUSER = 8,
  parameter integer AXI_BUSER = 8
)(
  input wire start,
  (*mark_debug = "true"*)input wire FBFlag,
  input wire [31:0]FBCount,
  Axi4StreamIf.slave CompressIn,
  Axi4StreamIf.master CompressOut,
  Axi4FullIf.master_wr DDRWrite,
  Axi4FullIf.master_rd DDRRead,
  (*mark_debug = "true"*)output logic ByteFinish,
  output logic tableInitFinish,
  output logic [31 : 0]EncLow,EncHigh,EncMid,
  output logic FileFinish
);
  logic CBoutputValid;
  (*mark_debug = "true"*)logic[2:0]FBLastState;
  logic [$clog2(NumberPerBlock)-1:0]B_counter;
  logic [31:0]FB_Counter;
  CompressByte3#(AXIS_DW,AXIS_DW,32,1,CM_TW,CM_COUNT_LIMIT,32,1024,32,32,
    CMTable_BaseAddr,
    AXI_DWByte,
    AXI_IDW,
    AXI_AW,
    AXI_AWUSER,
    AXI_ARUSER,
    AXI_WUSER,
    AXI_RUSER,
    AXI_BUSER
  )compressBtye(
    .clk(CompressIn.clk),
    .rst(~CompressIn.reset_n),
    .start(start),
    .CompressIn(CompressIn.tdata),
    .InputValid(CompressIn.tvalid),
    .OutputReady(CompressOut.tready),
    .CompressOut(CompressOut.tdata),
    .OutputValid(CBoutputValid),
   	.InputReady(CompressIn.tready),
    .ByteCompressFinish(ByteFinish),
    .tableInitFinish(tableInitFinish),
    .EncLow(EncLow),
    .EncHigh(EncHigh),
    .EncMid(EncMid),
    .DDRWrite(DDRWrite),
    .DDRRead(DDRRead)
  );
  
  always_ff@(posedge CompressIn.clk)begin : Proc_Block
    if(~CompressIn.reset_n)begin
        B_counter <= '0;
    end
    else begin
        if(CompressOut.tvalid & CompressOut.tready & (~FileFinish))begin
            if(B_counter < (NumberPerBlock-1))
                B_counter++;
            else if(B_counter == (NumberPerBlock-1))begin
                B_counter <= '0;
            end
        end
    end    
  end
  
  always_ff@(posedge CompressIn.clk)begin : Proc_FBcounter
    if(~CompressIn.reset_n)begin
        FB_Counter <= '0; 
    end
    else begin
        if(FBFlag)begin
            if(ByteFinish)FB_Counter++;
            else if(CompressOut.tlast)FB_Counter <= '0;
        end 
        else begin
            FB_Counter <= '0;
        end
    end
  end
  
  always_ff@(posedge CompressIn.clk)begin : Proc_LastState
    if(~CompressIn.reset_n)begin
        FBLastState <= '0;
    end
    else begin
        case(FBLastState)
            3'b000:begin
                if(CompressIn.tvalid & CompressIn.tready & (~CompressIn.tlast) & FBFlag)begin
                    FBLastState <= 3'b001;
                end
            end
            3'b001:begin
                if(CompressIn.tvalid & CompressIn.tready & (CompressIn.tlast))begin
                   FBLastState <= 3'b010; 
                end
            end
            3'b010:begin
                if(ByteFinish)begin
                   FBLastState <= 3'b011;
                end
            end
            3'b011:begin
                if(ByteFinish)begin
                   FBLastState <= 3'b100;
                end
            end
            3'b100:begin
                if(CompressOut.tvalid & CompressOut.tready & (CompressOut.tlast))begin
                    FBLastState <= 3'b101; 
                end
            end
            default: FBLastState <= 0;
        endcase
    end
  end
  
  always_comb begin : Proc_OutValid
    if(FBFlag)begin
        if(FBLastState == 3'b100 & CompressOut.tready)begin
            CompressOut.tvalid = 1;
        end
        else begin
           CompressOut.tvalid = CBoutputValid;
        end
    end
    else begin
        CompressOut.tvalid = CBoutputValid;
    end
  end
  
  always_comb begin : Proc_OutLast
    if(FBFlag)begin
        if(FBLastState == 3'b100 & CompressOut.tready)begin
            CompressOut.tlast = 1;
        end
        else begin
            CompressOut.tlast = 0;
        end
    end
    else begin
        if(B_counter == (NumberPerBlock-1) & CompressOut.tvalid & CompressOut.tready)
            CompressOut.tlast = 1;
        else begin
            CompressOut.tlast = 0;
        end
    end
  end
  
  always_ff@(posedge CompressIn.clk)begin : Proc_FileFinish
    if(~CompressIn.reset_n)FileFinish <= '0;
    else begin
      if(FBLastState == 3'b100 & CompressOut.tready & CompressOut.tvalid & CompressOut.tlast)FileFinish <= 1;
    end
  end
//  assign CompressOut.tlast = 0;
endmodule
