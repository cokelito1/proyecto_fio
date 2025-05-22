import re
import networkx as nx
import matplotlib.pyplot as plt

def parse_output(file_path):
    edges = []
    metadata = {}

    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Parse metadata line, e.g. meta: S = 1 T = 8 TN = 5 FN = 10
    meta_line = lines[0].strip()
    meta_matches = re.findall(r"(\w+) = (\d+)", meta_line)
    metadata = {key: int(value) for key, value in meta_matches}

    # Parse edges from the remaining lines
    for line in lines[1:]:
        line = line.strip()
        # Regex matching the example format
        match = re.search(
            r"Se instala cañeria del tipo (\d+) entre (fuente|tanque|nodo transitorio|nodo final) (\d+) y (fuente|tanque|nodo transitorio|nodo final) (\d+) con flujo ([\d\.]+)",
            line)
        if match:
            pipe_type = int(match.group(1))
            from_type = match.group(2)
            from_id = match.group(3)
            to_type = match.group(4)
            to_id = match.group(5)
            flow = float(match.group(6))

            # Normalize node names exactly as in input
            from_node = f"{from_type} {from_id}"
            to_node = f"{to_type} {to_id}"

            edges.append({'from': from_node, 'to': to_node, 'type': pipe_type, 'flow': flow})

    return metadata, edges


def visualize_graph_stratified(metadata, edges):
    G = nx.DiGraph()

 # Add all nodes from metadata
    for i in range(1, metadata.get("S", 0) + 1):
        G.add_node(f"fuente {i}")
    for i in range(1, metadata.get("T", 0) + 1):
        G.add_node(f"tanque {i}")
    for i in range(1, metadata.get("TN", 0) + 1):
        G.add_node(f"nodo transitorio {i}")
    for i in range(1, metadata.get("FN", 0) + 1):
        G.add_node(f"nodo final {i}")

    # Add edges with flow labels
    for edge in edges:
        G.add_edge(edge['from'], edge['to'], label=f"{edge['flow']:.2f}, tipo: {edge['type']}", type=edge['type'])

    # Prepare node colors for all categories based on metadata
    node_colors = {}
    for i in range(1, metadata.get("S", 0) + 1):
        node_colors[f"fuente {i}"] = "red"
    for i in range(1, metadata.get("T", 0) + 1):
        node_colors[f"tanque {i}"] = "blue"
    for i in range(1, metadata.get("TN", 0) + 1):
        node_colors[f"nodo transitorio {i}"] = "green"
    for i in range(1, metadata.get("FN", 0) + 1):
        node_colors[f"nodo final {i}"] = "purple"

    # Assign colors; default gray if not found in metadata keys
    node_color_list = [node_colors.get(node, "gray") for node in G.nodes()]

    # Create stratified positions
    pos = {}

    # Helper to assign positions in vertical columns
    def assign_positions(prefix, count, x_coord):
        positions = {}
        for i in range(1, count + 1):
            node_name = f"{prefix} {i}"
            if node_name in G:
                # y = -i to have top node at top (optional)
                positions[node_name] = (x_coord, -i)
        return positions

    pos.update(assign_positions("fuente", metadata.get("S", 0), 0))
    pos.update(assign_positions("tanque", metadata.get("T", 0), 1))
    pos.update(assign_positions("nodo transitorio", metadata.get("TN", 0), 2))
    pos.update(assign_positions("nodo final", metadata.get("FN", 0), 3))

    # For any nodes that weren't in metadata lists, position them on the right side in a column 4
    other_nodes = set(G.nodes()) - set(pos.keys())
    for idx, node in enumerate(sorted(other_nodes)):
        pos[node] = (4, -idx-1)

    # Draw graph with labels and edge labels
    plt.figure(figsize=(12, 8))
    nx.draw(G, pos, with_labels=True, node_color=node_color_list, node_size=1500, font_size=10, arrowsize=20)
    edge_labels = nx.get_edge_attributes(G, 'label')
    nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, font_color="black", font_size=8)

    plt.title("Flow Network Stratified by Node Type")
    plt.axis('off')
    plt.savefig("output.png")

if __name__ == "__main__":
    meta, edges = parse_output("output.txt")
    visualize_graph_stratified(meta, edges)
