/* Programador de Quartus: tarjeta de la mochila (con ESP32 o con la tarjeta insecto) */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Cfg)
		Device PartName(10M50DAF484) Path("output_files/") File("biobot.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
