#define TANK_COMPRESSOR_PRESSURE_LIMIT 5000
#define TANK_COMPRESSOR_MAX_TRANSFER_RATE 20
#define SIGNIFICANT_AMOUNT_OF_MOLES 10

/obj/machinery/atmospherics/components/binary/tank_compressor
	name = "Tank Compressor"
	desc = "Heavy duty shielded air compressor designed to pressurize tanks above the safe limit."
	circuit = /obj/item/circuitboard/machine/tank_compressor
	icon = 'icons/obj/machines/research.dmi'
	base_icon_state = "tank_compressor"
	icon_state = "tank_compressor-open"
	density = TRUE

	var/active = FALSE
	var/transfer_rate = TANK_COMPRESSOR_MAX_TRANSFER_RATE
	var/datum/gas_mixture/leaked_gas_buffer
	var/list/compressor_record
	var/last_recorded_pressure = 0
	var/record_number = 1
	var/obj/item/tank/inserted_tank
	/// Reference to a disk we are going to print to.
	var/obj/item/computer_hardware/hard_drive/portable/inserted_drive

	pipe_flags = PIPING_ONE_PER_TURF | PIPING_DEFAULT_LAYER_ONLY

/obj/machinery/atmospherics/components/binary/tank_compressor/Initialize(mapload)
	. = ..()
	leaked_gas_buffer = new(200)
	compressor_record = list()
	RegisterSignal(src, COMSIG_ATOM_INTERNAL_EXPLOSION, PROC_REF(explosion_handle))

/obj/machinery/atmospherics/components/binary/tank_compressor/examine()
	. = ..()
	. += "This one is rated for up to [TANK_COMPRESSOR_PRESSURE_LIMIT] kPa."

/// Stores the record of the gas data for a significant enough tank leak
/datum/data/compressor_record
	/// Tank Name
	var/experiment_source
	/// Key: Path, Value: Moles
	var/list/gas_data = list()
	var/timestamp

/obj/machinery/atmospherics/components/binary/tank_compressor/attackby(obj/item/item, mob/living/user)
	if (panel_open)
		return ..()

	if(istype(item, /obj/item/tank))
		var/obj/item/tank/tank_item = item
		if(inserted_tank)
			if(!eject_tank(user))
				balloon_alert(user, span_warning("[inserted_tank] is stuck inside."))
				return ..()
		if(!user.transferItemToLoc(tank_item, src))
			balloon_alert(user, span_warning("[tank_item] is stuck to your hand."))
			return ..()
		inserted_tank = tank_item
		last_recorded_pressure = 0
		RegisterSignal(inserted_tank, COMSIG_PARENT_QDELETING, PROC_REF(tank_destruction))
		update_appearance()
		return
	if(istype(item, /obj/item/computer_hardware/hard_drive/portable))
		var/obj/item/computer_hardware/hard_drive/portable/attacking_disk = item
		eject_drive(user)
		if(user.transferItemToLoc(attacking_disk, src))
			inserted_drive = attacking_disk
		else
			balloon_alert(user, span_warning("[attacking_disk] is stuck to your hand."))
		return
	return ..()

/obj/machinery/atmospherics/components/binary/tank_compressor/wrench_act(mob/living/user, obj/item/tool)
	if(active || inserted_tank)
		return FALSE
	if(!default_change_direction_wrench(user, tool))
		return FALSE
	return TRUE

/obj/machinery/atmospherics/components/binary/tank_compressor/screwdriver_act(mob/living/user, obj/item/tool)
	if(active || inserted_tank)
		return FALSE
	if(!default_deconstruction_screwdriver(user, "[base_icon_state]-open", "[base_icon_state]-open", tool))
		return FALSE
	update_appearance()
	return TRUE

/obj/machinery/atmospherics/components/binary/tank_compressor/crowbar_act(mob/living/user, obj/item/tool)
	if(active || inserted_tank)
		return FALSE
	if(!default_deconstruction_crowbar(tool))
		return FALSE
	return TRUE

/obj/machinery/atmospherics/components/binary/tank_compressor/default_change_direction_wrench(mob/user, obj/item/wrench)
	. = ..()
	if(!.)
		return

	// Disconnect our partner.
	if(nodes[1])
		nodes[1].disconnect(src)
		nodes[1] = null
		if(parents[1])
			nullify_pipenet(parents[1])
	if(nodes[2])
		nodes[2].disconnect(src)
		nodes[2] = null
		if(parents[2])
			nullify_pipenet(parents[2])
	set_init_directions()
	// Connect to a new one.
	atmos_init()
	if(nodes[1])
		nodes[1].atmos_init()
		nodes[1].add_member(src)
	if(nodes[2])
		nodes[2].atmos_init()
		nodes[2].add_member(src)
	SSairmachines.add_to_rebuild_queue(src)
	update_appearance()

