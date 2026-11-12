/* Programador de Quartus: demostracion en una sola DE10-Lite */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Cfg)
		Device PartName(10M50DAF484) Path("output_files/") File("biobot_demo.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
