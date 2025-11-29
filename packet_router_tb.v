`timescale 1ns/10ps

module packet_router_tb;

localparam integer PATH_COUNT = 4;
localparam integer DATA_WIDTH = 8;

reg tb2dut_Clk;
reg tb2dut_Rst;
reg tb2dut_pktValid;
reg [DATA_WIDTH-1:0]  tb2dut_pktData;
reg [DATA_WIDTH-1:0]  dut2tb_data;
reg [PATH_COUNT-1:0]  dut2tb_dataVld;
reg [PATH_COUNT-1:0] [31:0] tb2dut_RegMatchCriteria;

// clock
initial begin
  $dumpvars;
  tb2dut_Clk = 1'b0;
  forever begin
    #5ns tb2dut_Clk = ~tb2dut_Clk;
  end
end

genvar i;
generate
  for(i = 0; i < PATH_COUNT; i++) begin
    assign tb2dut_RegMatchCriteria[i][31:28] = i;
    assign tb2dut_RegMatchCriteria[i][27:0]  = 28'b0;
  end
endgenerate
// stimulus
initial begin
  tb2dut_Rst <= 1'b1;
  tb2dut_pktValid <= 1'b0;
  #10ns;
  tb2dut_Rst <= 1'b0;
  #100ns;
  // drive some stimulus
  tb2dut_pktValid <= 1'b1;
  tb2dut_pktData  <= {4'b00, 4'b0101};
  @(posedge tb2dut_Clk);  
    tb2dut_pktData  <= {4'b01, 4'b0101};
  @(posedge tb2dut_Clk);  
    tb2dut_pktData  <= {4'b01, 4'b0111};
  @(posedge tb2dut_Clk);  
    tb2dut_pktData  <= {4'b11, 4'b0101};
  @(posedge tb2dut_Clk);  
    tb2dut_pktData  <= {4'b10, 4'b0101};
  #20ns;
  @(posedge tb2dut_Clk);  
    tb2dut_pktData  <= {4'b11, 4'b0101};
  @(posedge tb2dut_Clk);
    tb2dut_pktData <= 'x;
    tb2dut_pktValid <= 1'b0;
  #1000ns;
  $finish;
end

packet_router #(
  .PATH_COUNT(PATH_COUNT),
  .DATA_WIDTH(DATA_WIDTH)
) u_packet_router (
  .iClk(tb2dut_Clk),
  .iRst(tb2dut_Rst),
  .iPktValid(tb2dut_pktValid),
  .iPktData(tb2dut_pktData),
  .oData(dut2tb_data),
  .oDataVld(dut2tb_dataVld),
  .iRegMatchCriteria(tb2dut_RegMatchCriteria)
);

endmodule : packet_router_tb