

library(tidyverse)
library(spaMM)
library(sf)
library(dagirlite)

data("geo_sogne")

geo_sogne$expected_women <- geo_sogne$population * (sum(geo_sogne$women) / sum(geo_sogne$men) / 2)

nbs <- st_intersects(geo_sogne, geo_sogne, sparse = FALSE)
nbs[] <- +nbs
geo_sogne$id <- 1:nrow(geo_sogne)

fit <- fitme(women ~ 0 + offset(log(expected_women)) + adjacency(1|id), adjMatrix = nbs, 
             data = geo_sogne, family = "poisson", method = "REML")

pred <- predict(fit, variances = list(linpred = TRUE, disp = TRUE, respVar = TRUE))

geo_sogne$pred <- pred[]
geo_sogne$fitted <- fitted(fit)
geo_sogne$pv <- attr(pred, which = "predVar")
geo_sogne$prob_02 <- pnorm(log(1.02), mean = log(geo_sogne$pred) - log(geo_sogne$expected_women), sd = sqrt(geo_sogne$pv), lower.tail = FALSE)

geo_sogne |> ggplot() + 
  geom_sf(aes(fill = women / expected_women), color = NA) +
  labs(title="Rate of women")

geo_sogne |> ggplot() + 
  geom_sf(aes(fill = fitted / expected_women), color = NA)+
  labs(title="Smoothed rate of women")

geo_sogne |> ggplot() + 
  geom_sf(aes(fill = prob_02 > 0.95), color = NA) + 
  geom_point(data = geo_sogne %>% filter(prob_02 > 0.95), aes(x = visueltcenter_x, y = visueltcenter_y), size = 7, shape = 21) +
  labs(title="Significant clusters of women (2% increase)")

