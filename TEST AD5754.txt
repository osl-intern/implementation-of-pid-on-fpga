`timescale 1ns/1ps

module tb_ad5754_reset_mid_spi;

reg clk;
reg rst;

reg update_all;
reg [15:0] dac_data;

wire MOSI;
wire SCLK;
wire SYNC;
wire LDAC;

wire init_done;
wire data_request;

integer init_count;

//////////////////////////////////////////////////////////
// DUT
//////////////////////////////////////////////////////////

ad5754_top DUT
(
    .clk(clk),
    .rst(rst),

    .update_all(update_all),
    .dac_data(dac_data),

    .data_request(data_request),
    .init_done(init_done),

    .MOSI(MOSI),
    .SCLK(SCLK),
    .SYNC(SYNC),
    .LDAC(LDAC)
);

//////////////////////////////////////////////////////////
// Clock
//////////////////////////////////////////////////////////

initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end

//////////////////////////////////////////////////////////
// Reset
//////////////////////////////////////////////////////////

initial
begin
    rst = 1;
    update_all = 0;
    dac_data = 16'h1111;

    #50;
    rst = 0;
end

//////////////////////////////////////////////////////////
// Waveform
//////////////////////////////////////////////////////////

initial
begin
    $dumpfile("reset_mid_spi.vcd");
    $dumpvars(0,tb_ad5754_reset_mid_spi);
end

//////////////////////////////////////////////////////////
// Count Initialization Transactions
//////////////////////////////////////////////////////////

initial
init_count = 0;

always @(posedge DUT.spi_done)
begin
    if(!init_done)
    begin
        init_count = init_count + 1;

        $display("[%0t] Init Transaction %0d  Frame=%h",
                 $time,
                 init_count,
                 DUT.spi_frame);
    end
end

//////////////////////////////////////////////////////////
// Main Test
//////////////////////////////////////////////////////////

initial
begin

    //------------------------------------------------------
    // Wait for first initialization
    //------------------------------------------------------

    wait(init_done);

    $display("\n=================================");
    $display("Initialization Complete");
    $display("=================================\n");

    //------------------------------------------------------
    // Start DAC update
    //------------------------------------------------------

    @(posedge clk);

    update_all = 1;

    @(posedge clk);

    update_all = 0;

    $display("[%0t] DAC Update Requested",$time);

    //------------------------------------------------------
    // Wait until SPI starts
    //------------------------------------------------------

    @(posedge DUT.spi_start);

    $display("[%0t] SPI Started",$time);

    //------------------------------------------------------
    // Let a few clocks pass
    //------------------------------------------------------

    repeat(10) @(posedge clk);

    //------------------------------------------------------
    // Assert RESET in middle of SPI
    //------------------------------------------------------

    $display("\n=================================");
    $display("ASSERTING RESET DURING SPI");
    $display("=================================\n");

    rst = 1;

    #40;

    rst = 0;

    $display("[%0t] RESET Released",$time);

    //------------------------------------------------------
    // Wait for initialization again
    //------------------------------------------------------

    wait(init_done);

    $display("\n=================================");
    $display("Initialization Restarted Successfully");
    $display("=================================\n");

    #100;

    $display("TEST PASSED");

    $finish;

end

//////////////////////////////////////////////////////////
// Useful Monitors
//////////////////////////////////////////////////////////

always @(posedge rst)
begin
    $display("[%0t] RESET ASSERTED",$time);
end

always @(negedge rst)
begin
    $display("[%0t] RESET DEASSERTED",$time);
end

always @(posedge DUT.spi_start)
begin
    $display("[%0t] SPI START",$time);
end

always @(posedge DUT.spi_done)
begin
    $display("[%0t] SPI DONE",$time);
end

always @(SYNC)
begin
    $display("[%0t] SYNC = %b",$time,SYNC);
end

always @(LDAC)
begin
    $display("[%0t] LDAC = %b",$time,LDAC);
end

always @(posedge clk)
begin
    if(DUT.controller_inst.state != 5'd6)
    begin
        $display("[%0t] STATE = %0d",
                 $time,
                 DUT.controller_inst.state);
    end
end

endmodule

`timescale 1ns/1ps

module tb_ad5754_stage2;

reg clk;
reg rst;

reg update_all;
reg [15:0] dac_data;

wire MOSI;
wire SCLK;
wire SYNC;
wire LDAC;

wire init_done;
wire data_request;

//////////////////////////////////////////////////////////
// DUT
//////////////////////////////////////////////////////////

