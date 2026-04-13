/* Copyright (c) 2025 Synology Inc. All rights reserved. */

Ext.define("SYNO.SDS.VideoPlayerCommonDSM.Button", {
    extend: "SYNO.ux.Button",
    constructor: function(b) {
        var a = {
            cls: "vp-button",
            handler: this.clickHandler
        };
        this.callParent([Ext.apply(a, b)])
    },
    getController: function() {
        return this.module.getController()
    },
    clickHandler: Ext.emptyFn
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.Menu", {
    extend: "Ext.menu.Menu",
    constructor: function(b) {
        var a = {
            cls: "syno-vp-menu",
            listeners: {
                scope: this,
                beforerender: function() {
                    this.orig_useShims = Ext.useShims;
                    Ext.useShims = true
                },
                afterrender: function() {
                    Ext.useShims = this.orig_useShims;
                    this.keyNav.disable()
                }
            }
        };
        this.callParent([Ext.apply(a, b)])
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.ItemMenu", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.Menu",
    constructor: function(b) {
        var a = {
            defaultOffsets: [0, -11]
        };
        this.callParent([Ext.apply(a, b)]);
        this.addClass("item-menu")
    },
    addItemGeneral: function(g, f, a, d, b) {
        var e = Ext.util.Format.ellipsis(f, 40, false);
        var c = new Ext.menu.Item({
            item_id: g,
            text: Ext.util.Format.htmlEncode(e),
            cls: a,
            group: d || "",
            scope: this,
            handler: b,
            listeners: {
                render: function() {
                    this.getEl().dom.qtip = Ext.util.Format.htmlEncode(f)
                }
            }
        });
        this.addItem(c)
    },
    addTitle: function(b, a) {
        if (!Ext.isString(b)) {
            return
        }
        this.addItemGeneral(Ext.id(), b, "title", a, Ext.emptyFn)
    },
    addOneItem: function(f, e, a, c, d) {
        if (!Ext.isDefined(f) || !Ext.isString(e) || !Ext.isFunction(a)) {
            return
        }
        var b = function() {
            this.setItemSelected(f, d);
            a()
        };
        this.addItemGeneral(f, e, ((true === c) ? "selected" : ""), d, b)
    },
    setItemSelected: function(b, a) {
        if (!this.items || !Ext.isDefined(b)) {
            return
        }
        this.items.each(function(c) {
            if (!Ext.isDefined(a) || c.group === a) {
                c.removeClass("selected");
                c[(c.item_id === b) ? "addClass" : "removeClass"]("selected")
            }
        })
    },
    removeGroup: function(a) {
        if (!Ext.isObject(this.items)) {
            return
        }
        this.items.each(function(b) {
            if (b.group === a) {
                this.remove(b)
            }
        }, this)
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.SubtitleMenu", {
    statics: {
        ID_NO_SUBTITLE: "no_subtitle",
        ID_EXTERNAL: "external",
        ID_BROWSE_SUBTITLE: "browse_subtitle",
        ID_SHIFT_SUBTITLE: "shift_subtitle"
    },
    extend: "SYNO.SDS.VideoPlayerCommonDSM.ItemMenu",
    constructor: function(a) {
        this.callParent([a]);
        this.addNoSubtitleItem()
    },
    addNoSubtitleItem: function() {
        this.addOneItem(SYNO.SDS.VideoPlayerCommonDSM.SubtitleMenu.ID_NO_SUBTITLE, _T("video_player", "no_subtitle"), this.setNoSubtitle.createDelegate(this), true)
    },
    setNoSubtitle: function() {
        this.button.getController().setSubtitleEnabled(false)
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.Util", {
    statics: {
        STATE: {
            NO_MEDIA: 0,
            STOPPED: 1,
            PLAYING: 2,
            PAUSED: 3,
            BUFFERING: 4,
            ERROR: 5,
            CLEAR: 6
        },
        MimeType: {
            ogg: "audio/ogg",
            ogv: "video/ogg",
            wav: "audio/wav",
            mp3: "audio/mpeg",
            m4a: "audio/mp4",
            m4b: "audio/mp4",
            m4v: "video/mp4",
            mov: "video/mp4"
        },
        getFileExt: function(a) {
            var b = (/[.]/.exec(a)) ? /[^.]+$/.exec(a)[0] : "";
            return b.toLowerCase()
        },
        createVLCElement: function(e, f, d, a, c) {
            var b;
            if (Ext.isIE || Ext.isIE11) {
                b = e.createChild({
                    tag: "object",
                    id: f,
                    classid: "clsid:9BE31822-FDAD-461B-AD51-BE1D1C159921",
                    codebase: "http://download.videolan.org/pub/videolan/vlc/last/win32/axvlc.cab",
                    width: d || "100%",
                    height: a || "100%",
                    style: c || "",
                    cn: [{
                        tag: "param",
                        name: "src",
                        value: ""
                    }, {
                        tag: "param",
                        name: "allowfullscreen",
                        value: "false"
                    }, {
                        tag: "param",
                        name: "bgcolor",
                        value: "#000000"
                    }, {
                        tag: "param",
                        name: "toolbar",
                        value: "false"
                    }]
                })
            } else {
                b = e.createChild({
                    tag: "embed",
                    id: f,
                    type: "application/x-vlc-plugin",
                    version: "VideoLAN.VLCPlugin.2",
                    pluginspage: "http://www.videolan.org/",
                    width: d || "100%",
                    height: a || "100%",
                    style: c || "",
                    src: "",
                    allowfullscreen: "false",
                    bgcolor: "#000000",
                    toolbar: "false"
                })
            }
            return b
        },
        isVLCSupported: function() {
            return false
        },
        detectPlugin: function() {
            var b, d, a, c = navigator.plugins || [], f = arguments;
            if (Ext.isIE || Ext.isIE11) {
                try {
                    if ((new ActiveXObject(f[0]))) {
                        return true
                    }
                } catch (g) {}
                return false
            }
            for (b = 0; b < c.length; ++b) {
                a = true;
                for (d = 1; d < f.length; ++d) {
                    if (-1 === c[b].name.indexOf(f[d]) && -1 === c[b].description.indexOf(f[d])) {
                        a = false;
                        break
                    }
                }
                if (a) {
                    return true
                }
            }
            return false
        },
        addDomListener: function(a) {
            return function(f, e, d, c, b) {
                if (!f || !Ext.isString(e) || !Ext.isFunction(d) || !Ext.isObject(c)) {
                    return
                }
                if (a && Ext.isIE && f.attachEvent) {
                    f.attachEvent(e, d.createDelegate(c, b))
                } else {
                    if (Ext.isFunction(f.addEventListener)) {
                        f.addEventListener(e, d.createDelegate(c, b), false)
                    } else {
                        f["on" + e] = d.createDelegate(c, b)
                    }
                }
            }
        },
        FullscreenEventMap: {
            requestFullscreen: "fullscreenchange",
            webkitRequestFullscreen: "webkitfullscreenchange",
            mozRequestFullScreen: "mozfullscreenchange",
            msRequestFullscreen: "MSFullscreenChange"
        },
        FullscreenFn: ["requestFullscreen", "webkitRequestFullscreen", "mozRequestFullScreen", "msRequestFullscreen"],
        hookDoLayout: function(a) {
            var c;
            var b = a.getEl();
            Ext.each(SYNO.SDS.VideoPlayerCommonDSM.Util.FullscreenFn, function(e) {
                if (Ext.isFunction(b.dom[e])) {
                    c = SYNO.SDS.VideoPlayerCommonDSM.Util.FullscreenEventMap[e];
                    return false
                }
            });
            if (Ext.isString(c)) {
                var d = function() {
                    SYNO.Debug("dolayout");
                    a.doLayout()
                };
                SYNO.Debug("add fullscreen listener to: ", c);
                document.addEventListener(c, d, false)
            }
        },
        setDomFullscreen: function(a) {
            Ext.each(SYNO.SDS.VideoPlayerCommonDSM.Util.FullscreenFn, function(b) {
                if (Ext.isFunction(a[b])) {
                    a[b]();
                    return false
                }
            })
        },
        isDomFullscreenSupported: function() {
            var b = document.body;
            var a = false;
            Ext.each(SYNO.SDS.VideoPlayerCommonDSM.Util.FullscreenFn, function(c) {
                if (Ext.isFunction(b[c])) {
                    a = true;
                    return false
                }
            });
            return a
        },
        isMobile: function() {
            return _S("isMobile") === true
        },
        utfencode: function(b) {
            var e, d, a = "";
            b = b.replace(/\r\n/g, "\n");
            for (e = 0; e < b.length; e++) {
                d = b.charCodeAt(e);
                if (d < 128) {
                    a += String.fromCharCode(d)
                } else {
                    if ((d > 127) && (d < 2048)) {
                        a += String.fromCharCode((d >> 6) | 192);
                        a += String.fromCharCode((d & 63) | 128)
                    } else {
                        a += String.fromCharCode((d >> 12) | 224);
                        a += String.fromCharCode(((d >> 6) & 63) | 128);
                        a += String.fromCharCode((d & 63) | 128)
                    }
                }
            }
            return a
        },
        bin2hex: function(d) {
            var c, e = 0, b = [];
            d = SYNO.SDS.VideoPlayerCommonDSM.Util.utfencode(d) + "";
            e = d.length;
            for (c = 0; c < e; c++) {
                b[c] = d.charCodeAt(c).toString(16).replace(/^([\da-f])$/, "0$1")
            }
            return b.join("")
        },
        getDownloadLink: function(b) {
            var a = b.substr(1 + b.lastIndexOf("/")).replace(/[\/\\\:\?\><\*\"\;\|\#\%]/g, "-");
            var c = {
                mode: Ext.encode("download"),
                stdhtml: Ext.encode(false),
                dlink: Ext.encode(SYNO.SDS.VideoPlayerCommonDSM.Util.bin2hex(b))
            };
            return Ext.urlAppend(String.format("fbdownload/{0}", encodeURIComponent(a)), Ext.urlEncode(c))
        },
        launchFn: function(d, b, a) {
            a = a || false;
            var e;
            if (SYNO.SDS.StatusNotifier.isAppEnabled("SYNO.SDS.VideoStation.AppInstance") && (true === SYNO.SDS.StatusNotifier.isAppHasPrivilege("SYNO.SDS.VideoStation.AppInstance"))) {
                e = {
                    player_id: "streaming",
                    browse_type: "filevideo",
                    video_type: "filevideo",
                    is_drive: a
                };
                if (a) {
                    e = Ext.apply(e, {
                        drive_path: "id:" + d[0].get("file_id")
                    })
                } else {
                    e = Ext.apply(e, {
                        path: d[0].get("real_path")
                    })
                }
                SYNO.SDS.WindowLaunch("SYNO.VideoController2.Application", e)
            } else {
                e = {
                    ieMode: 9,
                    is_drive: a
                };
                if (a) {
                    var c;
                    if (b) {
                        b = Ext.getClassByName(b);
                        c = b(d[0], "SYNO.SDS.VideoPlayer2.Application")
                    }
                    e = Ext.apply(e, {
                        url: c,
                        path: "id:" + d[0].get("file_id"),
                        filename: d[0].get("name")
                    })
                } else {
                    e = Ext.apply(e, {
                        path: d[0].get("path"),
                        file_id: d[0].get("file_id")
                    })
                }
                SYNO.SDS.WindowLaunch("SYNO.SDS.VideoPlayer2.Application", e)
            }
        },
        launchDriveFn: function(a) {
            SYNO.SDS.VideoPlayerCommonDSM.Util.launchFn(a.recs, a.urlFn, true)
        }
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.MenuButton", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.Button",
    constructor: function(b) {
        var a = {
            menu: this.createMenu(),
            menuAlign: "br-tr"
        };
        this.callParent([Ext.apply(a, b)])
    },
    createMenu: Ext.emptyFn,
    getMenuClass: function() {
        return ""
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.SubtitleButton", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.MenuButton",
    constructor: function(a) {
        this.callParent([a]);
        this.addClass("subtitle")
    },
    createMenu: function() {
        return new SYNO.SDS.VideoPlayerCommonDSM.SubtitleMenu({
            button: this
        })
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.FullscreenButton", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.Button",
    constructor: function(b) {
        var a = {
            disabled: !SYNO.SDS.VideoPlayerCommonDSM.Util.isDomFullscreenSupported()
        };
        this.callParent([Ext.apply(a, b)]);
        this.addClass("fullscreen")
    },
    clickHandler: function() {
        this.getController().fullscreen()
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.PlayButton", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.Button",
    constructor: function(a) {
        this.callParent([a]);
        this.addClass("big");
        this.addClass("play-pause");
        this.addClass("play")
    },
    clickHandler: function() {
        this.getController().play()
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.StopButton", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.Button",
    constructor: function(a) {
        this.callParent([a]);
        this.addClass("stop")
    },
    clickHandler: function() {
        this.getController().stop()
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.TimeText", {
    extend: "Ext.Toolbar.TextItem",
    constructor: function(b) {
        var a = {
            text: "00:00",
            listeners: {
                afterrender: {
                    fn: this.initAriaProperty,
                    scope: this
                }
            }
        };
        this.callParent([Ext.apply(a, b)])
    },
    initAriaProperty: function(b) {
        var a = this.el.parent();
        a.setARIA({
            tabindex: 0,
            label: this.ariaTitle,
            describedby: this.el.id
        })
    },
    formatTime: function(c) {
        c = parseInt(Math.round(c), 10);
        var a = parseInt(c / 3600, 10);
        var d = parseInt((c % 3600) / 60, 10);
        var b = c % 60;
        return ((a > 0) ? a + ":" : "") + String.leftPad(d, 2, "0") + ":" + String.leftPad(b, 2, "0")
    },
    updateView: function(a) {
        if (!Ext.isNumber(a) || 0 >= a) {
            this.setText("00:00")
        } else {
            this.setText(this.formatTime(a))
        }
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.Slider", {
    extend: "SYNO.ux.SingleSlider",
    constructor: function(b) {
        var a = {
            animate: false,
            increment: 1,
            value: 0,
            listeners: {
                scope: this,
                change: this.onChange,
                changecomplete: this.onChangeComplete,
                afterrender: this.onAfterRender
            }
        };
        this.callParent([Ext.apply(a, b)]);
        this.addClass("vp-slider")
    },
    onChange: Ext.emptyFn,
    onChangeComplete: Ext.emptyFn,
    onAfterRender: Ext.emptyFn,
    isDragging: function() {
        return this.thumbs[0].dragging
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.ProgressBar", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.Slider",
    progressMax: 10000,
    constructor: function(b) {
        var a = {
            minValue: 0,
            maxValue: this.progressMax
        };
        this.callParent([Ext.apply(a, b)]);
        this.addClass("syno-vp-progress-bar");
        this.duration = 0
    },
    updateView: function(a, b) {
        this.duration = b || this.duration;
        if (Ext.isNumber(this.duration) && this.duration > 0) {
            this.setDisable(false);
            if (!this.isDragging()) {
                this.setValue(this.progressMax * a / this.duration)
            }
        } else {
            this.setDisable(true)
        }
    },
    insertSeekProgress: function() {
        if (this.seekProgress) {
            return
        }
        this.seekProgress = Ext.DomHelper.insertBefore(this.thumbs[0].el, {
            tag: "div",
            cls: "progress"
        }, true);
        this.seekProgress.setWidth(0);
        this.halfThumb = 12
    },
    onAfterRender: function() {
        this.insertSeekProgress();
        this.setValue(1);
        this.setValue(0)
    },
    onChange: function(c, d, b) {
        var a = this.duration * d / this.progressMax;
        this.module.getControlPanel().setPlaybackPosition(a);
        this.seekProgress.setWidth(b.el.getLeft(true) + this.halfThumb)
    },
    onChangeComplete: function(c, d, b) {
        var a = this.duration * d / this.progressMax;
        if (Ext.isNumber(a)) {
            this.module.getController().seek(a)
        }
    },
    setDisable: function(a) {
        if (a) {
            this.setValue(0);
            this.seekProgress.setWidth(0);
            this.disable()
        } else {
            this.enable()
        }
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.VolumeButton", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.MenuButton",
    constructor: function(b) {
        this.module = b.module;
        var a = {
            muted: false,
            menuAlign: "b-t"
        };
        this.callParent([Ext.apply(a, b)]);
        this.addClass("volume");
        this.on("afterrender", this.registerKeyEvents, this)
    },
    registerKeyEvents: function() {
        this.btnEl.addKeyListener(Ext.EventObject.ENTER, this.onKeyDown, this);
        this.btnEl.addKeyListener(Ext.EventObject.SPACE, this.onKeyDown, this)
    },
    createMenu: function() {
        this.volumePanel = new SYNO.SDS.VideoPlayerCommonDSM.VolumePanel({
            module: this.module
        });
        var a = new SYNO.SDS.VideoPlayerCommonDSM.Menu({
            cls: "syno-vp-volume-menu",
            defaultOffsets: [0, -11],
            items: [this.volumePanel],
            volumePanel: this.volumePanel,
            focus: function() {
                this.volumePanel.volumeBar.focusEl.focus()
            }
        });
        a.on("hide", function() {
            this.btnEl.focus()
        }, this);
        return a
    },
    setMute: function(a) {
        this.muted = a;
        if (this.muted) {
            this.addClass("mute");
            this.hideMenu()
        } else {
            this.removeClass("mute");
            if (this.getEl().hasClass("x-btn-over")) {
                this.showMenu()
            }
        }
    },
    setVolume: function(a) {
        this.volumePanel.volumeBar.updateView(a)
    },
    clickHandler: function() {
        this.getController().toggleMute()
    },
    onClick: function(a) {
        if (a) {
            a.preventDefault()
        }
        if (a.button !== 0 || this.disabled) {
            return
        }
        this.doToggle();
        this.fireEvent("click", this, a);
        if (this.handler) {
            this.handler.call(this.scope || this, this, a)
        }
    },
    onKeyDown: function(a) {
        if (!this.muted && !this.disabled) {
            this.showMenu()
        }
    },
    onMouseOver: function(a) {
        if (!this.muted && !this.disabled) {
            this.showMenu()
        }
        this.callParent(arguments)
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.VolumePanel", {
    extend: "Ext.Panel",
    constructor: function(b) {
        this.volumeBar = new SYNO.SDS.VideoPlayerCommonDSM.VolumeBar({
            module: b.module
        });
        var a = {
            cls: "vp-volume-panel",
            frame: true,
            items: [this.volumeBar]
        };
        this.callParent([Ext.apply(a, b)])
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.VolumeBar", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.Slider",
    constructor: function(b) {
        var a = {
            title: _T("audio_player", "player_volume"),
            cls: "vp-volume-bar",
            minValue: 0,
            maxValue: 100,
            vertical: true
        };
        this.callParent([Ext.apply(a, b)])
    },
    updateView: function(a) {
        if (!this.disabled && !this.isDragging()) {
            this.setValue(a)
        }
    },
    insertVolumeStrip: function() {
        if (this.volumeStrip) {
            return
        }
        this.volumeStrip = Ext.DomHelper.insertBefore(this.thumbs[0].el, {
            tag: "div",
            cls: "volume"
        }, true);
        this.volumeStrip.setHeight(0);
        this.halfThumb = 8
    },
    onAfterRender: function() {
        this.insertVolumeStrip();
        var a = this.getValue();
        this.setValue(1);
        this.setValue(a)
    },
    onChange: function(c, d, b) {
        var a = d / 100 * 138;
        this.volumeStrip.setHeight(a)
    },
    onChangeComplete: function(b, c, a) {
        if (!this.disabled) {
            this.module.getController().setVolume(c)
        }
    },
    setDisable: function(a) {
        if (a) {
            this.setValue(0);
            this.volumeStrip.setWidth(0);
            this.disable()
        } else {
            this.enable()
        }
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.ControlBar", {
    extend: "SYNO.ux.Toolbar",
    slashConfig: {
        cls: "slash",
        xtype: "tbtext",
        text: " / "
    },
    constructor: function(b) {
        this.module = b.module;
        var a = {
            items: [{
                xtype: "tbspacer",
                width: 14
            }, this.getPlayButton(), this.getStopButton(), {
                xtype: "tbspacer",
                width: 14
            }, {
                xtype: "tbseparator",
                cls: "vp-separator"
            }, {
                xtype: "tbspacer",
                width: 30
            }, this.getPositionText(), this.slashConfig, this.getDurationText(), "->", this.getVolumeButton(), this.getSubtitleButton(), this.getFullscreenButton(), {
                xtype: "tbspacer",
                width: 14
            }]
        };
        this.callParent([Ext.apply(a, b)]);
        this.addClass("syno-vp-control-bar")
    },
    getPlayButton: function() {
        if (!Ext.isDefined(this.playButton)) {
            this.playButton = new SYNO.SDS.VideoPlayerCommonDSM.PlayButton({
                "aria-label": _T("audio_player", "player_play"),
                module: this.module
            })
        }
        return this.playButton
    },
    getStopButton: function() {
        if (!Ext.isDefined(this.stopButton)) {
            this.stopButton = new SYNO.SDS.VideoPlayerCommonDSM.StopButton({
                "aria-label": _T("audio_player", "player_stop"),
                module: this.module
            })
        }
        return this.stopButton
    },
    getPositionText: function() {
        if (!Ext.isDefined(this.positionText)) {
            this.positionText = new SYNO.SDS.VideoPlayerCommonDSM.TimeText({
                ariaTitle: _T("audio_player", "current_time"),
                cls: "position"
            })
        }
        return this.positionText
    },
    getDurationText: function() {
        if (!Ext.isDefined(this.durationText)) {
            this.durationText = new SYNO.SDS.VideoPlayerCommonDSM.TimeText({
                ariaTitle: _T("audio_player", "sound_length"),
                cls: "duration"
            })
        }
        return this.durationText
    },
    getVolumeButton: function() {
        if (!Ext.isDefined(this.volumeButton)) {
            this.volumeButton = new SYNO.SDS.VideoPlayerCommonDSM.VolumeButton({
                "aria-label": _T("audio_player", "player_volume"),
                module: this.module
            })
        }
        return this.volumeButton
    },
    getSubtitleButton: function() {
        if (!Ext.isDefined(this.subtitleButton)) {
            this.subtitleButton = new SYNO.SDS.VideoPlayerCommonDSM.SubtitleButton({
                tabIndex: -1,
                module: this.module
            })
        }
        return this.subtitleButton
    },
    getFullscreenButton: function() {
        if (!Ext.isDefined(this.fullscreenButton)) {
            this.fullscreenButton = new SYNO.SDS.VideoPlayerCommonDSM.FullscreenButton({
                tabIndex: -1,
                module: this.module
            })
        }
        return this.fullscreenButton
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.ControlPanel", {
    extend: "Ext.Container",
    constructor: function(b) {
        this.module = b.module;
        var a = {
            overCls: "control-panel-over",
            items: [this.getProgressBar(), this.getControlBar()]
        };
        this.callParent([Ext.apply(a, b)])
    },
    getControlBar: function() {
        if (!Ext.isDefined(this.controlBar)) {
            this.controlBar = new SYNO.SDS.VideoPlayerCommonDSM.ControlBar({
                module: this.module
            })
        }
        return this.controlBar
    },
    getProgressBar: function() {
        if (!Ext.isDefined(this.progressBar)) {
            this.progressBar = new SYNO.SDS.VideoPlayerCommonDSM.ProgressBar({
                module: this.module
            })
        }
        return this.progressBar
    },
    setMute: function(a) {
        this.getControlBar().getVolumeButton().setMute(a)
    },
    setVolume: function(a) {
        this.getControlBar().getVolumeButton().setVolume(a)
    },
    setState: function(b, c) {
        var a = this.getControlBar().getPlayButton();
        switch (b) {
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.CLEAR:
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.STOPPED:
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PAUSED:
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR:
            a.removeClass("pause");
            a.addClass("play");
            break;
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.BUFFERING:
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PLAYING:
            a.removeClass("play");
            a.addClass("pause");
            break;
        default:
            break
        }
        a.setDisabled(b === SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR)
    },
    setTime: function(a, c) {
        var b = this.getProgressBar();
        b.updateView(a, c);
        this.setPlaybackDuration(c)
    },
    setPlaybackPosition: function(a) {
        this.getControlBar().getPositionText().updateView(a)
    },
    setPlaybackDuration: function(a) {
        this.getControlBar().getDurationText().updateView(a)
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.MetaDisplay", {
    extend: "Ext.Container",
    constructor: function(b) {
        var a = {
            itemId: "meta_display",
            cls: "meta-display",
            hidden: true,
            hideMode: "offsets",
            html: this.getHtml()
        };
        this.callParent([Ext.apply(a, b)])
    },
    setImage: function(b) {
        var a = Ext.get(this.getIconID());
        if ("" === b) {
            this.icon_src = "";
            a.hide();
            a.setStyle("background-image", "")
        } else {
            if (b === this.icon_src) {
                return
            }
            this.icon_src = b;
            a.setStyle("background-image", String.format("url({0})", b));
            a.show()
        }
    },
    setText: function(a) {
        if (!Ext.isString(a)) {
            return
        }
        Ext.get(this.getTextID()).update(Ext.util.Format.htmlEncode(a))
    },
    getTextID: function() {
        if (!Ext.isDefined(this.text_id)) {
            this.text_id = Ext.id()
        }
        return this.text_id
    },
    getIconID: function() {
        if (!Ext.isDefined(this.icon_id)) {
            this.icon_id = Ext.id()
        }
        return this.icon_id
    },
    getHtml: function() {
        return ['<table width="100%" height="100%" cellspacing="0" cellpadding="0" border="0">', "<tbody>", "<tr><td>", '<div class="frame">', '<div class="cover-frame"></div>', '<div class="icon-frame"><div class="icon" id="' + this.getIconID() + '"></div></div>', "</div>", '<div class="status-text" id="' + this.getTextID() + '"></div>', "</td></tr>", "</tbody>", "</table>"].join("")
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.VideoDisplay", {
    extend: "Ext.Container",
    constructor: function(b) {
        var a = {
            layout: "border",
            itemId: "video_display",
            cls: "video-display",
            hideMode: "offsets",
            items: [{
                xtype: "container",
                itemId: "video",
                region: "center",
                cls: "video"
            }, new SYNO.SDS.VideoPlayerCommonDSM.SubtitleDisplay({
                itemId: "subtitle",
                region: "south",
                hidden: true
            })]
        };
        this.callParent([Ext.apply(a, b)])
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.SubtitleDisplay", {
    extend: "Ext.Container",
    SUBTITLE_HEIGHT: 80,
    MAX_LINE: 6,
    constructor: function(b) {
        var a = {
            height: this.SUBTITLE_HEIGHT,
            cls: "subtitle",
            prev_text: null
        };
        this.callParent([Ext.apply(a, b)])
    },
    setText: function(f) {
        if (f === this.prev_text) {
            return
        }
        this.prev_text = f;
        var b = this.SUBTITLE_HEIGHT;
        var c = Ext.min([f.split("<br/>").length, this.MAX_LINE]);
        var e = (c > 1) ? (b / c) : b;
        var a = (c > 1) ? (e * 0.9) : (b * 0.45);
        var d = this.getEl();
        d.update(f);
        d.setStyle("padding-top", "10px");
        d.setStyle("padding-bottom", "10px");
        d.setStyle("font-size", a.toFixed(2) + "px");
        d.setStyle("line-height", e.toFixed(2) + "px")
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.Display", {
    extend: "Ext.Container",
    constructor: function(b) {
        var a = {
            layout: "card",
            itemId: "body",
            cls: "syno-vp-body",
            activeItem: 0,
            items: [this.getVideoDisplay(), this.getMetaDisplay()],
            listeners: {
                scope: this,
                afterrender: function() {
                    SYNO.SDS.VideoPlayerCommonDSM.Util.hookDoLayout(this)
                }
            }
        };
        this.callParent([Ext.apply(a, b)])
    },
    setSubtitle: function(a) {
        this.getVideoDisplay().getComponent("subtitle").setText(a)
    },
    showSubtitle: function(a) {
        this.getVideoDisplay().getComponent("subtitle")[(true === a) ? "show" : "hide"]();
        this.doLayout()
    },
    getVideoDisplay: function() {
        if (!Ext.isDefined(this.video_display)) {
            this.video_display = new SYNO.SDS.VideoPlayerCommonDSM.VideoDisplay()
        }
        return this.video_display
    },
    getMetaDisplay: function() {
        if (!Ext.isDefined(this.meta_display)) {
            this.meta_display = new SYNO.SDS.VideoPlayerCommonDSM.MetaDisplay()
        }
        return this.meta_display
    },
    setState: function(a, b) {
        switch (a) {
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.CLEAR:
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.STOPPED:
            this.setStopped();
            break;
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PAUSED:
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PLAYING:
            this.setPlaying();
            break;
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.BUFFERING:
            this.setBuffering();
            break;
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR:
            SYNO.Debug("error: ", b);
            this.setError(b);
            break;
        default:
            break
        }
    },
    setStopped: function() {
        this.layout.setActiveItem(0);
        this.getMetaDisplay().removeClass(["buffer", "error"])
    },
    setPlaying: function() {
        this.layout.setActiveItem(0)
    },
    setBuffering: function() {
        this.layout.setActiveItem(1);
        this.getMetaDisplay().addClass("buffer");
        this.getMetaDisplay().removeClass("error");
        this.getMetaDisplay().setText("")
    },
    setError: function(a) {
        this.layout.setActiveItem(1);
        this.getMetaDisplay().addClass("error");
        this.getMetaDisplay().removeClass("buffer");
        this.getMetaDisplay().setText(a);
        this.getMetaDisplay().setImage("")
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.AppWindow", {
    extend: "SYNO.SDS.AppWindow",
    constructor: function(b) {
        var a = {
            dsmStyle: "v5",
            showHelp: false,
            cls: "syno-vp-appwin",
            minHeight: 480,
            minWidth: 720,
            items: [this.getDisplay()],
            bbar: this.getControlPanel()
        };
        this.callParent([Ext.apply(a, b)])
    },
    getDisplay: function() {
        if (!Ext.isDefined(this.display)) {
            this.display = new SYNO.SDS.VideoPlayerCommonDSM.Display()
        }
        return this.display
    },
    getControlPanel: function() {
        if (!Ext.isDefined(this.control_panel)) {
            this.control_panel = new SYNO.SDS.VideoPlayerCommonDSM.ControlPanel({
                module: this
            })
        }
        return this.control_panel
    },
    setState: function(a, b) {
        this.getDisplay().setState(a, b);
        this.getControlPanel().setState(a, b)
    },
    setTime: function(a, b) {
        if (this.getController().isSubtitleVisible()) {
            var c = this.getController().getSubtitleParser().getText(a);
            this.getDisplay().setSubtitle(c)
        }
        this.getControlPanel().setTime(a, b)
    },
    setSubtitle: function(a) {
        this.getDisplay().showSubtitle(a)
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.Player", {
    extend: "Ext.util.Observable",
    constructor: function(b) {
        var a = Ext.apply({
            subtitle_is_srt: true,
            name: "",
            player: null,
            pluginInit: false
        }, b);
        this.callParent([a]);
        Ext.apply(this, a)
    },
    canPlayType: Ext.emptyFn,
    isAvailable: Ext.emptyFn,
    getName: function() {
        return this.name
    },
    fullscreen: Ext.emptyFn,
    play: Ext.emptyFn,
    pause: Ext.emptyFn,
    resume: Ext.emptyFn,
    stop: Ext.emptyFn,
    seek: Ext.emptyFn,
    getPosition: Ext.emptyFn,
    getDuration: Ext.emptyFn,
    getVolume: Ext.emptyFn,
    setVolume: Ext.emptyFn,
    getMute: Ext.emptyFn,
    setMute: Ext.emptyFn,
    getState: Ext.emptyFn,
    disablePlayerSubtitle: Ext.emptyFn,
    setPlayerSubtitle: Ext.emptyFn,
    setStartPosition: function(a) {
        if (Ext.isNumber(a) && a > 0) {
            this.start_position = a
        }
    },
    notifyClear: function() {
        this.controller.updateState(SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.CLEAR)
    },
    clear: function() {
        if (this.player) {
            this.el.remove();
            this.el = null;
            this.player = null;
            this.pluginInit = false;
            this.notifyClear()
        }
    },
    stateHandler: function(d) {
        var c = this.getState();
        if (c === SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PLAYING) {
            this.disablePlayerSubtitle();
            if (Ext.isNumber(this.start_position)) {
                var a = this.start_position;
                this.start_position = null;
                var b = this.seek.createDelegate(this, [a]);
                b.defer(200)
            }
        }
        this.controller.updateState(c, d)
    },
    durationHandler: function(b) {
        var a = Ext.isNumber(b) ? b : this.getDuration();
        this.controller.updateDuration(a)
    },
    positionHandler: function(a) {
        var b = Ext.isNumber(a) ? a : this.getPosition();
        this.controller.updatePosition(b)
    },
    volumeHandler: function() {
        this.controller.updateMute(this.getMute());
        var a = this.getVolume();
        if (Ext.isNumber(a) && a >= 0 && a <= 100) {
            this.controller.updateVolume(a)
        }
    },
    webkitHandler: function() {
        this.controller.stop();
        this.controller.play();
        this.controller.pause()
    },
    registerEventHandler: Ext.emptyFn
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.FlashPlayer", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.Player",
    constructor: function(b) {
        var a = {
            name: "Flash",
            player_id: "_flash_video_player",
            error: false
        };
        this.callParent([Ext.apply(a, b)])
    },
    canPlayType: function(a) {
        var b = ["mp4", "mov", "m4v", "flv", "f4v"];
        return (-1 !== b.indexOf(a))
    },
    isAvailable: function() {
        return SYNO.SDS.VideoPlayerCommonDSM.Util.detectPlugin("ShockwaveFlash.ShockwaveFlash", "Shockwave", "Flash")
    },
    fullscreen: function() {
        if (this.pluginInit) {
            SYNO.SDS.VideoPlayerCommonDSM.Util.setDomFullscreen(this.controller.container.dom)
        }
    },
    play: function(a) {
        this.error = false;
        this.url = a;
        if (!this.createPlayer()) {
            this.player.load([{
                file: this.url
            }])
        }
    },
    pause: function() {
        if (this.pluginInit) {
            this.player.pause(true)
        }
    },
    resume: function() {
        if (this.pluginInit) {
            this.player.play(true)
        }
    },
    stop: function() {
        if (this.pluginInit) {
            this.player.stop()
        }
    },
    seek: function(a) {
        if (this.pluginInit && a >= 0 && a <= this.player.getDuration()) {
            this.player.seek(a)
        }
    },
    getPosition: function() {
        if (!this.pluginInit) {
            return -1
        }
        return this.player.getPosition()
    },
    getDuration: function() {
        if (!this.pluginInit) {
            return -1
        }
        return this.player.getDuration()
    },
    getVolume: function() {
        if (!this.pluginInit) {
            return -1
        }
        return this.player.getVolume()
    },
    setVolume: function(a) {
        if (this.pluginInit) {
            this.player.setVolume(a)
        }
    },
    getMute: function() {
        if (!this.pluginInit) {
            return false
        }
        return this.player.getMute()
    },
    setMute: function(a) {
        if (this.pluginInit) {
            this.player.setMute(a)
        }
    },
    StateMap: {
        IDLE: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.STOPPED,
        BUFFERING: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.BUFFERING,
        PLAYING: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PLAYING,
        PAUSED: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PAUSED
    },
    getPlayerState: function() {
        if (!this.pluginInit) {
            return "IDLE"
        }
        return this.player.getState()
    },
    getState: function() {
        if (!this.pluginInit) {
            return SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.NO_MEDIA
        }
        if (this.error) {
            return SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR
        }
        var a = this.StateMap[this.getPlayerState()] || SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR;
        return a
    },
    clear: function() {
        this.delayDestroy.defer(1, this, arguments)
    },
    delayDestroy: function() {
        if (this.player) {
            this.player.remove();
            this.el.remove();
            this.el = null;
            this.el = Ext.get(this.player_id);
            this.el.remove();
            this.el = null;
            this.player = null;
            this.pluginInit = false;
            this.notifyClear()
        }
    },
    onReady: function() {
        this.pluginInit = true;
        this.player = jwplayer(this.player_id);
        this.registerEventHandler();
        this.setVolume(this.controller.volume)
    },
    onError: function() {
        this.error = true;
        this.stateHandler()
    },
    onPlaylist: function() {
        this.player.playlistItem(0)
    },
    onTime: function(a) {
        if (!Ext.isObject(a)) {
            return
        }
        if (Ext.isNumber(a.duration)) {
            this.durationHandler(a.duration)
        }
        if (Ext.isNumber(a.position)) {
            this.positionHandler(a.position)
        }
    },
    createPlayer: function() {
        if (this.player) {
            return false
        }
        if (!Ext.isDefined(window.jwplayer)) {
            this.loadJWScript();
            return true
        }
        this.el = Ext.get(this.player_id) || this.controller.video.createChild({
            tag: "div",
            id: this.player_id,
            style: {
                width: "100%",
                height: "100%"
            }
        });
        var b = String.format("{0}/skin/empty-controlbar.xml", this.controller.jsBaseURL);
        var a = String.format("{0}/jwplayer.flash.swf?v=6.8.4616-2", this.controller.jsBaseURL);
        this.player = jwplayer(this.player_id).setup({
            fallback: false,
            flashplayer: a,
            file: this.url,
            controls: false,
            autostart: false,
            skin: b,
            height: "100%",
            width: "100%",
            stretching: "uniform",
            primary: "flash",
            analytics: {
                enabled: false
            }
        });
        this.registerSetupHandler();
        return true
    },
    registerSetupHandler: function() {
        jwplayer(this.player_id).onReady(this.onReady.createDelegate(this));
        jwplayer(this.player_id).onSetupError(this.onError.createDelegate(this))
    },
    registerEventHandler: function() {
        this.player.onPlaylist(this.onPlaylist.createDelegate(this));
        this.player.onPlaylistComplete(this.stateHandler.createDelegate(this));
        this.player.onPlay(this.stateHandler.createDelegate(this));
        this.player.onPause(this.stateHandler.createDelegate(this));
        this.player.onBuffer(this.stateHandler.createDelegate(this));
        this.player.onIdle(this.stateHandler.createDelegate(this));
        this.player.onComplete(this.stateHandler.createDelegate(this));
        this.player.onError(this.onError.createDelegate(this));
        this.player.onTime(this.onTime.createDelegate(this));
        this.player.onMute(this.volumeHandler.createDelegate(this));
        this.player.onVolume(this.volumeHandler.createDelegate(this))
    },
    loadJWScript: function() {
        var a = document.getElementsByTagName("head")[0];
        var b = document.createElement("script");
        var e = String.format("{0}/jwplayer.js?v=6.8.4616", this.controller.jsBaseURL);
        var d = this.setJWPlayerKey.createSequence(this.createPlayer, this);
        b.type = "text/javascript";
        if (Ext.isIE) {
            b.onready = d;
            b.onreadystatechange = function c() {
                if ("complete" !== this.readyState && "loaded" !== this.readyState) {
                    return
                }
                this.onready()
            }
        } else {
            b.onload = d
        }
        b.src = e;
        a.appendChild(b)
    },
    setJWPlayerKey: function() {
        if (jwplayer.key) {
            return
        }
        jwplayer.key = "ADrNpyYVQ13xVOfDuZpCXl4Bioq40D0Omx8S/CIM46w="
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.HTML5Player", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.Player",
    constructor: function(b) {
        var a = {
            name: "HTML5",
            player_id: "_html5_video_player",
            stopped: false
        };
        this.callParent([Ext.apply(a, b)])
    },
    canPlayType: function(b) {
        var a = document.createElement("video")
          , c = SYNO.SDS.VideoPlayerCommonDSM.Util.MimeType[b] || ("video/" + b);
        if (!a || !Ext.isFunction(a.canPlayType)) {
            return false
        }
        return a.canPlayType(c)
    },
    isAvailable: function() {
        var a = document.createElement("video");
        if (!a || !Ext.isFunction(a.canPlayType)) {
            return false
        }
        return true
    },
    fullscreen: function() {
        if (this.pluginInit) {
            SYNO.SDS.VideoPlayerCommonDSM.Util.setDomFullscreen(this.controller.container.dom)
        }
    },
    play: function(a) {
        this.stopped = false;
        this.createPlayer();
        this.player.src = a;
        this.player.play();
        this.setVolume(this.controller.volume)
    },
    pause: function() {
        if (this.pluginInit) {
            this.player.pause()
        }
    },
    resume: function() {
        if (this.pluginInit) {
            this.player.play()
        }
    },
    stop: function() {
        if (this.pluginInit) {
            this.stopped = true;
            this.player.pause();
            this.stateHandler()
        }
    },
    seek: function(a) {
        if (this.pluginInit && a >= 0 && a <= this.player.duration) {
            this.player.currentTime = a
        }
    },
    getPosition: function() {
        if (!this.pluginInit) {
            return -1
        }
        return this.player.currentTime
    },
    getDuration: function() {
        if (!this.pluginInit) {
            return -1
        }
        return this.player.duration
    },
    getVolume: function() {
        if (!this.pluginInit) {
            return -1
        }
        return this.player.volume * 100
    },
    setVolume: function(a) {
        if (this.pluginInit) {
            this.player.volume = a / 100
        }
    },
    getMute: function() {
        var a = false;
        if (this.pluginInit) {
            a = this.player.muted
        }
        return a
    },
    setMute: function(a) {
        if (this.pluginInit) {
            this.player.muted = a
        }
    },
    getState: function() {
        if (!this.pluginInit) {
            return SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.NO_MEDIA
        }
        if (this.player.error) {
            return SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR
        }
        if (this.player.ended || this.player.HAVE_NOTHING === this.player.readyState || this.stopped) {
            return SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.STOPPED
        }
        if (this.player.paused) {
            return SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PAUSED
        }
        if (this.player.HAVE_CURRENT_DATA >= this.player.readyState) {
            return SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.BUFFERING
        }
        return SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PLAYING
    },
    setVisible: function(a) {
        if (Ext.isSafari && this.el) {
            this.el.setVisible(a)
        }
    },
    createPlayer: function() {
        if (this.player) {
            return false
        }
        this.el = Ext.get(this.player_id) || this.controller.video.createChild({
            tag: "video",
            tabindex: -1,
            id: this.player_id,
            style: {
                width: "100%",
                height: "100%"
            }
        });
        this.player = this.el.dom;
        this.registerEventHandler();
        this.pluginInit = true;
        this.el.enableDisplayMode();
        this.el.show();
        this.player.pause();
        return true
    },
    registerEventHandler: function() {
        var a = SYNO.SDS.VideoPlayerCommonDSM.Util.addDomListener(false);
        a(this.player, "play", this.stateHandler, this);
        a(this.player, "playing", this.stateHandler, this);
        a(this.player, "waiting", this.stateHandler, this);
        a(this.player, "pause", this.stateHandler, this);
        a(this.player, "ended", this.stateHandler, this);
        a(this.player, "error", this.stateHandler, this);
        a(this.player, "durationchange", this.durationHandler, this);
        a(this.player, "timeupdate", this.positionHandler, this);
        a(this.player, "volumechange", this.volumeHandler, this);
        a(this.player, "webkitendfullscreen", this.webkitHandler, this)
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.NullPlayer", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.Player",
    constructor: function(b) {
        var a = {
            name: "Null",
            error: false
        };
        this.callParent([Ext.apply(a, b)])
    },
    canPlayType: function() {
        return false
    },
    isAvailable: function() {
        return true
    },
    play: function() {
        this.error = true;
        var a = SYNO.SDS.VideoPlayerCommonDSM.Util.isMobile();
        var b = _T("video_player", "error_play");
        if (!a && !Ext.isMac) {
            b = _T("audio_player", "err_format_not_support")
        }
        this.stateHandler(b)
    },
    getState: function() {
        return this.error ? SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR : SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.STOPPED
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.SubtitleParser", {
    extend: "Ext.util.Observable",
    subtitles: null,
    destroy: function() {
        delete this.subtitles
    },
    parseSeconds: function(d) {
        if (!d) {
            return
        }
        var a = 0;
        var c = d.split(":");
        if (c.length > 3) {
            return
        }
        for (var b = 0; b < c.length; ++b) {
            a = a * 60 + parseFloat(c[b].replace(",", "."))
        }
        return a
    },
    parseSrt: function(f) {
        var d = f.replace(/\r\n|\r/g, "\n").trim();
        var e = d.split("\n\n");
        this.clear();
        for (var b = 0; b < e.length; ++b) {
            var c = e[b].split("\n");
            if (c.length < 3) {
                continue
            }
            c.shift();
            var a = c.shift().split(" --> ");
            var h = this.parseSeconds(a[0]);
            var g = this.parseSeconds(a[1]);
            if (!Ext.isNumber(h) || !Ext.isNumber(g)) {
                continue
            }
            this.subtitles.push({
                from: h,
                to: g,
                text: c.join("<br/>")
            })
        }
        this.subtitles.sort(function(j, i) {
            return (j.from < i.from ? -1 : 1)
        })
    },
    clear: function() {
        this.subtitles = []
    },
    hasSubtitle: function() {
        return Ext.isArray(this.subtitles) && this.subtitles.length > 0
    },
    getText: function(c) {
        var e = this.subtitles;
        var d = [];
        if (!e) {
            return ""
        }
        for (var a = 0; a < e.length; ++a) {
            var b = e[a];
            if (c < b.from) {
                break
            }
            if (b.from <= c && c <= b.to) {
                d.push(b.text)
            }
        }
        return d.join("<br/>")
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.VLCPlayer", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.Player",
    constructor: function(b) {
        var a = {
            name: "VLC",
            player_id: "_vlc_video_player",
            error: false
        };
        this.callParent([Ext.apply(a, b)])
    },
    canPlayType: function(a) {
        return ("ogg" !== a) && ("ogv" !== a)
    },
    isAvailable: function() {
        return SYNO.SDS.VideoPlayerCommonDSM.Util.isVLCSupported()
    },
    fullscreen: function() {
        if (this.pluginInit) {
            SYNO.SDS.VideoPlayerCommonDSM.Util.setDomFullscreen(this.controller.container.dom)
        }
    },
    play: function(a) {
        this.url = a;
        if (!this.createPlayer()) {
            this.onVLCReady()
        }
    },
    pause: function() {
        if (this.pluginInit) {
            this.player.playlist.pause()
        }
    },
    resume: function() {
        if (this.pluginInit) {
            this.player.playlist.play()
        }
    },
    stop: function() {
        var a = this.getState();
        if (this.pluginInit) {
            if (a === SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PLAYING || a === SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PAUSED) {
                this.player.playlist.stop()
            } else {
                this.stop.defer(100, this, arguments)
            }
        }
    },
    seek: function(a) {
        var b = a * 1000;
        if (this.pluginInit && b >= 0 && b <= this.player.input.length) {
            this.player.input.time = b
        }
    },
    getPosition: function() {
        if (!this.pluginInit) {
            return -1
        }
        return this.player.input.time / 1000
    },
    getDuration: function() {
        if (!this.pluginInit) {
            return -1
        }
        return this.player.input.length / 1000
    },
    getVolume: function() {
        if (!this.pluginInit) {
            return -1
        }
        return this.player.audio.volume
    },
    setVolume: function(a) {
        if (this.pluginInit) {
            this.player.audio.volume = a;
            this.volumeHandler()
        }
    },
    getMute: function() {
        var a = false;
        if (this.pluginInit) {
            a = this.player.audio.mute
        }
        return a
    },
    setMute: function(a) {
        if (this.pluginInit) {
            this.player.audio.mute = a;
            this.volumeHandler()
        }
    },
    StateMap: {
        0: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.NO_MEDIA,
        1: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.BUFFERING,
        2: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.BUFFERING,
        3: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PLAYING,
        4: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PAUSED,
        5: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.STOPPED,
        6: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.STOPPED,
        7: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR
    },
    getPlayerState: function() {
        var a = 1;
        try {
            a = this.player.input.state
        } catch (b) {}
        if (a === 7) {
            this.error = true
        }
        return a
    },
    getState: function() {
        if (!this.pluginInit) {
            return SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.NO_MEDIA
        }
        if (this.error) {
            return SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR
        }
        var a = this.StateMap[this.getPlayerState()] || SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR;
        return a
    },
    disablePlayerSubtitle: function() {
        if (this.pluginInit && this.subtitle_is_srt === true) {
            var c = this.player.VersionInfo.match(/\d+/g);
            var a = parseInt(c[0], 10);
            var b = parseInt(c[1], 10);
            if (a < 2 || (a == 2 && b < 2)) {
                this.player.subtitle.track = -1
            } else {
                if (this.player.subtitle.count > 0) {
                    this.player.subtitle.track = 0
                }
            }
        }
    },
    setPlayerSubtitle: function(a) {
        if (this.pluginInit && this.subtitle_is_srt !== true) {
            this.player.subtitle.track = a
        }
    },
    createPlayer: function() {
        if (this.player) {
            return false
        }
        this.el = SYNO.SDS.VideoPlayerCommonDSM.Util.createVLCElement(this.controller.video, this.player_id);
        this.player = this.el.dom;
        this.registerEventHandler();
        this.el.enableDisplayMode();
        this.el.show();
        this.pluginInit = true;
        this.onVLCReady();
        return true
    },
    onVLCReady: function() {
        if (!this.player) {
            return
        }
        if (!this.player.VersionInfo) {
            this.onVLCReady.defer(100, this);
            return
        }
        this.fitPlayer.defer(100, this);
        this.fitPlayer.defer(500, this);
        if (Ext.isString(this.url)) {
            if (this.player.playlist.items && this.player.playlist.items.count > 0) {
                this.player.playlist.items.clear()
            }
            this.playlistItemId = this.player.playlist.add(this.url);
            this.player.playlist.playItem(this.playlistItemId)
        }
        if (Ext.isIE) {
            this.adjustPlayerWidthHack()
        }
        return
    },
    fitPlayer: function() {
        if (this.el) {
            this.el.setSize("100%", "100%")
        }
    },
    adjustPlayerWidthHack: function() {
        if (this.el) {
            this.el.setWidth(this.el.getWidth() + 1);
            this.el.setWidth(this.el.getWidth() - 1)
        }
    },
    durationHandler: function(b) {
        var a = Ext.isNumber(b) ? (b / 1000) : null;
        this.callParent([a])
    },
    positionHandler: function(a) {
        this.callParent([a / 1000])
    },
    stateHandler: function() {
        this.setVolume.defer(1000, this, [this.controller.volume]);
        this.durationHandler();
        this.callParent(arguments)
    },
    registerEventHandler: function() {
        var a = SYNO.SDS.VideoPlayerCommonDSM.Util.addDomListener(true);
        a(this.player, "MediaPlayerOpening", this.stateHandler, this);
        a(this.player, "MediaPlayerPlaying", this.stateHandler, this);
        a(this.player, "MediaPlayerPaused", this.stateHandler, this);
        a(this.player, "MediaPlayerStopped", this.stateHandler, this);
        a(this.player, "MediaPlayerEndReached", this.stateHandler, this);
        a(this.player, "MediaPlayerEncounteredError", this.stateHandler, this);
        a(this.player, "MediaPlayerTimeChanged", this.positionHandler, this);
        a(this.player, "MediaPlayerLengthChanged", this.durationHandler, this)
    }
});
Ext.define("SYNO.SDS.VideoPlayerCommonDSM.Controller", {
    extend: "Ext.util.Observable",
    constructor: function(b) {
        this.addEvents({
            statechange: true,
            mutechange: true,
            volumechange: true,
            timechange: true,
            subtitlechange: true
        });
        var a = Ext.apply({
            subtitle_visible: false,
            mute: false,
            state: SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.STOPPED,
            volume: 50,
            position: 0,
            duration: 0,
            initPlaying: false
        }, b);
        Ext.apply(this, a);
        this.callParent([a]);
        this.initPlayers()
    },
    onStateChange: function(a, b) {
        this.fireEvent("statechange", a, b)
    },
    onMuteChange: function(a) {
        this.fireEvent("mutechange", a)
    },
    onVolumeChange: function(a) {
        this.fireEvent("volumechange", a)
    },
    onTimeChange: function(a, b) {
        this.fireEvent("timechange", a, b)
    },
    onSubtitleChange: function(b, a) {
        this.fireEvent("subtitlechange", b, a)
    },
    initPlayers: function() {
        var a;
        a = [new SYNO.SDS.VideoPlayerCommonDSM.NullPlayer({
            controller: this
        }), this.html5Player(), this.flashPlayer(), new SYNO.SDS.VideoPlayerCommonDSM.VLCPlayer({
            controller: this
        })];
        this.players = [];
        Ext.each(a, function(b) {
            if (b.isAvailable()) {
                this.players.push(b)
            }
        }, this)
    },
    flashPlayer: function() {
        return new SYNO.SDS.VideoPlayerCommonDSM.FlashPlayer({
            controller: this
        })
    },
    html5Player: function() {
        return new SYNO.SDS.VideoPlayerCommonDSM.HTML5Player({
            controller: this
        })
    },
    updatePlayer: function(d) {
        var a = d.filename;
        var b;
        if (Ext.isString(a)) {
            var c = SYNO.SDS.VideoPlayerCommonDSM.Util.getFileExt(a);
            Ext.each(this.players, function(e) {
                if (e.canPlayType(c)) {
                    b = e;
                    return false
                }
            }, this)
        }
        this.player = b || this.players[0]
    },
    selectPlayer: function(a) {
        var b = null;
        Ext.each(this.players, function(c) {
            if (a === c.getName()) {
                b = c;
                return false
            }
        });
        if (b === null) {
            b = this.players[0]
        }
        this.player = b;
        return b
    },
    getPlayer: function() {
        if (Ext.isObject(this.player)) {
            return this.player
        }
        return this.players[0]
    },
    play: function(b) {
        switch (this.state) {
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR:
            var a = this.play.createDelegate(this, arguments);
            this.initPlaying = false;
            this.updateState(SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.NO_MEDIA);
            this.stop(a);
            break;
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.NO_MEDIA:
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.CLEAR:
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.STOPPED:
            this.initPlaying = true;
            this.url = b || this.url;
            this.playCurrentVideo();
            break;
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PLAYING:
            this.getPlayer().pause();
            break;
        case SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PAUSED:
            this.getPlayer().resume();
            break;
        default:
            break
        }
    },
    playCurrentVideo: function() {
        this.getPlayer().play(this.url)
    },
    stop: function(a) {
        if (!this.getPlayer().pluginInit) {
            if (Ext.isFunction(a)) {
                a()
            }
            return
        }
        this.clearCallback = a;
        this.getPlayer().stop()
    },
    updateState: function(a, b) {
        this.state = a;
        if (!this.initPlaying && a === SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.STOPPED) {
            this.getPlayer().clear();
            this.updateDuration(0);
            this.updatePosition(0)
        }
        if (this.initPlaying && (a === SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.PLAYING || a === SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.BUFFERING)) {
            this.initPlaying = false
        }
        if (a === SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.ERROR) {
            b = Ext.isString(b) ? b : _T("video_player", "error_play")
        }
        this.onStateChange(this.state, b);
        if (a === SYNO.SDS.VideoPlayerCommonDSM.Util.STATE.CLEAR && Ext.isFunction(this.clearCallback)) {
            var c = this.clearCallback;
            this.clearCallback = null;
            c()
        }
    },
    toggleMute: function() {
        this.getPlayer().setMute(!this.mute)
    },
    updateMute: function(a) {
        this.mute = a;
        this.onMuteChange(this.mute)
    },
    setVolume: function(a) {
        this.getPlayer().setVolume(a)
    },
    updateVolume: function(a) {
        this.volume = a;
        this.onVolumeChange(this.volume)
    },
    updateDuration: function(a) {
        this.duration = a;
        this.onTimeChange(this.position, this.duration)
    },
    seek: function(a) {
        this.getPlayer().seek(a)
    },
    updatePosition: function(a) {
        this.position = a;
        this.onTimeChange(this.position, this.duration)
    },
    fullscreen: function() {
        this.getPlayer().fullscreen()
    },
    isSubtitleVisible: function() {
        return this.subtitle_visible
    },
    setSubtitleEnabled: function(b, a) {
        this.subtitle_visible = b;
        this.onSubtitleChange(b, a)
    },
    getSubtitleParser: function() {
        if (!Ext.isDefined(this.subtitle_parser)) {
            this.subtitle_parser = new SYNO.SDS.VideoPlayerCommonDSM.SubtitleParser()
        }
        return this.subtitle_parser
    }
});
Ext.define("SYNO.SDS.VideoPlayer2.Application", {
    extend: "SYNO.SDS.AppInstance",
    appWindowName: "SYNO.SDS.VideoPlayer2.AppWindow"
});
Ext.define("SYNO.SDS.VideoPlayer2.AppWindow", {
    extend: "SYNO.SDS.VideoPlayerCommonDSM.AppWindow",
    constructor: function(a) {
        this.callParent([a]);
        this.addClass("video-player")
    },
    getController: function() {
        if (!Ext.isDefined(this.controller)) {
            var a = this.getControlPanel();
            this.controller = new SYNO.SDS.VideoPlayerCommonDSM.Controller({
                container: this.getDisplay().getEl(),
                video: this.getDisplay().getComponent("video_display").getComponent("video").getEl(),
                jsBaseURL: this.jsConfig.jsBaseURL,
                listeners: {
                    statechange: this.setState.createDelegate(this),
                    mutechange: a.setMute.createDelegate(a),
                    volumechange: a.setVolume.createDelegate(a),
                    timechange: this.setTime.createDelegate(this),
                    subtitlechange: this.setSubtitle.createDelegate(this)
                }
            })
        }
        return this.controller
    },
    requestSubtitle: function(b, a) {
        this.sendWebAPI({
            api: a ? "SYNO.VideoPlayer.SynologyDrive.Subtitle" : "SYNO.VideoPlayer.Subtitle",
            method: "get",
            version: 1,
            responseFormat: "text",
            params: {
                path: b
            },
            scope: this,
            callback: function(h, e, g, d) {
                if (this.isDestroyed || !Ext.isString(e)) {
                    return
                }
                var c = this.getController();
                c.getSubtitleParser().parseSrt(e);
                if (!c.getSubtitleParser().hasSubtitle()) {
                    return
                }
                var f = this.getControlPanel().getControlBar().getSubtitleButton().menu;
                f.addOneItem(SYNO.SDS.VideoPlayerCommonDSM.SubtitleMenu.ID_EXTERNAL, _T("video_player", "external_subtitle"), c.setSubtitleEnabled.createDelegate(c, [true]));
                f.items.itemAt(1).handler.call(f)
            }
        })
    },
    onOpen: function(e) {
        var b, f, d, c;
        this.callParent(arguments);
        if (!Ext.isObject(e)) {
            return
        }
        if (Ext.isString(e.file_id) && Ext.isString(e.path)) {
            f = e.path;
            d = f.substr(1 + f.lastIndexOf("/"));
            b = this.getController();
            c = SYNO.SDS.VideoPlayerCommonDSM.Util.getDownloadLink(e.file_id);
            b.updatePlayer({
                filename: d
            });
            this.controller.play.defer(1000, b, [c])
        } else {
            if (Ext.isString(e.url) && Ext.isString(e.filename)) {
                b = this.getController();
                b.updatePlayer({
                    filename: e.filename
                });
                this.controller.play.defer(1000, b, [e.url])
            }
        }
        if (b && e.path) {
            var a = Ext.isString(e.is_drive) && e.is_drive === "true";
            this.requestSubtitle(e.path, a)
        }
    }
});
