
$(document).delegate("div", "pageinit", function(e) {
    page = $(this)
    customizeHeader(page)
    page.page()
});

function customizeHeader(page)
{
    // updatethe title using the page propertiues
    // var page_title = page.attr("data-dexhdr-title")
    // if(typeof page_title == "string") {
    //     page.find(".dex-page-title").text(page_title)
    // }
    // remove this page from the menu in the header
    var menu = page.find(".dex-page-menu")
    pageId = page.attr("id")
    query = "a[href='#"+pageId+"']"
    menu.find(query).parents("li").hide()
    // hide the filter by default
    page.find("form.ui-listview-filter").hide()
};

$(document).on("pageinit", "#component", function(e) {
    var page = $(this)
    return home(page)
});

var refreshTimer = 0

$(document).on("click", "a", function(e){
    at = $(this).attr("data-dex-ref")
    if(at) {
        page = $(".ui-page-active")
        navigate(page, at)
        //e.preventDefault()
        //return false
    }
    // not one of our links process normally
    return true
});

function stopRefresh()
{
    if(refreshTimer != 0){
        clearTimeout(refreshTimer)
        refreshTimer = 0
    }
}

function appendParameter(url, name, value) {
    if(value && value.length){
        if(url.indexOf("?") != -1) {
            url += "&"
        }else{
            url += "?"
        }
        url += name + "=" +value
    }
    return url
}

function getApiData(page, dataref, append, position) {
    var url = '/api' + dataref
    url = appendParameter(url, "position", position)
    console.log("GET: "+ url)
    $.ajax({
        type: "GET",
        url: url,
        async: true,
        error: function(jqxhr, error, ex) { alert("failed to get " + url) },
        success: function(response,textStatus, jqxhr){ processResponse(page, response, dataref, append)}
    });
}


function navigate(page, dataref){
    stopRefresh()
    $.mobile.loading('show')
    filterReset(page)
    getApiData(page, dataref, false, null)
}

function home(page) {
    return navigate(page, "/")
}


function timedRefresh(page, dataref, position) {
    return getApiData(page, dataref, true, position)
}

function empty_result(result) {
    has_body =  result["body"] && result["body"].length > 0
    return !has_body
}

function processResponse(page, response, dataref, append ) {
    res = page.find(".dex-component-output")
    list = page.find(".dex-component-menu")
    var result = JSON.parse(response)
    result_type = result["type"]
    // if url then navigte to it and leave this page as is
    if(result_type == "url") {
        $.mobile.loading('hide')
        window.location.href = result["body"]
        return false
    }
    append || page.find(".dex-page-title").text(result["title"])
    // if menu hide res show list and construct
    if(result_type == "menu") {
        if(!append) {
            res.hide()
            list.show()
        }
        componentListHtml(page, result, list, append)
    }
    // if log activate res and insert hide list
    if(result_type == "log") {
        list.hide()
        res.show()
        if(append) {
            res.find('pre').append(result["body"])
        }else{
            res.html("<pre style='overflow:auto;'>" + result["body"] + "</pre>")
        }
    }
    // if html activate res and insert hide list
    if(result_type == "html" || result_type == "error" ) {
        list.hide()
        res.show()
        if(append) {
            res.append(result["body"])
        }else{
            res.html(result["body"])
        }
    }
    if(result["position"]) {
        var delay = empty_result(result) ? 5000 : 1000
        var position = result["position"]
        refreshTimer = setTimeout(function() { timedRefresh(page, dataref, position)}, delay)
    }
    if(!append) {
        // move to the top of the page
        $.mobile.silentScroll(0)
        // reset the filter
        $.mobile.loading('hide')
        // update the refresh button to point at the current reference
        page.find(".dex-page-refresh").attr("data-dex-ref", dataref)
    }
    return false
}

function createItemReference(item) {
    res = "/" + item["action"]
    if(item["query"] && item["query"].length) {
        res += "?query=" + item["query"]
    }
    return res
}

function constructItemLink(item, ref) {
    link = $("<a>")
    // if item has href link goes direct and no dex-data
    if(item["href"] && item["href"].length) {
        href = item["href"] + "?query=" + item["query"]
        link.attr("href", href).attr("data-ajax", "false")
    }
    else { // use dex data-ref an no href
        link.attr("href",'#').attr('data-dex-ref',ref)
    }
    // create the content of the link
    iconpath = item["icon"] ? item["icon"] : "icons/ToolbarAdvanced.png"
    link.append($("<img>").attr("src",iconpath).attr("height",'80').attr("width",'80'))
    link.append($("<h3>").text(item["title"]))
    link.append($("<p>").text(item["subtitle"]))
    if(item["count"]) {
        link.append($("<span>").addClass("ui-li-count").text(item["count"]))
    }
    return link
}

function componentListHtml(page, result, list, append) {
    if(!append) {
        list.empty()
    }
    items = result["body"]
    var tempList = $('<ul></ul>')
    for(var i = 0; i < items.length; i++) {
        var item = items[i]
        ref = createItemReference(item)
        link = constructItemLink(item, ref)
        li = $("<li>").append(link)
        tempList.append(li)
    }
    list.append(tempList.children())
    list.listview("refresh")
    page.find(".ui-input-search .ui-input-text").trigger("change");
}

function filterToggle(e) {
    console.log("filter toggle")
    $("form.ui-listview-filter").toggle()
    e.preventDefault()
    // move to the top of the page
    $.mobile.silentScroll(0)
    return false
}

function filterReset(page) {
    page.find('input[data-type="search"]').val("")
}

$(document).on("click", "a.dex-filter-toggle", filterToggle);

$(document).on("click", "a.dex-home-link", function(e){
        page = $(".ui-page-active")
        home(page)
        return false
});


