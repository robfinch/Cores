bytecnt <= 12'hFFF;
if (bytecnt[11]) begin
	if (slot_lsm[0])
		bytecnt <= slot_bytecnt[0];
	else if (slot_lsm[1])
		bytecnt <= slot_bytecnt[1];
	else if (slot_lsm[1])
		bytecnt <= slot_bytecnt[2];
end
if (queuedCnt > 3'd0 && !bytecnt[11])
	bytecnt <= bytecnt - 12'd32;
