#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use Mojo::Transaction::Single;
use Mojo::Client;

use FindBin;
require "$FindBin::Bin/../wolicious.pl";

my $client = Mojo::Client->new;

# Index page
my $tx = Mojo::Transaction::Single->new_get('/');
$client->process_app(app(), $tx);
is($tx->res->code, 200);

# Index page
$tx = Mojo::Transaction::Single->new_get('/index.html');
$client->process_app(app(), $tx);
is($tx->res->code, 200);

# wol page 1
$tx = Mojo::Transaction::Single->new_get('/wol/1');
$client->process_app(app(), $tx);
is($tx->res->code, 200);
like($tx->res->body, qr/wake-up/);
like($tx->res->body, qr/00\:11\:22\:AA\:AA\:AA/);

# wol page 2
$tx = Mojo::Transaction::Single->new_get('/wol/2');
$client->process_app(app(), $tx);
is($tx->res->code, 200);
like($tx->res->body, qr/wake-up/);
like($tx->res->body, qr/00\:11\:22\:AA\:AA\:BB/);

