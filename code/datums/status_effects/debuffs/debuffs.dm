//Largely negative status effects go here, even if they have small benificial effects
//STUN EFFECTS
/datum/status_effect/incapacitating
	tick_interval = 0
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/needs_update_stat = FALSE

/datum/status_effect/incapacitating/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()
	if(. && (needs_update_stat || issilicon(owner)))
		owner.update_stat()


/datum/status_effect/incapacitating/on_remove()
	if(needs_update_stat || issilicon(owner)) //silicons need stat updates in addition to normal canmove updates
		owner.update_stat()
	return ..()


//STUN
/datum/status_effect/incapacitating/stun
	id = "stun"
	max_duration = 30 SECONDS

/datum/status_effect/incapacitating/stun/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/stun/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	return ..()


//KNOCKDOWN
/datum/status_effect/incapacitating/knockdown
	id = "knockdown"
	max_duration = 30 SECONDS

/datum/status_effect/incapacitating/knockdown/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/knockdown/on_remove()
	REMOVE_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))
	return ..()


//IMMOBILIZED
/datum/status_effect/incapacitating/immobilized
	id = "immobilized"

/datum/status_effect/incapacitating/immobilized/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/immobilized/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	return ..()


//PARALYZED
/datum/status_effect/incapacitating/paralyzed
	id = "paralyzed"
	max_duration = 30 SECONDS

/datum/status_effect/incapacitating/paralyzed/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/paralyzed/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	return ..()

//INCAPACITATED
/// This status effect represents anything that leaves a character unable to perform basic tasks (interrupting do-afters, for example), but doesn't incapacitate them further than that (no stuns etc..)
/datum/status_effect/incapacitating/incapacitated
	id = "incapacitated"

// What happens when you get the incapacitated status. You get TRAIT_INCAPACITATED added to you for the duration of the status effect.
/datum/status_effect/incapacitating/incapacitated/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))

// When the status effect runs out, your TRAIT_INCAPACITATED is removed.
/datum/status_effect/incapacitating/incapacitated/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	return ..()


//UNCONSCIOUS
/datum/status_effect/incapacitating/unconscious
	id = "unconscious"
	needs_update_stat = TRUE

/datum/status_effect/incapacitating/unconscious/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/unconscious/on_remove()
	REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	return ..()

/datum/status_effect/incapacitating/unconscious/tick()
	if(owner.stamina.loss)
		owner.stamina.adjust(-0.3) //reduce stamina loss by 0.3 per tick, 6 per 2 seconds


//SLEEPING
/datum/status_effect/incapacitating/sleeping
	id = "sleeping"
	alert_type = /atom/movable/screen/alert/status_effect/asleep
	needs_update_stat = TRUE
	tick_interval = 2 SECONDS

/datum/status_effect/incapacitating/sleeping/on_apply()
	. = ..()
	if(!.)
		return

	if(!HAS_TRAIT(owner, TRAIT_SLEEPIMMUNE))
		ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
		tick_interval = -1

	if(owner.mind)
		COOLDOWN_START(owner.mind, dream_cooldown, 5 SECONDS) // You need to sleep for atleast 5 seconds to begin dreaming.

	ADD_TRAIT(owner, TRAIT_DEAF, TRAIT_STATUS_EFFECT(id))
	RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_SLEEPIMMUNE), PROC_REF(on_owner_insomniac))
	RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_SLEEPIMMUNE), PROC_REF(on_owner_sleepy))

/datum/status_effect/incapacitating/sleeping/on_remove()
	REMOVE_TRAIT(owner, TRAIT_DEAF, TRAIT_STATUS_EFFECT(id))
	UnregisterSignal(owner, list(SIGNAL_ADDTRAIT(TRAIT_SLEEPIMMUNE), SIGNAL_REMOVETRAIT(TRAIT_SLEEPIMMUNE)))
	if(!HAS_TRAIT(owner, TRAIT_SLEEPIMMUNE))
		REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
		tick_interval = initial(tick_interval)

	return ..()

///If the mob is sleeping and gain the TRAIT_SLEEPIMMUNE we remove the TRAIT_KNOCKEDOUT and stop the tick() from happening
/datum/status_effect/incapacitating/sleeping/proc/on_owner_insomniac(mob/living/source)
	SIGNAL_HANDLER
	REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	tick_interval = -1

///If the mob has the TRAIT_SLEEPIMMUNE but somehow looses it we make him sleep and restart the tick()
/datum/status_effect/incapacitating/sleeping/proc/on_owner_sleepy(mob/living/source)
	SIGNAL_HANDLER
	ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	tick_interval = initial(tick_interval)

/datum/status_effect/incapacitating/sleeping/tick()
	var/healing = -0.2
	if(isturf(owner.loc))
		if((locate(/obj/structure/bed) in owner.loc))
			healing -= 0.3
		else if((locate(/obj/structure/table) in owner.loc))
			healing -= 0.1

		if((locate(/obj/structure/table) in owner.loc))
			healing -= 0.1

	if(owner.getToxLoss() >= 20)
		owner.adjustToxLoss(healing * 0.5, TRUE, TRUE)

	owner.stamina.adjust(-healing)

	// Drunkenness gets reduced by 0.3% per tick (6% per 2 seconds)
	owner.set_drunk_effect(owner.get_drunk_amount() * 0.997)

	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.try_dream()

	if(prob(2) && owner.health > owner.crit_threshold)
		owner.emote("snore")

/atom/movable/screen/alert/status_effect/asleep
	name = "Asleep"
	desc = "You've fallen asleep. Wait a bit and you should wake up. Unless you don't, considering how helpless you are."
	icon_state = "asleep"

//STASIS
/datum/status_effect/grouped/hard_stasis
	id = "stasis"
	duration = -1
	alert_type = /atom/movable/screen/alert/status_effect/stasis
	var/last_dead_time

