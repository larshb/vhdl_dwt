`timescale 1ns / 1ps

module dwt_2_tb;

parameter PERIOD = 10;
parameter WIDTH = 16;
parameter NUMEL = 512;

reg  CLK = 0, RST = 1, valid_i = 0;
reg  signed [WIDTH-1:0] din;
wire valid_o;
wire signed [WIDTH-1:0] dout;

dwt_2 dwt_2_i(
    .clk(CLK),
    .rst(RST),
    .valid_i(valid_i),
    .valid_o(valid_o),
    .din(din),
    .dout(dout));

// Clock generator
always #(PERIOD/2) CLK = ~CLK;

integer input_file,
        golden_file,
        count,
        errors = 0;
reg signed [WIDTH-1:0] golden_dout;
reg input_read=0, golden_read=1;

initial begin
  // Input data file
  input_file = $fopen("../dat/raw.dat", "r");
  if (input_file == 0) begin
    $display("input_file handle was NULL");
    $finish;
  end
  
  // Golden data file (Expected output)
  golden_file = $fopen("../dat/dwt2.dat", "r");
  if (golden_file == 0) begin
    $display("golden_file handle was NULL");
    $finish;
  end
  
  // Control signals
  #13 RST <= 0;
  input_read <= 1;
end

always @(posedge CLK) begin
  // Feed data
  if (input_read==1) begin
    count = $fscanf(input_file, "%d\n", din);
    valid_i = 1;
    if ($feof(input_file)) begin
      $fclose(input_file);
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
      $display($time,,,"Expected: %d\t Read: %d",
        golden_dout, dout);
    end 
    
    if ($feof(golden_file)) begin
      $fclose(golden_file);
      golden_read <= 0;
      $display("*************************************");
      $display("*        Simulation finished        *");
      $display("*                                   *");
      $display("*   Errors:           %d   *", errors);
      $display("*************************************");
      $finish;
    end
  end
end

endmodule
