module APB_MASTER_SLAVE #(
	parameter      ADDR_WIDTH									=    1,
	parameter      DATA_WIDTH 	         						=    1,
	parameter      SLAVE_ID_WIDTH         	                    =    1,
	parameter      MASTER_ID_WIDTH								=    1,
	parameter      NO_OF_SLAVES 		                        =    1,
	parameter      NO_OF_MASTERS                                =    1,
	parameter      ARBITRATION_TYPE								=    1,
	parameter int  master_mem_depth      [NO_OF_MASTERS - 1:0] 	= '{4},
	parameter int  slave_mem_depth       [NO_OF_SLAVES  - 1:0] 	= '{4},
	parameter int  slave_mem_baseaddress [NO_OF_SLAVES  - 1:0]	= '{0}

)(

//Global clock and reset signals
    input   wire				    I_PCLK,
    input   wire				    I_PRESETN,

//tb related signals
    input   wire    [NO_OF_MASTERS - 1:0][ADDR_WIDTH - 1:0]     TB_PADDR,
    input   wire    [NO_OF_MASTERS - 1:0]	    			 	TB_PADDR_VALID,
    output  wire    [NO_OF_MASTERS - 1:0]	    			 	TB_PADDR_READY,
    input   wire    [NO_OF_MASTERS - 1:0][DATA_WIDTH - 1:0]     TB_PWDATA,
    input   wire    [NO_OF_MASTERS - 1:0]           			TB_PWDATA_VALID,
    output  wire    [NO_OF_MASTERS - 1:0]           			TB_PWDATA_READY,
  	input   wire    [NO_OF_MASTERS - 1:0]	    			    TB_PWRITE,
    input   wire    [NO_OF_MASTERS - 1:0][SLAVE_ID_WIDTH - 1:0]	TB_PSLAVE_ID
);


//-----------------------------Local Parameters Start Here---------------------------
localparam PSEL_WIDTH = NO_OF_SLAVES;

//-----------------------------Local Parameters End Here-----------------------------


//-----------------------------Wire / Register declarations Start Here---------------------------


struct packed { 
                logic [NO_OF_MASTERS - 1:0]	apb_bus_pslverr;
                logic [DATA_WIDTH - 1:0] 	apb_bus_prdata ;
                logic [NO_OF_MASTERS - 1:0]	apb_bus_pready ;
	          } apb_bus_otm_t;

struct packed { 
                logic [NO_OF_MASTERS - 1:0][PSEL_WIDTH - 1:0] apb_bus_psel		;
  				logic [NO_OF_MASTERS - 1:0]		      		  apb_bus_penable   ;
                logic [NO_OF_MASTERS - 1:0]		      		  apb_bus_pwrite    ;
  				logic [NO_OF_MASTERS - 1:0][ADDR_WIDTH - 1:0] apb_bus_paddr	    ;
                logic [NO_OF_MASTERS - 1:0][DATA_WIDTH - 1:0] apb_bus_pwdata	;
	          } apb_bus_ifm_t;

struct packed { 
                logic [PSEL_WIDTH - 1:0]   apb_bus_psel	  ;
                logic 			   		   apb_bus_penable;
                logic 			   		   apb_bus_pwrite ;
                logic [ADDR_WIDTH - 1:0]   apb_bus_paddr  ;
                logic [DATA_WIDTH - 1:0]   apb_bus_pwdata ;
	          } apb_bus_ots_t;

struct packed { 
  				logic [NO_OF_SLAVES - 1:0]		       		   apb_bus_pslverr;
				logic [NO_OF_SLAVES - 1:0][DATA_WIDTH - 1:0]   apb_bus_prdata ;
  				logic [NO_OF_SLAVES - 1:0]		       		   apb_bus_pready ;
	      } apb_bus_ifs_t;

struct packed { 
				logic [NO_OF_MASTERS - 1:0]		       bus_access_req;
	          } arbiter_bus_req_t;

struct packed { 
				logic [NO_OF_MASTERS - 1:0]		       bus_access_grant;
	     	  } arbiter_bus_grant_t;


//-----------------------------Wire / Register declarations End Here---------------------------


//-----------------------------Master Instantiation Starts Here----------------------------------
  
generate

    for(master_idx = 0; master_idx < NO_OF_MASTERS; master_idx++)begin
	APB_MASTER #(.ADDR_WIDTH(ADDR_WIDTH), 
		     .DATA_WIDTH(DATA_WIDTH),
		     .MEM_DEPTH(master_mem_depth[master_idx]),
		     .SLAVE_ID_WIDTH(SLAVE_ID_WIDTH),
		     .NO_OF_SLAVES(NO_OF_SLAVES)
                    )master(
			    			.I_PCLK,
                            .I_PRESETN,
                            .TB_PADDR        	   (TB_PADDR[master_idx]		            	),
                            .TB_PADDR_VALID        (TB_PADDR_VALID[master_idx]		            ),
			    			.TB_PADDR_READY        (TB_PADDR_READY[master_idx]		            ),
      						.TB_PWDATA		   	   (TB_PWDATA[master_idx]			            ),
                            .TB_PWDATA_VALID       (TB_PWDATA_VALID[master_idx]		            ),
			    			.TB_PWDATA_READY       (TB_PWDATA_READY[master_idx]		            ),
      						.TB_PWRITE       	   (TB_PWRITE[master_idx]			            ),
			    			.TB_PSLAVE_ID          (TB_PSLAVE_ID[master_idx]			    	),
                            .I_PREADY 		  	   (apb_bus_otm_t.apb_bus_pready[master_idx]    ),
                            .I_PRDATA 		   	   (apb_bus_otm_t.apb_bus_prdata 	            ),
                            .I_PSLVERR		       (apb_bus_otm_t.apb_bus_pslverr[master_idx]   ),
                            .O_PSEL   		       (apb_bus_ifm_t.apb_bus_psel[master_idx]      ),
                            .O_PENABLE		       (apb_bus_ifm_t.apb_bus_penable[master_idx]   ),
                            .O_PWRITE 		       (apb_bus_ifm_t.apb_bus_pwrite[master_idx]    ),
                            .O_PADDR  		       (apb_bus_ifm_t.apb_bus_paddr[master_idx]     ),
                            .O_PWDATA 		       (apb_bus_ifm_t.apb_bus_pwdata[master_idx]    )

		           );
    end

