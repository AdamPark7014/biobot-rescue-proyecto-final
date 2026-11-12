/* Programador de Quartus: segunda DE10-Lite, insecto y sensor de prueba */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Cfg)
		Device PartName(10M50DAF484) Path("output_files/") File("biobot_insecto.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
