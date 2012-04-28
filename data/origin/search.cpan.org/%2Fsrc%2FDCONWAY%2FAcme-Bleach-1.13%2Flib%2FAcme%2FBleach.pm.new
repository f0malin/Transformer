package Acme::Bleach;
our $VERSION = '1.13';
my $tie = " \t"x8;
sub whiten { local $_ = unpack "b*", pop; tr/01/ \t/; s/(.{9})/$1\n/g; $tie.$_ }
sub brighten { local $_ = pop; s/^$tie|[^ \t]//g; tr/ \t/01/; pack "b*", $_ }
sub dirty { $_[0] =~ /\S/ }
sub dress { $_[0] =~ /^$tie/ }
open 0 or print "Can't rebleach '$0'\n" and exit;
(my $shirt = join "", <0>) =~ s/(.*)^\s*use\s+Acme::Bleach\s*;\n//sm;
my $coat = $1;
local $SIG{__WARN__} = \&dirty;
do {eval $coat . brighten $shirt; print STDERR $@ if $@; exit}
	unless dirty $shirt && not dress $shirt;
open 0, ">$0" or print "Cannot bleach '$0'\n" and exit;
print {0} "${coat}use Acme::Bleach;\n", whiten $shirt and exit;
__END__

=head1 NAME

Acme::Bleach - For I<really> clean programs

=head1 SYNOPSIS

	use Acme::Bleach;

	print "Hello world";

=head1 DESCRIPTION

The first time you run a program under C<use Acme::Bleach>, the module
removes all the unsightly printable characters from your source file.
The code continues to work exactly as it did before, but now it
looks like this:

	use Acme::Bleach;
	 	 	 	 	 	 	 	 	 	 	     
	   			  	
	  			 	  
		 		  			
	 		   	 	
			      	
	   	   	 
	    	  	 
		 	  		  
	 		 		   
			 		 			
		 		     
	 	  			 	
			 				 	
		  	  			
	   		 		 
	  	  		  
		   	  		
	 			   	 
		    

=head1 DIAGNOSTICS

=over 4

=item C<Can't bleach '%s'>

Acme::Bleach could not access the source file to modify it.

=item C<Can't rebleach '%s'>

Acme::Bleach could not access the source file to execute it.

=back 

=head1 SEE ALSO

http://www.templetons.com/tech/proletext.html

=head1 AUTHOR

Damian Conway (as if you couldn't guess)

=head1 COPYRIGHT

   Copyright (c) 2001, Damian Conway. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
     (see http://www.perl.com/perl/misc/Artistic.html)
