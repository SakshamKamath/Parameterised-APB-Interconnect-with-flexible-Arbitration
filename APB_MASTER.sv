module APB_MASTER #(
    parameter MEM_DEPTH        = 1,
    parameter ADDR_WIDTH       = 16,
    parameter DATA_WIDTH       = 32,
    parameter SLAVE_ID_WIDTH   = 1,
    parameter NO_OF_SLAVES     = 1,

    /*Computed Parameter */
    parameter PSEL_WIDTH       = NO_OF_SLAVES

)(

//Global clock and reset signals
    input   wire				    I_PCLK,
    input   wire				    I_PRESETN,

//tb related signals
    input   wire    [ADDR_WIDTH - 1:0]  	TB_PADDR,
    input   wire				    		TB_PADDR_VALID,
    output  wire				        	TB_PADDR_READY,
    input   wire    [DATA_WIDTH - 1:0]  	TB_PWDATA,
    input   wire				    		TB_PWDATA_VALID,
    output  wire				    		TB_PWDATA_READY,
    input   wire				    		TB_PWRITE,
    input   wire    [SLAVE_ID_WIDTH - 1:0]	TB_PSLAVE_ID,
    

//APB signals
    input   wire				    		I_PREADY,
    input   wire    [DATA_WIDTH - 1:0]      I_PRDATA,
    input   wire				    		I_PSLVERR,
    output  wire    [PSEL_WIDTH - 1:0]	    O_PSEL,
    output  wire			 	    		O_PENABLE,
    output  wire				    		O_PWRITE,
    output  wire    [ADDR_WIDTH - 1:0]      O_PADDR,
    output  wire    [DATA_WIDTH - 1:0]      O_PWDATA


);
//-----------------------------Wire / Register declarations Start Here---------------------------
struct packed { 
		        logic fifo_empty      ;
				logic fifo_full       ;
				logic fifo_empty_pre  ;
				logic fifo_full_pre   ;
				logic trnscn_cont     ;
	          } addr_fifo_status_t;

struct packed { 
				logic fifo_empty      ;
				logic fifo_full       ;
				logic fifo_empty_pre  ;
				logic fifo_full_pre   ;
	          } wdata_fifo_status_t;

struct packed { 
				logic fifo_rd_en  ;
	          } addr_fifo_rd_ctrl_t;
  
struct packed { 
				logic fifo_rd_en ;
	      	  } wdata_fifo_rd_ctrl_t;

struct packed { 
				logic [SLAVE_ID_WIDTH - 1:0] fifo_rd_data_pslave_id ;
				logic 			     		 fifo_rd_data_pwrite    ;
				logic [ADDR_WIDTH - 1:0]     fifo_rd_data_paddr     ;
	      	  } addr_fifo_out_t;

struct packed { 
                logic [DATA_WIDTH - 1:0] fifo_rd_data ;
	          } wdata_fifo_out_t;

struct packed { 
				logic [PSEL_WIDTH - 1:0]     psel    ;
				logic			             penable ;
				logic 			             pwrite  ;
				logic [ADDR_WIDTH - 1:0]     paddr   ;
				logic [DATA_WIDTH - 1:0]     pwdata  ;
              } apb_output_bus_t;


logic [ADDR_WIDTH + SLAVE_ID_WIDTH :0] master_addr_fifo_in;
logic [PSEL_WIDTH - 1:0] w_one_hot_psel;
  
//-----------------------------Wire / Register declarations End Here-----------------------------


//-----------------------------Assignments Start Here---------------------------
assign master_addr_fifo_in = {TB_PSLAVE_ID, TB_PWRITE, TB_PADDR};

//-----------------------------Assignments End Here-----------------------------


