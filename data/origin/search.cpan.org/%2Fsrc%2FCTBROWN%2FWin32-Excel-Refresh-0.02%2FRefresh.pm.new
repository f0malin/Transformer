package Win32::Excel::Refresh;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader qw(AUTOLOAD);

use File::Spec::Functions ':ALL';

use Win32::OLE;
use Win32::OLE qw(in);
use Win32::OLE::Const 'Microsoft Excel';

# use Data::Dumper;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Excel::Refresh ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(XLRefresh);

our $VERSION = '0.02';


# Preloaded methods go here.

# ---------------------------------------------------------------
# SUBROUTINE: XLRefresh
#   Usage: XLRefresh( $filename, $opts );
#
#   $filename is a relative or absoulte filename.
#
#   $opts is a hash reference of parameters
#	 { all          => [ 0 | 1 ] }
#     { query-tables => [ 0 | 1 ] }
#     { pivot-tables => [ 0 | 1 ] }
#     { visible      => [ 0 | 1 ] }
#     { macros      => [list] } 
#	 
#	list is string of macros and argumants, "macro(args)", "marco(args)"	
#	e.g. macros => "RefreshAllPivotTables( true, true )", 
#
#  2) Implement more of a Excel Feel
#      XLRefresh.exe -m Sheet1!RefreshAllPivotTables( true, true );
# ---------------------------------------------------------------
sub XLRefresh {

	my $filename = shift || die("No filename supplied");
	my $opts = shift;

  	# print Dumper( $opts ); 

  # -------------------------------------------------------------
  # CLEAN AND TRAP FILENAME INPUT
  # -------------------------------------------------------------
	$filename = rel2abs($filename);
	croak("$filename does not exist.\n") if ( !-e $filename);
	
  # -------------------------------------------------------------  
  # OPEN A NEW APPLICATION INSTANCE.
  #   Opening a new application instance prevents a workbook of
  #   same name and a generation of an error and prevents the the
  #   decision as to whether to close the existing application or
  #   not.  Cf the deprecated subroutines at the end to see how 
  #   it was done previously.
  # -------------------------------------------------------------	
	my $Excel;
	$Excel = Win32::OLE->new('Excel.Application', 'Quit');

  # -------------------------------------------------------------
  # Set the visibility of the operations
  # -------------------------------------------------------------
	$Excel->{DisplayAlerts} = "False";
	$Excel->{Visible} = $opts->{'visible'} || 0 ;         # if you want to see what's going on


  # -------------------------------------------------------------
  # OPEN FILE:
  # There is no need to trap if the workbook is open.  If the file is open elsewhere
  # do not save this file.
  # The open function:
  # expression.Open(FileName, RefreshLinks, ReadOnly, Format, Password, WriteResPassword,
  # IgnoreReadOnlyRecommended, Origin, Delimiter, Editable, Notify, Converter, AddToMRU)
  # -------------------------------------------------------------	
	my $wb = $Excel->Workbooks->Open( $filename );      # open the file

  # -------------------------------------------------------------	
  # Workbook.RefreshAll 
  # Refreshes all external data ranges and PivotTable reports in the specified workbook.
  # -------------------------------------------------------------	
	$wb->RefreshAll if ( $opts->{all} );

  # -------------------------------------------------------------	
  # Refresh Charts
  # -------------------------------------------------------------	
	#_refreshall( $wb, "Charts", "Refresh" );
	# foreach my $chart ( in($Excel->Charts) ) {
	#	$chart->Calculate;
	#}


  # -------------------------------------------------------------	
  # REFRESH: Query Tables and Pivot tables 
  #  Iterate through worksheets 
  # -------------------------------------------------------------	
	foreach my $ws ( in( $wb->WorkSheets ) ) {

		# print "Updating Worksheet: $ws->{Name}\n";

	   # ------------------------------------------------------
	   # Query Tables
	   # ------------------------------------------------------
		if ( $opts->{'query-tables'} ){
			_refreshall( $ws, "QueryTables", "Refresh");
			# print "\tRefreshing QueryTable(s)\n";
		}

	   # ------------------------------------------------------
	   # Pivot Tables
	   # ------------------------------------------------------
		if ( $opts->{'pivot-tables'} ) {			
			_refreshall( $ws, "PivotTables", "RefreshTable")	;
			# print "\tRefreshing Pivot Table(s)\n";
		}
	
	}
	

  # -------------------------------------------------------------
  # Run Macros: Query Tables and Pivot tables 
  # -------------------------------------------------------------
	foreach my $macro ( @{ $opts->{'macros'} } ) {
		$Excel->Run( $macro );
		# $Excel->Run('Sheet1.macro1');
		# print "Running Macro: $macro\n";
	}

  # -------------------------------------------------------------
  # SAVE WORKBOOK
  # expression.SaveAs(Filename, FileFormat, Password, WriteResPassword,
  #	ReadOnlyRecommended, CreateBackup, AccessMode, ConflictResolution,
  #	AddToMru, TextCodePage, TextVisualLayout)
  # -------------------------------------------------------------
	## Recalculate before closing 
	$Excel->Calculate;
	$wb->Save;
	$wb->Close;		

	# $wb->SaveAs(
	#	{ 	Filename 	=>$filename,
	#		AddToMru => 'FALSE' ,
	#	}
	#);

	$Excel->Quit(); #  if ( $close_on_exit == TRUE );
	
} ##  END SUBROUTINE XLRefresh


