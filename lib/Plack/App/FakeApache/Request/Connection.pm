package Plack::App::FakeApache::Request::Connection;

use Moose;

has remote_ip => (
    is => 'rw',
    isa => 'Str',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Plack::App::FakeApache::Request::Connection - mock Apache::Connection for Plack

=head1 DESCRIPTION

Only the C<remote_ip> method is implmented.