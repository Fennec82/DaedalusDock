/// Creates and sorts all the keybinding datums
/proc/init_keybindings()
	for(var/KB in subtypesof(/datum/keybinding))
		var/datum/keybinding/keybinding = KB
		if(!initial(keybinding.keybind_signal) || !initial(keybinding.name))
			continue
		add_keybinding(new keybinding)
	init_emote_keybinds()

/// Adds an instanced keybinding to the global tracker
/proc/add_keybinding(datum/keybinding/instance)
	if(istype(instance, /datum/keybinding/rawkey))
		for(var/key in instance.hotkey_keys)
			GLOB.raw_keybindings_by_key[key] = instance
		return

	GLOB.keybindings_by_name[instance.name] = instance

	// Hotkey
	if(LAZYLEN(instance.hotkey_keys))
		for(var/bound_key in instance.hotkey_keys)
			if (bound_key == "Unbound")
				LAZYADD(GLOB.default_hotkeys[instance.name], list())
			else
				LAZYADD(GLOB.default_hotkeys[instance.name], list(bound_key))

/proc/init_emote_keybinds()
	for(var/i in subtypesof(/datum/emote))
		var/datum/emote/faketype = i
		if(!initial(faketype.key) || !initial(faketype.can_player_use))
			continue
		var/datum/keybinding/emote/emote_kb = new
		emote_kb.link_to_emote(faketype)
		add_keybinding(emote_kb)
