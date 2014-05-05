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

> cd NodeSizer

for development

> npm install -g nodemon

> nodemon app.coffee

for poduction

> coffee -c app.coffee

> node app.js


## Does it work?

`http://localhost:8080/fit?source=http://i.imgur.com/2dD6DL5.jpg&size=350x350`

you should see restaurant in a box 350px X 350px

`http://localhost:8080/width?source=http://i.imgur.com/2dD6DL5.jpg&size=350`

you should see restaurant resized to 350px


## Options

* **`src=`** the source file anywhere on the internet. (WebAddress)
* **`size=`** single or widthxheight e.g. '240' (finds the largest side) '240x360' will do it exact and crop.
* `ext=` png,jpg,gif,tiff
* `q=` 1-100 defaults to _80_ only works on jpeg, does a default 7 pass png optimisation.


## Shugar


Base64 URL cache safe paths

`http://localhost:8080/fit?source=http://i.imgur.com/2dD6DL5.jpg&size=350x350`

can be written as

`http://localhost:8080/fit/300x300/aHR0cDovL2kuaW1ndXIuY29tLzJkRDZETDUuanBn.jpg`
`http://localhost:8080/fit/(size)/Base64(source).(jpg)`


## In plan

* Social services avatar cache (facebook, twitter) aka /100x100/twitter:dux of /50x50/fb:dino.reic


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