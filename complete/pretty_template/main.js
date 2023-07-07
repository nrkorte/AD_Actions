document.addEventListener("DOMContentLoaded", function () {
    var radioButtons = document.querySelectorAll("input[type='radio']");
    radioButtons.forEach(function (radio) {
        radio.addEventListener("change", function () {
            var label = this.previousElementSibling;
            var value = label.textContent;
            var parent = label.parentNode;
            var paragraph = parent.parentNode;
            if (paragraph.textContent.includes("Unauthorized") && value === "Yes") {
                // Create the textarea element
                var textarea = document.createElement("textarea");
                textarea.rows = 4;
                textarea.cols = 30;
                textarea.setAttribute("id", "txtarea");
                textarea.placeholder = "Please describe what unauthorized activity was noticed";

                // Append the textarea below the paragraph
                paragraph.parentNode.insertBefore(textarea, paragraph.nextSibling);
            } else if (paragraph.textContent.includes("Unauthorized") && value === "No") {
                var textareas = document.querySelectorAll('textarea');
                textareas.forEach(function (textarea) {
                    textarea.parentNode.removeChild(textarea);
                });
            }
        });
    });
});
let txtarea_store = "";
let text_store = [];
let radio_store = [];
let image_store = null;

function printit() {

    if (document.getElementById("sys_name").value === "" ||
        document.getElementById("location").value === "" ||
        document.getElementById("sop").value === "" ||
        (!document.getElementById("unauth_no").checked && !document.getElementById("unauth_yes").checked) ||
        (!document.getElementById("clock_no").checked && !document.getElementById("clock_yes").checked) ||
        (!document.getElementById("back_no").checked && !document.getElementById("back_yes").checked) ||
        document.getElementById("quantity").value === "") {
        alert("Fields cannot be left blank!")
        return
    }

    if (document.getElementById("quantity").value !== "0" && document.getElementById("users").value === "") {
        alert("Please mention users that were removed!")
        return
    }

    if (document.getElementById("unauth_yes").checked && document.getElementById("txtarea").value === "") {
        alert("Unauthorized user activity cannot be blank")
        return
    }

    // Convert text fields to text
    var textFields = document.querySelectorAll("input[type='text']");
    let j = 0;
    textFields.forEach(function (field) {
        var text = field.value;
        text_store[j] = text;
        var textNode = document.createTextNode(text);
        field.parentNode.replaceChild(textNode, field);
        j++;
    });

    // Convert radio buttons to text
    var radioButtons = document.querySelectorAll("input[type='radio']");
    let i = 0;
    radioButtons.forEach(function (radio) {
        var label = radio.previousElementSibling;
        if (radio.checked) {
            var value = label.textContent;
            radio_store[i] = value;
            var parent = label.parentNode;
            var paragraph = parent.parentNode;
            parent.remove();
            if (paragraph.textContent.includes("Unauthorized") && value === "Yes") {
                // Create the textarea element
                var textarea = document.createElement("textarea");
                textarea.rows = 4;
                textarea.cols = 30;
                textarea.setAttribute("id", "txtarea");
                textarea.placeholder = "Please describe what unauthorized activity was noticed";

                // Append the textarea below the paragraph
                paragraph.parentNode.insertBefore(textarea, paragraph.nextSibling);

                // Convert textarea to text
                var textareas = document.querySelectorAll("textarea");
                textareas.forEach(function (txt) {
                    var text = txt.value;
                    txtarea_store = text;
                    var textNode = document.createTextNode(text);
                    var paragraph = document.createElement("p");
                    paragraph.appendChild(textNode);
                    txt.parentNode.replaceChild(paragraph, txt);
                });
            }
            paragraph.textContent = paragraph.textContent + value;

        } else {
            radio.parentNode.removeChild(radio);
        }
        i++;

    });
    radio_store = radio_store.filter(Boolean)
    try {
        // Convert file upload to image
        var fileInput = document.getElementById("image");
        var file = fileInput.files[0];
        var reader = new FileReader();
        reader.onload = function (e) {
            var image = document.createElement("img");
            image.onload = function () {
                var canvas = document.createElement("canvas");
                var context = canvas.getContext("2d");
                canvas.width = image.width;
                canvas.height = image.height;
                context.drawImage(image, 0, 0);
                var dataURL = canvas.toDataURL();
                image_store = dataURL;
                if (typeof callback === "function") {
                    callback();
                }
            };
            image.src = e.target.result;
            fileInput.parentNode.replaceChild(image, fileInput);
        };
        reader.readAsDataURL(file);
    } catch (e) {
        try {
            var fileInput = document.getElementById("image");
            fileInput.parentNode.removeChild(fileInput);
        } catch (e) { }
    }


    //hide/show buttons
    document.querySelector('.final').style.display = "none";
    document.querySelector('.copy').style.display = "block";
    document.querySelector('#image_label').style.display = "none";
}

document.addEventListener("DOMContentLoaded", function () {
    var copyButton = document.querySelector('.copy');
    copyButton.addEventListener('click', function () {
        console.log(image_store);
        let value = "Audit Trail Review " + text_store[0] + " at " + text_store[1] + " per " + text_store[2] + "<br><br>"
            + "Unauthorized activity? " + radio_store[0] + "<br><br>"
            + "Clock Correct? " + radio_store[1] + "<br><br>"
            + text_store[3] + " user(s) deactivated: " + text_store[4] + "<br><br>"
            + "Backups working as intended? " + radio_store[2] + "<br><br>";
        // + '<img src="' + image_store + '">';

        if (image_store !== null) {
            value += '<img src="' + image_store + '">';
        }

        copyToClipboard(value);

        function copyToClipboard(value) {
            navigator.clipboard.write([
                new ClipboardItem({
                    'text/html': new Blob([value], { type: 'text/html' })
                })
            ]).then(function () {
                console.log('Content copied to clipboard.');
                document.querySelector('.copy').textContent = "Copied";
            }).catch(function (error) {
                console.log('Failed to copy content to clipboard: ', error);
            });
        }
    });
});