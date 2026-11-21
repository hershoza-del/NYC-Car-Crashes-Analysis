# NYC Car Crashes Analysis

As NYC gradually reopened in the second half of 2021, following the COVID-19 pandemic, shifting traffic patterns led to a sharp rebound in severe roadway incidents. This project analyzes NYC motor vehicle collision data to uncover where, when, and why crashes occurred across the five boroughs.

## Disclaimers

- **With n = 57,946, almost every test is significant:** Effect sizes of V, w, η², or any other odds ratios can hoist a large difference.
- **Some rows have missing boroughs:** From the original dataset, there were more rows than I thought that didn't state the boroughs. However, I was able to figure it out as the original dataset listed street names, instead. While I was able to uncover most of the missing boroughs, I was not able to uncover all of them. Any row with a missing borough is left **blank**.
- **MOST IMPORTANTLY:** Based on my discretion, not all categorical/numerical values from the original dataset were taken into account. Also, the statistical results down below are solely based from my altered dataset. 

## Approach

- **Python (pandas/matplotlib):** cleaned and rearranged the data and a chart for each question (charts can be found on my LinkedIn page)
- **SQL:** exploring and summarizing the data for each question
- **R:** running statistical tests for each question

## Data

| | |
|---|---|
| Source | https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95/about_data, Police Department (NYPD) |
| Coverage | Car crashes from July 1, 2021 to December 31, 2021 |
| Rows | 57,946 car crashes |

## Findings

### Question 1: When do crashes happen?

| Time period | Crashes | Share of crashes | Injury rate | Fatal crashes per 1,000 |
|---|---:|---:|---:|---:|
| Late night (0–5) | 8,704 | 15.0% | 33.5% | **6.2** |
| Morning rush (6–9) | 8,968 | 15.5% | 32.7% | 2.5 |
| Midday (10–15) | 17,817 | **30.7%** | 35.7% | 1.9 |
| Evening rush (16–19) | 13,340 | 23.0% | 39.4% | 1.4 |
| Evening (20–23) | 9,117 | 15.7% | **41.6%** | 3.4 |

**Statistical Tests**

| Test | Result | What it means |
|---|---|---|
| Chi-square goodness-of-fit (are crashes spread evenly over 24 hours?) | χ²(23) = 6,205.8, p < 0.001, Cohen's w = 0.33 | Crashes are not spread evenly across the day (medium effect) |
| Logistic regression (injury ~ time period + weekday), reference = Midday, Monday | Evening OR = 1.28 (95% CI 1.22–1.35); Evening rush OR = 1.17 (1.12–1.23); Late night OR = 0.91 (0.86–0.96); Morning rush OR = 0.88 (0.83–0.93); all p < 0.001 | Compared with midday, the odds that a crash injures someone are 28% higher in the evening and 17% higher in the evening rush, and about 10% lower late at night and in the morning rush |
| Same model, weekday terms | Only Thursday reaches p < 0.05 (OR = 1.07, p = 0.037); all other days p > 0.08 | The day of the week barely affects whether a crash causes an injury. The Thursday result would not survive a correction for testing six days |

**Key Takeaways**

