`timescale 1ns/1ps

/*
 * Route packets to queues based on matching criteria.
 */

module packet_router #(
  parameter integer PATH_COUNT = 4,
  parameter integer DATA_WIDTH = 64
)(
  input   wire                                  iClk,
  input   wire                                  iRst,
  input   wire                                  iPktValid,
  input   wire  [DATA_WIDTH-1:0]                iPktData,
  output  wire  [DATA_WIDTH-1:0]                oData,
  output  wire  [PATH_COUNT-1:0]                oDataVld,
  // registers for path matchig criteria
  input   wire  [PATH_COUNT-1:0] [31:0]         iRegMatchCriteria
);


// incoming packet match signal, one hot
reg [PATH_COUNT-1:0] packet_hit;

// incoming fifo mem array PATH_COUNT deep to overtake arbitration delay on the output
reg  [PATH_COUNT-1:0] [DATA_WIDTH-1:0]         mem_fifo0;
reg  [PATH_COUNT-1:0] [DATA_WIDTH-1:0]         mem_fifo1;
reg  [PATH_COUNT-1:0] [DATA_WIDTH-1:0]         mem_fifo2;
reg  [PATH_COUNT-1:0] [DATA_WIDTH-1:0]         mem_fifo3;
reg  [PATH_COUNT-1:0] [$clog2(PATH_COUNT):0]   fifo_size;
reg  [PATH_COUNT-1:0] [$clog2(PATH_COUNT)-1:0] fifo_wr_ptr;
reg  [PATH_COUNT-1:0] [$clog2(PATH_COUNT)-1:0] fifo_rd_ptr;
reg  [PATH_COUNT-1:0]                          fifo_rden;
reg  [PATH_COUNT-1:0]                          fifo_wren;

// control logic for outgoing arbitration logic
reg [$clog2(PATH_COUNT)-1:0]                      fifo_prev_sel;
reg [$clog2(PATH_COUNT)-1:0]                      fifo_sel; // comb logic

// output registers
reg [DATA_WIDTH-1:0]                      dataOut;
reg [PATH_COUNT-1:0]                      dataOutVld;

genvar i;
generate
  for(i = 0; i < PATH_COUNT; i = i + 1) begin
    always @(*) begin
      packet_hit[i] = (iRegMatchCriteria[i][31:28] == iPktData[DATA_WIDTH-1:DATA_WIDTH-4]) ? iPktValid : 1'b0;
      fifo_wren[i]  = (iRegMatchCriteria[i][31:28] == iPktData[DATA_WIDTH-1:DATA_WIDTH-4]) ? iPktValid : 1'b0;
    end
  end
endgenerate

// essentially we need PATH # of fifos/queues why??
// assumption is fifo_size > 0 is qualification for arbitration. 
// one cycle to push to cycle and one cycle to read from fifo
// TODO: Can we write a generate for below FIFOs ... possibly but it depends on the compiler support for SystemVerilog

// FIFO 0 
always @(posedge iClk) begin
  if(iRst) begin
    mem_fifo0[PATH_COUNT-1:0] <= {DATA_WIDTH{1'b0}};
    fifo_size[0]          <= {$clog2(PATH_COUNT){1'b0}};
    fifo_rd_ptr[0]            <= {$clog2(PATH_COUNT){1'b0}};
    fifo_wr_ptr[0]            <= {$clog2(PATH_COUNT){1'b0}};
  end else if(fifo_rden[0] & ~fifo_wren[0]) begin
    // decrease the size and increment the read pointer
    fifo_rd_ptr[0]    <= (fifo_rd_ptr[0] + 1'b1) % PATH_COUNT;
    fifo_size[0]  <= fifo_size[0] - 1'b1;
  end else if(~fifo_rden[0] & fifo_wren[0]) begin
    // increase the size and increment the write pointer
    mem_fifo0[fifo_wr_ptr[0]] <= iPktData;
    fifo_wr_ptr[0]    <= (fifo_wr_ptr[0] + 1'b1) % PATH_COUNT;
    fifo_size[0]  <= fifo_size[0] + 1'b1;
  end else if(fifo_rden[0] & fifo_wren[0]) begin
    // move both pointer but don't increase the size
    mem_fifo0[fifo_wr_ptr[0]] <= iPktData;
    fifo_wr_ptr[0]    <= (fifo_wr_ptr[0] + 1'b1) % PATH_COUNT;
    fifo_rd_ptr[0]    <= (fifo_rd_ptr[0] + 1'b1) % PATH_COUNT;
  end
end

// FIFO 1
always @(posedge iClk) begin
  if(iRst) begin
    mem_fifo1[PATH_COUNT-1:0] <= {DATA_WIDTH{1'b0}};
    fifo_size[1]          <= {$clog2(PATH_COUNT){1'b0}};
    fifo_rd_ptr[1]            <= {$clog2(PATH_COUNT){1'b0}};
    fifo_wr_ptr[1]            <= {$clog2(PATH_COUNT){1'b0}};
  end else if(fifo_rden[1] & ~fifo_wren[1]) begin
    // decrease the size and increment the read pointer
    fifo_rd_ptr[1]    <= (fifo_rd_ptr[1] + 1'b1) % PATH_COUNT;
    fifo_size[1]  <= fifo_size[1] - 1'b1;
  end else if(~fifo_rden[1] & fifo_wren[1]) begin
    // increase the size and increment the write pointer
    mem_fifo1[fifo_wr_ptr[1]] <= iPktData;
    fifo_wr_ptr[1]    <= (fifo_wr_ptr[1] + 1'b1) % PATH_COUNT;
    fifo_size[1]  <= fifo_size[1] + 1'b1;
  end else if(fifo_rden[1] & fifo_wren[1]) begin
    // move both pointer but don't increase the size
    mem_fifo1[fifo_wr_ptr[1]] <= iPktData;
    fifo_wr_ptr[1]    <= (fifo_wr_ptr[1] + 1'b1) % PATH_COUNT;
    fifo_rd_ptr[1]    <= (fifo_rd_ptr[1] + 1'b1) % PATH_COUNT;
  end
end

// FIFO 3
always @(posedge iClk) begin
  if(iRst) begin
    mem_fifo2[PATH_COUNT-1:0] <= {DATA_WIDTH{1'b0}};
    fifo_size[2]          <= {$clog2(PATH_COUNT){1'b0}};
    fifo_rd_ptr[2]            <= {$clog2(PATH_COUNT){1'b0}};
    fifo_wr_ptr[2]            <= {$clog2(PATH_COUNT){1'b0}};
  end else if(fifo_rden[2] & ~fifo_wren[2]) begin
    // decrease the size and increment the read pointer
    fifo_rd_ptr[2]    <= (fifo_rd_ptr[2] + 1'b1) % PATH_COUNT;
    fifo_size[2]  <= fifo_size[2] - 1'b1;
  end else if(~fifo_rden[2] & fifo_wren[2]) begin
    // increase the size and increment the write pointer
    fifo_wr_ptr[2]    <= (fifo_wr_ptr[2] + 1'b1) % PATH_COUNT;
    fifo_size[2]  <= fifo_size[2] + 1'b1;
    mem_fifo2[fifo_wr_ptr[2]] <= iPktData;
  end else if(fifo_rden[2] & fifo_wren[2]) begin
    // move both pointer but don't increase the size
    mem_fifo2[fifo_wr_ptr[2]] <= iPktData;
    fifo_wr_ptr[2]    <= (fifo_wr_ptr[2] + 1'b1) % PATH_COUNT;
    fifo_rd_ptr[2]    <= (fifo_rd_ptr[2] + 1'b1) % PATH_COUNT;
  end
end

// FIFO 4
always @(posedge iClk) begin
  if(iRst) begin
    mem_fifo3[PATH_COUNT-1:0] <= {DATA_WIDTH{1'b0}};
    fifo_size[3]          <= {$clog2(PATH_COUNT){1'b0}};
    fifo_rd_ptr[3]            <= {$clog2(PATH_COUNT){1'b0}};
    fifo_wr_ptr[3]            <= {$clog2(PATH_COUNT){1'b0}};
  end else if(fifo_rden[3] & ~fifo_wren[3]) begin
    // decrease the size and increment the read pointer
    fifo_rd_ptr[3]    <= (fifo_rd_ptr[3] + 1'b1) % PATH_COUNT;
    fifo_size[3]  <= fifo_size[3] - 1'b1;
  end else if(~fifo_rden[3] & fifo_wren[3]) begin
    // increase the size and increment the write pointer
    fifo_wr_ptr[3]    <= (fifo_wr_ptr[3] + 1'b1) % PATH_COUNT;
    fifo_size[3]  <= fifo_size[3] + 1'b1;
    mem_fifo3[fifo_wr_ptr[3]] <= iPktData;
  end else if(fifo_rden[2] & fifo_wren[3]) begin
    // move both pointer but don't increase the size
    mem_fifo3[fifo_wr_ptr[3]] <= iPktData;
    fifo_wr_ptr[3]    <= (fifo_wr_ptr[3] + 1'b1) % PATH_COUNT;
    fifo_rd_ptr[3]    <= (fifo_rd_ptr[3] + 1'b1) % PATH_COUNT;
  end
end

// Arbiter logic for selecting from on of the 4 fifos based on fifo_size > 0
// the arbiter strategy is a simple round robin with look ahead i.e. no delays between selecting the next qualifying request
always @(posedge iClk) begin
  if(iRst) begin
    fifo_prev_sel[PATH_COUNT-1:0] <= {PATH_COUNT{1'b0}};
  end else begin
    // track the previous arb_sel for round robin
    fifo_prev_sel          <= fifo_sel;
  end
end

// select the next fifo to select using fifo_size as the filtering criteria
always @(*) begin
  fifo_sel = (fifo_prev_sel + 1'b1);
  for(integer i = 0; i < PATH_COUNT; i++) begin
    if(fifo_size[fifo_sel] == 0) begin
      fifo_sel = fifo_sel + 1'b1;
    end
  end
end

// generate fifo read 
genvar fifo_idx;
generate
  for(fifo_idx = 0; fifo_idx < PATH_COUNT; fifo_idx++)
    assign fifo_rden[fifo_idx] = (fifo_size[fifo_idx] > 0) && (fifo_sel == fifo_idx) ? 1'b1 : 1'b0;
endgenerate

// output packet logic
always @(posedge iClk) begin
  if(iRst) begin
    dataOut[DATA_WIDTH-1:0] <= {DATA_WIDTH{1'b0}};
    dataOutVld              <= {PATH_COUNT{1'b0}};
  end else begin
    dataOut[DATA_WIDTH-1:0] <= (fifo_sel == 0 ? mem_fifo0[fifo_rd_ptr[0]] : (fifo_sel == 1 ? mem_fifo1[fifo_rd_ptr[1]] : (fifo_sel == 2 ? mem_fifo2[fifo_rd_ptr[2]] : mem_fifo3[fifo_rd_ptr[3]])));
    dataOutVld              <= fifo_rden;
  end
end

// assign outputs
assign oData    = dataOut;
assign oDataVld = dataOutVld;

endmodule : packet_router