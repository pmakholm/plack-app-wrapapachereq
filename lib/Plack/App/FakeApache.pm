package Plack::App::FakeApache;

use Plack::Util;
use Plack::Util::Accessor qw( handler dir_config );
use Plack::App::FakeApache::Request;
use parent qw( Plack::Component );
use attributes;

use Carp;
use Scalar::Util qw( blessed );

our $VERSION = 0.02;

sub call {
    my ($self, $env) = @_;

    my $fake_req = Plack::App::FakeApache::Request->new(
        env => $env,
        dir_config => $self->dir_config,
    );
    $fake_req->status( 200 );


    my $handler;
    if ( blessed $self->handler ) {
        $handler = sub { $self->handler->handler( $fake_req ) };
    } else {
        my $class   = $self->handler;
        my $method = eval { $class->can("handler") };

        if ( grep { $_ eq 'method' } attributes::get($method) ) {
            $handler = sub { $class->$method( $fake_req ) };
        } else {
            $handler = $method;
        }
    }

    my $result = $handler->( $fake_req ); 
    
    if ( $result != OK ) {
        $fake_req->status( $result );    
    }

    return $fake_req->finalize;
}

sub prepare_app {
    my $self    = shift;
    my $handler = $self->handler;

    carp "handler not defined" unless defined $handler;

    $handler = Plack::Util::load_class( $handler ) unless blessed $handler;
    $self->handler( $handler );

    return;
}

1;

__END__

=head1 NAME

Plack::App::FakeApache - Wrapping mod_perl2 applications in Plack

=head1 SYNOPSIS

  use Plack::App::FakeApache;

  my $app = Plack::App::FakeApache->new( 
    handler    => "My::ResponseHandler"
    dir_config => { ... }
  )->to_app;    

=head1 DESCRIPTION

Plack::App::FakeApache transforms a mod_perl2 application into
a PSGI application

=head1 NOTICE

This is Proof of Concept code originating in the mocking code developed to
test an internal very non-trivial mod_perl2 application. Features have been
added on a need to have basis.

=head1 CONFIGURATION

=over 4

=item handler (required)

=item dir_config

Hash used to resolve $req->dir_config() requests

=back

=head1 APACHE METHODS

The following methods from L<Apache2::RequestRec> and mixins are supported:

=over 4

=item headers_in

=item headers_out

=item subprecess_env

=item dir_config

=item method

=item unparsed_uri

=item uri

=item user

=item hostname

=item content_type

=item content_encoding

=item status

=item log_reason (implemented as a no-op)

=item read

=item print

=item write

=back

=head1 PLACK METHODS

A few methods have been added to the interface to enable interaction with
Plack:

=over 4

=item plack_request

Returns the underling L<Plack::Request> object

=item plack_response

Returns the underlying L<Plack::Response> object. During the request phase
this is incomplete.

=item finalize

Fills information into the response object and finalizes it.

=back

=head1 AUTHOR

Peter Makholm, L<peter@makholm.net>

=cut
