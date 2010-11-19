package Plack::App::WrapApacheReq::FakeRequest;

use Moose;

use APR::Pool;
use APR::Table;

use Plack::Request;
use Plack::Response;

# Plack related attributes:
has env => (
    is       => 'ro',
    isa      => 'HashRef[Any]',
    required => 1,
);

has plack_request => (
    is         => 'ro',
    isa        => 'Plack::Request',
    lazy_build => 1,
    handles    => {
        method       => 'method',
        unparsed_uri => 'request_uri',
        uri          => 'path',
        user         => 'user',
    },
);

has plack_response => (
    is         => 'ro',
    isa        => 'Plack::Response',
    lazy_build => 1,
    handles    => {
        content_type     => 'content_type',
        content_encoding => 'content_encoding',
        status           => 'status',
    },
);

# Apache related attributes
has _apr_pool => (
    is         => 'ro',
    isa        => 'APR::Pool',
    lazy_build => 1,
);

has headers_in => (
    is         => 'ro',
    isa        => 'APR::Table',
    lazy_build => 1,
);

has headers_out => (
    is         => 'ro',
    isa        => 'APR::Table',
    lazy_build => 1,
);

has subprocess_env => (
    is         => 'ro',
    isa        => 'APR::Table',
    lazy_build => 1,
);

has dir_config => (
    isa     => 'HashRef[Any]',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        dir_config => 'accessor'
    }
);

# builders
sub _build_plack_request  { return Plack::Request->new( shift->env ) }
sub _build_plack_response { return Plack::Response->new( 200, {}, [] ) }
sub _build__apr_pool      { return APR::Pool->new() }
sub _build_subprocess_env { return APR::Table::make( shift->_apr_pool, 64 ) }
sub _build_headers_out    { return APR::Table::make( shift->_apr_pool, 64 ) }

sub _build_headers_in { 
    my $self  = shift;
    my $table = APR::Table::make( $self->_apr_pool, 64 );

    $self->plack_request->headers->scan( sub {
        $table->add( @_ );
    } );

   return $table;
}

# Plack methods
sub finalize { 
    my $self     = shift;
    my $response = $self->plack_response;

    # XXX Why does I suddenly need a filter to supress 'Use of uninitialized value in subroutine entry'
    $self->headers_out->do( sub { $response->header( @_ ) }, sub { 1 } );

    return $response->finalize;
};

# Appache methods
sub log_reason { 1 } # TODO
sub hostname {
    my $self = shift;

    return $self->env->{SERVER_NAME};
}

sub read {
    my $self = shift;
    my ($buffer, $length, $offset) = @_; # ... but use $_[0] for buffer

    my $request = $self->plack_request;

    # Is this needed? Intrudes on a Plack::Request private methodf...
    unless ($request->env->{'psgix.input.buffered'}) {
        $request->_parse_request_body;

        # Sets psgix.input.buffered and rewinds.
    }

    my $fh = $request->input
        or return 0;

    return $fh->read($_[0], $length, $offset);
}

sub print {
    my $self = shift;

    my $length = 0;
    for (@_) {
        $self->_add_content($_);
        $length += length;
    }

    return $length;
}

sub write {
    my ($self, $buffer, $length, $offset) = @_;

    if (defined $length && $length == -1) {
        $self->_add_content($buffer);
        return length $buffer;
    }

    my $output = substr $buffer, $offset // 0, $length // length $buffer;

    $self->_add_content($output);
    
    return length $output;
}

sub _add_content {
    my $self = shift;

    push @{ $self->plack_response->body }, @_;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
