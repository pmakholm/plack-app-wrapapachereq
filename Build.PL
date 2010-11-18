#!/usr/bin/perl
# $Id:$

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Plack::App::WrapApacheReq',

    requires    => {
        'Plack'      => 0,
        'APR::Pool'  => 0,
        'APR::Table' => 0,
    },
);
$build->create_build_script;

