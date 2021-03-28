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
my $pos_x = 4;
my $pos_y = 19;

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
        move( -1, 0 );
    }

    if ( $key eq "d" ) {
        move( 1, 0 );
    }

    if ( $key eq "s" ) {
        move( 0, -1);
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
            move( 0, -1 );
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

my $hor_moves = 0;

sub move {
    my ( $hor, $ver ) = @_;

    #force move down after 10 hor moves - hacky
    $ver = -1 if ( $hor_moves > 9 );

    #later use loop
    if ( $ver != 0 ) {

        #item is done if it tries to move down on non empty position
        if ( hit( $pos_x + $hor, $pos_y + $ver, 2 ) ) {
            if ( check_game_over() ) {
                print "Game Over!\n";
                exit(0);
            }
            if ( check_clear_row() ) {
                clear_row($pos_y);
                print "schould clear that row bro ho ho hoe\n";
            }
            trigger_next();
            return;
        }

        my @row = @{ $board{"row_$pos_y"} };
        $row[$pos_x]         = 0;
        $row[ $pos_x + 1 ]   = 0;
        $board{"row_$pos_y"} = \@row;

        $pos_y += $ver;

        my @next_row = @{ $board{"row_$pos_y"} };
        $next_row[$pos_x]       = 1;
        $next_row[ $pos_x + 1 ] = 1;
        $board{"row_$pos_y"}    = \@next_row;

        $hor_moves = 0;
    }
    if ($hor) {
        my @row = @{ $board{"row_$pos_y"} };
        $row[$pos_x]         = 0;
        $row[ $pos_x + 1 ]   = 0;
        $board{"row_$pos_y"} = \@row;

        $pos_x += $hor;

        @row                 = @{ $board{"row_$pos_y"} };
        $row[$pos_x]         = 1;
        $row[ $pos_x + 1 ]   = 1;
        $board{"row_$pos_y"} = \@row;

        $hor_moves++;
    }

    print_board();
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