/datum/status_effect/grouped/hard_stasis/proc/update_time_of_death()
	if(last_dead_time)
		var/delta = world.time - last_dead_time
		var/new_timeofdeath = owner.timeofdeath + delta
		owner.timeofdeath = new_timeofdeath
		owner.timeofdeath_as_ingame = stationtime2text(reference_time=new_timeofdeath)
		last_dead_time = null
	if(owner.stat == DEAD)
		last_dead_time = world.time

/datum/status_effect/grouped/hard_stasis/on_creation(mob/living/new_owner, set_duration)
	. = ..()
	if(.)
		update_time_of_death()
		owner.reagents?.end_metabolization(owner, FALSE)

/datum/status_effect/grouped/hard_stasis/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	owner.add_filter("stasis_status_ripple", 2, list("type" = "ripple", "flags" = WAVE_BOUNDED, "radius" = 0, "size" = 2))
	var/filter = owner.get_filter("stasis_status_ripple")
	animate(filter, radius = 32, time = 15, size = 0, loop = -1)
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.update_bodypart_bleed_overlays()

/datum/status_effect/grouped/hard_stasis/tick()
	update_time_of_death()

/datum/status_effect/grouped/hard_stasis/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	owner.remove_filter("stasis_status_ripple")
	update_time_of_death()
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.update_bodypart_bleed_overlays()
	return ..()

/atom/movable/screen/alert/status_effect/stasis
	name = "Stasis"
	desc = "Your biological functions have halted. You could live forever this way, but it's pretty boring."
	icon_state = "stasis"

/datum/status_effect/pacify
	id = "pacify"
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	duration = 100
	alert_type = null

/datum/status_effect/pacify/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/pacify/on_apply()
	ADD_TRAIT(owner, TRAIT_PACIFISM, STATUS_EFFECT_TRAIT)
	return ..()

/datum/status_effect/pacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, STATUS_EFFECT_TRAIT)

/datum/status_effect/his_wrath //does minor damage over time unless holding His Grace
	id = "his_wrath"
	duration = -1
	tick_interval = 4
	alert_type = /atom/movable/screen/alert/status_effect/his_wrath

/atom/movable/screen/alert/status_effect/his_wrath
	name = "His Wrath"
	desc = "You fled from His Grace instead of feeding Him, and now you suffer."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/datum/status_effect/his_wrath/tick()
	for(var/obj/item/his_grace/HG in owner.held_items)
		qdel(src)
		return
	owner.adjustBruteLoss(0.1)
	owner.adjustFireLoss(0.1)
	owner.adjustToxLoss(0.2, TRUE, TRUE, cause_of_death = "His wrath")

/datum/status_effect/cultghost //is a cult ghost and can't use manifest runes
	id = "cult_ghost"
	duration = -1
	alert_type = null

/datum/status_effect/cultghost/on_apply()
	owner.see_invisible = SEE_INVISIBLE_OBSERVER
	owner.see_in_dark = 2

/datum/status_effect/cultghost/tick()
	if(owner.reagents)
		owner.reagents.del_reagent(/datum/reagent/water/holywater) //can't be deconverted

/datum/status_effect/eldritch
	id = "heretic_mark"
	duration = 15 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	on_remove_on_mob_delete = TRUE
	///underlay used to indicate that someone is marked
	var/mutable_appearance/marked_underlay
	/// icon file for the underlay
	var/effect_icon = 'icons/effects/eldritch.dmi'
	/// icon state for the underlay
	var/effect_icon_state = ""

/datum/status_effect/eldritch/on_creation(mob/living/new_owner, ...)
	marked_underlay = mutable_appearance(effect_icon, effect_icon_state, BELOW_MOB_LAYER)
	return ..()

/datum/status_effect/eldritch/Destroy()
	QDEL_NULL(marked_underlay)
	return ..()

/datum/status_effect/eldritch/on_apply()
	if(owner.mob_size >= MOB_SIZE_HUMAN || ishuman(owner)) // This is horrible but I can't see a better way to do it
		RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_owner_underlay))
		owner.update_icon(UPDATE_OVERLAYS)
		return TRUE
	return FALSE

/datum/status_effect/eldritch/on_remove()
	UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
	owner.update_icon(UPDATE_OVERLAYS)
	return ..()

/**
 * Signal proc for [COMSIG_ATOM_UPDATE_OVERLAYS].
 *
 * Adds the generated mark overlay to the afflicted.
 */
/datum/status_effect/eldritch/proc/update_owner_underlay(atom/source, list/overlays)
	SIGNAL_HANDLER

	overlays += marked_underlay

/**
 * Called when the mark is activated by the heretic.
 */
/datum/status_effect/eldritch/proc/on_effect()
	SHOULD_CALL_PARENT(TRUE)

	playsound(owner, 'sound/magic/repulse.ogg', 75, TRUE)
	qdel(src) //what happens when this is procced.

//Each mark has diffrent effects when it is destroyed that combine with the mansus grasp effect.
/datum/status_effect/eldritch/flesh
	effect_icon_state = "emark1"

/datum/status_effect/eldritch/flesh/on_effect()
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		var/obj/item/bodypart/bodypart = pick(human_owner.bodyparts)
		bodypart.receive_damage(40, sharpness = (SHARP_EDGED|SHARP_POINTY))

	return ..()

/datum/status_effect/eldritch/ash
	effect_icon_state = "emark2"
	/// Dictates how much stamina and burn damage the mark will cause on trigger.
	var/repetitions = 1

/datum/status_effect/eldritch/ash/on_creation(mob/living/new_owner, repetition = 5)
	. = ..()
	src.repetitions = max(1, repetition)

