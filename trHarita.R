library(maps)
library(tidyverse)
library(RColorBrewer)
library(ggmap)
library(mapdata)

tr <- map_data(map = "world", region = "Turkey")
sehir <- read.csv("trSehirHaritasi.csv", stringsAsFactors = F)
names(sehir)[1] <- "iller"
gdp <- read.csv("ilBazindaGSYH.csv", header = T, stringsAsFactors = F)
gdp <- gdp[!is.na(gdp$yil), ]
gdp[, 3:8] <- as.data.frame(sapply(gdp[, 3:8], gsub, pattern = " ", replacement = ""), stringsAsFactors = F)
gdp[, 3:8] <- sapply(gdp[, 3:8], as.numeric)
any(is.na(gdp[, 2:8]))
x <- cut(1:1148, breaks = 14*(0:82), labels = unique(gdp$il)[-2], include.lowest = F, right = T)
gdp$iller <- rep(levels(x), each = 14)
glimpse(gdp)

glimpse(sehir)
setequal(unique(gdp$iller)[-1], unique(sehir$city))
head(sehir)
head(tr)

year <- 2016

gdp$percGdp <- round(gdp$gdp / gdp$gdp[1:14] * 100, 2)

percGdp <- gdp %>% filter(yil == year) %>%
  mutate(Perc_Gdp = round(gdp / gdp[1] * 100, 2)) %>%
  mutate(ctg = cut(Perc_Gdp, breaks = c(0, 0.5, 1, 5, 10, 30, 100),
                   labels = c("< 0.5", "< 1", "< 5", "< 10", "< 30", "> 30"),
                   include.lowest = T, right = F)) %>%
  select(c('iller', 'Perc_Gdp', "ctg")) %>%
  filter(iller != "Turkiye")
  
sapply(tr[c(3,5,6)], unique)
sapply(tr[1:2], min)
sapply(tr[1:2], max)

sehir <- left_join(sehir, percGdp, "iller")


p <- ggplot(data = tr) + 
  geom_polygon(aes(x = long, y = lat, fill = region, group = group), col = "blue", fill = "salmon") + 
  coord_fixed(1.3) + geom_point(data = sehir, aes(x=long, y = lat)) +
  guides(fill=FALSE) +  # do this to leave off the color legend
  theme(rect = element_blank(), axis.ticks = element_blank(), legend.position = "bottom",
        axis.text = element_blank()) + ylab("") + xlab("") +
  geom_label(data = sehir,
             aes(long, lat, fill = ctg, label = toupper(iller)),
             size = 3, label.r = unit(0.01, "lines"), label.padding = unit(0.15, "lines")) +
  geom_label(data = sehir,
             aes(long, lat, fill = ctg, label = Perc_Gdp),
             nudge_x = 0.1, nudge_y = -0.2, size = 3,
             label.r = unit(0.01, "lines"), label.padding = unit(0.15, "lines")) +
  ggtitle(paste0("Turkish GDP, Percentage Distribution By Province (",
                 year, ") / Illere Gore Yuzdelik GSYH Dagilimi (", year,")"),
          subtitle = "Data Source: TurkStat / Veri Kaynagi: TUIK")
p
ggsave(paste0("trgdp", year,".png"), p, units = "cm", width = 30, height = 15)
