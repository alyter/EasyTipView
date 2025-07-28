/**
 * Copyright (C) 2015 Wasabeef
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
"use strict";

var RE = {};

window.onload = function() {
    RE.callback("ready");
};

RE.editor = document.getElementById('editor');
RE.initialContents = "";

// Not universally supported, but seems to work in iOS 7 and 8
document.addEventListener("selectionchange", function() {
    if (RE.rangeSelectionExists) {
        RE.backuprange();
        RE.callback("selectionChange");
    }
});

//looks specifically for a Range selection and not a Caret selection
RE.rangeSelectionExists = function() {
    //!! coerces a null to bool
    var sel = document.getSelection();
    if (sel && sel.type == "Range") {
        return true;
    }
    return false;
};

RE.rangeOrCaretSelectionExists = function() {
    //!! coerces a null to bool
    var sel = document.getSelection();
    if (sel && (sel.type == "Range" || sel.type == "Caret")) {
        return true;
    }
    return false;
};

RE.editor.addEventListener("input", function() {
    RE.updatePlaceholder();
    RE.backuprange();
    RE.callback("input");
});

RE.editor.addEventListener("focus", function() {
    RE.backuprange();
    RE.callback("focus");
});

RE.editor.addEventListener("blur", function() {
    RE.callback("blur");
});

document.addEventListener("touchend", function() {
    RE.callback("touchend");
});

RE.customAction = function(action) {
    RE.callback("action/" + action);
};

RE.updateHeight = function() {
    RE.callback("updateHeight");
}

RE.callbackQueue = [];
RE.runCallbackQueue = function() {
    if (RE.callbackQueue.length === 0) {
        return;
    }

    setTimeout(function() {
        window.location.href = "re-callback://";
    }, 0);
};

RE.getCommandQueue = function() {
    var commands = JSON.stringify(RE.callbackQueue);
    RE.callbackQueue = [];
    return commands;
};

RE.callback = function(method) {
    RE.callbackQueue.push(method);
    RE.runCallbackQueue();
};

RE.getInitialModifiedHtml = function(contents) {
    //Done to allow newline when already content is present
    var newContents = contents + "<div><br></div>";
    return newContents;
};

RE.setInitialContents = function(contents) {
    var tempWrapper = document.createElement('div');
    tempWrapper.innerHTML = contents;
    RE.initialContents = tempWrapper.innerHTML;
};

RE.setHtml = function(contents) {
    
    RE.setInitialContents(contents);
    
    var newContents = RE.getInitialModifiedHtml(RE.initialContents);
    
    var tempWrapper = document.createElement('div');
    tempWrapper.innerHTML = newContents;
    var images = tempWrapper.querySelectorAll("img");

    for (var i = 0; i < images.length; i++) {
        images[i].onload = RE.updateHeight;
    }

    RE.editor.innerHTML = tempWrapper.innerHTML;
    RE.updatePlaceholder();
};

RE.getHtml = function() {
    
    var initialModifiedHtml = RE.getInitialModifiedHtml(RE.initialContents);
    
    if (RE.editor.innerHTML == initialModifiedHtml) {
        return RE.initialContents;
    } else {
        return RE.editor.innerHTML;
    }
};

RE.getNormalizedHtml = function(keyValues) {
    let elements = document.getElementsByTagName('*');
    
    var i;
    for (i = 0; i < elements.length; i++) {
        let element = elements[i];
        if (element.hasAttribute('src')) {
            let src = element.getAttribute('src');
            
            let originalString = keyValues[src];
            
            if (originalString != null) {
                element.setAttribute("src", originalString);
            }
        }
        
        if (element.style.backgroundImage != null) {
            var backgroundImageUrl = element.style.backgroundImage;
            
            let regex = /(?:url)\s*\((?:'|")(.*?)(?:'|")\)/;
            
            let urlMatches = regex.exec(backgroundImageUrl);

            if (urlMatches !== null) {
                urlMatches.forEach((match, groupIndex) => {
                    
                    let originalString = keyValues[match];
                    
                    if (originalString != null) {
                        element.style.backgroundImage = "url('"+ originalString +"')";
                    }

                    console.log(`Found match, group ${groupIndex}: ${match}`);
                });
            }
        }
    }
    
    return RE.getHtml();
};

RE.findAndReplaceUrl = function(findString, replaceString) {
    let elements = document.getElementsByTagName('*');
    
    var i;
    for (i = 0; i < elements.length; i++) {
        let element = elements[i];
        if (element.hasAttribute('src')) {
            let src = element.getAttribute('src');
            
            if (src == findString) {
                element.setAttribute("src", replaceString);
            }
        }
        
        if (element.style.backgroundImage != null) {
            var backgroundImageUrl = element.style.backgroundImage;
            
            let regex = /(?:url)\s*\((?:'|")(.*?)(?:'|")\)/;
            
            let urlMatches = regex.exec(backgroundImageUrl);

            if (urlMatches !== null) {
                urlMatches.forEach((match, groupIndex) => {
                                        
                    if (match == findString) {
                        element.style.backgroundImage = "url('"+ replaceString +"')";
                    }

                    console.log(`Found match, group ${groupIndex}: ${match}`);
                });
            }
        }
    }
};

RE.decodeSting = function(encodedStr) {
    
    var parser = new DOMParser;
    var dom = parser.parseFromString(
        '<!doctype html><body>' + encodedStr,
        'text/html');
    var decodedString = dom.body.textContent;
    return decodedString;

};

RE.getText = function() {
    return RE.editor.innerText;
};

RE.setBaseTextColor = function(color) {
    RE.editor.style.color  = color;
};

RE.setPlaceholderText = function(text) {
    RE.editor.setAttribute("placeholder", text);
};

RE.updatePlaceholder = function() {
    if (RE.editor.innerHTML.indexOf('img') !== -1 || (RE.editor.textContent.length > 0 && RE.editor.innerHTML.length > 0)) {
        RE.editor.classList.remove("placeholder");
    } else {
        RE.editor.classList.add("placeholder");
    }
};

RE.removeFormat = function() {
    document.execCommand('removeFormat', false, null);
};

RE.setFontSize = function(size) {
    RE.editor.style.fontSize = size;
};

RE.setBackgroundColor = function(color) {
    RE.editor.style.backgroundColor = color;
};

RE.setHeight = function(size) {
    RE.editor.style.height = size;
};

RE.undo = function() {
    document.execCommand('undo', false, null);
};

RE.redo = function() {
    document.execCommand('redo', false, null);
};

RE.setBold = function() {
    document.execCommand('bold', false, null);
};

RE.setItalic = function() {
    document.execCommand('italic', false, null);
};

RE.setSubscript = function() {
    document.execCommand('subscript', false, null);
};

RE.setSuperscript = function() {
    document.execCommand('superscript', false, null);
};

RE.setStrikeThrough = function() {
    document.execCommand('strikeThrough', false, null);
};

RE.setUnderline = function() {
    document.execCommand('underline', false, null);
};

RE.setTextColor = function(color) {
    RE.restorerange();
    document.execCommand("styleWithCSS", null, true);
    document.execCommand('foreColor', false, color);
    document.execCommand("styleWithCSS", null, false);
};

RE.setTextBackgroundColor = function(color) {
    RE.restorerange();
    document.execCommand("styleWithCSS", null, true);
    document.execCommand('hiliteColor', false, color);
    document.execCommand("styleWithCSS", null, false);
};

RE.setTextFontFamily = function(family) {
    document.execCommand('fontName', false, family);
};

RE.setTextFontSize = function(size) {
    document.execCommand('fontSize', false, size);
};

RE.isCommandEnabled = function(commandName) {
    return document.queryCommandState(commandName);
};

RE.getCommandValue = function(commandName) {
    if(commandName == 'foreColor') {
        let value = document.queryCommandValue(commandName);
        return RE.rgbaTohex(value);
    } else if(commandName == 'hiliteColor') {
        
        let value = document.queryCommandValue('backColor');
        if(value == null) {
            document.execCommand("styleWithCSS", null, true);
            let hiliteValue = document.queryCommandValue('hiliteColor');
            document.execCommand("styleWithCSS", null, false);
            return RE.rgbaTohex(hiliteValue);
        }
        
        return RE.rgbaTohex(value);
    } else {
        return document.queryCommandValue(commandName);
    }
};

RE.setHeading = function(heading) {
    document.execCommand('formatBlock', false, '<h' + heading + '>');
};

RE.setIndent = function() {
    document.execCommand('indent', false, null);
};

RE.setOutdent = function() {
    document.execCommand('outdent', false, null);
};

RE.setOrderedList = function() {
    document.execCommand('insertOrderedList', false, null);
};

RE.setUnorderedList = function() {
    document.execCommand('insertUnorderedList', false, null);
};

RE.setJustifyLeft = function() {
    document.execCommand('justifyLeft', false, null);
};

RE.setJustifyCenter = function() {
    document.execCommand('justifyCenter', false, null);
};

RE.setJustifyRight = function() {
    document.execCommand('justifyRight', false, null);
};

RE.setJustifyFull = function() {
    document.execCommand('justifyFull', false, null);
};

RE.getLineHeight = function() {
    return RE.editor.style.lineHeight;
};

RE.setLineHeight = function(height) {
    RE.editor.style.lineHeight = height;
};

RE.setHorizontalRule = function() {
    document.execCommand('insertHorizontalRule', false, null );
};

RE.insertImage = function(url, alt) {
    var img = document.createElement('img');
    img.setAttribute("src", url);
    img.setAttribute("alt", alt);
    img.onload = RE.updateHeight;

    RE.insertHTML(img.outerHTML);
    RE.callback("input");
};

RE.setBlockquote = function() {
    document.execCommand('formatBlock', false, '<blockquote>');
};

RE.insertHTML = function(html) {
    RE.restorerange();
    document.execCommand('insertHTML', false, html);
};

RE.insertLink = function(url, title, selectedText) {
    RE.restorerange();
    var sel = document.getSelection();
    let selectionString = sel.toString();
    let hasSelection = (selectionString.length !== 0) && (sel.rangeCount);
    var el = document.createElement("a");
    el.setAttribute("href", url);
    if (title.length != 0) {
        el.setAttribute("title", title);
    }

    if (hasSelection) {
        if (selectionString == selectedText) {
            var range = sel.getRangeAt(0).cloneRange();
            range.surroundContents(el);
            range.selectNodeContents(el);
            sel.removeAllRanges();
            sel.addRange(range);
        } else {
            el.innerHTML = selectedText;
            
            var range = sel.getRangeAt(0).cloneRange();
            range.deleteContents();
            sel.focusNode.parentNode.appendChild(el);
            range.insertNode(el);
            range.selectNodeContents(el);
            sel.removeAllRanges();
            sel.addRange(range);
        }
    } else {
        el.innerHTML = selectedText;
        var range = sel.getRangeAt(0).cloneRange();
        sel.focusNode.parentNode.appendChild(el);
        range.insertNode(el);
        range.setStartAfter(el);
        sel.removeAllRanges();
        sel.addRange(range);
    }
    RE.callback("input");
    return hasSelection;
}

RE.insertEmail = function(email, subject, selectedText) {
    RE.restorerange();
    var sel = document.getSelection();
    let selectionString = sel.toString();
    let hasSelection = (selectionString.length !== 0) && (sel.rangeCount);
    var el = document.createElement("a");
    el.setAttribute("href", email);
    if (subject.length != 0) {
        el.setAttribute("subject", subject);
    }
    
    if (hasSelection) {
        if (selectionString == selectedText) {
            var range = sel.getRangeAt(0).cloneRange();
            range.surroundContents(el);
            range.selectNodeContents(el);
            sel.removeAllRanges();
            sel.addRange(range);
        } else {
            el.innerHTML = selectedText;
            
            var range = sel.getRangeAt(0).cloneRange();
            range.deleteContents();
            sel.focusNode.parentNode.appendChild(el);
            range.insertNode(el);
            range.selectNodeContents(el);
            sel.removeAllRanges();
            sel.addRange(range);
        }
    } else {
        el.innerHTML = selectedText;
        var range = sel.getRangeAt(0).cloneRange();
        sel.focusNode.parentNode.appendChild(el);
        range.insertNode(el);
        range.setStartAfter(el);
        sel.removeAllRanges();
        sel.addRange(range);
    }
    RE.callback("input");
    return hasSelection;
};

RE.selectedText = function() {
    var text = "";
    if (window.getSelection) {
        text = window.getSelection().toString();
    } else if (document.selection && document.selection.type != "Control") {
        text = document.selection.createRange().text;
    }
    return text;
};

RE.selectedHref = function() {
    var href = "";
    let sel = window.getSelection();
    if(sel.focusNode.parentNode.tagName == 'A') {
        href = sel.focusNode.parentNode.getAttribute('href');
    }
    return href;
};

RE.selectedSubject = function() {
    var subject = "";
    let sel = window.getSelection();
    if(sel.focusNode.parentNode.tagName == 'A') {
        subject = sel.focusNode.parentNode.getAttribute('subject');
    }
    return subject;
};

RE.prepareInsert = function() {
    RE.backuprange();
};

RE.backuprange = function() {
    var selection = window.getSelection();
    if (selection.rangeCount > 0) {
        var range = selection.getRangeAt(0);
        RE.currentSelection = {
            "startContainer": range.startContainer,
            "startOffset": range.startOffset,
            "endContainer": range.endContainer,
            "endOffset": range.endOffset
        };
    }
};

RE.restorerange = function() {
    var selection = window.getSelection();
    selection.removeAllRanges();
    var range = document.createRange();
    range.setStart(RE.currentSelection.startContainer, RE.currentSelection.startOffset);
    range.setEnd(RE.currentSelection.endContainer, RE.currentSelection.endOffset);
    selection.addRange(range);
};

RE.focusRestoringRange = function() {
    var range = document.createRange();
    range.setStart(RE.currentSelection.startContainer, RE.currentSelection.startOffset);
    range.setEnd(RE.currentSelection.endContainer, RE.currentSelection.endOffset);

    var selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);

    RE.editor.focus();
};

RE.focus = function() {
    var range = document.createRange();
    range.selectNodeContents(RE.editor);
    range.collapse(false);

    var selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);

    RE.editor.focus();
};

RE.focusAtPoint = function(x, y) {
    var range = document.caretRangeFromPoint(x, y) || document.createRange();
    var selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    RE.editor.focus();
};

RE.blurFocusBackingUpRange = function() {
    RE.backuprange();
    RE.editor.blur();
};

RE.blurFocus = function() {
    RE.editor.blur();
};

RE.getAllColors = function() {
    var rgbRegex = /^rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*(\d+(?:\.\d+)?))?\)$/;
    
    var allColors = [];
    
    var elems = document.getElementsByTagName('*');
    var total = elems.length;
    
    var x,y,elemStyles,styleName,styleValue,rgbVal;
    
    for(x = 0; x < total; x++) {
        elemStyles = window.getComputedStyle(elems[x]);
        
        for(y = 0; y < elemStyles.length; y++) {
            styleName = elemStyles[y];
            styleValue = elemStyles[styleName];
            
            if(!styleValue) {
                continue;
            }
            
            if(styleName != "background-color" && styleName != "color") {
                continue;
            }
            
            // convert to string to avoid match exceptions
            styleValue += "";
            
            rgbVal = styleValue.match(rgbRegex);
            if(!rgbVal) { // property does not contain a color
                continue;
            }
                  
            let hexValue = RE.rgbaTohex(rgbVal.input)
            
            if(allColors.indexOf(hexValue) == -1) { // avoid duplicate entries
                allColors.push(hexValue);
            }
            
        }
        
    }
    
    return allColors;
}

RE.rgbaTohex = function(orig) {
  var a, isPercent,
    rgb = orig.replace(/\s/g, '').match(/^rgba?\((\d+),(\d+),(\d+),?([^,\s)]+)?/i),
    alpha = (rgb && rgb[4] || "").trim(),
    hex = rgb ?
    (rgb[1] | 1 << 8).toString(16).slice(1) +
    (rgb[2] | 1 << 8).toString(16).slice(1) +
    (rgb[3] | 1 << 8).toString(16).slice(1) : orig;

//  if (alpha !== "") {
//    a = alpha;
//  } else {
//    a = 01;
//  }
//  // multiply before convert to HEX
//  a = ((a * 255) | 1 << 8).toString(16).slice(1)
//  hex = hex + a;

  return "#" + hex;
}

/**
Recursively search element ancestors to find a element nodeName e.g. A
**/
var _findNodeByNameInContainer = function(element, nodeName, rootElementId) {
    if (element.nodeName == nodeName) {
        return element;
    } else {
        if (element.id === rootElementId) {
            return null;
        }
        _findNodeByNameInContainer(element.parentElement, nodeName, rootElementId);
    }
};

