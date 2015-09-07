onThresholds ->

  # Used when selecting a hierarchy field value
  class @FieldHierarchyItem 
    constructor: (field, data, parent = null, level = 0) ->
      @field = field
      @parent = parent

      @id = data.id
      @name = data.name
      @level = level
      @expanded = ko.observable(false)
      @value = ko.observable()
      @conditionValue = ko.computed =>
                          conditions = model.currentThreshold().conditions() if model.currentThreshold()
                          if conditions 
                            for condition in conditions
                              if condition.field() && (parseInt(condition.field().esCode()) == parseInt(@field.esCode()))
                                @value(condition.value())
      @selected = ko.computed => 
                    parseInt(@value()) == parseInt(@id)

      @fieldHierarchyItems =  if data.sub?
                                $.map data.sub, (x) => new FieldHierarchyItem(@field, x, @, level + 1)
                              else
                                []
      @selected.subscribe (newValue) =>
        @toggleParentsExpand() if newValue
      @hierarchyIds = ko.observable([@id])
      $.map @fieldHierarchyItems, (item) => 
        @loadItemToHierarchyIds(item)

    loadItemToHierarchyIds: (item) =>
      @hierarchyIds().push(item.id)
      $.map item.fieldHierarchyItems, (item) => @loadItemToHierarchyIds(item)

    toggleExpand: =>
      @expanded(!@expanded())

    toggleParentsExpand: =>
      @expanded(true) if @value() != @id
      @parent.toggleParentsExpand() if @parent

    select: => 
      conditions = model.currentThreshold().conditions()
      for condition in conditions
        if condition.field().kind() == 'hierarchy'
          if parseInt(condition.field().esCode()) == parseInt(@field.esCode())
            condition.value(@id)
            @value(@id)








