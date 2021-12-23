`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:12:21 11/11/2021 
// Design Name: 
// Module Name:    mips 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
/////////////////////////////////////////////////////////////////////////////////
	
module CPU(
	input clk,
	input reset,
	input [31:0] i_inst_rdata,
   input [31:0] m_data_rdata,
	input [5:0] HWInt,                
   output [31:0] macroscopic_pc,   
   output [31:0] i_inst_addr,
   output [31:0] m_data_addr,
   output [31:0] m_data_wdata,
   output [3 :0] m_data_byteen,
   output [31:0] m_inst_addr,
   output w_grf_we,
   output [4:0] w_grf_addr,
   output [31:0] w_grf_wdata,
   output [31:0] w_inst_addr
    );
	//-----------------F-----------------------
	wire BDF;
	wire [4:0] ExcCodeF;
	wire [31:0] instrF;
	wire [31:0] PCF;
	//-----------------D-----------------------
	wire useMD,RI,BD,BDD,eretD,stall;
	wire [2:0] Cmp,CmpSel,ExtOp,NPCSel,tuseRsD,tuseRtD,rsDfwd,rtDfwd;
	wire [4:0] A3D,ExcCodeD;
	wire [31:0] rd1D,rd2D,rd1Draw,rd2Draw,PCD,luiD,imm32D,instrD; 
	//-----------------E-----------------------
	wire start,busy,BDE;
	wire [2:0] rsEfwd,rtEfwd,ALUSrc,RegSrcE,tnewE,MDop,Ov;
	wire [4:0] A3E,ALUCtrl,ExcCodeE;
	wire [31:0] rd1E,rd2E,rd1Eraw,rd2Eraw,HIE,LOE;
	wire [31:0] instrE,imm32E,PCE,luiE,SrcB,ALUOutE,RegDataE;
	//-----------------M-----------------------
	wire eretM,BDM,Req,IntReq;
	wire [2:0] rtMfwd,RegSrcM,tnewM,storeOp,loadOp;
	wire [4:0] A3M,ExcCodeM;
	wire [31:0] rd2M,luiM,PCM,rd2Mraw,MemRdM,instrM,ALUOutM,RegDataM,HIM,LOM,CPOutM;
	wire [31:0] EPC;
	//-----------------W-----------------------
	wire RegWriteW;
	wire [2:0] RegSrcW;
	wire [4:0] A3W;
	wire [31:0] PCW,luiW,ALUOutW,MemRdW,instrW,RegDataW,HIW,LOW,CPOutW;
	//-----------------------------------------
		
	assign i_inst_addr=PCF;
	assign w_grf_we=RegWriteW;
	assign w_grf_addr=A3W;
	assign w_grf_wdata=RegDataW;
	assign m_inst_addr=PCM;
	assign w_inst_addr=PCW;
	
	IFU IFU(
		.NPCop(NPCSel),
		.clk(clk),				.PC(PCF),
		.reset(reset),
		.branch(imm32D),	
		.jump(instrD[25:0]),		
		.jr(rd1D),
		.stall(stall),
		.Req(Req),
		.eretD(eretD),
		.EPC(EPC)
	);
	
	assign ExcCodeF=((PCF[1:0]||PCF<32'h3000||PCF>32'h6ffc)&&!eretD)?4:0;
	assign BDF=BD;
	
	D D(
		.clk(clk),					.instrD(instrD),
		.reset(reset),				.PCD(PCD),
		.weD(!stall),				.ExcCodeD(ExcCodeD),
		.instrF(i_inst_rdata),	.BDD(BDD),
		.PCF(PCF),
		.ExcCodeF(ExcCodeF),
		.BDF(BDF),
		.Req(Req)
	);
	
	Controller CtrlD(
		.Cmp(Cmp),				.NPCSel(NPCSel),
		.instr(instrD),		.ExtOp(ExtOp),
									.tuseRs(tuseRsD),
									.tuseRt(tuseRtD),
									.A3(A3D),
									.CmpSel(CmpSel),
									.useMD(useMD),
									.RI(RI),
									.BD(BD),
									.eret(eretD)
	);
	
	GRF GRF(
		.clk(clk),				.RD1(rd1Draw),
		.we(RegWriteW),		.RD2(rd2Draw),
		.reset(reset),
		.instr(instrD),
		.A3(A3W),
		.WD(RegDataW),
		.PC(PCW)
	);
	
	MUX8 #(32) forward_rsD(
		.sel(rsDfwd),		.out(rd1D),
		.in0(rd1Draw),
		.in1(RegDataM),
		.in2(RegDataE)
	);
	
	MUX8 #(32) forward_rtD(
		.sel(rtDfwd),		.out(rd2D),
		.in0(rd2Draw),
		.in1(RegDataM),
		.in2(RegDataE)
	);
	
	Compare Compare(
		.SrcA(rd1D),			.CmpOut(Cmp),
		.SrcB(rd2D),
		.CmpSel(CmpSel)
	);
				  
	Ext Ext(
		.instr(instrD),		.lui(luiD),
		.ExtOp(ExtOp),			.imm32(imm32D)
	);
	
	E E(
		.clk(clk),				.rd1E(rd1Eraw),
		.reset(reset),			.rd2E(rd2Eraw),
		.rd1D(rd1D),			.instrE(instrE),
		.rd2D(rd2D),			.imm32E(imm32E),
		.instrD(instrD),		.PCE(PCE),
		.imm32D(imm32D),		.luiE(luiE),
		.PCD(PCD),				.ExcCodeE(ExcCodeE),
		.luiD(luiD),			.BDE(BDE),
		.ExcCodeD(ExcCodeD),	
		.RI(RI),
		.BDD(BDD),
		.stall(stall),
		.Req(Req)
	);
	
	MUX8 #(32) M_RegDataE(
		.sel(RegSrcE),		.out(RegDataE),
		.in2(luiE),
		.in3(PCE+8)
	);
	
	Controller CtrlE(
									.ALUSrc(ALUSrc),
									.ALUCtrl(ALUCtrl),
		.instr(instrE),		.RegSrc(RegSrcE),
									.tnew(tnewE),
									.A3(A3E),
									.start(start),
									.MDop(MDop)
	);

	MUX8 #(32) forward_rsE(
		.sel(rsEfwd),		.out(rd1E),
		.in0(rd1Eraw),
		.in1(RegDataW),
		.in2(RegDataM)
	);
	
	MUX8 #(32) forward_rtE(
		.sel(rtEfwd),		.out(rd2E),
		.in0(rd2Eraw),
		.in1(RegDataW),
		.in2(RegDataM)
	);
	
	MUX8 #(32) M_SrcB(
		.sel(ALUSrc),		.out(SrcB),
		.in0(rd2E),
		.in1(imm32E),
		.in2(32'b0)
	);
	
	ALU ALU(
		.ALUCtrl(ALUCtrl),	.ALUOut(ALUOutE),
		.instr(instrE),
		.SrcA(rd1E),			.Ov(Ov),
		.SrcB(SrcB)
	);
	
	MultDiv MultDiv(
		.clk(clk),				.HI(HIE),
		.reset(reset),			.LO(LOE),
		.start(start),			.busy(busy),
		.rd1(rd1E),
		.rd2(SrcB),
		.op(MDop),
		.Req(Req)
	);
	
	M M(
		.clk(clk),						.rd2M(rd2Mraw),
		.reset(reset),					.ALUOutM(ALUOutM),
		.instrE(instrE),				.instrM(instrM),
		.rd2E(rd2E),					.luiM(luiM),
		.ALUOutE(ALUOutE),			.PCM(PCM),
		.luiE(luiE),					.HIM(HIM),
		.PCE(PCE),						.LOM(LOM),
		.HIE(HIE),						.ExcCodeM(ExcCodeM),
		.LOE(LOE),						.BDM(BDM),
		.ExcCodeE(ExcCodeE),
		.Ov(Ov),
		.BDE(BDE),
		.Req(Req)
	);
	
	assign macroscopic_pc=PCM;
	
	MUX8 #(32) M_RegDataM(
		.sel(RegSrcM),		.out(RegDataM),
		.in0(ALUOutM),
		.in2(luiM),
		.in3(PCM+8),
		.in4(HIM),
		.in5(LOM)
	);
	
	Controller CtrlM(	
		.instr(instrM),		.RegSrc(RegSrcM),
									.tnew(tnewM),
									.A3(A3M),
									.storeOp(storeOp),
									.loadOp(loadOp),
									.eret(eretM)
	);
	
	MUX8 #(32) forward_rtM(
		.sel(rtMfwd),		.out(rd2M),
		.in0(rd2Mraw),
		.in1(RegDataW)
	);
	
	//-------------------------------------------
	BE BE(
		.clk(clk),
		.instr(instrM),			.byteen(m_data_byteen),
		.idata(rd2M),				.wdata(m_data_wdata),
		.iaddr(ALUOutM),			.waddr(m_data_addr),
		.storeOp(storeOp),
		.Int(IntReq),
		.Req(Req)
	);
	
	DataExt DataExt(
		.rdata(m_data_rdata),	.MemRd(MemRdM),
		.addr(ALUOutM),
		.instr(instrM),
		.loadOp(loadOp)
	);
	//-------------------------------------------
	
	CP0 CP0(
		.instr(instrM),
		.Din(rd2M),								.EPC(EPC),
		.PC(PCM),	
		.ExcCode(ExcCodeM),					.Dout(CPOutM),
		.HWInt(HWInt),		
		.EXLclr(eretM),						.Req(Req),
		.BD(BDM),
		.clk(clk),								.IntReq(IntReq),
		.reset(reset)
	);
	
	W W(
		.clk(clk),						.MemRdW(MemRdW),
		.reset(reset),					.ALUOutW(ALUOutW),
		.luiM(luiM),					.instrW(instrW),
		.MemRdM(MemRdM),				.luiW(luiW),
		.ALUOutM(ALUOutM),			.PCW(PCW),
		.instrM(instrM),				.HIW(HIW),
		.PCM(PCM),						.LOW(LOW),
		.HIM(HIM),						.CPOutW(CPOutW),
		.LOM(LOM),	
		.CPOutM(CPOutM),
		.Req(Req)
	);
	
	MUX8 #(32) M_RegDataW(
		.sel(RegSrcW),		.out(RegDataW),
		.in0(ALUOutW),
		.in1(MemRdW),
		.in2(luiW),
		.in3(PCW+8),
		.in4(HIW),
		.in5(LOW),
		.in6(CPOutW)
	);
	
	Controller CtrlW(
									.RegSrc(RegSrcW),
		.instr(instrW),		.RegWrite(RegWriteW),
									.A3(A3W)
	);
					 
	Crush Crush(
		.tuseRsD(tuseRsD),	
		.tuseRtD(tuseRtD),	
		.tnewE(tnewE),			.stall(stall),
		.tnewM(tnewM),			.rsDfwd(rsDfwd),
		.A3E(A3E),				.rtDfwd(rtDfwd),
		.A3M(A3M),				.rsEfwd(rsEfwd),
		.A3W(A3W),				.rtEfwd(rtEfwd),
		.instrD(instrD),		.rtMfwd(rtMfwd),		
		.instrE(instrE),
		.instrM(instrM),
		.useMD(useMD),
		.MDbusy(busy|start)
	);
		
endmodule
