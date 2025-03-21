/obj/item/assembly/control
	name = "blast door controller"
	desc = "A small electronic device able to control a blast door remotely."
	icon_state = "control"
	attachable = TRUE
	var/id = null
	var/can_change_id = 0
	var/cooldown = FALSE //Door cooldowns
	var/sync_doors = TRUE

/obj/item/assembly/control/examine(mob/user)
	. = ..()
	if(id)
		. += span_notice("Its channel ID is '[id]'.")

/obj/item/assembly/control/multitool_act(mob/living/user)
	var/change_id = tgui_input_number(user, "Set the door controllers ID", "Door ID", id, 100)
	if(!change_id || QDELETED(user) || QDELETED(src) || !usr.canUseTopic(src, USE_CLOSE|USE_IGNORE_TK))
		return
	id = change_id
	to_chat(user, span_notice("You change the ID to [id]."))

/obj/item/assembly/control/activate()
	var/openclose
	if(cooldown)
		return
	cooldown = TRUE
	for(var/obj/machinery/door/poddoor/M in INSTANCES_OF(/obj/machinery/door))
		if(M.id == src.id)
			if(openclose == null || !sync_doors)
				openclose = M.density
			INVOKE_ASYNC(M, openclose ? TYPE_PROC_REF(/obj/machinery/door/poddoor, open) : TYPE_PROC_REF(/obj/machinery/door/poddoor, close))
	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 10)

/obj/item/assembly/control/curtain
	name = "curtain controller"
	desc = "A small electronic device able to control a mechanical curtain remotely."

/obj/item/assembly/control/curtain/examine(mob/user)
	. = ..()
	if(id)
		. += span_notice("Its channel ID is '[id]'.")

/obj/item/assembly/control/curtain/activate()
	var/openclose
	if(cooldown)
		return
	cooldown = TRUE
	for(var/obj/structure/curtain/cloth/fancy/mechanical/M as anything in INSTANCES_OF(/obj/structure/curtain/cloth/fancy/mechanical))
		if(M.id == src.id)
			if(openclose == null || !sync_doors)
				openclose = M.density
			INVOKE_ASYNC(M, openclose ? TYPE_PROC_REF(/obj/structure/curtain/cloth/fancy/mechanical, open) : TYPE_PROC_REF(/obj/structure/curtain/cloth/fancy/mechanical, close))
	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 5)


/obj/item/assembly/control/airlock
	name = "airlock controller"
	desc = "A small electronic device able to control an airlock remotely."
	id = "badmin" // Set it to null for MEGAFUN.
	var/specialfunctions = OPEN
	/*
	Bitflag, 1= open (OPEN)
				2= idscan (IDSCAN)
				4= bolts (BOLTS)
				8= shock (SHOCK)
				16= door safties (SAFE)
	*/

/obj/item/assembly/control/airlock/activate()
	if(cooldown)
		return
	cooldown = TRUE
	var/doors_need_closing = FALSE
	var/list/obj/machinery/door/airlock/open_or_close = list()
	for(var/obj/machinery/door/airlock/D in INSTANCES_OF(/obj/machinery/door))
		if(D.id_tag == src.id)
			if(specialfunctions & OPEN)
				open_or_close += D
				if(!D.density)
					doors_need_closing = TRUE
			if(specialfunctions & IDSCAN)
				D.aiDisabledIdScanner = !D.aiDisabledIdScanner
			if(specialfunctions & BOLTS)
				if(!D.wires.is_cut(WIRE_BOLTS) && D.hasPower())
					D.locked = !D.locked
					D.update_appearance()
			if(specialfunctions & SHOCK)
				if(D.secondsElectrified)
					D.set_electrified(MACHINE_ELECTRIFIED_PERMANENT, usr)
				else
					D.set_electrified(MACHINE_NOT_ELECTRIFIED, usr)
			if(specialfunctions & SAFE)
				D.dont_close_on_dense_objects = !D.dont_close_on_dense_objects

	for(var/D in open_or_close)
		INVOKE_ASYNC(D, doors_need_closing ? TYPE_PROC_REF(/obj/machinery/door/airlock, close) : TYPE_PROC_REF(/obj/machinery/door/airlock, open))

	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 10)


/obj/item/assembly/control/massdriver
	name = "mass driver controller"
	desc = "A small electronic device able to control a mass driver."

/obj/item/assembly/control/massdriver/activate()
	if(cooldown)
		return
	cooldown = TRUE
	for(var/obj/machinery/door/poddoor/M in INSTANCES_OF(/obj/machinery/door))
		if (M.id == src.id)
			INVOKE_ASYNC(M, TYPE_PROC_REF(/obj/machinery/door/poddoor, open))

	sleep(10)

	for(var/obj/machinery/mass_driver/M as anything in INSTANCES_OF(/obj/machinery/mass_driver))
		if(M.id == src.id)
			M.drive()

	sleep(60)

	for(var/obj/machinery/door/poddoor/M in INSTANCES_OF(/obj/machinery/door))
		if (M.id == src.id)
			INVOKE_ASYNC(M, TYPE_PROC_REF(/obj/machinery/door/poddoor, close))

	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 10)


/obj/item/assembly/control/igniter
	name = "ignition controller"
	desc = "A remote controller for a mounted igniter."

