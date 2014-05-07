# https://github.com/dawanda/node-imageable-server
# https://github.com/sdepold/node-imageable
# https://github.com/chrisjenx/NodeSizer

express    = require("express")
easy_image = require("easyimage")
fs         = require("fs")
md5        = require("md5").digest_s
request    = require("request")
mkdirp     = require('mkdirp');

# helpers
l = (data) -> console.log(data)

class CacheImage
  constructor: (@url, @size, @quality, @type) ->
    path = @url.toLowerCase().split('/')
    path.shift()
    path.shift()
    @domain = path.shift()
    @file_name = path.join('/').replace(/[^\w\.]+/g, "_")

    @ext = @file_name.split('.').reverse()[0]
    if ['jpg', 'png', 'gif'].indexOf(@ext) == -1
      @ext = 'jpg'
    
    @file_name = "#{md5(@file_name)}.#{@ext}"

    @cached_dir   = "cache/ori/#{@domain}"
    @cached_file  = "#{@cached_dir}/#{@file_name}"
    @resized_dir  = "cache/res/#{@domain}/#{@type}/#{@size}-#{@quality}"
    @resized_file = "#{@resized_dir}/#{@file_name}"
    @start = Date.now()

class ResizeRequest
  constructor: (@req, @res, @type) ->
    opts = @req.path.split("/")
    
    qs = @req.query
    if opts[2]
      qs.size = opts[2]
      qs.source = new Buffer(opts.reverse()[0].split(".")[0], encoding = "Base64").toString("ascii")
    else
      qs.source ||= qs.src
    
    # we have all params?
    unless qs.source
      res.send 400, "<h3>Source not defined</h3>"
      return

    qs.q ||= 80
    @image = new CacheImage(qs.source, qs.size, qs.q, @type)

    if @req.headers['cache-control'] == 'no-cache' && fs.existsSync( @image.resized_file )
      fs.unlinkSync( @image.resized_file )

    if @type != 'copy' && fs.existsSync( @image.resized_file )
      return @deliver_resized_image()
    else
      if fs.existsSync( @image.cached_file )
        return @when_we_have_original_image()
      else
        mkdirp( @image.cached_dir )

        req = request(url: qs.source)
        req.on "response", (resp) =>
          if resp.statusCode is 200
            req.pipe fs.createWriteStream( @image.cached_file )
          else
            console.log "Error: Code: " + resp.statusCode
            console.log "Invalid File"

        req.on "end", => @when_we_have_original_image()

  print_image: (local_path) ->
    @res.set 'Content-Type': "image/#{@image.ext}"
    @res.set 'Cache-control': "public, max-age=10000000, no-transform"
    @res.set 'ETag': md5( local_path )
    @res.set 'Expires', new Date(Date.now() + 10000000).toUTCString()
    fs.createReadStream( local_path ).pipe( @res )

  when_we_have_original_image: ->
    return @deliver_resized_image() if fs.existsSync( @image.resized_file )
    return @print_image( @image.cached_file ) if @type == 'copy'

    mkdirp @image.resized_dir

    opts = 
      type: @image.ext
      fill: true
      quality: @image.quality
      src: @image.cached_file
      dst: @image.resized_file

    parts = @image.size.split('x')
    opts.width = parts[0]
    opts.height = parts[1] if parts[1]

    # if getImageExt(newPath) is "png"
    #  easyimg.exec "optipng -o7 " + newPath, (err, stdout, stderr) ->

    if @type == 'fit'
      opts.height ||= opts.width
      easy_image.rescrop opts, (err, img) =>
        return @res.send 500, "ERROR: #{err}" if err
        @deliver_resized_image()
    else
      easy_image.resize opts, (err, img) =>
        return @res.send 500, "ERROR: #{err}" if err
        @deliver_resized_image()


  deliver_resized_image: ->
    time_to_convert = Date.now() - @image.start

    console.log "#{time_to_convert} ms for #{@image.url} to #{@image.resized_file}"
    @print_image( @image.resized_file )


# Create express app
app = express()
app.set "title", "NodeIRP"
app.get "/", (req, res) -> res.send "<p>hakeru!!!<p>"
app.get '/favicon.ico', (req, res) -> res.send('')

# Converter
app.get "/width*",   (req, res) -> new ResizeRequest(req, res, 'resize')
app.get "/resize*",  (req, res) -> new ResizeRequest(req, res, 'resize')
app.get "/fit*",     (req, res) -> new ResizeRequest(req, res, 'fit')
app.get "/copy*",    (req, res) -> new ResizeRequest(req, res, 'copy')

port = if process.env.NODE_PROD is "true" then 80 else 8080
app.listen port
console.log "NodeIRP started on port " + port