var isAnchorNode = function(node) {
    return ("A" == node.nodeName);
};

RE.getAnchorTagsInNode = function(node) {
    var links = [];

    while (node.nextSibling !== null && node.nextSibling !== undefined) {
        node = node.nextSibling;
        if (isAnchorNode(node)) {
            links.push(node.getAttribute('href'));
        }
    }
    return links;
};

RE.countAnchorTagsInNode = function(node) {
    return RE.getAnchorTagsInNode(node).length;
};

/**
 * If the current selection's parent is an anchor tag, get the href.
 * @returns {string}
 */
RE.getSelectedHref = function() {
    var href, sel;
    href = '';
    sel = window.getSelection();
    if (!RE.rangeOrCaretSelectionExists()) {
        return null;
    }

    var tags = RE.getAnchorTagsInNode(sel.anchorNode);
    //if more than one link is there, return null
    if (tags.length > 1) {
        return null;
    } else if (tags.length == 1) {
        href = tags[0];
    } else {
        var node = _findNodeByNameInContainer(sel.anchorNode.parentElement, 'A', 'editor');
        href = node.href;
    }

    return href ? href : null;
};

// Returns the cursor position relative to its current position onscreen.
// Can be negative if it is above what is visible
RE.getRelativeCaretYPosition = function() {
    var y = 0;
    var sel = window.getSelection();
    if (sel.rangeCount) {
        var range = sel.getRangeAt(0);
        var needsWorkAround = (range.startOffset == 0)
        /* Removing fixes bug when node name other than 'div' */
        // && range.startContainer.nodeName.toLowerCase() == 'div');
        if (needsWorkAround) {
            y = range.startContainer.offsetTop - window.pageYOffset;
        } else {
            if (range.getClientRects) {
                var rects=range.getClientRects();
                if (rects.length > 0) {
                    y = rects[0].top;
                }
            }
        }
    }

    return y;
};

