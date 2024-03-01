XLAT:
	begin
		tRead({seg_reg,`SEG_SHIFT} + bx + al);
		tGoto(XLAT_ACK);
	end
XLAT_ACK:
	if (ack_i) begin
		res <= dat_i;
		wrregs <= 1'b1;
		w <= 1'b0;
		rrr <= 3'd0;
		tGoto(IFETCH);
	end
	else if (rty_i)
		tRead({seg_reg,`SEG_SHIFT} + bx + al);
