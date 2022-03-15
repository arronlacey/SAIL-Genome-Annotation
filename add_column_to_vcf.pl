#/usr/bin/env perl

BEGIN { $^I = ".bak"; }
BEGIN { $^W = l;}
while ( defined( $_ = readline ARGV ) ){
    if ( /^Chr/ ) {
        s/$/tVCF_FILE_PE/;
        ( $number ) = $ARGV =~ /^([0-9]+)/;
    } else {
        s/$/t$number/;
    }
    print $_;
}