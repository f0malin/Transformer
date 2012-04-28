#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 1 } ;

use Statistics::R ;

use strict ;
use warnings qw'all' ;

#########################
{

  my $R = Statistics::R->new() ;
  ok($R) ;
  
  # use Data::Dumper ; print Dumper( $R ) ; exit ;
  
  ok( $R->startR ) ;
  
  ok( $R->Rbin ) ;
  
  print "----\n" ;
 
  ok( $R->send(q`postscript("file.ps" , horizontal=FALSE , width=500 , height=500 , pointsize=1)`) ) ;
  
  ok( $R->send(q`plot(c(1, 5, 10), type = "l")`) ) ;

  ok( $R->send(qq`x = 123 \n print(x)`) ) ;
  
  my $ret = $R->read ;
  
  ok( $ret =~ /^\[\d+\]\s+123\s*$/ ) ;  
  
  ok( $R->send(qq`x = 456 \n print(x)`) ) ;
  $ret = $R->read ;
  ok( $ret =~ /^\[\d+\]\s+456\s*$/ ) ;  
    
  print "----\n" ;
  
  ok( $R->stopR() ) ;
  
}
#########################

print "\nThe End! By!\n" ;

1 ;
