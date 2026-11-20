#importing libraries and initial csv

import os
import re
from collections import Counter, defaultdict
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from scipy.spatial import cKDTree

df = pd.read_csv("/Users/hershoza/Downloads/Motor_Vehicle_Collisions_-_Crashes_20261116.csv")

#brief analysis of initial csv

print(df.shape)
print(df.info())
print(df.describe())
print(df.isnull().sum())
print(df.duplicated().sum())

#filling in missing borough rows

boros = ["BRONX", "BROOKLYN", "MANHATTAN", "QUEENS", "STATEN ISLAND"]
streets = ["ON STREET NAME", "CROSS STREET NAME", "OFF STREET NAME"]
print("Missing boroughs at start:", df["BOROUGH"].isna().sum())

bad = (df["LATITUDE"] == 0) | (df["LONGITUDE"] == 0)
df.loc[bad, ["LATITUDE", "LONGITUDE"]] = np.nan

known = df["BOROUGH"].notna() & df["LATITUDE"].notna()
fill = df["BOROUGH"].isna() & df["LATITUDE"].notna()
tree = cKDTree(df.loc[known, ["LATITUDE", "LONGITUDE"]].values)
_, idx = tree.query(df.loc[fill, ["LATITUDE", "LONGITUDE"]].values, k=5)
known_boros = df.loc[known, "BOROUGH"].values
df.loc[fill, "BOROUGH"] = [Counter(known_boros[row]).most_common(1)[0][0] for row in idx]
print("Missing after coordinates:", df["BOROUGH"].isna().sum())

def clean_street(s):
    if not isinstance(s, str):
        return None
    s = re.sub(r"\s+", " ", s.upper()).strip()
    s = re.sub(r"^\d+[A-Z]?(-\d+)? ", "", s)   # drop house numbers ("123 MAIN ST")
    return s or None

for c in streets:
    df[c] = df[c].map(clean_street)

street_boros = defaultdict(Counter)
for names, boro in zip(df.loc[df["BOROUGH"].notna(), streets].values.tolist(),
                       df.loc[df["BOROUGH"].notna(), "BOROUGH"]):
    for name in set(n for n in names if n):
        street_boros[name][boro] += 1

def guess_borough(names, min_conf=0.9):
    """Combine the evidence from every street name on the crash; only
    assign a borough if the best one has at least 90% probability."""
    names = [n for n in set(n for n in names if n) if n in street_boros]
    if not names:
        return None
    score = np.zeros(len(boros))
    for n in names:
        counts = street_boros[n]
        total = sum(counts.values())
        score += np.log([(counts[b] + 0.1) / (total + 0.5) for b in boros])
    prob = np.exp(score - score.max())
    prob /= prob.sum()
    return boros[prob.argmax()] if prob.max() >= min_conf else None

still_missing = df["BOROUGH"].isna()
df.loc[still_missing, "BOROUGH"] = [guess_borough(n) for n in
                                    df.loc[still_missing, streets].values.tolist()]
print("Missing after street names:", df["BOROUGH"].isna().sum())

#altering values/further changing the csv

keep_cols = ["CRASH DATE", "CRASH TIME", "BOROUGH",
             "NUMBER OF PERSONS INJURED", "NUMBER OF PERSONS KILLED",
             "NUMBER OF PEDESTRIANS INJURED", "NUMBER OF PEDESTRIANS KILLED",
             "NUMBER OF CYCLIST INJURED", "NUMBER OF CYCLIST KILLED",
             "NUMBER OF MOTORIST INJURED", "NUMBER OF MOTORIST KILLED",
             "CONTRIBUTING FACTOR VEHICLE 1"]
df = df[keep_cols].copy()

df.columns = df.columns.str.capitalize()   # "CRASH DATE" -> "Crash date"
df["Borough"] = df["Borough"].str.title()

