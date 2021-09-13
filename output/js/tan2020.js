/* GLOBAL VARIABLES */
var glossIsBeingHovered = false, sourceGlossClass = "highlight0", targetGlossClasses =[ "highlight1", "highlight2"];

/* FUNCTIONS */
/* --general */

function comparePositions(p1, p2) {
    // Input: two arrays, each consisting of a pair of arrays, each with two numbers representing the X and Y limits of a div
    // Output: whether the two divs overlap
    if (p1 === undefined) {
        p1 =[0, 0];
    }
    if (p2 === undefined) {
        p2 =[1, 1];
    }
    return (isBetween(p1[0][0], p2[0]) || isBetween(p1[0][1], p2[0]) || isBetween(p2[0][0], p1[0])) && (isBetween(p1[1][0], p2[1]) || isBetween(p1[1][1], p2[1]) || isBetween(p2[1][0], p1[1]));
};

function filterArray(array, regExp) {
    var filtered =[];
    for (i = 0; i < array.length; i++) {
        if (regExp.test(array[i])) {
            filtered.push(array[i]);
        }
    }
    return filtered;
};

function getMaxOfArray(numArray) {
    return Math.max.apply(null, numArray);
};

function getPositions(elem) {
    // adapted from code courtesy @ŠimeVidas, http://stackoverflow.com/a/4230951
    var pos, width, height;
    pos = $(elem).offset();
    width = $(elem).width();
    height = $(elem).height();
    if (pos !== undefined) {
        return[[pos.left, pos.left + width],[pos.top, pos.top + height]]
    };
};

function getTextNodesUnder(el) {
    // code courtesy @Phrogz, http://stackoverflow.com/a/10730777
    var n, a =[], walk = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, null, false);
    while (n = walk.nextNode()) a.push(n);
    return a;
}

function getTextWidth(text, font) {
    /* courtesy @Domi, http://stackoverflow.com/a/21015393 */
    // re-use canvas object for better performance
    var canvas = getTextWidth.canvas || (getTextWidth.canvas = document.createElement("canvas"));
    var context = canvas.getContext("2d");
    context.font = font;
    var metrics = context.measureText(text);
    return metrics.width;
}

function intersects(array1, array2) {
    var truthValue = false;
    for (i = 0; i < array1.length; i++) {
        for (j = 0; j < array2.length; j++) {
            if (array1[i] == array2[j]) {
                truthValue = true;
                break
            };
        };
    };
    return truthValue;
};

function isBetween(point, pair) {
    // Input: a number and an array of two numbers, with the smaller first
    // Output: a boolean indicating whether the point is between the pair, or identical to one of them
    return point >= pair[0] && point <= pair[1];
}

function maxLengthInStringArray(array, normSpace) {
    var a =[];
    for (var i = 0; i < array.length; i++) {
        thisText = array[i].textContent;
        thisTextNorm = normSpace ? normalizeSpace(thisText): thisText;
        a.push(thisTextNorm.length)
    }
    return Math.max(a, 1);
}

function normalizeSpace(string) {
    return string.replace(/\s+/g, " ")
}

function sum(array) {
    for (var i = 0; i < array.length; i++) {
        total += array[i] << 0;
    }
}

/* --specific to TAN class-2 files transformed to HTML */

function repositionTokClaims() {
    /*$(".align > .tok, .ana > .tok, .claim > * > .tok").each(function () {
    /\* process claims that affect tokens *\/
    var thisId = $(this).attr('id');
    var firstMatch = $('.idref--' + thisId).first();
    var lineHeight = firstMatch.height();
    var thisClaim = $(this).siblings().clone().wrapAll("<div style='bottom: " +(lineHeight * 1.0) + "' class='claim idref--" + thisId + "' />").parent();
    $(thisClaim).prependTo(firstMatch);
    /\*console.log(thisId, lineHeight);*\/
    });*/
    /*$(".claim .div-ref").each(function () {
    /\* process claims that affect divs *\/
    var thisId = $(this).parent().attr('id');
    var firstMatch = $('.idref--' + thisId).first();
    var thisClaim = $(this).parent().siblings().clone().wrapAll("<div class='claim idref--" + thisId + "' />").parent();
    $(thisClaim).appendTo(firstMatch);
    /\*console.log(thisId, lineHeight);*\/
    });*/
    $(".claim *[id], .align *[id], .ana *[id]").each(function () {
        /* go through each claim in a class 2 file, and place a copy in the class 1 dependencies */
        var thisId = $(this).attr('id');
        var firstMatch = $('.idref--' + thisId).first();
        var firstMatchIsDiv = $(firstMatch).hasClass('div');
        var thisClaim = $(this).parents('.claim, .align, .ana').first().clone().addClass('idref--' + thisId);
        /*if (firstMatchIsDiv) {
        $(thisClaim).insertAfter(firstMatch);
        $(firstMatch).next().find('#' + thisId).remove();
        } else {*/
        $(thisClaim).appendTo(firstMatch);
        $(firstMatch).find('#' + thisId).remove();
        /*};*/
        console.log(thisId, firstMatchIsDiv);
    });
    $(".div > .tok > *").each(function () {
        /* adjust claims so that they don't overlap */
        var prevClaim =[], bumpUpIncrement = 5;
        thisClaimPos = getPositions($(this));
        
        prevSiblingClaim = $(this).prevAll(".align, .ana, .claim").last();
        prevSiblingClaimPos = getPositions(prevSiblingClaim);
        prevSiblingClaimOverlap = comparePositions(thisClaimPos, prevSiblingClaimPos);
        
        prevClaim = $(this).parent().prevAll().find(".align, .ana, .claim").last();
        prevClaimPos = getPositions(prevClaim);
        prevClaimOverlap = comparePositions(thisClaimPos, prevClaimPos);
        
        while (prevClaimOverlap || prevSiblingClaimOverlap) {
            thisBottom = parseInt($(this).css("bottom"));
            $(this).css("bottom", thisBottom + bumpUpIncrement);
            thisClaimPos = getPositions($(this));
            prevSiblingClaimOverlap = comparePositions(thisClaimPos, prevSiblingClaimPos);
            prevClaimOverlap = comparePositions(thisClaimPos, prevClaimPos);
        }
    });
    $(function () {
        /* now set up claims, so that they can be color coded through hovering */
        $("div").hover(function () {
            theseClasses = $(this).prop('class').split(/\s+/);
            idrefClasses = filterArray(theseClasses, /^idref--/);
            for (var j = 0; j < idrefClasses.length; j++) {
                var thisClass = idrefClasses[j];
                $("." + thisClass).toggleClass("highlight" + j);
                /*console.log(j);*/
            };
            /*console.log(theseClasses);*/
        });
    });
};

