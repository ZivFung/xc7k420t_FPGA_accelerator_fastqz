module squash#(
  parameter DW = 16,
  parameter TW = 4096
)(
  input wire [$clog2(TW)-1:0]Aw,
  output logic [DW-1:0]squashOut
);
  logic [DW-1:0]squasht[TW-1:0];
  
  initial begin
    for(int i = 0; i < TW; i++)begin
      //int(32768.0/(1+exp((i-2048)*(-1.0/64))));
      squasht[i] = $floor(32768.0 / (1 + $exp((i-2048)*(-1.0/64))));
    end  
  end

  assign squashOut = squasht[Aw];

endmodule
