---
jupyter:
  jupytext:
    text_representation:
      extension: .md
      format_name: markdown
      format_version: '1.3'
      jupytext_version: 1.14.1
  kernelspec:
    display_name: Python 3 (ipykernel)
    language: python
    name: python3
---

<!-- #region tags=[] -->
## Population health analysis

SHAARPEC for Population Health aggregates properties extracted from patient trajectories of a population sharing common traits. This subpopulation is called a patient cohort and is defined by attributes such as age or year-of-birth, or by diagnosis or medication codes. 
<!-- #endregion -->

<!-- #region tags=[] -->
You can define a cohort that can be reused for retrieving data from many of the resources in the SHAARPEC Analytics API. First, create a client and access the API.
<!-- #endregion -->

```python
from shaarpec import Client
```

```python
client = Client.with_device(
    "https://api-demo.shaarpec.com",
    auth={"host": "https://idp-demo.shaarpec.com"},
    # timeout=3600, # increase as needed
)
```

We use pandas for data analysis. 

```python
import pandas as pd
```

Get all (sorted) condition codes in the synthetic data.

```python
all_conditions = pd.Series(
    client.get("terminology/condition_type/codes").json()
).sort_index()
all_conditions
```

Note how we create a Python dict from the client response with the `.json()` method. A `pd.Series` object is then created directly from this object, which is sorted on the condition code.

<!-- #region tags=[] -->
### Define a cohort

Now let's say we want to do analysis for a patient cohort diagnosed with [atrial fibrillation](https://en.wikipedia.org/wiki/Atrial_fibrillation). Then we can filter this `pd.Series` on the right keyword and extract those codes:
<!-- #endregion -->

```python tags=[]
atfib = all_conditions.loc[
    lambda x: x.str.contains("hjärt.*svikt", case=False)
]
atfib
```

<!-- #region tags=[] -->
The diagnosis codes can be stored in a dict that can be passed to all population endpoints:
<!-- #endregion -->

```python tags=[]
atfib_cohort = {
    "conditions": atfib.index.tolist()
}
```

<!-- #region tags=[] -->
### Extract data corresponding to a cohort

Now it's simple to get a patient list for this cohort (see [the analytics API documentation](https://api-demo.shaarpec.com/population/docs#/Population/patients_population_get) for a description of the `edges` parameter):
<!-- #endregion -->

```python tags=[]
atfib_population = (
    pd.DataFrame(
        client.get("population", edges=[20, 40, 60, 80], **atfib_cohort).json()
    )
    .convert_dtypes()
    .replace({"deceased_year": {0: pd.NA}})
)
atfib_population
```

A complication here is that missing `deceased_year` is reported as 0. To replace this with `pd.NA` (Pandas Not-A-Number) we first need to convert the data to Pandas internal datatypes with the `pd.convert_dtypes` function.

<!-- #region tags=[] -->
### Data visualization

You can use your favorite library to visualize data, e.g., [Seaborn](https://seaborn.pydata.org), [altair](https://altair-viz.github.io), or [plotnine](https://plotnine.readthedocs.io/en/stable). In this tutorial, we use [plotly](https://plotly.com/python).
<!-- #endregion -->

```python tags=[]
import plotly.express as px
```

```python tags=[]
fig = px.histogram(
    atfib_population,
    x="deceased_year",
    color="gender",
    pattern_shape="age",
    labels={"deceased_year": "Deceased year", "count": "Count"},
    text_auto=True,
    width=1200,
    height=400,
)
fig.update_layout(bargap=0.1)
```

<!-- #region tags=[] -->
SHAARPEC also provides an overview summary of the population at hand.
<!-- #endregion -->

```python tags=[]
atfib_summary = client.get("population/summary", **atfib_cohort).json()
atfib_summary
```

<!-- #region tags=[] -->
With your everyday data manipulation, you can create a `pd.DataFrame` or whatever else data structure you prefer from this Python dict. For example, using Python's standard `datetime`
library:
<!-- #endregion -->

```python tags=[]
from datetime import datetime
```

We extract the data we are interested in and create a `pd.DataFrame`:

```python tags=[]
pd.concat(
    [
        pd.Series(
            {
                "from": datetime(**atfib_summary["timePeriod"]["min"]),
                "to": datetime(**atfib_summary["timePeriod"]["max"]),
                "patients": atfib_summary["patientCount"],
                "encounters": atfib_summary["encounterCount"],
            }
        ),
        pd.DataFrame(atfib_summary["encounterCountByCategory"]).pipe(
            lambda x: pd.Series(
                x["count"].values, index=x.category.name + '."' + x.category + '"'
            )
        ),
    ]
)
```

<!-- #region tags=[] -->
You can also get an overview of clinical data of the population, i.e., condition codes, and medication codes, and organizational data. Look around the API and tell us what is missing!
<!-- #endregion -->

<!-- #region tags=[] -->
### Example: Analyze medication codes prescribed to a atfib cohort

First, get the medications from the API using population health analysis:
<!-- #endregion -->

```python tags=[]
response = client.get("population/medications", **atfib_cohort)
```

This response is a nested dict. We can use `pd.json_normalize` to flatten the data. Then we sort by number of unique patients prescribed on the medication, in descending order:

```python tags=[]
atfib_medications = pd.json_normalize(response.json()).sort_values(
    by="unique_patients", ascending=False
)
```

<!-- #region tags=[] -->
Finally, it would be useful with a human-readable description for each medication. This can be extracted from the terminology endpoint in the API.
<!-- #endregion -->

```python
all_medications = pd.Series(client.get("terminology/medication_type/codes").json())
```

We can now map the medication codes of the cohort to those descriptions.

```python tags=[]
df = (
    atfib_medications.assign(
        description=lambda x: x.medication_types.map(all_medications)
    )
    .rename(
        columns={
            "medication_types": "medication",
            "unique_patients": "patients",
            "unique_encounters": "encounters",
        }
    )
    .filter(regex="^(?!summary)")
)
df.head()
```

Note that we also renamed some columns and dropped the summary columns. Finally we can plot the analysis:

```python
px.histogram(
    df.head(10),
    x="description",
    y="patients",
    labels={"description":"medication"}
)
```

```python

```