//-----------------------------FIFO Read Control Logic Starts Here------------------------------
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
	  APB_State[IDLE_BIT]	: begin
				      		  if(addr_fifo_status_t.fifo_empty != 1'b1 ) begin 
				          		APB_NxtState = SETUP;
				      		  end
				  			  end

	  APB_State[SETUP_BIT]	: begin
				      		  APB_NxtState = ACCESS;
				  			  end

	  APB_State[ACCESS_BIT]	: begin
				      		  if(I_PREADY) begin
					          	if(addr_fifo_status_t.fifo_empty_pre != 1'b1 && addr_fifo_status_t.trnscn_cont == 1'b1) APB_NxtState = SETUP;
					  			else APB_NxtState = IDLE;
                              end
				  			  end
    endcase

end : NXT_STATE_LOGIC



always_comb begin : PSEL_DEC_TO_ONE_HOT_LOGIC

    w_one_hot_psel = '0;
    w_one_hot_psel[addr_fifo_out_t.fifo_rd_data_pslave_id] = 1'b1;

end : PSEL_DEC_TO_ONE_HOT_LOGIC
  
assign apb_output_bus_t.psel    = {PSEL_WIDTH{(APB_State != IDLE)}} & w_one_hot_psel; 
assign apb_output_bus_t.penable = (APB_State == ACCESS);
assign apb_output_bus_t.pwrite  = ^(apb_output_bus_t.psel) && addr_fifo_out_t.fifo_rd_data_pwrite; 
assign apb_output_bus_t.paddr   = addr_fifo_out_t.fifo_rd_data_paddr;
assign apb_output_bus_t.pwdata  = wdata_fifo_out_t.fifo_rd_data;

assign addr_fifo_rd_ctrl_t.fifo_rd_en  = (APB_State == ACCESS) && I_PREADY;
assign wdata_fifo_rd_ctrl_t.fifo_rd_en = (APB_State == ACCESS) && I_PREADY;


//-----------------------------FIFO Read Control Logic Ends Here--------------------------------


//-----------------------------ADDR FIFO instantiation Starts Here------------------------------

//-----------------------------ADDR FIFO instantiation Starts Here-----------------------------

APB_FIFO #(.MEM_DEPTH(MEM_DEPTH), 
           .MEM_WIDTH(ADDR_WIDTH + 1 + SLAVE_ID_WIDTH)
)apb_master_addr_fifo(
    .rst_n	(I_PRESETN),
    .clk	(I_PCLK),
    .wr_en	(TB_PADDR_VALID),
    .wr_data	(master_addr_fifo_in),
    .rd_en	(addr_fifo_rd_ctrl_t.fifo_rd_en),
    .rd_data	(addr_fifo_out_t),
    .empty	(addr_fifo_status_t.fifo_empty), 
    .full	(addr_fifo_status_t.fifo_full), 
    .empty_pre	(addr_fifo_status_t.fifo_empty_pre), 
    .full_pre	(addr_fifo_status_t.fifo_full_pre),
    .trnscn_cont(addr_fifo_status_t.trnscn_cont) 
);

//-----------------------------ADDR FIFO instantiation Ends Here--------------------------------


//-----------------------------DATA FIFO instantiation Starts Here-----------------------------
  

APB_FIFO #(.MEM_DEPTH(MEM_DEPTH), 
           .MEM_WIDTH(DATA_WIDTH)
)apb_master_wdata_fifo(
    .rst_n	  (I_PRESETN),
    .clk	  (I_PCLK),
    .wr_en	  (TB_PWDATA_VALID),
    .wr_data  (TB_PWDATA),
    .rd_en	  (wdata_fifo_rd_ctrl_t.fifo_rd_en),
    .rd_data  (wdata_fifo_out_t.fifo_rd_data),
    .empty	  (wdata_fifo_status_t.fifo_empty), 
    .full	  (wdata_fifo_status_t.fifo_full), 
    .empty_pre(wdata_fifo_status_t.fifo_empty_pre), 
    .full_pre (wdata_fifo_status_t.fifo_full_pre),
    .trnscn_cont() 
);

//-----------------------------DATA FIFO instantiation Ends Here--------------------------------
  
//-----------------------------Output Assignments Start Here-----------------------------

assign O_PSEL     =  apb_output_bus_t.psel    ;
assign O_PENABLE  =  apb_output_bus_t.penable ;
assign O_PWRITE   =  apb_output_bus_t.pwrite  ;
assign O_PADDR    =  apb_output_bus_t.paddr   ;
assign O_PWDATA   =  apb_output_bus_t.pwdata  ; 

assign TB_PADDR_READY  = TB_PADDR_VALID && !addr_fifo_status_t.fifo_full;
assign TB_PWDATA_READY  = TB_PWDATA_VALID && !wdata_fifo_status_t.fifo_full;

//-----------------------------Output Assignments End Here-------------------------------

endmodule
