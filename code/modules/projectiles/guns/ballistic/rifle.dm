/obj/item/gun/ballistic/rifle
	name = "Bolt Rifle"
	desc = "Some kind of bolt action rifle. You get the feeling you shouldn't have this."
	icon_state = "moistnugget"
	w_class = WEIGHT_CLASS_BULKY
	inhand_icon_state = "moistnugget"
	worn_icon_state = "moistnugget"
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction
	bolt_wording = "bolt"
	bolt = /datum/gun_bolt/locking
	semi_auto = FALSE
	internal_magazine = TRUE
	fire_sound = 'sound/weapons/gun/rifle/shot.ogg'
	fire_sound_volume = 90
	rack_sound = 'sound/weapons/gun/rifle/bolt_out.ogg'
	bolt_drop_sound = 'sound/weapons/gun/rifle/bolt_in.ogg'

	recoil = 1
	unwielded_recoil = 4

	accuracy_falloff = 2 //Rifles are extremely accurate
	unwielded_spread_bonus = 50

/obj/item/gun/ballistic/rifle/rack(mob/user = null)
	if (bolt.is_locked == FALSE) // The bolt is closed
		to_chat(user, span_notice("You open the bolt of \the [src]."))
		playsound(src, rack_sound, rack_sound_volume, rack_sound_vary)

		update_chamber(FALSE, FALSE, FALSE)

		bolt.is_locked = TRUE
		update_appearance()
		return

	drop_bolt(user)

/obj/item/gun/ballistic/rifle/can_fire()
	if(bolt.is_locked)
		return FALSE
	return ..()

/obj/item/gun/ballistic/rifle/attackby(obj/item/A, mob/user, params)
	if (!bolt.is_locked && !istype(A, /obj/item/stack/sheet/cloth))
		to_chat(user, span_notice("The bolt is closed!"))
		return
	return ..()

/obj/item/gun/ballistic/rifle/examine(mob/user)
	. = ..()
	. += "The bolt is [bolt.is_locked ? "open" : "closed"]."

///////////////////////
// BOLT ACTION RIFLE //
///////////////////////

/obj/item/gun/ballistic/rifle/boltaction
	name = "\improper Mosin Nagant"
	desc = "This piece of junk looks like something that could have been used 700 years ago. It feels slightly moist."
	sawn_desc = "An extremely sawn-off Mosin Nagant, popularly known as an \"Obrez\". \
		There was probably a reason it wasn't manufactured this short to begin with."
	icon_state = "moistnugget"
	inhand_icon_state = "moistnugget"
	slot_flags = ITEM_SLOT_BACK
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction
	can_bayonet = TRUE
	knife_x_offset = 27
	knife_y_offset = 13
	can_be_sawn_off = TRUE
	unwielded_spread_bonus = 90

	var/jamming_chance = 20
	var/unjam_chance = 10
	var/jamming_increment = 5
	var/jammed = FALSE
	var/can_jam = TRUE

/obj/item/gun/ballistic/rifle/boltaction/sawoff(mob/user)
	. = ..()
	if(.)
		spread = 36
		can_bayonet = FALSE
		update_appearance()

/obj/item/gun/ballistic/rifle/boltaction/attack_self(mob/user)
	if(can_jam)
		if(jammed)
			if(prob(unjam_chance))
				jammed = FALSE
				unjam_chance = 10
			else
				unjam_chance += 10
				to_chat(user, span_warning("[src] is jammed!"))
				playsound(user,'sound/weapons/jammed.ogg', 75, TRUE)
				return FALSE
	..()