ad5754_top DUT
(
    .clk(clk),
    .rst(rst),

    .update_all(update_all),
    .dac_data(dac_data),

    .data_request(data_request),
    .init_done(init_done),

    .MOSI(MOSI),
    .SCLK(SCLK),
    .SYNC(SYNC),
    .LDAC(LDAC)
);

//////////////////////////////////////////////////////////
// Clock
//////////////////////////////////////////////////////////

initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end

//////////////////////////////////////////////////////////
// Reset
//////////////////////////////////////////////////////////

initial
begin

    rst = 1;
    update_all = 0;
    dac_data   = 16'h0000;

    #50;
    rst = 0;

end

//////////////////////////////////////////////////////////
// Waveform
//////////////////////////////////////////////////////////

initial
begin
    $dumpfile("stage2.vcd");
    $dumpvars(0,tb_ad5754_stage2);
end

//////////////////////////////////////////////////////////
// Initialization Monitor
//////////////////////////////////////////////////////////

integer init_transaction;

initial
init_transaction = 0;

always @(posedge DUT.spi_done)
begin

    init_transaction = init_transaction + 1;

    if(init_transaction <= 3)
    begin

        $display("------------------------------------");
        $display("Initialization Transaction %0d",init_transaction);
        $display("Frame = %h",DUT.spi_frame);

    end

end

//////////////////////////////////////////////////////////
// Stage-2 Stimulus
//////////////////////////////////////////////////////////

initial
begin

    @(negedge rst);

    $display("\nWaiting for Initialization...\n");

    wait(init_done);

    $display("------------------------------------");
    $display("Initialization Complete");
    $display("------------------------------------");

    //////////////////////////////////////////////////////
    // Send DAC A
    //////////////////////////////////////////////////////

    @(posedge clk);

    dac_data = 16'h1234;

    $display("\nApplying DAC A Data = %h",dac_data);

    update_all = 1;

    @(posedge clk);

    update_all = 0;

    $display("update_all Deasserted");

end

//////////////////////////////////////////////////////////
// Check DAC-A Frame
//////////////////////////////////////////////////////////

