module squash1#(
  parameter DW = 16,
  parameter TW = 4096
)(
  input wire clk,
  input wire [$clog2(TW)-1:0]Aw,
  output logic [DW-1:0]squashOut
);
  logic [DW-1:0]squasht[TW-1:0];
  
  initial begin
    $readmemh("squash.dat",squasht);  
  end

  always_ff@(posedge clk) squashOut <= squasht[Aw];

endmodule