RE.checkAndAddBRElement = function() {
    if (RE.editor.lastChild.tagName != "BR") {
        let brElement = document.createElement('br');
        RE.editor.appendChild(brElement);
    }
};

RE.containsTag = function(tagName, node) {
    if(node == null) {
        return false;
    } else if (node.tagName == tagName) {
        return true;
    } else {
        return RE.containsTag(tagName, node.parentNode);
    }
};

RE.getNodeByTagName = function(tagName, node) {
    if(node == null) {
        return null;
    } else if (node.tagName == tagName) {
        return node;
    } else {
        return RE.getNodeByTagName(node.parentNode);
    }
}

RE.insertBlockQuote  = function () {
    
    var sel = document.getSelection();
    
    let containsBlockQuote = RE.containsTag('BLOCKQUOTE', sel.focusNode);
    let hasSelection = (sel.toString().length !== 0) && (sel.rangeCount);
    
    if (containsBlockQuote == false) {
        var blockQuote = document.createElement("blockquote");
        blockQuote.style.border = 'thin';
        blockQuote.style.backgroundColor = '#F0F0F0';
        blockQuote.style.borderStyle = 'solid';
        blockQuote.style.borderWidth = 'thin';
        blockQuote.style.borderColor = '#BCBCBC';
        blockQuote.style.padding = '7px';

        if (hasSelection) {
            let textNode = document.createTextNode(sel.toString());
            blockQuote.appendChild(textNode);
        } else {
            let textNode = document.createTextNode('\u0020');
            blockQuote.appendChild(textNode);
        }
        
        blockQuote.onload = RE.updateHeight;
        
        var range = sel.getRangeAt(0).cloneRange();
        range.surroundContents(blockQuote);
        if (!hasSelection) {
            range.selectNodeContents(blockQuote);
            range.collapse(true);
        }
        sel.removeAllRanges();
        sel.addRange(range);
        RE.checkAndAddBRElement();
        RE.callback("input");
    }
}

