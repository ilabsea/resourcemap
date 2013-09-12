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
    @secretCode = null
    @phoneExiste = ko.observable false
    @codeVerificationMsg = ko.observable('Click "Text Me!". You will receive an SMS pin code for verification.')
    @emailError = ko.computed =>
      if @hasEmail()
        atPos = @email().indexOf('@')
        dotPos = @email().indexOf('.')
        if atPos<1 || dotPos < atPos + 2 || dotPos + 2 >= @email().length
          'Email is invalid'
        else
          null
    @phoneError = ko.computed => 
      if @hasPhone()
        if @phoneExiste()
          "Phone number is taken" 
        else 
          null
      else
        "Phone number is required"

    @hasError = ko.computed =>
      return true if @phoneError() || @emailError() || @smsCodeExiste()

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

  smsCodeExiste: () => @smsCode() != @secretCode

  sentCodeMsg: () =>
    _self = this;
    if (@phoneNumber())
      $.post "/collections/#{ @collectionId() }/send_new_member_sms.json", phone_number: @phoneNumber(), (data) ->
        if data.errors
          _self.codeVerificationMsg(data.errors)
        else
          _self.secretCode = data.secret_code
          _self.codeVerificationMsg('The pin code has been sent to the phone number above. Please enter the pin code in the textbox for verification.')

  showRegisterMembership: () =>
    @showRegisterNewMember(true)
    @email($('#member_email').val());

  hideRegisterMembership: () =>
    @showRegisterNewMember(false)
    @smsCode("")
    @secretCode = null
    @phoneNumber("")
    @email("")
    @codeVerificationMsg('Click "Text Me!". You will receive an SMS pin code for verification.')

  runSomething: () =>
    alert("test")

  hasEmail: => $.trim(@email()).length > 0

  hasPhone: => $.trim(@phoneNumber()).length > 0

  createMembership: () ->
    _self = this;
    if ((@smsCode() == @secretCode) && @hasPhone())
      $.post "/collections/#{ @collectionId() }/memberships.json", user: email: @email(), phone_number: @phoneNumber(), (data) ->
          if data.status == 'ok'
            new_member = new Membership(window.model, { user_id: data.user_id, user_display_name: data.user_display_name, layers: data.layers })
            window.model.memberships.push new_member
            _self.hideRegisterMembership()
            $('#member_email').val("")
          else if data.status == 'phone_existed'
            _self.phoneExiste true




