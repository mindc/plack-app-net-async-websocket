
use strict;
use Plack::App::Net::Async::WebSocket;

my $app = Plack::App::Net::Async::WebSocket->new(
	on_frame => sub {
		my ( $ws, $frame ) = @_;
		$ws->send_frame( $frame );
	}
)->to_app;