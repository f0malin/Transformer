#!/usr/bin/pugs

use WWW::Kontent;
my $root=WWW::Kontent::get_root;

my $message = shift @ARGS;

my $y = eval slurp($*IN), :lang<yaml>;

my $draft;
try {
	my($newpage, @rest)=reverse split '/', $y<pagename>;
	my $parentpage = join '/', reverse @rest;
	die unless $newpage or $parentpage;
	
	my $request=WWW::Kontent::Request.new(:root($root), :page($parentpage), :loaduser(0));
	$request.resolve_all();
	
	my $rev = $request.revision;
	$draft  = $rev.create($newpage);
	$draft  = $draft.draft_revision;
	print "Creating a new page $y<pagename>...";
};
if $! {
	my $request=WWW::Kontent::Request.new(:root($root), :page($y<pagename>), :loaduser(0));
	$request.resolve_all();
	
	my $rev = $request.revision;
	$draft  = $rev.revise($rev.revno + 1);
	print "Creating a new revision of $y<pagename>...";
}

for $y<attributes>.kv -> $k, $v {
	$draft.attributes{$k}=$v;
}

$draft.attributes<rev:log> = $message if $message;
$draft.commit();
say "done.";
