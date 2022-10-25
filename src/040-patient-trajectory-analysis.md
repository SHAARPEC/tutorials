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
## Patient trajectory graph analysis

SHAARPEC API data is often the result of aggregating over the patient trajectories of a cohort. However, it is also possible to extract full patient trajectories for custom analysis or investigations. The patient trajectories are stored in the platform as [labeled property graphs](https://neo4j.com/developer/graph-database), i.e., directed graphs where nodes and edges are labeled by categories, and data is stored on nodes and edges as key/value pairs.

Let us see how such trajectory graphs can be analyzed.
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

Define the (atrial fibrillation) cohort as a Python dict and get the corresponding population as a `pd.DataFrame`:

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

```python tags=[]
atfib_population = (
    pd.DataFrame(
        client.get("population", edges=[20, 40, 60, 80], **atfib_cohort).json()
    )
    .convert_dtypes()
    .replace({"deceased_year": {0: pd.NA}})
)
atfib_population.head(10)
```

<!-- #region tags=[] -->
## Extract patient trajectories from the API
Let's focus on the first patient in this population:
<!-- #endregion -->

```python tags=[]
patient = atfib_population.patient_origin_id.iloc[0]
patient
```

We can extract the patient trajectory from the API:

```python tags=[]
response = client.get(f"/patient/{patient}/trajectory")
response
```

```python tags=[]
print("object keys: ", list(response.json().keys()))
print("graph keys: ", list(response.json()["graph"].keys()))
```

<!-- #region tags=[] -->
The patient trajectory is tagged with the (patient) originId, and the corresponding patient graph data. The patient graph is a directed acyclic graph (DAG), keyed by:
- nodes: List of patient data nodes.
- edges: List of patient data relationships.
- labels: Lookup-table for the node labels and the node ids.
- types: Lookup-table for the relationship label and relationship ids.
<!-- #endregion -->

<!-- #region tags=[] -->
## Build a patient graph with networkx

The patient graph is best analyzed with a graph library. For Python there are several, the most popular library is probably [networkx](https://networkx.org).

`networkx` is pure Python, so not too performant, but has a very user-friendly API.
<!-- #endregion -->

```python tags=[]
import networkx as nx
```

The following code builds a graph and should be more or less self-explanatory.

```python tags=[]
nodes = response.json()["graph"]["nodes"]
edges = response.json()["graph"]["edges"]
```

```python tags=[]
G = nx.MultiDiGraph() # Multi-edge directional graph

# Add nodes with data
for node in nodes.values():
    node_id = node.get("nodeId")
    node_label = node.get("labels", [""])[0]
    node_data = node.get(node_label.lower(), {})
    if node_id:
        G.add_node(node_id, label=node_label, **node_data)

# Add edges with data
for (edge_id, edge) in response.json()["graph"]["edges"].items():
    edge_source = edge.get("nodeIdFrom")
    edge_target = edge.get("nodeIdTo")
    edge_type = edge.get("type", "")
    edge_data = edge.get(edge_type.lower(), {})

    if edge_id:
        G.add_edge(edge_source, edge_target, key=edge_id, type=edge_type, **edge_data)
str(G)
```

<!-- #region tags=[] -->
`networkx` supports many graph calculations such as shortest path calculations, similarity, clustering, etc. Let's leave this for another session... Let's print out some simple statistics here:
<!-- #endregion -->

```python tags=[]
print(f"The patient trajectory with origin_id={patient} has {G.number_of_nodes()} nodes and {G.number_of_edges()} edges.")
```

<!-- #region tags=[] -->
Networkx is not really a visualization library, but let's see what happens if we try to draw the network structure of the graph:
<!-- #endregion -->

```python tags=[]
nx.draw_networkx(G)
```

<!-- #region tags=[] -->
Yikes... Let's see if we can improve on that?
<!-- #endregion -->

<!-- #region tags=[] -->
## Visualize patient timeline

Instead, let's visualize a timeline for the patient, i.e., a linear subgraph that only consists of the encounter nodes and the NEXT relationships between them.

Every Encounter node is assigned a position according to its timestamp with respect to the first encounter in the patient trajectory, and a size which is the number of events that occured on the Encounter.
<!-- #endregion -->

```python
encounters = response.json()["graph"]["labels"]["Encounter"]["nodeIds"] # Get encounters from the API by nodeIds
encounter_edges = response.json()["graph"]["types"]["NEXT"]["edgeIds"]  # Get encounter edges from the API by edgeIds 
```

Let's build a DataFrame with all the data we need.

```python
timeline_data = (
    # Here we read the timestamps from the encounters
    pd.DataFrame(
        {
            encounter: ts["startDate"] | ts["startTime"]
            for encounter in encounters
            if (ts := nodes[encounter]["encounter"])
        }
    )
    # Convert to datetimes
    .T.pipe(pd.to_datetime)
    # And sort them
    .sort_values()
    # Convert to DataFrame
    .rename("timestamp")
    .rename_axis("encounter_id")
    .reset_index()
    # From here the pipeline creates node and edge metadata
    .assign(
        order=lambda x: x.index + 1,
        locked=True,
        size=lambda x: 3 * (x.encounter_id.map(G.out_degree(x.encounter_id)) - 1),
        successor=lambda x: x.encounter_id.map(
            {
                edge["nodeIdFrom"]: edge["nodeIdTo"]
                for edge_id in encounter_edges
                if (edge := edges[edge_id])
            }
        ),
        elapsed_days=lambda x: x.timestamp.diff()
        .fillna(pd.Timedelta(seconds=0))
        .cumsum()
        .dt.round("D").dt.days,
        elapsed_days_label=lambda x: "Day " + x.elapsed_days.astype(str),
        x=lambda x: 45 * x.elapsed_days,
        y=0,
        position=lambda x: [
            row._asdict() for row in x[["x", "y"]].itertuples(index=False)
        ],
    )
)
timeline_data
```

Note that the pd.DataFrame.assign call allows to create new columns based on information available in the DataFrame. The order of the assign argument will be respected, so one can use previous information along the pipeline. In particular:
- order: Consecutive node number from 1 to n.
- locked: True for all so that nodes can not be draggable in the visualization.
- size: The node size calculated from the number of outgoing relationships on the encounter.
- successor: The node id for the next encounter in the graph.
- elapsed_days: The accumulated number of days starting from the first encounter.
- elapsed_days_label: Text representation of `elapsed_days`.
- x: node x-position is set to elapsed days times a scaling factor.
- y: node y-position is always set to zero.
- position: position dict passed to the visualization library.


We create a networkx graph from the pandas DataFrame, remember to drop the the last node which has no successor.

```python
timeline = nx.from_pandas_edgelist(
    timeline_data.dropna(),
    source="encounter_id",
    target="successor",
    create_using=nx.MultiDiGraph,
)

nx.set_node_attributes(
    timeline,
    timeline_data.set_index("encounter_id")
    .drop(columns="successor")
    .to_dict(orient="index"),
)
```

<!-- #region tags=[] -->
We can visualize this graph with [Cytoscape.js](https://js.cytoscape.org), a open-source graph theory network library. It is really powerful, but requires some effort to play nice. Cytoscape.js can be visualized as a widget in Jupyterlab with the [ipycytoscape](https://ipycytoscape.readthedocs.io/en/latest) library.
<!-- #endregion -->

```python tags=[]
from ipycytoscape import CytoscapeWidget
```

<!-- #region tags=[] -->
Create a widget from our timeline graph:
<!-- #endregion -->

```python tags=[]
cyto = CytoscapeWidget()
cyto.graph.add_graph_from_networkx(timeline)

cyto.layout.width = "1600px"
cyto.layout.height = "400px"
```

Set the layout, use our already pre-calculated positions for the nodes:

```python tags=[]
cyto.set_layout(
    name="preset",
    animate=False,
    fit=False,
    randomize=False,
    nodeSpacing=10,
    edgeLengthVal=10,
    zoom=1,
    pan={"x": 100, "y": 200},
)
```

<!-- #region tags=[] -->
Styling of Cytoscape.js is done with CSS attributes. You can learn about the syntax from the homepage. We provide a stylingn example to this tutorial ("style.json"). You can check it out and change if you want to. Styling changes should be picked up immediately by the Jupyterlab widget.
<!-- #endregion -->

```python tags=[]
import json
```

```python tags=[]
with open('style.json') as style_file:
    trajectory_style = json.load(style_file)
cyto.set_style(trajectory_style)
```

```python tags=[]
cyto
```

<!-- #region tags=[] -->
Isn't that nice!
<!-- #endregion -->
