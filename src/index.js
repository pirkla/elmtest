import { Elm } from './Main.elm'

var storedState = localStorage.getItem('model');
var startingState = storedState ? JSON.parse(storedState) : null;


const elmApp = Elm.Main.init({
    node: document.getElementById("main"),
    flags: startingState
});

elmApp.ports.setStorage.subscribe(function(state) {
    localStorage.setItem('model', JSON.stringify(state));
});

elmApp.ports.removeStorage.subscribe(function() {
    localStorage.removeItem('model');
});