#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use Mojo::Transaction::HTTP;
use Mojo::UserAgent;

use FindBin;
require "$FindBin::Bin/../wolicious.pl";

my $ua = Mojo::UserAgent->new;

# Index page
my $tx = Mojo::Transaction::HTTP->new;
$tx->req->method('GET');
$tx->req->url->parse('/');
$ua->start($tx);
is($tx->res->code, 200, "get /");

# Index page
$tx = Mojo::Transaction::HTTP->new;
$tx->req->method('GET');
$tx->req->url->parse('/index.html');
$ua->start($tx);
is($tx->res->code, 200, "get /index.html");

# wol page 1
$tx = Mojo::Transaction::HTTP->new;
$tx->req->method('GET');
$tx->req->url->parse('/wol/1');
$ua->start($tx);
is($tx->res->code, 200, "get /wol/1");
like($tx->res->body, qr/wake-up/, "like wake-up");
like($tx->res->body, qr/00\:11\:22\:AA\:AA\:AA/, 'like 00:11:22:AA:AA:AA');

## wol page 2
$tx = Mojo::Transaction::HTTP->new;
$tx->req->method('GET');
$tx->req->url->parse('/wol/2');
$ua->start($tx);
is($tx->res->code, 200, "get /wol/2");
like($tx->res->body, qr/wake-up/, 'like wake-up');
like($tx->res->body, qr/00\:11\:22\:AA\:AA\:BB/, 'like 00:11:22:AA:AA:BB');

