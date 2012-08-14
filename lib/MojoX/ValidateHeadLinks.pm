package MojoX::ValidateHeadLinks;

use feature 'say';
use strict;
use warnings;

use Hash::FieldHash ':all';

use Log::Handler;

use Mojo::UserAgent;

fieldhash my %doc_root => 'doc_root';
fieldhash my %logger   => 'logger';
fieldhash my %maxlevel => 'maxlevel';
fieldhash my %minlevel => 'minlevel';
fieldhash my %url      => 'url';

our $VERSION = '1.00';

# -----------------------------------------------

sub _count
{
	my($self, $want, $type, $target) = @_;

	$$want{$type}{count}++;

	my($file_name) = $self -> doc_root . $target;

	$self -> log(debug => sprintf('%7s: %s', "\u$type", $file_name) );

	if (! -e $file_name)
	{
		$$want{$type}{error}++;

		$self -> log(error => "Error: $file_name does not exist");
	}

} # End of _count.

# --------------------------------------------------

sub _init
{
	my($self, $arg) = @_;
	$$arg{doc_root} ||= ''; # Caller can set.
	$$arg{logger}   = Log::Handler -> new;
	$$arg{maxlevel} ||= 'notice'; # Caller can set.
	$$arg{minlevel} ||= 'error';  # Caller can set.
	$$arg{url}      ||= '';       # Caller can set.
	$$arg{url}      = "http://$$arg{url}" if ($$arg{url} !~ /^http/);
	$self           = from_hash($self, $arg);

	$self -> logger -> add
	(
	 screen =>
	 {
		 maxlevel       => $self -> maxlevel,
		 message_layout => '%m',
		 minlevel       => $self -> minlevel,
		 newline        => 1, # When running from the command line.
	 }
	);

	return $self;

} # End of _init.

# -----------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> $level($s || '');

} # End of log.

# --------------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	return $self;

}	# End of new.

# -----------------------------------------------

sub quit
{
	my($self, $s) = @_;

	$self -> log(error => $s);

	die "\n";

} # End of quit.

# -----------------------------------------------

sub run
{
	my($self) = @_;

	$self -> log(debug => 'URL: ' . $self -> url);
	$self -> quit('You must provide a value for the doc_root parameter') if (! $self -> doc_root);
	$self -> quit('You must provide a value for the url parameter')      if (! $self -> url);

	my(%want) =
	(
		import =>
		{
			count => 0,
			error => 0,
		},
		link =>
		{
			count => 0,
			error => 0,
		},
		script =>
		{
			count => 0,
			error => 0,
		},
	);
	my($ua)   = Mojo::UserAgent -> new;
	my($head) = $ua -> get($self -> url) -> res -> dom -> html -> head;

	my(@field);
	my(@import);

	for my $item (@{$head -> style})
	{
		next if (! $item -> can('text') );

		@field = map{s/^\s+//; s/\s$//; $_} split(/;/, $item -> text);

		next if ($field[0] !~ /^\@import/);

		for my $field (@field)
		{
			@import    = split(/\s+/, $field);
			$import[1] =~ s/(["'])(.+)\1/$2/;

			$self -> _count(\%want, 'import', $import[1]);
		}
	}

	for my $item (@{$head -> link})
	{
		my($index);

		for my $i (0 .. $#{$$item{tree} })
		{
			if ( (ref $$item{tree}[$i] eq 'HASH') && exists $$item{tree}[$i]{href})
			{
				$index = $i;

				last;
			}
		}

		$self -> _count(\%want, 'link', $$item{tree}[$index]{href}) if ($index);
	}

#	if ($head -> can('script') )
	{
		for my $item (@{$head -> script})
		{
			$self -> _count(\%want, 'script', $$item{src}) if ($$item{src});
		}
	}

	for my $type (sort keys %want)
	{
		$self -> log(info => sprintf('%7s: %d. Errors: %d', "\u${type}s", $want{$type}{count}, $want{$type}{error}) );
	}

	# Return:
	# 0 => success.
	# 1+ => error.

	return $want{link}{error} + $want{import}{error} + $want{script}{error};

}	# End of run.

# -----------------------------------------------

1;

=head1 NAME

MojoX-ValidateHeadLinks - Ensure CSS and JS links in web pages point to real files

=head1 Synopsis

	shell> validate.head.links.pl -h
	shell> validate.head.links.pl -d /dev/shm/html -u http://127.0.0.1/index.html

On my machine, /dev/shm/ is the directory used to access Debian's built-in RAM disk, and /dev/shm/html/ is my
web server's document root directory.

Since this script ships in the bin/ directory, it is installed somewhere along your executable search path
when the module is installed.

=head1 Description

C<MojoX-ValidateHeadLinks> is a pure Perl module.

It does no more than this:

	o Uses HTTP::Tiny to get the web page
	o Extracts the CSS and JS links
	o Ensures these links point to real files

The point is to run validate.head.links.pl after generating a web page, to check whether or not the code
successfully built the <head> part of the page.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<MojoX-ValidateHeadLinks>.

This is the class's contructor.

Usage: C<< MojoX-ValidateHeadLinks -> new() >>.

This method takes a hashref of options.

Call C<new()> as C<< new({option_1 => value_1, option_2 => value_2, ...}) >>.

Available options:

=over 4

=item o doc_root => $dir_name

Use this to specify the doc root of your web server. This option is mandatory.

Default: ''.

=item o maxlevel => $logOption1

This option affects L<Log::Handler>.

See the L<Log::Handler::Levels> docs.

Default: 'notice'.

For more details in the printed report, try:

	my($validator) = HMTL::ValidateHeadLinks -> new(doc_root => $d, maxlevel => 'debug', url => $u);

=item o minlevel => $logOption2

This option affects L<Log::Handler>.

See the L<Log::Handler::Levels> docs.

Default: 'error'.

No lower levels are used.

=item o url => $url

Use this to specify the URL of the web page to be checked.

Default: ''.

If the string supplied does not start with 'http', then 'http://' is prefixed to $url automatically.

=back

=head1 Methods

=head2 doc_root([$dir_name])

Here, the [] indicate an optional parameter.

Get or set the name of your web server's doc root directory.

=head2 log($level => $message)

Log the string $message at log level $level.

The logger class is L<Log::Handler>.

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

For more details in the printed report, try:

	my($validator) = HMTL::ValidateHeadLinks -> new(doc_root => $d, maxlevel => 'debug', url => $u);

'maxlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

'minlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 quit($message)

Logs $message at log level I<error>, and then dies.

Errors can arise in these situations:

=over 4

=item o doc_root has no value during the call to L</run()>

=item o url has no value during the call to L</run()>

=item o L<HTML::Tiny> could not access the url

=item o The web page has no content

=back

=head2 run()

Does all the work.

Returns the number of errors detected, so 0 is good and N > 1 is bad.

=head2 url([$url])

Here, the [] indicate an optional parameter.

Get or set the URL of the web page your wish to check.

=head1 FAQ

=head2 How does bin/validate.head.links.pl differ from L<linkcheck.pl|http://world.std.com/~swmcd/steven/perl/pm/lc/linkcheck.html>?

linkcheck.pl does not check that links to non-HTML resources point to read file.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MojoX::ValidateHeadLinks>.

=head1 Author

C<MojoX-ValidateHeadLinks> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