/* --TAN-A */
$(function () {
    $(".sortable").sortable({
        stop: function (event, item) {
            updateSourceOrder(this);
        }
    });
    function updateSourceOrder(key) {
        console.log('Updating order of sources');
        /* The control might itself be a .sortable, so we need addBack() */
        srcKey = $(key).parents('.control').addBack('.control').find('.head, .e-head').children('.label');
        srcClasses =[];
        for (i = 0; i < srcKey.length; i++) {
            srcClasses.push(srcKey[i].innerHTML)
        };
        console.log('Source classes:', srcClasses);
        srcClasses.push('last');
        $('.div:has(.td), tr, colgroup').each(function () {
            tdSort = $(this).children('div, td, col').sort(function (a, b) {
                /* first, get rid of numbered source classes, then look for names */
                aNorm = a.className.replace(/src--\d+/, '').replace(/.*src--(\S+).*/, '$1');
                bNorm = b.className.replace(/src--\d+/, '').replace(/.*src--(\S+).*/, '$1');
                var _aInd = srcClasses.indexOf(aNorm);
                var _bInd = srcClasses.indexOf(bNorm);
                if (_aInd < _bInd) {
                    return -1;
                } else if (_aInd > _bInd) {
                    return 1;
                } else {
                    return 0;
                }
            });
            console.log(srcKey, tdSort);
            $(tdSort).appendTo(this);
        });
    };
    $("div > .switch").click(function () {
        /* This function turns sources on and off */
        /*thisLabelRaw = $(this).parent().children('.label').text();*/
        thisLabelRaw = $(this).parent().children('.label').text();
        thisLabel = thisLabelRaw.replace(/\s+/g, '_');
        console.log("This label:", thisLabel);
        $("div.version.src--" + thisLabel).toggle();
        $("col.src--" + thisLabel).toggle();
        $("tr .src--" + thisLabel).toggle();
        /*$("td.src--" + thisLabel).toggle();*/
        
        theseClasses = $(this).parent().prop('class').split(/\s+/);
        aliasClasses = filterArray(theseClasses, /^alias--/);
        console.log("These alias classes:", aliasClasses);
        
        if (aliasClasses.length >= 1) {
            $("div.version." + aliasClasses).toggle();
            $("col." + aliasClasses).toggle();
            $("tr ." + aliasClasses).toggle();
            /*$("td.alias--" + thisLabel).toggle();*/
            
        };

        
        /* now change the checkbox */
        $(this).children().toggle();
        /* and show that the item has been suppressed */
        $(this).parent().toggleClass('suppressed');
    });
    $("div > .classSwitch").click(function () {
        /* This function turns classes on and off */
        thisElementName = $(this).children('.elementName').text();
        thisClassName = $(this).children('.className').text();
        console.log(thisElementName);
        console.log(thisClassName);
        $("" + thisElementName).toggleClass(thisClassName);
        $(this).children('.on').toggle();
        $(this).children('.off').toggle();
    });
    $("#tableWidth").change(function() {
        thisNewWidth = $(this).val();
        console.log(thisNewWidth);
        $("table").css({"width": thisNewWidth + "%"});
    });
    $(".lem").click(function () {
        $(this).parent().children('.rdg').toggleClass('hidden');
    });
    $(".label, .signal").click(function () {
        $(this).nextAll().toggle("fast");
    });
});

/* --TAN-A-tok */


/* DOCUMENT HANDLING */

jQuery.fn.justtext = function () {
    return $(this).clone().children().remove().end().text();
};
$(".label").click(function () {
    $(this).nextAll("div, table").toggle("fast");
});
prepareDocument = function () {
    repositionTokClaims();
};

window.onload = prepareDocument;