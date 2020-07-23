module ecc_dec (
    input  wire                  clk         , // clock
    input  wire                  rstn        , // reset
    input  wire [63:0]           data_in     , // data input
    input  wire [ 7:0]           ecc_in      , // ecc input
    output reg  [63:0]           data_out    , // data output
    output reg  [ 1:0]           err_sts_out   // err status
);

localparam DATA_WIDTH   = 64 ;
localparam ECC_WIDTH    = 8  ;
localparam DATAECC_WIDTH = DATA_WIDTH + ECC_WIDTH;
localparam PARITY_WIDTH = ECC_WIDTH - 1;

reg  [DATA_WIDTH   -1:0] data_in_1t     ;
reg  [ECC_WIDTH    -1:0] ecc_in_1t      ;
reg                      secded         ;
wire [ECC_WIDTH    -1:0] ecc_enc_out    ;
wire [PARITY_WIDTH -1:0] correct_bitnum ;
wire                     single_biterr  ; 
wire [DATAECC_WIDTH-1:0] ecc_bitmap     ;
wire [DATAECC_WIDTH-1:0] correct_bitmap ;
wire [DATA_WIDTH   -1:0] correct_data   ; 
wire                     ecc_biterr     ; 
wire [1:0]               err_sts        ;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        data_in_1t <= {DATA_WIDTH{1'b0}};
        ecc_in_1t  <= {ECC_WIDTH{1'b0}};
        secded     <= 1'b0;
    end else begin
        data_in_1t <= data_in;
        ecc_in_1t  <= ecc_in;
        secded     <= (^ data_in) ^ (^ ecc_in[6:0]);
    end
end

ecc_enc u_ecc_enc (
    .clk       (clk          ), // input  wire                  clock
    .rstn      (rstn         ), // input  wire                  reset
    .data_in   (data_in      ), // input  wire [63:0]           data input
    .data_out  (/* open */   ), // output reg  [63:0]           data output
    .ecc_out   (ecc_enc_out  )  // output reg  [ 7:0]           ecc output
);

assign correct_bitnum = ecc_in_1t[6:0] ^ ecc_enc_out[6:0];
assign single_biterr  = ecc_in_1t[7] ^ secded;

assign ecc_bitmap[    0] = 1'b0             ; // dummy
assign ecc_bitmap[    1] = ecc_in_1t[0]     ; // P0
assign ecc_bitmap[    2] = ecc_in_1t[1]     ; // P1
assign ecc_bitmap[    3] = data_in_1t[    0];
assign ecc_bitmap[    4] = ecc_in_1t[2]     ; // P2
assign ecc_bitmap[ 7: 5] = data_in_1t[ 3: 1];
assign ecc_bitmap[    8] = ecc_in_1t[3]     ; // P3
assign ecc_bitmap[15: 9] = data_in_1t[10: 4];
assign ecc_bitmap[   16] = ecc_in_1t[4]     ; // P4
assign ecc_bitmap[31:17] = data_in_1t[25:11];
assign ecc_bitmap[   32] = ecc_in_1t[5]     ; // P5
assign ecc_bitmap[63:33] = data_in_1t[56:26];
assign ecc_bitmap[   64] = ecc_in_1t[6]     ; // P6
assign ecc_bitmap[DATAECC_WIDTH-1:65] = data_in_1t[DATA_WIDTH-1:57];

generate
    genvar v_bm;
    for(v_bm=0; v_bm<DATAECC_WIDTH; v_bm=v_bm+1) begin : g_correct_bitmap
        assign correct_bitmap[v_bm] = (correct_bitnum == v_bm) ? ~ecc_bitmap[v_bm] : ecc_bitmap[v_bm];
    end
endgenerate

assign correct_data[    0] = correct_bitmap[    3];
assign correct_data[ 3: 1] = correct_bitmap[ 7: 5];
assign correct_data[10: 4] = correct_bitmap[15: 9];
assign correct_data[25:11] = correct_bitmap[31:17];
assign correct_data[56:26] = correct_bitmap[63:33];
assign correct_data[DATA_WIDTH-1:57] = correct_bitmap[DATAECC_WIDTH-1:65];

assign ecc_biterr = (correct_bitnum ==  7'd1)
                  | (correct_bitnum ==  7'd2)
                  | (correct_bitnum ==  7'd4)
                  | (correct_bitnum ==  7'd8)
                  | (correct_bitnum == 7'd16)
                  | (correct_bitnum == 7'd32)
                  | (correct_bitnum == 7'd64);

assign err_sts = ( {single_biterr, correct_bitnum} == {1'b0, {7{1'b0}}} ) ? 2'b00 : // No Error
                 ( {single_biterr, ecc_biterr} == {1'b1, 1'b0}          ) ? 2'b01 : // Single Bit Error (Data Collect)
                 ( {single_biterr, ecc_biterr} == {1'b1, 1'b1}          ) ? 2'b10 : // Ecc Data Error (No Collect)
                                                                            2'b11 ; // Multi Bit Error

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        data_out    <= {DATA_WIDTH{1'b0}};
        err_sts_out <= {2{1'b0}};
    end else begin
        data_out    <= (err_sts == 2'b01) ? correct_data : data_in_1t;
        err_sts_out <= err_sts;
    end
end


endmodule