optionalParam        = /\((.*?)\)/g
namesPattern         = /[\:\*]([^\:\?\/\)]+)/g
optionalNamesPattern = /\(\/[\:\*]([^\:\?\/]+)\)/g


# Monkey patch Backbone.Router to store the necessary 
# data for each route
origRouteMethod = Backbone.Router.prototype.route
Backbone.Router.prototype.route = (route, name, callback) ->
  if _.isRegExp(route)
    for k in ["template", "name", "allParamNames", "optionalParamNames"]
      route[k] = null unless route[k]?
  else
    # Store template in temp container
    template = route
    # Turn route into regex
    route = @_routeToRegExp(route)
    # Set template
    route.template = template
    # Set optional param names
    route.optionalParamNames = _.map template.match(optionalParam), (opt) ->
      opt.replace optionalNamesPattern, "$1"
    # Set all param names
    route.allParamNames = _.map template.match(namesPattern), (n) -> n.substring(1)
    # set name
    route.name = name

  origRouteMethod.apply this, [route, name, callback]


# Monkey patch Backbone.History to track current route (helper)
originalLoadUrlMethod = Backbone.History.prototype.loadUrl
Backbone.History.prototype.loadUrl = (fragmentOverride) ->
  # Get the current URL fragment
  fragment = @getFragment(fragmentOverride)

  # Get the handler for the fragment
  handler = _.find @handlers, (handler) ->
    handler.route.test(fragment)

  # Get the route from the handler
  route = handler.route

  # Extract the route params from the fragment
  params = Backbone.Router.prototype._extractParameters route, fragment

  # convert last arg into query params
  query = params.pop()

  # Convert params into object (from array) using the appropriate keys
  params = _.object route.allParamNames, params

  # Create a new route helper
  helper = Backbone.RouteHelper.build route.name
  
  # Set the params to the current params
  helper.build().params(params)
  
  # If query preset, set it too.
  if query
    helper.query(query)

  @__currentRouteHelper = helper

  # OK we are done monkey matching, call original method.
  originalLoadUrlMethod.apply this, [fragmentOverride]

# -----------------------------------------------------------------------------

class Backbone.RouteHelper

  @current: ->
    Backbone.history.__currentRouteHelper.clone()

  @modify: (name=null) ->
    @current().modify(name)

  @route: ->
    @current().route()

  @build: (name=null) ->
    name ||= RouteHelper.current()._options.route.name
    rh = new RouteHelper(name)
    rh.build()
    rh

  constructor: (routeName) ->
    @_options = {}
    @_options.route = @_getRouteByName(routeName)
    @_options.params = {}
    @_options.query = {}


  # Kicker
  route: ->
    _rt = @_buildRoute @_options.route, @_options.params
    if _.values(@_options.query || {}).length
      _rt = @_attachQuery _rt, @_options.query
    _rt

  build: (name=null) ->
    if name
      @_options.route = @_getRouteByName(name)
    @_buildType = "build"
    @

  modify: (name=null) ->
    if name
      @_options.route = @_getRouteByName(name)
    @_buildType = "modify"
    @

  params: (args) ->
    switch @_buildType
      when "build"  then @_options.params = args
      when "modify" then _.extend(@_options.params, args)
    @

  query: (args) ->
    args = @_parseQuery(args) if typeof args is "string"
    switch @_buildType
      when "build"
        @_options.query = args
      when "modify"
        _.extend(@_options.query, args)
    @

  clone: ->
    _clone = new RouteHelper @_options.route.name
    _clone._options.params = _.clone @_options.params
    if @_options.query
      _clone._options.query = _.clone @_options.query
    if @_buildRoute == "modify"
      _clone.modify()
    else
      _clone.build()
    _clone


  _attachQuery: (route, query) ->
    route + "?" + @_buildQuery query

  _getRouteByName: (name) ->
    handler = _.find Backbone.history.handlers, (handler) ->
      handler.route.name == name
    handler.route

  _parseQuery: (str) ->

  _buildQuery: (obj) ->

  _buildRoute: (route, args) ->
    hasKeys = _.keys args
    allKeys = route.allParamNames
    optKeys = route.optionalParamNames
    reqKeys = _.without allKeys, optKeys...
    misKeys = _.without reqKeys, hasKeys...

    if misKeys.length
      throw "Missing required params: #{misKeys.join ', '} for #{route.name}"

    template = route.template

    # Insert required values into template
    _.each reqKeys, (key) =>
      val = args[key]
      re = new RegExp "(^|\/)(:|\\*)(#{key})"
      template = template.replace re, "$1#{val}"

    # Insert optional values into template
    _.each optKeys, (key) =>
      val = args[key]
      if val
        re = new RegExp "\\(\/:#{key}\\)"
        template = template.replace re, "/#{val}"

    # Remove any missing optional values from template
    template = template.replace optionalParam, ''

    template
