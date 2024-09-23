module APB_MASTER_SLAVE_INTERCONNECT #(
	parameter  NO_OF_SLAVES      =    1,
	parameter  NO_OF_MASTERS     =    1,
	parameter  MASTER_ID_WIDTH   =    1,
	parameter  SLAVE_ID_WIDTH    =    1,
	parameter  ARBITRATION_TYPE  =    1,
	parameter  ADDR_WIDTH	     =    16,
	parameter  DATA_WIDTH	     =    32

)(
	input                                                    I_PCLK,
	input                                                    I_PRESETN,
	input    [NO_OF_MASTERS - 1:0][NO_OF_SLAVES - 1:0]  	 IFM_PSEL,
  	input    [NO_OF_MASTERS - 1:0]			     	 		 IFM_PENABLE,
  	input    [NO_OF_MASTERS - 1:0]		     		 		 IFM_PWRITE,
	input    [NO_OF_MASTERS - 1:0][ADDR_WIDTH - 1:0]    	 IFM_PADDR,
	input    [NO_OF_MASTERS - 1:0][DATA_WIDTH - 1:0]    	 IFM_PWDATA,
    input    [NO_OF_SLAVES - 1:0]  			 	 			 IFS_PSLVERR,
    input    [NO_OF_SLAVES - 1:0][DATA_WIDTH - 1:0]  	 	 IFS_PRDATA,
    input    [NO_OF_SLAVES - 1:0]  			 			 	 IFS_PREADY,
    output   [NO_OF_MASTERS - 1:0]	     		 		 	 OTM_PSLVERR,
    output   [NO_OF_SLAVES - 1:0]  			 				 OTS_PSEL,
    output   		  			 	 						 OTS_PENABLE,
    output   		  			 							 OTS_PWRITE,
    output   [ADDR_WIDTH - 1:0]    			 	 			 OTS_PADDR,
    output   [DATA_WIDTH - 1:0]    			 	 			 OTS_PWDATA,
    output   [DATA_WIDTH - 1:0]    			 	 			 OTM_PRDATA,
    output   [NO_OF_MASTERS - 1:0] 			 	 			 OTM_PREADY

);
  
