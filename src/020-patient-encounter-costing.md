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
## Patient Encounter Costing (PEC)

PEC is a model that computes a (resource) cost for each encounter in the system, which is useful for determining where resources are spent within the healthcare organization. Per-encounter costs can be aggregated over patient cohorts, organization units, and cost group types.

Describing the PEC computational model is beyond scope of this tutorial, but it can be useful to note that cost drivers, which are the central components of the PEC calculation, are typically clinician's time or the number of staffed beds at the hospital.

This tutorial shows how you can extract PEC costs for population health analysis.
<!-- #endregion -->

<!-- #region tags=[] -->
Create a client and access the API.
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

Define your cohort for, say atrial fibrillation, as a Python dict:

```python
import pandas as pd
```

```python tags=[]
all_conditions = pd.Series(
    client.get("terminology/condition_type/codes").json()
).sort_index()
atfib = all_conditions.loc[lambda x: x.str.contains("hjärt.*svikt", case=False)]
atfib_cohort = {"conditions": atfib.index.tolist()}
```

## PEC per year

Now, get the PEC calculation for year 2018:

```python
response = client.get("pec/encounters/year/2018", **atfib_cohort)
response
```

The returned data is a list of all encounters, what patient was involved, the primary condition of that encounter, and the cost. It is not difficult to create a DataFrame for this that we can use as a basis for our data analysis.

```python tags=[]
pec_2018 = (
    pd.concat(
        {
            encounter_id: pd.Series(data)
            for (encounter_id, data) in response.json().items()
        }
    )
    # The rest here is data munging to get it on the format we like
    .unstack()
    .rename_axis("encounter_id")
    .reset_index()
    .replace({"primary_condition": {"": pd.NA}})
)
pec_2018
```

<!-- #region tags=[] -->
Now, let's say we want to aggregate those costs based on primary condition. We can do this with a data analysis pipeline:
<!-- #endregion -->

```python tags=[]
df = (
    pec_2018.groupby("primary_condition", dropna=False)                 # Group by primary condition
    .cost.sum()                                                         # Sum the cost
    .sort_values(ascending=False)                                       # Sort in descending order
    .reset_index()                                                      # Convert to DataFrame
    .assign(
        description=lambda x: x.primary_condition.map(all_conditions)
    )                                                                   # Add description
    .replace(pd.NA, "Okänd")
)
df
```

Note that "Okänd" (missing primary condition) is the data entry where the second-most costs are spent. We can directly compute percentages for the data entries as well:

```python
df.assign(percentage=lambda x: 100 * x.cost / x.cost.sum())
```

<!-- #region tags=[] -->
## Accumulated PEC

We can also calculate the accumulated PEC cost per patient, ordering by the highest cost patients. Let's do this for the atrial fibrillation cohort for the calendar year 2020. You can check out the parameters in the [interactive documentation](https://api-demo.shaarpec.com).
<!-- #endregion -->

```python tags=[]
pec_accumulation = pd.DataFrame(
    client.get(
        "pec/patients/accumulation",
        start_date="2020-01-01",
        end_date="2020-12-31",
        **atfib_cohort
    ).json()[-1]
)
pec_accumulation
```

The returned data is a sorted list of patients in the cohort and their costs during the time period (from patient with most costs to patient with least costs).

In other words, the DataFrame has one row for each patient in the population, and is sorted in descending order on PEC utilization cost ("most expensive patient first"). The `count_` and `sum_` columns are accumulated costs per EncounterCategory, `cost_share` is the percentage of total cost (100% is maximum) and `n` is the percentage of patients in the population.

This can be visualized in a line plot (we need to add a zero point to get a continuous line).

```python
import plotly.express as px
```

```python tags=[]
px.line(
    pec_accumulation.pipe(
        lambda x: pd.concat(
            [pd.DataFrame(0, index=[-1], columns=x.columns), x]
        )  # Add point at zero for plotting
    ),
    x="n",
    y="cost_share",
    range_x=(0, 100),
    range_y=(0, 100),
    labels={"n": "Fraction of patients", "cost_share": "Fraction of costs"},
)
```

If each patient had the same costs, we would expect a diagonal line from the left bottom corner to the right top corner. What we usually see, however, is that there is a small number of patients that account for most of the costs (80/20 rule). Identifying the patients with large costs helps in understanding what the common denominator is for that subpopulation.

```python

```
