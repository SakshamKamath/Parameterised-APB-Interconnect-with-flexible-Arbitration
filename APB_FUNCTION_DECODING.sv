function automatic end_addr_calc(
                                  input int DATA_WIDTH,
                                  input int MEM_DEPTH,
                                  input int BASEADDRESS
		     					 );

begin
    end_addr_calc = BASEADDRESS + (DATA_WIDTH * MEM_DEPTH)/8 ;
end

endfunction
