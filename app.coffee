# https://github.com/dawanda/node-imageable-server

# https://github.com/sdepold/node-imageable
# https://github.com/chrisjenx/NodeSizer

# generate thumbnail
# http://localhost:8080/fit?image=http%3A%2F%2Flocalhost%3A4000%2F%3Furl%3Dhttp%3A%2F%2Findex.hr&size=250&gravity=North

# generate web shoot thumbnail
# http://localhost:8080/fit?page=http://www.trab.io&size=400x300

#fit
#convert v.jpg -resize 200x200^ -gravity center -background black -extent 200x200 v_fit.jpg

#resize
#convert v.jpg -resize 200x1000 v_resize.jpg

express    = require("express")
# easy_image = require("easyimage")
fs         = require("fs")
md5        = require("md5").digest_s
request    = require("request")
# mkdirp     = require('mkdirp');
webshot    = require('webshot');
exec       = require('child_process').exec;

# helpers
l = (data) -> console.log(data)

easy_image_rescrop = (opts, func) ->
  doit = "convert #{opts['src']} -quality #{opts['quality']} -resize #{opts['width']}x#{opts['height']}^ -gravity center -background black -extent #{opts['width']}x#{opts['height']} #{opts['dst']}"
  console.log "CropFit: #{doit}"
  exec doit, func

easy_image_resize = (opts, func) ->
  doit = "convert #{opts['src']} -quality #{opts['quality']} -resize #{opts['width']}x2000 #{opts['dst']}"
  console.log "Resize: #{doit}"
  exec doit, func

mkdirp = (path) ->
  return if fs.existsSync( path )  
  base = []
  for el in path.split('/')
    base.push el
    fs.mkdirSync base.join('/') unless fs.existsSync( base.join('/') )  

class CacheImage
  @content_type = 
    jpg: 'image/jpeg'
    jpeg: 'image/jpeg'
    gif: 'image/gif'
    png: 'image/png'
    js: 'text/javascript'

  constructor: (@url, @size, @quality, @type) ->
    path = @url.toLowerCase().split('/')
    path.shift()
    path.shift()
    @domain = path.shift().replace(/www\./,'')
    @domain = "#{@domain[0]}/#{@domain}"
    @file_name = path.join('/').replace(/[^\w\.]+/g, "_")

    @ext = @file_name.split('.').reverse()[0]
    @file_name = "#{md5(@file_name)}.#{@ext}"

    @cached_dir   = "cache/ori/#{@domain}"
    @cached_file  = "#{@cached_dir}/#{@file_name}"
    @resized_dir  = "cache/res/#{@domain}/#{@type}/#{@size}-#{@quality}"
    @resized_file = "#{@resized_dir}/#{@file_name}"
    @start = Date.now()


