#!/usr/bin/env perl

BEGIN { use FindBin; use lib "$FindBin::Bin/mojo/lib" }

use Mojolicious::Lite;

app->secrets(['kuuX8sheish0is1il1ci3ieQuu1ohh']);

my %config = (
    title   => $ENV{WOLICIOUS_TITLE}   || 'wolicious',
    descr   => $ENV{WOLICIOUS_DESCR}   || 'Wake on Lan Monitor',
    footer  => $ENV{WOLICIOUS_FOOTER}  || 'powered by Mojolicious::Lite',
    reload  => $ENV{WOLICIOUS_RELOAD}  || '',
    baseurl => $ENV{WOLICIOUS_BASEURL} || '/',
    ping_proto   => 'tcp',    # default tcp, icmp, udp
    ping_timeout => '0.5',    # ping timeout
);

#
# setup your sleeping lan in %hosts
#
my %hosts = (
    1 => ["pc01", "10.10.10.1", "00:11:22:AA:AA:AA"],
    2 => ["pc02", "10.10.10.2", "00:11:22:AA:AA:BB"],
    3 => ["pc03", "10.10.10.3", "00:11:22:AA:AA:CC"],
    4 => ["pc04", "10.10.10.4", "00:11:22:AA:AA:DD"],
    5 => ["pc05", "10.10.10.5", "00:11:22:AA:AA:EE"],
);

#
# or do it with an csv-file named: wolicious.csv
#
#   #id,name,ip,mac
#   1,pc01,10.10.10.1,00:11:22:AA:AA:AA
#   2,pc02,10.10.10.2,00:11:22:AA:AA:BB
#   ...
#
my $csv_file = "wolicious.csv";
_read_hosts_from_csv(\%hosts, $csv_file) if (-e $csv_file);

sub index {
    my $self = shift;

    use Net::Ping;
    my $p = Net::Ping->new($config{'ping_proto'}, $config{'ping_timeout'});

    my %alive;

    foreach my $host (keys %hosts) {
        $alive{$host} = 'alive' if $p->ping("$hosts{$host}[1]");
        app->log->debug("ping host:$hosts{$host}[1]");
    }

    $self->stash(config => \%config, hosts => \%hosts, alive => \%alive,);
}

sub wol {
    my $self = shift;

    my $id   = $self->stash('id');
    my $name = $hosts{$id}[0];
    my $ip   = $hosts{$id}[1];
    my $mac  = $hosts{$id}[2];

    use Net::Wake;
    my $ret = Net::Wake::by_udp(undef, $mac);
    app->log->info("wol: id:$id, mac:$mac, ret:$ret");

    $self->stash(
        config => \%config,
        id     => \$id,
        name   => \$name,
        ip     => \$ip,
        mac    => \$mac,
    );
}

sub _read_hosts_from_csv {
    my ($hosts, $file) = @_;

    %$hosts = ();

    if (open my $fh, "<", $file) {
        my @lines = <$fh>;
        close $fh;

        my @csv;

        foreach my $line (@lines) {

            chomp $line;
            next unless $line;
            next if $line =~ m/^$/;
            next if $line =~ m/^#/;

            @csv = split /,/, $line;
            my $id = shift @csv;
            $hosts->{$id} = [@csv];

        }

    }

}

#
# Routes
#
get '/' => \&index => 'index';

get '/index' => \&index => 'index';

get '/wol/:id' => \&wol => 'wol';

app->start(@ARGV ? @ARGV : 'cgi');

__DATA__

@@ index.html.ep
% my $self = shift;
% layout 'default';
<div id="header">
    <h1 id="title"><a href="/"><%= $config->{'title'} %></a></h1>
    <h2 id="descr"><%= $config->{'descr'} %>!</h2>
</div><!-- div id="header" --> 
    <p />
    <div align="center"><h1>Hosts</h1></div>
    <p />
    <div align="center"><table border="0" cellspcacing="15" cellpadding="15">
    <!--
        <tr>
            <th>Nr.</th>
            <th>Name</th>
            <th>IP</th>
            <th>Status</th>
        </tr>
    -->
% foreach my $host (sort keys %$hosts) {
% if ($alive->{$host}) {
        <tr>
            <td bgcolor="lightgreen"><%= $host %></td>
            <td bgcolor="lightgreen"><%= $hosts->{$host}[0] %></td>
            <td bgcolor="lightgreen"><%= $hosts->{$host}[1] %></td>
            <td bgcolor="lightgreen">alive</td>
        </tr>
% } else {
        <tr>
            <td bgcolor="lightgrey"><%= $host %></td>
            <td bgcolor="lightgrey"><%= $hosts->{$host}[0] %></td>
            <td bgcolor="lightgrey"><%= $hosts->{$host}[1] %></td>
            <td bgcolor="lightgrey"><a href="wol/<%= $host %>"> >> wake-up</a></td>
        </tr>
% }
% }
    </table></div>
    <p />

@@ wol.html.ep
% my $self = shift;
% layout 'default';
<div id="header">
    <h1 id="title"><a href="../"><%= $config->{'title'} %></a></h1>
    <h2 id="descr"><%= $config->{'descr'} %>!</h2>
</div><!-- div id="header" --> 
<p />
<pre>
  send wake-up: <b><%= $$id %> ->  <%= $$name %>, <%= $$ip %>, <%= $$mac %></b>
