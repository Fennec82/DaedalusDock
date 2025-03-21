///Pathfinder - Can fly the suit from a long distance to an implant installed in someone.
/obj/item/mod/module/pathfinder
	name = "\improper MOD recall module"
	desc = "This module, brought to you by Nakamura Engineering, has two components. \
		The first component is a series of thrusters and a computerized location subroutine installed into the \
		very control unit of the suit, allowing it flight at highway speeds, \
		and to be able to locate the second part of the system; \
		a pathfinding implant installed into the base of the user's spine, \
		broadcasting their location to the suit and allowing them to recall it to their back at any time. \
		The implant is stored in the module and needs to be injected in a human to function. \
		Nakamura Engineering swears up and down there's airbrakes."
	icon_state = "pathfinder"
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN * 10
	incompatible_modules = list(/obj/item/mod/module/pathfinder)
	required_slots = list(ITEM_SLOT_BACK|ITEM_SLOT_BELT)
	/// The pathfinding implant.
	var/obj/item/implant/mod/implant

/obj/item/mod/module/pathfinder/Initialize(mapload)
	. = ..()
	implant = new(src)

/obj/item/mod/module/pathfinder/Destroy()
	QDEL_NULL(implant)
	return ..()

/obj/item/mod/module/pathfinder/Exited(atom/movable/gone, direction)
	if(gone == implant)
		implant = null
		update_icon_state()
	return ..()

/obj/item/mod/module/pathfinder/update_icon_state()
	. = ..()
	icon_state = implant ? "pathfinder" : "pathfinder_empty"

/obj/item/mod/module/pathfinder/examine(mob/user)
	. = ..()
	if(implant)
		. += span_notice("Use it on a human to implant them.")
	else
		. += span_warning("The implant is missing.")

/obj/item/mod/module/pathfinder/attack(mob/living/target, mob/living/user, params)
	if(!ishuman(target) || !implant)
		return
	if(!do_after(user, target, 1.5 SECONDS))
		return

	var/implant_cache = implant // implant() will make implant null
	if(!implant.implant(target, user, deprecise_zone(user.zone_selected)))
		return

	if(target == user)
		to_chat(user, span_notice("You implant yourself with [implant_cache]."))
	else
		target.visible_message(span_notice("[user] implants [target]."), span_notice("[user] implants you with [implant_cache]."))
	playsound(src, 'sound/effects/spray.ogg', 30, TRUE, -6)

