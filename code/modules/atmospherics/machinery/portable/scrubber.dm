/obj/machinery/portable_atmospherics/scrubber
	name = "portable air scrubber"
	icon_state = "scrubber"
	density = TRUE
	max_integrity = 250
	volume = 1000

	///Max amount of heat allowed inside of the canister before it starts to melt (different tiers have different limits)
	var/heat_limit = 5000
	///Max amount of pressure allowed inside of the canister before it starts to break (different tiers have different limits)
	var/pressure_limit = 50000
	///Is the machine on?
	var/on = FALSE
	///the rate the machine will scrub air
	var/volume_rate = 1000
	///Multiplier with ONE_ATMOSPHERE, if the enviroment pressure is higher than that, the scrubber won't work
	var/overpressure_m = 80
	///Should the machine use overlay in update_overlays() when open/close?
	var/use_overlays = TRUE
	var/power_rating = 7500
	///List of gases that are being scrubbed.
	var/list/scrubbing = list()

/obj/machinery/portable_atmospherics/scrubber/Initialize(mapload)
	. = ..()

/obj/machinery/portable_atmospherics/scrubber/Destroy()
	var/turf/T = get_turf(src)
	T.assume_air(air_contents)
	return ..()

/obj/machinery/portable_atmospherics/scrubber/update_icon_state()
	icon_state = "[initial(icon_state)]_[on]"
	return ..()

/obj/machinery/portable_atmospherics/scrubber/update_overlays()
	. = ..()
	if(!use_overlays)
		return
	if(holding)
		. += "scrubber-open"
	if(connected_port)
		. += "scrubber-connector"

/obj/machinery/portable_atmospherics/scrubber/process_atmos()
	var/pressure = air_contents.returnPressure()
	var/temperature = air_contents.temperature
	///function used to check the limit of the scrubbers and also set the amount of damage that the scrubber can receive, if the heat and pressure are way higher than the limit the more damage will be done
	if(temperature > heat_limit || pressure > pressure_limit)
		take_damage(clamp((temperature/heat_limit) * (pressure/pressure_limit), 5, 50), BURN, 0)
		excited = TRUE
		return ..()

	if(!on)
		return ..()

	excited = TRUE

	var/atom/target = holding || get_turf(src)
	if(scrub(target.unsafe_return_air()))
		SAFE_ZAS_UPDATE(target)


	return ..()

/**
 * Called in process_atmos(), handles the scrubbing of the given gas_mixture
 * Arguments:
 * * mixture: the gas mixture to be scrubbed
 */
/obj/machinery/portable_atmospherics/scrubber/proc/scrub(datum/gas_mixture/mixture)
	if(!mixture.total_moles || !length(scrubbing))
		return
	if(air_contents.returnPressure() >= overpressure_m * ONE_ATMOSPHERE)
		return

	var/transfer_moles = min(1, volume_rate/mixture.volume)*mixture.total_moles

	var/draw = scrub_gas(scrubbing, mixture, air_contents, transfer_moles, power_rating)
	ATMOS_USE_POWER(draw)
	return TRUE

/obj/machinery/portable_atmospherics/scrubber/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(is_operational)
		if(prob(50 / severity))
			on = !on
			if(on)
				SSairmachines.start_processing_machine(src)
		update_appearance()

/obj/machinery/portable_atmospherics/scrubber/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PortableScrubber", name)
		ui.open()

/obj/machinery/portable_atmospherics/scrubber/ui_data()
	var/data = list()
	data["on"] = on
	data["connected"] = connected_port ? 1 : 0
	data["pressure"] = round(air_contents.returnPressure() ? air_contents.returnPressure() : 0)

	data["id_tag"] = -1 //must be defined in order to reuse code between portable and vent scrubbers
	data["filter_types"] = list()
	for(var/gas_id in ASSORTED_GASES)
		data["filter_types"] += list(list("gas_id" = gas_id, "gas_name" = gas_id, "enabled" = (gas_id in scrubbing)))

	if(holding)
		data["holding"] = list()
		data["holding"]["name"] = holding.name
		var/datum/gas_mixture/holding_mix = holding.return_air()
		data["holding"]["pressure"] = round(holding_mix.returnPressure())
	else
		data["holding"] = null
	return data

/obj/machinery/portable_atmospherics/scrubber/replace_tank(mob/living/user, close_valve)
	. = ..()
	if(!.)
		return
	if(close_valve)
		if(on)
			on = FALSE
			update_appearance()
	else if(on && holding)
		investigate_log("[key_name(user)] started a transfer into [holding].", INVESTIGATE_ATMOS)

/obj/machinery/portable_atmospherics/scrubber/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("power")
			on = !on
			if(on)
				SSairmachines.start_processing_machine(src)
			. = TRUE
		if("eject")
			if(holding)
				replace_tank(usr, FALSE)
				. = TRUE
		if("toggle_filter")
			scrubbing ^= params["val"]
			. = TRUE
	update_appearance()

/obj/machinery/portable_atmospherics/scrubber/unregister_holding()
	on = FALSE
	return ..()

/obj/machinery/portable_atmospherics/scrubber/huge
	name = "huge air scrubber"
	icon_state = "hugescrubber"
	anchored = TRUE
	power_rating = 100000

	overpressure_m = 200
	volume_rate = 1500
	volume = 50000

	var/movable = FALSE
	use_overlays = FALSE

/obj/machinery/portable_atmospherics/scrubber/huge/movable
	movable = TRUE

/obj/machinery/portable_atmospherics/scrubber/huge/movable/cargo
	anchored = FALSE

/obj/machinery/portable_atmospherics/scrubber/huge/update_icon_state()
	icon_state = "[initial(icon_state)]_[on]"
	return ..()

/obj/machinery/portable_atmospherics/scrubber/huge/process_atmos()
	if((!anchored && !movable) || !is_operational)
		on = FALSE
		update_appearance()

	if(!on)
		return ..()

	excited = TRUE

	if(!holding)
		var/turf/muhturf = get_turf(src)
		if(scrub(muhturf.unsafe_return_air()))
			SAFE_ZAS_UPDATE(muhturf)

	return ..()

/obj/machinery/portable_atmospherics/scrubber/huge/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(default_unfasten_wrench(user, tool))
		if(!movable)
			on = FALSE
		return ITEM_INTERACT_SUCCESS
	return FALSE

