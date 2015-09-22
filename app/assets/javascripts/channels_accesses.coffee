#= require channels_accesses/on_channels_accesses
#= require_tree ./channels_accesses/.

onChannelsAccesses -> if $('#channels_accesses-main').length > 0
  window.model = new MainViewModel
  ko.applyBindings(window.model)
  window.model.initAutocomplete()

  
  $('.hidden-until-loaded').show()