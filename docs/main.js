const groups_url = new URL("https://raw.githubusercontent.com/kalmarek/SmallHyperbolic/master/data/triangle_groups.json")

async function fetch_json(url) {
    try {
        let response = await fetch(url);
        let json = await response.json();
        return json;
    } catch (err) {
        console.log("Error while fetching json:" + err);
    }
}

let table = fetch_json(groups_url)
    .then(setup_table)
    .then(setup_filter)
    ;

let math_objects = document.getElementsByClassName("math");
let katex_switch = document.getElementById("renderWithKatex");
katex_switch.checked = true;
katex_switch.addEventListener(
    "change",
    function () {
        let toggle = this.checked;
        for (let element of math_objects) {
            toggleKaTeX(element, toggle);
        }
    }
);
