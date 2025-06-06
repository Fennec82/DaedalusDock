/// Trim for Syndicate mobs, outfits and corpses.
/datum/access_template/syndicom
	assignment = "Syndicate Overlord"
	template_state = "trim_syndicate"
	sechud_icon_state = SECHUD_SYNDICATE
	access = list(ACCESS_SYNDICATE)

/// Trim for Syndicate mobs, outfits and corpses.
/datum/access_template/syndicom/crew
	assignment = "Syndicate Operative"
	access = list(ACCESS_SYNDICATE, ACCESS_ROBOTICS)

/// Trim for Syndicate mobs, outfits and corpses.
/datum/access_template/syndicom/captain
	assignment = "Syndicate Ship Captain"
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER, ACCESS_ROBOTICS)

/// Trim for Syndicate mobs, outfits and corpses.
/datum/access_template/battlecruiser
	assignment = "Syndicate Battlecruiser Crew"
	template_state = "trim_syndicate"
	access = list(ACCESS_SYNDICATE)

/// Trim for Syndicate mobs, outfits and corpses.
/datum/access_template/battlecruiser/captain
	assignment = "Syndicate Battlecruiser Captain"
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)

/// Trim for Chameleon ID cards. Many outfits, nuke ops and some corpses hold Chameleon ID cards.
/datum/access_template/chameleon
	assignment = "Unknown"
	access = list(ACCESS_SYNDICATE, ACCESS_MAINT_TUNNELS)

/// Trim for Chameleon ID cards. Many outfits, nuke ops and some corpses hold Chameleon ID cards.
/datum/access_template/chameleon/operative
	assignment = "Syndicate Operative"
	template_state = "trim_syndicate"

/// Trim for Chameleon ID cards. Many outfits, nuke ops and some corpses hold Chameleon ID cards.
/datum/access_template/chameleon/operative/clown
	assignment = "Syndicate Entertainment Operative"

/// Trim for Chameleon ID cards. Many outfits, nuke ops and some corpses hold Chameleon ID cards.
/datum/access_template/chameleon/operative/clown_leader
	assignment = "Syndicate Entertainment Operative Leader"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)

/// Trim for Chameleon ID cards. Many outfits, nuke ops and some corpses hold Chameleon ID cards.
/datum/access_template/chameleon/operative/nuke_leader
	assignment = "Syndicate Operative Leader"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
