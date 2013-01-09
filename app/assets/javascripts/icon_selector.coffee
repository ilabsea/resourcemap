@initIconSelector = (all_icons) ->
  selected_icon = $('#selected_icon')

  if selected_icon.val() == ""
    selected_icon.val all_icons[0]

  $(".icon_selector_button.#{selected_icon.val()}").addClass 'pushed'

  $(".icon_selector_button").click ->
    if @.id != selected_icon.val()
      $("##{selected_icon.val()}").removeClass 'pushed'
      selected_icon.val(@.id)
      $("##{selected_icon.val()}").addClass 'pushed'


