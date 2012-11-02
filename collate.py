#!/usr/bin/python

import os

# we're gonna make a list of paths to project data files made by the scrapers
projects = [ ]
for directory, subdirs, filenames in os.walk("projects/"):
	if subdirs != []:
		# there are subdirectories, this isn't a project directory
		continue
	for filename in filenames:
		projects += [os.path.join(directory, filename)]

# now open each individual file and add it to a master data file R can read

output = open("infos.txt", "wb")
output.write("id\tstart\tnow\tt\tchumps\tgoal\tfunds\tf\n") # set better column names than R's default "V2" shit

empties = 0
for i in xrange(len(projects)):
	project = projects[i]
	everything = open(project).readlines()
	if everything == []:
		# project data file is empty, no biggie, just count it then skip it
		empties += 1
		continue
	summary = everything[0].split("\t")
	data = everything[1:]
	start = summary[3][:-6] # cut off useless timezone that's always +0000
	goal = float(summary[5])
	#print i, project, summary, goal
	for point in data:
		timestamp, normedtime, chumps, funds = point.strip().split("\t")
		timestamp = timestamp[:-6] # cut off that useless timezone again
		funds = float(funds)
		output.write("%i\t%s\t%s\t%.6f\t%s\t%i\t%i\t%.6f\n" % (i+1, start, timestamp, float(normedtime), chumps, goal, funds, funds / goal))

output.close()

print empties, "projects have no individual data file yet btw"
