`timescale 1ns / 1ps

module tb_aq_axis_fifo;

  reg RST;
  reg WRCLK, RDCLK;

  localparam CLK100M = 10;
  localparam CLK200M = 5;

  localparam FIFO_DEPTH = 4;
  localparam FIFO_WIDTH = 32;

  localparam FIFO_WR_ALM_COUNT = 4;
  localparam FIFO_RD_ALM_COUNT = 2;

  // Clock
  always begin
    #(CLK100M / 2) WRCLK <= ~WRCLK;
  end

  always begin
    #(CLK200M / 2) RDCLK <= ~RDCLK;
  end

  initial begin
    $display("========================================");
    $display("Simulation Start");
    $display("========================================");

    #0;
    RST   = 1;
    WRCLK = 0;
    RDCLK = 0;

    #100;
    RST = 0;
  end

  reg WREN;
  wire AFULL, FULL;
  reg [31:0] DIN;

  reg RDEN;
  wire AEMPTY, EMPTY;
  wire [31:0] DOUT;

  reg ERROR;
  reg [31:0] TEMP;

  integer i, k;

  integer write_end;

  initial begin
    ERROR = 0;
    #0;
    WREN = 0;

    write_end = 0;

    wait (!RST);

    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;

    $display("1st write");

    for (i = 0; i < 20; i = i + 1) begin
      WREN = 1;
      DIN  = 32'h00000000 + i;
      @(posedge WRCLK) #1;
    end

    WREN = 0;
    DIN  = 64'd0;
    @(posedge WRCLK) #1;

    write_end = 1;

    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;

    write_end = 0;

    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;
    @(posedge WRCLK) #1;

    wait (EMPTY);
    wait (!FULL);

    $display("2nd write");

    @(posedge WRCLK) #1;

    for (i = 0; i < 20; i = i + 1) begin
      WREN = 1;
      DIN  = 32'h00000100 + i;
      @(posedge WRCLK) #1;
      if (i == 8) begin
        write_end = 1;
      end
    end

    WREN = 0;
    DIN  = 64'd0;
    @(posedge WRCLK) #1;


  end

  initial begin
    #0;
    RDEN = 0;

    wait (!RST);

    @(posedge RDCLK) #1;

    wait (write_end);

    @(posedge RDCLK) #1;

    $display("1st read");
    for (k = 0; k < 20; k = k + 1) begin
      RDEN = 1;
      TEMP = (32'h00000000 + k);
      if (!EMPTY && (DOUT != TEMP)) begin
        $display("ERROR: %16h:%16h", TEMP, DOUT);
        ERROR = 1;
      end else begin
        ERROR = 0;
      end
      @(posedge RDCLK) #1;
    end

    RDEN = 0;
    @(posedge RDCLK) #1;


    wait (write_end);

    @(posedge RDCLK) #1;

    $display("2nd read");
    k = 0;
    while (k < 16) begin
      if (!EMPTY) begin
        RDEN = 1;
        TEMP = (32'h00000100 + k);
        k = k + 1;
        if (!EMPTY && (DOUT != TEMP)) begin
          $display("ERROR: %16h:%16h", TEMP, DOUT);
          ERROR = 1;
        end else begin
          ERROR = 0;
        end
      end else begin
        ERROR = 0;
        RDEN  = 0;
      end
      @(posedge RDCLK) #1;
    end
    ERROR = 0;

    RDEN  = 0;
    @(posedge RDCLK) #1;



    @(posedge RDCLK) #1;
    @(posedge RDCLK) #1;
    @(posedge RDCLK) #1;
    @(posedge RDCLK) #1;
    @(posedge RDCLK) #1;
    @(posedge RDCLK) #1;
    @(posedge RDCLK) #1;
    @(posedge RDCLK) #1;
    @(posedge RDCLK) #1;
    @(posedge RDCLK) #1;


    $display("========================================");
    $display("Simulation Finish");
    $display("========================================");

    $finish();

  end

  aq_axis_fifo #(
      .FIFO_DEPTH(FIFO_DEPTH),
      .FIFO_WIDTH(FIFO_WIDTH)
  ) u_aq_axis_fifo (
      .RST_N(~RST),

      .S_AXIS_ACLK  (WRCLK),
      .S_AXIS_TVALID(WREN),
      .S_AXIS_TREADY(),
      .S_AXIS_TLAST (1'b1),
      .S_AXIS_TDATA (DIN),

      .FIFO_WR_FULL     (FULL),
      .FIFO_WR_ALM_FULL (AFULL),
      .FIFO_WR_ALM_COUNT(FIFO_WR_ALM_COUNT),

      .M_AXIS_ACLK  (RDCLK),
      .M_AXIS_TVALID(),
      .M_AXIS_TREADY(RDEN),
      .M_AXIS_TDATA (DOUT),

      .FIFO_RD_EMPTY    (EMPTY),
      .FIFO_RD_ALM_EMPTY(AEMPTY),
      .FIFO_RD_ALM_COUNT(FIFO_RD_ALM_COUNT)
  );

endmodule
