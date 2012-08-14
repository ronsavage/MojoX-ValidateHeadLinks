use Module::Build;

Module::Build -> new
(
	module_name    => 'MojoX::ValidateHeadLinks',
	license        => 'artistic',
	dist_abstract  => 'Ensure CSS and JS links in web pages point to real files',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::More => 0.94,
		Test::Pod  => 1.44,
	},
	configure_requires =>
	{
		Module::Build => 0.3800,
	},
	requires =>
	{
		feature           => 1.20,
		Getopt::Long      => 2.38,
		Hash::FieldHash   => 0.12,
		HTML::TreeBuilder => 4.2,
		HTTP::Tiny        => 0.022,
		Log::Handler      => 0.75,
		Mojolicious       => 3.30,
		Pod::Usage        => 1.51,
		strict            => 1.03,
		warnings          => 1.03,
	},
) -> create_build_script();
