class @MembershipsViewModel
  initialize: (admin, memberships, layers, collectionId) ->
    _self = @
    @collectionId = ko.observable(collectionId)

    @selectedLayer = ko.observable()
    @layers = ko.observableArray $.map(layers, (x) -> new Layer(x))

    @memberships = ko.observableArray $.map(memberships, (x) -> new Membership(_self, x))
    @admin = ko.observable admin

    @showRegisterNewMember = ko.observable(false)
    @email = ko.observable()
    @phoneNumber = ko.observable()
    @smsCode = ko.observable()

    @groupBy = ko.observable("Users")
    @groupByOptions = ["Users", "Layers"]


  destroyMembership: (membership) =>
    if confirm("Are you sure you want to remove #{membership.userDisplayName()} from the collection?")
      $.post "/collections/#{collectionId}/memberships/#{membership.userId()}.json", {_method: 'delete'}, =>
        @memberships.remove membership

  phoneNumberExist: () =>
    if (@phoneNumber())
      false
    else
      true

  smsCodeExiste: () =>
    if (@smsCode())
      false
    else
      true

  sentCodeMsg: () =>
    alert("code msg is sent");

  showRegisterMembership: () =>
    @showRegisterNewMember(true)
    @email($('#member_email').val());

  hideRegisterMembership: () =>
    @showRegisterNewMember(false)

  createMembership: () ->
    _self = this;
    if $.trim(@email()).length > 0
      
      $.post "/collections/#{ @collectionId() }/memberships.json", user: email: @email(), phone_number: @phoneNumber(), (data) ->
          if data.status == 'ok'
            new_member = new Membership(window.model, { user_id: data.user_id, user_display_name: data.user_display_name, layers: data.layers })
            window.model.memberships.push new_member
            _self.showRegisterNewMember(false)
            _self.email("")
            _self.phoneNumber("")
            $('#member_email').val("")




