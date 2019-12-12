module ArithEncoder1#(
    parameter In_DW = 1,
    parameter Prob_DW = 32,
    parameter Out_DW = 8
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [In_DW-1:0]y,
    input wire signed[Prob_DW-1:0]p,
    input wire inputVaild,
    input wire outputReady,
    output logic inputReady = '0,
    output logic [Out_DW-1 : 0]out,
    output logic outputValid,
    output logic EncFinish,
    output logic [Prob_DW-1 : 0]EncLow,EncHigh,EncMid
);
  /****************Variable****************/
  localparam S_Idle = 5'b00001;
  localparam S_SetIn = 5'b00010;
  localparam S_ComputeMid = 5'b00100;
  localparam S_ComputeBoundary = 5'b01000;
  localparam S_SetOut = 5'b10000; 
  logic [4:0]state,nxt_state;
  logic InputEn,InputEnDelay,MulWaitDelay,MulWaitDelayDelay,OutputEn;
  logic [Prob_DW-1 : 0]Low,High,Mid;
  logic [Prob_DW-1 : 0]ProbDelta;
  logic [Prob_DW-1 : 0]Delta,DeltaDly;
  logic [In_DW-1 : 0]y_reg;
  logic [Prob_DW-1 : 0]p_reg;
  logic [0:0]WriteByteWait;
  wire [Prob_DW-1 : 0]Low_ShfitLeft8 = (Low << 8);
  wire WriteByteEn = (High ^ Low) < 32'h100_0000;
  
  /********************************Assignment process********************************/
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
          nxt_state = S_SetIn;
        end
        else nxt_state = S_Idle;
      end
      S_SetIn:begin
        if(rst)nxt_state = S_Idle;
        else if(WriteByteEn)nxt_state = S_SetOut;
        else if(InputEn)nxt_state = S_ComputeMid;
      end
      S_ComputeMid:begin
        if(rst)nxt_state = S_Idle;
        else if(MulWaitDelayDelay)begin
          nxt_state = S_ComputeBoundary;
        end
        else begin
          nxt_state = S_ComputeMid;
        end
      end
      S_ComputeBoundary:begin
        if(rst)nxt_state = S_Idle;
        else if(WriteByteWait)nxt_state = S_ComputeBoundary;
        else if(WriteByteEn)begin
          nxt_state = S_SetOut;
        end
        else begin
          nxt_state = S_SetIn;
        end
      end
      S_SetOut:begin
        if(rst)nxt_state = S_Idle;
        else if(outputReady) nxt_state = S_SetIn;
        else nxt_state = S_SetOut;
      end
    endcase
  end
  
  always_comb begin : Comb_If
    outputValid = (state == S_SetOut);
    out = (outputValid) ? (High>>24) : 0;
    inputReady = ((state == S_SetIn & (~WriteByteEn)) | state == S_Idle);
    EncFinish = (state == S_ComputeBoundary & nxt_state == S_SetIn) | (state == S_SetOut & nxt_state == S_SetIn);
    InputEn = inputVaild & inputReady;
    OutputEn = outputReady & outputValid;
    EncLow = Low;
    EncHigh = High;
    EncMid = Mid;
  end
  
  always_ff@(posedge clk)begin
    InputEnDelay <= InputEn;
    MulWaitDelay <= InputEnDelay;
    MulWaitDelayDelay <= MulWaitDelay;
  end
  
  always_ff@(posedge clk)begin : RegInput
    if(rst)begin
      y_reg <= '0;p_reg <= '0;
    end
    else begin
      case(state)
        S_SetIn:begin
          if(InputEn)begin
            y_reg <= y;
            p_reg <= p;
          end
        end
      endcase
    end
  end

  always_ff@(posedge clk) begin : ComputeDelta
    if(rst)begin
      ProbDelta <= '0;
    end
    else begin
      ProbDelta <= High - Low;
    end  
    Delta <= ((2*Prob_DW)'(ProbDelta) * (2*Prob_DW)'(p_reg)) >>> 16; 
  end
  
  always_ff@(posedge clk)begin : MulDly
    DeltaDly <= Delta;
  end
  
  always_ff@(posedge clk)begin : ComputeMid
    if(rst)begin
      Mid <= '0;
    end
    else begin
      case(state)
        S_ComputeMid:begin
          if(MulWaitDelayDelay)Mid <= Low + DeltaDly;
        end
      endcase
    end
  end

  always_ff@(posedge clk)begin : proc_IsOut
    if(rst)WriteByteWait <= 0;
    else begin
      if(nxt_state == S_ComputeBoundary & state == S_ComputeMid)WriteByteWait <= 1;
      else WriteByteWait <= 0;
    end
  end

  always_ff@(posedge clk)begin : ComputeBoundary
    if(rst)begin
      High <= (Prob_DW)'(-1);Low <= 1;
    end
    else begin
      case(state)
        S_ComputeBoundary:begin
          if(y_reg)High <= Mid;
          else Low <= Mid + 1;
        end
        S_SetOut:begin
          if(OutputEn)begin
            High <= High <<8 | 255;
           	Low <= (Low << 8) + (Low_ShfitLeft8 == 0);
         	end
        end
      endcase
    end
  end
    
endmodule
