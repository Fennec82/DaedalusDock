/**Choking
 * Very very noticable.
 * Lowers resistance
 * Decreases stage speed
 * Greatly decreases transmissibility
 * Moderate Level.
 * Bonus: Inflicts spikes of oxyloss
 */

/datum/symptom/choking
	name = "Choking"
	desc = "The virus causes inflammation of the host's air conduits, leading to intermittent choking."
	stealth = -3
	resistance = -2
	stage_speed = -2
	transmittable = -2
	level = 3
	severity = 3
	base_message_chance = 15
	symptom_delay_min = 10
	symptom_delay_max = 30
	threshold_descs = list(
		"Stage Speed 8" = "Causes choking more frequently.",
		"Stealth 4" = "The symptom remains hidden until active."
	)

/datum/symptom/choking/sync_properties(list/properties)
	. = ..()
	if(!.)
		return
	if(properties[PATHOGEN_PROP_STAGE_RATE] >= 8)
		symptom_delay_min = 7
		symptom_delay_max = 24
	if(properties[PATHOGEN_PROP_STEALTH] >= 4)
		suppress_warning = TRUE

/datum/symptom/choking/on_process(datum/pathogen/advance/A)
	. = ..()
	if(!.)
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(1, 2)
			if(prob(base_message_chance) && !suppress_warning)
				to_chat(M, span_warning("[pick("You're having difficulty breathing.", "Your breathing becomes heavy.")]"))
		if(3, 4)
			if(!suppress_warning)
				to_chat(M, span_warning("[pick("Your windpipe feels like a straw.", "Your breathing becomes tremendously difficult.")]"))
			else
				to_chat(M, span_warning("You feel very [pick("dizzy","woozy","faint")].")) //fake bloodloss messages
			Choke_stage_3_4(M, A)
			M.emote(/datum/emote/living/carbon/gasp_air)
		else
			to_chat(M, span_userdanger("[pick("You're choking!", "You can't breathe!")]"))
			Choke(M, A)
			M.emote(/datum/emote/living/carbon/gasp_air)

/datum/symptom/choking/proc/Choke_stage_3_4(mob/living/M, datum/pathogen/advance/A)
	M.adjustOxyLoss(rand(6,13))
	return 1

/datum/symptom/choking/proc/Choke(mob/living/M, datum/pathogen/advance/A)
	M.adjustOxyLoss(rand(10,18))
	return 1

/*
//////////////////////////////////////

Asphyxiation

	Very very noticable.
	Decreases stage speed.
	Decreases transmittablity.

Bonus
	Inflicts large spikes of oxyloss
	Introduces Asphyxiating drugs to the system
	Causes cardiac arrest on dying victims.

//////////////////////////////////////
*/

/datum/symptom/asphyxiation

	name = "Acute respiratory distress syndrome"
	desc = "The virus causes shrinking of the host's lungs, causing severe asphyxiation. May also lead to heart attacks."
	stealth = -2
	resistance = -0
	stage_speed = -1
	transmittable = -2
	level = 7
	severity = 6
	base_message_chance = 15
	symptom_delay_min = 14
	symptom_delay_max = 30
	var/paralysis = FALSE
	threshold_descs = list(
		"Stage Speed 8" = "Additionally synthesizes pancuronium and sodium thiopental inside the host.",
		"Transmission 8" = "Doubles the damage caused by the symptom."
	)


/datum/symptom/asphyxiation/sync_properties(list/properties)
	. = ..()
	if(!.)
		return
	if(properties[PATHOGEN_PROP_STAGE_RATE] >= 8)
		paralysis = TRUE
	if(properties[PATHOGEN_PROP_TRANSMITTABLE] >= 8)
		power = 2

/datum/symptom/asphyxiation/on_process(datum/pathogen/advance/A)
	. = ..()
	if(!.)
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(3, 4)
			to_chat(M, span_warning("<b>[pick("Your windpipe feels thin.", "Your lungs feel small.")]"))
			Asphyxiate_stage_3_4(M, A)
			M.emote(/datum/emote/living/carbon/gasp_air)
		if(5)
			to_chat(M, span_userdanger("[pick("Your lungs hurt!", "It hurts to breathe!")]"))
			Asphyxiate(M, A)
			M.emote(/datum/emote/living/carbon/gasp_air)
			if(M.getOxyLoss() >= 120)
				M.visible_message(span_warning("[M] stops breathing, as if their lungs have totally collapsed!"))
				Asphyxiate_death(M, A)
	return

/datum/symptom/asphyxiation/proc/Asphyxiate_stage_3_4(mob/living/M, datum/pathogen/advance/A)
	var/get_damage = rand(10,15) * power
	M.adjustOxyLoss(get_damage)
	return 1

/datum/symptom/asphyxiation/proc/Asphyxiate(mob/living/M, datum/pathogen/advance/A)
	var/get_damage = rand(15,21) * power
	M.adjustOxyLoss(get_damage)
	if(paralysis)
		M.reagents.add_reagent_list(list(/datum/reagent/toxin/pancuronium = 3, /datum/reagent/toxin/sodium_thiopental = 3))
	return 1

/datum/symptom/asphyxiation/proc/Asphyxiate_death(mob/living/M, datum/pathogen/advance/A)
	var/get_damage = rand(25,35) * power
	M.adjustOxyLoss(get_damage)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, get_damage/2)
	return 1
