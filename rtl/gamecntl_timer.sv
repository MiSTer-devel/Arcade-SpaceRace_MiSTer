/*
 * Playtime and Fuel bar timer (C9 and D9)
 */
module gamecntl_timer(
  input  logic       CLK_DRV,
  input  logic       RST_C9_N,
  input  logic [3:0] PLAYTIME,  // 0: 0%,  1: 10%, 2: 20%, 3: 30%, 4: 40%, 5: 50%,
                                // 6: 60%, 7: 70%, 8: 80%, 9: 90%, 10: 100%
  input  logic       TRG_C9_N,
  input  logic       TRG_D9_N,
  output logic       C9_OUT,
  output logic       D9_OUT
);
  // ---------------------------------------------------------------------------
  // C9 count value for each PLAYTIME setting
  // ---------------------------------------------------------------------------
  logic [13:0] counts_C9;
  always_comb begin
    case (PLAYTIME)
      4'd0:  counts_C9 = 13'd2567; // 45 s
      4'd1:  counts_C9 = 13'd3113; // 60 s
      4'd2:  counts_C9 = 13'd3659; // 75 s
      4'd3:  counts_C9 = 13'd4205; // 90 s
      4'd4:  counts_C9 = 13'd4752; // 105 s
      4'd5:  counts_C9 = 13'd5298; // 120 s
      4'd6:  counts_C9 = 13'd5844; // 135 s
      4'd7:  counts_C9 = 13'd6390; // 150 s
      4'd8:  counts_C9 = 13'd6937; // 165 s
      4'd9:  counts_C9 = 13'd7483; // 180 s
      4'd10: counts_C9 = 13'd8029; // 195 s
      default: counts_C9 = 12'd5298; // 120 s
    endcase
  end

  // To simplify, generate count enable signal of 1 second
  logic [19:0] div;
  logic        en_1sec;
  always_ff @(posedge CLK_DRV) begin
    div <= div + 1'd1;
  end
  assign cnt_en = div == 0;

    state_t state_C9;
  state_t state_D9;


  oneshot_555_var #(
    .BW(13)
  ) oneshot_555_C9 (
    .CLK(CLK_DRV),
    .RST_N(RST_N),
    .COUNTS(counts),
    .COUNT_EN(cnt_en),
    .TRG_N(TRG_N),
    .OUT(OUT)
  );

endmodule
