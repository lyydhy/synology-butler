!function() {
    var t = {
        766: function() {
            SYNO.ns("SYNO.SDS.Session"),
            _S = function(t) {
                return SYNO.SDS.Session[t]
            }
            ,
            _TT = function(t, e, n) {
                try {
                    return SYNO.SDS.Strings[t][e][n]
                } catch (t) {
                    return ""
                }
            }
        },
        240: function() {
            SYNO.SDS._GetCookie = function(t, e) {
                var n = new RegExp("(?:(?:^|.*;\\s*)" + t + "\\s*\\=\\s*([^;]*).*$)|^.*$")
                  , i = e.replace(n, "$1");
                return "" === i ? null : decodeURIComponent(i)
            }
            ,
            SYNO.SDS._SetCookie = function(t, e, n, i) {
                var o = t + "=" + encodeURIComponent(e);
                if ("object" == typeof n)
                    o += ";expires=" + n.toUTCString();
                else if ("number" == typeof n) {
                    var r = new Date;
                    r.setTime(r.getTime() + 24 * n * 60 * 60 * 1e3),
                    o += "; expires=" + r.toUTCString()
                }
                "string" == typeof i && (o += "; path=" + i),
                document.cookie = o
            }
            ,
            SYNO.SDS.GetCookieByName = function(t) {
                return SYNO.SDS._GetCookie(t, document.cookie)
            }
            ,
            SYNO.SDS.SetCookie = function(t, e, n) {
                SYNO.SDS._SetCookie(t, e, n, "/")
            }
        },
        705: function() {
            var t, e, n;
            SYNO.ns("SYNO.Encryption"),
            SYNO.Encryption.AES = (n = function(t, e) {
                var n = {}
                  , i = n.lib = {}
                  , o = function() {}
                  , r = i.Base = {
                    extend: function(t) {
                        o.prototype = this;
                        var e = new o;
                        return t && e.mixIn(t),
                        e.hasOwnProperty("init") || (e.init = function() {
                            e.$super.init.apply(this, arguments)
                        }
                        ),
                        e.init.prototype = e,
                        e.$super = this,
                        e
                    },
                    create: function() {
                        var t = this.extend();
                        return t.init.apply(t, arguments),
                        t
                    },
                    init: function() {},
                    mixIn: function(t) {
                        for (var e in t)
                            t.hasOwnProperty(e) && (this[e] = t[e]);
                        t.hasOwnProperty("toString") && (this.toString = t.toString)
                    },
                    clone: function() {
                        return this.init.prototype.extend(this)
                    }
                }
                  , a = i.WordArray = r.extend({
                    init: function(t, e) {
                        t = this.words = t || [],
                        this.sigBytes = null != e ? e : 4 * t.length
                    },
                    toString: function(t) {
                        return (t || c).stringify(this)
                    },
                    concat: function(t) {
                        var e = this.words
                          , n = t.words
                          , i = this.sigBytes;
                        if (t = t.sigBytes,
                        this.clamp(),
                        i % 4)
                            for (var o = 0; o < t; o++)
                                e[i + o >>> 2] |= (n[o >>> 2] >>> 24 - o % 4 * 8 & 255) << 24 - (i + o) % 4 * 8;
                        else if (65535 < n.length)
                            for (o = 0; o < t; o += 4)
                                e[i + o >>> 2] = n[o >>> 2];
                        else
                            e.push.apply(e, n);
                        return this.sigBytes += t,
                        this
                    },
                    clamp: function() {
                        var e = this.words
                          , n = this.sigBytes;
                        e[n >>> 2] &= 4294967295 << 32 - n % 4 * 8,
                        e.length = t.ceil(n / 4)
                    },
                    clone: function() {
                        var t = r.clone.call(this);
                        return t.words = this.words.slice(0),
                        t
                    },
                    random: function(e) {
                        for (var n = [], i = 0; i < e; i += 4)
                            n.push(4294967296 * t.random() | 0);
                        return new a.init(n,e)
                    }
                })
                  , s = n.enc = {}
                  , c = s.Hex = {
                    stringify: function(t) {
                        var e = t.words;
                        t = t.sigBytes;
                        for (var n = [], i = 0; i < t; i++) {
                            var o = e[i >>> 2] >>> 24 - i % 4 * 8 & 255;
                            n.push((o >>> 4).toString(16)),
                            n.push((15 & o).toString(16))
                        }
                        return n.join("")
                    },
                    parse: function(t) {
                        for (var e = t.length, n = [], i = 0; i < e; i += 2)
                            n[i >>> 3] |= parseInt(t.substr(i, 2), 16) << 24 - i % 8 * 4;
                        return new a.init(n,e / 2)
                    }
                }
                  , u = s.Latin1 = {
                    stringify: function(t) {
                        var e = t.words;
                        t = t.sigBytes;
                        for (var n = [], i = 0; i < t; i++)
                            n.push(String.fromCharCode(e[i >>> 2] >>> 24 - i % 4 * 8 & 255));
                        return n.join("")
                    },
                    parse: function(t) {
                        for (var e = t.length, n = [], i = 0; i < e; i++)
                            n[i >>> 2] |= (255 & t.charCodeAt(i)) << 24 - i % 4 * 8;
                        return new a.init(n,e)
                    }
                }
                  , l = s.Utf8 = {
                    stringify: function(t) {
                        try {
                            return decodeURIComponent(escape(u.stringify(t)))
                        } catch (t) {
                            throw Error("Malformed UTF-8 data")
                        }
                    },
                    parse: function(t) {
                        return u.parse(unescape(encodeURIComponent(t)))
                    }
                }
                  , d = i.BufferedBlockAlgorithm = r.extend({
                    reset: function() {
                        this._data = new a.init,
                        this._nDataBytes = 0
                    },
                    _append: function(t) {
                        "string" == typeof t && (t = l.parse(t)),
                        this._data.concat(t),
                        this._nDataBytes += t.sigBytes
                    },
                    _process: function(e) {
                        var n = this._data
                          , i = n.words
                          , o = n.sigBytes
                          , r = this.blockSize
                          , s = o / (4 * r);
                        if (e = (s = e ? t.ceil(s) : t.max((0 | s) - this._minBufferSize, 0)) * r,
                        o = t.min(4 * e, o),
                        e) {
                            for (var c = 0; c < e; c += r)
                                this._doProcessBlock(i, c);
                            c = i.splice(0, e),
                            n.sigBytes -= o
                        }
                        return new a.init(c,o)
                    },
                    clone: function() {
                        var t = r.clone.call(this);
                        return t._data = this._data.clone(),
                        t
                    },
                    _minBufferSize: 0
                });
                i.Hasher = d.extend({
                    cfg: r.extend(),
                    init: function(t) {
                        this.cfg = this.cfg.extend(t),
                        this.reset()
                    },
                    reset: function() {
                        d.reset.call(this),
                        this._doReset()
                    },
                    update: function(t) {
                        return this._append(t),
                        this._process(),
                        this
                    },
                    finalize: function(t) {
                        return t && this._append(t),
                        this._doFinalize()
                    },
                    blockSize: 16,
                    _createHelper: function(t) {
                        return function(e, n) {
                            return new t.init(n).finalize(e)
                        }
                    },
                    _createHmacHelper: function(t) {
                        return function(e, n) {
                            return new h.HMAC.init(t,n).finalize(e)
                        }
                    }
                });
                var h = n.algo = {};
                return n
            }(Math),
            e = (t = n).lib.WordArray,
            t.enc.Base64 = {
                stringify: function(t) {
                    var e = t.words
                      , n = t.sigBytes
                      , i = this._map;
                    t.clamp(),
                    t = [];
                    for (var o = 0; o < n; o += 3)
                        for (var r = (e[o >>> 2] >>> 24 - o % 4 * 8 & 255) << 16 | (e[o + 1 >>> 2] >>> 24 - (o + 1) % 4 * 8 & 255) << 8 | e[o + 2 >>> 2] >>> 24 - (o + 2) % 4 * 8 & 255, a = 0; 4 > a && o + .75 * a < n; a++)
                            t.push(i.charAt(r >>> 6 * (3 - a) & 63));
                    if (e = i.charAt(64))
                        for (; t.length % 4; )
                            t.push(e);
                    return t.join("")
                },
                parse: function(t) {
                    var n = t.length
                      , i = this._map;
                    (o = i.charAt(64)) && -1 != (o = t.indexOf(o)) && (n = o);
                    for (var o = [], r = 0, a = 0; a < n; a++)
                        if (a % 4) {
                            var s = i.indexOf(t.charAt(a - 1)) << a % 4 * 2
                              , c = i.indexOf(t.charAt(a)) >>> 6 - a % 4 * 2;
                            o[r >>> 2] |= (s | c) << 24 - r % 4 * 8,
                            r++
                        }
                    return e.create(o, r)
                },
                _map: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
            },
            function(t) {
                function e(t, e, n, i, o, r, a) {
                    return ((t = t + (e & n | ~e & i) + o + a) << r | t >>> 32 - r) + e
                }
                function i(t, e, n, i, o, r, a) {
                    return ((t = t + (e & i | n & ~i) + o + a) << r | t >>> 32 - r) + e
                }
                function o(t, e, n, i, o, r, a) {
                    return ((t = t + (e ^ n ^ i) + o + a) << r | t >>> 32 - r) + e
                }
                function r(t, e, n, i, o, r, a) {
                    return ((t = t + (n ^ (e | ~i)) + o + a) << r | t >>> 32 - r) + e
                }
                for (var a = n, s = (u = a.lib).WordArray, c = u.Hasher, u = a.algo, l = [], d = 0; 64 > d; d++)
                    l[d] = 4294967296 * t.abs(t.sin(d + 1)) | 0;
                u = u.MD5 = c.extend({
                    _doReset: function() {
                        this._hash = new s.init([1732584193, 4023233417, 2562383102, 271733878])
                    },
                    _doProcessBlock: function(t, n) {
                        for (var a = 0; 16 > a; a++) {
                            var s = t[c = n + a];
                            t[c] = 16711935 & (s << 8 | s >>> 24) | 4278255360 & (s << 24 | s >>> 8)
                        }
                        a = this._hash.words;
                        var c = t[n + 0]
                          , u = (s = t[n + 1],
                        t[n + 2])
                          , d = t[n + 3]
                          , h = t[n + 4]
                          , f = t[n + 5]
                          , p = t[n + 6]
                          , S = t[n + 7]
                          , m = t[n + 8]
                          , g = t[n + 9]
                          , v = t[n + 10]
                          , y = t[n + 11]
                          , b = t[n + 12]
                          , w = t[n + 13]
                          , _ = t[n + 14]
                          , k = t[n + 15]
                          , O = e(O = a[0], Y = a[1], N = a[2], D = a[3], c, 7, l[0])
                          , D = e(D, O, Y, N, s, 12, l[1])
                          , N = e(N, D, O, Y, u, 17, l[2])
                          , Y = e(Y, N, D, O, d, 22, l[3]);
                        O = e(O, Y, N, D, h, 7, l[4]),
                        D = e(D, O, Y, N, f, 12, l[5]),
                        N = e(N, D, O, Y, p, 17, l[6]),
                        Y = e(Y, N, D, O, S, 22, l[7]),
                        O = e(O, Y, N, D, m, 7, l[8]),
                        D = e(D, O, Y, N, g, 12, l[9]),
                        N = e(N, D, O, Y, v, 17, l[10]),
                        Y = e(Y, N, D, O, y, 22, l[11]),
                        O = e(O, Y, N, D, b, 7, l[12]),
                        D = e(D, O, Y, N, w, 12, l[13]),
                        N = e(N, D, O, Y, _, 17, l[14]),
                        O = i(O, Y = e(Y, N, D, O, k, 22, l[15]), N, D, s, 5, l[16]),
                        D = i(D, O, Y, N, p, 9, l[17]),
                        N = i(N, D, O, Y, y, 14, l[18]),
                        Y = i(Y, N, D, O, c, 20, l[19]),
                        O = i(O, Y, N, D, f, 5, l[20]),
                        D = i(D, O, Y, N, v, 9, l[21]),
                        N = i(N, D, O, Y, k, 14, l[22]),
                        Y = i(Y, N, D, O, h, 20, l[23]),
                        O = i(O, Y, N, D, g, 5, l[24]),
                        D = i(D, O, Y, N, _, 9, l[25]),
                        N = i(N, D, O, Y, d, 14, l[26]),
                        Y = i(Y, N, D, O, m, 20, l[27]),
                        O = i(O, Y, N, D, w, 5, l[28]),
                        D = i(D, O, Y, N, u, 9, l[29]),
                        N = i(N, D, O, Y, S, 14, l[30]),
                        O = o(O, Y = i(Y, N, D, O, b, 20, l[31]), N, D, f, 4, l[32]),
                        D = o(D, O, Y, N, m, 11, l[33]),
                        N = o(N, D, O, Y, y, 16, l[34]),
                        Y = o(Y, N, D, O, _, 23, l[35]),
                        O = o(O, Y, N, D, s, 4, l[36]),
                        D = o(D, O, Y, N, h, 11, l[37]),
                        N = o(N, D, O, Y, S, 16, l[38]),
                        Y = o(Y, N, D, O, v, 23, l[39]),
                        O = o(O, Y, N, D, w, 4, l[40]),
                        D = o(D, O, Y, N, c, 11, l[41]),
                        N = o(N, D, O, Y, d, 16, l[42]),
                        Y = o(Y, N, D, O, p, 23, l[43]),
                        O = o(O, Y, N, D, g, 4, l[44]),
                        D = o(D, O, Y, N, b, 11, l[45]),
                        N = o(N, D, O, Y, k, 16, l[46]),
                        O = r(O, Y = o(Y, N, D, O, u, 23, l[47]), N, D, c, 6, l[48]),
                        D = r(D, O, Y, N, S, 10, l[49]),
                        N = r(N, D, O, Y, _, 15, l[50]),
                        Y = r(Y, N, D, O, f, 21, l[51]),
                        O = r(O, Y, N, D, b, 6, l[52]),
                        D = r(D, O, Y, N, d, 10, l[53]),
                        N = r(N, D, O, Y, v, 15, l[54]),
                        Y = r(Y, N, D, O, s, 21, l[55]),
                        O = r(O, Y, N, D, m, 6, l[56]),
                        D = r(D, O, Y, N, k, 10, l[57]),
                        N = r(N, D, O, Y, p, 15, l[58]),
                        Y = r(Y, N, D, O, w, 21, l[59]),
                        O = r(O, Y, N, D, h, 6, l[60]),
                        D = r(D, O, Y, N, y, 10, l[61]),
                        N = r(N, D, O, Y, u, 15, l[62]),
                        Y = r(Y, N, D, O, g, 21, l[63]),
                        a[0] = a[0] + O | 0,
                        a[1] = a[1] + Y | 0,
                        a[2] = a[2] + N | 0,
                        a[3] = a[3] + D | 0
                    },
                    _doFinalize: function() {
                        var e = this._data
                          , n = e.words
                          , i = 8 * this._nDataBytes
                          , o = 8 * e.sigBytes;
                        n[o >>> 5] |= 128 << 24 - o % 32;
                        var r = t.floor(i / 4294967296);
                        for (n[15 + (o + 64 >>> 9 << 4)] = 16711935 & (r << 8 | r >>> 24) | 4278255360 & (r << 24 | r >>> 8),
                        n[14 + (o + 64 >>> 9 << 4)] = 16711935 & (i << 8 | i >>> 24) | 4278255360 & (i << 24 | i >>> 8),
                        e.sigBytes = 4 * (n.length + 1),
                        this._process(),
                        n = (e = this._hash).words,
                        i = 0; 4 > i; i++)
                            o = n[i],
                            n[i] = 16711935 & (o << 8 | o >>> 24) | 4278255360 & (o << 24 | o >>> 8);
                        return e
                    },
                    clone: function() {
                        var t = c.clone.call(this);
                        return t._hash = this._hash.clone(),
                        t
                    }
                }),
                a.MD5 = c._createHelper(u),
                a.HmacMD5 = c._createHmacHelper(u)
            }(Math),
            function() {
                var t, e = n, i = (t = e.lib).Base, o = t.WordArray, r = (t = e.algo).EvpKDF = i.extend({
                    cfg: i.extend({
                        keySize: 4,
                        hasher: t.MD5,
                        iterations: 1
                    }),
                    init: function(t) {
                        this.cfg = this.cfg.extend(t)
                    },
                    compute: function(t, e) {
                        for (var n = (s = this.cfg).hasher.create(), i = o.create(), r = i.words, a = s.keySize, s = s.iterations; r.length < a; ) {
                            c && n.update(c);
                            var c = n.update(t).finalize(e);
                            n.reset();
                            for (var u = 1; u < s; u++)
                                c = n.finalize(c),
                                n.reset();
                            i.concat(c)
                        }
                        return i.sigBytes = 4 * a,
                        i
                    }
                });
                e.EvpKDF = function(t, e, n) {
                    return r.create(n).compute(t, e)
                }
            }(),
            n.lib.Cipher || function(t) {
                var e = (p = n).lib
                  , i = e.Base
                  , o = e.WordArray
                  , r = e.BufferedBlockAlgorithm
                  , a = p.enc.Base64
                  , s = p.algo.EvpKDF
                  , c = e.Cipher = r.extend({
                    cfg: i.extend(),
                    createEncryptor: function(t, e) {
                        return this.create(this._ENC_XFORM_MODE, t, e)
                    },
                    createDecryptor: function(t, e) {
                        return this.create(this._DEC_XFORM_MODE, t, e)
                    },
                    init: function(t, e, n) {
                        this.cfg = this.cfg.extend(n),
                        this._xformMode = t,
                        this._key = e,
                        this.reset()
                    },
                    reset: function() {
                        r.reset.call(this),
                        this._doReset()
                    },
                    process: function(t) {
                        return this._append(t),
                        this._process()
                    },
                    finalize: function(t) {
                        return t && this._append(t),
                        this._doFinalize()
                    },
                    keySize: 4,
                    ivSize: 4,
                    _ENC_XFORM_MODE: 1,
                    _DEC_XFORM_MODE: 2,
                    _createHelper: function(t) {
                        return {
                            encrypt: function(e, n, i) {
                                return ("string" == typeof n ? S : f).encrypt(t, e, n, i)
                            },
                            decrypt: function(e, n, i) {
                                return ("string" == typeof n ? S : f).decrypt(t, e, n, i)
                            }
                        }
                    }
                });
                e.StreamCipher = c.extend({
                    _doFinalize: function() {
                        return this._process(!0)
                    },
                    blockSize: 1
                });
                var u = p.mode = {}
                  , l = function(t, e, n) {
                    var i = this._iv;
                    i ? this._iv = void 0 : i = this._prevBlock;
                    for (var o = 0; o < n; o++)
                        t[e + o] ^= i[o]
                }
                  , d = (e.BlockCipherMode = i.extend({
                    createEncryptor: function(t, e) {
                        return this.Encryptor.create(t, e)
                    },
                    createDecryptor: function(t, e) {
                        return this.Decryptor.create(t, e)
                    },
                    init: function(t, e) {
                        this._cipher = t,
                        this._iv = e
                    }
                })).extend();
                d.Encryptor = d.extend({
                    processBlock: function(t, e) {
                        var n = this._cipher
                          , i = n.blockSize;
                        l.call(this, t, e, i),
                        n.encryptBlock(t, e),
                        this._prevBlock = t.slice(e, e + i)
                    }
                }),
                d.Decryptor = d.extend({
                    processBlock: function(t, e) {
                        var n = this._cipher
                          , i = n.blockSize
                          , o = t.slice(e, e + i);
                        n.decryptBlock(t, e),
                        l.call(this, t, e, i),
                        this._prevBlock = o
                    }
                }),
                u = u.CBC = d,
                d = (p.pad = {}).Pkcs7 = {
                    pad: function(t, e) {
                        for (var n, i = (n = (n = 4 * e) - t.sigBytes % n) << 24 | n << 16 | n << 8 | n, r = [], a = 0; a < n; a += 4)
                            r.push(i);
                        n = o.create(r, n),
                        t.concat(n)
                    },
                    unpad: function(t) {
                        t.sigBytes -= 255 & t.words[t.sigBytes - 1 >>> 2]
                    }
                },
                e.BlockCipher = c.extend({
                    cfg: c.cfg.extend({
                        mode: u,
                        padding: d
                    }),
                    reset: function() {
                        c.reset.call(this);
                        var t = (e = this.cfg).iv
                          , e = e.mode;
                        if (this._xformMode == this._ENC_XFORM_MODE)
                            var n = e.createEncryptor;
                        else
                            n = e.createDecryptor,
                            this._minBufferSize = 1;
                        this._mode = n.call(e, this, t && t.words)
                    },
                    _doProcessBlock: function(t, e) {
                        this._mode.processBlock(t, e)
                    },
                    _doFinalize: function() {
                        var t = this.cfg.padding;
                        if (this._xformMode == this._ENC_XFORM_MODE) {
                            t.pad(this._data, this.blockSize);
                            var e = this._process(!0)
                        } else
                            e = this._process(!0),
                            t.unpad(e);
                        return e
                    },
                    blockSize: 4
                });
                var h = e.CipherParams = i.extend({
                    init: function(t) {
                        this.mixIn(t)
                    },
                    toString: function(t) {
                        return (t || this.formatter).stringify(this)
                    }
                })
                  , f = (u = (p.format = {}).OpenSSL = {
                    stringify: function(t) {
                        var e = t.ciphertext;
                        return ((t = t.salt) ? o.create([1398893684, 1701076831]).concat(t).concat(e) : e).toString(a)
                    },
                    parse: function(t) {
                        var e = (t = a.parse(t)).words;
                        if (1398893684 == e[0] && 1701076831 == e[1]) {
                            var n = o.create(e.slice(2, 4));
                            e.splice(0, 4),
                            t.sigBytes -= 16
                        }
                        return h.create({
                            ciphertext: t,
                            salt: n
                        })
                    }
                },
                e.SerializableCipher = i.extend({
                    cfg: i.extend({
                        format: u
                    }),
                    encrypt: function(t, e, n, i) {
                        i = this.cfg.extend(i);
                        var o = t.createEncryptor(n, i);
                        return e = o.finalize(e),
                        o = o.cfg,
                        h.create({
                            ciphertext: e,
                            key: n,
                            iv: o.iv,
                            algorithm: t,
                            mode: o.mode,
                            padding: o.padding,
                            blockSize: t.blockSize,
                            formatter: i.format
                        })
                    },
                    decrypt: function(t, e, n, i) {
                        return i = this.cfg.extend(i),
                        e = this._parse(e, i.format),
                        t.createDecryptor(n, i).finalize(e.ciphertext)
                    },
                    _parse: function(t, e) {
                        return "string" == typeof t ? e.parse(t, this) : t
                    }
                }))
                  , p = (p.kdf = {}).OpenSSL = {
                    execute: function(t, e, n, i) {
                        return i || (i = o.random(8)),
                        t = s.create({
                            keySize: e + n
                        }).compute(t, i),
                        n = o.create(t.words.slice(e), 4 * n),
                        t.sigBytes = 4 * e,
                        h.create({
                            key: t,
                            iv: n,
                            salt: i
                        })
                    }
                }
                  , S = e.PasswordBasedCipher = f.extend({
                    cfg: f.cfg.extend({
                        kdf: p
                    }),
                    encrypt: function(t, e, n, i) {
                        return n = (i = this.cfg.extend(i)).kdf.execute(n, t.keySize, t.ivSize),
                        i.iv = n.iv,
                        (t = f.encrypt.call(this, t, e, n.key, i)).mixIn(n),
                        t
                    },
                    decrypt: function(t, e, n, i) {
                        return i = this.cfg.extend(i),
                        e = this._parse(e, i.format),
                        n = i.kdf.execute(n, t.keySize, t.ivSize, e.salt),
                        i.iv = n.iv,
                        f.decrypt.call(this, t, e, n.key, i)
                    }
                })
            }(),
            function() {
                for (var t = n, e = t.lib.BlockCipher, i = t.algo, o = [], r = [], a = [], s = [], c = [], u = [], l = [], d = [], h = [], f = [], p = [], S = 0; 256 > S; S++)
                    p[S] = 128 > S ? S << 1 : S << 1 ^ 283;
                var m = 0
                  , g = 0;
                for (S = 0; 256 > S; S++) {
                    var v = (v = g ^ g << 1 ^ g << 2 ^ g << 3 ^ g << 4) >>> 8 ^ 255 & v ^ 99;
                    o[m] = v,
                    r[v] = m;
                    var y = p[m]
                      , b = p[y]
                      , w = p[b]
                      , _ = 257 * p[v] ^ 16843008 * v;
                    a[m] = _ << 24 | _ >>> 8,
                    s[m] = _ << 16 | _ >>> 16,
                    c[m] = _ << 8 | _ >>> 24,
                    u[m] = _,
                    _ = 16843009 * w ^ 65537 * b ^ 257 * y ^ 16843008 * m,
                    l[v] = _ << 24 | _ >>> 8,
                    d[v] = _ << 16 | _ >>> 16,
                    h[v] = _ << 8 | _ >>> 24,
                    f[v] = _,
                    m ? (m = y ^ p[p[p[w ^ y]]],
                    g ^= p[p[g]]) : m = g = 1
                }
                var k = [0, 1, 2, 4, 8, 16, 32, 64, 128, 27, 54];
                i = i.AES = e.extend({
                    _doReset: function() {
                        for (var t = (n = this._key).words, e = n.sigBytes / 4, n = 4 * ((this._nRounds = e + 6) + 1), i = this._keySchedule = [], r = 0; r < n; r++)
                            if (r < e)
                                i[r] = t[r];
                            else {
                                var a = i[r - 1];
                                r % e ? 6 < e && 4 == r % e && (a = o[a >>> 24] << 24 | o[a >>> 16 & 255] << 16 | o[a >>> 8 & 255] << 8 | o[255 & a]) : (a = o[(a = a << 8 | a >>> 24) >>> 24] << 24 | o[a >>> 16 & 255] << 16 | o[a >>> 8 & 255] << 8 | o[255 & a],
                                a ^= k[r / e | 0] << 24),
                                i[r] = i[r - e] ^ a
                            }
                        for (t = this._invKeySchedule = [],
                        e = 0; e < n; e++)
                            r = n - e,
                            a = e % 4 ? i[r] : i[r - 4],
                            t[e] = 4 > e || 4 >= r ? a : l[o[a >>> 24]] ^ d[o[a >>> 16 & 255]] ^ h[o[a >>> 8 & 255]] ^ f[o[255 & a]]
                    },
                    encryptBlock: function(t, e) {
                        this._doCryptBlock(t, e, this._keySchedule, a, s, c, u, o)
                    },
                    decryptBlock: function(t, e) {
                        var n = t[e + 1];
                        t[e + 1] = t[e + 3],
                        t[e + 3] = n,
                        this._doCryptBlock(t, e, this._invKeySchedule, l, d, h, f, r),
                        n = t[e + 1],
                        t[e + 1] = t[e + 3],
                        t[e + 3] = n
                    },
                    _doCryptBlock: function(t, e, n, i, o, r, a, s) {
                        for (var c = this._nRounds, u = t[e] ^ n[0], l = t[e + 1] ^ n[1], d = t[e + 2] ^ n[2], h = t[e + 3] ^ n[3], f = 4, p = 1; p < c; p++) {
                            var S = i[u >>> 24] ^ o[l >>> 16 & 255] ^ r[d >>> 8 & 255] ^ a[255 & h] ^ n[f++]
                              , m = i[l >>> 24] ^ o[d >>> 16 & 255] ^ r[h >>> 8 & 255] ^ a[255 & u] ^ n[f++]
                              , g = i[d >>> 24] ^ o[h >>> 16 & 255] ^ r[u >>> 8 & 255] ^ a[255 & l] ^ n[f++];
                            h = i[h >>> 24] ^ o[u >>> 16 & 255] ^ r[l >>> 8 & 255] ^ a[255 & d] ^ n[f++],
                            u = S,
                            l = m,
                            d = g
                        }
                        S = (s[u >>> 24] << 24 | s[l >>> 16 & 255] << 16 | s[d >>> 8 & 255] << 8 | s[255 & h]) ^ n[f++],
                        m = (s[l >>> 24] << 24 | s[d >>> 16 & 255] << 16 | s[h >>> 8 & 255] << 8 | s[255 & u]) ^ n[f++],
                        g = (s[d >>> 24] << 24 | s[h >>> 16 & 255] << 16 | s[u >>> 8 & 255] << 8 | s[255 & l]) ^ n[f++],
                        h = (s[h >>> 24] << 24 | s[u >>> 16 & 255] << 16 | s[l >>> 8 & 255] << 8 | s[255 & d]) ^ n[f++],
                        t[e] = S,
                        t[e + 1] = m,
                        t[e + 2] = g,
                        t[e + 3] = h
                    },
                    keySize: 8
                }),
                t.AES = e._createHelper(i)
            }(),
            n.AES)
        },
        765: function() {
            var t;
            SYNO.ns("SYNO.Encryption"),
            SYNO.Encryption.Base64 = (t = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
            {
                hex2b64: function(e) {
                    var n, i, o = "";
                    for (n = 0; n + 3 <= e.length; n += 3)
                        i = parseInt(e.substring(n, n + 3), 16),
                        o += t.charAt(i >> 6) + t.charAt(63 & i);
                    for (n + 1 == e.length ? (i = parseInt(e.substring(n, n + 1), 16),
                    o += t.charAt(i << 2)) : n + 2 == e.length && (i = parseInt(e.substring(n, n + 2), 16),
                    o += t.charAt(i >> 2) + t.charAt((3 & i) << 4)); (3 & o.length) > 0; )
                        o += "=";
                    return o
                },
                b64tohex: function(e) {
                    var n, i, o = "", r = 0;
                    for (n = 0; n < e.length && "=" != e.charAt(n); ++n) {
                        var a = t.indexOf(e.charAt(n));
                        a < 0 || (0 === r ? (o += int2char(a >> 2),
                        i = 3 & a,
                        r = 1) : 1 == r ? (o += int2char(i << 2 | a >> 4),
                        i = 15 & a,
                        r = 2) : 2 == r ? (o += int2char(i),
                        o += int2char(a >> 2),
                        i = 3 & a,
                        r = 3) : (o += int2char(i << 2 | a >> 4),
                        o += int2char(15 & a),
                        r = 0))
                    }
                    return 1 == r && (o += int2char(i << 2)),
                    o
                },
                b64toBA: function(t) {
                    var e, n = this.b64tohex(t), i = [];
                    for (e = 0; 2 * e < n.length; ++e)
                        i[e] = parseInt(n.substring(2 * e, 2 * e + 2), 16);
                    return i
                }
            })
        },
        554: function() {
            SYNO.ns("SYNO.Encryption"),
            SYNO.Encryption.BigInteger = function() {
                var t;
                function e(t, e, n) {
                    SYNO.SDS.isEmpty(t) || ("number" == typeof t ? this.fromNumber(t, e, n) : SYNO.SDS.isEmpty(e) && "string" != typeof t ? this.fromString(t, 256) : this.fromString(t, e))
                }
                function n() {
                    return new e(null)
                }
                "Microsoft Internet Explorer" == navigator.appName ? (e.prototype.am = function(t, e, n, i, o, r) {
                    for (var a = 32767 & e, s = e >> 15; --r >= 0; ) {
                        var c = 32767 & this[t]
                          , u = this[t++] >> 15
                          , l = s * c + u * a;
                        o = ((c = a * c + ((32767 & l) << 15) + n[i] + (1073741823 & o)) >>> 30) + (l >>> 15) + s * u + (o >>> 30),
                        n[i++] = 1073741823 & c
                    }
                    return o
                }
                ,
                t = 30) : "Netscape" != navigator.appName ? (e.prototype.am = function(t, e, n, i, o, r) {
                    for (; --r >= 0; ) {
                        var a = e * this[t++] + n[i] + o;
                        o = Math.floor(a / 67108864),
                        n[i++] = 67108863 & a
                    }
                    return o
                }
                ,
                t = 26) : (e.prototype.am = function(t, e, n, i, o, r) {
                    for (var a = 16383 & e, s = e >> 14; --r >= 0; ) {
                        var c = 16383 & this[t]
                          , u = this[t++] >> 14
                          , l = s * c + u * a;
                        o = ((c = a * c + ((16383 & l) << 14) + n[i] + o) >> 28) + (l >> 14) + s * u,
                        n[i++] = 268435455 & c
                    }
                    return o
                }
                ,
                t = 28),
                e.prototype.DB = t,
                e.prototype.DM = (1 << t) - 1,
                e.prototype.DV = 1 << t,
                e.prototype.FV = Math.pow(2, 52),
                e.prototype.F1 = 52 - t,
                e.prototype.F2 = 2 * t - 52;
                var i, o, r = [];
                for (i = "0".charCodeAt(0),
                o = 0; o <= 9; ++o)
                    r[i++] = o;
                for (i = "a".charCodeAt(0),
                o = 10; o < 36; ++o)
                    r[i++] = o;
                for (i = "A".charCodeAt(0),
                o = 10; o < 36; ++o)
                    r[i++] = o;
                function a(t) {
                    return "0123456789abcdefghijklmnopqrstuvwxyz".charAt(t)
                }
                function s(t, e) {
                    var n = r[t.charCodeAt(e)];
                    return SYNO.SDS.isEmpty(n) ? -1 : n
                }
                function c(t) {
                    var e = n();
                    return e.fromInt(t),
                    e
                }
                function u(t) {
                    var e, n = 1;
                    return 0 != (e = t >>> 16) && (t = e,
                    n += 16),
                    0 != (e = t >> 8) && (t = e,
                    n += 8),
                    0 != (e = t >> 4) && (t = e,
                    n += 4),
                    0 != (e = t >> 2) && (t = e,
                    n += 2),
                    0 != (e = t >> 1) && (t = e,
                    n += 1),
                    n
                }
                function l(t) {
                    this.m = t
                }
                function d(t) {
                    this.m = t,
                    this.mp = t.invDigit(),
                    this.mpl = 32767 & this.mp,
                    this.mph = this.mp >> 15,
                    this.um = (1 << t.DB - 15) - 1,
                    this.mt2 = 2 * t.t
                }
                return l.prototype.convert = function(t) {
                    return t.s < 0 || t.compareTo(this.m) >= 0 ? t.mod(this.m) : t
                }
                ,
                l.prototype.revert = function(t) {
                    return t
                }
                ,
                l.prototype.reduce = function(t) {
                    t.divRemTo(this.m, null, t)
                }
                ,
                l.prototype.mulTo = function(t, e, n) {
                    t.multiplyTo(e, n),
                    this.reduce(n)
                }
                ,
                l.prototype.sqrTo = function(t, e) {
                    t.squareTo(e),
                    this.reduce(e)
                }
                ,
                d.prototype.convert = function(t) {
                    var i = n();
                    return t.abs().dlShiftTo(this.m.t, i),
                    i.divRemTo(this.m, null, i),
                    t.s < 0 && i.compareTo(e.ZERO) > 0 && this.m.subTo(i, i),
                    i
                }
                ,
                d.prototype.revert = function(t) {
                    var e = n();
                    return t.copyTo(e),
                    this.reduce(e),
                    e
                }
                ,
                d.prototype.reduce = function(t) {
                    for (; t.t <= this.mt2; )
                        t[t.t++] = 0;
                    for (var e = 0; e < this.m.t; ++e) {
                        var n = 32767 & t[e]
                          , i = n * this.mpl + ((n * this.mph + (t[e] >> 15) * this.mpl & this.um) << 15) & t.DM;
                        for (t[n = e + this.m.t] += this.m.am(0, i, t, e, 0, this.m.t); t[n] >= t.DV; )
                            t[n] -= t.DV,
                            t[++n]++
                    }
                    t.clamp(),
                    t.drShiftTo(this.m.t, t),
                    t.compareTo(this.m) >= 0 && t.subTo(this.m, t)
                }
                ,
                d.prototype.mulTo = function(t, e, n) {
                    t.multiplyTo(e, n),
                    this.reduce(n)
                }
                ,
                d.prototype.sqrTo = function(t, e) {
                    t.squareTo(e),
                    this.reduce(e)
                }
                ,
                e.prototype.copyTo = function(t) {
                    for (var e = this.t - 1; e >= 0; --e)
                        t[e] = this[e];
                    t.t = this.t,
                    t.s = this.s
                }
                ,
                e.prototype.fromInt = function(t) {
                    this.t = 1,
                    this.s = t < 0 ? -1 : 0,
                    t > 0 ? this[0] = t : t < -1 ? this[0] = t + DV : this.t = 0
                }
                ,
                e.prototype.fromString = function(t, n) {
                    var i;
                    if (16 == n)
                        i = 4;
                    else if (8 == n)
                        i = 3;
                    else if (256 == n)
                        i = 8;
                    else if (2 == n)
                        i = 1;
                    else if (32 == n)
                        i = 5;
                    else {
                        if (4 != n)
                            return void this.fromRadix(t, n);
                        i = 2
                    }
                    this.t = 0,
                    this.s = 0;
                    for (var o = t.length, r = !1, a = 0; --o >= 0; ) {
                        var c = 8 == i ? 255 & t[o] : s(t, o);
                        c < 0 ? "-" == t.charAt(o) && (r = !0) : (r = !1,
                        0 === a ? this[this.t++] = c : a + i > this.DB ? (this[this.t - 1] |= (c & (1 << this.DB - a) - 1) << a,
                        this[this.t++] = c >> this.DB - a) : this[this.t - 1] |= c << a,
                        (a += i) >= this.DB && (a -= this.DB))
                    }
                    8 == i && 0 != (128 & t[0]) && (this.s = -1,
                    a > 0 && (this[this.t - 1] |= (1 << this.DB - a) - 1 << a)),
                    this.clamp(),
                    r && e.ZERO.subTo(this, this)
                }
                ,
                e.prototype.clamp = function() {
                    for (var t = this.s & this.DM; this.t > 0 && this[this.t - 1] == t; )
                        --this.t
                }
                ,
                e.prototype.dlShiftTo = function(t, e) {
                    var n;
                    for (n = this.t - 1; n >= 0; --n)
                        e[n + t] = this[n];
                    for (n = t - 1; n >= 0; --n)
                        e[n] = 0;
                    e.t = this.t + t,
                    e.s = this.s
                }
                ,
                e.prototype.drShiftTo = function(t, e) {
                    for (var n = t; n < this.t; ++n)
                        e[n - t] = this[n];
                    e.t = Math.max(this.t - t, 0),
                    e.s = this.s
                }
                ,
                e.prototype.lShiftTo = function(t, e) {
                    var n, i = t % this.DB, o = this.DB - i, r = (1 << o) - 1, a = Math.floor(t / this.DB), s = this.s << i & this.DM;
                    for (n = this.t - 1; n >= 0; --n)
                        e[n + a + 1] = this[n] >> o | s,
                        s = (this[n] & r) << i;
                    for (n = a - 1; n >= 0; --n)
                        e[n] = 0;
                    e[a] = s,
                    e.t = this.t + a + 1,
                    e.s = this.s,
                    e.clamp()
                }
                ,
                e.prototype.rShiftTo = function(t, e) {
                    e.s = this.s;
                    var n = Math.floor(t / this.DB);
                    if (n >= this.t)
                        e.t = 0;
                    else {
                        var i = t % this.DB
                          , o = this.DB - i
                          , r = (1 << i) - 1;
                        e[0] = this[n] >> i;
                        for (var a = n + 1; a < this.t; ++a)
                            e[a - n - 1] |= (this[a] & r) << o,
                            e[a - n] = this[a] >> i;
                        i > 0 && (e[this.t - n - 1] |= (this.s & r) << o),
                        e.t = this.t - n,
                        e.clamp()
                    }
                }
                ,
                e.prototype.subTo = function(t, e) {
                    for (var n = 0, i = 0, o = Math.min(t.t, this.t); n < o; )
                        i += this[n] - t[n],
                        e[n++] = i & this.DM,
                        i >>= this.DB;
                    if (t.t < this.t) {
                        for (i -= t.s; n < this.t; )
                            i += this[n],
                            e[n++] = i & this.DM,
                            i >>= this.DB;
                        i += this.s
                    } else {
                        for (i += this.s; n < t.t; )
                            i -= t[n],
                            e[n++] = i & this.DM,
                            i >>= this.DB;
                        i -= t.s
                    }
                    e.s = i < 0 ? -1 : 0,
                    i < -1 ? e[n++] = this.DV + i : i > 0 && (e[n++] = i),
                    e.t = n,
                    e.clamp()
                }
                ,
                e.prototype.multiplyTo = function(t, n) {
                    var i = this.abs()
                      , o = t.abs()
                      , r = i.t;
                    for (n.t = r + o.t; --r >= 0; )
                        n[r] = 0;
                    for (r = 0; r < o.t; ++r)
                        n[r + i.t] = i.am(0, o[r], n, r, 0, i.t);
                    n.s = 0,
                    n.clamp(),
                    this.s != t.s && e.ZERO.subTo(n, n)
                }
                ,
                e.prototype.squareTo = function(t) {
                    var e, n = this.abs();
                    for (e = t.t = 2 * n.t; --e >= 0; )
                        t[e] = 0;
                    for (e = 0; e < n.t - 1; ++e) {
                        var i = n.am(e, n[e], t, 2 * e, 0, 1);
                        (t[e + n.t] += n.am(e + 1, 2 * n[e], t, 2 * e + 1, i, n.t - e - 1)) >= n.DV && (t[e + n.t] -= n.DV,
                        t[e + n.t + 1] = 1)
                    }
                    t.t > 0 && (t[t.t - 1] += n.am(e, n[e], t, 2 * e, 0, 1)),
                    t.s = 0,
                    t.clamp()
                }
                ,
                e.prototype.divRemTo = function(t, i, o) {
                    var r = t.abs();
                    if (!(r.t <= 0)) {
                        var a = this.abs();
                        if (a.t < r.t)
                            return SYNO.SDS.isEmpty(i) || i.fromInt(0),
                            void (SYNO.SDS.isEmpty(o) || this.copyTo(o));
                        SYNO.SDS.isEmpty(o) && (o = n());
                        var s = n()
                          , c = this.s
                          , l = t.s
                          , d = this.DB - u(r[r.t - 1]);
                        d > 0 ? (r.lShiftTo(d, s),
                        a.lShiftTo(d, o)) : (r.copyTo(s),
                        a.copyTo(o));
                        var h = s.t
                          , f = s[h - 1];
                        if (0 !== f) {
                            var p = f * (1 << this.F1) + (h > 1 ? s[h - 2] >> this.F2 : 0)
                              , S = this.FV / p
                              , m = (1 << this.F1) / p
                              , g = 1 << this.F2
                              , v = o.t
                              , y = v - h
                              , b = SYNO.SDS.isEmpty(i) ? n() : i;
                            for (s.dlShiftTo(y, b),
                            o.compareTo(b) >= 0 && (o[o.t++] = 1,
                            o.subTo(b, o)),
                            e.ONE.dlShiftTo(h, b),
                            b.subTo(s, s); s.t < h; )
                                s[s.t++] = 0;
                            for (; --y >= 0; ) {
                                var w = o[--v] == f ? this.DM : Math.floor(o[v] * S + (o[v - 1] + g) * m);
                                if ((o[v] += s.am(0, w, o, y, 0, h)) < w)
                                    for (s.dlShiftTo(y, b),
                                    o.subTo(b, o); o[v] < --w; )
                                        o.subTo(b, o)
                            }
                            SYNO.SDS.isEmpty(i) || (o.drShiftTo(h, i),
                            c != l && e.ZERO.subTo(i, i)),
                            o.t = h,
                            o.clamp(),
                            d > 0 && o.rShiftTo(d, o),
                            c < 0 && e.ZERO.subTo(o, o)
                        }
                    }
                }
                ,
                e.prototype.invDigit = function() {
                    if (this.t < 1)
                        return 0;
                    var t = this[0];
                    if (0 == (1 & t))
                        return 0;
                    var e = 3 & t;
                    return (e = (e = (e = (e = e * (2 - (15 & t) * e) & 15) * (2 - (255 & t) * e) & 255) * (2 - ((65535 & t) * e & 65535)) & 65535) * (2 - t * e % this.DV) % this.DV) > 0 ? this.DV - e : -e
                }
                ,
                e.prototype.isEven = function() {
                    return 0 === (this.t > 0 ? 1 & this[0] : this.s)
                }
                ,
                e.prototype.exp = function(t, i) {
                    if (t > 4294967295 || t < 1)
                        return e.ONE;
                    var o = n()
                      , r = n()
                      , a = i.convert(this)
                      , s = u(t) - 1;
                    for (a.copyTo(o); --s >= 0; )
                        if (i.sqrTo(o, r),
                        (t & 1 << s) > 0)
                            i.mulTo(r, a, o);
                        else {
                            var c = o;
                            o = r,
                            r = c
                        }
                    return i.revert(o)
                }
                ,
                e.prototype.toString = function(t) {
                    if (this.s < 0)
                        return "-" + this.negate().toString(t);
                    var e;
                    if (16 == t)
                        e = 4;
                    else if (8 == t)
                        e = 3;
                    else if (2 == t)
                        e = 1;
                    else if (32 == t)
                        e = 5;
                    else {
                        if (4 != t)
                            return this.toRadix(t);
                        e = 2
                    }
                    var n, i = (1 << e) - 1, o = !1, r = "", s = this.t, c = this.DB - s * this.DB % e;
                    if (s-- > 0)
                        for (c < this.DB && (n = this[s] >> c) > 0 && (o = !0,
                        r = a(n)); s >= 0; )
                            c < e ? (n = (this[s] & (1 << c) - 1) << e - c,
                            n |= this[--s] >> (c += this.DB - e)) : (n = this[s] >> (c -= e) & i,
                            c <= 0 && (c += this.DB,
                            --s)),
                            n > 0 && (o = !0),
                            o && (r += a(n));
                    return o ? r : "0"
                }
                ,
                e.prototype.negate = function() {
                    var t = n();
                    return e.ZERO.subTo(this, t),
                    t
                }
                ,
                e.prototype.abs = function() {
                    return this.s < 0 ? this.negate() : this
                }
                ,
                e.prototype.compareTo = function(t) {
                    var e = this.s - t.s;
                    if (0 !== e)
                        return e;
                    var n = this.t;
                    if (0 != (e = n - t.t))
                        return e;
                    for (; --n >= 0; )
                        if (0 != (e = this[n] - t[n]))
                            return e;
                    return 0
                }
                ,
                e.prototype.bitLength = function() {
                    return this.t <= 0 ? 0 : this.DB * (this.t - 1) + u(this[this.t - 1] ^ this.s & this.DM)
                }
                ,
                e.prototype.mod = function(t) {
                    var i = n();
                    return this.abs().divRemTo(t, null, i),
                    this.s < 0 && i.compareTo(e.ZERO) > 0 && t.subTo(i, i),
                    i
                }
                ,
                e.prototype.modPowInt = function(t, e) {
                    var n;
                    return n = t < 256 || e.isEven() ? new l(e) : new d(e),
                    this.exp(t, n)
                }
                ,
                e.ZERO = c(0),
                e.ONE = c(1),
                e
            }()
        },
        109: function() {
            SYNO.ns("SYNO.Encryption"),
            SYNO.Encryption.SecureRandom = function() {
                function t() {
                    this.i = 0,
                    this.j = 0,
                    this.S = []
                }
                var e, n, i;
                function o() {
                    var t;
                    t = (new Date).getTime(),
                    n[i++] ^= 255 & t,
                    n[i++] ^= t >> 8 & 255,
                    n[i++] ^= t >> 16 & 255,
                    n[i++] ^= t >> 24 & 255,
                    i >= 256 && (i -= 256)
                }
                if (t.prototype.init = function(t) {
                    var e, n, i;
                    for (e = 0; e < 256; ++e)
                        this.S[e] = e;
                    for (n = 0,
                    e = 0; e < 256; ++e)
                        n = n + this.S[e] + t[e % t.length] & 255,
                        i = this.S[e],
                        this.S[e] = this.S[n],
                        this.S[n] = i;
                    this.i = 0,
                    this.j = 0
                }
                ,
                t.prototype.next = function() {
                    var t;
                    return this.i = this.i + 1 & 255,
                    this.j = this.j + this.S[this.i] & 255,
                    t = this.S[this.i],
                    this.S[this.i] = this.S[this.j],
                    this.S[this.j] = t,
                    this.S[t + this.S[this.i] & 255]
                }
                ,
                SYNO.SDS.isEmpty(n)) {
                    var r;
                    if (n = [],
                    i = 0,
                    "Netscape" == navigator.appName && navigator.appVersion < "5" && window.crypto) {
                        var a = window.crypto.random(32);
                        for (r = 0; r < a.length; ++r)
                            n[i++] = 255 & a.charCodeAt(r)
                    }
                    for (; i < 256; )
                        r = Math.floor(65536 * Math.random()),
                        n[i++] = r >>> 8,
                        n[i++] = 255 & r;
                    i = 0,
                    o()
                }
                function s() {
                    if (SYNO.SDS.isEmpty(e)) {
                        for (o(),
                        (e = new t).init(n),
                        i = 0; i < n.length; ++i)
                            n[i] = 0;
                        i = 0
                    }
                    return e.next()
                }
                function c() {}
                return c.prototype.nextBytes = function(t) {
                    var e;
                    for (e = 0; e < t.length; ++e)
                        t[e] = s()
                }
                ,
                c.rng_seed_time = o,
                c
            }()
        },
        730: function() {
            SYNO.ns("SYNO.Encryption"),
            SYNO.Encryption.RSA = function() {
                function t() {
                    this.n = null,
                    this.e = 0,
                    this.d = null,
                    this.p = null,
                    this.q = null,
                    this.dmp1 = null,
                    this.dmq1 = null,
                    this.coeff = null
                }
                return t.prototype.doPublic = function(t) {
                    return t.modPowInt(this.e, this.n)
                }
                ,
                t.prototype.setPublic = function(t, e) {
                    var n;
                    !Ext.isEmpty(t) && !Ext.isEmpty(e) && t.length > 0 && e.length > 0 && (this.n = (n = t,
                    16,
                    new SYNO.Encryption.BigInteger(n,16)),
                    this.e = parseInt(e, 16))
                }
                ,
                t.prototype.encrypt = function(t) {
                    var e = function(t, e) {
                        if (e < t.length + 11)
                            return null;
                        for (var n = [], i = t.length - 1; i >= 0 && e > 0; ) {
                            var o = t.charCodeAt(i--);
                            o < 128 ? n[--e] = o : o > 127 && o < 2048 ? (n[--e] = 63 & o | 128,
                            n[--e] = o >> 6 | 192) : (n[--e] = 63 & o | 128,
                            n[--e] = o >> 6 & 63 | 128,
                            n[--e] = o >> 12 | 224)
                        }
                        n[--e] = 0;
                        for (var r = new SYNO.Encryption.SecureRandom, a = []; e > 2; ) {
                            for (a[0] = 0; 0 === a[0]; )
                                r.nextBytes(a);
                            n[--e] = a[0]
                        }
                        return n[--e] = 2,
                        n[--e] = 0,
                        new SYNO.Encryption.BigInteger(n)
                    }(t, this.n.bitLength() + 7 >> 3);
                    if (Ext.isEmpty(e))
                        return null;
                    var n = this.doPublic(e);
                    if (Ext.isEmpty(n))
                        return null;
                    var i = n.toString(16);
                    return 0 == (1 & i.length) ? i : "0" + i
                }
                ,
                t
            }()
        },
        469: function() {
            var t;
            SYNO.ns("SYNO.Encryption"),
            SYNO.Encryption.CipherKey = "",
            SYNO.Encryption.RSAModulus = "",
            SYNO.Encryption.CipherToken = "",
            SYNO.Encryption.TimeBias = 0,
            SYNO.Encryption.RandomUint8 = function(t) {
                try {
                    var e = new Uint8Array(1);
                    if (!(e && e.buffer instanceof ArrayBuffer && void 0 !== e.byteLength))
                        throw new Error("byte array is invalid");
                    if (window.crypto && window.crypto.getRandomValues)
                        window.crypto.getRandomValues(e);
                    else {
                        if (!window.msCrypto || !window.msCrypto.getRandomValues)
                            throw new Error("there are not valid crypto");
                        window.msCrypto.getRandomValues(e)
                    }
                    var n = t + 1;
                    return e[0] >= Math.floor(256 / n) * n ? SYNO.Encryption.RandomUint8(t) : e[0] % n
                } catch (e) {
                    return SYNO.Debug.error(e),
                    Math.floor(Math.random() * (t + 1))
                }
            }
            ,
            SYNO.Encryption.GenRandomKey = (t = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ~!@#$%^&*()_+-/".split(""),
            function(e) {
                for (var n = []; e > 0; )
                    n.push(t[SYNO.Encryption.RandomUint8(t.length - 1)]),
                    e--;
                return n.join("")
            }
            ),
            SYNO.Encryption.EncryptParam = function(t) {
                var e, n, i, o = {}, r = {}, a = SYNO.Encryption.GenRandomKey(501);
                return SYNO.Encryption.CipherKey && SYNO.Encryption.RSAModulus && SYNO.Encryption.CipherToken ? ((e = new SYNO.Encryption.RSA).setPublic(SYNO.Encryption.RSAModulus, "10001"),
                o[SYNO.Encryption.CipherToken] = Math.floor(+new Date / 1e3) + SYNO.Encryption.TimeBias,
                (n = e.encrypt(a)) ? (Ext.apply(o, t),
                (i = SYNO.Encryption.AES.encrypt(Ext.urlEncode(o), a).toString()) ? (r[SYNO.Encryption.CipherKey] = JSON.stringify({
                    rsa: SYNO.Encryption.Base64.hex2b64(n),
                    aes: i
                }),
                r) : t) : t) : t
            }
        },
        429: function() {
            var t, e;
            SYNO.SDS.LoginInitUtils = (t = SYNO.SDS.Utils.UserAgent,
            e = function() {
                synowebapi.promises.request({
                    api: "SYNO.Core.Desktop.PersonalUpdater",
                    method: "need_update",
                    version: 1
                }).then((t => {
                    if (t.need_update)
                        SYNO.CreateLoginInstance({
                            goToPersonalUpdater: !0
                        });
                    else if (SYNO.SDS.initData(),
                    "1" === SYNO.SDS.GetCookieByName("stay_login")) {
                        var e = new Date;
                        e.setDate(e.getDate() + 30);
                        var n = SYNO.SDS.GetCookieByName("id");
                        SYNO.SDS.SetCookie("id", n, e)
                    }
                }
                )).catch((t => {
                    SYNO.Debug.error(t),
                    SYNO.SDS.initData()
                }
                ))
            }
            ,
            {
                IEUpgradeAlert: function() {
                    return (t.isIE6 || t.isIE7 || t.isIE8 || t.isIE9 || t.isIE10) && (SYNO.SDS.GetCookieByName("skip_upgrade_ie_alert") || (new SYNO.SDS.IEUpgradeAlert).show()),
                    this
                },
                disableKeyboardEvent: function() {
                    return SYNO.Debug("disable keyboard event is unnecessary, please stop calling this function"),
                    this
                },
                disableRightClick: function() {
                    return SYNO.SDS.GetBody().addEventListener("contextmenu", (function(t) {
                        (function(t) {
                            if (t.target.closest(".selectabletext"))
                                return !0;
                            if (t.target.closest("textarea"))
                                return !0;
                            var e = t.target.closest("input")
                              , n = e && e.type ? e.type.toLowerCase() : "";
                            return ("text" === n || "textarea" === n || "password" === n) && !e.readOnly
                        }
                        )(t) || t.target.closest(".allowDefCtxMenu") || (t.stopPropagation(),
                        t.preventDefault())
                    }
                    )),
                    this
                },
                initHTML5Upload: function() {
                    return SYNO.SDS.HTML5Utils.isSupportHTML5Upload() && SYNO.SDS.GetBody().addEventListener("dragover", (function(t) {
                        SYNO.SDS.HTML5Utils.isDragFile(t) && (t.preventDefault(),
                        t.dataTransfer.dropEffect = "none")
                    }
                    )),
                    this
                },
                defaultCSSSelectors: function() {
                    var e = SYNO.SDS.GetBody();
                    return _S("diskless") && e.classList.add("syno-diskless"),
                    t.isIE10Touch && e.classList.add("syno-ie10-touch"),
                    void 0 !== SYNO.SDS.Utils.GetURLParam(location.search.substr(1)).accessible && e.classList.add("accessible"),
                    this
                },
                initSSO: function() {
                    return SYNO.SDS.SSOUtils.init(),
                    this
                },
                checkTokenLogin: function() {
                    if (!0 === _S("isLogined"))
                        return Promise.resolve();
                    var t = _S("sso_custom_param_name")
                      , e = SYNO.SDS.Utils.GetURLParam(location.search.substr(1))
                      , n = void 0;
                    if (t && e && e[t] && ((n = {})[t] = e[t],
                    n.type = "sso"),
                    "object" == typeof e && "sig"in e && 1 === Object.keys(e).length) {
                        n = {
                            sig: e.sig,
                            type: "support"
                        };
                        let t = new URL(window.location.href);
                        t.searchParams.delete("sig"),
                        history.replaceState({}, "", t)
                    }
                    if ("object" == typeof e && "auth_key"in e) {
                        n = {
                            auth_key: e.auth_key,
                            type: "auth_key"
                        };
                        let t = new URL(window.location.href);
                        t.searchParams.delete("auth_key"),
                        history.replaceState({}, "", t)
                    }
                    return !n && (-1 < navigator.userAgent.toLowerCase().indexOf("window") || -1 < navigator.userAgent.toLowerCase().indexOf("win32")) && !1 === _S("isLogined") && !0 === _S("enable_http_negotiate") && (n = {
                        negotiate: Math.floor(window.performance.now())
                    }),
                    n ? new Promise((function(t, e) {
                        synowebapi.promises.request({
                            api: "SYNO.API.Auth.Type",
                            version: 1,
                            method: "get"
                        }).then(( () => {
                            synowebapi.request({
                                url: "webapi/entry.cgi?api=SYNO.API.Auth",
                                requestFormat: "raw",
                                responseFormat: "raw",
                                method: "GET",
                                params: SYNO.SDS.HandShake.GetLoginParams(n),
                                callback: function(e, n) {
                                    if (!0 === n.success) {
                                        SYNO.SDS.Session.isLogined = !0;
                                        let e = SYNO.SDS.HandShake.GetLoginSynoToken(n);
                                        SYNO.SDS.isEmpty(e) || (SYNO.SDS.Session.SynoToken = e),
                                        t()
                                    } else
                                        t()
                                },
                                scope: this
                            })
                        }
                        ))
                    }
                    )) : Promise.resolve()
                },
                initHDPack: function() {
                    return SYNO.SDS.UIFeatures.IconSizeManager.addHDClsAndCSS(),
                    this
                },
                initLoginInstance: function() {
                    if (void 0 !== SYNO.SDS.ForgotPass)
                        SYNO.ShowResetForgotPassword();
                    else if (_S("isLogined") && -1 === window.location.search.indexOf("force_login=yes"))
                        _S("preview") ? SYNO.CreateLoginInstance() : "no" !== _S("enable_syno_token") ? SYNO.API.UpdateSynoToken(e) : e();
                    else if (0 < window.location.search.indexOf("SynoToken=")) {
                        var t = window.location.search.replace(/(&|\?)SynoToken=[^&]*/, "").replace(/^&/, "?");
                        window.location.href = window.location.origin + window.location.pathname + t
                    } else if (_S("public_access"))
                        e();
                    else if (document.getElementById("logined-default-admin"))
                        if (!1 !== _S("isLogined") || localStorage.getItem("newInstallRedirectedHTTPS"))
                            localStorage.removeItem("newInstallRedirectedHTTPS"),
                            window.loginLang = _S("lang"),
                            SYNO.CreateLoginInstance();
                        else {
                            var n = "https://" + window.location.hostname + ":5001/webapi/entry.cgi?";
                            n += "api=SYNO.API.Auth&version=7&method=logout&redirect_url=",
                            n += encodeURIComponent(window.location.href),
                            window.location.href = n,
                            localStorage.setItem("newInstallRedirectedHTTPS", "1")
                        }
                    else
                        window.loginLang = _S("lang"),
                        SYNO.CreateLoginInstance();
                    return this
                }
            }),
            SYNO.SDS.DestroyLoginInstance = function() {
                SYNO.LoginInstance && (SYNO.LoginInstance.$destroy(),
                SYNO.LoginInstance = null)
            }
        },
        738: function() {
            SYNO.SDS._LoginPlugins = class {
                constructor() {
                    this._registerQueue = [],
                    this._plugins = {}
                }
                get plugins() {
                    return this._plugins
                }
                getPlugin(t) {
                    return this._plugins[t]
                }
                register(t) {
                    this._registerQueue.push(t)
                }
                unregister(t) {
                    void 0 !== this._plugins[t] && (this._plugins[t] = null,
                    delete this._plugins[t])
                }
                loadPlugins(t, e, n, i, o) {
                    for (let r of this._registerQueue) {
                        let a = new r(t,e,i,o)
                          , s = a.id;
                        void 0 === s && SYNO.Debug("Error: Must provide plugin id"),
                        void 0 !== this._plugins[s] && SYNO.Debug(`Warning: Login plugin ${s} already exists.`),
                        this._plugins[s] = a,
                        void 0 !== n && n(s, a)
                    }
                    return this._plugins
                }
                release() {
                    for (let t in this._plugins)
                        this.unregister(t);
                    this._plugins = null,
                    this._registerQueue = null
                }
            }
            ,
            SYNO.SDS.LoginPlugins = new SYNO.SDS._LoginPlugins
        },
        377: function() {
            SYNO.SDS.LoginStyleParser = function(t) {
                this.isPreview = t.isPreview,
                this.parseAppPortalName(),
                this.parseTpl()
            }
            ;
            var t = {
                getParam: function(t) {
                    var e;
                    return this.isPreview && window.opener && window.opener.previewParam ? ("string" == typeof (e = window.opener.previewParam[t]) || e instanceof String) && (e = SYNO.SDS.htmlEncode(e)) : e = _S(t),
                    e
                },
                parseAppPortalName: function() {
                    var t = _S("preview_appName") || _S("appName");
                    this.appName = t ? t + "_" : ""
                },
                parseTpl: function() {
                    var t = this.getParam("login_style");
                    this.tpl = "dark" === t ? "dark" : "light"
                },
                getLoginConfig: function() {
                    var t = {
                        tplName: this.tpl,
                        preview: this.isPreview
                    };
                    return Object.assign(t, this.getTitleConf()),
                    Object.assign(t, this.getCustomizeLogoConf()),
                    Object.assign(t, this.getWelcomeMsgConf()),
                    Object.assign(t, this.getBkgConf()),
                    Object.assign(t, this.getVersionLogoConf()),
                    t
                },
                getBkgConf: function() {
                    var t = this.getRawBkgConf()
                      , e = t.background_enable
                      , n = t.only_bgcolor;
                    return e ? this.isPreview && this.getParam("new_background") ? t.background_path = this.getEncodedPathUrl(this.getParam("login_background_path")) : t.background_path = this.getBuiltInPath(t) : n ? t.background_path = SYNO.SDS.GetBlankImageUrl() : t = this.getDefaultBkgConf(),
                    t
                },
                getVersionLogoConf: function() {
                    var t = this.getParam("login_version_logo");
                    return {
                        versionLogo: !SYNO.SDS.isDefined(t) || t
                    }
                },
                getRawBkgConf: function() {
                    return {
                        background_enable: this.getParam("login_background_enable"),
                        background_pos: this.getParam("login_background_pos") || "fill",
                        only_bgcolor: this.getParam("login_only_bgcolor"),
                        background_color: this.getParam("login_background_color") || "#FFFFFF",
                        ext: _S("login_background_ext"),
                        idx: _S("login_background_seq"),
                        background_width: _S("login_background_width"),
                        background_height: _S("login_background_height")
                    }
                },
                getDefaultBkgConf: function() {
                    var t, e = "webman/resources/images/2x/default_login_background/", n = {
                        background_pos: "fill",
                        background_path: e + "dsm7_01.jpg?v=" + _S("version"),
                        background_color: "#505050"
                    }, i = {
                        background_pos: "fill",
                        background_path: e + "dsm7_01.jpg?v=" + _S("version"),
                        background_color: "#4c8fbf"
                    };
                    t = "dark" === this.tpl ? n : i;
                    var o = this.getPkgDefBgPath(!0);
                    return null !== o && (t.background_path = o),
                    this.isDVA() && (t.background_path = SYNO.SDS.formatString("webman/3rdparty/SurveillanceStation/resources/images/{0}/ssIcon/wallpaper_surveillance_station.jpg", this.isRetina() ? "2x" : "1x")),
                    t
                },
                isDVA: function() {
                    return navigator.userAgent.includes("SurvLocalDisplay")
                },
                isRetina: function() {
                    return SYNO.SDS.UIFeatures.IconSizeManager.isRetinaMode()
                },
                isBuiltInBkg2X: function() {
                    var t = "default" === this.getParam("login_background_type")
                      , e = this.isRetina();
                    return t && e
                },
                getEncodedPathUrl: function(t) {
                    if (this.isPreview && "pkgDefault" === this.getParam("login_background_type"))
                        return t.replace("/usr/syno/synoman/", "");
                    var e = new Date;
                    return SYNO.SDS.urlAppend("webapi/entry.cgi", SYNO.SDS.urlEncode({
                        api: "SYNO.Core.PersonalSettings",
                        method: "wallpaper",
                        version: 1,
                        path: JSON.stringify(SYNO.SDS.Utils.bin2hex(t)),
                        preview: e.getTime()
                    }))
                },
                getBuiltInPath: function(t) {
                    var e = this.getPkgDefBgPath(this.isBuiltInBkg2X());
                    return null !== e && 0 === t.idx ? e : `webman/${this.appName}login_background${t.ext}?id=${t.idx}`
                },
                getTitleConf: function() {
                    var t = this.getParam("custom_login_title");
                    return {
                        login_title: t || _S("hostname"),
                        has_custom_title: Boolean(t)
                    }
                },
                getCustomizeLogoConf: function() {
                    var t = {
                        logo_enable: this.getParam("login_logo_enable")
                    };
                    return this.isPreview && t.logo_enable && this.getParam("new_logo") ? t.logo_path = this.getEncodedPathUrl(this.getParam("login_logo_path")) : t.logo_enable && (t.logo_path = "webman/" + this.appName + "login_logo" + _S("login_logo_ext") + "?id=" + _S("login_logo_seq")),
                    t
                },
                getWelcomeMsgConf: function() {
                    return {
                        login_welcome_title: this.getParam("login_welcome_title") || "",
                        login_welcome_msg: this.getParam("login_welcome_msg") || ""
                    }
                },
                getPkgDefBgPath: function(t) {
                    return SYNO.SDS.Session && SYNO.SDS.Session.appLoginStyle && SYNO.SDS.Session.appLoginStyle.defaultLoginWallpaper && SYNO.SDS.Session.appLoginStyle.defaultLoginWallpaperThumbnail ? SYNO.SDS.formatString(SYNO.SDS.Session.appLoginStyle.defaultLoginWallpaper, t ? "2x" : "1x") : null
                }
            };
            Object.assign(SYNO.SDS.LoginStyleParser.prototype, t)
        },
        874: function() {
            var t, e, n;
            SYNO.SDS.SSOUtils = function() {
                return {
                    callbackFn: {
                        fn: function() {},
                        scope: this
                    },
                    setCallback: function(t, e) {
                        this.callbackFn.fn = t,
                        SYNO.SDS.isDefined(e) && (this.callbackFn.scope = e)
                    },
                    isSupport: function() {
                        try {
                            const t = new URL(new URLSearchParams(location.search).get("redirect_uri"));
                            if (null !== new URLSearchParams(location.search).get("synossoJSSDK") && t.origin === location.origin && t.pathname === location.pathname)
                                return !1
                        } catch (t) {
                            SYNO.Debug(t)
                        }
                        return _S("sso_support") && _S("sso_server") && _S("sso_appid") && "SYNOSSO"in window && SYNOSSO && SYNO.SDS.isFunction(SYNOSSO.init)
                    },
                    getSynoSSOToken: function() {
                        return "undefined" == typeof SYNOSSO ? void 0 : SYNOSSO.access_token
                    },
                    forceLocationReplace: function(t) {
                        const e = t.indexOf("?")
                          , n = t.indexOf("#");
                        let i;
                        i = -1 === e ? "?" : -1 === n ? t : t.substring(e, n),
                        i === window.location.search && window.addEventListener("hashchange", ( () => {
                            window.location.hash.startsWith("#access_token=") && (SYNO.Debug("work around, vue router do not reload page."),
                            location.reload())
                        }
                        ), !1),
                        window.location.replace(t)
                    },
                    checkSynoSSORedirect: function(t) {
                        if (!this.isSupport())
                            return !1;
                        if (!t.access_token || !t.state)
                            return SYNO.Debug("not yet redirect."),
                            !1;
                        const e = t.state.substr(8);
                        if (0 != e.length)
                            try {
                                let n = new URL(window.atob(e));
                                if (window.location.hostname !== n.hostname)
                                    return window.alert(_T("login", "sso_oidc_mismatch_url_error_msg")),
                                    SYNO.Debug.error("not yet redirect."),
                                    !1;
                                let i = new URLSearchParams(n.search);
                                if (i.get("redirect_uri") && "/" !== i.get("redirect_uri"))
                                    return SYNO.Debug("give access token back."),
                                    this.forceLocationReplace(SYNO.SDS.formatString("{0}#access_token={1}&state={2}", n.search, t.access_token, t.state.substr(0, 8))),
                                    !0;
                                if ("/" !== i.get("redirect_uri") && (n.search || window.origin !== n.origin || window.location.pathname !== n.pathname))
                                    return SYNO.Debug("give window.location.search back."),
                                    this.forceLocationReplace(SYNO.SDS.formatString("{0}{1}{2}#access_token={3}&state={4}", n.origin, n.pathname, n.search, t.access_token, t.state.substr(0, 8))),
                                    !0
                            } catch (t) {
                                return SYNO.Debug("not yet redirect."),
                                !1
                            }
                        return 8 > t.state.length || !window.localStorage.getItem("synosso_state") ? (SYNO.Debug("not yet redirect."),
                        !1) : 0 !== t.state.indexOf(window.localStorage.getItem("synosso_state")) ? (SYNO.Debug.error("not our redirect back."),
                        !1) : (window.localStorage.removeItem("synosso_state"),
                        SYNOSSO.access_token = t.access_token,
                        !1)
                    },
                    server_url: "",
                    redirect_uri: "",
                    app_id: "",
                    init: function(t, e) {
                        if (this.isSupport())
                            if (SYNO.SDS.isString(SYNOSSO.version))
                                this.server_url = _S("sso_server"),
                                this.redirect_uri = encodeURIComponent(document.URL.split("#")[0]),
                                this.app_id = _S("sso_appid"),
                                t.bind(e)({
                                    status: "not login"
                                });
                            else {
                                this.setCallback(t, e);
                                try {
                                    SYNOSSO.init({
                                        oauthserver_url: _S("sso_server"),
                                        app_id: _S("sso_appid"),
                                        redirect_uri: document.URL,
                                        callback: this.callback.bind(this)
                                    })
                                } catch (t) {}
                            }
                    },
                    callback: function(t) {
                        SYNOSSO.status = t.status,
                        this.callbackFn.fn.call(this.callbackFn.scope, t)
                    },
                    login: function(t, e) {
                        if (this.isSupport())
                            if (SYNO.SDS.isString(SYNOSSO.version)) {
                                const t = window.btoa(SYNO.Encryption.GenRandomKey(6));
                                window.localStorage.setItem("synosso_state", t),
                                window.location.href = this.server_url + "/webman/sso/SSOOauth.cgi?scope=user_id&synossoJSSDK=false&redirect_uri=" + this.redirect_uri + "&app_id=" + this.app_id + "&state=" + t + window.btoa(window.location.href)
                            } else
                                this.setCallback(t, e),
                                SYNOSSO.login()
                    },
                    logout: function() {
                        SYNOSSO.logout()
                    }
                }
            }(),
            SYNO.SDS.OIDCUtils = {
                authUrl: function(t, e) {
                    synowebapi.request({
                        url: "index.cgi?" + SYNO.SDS.urlEncode({
                            action: "oidcauthurl",
                            method: t
                        }),
                        requestFormat: "raw",
                        responseFormat: "webapi",
                        requestMethod: "GET",
                        callback: e
                    })
                },
                genState: function() {
                    return SYNO.SDS.Utils.bin2hex(SYNO.Encryption.GenRandomKey(32))
                },
                login: function(t, e, n, i) {
                    var o = this
                      , r = function(i) {
                        if (i.isTrusted && i.data && i.data.code) {
                            window.removeEventListener("message", r),
                            window.localStorage.removeItem("oidc_state");
                            var o = i.data;
                            o.server = t,
                            e(n, o)
                        }
                    }
                    .bind(this);
                    this.authUrl(t, (function(t, e) {
                        if (t) {
                            var n = o.genState();
                            window.localStorage.setItem("oidc_state", n),
                            window.addEventListener("message", r),
                            _S("isMobileDevice") ? setTimeout(( () => {
                                window.open(e.url + "&state=" + n, "OIDC", i)
                            }
                            )) : window.open(e.url + "&state=" + n, "OIDC", i)
                        } else
                            alert(_T("sso", "error_get_auth_url"))
                    }
                    ))
                }
            },
            SYNO.SDS.AzureSSOUtils = (t = screen.width / 2 - 250,
            e = screen.height / 2 - 300,
            n = SYNO.SDS.formatString("height={0},width={1},left={2},top={3}", 600, 500, t, e),
            {
                login: function(t, e) {
                    SYNO.SDS.OIDCUtils.login("azure", t, e, n)
                },
                logout: function() {
                    var t = "webman/logout.cgi?" + SYNO.SDS.urlEncode({
                        asso: "true"
                    });
                    window.open(t, "OIDC", n)
                }
            }),
            SYNO.SDS.WebSphereSSOUtils = function() {
                var t = screen.width / 2 - 250
                  , e = screen.height / 2 - 300
                  , n = SYNO.SDS.formatString("height={0},width={1},left={2},top={3}", 600, 500, t, e);
                return {
                    login: function(t, e) {
                        SYNO.SDS.OIDCUtils.login("websphere", t, e, n)
                    },
                    logout: function() {
                        var t = "webman/logout.cgi?" + SYNO.SDS.urlEncode({
                            webspheresso: "true"
                        });
                        window.open(t, "OIDC", n)
                    }
                }
            }(),
            SYNO.SDS.OIDCSSOUtils = function() {
                var t = screen.width / 2 - 250
                  , e = screen.height / 2 - 300
                  , n = SYNO.SDS.formatString("height={0},width={1},left={2},top={3}", 600, 500, t, e);
                return {
                    login: function(t, e) {
                        SYNO.SDS.OIDCUtils.login("oidc", t, e, n)
                    }
                }
            }(),
            SYNO.SDS.SSOSAMLUtils = {
                login: function(t, e) {
                    const n = window.location.origin
                      , i = window.btoa(SYNO.Encryption.GenRandomKey(32));
                    window.localStorage.setItem("saml_state", i);
                    let o = new URLSearchParams(window.location.search);
                    o.append("action", "samlauthurl"),
                    o.append("saml_state", i),
                    o.append("acs", n),
                    synowebapi.promises.request({
                        url: "index.cgi?" + o.toString(),
                        requestFormat: "raw",
                        responseFormat: "webapi",
                        requestMethod: "GET"
                    }).then((t => {
                        window.location.href = t.url
                    }
                    )).catch((t => {
                        window.alert(_T("sso", "error_get_auth_url"))
                    }
                    ))
                }
            },
            SYNO.SDS.SSOCASUtils = {
                login(t, e) {
                    window.localStorage.setItem("cas_redirect_uri", window.location.href);
                    const n = location.protocol + "//" + location.hostname + (location.port ? ":" + location.port : "") + location.pathname;
                    let i = new URLSearchParams;
                    i.append("action", "casauthurl"),
                    i.append("redirect_url", n),
                    synowebapi.promises.request({
                        url: "index.cgi?" + i.toString(),
                        requestFormat: "raw",
                        responseFormat: "webapi",
                        requestMethod: "GET"
                    }).then((t => {
                        window.location.href = t.url
                    }
                    )).catch((e => {
                        t(e)
                    }
                    ))
                }
            }
        },
        918: function() {
            function t(t) {
                return ["About"].includes(t)
            }
            SYNO.SDS.UIFeatures = function() {
                var t, e, n, i = SYNO.SDS.Utils.UserAgent, o = {
                    previewBox: !i.isIE || i.isModernIE,
                    expandMenuHideAll: !0,
                    windowGhost: !i.isIE || i.isModernIE,
                    disableWindowShadow: i.isIE && !i.isModernIE,
                    exposeWindow: !i.isIE || i.isIE10p,
                    msPointerEnabled: window.navigator.msPointerEnabled && window.navigator.msMaxTouchPoints > 0,
                    isTouch: "ontouchstart"in window || window.navigator.msPointerEnabled && window.navigator.msMaxTouchPoints > 0,
                    isRetina: (t = !1,
                    window.devicePixelRatio >= 1.5 && (t = !0),
                    window.matchMedia && window.matchMedia("(-webkit-min-device-pixel-ratio: 1.5),(min--moz-device-pixel-ratio: 1.5),(-o-min-device-pixel-ratio: 3/2),(min-resolution: 1.5dppx)").matches && (t = !0),
                    t),
                    isSupportFullScreen: document.fullscreenEnabled || document.webkitFullscreenEnabled || document.mozFullScreenEnabled || document.msFullscreenEnabled
                }, r = SYNO.SDS.Utils.GetURLParam(location.search.substr(1));
                for (e in r)
                    r.hasOwnProperty(e) && (n = r[e],
                    void 0 !== o[e] && (o[e] = "false" !== n));
                return {
                    test: function(t) {
                        return !!o[t]
                    },
                    listAll: function() {
                        var t, e = "== Feature List ==\n";
                        for (t in o)
                            o.hasOwnProperty(t) && (e += SYNO.SDS.formatString("{0}: {1}\n", t, o[t]));
                        return e
                    },
                    isFullScreenMode: function() {
                        return !!(document.fullscreenElement || document.mozFullScreenElement || document.webkitFullscreenElement || document.msFullscreenElement)
                    }
                }
            }(),
            SYNO.SDS.UIFeatures.IconSizeManager = {
                PortalIcon: 64,
                GroupView: 24,
                Taskbar: 24,
                WidgetHeader: 32,
                GroupViewHover: 48,
                Desktop: 64,
                ClassicalDesktop: 48,
                AppView: 72,
                AppViewClassic: 48,
                Header: 24,
                HeaderV4: 16,
                TreeIcon: 16,
                StandaloneHeader: 24,
                FavHeader: 16,
                FinderPreview: 128,
                BackgroundTaskIcon: 32,
                isEnableHDPack: !1,
                cls: "synohdpack",
                debugCls: "synohdpackdebug",
                getAppPortalIconPath: function(t) {
                    var e = this.isRetinaMode()
                      , n = e ? 256 : this.PortalIcon
                      , i = e ? "2x" : "1x";
                    return SYNO.SDS.formatString(t, n, i)
                },
                getIconPath: function(e, n, i) {
                    var o, r, a = "webman/", s = "/synohdpack/images/dsm/", c = this.isRetinaMode(), u = function(t, e, n, i) {
                        return t.replace(e, "48" === e ? "128" : 2 * e)
                    }, l = function(t, e, n, i) {
                        return t.replace(e, "48" === e ? "128" : 2 * e)
                    };
                    if (0 === e.indexOf("webman/3rdparty/") && !t(n))
                        return c = "FavHeader" !== n && c,
                        SYNO.SDS.formatString("webapi/entry.cgi?api=SYNO.Core.Synohdpack&version=1&method=getHDIcon&res={0}&retina={1}&path={2}", this.getRes(n), c, e.replace("{1}", c ? "2x" : "1x"));
                    switch (r = -1 === e.indexOf("{1}") ? c && !t(n) ? (i = i || !1) || -1 !== e.indexOf("shortcut_icons") || -1 !== e.indexOf("webfm/images") ? e : 0 === e.indexOf(a) ? s + e.substr(a.length) : s + e : e : e.replace("{1}", c ? "2x" : "1x"),
                    n) {
                    case "Taskbar":
                        o = SYNO.SDS.formatString(r, c ? 2 * this.Taskbar : this.Taskbar);
                        break;
                    case "Desktop":
                        -1 != r.indexOf("files_ext_48") && "classical" != SYNO.SDS.UserSettings.getProperty("Desktop", "desktopStyle") && (r = r.replace("files_ext_48", "files_ext_64")),
                        -1 != r.indexOf("files_ext_") ? (r = r.replace(/webfm\/images/, c ? "images/2x" : "images/1x"),
                        o = c ? r.replace(/.*\/files_ext_(\d+)\/.*/, u) : r) : -1 != r.indexOf("shortcut_icons") ? (r = r.replace(/images\/default\/.+\/shortcut_icons/, c ? "images/2x/shortcut_icons" : "images/1x/shortcut_icons"),
                        o = c ? r.replace(/.*\/.*_(\d+)\.png$/, l) : r) : o = SYNO.SDS.formatString(r, c ? 256 : this.Desktop);
                        break;
                    case "ClassicalDesktop":
                        -1 != r.indexOf("files_ext_") ? (r = r.replace(/webfm\/images/, c ? "images/2x" : "images/1x"),
                        o = c ? r.replace(/.*\/files_ext_(\d+)\/.*/, u) : r) : -1 != r.indexOf("shortcut_icons") ? (r = r.replace(/images\/default\/.+\/shortcut_icons/, c ? "images/2x/shortcut_icons" : "images/1x/shortcut_icons"),
                        o = c ? r.replace(/.*\/.*_(\d+)\.png$/, l) : r) : o = SYNO.SDS.formatString(r, c ? 256 : this.ClassicalDesktop);
                        break;
                    case "AppView":
                        o = SYNO.SDS.formatString(r, c ? 256 : this.AppView);
                        break;
                    case "AppViewClassic":
                        o = SYNO.SDS.formatString(r, c ? 256 : this.AppViewClassic);
                        break;
                    case "Header":
                        o = SYNO.SDS.formatString(r, c ? 2 * this.Header : this.Header);
                        break;
                    case "HeaderV4":
                        o = SYNO.SDS.formatString(r, c ? 2 * this.HeaderV4 : this.HeaderV4);
                        break;
                    case "StandaloneHeader":
                        o = SYNO.SDS.formatString(r, c ? 2 * this.StandaloneHeader : this.StandaloneHeader);
                        break;
                    case "FavHeader":
                        o = SYNO.SDS.formatString(r, c ? 2 * this.FavHeader : this.FavHeader);
                        break;
                    case "FileType":
                        o = c ? r.replace(/.*\/files_ext_(\d+)\/.*/, u) : r;
                        break;
                    case "TreeIcon":
                        o = SYNO.SDS.formatString(r, c ? 3 * this.TreeIcon : this.TreeIcon);
                        break;
                    case "FinderPreview":
                        o = SYNO.SDS.formatString(r, c ? 256 : 128);
                        break;
                    case "WidgetHeader":
                        o = SYNO.SDS.formatString(r, c ? 2 * this.WidgetHeader : this.WidgetHeader);
                        break;
                    case "BackgroundTaskIcon":
                        o = SYNO.SDS.formatString(r, c ? 2 * this.BackgroundTaskIcon : this.BackgroundTaskIcon);
                        break;
                    case "About":
                        o = SYNO.SDS.formatString(r, "about");
                        break;
                    default:
                        o = r
                    }
                    return -1 == o.indexOf(SYNO.SDS.formatString("?v={0}", _S("fullversion"))) && ".png" === o.substr(o.length - 4) && (o += "?v=" + _S("fullversion")),
                    encodeURI(o)
                },
                enableHDDisplay: function(t) {
                    SYNO.SDS.UIFeatures.IconSizeManager.isEnableHDPack = t
                },
                isRetinaMode: function() {
                    return SYNO.SDS.UIFeatures.test("isRetina") && this.isEnableHDPack
                },
                getRetinaAndSynohdpackStatus: function() {
                    return SYNO.Debug("SYNO.SDS.UIFeatures.IconSizeManager.getRetinaAndSynohdpackStatus() was renamed, please call SYNO.SDS.UIFeatures.IconSizeManager.isRetinaMode() instead."),
                    this.isRetinaMode()
                },
                addHDClsAndCSS: function() {
                    var t = !1;
                    SYNO.SDS.UIFeatures.test("isRetina") && (document.documentElement.classList.add(this.cls),
                    t = !0),
                    SYNO.SDS.UIFeatures.IconSizeManager.isEnableHDPack = t
                },
                enableRetinaDisplay: function() {
                    document.documentElement.classList.remove(this.debugCls),
                    document.documentElement.classList.add(this.cls),
                    SYNO.SDS.UIFeatures.IconSizeManager.isEnableHDPack = !0
                },
                enableRetinaDebugMode: function() {
                    document.documentElement.classList.remove(this.cls),
                    document.documentElement.classList.add(this.debugCls),
                    SYNO.SDS.UIFeatures.IconSizeManager.isEnableHDPack = !0
                },
                disableRetinaDisplay: function() {
                    document.documentElement.classList.remove(this.cls),
                    document.documentElement.classList.remove(this.debugCls),
                    SYNO.SDS.UIFeatures.IconSizeManager.isEnableHDPack = !1
                },
                getRes: function(t) {
                    return this[t] ? this[t] : -1
                }
            }
        },
        895: function() {
            SYNO.namespace("SYNO.SDS"),
            SYNO.SDS.Utils.RemoveURLParam = function(t, e) {
                var n = new URL(t);
                return n.searchParams.delete(e),
                n.toString()
            }
            ,
            SYNO.SDS.UpdateSynoToken = function(t) {
                return SYNO.Deprecated("SYNO.SDS.UpdateSynoToken", "SYNO.API.UpdateSynoToken"),
                SYNO.API.UpdateSynoToken(t)
            }
        }
    }
      , e = {};
    function n(i) {
        var o = e[i];
        if (void 0 !== o)
            return o.exports;
        var r = e[i] = {
            exports: {}
        };
        return t[i](r, r.exports, n),
        r.exports
    }
    !function() {
        "use strict";
        n(895),
        n(705),
        n(765),
        n(554),
        n(109),
        n(730),
        n(469),
        n(766),
        n(240);
        var t = function() {
            var t = this
              , e = t.$createElement
              , n = t._self._c || e;
            return "fill" === t.config.type || "fit" === t.config.type ? n("div", {
                style: {
                    backgroundColor: t.config.bgColor,
                    width: this.suffixPx(t.config.winW),
                    height: this.suffixPx(t.config.winH),
                    visibility: "visible"
                }
            }, [n("img", {
                key: t.config.type + "-" + t.config.bgColor,
                style: this.imgStyle,
                attrs: {
                    src: this.imgSrcFinalized,
                    draggable: "false"
                },
                on: {
                    load: t.imgLoaded
                }
            })]) : "stretch" === t.config.type ? n("div", {
                style: {
                    backgroundColor: t.config.bgColor,
                    width: this.suffixPx(t.config.winW),
                    height: this.suffixPx(t.config.winH),
                    visibility: "visible"
                }
            }, [n("img", {
                key: "stretch",
                style: {
                    position: "absolute",
                    visibility: "visible",
                    width: "100%",
                    height: "100%"
                },
                attrs: {
                    src: this.imgSrcFinalized,
                    draggable: "false"
                },
                on: {
                    load: t.imgLoaded
                }
            })]) : "center" === t.config.type ? n("div", {
                style: {
                    width: this.suffixPx(t.config.winW),
                    height: this.suffixPx(t.config.winH),
                    backgroundColor: t.config.bgColor,
                    backgroundImage: "url(" + t.config.imgSrc + ")",
                    backgroundPosition: "50% 50%",
                    backgroundRepeat: "no-repeat",
                    visibility: "visible"
                }
            }) : "tile" === t.config.type ? n("div", {
                style: {
                    width: this.suffixPx(t.config.winW),
                    height: this.suffixPx(t.config.winH),
                    backgroundColor: t.config.bgColor,
                    backgroundImage: "url(" + t.config.imgSrc + ")",
                    backgroundRepeat: "repeat",
                    visibility: "visible"
                }
            }) : t._e()
        };
        t._withStripped = !0;
        var e = function(t, e, n, i, o, r, a, s) {
            var c, u = "function" == typeof t ? t.options : t;
            if (e && (u.render = e,
            u.staticRenderFns = [],
            u._compiled = !0),
            c)
                if (u.functional) {
                    u._injectStyles = c;
                    var l = u.render;
                    u.render = function(t, e) {
                        return c.call(e),
                        l(t, e)
                    }
                } else {
                    var d = u.beforeCreate;
                    u.beforeCreate = d ? [].concat(d, c) : [c]
                }
            return {
                exports: t,
                options: u
            }
        }({
            name: "BackgroundTpl",
            data: function() {
                return {
                    imageProps: {
                        width: 0,
                        height: 0,
                        sizeSet: !1
                    },
                    config: {
                        type: "",
                        imgSrc: SYNO.SDS.GetBlankImageUrl(),
                        imgBackgroundW: 0,
                        imgBackgroundH: 0,
                        imgLeft: 0,
                        imgTop: 0,
                        bgColor: "#FFFFFF",
                        winW: document.body.clientWidth,
                        winH: document.body.clientHeight,
                        imgSizeSet: !1
                    }
                }
            },
            methods: {
                suffixPx: function(t) {
                    return t + "px"
                },
                imgLoaded: function(t) {
                    this.setImgSize(t.target.naturalWidth, t.target.naturalHeight),
                    this.$emit("wallpaperLoaded")
                },
                setConfig: function(t) {
                    this.config = Object.assign(this.config, t),
                    "center" !== this.config.type && "tile" !== this.config.type || this.fakeImageLoaded(),
                    this.refresh()
                },
                unsetImgSize: function() {
                    this.imageProps.sizeSet = !1
                },
                fakeImageLoaded: function() {
                    if (!this.fakeImg) {
                        var t = this.config.imgSrc;
                        this.fakeImg = new Image,
                        this.fakeImg.src = t,
                        this.fakeImg.onload = function(t) {
                            this.$emit("wallpaperLoaded"),
                            this.fakeImg = null
                        }
                        .bind(this)
                    }
                },
                refresh: function() {
                    "fill" === this.config.type ? this.setFillConfig() : "fit" === this.config.type && this.setFitConfig()
                },
                setFillConfig: function() {
                    var t, e = this.config.winH, n = this.config.winW, i = this.imageProps.width / this.imageProps.height;
                    t = n > e * i ? this.fitByWidth(n, e, i) : this.fitByHeight(n, e, i),
                    this.config = Object.assign(this.config, t)
                },
                setFitConfig: function() {
                    var t, e = this.config.winH, n = this.config.winW, i = this.imageProps.width / this.imageProps.height;
                    t = n > e * i ? this.fitByHeight(n, e, i) : this.fitByWidth(n, e, i),
                    this.config = Object.assign(this.config, t)
                },
                fitByWidth: function(t, e, n) {
                    return {
                        imgBackgroundW: t,
                        imgBackgroundH: t / n,
                        imgLeft: 0,
                        imgTop: (e - t / n) / 2
                    }
                },
                fitByHeight: function(t, e, n) {
                    return {
                        imgBackgroundW: e * n,
                        imgBackgroundH: e,
                        imgLeft: (t - e * n) / 2,
                        imgTop: 0
                    }
                },
                setImgSize: function(t, e) {
                    this.imageProps = {
                        width: t,
                        height: e,
                        sizeSet: !0
                    }
                }
            },
            watch: {
                imageProps: {
                    handler: function() {
                        this.refresh()
                    },
                    deep: !0
                }
            },
            computed: {
                imgSrcFinalized: function() {
                    return this.config.imgSrc
                },
                imgStyle: function() {
                    var t = {
                        position: "absolute",
                        visibility: "visible"
                    };
                    return this.imageProps.sizeSet && (t.width = this.suffixPx(this.config.imgBackgroundW),
                    t.height = this.suffixPx(this.config.imgBackgroundH),
                    t.left = this.suffixPx(this.config.imgLeft),
                    t.top = this.suffixPx(this.config.imgTop)),
                    t
                }
            }
        }, t);
        e.options.__file = "Common/backgroundTpl.vue";
        var i = e.exports;
        n(874),
        n(918),
        n(377),
        n(738);
        var o = function() {
            return o = Object.assign || function(t) {
                for (var e, n = 1, i = arguments.length; n < i; n++)
                    for (var o in e = arguments[n])
                        Object.prototype.hasOwnProperty.call(e, o) && (t[o] = e[o]);
                return t
            }
            ,
            o.apply(this, arguments)
        };
        function r(t, e, n, i) {
            return new (n || (n = Promise))((function(o, r) {
                function a(t) {
                    try {
                        c(i.next(t))
                    } catch (t) {
                        r(t)
                    }
                }
                function s(t) {
                    try {
                        c(i.throw(t))
                    } catch (t) {
                        r(t)
                    }
                }
                function c(t) {
                    var e;
                    t.done ? o(t.value) : (e = t.value,
                    e instanceof n ? e : new n((function(t) {
                        t(e)
                    }
                    ))).then(a, s)
                }
                c((i = i.apply(t, e || [])).next())
            }
            ))
        }
        function a(t, e) {
            var n, i, o, r, a = {
                label: 0,
                sent: function() {
                    if (1 & o[0])
                        throw o[1];
                    return o[1]
                },
                trys: [],
                ops: []
            };
            return r = {
                next: s(0),
                throw: s(1),
                return: s(2)
            },
            "function" == typeof Symbol && (r[Symbol.iterator] = function() {
                return this
            }
            ),
            r;
            function s(s) {
                return function(c) {
                    return function(s) {
                        if (n)
                            throw new TypeError("Generator is already executing.");
                        for (; r && (r = 0,
                        s[0] && (a = 0)),
                        a; )
                            try {
                                if (n = 1,
                                i && (o = 2 & s[0] ? i.return : s[0] ? i.throw || ((o = i.return) && o.call(i),
                                0) : i.next) && !(o = o.call(i, s[1])).done)
                                    return o;
                                switch (i = 0,
                                o && (s = [2 & s[0], o.value]),
                                s[0]) {
                                case 0:
                                case 1:
                                    o = s;
                                    break;
                                case 4:
                                    return a.label++,
                                    {
                                        value: s[1],
                                        done: !1
                                    };
                                case 5:
                                    a.label++,
                                    i = s[1],
                                    s = [0];
                                    continue;
                                case 7:
                                    s = a.ops.pop(),
                                    a.trys.pop();
                                    continue;
                                default:
                                    if (!((o = (o = a.trys).length > 0 && o[o.length - 1]) || 6 !== s[0] && 2 !== s[0])) {
                                        a = 0;
                                        continue
                                    }
                                    if (3 === s[0] && (!o || s[1] > o[0] && s[1] < o[3])) {
                                        a.label = s[1];
                                        break
                                    }
                                    if (6 === s[0] && a.label < o[1]) {
                                        a.label = o[1],
                                        o = s;
                                        break
                                    }
                                    if (o && a.label < o[2]) {
                                        a.label = o[2],
                                        a.ops.push(s);
                                        break
                                    }
                                    o[2] && a.ops.pop(),
                                    a.trys.pop();
                                    continue
                                }
                                s = e.call(t, a)
                            } catch (t) {
                                s = [6, t],
                                i = 0
                            } finally {
                                n = o = 0
                            }
                        if (5 & s[0])
                            throw s[1];
                        return {
                            value: s[0] ? s[1] : void 0,
                            done: !0
                        }
                    }([s, c])
                }
            }
        }
        function s(t, e, n) {
            if (n || 2 === arguments.length)
                for (var i, o = 0, r = e.length; o < r; o++)
                    !i && o in e || (i || (i = Array.prototype.slice.call(e, 0, o)),
                    i[o] = e[o]);
            return t.concat(i || Array.prototype.slice.call(e))
        }
        Object.create,
        Object.create;
        var c = "3.4.0";
        function u(t, e) {
            return new Promise((function(n) {
                return setTimeout(n, t, e)
            }
            ))
        }
        function l(t, e) {
            try {
                var n = t();
                (i = n) && "function" == typeof i.then ? n.then((function(t) {
                    return e(!0, t)
                }
                ), (function(t) {
                    return e(!1, t)
                }
                )) : e(!0, n)
            } catch (t) {
                e(!1, t)
            }
            var i
        }
        function d(t, e, n) {
            return void 0 === n && (n = 16),
            r(this, void 0, void 0, (function() {
                var i, o, r;
                return a(this, (function(a) {
                    switch (a.label) {
                    case 0:
                        i = Date.now(),
                        o = 0,
                        a.label = 1;
                    case 1:
                        return o < t.length ? (e(t[o], o),
                        (r = Date.now()) >= i + n ? (i = r,
                        [4, u(0)]) : [3, 3]) : [3, 4];
                    case 2:
                        a.sent(),
                        a.label = 3;
                    case 3:
                        return ++o,
                        [3, 1];
                    case 4:
                        return [2]
                    }
                }
                ))
            }
            ))
        }
        function h(t) {
            t.then(void 0, (function() {}
            ))
        }
        function f(t, e) {
            t = [t[0] >>> 16, 65535 & t[0], t[1] >>> 16, 65535 & t[1]],
            e = [e[0] >>> 16, 65535 & e[0], e[1] >>> 16, 65535 & e[1]];
            var n = [0, 0, 0, 0];
            return n[3] += t[3] + e[3],
            n[2] += n[3] >>> 16,
            n[3] &= 65535,
            n[2] += t[2] + e[2],
            n[1] += n[2] >>> 16,
            n[2] &= 65535,
            n[1] += t[1] + e[1],
            n[0] += n[1] >>> 16,
            n[1] &= 65535,
            n[0] += t[0] + e[0],
            n[0] &= 65535,
            [n[0] << 16 | n[1], n[2] << 16 | n[3]]
        }
        function p(t, e) {
            t = [t[0] >>> 16, 65535 & t[0], t[1] >>> 16, 65535 & t[1]],
            e = [e[0] >>> 16, 65535 & e[0], e[1] >>> 16, 65535 & e[1]];
            var n = [0, 0, 0, 0];
            return n[3] += t[3] * e[3],
            n[2] += n[3] >>> 16,
            n[3] &= 65535,
            n[2] += t[2] * e[3],
            n[1] += n[2] >>> 16,
            n[2] &= 65535,
            n[2] += t[3] * e[2],
            n[1] += n[2] >>> 16,
            n[2] &= 65535,
            n[1] += t[1] * e[3],
            n[0] += n[1] >>> 16,
            n[1] &= 65535,
            n[1] += t[2] * e[2],
            n[0] += n[1] >>> 16,
            n[1] &= 65535,
            n[1] += t[3] * e[1],
            n[0] += n[1] >>> 16,
            n[1] &= 65535,
            n[0] += t[0] * e[3] + t[1] * e[2] + t[2] * e[1] + t[3] * e[0],
            n[0] &= 65535,
            [n[0] << 16 | n[1], n[2] << 16 | n[3]]
        }
        function S(t, e) {
            return 32 == (e %= 64) ? [t[1], t[0]] : e < 32 ? [t[0] << e | t[1] >>> 32 - e, t[1] << e | t[0] >>> 32 - e] : (e -= 32,
            [t[1] << e | t[0] >>> 32 - e, t[0] << e | t[1] >>> 32 - e])
        }
        function m(t, e) {
            return 0 == (e %= 64) ? t : e < 32 ? [t[0] << e | t[1] >>> 32 - e, t[1] << e] : [t[1] << e - 32, 0]
        }
        function g(t, e) {
            return [t[0] ^ e[0], t[1] ^ e[1]]
        }
        function v(t) {
            return t = g(t, [0, t[0] >>> 1]),
            t = g(t = p(t, [4283543511, 3981806797]), [0, t[0] >>> 1]),
            g(t = p(t, [3301882366, 444984403]), [0, t[0] >>> 1])
        }
        function y(t) {
            return parseInt(t)
        }
        function b(t) {
            return parseFloat(t)
        }
        function w(t, e) {
            return "number" == typeof t && isNaN(t) ? e : t
        }
        function _(t) {
            return t.reduce((function(t, e) {
                return t + (e ? 1 : 0)
            }
            ), 0)
        }
        function k(t, e) {
            if (void 0 === e && (e = 1),
            Math.abs(e) >= 1)
                return Math.round(t / e) * e;
            var n = 1 / e;
            return Math.round(t * n) / n
        }
        function O(t) {
            return t && "object" == typeof t && "message"in t ? t : {
                message: t
            }
        }
        function D(t) {
            return "function" != typeof t
        }
        function N(t, e, n) {
            var i = Object.keys(t).filter((function(t) {
                return !function(t, e) {
                    for (var n = 0, i = t.length; n < i; ++n)
                        if (t[n] === e)
                            return !0;
                    return !1
                }(n, t)
            }
            ))
              , o = Array(i.length);
            return d(i, (function(n, i) {
                o[i] = function(t, e) {
                    var n = new Promise((function(n) {
                        var i = Date.now();
                        l(t.bind(null, e), (function() {
                            for (var t = [], e = 0; e < arguments.length; e++)
                                t[e] = arguments[e];
                            var o = Date.now() - i;
                            if (!t[0])
                                return n((function() {
                                    return {
                                        error: O(t[1]),
                                        duration: o
                                    }
                                }
                                ));
                            var r = t[1];
                            if (D(r))
                                return n((function() {
                                    return {
                                        value: r,
                                        duration: o
                                    }
                                }
                                ));
                            n((function() {
                                return new Promise((function(t) {
                                    var e = Date.now();
                                    l(r, (function() {
                                        for (var n = [], i = 0; i < arguments.length; i++)
                                            n[i] = arguments[i];
                                        var r = o + Date.now() - e;
                                        if (!n[0])
                                            return t({
                                                error: O(n[1]),
                                                duration: r
                                            });
                                        t({
                                            value: n[1],
                                            duration: r
                                        })
                                    }
                                    ))
                                }
                                ))
                            }
                            ))
                        }
                        ))
                    }
                    ));
                    return h(n),
                    function() {
                        return n.then((function(t) {
                            return t()
                        }
                        ))
                    }
                }(t[n], e)
            }
            )),
            function() {
                return r(this, void 0, void 0, (function() {
                    var t, e, n, r, s, c;
                    return a(this, (function(l) {
                        switch (l.label) {
                        case 0:
                            for (t = {},
                            e = 0,
                            n = i; e < n.length; e++)
                                r = n[e],
                                t[r] = void 0;
                            s = Array(i.length),
                            c = function() {
                                var e;
                                return a(this, (function(n) {
                                    switch (n.label) {
                                    case 0:
                                        return e = !0,
                                        [4, d(i, (function(n, i) {
                                            if (!s[i])
                                                if (o[i]) {
                                                    var r = o[i]().then((function(e) {
                                                        return t[n] = e
                                                    }
                                                    ));
                                                    h(r),
                                                    s[i] = r
                                                } else
                                                    e = !1
                                        }
                                        ))];
                                    case 1:
                                        return n.sent(),
                                        e ? [2, "break"] : [4, u(1)];
                                    case 2:
                                        return n.sent(),
                                        [2]
                                    }
                                }
                                ))
                            }
                            ,
                            l.label = 1;
                        case 1:
                            return [5, c()];
                        case 2:
                            if ("break" === l.sent())
                                return [3, 4];
                            l.label = 3;
                        case 3:
                            return [3, 1];
                        case 4:
                            return [4, Promise.all(s)];
                        case 5:
                            return l.sent(),
                            [2, t]
                        }
                    }
                    ))
                }
                ))
            }
        }
        function Y() {
            var t = window
              , e = navigator;
            return _(["MSCSSMatrix"in t, "msSetImmediate"in t, "msIndexedDB"in t, "msMaxTouchPoints"in e, "msPointerEnabled"in e]) >= 4
        }
        function x() {
            var t = window
              , e = navigator;
            return _(["webkitPersistentStorage"in e, "webkitTemporaryStorage"in e, 0 === e.vendor.indexOf("Google"), "webkitResolveLocalFileSystemURL"in t, "BatteryManager"in t, "webkitMediaStream"in t, "webkitSpeechGrammar"in t]) >= 5
        }
        function L() {
            var t = window
              , e = navigator;
            return _(["ApplePayError"in t, "CSSPrimitiveValue"in t, "Counter"in t, 0 === e.vendor.indexOf("Apple"), "getStorageUpdates"in e, "WebKitMediaKeys"in t]) >= 4
        }
        function C() {
            var t = window;
            return _(["safari"in t, !("DeviceMotionEvent"in t), !("ongestureend"in t), !("standalone"in navigator)]) >= 3
        }
        function I() {
            var t = document;
            return (t.exitFullscreen || t.msExitFullscreen || t.mozCancelFullScreen || t.webkitExitFullscreen).call(t)
        }
        function P() {
            var t = x()
              , e = function() {
                var t, e, n = window;
                return _(["buildID"in navigator, "MozAppearance"in (null !== (e = null === (t = document.documentElement) || void 0 === t ? void 0 : t.style) && void 0 !== e ? e : {}), "onmozfullscreenchange"in n, "mozInnerScreenX"in n, "CSSMozDocumentRule"in n, "CanvasCaptureMediaStream"in n]) >= 4
            }();
            if (!t && !e)
                return !1;
            var n = window;
            return _(["onorientationchange"in n, "orientation"in n, t && !("SharedWorker"in n), e && /android/i.test(navigator.appVersion)]) >= 2
        }
        function E(t) {
            var e = new Error(t);
            return e.name = t,
            e
        }
        function R(t, e, n) {
            var i, o, s;
            return void 0 === n && (n = 50),
            r(this, void 0, void 0, (function() {
                var r, c;
                return a(this, (function(a) {
                    switch (a.label) {
                    case 0:
                        r = document,
                        a.label = 1;
                    case 1:
                        return r.body ? [3, 3] : [4, u(n)];
                    case 2:
                        return a.sent(),
                        [3, 1];
                    case 3:
                        c = r.createElement("iframe"),
                        a.label = 4;
                    case 4:
                        return a.trys.push([4, , 10, 11]),
                        [4, new Promise((function(t, n) {
                            var i = !1
                              , o = function() {
                                i = !0,
                                t()
                            };
                            c.onload = o,
                            c.onerror = function(t) {
                                i = !0,
                                n(t)
                            }
                            ;
                            var a = c.style;
                            a.setProperty("display", "block", "important"),
                            a.position = "absolute",
                            a.top = "0",
                            a.left = "0",
                            a.visibility = "hidden",
                            e && "srcdoc"in c ? c.srcdoc = e : c.src = "about:blank",
                            r.body.appendChild(c);
                            var s = function() {
                                var t, e;
                                i || ("complete" === (null === (e = null === (t = c.contentWindow) || void 0 === t ? void 0 : t.document) || void 0 === e ? void 0 : e.readyState) ? o() : setTimeout(s, 10))
                            };
                            s()
                        }
                        ))];
                    case 5:
                        a.sent(),
                        a.label = 6;
                    case 6:
                        return (null === (o = null === (i = c.contentWindow) || void 0 === i ? void 0 : i.document) || void 0 === o ? void 0 : o.body) ? [3, 8] : [4, u(n)];
                    case 7:
                        return a.sent(),
                        [3, 6];
                    case 8:
                        return [4, t(c, c.contentWindow)];
                    case 9:
                        return [2, a.sent()];
                    case 10:
                        return null === (s = c.parentNode) || void 0 === s || s.removeChild(c),
                        [7];
                    case 11:
                        return [2]
                    }
                }
                ))
            }
            ))
        }
        function F(t) {
            for (var e = function(t) {
                for (var e, n, i = "Unexpected syntax '".concat(t, "'"), o = /^\s*([a-z-]*)(.*)$/i.exec(t), r = o[1] || void 0, a = {}, s = /([.:#][\w-]+|\[.+?\])/gi, c = function(t, e) {
                    a[t] = a[t] || [],
                    a[t].push(e)
                }; ; ) {
                    var u = s.exec(o[2]);
                    if (!u)
                        break;
                    var l = u[0];
                    switch (l[0]) {
                    case ".":
                        c("class", l.slice(1));
                        break;
                    case "#":
                        c("id", l.slice(1));
                        break;
                    case "[":
                        var d = /^\[([\w-]+)([~|^$*]?=("(.*?)"|([\w-]+)))?(\s+[is])?\]$/.exec(l);
                        if (!d)
                            throw new Error(i);
                        c(d[1], null !== (n = null !== (e = d[4]) && void 0 !== e ? e : d[5]) && void 0 !== n ? n : "");
                        break;
                    default:
                        throw new Error(i)
                    }
                }
                return [r, a]
            }(t), n = e[0], i = e[1], o = document.createElement(null != n ? n : "div"), r = 0, a = Object.keys(i); r < a.length; r++) {
                var s = a[r]
                  , c = i[s].join(" ");
                "style" === s ? B(o.style, c) : o.setAttribute(s, c)
            }
            return o
        }
        function B(t, e) {
            for (var n = 0, i = e.split(";"); n < i.length; n++) {
                var o = i[n]
                  , r = /^\s*([\w-]+)\s*:\s*(.+?)(\s*!([\w-]+))?\s*$/.exec(o);
                if (r) {
                    var a = r[1]
                      , s = r[2]
                      , c = r[4];
                    t.setProperty(a, s, c || "")
                }
            }
        }
        var M, T, A = ["monospace", "sans-serif", "serif"], V = ["sans-serif-thin", "ARNO PRO", "Agency FB", "Arabic Typesetting", "Arial Unicode MS", "AvantGarde Bk BT", "BankGothic Md BT", "Batang", "Bitstream Vera Sans Mono", "Calibri", "Century", "Century Gothic", "Clarendon", "EUROSTILE", "Franklin Gothic", "Futura Bk BT", "Futura Md BT", "GOTHAM", "Gill Sans", "HELV", "Haettenschweiler", "Helvetica Neue", "Humanst521 BT", "Leelawadee", "Letter Gothic", "Levenim MT", "Lucida Bright", "Lucida Sans", "Menlo", "MS Mincho", "MS Outlook", "MS Reference Specialty", "MS UI Gothic", "MT Extra", "MYRIAD PRO", "Marlett", "Meiryo UI", "Microsoft Uighur", "Minion Pro", "Monotype Corsiva", "PMingLiU", "Pristina", "SCRIPTINA", "Segoe UI Light", "Serifa", "SimHei", "Small Fonts", "Staccato222 BT", "TRAJAN PRO", "Univers CE 55 Medium", "Vrinda", "ZWAdobeF"];
        function W(t) {
            return t.toDataURL()
        }
        function H() {
            var t = screen;
            return [w(b(t.availTop), null), w(b(t.width) - b(t.availWidth) - w(b(t.availLeft), 0), null), w(b(t.height) - b(t.availHeight) - w(b(t.availTop), 0), null), w(b(t.availLeft), null)]
        }
        function G(t) {
            for (var e = 0; e < 4; ++e)
                if (t[e])
                    return !1;
            return !0
        }
        function Z(t) {
            var e;
            return r(this, void 0, void 0, (function() {
                var n, i, o, r, s, c, l;
                return a(this, (function(a) {
                    switch (a.label) {
                    case 0:
                        for (n = document,
                        i = n.createElement("div"),
                        o = new Array(t.length),
                        r = {},
                        j(i),
                        l = 0; l < t.length; ++l)
                            s = F(t[l]),
                            j(c = n.createElement("div")),
                            c.appendChild(s),
                            i.appendChild(c),
                            o[l] = s;
                        a.label = 1;
                    case 1:
                        return n.body ? [3, 3] : [4, u(50)];
                    case 2:
                        return a.sent(),
                        [3, 1];
                    case 3:
                        n.body.appendChild(i);
                        try {
                            for (l = 0; l < t.length; ++l)
                                o[l].offsetParent || (r[t[l]] = !0)
                        } finally {
                            null === (e = i.parentNode) || void 0 === e || e.removeChild(i)
                        }
                        return [2, r]
                    }
                }
                ))
            }
            ))
        }
        function j(t) {
            t.style.setProperty("display", "block", "important")
        }
        function z(t) {
            return matchMedia("(inverted-colors: ".concat(t, ")")).matches
        }
        function X(t) {
            return matchMedia("(forced-colors: ".concat(t, ")")).matches
        }
        function U(t) {
            return matchMedia("(prefers-contrast: ".concat(t, ")")).matches
        }
        function J(t) {
            return matchMedia("(prefers-reduced-motion: ".concat(t, ")")).matches
        }
        function Q(t) {
            return matchMedia("(dynamic-range: ".concat(t, ")")).matches
        }
        var K = Math
          , q = function() {
            return 0
        }
          , $ = {
            default: [],
            apple: [{
                font: "-apple-system-body"
            }],
            serif: [{
                fontFamily: "serif"
            }],
            sans: [{
                fontFamily: "sans-serif"
            }],
            mono: [{
                fontFamily: "monospace"
            }],
            min: [{
                fontSize: "1px"
            }],
            system: [{
                fontFamily: "system-ui"
            }]
        }
          , tt = {
            fonts: function() {
                return R((function(t, e) {
                    var n = e.document
                      , i = n.body;
                    i.style.fontSize = "48px";
                    var o = n.createElement("div")
                      , r = {}
                      , a = {}
                      , s = function(t) {
                        var e = n.createElement("span")
                          , i = e.style;
                        return i.position = "absolute",
                        i.top = "0",
                        i.left = "0",
                        i.fontFamily = t,
                        e.textContent = "mmMwWLliI0O&1",
                        o.appendChild(e),
                        e
                    }
                      , c = A.map(s)
                      , u = function() {
                        for (var t = {}, e = function(e) {
                            t[e] = A.map((function(t) {
                                return function(t, e) {
                                    return s("'".concat(t, "',").concat(e))
                                }(e, t)
                            }
                            ))
                        }, n = 0, i = V; n < i.length; n++)
                            e(i[n]);
                        return t
                    }();
                    i.appendChild(o);
                    for (var l = 0; l < A.length; l++)
                        r[A[l]] = c[l].offsetWidth,
                        a[A[l]] = c[l].offsetHeight;
                    return V.filter((function(t) {
                        return e = u[t],
                        A.some((function(t, n) {
                            return e[n].offsetWidth !== r[t] || e[n].offsetHeight !== a[t]
                        }
                        ));
                        var e
                    }
                    ))
                }
                ))
            },
            domBlockers: function(t) {
                var e = (void 0 === t ? {} : t).debug;
                return r(this, void 0, void 0, (function() {
                    var t, n, i, o, r;
                    return a(this, (function(a) {
                        switch (a.label) {
                        case 0:
                            return L() || P() ? (s = atob,
                            t = {
                                abpIndo: ["#Iklan-Melayang", "#Kolom-Iklan-728", "#SidebarIklan-wrapper", s("YVt0aXRsZT0iN25hZ2EgcG9rZXIiIGld"), '[title="ALIENBOLA" i]'],
                                abpvn: ["#quangcaomb", s("Lmlvc0Fkc2lvc0Fkcy1sYXlvdXQ="), ".quangcao", s("W2hyZWZePSJodHRwczovL3I4OC52bi8iXQ=="), s("W2hyZWZePSJodHRwczovL3piZXQudm4vIl0=")],
                                adBlockFinland: [".mainostila", s("LnNwb25zb3JpdA=="), ".ylamainos", s("YVtocmVmKj0iL2NsaWNrdGhyZ2guYXNwPyJd"), s("YVtocmVmXj0iaHR0cHM6Ly9hcHAucmVhZHBlYWsuY29tL2FkcyJd")],
                                adBlockPersian: ["#navbar_notice_50", ".kadr", 'TABLE[width="140px"]', "#divAgahi", s("I2FkMl9pbmxpbmU=")],
                                adBlockWarningRemoval: ["#adblock-honeypot", ".adblocker-root", ".wp_adblock_detect", s("LmhlYWRlci1ibG9ja2VkLWFk"), s("I2FkX2Jsb2NrZXI=")],
                                adGuardAnnoyances: ['amp-embed[type="zen"]', ".hs-sosyal", "#cookieconsentdiv", 'div[class^="app_gdpr"]', ".as-oil"],
                                adGuardBase: [".BetterJsPopOverlay", s("I2FkXzMwMFgyNTA="), s("I2Jhbm5lcmZsb2F0MjI="), s("I2FkLWJhbm5lcg=="), s("I2NhbXBhaWduLWJhbm5lcg==")],
                                adGuardChinese: [s("LlppX2FkX2FfSA=="), s("YVtocmVmKj0iL29kMDA1LmNvbSJd"), s("YVtocmVmKj0iLmh0aGJldDM0LmNvbSJd"), ".qq_nr_lad", "#widget-quan"],
                                adGuardFrench: [s("I2Jsb2NrLXZpZXdzLWFkcy1zaWRlYmFyLWJsb2NrLWJsb2Nr"), "#pavePub", s("LmFkLWRlc2t0b3AtcmVjdGFuZ2xl"), ".mobile_adhesion", ".widgetadv"],
                                adGuardGerman: [s("LmJhbm5lcml0ZW13ZXJidW5nX2hlYWRfMQ=="), s("LmJveHN0YXJ0d2VyYnVuZw=="), s("LndlcmJ1bmcz"), s("YVtocmVmXj0iaHR0cDovL3d3dy5laXMuZGUvaW5kZXgucGh0bWw/cmVmaWQ9Il0="), s("YVtocmVmXj0iaHR0cHM6Ly93d3cudGlwaWNvLmNvbS8/YWZmaWxpYXRlSWQ9Il0=")],
                                adGuardJapanese: ["#kauli_yad_1", s("YVtocmVmXj0iaHR0cDovL2FkMi50cmFmZmljZ2F0ZS5uZXQvIl0="), s("Ll9wb3BJbl9pbmZpbml0ZV9hZA=="), s("LmFkZ29vZ2xl"), s("LmFkX3JlZ3VsYXIz")],
                                adGuardMobile: [s("YW1wLWF1dG8tYWRz"), s("LmFtcF9hZA=="), 'amp-embed[type="24smi"]', "#mgid_iframe1", s("I2FkX2ludmlld19hcmVh")],
                                adGuardRussian: [s("YVtocmVmXj0iaHR0cHM6Ly9hZC5sZXRtZWFkcy5jb20vIl0="), s("LnJlY2xhbWE="), 'div[id^="smi2adblock"]', s("ZGl2W2lkXj0iQWRGb3hfYmFubmVyXyJd"), s("I2FkX3NxdWFyZQ==")],
                                adGuardSocial: [s("YVtocmVmXj0iLy93d3cuc3R1bWJsZXVwb24uY29tL3N1Ym1pdD91cmw9Il0="), s("YVtocmVmXj0iLy90ZWxlZ3JhbS5tZS9zaGFyZS91cmw/Il0="), ".etsy-tweet", "#inlineShare", ".popup-social"],
                                adGuardSpanishPortuguese: ["#barraPublicidade", "#Publicidade", "#publiEspecial", "#queTooltip", s("W2hyZWZePSJodHRwOi8vYWRzLmdsaXNwYS5jb20vIl0=")],
                                adGuardTrackingProtection: ["#qoo-counter", s("YVtocmVmXj0iaHR0cDovL2NsaWNrLmhvdGxvZy5ydS8iXQ=="), s("YVtocmVmXj0iaHR0cDovL2hpdGNvdW50ZXIucnUvdG9wL3N0YXQucGhwIl0="), s("YVtocmVmXj0iaHR0cDovL3RvcC5tYWlsLnJ1L2p1bXAiXQ=="), "#top100counter"],
                                adGuardTurkish: ["#backkapat", s("I3Jla2xhbWk="), s("YVtocmVmXj0iaHR0cDovL2Fkc2Vydi5vbnRlay5jb20udHIvIl0="), s("YVtocmVmXj0iaHR0cDovL2l6bGVuemkuY29tL2NhbXBhaWduLyJd"), s("YVtocmVmXj0iaHR0cDovL3d3dy5pbnN0YWxsYWRzLm5ldC8iXQ==")],
                                bulgarian: [s("dGQjZnJlZW5ldF90YWJsZV9hZHM="), "#ea_intext_div", ".lapni-pop-over", "#xenium_hot_offers", s("I25ld0Fk")],
                                easyList: [s("I0FEX0NPTlRST0xfMjg="), s("LnNlY29uZC1wb3N0LWFkcy13cmFwcGVy"), ".universalboxADVBOX03", s("LmFkdmVydGlzZW1lbnQtNzI4eDkw"), s("LnNxdWFyZV9hZHM=")],
                                easyListChina: [s("YVtocmVmKj0iLndlbnNpeHVldGFuZy5jb20vIl0="), s("LmFwcGd1aWRlLXdyYXBbb25jbGljayo9ImJjZWJvcy5jb20iXQ=="), s("LmZyb250cGFnZUFkdk0="), "#taotaole", "#aafoot.top_box"],
                                easyListCookie: ["#AdaCompliance.app-notice", ".text-center.rgpd", ".panel--cookie", ".js-cookies-andromeda", ".elxtr-consent"],
                                easyListCzechSlovak: ["#onlajny-stickers", s("I3Jla2xhbW5pLWJveA=="), s("LnJla2xhbWEtbWVnYWJvYXJk"), ".sklik", s("W2lkXj0ic2tsaWtSZWtsYW1hIl0=")],
                                easyListDutch: [s("I2FkdmVydGVudGll"), s("I3ZpcEFkbWFya3RCYW5uZXJCbG9jaw=="), ".adstekst", s("YVtocmVmXj0iaHR0cHM6Ly94bHR1YmUubmwvY2xpY2svIl0="), "#semilo-lrectangle"],
                                easyListGermany: [s("I0FkX1dpbjJkYXk="), s("I3dlcmJ1bmdzYm94MzAw"), s("YVtocmVmXj0iaHR0cDovL3d3dy5yb3RsaWNodGthcnRlaS5jb20vP3NjPSJd"), s("I3dlcmJ1bmdfd2lkZXNreXNjcmFwZXJfc2NyZWVu"), s("YVtocmVmXj0iaHR0cDovL2xhbmRpbmcucGFya3BsYXR6a2FydGVpLmNvbS8/YWc9Il0=")],
                                easyListItaly: [s("LmJveF9hZHZfYW5udW5jaQ=="), ".sb-box-pubbliredazionale", s("YVtocmVmXj0iaHR0cDovL2FmZmlsaWF6aW9uaWFkcy5zbmFpLml0LyJd"), s("YVtocmVmXj0iaHR0cHM6Ly9hZHNlcnZlci5odG1sLml0LyJd"), s("YVtocmVmXj0iaHR0cHM6Ly9hZmZpbGlhemlvbmlhZHMuc25haS5pdC8iXQ==")],
                                easyListLithuania: [s("LnJla2xhbW9zX3RhcnBhcw=="), s("LnJla2xhbW9zX251b3JvZG9z"), s("aW1nW2FsdD0iUmVrbGFtaW5pcyBza3lkZWxpcyJd"), s("aW1nW2FsdD0iRGVkaWt1b3RpLmx0IHNlcnZlcmlhaSJd"), s("aW1nW2FsdD0iSG9zdGluZ2FzIFNlcnZlcmlhaS5sdCJd")],
                                estonian: [s("QVtocmVmKj0iaHR0cDovL3BheTRyZXN1bHRzMjQuZXUiXQ==")],
                                fanboyAnnoyances: ["#feedback-tab", "#taboola-below-article", ".feedburnerFeedBlock", ".widget-feedburner-counter", '[title="Subscribe to our blog"]'],
                                fanboyAntiFacebook: [".util-bar-module-firefly-visible"],
                                fanboyEnhancedTrackers: [".open.pushModal", "#issuem-leaky-paywall-articles-zero-remaining-nag", "#sovrn_container", 'div[class$="-hide"][zoompage-fontsize][style="display: block;"]', ".BlockNag__Card"],
                                fanboySocial: [".td-tags-and-social-wrapper-box", ".twitterContainer", ".youtube-social", 'a[title^="Like us on Facebook"]', 'img[alt^="Share on Digg"]'],
                                frellwitSwedish: [s("YVtocmVmKj0iY2FzaW5vcHJvLnNlIl1bdGFyZ2V0PSJfYmxhbmsiXQ=="), s("YVtocmVmKj0iZG9rdG9yLXNlLm9uZWxpbmsubWUiXQ=="), "article.category-samarbete", s("ZGl2LmhvbGlkQWRz"), "ul.adsmodern"],
                                greekAdBlock: [s("QVtocmVmKj0iYWRtYW4ub3RlbmV0LmdyL2NsaWNrPyJd"), s("QVtocmVmKj0iaHR0cDovL2F4aWFiYW5uZXJzLmV4b2R1cy5nci8iXQ=="), s("QVtocmVmKj0iaHR0cDovL2ludGVyYWN0aXZlLmZvcnRobmV0LmdyL2NsaWNrPyJd"), "DIV.agores300", "TABLE.advright"],
                                hungarian: ["#cemp_doboz", ".optimonk-iframe-container", s("LmFkX19tYWlu"), s("W2NsYXNzKj0iR29vZ2xlQWRzIl0="), "#hirdetesek_box"],
                                iDontCareAboutCookies: ['.alert-info[data-block-track*="CookieNotice"]', ".ModuleTemplateCookieIndicator", ".o--cookies--container", ".cookie-msg-info-container", "#cookies-policy-sticky"],
                                icelandicAbp: [s("QVtocmVmXj0iL2ZyYW1ld29yay9yZXNvdXJjZXMvZm9ybXMvYWRzLmFzcHgiXQ==")],
                                latvian: [s("YVtocmVmPSJodHRwOi8vd3d3LnNhbGlkemluaS5sdi8iXVtzdHlsZT0iZGlzcGxheTogYmxvY2s7IHdpZHRoOiAxMjBweDsgaGVpZ2h0OiA0MHB4OyBvdmVyZmxvdzogaGlkZGVuOyBwb3NpdGlvbjogcmVsYXRpdmU7Il0="), s("YVtocmVmPSJodHRwOi8vd3d3LnNhbGlkemluaS5sdi8iXVtzdHlsZT0iZGlzcGxheTogYmxvY2s7IHdpZHRoOiA4OHB4OyBoZWlnaHQ6IDMxcHg7IG92ZXJmbG93OiBoaWRkZW47IHBvc2l0aW9uOiByZWxhdGl2ZTsiXQ==")],
                                listKr: [s("YVtocmVmKj0iLy9hZC5wbGFuYnBsdXMuY28ua3IvIl0="), s("I2xpdmVyZUFkV3JhcHBlcg=="), s("YVtocmVmKj0iLy9hZHYuaW1hZHJlcC5jby5rci8iXQ=="), s("aW5zLmZhc3R2aWV3LWFk"), ".revenue_unit_item.dable"],
                                listeAr: [s("LmdlbWluaUxCMUFk"), ".right-and-left-sponsers", s("YVtocmVmKj0iLmFmbGFtLmluZm8iXQ=="), s("YVtocmVmKj0iYm9vcmFxLm9yZyJd"), s("YVtocmVmKj0iZHViaXp6bGUuY29tL2FyLz91dG1fc291cmNlPSJd")],
                                listeFr: [s("YVtocmVmXj0iaHR0cDovL3Byb21vLnZhZG9yLmNvbS8iXQ=="), s("I2FkY29udGFpbmVyX3JlY2hlcmNoZQ=="), s("YVtocmVmKj0id2Vib3JhbWEuZnIvZmNnaS1iaW4vIl0="), ".site-pub-interstitiel", 'div[id^="crt-"][data-criteo-id]'],
                                officialPolish: ["#ceneo-placeholder-ceneo-12", s("W2hyZWZePSJodHRwczovL2FmZi5zZW5kaHViLnBsLyJd"), s("YVtocmVmXj0iaHR0cDovL2Fkdm1hbmFnZXIudGVjaGZ1bi5wbC9yZWRpcmVjdC8iXQ=="), s("YVtocmVmXj0iaHR0cDovL3d3dy50cml6ZXIucGwvP3V0bV9zb3VyY2UiXQ=="), s("ZGl2I3NrYXBpZWNfYWQ=")],
                                ro: [s("YVtocmVmXj0iLy9hZmZ0cmsuYWx0ZXgucm8vQ291bnRlci9DbGljayJd"), 'a[href^="/magazin/"]', s("YVtocmVmXj0iaHR0cHM6Ly9ibGFja2ZyaWRheXNhbGVzLnJvL3Ryay9zaG9wLyJd"), s("YVtocmVmXj0iaHR0cHM6Ly9ldmVudC4ycGVyZm9ybWFudC5jb20vZXZlbnRzL2NsaWNrIl0="), s("YVtocmVmXj0iaHR0cHM6Ly9sLnByb2ZpdHNoYXJlLnJvLyJd")],
                                ruAd: [s("YVtocmVmKj0iLy9mZWJyYXJlLnJ1LyJd"), s("YVtocmVmKj0iLy91dGltZy5ydS8iXQ=="), s("YVtocmVmKj0iOi8vY2hpa2lkaWtpLnJ1Il0="), "#pgeldiz", ".yandex-rtb-block"],
                                thaiAds: ["a[href*=macau-uta-popup]", s("I2Fkcy1nb29nbGUtbWlkZGxlX3JlY3RhbmdsZS1ncm91cA=="), s("LmFkczMwMHM="), ".bumq", ".img-kosana"],
                                webAnnoyancesUltralist: ["#mod-social-share-2", "#social-tools", s("LmN0cGwtZnVsbGJhbm5lcg=="), ".zergnet-recommend", ".yt.btn-link.btn-md.btn"]
                            },
                            n = Object.keys(t),
                            [4, Z((r = []).concat.apply(r, n.map((function(e) {
                                return t[e]
                            }
                            ))))]) : [2, void 0];
                        case 1:
                            return i = a.sent(),
                            e && function(t, e) {
                                for (var n = "DOM blockers debug:\n```", i = 0, o = Object.keys(t); i < o.length; i++) {
                                    var r = o[i];
                                    n += "\n".concat(r, ":");
                                    for (var a = 0, s = t[r]; a < s.length; a++) {
                                        var c = s[a];
                                        n += "\n  ".concat(e[c] ? "🚫" : "➡️", " ").concat(c)
                                    }
                                }
                                console.log("".concat(n, "\n```"))
                            }(t, i),
                            (o = n.filter((function(e) {
                                var n = t[e];
                                return _(n.map((function(t) {
                                    return i[t]
                                }
                                ))) > .6 * n.length
                            }
                            ))).sort(),
                            [2, o]
                        }
                        var s
                    }
                    ))
                }
                ))
            },
            fontPreferences: function() {
                return void 0 === t && (t = 4e3),
                R((function(e, n) {
                    var i = n.document
                      , o = i.body
                      , r = o.style;
                    r.width = "".concat(t, "px"),
                    r.webkitTextSizeAdjust = r.textSizeAdjust = "none",
                    x() ? o.style.zoom = "".concat(1 / n.devicePixelRatio) : L() && (o.style.zoom = "reset");
                    var a = i.createElement("div");
                    return a.textContent = s([], Array(t / 20 << 0), !0).map((function() {
                        return "word"
                    }
                    )).join(" "),
                    o.appendChild(a),
                    function(t, e) {
                        for (var n = {}, i = {}, o = 0, r = Object.keys($); o < r.length; o++) {
                            var a = r[o]
                              , s = $[a]
                              , c = s[0]
                              , u = void 0 === c ? {} : c
                              , l = s[1]
                              , d = void 0 === l ? "mmMwWLliI0fiflO&1" : l
                              , h = t.createElement("span");
                            h.textContent = d,
                            h.style.whiteSpace = "nowrap";
                            for (var f = 0, p = Object.keys(u); f < p.length; f++) {
                                var S = p[f]
                                  , m = u[S];
                                void 0 !== m && (h.style[S] = m)
                            }
                            n[a] = h,
                            e.appendChild(t.createElement("br")),
                            e.appendChild(h)
                        }
                        for (var g = 0, v = Object.keys($); g < v.length; g++)
                            i[a = v[g]] = n[a].getBoundingClientRect().width;
                        return i
                    }(i, o)
                }
                ), '<!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">');
                var t
            },
            audio: function() {
                var t = window
                  , e = t.OfflineAudioContext || t.webkitOfflineAudioContext;
                if (!e)
                    return -2;
                if (L() && !C() && !function() {
                    var t = window;
                    return _(["DOMRectList"in t, "RTCPeerConnectionIceEvent"in t, "SVGGeometryElement"in t, "ontransitioncancel"in t]) >= 3
                }())
                    return -1;
                var n = new e(1,5e3,44100)
                  , i = n.createOscillator();
                i.type = "triangle",
                i.frequency.value = 1e4;
                var o = n.createDynamicsCompressor();
                o.threshold.value = -50,
                o.knee.value = 40,
                o.ratio.value = 12,
                o.attack.value = 0,
                o.release.value = .25,
                i.connect(o),
                o.connect(n.destination),
                i.start(0);
                var r = function(t) {
                    var e = function() {};
                    return [new Promise((function(n, i) {
                        var o = !1
                          , r = 0
                          , a = 0;
                        t.oncomplete = function(t) {
                            return n(t.renderedBuffer)
                        }
                        ;
                        var s = function() {
                            setTimeout((function() {
                                return i(E("timeout"))
                            }
                            ), Math.min(500, a + 5e3 - Date.now()))
                        }
                          , c = function() {
                            try {
                                switch (t.startRendering(),
                                t.state) {
                                case "running":
                                    a = Date.now(),
                                    o && s();
                                    break;
                                case "suspended":
                                    document.hidden || r++,
                                    o && r >= 3 ? i(E("suspended")) : setTimeout(c, 500)
                                }
                            } catch (t) {
                                i(t)
                            }
                        };
                        c(),
                        e = function() {
                            o || (o = !0,
                            a > 0 && s())
                        }
                    }
                    )), e]
                }(n)
                  , a = r[0]
                  , s = r[1]
                  , c = a.then((function(t) {
                    return function(t) {
                        for (var e = 0, n = 0; n < t.length; ++n)
                            e += Math.abs(t[n]);
                        return e
                    }(t.getChannelData(0).subarray(4500))
                }
                ), (function(t) {
                    if ("timeout" === t.name || "suspended" === t.name)
                        return -3;
                    throw t
                }
                ));
                return h(c),
                function() {
                    return s(),
                    c
                }
            },
            screenFrame: function() {
                var t = this
                  , e = function() {
                    var t = this;
                    return function() {
                        if (void 0 === T) {
                            var t = function() {
                                var e = H();
                                G(e) ? T = setTimeout(t, 2500) : (M = e,
                                T = void 0)
                            };
                            t()
                        }
                    }(),
                    function() {
                        return r(t, void 0, void 0, (function() {
                            var t;
                            return a(this, (function(e) {
                                switch (e.label) {
                                case 0:
                                    return G(t = H()) ? M ? [2, s([], M, !0)] : (n = document).fullscreenElement || n.msFullscreenElement || n.mozFullScreenElement || n.webkitFullscreenElement ? [4, I()] : [3, 2] : [3, 2];
                                case 1:
                                    e.sent(),
                                    t = H(),
                                    e.label = 2;
                                case 2:
                                    return G(t) || (M = t),
                                    [2, t]
                                }
                                var n
                            }
                            ))
                        }
                        ))
                    }
                }();
                return function() {
                    return r(t, void 0, void 0, (function() {
                        var t, n;
                        return a(this, (function(i) {
                            switch (i.label) {
                            case 0:
                                return [4, e()];
                            case 1:
                                return t = i.sent(),
                                [2, [(n = function(t) {
                                    return null === t ? null : k(t, 10)
                                }
                                )(t[0]), n(t[1]), n(t[2]), n(t[3])]]
                            }
                        }
                        ))
                    }
                    ))
                }
            },
            osCpu: function() {
                return navigator.oscpu
            },
            languages: function() {
                var t, e = navigator, n = [], i = e.language || e.userLanguage || e.browserLanguage || e.systemLanguage;
                if (void 0 !== i && n.push([i]),
                Array.isArray(e.languages))
                    x() && _([!("MediaSettingsRange"in (t = window)), "RTCEncodedAudioFrame"in t, "" + t.Intl == "[object Intl]", "" + t.Reflect == "[object Reflect]"]) >= 3 || n.push(e.languages);
                else if ("string" == typeof e.languages) {
                    var o = e.languages;
                    o && n.push(o.split(","))
                }
                return n
            },
            colorDepth: function() {
                return window.screen.colorDepth
            },
            deviceMemory: function() {
                return w(b(navigator.deviceMemory), void 0)
            },
            screenResolution: function() {
                var t = screen
                  , e = function(t) {
                    return w(y(t), null)
                }
                  , n = [e(t.width), e(t.height)];
                return n.sort().reverse(),
                n
            },
            hardwareConcurrency: function() {
                return w(y(navigator.hardwareConcurrency), void 0)
            },
            timezone: function() {
                var t, e = null === (t = window.Intl) || void 0 === t ? void 0 : t.DateTimeFormat;
                if (e) {
                    var n = (new e).resolvedOptions().timeZone;
                    if (n)
                        return n
                }
                var i, o = (i = (new Date).getFullYear(),
                -Math.max(b(new Date(i,0,1).getTimezoneOffset()), b(new Date(i,6,1).getTimezoneOffset())));
                return "UTC".concat(o >= 0 ? "+" : "").concat(Math.abs(o))
            },
            sessionStorage: function() {
                try {
                    return !!window.sessionStorage
                } catch (t) {
                    return !0
                }
            },
            localStorage: function() {
                try {
                    return !!window.localStorage
                } catch (t) {
                    return !0
                }
            },
            indexedDB: function() {
                var t, e;
                if (!(Y() || (t = window,
                e = navigator,
                _(["msWriteProfilerMark"in t, "MSStream"in t, "msLaunchUri"in e, "msSaveBlob"in e]) >= 3 && !Y())))
                    try {
                        return !!window.indexedDB
                    } catch (t) {
                        return !0
                    }
            },
            openDatabase: function() {
                return !!window.openDatabase
            },
            cpuClass: function() {
                return navigator.cpuClass
            },
            platform: function() {
                var t = navigator.platform;
                return "MacIntel" === t && L() && !C() ? function() {
                    if ("iPad" === navigator.platform)
                        return !0;
                    var t = screen
                      , e = t.width / t.height;
                    return _(["MediaSource"in window, !!Element.prototype.webkitRequestFullscreen, e > .65 && e < 1.53]) >= 2
                }() ? "iPad" : "iPhone" : t
            },
            plugins: function() {
                var t = navigator.plugins;
                if (t) {
                    for (var e = [], n = 0; n < t.length; ++n) {
                        var i = t[n];
                        if (i) {
                            for (var o = [], r = 0; r < i.length; ++r) {
                                var a = i[r];
                                o.push({
                                    type: a.type,
                                    suffixes: a.suffixes
                                })
                            }
                            e.push({
                                name: i.name,
                                description: i.description,
                                mimeTypes: o
                            })
                        }
                    }
                    return e
                }
            },
            canvas: function() {
                var t, e, n = !1, i = function() {
                    var t = document.createElement("canvas");
                    return t.width = 1,
                    t.height = 1,
                    [t, t.getContext("2d")]
                }(), o = i[0], r = i[1];
                if (function(t, e) {
                    return !(!e || !t.toDataURL)
                }(o, r)) {
                    n = function(t) {
                        return t.rect(0, 0, 10, 10),
                        t.rect(2, 2, 6, 6),
                        !t.isPointInPath(5, 5, "evenodd")
                    }(r),
                    function(t, e) {
                        t.width = 240,
                        t.height = 60,
                        e.textBaseline = "alphabetic",
                        e.fillStyle = "#f60",
                        e.fillRect(100, 1, 62, 20),
                        e.fillStyle = "#069",
                        e.font = '11pt "Times New Roman"';
                        var n = "Cwm fjordbank gly ".concat(String.fromCharCode(55357, 56835));
                        e.fillText(n, 2, 15),
                        e.fillStyle = "rgba(102, 204, 0, 0.2)",
                        e.font = "18pt Arial",
                        e.fillText(n, 4, 45)
                    }(o, r);
                    var a = W(o);
                    a !== W(o) ? t = e = "unstable" : (e = a,
                    function(t, e) {
                        t.width = 122,
                        t.height = 110,
                        e.globalCompositeOperation = "multiply";
                        for (var n = 0, i = [["#f2f", 40, 40], ["#2ff", 80, 40], ["#ff2", 60, 80]]; n < i.length; n++) {
                            var o = i[n]
                              , r = o[0]
                              , a = o[1]
                              , s = o[2];
                            e.fillStyle = r,
                            e.beginPath(),
                            e.arc(a, s, 40, 0, 2 * Math.PI, !0),
                            e.closePath(),
                            e.fill()
                        }
                        e.fillStyle = "#f9c",
                        e.arc(60, 60, 60, 0, 2 * Math.PI, !0),
                        e.arc(60, 60, 20, 0, 2 * Math.PI, !0),
                        e.fill("evenodd")
                    }(o, r),
                    t = W(o))
                } else
                    t = e = "";
                return {
                    winding: n,
                    geometry: t,
                    text: e
                }
            },
            touchSupport: function() {
                var t, e = navigator, n = 0;
                void 0 !== e.maxTouchPoints ? n = y(e.maxTouchPoints) : void 0 !== e.msMaxTouchPoints && (n = e.msMaxTouchPoints);
                try {
                    document.createEvent("TouchEvent"),
                    t = !0
                } catch (e) {
                    t = !1
                }
                return {
                    maxTouchPoints: n,
                    touchEvent: t,
                    touchStart: "ontouchstart"in window
                }
            },
            vendor: function() {
                return navigator.vendor || ""
            },
            vendorFlavors: function() {
                for (var t = [], e = 0, n = ["chrome", "safari", "__crWeb", "__gCrWeb", "yandex", "__yb", "__ybro", "__firefox__", "__edgeTrackingPreventionStatistics", "webkit", "oprt", "samsungAr", "ucweb", "UCShellJava", "puffinDevice"]; e < n.length; e++) {
                    var i = n[e]
                      , o = window[i];
                    o && "object" == typeof o && t.push(i)
                }
                return t.sort()
            },
            cookiesEnabled: function() {
                var t = document;
                try {
                    t.cookie = "cookietest=1; SameSite=Strict;";
                    var e = -1 !== t.cookie.indexOf("cookietest=");
                    return t.cookie = "cookietest=1; SameSite=Strict; expires=Thu, 01-Jan-1970 00:00:01 GMT",
                    e
                } catch (t) {
                    return !1
                }
            },
            colorGamut: function() {
                for (var t = 0, e = ["rec2020", "p3", "srgb"]; t < e.length; t++) {
                    var n = e[t];
                    if (matchMedia("(color-gamut: ".concat(n, ")")).matches)
                        return n
                }
            },
            invertedColors: function() {
                return !!z("inverted") || !z("none") && void 0
            },
            forcedColors: function() {
                return !!X("active") || !X("none") && void 0
            },
            monochrome: function() {
                if (matchMedia("(min-monochrome: 0)").matches) {
                    for (var t = 0; t <= 100; ++t)
                        if (matchMedia("(max-monochrome: ".concat(t, ")")).matches)
                            return t;
                    throw new Error("Too high value")
                }
            },
            contrast: function() {
                return U("no-preference") ? 0 : U("high") || U("more") ? 1 : U("low") || U("less") ? -1 : U("forced") ? 10 : void 0
            },
            reducedMotion: function() {
                return !!J("reduce") || !J("no-preference") && void 0
            },
            hdr: function() {
                return !!Q("high") || !Q("standard") && void 0
            },
            math: function() {
                var t, e = K.acos || q, n = K.acosh || q, i = K.asin || q, o = K.asinh || q, r = K.atanh || q, a = K.atan || q, s = K.sin || q, c = K.sinh || q, u = K.cos || q, l = K.cosh || q, d = K.tan || q, h = K.tanh || q, f = K.exp || q, p = K.expm1 || q, S = K.log1p || q;
                return {
                    acos: e(.12312423423423424),
                    acosh: n(1e308),
                    acoshPf: (t = 1e154,
                    K.log(t + K.sqrt(t * t - 1))),
                    asin: i(.12312423423423424),
                    asinh: o(1),
                    asinhPf: K.log(1 + K.sqrt(2)),
                    atanh: r(.5),
                    atanhPf: K.log(3) / 2,
                    atan: a(.5),
                    sin: s(-1e300),
                    sinh: c(1),
                    sinhPf: K.exp(1) - 1 / K.exp(1) / 2,
                    cos: u(10.000000000123),
                    cosh: l(1),
                    coshPf: (K.exp(1) + 1 / K.exp(1)) / 2,
                    tan: d(-1e300),
                    tanh: h(1),
                    tanhPf: (K.exp(2) - 1) / (K.exp(2) + 1),
                    exp: f(1),
                    expm1: p(1),
                    expm1Pf: K.exp(1) - 1,
                    log1p: S(10),
                    log1pPf: K.log(11),
                    powPI: K.pow(K.PI, -100)
                }
            },
            videoCard: function() {
                var t, e = document.createElement("canvas"), n = null !== (t = e.getContext("webgl")) && void 0 !== t ? t : e.getContext("experimental-webgl");
                if (n && "getExtension"in n) {
                    var i = n.getExtension("WEBGL_debug_renderer_info");
                    if (i)
                        return {
                            vendor: (n.getParameter(i.UNMASKED_VENDOR_WEBGL) || "").toString(),
                            renderer: (n.getParameter(i.UNMASKED_RENDERER_WEBGL) || "").toString()
                        }
                }
            },
            pdfViewerEnabled: function() {
                return navigator.pdfViewerEnabled
            },
            architecture: function() {
                var t = new Float32Array(1)
                  , e = new Uint8Array(t.buffer);
                return t[0] = 1 / 0,
                t[0] = t[0] - t[0],
                e[3]
            }
        };
        function et(t) {
            var e = function(t) {
                if (P())
                    return .4;
                if (L())
                    return C() ? .5 : .3;
                var e = t.platform.value || "";
                return /^Win/.test(e) ? .6 : /^Mac/.test(e) ? .5 : .7
            }(t)
              , n = function(t) {
                return k(.99 + .01 * t, 1e-4)
            }(e);
            return {
                score: e,
                comment: "$ if upgrade to Pro: https://fpjs.dev/pro".replace(/\$/g, "".concat(n))
            }
        }
        function nt(t) {
            return JSON.stringify(t, (function(t, e) {
                return e instanceof Error ? o({
                    name: (n = e).name,
                    message: n.message,
                    stack: null === (i = n.stack) || void 0 === i ? void 0 : i.split("\n")
                }, n) : e;
                var n, i
            }
            ), 2)
        }
        function it(t) {
            return function(t, e) {
                e = e || 0;
                var n, i = (t = t || "").length % 16, o = t.length - i, r = [0, e], a = [0, e], s = [0, 0], c = [0, 0], u = [2277735313, 289559509], l = [1291169091, 658871167];
                for (n = 0; n < o; n += 16)
                    s = [255 & t.charCodeAt(n + 4) | (255 & t.charCodeAt(n + 5)) << 8 | (255 & t.charCodeAt(n + 6)) << 16 | (255 & t.charCodeAt(n + 7)) << 24, 255 & t.charCodeAt(n) | (255 & t.charCodeAt(n + 1)) << 8 | (255 & t.charCodeAt(n + 2)) << 16 | (255 & t.charCodeAt(n + 3)) << 24],
                    c = [255 & t.charCodeAt(n + 12) | (255 & t.charCodeAt(n + 13)) << 8 | (255 & t.charCodeAt(n + 14)) << 16 | (255 & t.charCodeAt(n + 15)) << 24, 255 & t.charCodeAt(n + 8) | (255 & t.charCodeAt(n + 9)) << 8 | (255 & t.charCodeAt(n + 10)) << 16 | (255 & t.charCodeAt(n + 11)) << 24],
                    s = S(s = p(s, u), 31),
                    r = f(r = S(r = g(r, s = p(s, l)), 27), a),
                    r = f(p(r, [0, 5]), [0, 1390208809]),
                    c = S(c = p(c, l), 33),
                    a = f(a = S(a = g(a, c = p(c, u)), 31), r),
                    a = f(p(a, [0, 5]), [0, 944331445]);
                switch (s = [0, 0],
                c = [0, 0],
                i) {
                case 15:
                    c = g(c, m([0, t.charCodeAt(n + 14)], 48));
                case 14:
                    c = g(c, m([0, t.charCodeAt(n + 13)], 40));
                case 13:
                    c = g(c, m([0, t.charCodeAt(n + 12)], 32));
                case 12:
                    c = g(c, m([0, t.charCodeAt(n + 11)], 24));
                case 11:
                    c = g(c, m([0, t.charCodeAt(n + 10)], 16));
                case 10:
                    c = g(c, m([0, t.charCodeAt(n + 9)], 8));
                case 9:
                    c = p(c = g(c, [0, t.charCodeAt(n + 8)]), l),
                    a = g(a, c = p(c = S(c, 33), u));
                case 8:
                    s = g(s, m([0, t.charCodeAt(n + 7)], 56));
                case 7:
                    s = g(s, m([0, t.charCodeAt(n + 6)], 48));
                case 6:
                    s = g(s, m([0, t.charCodeAt(n + 5)], 40));
                case 5:
                    s = g(s, m([0, t.charCodeAt(n + 4)], 32));
                case 4:
                    s = g(s, m([0, t.charCodeAt(n + 3)], 24));
                case 3:
                    s = g(s, m([0, t.charCodeAt(n + 2)], 16));
                case 2:
                    s = g(s, m([0, t.charCodeAt(n + 1)], 8));
                case 1:
                    s = p(s = g(s, [0, t.charCodeAt(n)]), u),
                    r = g(r, s = p(s = S(s, 31), l))
                }
                return r = f(r = g(r, [0, t.length]), a = g(a, [0, t.length])),
                a = f(a, r),
                r = f(r = v(r), a = v(a)),
                a = f(a, r),
                ("00000000" + (r[0] >>> 0).toString(16)).slice(-8) + ("00000000" + (r[1] >>> 0).toString(16)).slice(-8) + ("00000000" + (a[0] >>> 0).toString(16)).slice(-8) + ("00000000" + (a[1] >>> 0).toString(16)).slice(-8)
            }(function(t) {
                for (var e = "", n = 0, i = Object.keys(t).sort(); n < i.length; n++) {
                    var o = i[n]
                      , r = t[o]
                      , a = r.error ? "error" : JSON.stringify(r.value);
                    e += "".concat(e ? "|" : "").concat(o.replace(/([:|\\])/g, "\\$1"), ":").concat(a)
                }
                return e
            }(t))
        }
        function ot(t) {
            return void 0 === t && (t = 50),
            function(t, e) {
                void 0 === e && (e = 1 / 0);
                var n = window.requestIdleCallback;
                return n ? new Promise((function(t) {
                    return n.call(window, (function() {
                        return t()
                    }
                    ), {
                        timeout: e
                    })
                }
                )) : u(Math.min(t, e))
            }(t, 2 * t)
        }
        function rt(t, e) {
            var n = Date.now();
            return {
                get: function(i) {
                    return r(this, void 0, void 0, (function() {
                        var o, r, s;
                        return a(this, (function(a) {
                            switch (a.label) {
                            case 0:
                                return o = Date.now(),
                                [4, t()];
                            case 1:
                                return r = a.sent(),
                                s = function(t) {
                                    var e;
                                    return {
                                        get visitorId() {
                                            return void 0 === e && (e = it(this.components)),
                                            e
                                        },
                                        set visitorId(t) {
                                            e = t
                                        },
                                        confidence: et(t),
                                        components: t,
                                        version: c
                                    }
                                }(r),
                                (e || (null == i ? void 0 : i.debug)) && console.log("Copy the text below to get the debug data:\n\n```\nversion: ".concat(s.version, "\nuserAgent: ").concat(navigator.userAgent, "\ntimeBetweenLoadAndGet: ").concat(o - n, "\nvisitorId: ").concat(s.visitorId, "\ncomponents: ").concat(nt(r), "\n```")),
                                [2, s]
                            }
                        }
                        ))
                    }
                    ))
                }
            }
        }
        var at, st, ct = {
            load: function(t) {
                var e = void 0 === t ? {} : t
                  , n = e.delayFallback
                  , i = e.debug
                  , o = e.monitoring
                  , s = void 0 === o || o;
                return r(this, void 0, void 0, (function() {
                    return a(this, (function(t) {
                        switch (t.label) {
                        case 0:
                            return s && function() {
                                if (!(window.__fpjs_d_m || Math.random() >= .001))
                                    try {
                                        var t = new XMLHttpRequest;
                                        t.open("get", "https://m1.openfpcdn.io/fingerprintjs/v".concat(c, "/npm-monitoring"), !0),
                                        t.send()
                                    } catch (t) {
                                        console.error(t)
                                    }
                            }(),
                            [4, ot(n)];
                        case 1:
                            return t.sent(),
                            [2, rt(N(tt, {
                                debug: i
                            }, []), i)]
                        }
                    }
                    ))
                }
                ))
            },
            hashComponents: it,
            componentsToDebugString: nt
        };
        SYNO.SDS.PreferAuthType = (at = function(t) {
            return 0 < t.indexOf("\\") ? t.split("\\").pop().toLowerCase() : t.split("@")[0].toLowerCase()
        }
        ,
        {
            Get: function(t) {
                let e = at(t);
                return 0 === e.length ? null : localStorage.getItem(e + ".AuthType")
            },
            Set: function(t) {
                let e = localStorage.getItem("choseAuthType");
                if (e) {
                    let n = at(t);
                    0 < n.length && localStorage.setItem(n + ".AuthType", e),
                    localStorage.removeItem("choseAuthType")
                }
            }
        }),
        SYNO.SDS.HandShakeCrPoSt = (st = (t, e) => {
            let n = ("; " + t).split("; " + e + "=")[1];
            return n ? n.split(";")[0] : void 0
        }
        ,
        {
            Get: function() {
                return new Promise((t => {
                    let e = decodeURI(window.atob(SYNO.SDS.GetCookieByName("_CrPoSt")))
                      , n = st(e, "protocol")
                      , i = st(e, "port");
                    return !n || n === window.location.protocol && i === window.location.port ? t(JSON.parse(localStorage.getItem("crossPortData"))) : "https:" === window.location.protocol && "http:" === n ? t({
                        error: "data under mixed content."
                    }) : t({
                        error: "cross scheme or port is not permitted"
                    })
                }
                ))
            },
            Set: function(t) {
                let e = "protocol=" + window.location.protocol + "; port=" + window.location.port + ";";
                e += " pathname=" + window.location.pathname + ";",
                SYNO.SDS._SetCookie("_CrPoSt", window.btoa(e), 365, "/"),
                localStorage.setItem("crossPortData", JSON.stringify(t))
            }
        }),
        SYNO.SDS.HandShake = {
            initHandShake: function() {
                return new Promise(( (t, e) => {
                    if ("undefined" == typeof noise_c_wasm)
                        return t(!1);
                    ct.load({
                        monitoring: !1
                    }).then((t => t.get())).then((t => {
                        this.fid = t.visitorId
                    }
                    )).catch((t => {
                        SYNO.Debug.error("failed to get fingerprint id:", t)
                    }
                    )),
                    SYNO.SDS.HandShakeCrPoSt.Get().then((e => {
                        noise_c_wasm((n => {
                            sodium.ready.then(( () => {
                                SYNO.SDS.HandShake.Init(n, e || {}),
                                this.cred.Resume().then(( () => {
                                    t(!0)
                                }
                                )).catch((e => {
                                    t(!1)
                                }
                                ))
                            }
                            ))
                        }
                        ))
                    }
                    )).catch((e => t(!1)))
                }
                ))
            },
            Init: function(t, e) {
                SYNO.SDS.HandShake._noise = t,
                SYNO.SDS.HandShake._tabid = sodium.randombytes_random() % 65536;
                let n = new synocredential(t,{
                    account: e.currentLoginUser || "",
                    authtok: e._HSID || "",
                    headers: {}
                });
                synowebapi.env.setCredential(n),
                this.cred = n
            },
            UrlAppend: function(t) {
                if (!SYNO.SDS.HandShake.cred)
                    return t;
                let e = SYNO.SDS.HandShake.cred.GetRequestHash();
                return e ? SYNO.SDS.urlAppend(t, "SynoHash=" + e) : t
            },
            GetCodeLoginParams: function(t) {
                let e = {};
                return t && "code" === t.response_type && ["client_id", "session", "redirect_uri", "code_challenge", "code_challenge_method", "response_type"].forEach((n => {
                    n in t && (e[n] = t[n])
                }
                )),
                e
            },
            GetLoginParams: function(t) {
                let e = SYNO.SDS.GetCookieByName("_SSID")
                  , n = SYNO.SDS.HandShake.IsSupport() ? this.cred.GetLoginParams({
                    tabid: SYNO.SDS.HandShake._tabid,
                    enable_syno_token: _S("enable_syno_token")
                }, e) : {
                    api: "SYNO.API.Auth",
                    version: 6,
                    method: "login",
                    session: "webui",
                    enable_syno_token: _S("enable_syno_token")
                }
                  , i = SYNO.SDS.urlDecode(window.location.search.split("?")[1])
                  , o = {};
                "code" === i.response_type && (o = Object.assign(o, this.GetCodeLoginParams(i)));
                let r = {
                    client: "browser"
                };
                return this.fid && this.fid.length > 0 && (r.fid = this.fid),
                Object.assign(i, n, t, o, r)
            },
            SendRedirectRequest: function(t, e) {
                let n = document.createElement("form");
                n.hidden = !0,
                n.method = "GET",
                n.action = "webapi/entry.cgi";
                for (const [i,o] of Object.entries({
                    api: "SYNO.API.Auth.RedirectURI",
                    version: 1,
                    method: "run",
                    session: t,
                    redirect_url: e
                })) {
                    let t = document.createElement("textarea");
                    t.name = i,
                    t.value = o,
                    n.appendChild(t)
                }
                document.body.appendChild(n),
                n.submit()
            },
            GetLoginSynoToken: function(t, e) {
                let n = null
                  , i = SYNO.SDS.urlDecode(window.location.search.split("?")[1])
                  , o = i.state;
                if (!0 === t.success && SYNO.SDS.isString(i.synossoJSSDK))
                    return delete SYNO.SDS.initData,
                    void window.location.replace("webman/sso/SSOOauth.cgi" + window.location.search);
                if (t.data.code && t.data.code.length > 0) {
                    if (window.opener && "" === t.data.redirect_uri)
                        return t.data.rs = SYNO.SDS.GetCookieByName("_SSID"),
                        window.opener.postMessage(t.data, i.opener),
                        void window.close();
                    if ("" === t.data.redirect_uri)
                        return void window.location.replace("/error");
                    let n = t.data.redirect_uri + "?code=" + t.data.code;
                    return n += "&rs=" + SYNO.SDS.GetCookieByName("_SSID"),
                    o && (n += "&state=" + o),
                    void (i.session ? this.SendRedirectRequest(i.session, n) : this.SendRedirectRequest(e, n))
                }
                if (!0 !== t.success || (SYNO.SDS.PreferAuthType.Set(t.data.account),
                !i.redirect_uri || i.flow && "oauth" === i.flow))
                    return t.data && (SYNO.SDS.HandShake.IsSupport() && (this.cred.SetLoginResult(t.data),
                    SYNO.SDS.HandShakeCrPoSt.Set({
                        currentLoginUser: t.data.account,
                        _HSID: this.cred.GetAuthtok()
                    })),
                    t.data.synotoken && (n = t.data.synotoken)),
                    n;
                window.location.replace(SYNO.SDS.Utils.RemoveURLParam(window.location.href, "redirect_uri"))
            },
            IsSupport: function() {
                return ("http:" !== window.location.protocol || !0 !== _S("is_secure")) && !!SYNO.SDS.GetCookieByName("_SSID") && void 0 !== SYNO.SDS.HandShake._noise
            },
            UnSupport: function() {
                delete SYNO.SDS.HandShake._noise
            }
        },
        n(429),
        SYNO.SDS.CreateBackgroundTpl = function(t) {
            return new (SYNO.SDS.Frameworks.get("vue").extend(i))(t)
        }
    }()
}();
