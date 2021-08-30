import { Elm } from './Main.elm'

// import { auth0 } from './Auth0.elm'

// var storedState = localStorage.getItem('model');
// var startingState = storedState ? JSON.parse(storedState) : null;


// const elmApp = Elm.Main.init({
//     node: document.getElementById("main"),
//     flags: startingState
// });

// elmApp.ports.setStorage.subscribe(function(state) {
//     localStorage.setItem('model', JSON.stringify(state));
// });

// elmApp.ports.removeStorage.subscribe(function() {
//     localStorage.removeItem('model');
// });



// todo - this throws errors if the userinfo is empty. Userinfo shouldn't usually be empty, but a null value shouldn't crash the page either.
var webAuth = new auth0.WebAuth({
    domain: 'dev-4soyikn3.us.auth0.com', // e.g., you.auth0.com
    clientID: 'IF3sz7cDBMLxsXoWBXMy72vkjlza6IRW',
    responseType: 'token',
    redirectUri: 'http://localhost:1234'
  });
  var storedProfile = localStorage.getItem('profile');
  var storedToken = localStorage.getItem('token');
  var authData = storedProfile && storedToken ? { profile: JSON.parse(storedProfile), token: storedToken } : null;

  const elmApp = Elm.Main.init({
    node: document.getElementById("main"),
    flags: authData
    });

//   var elmApp = Elm.Main.fullscreen(authData);
  // Auth0 authorize subscription
  elmApp.ports.auth0authorize.subscribe(function(opts) {
    webAuth.authorize();
  });
  // Log out of Auth0 subscription
  elmApp.ports.auth0logout.subscribe(function(opts) {
    localStorage.removeItem('profile');
    localStorage.removeItem('token');
  });
  // Watching for hash after redirect
  webAuth.parseHash({ hash: window.location.hash }, function(err, authResult) {
    if (err) {
      return console.error(err);
    }
    if (authResult) {
      webAuth.client.userInfo(authResult.accessToken, function(err, profile) {
        var result = { err: null, ok: null };
        var token = authResult.accessToken;
        if (err) {
          result.err = err.details;
          // Ensure that optional fields are on the object
          result.err.name = result.err.name ? result.err.name : null;
          result.err.code = result.err.code ? result.err.code : null;
          result.err.statusCode = result.err.statusCode ? result.err.statusCode : null;
        }
        if (authResult) {
          result.ok = { profile: profile, token: token };
          localStorage.setItem('profile', JSON.stringify(profile));
          localStorage.setItem('token', token);
        }
        elmApp.ports.auth0authResult.send(result);
      });
      window.location.hash = '';
    }
  });