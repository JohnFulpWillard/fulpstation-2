/datum/action/bloodsucker/targeted/brawn
	name = "Brawn"
	desc = "Snap restraints with ease, or deal terrible damage with your bare hands."
	button_icon_state = "power_strength"
	bloodcost = 10
	cooldown = 90
	target_range = 1
	power_activates_immediately = TRUE
	must_be_capacitated = TRUE
	can_be_immobilized = TRUE
	bloodsucker_can_buy = TRUE
	// Level Up
	var/upgrade_canLocker = FALSE
	var/upgrade_canDoor = FALSE

/datum/action/bloodsucker/targeted/brawn/CheckCanUse(display_error)
	if(!..(display_error))// DEFAULT CHECKS
		return FALSE
	. = TRUE
	// Break Out of Restraints! (And then cancel)
	if(CheckBreakRestraints())
		PowerActivatedSuccessfully() // PAY COST! BEGIN COOLDOWN!DEACTIVATE!
		. = FALSE //return FALSE
	// Throw Off Attacker! (And then cancel)
	if(CheckEscapePuller())
		PowerActivatedSuccessfully() // PAY COST! BEGIN COOLDOWN!DEACTIVATE!
		. = FALSE //return FALSE
	/*if(CheckBreakLocker())
		.= FALSE */
	// Did we successfuly use power to BREAK CUFFS and/or ESCAPE PULLER and/or escape from a locker?
	// Then PAY COST!
	if(. == FALSE)
		PowerActivatedSuccessfully() // PAY COST! BEGIN COOLDOWN!DEACTIVATE!
	// NOTE: We use . = FALSE so that we can break cuffs AND throw off our attacker in one use!
	return TRUE
/datum/action/bloodsucker/targeted/brawn/CheckValidTarget(atom/A)
	return isliving(A) || istype(A, /obj/machinery/door)

/datum/action/bloodsucker/targeted/brawn/CheckCanTarget(atom/A, display_error)
	// DEFAULT CHECKS (Distance)
	if(!..()) // Disable range notice for Brawn.
		return FALSE
	// Must outside Closet to target anyone!
	if(!isturf(owner.loc))
		return FALSE
	// Check: Self
	if(A == owner)
		return FALSE
	// Target Type: Living
	if(isliving(A))
		return TRUE
	// Target Type: Door
	else if(istype(A, /obj/machinery/door))
		return TRUE
	return ..() // yes, FALSE! You failed if you got here! BAD TARGET

/datum/action/bloodsucker/targeted/brawn/FireTargetedPower(atom/A)
	// set waitfor = FALSE   <---- DONT DO THIS! We WANT this power to hold up ClickWithPower(), so that we can unlock the power when it's done.
	var/mob/living/carbon/target = A
	var/mob/living/user = owner
	// Target Type: Mob
	if (isliving(target))
		var/mob/living/carbon/user_C = user
		var/hitStrength = user_C.dna.species.punchdamagehigh * 1.25 + 2
		// Knockdown!
		var/powerlevel = min(5, 1 + level_current)
		if(rand(5 + powerlevel) >= 5)
			target.visible_message("<span class='danger'>[user] lands a vicious punch, sending [target] away!</span>", \
							  "<span class='userdanger'>[user] has landed a horrifying punch on you, sending you flying!!</span>", null, COMBAT_MESSAGE_RANGE)
			target.Knockdown(min(5, rand(10, 10 * powerlevel)))
		// Attack!
		playsound(get_turf(target), 'sound/weapons/punch4.ogg', 60, 1, -1)
		user.do_attack_animation(target, ATTACK_EFFECT_SMASH)
		var/obj/item/bodypart/affecting = target.get_bodypart(ran_zone(target.zone_selected))
		target.apply_damage(hitStrength, BRUTE, affecting)
		// Knockback
		var/send_dir = get_dir(owner, target)
		var/turf/T = get_ranged_target_turf(target, send_dir, powerlevel)
		owner.newtonian_move(send_dir) // Bounce back in 0 G
		target.throw_at(T, powerlevel, TRUE, owner)  //new /datum/forced_movement(target, get_ranged_target_turf(target, send_dir, (hitStrength / 4)), 1, FALSE)
	// Target Type: Door
	else if(istype(target, /obj/machinery/door))
		var/obj/machinery/door/D = target
		playsound(get_turf(usr), 'sound/machines/airlock_alien_prying.ogg', 40, 1, -1)
		to_chat(user, "<span class='notice'>You prepare to tear open [D].</span>")
		if(do_mob(usr,target,25))
			if (D.Adjacent(user))
				to_chat(user, "<span class='notice'>You tear open the [D].</span>")
				user.Stun(10)
				user.do_attack_animation(D, ATTACK_EFFECT_SMASH)
				playsound(get_turf(D), 'sound/effects/bang.ogg', 30, 1, -1)
				D.open(2) // open(2) is like a crowbar or jaws of life.
	// Target Type: Closet

