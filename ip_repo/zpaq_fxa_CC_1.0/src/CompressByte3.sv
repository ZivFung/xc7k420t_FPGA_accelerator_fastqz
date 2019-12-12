module CompressByte3#(
  parameter integer IN_DW = 8,
  parameter integer OUT_DW = 8,
  parameter integer Prob_DW = 32,
  parameter integer Enc_IN_DW = 1,
  parameter integer CM_TW = 20,
  parameter integer CM_COUNT_LIMIT = 1020,
  parameter integer CM_DW = 32,
  parameter integer COUNT_DT_LEN = 1024,
  parameter integer COUNT_DT_DW =32,
  parameter integer H0_DW = 32,
  parameter integer CMTable_BaseAddr = 32'h8000_0000,
  parameter integer AXI_DWByte = 8,
  parameter integer AXI_IDW = 2,
  parameter integer AXI_AW = 32,
  parameter integer AXI_AWUSER = 8,
  parameter integer AXI_ARUSER = 8,
  parameter integer AXI_WUSER = 8,
  parameter integer AXI_RUSER = 8,
  parameter integer AXI_BUSER = 8
)(
  input wire clk,
  input wire rst,
  input wire start,
  input wire [IN_DW-1:0]CompressIn,
  input wire InputValid,
  input wire OutputReady,
  output logic [OUT_DW-1:0]CompressOut,
  output logic OutputValid,
  output logic InputReady,
  output logic ByteCompressFinish,
  output logic tableInitFinish,
  output logic [Prob_DW-1 : 0]EncLow,EncHigh,EncMid,
  Axi4FullIf.master_wr DDRWrite,
  Axi4FullIf.master_rd DDRRead
);
  /****************Global Variable****************/
  logic signed[31:0]hmap4[IN_DW-1:0];
  logic [H0_DW-1:0]h0;
  logic [CM_TW-1:0]cxt[IN_DW-1:0];
  logic [CM_TW-1:0]LookupCxt;
  wire InputEn = InputValid & InputReady;
  logic [IN_DW-1:0]InputBuffer;
  logic [IN_DW-1:0]InputBufferSuffix;
  localparam S_Idle = 8'b00000001;
  localparam S_WaitCMInit = 8'b00000010;
  localparam S_SetIn = 8'b00000100;
  localparam S_Encode0_0 = 8'b00001000;
  localparam S_ComputeHmap4 = 8'b00010000;
  localparam S_ComputeCxt = 8'b00100000;
  localparam S_Encode = 8'b01000000;
  localparam S_CompressFinish = 8'b10000000;
  (*mark_debug = "true"*)logic [7:0]state,nxt_state;
  logic [1:0]ByteFinishState;
  /****************Enc Variable****************/
  (*mark_debug = "true"*)logic EncoderIn,EncoderInputValid,EncoderInputReady,EncFinish;
  (*mark_debug = "true"*)logic [$clog2(IN_DW)-1:0]EncoderCnt;
  logic EncoderInputEn;
  /****************Train Variable****************/
  logic [CM_DW-1:0]CrCm;
  logic TrainInValid,TrainInReady,TrainFinish;
  logic [CM_TW-1:0]TrainCxt;
  logic [0:0]TrainIn;
  logic [Prob_DW-1:0]pin;
  logic CMInitFinish;
  logic ReadAddrEn;
  logic ReadAddrEnDly,ReadAddrEnDlyDly,ReadAddrEnDlyDlyDly,ReadAddrEnDlyDlyDlyDly;
  logic wr_b_reg;
  logic CrCmValid;
  logic PinValid;
  logic [1:0]LUTableState;
  logic signed[31:0]StretchOut;
  logic [15:0]SquashOut;
  logic [31:0]TrainCrCm;
  /****************UD8 Variable****************/
  logic [1:0]Update8ExState;
  logic UD8StateFlag;
  localparam UD8Idle = 2'b00;
  localparam UD8Runing = 2'b01;
  localparam UD8Finish = 2'b10;
  logic Update8Finish,Update8Start,Update8InValid,Update8InReady;
  logic Update8OutReady,Update8OutValid;
  
  /********************************Assignment process********************************/
  
  /****************Global Assignment****************/
  generate
    for(genvar i = 0; i < 8; i++)begin : ComputeInSuffix
      always_comb InputBufferSuffix[i] = InputBuffer[7-i];
    end
  endgenerate
  
  always_ff@(posedge clk)begin : Proc_byteFinishState
    if(rst) ByteFinishState <= 0;
    else begin
      case(ByteFinishState)
        2'b00:begin
          if(state == S_CompressFinish & EncoderInputReady) ByteFinishState <= 2'b10;
          else if(state == S_CompressFinish) ByteFinishState <= 2'b01;
        end
        2'b01:begin
          if(EncoderInputReady) ByteFinishState <= 2'b10;
        end
        2'b10:begin
          ByteFinishState <= 2'b00;
        end
      endcase
    end
  end
  
  always_comb begin : Comb_If
    InputReady = state == S_SetIn;
    ByteCompressFinish = ByteFinishState == 2'b10;
  end
  
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
        if(start)begin
          nxt_state = S_WaitCMInit;
        end
      end
      S_WaitCMInit:begin
        if(rst)nxt_state = S_Idle;
        else if(CMInitFinish)nxt_state = S_SetIn;
      end
      S_SetIn:begin
        if(rst)nxt_state = S_Idle;
        else if(InputEn)nxt_state = S_Encode0_0;
      end
      S_Encode0_0:begin
        if(rst)nxt_state = S_Idle;
        else if(EncoderInputEn)nxt_state = S_ComputeHmap4;
      end
      S_ComputeHmap4:begin
        if(rst)nxt_state = S_Idle;
        else nxt_state = S_ComputeCxt;
      end
      S_ComputeCxt:begin
        if(rst)nxt_state = S_Idle;
        else nxt_state = S_Encode;
      end
      S_Encode:begin
        if(rst)nxt_state = S_Idle;
        else if(EncoderCnt == 7 & EncoderInputEn)begin
          nxt_state = S_CompressFinish;
        end
      end
      S_CompressFinish:begin
        if(rst)nxt_state = S_Idle;
        else begin
          if(Update8ExState == UD8Finish)
            nxt_state = S_SetIn;
        end
      end
    endcase
  end
  
  always_ff@(posedge clk)begin : Set_Input
    if(rst)begin
      InputBuffer <= '0;
    end
    else begin
      case(state)
        S_SetIn:begin
          if(InputEn) InputBuffer <= CompressIn;
        end
      endcase
    end
  end

  generate 
    for(genvar i = 0; i < IN_DW; i++)begin : Compute_Hmap4
      if(i == 0)begin
        always_ff@(posedge clk)begin
          if(rst)hmap4[i] <= 1;
          else begin
            case(state)
              S_ComputeHmap4:begin
                hmap4[i] <= 1;
              end
              S_CompressFinish:begin
                hmap4[i] <= 1;
              end
            endcase
          end
        end
      end
      else if(i < 4)begin       
        always_ff@(posedge clk)begin
          if(rst) hmap4[i] <= 1;
          else begin
            case(state)
              S_ComputeHmap4:begin
                hmap4[i] <= (1 << i) | (InputBuffer >> (8-i));
              end
              S_CompressFinish:begin
                hmap4[i] <= 1;
              end
            endcase
          end
        end
      end
      else begin
        always_ff@(posedge clk)begin
          if(rst)hmap4[i] <= 1;
          else begin
            case(state)
              S_ComputeHmap4:begin
                hmap4[i] <= (((32)'(InputBuffer) | 32'h100) & 32'h1f0 ) | (1 << (i-4)) | ((InputBuffer & 8'h0F) >> (8-i));
              end
              S_CompressFinish:begin
               	hmap4[i] <= 1;
              end
            endcase
          end
        end
      end
    end
  endgenerate
  
  generate
    for(genvar i = 0; i < IN_DW; i++)begin : Compute_Cxt 
      always_ff@(posedge clk)begin
        if(rst)cxt[i] <= '0;
        else begin
          case(state)
            S_ComputeCxt:begin
              cxt[i] <= (CM_TW)'(h0) ^ (CM_TW)'(hmap4[i]);
            end
          endcase
        end
      end
    end
  endgenerate
  /****************Enc Assignment****************/
  always_comb EncoderInputEn = EncoderInputValid & EncoderInputReady;
  
  always_ff@(posedge clk)begin : EncoderCount
    if(rst)begin
      EncoderCnt <= '0;
    end
    else begin
      case(state)
        S_Encode:begin
          if(EncoderInputEn)EncoderCnt <= EncoderCnt + 1;
        end
        default:begin
          EncoderCnt <= EncoderCnt;
        end
      endcase
    end
  end
  
  logic stretchDly,squashDly;
  
  always_ff@(posedge clk)begin : EncoderInIf
    if(rst)begin
      EncoderIn <= '0;
      EncoderInputValid <= '0;
    end
    else begin
      case(state)
        S_Encode0_0:begin
          EncoderIn <= '0;
          EncoderInputValid <= 1;
        end
        S_Encode:begin
          if(EncoderInputEn)begin
            EncoderInputValid <= 0;
          end
          else if(squashDly & EncoderInputReady)begin   //altered
            EncoderIn <= InputBufferSuffix[EncoderCnt];
            EncoderInputValid <= 1;
          end

        end
        default: begin
          EncoderIn <= EncoderIn;
          EncoderInputValid <= 0;
        end
      endcase
    end  
  end
  
  always_ff@(posedge clk)begin
    if(rst)begin
      stretchDly <= '0;
      squashDly <= '0;   
    end
    else begin
      stretchDly <= CrCmValid;
      squashDly <= stretchDly;
    end
  end
  stretch1#(32,32768)StretchT(
    .clk(clk),
    .Aw((15)'(CrCm >> 17)),
    .stretchOut(StretchOut)
  );
  wire [11:0] squashIn = StretchOut + 2048;
  squash1#(16,4096)SquashT(
    .clk(clk),
    .Aw(squashIn),
    .squashOut(SquashOut)
  );

  always_ff@(posedge clk)begin : EncPinCompute
    if(rst)pin <= '0;
    else begin
      case(state)
        S_Encode0_0:begin
          pin <= 0;
        end
        S_Encode : begin
