module count_dt1#(
  parameter DT_LEN = 1024,
  parameter DT_DW = 32
)(
  input wire clk,
  input wire [$clog2(DT_LEN)-1:0]Aw,

  output logic signed[DT_DW-1:0]dt_out 
);
  logic signed[DT_DW-1:0]dt_table[DT_LEN-1:0];
  
  initial begin
    $readmemh("count_dt.dat",dt_table); 
  end
  
//  assign dt_out = dt_table[Aw];
  always_ff@(posedge clk)dt_out <= dt_table[Aw];
  
endmodule 