/datum/status_effect/eldritch/ash/on_effect()
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.stamina.adjust(-6 * repetitions) // first one = 30 stam
		carbon_owner.adjustFireLoss(3 * repetitions) // first one = 15 burn
		for(var/mob/living/carbon/victim in shuffle(range(1, carbon_owner)))
			if(IS_HERETIC(victim) || victim == carbon_owner)
				continue
			victim.apply_status_effect(type, repetitions - 1)
			break

	return ..()

/datum/status_effect/eldritch/rust
	effect_icon_state = "emark3"

/datum/status_effect/eldritch/rust/on_effect()
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		var/static/list/organs_to_damage = list(
			ORGAN_SLOT_BRAIN,
			ORGAN_SLOT_EARS,
			ORGAN_SLOT_EYES,
			ORGAN_SLOT_LIVER,
			ORGAN_SLOT_LUNGS,
			ORGAN_SLOT_STOMACH,
			ORGAN_SLOT_HEART,
		)

		// Roughly 75% of their organs will take a bit of damage
		for(var/organ_slot in organs_to_damage)
			if(prob(75))
				carbon_owner.adjustOrganLoss(organ_slot, 20)

		// And roughly 75% of their items will take a smack, too
		for(var/obj/item/thing in carbon_owner.get_all_gear())
			if(!QDELETED(thing) && prob(75))
				thing.take_damage(100)

	return ..()

/datum/status_effect/eldritch/void
	effect_icon_state = "emark4"

/datum/status_effect/eldritch/void/on_effect()
	var/turf/open/our_turf = get_turf(owner)
	our_turf.TakeTemperature(-40)
	owner.adjust_bodytemperature(-20)

	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.silent += 5

	return ..()

/datum/status_effect/eldritch/blade
	effect_icon_state = "emark5"
	/// If set, the owner of the status effect will not be able to leave this area.
	var/area/locked_to

/datum/status_effect/eldritch/blade/Destroy()
	locked_to = null
	return ..()

/datum/status_effect/eldritch/blade/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_MOVABLE_TELEPORTED, PROC_REF(on_teleport))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))

/datum/status_effect/eldritch/blade/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOVABLE_TELEPORTED, COMSIG_MOVABLE_MOVED))
	return ..()

/// Signal proc for [COMSIG_MOVABLE_TELEPORTED] that blocks any teleports from our locked area
/datum/status_effect/eldritch/blade/proc/on_teleport(mob/living/source, atom/destination, channel)
	SIGNAL_HANDLER

	if(!locked_to)
		return

	if(get_area(destination) == locked_to)
		return

	to_chat(source, span_hypnophrase("An otherworldly force prevents your escape from [get_area_name(locked_to)]!"))

	source.Stun(1 SECONDS)
	return COMPONENT_BLOCK_TELEPORT

/// Signal proc for [COMSIG_MOVABLE_MOVED] that blocks any movement out of our locked area
/datum/status_effect/eldritch/blade/proc/on_move(mob/living/source, turf/old_loc, movement_dir, forced)
	SIGNAL_HANDLER

	if(!locked_to)
		return

	if(get_area(source) == locked_to)
		return

	to_chat(source, span_hypnophrase("An otherworldly force prevents your escape from [get_area_name(locked_to)]!"))

	source.Stun(1 SECONDS)
	source.throw_at(old_loc, 5, 1)

/datum/status_effect/stacking/saw_bleed
	id = "saw_bleed"

	tick_interval = 0.6 SECONDS

	stack_decay = 1
	delay_before_decay = 5
	stack_threshold = 10
	max_stacks = 10

	consumed_on_threshold = TRUE

	overlay_file = 'icons/effects/bleed.dmi'
	overlay_state = "bleed"
	var/bleed_damage = 200

/datum/status_effect/stacking/saw_bleed/fadeout_effect()
	new /obj/effect/temp_visual/bleed(get_turf(owner))

/datum/status_effect/stacking/saw_bleed/threshold_cross_effect()
	owner.adjustBruteLoss(bleed_damage)
	var/turf/T = get_turf(owner)
	new /obj/effect/temp_visual/bleed/explode(T)
	for(var/d in GLOB.alldirs)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, d)
	playsound(T, SFX_DESECRATION, 100, TRUE, -1)

/// Return FALSE if the owner is not in a valid state (self-deletes the effect), or TRUE otherwise
/datum/status_effect/stacking/saw_bleed/can_have_status()
	return owner.stat != DEAD

/// Whether the owner can currently gain stacks or not
/// Return FALSE if the owner is not in a valid state, or TRUE otherwise
/datum/status_effect/stacking/saw_bleed/can_gain_stacks()
	return owner.stat != DEAD

/datum/status_effect/stacking/saw_bleed/bloodletting
	id = "bloodletting"
	stack_threshold = 7
	max_stacks = 7
	bleed_damage = 20

/datum/status_effect/neck_slice
	id = "neck_slice"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	duration = -1

/datum/status_effect/neck_slice/tick()

	var/mob/living/carbon/human/H = owner
	var/obj/item/bodypart/throat = H.get_bodypart(BODY_ZONE_HEAD)
	if(H.stat == DEAD || !throat)
		H.remove_status_effect(/datum/status_effect/neck_slice)

	var/still_bleeding = FALSE
	for(var/datum/wound/cut/W in throat.wounds)
		if(W.current_stage > 3)
			still_bleeding = TRUE
			break

	if(!still_bleeding)
		H.remove_status_effect(/datum/status_effect/neck_slice)

	if(prob(10))
		H.emote(pick(/datum/emote/living/carbon/gasp_air, "gag", "choke"))

/mob/living/proc/apply_necropolis_curse(set_curse)
	var/datum/status_effect/necropolis_curse/C = has_status_effect(/datum/status_effect/necropolis_curse)
	if(!set_curse)
		set_curse = pick(CURSE_BLINDING, CURSE_SPAWNING, CURSE_WASTING, CURSE_GRASPING)
	if(QDELETED(C))
		apply_status_effect(/datum/status_effect/necropolis_curse, set_curse)
	else
		C.apply_curse(set_curse)
		C.duration += 3000 //time added by additional curses
	return C

