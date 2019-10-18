console.log('Loading function');

var englishToRussianMap = new Map();
var englishToKazakhMap = new Map();
var englishToTurkishMap = new Map();


exports.handler = async (event, context) => {
    initRussian();
    initKazakh();
    initTurkish();

    var targetLanguage = event.targetLanguage.toLowerCase();
    var sourceText = event.source.toLowerCase();
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
    var response = {
        "message" : msg,
        "headers" : {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin' : '*'
        }
    }
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