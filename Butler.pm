## Copyright (c) 2001, Kurt Kincaid.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

package File::Butler;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA       = qw(Exporter AutoLoader);
@EXPORT    = qw(Butler);
@EXPORT_OK = qw(Version);

$VERSION = '2.0';

sub Version {
    return $VERSION;
}

sub Butler {
    my ( $file, $action, $array ) = @_;
    return undef unless defined $file && defined $action;
    if ( $action eq "dir" ) {
        unless ( -d $file ) {
            return undef;
        }
        opendir ITEMS, $file;
        @$array = grep !/^\./, readdir ITEMS;
        closedir ITEMS;
        chomp @$array;
        return @$array;
    } elsif ( $action eq "read" ) {

        unless ( -e $file ) {
            return undef;
        }
        open( BUTLER, $file ) || return undef;
        while (<BUTLER>) {
            chomp;
            push ( @$array, $_ );
        }
        close(BUTLER);
        local $/ = undef;
        open( BUTLER, $file ) || return undef;
        my $content = <BUTLER>;
        close(BUTLER);

        if ( wantarray() ) {
            return @$array;
        } elsif ( defined wantarray() ) {
            return $content;
        } else {
            return 1;
        }
    } elsif ( $action eq "write" ) {
        return undef unless defined $array;
        open( BUTLER, ">$file" ) || return undef;

        foreach (@$array) {
            chomp;
            print BUTLER $_, "\n";
        }
        close(BUTLER);
        return 1;
    } elsif ( $action eq "prepend" ) {
        return undef unless defined $array;
        open( BUTLER, $file ) || return undef;
        my @temp;

        while (<BUTLER>) {
            chomp;
            push ( @temp, $_ );
        }
        close(BUTLER);
        unshift ( @temp, @$array );
        Butler( $file, "write", \@temp );
        return 1;
    } elsif ( $action eq "append" ) {
        return undef unless defined $array;
        open( BUTLER, ">>$file" ) || return undef;

        foreach (@$array) {
            chomp;
            print BUTLER $_, "\n";
        }
        close(BUTLER);
        return 1;
    } elsif ( $action eq "srm" ) {
        my @text;
        my ( $method, $i, $j );
        unless ($array) { $array = 1 }
        $text[0] = Butler( $file, "read" );
        my $length = length $text[0];

        for ( $i = 0 ; $i <= $array - 1 ; $i++ ) {
            undef $text[0];
            $method = $i % 10;
            if ( $method <= 3 ) {
                for ( $j = 0 ; $j <= $length ; $j++ ) {
                    $text[0] .= sprintf( "%.0f", rand() );
                }
            } elsif ( $method == 4 ) {

                while ( length $text[0] < $length ) {
                    $text[0] .= "01010101";
                }
            } elsif ( $method == 5 ) {
                while ( length $text[0] < $length ) {
                    $text[0] .= "10101010";
                }
            } elsif ( $method == 6 ) {

                while ( length $text[0] < $length ) {
                    $text[0] .= "100100";
                }
            } elsif ( $method == 7 ) {
                while ( length $text[0] < $length ) {
                    $text[0] .= "010010";
                }
            } elsif ( $method == 8 ) {

                while ( length $text[0] < $length ) {
                    $text[0] .= "001001";
                }
            } elsif ( $method == 9 ) {
                while ( length $text[0] < $length ) {
                    $text[0] .= "00000000";
                }
            } else {

                while ( length $text[0] < $length ) {
                    $text[0] .= "11111111";
                }
            }
            Butler( $file, "write", \@text );
        }
        unlink $file;
        return 1;
    } elsif ( $action eq "wc" ) {
        my $text = Butler( $file, "read" );
        my $words = 0;

        while ( $text =~ m/(\w+)/g ) {
            $words++;
        }
        my $lines = ( split ( /\n/, $text ) );
        my $chars = length $text;
        return $lines, $words, $chars;
    } else {
        return undef;
    }
}

1;

__END__

=head1 NAME

File::Butler - Handy collection of file manipulation tools

=head1 SYNOPSIS

  use File::Butler;
  Butler( "somefile.txt", "read", \@lines );
  $single_line = Butler( "somefile.txt", "read" );
  Butler( "somefile.txt", "write", \@lines );
  Butler( "somefile.txt", "append", \@data );
  Butler( "somefile.txt", "prepend", \@data );
  Butler( "/home/kurt", "dir", \@files );
  Butler( "somefile.txt", "srm" [, passes]);
  ( $lines, $words, $characters ) = Butler( "somefile.txt", "wc" );

=head1 DESCRIPTION

This module is a handy collection of file manipulation tools, and was really designed as 
more of a convenience than anything else. All of the various functions are fairly self-
explanatory.

=head1 EXAMPLES

=head2 B<Butler( $file, "read", \@lines )>

Reads the contents of $file and stores the contents in the array passed as a reference.

=head2 $single_line = B<Butler( $file, "read" )>

Reads the contents of $file and returns the contents as a scalar.

=head2 B<Butler( $file, "write", \@lines )>

No surprises here. Writes the contents of @lines into $file, clobbering the previous contents of $file.

=head2 B<Butler( $file, "append", \@lines )>

Again, no surprises.  Appends the contents of @lines to $file.

=head2 B<Butler( $file, "prepend", \@lines )>

Prepends the contents of @lines to $file.

=head2 B<Butler( $directory, "dir", \@files )>

Returns a list of the files in $directory, ignoring files that start with "." (i.e., .htaccess)

=head2 B<Butler( $file, "srm" [, passes])>

Writes over the contents of $file with a series of 0's and 1's the specified number of times, and then unlinks the file. If passes is not specified, it writes over the file once before unlinking. 
A total of 10 different overwrite methods are used.  If more than 10 passes are specified, the cycle repeats. The cycle is as follows:  

Pass 1: Random 0's and 1's; Pass 2: Same as #1; Pass 3: Same as #1; Pass 4: Same as #1; Pass 5: 010101; Pass 6: 101010; Pass 7: 100100; Pass 8: 010010; Pass 9: 000000; Pass 10: 111111 

=head2 ( $lines, $words, $characters ) = B<Butler( $file, "wc" )>

Returns the number of lines, words, and characters in $file.  This may or may not exactly match the Linux tool "wc". The number of words in this case is the number of word items matching the regular expression m/(\w+)/g;

=head1 AUTHOR

Kurt Kincaid, sifukurt@yahoo.com

=head1 SEE ALSO

perl(1).

=cut
