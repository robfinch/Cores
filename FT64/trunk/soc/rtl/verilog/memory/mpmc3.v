

reg [127:0] wdata [0:63];
reg [15:0] wmask [0:63];
reg [31:0] waddr [0:63];
reg [1:0] cmdfile [0:63];
reg [7:0] reqno;
reg [5:0] qndx;
reg [1:0] cmd1,cmd2;

wire [15:0] masko = maskfile[qndx];
wire [127:0] dato = datafile[qndx];

wire advancePipe = mem_rdy & mem_wdf_rdy;

if (advancePipe) begin
    mem_addr <= addrfile[qndx];
    mem_wdf_mask <= maskfile[qndx];
    mem_wdf_data <= datafile[qndx];
    mem_en <= |cmdfile[qndx];
    mem_cmd <= cmdfile[qndx];
    mem_wdf_wren <= cmdfile[qndx]==2'b10;
    mem_wdf_end <= cmdfile[qndx]==2'b10;
end

if (mem_rdy) begin
end

if (advancePipe) begin
    cmd2 <= cmd1;
    mem_en <= |cmd2;
    mem_cmd <= cmd2==2'b01 ? SET_CMD_RD : SET_CMD_WRITE;
end

if (mem_rd_data_valid & mem_rd_data_end)
    
