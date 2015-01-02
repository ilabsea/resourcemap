$(document).on "input", "#create_user, #edit_user #user_password", ->
	email = $('#user_email').val()
	password = $('#user_password').val()
	validatePassword = PasswordStrength.test(email, password)

	if password.length > 0
		if (validatePassword.status == 'weak')
			$('#validateMeter').removeClass('strong-bar').addClass('weak-bar')
		else if (validatePassword.status == 'good' || 'strong')
			$('#validateMeter').removeClass('weak-bar').addClass('strong-bar')

		if password.length > 8
			length = 8
		else
			length = password.length

		$('#validateMeter').width(length*30)		
		$('#validateMessage').html(validatePassword.status)
	else
		$('#validateMeter').width(0)
		$('#validateMessage').html('')

$(document).on "blur", "#user_password_confirmation", ->
	password = $('#user_password').val()
	password_confirmation = $('#user_password_confirmation').val()

	if password != password_confirmation
		$('#confirmMessage').html('Password does not match confirmation')
	else
		$('#confirmMessage').html('')


	


