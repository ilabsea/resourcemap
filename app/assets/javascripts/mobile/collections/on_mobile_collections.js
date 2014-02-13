var _ref;

if ((_ref = window.onMobileCollections) == null) {
  window.onMobileCollections = function(callback) {
    return $(function() {
      if ($('#mobile-collections-main').length > 0) {
        return callback();
      }
    });
  };
}