- **Crashes peak on weekday afternoons:** 5 PM is the peak of rush hour and 3 AM in the very early morning is the quietest. Rush hour on a Friday afternoon is the worst time of the week when it came to car crashes.
- **Evening crashes are more likely to injure someone:** Did you know that severe pedestrian crashes rise nearly 40% in fall and winter evenings, when darkness falls during rush hour? The data from the NYC Department of Transportation includes the end of daylight saving time ([NYC DOT, Dusk and Darkness](https://www.nyc.gov/html/dot/html/pr2025/vision-zero-dusk-and-darkness-campaign.shtml); [NYC Mayor's Office, 2017](https://www.nyc.gov/office-of-the-mayor/news/687-17/vision-zero-de-blasio-administration-return-dusk-darkness-safety-campaign)).

### Question 2: Where do crashes happen?

| Borough | Crashes | Population (2020) | Median daily crashes per 100,000 residents | Injury rate | Fatal crashes |
|---|---:|---:|---:|---:|---:|
| Bronx | 10,093 | 1,472,654 | **3.73** | 36.2% | 30 |
| Brooklyn | 18,511 | 2,736,074 | 3.71 | **37.6%** | **52** |
| Queens | 15,758 | 2,405,464 | 3.58 | 36.6% | 31 |
| Manhattan | 9,395 | 1,694,251 | 3.07 | 37.0% | 31 |
| Staten Island | 2,684 | 495,747 | 2.82 | 32.6% | 6 |

**Statistical Tests**

| Test | Result | What it means |
|---|---|---|
| Kruskal-Wallis (daily crash rate ~ borough) | χ²(4) = 196.6, p < 0.001, ε² = 0.21 | Daily crash rates per resident differ across boroughs (large effect) |
| Test of equal proportions (injury share by borough) | χ²(4) = 27.1, p < 0.001, Cramér's V = 0.02 | Injury shares differ, but the difference is very small (32.6% to 37.6%) |

**Key Takeaways**

- **The Bronx and Brooklyn have the highest crash rates per resident, but slightly:** Both boroughs had about 3.7 per 100,000 per day.
- **Manhattan's low rate can be misleading:** Manhattan is the busiest borough in New York City, as around 1.6 million commuters come in each day. This roughly doubles its daytime population, so dividing by residents understates how busy its streets are ([U.S. Census Bureau](https://census.gov/newsroom/archives/2013-pr/cb13-r17.html)).
- **Staten Island has the lowest crash rate and injury share, despite the highest car ownership:** Staten Island has around a 83% car ownership rate, but its relatively lower density, compared with the other four boroughs, means fewer pedestrians and cyclists get hit. From my altered dataset, for instance, 133 pedestrians and 44 cyclists were injured in Staten Island compared with 1,434 and 1,061 in Brooklyn. ([NY State Comptroller](https://www.osc.ny.gov/press/releases/2024/09/draft-dinapoli-nyc-metro-transportation-costs-grew-slower-other-major-cities-still-rose-29-percent)).

### Question 3: Why do crashes happen? What causes them?

| Primary contributing factor | Crashes | Injury rate | Fatal crashes | Fatal crashes per 1,000 |
|---|---:|---:|---:|---:|
| Driver Inattention/Distraction | 13,767 | 40% | 19 | 1.4 |
| Failure to Yield Right-of-Way | 4,040 | **61%** | 8 | 2.0 |
| Following Too Closely | 3,868 | 40% | 1 | 0.3 |
| Passing or Lane Usage Improper | 2,704 | 26% | 1 | 0.4 |
| Passing Too Closely | 2,254 | 10% | 0 | 0.0 |
| Unsafe Speed | 2,081 | 45% | **43** | **20.7** |
| Backing Unsafely | 1,807 | 18% | 1 | 0.6 |
| Traffic Control Disregarded | 1,701 | 58% | 4 | 2.4 |
| Other Vehicular | 1,572 | 32% | 0 | 0.0 |
| Turning Improperly | 1,333 | 33% | 4 | 3.0 |

**Statistical Tests**

| Test | Result | What it means |
|---|---|---|
| Chi-square test of independence (factor × injury) | χ²(10) = 2,507.1, p < 0.001, Cramér's V = 0.24 | The injury rate depends on the cause of the crash (small to moderate effect) |
| Standardized residuals | More injuries than expected: Failure to Yield (+30.1), Traffic Control Disregarded (+16.7), Unsafe Speed (+6.1). Fewer: Passing Too Closely (−28.9), Backing Unsafely (−18.7), Passing/Lane Usage (−14.6) | Shows which causes drive the overall result |
| Fisher's exact test, each factor vs. all others (fatal crash), Holm-adjusted | Unsafe Speed OR = 12.57, p < 0.001. Lower odds: Inattention (OR = 0.44, p = 0.005), Following Too Closely (OR = 0.09, p = 0.005), Passing Too Closely (OR = 0, p = 0.03). Others not significant | Speeding crashes have about 12.6 times the odds of being fatal |

**Key Takeaways**

- **Speed makes crashes deadly:** Unsafe speed causes 4.8% of crashes but 38% of fatal ones. To put that into perspective, a pedestrian's risk of death rises from 10% at 23 mph to 50% at 42 mph ([AAA Foundation](https://aaafoundation.org/impact-speed-pedestrians-risk-severe-injury-death/)).
- **Failure to yield is the most likely cause to injure someone:** It injured 963 pedestrians, close to distraction's 1,057, from a third as many crashes. From their data, the NYC Department of Transportation found it is the main factor in 27% of crashes that kill or seriously injure pedestrians ([NYC TLC](https://www.nyc.gov/assets/tlc/downloads/pdf/tips_for_sharing_street.pdf)
- **Distraction is the most common cause but less severe:** Even though driver inattention/distraction is so common, it still ranks second in fatal crashes, after unsafe speed.
- **Low-speed maneuvers rarely injure anyone:** Factors like passing too closely, backing, and improper lane use are mostly fender-benders.