/datum/status_effect/necropolis_curse
	id = "necrocurse"
	duration = 6000 //you're cursed for 10 minutes have fun
	tick_interval = 50
	alert_type = null
	var/curse_flags = NONE
	var/effect_last_activation = 0
	var/effect_cooldown = 100
	var/obj/effect/temp_visual/curse/wasting_effect = new

/datum/status_effect/necropolis_curse/on_creation(mob/living/new_owner, set_curse)
	. = ..()
	if(.)
		apply_curse(set_curse)

/datum/status_effect/necropolis_curse/Destroy()
	if(!QDELETED(wasting_effect))
		qdel(wasting_effect)
		wasting_effect = null
	return ..()

/datum/status_effect/necropolis_curse/on_remove()
	remove_curse(curse_flags)

/datum/status_effect/necropolis_curse/proc/apply_curse(set_curse)
	curse_flags |= set_curse
	if(curse_flags & CURSE_BLINDING)
		owner.overlay_fullscreen("curse", /atom/movable/screen/fullscreen/curse, 1)

/datum/status_effect/necropolis_curse/proc/remove_curse(remove_curse)
	if(remove_curse & CURSE_BLINDING)
		owner.clear_fullscreen("curse", 50)
	curse_flags &= ~remove_curse

/datum/status_effect/necropolis_curse/tick()
	if(owner.stat == DEAD)
		return
	if(curse_flags & CURSE_WASTING)
		wasting_effect.forceMove(owner.loc)
		wasting_effect.setDir(owner.dir)
		wasting_effect.transform = owner.transform //if the owner has been stunned the overlay should inherit that position
		wasting_effect.alpha = 255
		animate(wasting_effect, alpha = 0, time = 32)
		playsound(owner, 'sound/effects/curse5.ogg', 20, TRUE, -1)
		owner.adjustFireLoss(0.75)
	if(effect_last_activation <= world.time)
		effect_last_activation = world.time + effect_cooldown
		if(curse_flags & CURSE_SPAWNING)
			var/turf/spawn_turf
			var/sanity = 10
			while(!spawn_turf && sanity)
				spawn_turf = locate(owner.x + pick(rand(10, 15), rand(-10, -15)), owner.y + pick(rand(10, 15), rand(-10, -15)), owner.z)
				sanity--
			if(spawn_turf)
				var/mob/living/simple_animal/hostile/asteroid/curseblob/C = new (spawn_turf)
				C.set_target = owner
				C.GiveTarget()
		if(curse_flags & CURSE_GRASPING)
			var/grab_dir = turn(owner.dir, pick(-90, 90, 180, 180)) //grab them from a random direction other than the one faced, favoring grabbing from behind
			var/turf/spawn_turf = get_ranged_target_turf(owner, grab_dir, 5)
			if(spawn_turf)
				grasp(spawn_turf)

/datum/status_effect/necropolis_curse/proc/grasp(turf/spawn_turf)
	set waitfor = FALSE
	new/obj/effect/temp_visual/dir_setting/curse/grasp_portal(spawn_turf, owner.dir)
	playsound(spawn_turf, 'sound/effects/curse2.ogg', 80, TRUE, -1)
	var/obj/projectile/curse_hand/C = new (spawn_turf)
	C.preparePixelProjectile(owner, spawn_turf)
	C.fire()

/obj/effect/temp_visual/curse
	icon_state = "curse"

/obj/effect/temp_visual/curse/Initialize(mapload)
	. = ..()
	deltimer(timerid)


/datum/status_effect/gonbola_pacify
	id = "gonbolaPacify"
	status_type = STATUS_EFFECT_MULTIPLE
	tick_interval = -1
	alert_type = null

/datum/status_effect/gonbola_pacify/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_PACIFISM, CLOTHING_TRAIT)
	ADD_TRAIT(owner, TRAIT_MUTE, CLOTHING_TRAIT)
	to_chat(owner, span_notice("You suddenly feel at peace and feel no need to make any sudden or rash actions..."))

/datum/status_effect/gonbola_pacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, CLOTHING_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_MUTE, CLOTHING_TRAIT)
	return ..()

/datum/status_effect/trance
	id = "trance"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 300
	tick_interval = 10
	var/stun = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/trance

/atom/movable/screen/alert/status_effect/trance
	name = "Trance"
	desc = "Everything feels so distant, and you can feel your thoughts forming loops inside your head..."
	icon_state = "high"

/datum/status_effect/trance/tick()
	if(stun)
		owner.Stun(6 SECONDS, TRUE)
	owner.set_timed_status_effect(40 SECONDS, /datum/status_effect/dizziness)

/datum/status_effect/trance/on_apply()
	if(!iscarbon(owner))
		return FALSE
	RegisterSignal(owner, COMSIG_MOVABLE_HEAR, PROC_REF(hypnotize))
	ADD_TRAIT(owner, TRAIT_MUTE, STATUS_EFFECT_TRAIT)
	owner.add_client_colour(/datum/client_colour/monochrome/trance)
	owner.visible_message("[stun ? span_warning("[owner] stands still as [owner.p_their()] eyes seem to focus on a distant point.") : ""]", \
	span_warning(pick("You feel your thoughts slow down...", "You suddenly feel extremely dizzy...", "You feel like you're in the middle of a dream...","You feel incredibly relaxed...")))
	return TRUE

/datum/status_effect/trance/on_creation(mob/living/new_owner, _duration, _stun = TRUE)
	duration = _duration
	stun = _stun
	return ..()