/// Glorified volume pump.
/obj/machinery/atmospherics/components/binary/tank_compressor/process_atmos()
	var/datum/gas_mixture/input_air = airs[2]
	if(!input_air?.total_moles || !active || !transfer_rate || !inserted_tank)
		return

	var/datum/gas_mixture/tank_air = inserted_tank.return_air()
	if(!tank_air)
		return

	if(input_air.returnPressure() < 0.01 || tank_air.returnPressure() > TANK_COMPRESSOR_PRESSURE_LIMIT)
		return

	/// Prevent pumping if tank is taking damage but still below pressure limit. Here to prevent exploiting the buffer system.
	if((inserted_tank.leaking) && (tank_air.returnPressure() <= TANK_LEAK_PRESSURE))
		active = FALSE
		return

	var/datum/gas_mixture/removed = input_air.removeRatio(transfer_rate / input_air.volume)
	if(!removed)
		return

	tank_air.merge(removed)
	update_parents()

/obj/machinery/atmospherics/components/binary/tank_compressor/assume_air(datum/gas_mixture/giver)
	if(!leaked_gas_buffer)
		return ..()
	leaked_gas_buffer.merge(giver)
	return TRUE

/// Recording of last pressure of the tank. Ran when a tank is about to explode or disintegrate. We dont care about last pressure if the tank is ejected.
/obj/machinery/atmospherics/components/binary/tank_compressor/proc/tank_destruction()
	SIGNAL_HANDLER
	if(inserted_tank.get_integrity() > 0)
		return
	flush_buffer()
	var/datum/gas_mixture/tank_air = inserted_tank.return_air()
	last_recorded_pressure = tank_air.returnPressure()
	active = FALSE
	return

/// Use this to absorb explosions.
/obj/machinery/atmospherics/components/binary/tank_compressor/proc/explosion_handle(atom/source, list/arguments)
	SIGNAL_HANDLER
	say("Internal explosion detected and absorbed.")
	SSexplosions.shake_the_room(get_turf(src), 1, 8, 0.5, 0.25, FALSE)
	return COMSIG_CANCEL_EXPLOSION

/**
 * Everytime a tank is destroyed or a new tank is inserted, our buffer is flushed.
 * Mole requirements in experiments are tracked by buffer data.
 */
/obj/machinery/atmospherics/components/binary/tank_compressor/proc/flush_buffer()
	if(!leaked_gas_buffer.total_moles)
		return
	if(leaked_gas_buffer.total_moles > SIGNIFICANT_AMOUNT_OF_MOLES)
		record_data()
	else
		say("Buffer data discarded. Required moles for storage: [SIGNIFICANT_AMOUNT_OF_MOLES] moles.")
	var/datum/gas_mixture/removed = leaked_gas_buffer.removeRatio(1)
	airs[1].merge(removed)
	say("Gas stored in buffer flushed to output port. Compressor ready to start the next experiment.")

/// This proc should be called whenever we want to store our buffer data.
/obj/machinery/atmospherics/components/binary/tank_compressor/proc/record_data()
	var/datum/data/compressor_record/new_record = new()
	new_record.name = "Log Recording #[record_number]"
	new_record.experiment_source = inserted_tank.name
	new_record.timestamp = stationtime2text()
	for(var/gas_path in leaked_gas_buffer.gas)
		new_record.gas_data[gas_path] = leaked_gas_buffer.gas[gas_path]

	compressor_record += new_record
	record_number += 1
	say("Buffer data stored.")

/obj/machinery/atmospherics/components/binary/tank_compressor/proc/print(mob/user, datum/data/compressor_record/record)
	if(!record || !inserted_drive)
		return

	var/datum/computer_file/data/ordnance/gaseous/record_data = new
	record_data.filename = "Gas Compressor " + record.name //Gas Compressor Log Recording #x
	record_data.gas_record = record

	if(inserted_drive.store_file(record_data))
		playsound(src, 'sound/machines/ping.ogg', 25)
	else
		playsound(src, 'sound/machines/terminal_error.ogg', 25)

/// Ejecting a tank. Also called on insertion to clear previous tanks.
/obj/machinery/atmospherics/components/binary/tank_compressor/proc/eject_tank(mob/user)
	if(!inserted_tank)
		return FALSE
	var/datum/gas_mixture/tank_air = inserted_tank.return_air()
	if(!tank_air.returnPressure() >= PUMP_MAX_PRESSURE)
		return FALSE
	flush_buffer()
	if(user)
		user.put_in_hands(inserted_tank)
	else
		inserted_tank.forceMove(drop_location())
	active = FALSE
	return TRUE

