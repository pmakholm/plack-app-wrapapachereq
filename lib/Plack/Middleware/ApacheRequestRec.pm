package Plack::Middleware::ApacheRequestRec;

use Plack::Util::Accessor qw( dir_config );
use Plack::Middleware::ApacheRequestRec::FakeRequest;
use parent qw( Plack::Middleware );

our $VERSION = 0.1;

sub call {
    my ($self, $env) = @_;

    my $fake_req = Plack::Middleware::ApacheRequestRec::FakeRequest->new(
        $env,
        dir_config => $self->dir_config,
    );
    $fake_req->status( 200 );

    my $result   = $self->app->handler( $fake_req ); # App is a mod_perl2 handler and not a PSGI APP.
    
    if ( $result != OK ) {
        $fake_req->status( $result );    
    }

    return $fake_req->finalize;
}

1;

__END__

=head1 NAME

Plack::Middleware::ApacheRequestRec - Wrapping mod_perl2 applications in Plack

=head1 SYNOPSIS

  use Plack::Builder;
  use My::ApacheHandler;

  builder {
      enable "ApacheRequestRec", dir_config => { ... };

      "My::ApacheHandler";
  }

=head1 DESCRIPTION

Plack::Middleware::ApacheRequestRec transforms a mod_perl2 application into
a PSGI application

=head1 NOTICE

This is Proof of Concept code originating in the mocking code developed to
test an internal very non-trivial mod_perl2 application. Features have been
added on a need to have basis.

=head1 CONFIGURATION

This Middleware module takes a single parameter for us with the dir_config
method.

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
