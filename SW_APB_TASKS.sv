//-----------------------------Task Definitions Start Here----------------------------------------

/* Reset Logic*/
task automatic RESET_LOGIC(const ref clk, ref rstn);

    repeat(2)
	@(posedge clk);
    
    @(posedge clk);
    #1; 
    rstn = 1'b0;

    repeat(2)
	@(posedge clk);

    @(posedge clk);
    #1; 
    rstn = 1'b1;

endtask

/* Single Read Instrn Issue*/
task automatic APB_READ_INSTRN_ISSUE(const ref pclk,
				     input [ADDR_WIDTH - 1:0] paddr,
				     input [SLAVE_ID_WIDTH - 1:0] pslave_id,			
				     input [MASTER_ID_WIDTH - 1:0] pmaster_id			
			            );
@(posedge pclk) 
#1;
TB_PMASTER_ID = pmaster_id;
TB_PADDR_VALID = (1 << pmaster_id);
TB_PADDR = paddr;
TB_PWRITE = 1'b0;
TB_PSLAVE_ID = pslave_id;

@(posedge pclk)
wait(TB_PADDR_READY == (1 << pmaster_id));
#1;
TB_PADDR_VALID = 'h0;

endtask


/* Single Write Instrn Issue*/
task automatic APB_WRITE_INSTRN_ISSUE(const ref pclk,
			              input [ADDR_WIDTH - 1:0] paddr,
				      input [DATA_WIDTH - 1:0] pwdata,
				      input [SLAVE_ID_WIDTH - 1:0] pslave_id,			
				      input [MASTER_ID_WIDTH - 1:0] pmaster_id			
			      	     );
@(posedge pclk) 
#1;
TB_PMASTER_ID = pmaster_id;
TB_PADDR_VALID = (1 << pmaster_id);
TB_PADDR = paddr;
TB_PWRITE = 1'b1 ;
TB_PWDATA_VALID = (1 << pmaster_id);
TB_PWDATA = pwdata;
TB_PSLAVE_ID = pslave_id;

@(posedge pclk)
wait(TB_PADDR_READY == (1 << pmaster_id));
#1;
TB_PADDR_VALID = 'h0;
TB_PWRITE = 1'b0;

wait(TB_PWDATA_READY == (1 << pmaster_id));
TB_PWDATA_VALID = 'h0;

endtask


/* Multiple Write Instrn Issue*/
task automatic APB_MULT_WRITE_INSTRN_ISSUE(const ref pclk,
					   input  int paddr[],
				      	   input  int pwdata[],
				      	   input  int pslave_id[],			
				      	   input  int pmaster_id[]			
					  );
@(posedge pclk) 
#1;

TB_PADDR_VALID = '0;
TB_PWDATA_VALID = '0;
TB_PWRITE = '0;
TB_PWDATA = '0;
TB_PSLAVE_ID = '0;
TB_PMASTER_ID = '0;
TB_PADDR = '0;

foreach (pmaster_id[i]) begin
    TB_PADDR_VALID[pmaster_id[i]] = 1'b1;
    TB_PADDR[pmaster_id[i]] = paddr[i];
    TB_PWDATA_VALID[pmaster_id[i]] = 1'b1;
    TB_PWRITE[pmaster_id[i]] = 1'b1;
    TB_PWDATA[pmaster_id[i]] = pwdata[i];
    TB_PSLAVE_ID[pmaster_id[i]] = pslave_id[i];
    TB_PMASTER_ID[pmaster_id[i]] = pmaster_id[i];
end

@(posedge pclk)
wait(TB_PADDR_READY == TB_PADDR_VALID);
#1;
TB_PADDR_VALID = 'h0;
TB_PWRITE = 'h0;

wait(TB_PWDATA_READY == TB_PWDATA_VALID);
TB_PWDATA_VALID = 'h0;

endtask

/* Multiple Read Instrn Issue*/
task automatic APB_MULT_READ_INSTRN_ISSUE (const ref pclk,
					   input  int paddr[],
				      	   input  int pslave_id[],			
				      	   input  int pmaster_id[]			
					  );
@(posedge pclk) 
#1;

TB_PADDR_VALID = '0;
TB_PWRITE = '0;
TB_PWDATA = '0;
TB_PSLAVE_ID = '0;
TB_PMASTER_ID = '0;
TB_PADDR = '0;

foreach (pmaster_id[i]) begin
    TB_PADDR_VALID[pmaster_id[i]] = 1'b1;
    TB_PADDR[pmaster_id[i]] = paddr[i];
    TB_PWRITE[pmaster_id[i]] = 1'b0;
    TB_PSLAVE_ID[pmaster_id[i]] = pslave_id[i];
    TB_PMASTER_ID[pmaster_id[i]] = pmaster_id[i];
end

@(posedge pclk)
wait(TB_PADDR_READY == TB_PADDR_VALID);
#1;
TB_PADDR_VALID = 'h0;

endtask

//-----------------------------Task Definitions End Here-----------------------------------------

