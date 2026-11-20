# NYC Car Crashes Analysis

As NYC gradually reopened in the second half of 2021, following the COVID-19 pandemic, shifting traffic patterns led to a sharp rebound in severe roadway incidents. This project analyzes NYC motor vehicle collision data to uncover where, when, and why crashes occurred across the five boroughs.

## Disclaimers

- **With n = 5,928, almost every test is significant:** Effect sizes of V, w, η², and odds ratios can hoist a large difference.
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
| Key fields | units by income tier, total units, counted (affordable) units, program group, start date, extended-affordability flag |

## Findings

### Question 1: When do crashes happen?

| Project size | 100% affordable | Mixed-income |
|---|---|---|
| Small (1–10 units) | 74.5% | 25.5% |
| Medium (11–100 units) | 31.5% | 68.5% |
| Large (100+ units) | 60.5% | 39.5% |

**Statistical Tests**

| Test | Result | What it means |
|---|---|---|
| Spearman correlation (size vs. affordable share) | ρ = −0.34, p < 0.001 | Bigger projects have a smaller affordable share (moderate effect) |
| Chi-square (size group × fully affordable) | χ²(2) = 906.0, p < 0.001, Cramér's V = 0.39 | Size group and being 100% affordable are related (moderate to strong) |
| Logistic regression (fully affordable ~ log size) | b = −0.376, z = −25.7, p < 0.001; OR per doubling = 0.77 | Each time size doubles, the odds of being 100% affordable drop by about 23% |

**Key Takeaways**

- Projects fall into two groups: **100% affordable**, or **mixed-income at about 20–30% affordable**. Few projects land in between, which suggests developers aim at specific targets instead of choosing an affordable share freely.
- The 20–30% band matches the city's rules. Policies like Mandatory Inclusionary Housing (MIH) and the 421-a / Affordable New York tax break require developers to set aside about 20–30% of a building's floor area or units as affordable, income-restricted housing. Most mixed-income buildings set aside the minimum the rules require.
- Bigger projects tend to have a smaller affordable share. The relationship isn't a straight line, though, as the next point shows.
- **Medium projects (11–100 units) are the most likely to be mixed-income:** only 31.5% are fully affordable, compared with 74.5% of small projects and 60.5% of large projects.
- 73% of small projects come from Homeowner Assistance, which is nearly always fully affordable.
- Many large projects are 100% affordable buildings financed directly by the city.
- Medium projects fall in between, where a lot of the mixed-income buildings are.

### Question 2: Where do crashes happen?

| Income tier | % of AMI (Area Median Income) | Share of affordable units |
|---|---|---|
| Extremely Low | 0–30% | 18.4% |
| Very Low | 31–50% | 27.1% |
| Low | 51–80% | **34.1%** |
| Moderate | 81–120% | 6.1% |
| Middle | 121–165% | 14.2% |

**Statistical Tests**

| Test | Result | What it means |
|---|---|---|
| Chi-square goodness-of-fit (are the 5 tiers equal?) | χ²(4) = 76,356, p < 0.001, Cohen's w = 0.49 | Units are not split evenly across tiers (medium to large effect) |
| Friedman test (tiers within each project) | χ²(4) = 2,814.5, p < 0.001 | Tier counts differ within the same projects |
| Paired Wilcoxon, Holm-adjusted | All 10 pairs p < 0.01 | Every pair of tiers differs; the closest pair is Extremely Low vs. Very Low (p = 0.002) |
| Chi-square (program × tier) | χ²(12) = 73,021, p < 0.001, Cramér's V = 0.28 | Each program has a different tier mix (small to moderate effect) |

**Key Takeaways**

- **Low income (51–80% AMI) gets the largest share at 34%. Moderate income gets the smallest at 6%.** "Low income" goes up to 80% of AMI, so the biggest group of units is not aimed at the city's poorest households.
- Extremely Low and Very Low together get about 45% of units. That's a large share, but it's still less than half.
- The mix depends on the program:
  - **Multifamily Finance** serves the lowest incomes most: 56% of its units go to Extremely Low or Very Low. These projects get direct city funding, which makes deeper affordability possible.
  - **Multifamily Incentives** (tax-incentive and inclusionary projects) puts **38% of its units in the Middle tier, which is tied with Low tier**, up to 165% of AMI. This fits 421-a options that allowed affordable units at up to 130% of AMI. A tax break alone covers less of the cost, so these projects lean toward higher incomes.

### Question 3: Why do crashes happen? What causes them?

| Program | Projects | Median affordable units |
|---|---|---|
| Multifamily Finance | 1,196 | 104 |
| Small Homes | 46 | 36 |
| Multifamily Incentives | 2,742 | 9 |
| Homeowner Assistance | 1,944 | 1 |

**Statistical Tests**

| Test | Result | What it means |
|---|---|---|
| Welch's ANOVA (log size ~ program) | F(3, 217.2) = 10,015, p < 0.001, η² = 0.73 | Program explains about 73% of the variation in project size (very large effect) |
| Tukey HSD (pairs of programs) | All 6 pairs p < 0.001 | Every program differs in size from every other program |
| Kruskal-Wallis (raw units) | χ²(3) = 4,653.2, p < 0.001 | Confirms the ANOVA result without assuming normality |
| Multiple regression (log size ~ program + start year + extended affordability) | R² = 0.73, F(5, 5922) = 3,208, p < 0.001 | Program gaps hold after the controls (see the next table) |

**Key Takeaways**

- **Program type explains most of the difference in project size.** Every program differs from every other one, so the programs really build different kinds of projects.
- **Multifamily Finance builds the biggest projects** (median 104 affordable units). **Homeowner Assistance projects are almost always 1 unit**, because they help individual homeowners instead of building apartments.
- **Multifamily Incentives has a small median (9 units) but a very wide spread.** Most of its projects are small, but some have thousands of units.
- **Small Homes has only 46 projects**, so its results are less certain than the other programs'.
- The gaps between programs barely change after controlling for start year and extended affordability. Program, not timing, drives project size.
