use Test::More tests => 1;

# ------------------------

my($url)      = 'http://savage.net.au/Novels-etc.html';
my(@result)   = `$^X bin/validate.head.links.pl -d t -max debug -u $url`;
my($result)   = join('', @result);
my($expected) = <<EOS;
URL: $url
 Import: t/assets/js/DataTables-1.9.4/media/css/demo_page.css
 Import: t/assets/js/DataTables-1.9.4/media/css/demo_table.css
 Script: t/assets/js/DataTables-1.9.4/media/js/jquery.js
 Script: t/assets/js/DataTables-1.9.4/media/js/jquery.dataTables.min.js
Imports: 2. Errors: 0
  Links: 0. Errors: 0
Scripts: 2. Errors: 0
EOS

is_deeply($result, $expected, "Checked $url has no errors");
