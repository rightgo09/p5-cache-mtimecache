use strict;
use warnings;
use File::Temp qw/ tempfile /;
use File::Basename qw/ dirname basename /;
use File::Spec;
use Test::More tests => 4;
use Cache::Mtimecache;

my $cache = new_ok('Cache::Mtimecache');
my ($fh, $tmpl_file) = tempfile(CLEANUP => 1);
print $fh <<'EOS';
%div
  %p Test
EOS
close $fh;
my $tmpl_dir = dirname($tmpl_file);
my $tmpl_name = basename($tmpl_file);

$cache->tmpl_dir($tmpl_dir);

$cache->set($tmpl_name, <<'EOS');
<div>
  <p>Test</p>
</div>
EOS
is($cache->get($tmpl_name), <<'EOS');
<div>
  <p>Test</p>
</div>
EOS

my $mtime = (stat($tmpl_file))[9];
$mtime += 1000;
utime $mtime, $mtime, $tmpl_file;

is($cache->get($tmpl_name), undef);

$cache->set($tmpl_name, <<'EOS');
<ul>
  <li>Test</li>
</ul>
EOS
is($cache->get($tmpl_name), <<'EOS');
<ul>
  <li>Test</li>
</ul>
EOS

