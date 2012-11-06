kick <- read.table("infos.txt", header=T, sep="\t")
print(table(table(kick$id)))  # count number of data points for each project
plot(table(table(kick$id)), xlab="number of data points", ylab="number of projects", main="How many data points do the projects have?")

ids <- unique(kick$id)

# superimpose a loess fit in red on a plot, with approx 95% CI interval
drawloess <- function(lo, ymustbepositive=T) {
	x <- seq(min(lo$x), max(lo$x), 0.005 * diff(range(lo$x)))
	y <- predict(lo, x, T) # predict with standard errors
	yhigh <- y$fit + 2 * y$se
	ylow <- y$fit - 2 * y$se
	if (ymustbepositive) { # don't fuck up graphs with log y scales
		ylow[ylow <= 1e-9] <- 1e-9
	}
	polygon(c(x, rev(x)), c(ylow, rev(yhigh)), col="#00006016")
	lines(x, y$fit, col="red")
}

# shove old plotting experiments into a side function
old1 <- function() {
	plot(kick$t, kick$funds, cex=0.5, log="y")
	fitfunds <- loess(funds ~ t, kick)
	drawloess(fitfunds)
	readline("hit enter to see next graph: plotting NORMED funds")

	plot(kick$t, kick$f, cex=0.5)
	fitf <- loess(f ~ t, kick)
	drawloess(fitf)

	readline("hit enter to see next graph: same but with log y scale")
	plot(kick$t, kick$f, cex=0.5, log="y")
	drawloess(fitf)

	readline("hit enter to see next graph: plotting LOG normed funds")

	kick$lf <- log(kick$f + 0.01) # 0.01 could be any positive number
	plot(kick$t, kick$lf, cex=0.5)
	fitlf <- loess(lf ~ t, kick)
	drawloess(fitlf, F)
}

# plot funding against normalised time, each project as its own line
old2 <- function() {
	plot(1, 1, type="n", xlim=0:1, ylim=c(1, max(kick$funds)), log="y", xlab="normalised time", ylab="project donations ($)")
	for (id in ids) {
		project <- kick[kick$id == id,]
		lines(project$t, project$funds, col="#00000044")
	}
}

old3 <- function() {
	rmslin <- c() # rms errors for each ordinary linear regression
	rmsnonlin <- c() # rms errors for the nonlinear regression
	N <- c() # number of data points for each project
	nls.control(maxiter=999)
	for (id in ids) {
		project <- kick[kick$id == id,]
		if (length(project[,1]) < 3) { # skip project if it has <3 data points
			next
		}
		N <- c(N, length(project[,1]))
		plot(project$t, project$funds, pch=16, main=paste("project", id), xlim=0:1)
		grid()
		linearreg <- lm(funds ~ t, project)
		rmslin <- c(rmslin, sqrt(sum((linearreg$residuals)^2)))
		abline(linearreg)
		if (sd(project$funds)) { # don't try the nonlinear fit if the funding curve is flat
			nonlinreg <- try(nls(funds ~ c1 * t^c2, project, start=list(c1=max(project$funds), c2=0.5)))
			if (typeof(nonlinreg) == "list") {
				# nonlinear regression fit didn't fail
				params <- nonlinreg$m$getPars()
				curve(params[1] * x^params[2], add=T, lty="dashed")
				rmsnonlin <- c(rmsnonlin, sqrt(sum(nonlinreg$m$resid()^2)))
			} else {
				# nonlinear regression fit failed on this data
				rmsnonlin <- c(rmsnonlin, NA)
			}
	#		Sys.sleep(2) # only bother pausing for graphs with nonlinear fits
		} else {
			rmsnonlin <- c(rmsnonlin, NA)
		}
	}

	par(mfrow=c(1, 2)) # 2 plots side by side
	plot(rmslin, rmsnonlin, xlab="rms error for linear regression", ylab="rms error for the nonlinear regression", log="xy", xlim=c(1, max(rmslin)))
	abline(0, 1, lty="dashed")
	plot(N, rmslin/rmsnonlin, log="y", xlab="number of data points for project", ylab="nonlinear fit rms error divided by linear fit rms error")
	abline(h=1, lty="dashed")
	par(mfrow=c(1, 1))
	print(summary(rmslin/rmsnonlin))
}

# ok let's write some actual comments for this
# iterate over projects, doing this:
# 1. try different fits, choose a preferred one
# 2. plot funding against normalised time
# 3. extrapolate prediction from fit
# 4. slap the fit on top of plot with error area
# 5. add final prediction to file
makeniceplots <- function(project, predfile="pred.txt", pngdir="pngs") {

	cat("making nice plots, gonna put them in the directory", pngdir, "\n")

	for (id in ids) {

		project <- kick[kick$id == id,] # make variable for this project's data
		if (length(project[,1]) < 3) { # skip project if it has <3 data points
			next
		}

		nonlinfailed <- T # nonlinear fitting not yet shown to work on this project

		# if the funding curve isn't flat,
		# try an unconstrained linear regression and a nonlinear fit
		if (sd(project$funds) > 1e-6) {
			linearreg <- lm(funds ~ t, project) # run straight line fit
			nonlinreg <- try(nls(funds ~ c1 * t^c2, project, start=list(c1=max(project$funds), c2=0.5)))
			if (typeof(nonlinreg) == "list") {
				nonlinfailed <- F # nonlinear fitting worked after all
				chosenfit <- "n" # record that we'll use nonlinear fit
			} else {
				chosenfit <- "ly" # gonna use normal linear regression
			}
		} else {
			# the funding curve is flat
			# so run straight line fit with line forced through origin,
			# to discourage pointless flat line fits
			# of course if funding is 0 for all time the line will be
			# flat anyway
			linearreg <- lm(funds ~ 0 + t, project)
			chosenfit <- "l0" # using special linear regression with y intercept fixed at 0
		}

		# open png file
		png(paste(pngdir, "/", id, ".png", sep=""), 800, 600)

		if (nonlinfailed) {
			# plot the linear fit
			y <- predict(linearreg, data.frame(t=0:1))
			sigma <- summary(linearreg)$sigma
			plot(project$t, project$funds, pch=16, main=paste("project", id), xlim=0:1, ylim=range(y), xlab="normalised time", ylab="$")
			polygon(c(0, 1, 1, 0), c(y - 2*sigma, rev(y + 2*sigma)), col="#00006016")
			abline(linearreg, col="red")
		} else {
			# plot the nonlinear fit
			x <- seq(0, 1, 0.002)
			y <- predict(nonlinreg, data.frame(t=x))
			sigma <- summary(nonlinreg)$sigma
			plot(project$t, project$funds, pch=16, main=paste("project", id), xlim=0:1, ylim=range(y), xlab="normalised time", ylab="$")
			polygon(c(x, rev(x)), c(y - 2*sigma, rev(y + 2*sigma)), col="#00006016")
			params <- nonlinreg$m$getPars()
			curve(params[1] * x^params[2], add=T, col="red", n=501)
		}

		# close png file now plotting's done
		dev.off()

		finalpred <- tail(y, 1) # predict final $
		write.table(data.frame(project=id, samplesize=length(project[,1]), final=finalpred, err=sigma, fittype=chosenfit), predfile, append=T, row.names=F, col.names=F)

		cat(id, "") # so we know something's happening
	}
}

makeniceplots() # assumes you made a pngs/ dir to put the png files in
cat("\n") # toss in a newline
