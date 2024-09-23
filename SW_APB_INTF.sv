// Code your testbench here
// or browse Examples


`define NO_OF_MASTERS 4 
`define NO_OF_SLAVES  4 
`define TIME_PERIOD 10


module SW_APB_INTF ();

timeunit 1ns;
timeprecision 1ps;
  
//-----------------------------Parameter declarations Start Here---------------------------
parameter int master_mem_depth[`NO_OF_MASTERS -1 :0] = '{4,4,4,4};
parameter int slave_mem_depth[`NO_OF_SLAVES -1 :0]   = '{4,8,4,16};
parameter int slave_mem_baseaddress[`NO_OF_SLAVES -1 :0]   = '{'h700, 'h600, 'h500, 'h400};
parameter ADDR_WIDTH       = 16;
parameter DATA_WIDTH       = 32;  
parameter ARBITRATION_TYPE = 2;
parameter MASTER_ID_WIDTH  = (`NO_OF_MASTERS == 1) ? 1 : $clog2(`NO_OF_MASTERS);
parameter SLAVE_ID_WIDTH   = (`NO_OF_SLAVES == 1) ? 1 : $clog2(`NO_OF_SLAVES);

//-----------------------------Parameter declarations End Here-----------------------------


//-----------------------------Baseaddress Correctness assertion Starts Here--------------------------------
  


initial begin

for(int i = 0; i < `NO_OF_SLAVES - 1; i++) begin
    
    assert(slave_mem_baseaddress[i+1] > slave_mem_baseaddress[i]) $display("Slave %d baseaddress is okay", i+1);
    else $error("Baseaddress of slave %d should be greater than baseaddress of slave %d",i+1, i);

    assert(slave_mem_baseaddress[i+1] > end_addr_calc(DATA_WIDTH, slave_mem_depth[i], slave_mem_baseaddress[i])) $display("Slave %d address range does not overlap with slave %d address range",i, i+1);
    else $error("Baseaddress %d should be greater than %d because slave %d address range overlaps with slave %d address range",i+1, end_addr_calc(DATA_WIDTH, slave_mem_depth[i], slave_mem_baseaddress[i]),i,i+1);

end

end


//-----------------------------Baseaddress Correctness assertion Ends Here--------------------------------


//-----------------------------Wire / Register declarations Start Here---------------------------
  
logic			                            I_PCLK;
logic			                            I_PRESETN;

logic [`NO_OF_MASTERS -1 :0][ADDR_WIDTH - 1:0]      TB_PADDR;
logic [`NO_OF_MASTERS -1 :0]			    TB_PADDR_VALID;
logic [`NO_OF_MASTERS -1 :0]  			    TB_PADDR_READY;
logic [`NO_OF_MASTERS -1 :0][DATA_WIDTH - 1:0]      TB_PWDATA;
logic [`NO_OF_MASTERS -1 :0]			    TB_PWDATA_VALID;
logic [`NO_OF_MASTERS -1 :0]  			    TB_PWDATA_READY;
logic [`NO_OF_MASTERS -1 :0]   			    TB_PWRITE;
logic [`NO_OF_MASTERS - 1:0][MASTER_ID_WIDTH - 1:0] TB_PMASTER_ID;
logic [`NO_OF_MASTERS - 1:0][SLAVE_ID_WIDTH - 1:0]  TB_PSLAVE_ID;

//-----------------------------Wire / Register declarations End Here-----------------------------

//-----------------------------Include Files-----------------------------------------------

`include "./RTL/SW_APB_TASKS.sv"

//-----------------------------Include Files-----------------------------------------------
  
//-----------------------------Clock / Reset Generation Logic Start Here---------------------------

initial begin

    I_PCLK = 1'b0;
    I_PRESETN = 1'b1;
    TB_PADDR_VALID = 'h0;
    TB_PADDR = 'h0;
    TB_PWDATA_VALID = 'h0;
    TB_PWDATA = 'h0;
    TB_PWRITE = 1'b0;
    TB_PSLAVE_ID = 'h0;

    RESET_LOGIC(.clk(I_PCLK), .rstn(I_PRESETN));

    @(posedge I_PCLK);
    APB_MULT_WRITE_INSTRN_ISSUE (.pclk(I_PCLK), 
                                 .paddr('{'h700, 'h500, 'h404}),
                                 .pwdata('{'hab, 'hcd, 'hef}),
                                 .pslave_id('{'h3, 'h1, 'h0}),
                                 .pmaster_id('{'h1, 'h0, 'h3})
                            	);
   
    repeat (10)
    @(posedge I_PCLK);

    APB_MULT_READ_INSTRN_ISSUE  (.pclk(I_PCLK), 
			         			 .paddr('{'h700, 'h500, 'h404}),
                                 .pslave_id('{'h3, 'h1, 'h0}),
                                 .pmaster_id('{'h3, 'h2, 'h1})
                           		);

    repeat (200) 
    @(posedge I_PCLK);
    
    #50;
    $finish;
end
  
always #(`TIME_PERIOD) I_PCLK = ~I_PCLK;

//-----------------------------Clock / Reset Generation Logic End Here-----------------------------


//-----------------------------Master/Slave Interface Instantiation Starts Here----------------------------------
  
APB_MASTER_SLAVE #(.ADDR_WIDTH(ADDR_WIDTH), 	         
                   .DATA_WIDTH(DATA_WIDTH), 	         
                   .NO_OF_SLAVES(`NO_OF_SLAVES),	 
                   .NO_OF_MASTERS(`NO_OF_MASTERS),        
                   .SLAVE_ID_WIDTH(SLAVE_ID_WIDTH),       
                   .MASTER_ID_WIDTH(MASTER_ID_WIDTH),       
		   		   .ARBITRATION_TYPE(ARBITRATION_TYPE),
                   .master_mem_depth(master_mem_depth), 	 
                   .slave_mem_depth(slave_mem_depth),	 
                   .slave_mem_baseaddress(slave_mem_baseaddress)
		  )master_slave_if(
                            .I_PCLK,
                            .I_PRESETN,
                            .TB_PADDR,
                            .TB_PADDR_VALID,
                            .TB_PADDR_READY,
                            .TB_PWDATA,
                            .TB_PWDATA_VALID,
                            .TB_PWDATA_READY,
                            .TB_PWRITE,
                            .TB_PSLAVE_ID
				  		  );
  
//-----------------------------Master/Slave Interface Instantiation Ends Here------------------------------------

endmodule
