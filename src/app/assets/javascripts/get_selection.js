//= require ISO_639_2.min.js
function getSelectionText() {
    var text = "";
    if (window.getSelection) {
        text = window.getSelection().toString();
    } else if (document.selection && document.selection.type != "Control") {
        text = document.selection.createRange().text;
    }
    setTimeout(function(){ alert(text); }, 0)
    return text;
}