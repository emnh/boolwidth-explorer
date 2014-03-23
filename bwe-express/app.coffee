express = require("express")
http = require("http")
path = require("path")
favicon = require("static-favicon")
logger = require("morgan")
cookieParser = require("cookie-parser")
bodyParser = require("body-parser")
routes = require("./routes")
users = require("./routes/user")
app = express()

# Notice the following code is coffescript
#coffeeDir = __dirname + '/coffee'
#publicDir = __dirname + '/public'
#app.use express.compiler(src: coffeeDir, dest: publicDir, enable: ['coffeescript'])
#app.use express.static(publicDir)
#
app.use require('connect-assets')()

# view engine setup
app.set "views", path.join(__dirname, "views")
app.set "view engine", "jade"
app.use favicon()
app.use logger("dev")
app.use bodyParser.json()
app.use bodyParser.urlencoded()
app.use cookieParser()
app.use require("stylus").middleware(path.join(__dirname, "public"))
app.use express.static(path.join(__dirname, "public"))
app.use app.router
app.get "/", routes.index
app.get "/users", users.list

#/ catch 404 and forwarding to error handler
app.use (req, res, next) ->
  err = new Error("Not Found")
  err.status = 404
  next err
  return

#/ error handlers

# development error handler
# will print stacktrace
if app.get("env") is "development"
  app.use (err, req, res, next) ->
    res.render "error",
      message: err.message
      error: err

    return


# production error handler
# no stacktraces leaked to user
app.use (err, req, res, next) ->
  res.render "error",
    message: err.message
    error: {}

  return

module.exports = app