## SUBROUTINE _refresh, _refreshall
## $self->_refreshall( $obj, collection_method, individual_method );
##	e.g. $self->refreshall($app, "workbooks", "refresh");
## 	Generic method for refreshing object.
## 	object: A suitable Win32::Object
##	collection_method: Method for returning an array of individuals in a collection
##	individual_method: Method to be executed for each individual	
sub _refreshall {

	my $obj = shift;
	my $collection_method = shift;
	my $individual_method = shift;

	return if ( $obj->$collection_method->Count < 1 );

	print "\tUpdating $collection_method: $obj->{Name}\n";
	
	foreach my $individual ( in( $obj->$collection_method ) ) {
		$individual->$individual_method;
	}

	## Error Trap.
	if ( Win32::OLE->LastError() ) {
		print "TRAPPING ERROR\n";
		print "Win32::OLE->LastError()\n";
	}		

} # END SUBROUTINE _refresh_all


sub _refresh {

	my $individual = shift;
	my $individual_method = shift;

	$individual->individual_method;

} # END SUBROUTINE _refresh




# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!



=pod

=begin PerlCtrl

    %TypeLib = (
        PackageName     => 'Win32::Excel::Refresh' ,

	# DO NOT edit the next 3 lines.
        TypeLibGUID     => '{E91B25C6-2B15-11D2-B466-0800365DA902}', 
        ControlGUID     => '{E91B25C7-2B15-11D2-B466-0800365DA902}',
        DispInterfaceIID=> '{E91B25C8-2B15-11D2-B466-0800365DA902}',

        ControlName     => 'Win32.Excel.Refresh',
        ControlVer      => 1,  
        ProgID          => 'Win32.Excel.Refresh',
        DefaultMethod   => '',

        Methods         => {
            'refresh' => {
                    RetType             =>  VT_BSTR,
                    TotalParams         =>  1,
                    NumOptionalParams   =>  0,
                    ParamList           =>[ 'file' => VT_BSTR ] 
                },
            },  # end of 'Methods'

        Properties      => {
            }
	    ,  # end of 'Properties'
        );  # end of %TypeLib

=end PerlCtrl

=cut

=head1 NAME

Win32::Excel::Refresh - Perl extension for automating the refresh of Microsoft Excel Workbooks

=head1 SYNOPSIS

  use Win32::Excel::Refresh;

  my $filename = "book1.xls";
  XLRefresh( $filename,
    {
      pivot-tables => 1 ,
	 query-tables => 1,
	 all => 1 ,
	 macros => [ "macro1", "macro2" ] ,
      visible => TRUE 
    }
  );

=head1 ABSTRACT

  Automate the refresh of Microsoft Excel workbooks.

=head1 DESCRIPTION

Win32::Excel::Refresh allows for programatic and/or automatic refreshing of Excel workbooks.  This module was written for situations where Excel workbooks are in need of refreshing but the responsible person is too lazy, forgetful or sick of opening up workbooks to execute a few refresh commands and saving the resulting workbook.  Complete automation can be acheived by wrapping this module into a script and scheduling in the Windows Task Scheduler (L<Win32::TaskScheduler>), AT(L<Schedule::At>) or a similar cron-type mechanism (L<Schedule::Cron>).

