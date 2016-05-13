package Plack::App::Net::Async::WebSocket;

use strict;
use warnings;
use parent qw( Plack::Component );

use Protocol::WebSocket::Handshake::Server;
use Carp;

our $VERSION = '0.01';

sub new {
	my ( $class, @params ) = @_;
	my $self = $class->SUPER::new( @params );
	croak "on_frame param is mandatory" if not defined $self->{on_frame};
	return $self;
}

sub call
{
	my ( $self, $env ) = @_;

	my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi( $env );

	if ( !$hs->is_done ) {
		$hs->parse('');

		if ( $hs->error ) {
			return [ 500,
				[ 'Content-Type' => 'text/plain' ],
				[ $hs->error ]];
		}

		if ( $hs->is_done ) {
			my $h = HTTP::Response->parse( $hs->to_string );
			return sub {
				my $responder = shift;
				my $writer = $responder->(
					[ 101, [ Upgrade => 'WebSocket', Connection => 'Upgrade', 'Sec-WebSocket-Accept' => $h->header('Sec-WebSocket-Accept') ]]
				);

				my $stream = $writer->[0]->stream;
				
				$stream->configure(
					on_read => sub {
						my ( $ws, $buffref, $closed ) = @_;

						my $framebuffer = $hs->build_frame;

						$framebuffer->append( $$buffref );

						while( defined( my $frame = $framebuffer->next ) ) {
							$self->{on_frame}->( $ws, $frame );
						}
						return 0;
					},
					on_closed => sub {
						$self->{on_closed}->( shift ) if exists $self->{on_closed};
					}
				);

				$self->{on_client}->( $stream ) if exists $self->{on_client};	
			};
		}
	}

1;

__END__

