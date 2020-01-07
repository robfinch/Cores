

len1 = uomap[opcode1][];
len2 = uomap[opcode2][];
mpc1 <= uomap[opcode1][];
mpc2 <= uomap[opcode2][];

cnt1 = 3'd0;
cnt2 = 3'd0;
for (n = 0; n < 6; n = n + 1)
begin
	uop[n] = uopl[mpc2_active ? mpc2+cnt2 : mpc1+cnt1];
	cnt1 = cnt1 + 3'd1;
	if (cnt1 > len1)
		mpc2_active = TRUE;
	if (mpc2_active)
		cnt2 = cnt2 + 3'd1;
end
