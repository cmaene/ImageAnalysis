#!/usr/bin/Rscript
# This is an Rscript to plot spectral profiles, also save as png
# usage e.g. ./plotSpectral.R "spring summer fall winter"
# (or loudly..) Rscript plotSpectral.R "spring summer fall winter"

seasons <- strsplit(commandArgs(TRUE), " ")[[1]]
# pop graphic window
#X11()

for (i in 1:length(seasons)) {
  input <-paste0("wksp/",seasons[i],"_mean.csv")
  # read data
  sdata <- read.csv(input)
  # header: id,Landcover,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10
  xlabel <- c(1,2,3,4,5,6,7)
  ylabel <- vector()
  xrange <- c(1,length(xlabel))
  yrange <- range(sdata[c(1:4),c(3:9)])
  linetype <- c(1:nrow(sdata))
  plotchar <- seq(18,18+nrow(sdata),1)

  png(paste0('wksp/spectral_',seasons[i],'.png'))  
  plot(xrange, yrange, type="n", xlab="Bands", ylab="TOA" )
  colors <- rainbow(4)
  # add lines
  for (i2 in 1:nrow(sdata)) {
    ylabel[i2] <- as.character(sdata[i2,c("Landcover")])
    lines(xlabel, sdata[i2,3:9], type="b", lwd=1.5,
          lty=linetype[i2], col=colors[i2], pch=plotchar[i2])
  }
  # add a title and subtitle
  title(paste("Spectral Profile:", seasons[i]))
  # add a legend
  legend(xrange[1], yrange[2], ylabel, cex=0.8, col=colors,
         pch=plotchar, lty=linetype, title="Features")

  # if poping graphic window, pause to give time to examine the plot
  #message("Press return to close the plot window..")
  #invisible(readLines("stdin", n=1))
  dev.off()
}
