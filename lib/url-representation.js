
const url = require('url');
const urljoin = require('url-join');

class UrlRepresentation {
  static parse(str) {
    const u = url.parse(str);
    const host = u.protocol + '//' + u.host;

    const m = u.pathname.match(/^\/([\w_-]+)\/(.*)$/);
    if (!((m != null ? m.length : undefined) >= 3)) {
      return null;
    }

    const [_path, cid, key] = Array.from(m);
    return new UrlRepresentation(host, cid, key);
  }

  constructor(host, cid, key) {
    this.options = this.options.bind(this);
    this.clearOptions = this.clearOptions.bind(this);
    this.toString = this.toString.bind(this);
    this._host = host;
    this._cid = cid;
    this._key = key;
    this._options = [];
  }

  options(...options) {
    this._options = this._options.concat(options);
    return this;
  }

  clearOptions() {
    this._options = [];
    return this;
  }

  toString() {
    return urljoin(
      this._host,
      this._cid,
      this._options.length ? (this._options.join('&') + '&') : '',
      this._key
    );
  }
}

module.exports = UrlRepresentation;
