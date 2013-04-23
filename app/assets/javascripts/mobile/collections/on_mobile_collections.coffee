window.onMobileCollections ?= (callback) -> $(-> callback() if $('#mobile-collections-main').length > 0)