/obj/item/restraints/Destroy()
	if(iscarbon(loc))
		var/mob/living/carbon/M = loc
		if(M.handcuffed == src)
			M.set_handcuffed(null)
			M.update_handcuffed()
			if(M.buckled && M.buckled.buckle_requires_restraints)
				M.buckled.unbuckle_mob(M)
		if(M.legcuffed == src)
			M.legcuffed = null
			M.update_inv_legcuffed()
	return ..()

/datum/action/bloodsucker/targeted/brawn/proc/CheckBreakRestraints(mob/living/carbon/human/user)
	// (NOTE: Just like biodegrade.dm, we only remove one thing per use) //
	if(user.handcuffed) //Removes Handcuffs
		var/obj/O = user.get_item_by_slot(ITEM_SLOT_HANDCUFFED)
		if(!istype(O))
			return FALSE
		user.visible_message("<span class='warning'>[user] breaks through the [user.p_their()] [O] like it's nothing!</span>", \
			"<span class='warning'>We break through our handcuffs!</span>")
		if(O && user.handcuffed == O)
			qdel(O)
		return TRUE
	if(user.legcuffed) //Removes Legcuffs
		var/obj/O = user.get_item_by_slot(ITEM_SLOT_LEGCUFFED)
		if(!istype(O))
			return FALSE
		user.visible_message("<span class='warning'>[user] kicks away the [user.p_their()] [O] like it's nothing!</span>", \
			"<span class='warning'>We discard our legcuffs!</span>")
		if(O && user.legcuffed == O)
			qdel(O)
		return TRUE
	if(user.wear_suit && user.wear_suit.breakouttime) //Removes straightjacket
		var/obj/item/clothing/suit/S = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		if(!istype(S))
			return FALSE
		user.visible_message("<span class='warning'>[user] rips straight through the [user.p_their()] [S]!</span>", \
			"<span class='warning'>We tore through our straightjacket!</span>")
		if(S && user.wear_suit == S)
			qdel(S)
		return TRUE
	..()
	return FALSE

/datum/action/bloodsucker/targeted/brawn/proc/CheckEscapePuller()
	if(!owner.pulledby) // || owner.pulledby.grab_state <= GRAB_PASSIVE)
		return FALSE
	var/mob/M = owner.pulledby
	var/pull_power = M.grab_state
	playsound(get_turf(M), 'sound/effects/woodhit.ogg', 75, 1, -1)
	// Knock Down (if Living)
	if (isliving(M))
		var/mob/living/L = M
		L.Knockdown(pull_power * 10 + 20)
	// Knock Back (before Knockdown, which probably cancels pull)
	var/send_dir = get_dir(owner, M)
	var/turf/T = get_ranged_target_turf(M, send_dir, pull_power)
	owner.newtonian_move(send_dir) // Bounce back in 0 G
	M.throw_at(T, pull_power, TRUE, owner, FALSE) // Throw distance based on grab state! Harder grabs punished more aggressively.
	// /proc/log_combat(atom/user, atom/target, what_done, atom/object=null, addition=null)
	log_combat(owner, M, "used Brawn power")
	owner.visible_message("<span class='warning'>[owner] tears free of [M]'s grasp!</span>", \
			 			"<span class='warning'>You shrug off [M]'s grasp!</span>")
	owner.pulledby = null // It's already done, but JUST IN CASE.
	return TRUE
/* Doesnt work
/datum/action/bloodsucker/targeted/brawn/proc/CheckBreakLocker()
	if(!istype(owner.loc, /obj/structure/closet))
		return FALSE
		playsound(get_turf(owner), 'sound/machines/airlock_alien_prying.ogg', 40, 1, -1)
		if(do_mob(owner ,target, 25))
			var/obj/structure/closet/C = owner.loc
			to_chat(owner, "<span class='notice'>You prepare to tear open the [C].</span>")
			owner.do_attack_animation(C, ATTACK_EFFECT_SMASH)
			playsound(get_turf(C), 'sound/effects/bang.ogg', 30, 1, -1)
			C.bust_open()
			return TRUE
*/
