module update8#(
  parameter IN_DW = 8,
  parameter H0_DW = 32
)(
  input wire clk,
  input wire rst,
  input wire start,
  input wire [IN_DW-1:0]Byte,
  input wire InputValid,
  input wire OutputReady,
  output logic [H0_DW-1:0]h0,
  output logic InputReady,
  output logic OutputValid,
  output logic Update8Finish
);
  /****************Variable****************/
  logic [31:0]a,b,c;
  logic [0:0]f;
  logic [5:0]ModelCnt;
  wire InputEn = InputValid & InputReady;
  wire OutputEn = OutputValid & OutputReady;
  
  /********************************Assignment process********************************/
  always_ff@(posedge clk)begin : proc_case
    if(rst)begin
      ModelCnt <= '0;
    end
    else begin
      case(ModelCnt)
        0:begin
          if(start)ModelCnt <= ModelCnt + 1;
        end
        1:begin
          if(InputEn)ModelCnt <= ModelCnt + 1;
        end
        36:begin          //finish
          if(OutputEn)ModelCnt <= '0;
        end
        4:begin
          ModelCnt <= ModelCnt + 2;
        end
        6:begin
          if(!f) ModelCnt <= ModelCnt + 8;  //7+1
          else ModelCnt <= ModelCnt + 2; 
        end
        9:begin
          ModelCnt <= ModelCnt + 2;
        end
        11:begin
          if(!f) ModelCnt <= ModelCnt + 3;  //2+1
          else ModelCnt <= ModelCnt + 2; 
        end
        15:begin
          ModelCnt <= ModelCnt + 2; 
        end
        17:begin
          if(!f) ModelCnt <= ModelCnt + 3;  //2+1
          else ModelCnt <= ModelCnt + 2; 
        end
        20:begin
          ModelCnt <= ModelCnt + 2; 
        end
        22:begin
          if(!f) ModelCnt <= ModelCnt + 10;  //9+1
          else ModelCnt <= ModelCnt + 2; 
        end
        25:begin
          ModelCnt <= ModelCnt + 2;
        end
        27:begin
          ModelCnt <= ModelCnt + 2;
        end
        30:begin
          ModelCnt <= ModelCnt + 3;//2 + 1
        end
        33:begin
          ModelCnt <= ModelCnt + 2;
        end
        default:ModelCnt <= ModelCnt + 1;
      endcase
    end
  end
  
  always_ff@(posedge clk)begin : Compute_A
    if(rst)a <= '0;
    else begin
      case(ModelCnt)
        1:if(InputEn)a <= (32)'(Byte);
        8:a <= c;
        14:a <= c;
        24:a <= b;
        25:a <= a >> 2;
        27:a <= a << 5;
        29:a <= a + c;
        32:a <= c;
        33:a <= a << 9;
      endcase
    end
  end
  
  always_ff@(posedge clk)begin : Compute_B
    if(rst)b <= '0;
    else begin
      case(ModelCnt)
        3:b <= a;
      endcase
    end
  end
  
  always_ff@(posedge clk)begin : Compute_C
    if(rst)c <= '0;
    else begin
      case(ModelCnt)
        2:c++;
        13:c <= 0;
        19:c <= 0;
      endcase
    end
  end
  
  always_ff@(posedge clk)begin : Compute_f
    if(rst)f <= '0;
    else begin
      case(ModelCnt)
        4:f <= (a == 0);
        9:f <= (a == 1);
        15:f <= (a > 7); 
        20:f <= (a < 6);
      endcase
    end
  end
  
  always_ff@(posedge clk)begin : Compute_H0
    if(rst)h0 <= 0;
    else if(ModelCnt == 35)h0 <= a;
    else  h0 <= h0;
  end
  
  always_comb begin : CombIf
    OutputValid = ModelCnt == 36;
    InputReady = ModelCnt == 1;
    Update8Finish = ModelCnt == 36;
  end
endmodule

