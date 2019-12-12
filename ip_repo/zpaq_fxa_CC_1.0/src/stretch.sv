module stretch#(
  parameter DW = 32,
  parameter TW = 32768
)(
  input wire [$clog2(TW)-1:0]Aw,
  output logic signed[DW-1:0]stretchOut
);
  logic signed [DW-1:0]stretcht[TW-1:0];
  
  initial begin
    for(int i = 0; i < TW; i++)begin
      stretcht[i] = $floor(($ln((i + 0.5) / (32767.5-i)) * 64 + 0.5 + 100000)) - 100000;
    end  
  end

  assign stretchOut = stretcht[Aw];

endmodule
