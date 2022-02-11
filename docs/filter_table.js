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
        at_start: [1,3,5,6,7,8,18,19,20,21],
        text: 'Hidden Columns: ',
        enable_tick_all: true
    }, {
        name: 'sort'
    }]
};

async function setup_filter(table) {
    console.log("filtered table of length " + table.rows.length);
    const filter = new TableFilter(table, filtersConfig);
    filter.init();
    return filter;
}
