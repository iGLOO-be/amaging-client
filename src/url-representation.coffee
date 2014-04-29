
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
    if @_options.length
      return @_domain + '/' + @_cid + '/' + (@_options.join('&') + '&/') + @_key
    else
      return @_domain + '/' + @_cid + '/' + @_key

module.exports = UrlRepresentation