function columnName(key) {
    let words = key.split("_");
    for (let i = 0; i < words.length; i++) {
        words[i][0] = words[i][0].toUpperCase();
    }
    return words.join(" ");
}

function generateTableHead(table, keys) {
    let thead = table.createTHead();
    let row = thead.insertRow();
    for (let key of keys) {
        let th = document.createElement("th");
        let text = document.createTextNode(columnName(key));
        th.appendChild(text);
        row.appendChild(th);
    }
}

function createDetails(object, summary_text = "show…", open = false) {
    let details = document.createElement("details");

    let summary = document.createElement("summary");
    summary.textContent = summary_text;

    details.appendChild(summary);
    details.appendChild(object);
    return details;
}

function createListFromJson(json, ismath = false) {
    let list = document.createElement("ul");
    for (let [k, v] of Object.entries(json)) {
        let item = document.createElement("li");
        if (ismath) {
            let math = createMathSpan(k + " : " + v);
            item.appendChild(math);
        } else {
            item.innerText = k + " : " + v;
        }
        list.appendChild(item);
    }
    return list
}

function createSpansFromArray(arr, ismath = false) {
    let list = document.createElement("span");
    if (arr == null) {
        return list;
    }
    for (let i = 0; i < arr.length; i++) {
        let item;
        if (ismath) {
            item = createMathSpan(arr[i]);
        } else {
            item = document.createElement("span");
            item.innerText = String(arr[i]);
        }

        list.appendChild(item);
        if (i != arr.length - 1) {
            let comma = document.createElement("span");
            comma.innerText = ", ";
            list.appendChild(comma);
        }
    }
    return list;
}

function fillRow(row, group_json) {
    for (let key of Object.keys(group_json)) {
        let cell = row.insertCell();
        let cell_content;
        let val = group_json[key];
        switch (key) {
            case "name":
                cell_content = createMathSpan(val);
                break;
            case "quotients":
                cell_content = createDetails(createListFromJson(val, ismath = true));
                break;
            case "quotients_utf8":
                cell_content = createDetails(createListFromJson(val));
                break;
            case "quotients_plain":
                cell_content = createListFromJson(val);
                break;
            case "generators":
                cell_content = createSpansFromArray(val,);
                break;
            case "relations":
                cell_content = createDetails(createSpansFromArray(val, ismath = true));
                break;
            case "witnesses_non_hyperbolictity":
                cell_content = createSpansFromArray(val, ismath = true);
                break;
            case "L2_quotients":
                cell_content = createSpansFromArray(val, ismath = true);
                break;
            case "alternating_quotients":
                cell_content = createDetails(createSpansFromArray(val));
                break;
            default:
                cell_content = document.createTextNode(val);
        }
        cell.appendChild(cell_content);
    }
    return row
}

function fillTableFromJson(table, json) {
    let keys = Object.keys(json[0]);
    for (let group of json) {
        let row = table.insertRow();
        fillRow(row, group);
    }
    generateTableHead(table, keys);
}

async function setup_table(data) {
    let table = document.querySelector("table");
    fillTableFromJson(table, data);
    console.log("created table of length " + table.rows.length);
    return table;
}