The author uses this modules to keep hundreds of Excel workbooks up-to-date.  Each of the workborks are dependent upon data from either web queries or database queries.  In most cases, the data is contained in Pivot Tables.  While I debated coding this in Visual Basic, I wanted to be able to some advantage of Perl.  

A single subroutine, XLRefresh is exported into he callers namespace.  This functions takes all a filename and a hash of parameters and does all the work invisibly in the background.

=head1 PREREQUISITES

=over 2

=item Microsoft Windows

=item Microsoft Excel

 

This module is dependent on Win32::OLE and is therefore non-functional on *NIX variants.  It has been used successfully with Microsoft Windows 2000 and XP and Microsoft Excel 2000 and 2003. 

=back

=head1 METHODS

=over 2

=item XLRefresh

  XLRefresh( $filename, $opts );

$filename is a filename that can be fully specified or relative to the caller's working directory.  If relative, the file is first converted to its fully specified form using L<File::Spec::Functions/"rel2abs">.  Filenames may contain forward or back slashes.

$opts is a reference to a hash of parameters used to control the refreshing.  Valid parameters are:

    all          => 0|1  Refresh everything
    query-tables => 0|1  Refresh query tables only
    pivot-tables => 0|1	Refresh pivot tables only
    visible      => 0|1  Perform the refreshes visibly or in the background, default: invisible.
    macros       => [ "macro1", "macro2" ] List of macros available to the workbook to run
 	
=item _refresh( $item, $method )

Internal method to invoke a VBA method on a given item.  This method should not be called directly.

=item _refresh_all

Internal method to invoke a method on each item in a collection.  This method should not be called directly. 

=back

=head1 EXPORT

XLRefresh by default

=head1 EXTRAS

=over 2

=item XLRefresh.pl

XLRefresh.pl is script to execute XLRefresh from the command line.  It relies on L<Getopt::Mixed|Getopt::Mixed> for the setting of the $opts parameters.  It can be found in the script directory. 

=back

    Usage: XLRefresh -[aqpv] -m macro(s) filename
    options:
      -a, --all          Refresh All PivotTables and Queries
      -q, --query-tables Refreshes All QueryTables  
      -p, --pivot-tables Refresh All PivotTables
      -m, --macros       Runs specified macros
      -v, --visible      Shows application while running, defaul invisible

=over 2

=item XLRefresh.exe

XLRefresh.exe is a compiled version of the above script using ActiveState's PerlApp Perl.  The application was compiled on Windows2000 and has been tested used successfully on WindowsXP.  It can be found in the bin directory of this distribution.

=back

=head1 EXAMPLES

Examples using Win32::Task Scheduler, AT and Schedule::Cron ...

=head1 TODO and possible modifications

  + Add support for charts
  + Add routine to remove old pivot table items cf http://www.contextures.com/xlPivot04.html
  + Add PPM package
  + Complete examples section
  + Support for workbook versioning (?)
  + Allow arguments for macros
  + Validate that the defaults are working correctly

=head1 SEE ALSO

L<Win32::OLE>,
L<File::Spec::Functions/"rel2abs">, 
L<Getopt::Mixed>, 
L<Win32::TaskScheduler>, 
L<Schedule::At>, 
L<Schedule::Cron>, 
Perl

=head1 AUTHOR

Christopher Brown, E<lt>ctbrown{at}cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Christopher Brown.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl.  There software comes with no warranty either expressed or implied.

=cut

# -------------------------------------------------------------
# AUTOLOADING
# 	Adapted from Programming Perl, 2nd Edition p.298 
#    by Wall, Christiansen, Schwartz 
# -------------------------------------------------------------
sub AUTOLOAD {

	my $self = shift;
	my $type = ref($self) || croak "$self is not an object.\n";
	my $name = lc $AUTOLOAD;
	
	$name =~ s/.*://; 					# Strip fully-qualified portion

	unless ( exists $self->{$name} ) {
		croak "Can't access '$name' field in object of class $type.";
	}

	if (@_) {
		return $self->{$name} = shift;
	} else {
		return $self->{$name};
	}

} ## END SUBROUTINE: AUTOLOAD



##### DEPRECATED:

	#$Excel = Win32::OLE->GetActiveObject('Excel.Application');

	# my $close_on_exit = FALSE;	
	# if (!$Excel) {
	# $Excel = Win32::OLE->new('Excel.Application', 'Quit');
	#	$close_on_exit = TRUE;
	# }