class ResizeRequest
  constructor: (@req, @res, @type) ->
    opts = @req.path.split("/")
    
    return @cached() if @type == 'cache'

    qs = @req.query
    if opts[2]
      qs.size = opts[2]
      qs.source = new Buffer(opts.reverse()[0].split(".")[0], encoding = "Base64").toString("ascii")
    else
      qs.source ||= qs.src || qs.image
      qs.size = qs.width if qs.width

    # for webshot
    if qs.page
      qs.is_page = true
      qs.source = qs.page

    # we have all params?
    return @res.send( 500, "<h3>Source not defined</h3>" ) unless qs.source
    return @res.send( 500, "<h3>BAD URL</h3><p>No http or https prefix on <b>#{qs.source}</b></p>" ) unless /https?:\/\//.test(qs.source)

    qs.q ||= 80

    if qs.is_page
      @req.query.gravity = 'North'
      @image ||= new CacheImage(qs.source+'/shot.jpg', qs.size, qs.q, @type)
      @image.is_page = true
      return @when_we_have_original_image() if fs.existsSync( @image.cached_file )
      mkdirp @image.cached_dir
      # @image.cached_file = 'nutshell.png'
      # qs.source = 'nutshell.com'
      webshot qs.source, @image.cached_file, { screenSize: { width: 1024, height: 768 }, userAgent:'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.125 Safari/537.36' }, (err) =>
        unless fs.existsSync( @image.cached_file )
          exec = require('child_process').exec
          exec("curl -o '#{@image.cached_file}' 'http://free.pagepeeker.com/v2/thumbs.php?size=l&url=#{qs.source.replace(/https?:\/\//,'').replace(/www\./,'')}'")
          # return @when_we_have_original_image()
          return @res.redirect("http://free.pagepeeker.com/v2/thumbs.php?size=l&url=#{qs.source}")
        
        return @when_we_have_original_image()
      return

    @image ||= new CacheImage(qs.source, qs.size, qs.q, @type)

    if @req.headers['cache-control'] == 'no-cache' && fs.existsSync( @image.resized_file )
      console.log "Deleted: #{@image.resized_file}"
      fs.unlinkSync( @image.cached_file )
      fs.unlinkSync( @image.resized_file )
      # return @res.send 200, 'Unlinked'

    if @type != 'copy' && fs.existsSync( @image.resized_file )
      return @deliver_resized_image()
    else
      if fs.existsSync( @image.cached_file )
        return @when_we_have_original_image()
      else
        console.log "Download start: #{qs.source}"
        try
          req = request(url: qs.source)
          req.on "response", (resp) =>
            console.log "Download END: #{qs.source} in #{Date.now() - @image.start}ms"

            if resp.statusCode is 200
              mkdirp( @image.cached_dir )
              req.pipe fs.createWriteStream( @image.cached_file )
              # return @req.send 200, @image.cached_file
            else
              console.log "Error: Code: " + resp.statusCode
              console.log "Invalid File"

          req.on "end", => @when_we_have_original_image()
        catch err
          @res.send 500, {}, "Error: #{err}, probably bad URL (#{qs.source})"
          return

  write_in_browser: (local_path) ->
    @res.set 'Content-Type': CacheImage.content_type[@image.ext] if CacheImage.content_type[@image.ext]
    @res.set 'Cache-control': "public, max-age=10000000, no-transform"
    @res.set 'ETag': md5( local_path )
    @res.set 'Expires', new Date(Date.now() + 10000000).toUTCString()
    fs.createReadStream( local_path ).pipe( @res )

  when_we_have_original_image: ->
    # return @deliver_resized_image() if fs.existsSync( @image.resized_file ) 
    return @write_in_browser( @image.cached_file ) if @type == 'copy'

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
      opts.gravity = @req.query.gravity
      console.log opts
      # easy_image.rescrop opts, (err, img) =>
      easy_image_rescrop opts, (err, img) =>
        if err
          if @image.is_page
            fs.unlinkSync @image.cached_file if fs.existsSync @image.cached_file
            fs.unlinkSync @image.resized_file if fs.existsSync @image.resized_file
          return @res.send 500, "ERROR: #{err}"
        @deliver_resized_image()
    else
      easy_image_resize opts, (err, img) =>
        return @res.send 500, "ERROR: #{err}" if err
        @deliver_resized_image()


  deliver_resized_image: ->
    time_to_convert = Date.now() - @image.start

    console.log "#{time_to_convert} ms for #{@image.url} to #{@image.resized_file}"
    @write_in_browser( @image.resized_file )

  cached: ->
    url = @req.query.url
    elms = @req.path.split('/')
    seconds = parseInt elms[1].split('-')[1]
    seconds = 10000000 if ! seconds || seconds < 1

    console.log "Cache for #{seconds} sec: #{url}"

    request.get url, (a, b, c) =>
      utc_ms = Math.round(new Date()/1000);
      sec_time_stamp = Math.round(utc_ms/seconds)*(seconds+1)

      @res.set 'Cache-control': "public, max-age=#{seconds}, no-transform"
      @res.set 'Content-type': b.headers['content-type']
      @res.set 'ETag': md5("#{url}-#{sec_time_stamp}")
      
      # @res.set 'Expires', new Date(Date.now() + seconds).toUTCString()
      
      return @res.send b.body


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
app.get "/cache*",   (req, res) -> new ResizeRequest(req, res, 'cache')

# port = if process.env.NODE_PROD is "true" then 80 else 8080
port = 4000
app.listen port
console.log "NodeIRP started on port " + port
