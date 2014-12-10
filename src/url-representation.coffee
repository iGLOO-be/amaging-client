
class UrlRepresentation
  constructor: (domain, cid, key) ->
    @_domain = domain
    @_cid = cid
    @_key = key
    @_options = []

  options: (options...) =>
    @_options = @_options.concat options
    return @

  toString: =>
    base = @_domain + '/' + @_cid + '/'
    if @_options.length
      return base + (@_options.join('&') + '&/') + @_key
    else
      return base + @_key

module.exports = UrlRepresentation