
url = require 'url'

class UrlRepresentation
  @parse: (str) ->
    u = url.parse(str)
    host = u.protocol + '//' + u.host

    m = u.pathname.match(/^\/([\w_-]+)\/(.*)$/)
    unless m?.length >= 3
      return null

    [_path, cid, key] = m
    new UrlRepresentation(host, cid, key)

  constructor: (host, cid, key) ->
    @_host = host
    @_cid = cid
    @_key = key
    @_options = []

  options: (options...) =>
    @_options = @_options.concat options
    return @

  toString: =>
    base = @_host + '/' + @_cid + '/'
    if @_options.length
      return base + (@_options.join('&') + '&/') + @_key
    else
      return base + @_key

module.exports = UrlRepresentation