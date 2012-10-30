#!/usr/bin/perl

use Modern::Perl    '2012';
use Data::Dump      'ddx';
use HTML::TreeBuilder;

use constant    PROJECT_DIR => 'projects/';

sub scrape_created {
	my $page    = shift || 1;
	my $url     = "http://www.kickstarter.com/discover/recently-launched?page=$page";

	my $tree    = HTML::TreeBuilder->new_from_url($url);
	my @pcards  = $tree->look_down(
		_tag    => 'div',
		class   => 'project-card',
	);

	# If no project cards are returned, then we are done
	return undef unless (@pcards);

	# Reverse order so oldest first
	my @projects;
	for my $project (reverse(@pcards)) {
		my $name    = $project->look_down(_tag => "h2")
						->look_down(_tag => "a")->attr('href');

		$name   =~ s#^/projects/##;
		$name   =~ s#\?.*$##;

		push (@projects, $name);
	}

	for my $project (@projects) {
		my $leader  = substr($project,0,1);
		my $dir     = PROJECT_DIR . "$leader/" . ($project =~ m#^(.*)/#)[0];
		my $name    = ($project =~ m#/(.*)$#)[0];

		mkdir (PROJECT_DIR . $leader) unless (-d PROJECT_DIR . $leader);
		mkdir ($dir) unless (-d $dir);

		if (-f "$dir/$name") {
			say "What the heck, the project existed? $project";
		} else {
			open (my $fh, '>', "$dir/$name");
			close ($fh);
		}
		say "Created project with location $dir/$name";
	}

	return scalar @projects;
}

my $page   = 1;
while (my $projects = scrape_created($page)) {
	say "Scraped page $page";
	say "Sleeping 10 seconds before scraping page " . ($page + 1);
	sleep 10;
	$page++;
}