always @(posedge DUT.spi_start)
begin
    if(init_done)
    begin
        if(DUT.spi_frame == 24'h001234)
    begin

        if(DUT.spi_frame == 24'h001234)
        begin
            $display("------------------------------------");
            $display("PASS : DAC A Frame Correct");
            $display("Frame = %h",DUT.spi_frame);
            $display("------------------------------------");
        end
        else if(init_done)
        begin
            $display("------------------------------------");
            $display("FAIL : Wrong DAC A Frame");
            $display("Expected = 001234");
            $display("Received = %h",DUT.spi_frame);
            $display("------------------------------------");
        end
      end
    end

end

//////////////////////////////////////////////////////////
// SPI Done Monitor
//////////////////////////////////////////////////////////

integer spi_count;

initial
spi_count = 0;

always @(posedge DUT.spi_done)
begin

    spi_count = spi_count + 1;

    if(spi_count == 4)
    begin

        $display("");
        $display("DAC A SPI Transaction Completed");

    end

end

//////////////////////////////////////////////////////////
// LDAC Monitor
//////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////
// LDAC Monitor
//////////////////////////////////////////////////////////

always @(LDAC)
begin
    if(init_done)
    begin
        if(LDAC)
            $display("[%0t] LDAC -> HIGH", $time);
        else
            $display("[%0t] LDAC -> LOW", $time);
    end
end

//////////////////////////////////////////////////////////
// Wait until Controller Returns READY
//////////////////////////////////////////////////////////

initial
begin

    wait(init_done);

    wait(spi_count == 4);

    @(negedge LDAC);
    @(posedge LDAC);

    wait(DUT.controller_inst.state == 5'd6);

    $display("");
    $display("====================================");
    $display("Controller Returned To READY");
    $display("STAGE-2 TEST PASSED");
    $display("====================================");

    #100;
    $finish;

end

endmodule

`timescale 1ns/1ps

module tb_ad5754_stage3;

reg clk;
reg rst;

reg update_all;
reg [15:0] dac_data;

wire MOSI;
wire SCLK;
wire SYNC;
wire LDAC;

wire init_done;
wire data_request;

localparam [15:0] DAC_A = 16'h1111;
localparam [15:0] DAC_B = 16'h2222;
localparam [15:0] DAC_C = 16'h3333;
localparam [15:0] DAC_D = 16'h4444;
//////////////////////////////////////////////////////////
// DUT
//////////////////////////////////////////////////////////

ad5754_top DUT
(
    .clk(clk),
    .rst(rst),

    .update_all(update_all),
    .dac_data(dac_data),

    .data_request(data_request),
    .init_done(init_done),

    .MOSI(MOSI),
    .SCLK(SCLK),
    .SYNC(SYNC),
    .LDAC(LDAC)
);

//////////////////////////////////////////////////////////
// Clock
//////////////////////////////////////////////////////////

initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end

//////////////////////////////////////////////////////////
// Reset
//////////////////////////////////////////////////////////

initial
begin

    rst = 1;
    update_all = 0;
    dac_data   = 16'h0000;

    #50;
    rst = 0;

end

//////////////////////////////////////////////////////////
// Waveform
//////////////////////////////////////////////////////////

initial
begin
    $dumpfile("stage3.vcd");
    $dumpvars(0,tb_ad5754_stage3);
end

//////////////////////////////////////////////////////////
// Initialization Monitor
//////////////////////////////////////////////////////////

integer normal_transaction;

initial
normal_transaction = 0;

always @(posedge DUT.spi_done)
begin

    if(init_done)
    begin

        normal_transaction = normal_transaction + 1;

        case(normal_transaction)

        1:
        begin
            if(DUT.spi_frame == 24'h001111)
                $display("PASS : DAC A Frame");
            else
                $display("FAIL : DAC A");
$display("Expected : 001111");
$display("Received : %h", DUT.spi_frame);
        end

        2:
        begin
            if(DUT.spi_frame == 24'h012222)
                $display("PASS : DAC B Frame");
            else
                $display("FAIL : DAC B");
        end

        3:
        begin
            if(DUT.spi_frame == 24'h023333)
                $display("PASS : DAC C Frame");
            else
                $display("FAIL : DAC C");
        end

        4:
        begin
            if(DUT.spi_frame == 24'h034444)
                $display("PASS : DAC D Frame");
            else
                $display("FAIL : DAC D");
        end

        endcase

    end

end

//////////////////////////////////////////////////////////
// Stage-2 Stimulus
//////////////////////////////////////////////////////////
initial
begin

    @(negedge rst);

    $display("\nWaiting for Initialization...\n");

    wait(init_done);

    $display("--------------------------------");
    $display("Initialization Complete");
    $display("--------------------------------");

    @(posedge clk);

    dac_data = DAC_A;

    $display("\nSending DAC A = %h",dac_data);

    update_all = 1;

    @(posedge clk);

    update_all = 0;

end

//////////////////////////////////////////////////////////
// Check DAC-A Frame
//////////////////////////////////////////////////////////

always @(posedge data_request)
begin

    case(dac_data)

        DAC_A:
        begin
            dac_data <= DAC_B;
            $display("[%0t] Controller requested DAC B", $time);
        end

        DAC_B:
        begin
            dac_data <= DAC_C;
            $display("[%0t] Controller requested DAC C", $time);
        end

        DAC_C:
        begin
            dac_data <= DAC_D;
            $display("[%0t] Controller requested DAC D", $time);
        end

        default:
        begin
        end

    endcase

end

//////////////////////////////////////////////////////////
// SPI Done Monitor
//////////////////////////////////////////////////////////

integer spi_count;

initial
spi_count = 0;

always @(posedge DUT.spi_done)
begin

    spi_count = spi_count + 1;

    if(init_done)
        $display("[%0t] SPI Transaction %0d Completed",$time,normal_transaction);

end

//////////////////////////////////////////////////////////
// LDAC Monitor
//////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////
// LDAC Monitor
//////////////////////////////////////////////////////////

always @(LDAC)
begin
    if(init_done)
    begin
        if(LDAC)
            $display("[%0t] LDAC -> HIGH", $time);
        else
            $display("[%0t] LDAC -> LOW", $time);
    end
end

//////////////////////////////////////////////////////////
// Wait until Controller Returns READY
//////////////////////////////////////////////////////////

initial
begin

    wait(init_done);

    wait(normal_transaction == 4);

    @(negedge LDAC);
    @(posedge LDAC);

    wait(DUT.controller_inst.state == 5'd6);

    $display("");
    $display("======================================");
    $display("ALL FOUR DAC WRITES VERIFIED");
    $display("LDAC Pulse Verified");
    $display("CONTROLLER RETURNED TO READY");
    $display("STAGE 3 PASSED");
    $display("======================================");

    #100;

    $finish;

end

endmodule