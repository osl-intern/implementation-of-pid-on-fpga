`timescale 1ns/1ps

module ltc2314_top_tb;

reg clk;
reg rst;
reg sample_trigger;
reg MISO;

wire SCLK;
wire CS;
wire [13:0] adc_data;
wire adc_valid;


//----------------------------------------------------
// DUT
//----------------------------------------------------

ltc2314_top dut
(
    .clk(clk),
    .rst(rst),
    .sample_trigger(sample_trigger),

    .MISO(MISO),
    .SCLK(SCLK),
    .CS(CS),

    .adc_data(adc_data),
    .adc_valid(adc_valid)
);


//----------------------------------------------------
// Clock
//----------------------------------------------------

initial
begin
    clk = 0;
    forever #5 clk = ~clk;      //100MHz
end


//----------------------------------------------------
// Test Data
//----------------------------------------------------
reg [13:0] adc_sample;   // Actual ADC conversion result
reg [15:0] adc_frame;    // Serial frame sent by ADC
integer i;


//----------------------------------------------------
// ADC Model
//----------------------------------------------------

task send_adc_word;



input [15:0] word;

begin

    //wait until SPI starts
@(negedge CS);

// First bit must already be present
MISO = word[15];

for(i=14;i>=0;i=i-1)
begin
    @(negedge SCLK);
    MISO = word[i];
end

    @(posedge CS);

end

endtask

task pipeline_fill;

begin

    adc_sample = 14'h0000;
    adc_frame  = {1'b0, adc_sample, 1'b0};

    @(posedge clk);
    sample_trigger = 1;

    @(posedge clk);
    sample_trigger = 0;

    send_adc_word(adc_frame);

    // Wait until SPI transfer finishes
    

    #200;

end

endtask

task run_conversion;

input [13:0] sample;

begin

    adc_sample = sample;
    adc_frame  = {1'b0, adc_sample, 1'b0};

    @(posedge clk);
    sample_trigger = 1;

    @(posedge clk);
    sample_trigger = 0;

    fork
        send_adc_word(adc_frame);
    join

    @(posedge adc_valid);

 
$display("--------------------------------");
$display("ADC Sample = %h", adc_sample);
$display("ADC Frame  = %h", adc_frame);
$display("Received   = %h", adc_data);

if(adc_data == adc_sample)
    $display("PASS");
else
    $display("FAIL");

    #200;

end

endtask


//----------------------------------------------------
// Stimulus
//----------------------------------------------------

initial
begin

    rst = 1;
    sample_trigger = 0;
    MISO = 0;

#100;
rst = 0;

// First conversion is discarded by the ADC
pipeline_fill();

// Now all conversions are valid
run_conversion(14'h0000);
run_conversion(14'h0001);
run_conversion(14'h3FFF);
run_conversion(14'h2AAA);
run_conversion(14'h1555);
run_conversion(14'h2000);
run_conversion(14'h0F0F);
run_conversion(14'h1234);
run_conversion(14'h2A5C);

$finish;
end


//----------------------------------------------------
// Monitor
//----------------------------------------------------

initial
begin
    $monitor("T=%0t  CS=%b SCLK=%b MISO=%b adc_valid=%b adc_data=%h",
              $time, CS, SCLK, MISO, adc_valid, adc_data);
end

endmodule