RE.isElementEmpty = function (node) {
    if (node.textContent === "" || node.textContent == null) {
        return true;
    } else {
        return false;
    }
}

RE.insertList = function() {
    var sel = document.getSelection();
    let containsList = RE.containsTag('UL', sel.focusNode);
    let hasSelection = (sel.toString().length !== 0) && (sel.rangeCount);
    
    if (containsList == false) {
        
        var ulist = document.createElement('ul');
        ulist.style.listStylePosition = 'outside';
        ulist.style.listStyleType = 'decimal';
        ulist.style.padding = '0px 30px';
        
        var list = document.createElement('li');
        list.style.listStylePosition = 'outside';
        list.style.listStyleType = 'decimal';
        list.style.padding = '2px';
        list.style.margin = '1px 0px';
        list.style.backgroundColor = 'rgb(245, 245, 245)';
        list.style.borderLeft = '2px solid rgb(204, 204, 204)';
                
        var range = sel.getRangeAt(0).cloneRange();
        range.surroundContents(list);
        range.surroundContents(ulist);

        ulist.onload = RE.updateHeight;

        if (!hasSelection) {
            range.selectNodeContents(list);
            range.collapse(true);
        }
        sel.removeAllRanges();
        sel.addRange(range);
        RE.callback("input");
    }
}

