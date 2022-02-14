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
