#!/usr/bin/perl -w
# Script to generate a valid .tex file from a Blogspot XML backup
use strict;
use POSIX ();

my $arguments = $#ARGV + 1;
if ($arguments != 1){
	print "Usage: blogger_to_latex.pl blog.xml\n";
	exit;
}

my $filename=$ARGV[0];

unless (-e $filename){
	print "No such file could be found, sorry.\n";
	exit;
}

my $document = do {
	local $/ = undef;
	open my $fh, "<", $filename
	or die "Could not open $filename: $!";
	<$fh>;
};

my $blog_author = "Unknown";
if ($document =~ m|<author><name>(.*?)</name>|){
	$blog_author = $1;
}

my $blog_name = "Unknown";
if ($document =~ m|</updated><title type='text'>(.*?)</title>|){
	$blog_name = $1;
}

my $blog_url = "Unknown";
if ($document =~ m|<link rel='alternate' type='text/html' href='(.*?)'/><author>|){
	$blog_url = $1;
}

# Document preamble
print "\\documentclass{article}\n";
print "\\usepackage{lmodern}\n";
print "\\usepackage[utf8]{inputenc}\n";
print "\\usepackage[T2A]{fontenc}\n";
print "\\usepackage{CJKutf8}\n";
print "\\usepackage[english,russian,french]{babel}\n";
print "\\title{$blog_name}\n";
print "\\begin{document}\n";

# Important!
my @all_posts;

my $blog_posts_count = 0;
while ($document =~ m|<entry><id>tag:blogger.com,1999:blog-\d*.post-\d*</id>(.*?)</entry>|gs){
	my $post_content_all = $1;

	if ($post_content_all =~ m|term='http://schemas.google.com/blogger/2008/kind#comment'|gs){
		last;
	}

	
	my $post_title = "Unknown";
	if ($post_content_all =~ m|<title type='text'>(.*?)</title>|){
		$post_title = $1;
	}

	my $post_date = "Unknown";
	if ($post_content_all =~ m|</published><updated>(.*?)</updated>|){
		$post_date = $1;
	}

	my $post_content = "Unknown";
	if ($post_content_all =~ m|<content type='html'>(.*?)</content>|){
		$post_content = $1;

		$post_content =~ s|{|\\{|gs;
		$post_content =~ s|}|\\}|gs;

		$post_content =~ s|&amp;nbsp;| |gs; # non-breaking spaces
		$post_content =~ s|&lt;br /&gt;|\\newline |gs; # new-lines
		$post_content =~ s|&lt;/p&gt;|\\newline |gs; # new-lines
		
		$post_content =~ s|&lt;i&gt;(.*?)&lt;/i&gt;|\\textit{$1}|gs; # Italicized text
		$post_content =~ s|&lt;b&gt;(.*?)&lt;/b&gt;|\\textbf{$1}|gs; # Bold text
		$post_content =~ s|&lt;(.*?)&gt;||gs; # remove all opening tags
		$post_content =~ s|&lt;(.*?)/&gt;||gs; # remove all closing tags

		# Handle special characters like % and ^ and # and @ and { and }
		$post_content =~ s|&amp;#233;|é|gs;

		$post_content =~ s|#|\\#|gs;
		$post_content =~ s|\$|\\\$|gs;
		$post_content =~ s|%|\\%|gs;
		$post_content =~ s|&amp;amp;|\\&|gs;
		$post_content =~ s|\^|\\textasciicircum|gs;

		$post_content =~ s|_|\\_|gs;
		$post_content =~ s|’|\'|gs;
		$post_content =~ s|&amp;gt;|\\textgreater |gs;
		$post_content =~ s|&amp;lt;|\\textless |gs;

		$post_content =~ s|“|``|gs;
		$post_content =~ s|”|''|gs;
		$post_content =~ s|^\s*?\\newline||gs;
		$post_content =~ s|^\s*?\\newline||gs;
		$post_content =~ s|^\s*?\\newline||gs;
	}


	$all_posts[$blog_posts_count][0] = "\\section*{$post_title}\n";
	my ($time,$time2,$sec,$min,$hour,$mday,$mon,$year,$isdst);
	if ($post_date =~ m|(\d+?)-(\d+?)-(\d+?)T(\d+?):(\d+?):(\d+?)|gs){
		$sec = $6;
		$min = $5;
		$hour = $4;
		$mon = $2 - 1;
		$mday = $3;
		$year = $1 - 1900;
		} else {
			print "Could not extract data from the date...\n";
		}

	$post_date = POSIX::mktime($sec,$min,$hour,$mday,$mon,$year,0,0,1);
	$all_posts[$blog_posts_count][1] = $post_date;
	$all_posts[$blog_posts_count][2] = "$post_content\n\n";
	$blog_posts_count++;
}

$blog_posts_count = $blog_posts_count - 1;

# Going to do an in-place selection sort
for my $i (0 .. $blog_posts_count - 1) {
	my $min = $i;
	for my $j ($i .. $blog_posts_count) {
		if ($all_posts[$j][1] < $all_posts[$min][1]) {
			$min = $j;
		}
	}
	if ($i != $min) {
		my $temp = $all_posts[$i][1];
		$all_posts[$i][1] = $all_posts[$min][1];
		$all_posts[$min][1] = $temp;

		$temp = $all_posts[$i][0];
		$all_posts[$i][0] = $all_posts[$min][0];
		$all_posts[$min][0] = $temp;

		$temp = $all_posts[$i][2];
		$all_posts[$i][2] = $all_posts[$min][2];
		$all_posts[$min][2] = $temp;	
	}
}


my $count = 0;
while ($count < $blog_posts_count + 1){
	print "$all_posts[$count][0] \n";
  	print "$all_posts[$count][2] \n\n";
  	$count++;
}

print "\\end{document}\n";
