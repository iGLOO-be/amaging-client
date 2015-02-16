
url = require 'url'
urljoin = require 'url-join'

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
    urljoin(
      @_host + '/' + @_cid
      (@_options.join('&') + '&') if @_options.length
      @_key
    )

module.exports = UrlRepresentation