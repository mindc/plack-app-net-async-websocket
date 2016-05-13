use 5.008005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Plack::App::Net::Async::WebSocket',
    VERSION_FROM   => 'lib/Plack/App/Net/Async/WebSocket.pm',
    PREREQ_PM      => { 
		'Test::More' => 0, 
		'Exporter'  => '5.57',
		'IO::Async' => '0.10',
		'Protocol::WebSocket::Handshake::Server' => 0
	},
);
