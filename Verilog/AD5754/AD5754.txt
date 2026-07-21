module ad5754_top
(
    input               clk,
    input               rst,

    //=========================================
    // User Interface
    //=========================================
    input               update_all,
    input      [15:0]   dac_data,

    output              data_request,
    output              init_done,

    //=========================================
    // AD5754 Pins
    //=========================================
    output              MOSI,
    output              SCLK,
    output              SYNC,
    output              LDAC
);

    //--------------------------------------------------
    // Internal Signals
    //--------------------------------------------------

    wire        spi_start;
    wire [23:0] spi_frame;

    wire        spi_done;
    wire        spi_busy;

    wire        count_en;
    wire        count_rst;

    wire [15:0] counter;

    //--------------------------------------------------
    // Counter
    //--------------------------------------------------
/*
    counter counter_inst
    (
        .clk        (clk),
        .rst        (count_rst),
        .count_en   (count_en),
        .count      (count)
    );
*/
    //--------------------------------------------------
    // AD5754 Controller
    //--------------------------------------------------

    ad5754_controller controller_inst
    (
        .clk                (clk),
        .rst                (rst),

        .update_all         (update_all),
        .dac_data           (dac_data),

        .data_request_reg   (data_request),

        .spi_start          (spi_start),
        .spi_frame          (spi_frame),

        .spi_done           (spi_done),

        .counter              (counter),
        .count_en           (count_en),
        .count_rst          (count_rst),

        .ldac               (LDAC),

        .init_done          (init_done)
    );

    //--------------------------------------------------
    // SPI Master
    //--------------------------------------------------

    spi_master_all_in_one
    #(
        .DATA_WIDTH (24),
        .COUNT      (3)
    )
    spi_master_inst
    (
        .clk            (clk),
        .rst            (rst),

        .start          (spi_start),
        .data_in        (spi_frame),

        .MISO           (1'b0),

        .CPOL           (1'b1),
        .CPHA           (1'b0),

        .MOSI           (MOSI),
        .sclk           (SCLK),
        .CS             (SYNC),

        .done           (spi_done),
        .busy           (spi_busy),

        .data_out       (),

        .sample_pulse   (),
        .shift_pulse    (),
        .bit_count      ()
    );

endmodule

module ad5754_controller
(
    input               clk,
    input               rst,

    //===========================
    // User Interface
    //===========================
    input               update_all,
    input      [15:0]   dac_data,

    output reg          data_request_reg,

    //===========================
    // SPI Master Interface
    //===========================
    output              spi_start,
    output     [23:0]   spi_frame,

    input               spi_done,

    //===========================
    // Counter Interface
    //===========================
    

    output              count_en,
    output reg          count_rst,
    output reg  [15:0]  counter ,
    //===========================
    // DAC Control
    //===========================
    output              ldac,

    //===========================
    // Status
    //===========================
    output              init_done
);

localparam ST_RESET         = 5'd0;

localparam ST_INIT_RANGE    = 5'd1;
localparam ST_INIT_CONTROL  = 5'd2;
localparam ST_INIT_POWER    = 5'd3;

localparam ST_WAIT_SPI      = 5'd4;
localparam ST_WAIT_DELAY    = 5'd5;

localparam ST_READY         = 5'd6;

localparam ST_BUILD_FRAME_A = 5'd7;
localparam ST_BUILD_FRAME_B = 5'd8;
localparam ST_BUILD_FRAME_C = 5'd9;
localparam ST_BUILD_FRAME_D = 5'd10;

localparam ST_LDAC_LOW      = 5'd11;
localparam ST_LDAC_HIGH     = 5'd12;

localparam T6_COUNT      = 16'd10;
localparam T10_COUNT     = 16'd13;
localparam T11_COUNT     = 16'd2;      // Change according to datasheet
localparam POWER_COUNT   = 16'd1000;

localparam [23:0] INIT_RANGE    = 24'h0C0004;
localparam [23:0] INIT_CONTROL  = 24'h32000D;
localparam [23:0] INIT_POWER    = 24'h20000F;

//-----------------------------------------------------
// Registers
//-----------------------------------------------------

reg [4:0] state;

reg [23:0] frame_reg;

reg spi_start_reg;

reg init_done_reg;

reg ldac_reg;

// Used by WAIT_DELAY state
reg [15:0] delay_count;

//reg [15:0] counter;

// Used by WAIT_DELAY state
reg [4:0] next_state_after_delay;

// output assignment 

assign spi_start = spi_start_reg;

assign spi_frame = frame_reg;

assign init_done = init_done_reg;

assign ldac = ldac_reg;

assign count_en = (state == ST_WAIT_DELAY);


always @(posedge clk or posedge rst)
begin

    if(rst)
    begin
        //--------------------------------------------------
        // Reset all registers
        //--------------------------------------------------
        state                   <= ST_RESET;

        frame_reg               <= 24'd0;

        spi_start_reg           <= 1'b0;

        init_done_reg           <= 1'b0;

        ldac_reg                <= 1'b1;      // LDAC inactive (active low)

        data_request_reg        <= 1'b0;

        count_rst               <= 1'b1;

        delay_count             <= 16'd0;

        next_state_after_delay  <= ST_RESET;
    end

    else
    begin

        //--------------------------------------------------
        // Default values every clock
        //--------------------------------------------------
        spi_start_reg    <= 1'b0;
        data_request_reg <= 1'b0;
        count_rst        <= 1'b0;

        //--------------------------------------------------
        // FSM
        //--------------------------------------------------

        case(state)

        //--------------------------------------------------
        // RESET
        //--------------------------------------------------

        ST_RESET :
        begin

            init_done_reg <= 1'b0;
            
           ldac_reg <=1;

            state <= ST_INIT_RANGE;

        end

        //--------------------------------------------------
        // Send Output Range Register
        //--------------------------------------------------

        ST_INIT_RANGE :
        begin

            frame_reg <= INIT_RANGE;

            spi_start_reg <= 1'b1;

            delay_count <= T6_COUNT;

            next_state_after_delay <= ST_INIT_CONTROL;

            state <= ST_WAIT_SPI;

        end

        //--------------------------------------------------
        // Wait SPI Transaction Complete
        //--------------------------------------------------

        ST_WAIT_SPI :
        begin

            if(spi_done)
            begin

                count_rst <= 1'b1;

                state <= ST_WAIT_DELAY;

            end

        end

        //--------------------------------------------------
        // Common Delay State
        //--------------------------------------------------

        ST_WAIT_DELAY :
        begin

if(counter == delay_count)
begin

    count_rst <= 1'b1;

    if(next_state_after_delay == ST_BUILD_FRAME_B ||
       next_state_after_delay == ST_BUILD_FRAME_C ||
       next_state_after_delay == ST_BUILD_FRAME_D)
    begin
        data_request_reg <= 1'b1;
    end

    state <= next_state_after_delay;

end

        end

        //--------------------------------------------------
        // Send Control Register
        //--------------------------------------------------

        ST_INIT_CONTROL :
        begin

            frame_reg <= INIT_CONTROL;

            spi_start_reg <= 1'b1;

            delay_count <= T6_COUNT;

            next_state_after_delay <= ST_INIT_POWER;

            state <= ST_WAIT_SPI;

        end

        //--------------------------------------------------
        // Send Power Register
        //--------------------------------------------------

        ST_INIT_POWER :
        begin

            frame_reg <= INIT_POWER;

            spi_start_reg <= 1'b1;

            delay_count <= POWER_COUNT;

            next_state_after_delay <= ST_READY;

            state <= ST_WAIT_SPI;

        end

        //--------------------------------------------------
        // Initialization Finished
        //--------------------------------------------------

       ST_READY :
begin

    init_done_reg <= 1'b1;

    if(update_all)
        state <= ST_BUILD_FRAME_A;
    else
        state <= ST_READY;

end


ST_BUILD_FRAME_A :
begin

    frame_reg <= {8'b00000000,dac_data};   // DAC A Address

    spi_start_reg <= 1'b1;

    delay_count <= T6_COUNT;

    next_state_after_delay <= ST_BUILD_FRAME_B;

    state <= ST_WAIT_SPI;

end

ST_BUILD_FRAME_B :
begin

    frame_reg <= {8'b00000001,dac_data};   // DAC B Address

    spi_start_reg <= 1'b1;

    delay_count <= T6_COUNT;

    next_state_after_delay <= ST_BUILD_FRAME_C;

    state <= ST_WAIT_SPI;

end

ST_BUILD_FRAME_C :
begin

    frame_reg <= {8'b00000010,dac_data};   // DAC C Address

    spi_start_reg <= 1'b1;

    delay_count <= T6_COUNT;

    next_state_after_delay <= ST_BUILD_FRAME_D;

    state <= ST_WAIT_SPI;

end

ST_BUILD_FRAME_D :
begin

    frame_reg <= {8'b00000011,dac_data};   // DAC D Address

    spi_start_reg <= 1'b1;

    delay_count <= T10_COUNT;

    next_state_after_delay <= ST_LDAC_LOW;

    state <= ST_WAIT_SPI;

end

ST_LDAC_LOW :
begin

    ldac_reg <= 1'b0;

    //count_rst <= 1'b0;

    delay_count <= T11_COUNT;

    next_state_after_delay <= ST_LDAC_HIGH;

    state <= ST_WAIT_DELAY;

end

ST_LDAC_HIGH :
begin

    ldac_reg <= 1'b1;
    
    data_request_reg <= 1'b0;
    
    state <= ST_READY;

end

default:
begin
    state <= ST_RESET;
end

        endcase

    end

end

// counter 

always @(posedge clk or posedge count_rst ) begin

if ( count_rst)
counter <=0;

else if (count_en)
counter <= counter +1 ;

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
