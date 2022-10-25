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
## Rule-based compliance calculations

We want to implement a number of scoring systems for estimating risks based on clinical prediction rules. Currently, the [Chads2Vasc2](https://en.wikipedia.org/wiki/CHA2DS2%E2%80%93VASc_score), a scoring system for predicting risk for atrial fibrillation stroke is supported.

SHAARPEC for population health is not classified as a medical device, and can not be used as a clinical decision support. Risk score calculations are only supported on the population health level.
<!-- #endregion -->

<!-- #region tags=[] -->
First, create a client and access the API.
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

## Chads2Vasc2 calculation for atrial fibrillation cohort


Define an atrial fibrillation cohort as earlier as a Python dict:

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

<!-- #region tags=[] -->
Then get the Chads2Vasc2 population health analysis for year 2018 (as always use the [interactive API](https://api-demo.shaarpec.com) to read the documentation on the parameters):
<!-- #endregion -->

```python tags=[]
df = pd.Series(
    client.get("scoring/cha2ds2vasc/stats", target_year=2018, **atfib_cohort).json()
).sort_values(ascending=False)
```

```python
df
```