RE.insertTable = function (rowCount,columnCount,wordWrap,borderWidth,isWidthInPercentage, width) {
    RE.restorerange();

    var sel = document.getSelection();

    var tbl = document.createElement('table');
    tbl.border = borderWidth.toString();
    tbl.cellSpacing = "2";
    tbl.cellPadding = "2";
//    tbl.style.borderCollapse = 'separate';
//    tbl.style.borderSpacing = '5px';
    tbl.style.border = borderWidth.toString().concat("px solid black");
    
    if (isWidthInPercentage == "true") {
        tbl.style.width = width.concat("%");
    } else {
        tbl.style.width = width.concat("px");
    }
    
    var tbdy = document.createElement('tbody');
    for (var i = 0; i < rowCount; i++) {
        var tr = document.createElement('tr');
        for (var j = 0; j < columnCount; j++) {
            var td = document.createElement('td');
            td.appendChild(document.createTextNode('\u0020'))
            var widthPercentage = 100 / columnCount;
            var widthPerncetageString = widthPercentage.toString().concat("%");
            td.style.width = widthPerncetageString;
            if (wordWrap == "true") {
                td.style.wordWrap = "break-word";
            }
            tr.appendChild(td);
        }
        tbdy.appendChild(tr);
    }
    tbl.appendChild(tbdy);
    tbl.onload = RE.updateHeight;
    
    var range = sel.getRangeAt(0).cloneRange();

    sel.focusNode.parentNode.appendChild(tbl);
    range.insertNode(tbl);
    
    range.setStartAfter(tbl);
    range.collapse(true);
    sel.removeAllRanges();
    sel.addRange(range);

    RE.checkAndAddBRElement();
    RE.callback("input");
}

