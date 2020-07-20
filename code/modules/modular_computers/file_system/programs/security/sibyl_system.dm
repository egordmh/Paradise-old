GLOBAL_LIST_EMPTY(guns_registry)
GLOBAL_VAR_INIT(sibsys_automode, TRUE)

#define SIBSYS_REGISTRY	0	// Guns registry table
#define SIBSYS_DETAILS	1	// Show log for gun

/datum/computer_file/program/sibyl_system
	filename = "sibyl_system"
	filedesc = "Sibyl System"
	program_icon_state = "generic"
	extended_desc = "Sibyl System - это проприетарная система одноимённой правоохранительной организации, работающей в сотрудничестве с корпорацией Nanotrasen для борьбы с преступностью."
	required_access = ACCESS_ARMORY
	requires_ntnet = TRUE
	size = 8
	usage_flags = PROGRAM_ALL
	network_destination = "station long-range communication array"
	unsendable = TRUE
	undeletable = TRUE
	var/screen = SIBSYS_REGISTRY
	var/sortBy = "name"
	var/cachedRegistry = null
	var/obj/item/sibyl_system_mod/M = null

/datum/computer_file/program/sibyl_system/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = FALSE)
	if(!(..()))
		return FALSE

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		var/datum/asset/assets = get_asset_datum(/datum/asset/simple/headers)
		assets.send(user)
		ui = new(user, src, ui_key, "sibyl_system.tmpl", "Sibyl System", 800, 700)
		ui.set_layout_key("program")
		ui.open()

/datum/computer_file/program/sibyl_system/ui_data(mob/user)
	var/list/data = get_header_data()

	var/obj/item/computer_hardware/printer/printer
	if(computer)
		printer = computer.all_components[MC_PRINT]

	data["screen"] = screen
	data["printer"] = printer ? TRUE : FALSE
	data["security_level"] = uppertext(get_security_level_ru())
	data["automode"] = GLOB.sibsys_automode
	if(screen == SIBSYS_REGISTRY)
		data["guns_registry"] = list()
		if(!isnull(GLOB.guns_registry))
			for(var/obj/item/sibyl_system_mod/mod in GLOB.guns_registry)
				var/background = ""
				switch(mod.lock)
					if(TRUE)
						background = "background-color:#216489"
					if(FALSE)
						background = "background-color:#007f47"
				var/limit_str = ""
				var/mode = ""
				if(!isnull(mod.weapon))
					limit_str = mod.get_available_text("<BR>")
					mode = mod.weapon.ammo_type[mod.weapon.select].select_name
				data["guns_registry"] += list(list(
											"ref" = mod.UID(),
											"name" = mod.user ? mod.user.registered_name : "Неавторизовано",
											"weapon" = mod.weapon ? mod.weapon.name : "Не установлен",
											"mode" = mode,
											"limit" = limit_str,
											"lock" = mod.lock ? "Заблокировано" : "Разблокировано",
											"force_lock" = mod.force_lock,
											"background" = background
										))
			if(data["guns_registry"].len > 0)
				data["guns_registry"] = sortByKey(data["guns_registry"], sortBy)
				cachedRegistry = data["guns_registry"]
	if(screen == SIBSYS_DETAILS)
		data["log"] = M.log

	return data

/datum/computer_file/program/sibyl_system/Topic(href, list/href_list)
	if(..())
		return TRUE

	switch(href_list["action"])
		if("PRG_screen")
			screen = text2num(href_list["target"])
		if("PRG_sort")
			sortBy = href_list["target"]
		if("PRG_lock")
			if(!get_signal())
				return TRUE
			M = locate(href_list["target"])
			if(!isnull(M))
				M.lock()
		if("PRG_unlock")
			if(!get_signal())
				return TRUE
			M = locate(href_list["target"])
			if(!isnull(M))
				M.unlock()
		if("PRG_toggle_force_lock")
			if(!get_signal())
				return TRUE
			M = locate(href_list["target"])
			if(!isnull(M))
				M.toggle_force_lock()
		if("PRG_details")
			M = locate(href_list["target"])
			if(!isnull(M))
				screen = SIBSYS_DETAILS
		if("PRG_log_del")
			if(!isnull(M))
				var/index = min(max(text2num(href_list["target"]) + 1, 1), length(M.log))
				if(M.log[index])
					M.log -= M.log[index]
		if("PRG_limit_up")
			if(!get_signal())
				return TRUE
			M = locate(href_list["target"])
			if(!isnull(M))
				M.limit_up()
		if("PRG_limit_down")
			if(!get_signal())
				return TRUE
			M = locate(href_list["target"])
			if(!isnull(M))
				M.limit_down()
		if("PRG_automode_on")
			GLOB.sibsys_automode = TRUE
		if("PRG_automode_off")
			GLOB.sibsys_automode = FALSE
		if("PRG_print")
			if(isnull(cachedRegistry))
				return TRUE

			var/obj/item/computer_hardware/printer/printer
			if(computer)
				printer = computer.all_components[MC_PRINT]
			if(isnull(printer))
				return TRUE

			var/text = {"<font face=\"Verdana\" color=black><center><B>Реестр оружия</B></center>
						<BR>Время: [station_time_timestamp()]
						<BR>Уровень угрозы: [uppertext(get_security_level_ru())]
						<BR><BR> <table border=1 cellspacing=0 cellpadding=3 style='border: 1px solid black;'></td>
						<tr><td><B>Имя</B><td><B>Оружие</B><td><B>Режим</B><td><B>Доступно</B><td><B>Статус</B></td>"}
			for(var/list/data in cachedRegistry)
				var/d_name = data["name"]
				var/d_weapon = data["weapon"]
				var/d_mode = data["mode"]
				var/d_limit = data["limit"]
				var/d_lock = data["lock"]
				text += "<tr><td>[d_name]<td>[d_weapon]<td>[d_mode]<td>[d_limit]<td>[d_lock]</td>"
			text += "</tr></table></font>"
			printer.print_text(text, "Sibyl System - Реестр оружия")
		else
			return FALSE
	SSnanoui.update_uis(src)
	return TRUE


/datum/computer_file/program/sibyl_system/run_program(mob/living/user)
	if(can_run(user, TRUE, required_access))
		if(requires_ntnet && network_destination)
			generate_network_log("Connection opened to [network_destination].")
		program_state = PROGRAM_STATE_ACTIVE
		return TRUE
	return FALSE

#undef SIBSYS_REGISTRY
#undef SIBSYS_DETAILS
