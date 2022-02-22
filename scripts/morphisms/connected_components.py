import networkx
import json
import os

DATA_DIR = os.path.join("..", "..", "data")

MORPHISMS_FILE = os.path.join(DATA_DIR, "morphisms.dot")
MORPHISMS_JSON = os.path.join(DATA_DIR, "triangle_groups_morphisms.json")

def level(G, node):
    parents = list(G.predecessors(node))
    if len(parents) == 0:
        return 0
    else:
        return 1 + max([level(G, n) for n in parents])

def nodes_from_component(G, cc, graph_json):
    subG = networkx.induced_subgraph(G, cc)
    assert networkx.is_weakly_connected(subG)

    root = [n for n,d in subG.in_degree() if d==0][0]

    for node in graph_json["nodes"]:
        if node["id"] in subG:
            print(node)
            n = node["id"]
            node["level"] = level(G, n)
            node["component_id"] = root

    return graph_json

G = networkx.nx_pydot.read_dot(MORPHISMS_FILE)
G_json = networkx.node_link_data(G)
G_components = networkx.weakly_connected_components(G)

for cc in G_components:
    nodes_from_component(G, cc, G_json)

with open(MORPHISMS_JSON, "w") as file:
    print("writing to ", MORPHISMS_JSON, "\n")
    json.dump(G_json, file, indent=4)
