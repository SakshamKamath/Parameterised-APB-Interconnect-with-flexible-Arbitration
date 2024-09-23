module APB_MEM #(
    parameter MEM_DEPTH   = 1,
    parameter MEM_WIDTH   = 1,
    parameter BASEADDRESS = 0,

    /* Computed Parameters */
    parameter ADDR_WIDTH = $clog2(MEM_DEPTH)

)(
    input    wire		      		  rst_n,
    input    wire    		          clk,
    input    wire  [ADDR_WIDTH - 1:0] addr,
    input    wire    		          wr_en,
    input    wire  [MEM_WIDTH - 1:0]  wr_data,
    input    wire    		          rd_en,
    output   wire  [MEM_WIDTH - 1:0]  rd_data
);

//-----------------------------Wire / Register declarations Start Here---------------------------
logic [MEM_DEPTH - 1:0][MEM_WIDTH - 1:0]MEM; //Packed Array only to view in Verdi
logic [MEM_WIDTH - 1:0] reg_rd_data;

//-----------------------------Wire / Register declarations End Here-----------------------------


//-----------------------------Main Code Starts Here--------------------------------

always_ff @(posedge clk) begin : MEM_WR_CTRL_BLOCK

    if(!rst_n)begin : RST_EN_BLOCK
	MEM    <=   '0;
        reg_rd_data <=   'h0;
    end : RST_EN_BLOCK

    else begin : RST_DIS_BLOCK

	if(wr_en)begin : WR_DATA_BLOCK
	    MEM[addr]	<= wr_data;
	end : WR_DATA_BLOCK

	if(rd_en)begin : RD_DATA_BLOCK
	    reg_rd_data         <= MEM[addr];
	end : RD_DATA_BLOCK
	else begin
	    reg_rd_data         <= 'h0;
	end

    end : RST_DIS_BLOCK

end : MEM_WR_CTRL_BLOCK

//-----------------------------Main Code Ends Here----------------------------------


//-----------------------------Output Assignments Start Here-----------------------------
assign rd_data = rd_en ? MEM[addr] : 'h0 /*reg_rd_data*/;

//-----------------------------Output Assignments End Here-------------------------------

endmodule
