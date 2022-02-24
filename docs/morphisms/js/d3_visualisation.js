function drag(simulation) {

  function dragstarted(event, d) {
    if (!event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
  }

  function dragged(event, d) {
    d.fx = event.x;
    d.fy = event.y;
  }

  function dragended(event, d) {
    if (!event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
  }

  return d3.drag()
      .on("start", dragstarted)
      .on("drag", dragged)
      .on("end", dragended);
}

function linkArc(d) {
    let r = Math.hypot(d.target.x - d.source.x, d.target.y - d.source.y);
    r = 40*Math.exp(r/50)
    // r = 50 + 2*(r/20)**3
// Elliptical arc:
//     return `
//     M${d.source.x},${d.source.y}
//     A${r},${r} 0 0,1 ${d.target.x},${d.target.y}
//   `;
    let xmid = (d.source.x + d.target.x) / 2
    let ymid = (d.source.y + d.target.y) / 2
    // cubic smooth Bezier
    return `
        M${d.source.x} ${d.source.y}
        S${xmid - 0.01*ymid} ${ymid + 0.01*xmid}
        ${d.target.x},${d.target.y}
    `
    ;
}

function highlight(node) {
    return node.transition()
        .duration('400')
        .attr('opacity', 1)
        .attr('filter', 'sepia(0.0)')
        ;
}

function dehighlight(node) {
    return node.transition()
        .duration('400')
        .attr('opacity', 0.3)
        .attr('filter', 'sepia(0.8)')
        ;
}

function _union(...arr) {
    return arr.reduce((first, second) => [...new Set(first.concat(second))]);
}

async function create_svg(
    data,
    width,
    height,
    ) {
    let links = data.links;
    let nodes = data.nodes;
    let types = Array.from(new Set(nodes.map(d => d.level)));
    let color = d3.scaleOrdinal(types, d3.schemeSet1);

    d3.select("datalist")
        .selectAll("option")
        .data(nodes)
        .join("option")
        .attr("value", n=>n.id)
        .text(n=>n.id)

    const simulation = d3.forceSimulation(nodes)
        // .alphaTarget(0.35)
        // .alphaDecay(0.5)
        .force("link", d3.forceLink(links).id(d => d.id))
        .force("charge", d3.forceManyBody().strength(-500))
        .force("center", d3.forceCenter(width/2, height/2))
        .force("x", d3.forceX())
        .force("y", d3.forceY().y(d => 100 * (2 * d.level + 1)))
        .force("radial", d3.forceRadial(d => 20 * (2*d.level), width/2, 0))

    const svg = d3.create("svg")
        .attr("preserveAspectRatio", "xMinYMin meet")
        .attr("viewBox", [0, 0, width, height])
        .classed("svg-content", true)
        .style("font", "12px sans-serif");

    // Per-type markers, as they don't inherit styles.
    svg.append("defs").selectAll("marker")
        .data(types)
        .join("marker")
        .attr("id", d => `arrow-${d}`)
        .attr("viewBox", "0 -5 10 10")
        .attr("refX", 15)
        .attr("refY", 0)
        .attr("markerWidth", 6)
        .attr("markerHeight", 6)
        .attr("orient", "auto")
        .append("path")
        .attr("fill", d=>color(d))
        .attr("d", "M0,-5 L10,0 L0,5 z")
        ;

    const svg_content = svg.append("g")

    const link = svg_content.append("g")
        .attr("fill", "none")
        .attr("stroke-width", 1.5)
        .selectAll("path")
        .data(links)
        .join("path")
        .attr("stroke", d => color(d.source.level))
        .attr("marker-end", d => `url(${new URL(`#arrow-${d.source.level}`, location)})`)
        .attr("opacity", 0.3)
        .attr("filter", "sepia(0.8)")
        ;

    function find_descendants(node) {
        let desc = links.filter(l => l.source.id == node.id );
        if (desc.length == 0) {
            return []
        } else {
            let all_desc = desc
                .map(d => find_descendants(d.target))
                .reduce(
                    (total, item) => Array.from(new Set(total.concat(item))),
                    desc.map(l=>l.target)
                )
                ;
            return all_desc;
            // return _union(desc, _union(...desc.map(l=>find_descendants(l.target))));
        }
    };

    const descendants = {};

    nodes.forEach((node) => {
        let desc = find_descendants(node);
        desc.push(node)
        descendants[node.id] = desc;
    });

    console.log(descendants)

    function foreground_descendants(id) {
        node.classed("foreground", (n) => {
            return (descendants[id].find(v => v.id == n.id)) ? true : false;
        });

        link.classed("foreground", (n) => {
            let verts = descendants[id]
            return (verts.includes(n.source) && verts.includes(n.target)) ? true : false;
        });
    }

    d3.select("input").on("input", function () {
        let id = this.value;
        let n = nodes.find(n => n.id == id)
        if (n) {
            foreground_descendants(id)

            svg.transition()
                .duration(750)
                .call(zoom.transform, d3.zoomIdentity);

            zoom.translateTo(svg.transition().duration(750), n.x, n.y)
        }
    });

    const node = svg_content.append("g")
        .attr("stroke-linecap", "round")
        .attr("stroke-linejoin", "round")
        .selectAll("g")
        .data(nodes)
        .join("g")
        .attr("class", d=>d.id)
        .attr("opacity", 0.3)
        .attr("filter", "sepia(0.8)")
        .on("mouseover", function (d, i) {
            highlight(d3.select(this));
        })
        .on("mouseout", function (d, i) {
            dehighlight(d3.select(this))
        })
        .on("click", function (d, i) {
            console.log(this)
            let id = this.classList[0];
            foreground_descendants(id);
        })
        .call(drag(simulation));

    // circles for nodes:
    node.append("circle")
        .attr("stroke", "white")
        .attr("stroke-width", 1.5)
        .attr("r", 5)
        .attr("fill", d => color(d.level));

    node.append("foreignObject")
        .attr("x", 10)
        .attr("y", "0.31em")
        .clone(true).lower()
        .attr("fill", "none")
        .attr("stroke", "white")
        .attr("stroke-width", 5)
        .append(d => createMathSpan(d.id));

    const zoom = d3.zoom()
        .scaleExtent([0.2, 5])
        .on("zoom", (e) => {
            console.log(e.transform)
            svg_content.attr("transform", e.transform)
        });

    svg.call(zoom)

    simulation.on("tick", () => {
        link.attr("d", linkArc);
        node.attr("transform", d => `translate(${d.x},${d.y})`);
    });

    return svg;
}
