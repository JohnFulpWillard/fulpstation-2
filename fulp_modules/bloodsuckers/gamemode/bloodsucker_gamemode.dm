/datum/game_mode
	var/list/datum/mind/bloodsuckers = list()

/datum/game_mode/bloodsucker
	name = "bloodsucker"
	config_tag = "bloodsucker"
	report_type = "Bloodsucker"
	antag_flag = ROLE_BLOODSUCKER
	false_report_weight = 10
	restricted_jobs = list("AI", "Cyborg")
	protected_jobs = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain", "Head of Personnel")
	required_players = 0
	required_enemies = 1
	recommended_enemies = 4
	reroll_friendly = 1
	round_ends_with_antag_death = FALSE

	announce_span = "greem"
	announce_text = "Filthy, bloodsucking vampires are crawling around disguised as crewmembers!\n\
	<span class='danger'>Bloodsuckers</span>: Claim a coffin and grow strength, turn the crew into your slaves.\n\
	<span class='notice'>Crew</span>: Put an end to the undead menace and resist their brainwashing!"

/datum/game_mode/bloodsucker/pre_setup()

	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += protected_jobs

	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		restricted_jobs += "Assistant"

	recommended_enemies = clamp(round(num_players()/10), 1, 6);

	for(var/i = 0, i < recommended_enemies, i++)
		if (!antag_candidates.len)
			break
		var/datum/mind/bloodsucker = pick(antag_candidates)
		// Can we even BE a bloodsucker?
		//if (can_make_bloodsucker(bloodsucker, display_warning=FALSE))
		bloodsuckers += bloodsucker
		bloodsucker.restricted_roles = restricted_jobs
		log_game("[bloodsucker.key] (ckey) has been selected as a Bloodsucker.")
		antag_candidates.Remove(bloodsucker) // Apparently you can also write antag_candidates -= bloodsucker

	//  Assign Hunters (as many as monsters, plus one)
	//assign_monster_hunters(bloodsuckers.len, TRUE, bloodsuckers)	// Disabled, monster hunters are meant to be Admin only!

	// Do we have enough vamps to continue?
	return bloodsuckers.len >= required_enemies

/datum/game_mode/bloodsucker/post_setup()
	// Sunlight (Creating Bloodsuckers manually will check to create this, too)
	check_start_sunlight()
	// Vamps
	for(var/datum/mind/bloodsucker in bloodsuckers)
		if(!make_bloodsucker(bloodsucker))
			bloodsuckers -= bloodsucker
	..()

// Init Sunlight (called from datum_bloodsucker.on_gain(), in case game mode isn't even Bloodsucker
/datum/game_mode/proc/check_start_sunlight()
	// Already Sunlight (and not about to cancel)
	if(istype(bloodsucker_sunlight) && !bloodsucker_sunlight.cancel_me)
		return
	bloodsucker_sunlight = new ()

// End Sun (last bloodsucker removed)
/datum/game_mode/proc/check_cancel_sunlight()
	// No Sunlight
	if(!istype(bloodsucker_sunlight))
		return
	if(bloodsuckers.len <= 0)
		bloodsucker_sunlight.cancel_me = TRUE
		qdel(bloodsucker_sunlight)
		bloodsucker_sunlight = null

/datum/game_mode/proc/is_daylight()
	return istype(bloodsucker_sunlight) && bloodsucker_sunlight.amDay

/datum/game_mode/bloodsucker/generate_report()
	return "There's been a report of the undead roaming around the sector, especially those that display Vampiric abilities.\
			They've displayed the ability to disguise themselves as anyone and brainwash the minds of people they capture alive.\
			Please take care of the crew and their health, as it is impossible to tell if one is lurking in the darkness behind."

/datum/game_mode/bloodsucker/make_antag_chance(mob/living/carbon/human/character) //Assigns changeling to latejoiners
	var/bloodsuckercap = min(round(GLOB.joined_player_list.len / (csc * 2)) + 2, round(GLOB.joined_player_list.len / csc))
	if(bloodsuckers.len >= bloodsuckercap) //Caps number of latejoin antagonists
		return
	if(bloodsuckers.len <= (bloodsuckercap - 2) || prob(100 - (csc * 2)))
		if(ROLE_BLOODSUCKER in character.client.prefs.be_special)
			if(!is_banned_from(character.ckey, list(ROLE_BLOODSUCKER, ROLE_SYNDICATE)) && !QDELETED(character))
				if(age_check(character.client))
					if(!(character.job in restricted_jobs))
						character.mind.make_Bloodsucker()
						bloodsuckers += character.mind

//////////////////////////////////////////////////////////////////////////////

