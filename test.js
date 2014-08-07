var webshot = require('webshot');

var options = {
  screenSize: { width: 1024, height: 768 }
  , userAgent:'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.125 Safari/537.36'
  //shotSize: { width: 320, height: 200 }
}

webshot('nutshell.com', 'nutshell.com.png', options, function(err) {
  // screenshot now saved to flickr.jpeg
});