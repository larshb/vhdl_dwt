`timescale 1ns / 1ps

module axis_dwt2_tb;

parameter PERIOD = 10;
parameter WIDTH = 16;
parameter NUMEL = 128; // One dimension

reg  CLK = 0, RST = 1, valid_i = 0, rdy_o = 0;
reg  signed [WIDTH-1:0] din;
wire valid_o, rdy_i, last;
wire signed [WIDTH-1:0] dout;

axis_dwt2 /*#(WIDTH,NUMEL)*/ axis_dwt2_dut(
    .aclk(CLK),
    .aresetn(RST),
    .s00_axis_tvalid(valid_i),
    .m00_axis_tvalid(valid_o),
    .s00_axis_tready(rdy_i),
    .m00_axis_tready(rdy_o),
    .s00_axis_tdata(din),
    .m00_axis_tdata(dout),
    .m00_axis_tlast(last));

// Clock generator
always #(PERIOD/2) CLK = ~CLK;

integer input_file,
        golden_file,
        count,
        errors = 0;
reg signed [WIDTH-1:0] golden_dout = 0;
reg input_read=0, golden_read = 1;
integer current_cycle = 0, cycles = 2;

initial begin
  // Input data file
  input_file = $fopen("raw.dat", "r");
  if (input_file == 0) begin
    $display("input_file handle was NULL");
    $finish;
  end
  
  // Golden data file (Expected output)
  golden_file = $fopen("dwt2.dat", "r");
  if (golden_file == 0) begin
    $display("golden_file handle was NULL");
    $finish;
  end
  
  // Control signals
  #13 RST <= 0;
  input_read <= 1;
  current_cycle <= 1;
end

always @(posedge CLK) begin
  // Feed data
  if (input_read==1) begin
    count = $fscanf(input_file, "%d\n", din);
    valid_i = 1;
    if ($feof(input_file)) begin
      $fclose(input_file);
      rdy_o <= 1;
      input_read <= 0;
    end
  end
  else begin
    valid_i = 0;
  end
  
  // Validate output
  if (golden_read==1 && valid_o==1) begin
    count = $fscanf(golden_file, "%d\n", golden_dout);
    
    if (golden_dout != dout) begin
      errors = errors+1;
      if (errors < 10) $display($time,,,"Expected: %d\t Read: %d",
        golden_dout, dout);
      else if (errors == 10) $display($time,,,"...");
    end 
    
    if ($feof(golden_file)) begin
      $fclose(golden_file);
      //golden_read <= 0;
      if (current_cycle < cycles) begin
        current_cycle = current_cycle + 1;
        input_read = 1;
        input_file = $fopen("raw.dat", "r");
        golden_file = $fopen("dwt2.dat", "r");
      end
      else begin
        $display("*************************************");
        $display("*        Simulation finished        *");
        $display("*                                   *");
        $display("*   Clock freq.:  ",      "%d MHz   *", 1000/PERIOD);
        $display("*   Tile size:    "      ,"    %d   *", NUMEL); 
        $display("*   Transmit cycles:",      "  %d   *", cycles);
        $display("*   Time:    ",   ($time-15)/10,"   *"); //15 ns reset delay
        $display("*   Errors:       ",      "    %d   *", errors);
        $display("*************************************");
        $finish;
      end
    end
  end
end

endmodule
