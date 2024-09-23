
module APB_FIFO #(
    parameter MEM_DEPTH = 1,
    parameter MEM_WIDTH = 1
)(
    input    wire		      	  	  rst_n,
    input    wire    		          clk,
    input    wire    		      	  wr_en,
    input    wire  [MEM_WIDTH - 1:0]  wr_data,
    input    wire    		      	  rd_en,
    output   wire  [MEM_WIDTH - 1:0]  rd_data,
    output   wire		      		  empty, 
    output   wire    		      	  full, 
    output   wire		      		  empty_pre, 
    output   wire    		      	  full_pre,
    output   wire		      		  trnscn_cont 
);
  
//-----------------------------Local Parameters Start Here---------------------------
localparam PTR_WIDTH = $clog2(MEM_DEPTH);

//-----------------------------Local Parameters End Here-----------------------------



//-----------------------------Wire / Register declarations Start Here---------------------------
logic [PTR_WIDTH  :0]  rd_ptr;
logic [PTR_WIDTH  :0]  wr_ptr;


//-----------------------------Wire / Register declarations End Here-----------------------------


logic [MEM_DEPTH - 1:0][MEM_WIDTH - 1:0]FIFO_MEM; //Packed Array only to view in Verdi
  
always_ff @(posedge clk) begin : FIFO_WR_CTRL_BLOCK

    if(!rst_n)begin : RST_EN_BLOCK
	FIFO_MEM    <=   '0;
	wr_ptr	    <=   'h0;
    end : RST_EN_BLOCK

    else begin : RST_DIS_BLOCK

	if(wr_en && !full)begin : WR_DATA_BLOCK
	    FIFO_MEM[wr_ptr]	<= wr_data;
	    wr_ptr		<= wr_ptr + 1'b1;
	end : WR_DATA_BLOCK

    end : RST_DIS_BLOCK

end : FIFO_WR_CTRL_BLOCK

always_ff @(posedge clk) begin : FIFO_RD_CTRL_BLOCK

    if(!rst_n)begin : RST_EN_BLOCK
	FIFO_MEM    <=   '0;
	rd_ptr	    <=   'h0;
    end : RST_EN_BLOCK

    else begin : RST_DIS_BLOCK

	if(rd_en && !empty)begin : RD_DATA_BLOCK
	    rd_ptr		<= rd_ptr + 1'b1;
	end : RD_DATA_BLOCK

    end : RST_DIS_BLOCK

end : FIFO_RD_CTRL_BLOCK
  
//-----------------------------Output Assignments Start Here-----------------------------
assign full	 = ((wr_ptr ^ rd_ptr) == (1 << PTR_WIDTH)) ? 1'b1 : 1'b0 ;
assign empty	 = (wr_ptr == rd_ptr) ? 1'b1 : 1'b0 ;

assign full_pre	 = (((wr_ptr + 1'b1) ^ rd_ptr) == (1 << PTR_WIDTH)) ? 1'b1 : 1'b0 ;
assign empty_pre = (wr_ptr == (rd_ptr + 1'b1)) ? 1'b1 : 1'b0 ;

assign rd_data  = FIFO_MEM[rd_ptr[PTR_WIDTH - 1:0]];

assign trnscn_cont = (FIFO_MEM[rd_ptr[PTR_WIDTH - 1:0]] == FIFO_MEM[rd_ptr[PTR_WIDTH - 1:0] + 1'b1]);

//-----------------------------Output Assignments End Here-------------------------------

endmodule