RE.insertColumnRight = function (action)  {
    // editor.win.focus();
    var current_row = RE.get_current_row();
    if (!current_row) {
        return;
    }

    /* Extracting column attributes if any */
    var current_column = RE.get_current_column();
    var colStyleAttrs = current_column.getAttribute("style");
    var length = 0;
    var colBorderAttr = {};
    if (colStyleAttrs) {
    var colIndAttr = colStyleAttrs.split(";");
    length = colIndAttr.length;
    var colStyAtt;
    colBorderAttr.borderWidth = current_row.parentElement.firstChild.firstChild.style.borderWidth;
    colBorderAttr.borderStyle = current_row.parentElement.firstChild.firstChild.style.borderStyle;
    }
    /* Extracting column attributes if any */

    var currentPos = RE.getPosition(current_row, current_column);
    var tbody = current_row.parentNode;
    var tr_list = tbody.getElementsByTagName("TR");
    var _length = tr_list.length;
    for (i = 0; i < _length; i++)   {
        var td_list = tr_list[i].children;
        var tdElem = document.createElement("td");

        /* Apply column style attributes if any */
        if (length > 0) {
            tdElem.style.width = current_row.offsetWidth + "px";
        }
        for (var p = 0 ; p < length ; p++) {
            colStyAtt = colIndAttr[p].split(":");
            if (colStyAtt[0].trim().length > 0) {
            tdElem.style[colStyAtt[0].trim()] = colStyAtt[1].trim();
            }
        }
        for (p = 0 ; p < Object.keys(colBorderAttr).length ; p++){
            tdElem.style.borderWidth = colBorderAttr.borderWidth;
            tdElem.style.borderStyle = colBorderAttr.borderStyle;
         }
        /* Apply column style attributes if any */

         /* Merge columns check */

        var divElem = document.createElement("div");
        divElem.appendChild(document.createElement("br"));
        tdElem.appendChild(divElem);
        if (td_list[currentPos]){
        tr_list[i].insertBefore(tdElem, td_list[currentPos].nextSibling);
        } else if (td_list[td_list.length - 1]){
            tr_list[i].insertBefore(tdElem, td_list[td_list.length - 1].nextSibling);
        }

        
    }
                                 
//                                 console.log("tbodytbodytbody");
//                                 console.log(tbody);
//    if (action !== 'noHide'){
//        hideContextMenu();
//      }
//    editor.saveCurrentState();
};

