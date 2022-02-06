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

function filter_group_json(obj) {
    for (let key of Object.keys(obj)) {
        if (key.match(/utf8/) != null) {
            delete obj[key];
        }
    }
    return obj
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
        // swtich(key){
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
    for (let i=0; i<json.length; i++) {
        json[i] = filter_group_json(json[i]);
    }
    let keys = Object.keys(json[0]);
    for (let group of json) {
        let row = table.insertRow();
        fillRow(row, group);
    }
    generateTableHead(table, keys);
}

function rerender_with_katex(elt) {
    let txt = elt.textContent;
    if (txt != null && txt != ""  && txt != "null") {
        let txt = elt.textContent
            .replace(/\*/g, "")
            .replace(/-1/g, "{-1}")
            .replace(/inf/g, "\\infty")
            ;
        katex.render(txt, elt);
    }
}

function rerender_columns_katex(table, columns = [
        "name",
        "generators",
        "relations",
        "witnesses non hyperbolictity",
        "L2 quotients",
    ]) {
    let header = table.rows[0];
    let column_indices = [];

    for (let col_idx = 0; col_idx < header.cells.length; col_idx++) {
        let label = header.cells[col_idx].textContent;
        let found = columns.indexOf(label);
        if (found >= 0) {
            column_indices.push(col_idx);
            columns.splice(found, 1);
        }
    }

    if (columns.length != 0) {
        console.log("In Katexify: some columns were not found! " + columns);
    }

    for (let col_idx of column_indices) {
        // we're skipping the header row
        for (let row of table.rows) {
            if ( row == header ) { continue; }
            rerender_with_katex(row.cells[col_idx]);
        }
    }

    return table
}

const filtersConfig = {
    base_path: 'tablefilter/',
    auto_filter: {
                    delay: 400
                },
    filters_row_index: 1,
    highlight_keywords: true,
    responsive: true,
    state: true,
    sticky_headers: true,
    // popup_filters: true,
    no_results_message: true,
    alternate_rows: true,
    mark_active_columns: true,
    rows_counter: true,
    btn_reset: true,
    status_bar: true,
    msg_filter: 'Filtering...',
    extensions: [{
        name: 'colsVisibility',
        at_start: [2,4,5,6,7,15],
        text: 'Hidden Columns: ',
        enable_tick_all: true
    }, {
        name: 'sort'
    }]
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

let button = document.getElementById("katexify");
button.addEventListener("click", ()=>{
    rerender_columns_katex(table);
    button.disabled = true;
});
