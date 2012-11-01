kick <- read.table("infos.txt", header=T, sep="\t")
print(summary(kick))

# superimpose a loess fit in red on a plot, with approx 95% CI interval
drawloess <- function(lo, ymustbepositive=T)
{
	x <- seq(min(lo$x), max(lo$x), 0.005 * diff(range(lo$x)))
	y <- predict(lo, x, TRUE) # predict with standard errors
	yhigh <- y$fit + 2 * y$se
	ylow <- y$fit - 2 * y$se
	if (ymustbepositive) { # don't fuck up graphs with log y scales
		ylow[ylow <= 1e-9] <- 1e-9
	}
	polygon(c(x, rev(x)), c(ylow, rev(yhigh)), col="#00006016")
	lines(x, y$fit, col="red")
}

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

kick$lf <- log(kick$f + 0.01) # 0.01 is arbitrary, could be anything positive
plot(kick$t, kick$lf, cex=0.5)
fitlf <- loess(lf ~ t, kick)
drawloess(fit2, F)