</pre>

@@ layouts/default.html.ep
% my $self = shift;
<!html>
    <head>
        <title><%= $config->{'title'} %></title>
        <meta http-equiv="refresh" content="<%= $config->{'reload'} %>; URL=/">
        <style type="text/css">
            body {background: #fff;font-family: "Helvetica Neue", Arial, Helvetica, sans-serif;}
            h1,h2,h3,h4,h5 {font-family: times, "Times New Roman", times-roman, georgia, serif; line-height: 40px; letter-spacing: -1px; color: #444; margin: 0 0 0 0; padding: 0 0 0 0; font-weight: 100;}
            a,a:active {color:#555}
            a:hover{color:#000}
            a:visited{color:#000}
            img{border:0px}
            pre{border:2px solid #ccc;background:#eee;padding:2em}
            #body {width:65%;margin:auto}
            #header {text-align:center;padding:2em 0em 0.5em 0em;border-bottom: 1px solid #000}
            h1#title{font-size:3em}
            h2#descr{font-size:1.5em;color:#999}
            span#author {font-weight:bold}
            span#about {font-style:italic}
            #menu {padding-top:1em;text-align:right}
            #content {background:#FFFFFF}
            .created, .modified {color:#999;margin-left:10px;font-size:small;font-style:italic;padding-bottom:0.5em}
            .modified {margin:0px}
            .tags{margin-left:10px;text-transform:uppercase;}
            .text {padding:2em;}
            .text h1.title {font-size:2.5em}
            .more {margin-left:10px}
            #pager {text-align:center;padding:2em}
            #pager span.notactive {color:#ccc}
            #subfooter {padding:2em;border-top:#000000 1px solid}
            #footer {font-size:80%;text-align:center;padding:2em;border-top:#000000 1px solid}
        </style>
    </head>
    <body>
        <div id="body">
            <%= content %>
            <div id="footer"><%= $config->{footer} %></div>
        </div><!-- div id=body -->
    </body>
</html>

__END__

=head1 NAME

Wolicious -  Wake On Lan Monitor!

=head1 SYNOPSIS

$ perl wolicious.pl daemon

$ <lynx|w3m|firefox> http://localhost:3000

=head1 DESCRIPTION

Wolicious is an wake on lan application, which shows if hosts are
alive or down. You can wake up down machines with one click. It is
specially useful for remote lan access.

Wolicious is my first Mojolicious::Light webapp. More for testing
mojolicious and github rather then absolut required. It's based of
an old CGI.pm tool of mine. 

The Design is of course an contribute to vti and his cool one-file
blog engine. <http://getbootylicios.org> 
Bootylicious is also a good introduction in mojolicious by example.

=head1 DEPENDENCIES

=over

=item * Perl 5.8.1 or greater, <http://www.perl.org/get.html>

=item * Mojolicious, <http://www.mojolicious.org>

=item * Net::Ping, <http://search.cpan.org/~smpeters/Net-Ping-2.36/>

=item * Net::Wake, <http://search.cpan.org/~clintdw/Net-Wake-0.02/>

=back

=head1 CONFIGURATION

Wolicious can be configured like bootylicious through %config in 
wolicious.pl or it's corresponding enviroment variables.

    my %config = (
        title   => $ENV{WOLICIOUS_TITLE}   || 'wolicious',
        descr   => $ENV{WOLICIOUS_DESCR}   || 'Wake on Lan Monitor',
        footer  => $ENV{WOLICIOUS_FOOTER}  || 'powered by Mojolicious::Lite',
        reload  => $ENV{WOLICIOUS_RELOAD}  || '',
        baseurl => $ENV{WOLICIOUS_BASEURL} || '/',
    );

Setup your lan machines in %hosts in wolicious.pl,

    my %hosts = (
        1 => ["pc01", "10.10.10.1", "00:11:22:AA:AA:AA"],
        2 => ["pc02", "10.10.10.2", "00:11:22:AA:AA:BB"],
        3 => ["pc03", "10.10.10.3", "00:11:22:AA:AA:CC"],
        4 => ["pc04", "10.10.10.4", "00:11:22:AA:AA:DD"],
        5 => ["pc05", "10.10.10.5", "00:11:22:AA:AA:EE"],
    );


or in csv-file named wolicious.csv placed in the same directory as
wolicious.pl.

    #
    # id,name,ip,mac
    #
    1,pc01,10.10.10.1,00:11:22:AA:AA:AA
    2,pc02,10.10.10.2,00:11:22:AA:AA:BB
    3,pc03,10.10.10.3,00:11:22:AA:AA:CC
    4,pc04,10.10.10.4,00:11:22:AA:AA:DD
    5,pc05,10.10.10.5,00:11:22:AA:AA:EE

=head1 DEVELOPEMENT

=head2 REPOSITORY

http://github.com/tholen/wolicious

=head2 BUGTRACKING

http://github.com/tholen/wolicious/issues

=head2 WIKI

http://wiki.github.com/tholen/wolicious

=head1 SEE ALSO

L<Mojo> L<Mojolicious> L<Mojolicious::Lite> L<Bootylicious>

=head1 CREDITS

Viacheslav Tykhanovskyi

Sebastian Riedel

=head1 AUTHOR

Thomas Lenz, C<tholen@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Thomas Lenz.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
