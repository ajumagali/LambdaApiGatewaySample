'use strict';

console.log('Loading function');

var englishToRussianMap = new Map();
var englishToKazakhMap = new Map();
var englishToTurkishMap = new Map();


exports.handler = async (event, context) => {
    initRussian();
    initKazakh();
    initTurkish();

    var targetLanguage = "";
    var sourceText = "";

    if (event.body) {
        var body = JSON.parse(event.body);

        if (body.targetLanguage)
            targetLanguage = body.targetLanguage.toLowerCase();
        if (body.source)
            sourceText = body.source.toLowerCase();
    }

    var msg = sourceText;

    switch (targetLanguage) {
        case 'russian':
            msg = englishToRussianMap.get(sourceText);
            break;
        case 'kazakh':
            msg = englishToKazakhMap.get(sourceText);
            break;
        case 'turkish':
            msg = englishToTurkishMap.get(sourceText);
            break;
        default:
            break;
    }

    console.log('Received event:', event);
    var responseBody = {
        "message" : msg
    };
    var response = {
        "statusCode" : 200,
        "headers" : {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin' : '*'
        },
        "body" : JSON.stringify(responseBody)

    };
    console.log("response: " + JSON.stringify(response))
    return response;
};

function initRussian() {
    englishToRussianMap.set("hello", "привет");
    englishToRussianMap.set("hi", "привет");
    englishToRussianMap.set("bye", "пока");
    englishToRussianMap.set("see you", "пока");
}

function initKazakh() {
    englishToKazakhMap.set("hello", "salem");
    englishToKazakhMap.set("hi", "salem");
    englishToKazakhMap.set("bye", "sau bol");
    englishToKazakhMap.set("see you", "koriskenshe");
}

function initTurkish() {
    englishToTurkishMap.set("hello", "merhaba");
    englishToTurkishMap.set("hi", "merhaba");
    englishToTurkishMap.set("bye", "hoşçakal");
}