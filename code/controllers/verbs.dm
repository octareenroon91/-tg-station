//TODO: rewrite and standardise all controller datums to the datum/controller type
//TODO: allow all controllers to be deleted for clean restarts (see WIP master controller stuff) - MC done - lighting done



/client/proc/debug_controller(controller in list("Master","Failsafe","Ticker","Jobs","Radio","Configuration", "Cameras"))
	set category = "Debug"
	set name = "Debug Controller"
	set desc = "Debug the various periodic loop controllers for the game (be careful!)"

	if(!holder)	return
	switch(controller)
		if("Master")
			debug_variables(Master)

		if("Failsafe")
			debug_variables(Failsafe)

		if("Ticker")
			debug_variables(ticker)

		if("Jobs")
			debug_variables(SSjob)

		if("Radio")
			debug_variables(radio_controller)

		if("Configuration")
			debug_variables(config)

		if("Cameras")
			debug_variables(cameranet)

	message_admins("Admin [key_name_admin(usr)] is debugging the [controller] controller.")
	return
