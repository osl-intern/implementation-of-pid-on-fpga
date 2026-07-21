
module DAC2932_CONTROLLER(
input clk,
input rst,

input start,
input [11:0] data_in,

output [11:0] dac_data,
output reg dac_clk,
output busy,
output reg done,
output cs,
output pd,
output stby);

assign cs   = 1'b0;
assign pd   = 1'b0;
assign stby = 1'b1;

reg [11:0] data_reg;

reg [2:0] state;
reg [2:0] next_state ;

assign dac_data = data_reg;
assign  busy = (state != IDLE);

localparam
IDLE            = 3'd0,
LOAD            = 3'd1,
CLOCK_HIGH      = 3'd2,
CLOCK_HIGH_HOLD = 3'd3,
CLOCK_LOW       = 3'd4,
DONE            = 3'd5;


//----------------------------------------------------------
// Sequential Logic
//----------------------------------------------------------
always @(posedge clk) begin

    if(rst) begin

        state    <= IDLE;
        data_reg <= 12'd0;
        done     <= 1'b0;

    end
    else begin

        state <= next_state;

        // default
        done <= 1'b0;

        case(state)

            LOAD:
                data_reg <= data_in;

            DONE:
                done <= 1'b1;

            default: ;

        endcase

    end

end


//----------------------------------------------------------
// Next State Logic
//----------------------------------------------------------
always @(*) begin

    next_state = state;

    case(state)

        IDLE: begin
            if(start)
                next_state = LOAD;
            else
                next_state = IDLE;
        end

        LOAD:
            next_state = CLOCK_HIGH;

        CLOCK_HIGH:
            next_state = CLOCK_HIGH_HOLD;

        CLOCK_HIGH_HOLD:
            next_state = CLOCK_LOW;

        CLOCK_LOW:
            next_state = DONE;

        DONE:
            next_state = IDLE;

        default:
            next_state = IDLE;

    endcase

end

always @(*) begin

    dac_clk = 1'b0;

    case(state)

        CLOCK_HIGH,
        CLOCK_HIGH_HOLD:
            dac_clk = 1'b1;

        default:
            dac_clk = 1'b0;

    endcase

end

endmodule 
