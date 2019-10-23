#For R-3.5 and newer only.
#Green text are comments, please read all comments.
#To run, highlight all code (or ctrl+a (PC) or command+A (mac)) and click run in the menu directly above (or ctrl+enter).
#If prompted to update packages, type 'a' or 'yes' in the 
#console, which is the bottom left quadrant of R studio. 

install.packages("devtools")
install.packages("vegan")
install.packages("ggplot2")
install.packages("spaa")
install.packages("stringr")
install.packages("plyr")

library(devtools)
devtools::install_github("GuillemSalazar/EcolUtils")

if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install("biomformat")
BiocManager::install("phyloseq")

#If you are unsure if the installation was successful,  |
#re-run by highlighting the code below beginning here.  V

#Lastly, check to see that the packages can be loaded without errors:

library(EcolUtils)
library(vegan)
library(ggplot2)
library(stringr)
library(plyr)

test1 <- as.data.frame(matrix(data = c(44,51,58,42), ncol =10, nrow =10))
test2 <- as.data.frame(rrarefy.perm(test1, sample = 200, n = 10, round.out = T))
test3 <- as.data.frame(as.matrix(avgdist(test2, sample = 10)))
test_nmds <- metaMDS(test3)
test_coordinates <- data.frame(test_nmds$points[,1:2])
ggplot(data = test_coordinates) +
  aes(x = test_coordinates$MDS1, y = test_coordinates$MDS2) +
  geom_point() +
  ylab(label = "Congratulations") +
  xlab(label = "Installation Complete")

library(phyloseq)
data(GlobalPatterns)

#If all went well, you should get a plot in the bottom right quadrant. 
#Otherwise, an error has occurred. Re-run lines 23 - 36 if you are unsure
#if everything installed properly. If you are still having trouble, further
#assistance will be provided the day of the workshop.

#Congratulations, you have installed everything successfully.

#Last revised: 10/14/2019 by Alexander B Chase