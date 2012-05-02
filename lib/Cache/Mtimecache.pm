package Cache::Mtimecache;
use strict;
use warnings;
use File::Spec;
use Mouse;

has 'cache_dir' => (
	is => 'rw',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $cache_dir = '.cache_mtime_cache';
		for my $dir ($ENV{HOME}, File::Spec->tmpdir) {
			if (defined($dir) && -d $dir && -w _) {
				$cache_dir = File::Spec->catdir($dir, '.cache_mtime_cache');
				last;
			}
		}
		return $cache_dir;
	},
);
has 'tmpl_dir' => (
	is => 'rw',
	isa => 'Str',
	lazy => 1,
	default => '.',
);
has 'cache_ext' => (
	is => 'rw',
	isa => 'Str',
	lazy => 1,
	default => 'cache',
);

__PACKAGE__->meta->make_immutable();

no Mouse;
use Carp ();
use File::Path qw/ mkpath /;
use URI::Escape qw/ uri_escape /;
use File::Basename qw/ basename dirname /;

sub get {
	my ($self, $tmpl_path) = @_;

	my ($cache_fullpath, $orig_mtime) = $self->_init($tmpl_path);

	open my $fh, '<:raw', $cache_fullpath or return;
	read $fh, my $cache_mtime, length($orig_mtime);
	if ($orig_mtime == $cache_mtime) {
		my $content = do { local $/; <$fh> };
		return $content;
	}
	return;
}

sub set {
	my ($self, $tmpl_path, $content) = @_;

	my ($cache_fullpath, $orig_mtime) = $self->_init($tmpl_path);

	open my $fh, '>', $cache_fullpath or return;
	print $fh $orig_mtime.$content;
	close $fh;

	return 1;
}

sub _init {
	my ($self, $tmpl_path) = @_;

	Carp::croak("require \$tmpl_path!") unless $tmpl_path;

	my $tmpl_fullpath = File::Spec->rel2abs(File::Spec->catfile($self->tmpl_dir, $tmpl_path));

	my $dir_uri_escaped = uri_escape(dirname($tmpl_fullpath));

	my $cache_dir = File::Spec->catdir($self->cache_dir, $dir_uri_escaped);

	unless (-d $cache_dir) {
		mkpath($cache_dir) or die $!;
	}
	my $tmpl_file = basename($tmpl_path);

	my $cache_fullpath = File::Spec->catfile($cache_dir, $tmpl_file.'.'.$self->cache_ext);
	my $orig_mtime = (stat($tmpl_fullpath))[9];

	return ($cache_fullpath, $orig_mtime);
}

1;