RE.insertColumnLeft = function (action) {
    // editor.win.focus();
    current_row = RE.get_current_row();
    if (!current_row) {
        return;
    }

    /* Extracting the column style attributes if any */
    var current_column = RE.get_current_column();
    var colStyleAttrs = current_column.getAttribute("style");
    var length = 0;
    var colBorderAttr = {};
    if (colStyleAttrs) {
    var colIndAttr = colStyleAttrs.split(";");
    length = colIndAttr.length;
    var colStyAtt;
    colBorderAttr.borderWidth = current_row.parentElement.firstChild.firstChild.style.borderWidth;
    colBorderAttr.borderStyle = current_row.parentElement.firstChild.firstChild.style.borderStyle;
    }
    /* Extracting the column style attributes if any */

    var currentPos = RE.getPosition(current_row, current_column);
    var tbody = current_row.parentNode;
    var tr_list = tbody.getElementsByTagName("TR");
    _length = tr_list.length;
    for (i = 0; i < _length; i++)   {
        var td_list = tr_list[i].children;
        var tdElem = document.createElement("td");

        /* Apply style attributes to column */
        if (length > 0) {
            tdElem.style.width = current_row.offsetWidth + "px";
        }

        for (var p = 0 ; p < length ; p++) {
            colStyAtt = colIndAttr[p].split(":");
            if (colStyAtt[0].trim().length > 0) {
            tdElem.style[colStyAtt[0].trim()] = colStyAtt[1].trim();
            }
        }
        for (p = 0 ; p < Object.keys(colBorderAttr).length ; p++){
            tdElem.style.borderWidth = colBorderAttr.borderWidth;
            tdElem.style.borderStyle = colBorderAttr.borderStyle;
         }
        /* Apply style attributes to column */

        /* Merge columns check */

        var divElem = document.createElement("div");
        divElem.appendChild(document.createElement("br"));
        tdElem.appendChild(divElem);
        tr_list[i].insertBefore(tdElem, td_list[currentPos]);


    //     var previousColPos;

    //     var colList = constructColspanObj(td_list);
    //      var curIndex = getCurrentColumn(currentPos , colList);

    //      if (curIndex && colList[curIndex].length > 1){
    //          previousColPos = curIndex;
    //      }

    //     if (
    //         !td_list[currentPos] &&
    //          td_list[previousColPos] &&
    //         td_list[previousColPos].hasAttribute("colspan")){
    //         var colspan = parseInt(td_list[previousColPos].getAttribute("colspan")) + 1;
    //         td_list[previousColPos].setAttribute("colspan", colspan);
    //         /* Merge columns check */
    //     } else {
    //     var divElem = document.createElement("div");
    //     divElem.appendChild(document.createElement("br"));
    //     tdElem.appendChild(divElem);
    //     tr_list[i].insertBefore(tdElem, td_list[currentPos]);
    // }
    }
    // if (action !== 'noHide'){
    //     hideContextMenu();
    //   }
    // editor.saveCurrentState();
};

RE.get_current_column = function () {
        var _target = RE.contextMenuTarget;
        if (_target.nodeName != "TD") {
            for (; _target !== null; _target = _target.parentNode) {
                if (_target.nodeName == "TD" || _target.nodeName == "TH") {
                    break;
                }
            }
        }
        return _target;
};

RE.get_current_row = function () {
        var _target = RE.contextMenuTarget;
        if (_target.nodeName != "TR") {
            for (; _target !== null; _target = _target.parentNode) {
                if (_target.nodeName == "TR") {
                    break;
                }
            }
        }
        return _target;
};

RE.getPosition = function (_current_row, _current_column)  {
        var td_list = _current_row.children;
        _length = td_list.length;
        for (i = 0; i < _length; i++)   {
            if (_current_column === td_list[i])     {
                return i;
            }
        }
};

RE.tableWidthCalculation = function (table) {
    var _table = table;
    var _tabWidth = _table.offsetWidth;
    var tr = _table.getElementsByTagName("TR");
    var td = tr[0].getElementsByTagName("TD");
    var tdLen = td.length;
    var trLen = tr.length;
    var tdWidth = _tabWidth / tdLen;
    for (var i = 0 ; i < trLen; i++) {
        for (var j = 0; j < tdLen; j++) {
            tr[i].getElementsByTagName("TD")[j].style.width = tdWidth + "px";
        }
    }
};