/datum/status_effect/trance/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)
	REMOVE_TRAIT(owner, TRAIT_MUTE, STATUS_EFFECT_TRAIT)
	owner.remove_status_effect(/datum/status_effect/dizziness)
	owner.remove_client_colour(/datum/client_colour/monochrome/trance)
	to_chat(owner, span_warning("You snap out of your trance!"))

/datum/status_effect/trance/get_examine_text()
	return span_warning("[owner.p_they(TRUE)] seem[owner.p_s()] slow and unfocused.")

/datum/status_effect/trance/proc/hypnotize(datum/source, list/hearing_args)
	SIGNAL_HANDLER

	var/datum/language/L = hearing_args[HEARING_LANGUAGE]
	if(!L?.can_receive_language(owner) || !owner.has_language(L))
		return

	var/mob/hearing_speaker = hearing_args[HEARING_SPEAKER]
	if(hearing_speaker == owner)
		return
	var/mob/living/carbon/C = owner
	C.cure_trauma_type(/datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY) //clear previous hypnosis
	// The brain trauma itself does its own set of logging, but this is the only place the source of the hypnosis phrase can be found.
	hearing_speaker.log_message("has hypnotised [key_name(C)] with the phrase '[hearing_args[HEARING_RAW_MESSAGE]]'", LOG_ATTACK)
	C.log_message("has been hypnotised by the phrase '[hearing_args[HEARING_RAW_MESSAGE]]' spoken by [key_name(hearing_speaker)]", LOG_VICTIM, log_globally = FALSE)
	addtimer(CALLBACK(C, TYPE_PROC_REF(/mob/living/carbon, gain_trauma), /datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY, hearing_args[HEARING_RAW_MESSAGE]), 10)
	addtimer(CALLBACK(C, TYPE_PROC_REF(/mob/living, Stun), 60, TRUE, TRUE), 15) //Take some time to think about it
	qdel(src)

/datum/status_effect/spasms
	id = "spasms"
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null

/datum/status_effect/spasms/tick()
	if(owner.stat >= UNCONSCIOUS)
		return
	if(!prob(15))
		return
	switch(rand(1,5))
		if(1)
			if((owner.mobility_flags & MOBILITY_MOVE) && isturf(owner.loc))
				to_chat(owner, span_warning("Your leg spasms!"))
				step(owner, pick(GLOB.cardinals))
		if(2)
			if(owner.incapacitated())
				return
			var/obj/item/held_item = owner.get_active_held_item()
			if(!held_item)
				return
			to_chat(owner, span_warning("Your fingers spasm!"))
			owner.log_message("used [held_item] due to a Muscle Spasm", LOG_ATTACK)
			held_item.attack_self(owner)
		if(3)
			owner.set_combat_mode(TRUE)

			var/range = 1
			if(istype(owner.get_active_held_item(), /obj/item/gun)) //get targets to shoot at
				range = 7

			var/list/mob/living/targets = list()
			for(var/mob/living/nearby_mobs in oview(owner, range))
				targets += nearby_mobs
			if(LAZYLEN(targets))
				to_chat(owner, span_warning("Your arm spasms!"))
				owner.log_message(" attacked someone due to a Muscle Spasm", LOG_ATTACK) //the following attack will log itself
				owner.ClickOn(pick(targets))
			owner.set_combat_mode(FALSE)
		if(4)
			owner.set_combat_mode(TRUE)
			to_chat(owner, span_warning("Your arm spasms!"))
			owner.log_message("attacked [owner.p_them()]self to a Muscle Spasm", LOG_ATTACK)
			owner.ClickOn(owner)
			owner.set_combat_mode(FALSE)
		if(5)
			if(owner.incapacitated())
				return
			var/obj/item/held_item = owner.get_active_held_item()
			var/list/turf/targets = list()
			for(var/turf/nearby_turfs in oview(owner, 3))
				targets += nearby_turfs
			if(LAZYLEN(targets) && held_item)
				to_chat(owner, span_warning("Your arm spasms!"))
				owner.log_message("threw [held_item] due to a Muscle Spasm", LOG_ATTACK)
				owner.throw_item(pick(targets))

/datum/status_effect/convulsing
	id = "convulsing"
	duration = 150
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/convulsing

/datum/status_effect/convulsing/on_creation(mob/living/zappy_boy)
	. = ..()
	to_chat(zappy_boy, span_boldwarning("You feel a shock moving through your body! Your hands start shaking!"))

/datum/status_effect/convulsing/tick()
	var/mob/living/carbon/H = owner
	if(prob(40))
		var/obj/item/I = H.get_active_held_item()
		if(I && H.dropItemToGround(I))
			H.visible_message(
				span_notice("[H]'s hand convulses, and they drop their [I.name]!"),
				span_userdanger("Your hand convulses violently, and you drop what you were holding!"),
			)
			H.adjust_timed_status_effect(10 SECONDS, /datum/status_effect/jitter)

/atom/movable/screen/alert/status_effect/convulsing
	name = "Shaky Hands"
	desc = "You've been zapped with something and your hands can't stop shaking! You can't seem to hold on to anything."
	icon_state = "convulsing"

/datum/status_effect/dna_melt
	id = "dna_melt"
	duration = 600
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/dna_melt
	var/kill_either_way = FALSE //no amount of removing mutations is gonna save you now

/datum/status_effect/dna_melt/on_creation(mob/living/new_owner, set_duration)
	. = ..()
	to_chat(new_owner, span_boldwarning("My body can't handle the mutations! I need to get my mutations removed fast!"))

/datum/status_effect/dna_melt/on_remove()
	if(!ishuman(owner))
		owner.gib() //fuck you in particular
		return
	var/mob/living/carbon/human/H = owner
	H.something_horrible(kill_either_way)

/atom/movable/screen/alert/status_effect/dna_melt
	name = "Genetic Breakdown"
	desc = "I don't feel so good. Your body can't handle the mutations! You have one minute to remove your mutations, or you will be met with a horrible fate."
	icon_state = "dna_melt"

