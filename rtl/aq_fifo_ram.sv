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

module aq_fifo_ram #(
    parameter DEPTH = 8,
    parameter WIDTH = 32
) (
    // Write Interface
    input  wire              WR_CLK,
    input  wire              WR_ENA,
    input  wire [DEPTH -1:0] WR_ADRS,
    input  wire [WIDTH -1:0] WR_DATA,
    // Read Interface
    input  wire              RD_CLK,
    input  wire [DEPTH -1:0] RD_ADRS,
    output wire [WIDTH -1:0] RD_DATA
);
  reg [WIDTH -1:0]    ram [0:(2**DEPTH) -1];
  reg [WIDTH -1:0]    rd_reg;

  always @(posedge WR_CLK) begin
    if (WR_ENA) ram[WR_ADRS] <= WR_DATA;
  end

  always @(posedge RD_CLK) begin
    rd_reg <= ram[RD_ADRS];
  end

  assign RD_DATA = rd_reg;
endmodule

`default_nettype wire