//          if(CrCmValid)pin = ((CrCm >> 17) <<< 1) + 1;
          if(squashDly)pin = (Prob_DW)'(SquashOut <<< 1) + 1;
        end
      endcase
    end
  end
  
  ArithEncoder1#(Enc_IN_DW,Prob_DW,OUT_DW)the_ArithEnc(
    .clk(clk),
    .rst(rst),
    .start(start),
    .y(EncoderIn),
    .p(pin),
    .inputVaild(EncoderInputValid),
    .outputReady(OutputReady),
    .inputReady(EncoderInputReady),
    .out(CompressOut),
    .outputValid(OutputValid),
    .EncFinish(EncFinish),
    .EncLow(EncLow),
    .EncHigh(EncHigh),
    .EncMid(EncMid)
  );
  /****************Train Assignment****************/
  
  always_ff@(posedge clk)begin : ReadCm
    if(rst)begin
      LookupCxt<='0;
      ReadAddrEn <= '0;
      LUTableState <= '0;
    end
    else begin
      case(state)
        S_Encode:begin
		    case(LUTableState)
            2'b00:begin
              if(EncoderInputReady & (~ReadAddrEn))begin
                LookupCxt <= cxt[EncoderCnt];
                ReadAddrEn <= 1;
                LUTableState <= 2'b01;
              end
            end
            2'b01:begin
              if(ReadAddrEn)ReadAddrEn <= '0;
