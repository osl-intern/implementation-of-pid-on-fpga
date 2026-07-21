
`timescale 1ns/1ps

module tb_DAC2932_CONTROLLER;

reg clk;
reg rst;
reg start;
reg [11:0] data_in;

wire [11:0] dac_data;
wire dac_clk;
wire busy;
wire done;
wire cs;
wire pd;
wire stby;

//------------------------------------------------------------
// DUT
//------------------------------------------------------------
DAC2932_CONTROLLER dut (

    .clk(clk),
    .rst(rst),

    .start(start),
    .data_in(data_in),

    .dac_data(dac_data),
    .dac_clk(dac_clk),
    .busy(busy),
    .done(done),
    .cs(cs),
    .pd(pd),
    .stby(stby)

);


//------------------------------------------------------------
// Clock Generation
//------------------------------------------------------------
initial
    clk = 0;

always #5 clk = ~clk;      //100 MHz


//------------------------------------------------------------
// Task : Send Sample
//------------------------------------------------------------
task send_sample;

input [11:0] sample;

begin

    @(posedge clk);

    data_in <= sample;
    start   <= 1'b1;

    @(posedge clk);

    start <= 1'b0;

    wait(done);

    @(posedge clk);

end

endtask


//------------------------------------------------------------
// Monitor
//------------------------------------------------------------
initial
begin

$display("------------------------------------------------------------");
$display("Time\tState\tStart\tBusy\tDone\tDAC_CLK\tDAC_DATA");
$display("------------------------------------------------------------");

$monitor("%0t\t%d\t%b\t%b\t%b\t%b\t%03h",
         $time,
         dut.state,
         start,
         busy,
         done,
         dac_clk,
         dac_data);

end


//------------------------------------------------------------
// Test Sequence
//------------------------------------------------------------
initial
begin

//------------------------------------------------------------
// Initialization
//------------------------------------------------------------

rst     = 1'b1;
start   = 1'b0;
data_in = 12'h000;

repeat(3) @(posedge clk);

rst = 1'b0;

$display("\nRESET COMPLETE\n");


//------------------------------------------------------------
// Test 1
//------------------------------------------------------------

$display("TEST 1 : Send 123");

send_sample(12'h123);

if(dac_data == 12'h123)
    $display("PASS");
else
    $display("FAIL");


//------------------------------------------------------------
// Test 2
//------------------------------------------------------------

$display("TEST 2 : Send ABC");

send_sample(12'hABC);

if(dac_data == 12'hABC)
    $display("PASS");
else
    $display("FAIL");


//------------------------------------------------------------
// Test 3
//------------------------------------------------------------

$display("TEST 3 : Send 555");

send_sample(12'h555);

if(dac_data == 12'h555)
    $display("PASS");
else
    $display("FAIL");


//------------------------------------------------------------
// Test 4
//------------------------------------------------------------

$display("TEST 4 : Back-to-back Transfers");

send_sample(12'h111);
send_sample(12'h222);
send_sample(12'h333);

$display("PASS");


//------------------------------------------------------------

#50;

$display("\n=======================================");
$display("SIMULATION COMPLETED");
$display("=======================================\n");

$finish;

end

endmodule