/obj/item/assembly/control/igniter/activate()
	if(cooldown)
		return

	cooldown = TRUE

	for(var/obj/machinery/sparker/M as anything in INSTANCES_OF(/obj/machinery/sparker))
		if (M.id == src.id)
			INVOKE_ASYNC(M, TYPE_PROC_REF(/obj/machinery/sparker, ignite))

	for(var/obj/machinery/igniter/M as anything in INSTANCES_OF(/obj/machinery/igniter))
		if(M.id == src.id)
			M.use_power(50)
			M.on = !M.on
			M.icon_state = "igniter[M.on]"

	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 30)

/obj/item/assembly/control/flasher
	name = "flasher controller"
	desc = "A remote controller for a mounted flasher."

/obj/item/assembly/control/flasher/activate()
	if(cooldown)
		return
	cooldown = TRUE
	for(var/obj/machinery/flasher/M as anything in INSTANCES_OF(/obj/machinery/flasher))
		if(M.id == src.id)
			INVOKE_ASYNC(M, TYPE_PROC_REF(/obj/machinery/flasher, flash))

	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 50)

/obj/item/assembly/control/crematorium
	name = "crematorium controller"
	desc = "An evil-looking remote controller for a crematorium."

/obj/item/assembly/control/crematorium/activate()
	if(cooldown)
		return
	cooldown = TRUE
	for (var/obj/structure/bodycontainer/crematorium/C in GLOB.crematoriums)
		if (C.id == id)
			C.cremate(usr)

	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 50)

//how long it spends on each floor when moving somewhere, so it'd take 4 seconds to reach you if it had to travel up 2 floors
#define FLOOR_TRAVEL_TIME 2 SECONDS
/obj/item/assembly/control/elevator
	name = "elevator controller"
	desc = "A small device used to call elevators to the current floor."

/obj/item/assembly/control/elevator/activate()
	if(cooldown)
		return
	cooldown = TRUE
	var/datum/lift_master/lift
	for(var/datum/lift_master/possible_match as anything in GLOB.active_lifts_by_type[BASIC_LIFT_ID])
		if(possible_match.specific_lift_id != id || !check_z(possible_match) || possible_match.controls_locked)
			continue

		lift = possible_match
		break

	if(!lift)
		addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 2 SECONDS)
		return

	var/obj/structure/industrial_lift/target = lift.lift_platforms[1]
	var/target_z = target.z

	lift.set_controls(LIFT_PLATFORM_LOCKED)
	///The z level to which the elevator should travel
	var/targetZ = (abs(loc.z)) //The target Z (where the elevator should move to) is not our z level (we are just some assembly in nullspace) but actually the Z level of whatever we are contained in (e.g. elevator button)
	///The amount of z levels between the our and targetZ
	var/difference = abs(targetZ - target_z)
	///Direction (up/down) needed to go to reach targetZ
	var/direction = target_z < targetZ ? UP : DOWN
	///How long it will/should take us to reach the target Z level
	var/travel_duration = FLOOR_TRAVEL_TIME * difference //100 / 2 floors up = 50 seconds on every floor, will always reach destination in the same time
	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), travel_duration)

	for(var/i in 1 to difference)
		sleep(FLOOR_TRAVEL_TIME)//hey this should be alright... right?
		if(QDELETED(lift) || QDELETED(src))//elevator control or button gone = don't go up anymore
			return
		lift.MoveLift(direction, null)
	lift.set_controls(LIFT_PLATFORM_UNLOCKED)

///check if any of the lift platforms are already here
/obj/item/assembly/control/elevator/proc/check_z(datum/lift_master/lift)
	for(var/obj/structure/industrial_lift/platform as anything in lift.lift_platforms)
		if(platform.z == loc.z)
			return FALSE

	return TRUE

#undef FLOOR_TRAVEL_TIME

/obj/item/assembly/control/tram
	name = "tram call button"
	desc = "A small device used to bring trams to you."
	///for finding the landmark initially - should be the exact same as the landmark's destination id.
	var/initial_id
	///ID to link to allow us to link to one specific tram in the world
	var/specific_lift_id = MAIN_STATION_TRAM
	///this is our destination's landmark, so we only have to find it the first time.
	var/datum/weakref/to_where

/obj/item/assembly/control/tram/Initialize(mapload)
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/item/assembly/control/tram/LateInitialize()
	. = ..()
	//find where the tram needs to go to (our destination). only needs to happen the first time
	for(var/obj/effect/landmark/tram/our_destination as anything in GLOB.tram_landmarks[specific_lift_id])
		if(our_destination.destination_id == initial_id)
			to_where = WEAKREF(our_destination)
			break

/obj/item/assembly/control/tram/Destroy()
	to_where = null
	return ..()

/obj/item/assembly/control/tram/activate()
	if(cooldown)
		return
	cooldown = TRUE
	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 2 SECONDS)

	var/datum/lift_master/tram/tram
	for(var/datum/lift_master/tram/possible_match as anything in GLOB.active_lifts_by_type[TRAM_LIFT_ID])
		if(possible_match.specific_lift_id == specific_lift_id)
			tram = possible_match
			break

	if(!tram)
		say("The tram is not responding to call signals. Please send a technician to repair the internals of the tram.")
		return
	if(tram.travelling) //in use
		say("The tram is already travelling to [tram.from_where].")
		return
	if(!to_where)
		return
	var/obj/effect/landmark/tram/current_location = to_where.resolve()
	if(!current_location)
		return
	if(tram.from_where == current_location) //already here
		say("The tram is already here. Please board the tram and select a destination.")
		return

	say("The tram has been called to [current_location.name]. Please wait for its arrival.")
	tram.tram_travel(current_location)
