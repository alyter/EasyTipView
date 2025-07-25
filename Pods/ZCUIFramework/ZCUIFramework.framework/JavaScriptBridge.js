
// Variables in the files are used as ${var_name}

function divComponentOnClick(requestUrlString)
{
    var dict = {urlString:requestUrlString};
    webkit.messageHandlers.divComponent.postMessage(dict);
};

function iframeWithWindowOnClick(hyperLink,windowType)
{
    var dict = {link:hyperLink , window:windowType};
    webkit.messageHandlers.iframeOnClick.postMessage(dict);
};

function printPDFView(action)
{
    var dict = {actionToPerform:action };
    webkit.messageHandlers.PrintPDFOnClick.postMessage(dict);
};

function iframeClick(sourceURL)
{
    var dict = {source : sourceURL};
    webkit.messageHandlers.iframeClick.postMessage(dict);
};

function evaulateHeight(sourceURL)
{
    var dict = {source : sourceURL};
    webkit.messageHandlers.EvaluateHeight.postMessage(dict);
};