//              else if(PinValid & ~ReadAddrEn)begin
              else if(CrCmValid & ~ReadAddrEn)begin
                LUTableState <= 2'b10;
              end
            end
            2'b10:begin
              if(TrainFinish)LUTableState <= 2'b00;
            end
          endcase
        end
        default:begin
          case(LUTableState)
            2'b10:begin
              if(TrainFinish)LUTableState <= 2'b00;
              else LUTableState <= LUTableState;
            end
            default:begin
              LookupCxt <= LookupCxt;
              ReadAddrEn <= '0;
              LUTableState <= '0;
            end
          endcase
        end
      endcase
    end
  end

  always_comb begin
    TrainInValid = ((state == S_Encode) & EncoderInputEn);
    TrainCxt = cxt[EncoderCnt];
    TrainIn = InputBufferSuffix[EncoderCnt];
    tableInitFinish = CMInitFinish;
  end

  train6#(
    .CM_TW(CM_TW),
    .CM_COUNT_LIMIT(CM_COUNT_LIMIT),
    .CM_DW(CM_DW),
    .IN_DW(1),
    .COUNT_DT_LEN(COUNT_DT_LEN),
    .COUNT_DT_DW(COUNT_DT_DW),
    .CMTable_BaseAddr(CMTable_BaseAddr),
    .AXI_DWByte(AXI_DWByte),
    .AXI_IDW(AXI_IDW),
    .AXI_AW(AXI_AW),
    .AXI_AWUSER(AXI_AWUSER),
    .AXI_ARUSER(AXI_ARUSER),
    .AXI_WUSER(AXI_WUSER),
    .AXI_RUSER(AXI_RUSER),
    .AXI_BUSER(AXI_BUSER)
  )theTrain0(
    .clk(clk),
    .rst(rst),
    .Start(start),
    .train_cxt(TrainCxt),
    .lu_cxt(LookupCxt),
    .wr_b(ReadAddrEn),
    .y(TrainIn),
    .inputValid(TrainInValid),
    .TrainCrCm(CrCm),
    .inputReady(TrainInReady),
    .TalbeInitFinish(CMInitFinish),
    .trainFinish(TrainFinish),
    .cr_cm(CrCm),
    .crcmValid(CrCmValid),
    .CMTableWrite(DDRWrite),
    .CMTableRead(DDRRead)
);

  /****************UD8 Assignment****************/
  always_comb begin : Compute_UD8flag
    UD8StateFlag = state == S_CompressFinish & Update8ExState == UD8Finish;
  end
 
  update8#(IN_DW,H0_DW
  )theUpdate8(
   .clk(clk),
   .rst(rst),
   .start(Update8Start),
   .Byte(InputBuffer),
   .InputValid(Update8InValid),
   .OutputReady(Update8OutReady),
   .h0(h0),
   .InputReady(Update8InReady),
   .OutputValid(Update8OutValid),
   .Update8Finish(Update8Finish)
  );
  
  always_comb begin : Update8_If
	  Update8OutReady = state == S_ComputeCxt? 0 : 1;
	  Update8Start = (EncoderCnt == 0) & (state == S_Encode) & EncoderInputEn & (Update8ExState == UD8Idle);
	  Update8InValid = state == S_Encode;
  end
  
  always_ff@(posedge clk)begin : UD8ExSts_Proc
    if(rst)Update8ExState <= '0;
    else begin
      case(Update8ExState)
        UD8Idle:begin
          if(Update8Start)Update8ExState <= UD8Runing;
          else Update8ExState <= Update8ExState;
        end
        UD8Runing:begin
          if(Update8Finish)Update8ExState <= UD8Finish;
          else Update8ExState <= Update8ExState;
        end
        UD8Finish:begin
          if(UD8StateFlag)Update8ExState <= UD8Idle;
          else Update8ExState <= Update8ExState;
        end
        default:begin
          Update8ExState <= UD8Idle;
        end
      endcase
    end
  end

endmodule
