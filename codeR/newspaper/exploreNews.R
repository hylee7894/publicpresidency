###################################
# Media Coverage of Trump: NYT, WSJ
# Initial Exploration 
# Michele Claibourn
# February 21, 2017
# Updated March 20, 2018
##################################

#####################
# Loading libraries
# Setting directories
#####################
# install.packages("scales")
# install.packages("wordcloud")
# install.packages("RColorBrewer")

rm(list=ls())
library(tidyverse)
library(quanteda)
library(scales)
library(wordcloud)
library(RColorBrewer)

# Load the data and environment from readNews.R
setwd("~/Box Sync/mpc/dataForDemocracy/presidency_project/newspaper/")
load("workspaceR/newspaper.Rdata")


##################################
# Exploring the text, pre-analysis
##################################
# Some descriptives
summary(qmeta$length)
qmeta %>% group_by(pub) %>% summarize(mean(length, na.rm=TRUE), sd(length, na.rm=TRUE))
qcorpus2 <- corpus_subset(qcorpus, as.integer(length)>99)

table(qmeta$pub)
qmeta$pub <- as.factor(qmeta$pub)
qmeta2 <- subset(qmeta, as.integer(length)>99)
table(qmeta2$pub)

# Number of stories by day
# Create date breaks to get chosen tick marks on graph
date.vec <- seq(from=as.Date("2017-01-20"), to=as.Date("2018-03-02"), by="2 weeks") # update to Friday after last story
ggplot(qmeta2, aes(x=date)) + geom_point(stat="count") + 
  facet_wrap(~pub) +
  scale_x_date(labels = date_format("%m/%d"), breaks=date.vec) + 
  labs(title = "Volume of Trump Coverage", 
       subtitle = "New York Times, Washington Post, Wall Street Journal", 
       x="Date", y="Number of Stories") +
  theme(axis.text.x=element_text(angle=90, size=8), 
        plot.title = element_text(face="bold", size=18, hjust=0), 
        axis.title = element_text(face="bold", size=16),
        panel.grid.minor = element_blank(),
        legend.position="none")
ggsave("figuresR/newspapervolume.png")


## Clean up terms
# common bigrams
# qcorpus_tokens  <- tokens(qcorpus2) # textstat_collocations wants tokenized text
# qcorpus_tokens <- tokens_remove(qcorpus_tokens, stopwords("english"), padding = TRUE)
# bigrams <- textstat_collocations(qcorpus_tokens, min_count = 100, size = 2) # took about 45 minutes
# bigrams[bigrams$count>1000,]
## replace some key phrases with single-token versions
# save_bigrams <- bigrams[c(1:2,4:6,12:13,24,52,57,64),] # save key bigrams
## united states, white house, national security, health care, north korea,
## executive order, justice department, attorney general, united nations,  
## prime minister, supreme court
# qcorpus3 <- tokens_compound(qcorpus_tokens, save_bigrams) 
## hmmm, qcorpus3 is now a tokens object; 
## also, this didn't do what I'd expected (i.e., replace selected phrases with concatenated phrase)
## https://stackoverflow.com/questions/38931507/create-dfm-step-by-step-with-quanteda


## Key words in context (from quanteda)
# liecount <- kwic(qcorpus2, c("lie", "lies", "lied"), 3)
# liecount
# fakecount <- kwic(qcorpus2, c("fake"), 3)
# fakecount


## Frequent words/Wordclouds
qcorpus_tokens  <- tokens(qcorpus2) 
qcorpus_tokens <- tokens_remove(qcorpus_tokens, stopwords("english"), padding = TRUE)

npdfm <- dfm(qcorpus_tokens, remove_punct = TRUE, 
             ngrams = 1:2, verbose = TRUE) # turn it into a document-feature matrix
topfeatures(npdfm, 100) 
palD <- brewer.pal(8, "Paired")
textplot_wordcloud(npdfm, max.words = 200, colors = palD, scale = c(3, .5))

# Wordcloud by source
bynpdfm <- dfm(qcorpus_tokens, groups = "pub",
                  remove_punct = TRUE, ngrams = 1:2, verbose = TRUE)

palO <- colorRampPalette(brewer.pal(9,"Oranges"))(32)[13:32]
palB <- colorRampPalette(brewer.pal(9,"Blues"))(32)[13:32]

textplot_wordcloud(bynpdfm[1], max.words = 200, colors = palB, scale = c(3, .5)) # nyt
textplot_wordcloud(bynpdfm[2], max.words = 200, colors = palO, scale = c(3, .5)) # wsj
textplot_wordcloud(bynpdfm[3], max.words = 200, colors = palB, scale = c(3, .5)) # wp 

# Wordcloud of opinion-editorial pieces
qcorpus_oped <- corpus_subset(qcorpus2, oped==1)
qcorpus_oped_tokens  <- tokens(qcorpus_oped) 
qcorpus_oped_tokens <- tokens_remove(qcorpus_oped_tokens, stopwords("english"))
bynpdfmoped <- dfm(qcorpus_oped_tokens, groups = "pub", remove_punct = TRUE)

textplot_wordcloud(bynpdfmoped[1], max.words = 150, colors = palB, scale = c(3, .5)) # nyt
textplot_wordcloud(bynpdfmoped[2], max.words = 150, colors = palO, scale = c(3, .5)) # wsj
textplot_wordcloud(bynpdfmoped[3], max.words = 150, colors = palB, scale = c(3, .5)) # wp

# Plot keyness
qcorpus_tokens %>% dfm(groups = "pub", remove = c(stopwords("english")),
                       remove_punct = TRUE, ngrams = 1:2) %>% 
  textstat_keyness(target = "WSJ") %>% textplot_keyness()


## Readability/Complexity Analysis (from quanteda)
fk <- textstat_readability(qcorpus2, measure = "Flesch.Kincaid") # back to qcorpus2 (with stopwords)
qmeta2$readability <- fk$Flesch.Kincaid 

# Plot
qmeta2 %>% filter(readability<100) %>% 
  ggplot(aes(x = date, y = readability)) + 
  geom_jitter(aes(color=pub), alpha=0.05, width=0.25, height=0.0, size=2) +
  geom_smooth(aes(color=pub)) +
  scale_x_date(labels = date_format("%m/%d"), breaks=date.vec) + 
  ggtitle("'Readability' of Newspaper Coverage of Trump") +
  labs(y = "Readability (grade level)", x = "Date of Article") +
  scale_color_manual(values=c("blue3","turquoise","orange3"), name="Source") +
  theme(plot.title = element_text(face="bold", size=18, hjust=0),
        axis.title = element_text(face="bold", size=16),
        panel.grid.minor = element_blank(), legend.position = c(0.95,0.9),
        axis.text.x = element_text(angle=90),
        legend.text=element_text(size=10))
ggsave("figuresR/newspaperreadability.png")

qmeta2 %>% filter(readability<100) %>% 
  group_by(pub) %>% summarize(mean(readability)) 

# What are the "complex" and "simple" articles?
mincomplex <- qmeta2 %>% filter(readability <= 6)
mincomplex[,c("heading", "pub", "date", "readability")] 
# Many quizzes and transcripts of speeches/interviews

maxcomplex <- qmeta2 %>% filter(readability >= 20)
maxcomplex[,c("heading", "pub", "date", "readability")] # Identify article
# Many "at a glance" collections, aggregated news summaries

# Save
rm("fk", "palD", "palO", "palB")
save.image("workspaceR/newspaperExplore.RData")
# load("workspaceR/newspaperExplore.RData")