/obj/item/mod/module/pathfinder/proc/attach(mob/living/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/human_user = user
	if(human_user.get_item_by_slot(mod.slot_flags) && !human_user.dropItemToGround(human_user.get_item_by_slot(mod.slot_flags)))
		return
	if(!human_user.equip_to_slot_if_possible(mod, mod.slot_flags, qdel_on_fail = FALSE, disable_warning = TRUE))
		return

	mod.quick_deploy(user)
	human_user.update_action_buttons(TRUE)
	playsound(mod, 'sound/machines/ping.ogg', 50, TRUE)
	drain_power(use_power_cost)

/obj/item/implant/mod
	name = "\improper MOD recall implant"
	desc = "Lets you recall a MODsuit to you at any time."
	actions_types = list(/datum/action/item_action/mod_recall)
	implant_flags = IMPLANT_KNOWN

	/// The pathfinder module we are linked to.
	var/obj/item/mod/module/pathfinder/module
	/// The jet icon we apply to the MOD.
	var/image/jet_icon

/obj/item/implant/mod/Initialize(mapload)
	. = ..()
	if(!istype(loc, /obj/item/mod/module/pathfinder))
		return INITIALIZE_HINT_QDEL
	module = loc
	jet_icon = image(icon = 'icons/obj/clothing/modsuit/mod_modules.dmi', icon_state = "mod_jet", layer = LOW_ITEM_LAYER)

/obj/item/implant/mod/Destroy()
	if(module?.mod?.ai_controller)
		end_recall(successful = FALSE)

	module = null
	jet_icon = null
	return ..()

/obj/item/implant/mod/get_data()
	var/dat = {"<b>Implant Specifications:</b><BR>
				<b>Name:</b> Nakamura Engineering Pathfinder Implant<BR>
				<b>Implant Details:</b> Allows for the recall of a Modular Outerwear Device by the implant owner at any time.<BR>"}
	return dat

/obj/item/implant/mod/proc/recall(mob/user)
	if(!module?.mod)
		to_chat(user, span_warning("There is no suit linked to your [src]."))
		return FALSE

	if(module.mod.open)
		to_chat(user, span_warning("Unable to recall MOD suit - Maintenance hatch open."))
		return FALSE

	if(module.mod.ai_controller)
		to_chat(user, span_warning("Unable to recall MOD suit - Already in transit."))
		return FALSE


	if(module.z != z || get_dist(imp_in, module.mod) > MOD_AI_RANGE)
		to_chat(user, span_warning("Unable to recall MOD suit - Out of range."))
		return FALSE

	if(!isturf(module.mod.loc))
		if(!isliving(module.mod.loc))
			to_chat(user, span_warning("Unable to recall MOD suit - Suit is inside container."))
			return FALSE

		var/mob/living/L = module.mod.loc
		if(L.is_holding(module.mod))
			if(L.dropItemToGround(module.mod))
				L.visible_message(span_alert("[module.mod] suddenly activates, flying out from [L]'s grasp!"))
			else
				to_chat(user, span_warning("Unable to recall MOD suit - Suit is inside container."))
				return FALSE

		else if(L.get_item_by_slot(ITEM_SLOT_BACK))
			to_chat(user, span_warning("Unable to recall MOD suit - Suit is being worn."))
			return FALSE
		else
			to_chat(user, span_warning("Unable to recall MOD suit - Suit is inside container."))
			return FALSE

	var/datum/ai_controller/mod_ai = new /datum/ai_controller/mod(module.mod)
	module.mod.ai_controller = mod_ai
	mod_ai.set_move_target(imp_in)
	mod_ai.set_blackboard_key(BB_MOD_TARGET, imp_in)
	mod_ai.set_blackboard_key(BB_MOD_IMPLANT, src)
	module.mod.interaction_flags_item &= ~INTERACT_ITEM_ATTACK_HAND_PICKUP
	module.mod.AddElement(/datum/element/movetype_handler)
	ADD_TRAIT(module.mod, TRAIT_MOVE_FLYING, MOD_TRAIT)
	animate(module.mod, 0.2 SECONDS, pixel_x = base_pixel_y, pixel_y = base_pixel_y)
	module.mod.add_overlay(jet_icon)
	RegisterSignal(module.mod, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))

	to_chat(user, "[src] pings, \"MOD suit recalled.\"")
	return TRUE

/obj/item/implant/mod/proc/end_recall(successful = TRUE)
	if(!module?.mod)
		return

	QDEL_NULL(module.mod.ai_controller)
	module.mod.interaction_flags_item |= INTERACT_ITEM_ATTACK_HAND_PICKUP
	REMOVE_TRAIT(module.mod, TRAIT_MOVE_FLYING, MOD_TRAIT)
	module.mod.RemoveElement(/datum/element/movetype_handler)
	module.mod.cut_overlay(jet_icon)
	module.mod.transform = matrix()
	UnregisterSignal(module.mod, COMSIG_MOVABLE_MOVED)
	if(!successful)
		to_chat(imp_in, span_warning("[src] buzzes, \"MOD suit stopped travelling due to obstruction.\""))

/obj/item/implant/mod/proc/on_move(atom/movable/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER

	var/distance = get_dist(source, imp_in)
	if(!(distance %% 20))
		to_chat(imp_in, "[src] pings, \"Suit is [distance] meters away.\"")

/datum/action/item_action/mod_recall
	name = "Recall MOD"
	desc = "Recall a MODsuit anyplace, anytime."
	check_flags = AB_CHECK_CONSCIOUS
	background_icon_state = "bg_tech_blue"
	button_icon = 'icons/mob/actions/actions_mod.dmi'
	button_icon_state = "recall"
	/// The cooldown for the recall.
	COOLDOWN_DECLARE(recall_cooldown)

/datum/action/item_action/mod_recall/New(Target)
	..()
	if(!istype(Target, /obj/item/implant/mod))
		qdel(src)
		return

/datum/action/item_action/mod_recall/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return
	var/obj/item/implant/mod/implant = target
	if(!COOLDOWN_FINISHED(src, recall_cooldown))
		to_chat(implant.imp_in, span_warning("[implant] is on cooldown."))
		return

	if(implant.recall(implant.imp_in))
		COOLDOWN_START(src, recall_cooldown, 15 SECONDS)
