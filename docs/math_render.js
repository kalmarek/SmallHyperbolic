function prepareTextForKatex(string) {
    return string.replace(/ /g, "")
        .replace(/\*/g, "")
        .replace(/\^-1/g, "^{-1}")
        .replace(/inf/g, "\\infty");
}

function createMathSpan(content) {
    let item = document.createElement("span");
    item.className = "math";

    let math_text = document.createElement("span");
    let math_tex = document.createElement("span");

    math_text.className = "math-text";
    math_text.innerText = content.toString().replace(/\*/g, "").replace(/ /g, "")

    math_tex.className = "math-tex";
    katex.render(prepareTextForKatex(math_text.innerText), math_tex);

    item.appendChild(math_text);
    item.appendChild(math_tex);

    return item;
}

function toggleKaTeX(elt, toggle) {
    let display_text = toggle ? "none" : "revert";
    let display_tex = toggle ? "revert" : "none";
    for (let child of elt.childNodes) {
        switch (child.className) {
            case "math-text":
                child.style.display = display_text;
                break;
            case "math-tex":
                child.style.display = display_tex;
                break;
            default:
            // nothing
        }
    }
}

let math_objects = document.getElementsByClassName("math");
let katex_switch = document.getElementById("renderWithKatex");
katex_switch.checked = false;
katex_switch.addEventListener(
    "change",
    function () {
        let toggle = this.checked;
        for (let element of math_objects) {
            toggleKaTeX(element, toggle);
        }
    }
);
