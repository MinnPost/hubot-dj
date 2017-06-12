{join}      = require 'path'
events      = require 'events'
nunjucks    = require 'nunjucks'
request     = require 'request'
redis       = require 'redis'
shell       = require 'sh'
qs          = require 'querystring'
SpotifyAPI  = require 'spotify-web-api-node'

filepath = "#{join process.cwd(), 'node_modules/hubot-dj/views'}"
template = new nunjucks.Environment(new nunjucks.FileSystemLoader(filepath))

config =
  clientId: process.env.SPOTIFY_CLIENT_ID
  clientSecret: process.env.SPOTIFY_CLIENT_SECRET
  redirectUri: process.env.SPOTIFY_CALLBACK_URL

scopes = [
  'user-follow-read'
  'user-library-read'
  'playlist-modify-public'
  'playlist-read-collaborative'
]

module.exports = (robot) ->
  regx = /\/batibot\s(search|playlist|help)?(\strack:\s|\sadd:\s)?(\"?.*?\"?\s?(--add|-a|--remove|-rm)?)?$/i

  # Utilities
  util =
    filter: (arr, str) ->
      store = 0
      arr.forEach (e, i, a) ->
        str.toLowerCase().match(e) and store++
      return store
    comparator: (subject, switchOne, switchTwo) ->
      if subject == switchOne or subject == switchTwo
        return true
      else
        return false

  # Hubot Respawned
  enter = [
    "What's up humanoids?! I've respawned, Let's take over the world.",
    "I'm your genie for today, you have three wishes I can fulfill.. Actually,
    just type in a command.",
    "Is anybody up? Let's brew some coffee.",
    "I'm built with CoffeeScript and Shell, I'm made for parties.",
    "I'm rising from the murks of the sultry abyss.
    Let's get this show started."
  ]

  # Hubot Night Mode
  leave = [
    "I need to relieve myself in the bathroom to reboot my awesomeness.
    Peace out!",
    "See you in a bit."
  ]

  ###
  # @name bieber thing
  # @desc Bot responds with these images whenever a user searches
  #       for Justin Bieber.
  ###
  bieber = [
    "http://i0.kym-cdn.com/entries/icons/original/000/007/423/untitle.JPG"
  ]

  ###
  # @name ban array
  # @desc lists of artists to ban
  ###
  ban = [
    'bieber'
    'justin bieber'
    'april boy'
    'regino'
    'renz verano'
    'secondhand serenade'
  ]


  # Initialize Spotify API
  spotify = new SpotifyAPI(config)
  authHeader = new Buffer("#{config.clientId}:#{config.clientSecret}")

  ###
  # @name authenticate
  # @desc you know, authentication stuff.
  ###
  authenticate = (req, res, next) ->
    spotify.authorizationCodeGrant(req.query.code)
      .then ((data) ->
        # Attach Spotify Access and Refresh Tokens to the constructor
        spotify.setAccessToken data.body.access_token
        spotify.setRefreshToken data.body.refresh_token

        # Save it to Batibot's brain just in case he crashes and
        # burns and fall into the sultry abyss again.
        robot.brain.set 'spotify', data.body

        # Tell batibot to stop listening for this event now
        robot.removeListener 'authenticate', authenticate

        # Then let's proceed
        next()
      ), (err) ->
        robot.removeListener 'authenticate', authenticate
        res.status 400
        res.send template.render 'index.html', error: err
        return

  ###
  # @name refresh token
  # @desc auto-refresh access token whenever it expires
  ###
  refreshToken = (callback) ->
    spotify.refreshAccessToken().then ((data) ->
      # Re-attach the newly refreshed Spotify Access and
      # Refresh Tokens to the constructor.
      spotify.setAccessToken(data.body.access_token)
      spotify.setRefreshToken(data.body.refresh_token)

      # Re-save it to Batibot's brain just in case he crashes and
      # burns and fall into the sultry abyss again.
      robot.brain.set 'spotify', data.body

      # Callback for optimum awesome, returns auth object
      callback and callback(data)
      return
    ), (err) ->
      refreshToken(callback)
      return


  ###
  # @name Spotify Search
  # @desc Function that searches spotify for your favorite tracks
  ###
  search = (opts) ->
    console.log opts
    return

  ###
  # @name PLayList
  # @desc Function to perform CRUD operations to Playlist
  ###
  playlist = (opts) ->
    console.log opts
    return

  # Event Listenersm they go here
  # -----------------------------

  # Listening for Authentication
  robot.on 'authenticate', authenticate

  # Listening for Search Events
  robot.on 'search', search

  # Listening for Playlist Events
  robot.on 'playlist', playlist

  # Routes, they go here
  # --------------------


  ###
  # @name spotify login
  # @desc a login route where playlist admin get started with all the shiz.
  ###
  robot.router.get '/spotify/login', (req, res) ->
    authorize = spotify.createAuthorizeURL scopes, require('node-uuid').v4()
    res.send template.render 'index.html', {authorize: authorize}
    res.end()

  ###
  # @name spotify callback
  # @desc is a callback route where spotify returns oauth code and all that
  #       shiz for batibot to post back to spotify in order for us to acquire
  #       authentication tokens and stuff... yazz.
  ###
  robot.router.get '/hubot/oauth2/callback', ((req, res, next) ->
    robot.emit 'authenticate', req, res, next
    return
  ), (req, res) ->
    res.redirect '/spotify'
    res.end()
    return

  ###
  # @name spotify playlist admin
  # @desc a single page app the displays playlist admin options.
  ###
  robot.router.get '/spotify', ((req, res, next) ->
    credentials = robot.brain.get('spotify')
    if credentials
      res.send template.render 'admin.html', {credentials: credentials}
      res.end()
    else
      next()

  ), (req, res) ->
    res.redirect '/spotify/login'
    res.end()
    return

  ###
  # @name robot commands
  # @desc these are the commands robot will answer to
  ###
  robot.respond regx, (msg) ->
    console.log 'user:', msg.user
    console.log 'message:', msg.message
    console.log 'commands:', msg.match

    switch msg.match[1]
      # when 'help'
      when 'search'
        msg.reply 'Search Spotify'
