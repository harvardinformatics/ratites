#!/Users/mclamp/poginstall/bin/perl

use Perlwikipedia;
use WikiUtils;
use File::Basename;
use strict;

use Getopt::Long;


my $protocol = "https";
my $httpuser = "epawiki";
my $httppass = "wikilims2536";
my $wikiuser = "Admin";
my $wikipass = "123456";
my $host     = "localhost:8080";
my $dir      = "wiki";
my $overwrite= "false";
my $infile;

&GetOptions(
	"protocol:s" => \$protocol,
 	"httpuser:s" => \$httpuser,
	"httppass:s" => \$httppass,
 	"wikiuser:s" => \$wikiuser,
	"wikipass:s" => \$wikipass,
	"host:s"     => \$host,
	"dir:s"      => \$dir,
        "overwrite:s" => \$overwrite,
        "infile:s"    =>\$infile);
	
my $wikibot = Perlwikipedia->new(
		protocol      => $protocol,
		http_username => $httpuser,
		http_password => $httppass,
		debug         => 1,
		);
		
$wikibot->set_wiki($host,$dir);
$wikibot->login($wikiuser,$wikipass);

my $pagefile = $infile or die "No page file given";

if ($overwrite eq "false") {
    my $page = $wikibot->get_text($pagefile);

    print "Page is $page : $pagefile\n";

    if ($page != 2) {
	print "Page exists : not overwriting. Exit\n";
	exit(0);
    }

}
my $pagename = basename($pagefile);
my $text     = get_text($pagefile);

$wikibot->edit($pagename,$text);

print "Done\n";

sub get_text {
	my $file = shift;
	local $/ = undef;
	open MYIN,$file;
	my $text = <MYIN>;
	$text;
}