/datum/status_effect/go_away
	id = "go_away"
	duration = 100
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	alert_type = /atom/movable/screen/alert/status_effect/go_away
	var/direction

/datum/status_effect/go_away/on_creation(mob/living/new_owner, set_duration)
	. = ..()
	direction = pick(NORTH, SOUTH, EAST, WEST)
	new_owner.setDir(direction)

/datum/status_effect/go_away/tick()
	owner.AdjustStun(1, ignore_canstun = TRUE)
	var/turf/T = get_step(owner, direction)
	owner.forceMove(T)

/atom/movable/screen/alert/status_effect/go_away
	name = "TO THE STARS AND BEYOND!"
	desc = "I must go, my people need me!"
	icon_state = "high"

/datum/status_effect/fake_virus
	id = "fake_virus"
	duration = 1800//3 minutes
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	alert_type = null
	var/msg_stage = 0//so you dont get the most intense messages immediately

/datum/status_effect/fake_virus/tick()
	var/fake_msg = ""
	var/fake_emote = ""
	switch(msg_stage)
		if(0 to 300)
			if(prob(1))
				fake_msg = pick(
				span_warning(pick("Your head hurts.", "Your head pounds.")),
				span_warning(pick("You're having difficulty breathing.", "Your breathing becomes heavy.")),
				span_warning(pick("You feel dizzy.", "Your head spins.")),
				span_warning(pick("You swallow excess mucus.", "You lightly cough.")),
				span_warning(pick("Your head hurts.", "Your mind blanks for a moment.")),
				span_warning(pick("Your throat hurts.", "You clear your throat.")))
		if(301 to 600)
			if(prob(2))
				fake_msg = pick(
				span_warning(pick("Your head hurts a lot.", "Your head pounds incessantly.")),
				span_warning(pick("Your windpipe feels like a straw.", "Your breathing becomes tremendously difficult.")),
				span_warning("You feel very [pick("dizzy","woozy","faint")]."),
				span_warning(pick("You hear a ringing in your ear.", "Your ears pop.")),
				span_warning("You nod off for a moment."))
		else
			if(prob(3))
				if(prob(50))// coin flip to throw a message or an emote
					fake_msg = pick(
					span_userdanger(pick("Your head hurts!", "You feel a burning knife inside your brain!", "A wave of pain fills your head!")),
					span_userdanger(pick("Your lungs hurt!", "It hurts to breathe!")),
					span_warning(pick("You feel nauseated.", "You feel like you're going to throw up!")))
				else
					fake_emote = pick("cough", "sniff", "sneeze")

	if(fake_emote)
		owner.emote(fake_emote)
	else if(fake_msg)
		to_chat(owner, fake_msg)

	msg_stage++

/datum/status_effect/corrosion_curse
	id = "corrosion_curse"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	tick_interval = 1 SECONDS

/datum/status_effect/corrosion_curse/on_creation(mob/living/new_owner, ...)
	. = ..()
	to_chat(owner, span_userdanger("Your body starts to break apart!"))

/datum/status_effect/corrosion_curse/tick()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/human_owner = owner
	var/chance = rand(0, 100)
	switch(chance)
		if(0 to 10)
			human_owner.vomit()
		if(20 to 30)
			human_owner.set_timed_status_effect(100 SECONDS, /datum/status_effect/dizziness, only_if_higher = TRUE)
			human_owner.set_timed_status_effect(100 SECONDS, /datum/status_effect/jitter, only_if_higher = TRUE)
		if(30 to 40)
			human_owner.adjustOrganLoss(ORGAN_SLOT_LIVER, 5)
		if(40 to 50)
			human_owner.adjustOrganLoss(ORGAN_SLOT_HEART, 5, 90)
		if(50 to 60)
			human_owner.adjustOrganLoss(ORGAN_SLOT_STOMACH, 5)
		if(60 to 70)
			human_owner.adjustOrganLoss(ORGAN_SLOT_EYES, 10)
		if(70 to 80)
			human_owner.adjustOrganLoss(ORGAN_SLOT_EARS, 10)
		if(80 to 90)
			human_owner.adjustOrganLoss(ORGAN_SLOT_LUNGS, 10)
		if(90 to 95)
			human_owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 20, 190)
		if(95 to 100)
			human_owner.adjust_timed_status_effect(12 SECONDS, /datum/status_effect/confusion)

/datum/status_effect/amok
	id = "amok"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	duration = 10 SECONDS
	tick_interval = 1 SECONDS

/datum/status_effect/amok/on_apply(mob/living/afflicted)
	. = ..()
	to_chat(owner, span_boldwarning("You feel filled with a rage that is not your own!"))

/datum/status_effect/amok/tick()
	. = ..()
	var/prev_combat_mode = owner.combat_mode
	owner.set_combat_mode(TRUE)

	var/list/mob/living/targets = list()
	for(var/mob/living/potential_target in oview(owner, 1))
		if(IS_HERETIC_OR_MONSTER(potential_target))
			continue
		targets += potential_target
	if(LAZYLEN(targets))
		owner.log_message(" attacked someone due to the amok debuff.", LOG_ATTACK) //the following attack will log itself
		owner.ClickOn(pick(targets))
	owner.set_combat_mode(prev_combat_mode)

/datum/status_effect/cloudstruck
	id = "cloudstruck"
	status_type = STATUS_EFFECT_REPLACE
	duration = 3 SECONDS
	on_remove_on_mob_delete = TRUE
	///This overlay is applied to the owner for the duration of the effect.
	var/mutable_appearance/mob_overlay

