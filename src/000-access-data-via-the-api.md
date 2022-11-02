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
## Access data via the SHAARPEC Analytics API

Data from SHAARPEC analyses can be fetched in [JSON](https://www.json.org) format from the API. E.g., visit https://api-demo.shaarpec.com/terminology/condition_type/codes to get a list of the condition codes that are available in the synthetic data set of the test account (you will be asked to login).

Access to the data is controlled by the [SHAARPEC identity server](https://identityserver4.readthedocs.io/en/latest) (IDP). Access to the API is requested via the IDP as specified by the standard [OpenId Connect (OIDC) protocol](https://openid.net/connect).

The authorization procedure is done with standard https requests, exactly how this is done for your favorite tool (R, Fortran, Tableau) is beyond the scope of this session but general instructions are found in the above links.
<!-- #endregion -->

<!-- #region tags=[] -->
For Python we provide an API client library that can be installed with `pip`:
```bash
pip install shaarpec
```
The client is used as:
<!-- #endregion -->

```python tags=[]
from shaarpec import Client
```

```python tags=[]
client = Client.with_device(
    "https://api-demo.shaarpec.com",
    auth={"host": "https://idp-demo.shaarpec.com"},
    #timeout=3600, # increase as needed
)
```

As you can see, the login asks your to visit a web address where you login and authenticate the client as a new device.

A success notification is shown when the verification is complete. The client timeout is 60 s by default, some calculations may take longer and then you can increase it as needed.

<!-- #region tags=[] -->
## Authentication

`Client` supports two authentication flows: `device` and `code`. For script access you want to use `device` flow. (Read more at https://www.github.com/SHAARPEC/shaarpec-python-client.) The client needs the base URL to the REST API (https://api-demo.shaarpec.com) and the location of the identity server for authentication (https://idp-demo.shaarpec.com).

You also need *credentials*. For device flow these are:
- client_id: A unique client id (environment variable OIDCISH_CLIENT_ID)
- client_secret: A unique secret for using the client (OIDCISH_SECRET).
- audience: Who these resources are intended for (OIDCISH_AUDIENCE).
- scope: What resources you want to access (OIDCISH_SCOPE).

These values can be given to the `auth` keyword in the `Client` constructor, but it is bad practice to store confidential information in your code. The SHAARPEC Python client authenticates using the [oidcish](https://github.com/SHAARPEC/oidcish) library, which supports a better option, namely to read them dynamically as [environment variables](https://en.wikipedia.org/wiki/Environment_variable). `oidcish` expects a variable prefix (default is `OIDCISH_`).

These variables are pre-set in the environment of this tutorial. Note that oidcish also supports keeping the variables in a .env file in the same folder as the script, see the oidcish documentation for details. The audience and scope do not need to be changed. The client id and secret must be provided to start this tutorial.
<!-- #endregion -->

```python tags=[]
# Run this command to read the credentials from the environment
!env | grep OIDCISH_
```

<!-- #region tags=[] -->
## Accessing data

Once authenticated, we can get data from the API. The SHAARPEC Python client returns standard `response` objects (familiar from the `requests` or `httpx` libraries) for API data. The response can be converted to a Python object with its `.json()` method. The status code of a successful response is 200, 40X for authentication errors, and 500 if there was an internal error. 

The client can call the API with `.get()` or `.post()` methods. The input to these methods are the endpoint and its expected query parameters. These are documented and testable in the [interactive API](https://api-demo.shaarpec.com).
<!-- #endregion -->

<!-- #region tags=[] -->
As a first example, get all conditions types (diagnosis codes) in the data:
<!-- #endregion -->

```python tags=[]
client.get("terminology/condition_type/codes")
```

<!-- #region tags=[] -->
The returned data is (mostly) directly compatible with your standard data processing libraries. In this tutorial we use the popular [pandas](https://pandas.pydata.org) library and its [Series and DataFrame representations](https://pandas.pydata.org/docs/getting_started/overview.html).
<!-- #endregion -->

```python
import pandas as pd
```

<!-- #region tags=[] -->
Get all condition and medication codes in the synthetic data
<!-- #endregion -->

```python tags=[]
all_conditions = pd.Series(client.get("terminology/condition_type/codes").json())
all_medications = pd.Series(client.get("terminology/medication_type/codes").json())
```

```python tags=[]
all_conditions
```

```python tags=[]
all_medications
```