/datum/game_mode/proc/can_make_bloodsucker(datum/mind/bloodsucker, datum/mind/creator, display_warning=TRUE) // Creator is just here so we can display fail messages to whoever is turning us.
	// No Mind
	if(!bloodsucker || !bloodsucker.key) // KEY is client login?
		//if(creator) // REMOVED. You wouldn't see their name if there is no mind, so why say anything?
		//	to_chat(creator, "<span class='danger'>[bloodsucker] isn't self-aware enough to be raised as a Bloodsucker!</span>")
		return FALSE
	// Species Must have a HEART (Sorry Plasmabois)
	var/mob/living/carbon/human/H = bloodsucker.current
	if(NOBLOOD in H.dna.species.species_traits)
		if(display_warning && creator)
			to_chat(creator, "<span class='danger'>[bloodsucker]'s DNA isn't compatible!</span>")
		return FALSE
	// Already a Non-Human Antag
	if(bloodsucker.has_antag_datum(/datum/antagonist/abductor) || bloodsucker.has_antag_datum(/datum/antagonist/changeling))
		return FALSE
	// Already a vamp
	if(bloodsucker.has_antag_datum(ANTAG_DATUM_BLOODSUCKER))
		if(display_warning && creator)
			to_chat(creator, "<span class='danger'>[bloodsucker] is already a Bloodsucker!</span>")
		return FALSE
	return TRUE

/datum/game_mode/proc/can_make_vassal(mob/living/target, datum/mind/creator, display_warning = TRUE)//, check_antag_or_loyal=FALSE)
	// Not Correct Type: Abort
	if(!iscarbon(target) || !creator)
		return FALSE
	if(target.stat > UNCONSCIOUS)
		return FALSE
	// No Mind!
	if(!target.mind || !target.mind.key)
		if(display_warning)
			to_chat(creator, "<span class='danger'>[target] isn't self-aware enough to be made into a Vassal.</span>")
		return FALSE
	// Already MY Vassal
	var/datum/antagonist/vassal/V = target.mind.has_antag_datum(ANTAG_DATUM_VASSAL)
	if(istype(V) && V.master)
		if(V.master.owner == creator)
			if(display_warning)
				to_chat(creator, "<span class='danger'>[target] is already your loyal Vassal!</span>")
		else
			if(display_warning)
				to_chat(creator, "<span class='danger'>[target] is the loyal Vassal of another Bloodsucker!</span>")
		return FALSE
	// Already Antag or Loyal (Vamp Hunters count as antags)
	if(target.mind.enslaved_to || AmInvalidAntag(target.mind)) //!VassalCheckAntagValid(target.mind, check_antag_or_loyal)) // HAS_TRAIT(target, TRAIT_MINDSHIELD, "implant") ||
		if(display_warning)
			to_chat(creator, "<span class='danger'>[target] resists the power of your blood to dominate their mind!</span>")
		return FALSE
	return TRUE

/datum/game_mode/proc/AmValidAntag(datum/mind/M)
	// No List?
	if(!islist(M.antag_datums) || M.antag_datums.len == 0)
		return FALSE
	// Am I NOT an invalid Antag?    NOTE: We already excluded non-antags above. Don't worry about the "No List?" check in AmInvalidIntag()
	return !AmInvalidAntag(M)

/datum/game_mode/proc/AmInvalidAntag(datum/mind/M)
	// No List?
	if(!islist(M.antag_datums) || M.antag_datums.len == 0)
		return FALSE
	// Does even ONE antag appear in this mind that isn't in the list? Then FAIL!
	for(var/datum/antagonist/antag_datum in M.antag_datums)
		if(!(antag_datum.type in vassal_allowed_antags))  // vassal_allowed_antags is a list stored in the game mode, above.
			//message_admins("DEBUG VASSAL: Found Invalid: [antag_datum] // [antag_datum.type]")
			return TRUE
	//message_admins("DEBUG VASSAL: Valid Antags! (total of [M.antag_datums.len])")
	// WHEN YOU DELETE THE ABOVE: Remove the 3 second timer on converting the vassal too.
	return FALSE

/datum/game_mode/proc/make_vassal(var/mob/living/target, var/datum/mind/creator)
	if(!can_make_vassal(target, creator))
		return FALSE
	// Make Vassal
	var/datum/antagonist/vassal/V = new(target.mind)
	var/datum/antagonist/bloodsucker/B = creator.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
	V.master = B
	target.mind.add_antag_datum(V, V.master.get_team())
	// Update Bloodsucker Title (we're a daddy now)
	B.SelectTitle(am_fledgling = FALSE) // Only works if you have no title yet.
	// Log it
	message_admins("[target] has become a Vassal, and is enslaved to [creator].")
	log_admin("[target] has become a Vassal, and is enslaved to [creator].")
	return TRUE
