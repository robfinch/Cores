if (branchmiss) begin
	$display("pc <= %h", misspc);
	pc <= misspc;
	fetchbuf <= 1'b0;
	fetchbufA_v <= 1'b0;
	fetchbufB_v <= 1'b0;
	fetchbufC_v <= 1'b0;
	fetchbufD_v <= 1'b0;
	fetchbufE_v <= 1'b0;
	fetchbufF_v <= 1'b0;
end
else if (take_branch) begin
	if (fetchbuf == 1'b0) begin
		casex ({fetchbufA_v,fetchbufB_v,fetchbufC_v,fetchbufD_v,fetchbufE_v,fetchbufF_v})
		6'b000000:
			begin
			    fetchDEF();
				if (do_pcinc) pc <= pc + 32'd16;
				fetchbuf <= ~fetchbuf;
			end
		6'b000001:    panic <= `PANIC_INVALIDFBSTATE;
		6'b000010:    panic <= `PANIC_INVALIDFBSTATE;
		6'b000011:    panic <= `PANIC_INVALIDFBSTATE;
		6'b000100:    panic <= `PANIC_INVALIDFBSTATE;
		6'b000101:    panic <= `PANIC_INVALIDFBSTATE;
		6'b000110:    panic <= `PANIC_INVALIDFBSTATE;
		6'b000111:    panic <= `PANIC_INVALIDFBSTATE;
		6'b001000:
			begin
			    fetchDEF();
				if (do_pcinc) pc <= pc + 32'd16;
				fetchbufC_v <= !(queued1|queuedNop);
				if (queued1|queuedNop)
					fetchbuf <= ~fetchbuf;
			end
		6'b001001:    panic <= `PANIC_INVALIDFBSTATE;
		6'b001010:    panic <= `PANIC_INVALIDFBSTATE;
		6'b001011:    panic <= `PANIC_INVALIDFBSTATE;
		6'b001100:    panic <= `PANIC_INVALIDFBSTATE;
		6'b001101:    panic <= `PANIC_INVALIDFBSTATE;
		6'b001110:    panic <= `PANIC_INVALIDFBSTATE;
		6'b001111:    
			begin
                fetchbufC_v <= !(queued1|queuedNop);
                if (queued1|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b010000:
			begin
			    fetchDEF();
                if (do_pcinc) pc <= pc + 32'd16;
                fetchbufB_v <= !(queued1|queuedNop);
                if (queued1|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b010001:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010010:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010011:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010100:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010101:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010110:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010111:
            begin
                fetchbufB_v <= !(queued1|queuedNop);
                if (queued1|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b011000:
            begin
                if (IsBranch(instrB) & predict_takenB) begin
                    pc <= branch_pc;
                    fetchbufB_v <= !(queued1|queuedNop);
                    fetchbufC_v <= `INV;
                end
                else begin
                    if (did_branchback0) begin
                        fetchDEF();
                        if (do_pcinc) pc <= pc + 32'd16;
                        fetchbufB_v <= !(queued1|queuedNop);
                        fetchbufC_v <= !(queued2|queuedNop);
                        if (queued2|queuedNop)
                            fetchbuf <= ~fetchbuf;
                    end
                    else begin
                        pc <= branch_pc;
                        fetchbufB_v <= !(queued1|queuedNop);
                        fetchbufC_v <= !(queued2|queuedNop);
                    end
                end
            end
        6'b011001:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011010:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011011:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011100:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011101:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011110:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011111:
            begin
                fetchbufB_v <= !(queued1|queuedNop);
                fetchbufC_v <= !(queued2|queuedNop);
                if (queued2|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b100000:
            begin
                fetchDEF();
                if (do_pcinc) pc <= pc + 32'd16;
                fetchbufA_v <= !(queued1|queuedNop);
                if (queued1|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b100001:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100010:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100011:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100100:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100101:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100110:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100111:
            begin
                fetchbufA_v <= !(queued1|queuedNop);
                if (queued1|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b101xxx:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110000:
            begin
                if (IsBranch(instrA) && predict_takenA) begin
                    pc <= branch_pc;
                    fetchbufA_v <= !(queued1|queuedNop);
                    fetchbufB_v <= `INV;
                end
                else begin
                    if (did_branchback0) begin
                        fetchDEF();
                        if (do_pcinc) pc <= pc + 32'd16;
                        fetchbufA_v <= !(queued1|queuedNop);
                        fetchbufB_v <= !(queued2|queuedNop);
                        if (queued2|queuedNop)
                            fetchbuf <= ~fetchbuf;
                    end
                    else begin
                        pc <= branch_pc;
                        fetchbufA_v <= !(queued1|queuedNop);
                        fetchbufB_v <= !(queued2|queuedNop);
                    end
                end
            end
        6'b110001:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110010:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110011:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110100:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110101:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110110:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110111:
            begin
                if (IsBranch(instrA) & predict_takenA)
                    panic <= `PANIC_INVALIDFBSTATE;
                else begin
                    fetchbufA_v <= !(queued1|queuedNop);
                    fetchbufB_v <= !(queued2|queuedNop);
                    if (queued2|queuedNop)
                        fetchbuf <= ~fetchbuf;
                end
        6'b111000:
            begin
                fetchDEF();
                if (do_pcinc) pc <= pc + 32'd16;
                fetchbufA_v <= !(queued1|queuedNop);
                fetchbufB_v <= !(queued2|queuedNop);
                fetchbufC_v <= !(queued3|queuedNop);
                if (queued3|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b111001:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111010:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111011:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111100:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111101:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111110:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111111:  panic <= `PANIC_INVALIDFBSTATE;
            begin
                fetchbufA_v <= !(queued1|queuedNop);
                fetchbufB_v <= !(queued2|queuedNop);
                fetchbufC_v <= !(queued3|queuedNop);
                if (queued3|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        endcase
    else
		casex ({fetchbufD_v,fetchbufE_v,fetchbufF_v,fetchbufA_v,fetchbufB_v,fetchbufC_v})
        6'b000000:
            begin
                fetchABC();
                if (do_pcinc) pc <= pc + 32'd16;
                fetchbuf <= ~fetchbuf;
            end
        6'b000001:    panic <= `PANIC_INVALIDFBSTATE;
        6'b000010:    panic <= `PANIC_INVALIDFBSTATE;
        6'b000011:    panic <= `PANIC_INVALIDFBSTATE;
        6'b000100:    panic <= `PANIC_INVALIDFBSTATE;
        6'b000101:    panic <= `PANIC_INVALIDFBSTATE;
        6'b000110:    panic <= `PANIC_INVALIDFBSTATE;
        6'b000111:    panic <= `PANIC_INVALIDFBSTATE;
        6'b001000:
            begin
                fetchABC();
                if (do_pcinc) pc <= pc + 32'd16;
                fetchbufF_v <= !(queued1|queuedNop);
                if (queued1|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b001001:    panic <= `PANIC_INVALIDFBSTATE;
        6'b001010:    panic <= `PANIC_INVALIDFBSTATE;
        6'b001011:    panic <= `PANIC_INVALIDFBSTATE;
        6'b001100:    panic <= `PANIC_INVALIDFBSTATE;
        6'b001101:    panic <= `PANIC_INVALIDFBSTATE;
        6'b001110:    panic <= `PANIC_INVALIDFBSTATE;
        6'b001111:    
            begin
                fetchbufF_v <= !(queued1|queuedNop);
                if (queued1|queuedNop)
                    fetchbuf <= 1'b1;
            end
        6'b010000:
            begin
                fetchABC();
                if (do_pcinc) pc <= pc + 32'd16;
                fetchbufE_v <= !(queued1|queuedNop);
                if (queued1|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b010001:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010010:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010011:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010100:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010101:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010110:  panic <= `PANIC_INVALIDFBSTATE;
        6'b010111:
            begin
                fetchbufE_v <= !(queued1|queuedNop);
                if (queued1|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b011000:
            begin
                if (IsBranch(instrE) & predict_takenE) begin
                    pc <= branch_pc;
                    fetchbufE_v <= !(queued1|queuedNop);
                    fetchbufF_v <= `INV;
                end
                else begin
                    if (did_branchback1) begin
                        fetchABC();
                        if (do_pcinc) pc <= pc + 32'd16;
                        fetchbufE_v <= !(queued1|queuedNop);
                        fetchbufF_v <= !(queued2|queuedNop);
                        if (queued2|queuedNop)
                            fetchbuf <= ~fetchbuf;
                    end
                    else begin
                        pc <= branch_pc;
                        fetchbufE_v <= !(queued1|queuedNop);
                        fetchbufF_v <= !(queued2|queuedNop);
                    end
                end
            end
        6'b011001:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011010:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011011:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011100:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011101:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011110:  panic <= `PANIC_INVALIDFBSTATE;
        6'b011111:
            begin
                fetchbufE_v <= !(queued1|queuedNop);
                fetchbufF_v <= !(queued2|queuedNop);
                if (queued2|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b100000:
            begin
                fetchABC();
                if (do_pcinc) pc <= pc + 32'd16;
                fetchbufD_v <= !(queued1|queuedNop);
                if (queued1|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b100001:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100010:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100011:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100100:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100101:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100110:  panic <= `PANIC_INVALIDFBSTATE;
        6'b100111:
            begin
                fetchbufD_v <= !(queued1|queuedNop);
                if (queued1|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b101xxx:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110000:
            begin
                if (IsBranch(instrD) && predict_takenD) begin
                    pc <= branch_pc;
                    fetchbufD_v <= !(queued1|queuedNop);
                    fetchbufE_v <= `INV;
                end
                else begin
                    if (did_branchback1) begin
                        fetchABC();
                        if (do_pcinc) pc <= pc + 32'd16;
                        fetchbufD_v <= !(queued1|queuedNop);
                        fetchbufE_v <= !(queued2|queuedNop);
                        if (queued2|queuedNop)
                            fetchbuf <= ~fetchbuf;
                    end
                    else begin
                        pc <= branch_pc;
                        fetchbufD_v <= !(queued1|queuedNop);
                        fetchbufE_v <= !(queued2|queuedNop);
                    end
                end
            end
        6'b110001:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110010:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110011:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110100:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110101:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110110:  panic <= `PANIC_INVALIDFBSTATE;
        6'b110111:
            begin
                if (IsBranch(instrD) && predict_takenD)
                    panic <= `PANIC_INVALIDFBSTATE;
                else begin
                    fetchbufD_v <= !(queued1|queuedNop);
                    fetchbufE_v <= !(queued2|queuedNop);
                    if (queued2|queuedNop)
                        fetchbuf <= ~fetchbuf;
                end
        6'b111000:
            begin
                fetchABC();
                if (do_pcinc) pc <= pc + 32'd16;
                fetchbufD_v <= !(queued1|queuedNop);
                fetchbufE_v <= !(queued2|queuedNop);
                fetchbufF_v <= !(queued3|queuedNop);
                if (queued3|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        6'b111001:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111010:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111011:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111100:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111101:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111110:  panic <= `PANIC_INVALIDFBSTATE;
        6'b111111:  panic <= `PANIC_INVALIDFBSTATE;
            begin
                fetchbufD_v <= !(queued1|queuedNop);
                fetchbufE_v <= !(queued2|queuedNop);
                fetchbufF_v <= !(queued3|queuedNop);
                if (queued3|queuedNop)
                    fetchbuf <= ~fetchbuf;
            end
        endcase
else begin  // if (take_branch)
    if (fetchbuf==1'b0)
		case ({fetchbufA_v,fetchbufB_v,fetchbufC_v})
		3'b000:   ;
		3'b001:
		    begin
		        fetchbufC_v <= !queued1;
		        fetchbuf <= !queued1;
		    end
		3'b010:
		    begin
		        fetchbufB_v <= !queued1;
		        fetchbuf <= !queued1;
		    end
		3'b011:
		    begin
		        fetchbufB_v <= !(queued1|queued2);
		        fetchbufC_v <= !queued2;
                fetchbuf <= !queued2;
		    end
		3'b100:
		    begin
		        fetchbufA_v <= !queued1;
                fetchbuf <= !queued1;
		    end
		3'b101:   // This is an invalid state
		    begin
                fetchbufA_v <= !(queued1|queued2);
                fetchbufC_v <= !queued2;
                fetchbuf <= !queued2;
            end
        3'b110:
		    begin
                fetchbufA_v <= !(queued1|queued2);
                fetchbufB_v <= !queued2;
                fetchbuf <= !queued2;
            end
        3'b111:
		    begin
                fetchbufA_v <= !(queued1|queued2|queued3);
                fetchbufB_v <= !(queued2|queued3);
                fetchbufC_v <= !queued3;
                fetchbuf <= !queued3;
            end
        endcase
    else
		case ({fetchbufD_v,fetchbufE_v,fetchbufF_v})
		3'b000:   ;
        3'b001:
            begin
                fetchbufF_v <= !queued1;
                fetchbuf <= queued1;
            end
        3'b010:
            begin
                fetchbufE_v <= !queued1;
                fetchbuf <= queued1;
            end
        3'b011:
            begin
                fetchbufE_v <= !(queued1|queued2);
                fetchbufF_v <= !queued2;
                fetchbuf <= queued2;
            end
        3'b100:
            begin
                fetchbufF_v <= !queued1;
                fetchbuf <= queued1;
            end
        3'b101:   // This is an invalid state
            begin
                fetchbufD_v <= !(queued1|queued2);
                fetchbufF_v <= !queued2;
                fetchbuf <= queued2;
            end
        3'b110:
            begin
                fetchbufD_v <= !(queued1|queued2);
                fetchbufE_v <= !queued2;
                fetchbuf <= queued2;
            end
        3'b111:
            begin
                fetchbufD_v <= !(queued1|queued2|queued3);
                fetchbufE_v <= !(queued2|queued3);
                fetchbufF_v <= !queued3;
                fetchbuf <= queued3;
            end
        endcase

	if (fetchbufA_v == `INV && fetchbufB_v == `INV && fetchbufD_v==`INV) begin
	    fetchABC();
        if (do_pcinc) pc <= pc + 32'd16;
        // fetchbuf steering logic correction
        if (fetchbufD_v==`INV && fetchbufE_v==`INV && fetchbufF_v==`INV && do_pcinc)
            fetchbuf <= 1'b0;
        $display("hit %b 1pc <= %h", do_pcinc, pc + 32'd16);
    end
    else if (fetchbufD_v == `INV && fetchbufE_v == `INV && fetchbufF_v==`INV) begin
        fetchDEF();
        if (do_pcinc) pc <= pc + 32'd16;
        $display("2pc <= %h", pc + 32'd16);
    end
end
