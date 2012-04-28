use Module::Build;
my $build = Module::Build->new(
    module_name        => 'DBIx::Path',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    requires => {
        perl         => '5.6.1',
        DBI          => 0,
	},
	recommends => {
        AnyData      => 0,
	    DBD::AnyData => 0
	}
);
$build->create_build_script;
