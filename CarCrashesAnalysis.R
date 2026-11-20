> # ---------------- SETUP ----------------
> df <- read.csv("/Users/hershoza/Downloads/CarCrashesAnalysis.csv", check.names = FALSE)
> df$fatal <- as.integer(df$`Number of persons killed` > 0)

> # ---------------- Q1: WHEN ----------------
> # Test 1: Chi-square goodness-of-fit - are crashes spread evenly across the 24 hours?
  > hour_counts <- table(df$Hour)
  > chisq.test(hour_counts)
  
  Chi-squared test for given probabilities
  
  data:  hour_counts
  X-squared = 6205.8, df = 23, p-value < 2.2e-16
  
  > # Test 2: Logistic regression - do the odds of an injury crash depend on time period and weekday?
    > df$`Time period` <- relevel(factor(df$`Time period`), ref = "Midday (10-15)")
  > df$Weekday <- relevel(factor(df$Weekday), ref = "Monday")
  > q1_model <- glm(Injured ~ `Time period` + Weekday, data = df, family = binomial)
  > summary(q1_model)
  
  Call:
    glm(formula = Injured ~ `Time period` + Weekday, family = binomial, 
        data = df)
  
  Coefficients:
    Estimate Std. Error z value Pr(>|z|)    
  (Intercept)                       -0.62956    0.02650 -23.757  < 2e-16 ***
    `Time period`Evening (20-23)       0.24903    0.02643   9.423  < 2e-16 ***
    `Time period`Evening rush (16-19)  0.15647    0.02363   6.621 3.58e-11 ***
    `Time period`Late night (0-5)     -0.09430    0.02787  -3.383 0.000717 ***
    `Time period`Morning rush (6-9)   -0.13206    0.02742  -4.816 1.47e-06 ***
    WeekdayFriday                      0.04800    0.03159   1.520 0.128607    
  WeekdaySaturday                    0.04308    0.03265   1.320 0.186933    
  WeekdaySunday                      0.02677    0.03343   0.801 0.423213    
  WeekdayThursday                    0.06692    0.03216   2.081 0.037468 *  
    WeekdayTuesday                     0.05634    0.03272   1.722 0.085030 .  
  WeekdayWednesday                   0.04492    0.03261   1.378 0.168325    
  ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
  
  (Dispersion parameter for binomial family taken to be 1)
  
  Null deviance: 76177  on 57945  degrees of freedom
  Residual deviance: 75930  on 57935  degrees of freedom
  AIC: 75952
  
  Number of Fisher Scoring iterations: 4
  
  > round(exp(cbind(OR = coef(q1_model), confint.default(q1_model))), 3)   # odds ratios + 95% CI
  OR 2.5 % 97.5 %
    (Intercept)                       0.533 0.506  0.561
  `Time period`Evening (20-23)      1.283 1.218  1.351
  `Time period`Evening rush (16-19) 1.169 1.116  1.225
  `Time period`Late night (0-5)     0.910 0.862  0.961
  `Time period`Morning rush (6-9)   0.876 0.830  0.925
  WeekdayFriday                     1.049 0.986  1.116
  WeekdaySaturday                   1.044 0.979  1.113
  WeekdaySunday                     1.027 0.962  1.097
  WeekdayThursday                   1.069 1.004  1.139
  WeekdayTuesday                    1.058 0.992  1.128
  WeekdayWednesday                  1.046 0.981  1.115
  
  > # ---------------- Q2: WHERE ----------------
  > pop <- c(Bronx = 1472654, Brooklyn = 2736074, Manhattan = 1694251,
             +          Queens = 2405464, `Staten Island` = 495747)
  > b <- df[!is.na(df$Borough) & df$Borough != "", ]
  > # Daily crashes per 100,000 residents (days with no crashes count as 0)
    > daily <- as.data.frame(table(date = b$`Crash date`, borough = b$Borough))
  > daily$rate <- daily$Freq / pop[as.character(daily$borough)] * 100000
  
  > # Test 1: Kruskal-Wallis - do daily crash rates differ across boroughs?
    > kruskal.test(rate ~ borough, data = daily)
  
  Kruskal-Wallis rank sum test
  
  data:  rate by borough
  Kruskal-Wallis chi-squared = 196.62, df = 4, p-value < 2.2e-16
  
  > tapply(daily$rate, daily$borough, median)   # median daily rate per borough
  Bronx      Brooklyn     Manhattan        Queens Staten Island 
  3.734754      3.709695      3.069203      3.575194      2.824021 
  
  > # Test 2: Test of equal proportions - is the share of injury crashes the same in every borough?
    > injury_crashes <- tapply(b$Injured, b$Borough, sum)
  > total_crashes  <- tapply(b$Injured, b$Borough, length)
  > prop.test(injury_crashes, total_crashes)
  
  5-sample test for equality of proportions without continuity
  correction
  
  data:  injury_crashes out of total_crashes
  X-squared = 27.127, df = 4, p-value = 1.873e-05
  alternative hypothesis: two.sided
  sample estimates:
    prop 1    prop 2    prop 3    prop 4    prop 5 
  0.3616368 0.3757225 0.3699840 0.3660998 0.3260060 
  
  > round(injury_crashes / total_crashes, 3)   # injury rate per borough
  Bronx      Brooklyn     Manhattan        Queens Staten Island 
  0.362         0.376         0.370         0.366         0.326 
  
  > # ---------------- Q3: WHY ----------------
  > f <- df[!is.na(df$`Contributing factor vehicle 1`) &
              +         df$`Contributing factor vehicle 1` != "" &
              +         df$`Contributing factor vehicle 1` != "Unspecified", ]
  > top10 <- names(sort(table(f$`Contributing factor vehicle 1`), decreasing = TRUE))[1:10]
  > f$factor <- ifelse(f$`Contributing factor vehicle 1` %in% top10,
                       +                    f$`Contributing factor vehicle 1`, "Other")
  
  > # Test 1: Chi-square test of independence - do injury rates differ by primary factor?
    > tab <- table(f$factor, f$Injured)
  > q3_chi <- chisq.test(tab)
  > q3_chi
  
  Pearson's Chi-squared test

