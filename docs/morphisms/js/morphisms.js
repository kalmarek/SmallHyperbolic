const morphisms_url = new URL("https://raw.githubusercontent.com/kalmarek/SmallHyperbolic/mk/morphisms/data/triangle_groups_morphisms.json")

async function fetch_json(url) {
    try {
        let response = await fetch(url);
        let json = await response.json();
        return json;
    } catch (err) {
        console.log("Error while fetching json:" + err);
    }
};

async function place_svg(svg) {
    d3.select("div.canvas")
        .append("div")
        .attr("class", "container-fluid")
        .attr("class", "svg-container")
        .node()
        .appendChild(svg.node())
        ;
};

async function add_search() {
    let input_grp = d3.select("div.canvas")
        .append("div")
        .classed("search-field", true)
        .append("div")
        .classed("container", true)
        ;

    let input = input_grp.insert("input")
        .attr("class", "form-control")
        .attr("list", "datalistOptions")
        .attr("id", "groupSearch")
        .attr("placeholder", "Type to search...")
        ;

    input_grp.insert("datalist")
        .attr("id", "datalistOptions")
        ;

}

async function switch_katex(toggle=true) {
    let math_objects = document.getElementsByClassName("math");
    for (let elt of math_objects) {
        toggleKaTeX(elt, toggle);
        let fObj = elt.parentElement;
        let rect = elt.getElementsByClassName("math-tex")[0].getBoundingClientRect();
        fObj.setAttribute("width", rect.width+4);
        fObj.setAttribute("height", rect.height+4);
    }
};

add_search()

fetch_json(morphisms_url)
    // .then(async (data) => { console.log(data); return data;})
    .then(async (data) => {
        return create_svg(data, window.innerWidth, window.innerHeight);
    })
    // .then(async (data) => { console.log(data); return data; })
    .then(place_svg)
    .then(switch_katex)
    // .then(add_search)
;

