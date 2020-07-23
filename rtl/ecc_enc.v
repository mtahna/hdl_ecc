module ecc_enc (
    input  wire                  clk       , // clock
    input  wire                  rstn      , // reset
    input  wire [63:0]           data_in   , // data input
    output reg  [63:0]           data_out  , // data output
    output reg  [ 7:0]           ecc_out     // ecc output
);

localparam DATA_WIDTH   = 64 ;
localparam ECC_WIDTH    = 8  ;
localparam DATAECC_WIDTH = DATA_WIDTH + ECC_WIDTH;
localparam PARITY_WIDTH = ECC_WIDTH - 1;

wire [DATAECC_WIDTH-1:0]              bitmap      ;
wire [PARITY_WIDTH*DATAECC_WIDTH-1:0] mask        ;
wire [PARITY_WIDTH -1:0]              even_parity ;
wire                                  secded      ;

//         0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21
//            p0  p1  d0  p2  d1  d2  d3  p3  d4  d5  d6  d7  d8  d9 d10  p4 d11 d12 d13 d14 d15
// secded      x   x   x   x   x   x   x   x   x   x   x   x   x   x   x   x   x   x   x   x   x
// p0          x       x       x       x       x       x       x       x   x   x   x   x   x   x
// p1              x   x           x   x           x   x           x   x   x   x   x   x   x   x
// p2                      x   x   x   x                   x   x   x   x   x   x   x   x   x   x
// p3                                      x   x   x   x   x   x   x   x   x   x   x   x   x   x
// p4                                                                      x   x   x   x   x   x

assign bitmap[    0] = 1'b0          ; // dummy
assign bitmap[    1] = 1'b0          ; // dummy P0
assign bitmap[    2] = 1'b0          ; // dummy P1
assign bitmap[    3] = data_in[    0];
assign bitmap[    4] = 1'b0          ; // dummy P2
assign bitmap[ 7: 5] = data_in[ 3: 1];
assign bitmap[    8] = 1'b0          ; // dummy P3
assign bitmap[15: 9] = data_in[10: 4];
assign bitmap[   16] = 1'b0          ; // dummy P4
assign bitmap[31:17] = data_in[25:11];
assign bitmap[   32] = 1'b0          ; // dummy P5
assign bitmap[63:33] = data_in[56:26];
assign bitmap[   64] = 1'b0          ; // dummy P6
assign bitmap[DATAECC_WIDTH-1:65] = data_in[DATA_WIDTH-1:57];

generate
    genvar v_pa, v_dt;
    for(v_pa=0; v_pa<PARITY_WIDTH; v_pa=v_pa+1) begin : g_pa_mask
        for(v_dt=0; v_dt<DATAECC_WIDTH; v_dt=v_dt+1) begin : g_dt_mask
            assign mask[v_pa*DATAECC_WIDTH + v_dt] = ((v_dt % (2**(v_pa+1))) >=  (2**(v_pa))) ? 1'b1 : 1'b0 ;
        end
    end
    for(v_pa=0; v_pa<PARITY_WIDTH; v_pa=v_pa+1) begin : g_parity
        assign even_parity[v_pa] = ^(bitmap & mask[(v_pa+1)*DATAECC_WIDTH-1:v_pa*DATAECC_WIDTH]);
    end
endgenerate

assign secded = (^data_in) ^ (^even_parity);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        data_out <= {DATA_WIDTH{1'b0}};
        ecc_out  <= {ECC_WIDTH{1'b0}};
    end else begin
        data_out <= data_in;
        ecc_out  <= {secded, even_parity};
    end
end


endmodule