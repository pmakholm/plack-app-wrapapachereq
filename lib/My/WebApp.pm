package My::WebApp;

use 5.10.0;
use strict;
use warnings;

use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::Log;
use Apache2::Const qw(:common :http);

use Cwd;
use Errno qw(:POSIX);
use Scalar::Util qw(blessed);
use Digest::SHA qw(sha1_hex);

sub new {
    my $class = shift;
    my $self  = {
        docroot => getcwd(),
        @_
    };

    return bless $self, $class;
}

sub docroot { return shift->{docroot} };

sub handler :method {
    my ($proto, $req) = @_;
    my $method  = uc( $req->method);
    my $self    = blessed $proto ? $proto : $proto->new();     

    return $self->$method($req) if $self->can($method);
    
    $req->status(HTTP_NOT_IMPLEMENTED);
    return HTTP_NOT_IMPLEMENTED;
}

sub GET {
    my ($self, $req) = @_;
    my $path = join("/", $self->docroot, sha1_hex($req->uri));

    open my $fh, "<", $path
        or do {
            my $err = $!;

            $req->log_reason("Couldn't open $path: $err");
            return HTTP_NOT_FOUND if $err == ENOENT;
            return HTTP_FORBIDDEN if $err == EPERM;
            return HTTP_INTERNAL_SERVER_ERROR;
        };
        

    my $content;
    while( defined( $content = <$fh> ) ) {
        $req->write($content);
    }

    return OK;
}

sub PUT {
    my ($self, $req) = @_;
    my $path = join("/", $self->docroot, sha1_hex($req->uri));

    open my $fh, ">", $path
        or do {
            my $err = $!;

            $req->log_reason("Couldn't open $path: $err");
            return HTTP_NOT_FOUND if $err == ENOENT;
            return HTTP_FORBIDDEN if $err == EPERM;
            return HTTP_INTERNAL_SERVER_ERROR;
        };
        

    my $content;
    while( $req->read( $content, 4096 ) ) {
        print $fh $content;
    }

    $req->status(HTTP_CREATED);
    return OK;
}


1;
