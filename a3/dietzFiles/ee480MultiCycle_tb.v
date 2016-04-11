module ee480MultiCycle_tb;
reg reset = 0;
reg clk = 0;
wire halted;
processor PE(halted, reset, clk);
initial begin
  $dumpfile("ee480MultiCycle_tb.vdc");
  $dumpvars(0, ee480MultiCycle_tb);
  #10 reset = 1;
  #10 reset = 0;
  while (!halted) begin
    #10 clk = 1;
    #10 clk = 0;
  end
  $finish;
end
endmodule
