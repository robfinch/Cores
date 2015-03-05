
reg [31:0] sprite_attr_base;
reg [31:0] sprite_pat_base;
reg [31:0] sprite_attr [63:0];
reg [11:0] spriteX [63:0];
reg [11:0] spriteY [63:0];
reg [63:0] spriteM;
reg [5:0] sprite_n [7:0];	// array that contains sprite numbers visible on line

reg [11:0] imageX [7:0];
reg [11:0] imageY [7:0];
reg [7:0] imageM;

reg [11:0] sprite_dify [7:0];
reg [31:0] sprcol[7:0][11:0];

reg [15:0] color_cache0 [23:0];
reg [15:0] color_cache1 [23:0];
reg [15:0] color_cache2 [23:0];
reg [15:0] color_cache3 [23:0];
reg [15:0] color_cache4 [23:0];
reg [15:0] color_cache5 [23:0];
reg [15:0] color_cache6 [23:0];
reg [15:0] color_cache7 [23:0];

reg [12:0] difY;
reg [12:0] difX;

integer n;

always @*
for (n = 0; n < 64; n = n + 1) begin
	spriteX[n] = sprite_attr[n][11: 0];
	spriteY[n] = sprite_attr[n][27:16];
	spriteM[n] = sprite_attr[n][31];
end

always @*
for (n = 0; n < 8; n = n + 1) begin
	imageX[n] = spriteX[sprite_n[n]];
	imageY[n] = spriteY[sprite_n[n]];
	imageM[n] = spriteM[sprite_n[n]];
end

	// read from sprite attribute table
	// 
AC_SAT:
	begin
	sprite_num <= 5'd0;
	wb_burst(6'd63, {sprite_attr_base[31:8],8'h00});
	next_state(ACK_POS);
	end
ACK_POS:
	if (ack_i) begin
		sprite_pos[sprite_num] <= dat_i;
		next_state(ACK_ATTR);
	end
