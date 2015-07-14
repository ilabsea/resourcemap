window.onLayers ?= (callback) -> $(-> callback() if $('#layers-main').length > 0 || $('#adjust-layers').length > 0)
