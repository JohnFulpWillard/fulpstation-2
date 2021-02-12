/datum/job/fulp/deputy
	title = "Deputy"
	auto_deadmin_role_flags = DEADMIN_POSITION_SECURITY
	department_head = list("Head of Security")
	faction = "Station"
	total_positions = 4
	spawn_positions = 4
	supervisors = "the head of your assigned department, and the head of security when outside your post"
	selection_color = "#ffeeee"
	minimal_player_age = 7
	exp_requirements = 300
	exp_type = EXP_TYPE_CREW
	exp_type_department = EXP_TYPE_SECURITY
	id_icon = 'fulp_modules/jobs/cards.dmi'
	hud_icon = 'fulp_modules/jobs/huds.dmi'
	fulp_spawn = /obj/effect/landmark/start/deputy

	access = list(ACCESS_SECURITY, ACCESS_BRIG, ACCESS_SEC_DOORS, ACCESS_MAINT_TUNNELS)
	minimal_access = list(ACCESS_SECURITY, ACCESS_BRIG, ACCESS_SEC_DOORS) // ACCESS_BRIG due to delta departmental cells, sadly.
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_SEC
	mind_traits = list(TRAIT_LAW_ENFORCEMENT_METABOLISM)

	display_order = JOB_DISPLAY_ORDER_SECURITY_OFFICER
	bounty_types = CIV_JOB_SEC

//Default Deputy Clothes
/datum/outfit/job/deputy
	name = "Deputy"
	jobtype = /datum/job/fulp/deputy

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/headset_sec
	uniform = /obj/item/clothing/under/rank/security/officer/mallcop
	gloves = /obj/item/clothing/gloves/color/black
	head = /obj/item/clothing/head/beret/sec
	shoes = /obj/item/clothing/shoes/jackboots
	l_pocket = /obj/item/flashlight/seclite
	r_pocket = /obj/item/assembly/flash/handheld
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	backpack_contents = list(/obj/item/melee/baton/loaded=1, /obj/item/restraints/handcuffs/cable/zipties=1)

	backpack = /obj/item/storage/backpack/security
	satchel = /obj/item/storage/backpack/satchel/sec
	duffelbag = /obj/item/storage/backpack/duffelbag/sec
	box = /obj/item/storage/box/survival/security

	implants = list(/obj/item/implant/mindshield)

//////////////////////////////////////////////////////////
//Access + Department Assigning AKA The important stuff //
//////////////////////////////////////////////////////////
/datum/job/deputy/get_access()
	var/list/L = list()
	L |= ..()
	return L

GLOBAL_LIST_INIT(available_deputy_depts, sortList(list(SEC_DEPT_ENGINEERING, SEC_DEPT_MEDICAL, SEC_DEPT_SCIENCE, SEC_DEPT_SUPPLY)))

/datum/job/fulp/deputy/after_spawn(mob/living/carbon/human/H, mob/M) // Mostly copied from security_officer.dm
	. = ..()
	var/department
	if(M && M.client && M.client.prefs)
		department = M.client.prefs.prefered_security_department
		if(!LAZYLEN(GLOB.available_deputy_depts))
			return
		else if(department in GLOB.available_deputy_depts)
			LAZYREMOVE(GLOB.available_deputy_depts, department)
		else
			department = pick_n_take(GLOB.available_deputy_depts)
	var/list/dep_access = null
	switch(department) // Spawn points have been moved, read landmark.dm for more info
		if(SEC_DEPT_SUPPLY)
			dep_access = list(ACCESS_MAILSORTING, ACCESS_CARGO, ACCESS_MINING, ACCESS_MECH_MINING, ACCESS_MINING_STATION, ACCESS_MINERAL_STOREROOM, ACCESS_AUX_BASE)
			if(isplasmaman(H))
				H.equipOutfit(/datum/outfit/plasmaman/deputy)
			if(isbeefman(H))
				H.equipOutfit(/datum/outfit/job/deputy/beefman)
			H.equipOutfit(/datum/outfit/job/deputy/supply)
		if(SEC_DEPT_ENGINEERING)
			dep_access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_TECH_STORAGE, ACCESS_ATMOSPHERICS, ACCESS_AUX_BASE, ACCESS_CONSTRUCTION, ACCESS_MECH_ENGINE, ACCESS_TCOMSAT, ACCESS_MINERAL_STOREROOM)
			if(isplasmaman(H))
				H.equipOutfit(/datum/outfit/plasmaman/deputy)
			if(isbeefman(H))
				H.equipOutfit(/datum/outfit/job/deputy/beefman)
			H.equipOutfit(/datum/outfit/job/deputy/engineering)
		if(SEC_DEPT_MEDICAL)
			dep_access = list(ACCESS_MEDICAL, ACCESS_PSYCHOLOGY, ACCESS_MORGUE, ACCESS_VIROLOGY, ACCESS_PHARMACY, ACCESS_CHEMISTRY, ACCESS_SURGERY, ACCESS_MECH_MEDICAL)
			if(isplasmaman(H))
				H.equipOutfit(/datum/outfit/plasmaman/deputy)
			if(isbeefman(H))
				H.equipOutfit(/datum/outfit/job/deputy/beefman)
			H.equipOutfit(/datum/outfit/job/deputy/medical)
		if(SEC_DEPT_SCIENCE)
			dep_access = list(ACCESS_RND, ACCESS_GENETICS, ACCESS_TOXINS, ACCESS_MECH_SCIENCE, ACCESS_RESEARCH, ACCESS_ROBOTICS, ACCESS_XENOBIOLOGY, ACCESS_MINERAL_STOREROOM, ACCESS_TOXINS_STORAGE)
			if(isplasmaman(H))
				H.equipOutfit(/datum/outfit/plasmaman/deputy)
			if(isbeefman(H))
				H.equipOutfit(/datum/outfit/job/deputy/beefman)
			H.equipOutfit(/datum/outfit/job/deputy/science)

	if(department)
		to_chat(M, "<b>You have been assigned to [department]!</b>")
	else
		to_chat(M, "<b>You have not been assigned to any department. Please report this to the Head of Personnel.</b>")

	var/obj/item/card/id/W = H.wear_id
	W.access |= dep_access
	W.update_icon()

//Mood buff from being within your department. Used in deputy_zclothing.dm
/datum/mood_event/deputy_helpful
	description = "<span class='nicegreen'>I love helping out my department!</span>\n"
	mood_change = 5
