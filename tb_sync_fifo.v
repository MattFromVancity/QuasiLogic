`timescale 1ns/10ps

module tb_sync_fifo;

// TB Signals
reg tb2dut_clk;
reg tb2dut_rstn;
reg tb2dut_wren;
reg tb2dut_rden;
reg [63:0] tb2dut_data;
reg [63:0] dut2tb_data;
reg dut2tb_data_vld;
reg dut2tb_overflow;
reg dut2tb_underflow;
reg [63:0] tb_check_data;

// Clock Stim
initial begin
  tb2dut_clk = 0;
  $dumpvars;
  forever
    #5ns tb2dut_clk = ~tb2dut_clk;
end

// stimulus
initial begin
  tb2dut_rstn <= 0;
  tb2dut_rden <= 0;
  tb2dut_wren <= 0;
  tb2dut_data <= 0;
  #10ns
  tb2dut_rstn <= 1;
  tb2dut_wren <= 1'b1;
  tb2dut_data <= $urandom();
  @(posedge tb2dut_clk);
  tb2dut_wren <= 1'b0;
  tb2dut_rden <= 1'b1;
  @(posedge tb2dut_clk);
  tb2dut_rden <= 1'b0;
  @(posedge tb2dut_clk);
  tb2dut_rden <= 1'b1;
  tb2dut_wren <= 1'b1;
  tb2dut_data <= $urandom();
  @(posedge tb2dut_clk);
  tb2dut_rden = 1'b0;
  tb2dut_wren = 1'b0;
  // write 40 entires
  for(int i = 0; i < 40; i++) begin
    @(posedge tb2dut_clk);
    tb2dut_wren <= 1'b1;
    tb2dut_data <= $urandom();
  end
  // read back all entries
  @(posedge tb2dut_clk);
  tb2dut_wren <= 1'b0;
  tb2dut_rden <= 1'b1;
  for(int i = 0; i < 20; i++) begin
    @(posedge tb2dut_clk);
  end

  #500ns
  $finish;
end


// DUT instantiation
sync_fifo u_sync_fifo (
  .i_clk(tb2dut_clk),
  .i_rstn(tb2dut_rstn),
  .i_wren(tb2dut_wren),
  .i_rden(tb2dut_rden),
  .i_data(tb2dut_data),
  .o_data(dut2tb_data),
  .o_data_vld(dut2tb_data_vld),
  .o_overflow(dut2tb_overflow),
  .o_underflow(dut2tb_underflow)
);

endmodule