/datum/status_effect/cloudstruck/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/cloudstruck/on_apply()
	mob_overlay = mutable_appearance('icons/effects/eldritch.dmi', "cloud_swirl", ABOVE_MOB_LAYER)
	owner.overlays += mob_overlay
	owner.update_appearance()
	ADD_TRAIT(owner, TRAIT_BLIND, STATUS_EFFECT_TRAIT)
	return TRUE

/datum/status_effect/cloudstruck/on_remove()
	. = ..()
	if(QDELETED(owner))
		return
	REMOVE_TRAIT(owner, TRAIT_BLIND, STATUS_EFFECT_TRAIT)
	if(owner)
		owner.overlays -= mob_overlay
		owner.update_appearance()

/datum/status_effect/cloudstruck/Destroy()
	. = ..()
	QDEL_NULL(mob_overlay)

//Deals with ants covering someone.
/datum/status_effect/ants
	id = "ants"
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/ants
	duration = 2 MINUTES //Keeping the normal timer makes sure people can't somehow dump 300+ ants on someone at once so they stay there for like 30 minutes. Max w/ 1 dump is 57.6 brute.
	processing_speed = STATUS_EFFECT_NORMAL_PROCESS
	/// Will act as the main timer as well as changing how much damage the ants do.
	var/ants_remaining = 0
	/// Common phrases people covered in ants scream
	var/static/list/ant_debuff_speech = list(
		"GET THEM OFF ME!!",
		"OH GOD THE ANTS!!",
		"MAKE IT END!!",
		"THEY'RE EVERYWHERE!!",
		"GET THEM OFF!!",
		"SOMEBODY HELP ME!!"
	)

/datum/status_effect/ants/on_creation(mob/living/new_owner, amount_left)
	if(isnum(amount_left) && new_owner.stat < DEAD)
		if(new_owner.stat < UNCONSCIOUS) // Unconcious people won't get messages
			to_chat(new_owner, span_userdanger("You're covered in ants!"))
		ants_remaining += amount_left
		RegisterSignal(new_owner, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(ants_washed))
	. = ..()

/datum/status_effect/ants/refresh(effect, amount_left)
	var/mob/living/carbon/human/victim = owner
	if(isnum(amount_left) && ants_remaining >= 1 && victim.stat < DEAD)
		if(victim.stat < UNCONSCIOUS) // Unconcious people won't get messages
			if(!prob(1)) // 99%
				to_chat(victim, span_userdanger("You're covered in MORE ants!"))
			else // 1%
				victim.say("AAHH! THIS SITUATION HAS ONLY BEEN MADE WORSE WITH THE ADDITION OF YET MORE ANTS!!", forced = /datum/status_effect/ants)
		ants_remaining += amount_left
	. = ..()

/datum/status_effect/ants/on_remove()
	ants_remaining = 0
	to_chat(owner, span_notice("All of the ants are off of your body!"))
	UnregisterSignal(owner, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(ants_washed))
	. = ..()

/datum/status_effect/ants/proc/ants_washed()
	SIGNAL_HANDLER
	owner.remove_status_effect(/datum/status_effect/ants)
	return COMPONENT_CLEANED

/datum/status_effect/ants/get_examine_text()
	return span_warning("[owner.p_they(TRUE)] [owner.p_are()] covered in ants!")

/datum/status_effect/ants/tick()
	var/mob/living/carbon/human/victim = owner
	victim.adjustBruteLoss(max(0.1, round((ants_remaining * 0.004),0.1))) //Scales with # of ants (lowers with time). Roughly 10 brute over 50 seconds.
	if(victim.stat != CONSCIOUS && !HAS_TRAIT(victim, TRAIT_SOFT_CRITICAL_CONDITION)) //Makes sure people don't scratch at themselves while they're in a critical condition
		if(prob(15))
			switch(rand(1,2))
				if(1)
					victim.say(pick(ant_debuff_speech), forced = /datum/status_effect/ants)
				if(2)
					victim.emote("scream")
		if(prob(50)) // Most of the damage is done through random chance. When tested yielded an average 100 brute with 200u ants.
			switch(rand(1,50))
				if (1 to 8) //16% Chance
					var/obj/item/bodypart/head/hed = victim.get_bodypart(BODY_ZONE_HEAD)
					to_chat(victim, span_danger("You scratch at the ants on your scalp!."))
					hed.receive_damage(1,0)
				if (9 to 29) //40% chance
					var/obj/item/bodypart/arm = victim.get_bodypart(pick(BODY_ZONE_L_ARM,BODY_ZONE_R_ARM))
					to_chat(victim, span_danger("You scratch at the ants on your arms!"))
					arm.receive_damage(3,0)
				if (30 to 49) //38% chance
					var/obj/item/bodypart/leg = victim.get_bodypart(pick(BODY_ZONE_L_LEG,BODY_ZONE_R_LEG))
					to_chat(victim, span_danger("You scratch at the ants on your leg!"))
					leg.receive_damage(3,0)
				if(50) // 2% chance
					to_chat(victim, span_danger("You rub some ants away from your eyes!"))
					victim.blur_eyes(3)
					ants_remaining -= 5 // To balance out the blindness, it'll be a little shorter.
	ants_remaining--
	if(ants_remaining <= 0 || victim.stat == DEAD)
		victim.remove_status_effect(/datum/status_effect/ants) //If this person has no more ants on them or are dead, they are no longer affected.

/atom/movable/screen/alert/status_effect/ants
	name = "Ants!"
	desc = span_warning("JESUS FUCKING CHRIST! CLICK TO GET THOSE THINGS OFF!")
	icon_state = "antalert"

/atom/movable/screen/alert/status_effect/ants/Click()
	. = ..()
	if(.)
		return FALSE
	var/mob/living/living = owner
	if(!istype(living) || !living.can_resist())
		return
	to_chat(living, span_notice("You start to shake the ants off!"))
	if(!do_after(living, time = 2 SECONDS))
		return
	for (var/datum/status_effect/ants/ant_covered in living.status_effects)
		to_chat(living, span_notice("You manage to get some of the ants off!"))
		ant_covered.ants_remaining -= 10 // 5 Times more ants removed per second than just waiting in place

