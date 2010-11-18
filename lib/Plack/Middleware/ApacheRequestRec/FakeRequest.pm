package Plack::Middleware::ApacheRequestRec::FakeRequest;

use APR::Pool;
use APR::Table;

use Plack::Request;

sub new {
    my ($class, $env, %args) = @_;

    my $preq = Plack::Request->new( $env );
    my $pool = APR::Pool->new();

    my $self = {
        # Plack
        request    => $preq,
        response   => $preq->new_response,

        # Apache
        pool           => $pool,
        headers_in     => APR::Table::make($pool, 64),
        headers_out    => APR::Table::make($pool, 64),
        subprocess_env => APR::Table::make($pool, 64),

        content        => [],
        dir_config     => $args{dir_config} // {},
    };

    bless $self, $class;
}

# Plack interface:
sub plack_request  { $_[0]->{request}  }
sub plack_response { $_[0]->{response} }

sub finalize { 
    my $self     = shift;
    my $response = $self->plack_response;

    $self->{headers_out}->do( sub {
        $response->header( @_ );
    } );

    $response->body( $self->{content} );

    return $response->finalize;
};

# Apache interface:
sub headers_in     { $_[0]->{headers_in} }
sub headers_out    { $_[0]->{headers_in} }
sub subprocess_env { $_[0]->{subprocess_env} }

sub content_type     { shift->{response}->content_type( @_ ) }
sub content_encoding { shift->{response}->content_encoding( @_ ) }
sub status           { shift->{response}->status( @_ ) }
sub log_reason       { 1 }; # TODO!

sub method       { $_[0]->{request}->method }
sub unparsed_uri { $_[0]->{request}->request_uri }
sub uri          { $_[0]->{request}->path } 
sub user         { $_[0]->{request}->user }

sub dir_config   { $_[0]->{dir_config}->{$_[1]} }

sub hostname {
    my $self = shift;

    return $self->{request}->env->{SERVER_NAME};
}

sub read {
    my $self = shift;
    my ($buffer, $length, $offset) = @_; # ... but use $_[0] for buffer

    my $request = $self->{request};

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

    my $sent = 0;
    for (@_) {
        push @{ $self->{content} }, $_;
        $sum += length;
    }

    return $length;
}

sub write {
    my ($self, $buffer, $length, $offset) = @_;

    if ($lenght == -1) {
        push @{ $self->{content} }, $buffer;
        return length $buffer;
    }

    my $output = substr $buffer, $offset // 0, $length // length $buffer;

    push @{ $self->{content} }, $output;
    
    return length $output;
}

1;