/obj/machinery/atmospherics/components/binary/tank_compressor/proc/eject_drive(mob/user)
	if(!inserted_drive)
		return FALSE
	if(user)
		user.put_in_hands(inserted_drive)
	else
		inserted_drive.forceMove(drop_location())
	playsound(src, 'sound/machines/card_slide.ogg', 50)
	return TRUE

/// We rely on exited to clear references.
/obj/machinery/atmospherics/components/binary/tank_compressor/Exited(atom/movable/gone, direction)
	if(gone == inserted_drive)
		inserted_drive = null
	if(gone == inserted_tank)
		UnregisterSignal(inserted_tank, COMSIG_PARENT_QDELETING)
		inserted_tank = null
		update_appearance()
	. = ..()

/obj/machinery/atmospherics/components/binary/tank_compressor/on_deconstruction()
	eject_tank()
	eject_drive()
	return ..()

/obj/machinery/atmospherics/components/binary/tank_compressor/Destroy()
	inserted_tank = null
	inserted_drive = null
	leaked_gas_buffer = null
	compressor_record = null //We only want the list nuked, not the contents.
	return ..()

/obj/machinery/atmospherics/components/binary/tank_compressor/update_icon_state()
	if(istype(inserted_tank))
		icon_state = "[base_icon_state]-closed"
	else
		icon_state = "[base_icon_state]-open"
	return ..()

/obj/machinery/atmospherics/components/binary/tank_compressor/update_overlays()
	. = ..()
	. += get_pipe_image(icon, "[base_icon_state]-pipe", dir, COLOR_BLUE, piping_layer)
	. += get_pipe_image(icon, "[base_icon_state]-pipe", turn(dir, 180), COLOR_RED, piping_layer)
	if(!istype(inserted_tank))
		. += mutable_appearance(icon, "[base_icon_state]-doors",)
	if(panel_open)
		. += mutable_appearance(icon, "[base_icon_state]-maintenance")
	else
		. += mutable_appearance(icon, "[base_icon_state]-cables")

/obj/machinery/atmospherics/components/binary/tank_compressor/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TankCompressor")
		ui.open()

/obj/machinery/atmospherics/components/binary/tank_compressor/ui_act(action, list/params)
	. = ..()
	if (.)
		return
	switch(action)
		if("change_rate")
			transfer_rate = clamp(params["target"], 0, TANK_COMPRESSOR_MAX_TRANSFER_RATE)
		if("toggle_injection")
			active = !active
		if("eject_tank")
			eject_tank(usr)
		if("eject_disk")
			eject_drive(usr)
		if("delete_record")
			var/datum/data/compressor_record/record = locate(params["ref"]) in compressor_record
			if(!compressor_record || !(record in compressor_record))
				return
			compressor_record -= record
			return TRUE
		if("print_record")
			var/datum/data/compressor_record/record  = locate(params["ref"]) in compressor_record
			if(!compressor_record || !(record in compressor_record))
				return
			print(usr, record)
			return TRUE

/obj/machinery/atmospherics/components/binary/tank_compressor/ui_static_data()
	var/list/data = list(
	"maxTransfer" = TANK_COMPRESSOR_MAX_TRANSFER_RATE,
	"leakPressure" = round(TANK_LEAK_PRESSURE),
	"fragmentPressure" = round(TANK_FRAGMENT_PRESSURE),
	"ejectPressure" = PUMP_MAX_PRESSURE
	)
	return data

/obj/machinery/atmospherics/components/binary/tank_compressor/ui_data(mob/user)
	var/list/data = list()
	data["tankPresent"] = inserted_tank ? TRUE : FALSE
	var/datum/gas_mixture/tank_air = inserted_tank?.return_air()
	data["tankPressure"] = tank_air?.returnPressure()
	data["leaking"] = inserted_tank?.leaking

	data["active"] = active
	data["transferRate"] = transfer_rate
	data["lastPressure"] = last_recorded_pressure

	data["inputData"] = gas_mixture_parser(airs[2], "Input Port")
	data["outputData"] = gas_mixture_parser(airs[1], "Ouput Port")
	data["bufferData"] = gas_mixture_parser(leaked_gas_buffer, "Gas Buffer")

	data["disk"] = inserted_drive?.name
	data["storage"] = "[inserted_drive?.used_capacity] / [inserted_drive?.max_capacity] GQ"
	data["records"] = list()
	for (var/datum/data/compressor_record/record in compressor_record)
		var/list/single_record_data = list(
			"ref" = REF(record),
			"name" = record.name,
			"source" = record.experiment_source,
			"timestamp" = record.timestamp,
			"gases" = list()
		)
		for (var/path in record.gas_data)
			single_record_data["gases"] += list(path = record.gas_data[path])
		data["records"] += list(single_record_data)
	return data
