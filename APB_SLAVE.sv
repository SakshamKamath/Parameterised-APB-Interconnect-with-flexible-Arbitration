`include "./RTL/APB_FUNCTION_DECODING.sv"

module APB_SLAVE #(
    parameter MEM_DEPTH   = 1,
    parameter ADDR_WIDTH  = 16,
    parameter DATA_WIDTH  = 32,
    parameter BASEADDRESS = 0,

/* Computed Parameter*/
    parameter ENDADDRESS = end_addr_calc(DATA_WIDTH, MEM_DEPTH, BASEADDRESS)


)(
    input   wire                                    I_PCLK,
    input   wire                                    I_PRESETN,
    input   wire    [ADDR_WIDTH - 1:0]              I_PADDR,
    input   wire				    				I_PSEL,
    input   wire                        	    	I_PENABLE,
    input   wire                        	    	I_PWRITE,
    input   wire    [DATA_WIDTH - 1:0]              I_PWDATA,
    output  wire				    				O_PREADY,
    output  wire    [DATA_WIDTH - 1:0]              O_PRDATA,
    output  wire				    				O_PSLVERR
);

//-----------------------------Wire / Register declarations Start Here---------------------------
logic fifo_wr_en1;
logic fifo_wr_en2;
logic fifo_wr_en;
logic fifo_rd_en;
logic r_pready;

//-----------------------------Wire / Register declarations End Here-----------------------------

//-----------------------------Local Parameter Declarations Start Here-------------------------------

localparam ADDR_LSB = $clog2(DATA_WIDTH/8);
localparam ADDR_MSB = $clog2(MEM_DEPTH);

//-----------------------------Local Parameter Declarations Start Here-------------------------------


//-----------------------------MEM instantiation Starts Here-----------------------------

APB_MEM #(.MEM_DEPTH(MEM_DEPTH), 
           .MEM_WIDTH(DATA_WIDTH)
)apb_slave_mem(
    .rst_n	(I_PRESETN),
    .clk	(I_PCLK),
    .addr	(I_PADDR[ADDR_MSB + ADDR_LSB - 1:ADDR_LSB]),
    .wr_en	(fifo_wr_en),
    .wr_data(I_PWDATA),
    .rd_en	(fifo_rd_en),
    .rd_data(O_PRDATA)
);

//-----------------------------MEM instantiation Ends Here--------------------------------

//-----------------------------APB FSM Starts Here-----------------------------
enum {IDLE_BIT	    = 0,
      SETUP_BIT	    = 1, 
      ACCESS_BIT    = 2 
} state_bit;

enum logic[2:0] {IDLE	= 3'b001 << IDLE_BIT,
		 		 SETUP	= 3'b001 << SETUP_BIT,
		 		 ACCESS = 3'b001 << ACCESS_BIT
				}APB_State, APB_NxtState;
always_ff @(posedge I_PCLK)begin : APB_FSM

    if(!I_PRESETN)begin
	APB_State   <=   IDLE;
    end

    else begin
	APB_State   <=   APB_NxtState;
    end

end : APB_FSM

always_comb begin : NXT_STATE_LOGIC

    APB_NxtState = APB_State;
    case(1'b1) 
      APB_State[IDLE_BIT]	: begin if(I_PSEL) APB_NxtState = SETUP; end

	  APB_State[SETUP_BIT]	: begin APB_NxtState = ACCESS; end

	  APB_State[ACCESS_BIT]	: begin
				              if(O_PREADY) begin
				                if(I_PSEL) APB_NxtState = SETUP;
				                else APB_NxtState = IDLE;
				              end
				              end
    endcase

end : NXT_STATE_LOGIC

//-----------------------------APB FSM Ends Here-----------------------------


//-----------------------------FIFO control Starts Here-----------------------------
assign fifo_wr_en1 = (APB_State == ACCESS) && I_PWRITE && O_PREADY && I_PENABLE && !O_PSLVERR;
assign fifo_wr_en2 = (APB_State == SETUP) && I_PWRITE && O_PREADY && I_PENABLE && !O_PSLVERR;
assign fifo_rd_en1 = (APB_State == ACCESS) && !I_PWRITE && O_PREADY && I_PENABLE &&  !O_PSLVERR;
assign fifo_rd_en2 = (APB_State == SETUP) && !I_PWRITE && O_PREADY && I_PENABLE && !O_PSLVERR;

assign fifo_wr_en = fifo_wr_en1 | fifo_wr_en2;
assign fifo_rd_en = fifo_rd_en1 | fifo_rd_en2;


//-----------------------------FIFO control Ends Here--------------------------------

//-----------------------------Output Assignments Start Here-----------------------------
assign O_PREADY  = 1'b1;
assign O_PSLVERR = (I_PSEL == 1'b1) ? !(I_PADDR inside {[BASEADDRESS:ENDADDRESS-1]}) : 1'b0;

//-----------------------------Output Assignments End Here-------------------------------

endmodule
