const groups_url = new URL("https://raw.githubusercontent.com/kalmarek/SmallHyperbolic/mk/json/data/triangle_groups.json")

async function fetch_json(url) {
    try {
        let response = await fetch(url);
        let json = await response.json();
        return json;
    } catch(err) {
        console.log("Error while fetching json:" + err);
    }
}

function columnName(key) {
    let words = key.split("_");
    for (let i = 0; i < words.length; i++) {
        words[i][0].toUpperCase();
    }
    return words.join(" ");
}

function generateTableHead(table, keys) {
    let thead = table.createTHead();
    let row = thead.insertRow();
    for (let key of keys) {
//         if (key.match("utf8") != null) { continue; }
        let th = document.createElement("th");
        let text = document.createTextNode(columnName(key));
        th.appendChild(text);
        row.appendChild(th);
    }
}

function fillRow(row, group_json) {
    for (let key of Object.keys(group_json)) {
        let cell = row.insertCell();
        let cell_content;
        let value = group_json[key]
        if (key == "quotients" || key == "quotients_utf8") {
            cell_content = JSON.stringify(value);
        } else if (key == "name") {
            cell_content = value
        } else if ( key == "generators" || key == "relations") {
            cell_content = value.join(",");
        } else {
            cell_content = group_json[key];
        }
        let text = document.createTextNode(cell_content);
        cell.appendChild(text);
    }
}

function fillTableFromJson(table, json) {
    let keys = Object.keys(json[0]);
    for (let group of json) {
        let row = table.insertRow();
        fillRow(row, group);
    }
    generateTableHead(table, keys);
}

// table.setData(groups_url);

const filtersConfig = {
    base_path: 'tablefilter/',
    autofilter: {
                    delay: 200
                },
    filters_row_index: 1,
    state: true,
    alternate_rows: true,
    rows_counter: true,
    btn_reset: true,
    status_bar: true,
    msg_filter: 'Filtering...'
};


async function setup_table(data) {
    fillTableFromJson(table, data);
    console.log("created table of length " + table.rows.length);
    return table;
}
async function setup_filter(table) {
    console.log("filtered table of length " + table.rows.length);
    const filter = new TableFilter(table, filtersConfig);
    filter.init();
    return filter;
}

let table = document.querySelector("table");

let filtered_table = fetch_json(groups_url)
    .then(setup_table)
    .then(setup_filter)
;