/datum/status_effect/ghoul
	id = "ghoul"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = /atom/movable/screen/alert/status_effect/ghoul
	/// The new max health value set for the ghoul, if supplied
	var/new_max_health
	/// Reference to the master of the ghoul's mind
	var/datum/mind/master_mind
	/// An optional callback invoked when a ghoul is made (on_apply)
	var/datum/callback/on_made_callback
	/// An optional callback invoked when a goul is unghouled (on_removed)
	var/datum/callback/on_lost_callback

/datum/status_effect/ghoul/Destroy()
	master_mind = null
	QDEL_NULL(on_made_callback)
	QDEL_NULL(on_lost_callback)
	return ..()

/datum/status_effect/ghoul/on_creation(
	mob/living/new_owner,
	new_max_health,
	datum/mind/master_mind,
	datum/callback/on_made_callback,
	datum/callback/on_lost_callback,
)

	src.new_max_health = new_max_health
	src.master_mind = master_mind
	src.on_made_callback = on_made_callback
	src.on_lost_callback = on_lost_callback

	. = ..()

	if(master_mind)
		linked_alert.desc += " You are an eldritch monster reanimated to serve its master, [master_mind]."
	if(isnum(new_max_health))
		if(new_max_health > initial(new_owner.maxHealth))
			linked_alert.desc += " You are stronger in this form."
		else
			linked_alert.desc += " You are more fragile in this form."

/datum/status_effect/ghoul/on_apply()
	if(!ishuman(owner))
		return FALSE

	var/mob/living/carbon/human/human_target = owner

	RegisterSignal(human_target, COMSIG_LIVING_DEATH, PROC_REF(remove_ghoul_status))
	human_target.revive(full_heal = TRUE, admin_revive = TRUE)

	if(new_max_health)
		human_target.setMaxHealth(new_max_health)
		human_target.health = new_max_health

	on_made_callback?.Invoke(human_target)
	human_target.become_husk(MAGIC_TRAIT)
	human_target.faction |= FACTION_HERETIC

	if(human_target.mind)
		var/datum/antagonist/heretic_monster/heretic_monster = human_target.mind.add_antag_datum(/datum/antagonist/heretic_monster)
		heretic_monster.set_owner(master_mind)

	return TRUE

/datum/status_effect/ghoul/on_remove()
	remove_ghoul_status()
	return ..()

/// Removes the ghoul effects from our owner and returns them to normal.
/datum/status_effect/ghoul/proc/remove_ghoul_status(datum/source)
	SIGNAL_HANDLER

	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/human_target = owner

	if(new_max_health)
		human_target.setMaxHealth(initial(human_target.maxHealth))

	on_lost_callback?.Invoke(human_target)
	human_target.cure_husk(MAGIC_TRAIT)
	human_target.faction -= FACTION_HERETIC
	human_target.mind?.remove_antag_datum(/datum/antagonist/heretic_monster)

	UnregisterSignal(human_target, COMSIG_LIVING_DEATH)
	if(!QDELETED(src))
		qdel(src)

/atom/movable/screen/alert/status_effect/ghoul
	name = "Flesh Servant"
	desc = "You are a Ghoul!"
	icon_state = ALERT_MIND_CONTROL


/datum/status_effect/stagger
	id = "stagger"
	status_type = STATUS_EFFECT_REFRESH
	duration = 30 SECONDS
	tick_interval = 1 SECONDS
	alert_type = null

/datum/status_effect/stagger/on_apply()
	owner.next_move_modifier *= 1.5
	if(ishostile(owner))
		var/mob/living/simple_animal/hostile/simple_owner = owner
		simple_owner.ranged_cooldown_time *= 2.5
	return TRUE

/datum/status_effect/stagger/on_remove()
	. = ..()
	if(QDELETED(owner))
		return
	owner.next_move_modifier /= 1.5
	if(ishostile(owner))
		var/mob/living/simple_animal/hostile/simple_owner = owner
		simple_owner.ranged_cooldown_time /= 2.5

/datum/status_effect/freezing_blast
	id = "freezing_blast"
	alert_type = /atom/movable/screen/alert/status_effect/freezing_blast
	duration = 5 SECONDS
	status_type = STATUS_EFFECT_REPLACE

/atom/movable/screen/alert/status_effect/freezing_blast
	name = "Freezing Blast"
	desc = "You've been struck by a freezing blast! Your body moves more slowly!"
	icon_state = "frozen"

/datum/status_effect/freezing_blast/on_apply()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/freezing_blast, update = TRUE)
	return ..()

/datum/status_effect/freezing_blast/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/freezing_blast, update = TRUE)

/datum/movespeed_modifier/freezing_blast
	slowdown = 1

/datum/status_effect/discoordinated
	id = "discoordinated"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/discoordinated

/atom/movable/screen/alert/status_effect/discoordinated
	name = "Discoordinated"
	desc = "You can't seem to properly use anything..."
	icon_state = "convulsing"

/datum/status_effect/discoordinated/on_apply()
	ADD_TRAIT(owner, TRAIT_DISCOORDINATED_TOOL_USER, "[type]")
	return ..()

/datum/status_effect/discoordinated/on_remove()
	REMOVE_TRAIT(owner, TRAIT_DISCOORDINATED_TOOL_USER, "[type]")
	return ..()

/// Applied to monkeys to make them attack slower.
/datum/status_effect/monkey_retardation
	id = "monkey_retardation"
	alert_type = null
	duration = -1
	status_type = STATUS_EFFECT_UNIQUE

/datum/status_effect/monkey_retardation/nextmove_modifier()
	return 2

