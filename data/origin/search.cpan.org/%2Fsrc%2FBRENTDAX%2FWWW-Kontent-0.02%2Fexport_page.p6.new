#!/usr/bin/pugs

use WWW::Kontent;
my $pagename = shift @ARGS;

my $request=WWW::Kontent::Request.new(:root(WWW::Kontent::get_root), :path($pagename), :loaduser(0));
$request.resolve_all;
my $rev=$request.revision;

$rev.attributes<rev:author>='/users/contributors';
$rev.attributes<rev:log>='Initial page creation during import.';
$rev.attributes.delete('rev:date');

say qq(pagename: "$pagename");
say qq(attributes: );

for $rev.attributes.kv -> $k, $v is copy {
	$v ~~ s:perl5:g{\\}{\\\\};
	$v ~~ s:perl5:g{"}{\\"};
	$v ~~ s:perl5:g{\015}{};
	$v ~~ s:perl5:g{\n}{\\n};
	$v ~~ s:perl5:g{	}{\\t};
	
	say qq(    $k: "$v");
}
