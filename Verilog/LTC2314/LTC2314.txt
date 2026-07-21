`timescale 1ns / 1ps
module ltc2314_top
(
    input         clk,
    input         rst,

    // System Interface
    input         sample_trigger,

    // ADC Interface
    input         MISO,
    output        SCLK,
    output        CS,

    // PID Interface
    output [13:0] adc_data,
    output        adc_valid
);

wire        start;
wire        busy;
wire        done;
wire [15:0] rx_data;

// No MOSI data is required for LTC2314
wire        MOSI;

//----------------------------------------------------------
// ADC Controller
//----------------------------------------------------------

ltc2314_controller adc_controller
(
    .clk       (clk),
    .rst       (rst),
    .en        (sample_trigger),

    .busy      (busy),
    .done      (done),
    .data_in (rx_data),

    .start     (start),

    .data_out(adc_data),
    .adc_valid (adc_valid)
);

//----------------------------------------------------------
// Generic SPI Master
//----------------------------------------------------------

spi_master_all_in_one
#(
    .DATA_WIDTH (16),
    .COUNT      (18)
)
spi_master
(
    .clk      (clk),
    .rst      (rst),

    .start    (start),

    // ADC doesn't require MOSI data
    .data_in  (16'd0),

    .MISO     (MISO),

    // LTC2314 Timing
    .CPOL     (1'b0),
    .CPHA     (1'b0),

    .MOSI     (MOSI),      // Unused
    .sclk     (SCLK),
    .CS       (CS),

    .done     (done),
    .busy     (busy),

    .data_out (rx_data)
);

endmodule




module ltc2314_controller
(
    input         clk,
    input         rst,
    input         en,          // sample trigger

    // SPI Master Interface
    input         busy,
    input         done,
    input  [15:0] data_in,

    output        start,

    // PID Interface
    output reg [13:0] data_out,
    output reg        adc_valid
);

parameter IDLE_CONT     = 3'd0;
parameter START_SPI     = 3'd1;
parameter WAIT_SPI  = 3'd2;
parameter DONE = 3'd3;
parameter WAIT_ACQ  = 3'd4;
//reg [2:0] state ;

reg [1:0]count ;
//reg conv ;


reg [2:0] state ;
reg conv ;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE_CONT;
        adc_valid <=0;
        data_out  <= 14'd0;
        conv <= 0;
    end

    else if (state == IDLE_CONT) begin
        if (en)
            state <= START_SPI;
        else
            state <= IDLE_CONT;
    end

    else if (state == START_SPI) begin
        if (busy)
            state <= WAIT_SPI;
        else
            state <= START_SPI;
    end

    else if (state == WAIT_SPI) begin
        if (done)
            state <= DONE;
        else
            state <= WAIT_SPI;
    end

    else if (state == DONE) begin
        state <= WAIT_ACQ;
        
        if(conv) begin
        adc_valid <= 1;
        data_out <= data_in[14:1]; end
        else  begin
        adc_valid <= 0; 
        conv      <= 1;  end
        
    end

    else if (state == WAIT_ACQ) begin
        adc_valid <=0;
        if (count == 2)
            state <= IDLE_CONT;
        else
            state <= WAIT_ACQ;
    end
    
    else begin
    state <= IDLE_CONT;
    end

end

assign start = (state == START_SPI) ;

always@(posedge clk or posedge rst ) begin
if(rst || state== IDLE_CONT)
count <=0;
else if ( state == WAIT_ACQ)  
count <= count + 1 ;
end

endmodule
module spi_master_all_in_one
#(
    parameter DATA_WIDTH = 8,
    parameter COUNT      = 10
)
(
    input         clk,
    input         rst,

    input         start,
    input [DATA_WIDTH-1:0] data_in,

    input         MISO,
    
    input        CPOL,
    input        CPHA,

    output   reg  MOSI,
    output        sclk,
    output reg    CS,
    output reg    done,
    output busy,
    output reg [DATA_WIDTH-1:0] data_out,
    output  reg sample_pulse,
    output reg shift_pulse,
    output reg [$clog2(DATA_WIDTH+1)-1:0] bit_count


    
);
reg [3:0] state,next_state;
reg load_en;
reg shift_en;
reg count_en;
reg sclk_en;
reg [DATA_WIDTH-1:0] rx_shift_reg;
reg [DATA_WIDTH-1:0] shift_reg;

wire spi_clk;
wire div_rst;


wire falling_edge;
wire rising_edge;
wire trailing_edge;
wire t10_done;
wire half_tick;
reg  idle_clk;
wire MOSI_B;
reg MOSI_A;

parameter IDLE           = 3'd0;
parameter LOAD           = 3'd1;
parameter CS_LOW         = 3'd2;
parameter TRANSFER       = 3'd3;
parameter WAIT_LAST_EDGE = 3'd4;
parameter WAIT_T10       = 3'd5;
parameter CS_HIGH        = 3'd6;

wire[1:0] mode ;
assign mode = { CPOL , CPHA };
//
assign MOSI_B = shift_reg[DATA_WIDTH-1];

// fsm for mode 

always@(*) begin
case (mode)
0 : begin  sample_pulse = rising_edge ;
           shift_pulse= falling_edge ;
           idle_clk = 0 ;
           MOSI = MOSI_B; end 
           
1 : begin  shift_pulse = rising_edge ;
           sample_pulse= falling_edge ;
           idle_clk=0 ;
           MOSI = MOSI_A; end 
           
2 : begin  shift_pulse = rising_edge ;
           sample_pulse= falling_edge ;
           idle_clk =1 ;
           MOSI = MOSI_B; end 
           
3 : begin  sample_pulse = rising_edge ;
           shift_pulse= falling_edge ;
           idle_clk =1 ;
           MOSI = MOSI_A; end 
 default : begin    
    sample_pulse = 1'b0;
    shift_pulse  = 1'b0;
    idle_clk     = 1'b0; 
    MOSI         = 1'b0; end

endcase
end

assign trailing_edge = (CPOL == 1'b0) ? falling_edge : rising_edge;

// fsm
always @(posedge clk or posedge rst)
begin
    if(rst)
        state <= IDLE;
    else
        state <= next_state;
end
// logic for next state

always @(*)
begin

    next_state = state;

    case(state)

        IDLE:
        begin
            if(start)
                next_state = LOAD;
        end

        LOAD:
        begin
            next_state = CS_LOW;
        end

        CS_LOW:
        begin
            next_state = TRANSFER;
        end

        TRANSFER:
begin
    if(bit_count == DATA_WIDTH)
        next_state = WAIT_LAST_EDGE;
end

WAIT_LAST_EDGE:
begin
    if(trailing_edge)
        next_state = WAIT_T10;
end

WAIT_T10:
begin
    if(t10_done)
        next_state = CS_HIGH;
end

CS_HIGH:
begin
    next_state = IDLE;
end

        default:
            next_state = IDLE;

    endcase

end
// output logic

always @(*)
begin

    CS       = 1'b1;
    sclk_en  = 1'b0;
    load_en  = 1'b0;
    shift_en = 1'b0;
    count_en = 1'b0;
    done     = 1'b0;

    case(state)

        IDLE:
        begin
        end

        LOAD:
        begin
            load_en = 1'b1;
        end

        CS_LOW:
        begin
            CS = 1'b0;
        end

        TRANSFER:
        begin
            CS       = 1'b0;
            sclk_en  = 1'b1;
            shift_en = 1'b1;
            count_en = 1'b1;
        end
        
        WAIT_LAST_EDGE:
        begin
        CS       = 1'b0;
        sclk_en  = 1'b1;
        shift_en = 1'b0;
        count_en = 1'b0;
        end
        
        WAIT_T10:
        begin
        CS      = 1'b0;
        sclk_en = 1'b0;
        end

         CS_HIGH:
         begin
            CS   = 1'b1;
            done = 1'b1;
         end

    endcase

end
// shift register 


always @(posedge clk or posedge rst)
begin
    if(rst)  begin
        shift_reg <= 8'd0;
        MOSI_A <=0;
         end

    else if(load_en) begin
        shift_reg <= data_in;
        MOSI_A <=0;
        end

    else if(shift_en && shift_pulse) begin
            MOSI_A <= shift_reg[DATA_WIDTH-1];
           shift_reg <= {shift_reg[DATA_WIDTH-2:0],1'b0}; end
end

// receive shift register
always @(posedge clk or posedge rst)
begin

    if(rst)
        rx_shift_reg <= 8'd0;

    else if(load_en)
        rx_shift_reg <= 8'd0;

    else if(count_en && sample_pulse)
        rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], MISO};

end


// bit counter

always @(posedge clk or posedge rst)
begin

    if(rst)
        bit_count <= 0;

    else if(!count_en)
        bit_count <= 0;

    else if(sample_pulse)
        bit_count <= bit_count + 1;

end
// pulse generator
reg sclk_d;

always @(posedge clk or posedge rst)
begin
    if(rst)
        sclk_d <= 1'b0;
    else
        sclk_d <= sclk;
end

assign falling_edge = sclk_d & ~sclk;

assign rising_edge = ~sclk_d & sclk;

// output clock 
assign sclk = (sclk_en) ? spi_clk : idle_clk;

// output data from the bus 
always @(posedge clk or posedge rst)
begin
    if(rst)
        data_out <= 8'd0;

    else if( done )
        data_out <= rx_shift_reg[DATA_WIDTH-1:0];
end
// logic for busy
assign busy = (state != IDLE);

// frequency divider 
assign div_rst = rst | start;
assign t10_done = half_tick;
frequency_divider #(
    .COUNT(COUNT)
) u_clk_div (
    .clk(clk),
    .rst(div_rst),
    .idle_clk(idle_clk),
    .clk_out(spi_clk),
    .half_tick(half_tick)
);

endmodule

module frequency_divider
#(
    parameter COUNT = 10
)
(
    input  wire clk,
    input  wire rst,
    input idle_clk,
    
    output reg  clk_out,
    output  half_tick
);

reg [$clog2(COUNT)-1:0] counter;
assign half_tick = (counter == COUNT - 1);
always @(posedge clk )
begin
if(rst)
begin
    counter <= 0;
    clk_out <= idle_clk;
end

    else if(counter == COUNT-1)
    begin
        counter <= 0;
        clk_out <= ~clk_out;
    end

    else
    begin
        counter <= counter + 1'b1;
    end
end

endmodule
