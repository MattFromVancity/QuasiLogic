module sync_fifo #(
  parameter integer ENTRIES      = 20,
  parameter integer ENTRIES_LOG2 = $clog2(ENTRIES), 
  parameter integer DATA_WIDTH   = 64
) (
  input  wire                   i_clk,
  input  wire                   i_rstn,
  input  wire                   i_wren,
  input  wire                   i_rden,
  input  wire [DATA_WIDTH-1:0]  i_data,
  output wire                   o_data_vld,
  output wire [DATA_WIDTH-1:0]  o_data,
  output wire                   o_overflow,
  output wire                   o_underflow
);

// internal storage element and count
reg [ENTRIES] [DATA_WIDTH-1:0] mem_blk;
reg [ENTRIES_LOG2-1:0]                  size;

// read pointer
reg [ENTRIES_LOG2-1:0] wr_ptr;

// write pointer
reg [ENTRIES_LOG2-1:0] rd_ptr;

// internal signals to reduce fanout on output
wire int_overflow;
wire int_underflow;

// output buffer
reg [DATA_WIDTH-1:0] int_o_data;
reg                  int_data_vld;


// Design Considerations 
// 1. Read Collision (wr_ptr == rd_ptr) & i_wren & i_rden
// 2. Underflow (rd_ptr == wr_ptr ) & i_rden
// 3. Overflow  (rd_ptr == wr_ptr) & i_wren
// 4. Latency of internal storage mechanism FLOPS, (BRAM), SRAM all depends on the applicaiton

// Current implementation maintains a size count, can we decouple the RTL from just relying on pointer positions?
// By definition a FIFO has zero size when wr_ptr == rd_ptr and that if wr_ptr is always ahead of rd_ptr

always @(posedge i_clk) begin
  if(!i_rstn) begin
    mem_blk[ENTRIES_LOG2-1:0] <= {DATA_WIDTH{1'b0}};
    size                      <= {ENTRIES_LOG2{1'b0}};
    wr_ptr                    <= {ENTRIES_LOG2{1'b0}};
    rd_ptr                    <= {ENTRIES_LOG2{1'b0}};
    int_o_data                <= {DATA_WIDTH{1'b0}};
    int_data_vld              <= 1'b0;
  // regular (wr_ptr >= read_ptr)
  end else if(~int_overflow & i_wren & ~i_rden) begin
    size <= size + 1'b1;
    mem_blk[wr_ptr] <= i_data;
    wr_ptr <= (wr_ptr + 1'b1) % ENTRIES;
    int_data_vld <= 1'b0;
  // regular read (rd_ptr < wr_ptr)
  end else if(~int_underflow & ~i_wren & i_rden) begin
    size <= size - 1'b1;
    int_o_data <= mem_blk[rd_ptr];
    rd_ptr <= (rd_ptr + 1'b1) % ENTRIES;
    int_data_vld <= 1'b1;
  // read and write in same cycle (direct path)
  end else if(i_wren & i_rden & ~|size) begin
    int_o_data <= i_data;
    int_data_vld <= 1'b1;
  // read and write in same cycle (direct path)
  end else if(i_wren & i_rden & |size) begin
    mem_blk[wr_ptr] <= i_data;
    int_o_data <= mem_blk[rd_ptr];
    int_data_vld <= 1'b1;
    wr_ptr <= wr_ptr + 1'b1;
    rd_ptr <= rd_ptr + 1'b1;
  end else begin
    int_data_vld <= 1'b0;
  end
end

// fault conditions
assign int_overflow  = (rd_ptr == wr_ptr) & |size;
assign int_underflow = (rd_ptr == wr_ptr) & ~|size;

// fault conditions on the output
assign o_overflow   = int_overflow;
assign o_underflow  = int_underflow;

// data out and valid
assign o_data       = int_o_data;
assign o_data_vld   = int_data_vld & ~int_underflow;

endmodule