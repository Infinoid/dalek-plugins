test:
	prove t

testcover:
	@rm -rf cover_db
	@HARNESS_PERL_SWITCHES="-MDevel::Cover=+ignore,t/" prove t
	@cover -summary -report html -outputdir cover_db
