`default_nettype wire

module fifo_wrapper #(
    parameter FIFO_DEPTH = 8,
    parameter FIFO_WIDTH = 32
) (
    input  wire                  RST_N,
    input  wire                  FIFO_WR_CLK,
    input  wire                  FIFO_WR_ENA,
    input  wire [FIFO_WIDTH-1:0] FIFO_WR_DATA,
    input  wire                  FIFO_WR_LAST,
    output wire                  FIFO_WR_FULL,
    output wire                  FIFO_WR_ALM_FULL,
    input  wire                  FIFO_RD_CLK,
    input  wire                  FIFO_RD_ENA,
    output wire [FIFO_WIDTH-1:0] FIFO_RD_DATA,
    output wire                  FIFO_RD_EMPTY,
    output wire                  FIFO_RD_ALM_EMPTY
);

  aq_axis_fifo #(
      .FIFO_DEPTH(FIFO_DEPTH),
      .FIFO_WIDTH(FIFO_WIDTH)
  ) u_aq_axis_fifo (
      .RST_N(RST_N),

      .S_AXIS_ACLK  (FIFO_WR_CLK),
      .S_AXIS_TVALID(FIFO_WR_ENA),
      .S_AXIS_TREADY(),
      .S_AXIS_TLAST (FIFO_WR_LAST),
      .S_AXIS_TDATA (FIFO_WR_DATA),

      .FIFO_WR_FULL(FIFO_WR_FULL),
      .FIFO_WR_ALM_FULL(FIFO_WR_ALM_FULL),
      .FIFO_WR_ALM_COUNT(1),

      .M_AXIS_ACLK  (FIFO_RD_CLK),
      .M_AXIS_TVALID(),
      .M_AXIS_TREADY(FIFO_RD_ENA),
      .M_AXIS_TDATA (FIFO_RD_DATA),

      .FIFO_RD_EMPTY(FIFO_RD_EMPTY),
      .FIFO_RD_ALM_EMPTY(FIFO_RD_ALM_EMPTY),
      .FIFO_RD_ALM_COUNT()
  );

endmodule

`default_nettype none
