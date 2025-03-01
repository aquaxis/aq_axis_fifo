/*
 * Don't remove this header.
 * When you use this source, there is a need to inherit this header.
 *
 * Copyright (C)2007-2025 AQUAXIS TECHNOLOGY.
 *
 * License: MIT License
 *
 * For further information please contact.
 *  URI:    http://www.aquaxis.com/
 *  E-Mail: info(at)aquaxis.com
 */
`default_nettype none

module aq_axis_fifo #(
    parameter FIFO_DEPTH = 8,
    parameter FIFO_WIDTH = 32
) (
    // System
    input  wire                   RST_N,
    // AXIS Slave Interface(FIFO Write Interface)
    input  wire                   S_AXIS_ACLK,
    input  wire                   S_AXIS_TVALID,
    output wire                   S_AXIS_TREADY,
    input  wire                   S_AXIS_TLAST,
    input  wire [FIFO_WIDTH -1:0] S_AXIS_TDATA,
    // FIFO Write Status
    output wire                   FIFO_WR_FULL,
    output wire                   FIFO_WR_ALM_FULL,
    input  wire [FIFO_DEPTH -1:0] FIFO_WR_ALM_COUNT,
    // AXIS Master Interface(FIFO Read Interface)
    input  wire                   M_AXIS_ACLK,
    output wire                   M_AXIS_TVALID,
    input  wire                   M_AXIS_TREADY,
    output wire [FIFO_WIDTH -1:0] M_AXIS_TDATA,
    // FIFO Read Status
    output wire                   FIFO_RD_EMPTY,
    output wire                   FIFO_RD_ALM_EMPTY,
    input  wire [FIFO_DEPTH -1:0] FIFO_RD_ALM_COUNT
);

  reg [1:0] reg_wr_rst_n, reg_rd_rst_n;
  wire wr_rst_n, rd_rst_n;

  always @(posedge S_AXIS_ACLK) begin
    reg_wr_rst_n <= {reg_wr_rst_n[0], RST_N};
  end
  assign wr_rst_n = reg_wr_rst_n[1];

  always @(posedge M_AXIS_ACLK) begin
    reg_rd_rst_n <= {reg_rd_rst_n[0], RST_N};
  end
  assign rd_rst_n = reg_rd_rst_n[1];

  wire wr_ena, wr_full;
  reg wr_ena_req_pre, wr_ena_req;
  reg                    wr_rd_ena;
  reg  [            2:0] wr_rd_ena_d;
  wire                   wr_rd_ena_ack;
  reg  [FIFO_DEPTH -1:0] wr_adrs;
  reg [FIFO_DEPTH : 0] wr_count, wr_alm_count, wr_count_req_pre, wr_count_req, wr_rd_count;

  wire rd_ena, rd_empty;
  reg rd_ena_d;
  reg rd_ena_req_pre, rd_ena_req;
  reg                    rd_wr_ena;
  reg  [            2:0] rd_wr_ena_d;
  wire                   rd_wr_ena_ack;
  reg  [FIFO_DEPTH -1:0] rd_adrs;
  reg [FIFO_DEPTH : 0] rd_count, rd_alm_count, rd_count_req_pre, rd_count_req, rd_wr_count;

  wire                   rsv_ena;
  reg                    rsv_empty;
  reg  [FIFO_WIDTH -1:0] rsv_data;

  wire [FIFO_WIDTH -1:0] rd_fifo;

  /////////////////////////////////////////////////////////////////////
  // Write Block
  assign wr_full = wr_count[FIFO_DEPTH];
  assign wr_ena  = (!wr_full) ? (S_AXIS_TVALID) : 1'b0;

  // Write Address
  always @(posedge S_AXIS_ACLK) begin
    if (!wr_rst_n) begin
      wr_adrs <= 0;
    end else begin
      if (wr_ena) wr_adrs <= wr_adrs + 1;
    end
  end

  // make a full and almost full signal
  always @(posedge S_AXIS_ACLK) begin
    if (!wr_rst_n) begin
      wr_count     <= 0;
      wr_alm_count <= 0;
    end else begin
      if (wr_ena) begin
        if (wr_rd_ena) begin
          wr_count <= wr_count - wr_rd_count + 1;
        end else begin
          wr_count <= wr_count + 1;
        end
      end else if (wr_rd_ena) begin
        wr_count <= wr_count - wr_rd_count;
      end
      wr_alm_count <= wr_count + {1'b0, FIFO_WR_ALM_COUNT} + 1;
    end
  end

  // Read Control signal from Read Block
  always @(posedge S_AXIS_ACLK) begin
    if (!wr_rst_n) begin
      wr_rd_count      <= {(FIFO_DEPTH + 1) {1'b0}};
      wr_rd_ena_d[2:0] <= 3'd0;
      wr_rd_ena        <= 1'b0;
    end else begin
      wr_rd_ena_d[2:0] <= {wr_rd_ena_d[1:0], rd_ena_req};
      if (wr_rd_ena_d[2:1] == 2'b01) begin
        wr_rd_ena   <= 1'b1;
        wr_rd_count <= rd_count_req;
      end else begin
        wr_rd_ena <= 1'b0;
      end
    end
  end
  assign wr_rd_ena_ack = wr_rd_ena_d[2] & wr_rd_ena_d[1];

  // Send a write enable signal for Read Block
  reg [2:0] wr_rd_ack_d;
  always @(posedge S_AXIS_ACLK) begin
    if (!wr_rst_n) begin
      wr_ena_req_pre   <= 1'b0;
      wr_ena_req       <= 1'b0;
      wr_count_req_pre <= 0;
      wr_count_req     <= 0;
      wr_rd_ack_d      <= 3'd0;
    end else begin
      wr_rd_ack_d[2:0] <= {wr_rd_ack_d[1:0], rd_wr_ena_ack};
      if (wr_ena & S_AXIS_TLAST) begin
        wr_ena_req_pre <= 1'b1;
      end else if (~wr_ena_req & (wr_rd_ack_d[2:1] == 2'b00)) begin
        wr_ena_req_pre <= 1'b0;
      end
      if (~wr_ena_req & wr_ena_req_pre & (wr_rd_ack_d[2:1] == 2'b00)) begin
        if (wr_ena) begin
          wr_count_req_pre <= 1;
        end else begin
          wr_count_req_pre <= 0;
        end
      end else if (wr_ena) begin
        wr_count_req_pre <= wr_count_req_pre + 1;
      end
      if (~wr_ena_req & wr_ena_req_pre & (wr_rd_ack_d[2:1] == 2'b00)) begin
        wr_ena_req   <= 1'b1;
        wr_count_req <= wr_count_req_pre;
      end else if (wr_rd_ack_d[2:1] == 2'b01) begin
        wr_ena_req <= 1'b0;
      end
    end
  end

  // output signals
  assign S_AXIS_TREADY    = ~wr_count[FIFO_DEPTH];
  assign FIFO_WR_FULL     = wr_count[FIFO_DEPTH];
  assign FIFO_WR_ALM_FULL = wr_alm_count[FIFO_DEPTH];

  /////////////////////////////////////////////////////////////////////
  // Read Block
  assign rd_empty         = (rd_count == 0) ? 1'b1 : 1'b0;
  assign rsv_ena          = rsv_empty & ~rd_empty;
  assign rd_ena           = rsv_ena | (M_AXIS_TREADY & ~rd_empty);

  // Read Address
  always @(posedge M_AXIS_ACLK) begin
    if (!rd_rst_n) begin
      rd_adrs <= 0;
    end else begin
      if (rd_ena) begin
        rd_adrs <= rd_adrs + 1;
      end
    end
  end

  // make a empty and almost empty signal
  always @(posedge M_AXIS_ACLK) begin
    if (!rd_rst_n) begin
      rd_count     <= 0;
      rd_alm_count <= 0;
    end else begin
      if (rd_ena) begin
        if (rd_wr_ena) begin
          rd_count <= rd_count + rd_wr_count - 1;
        end else begin
          rd_count <= rd_count - 1;
        end
      end else if (rd_wr_ena) begin
        rd_count <= rd_count + rd_wr_count;
      end
      rd_alm_count <= rd_count - {1'b0, FIFO_RD_ALM_COUNT} - 1;
    end
  end

  // Write Control signal from Write Block
  always @(posedge M_AXIS_ACLK) begin
    if (!rd_rst_n) begin
      rd_wr_ena_d[2:0] <= 3'd0;
      rd_wr_count      <= {(FIFO_DEPTH + 1) {1'b0}};
      rd_wr_ena        <= 1'b0;
    end else begin
      rd_wr_ena_d[2:0] <= {rd_wr_ena_d[1:0], wr_ena_req};
      if (rd_wr_ena_d[2:1] == 2'b01) begin
        rd_wr_ena   <= 1'b1;
        rd_wr_count <= wr_count_req;
      end else begin
        rd_wr_ena <= 1'b0;
      end
    end
  end

  // Write enable signal from write block
  assign rd_wr_ena_ack = rd_wr_ena_d[2] & rd_wr_ena_d[1];

  // Send a read enable signal for Write Block
  reg [2:0] rd_wr_ack_d;
  always @(posedge M_AXIS_ACLK) begin
    if (!rd_rst_n) begin
      rd_ena_req_pre   <= 1'b0;
      rd_ena_req       <= 1'b0;
      rd_count_req     <= {(FIFO_DEPTH + 1) {1'b0}};
      rd_count_req_pre <= {(FIFO_DEPTH + 1) {1'b0}};
      rd_wr_ack_d[2:0] <= 3'd0;
    end else begin
      rd_wr_ack_d[2:0] <= {rd_wr_ack_d[1:0], wr_rd_ena_ack};
      if (rd_ena) begin
        rd_ena_req_pre <= 1'b1;
      end else if (~rd_ena_req & (rd_wr_ack_d[2:1] == 2'd00)) begin
        rd_ena_req_pre <= 1'b0;
      end
      if (~rd_ena_req & rd_ena_req_pre & (rd_wr_ack_d[2:1] == 2'd00)) begin
        if (rd_ena) begin
          rd_count_req_pre <= 1;
        end else begin
          rd_count_req_pre <= 0;
        end
      end else if (rd_ena) begin
        rd_count_req_pre <= rd_count_req_pre + 1;
      end
      if (~rd_ena_req & rd_ena_req_pre & (rd_wr_ack_d[2:1] == 2'd00)) begin
        rd_ena_req   <= 1'b1;
        rd_count_req <= rd_count_req_pre;
      end else if (rd_wr_ack_d[2:1] == 2'b01) begin
        rd_ena_req <= 1'b0;
      end
    end
  end

  /////////////////////////////////////////////////////////////////////
  // Resetve Block
  always @(posedge M_AXIS_ACLK) begin
    if (!rd_rst_n) begin
      rsv_empty <= 1'b1;
    end else begin
      rd_ena_d <= M_AXIS_TREADY;
      if (rd_ena | rd_ena_d) begin
        rsv_data <= rd_fifo;
      end

      if (M_AXIS_TREADY & rd_empty) begin
        rsv_empty <= 1'b1;
      end else if (rd_ena) begin
        rsv_empty <= 1'b0;
      end
    end
  end

  // output signals
  assign M_AXIS_TVALID     = ~rsv_empty;
  assign M_AXIS_TDATA      = (rd_ena_d) ? rd_fifo : rsv_data;
  assign FIFO_RD_EMPTY     = rsv_empty;
  assign FIFO_RD_ALM_EMPTY = rd_alm_count[FIFO_DEPTH];

  /////////////////////////////////////////////////////////////////////
  // RAM
  aq_fifo_ram #(
      .DEPTH(FIFO_DEPTH),
      .WIDTH(FIFO_WIDTH)
  ) u_aq_axis_fifo_ram (
      .WR_CLK (S_AXIS_ACLK),
      .WR_ENA (wr_ena),
      .WR_ADRS(wr_adrs),
      .WR_DATA(S_AXIS_TDATA),

      .RD_CLK (M_AXIS_ACLK),
      .RD_ADRS(rd_adrs),
      .RD_DATA(rd_fifo)
  );

endmodule

`default_nettype wire
