package Plack::App::Net::Async::WebSocket;

use strict;
use warnings;
use parent qw( Plack::Component );

use Protocol::WebSocket::Handshake::Server;
use Net::Async::WebSocket::Protocol;
use Carp;
use Data::Dumper;

our $VERSION = '0.01';


sub Net::Async::HTTP::Server::Protocol::send_frame
{
	my ( $self, $frame ) = @_;
	$self->write( Protocol::WebSocket::Frame->new( $frame )->to_bytes );
}

sub Net::Async::WebSocket::Protocol::send_broadcast
{
	my ( $self, $frame ) = @_;
	foreach ( $self->loop->notifiers ) {
		if ( exists($_->{'ws.path'}) && $_->{'ws.path'} eq $self->{'ws.path'} ) {
			$_->send_frame( $frame );
		}
	}
}

sub new {
	my ( $class, @params ) = @_;
	my $self = $class->SUPER::new( @params );
	croak "on_frame param is mandatory" if not defined $self->{on_frame};
	croak "on_established param is mandatory" if not defined $self->{on_established};
	return $self;
}

sub call
{
	my ( $self, $env ) = @_;

	my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi( $env );
	my $stream = $env->{'net.async.http.server.req'}->stream;

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

				my $fb = Protocol::WebSocket::Frame->new;
				$stream->configure(
					on_read => sub {
						my ( undef, $buffref, $closed ) = @_;
						$fb->append( $$buffref );
						while( defined( my $frame = $fb->next ) ) {
							$self->{on_frame}->( $stream, $frame );
						}
						return 0;
					}
				);
				
			};
		}
	}
}

1;