data:  tab
X-squared = 2507.1, df = 10, p-value < 2.2e-16

> round(q3_chi$stdres, 2)   # > +2 = more injuries than expected
                                
                                      0      1
  Backing Unsafely                18.67 -18.67
  Driver Inattention/Distraction  -1.25   1.25
  Failure to Yield Right-of-Way  -30.05  30.05
  Following Too Closely           -1.37   1.37
  Other                           -3.15   3.15
  Other Vehicular                  5.70  -5.70
  Passing or Lane Usage Improper  14.55 -14.55
  Passing Too Closely             28.94 -28.94
  Traffic Control Disregarded    -16.65  16.65
  Turning Improperly               4.27  -4.27
  Unsafe Speed                    -6.12   6.12

> # Test 2: Fisher's exact test - is each top factor linked to fatal crashes?
    > fisher_res <- lapply(top10, function(x) fisher.test(table(f$factor == x, f$fatal)))
  > fisher_p <- sapply(fisher_res, function(r) r$p.value)
  > data.frame(factor = top10,
               +            fatal_crashes = sapply(top10, function(x) sum(f$fatal[f$factor == x])),
               +            odds_ratio = round(sapply(fisher_res, function(r) r$estimate), 2), # > 1 = more deaths
               +            p_value = round(fisher_p, 4),
               +            p_holm = round(p.adjust(fisher_p, method = "holm"), 4),
               +            row.names = NULL)
  factor fatal_crashes odds_ratio p_value p_holm
  1  Driver Inattention/Distraction            19       0.44  0.0005 0.0045
  2   Failure to Yield Right-of-Way             8       0.75  0.5165 1.0000
  3           Following Too Closely             1       0.09  0.0007 0.0054
  4  Passing or Lane Usage Improper             1       0.13  0.0103 0.0618
  5             Passing Too Closely             0       0.00  0.0046 0.0319
  6                    Unsafe Speed            43      12.57  0.0000 0.0000
  7                Backing Unsafely             1       0.21  0.0944 0.3776
  8     Traffic Control Disregarded             4       0.91  1.0000 1.0000
  9                 Other Vehicular             0       0.00  0.0368 0.1841
  10             Turning Improperly             4       1.17  0.7797 1.0000