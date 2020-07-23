`timescale 1ns/1ps
module tb ();

localparam DATA_WIDTH = 64       ;
localparam ECC_WIDTH = 8         ;

logic                  clk        ; // clock
logic                  rstn       ; // reset
logic [DATA_WIDTH-1:0] data_in    ; // data input
logic [DATA_WIDTH-1:0] enc_out    ; // data input
logic [ECC_WIDTH -1:0] ecc        ; // data input
logic [DATA_WIDTH-1:0] data_out   ; // data output
logic [           1:0] err_sts_out; // data output

ecc_enc u_ecc_enc (
    .clk         (clk          ), // input  wire                  clock
    .rstn        (rstn         ), // input  wire                  reset
    .data_in     (data_in      ), // input  wire [63:0]           data input
    .data_out    (enc_out      ), // output reg  [63:0]           data output
    .ecc_out     (ecc          )  // output reg  [ 7:0]           ecc output
);

ecc_dec u_ecc_dec (
    .clk         (clk          ), // input  wire                  clock
    .rstn        (rstn         ), // input  wire                  reset
    .data_in     (enc_out      ), // input  wire [63:0]           data input
    .ecc_in      (ecc          ), // input  wire [ 7:0]           ecc input
    .data_out    (data_out     ), // output reg  [63:0]           data output
    .err_sts_out (err_sts_out  )  // output reg  [ 1:0]           err status
);


initial begin
    clk = 1;
    forever #1000 clk = ~clk;
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        data_out <= {DATA_WIDTH{1'b0}};
    end else begin
        $display("RDATA=%8x.",data_out);
    end
end

initial begin
    rstn = 0; data_in = {64{1'b0}};
    repeat(10) @(posedge clk);
    rstn = 1;
    repeat(10) @(posedge clk);

    @(posedge clk); #1; data_in = 64'h0000FFFF0000FFFF;
    @(posedge clk); #1; data_in = 64'h0000000000000000;
    @(posedge clk); #1; 
    @(posedge clk); #1; 

    @(posedge clk); #1; data_in = 64'hFFFF0000FFFF0000;
    @(posedge clk); #1; data_in = 64'h0000000000000000;
    @(posedge clk); #1; 
    @(posedge clk); #1; 

    @(posedge clk); #1; data_in = 64'h5555555555555555; 
    @(posedge clk); #1; data_in = 64'h0000000000000000; force enc_out[17] = ~enc_out[17];
    @(posedge clk); #1;                                 release enc_out[17];
    @(posedge clk); #1; 

    @(posedge clk); #1; data_in = 64'h0000FFFF0000FFFF; 
    @(posedge clk); #1; data_in = 64'h0000000000000000; force enc_out[34] = ~enc_out[34];
    @(posedge clk); #1;                                 release enc_out[34];
    @(posedge clk); #1; 

    @(posedge clk); #1; data_in = 64'hAAAAAAAAAAAAAAAA;
    @(posedge clk); #1; data_in = 64'h0000000000000000; force enc_out[56] = ~enc_out[56];
    @(posedge clk); #1;                                 release enc_out[56];
    @(posedge clk); #1; 

    @(posedge clk); #1; data_in = 64'hFFFF0000FFFF0000; 
    @(posedge clk); #1; data_in = 64'h0000000000000000; force ecc[4] = ~ecc[4];
    @(posedge clk); #1;                                 release ecc[4];
    @(posedge clk); #1; 

    @(posedge clk); #1; data_in = 64'hAAAAAAAAAAAAAAAA; 
    @(posedge clk); #1; data_in = 64'h0000000000000000; force enc_out[24] = ~enc_out[24]; force enc_out[60] = ~enc_out[60];
    @(posedge clk); #1;                                 release enc_out[24];              release enc_out[60];
    @(posedge clk); #1; 

    @(posedge clk); #1; data_in = 64'h5555555555555555; 
    @(posedge clk); #1; data_in = 64'h0000000000000000; force enc_out[ 9] = ~enc_out[ 9]; force enc_out[48] = ~enc_out[48];
    @(posedge clk); #1;                                 release enc_out[ 9];              release enc_out[48];
    @(posedge clk); #1; 

    @(posedge clk); #1; data_in = 64'h0000FFFF0000FFFF;
    @(posedge clk); #1; data_in = 64'h0000000000000000; 
    @(posedge clk); #1; 
    @(posedge clk); #1; 

    @(posedge clk); #1; data_in = 64'hFFFF0000FFFF0000;
    @(posedge clk); #1; data_in = 64'h0000000000000000; 
    @(posedge clk); #1; 
    @(posedge clk); #1; 

    repeat(10) @(posedge clk);
    $finish;
end

endmodule