endgenerate

//-----------------------------Master Instantiation Ends Here------------------------------------


//-----------------------------Master/Slave Interconnect Instantiation Starts Here----------------------------------
// IFM - Input From Master
// OTM - Output To Master
// IFS - Input From Slave
// OTS - Output to Slave
// The above are w.r.t the interconnect

APB_MASTER_SLAVE_INTERCONNECT #(.NO_OF_SLAVES(NO_OF_SLAVES), 
                                .NO_OF_MASTERS(NO_OF_MASTERS),
                                .MASTER_ID_WIDTH(MASTER_ID_WIDTH),
                                .SLAVE_ID_WIDTH(SLAVE_ID_WIDTH),
                                .ADDR_WIDTH(ADDR_WIDTH),	
								.ARBITRATION_TYPE(ARBITRATION_TYPE),
                                .DATA_WIDTH(DATA_WIDTH)
			       )ms_interconnect(
									.I_PCLK,
									.I_PRESETN,
									.IFM_PSEL    		(apb_bus_ifm_t.apb_bus_psel          ),
                                    .IFM_PENABLE 		(apb_bus_ifm_t.apb_bus_penable       ),
                                    .IFM_PWRITE  		(apb_bus_ifm_t.apb_bus_pwrite        ),
                                    .IFM_PADDR   		(apb_bus_ifm_t.apb_bus_paddr         ),
                                    .IFM_PWDATA  		(apb_bus_ifm_t.apb_bus_pwdata        ),
                                    .IFS_PSLVERR 		(apb_bus_ifs_t.apb_bus_pslverr       ),
                                    .IFS_PRDATA  		(apb_bus_ifs_t.apb_bus_prdata        ),
                                    .IFS_PREADY  		(apb_bus_ifs_t.apb_bus_pready        ),
                                    .OTM_PSLVERR 		(apb_bus_otm_t.apb_bus_pslverr       ),
                                    .OTS_PSEL    		(apb_bus_ots_t.apb_bus_psel          ),
                                    .OTS_PENABLE 		(apb_bus_ots_t.apb_bus_penable       ),
                                    .OTS_PWRITE  		(apb_bus_ots_t.apb_bus_pwrite        ),
                                    .OTS_PADDR   		(apb_bus_ots_t.apb_bus_paddr         ),
                                    .OTS_PWDATA  		(apb_bus_ots_t.apb_bus_pwdata        ),
                                    .OTM_PRDATA  		(apb_bus_otm_t.apb_bus_prdata        ),
                                    .OTM_PREADY  		(apb_bus_otm_t.apb_bus_pready        )
					       );


//-----------------------------Master/Slave Interconnect Instantiation Ends Here------------------------------------
  
//-----------------------------Slave Instantiation Starts Here----------------------------------

genvar slave_idx;

generate 

    for(slave_idx = 0; slave_idx < NO_OF_SLAVES; slave_idx++)begin
	
	APB_SLAVE #(.ADDR_WIDTH(ADDR_WIDTH), 
		     .DATA_WIDTH(DATA_WIDTH),
		     .MEM_DEPTH (slave_mem_depth[slave_idx]),
		     .BASEADDRESS (slave_mem_baseaddress[slave_idx])
                   )slave(
			   .I_PCLK,
		       	   .I_PRESETN,
      			   .I_PADDR  (apb_bus_ots_t.apb_bus_paddr	      	  ),
		       	   .I_PSEL   (apb_bus_ots_t.apb_bus_psel[slave_idx]   ),
      			   .I_PENABLE(apb_bus_ots_t.apb_bus_penable	     	  ),
      			   .I_PWRITE (apb_bus_ots_t.apb_bus_pwrite 	     	  ),
     			     .I_PWDATA (apb_bus_ots_t.apb_bus_pwdata	      	  ),
		       	   .O_PREADY (apb_bus_ifs_t.apb_bus_pready[slave_idx] ),
		       	   .O_PRDATA (apb_bus_ifs_t.apb_bus_prdata[slave_idx] ),
		       	   .O_PSLVERR(apb_bus_ifs_t.apb_bus_pslverr[slave_idx])
			  );


    end

endgenerate

//-----------------------------Slave Instantiation Ends Here------------------------------------

endmodule
  
  
  
  