df["Crash date"] = pd.to_datetime(df["Crash date"], format="%m/%d/%Y")
df["Hour"] = pd.to_datetime(df["Crash time"], format="%H:%M").dt.hour
df["Weekday"] = df["Crash date"].dt.day_name()
df["Time period"] = pd.cut(df["Hour"], bins=[-1, 5, 9, 15, 19, 23],
                           labels=["Late night (0-5)", "Morning rush (6-9)",
                                   "Midday (10-15)", "Evening rush (16-19)",
                                   "Evening (20-23)"])

df["Injured"] = (df["Number of persons injured"] > 0).astype(int)

df = (df.sort_values(["Crash date", "Crash time"], kind="stable")
        .reset_index(drop=True))
df.insert(0, "Collision ID", range(1, len(df) + 1))

#exporting the new, cleaned csv 

df.to_csv("/Users/hershoza/Downloads/CarCrashesAnalysis.csv", index=False)
df.assign(**{"Crash date": df["Crash date"].dt.date}).to_excel("/Users/hershoza/Downloads/CarCrashesAnalysis.xlsx", index=False)

#where my charts will be saved as a separate folder

folder_name = os.path.join(os.path.expanduser("~"), "car crashes analysis charts")
os.makedirs(folder_name, exist_ok=True)

def save_path(filename):
    return os.path.join(folder_name, filename)

print(f"Charts will be saved in: {folder_name}")

#heatmap
days = ["Monday", "Tuesday", "Wednesday", "Thursday",
        "Friday", "Saturday", "Sunday"]
grid = (df.pivot_table(index="Weekday", columns="Hour", values="Collision ID",
                       aggfunc="count", fill_value=0)
          .reindex(days))

fig, ax = plt.subplots(figsize=(12, 4.5))
im = ax.imshow(grid, aspect="auto", cmap="YlOrRd")
ax.set_xticks(range(24))
ax.set_xticklabels(range(24))
ax.set_yticks(range(7))
ax.set_yticklabels(days)
ax.set_xlabel("Hour of day")
ax.set_title("NYC crashes by hour and weekday (Jul-Dec 2021)")
fig.colorbar(im, ax=ax, label="Number of crashes")
plt.tight_layout()
fig.savefig(save_path("heatmap.png"), dpi=150)
plt.show()
plt.close(fig)

#boxplot graph
b = df.dropna(subset=["Borough"])
pop = {"Bronx": 1472654, "Brooklyn": 2736074, "Manhattan": 1694251,
       "Queens": 2405464, "Staten Island": 495747}
daily = b.groupby(["Crash date", "Borough"]).size().unstack(fill_value=0)
rate = daily.div(pd.Series(pop)) * 100000

boroughs = list(pop.keys())
fig, ax = plt.subplots(figsize=(9, 5))
ax.boxplot([rate[x] for x in boroughs], tick_labels=boroughs, patch_artist=True,
          boxprops=dict(facecolor="green", edgecolor="black"),
          medianprops=dict(color="black"), 
          flierprops=dict(markeredgecolor="gray", alpha=0.5))
ax.set_ylabel("Daily crashes per 100,000 residents")
ax.set_title("Daily crash rate by borough (Jul-Dec 2021)")
plt.tight_layout()
fig.savefig(save_path("boxplot.png"), dpi=150)
plt.show()
plt.close(fig)

#barchart graph
f = df[df["Contributing factor vehicle 1"].notna() &
       (df["Contributing factor vehicle 1"] != "Unspecified")]
top = (f.groupby("Contributing factor vehicle 1")
        .agg(crashes=("Injured", "size"), injury_rate=("Injured", "mean"))
        .sort_values("crashes").tail(10))

fig, ax = plt.subplots(figsize=(10, 6))
bars = ax.barh(top.index, top["crashes"], color="blue", edgecolor="black")
for bar, r in zip(bars, top["injury_rate"]):
    ax.text(bar.get_width() + 150, bar.get_y() + bar.get_height() / 2,
            f"{r:.0%} injury", va="center", fontsize=9)
ax.set_xlabel("Number of crashes")
ax.set_title("Top 10 primary contributing factors (Jul-Dec 2021)")
ax.set_xlim(0, top["crashes"].max() * 1.18)
plt.tight_layout()
fig.savefig(save_path("barchart.png"), dpi=150)
plt.show()
plt.close(fig)

