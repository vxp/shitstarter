#!/usr/bin/perl

use Modern::Perl    '2012';
use Data::Dump      'ddx';
use File::Find;
use Time::Seconds;
use Time::Piece;
use HTML::TreeBuilder;

use constant    PROJECT_DIR => 'projects/';
use constant    TIME_FORMAT => '%T %D %z';

sub scrape_project {
	my $path    = shift;
	my $project = ($path =~ m#projects/./(.*)$#)[0];
	return unless ($project);
	my $url     = "http://www.kickstarter.com/projects/$project";

	say "Url: $url";
	my $tree    = HTML::TreeBuilder->new_from_url($url);

	say "Opening $path";
	open (my $fh, '<', $path) or warn "Unable to open file! $!";
	my $firstline   = <$fh>;
	close ($fh);

	open ($fh, '>>', $path) or warn "Unable to write to file! $!";
	unless($firstline) {
		# Write the first line of information to the file
		my $whobox  = $tree->look_down(id => 'project-by');

		my $creator = $whobox->look_down(id => 'creator-name')
						->look_down(_tag => 'h3')->as_text;
		my $loc     = $whobox->look_down(class => 'location')->as_text;
		my $weblink = $whobox->look_down(_tag => 'li', class => 'links');
		my $website = $weblink ? $weblink->look_down(_tag => 'a')->attr('href') : "No website";

		my $stats   = $tree->look_down(id   => 'stats');
		my $pledged = $stats->look_down(id  => 'pledged');
		my $money   = $pledged->look_down(_tag => 'span')->attr('data-currency');
		my $goal    = $pledged->attr('data-goal');

		my $dur     = $stats->look_down(id  => 'project_duration_data');
		my $end     = Time::Piece->strptime($dur->attr('data-end_time'), '%a, %d %b %Y %T %z');
		my $start   = $end - ($dur->attr('data-duration') * ONE_DAY);

		$firstline = "$creator\t$loc\t$website\t" . $start->strftime(TIME_FORMAT) . "\t"
			. $end->strftime(TIME_FORMAT) . "\t$goal\t$money\n";

		print $fh $firstline;

		say "Creator is $creator";
		say "Location is $loc";
		say "Website is $website";
		say "Goal is $goal";
		say "Project began at $start and ends at $end";
	}

	# Write the current progress
	my @first   = split(/\t/, $firstline);
	say "First: $first[3]. Second: $first[4]";
	my $start   = Time::Piece->strptime($first[3], TIME_FORMAT);
	my $end     = Time::Piece->strptime($first[4], TIME_FORMAT);
	my $length  = $end - $start;
	my $now     = localtime();
	my $prog    = $now - $start;
	my $reltime = $prog->seconds/$length->seconds;
	
	my $stats   = $tree->look_down(id   => 'stats');
	my $backers = $stats->look_down(id  => 'backers_count')
					->attr('data-backers-count');
	my $amount  = $stats->look_down(id  => 'pledged')
					->look_down(_tag => 'span')->attr('data-value');

	say "There are $backers backers, who have given $amount of $first[5] $first[6]";
	say "Project began at $start and ends at $end, relative progression $reltime";

	print $fh $now->strftime(TIME_FORMAT) . "\t$reltime\t$backers\t$amount\n";
	close($fh);
}

if (@ARGV) {
	for my $project (@ARGV) {
		say "Scraping $project";
		scrape_project($project);
		sleep 2;
	};
} else {
	find({
		wanted  => sub {
			return unless (-f $_);
			say "Scraping $_";
			scrape_project($_);
			sleep 2;
		},
		no_chdir    => 1,
	}, PROJECT_DIR);
}