ACK_ATTR:
	if (ack_i) begin
		sprite_attr[sprite_num] <= dat_i;
		if (sprite_num==5'd31)
			next_state();
		else begin
			sprite_num <= sprite_num + 5'd1;
			next_state(ACK_POS);
		end
	end

// Test if sprite is visible on scanline
// Record which sprites are visible in sprite_n[] array

always @*
begin
	m = 0;
	sprite_n[0] <= 0;
	sprite_n[1] <= 0;
	sprite_n[2] <= 0;
	sprite_n[3] <= 0;
	sprite_n[4] <= 0;
	sprite_n[5] <= 0;
	sprite_n[6] <= 0;
	sprite_n[7] <= 0;
	for (n = 0; n < 64; n = n + 1) begin
		difY = raster - spriteY[n];
		sprite_dify[m] = difY;
		if (spriteX[n] > 0) begin
			if (!difY[12] && difY < (spriteM[n] ? 13'd42 : 13'd21) && m < 8) begin
				sprite_n[m] <= n;
				m = m + 1;
			end
		end
	end
end

	j = 3'd0;
AC_COL_ST:
	begin
		k = 4'd0;
		wb_burst(6'd11,{sprite_pat_base[31:10],10'd0} + {sprite_n[j],10'd0} +
			spriteMag[sprite_n[j]] ?
			({sprite_dify[j],3'h0} + {sprite_dify[j],2'h0}) :	// 24 pixels X sprite scanline number / 2
			({sprite_dify[j],4'h0} + {sprite_dify[j],3'h0}));	// 24 pixels X sprite scanline number
		next_state(AC_COL);
	end
AC_COL:
	if (ack_i) begin
		case(j)
		3'd0:	begin
				color_cache0[{k,1'b0}] <= dat_i[15: 0];
				color_cache0[{k,1'b1}] <= dat_i[31:16];
				end
		3'd1:	begin
				color_cache1[{k,1'b0}] <= dat_i[15: 0];
				color_cache1[{k,1'b1}] <= dat_i[31:16];
				end
		3'd2:	begin
				color_cache2[{k,1'b0}] <= dat_i[15: 0];
				color_cache2[{k,1'b1}] <= dat_i[31:16];
				end
		3'd3:	begin
				color_cache3[{k,1'b0}] <= dat_i[15: 0];
				color_cache3[{k,1'b1}] <= dat_i[31:16];
				end
		3'd4:	begin
				color_cache4[{k,1'b0}] <= dat_i[15: 0];
				color_cache4[{k,1'b1}] <= dat_i[31:16];
				end
		3'd5:	begin
				color_cache5[{k,1'b0}] <= dat_i[15: 0];
				color_cache5[{k,1'b1}] <= dat_i[31:16];
				end
		3'd6:	begin
				color_cache6[{k,1'b0}] <= dat_i[15: 0];
				color_cache6[{k,1'b1}] <= dat_i[31:16];
				end
		3'd7:	begin
				color_cache7[{k,1'b0}] <= dat_i[15: 0];
				color_cache7[{k,1'b1}] <= dat_i[31:16];
				end
		endcase
		k <= k + 4'd1;
		if (k == 4'd11) begin
			next_state(AC_COL_ST);
			j <= j + 3'd1;
		end
		else
			next_state(AC_COL);
	end

	if (sprite_xpos[g]==0)
		case(g)
		3'd0:
			begin
				for (n = 0; n < 23; n = n + 1)
					color_cache0[n] <= color_cache0[n+1];
				color_cache0[23] <= sprite_tc[g];
			end
		3'd1:
			begin
				for (n = 0; n < 23; n = n + 1)
					color_cache1[n] <= color_cache1[n+1];
				color_cache1[23] <= sprite_tc[g];
			end
		3'd2:
			begin
				for (n = 0; n < 23; n = n + 1)
					color_cache2[n] <= color_cache2[n+1];
				color_cache2[23] <= sprite_tc[g];
			end
		3'd3:
			begin
				for (n = 0; n < 23; n = n + 1)
					color_cache3[n] <= color_cache3[n+1];
				color_cache3[23] <= sprite_tc[g];
			end
		3'd4:
			begin
				for (n = 0; n < 23; n = n + 1)
					color_cache4[n] <= color_cache4[n+1];
				color_cache4[23] <= sprite_tc[g];
			end
		3'd5:
			begin
				for (n = 0; n < 23; n = n + 1)
					color_cache5[n] <= color_cache5[n+1];
				color_cache5[23] <= sprite_tc[g];
			end
		3'd6:
			begin
				for (n = 0; n < 23; n = n + 1)
					color_cache6[n] <= color_cache6[n+1];
				color_cache6[23] <= sprite_tc[g];
			end
		3'd7:
			begin
				for (n = 0; n < 23; n = n + 1)
					color_cache7[n] <= color_cache7[n+1];
				color_cache7[23] <= sprite_tc[g];
			end
		endcase

	if (!sprite_difx[j][12] && sprite_difx[j] < 
	spriteX[sprite_n[j]];

	spr0_col_o <= spr0_tc;
	spr1_col_o <= spr1_tc;
	spr2_col_o <= spr2_tc;
	spr3_col_o <= spr3_tc;
	spr4_col_o <= spr4_tc;
	spr5_col_o <= spr5_tc;
	spr6_col_o <= spr6_tc;
	spr7_col_o <= spr7_tc;
	if (color_cache0[0] != spr0_tc && m > 0)
		spr0_col_o <= color_cache0[0];
	if (color_cache1[0] != spr1_tc && m > 1)
		spr1_col_o <= color_cache1[0];
	if (color_cache2[0] != spr2_tc && m > 2)
		spr2_col_o <= color_cache2[0];
	if (color_cache3[0] != spr3_tc && m > 3)
		spr3_col_o <= color_cache3[0];
	if (color_cache4[0] != spr4_tc && m > 4)
		spr4_col_o <= color_cache4[0];
	if (color_cache5[0] != spr5_tc && m > 5)
		spr5_col_o <= color_cache5[0];
	if (color_cache6[0] != spr6_tc && m > 6)
		spr6_col_o <= color_cache6[0];
	if (color_cache7[0] != spr7_tc && m > 7)
		spr7_col_o <= color_cache7[0];

	
