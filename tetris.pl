#!/usr/bin/perl

use strict;
use warnings;

use lib "./local/lib/perl5";

use Data::Dumper;
use Term::ANSIColor;
use Term::Cap;
use Term::ReadKey;

print "this is tetris\n";

#do it better copy and paste sucks
#
require POSIX;
my $termios = new POSIX::Termios;
$termios->getattr;
my $ospeed = $termios->getospeed;

my $terminal = Tgetent Term::Cap { TERM => undef, OSPEED => $ospeed };

$terminal->Trequire(qw/ce ku kd/);

my $FH = *STDOUT;

my %board;
my $pos_x     = 4;
my $pos_y     = 16;
my $hor_moves = 0;
my @bar       = ( [ 1, 1 ] );
my @square    = ( [ 1, 1 ], [ 1, 1 ] );
my @cur_block = @bar;

init_empty_board();
print_board();
input();

sub input {
    wait_for_input( \&input_cb );
}

sub input_cb {
    my ($key) = @_;

    print "key hit";
    if ( $key eq "a" ) {
        $pos_x--;
        set_block( "left", ".", $pos_y, $pos_x, \@cur_block );
    }

    if ( $key eq "d" ) {
        $pos_x++;
        set_block( "right", ".", $pos_y, $pos_x, \@cur_block );
    }

    if ( $key eq "s" ) {
        $pos_y--;
        set_block( "down", ".", $pos_y, $pos_x, \@cur_block );
    }

    if ( $key eq " " ) {
        roate();
    }
    input();
}

my $lock_hor = 0;

sub wait_for_input {
    my ($callback) = @_;

    my $input = undef;

    ReadMode 4;    # Turn off controls keys

    my $move_down_counter = 0;
    while ( not defined( $input = ReadKey(-1) ) ) {
        select( undef, undef, undef, 0.01 );
        $move_down_counter++;
        if ( $move_down_counter > 30 ) {
            #$pos_y--;
            #set_block( "down", ".", $pos_y, $pos_x, \@cur_block );
            $move_down_counter = 0;
        }
    }
    ReadMode 0;

    exit(0) if ( $input eq "q" );

    &$callback($input);
    $input = undef;

}

sub init_empty_board {

    for ( my $i = 0 ; $i < 20 ; $i++ ) {
        my @row;
        push @row, 0 while ( scalar @row < 10 );
        $board{"row_$i"} = \@row;
    }
}

sub print_board {

    $terminal->Tgoto( 'cm', 0, 0, $FH );    #cursor move
    $terminal->Tputs( 'cb', 1, $FH );       #Clear from beginning of line to cursor
    $terminal->Tputs( 'cd', 1, $FH );       #Clear to end of screen

    for ( my $i = 19 ; $i >= 0 ; $i-- ) {
        my @row = @{ $board{"row_$i"} };
        foreach my $field (@row) {
            ($field) ? print "x " : print "_ ";
        }
        print "\n";
    }
}

sub check_game_over {
    return 1 if ( $pos_y == 19 );
}

#@TODO consider height
sub check_clear_row {
    my @row = @{ $board{"row_$pos_y"} };
    for my $field (@row) {
        return 0 if ( $field == 0 );
    }
    return 1;
}

sub clear_row {
    my ($row2clear) = @_;
    my @row;
    push @row, 0 while ( scalar @row < 10 );
    $board{"row_$row2clear"} = \@row;
}

#returns true if element hits another element or bottom border
sub hit {
    my ( $pos_x, $pos_y, $width ) = @_;

    #hits bottom border
    return 1 if ( $pos_y < 0 );

    my @row = @{ $board{"row_$pos_y"} };
    for ( $pos_x .. ( $pos_x + $width - 1 ) ) {

        #hits another element
        if ( $row[$_] != 0 ) {
            return 1;
        }
    }

    return 0;

}

sub trigger_next {
    print "next\n";
    $pos_x = 4;
    $pos_y = 19;
    return;
}

sub rotate {
    return;
}

sub set_block {
    my ( $direction, $char, $row, $col, $block ) = @_;

    #print "set_block: char = $char, row = $row, col = $col\n";
    #print Dumper $block;

    my @block        = @{$block};
    my $block_height = scalar @block;

    my %changed_rows;

    #posy + height +1 muss genullt werden
    if ( $direction eq "down" ) {
        my $row_to_clear = $row + $block_height;
        print "clear row $row_to_clear\n";
        my @row          = @{ $board{"row_$row_to_clear"} };
        for ( my $k = 0 ; $k < scalar @{ $block[-1] } ; $k++ ) {
            $row[ $col + $k ] = 0;
        }
        $changed_rows{"row_$row_to_clear"} = \@row;
    }

    for ( my $i = 0 ; $i < $block_height ; $i++ ) {
        my $block_y   = $row + $i;
        my @row       = @{ $board{"row_$block_y"} };
        my $row_width = scalar @{ $block[$i] };

        for ( my $j = 0 ; $j < $row_width ; $j++ ) {
            my $row_x = $pos_x + $j;
            #if ( $row[$row_x] != 0 && $block[$i][$j] == 1 ) {

                #hit
                #dont edit board
                #trigger next
                #return;
                #}
            $row[$row_x] = $block[$i][$j];
        }

        if ( $direction eq "left" ) {
            my $x = $pos_x + $row_width;
            $row[$x] = 0;
        }
        if ( $direction eq "right" ) {
            my $x = $pos_x - 1;
            $row[$x] = 0;
        }
        $changed_rows{"row_$block_y"} = \@row;
    }

    #draw changes on board, after no collision
    foreach my $key ( keys %changed_rows ) {
        $board{$key} = $changed_rows{$key};
    }

    print_board();

    #    $pos_y--;
}
