module stretch1#(
  parameter DW = 32,
  parameter TW = 32768
)(
  input wire clk,
  input wire [$clog2(TW)-1:0]Aw,
  output logic signed[DW-1:0]stretchOut
);
  logic signed [DW-1:0]stretcht[TW-1:0];
  
  initial begin
    $readmemh("stretch.dat",stretcht);
  end

  always_ff@(posedge clk) stretchOut <= stretcht[Aw];

endmodule