/obj/item/gun/ballistic/rifle/boltaction/do_fire_gun(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(can_jam)
		if(chambered.loaded_projectile)
			if(prob(jamming_chance))
				jammed = TRUE
			jamming_chance += jamming_increment
			jamming_chance = clamp (jamming_chance, 0, 100)
	return ..()

/obj/item/gun/ballistic/rifle/boltaction/attackby(obj/item/item, mob/user, params)
	. = ..()
	if(!can_jam || !bolt.is_locked)
		return

	if(istype(item, /obj/item/gun_maintenance_supplies))
		if(do_after(user, 10 SECONDS, target = src))
			user.visible_message(span_notice("[user] finishes maintenance of [src]."))
			jamming_chance = 10
			qdel(item)

/obj/item/gun/ballistic/rifle/boltaction/blow_up(mob/user)
	. = FALSE
	if(chambered?.loaded_projectile)
		do_fire_gun(user, user, FALSE)
		. = TRUE

/obj/item/gun/ballistic/rifle/boltaction/harpoon
	name = "ballistic harpoon gun"
	desc = "A weapon favored by carp hunters, but just as infamously employed by agents of the Animal Rights Consortium against human aggressors. Because it's ironic."
	icon_state = "speargun"
	inhand_icon_state = "speargun"
	worn_icon_state = "speargun"
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/harpoon
	fire_sound = 'sound/weapons/gun/sniper/shot.ogg'
	can_be_sawn_off = FALSE
	can_jam = FALSE

/obj/item/gun/ballistic/rifle/boltaction/brand_new
	desc = "A brand new Mosin Nagant issued by Nanotrasen for their interns. You would rather not to damage it."
	can_be_sawn_off = FALSE
	can_jam = FALSE

/obj/item/gun/ballistic/rifle/boltaction/brand_new/prime
	name = "\improper Regal Nagant"
	desc = "A prized hunting Mosin Nagant. Used for the most dangerous game."
	icon_state = "moistprime"
	inhand_icon_state = "moistprime"
	worn_icon_state = "moistprime"
	can_be_sawn_off = TRUE
	sawn_desc = "A sawn-off Regal Nagant... Doing this was a sin, I hope you're happy. \
		You are now probably one of the few people in the universe to ever hold a \"Regal Obrez\". \
		Even thinking about that name combination makes you ill."

/obj/item/gun/ballistic/rifle/boltaction/brand_new/prime/sawoff(mob/user)
	. = ..()
	if(.)
		name = "\improper Regal Obrez" // wear it loud and proud

/obj/item/gun/ballistic/rifle/boltaction/pipegun
	name = "pipegun"
	desc = "An excellent weapon for flushing out tunnel rats and enemy assistants, but its rifling leaves much to be desired."
	icon_state = "musket"
	inhand_icon_state = "musket"
	worn_icon_state = "musket"
	lefthand_file = 'icons/mob/inhands/weapons/64x_guns_left.dmi'
	righthand_file = 'icons/mob/inhands/weapons/64x_guns_right.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	fire_sound = 'sound/weapons/gun/sniper/shot.ogg'
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/pipegun
	initial_caliber = CALIBER_12GAUGE
	alternative_caliber = CALIBER_A762
	initial_fire_sound = 'sound/weapons/gun/sniper/shot.ogg'
	alternative_fire_sound = 'sound/weapons/gun/shotgun/shot.ogg'
	can_modify_ammo = TRUE
	can_misfire = TRUE
	misfire_probability = 0
	misfire_percentage_increment = 5 //Slowly increases every shot
	can_bayonet = TRUE
	knife_y_offset = 11
	can_be_sawn_off = FALSE
	projectile_damage_multiplier = 0.75

/obj/item/gun/ballistic/rifle/boltaction/pipegun/do_chamber_update()
	. = ..()
	do_sparks(1, TRUE, src)

/obj/item/gun/ballistic/rifle/boltaction/pipegun/prime
	name = "regal pipegun"
	desc = "Older, territorial assistants typically possess more valuable loot."
	icon_state = "musket_prime"
	inhand_icon_state = "musket_prime"
	worn_icon_state = "musket_prime"
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/pipegun/prime
	can_misfire = FALSE
	can_jam = FALSE
	misfire_probability = 0
	misfire_percentage_increment = 0
	projectile_damage_multiplier = 1

/// MAGICAL BOLT ACTIONS + ARCANE BARRAGE? ///

/obj/item/gun/ballistic/rifle/enchanted
	name = "enchanted bolt action rifle"
	desc = "Careful not to lose your head."
	var/guns_left = 30
	mag_type = /obj/item/ammo_box/magazine/internal/enchanted
	can_be_sawn_off = FALSE

/obj/item/gun/ballistic/rifle/enchanted/arcane_barrage
	name = "arcane barrage"
	desc = "Pew Pew Pew."
	fire_sound = 'sound/weapons/emitter.ogg'
	pin = /obj/item/firing_pin/magic
	icon_state = "arcane_barrage"
	inhand_icon_state = "arcane_barrage"
	slot_flags = null
	can_bayonet = FALSE
	item_flags = NEEDS_PERMIT | DROPDEL | ABSTRACT | NOBLUDGEON
	flags_1 = NONE
	trigger_guard = TRIGGER_GUARD_ALLOW_ALL
	show_bolt_icon = FALSE //It's a magic hand, not a rifle

	mag_type = /obj/item/ammo_box/magazine/internal/arcane_barrage

/obj/item/gun/ballistic/rifle/enchanted/unequipped()
	. = ..()
	guns_left = 0
	magazine = null
	chambered = null

/obj/item/gun/ballistic/rifle/enchanted/proc/discard_gun(mob/living/user)
	user.throw_item(pick(oview(7,get_turf(user))))

/obj/item/gun/ballistic/rifle/enchanted/arcane_barrage/discard_gun(mob/living/user)
	qdel(src)

/obj/item/gun/ballistic/rifle/enchanted/attack_self()
	return

/obj/item/gun/ballistic/rifle/enchanted/do_fire_gun(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	. = ..()
	if(!.)
		return
	if(guns_left)
		var/obj/item/gun/ballistic/rifle/enchanted/gun = new type
		gun.guns_left = guns_left - 1
		discard_gun(user)
		user.try_swap_hand()
		user.put_in_hands(gun)
	else
		user.dropItemToGround(src, TRUE)
