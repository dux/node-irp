# NodeJS image resizer


*Caching ImageResizingProxy service running in node js.*

Server designed to provide a nice way of requesting images on the internet at a size you want. Designed and built in Node JS.
It's none blocking, so rolled on out on a CDN/Cloud will scale uniformly.

### Inspired by

https://github.com/chrisjenx/NodeSizer

I removed all code, converted to CoffeeScript, addeed Base64 Cache safe URLS and HTTP expiry headers. Terrible code quality inspired me to rewrite it, sor chrisjenx :)


## To install

start with

> git clone https://github.com/dux/node-irp

> cd node-irp

for development

> npm install -g nodemon

> nodemon app.coffee

for poduction

> coffee -c app.coffee

> node app.js


## Does it work?

> http://localhost:4000/fit?source=http://i.imgur.com/2dD6DL5.jpg&size=350x350

you should see restaurant in a box 350px X 350px

> http://localhost:4000/width?source=http://i.imgur.com/2dD6DL5.jpg&size=350

you should see restaurant resized to 350px


## Sugar

Base64 URL cache safe paths

> http://localhost:4000/fit?source=http://i.imgur.com/2dD6DL5.jpg&size=350x350

can be written as

> http://localhost:4000/fit/300x300/aHR0cDovL2kuaW1ndXIuY29tLzJkRDZETDUuanBn.jpg

> http://localhost:4000/fit/(size)/Base64(source).(jpg)


## Options

* **`src=`** the source file anywhere on the internet. (WebAddress)
* **`size=`** single or widthxheight e.g. '240' (finds the largest side) '240x360' will do it exact and crop.
* `ext=` png,jpg,gif,tiff
* `q=` 1-100 defaults to _80_ only works on jpeg, does a default 7 pass png optimisation.


## Methods - resize, fit, copy, cache

Resize resizes to defined width

> http://localhost:4000/resize/300/aHR0cDovL2kuaW1ndXIuY29tLzJkRDZETDUuanBn.jpg

Fit resizes and crops image to specified with and height

> http://localhost:4000/fit/200x300/aHR0cDovL2kuaW1ndXIuY29tLzJkRDZETDUuanBn.jpg
> http://localhost:4000/fit/300/aHR0cDovL2kuaW1ndXIuY29tLzJkRDZETDUuanBn.jpg

Copy just copyes resource as any plain CDN would.

> http://localhost:4000/copy/aHR0cDovL2kuaW1ndXIuY29tLzJkRDZETDUuanBn.jpg
> http://localhost:4000/copy?src=http://i.imgur.com/2dD6DL5.jpg


Cache caches for x seconds. 0 is infinite

> http://localhost:4000/cache-10?url=http://...
> http://localhost:4000/cache-0?url=http://...

## Web shots reize and capture

Instead source image you can have source web page. All other methods like fit, width work as with images.

> http://localhost:4000/width?page=http://trifolium.hr&size=300



## Production install nginx and forever

Install Forever ( https://www.npmjs.org/package/forever )
	
	npm install forever -g

Edit nginx to look like this

APP_NAME for example my_cool_app

APP_PORT for example 3000 or 4000

HOSTNAME for example github.com


	nginx http { 
		server_names_hash_bucket_size 64; 
	}

	upstream APP_NAME {
		server 127.0.0.1:APP_PORT;
  	}

  	server {
		listen 80;
		server_name HOSTNAME;

		location / {
  		proxy_set_header X-Real-IP $remote_addr:APP_PORT;
  		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  		proxy_set_header Host $http_host;
  		proxy_set_header X-NginX-Proxy true;

  		proxy_pass http://APP_NAME/;
  		proxy_redirect off;
		}
  	}

Go to your application folder 

	cd /path/to/your/node/app/

And run 

	forever start --spinSleepTime 10000 app.js
	
If you like you can create crontab (if you restart server you need to start forever again... )

First create logs folder inside your app 

	mkdir /path/to/your/node/app/logs
	
Create starter.sh inside your application folder 

	vi starter.sh
	
And paste this code	

	if [ $(ps -e -o uid,cmd | grep $UID | grep node | grep -v grep | wc -l | tr -s "\n") -eq 0 ]
	then
    	export PATH=/usr/local/bin:$PATH
    	forever start --spinSleepTime 10000 --sourceDir /path/to/your/node/app app.js >> /path/to/your/node/app/logs/log.txt 2>&1
	fi
	
Open crontab

	crontab -e
	
And add 

	@reboot /path/to/your/node/app/starter.sh		
That is it!

## In plan

* Social services avatar cache (facebook, twitter) aka /100x100/twitter:dux of /50x50/fb:dino.reic
* Copy suppot for css and js with adequate content headers


## Versions

* 0.1 released and not propperly tested


## Licence

Copyright 2014 Dino Reic (@dux)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.