//-----------------------------Include Files Start Here-----------------------------
`include "./RTL/APB_FUNCTION_DECODING.sv"

//-----------------------------Include Files End Here-----------------------------

//-----------------------------Function Definitions Start Here-----------------------------

function automatic void one_hot_to_bin(
                                        const ref logic [NO_OF_MASTERS - 1:0]   ONE_HOT,
                                        output     	[MASTER_ID_WIDTH - 1:0] BIN
                                      	);

begin
	BIN = '0;
	for(int i = 0; i < NO_OF_MASTERS; i++) begin
		if(ONE_HOT[i] == 1'b1) BIN = i;
	end
end

endfunction


//-----------------------------Function Definitions End Here-----------------------------
//-----------------------------Wire / Register declarations Start Here---------------------------

logic [NO_OF_MASTERS - 1:0]otm_pslverr;
logic [NO_OF_SLAVES - 1:0] ots_psel;
logic 			   		   ots_penable;
logic 			   		   ots_pwrite;
logic [ADDR_WIDTH - 1:0]   ots_paddr;
logic [DATA_WIDTH - 1:0]   ots_pwdata;
logic [DATA_WIDTH - 1:0]   otm_prdata;
logic [NO_OF_MASTERS - 1:0]otm_pready;

logic [NO_OF_MASTERS - 1:0]req;
logic [NO_OF_MASTERS - 1:0]locked_req;
logic [NO_OF_MASTERS - 1:0]mask;
logic [NO_OF_MASTERS - 1:0]mask_nxt;

logic [NO_OF_MASTERS - 1:0]   grant;
logic [MASTER_ID_WIDTH - 1:0] grant_master_idx;

logic [SLAVE_ID_WIDTH - 1:0] locked_slave_idx;



//-----------------------------Wire / Register declarations End Here-----------------------------
enum {IDLE_BIT              = 0,
      BUS_TRNSCN_SETUP_BIT  = 1,  
      BUS_TRNSCN_ACCESS_BIT = 2  
     } state_bit;


enum logic [2:0] {IDLE              = 3'b001 << IDLE_BIT,
		  		  BUS_TRNSCN_SETUP  = 3'b001 << BUS_TRNSCN_SETUP_BIT,  
		  		  BUS_TRNSCN_ACCESS = 3'b001 << BUS_TRNSCN_ACCESS_BIT  
		 		 } BUS_State, BUS_NxtState;


always_ff @(posedge I_PCLK)begin :BUS_FSM 

    if(!I_PRESETN)begin
	BUS_State   <=   IDLE;
    end

    else begin
	BUS_State   <=   BUS_NxtState;
    end

end : BUS_FSM
  
  
always_comb begin : NXT_STATE_LOGIC

    BUS_NxtState = BUS_State;
    case(1'b1) 
		BUS_State[IDLE_BIT]	                : begin
						      					if(|(req))begin
                                                  BUS_NxtState = BUS_TRNSCN_SETUP;
                                              	end
                                              end

		BUS_State[BUS_TRNSCN_SETUP_BIT]	        : begin
						      						BUS_NxtState = BUS_TRNSCN_ACCESS;
				                  				  end

		BUS_State[BUS_TRNSCN_ACCESS_BIT]        : begin
                                                    if(otm_pready)begin
                                                        BUS_NxtState = IDLE;
                                                    end
                                                  end
    endcase

end : NXT_STATE_LOGIC


genvar idx;
generate
    for(idx = 0; idx < NO_OF_MASTERS; idx++) begin
	assign req[idx]      = |IFM_PSEL[idx];
    end
endgenerate  
  
  
always_comb begin

    ots_psel   = 'h0;
    ots_paddr  = 'h0;
    ots_pwrite = 'h0;
    ots_pwdata = 'h0;

    if(BUS_State inside {BUS_TRNSCN_SETUP, BUS_TRNSCN_ACCESS}) begin
	ots_psel		     = IFM_PSEL[grant_master_idx];
	ots_paddr  		     = IFM_PADDR[grant_master_idx];
	ots_pwrite		     = IFM_PWRITE[grant_master_idx];
	ots_pwdata		     = IFM_PWDATA[grant_master_idx];
    end

end
  
always_comb begin

    ots_penable = 'h0;
    otm_pready  = 'h0;
    otm_prdata  = 'h0;
    otm_pslverr = 'h0;

    if(BUS_State inside {BUS_TRNSCN_ACCESS}) begin
	ots_penable		      = IFM_PENABLE[grant_master_idx];
	otm_pready[grant_master_idx]  = IFS_PREADY[locked_slave_idx];
	otm_prdata		      = IFS_PRDATA[locked_slave_idx];
    end

    if(BUS_State inside {BUS_TRNSCN_SETUP, BUS_TRNSCN_ACCESS}) begin
        otm_pslverr[grant_master_idx] = IFS_PSLVERR[locked_slave_idx];
    end

end

always_ff @(posedge I_PCLK) begin

    if(!I_PRESETN)begin
	locked_req <= 'h0;
	mask	   <= '1;
    end
    else begin
	if (BUS_State inside {IDLE}) begin
    	    locked_req <= req;
	    if(mask != mask_nxt)begin
	        mask   <= mask_nxt;
	    end
    	end
    end

end

/* Fixed Priority Arbitration */
genvar master_idx;
generate

    if(ARBITRATION_TYPE == 1)begin : fixed_priority_arbitration
	
	for(master_idx = 0; master_idx < NO_OF_MASTERS; master_idx++) begin
    	    if(master_idx == 0) begin 
    	        assign grant[0] = locked_req[0];
    	    end
    	    else begin 
    	        assign grant[master_idx] = locked_req[master_idx] & !(|grant[master_idx-1:0]);
    	    end
    	end
	
    end : fixed_priority_arbitration

    else if(ARBITRATION_TYPE == 2) begin : biased_round_robin_arbitration

	for(master_idx = 0; master_idx < NO_OF_MASTERS; master_idx++) begin
    	    if(master_idx == 0) begin 
    	        assign grant[0] = mask[0] & locked_req[0];
    	    end
    	    else begin 
    	        assign grant[master_idx] = mask[master_idx] & locked_req[master_idx] & !(|grant[master_idx-1:0]);
    	    end
    	end

    end : biased_round_robin_arbitration

endgenerate


/* Mask Update Logic */
generate 
    
    if(ARBITRATION_TYPE == 1)begin : fixed_priority_arbitration_mask_upd_logic
	always_comb begin
		mask_nxt = '1;
	end
    end : fixed_priority_arbitration_mask_upd_logic
  

    else if(ARBITRATION_TYPE == 2) begin : biased_round_robin_arbitration_mask_upd_logic
	always_comb begin
		if((mask == 'h0) | (mask & req == 0)) begin
		    mask_nxt = '1;
		end
		else begin
		    mask_nxt = mask & ~grant;
		end
	end
    end : biased_round_robin_arbitration_mask_upd_logic


endgenerate

/*One Hot to Binary Conversion Logic */

always_comb begin
   
    one_hot_to_bin(.ONE_HOT(grant),
		   .BIN(grant_master_idx)
		  );


    one_hot_to_bin(.ONE_HOT(ots_psel),
		   .BIN(locked_slave_idx)
		  );

end
  
//-----------------------------Output Assignments Start Here-----------------------------

assign OTS_PSEL    = ots_psel; 
assign OTM_PSLVERR = otm_pslverr; 
assign OTS_PENABLE = ots_penable; 
assign OTS_PWRITE  = ots_pwrite; 
assign OTS_PADDR   = ots_paddr; 
assign OTS_PWDATA  = ots_pwdata; 
assign OTM_PRDATA  = otm_prdata; 
assign OTM_PREADY  = otm_pready; 


//-----------------------------Output Assignments End Here-------------------------------

endmodule
  
  
  
  
  
  
  
  
