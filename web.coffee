express = require('express')
exec    = require('child_process').exec

String::strip = -> if String::trim? then @trim() else @replace /^\s+|\s+$/g, ""

app = express.createServer()

# :version: can be used to re-generate thumbnails
# :options: c_fill, w_200, h_200
# :url:     the source url
app.get '/:version/:options/:url(*)', (req, res) ->
  url     = req.params.url
  options = req.params.options

  console.log "fetching #{ url } and applying these options: #{ options }..."

  width  = options.match(/w_(\d+)/)?[1] || ''
  height = options.match(/h_(\d+)/)?[1] || ''
  crop   = options.match(/c_(\w+)/)?[1] || ''

  size = "#{width}x#{height}"

  # magick_options is an array of parameters that we pass to imagemagick's `convert` program.
  command = ["./resize.sh", url]

  if crop == 'fill'
    # We are resizing and cropping to fit
    size += "^"
    command.push "-thumbnail"
    command.push size
    command.push "-gravity"
    command.push "center"
    command.push "-extent"
    command.push size
    command.push "-quality"
    command.push "70"
  else if width or height
    # We are resizing
    command.push "-thumbnail"
    command.push size
    command.push "-quality"
    command.push "70"
  else
    # Just fetching the original image and returning it.

  command_string = command.join(' ')
  exec command_string, (error, stdout, stderr) ->
    console.log "error: #{ error}" if error
    console.log "stderr: #{ stderr}" if stderr
    return res.sendfile "no worky" if error or stderr

    filename = stdout.strip()
    # Send the thumbnail to the client with a expires a year from now
    res.sendfile filename, maxAge: 60*60*24*365*1000

app.listen(process.env.PORT || 3000)
