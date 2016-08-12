//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31
var/global/list/all_objectives = list()

var/list/potential_theft_objectives = subtypesof(/datum/theft_objective) \
	- /datum/theft_objective/steal \
	- /datum/theft_objective/special \
	- /datum/theft_objective/number \
	- /datum/theft_objective/number/special \
	- /datum/theft_objective/number/coins

/datum/objective
	var/datum/mind/owner = null			//Who owns the objective.
	var/explanation_text = "Nothing"	//What that person is supposed to do.
	var/datum/mind/target = null		//If they are focused on a particular person.
	var/target_amount = 0				//If they are focused on a particular number. Steal objectives have their own counter.
	var/completed = 0					//currently only used for custom objectives.
	var/martyr_compatible = 0			//If the objective is compatible with martyr objective, i.e. if you can still do it while dead.

/datum/objective/New(var/text)
	all_objectives |= src
	if(text)
		explanation_text = text

/datum/objective/Destroy()
	all_objectives -= src
	return ..()

/datum/objective/proc/check_completion()
	return completed

/datum/objective/proc/is_invalid_target(datum/mind/possible_target)
	if(possible_target == owner)
		return TARGET_INVALID_IS_OWNER
	if(!ishuman(possible_target.current))
		return TARGET_INVALID_NOT_HUMAN
	if(!possible_target.current.stat == DEAD)
		return TARGET_INVALID_DEAD

/datum/objective/proc/find_target()
	var/list/possible_targets = list()
	for(var/datum/mind/possible_target in ticker.minds)
		if(is_invalid_target(possible_target))
			continue

		possible_targets += possible_target

	if(possible_targets.len > 0)
		target = pick(possible_targets)


/datum/objective/assassinate
	martyr_compatible = 1

/datum/objective/assassinate/find_target()
	..()
	if(target && target.current)
		explanation_text = "Assassinate [target.current.real_name], the [target.assigned_role]."
	else
		explanation_text = "Free Objective"

/datum/objective/assassinate/check_completion()
	if(target && target.current)
		if(target.current.stat == DEAD)
			return 1
		if(issilicon(target.current) || isbrain(target.current)) //Borgs/brains/AIs count as dead for traitor objectives. --NeoFite
			return 1
		if(!target.current.ckey)
			return 1
		return 0
	return 1


/datum/objective/mutiny
	martyr_compatible = 1

/datum/objective/mutiny/find_target()
	..()
	if(target && target.current)
		explanation_text = "Assassinate [target.current.real_name], the [target.assigned_role]."
	else
		explanation_text = "Free Objective"
	return target

/datum/objective/mutiny/check_completion()
	if(target && target.current)
		if(target.current.stat == DEAD || !ishuman(target.current) || !target.current.ckey || !target.current.client)
			return 1
		var/turf/T = get_turf(target.current)
		if(T && !is_station_level(T.z))			//If they leave the station they count as dead for this
			return 1
		return 0
	return 1

/datum/objective/mutiny/rp
/datum/objective/mutiny/rp/find_target()
	..()
	if(target && target.current)
		explanation_text = "Assassinate, capture or convert [target.current.real_name], the [target.assigned_role]."
	else
		explanation_text = "Free Objective"

//less violent rev objectives
/datum/objective/mutiny/rp/check_completion()
	if(target && target.current)
		if(target.current.stat == DEAD)
			return 1
		if(!ishuman(target.current))
			return 1
		if(iscarbon(target.current))
			var/mob/living/carbon/C = target.current
			if(C.handcuffed)
				return 1

		if(GAMEMODE_IS_REVOLUTION)
			if(target in ticker.mode.head_revolutionaries)
				return 1

		var/turf/T = get_turf(target.current)
		if(T && !is_station_level(T.z))
			return 1

		return 0
	return 1


/datum/objective/maroon
	martyr_compatible = 1

/datum/objective/maroon/find_target()
	..()
	if(target && target.current)
		explanation_text = "Prevent [target.current.real_name], the [target.assigned_role] from escaping alive."
	else
		explanation_text = "Free Objective"
	return target

/datum/objective/maroon/check_completion()
	if(target && target.current)
		if(target.current.stat == DEAD)
			return 1
		if(!target.current.ckey)
			return 1
		if(issilicon(target.current))
			return 1
		if(isbrain(target.current))
			return 1
		var/turf/T = get_turf(target.current)
		if(is_admin_level(T.z))
			return 0
		return 0
	return 1


/datum/objective/debrain //I want braaaainssss
	martyr_compatible = 0

/datum/objective/debrain/find_target()
	..()
	if(target && target.current)
		explanation_text = "Steal the brain of [target.current.real_name] the [target.assigned_role]."
	else
		explanation_text = "Free Objective"
	return target


/datum/objective/debrain/check_completion()
	if(!target)//If it's a free objective.
		return 1
	if(!owner.current || owner.current.stat == DEAD)
		return 0
	if(!target.current || !isbrain(target.current))
		return 0
	var/atom/A = target.current
	while(A.loc)			//check to see if the brainmob is on our person
		A = A.loc
		if(A == owner.current)
			return 1
	return 0


/datum/objective/protect //The opposite of killing a dude.
	martyr_compatible = 1

/datum/objective/protect/find_target()
	..()
	if(target && target.current)
		explanation_text = "Protect [target.current.real_name], the [target.assigned_role]."
	else
		explanation_text = "Free Objective"
	return target

/datum/objective/protect/check_completion()
	if(!target) //If it's a free objective.
		return 1
	if(target.current)
		if(target.current.stat == DEAD)
			return 0
		if(issilicon(target.current))
			return 0
		if(isbrain(target.current))
			return 0
		return 1
	return 0

/datum/objective/protect/mindslave //subytpe for mindslave implants


/datum/objective/hijack
	martyr_compatible = 0 //Technically you won't get both anyway.
	explanation_text = "Hijack the shuttle by escaping on it with no loyalist NanoTrasen crew on board and alive. \
	Syndicate agents, other enemies of NanoTrasen, cyborgs, and pets may be allowed to escape alive."

/datum/objective/hijack/check_completion()
	if(!owner.current || owner.current.stat)
		return 0
	if(shuttle_master.emergency.mode < SHUTTLE_ENDGAME)
		return 0
	if(issilicon(owner.current))
		return 0

	var/area/A = get_area(owner.current)
	if(shuttle_master.emergency.areaInstance != A)
		return 0

	for(var/mob/living/player in player_list)
		if(player.mind && player.mind != owner)
			if(player.stat != DEAD)
				if(issilicon(player)) //Borgs are technically dead anyways
					continue
				if(isanimal(player)) //Poly does not own the shuttle
					continue
				if(player.mind.special_role && !(player.mind.special_role == SPECIAL_ROLE_ERT)) //Is antag, and not ERT
					continue

				if(get_area(player) == A)
					return 0
	return 1

/datum/objective/hijackclone
	explanation_text = "Hijack the emergency shuttle by ensuring only you (or your copies) escape."
	martyr_compatible = 0

/datum/objective/hijackclone/check_completion()
	if(!owner.current)
		return 0
	if(shuttle_master.emergency.mode < SHUTTLE_ENDGAME)
		return 0

	var/area/A = shuttle_master.emergency.areaInstance

	for(var/mob/living/player in player_list) //Make sure nobody else is onboard
		if(player.mind && player.mind != owner)
			if(player.stat != DEAD)
				if(issilicon(player))
					continue
				if(get_area(player) == A)
					if(player.real_name != owner.current.real_name && !istype(get_turf(player.mind.current), /turf/simulated/shuttle/floor4))
						return 0

	for(var/mob/living/player in player_list) //Make sure at least one of you is onboard
		if(player.mind && player.mind != owner)
			if(player.stat != DEAD)
				if(issilicon(player))
					continue
				if(get_area(player) == A)
					if(player.real_name == owner.current.real_name && !istype(get_turf(player.mind.current), /turf/simulated/shuttle/floor4))
						return 1
	return 0

/datum/objective/block
	explanation_text = "Do not allow any lifeforms, be it organic or synthetic to escape on the shuttle alive. AIs, Cyborgs, and pAIs are not considered alive."
	martyr_compatible = 1

/datum/objective/block/check_completion()
	if(!istype(owner.current, /mob/living/silicon))
		return 0
	if(shuttle_master.emergency.mode < SHUTTLE_ENDGAME)
		return 0
	if(!owner.current)
		return 0

	var/area/A = shuttle_master.emergency.areaInstance
	var/list/protected_mobs = list(/mob/living/silicon/ai, /mob/living/silicon/pai, /mob/living/silicon/robot)

	for(var/mob/living/player in player_list)
		if(player.type in protected_mobs)
			continue

		if(player.mind && player.stat != DEAD)
			if(get_area(player) == A)
				return 0

	return 1

/datum/objective/escape
	explanation_text = "Escape on the shuttle or an escape pod alive and free."

/datum/objective/escape/check_completion()
	if(issilicon(owner.current))
		return 0
	if(isbrain(owner.current))
		return 0
	if(!owner.current || owner.current.stat == DEAD)
		return 0
	if(ticker.force_ending) //This one isn't their fault, so lets just assume good faith
		return 1
	if(ticker.mode.station_was_nuked) //If they escaped the blast somehow, let them win
		return 1
	if(shuttle_master.emergency.mode < SHUTTLE_ENDGAME)
		return 0
	var/turf/location = get_turf(owner.current)
	if(!location)
		return 0

	if(istype(location, /turf/simulated/shuttle/floor4)) // Fails traitors if they are in the shuttle brig -- Polymorph
		return 0

	if(location.onCentcom() || location.onSyndieBase())
		return 1

	return 0


/datum/objective/escape/escape_with_identity
	var/target_real_name // Has to be stored because the target's real_name can change over the course of the round

/datum/objective/escape/escape_with_identity/find_target()
	var/list/possible_targets = list() //Copypasta because NO_SCAN races, yay for snowflakes.
	for(var/datum/mind/possible_target in ticker.minds)
		if(possible_target != owner && ishuman(possible_target.current) && (possible_target.current.stat != DEAD) && possible_target.current.client)
			var/mob/living/carbon/human/H = possible_target.current
			if(!(H.species.flags & NO_SCAN))
				possible_targets += possible_target
	if(possible_targets.len > 0)
		target = pick(possible_targets)
	if(target && target.current)
		target_real_name = target.current.real_name
		explanation_text = "Escape on the shuttle or an escape pod with the identity of [target_real_name], the [target.assigned_role] while wearing their identification card."
	else
		explanation_text = "Free Objective"

/datum/objective/escape/escape_with_identity/check_completion()
	if(!target_real_name)
		return 1
	if(!ishuman(owner.current))
		return 0
	var/mob/living/carbon/human/H = owner.current
	if(..())
		if(H.dna.real_name == target_real_name)
			if(H.get_id_name()== target_real_name)
				return 1
	return 0

/datum/objective/die
	explanation_text = "Die a glorious death."

/datum/objective/die/check_completion()
	if(!owner.current || owner.current.stat == DEAD || isbrain(owner.current))
		return 1
	if(issilicon(owner.current) && owner.current != owner.original)
		return 1
	return 0



/datum/objective/survive
	explanation_text = "Stay alive until the end."

/datum/objective/survive/check_completion()
	if(!owner.current || owner.current.stat == DEAD || isbrain(owner.current))
		return 0		//Brains no longer win survive objectives. --NEO
	if(issilicon(owner.current) && owner.current != owner.original)
		return 0
	return 1

/datum/objective/nuclear
	explanation_text = "Destroy the station with a nuclear device."
	martyr_compatible = 1



/datum/objective/steal
	var/datum/theft_objective/steal_target
	martyr_compatible = 0

/datum/objective/steal/find_target(var/special_only=0)
	var/loop=50
	while(!steal_target && loop > 0)
		loop--
		var/thefttype = pick(potential_theft_objectives)
		var/datum/theft_objective/O = new thefttype
		if(owner.assigned_role in O.protected_jobs)
			continue
		if(special_only)
			if(!(O.flags & 1)) // THEFT_FLAG_SPECIAL
				continue
		else
			if(O.flags & 1) // THEFT_FLAG_SPECIAL
				continue
		if(O.flags & 2)
			continue
		steal_target=O
		explanation_text = "Steal [O]."
		return
	explanation_text = "Free Objective."


/datum/objective/steal/proc/select_target()
	var/list/possible_items_all = potential_theft_objectives+"custom"
	var/new_target = input("Select target:", "Objective target", null) as null|anything in possible_items_all
	if(!new_target) return
	if(new_target == "custom")
		var/datum/theft_objective/O=new
		O.typepath = input("Select type:","Type") as null|anything in typesof(/obj/item)
		if(!O.typepath) return
		var/tmp_obj = new O.typepath
		var/custom_name = tmp_obj:name
		qdel(tmp_obj)
		O.name = sanitize(copytext(input("Enter target name:", "Objective target", custom_name) as text|null,1,MAX_NAME_LEN))
		if(!O.name) return
		steal_target = O
		explanation_text = "Steal [O.name]."
	else
		steal_target = new new_target
		explanation_text = "Steal [steal_target.name]."
	return steal_target

/datum/objective/steal/check_completion()
	if(!steal_target) return 1 // Free Objective
	return steal_target.check_completion(owner)

/datum/objective/steal/exchange
	martyr_compatible = 0

/datum/objective/steal/exchange/proc/set_faction(var/faction,var/otheragent)
	target = otheragent
	var/datum/theft_objective/unique/targetinfo
	if(faction == "red")
		targetinfo = new /datum/theft_objective/unique/docs_blue
	else if(faction == "blue")
		targetinfo = new /datum/theft_objective/unique/docs_red
	explanation_text = "Acquire [targetinfo.name] held by [target.current.real_name], the [target.assigned_role] and syndicate agent"
	steal_target = targetinfo

/datum/objective/steal/exchange/backstab
/datum/objective/steal/exchange/backstab/set_faction(var/faction)
	var/datum/theft_objective/unique/targetinfo
	if(faction == "red")
		targetinfo = new /datum/theft_objective/unique/docs_red
	else if(faction == "blue")
		targetinfo = new /datum/theft_objective/unique/docs_blue
	explanation_text = "Do not give up or lose [targetinfo.name]."
	steal_target = targetinfo

/datum/objective/download
/datum/objective/download/proc/gen_amount_goal()
	target_amount = rand(10,20)
	explanation_text = "Download [target_amount] research levels."
	return target_amount


/datum/objective/download/check_completion()
	return 0



/datum/objective/capture
/datum/objective/capture/proc/gen_amount_goal()
	target_amount = rand(5,10)
	explanation_text = "Accumulate [target_amount] capture points."
	return target_amount


/datum/objective/capture/check_completion()//Basically runs through all the mobs in the area to determine how much they are worth.
	return 0




/datum/objective/absorb
/datum/objective/absorb/proc/gen_amount_goal(var/lowbound = 4, var/highbound = 6)
	target_amount = rand (lowbound,highbound)
	if(ticker)
		var/n_p = 1 //autowin
		if(ticker.current_state == GAME_STATE_SETTING_UP)
			for(var/mob/new_player/P in player_list)
				if(P.client && P.ready && P.mind != owner)
					if(P.client.prefs && (P.client.prefs.species == "Vox" || P.client.prefs.species == "Slime People" || P.client.prefs.species == "Machine")) // Special check for species that can't be absorbed. No better solution.
						continue
					n_p++
		else if(ticker.current_state == GAME_STATE_PLAYING)
			for(var/mob/living/carbon/human/P in player_list)
				if(P.species.flags & NO_SCAN)
					continue
				if(P.client && !(P.mind in ticker.mode.changelings) && P.mind!=owner)
					n_p++
		target_amount = min(target_amount, n_p)

	explanation_text = "Absorb [target_amount] compatible genomes."
	return target_amount

/datum/objective/absorb/check_completion()
	if(owner && owner.changeling && owner.changeling.absorbed_dna && (owner.changeling.absorbedcount >= target_amount))
		return 1
	else
		return 0

/datum/objective/destroy
	martyr_compatible = 1
	var/target_real_name

/datum/objective/destroy/find_target()
	var/list/possible_targets = active_ais(1)
	var/mob/living/silicon/ai/target_ai = pick(possible_targets)
	target = target_ai.mind
	if(target && target.current)
		target_real_name = target.current.real_name
		explanation_text = "Destroy [target_real_name], the AI."
	else
		explanation_text = "Free Objective"
	return target

/datum/objective/destroy/check_completion()
	if(target && target.current)
		if(target.current.stat == DEAD || is_away_level(target.current.z) || !target.current.ckey)
			return 1
		return 0
	return 1

/datum/objective/blood
/datum/objective/blood/proc/gen_amount_goal(low = 150, high = 400)
	target_amount = rand(low,high)
	target_amount = round(round(target_amount/5)*5)
	explanation_text = "Accumulate atleast [target_amount] units of blood in total."
	return target_amount

/datum/objective/blood/check_completion()
	if(owner && owner.vampire && owner.vampire.bloodtotal && owner.vampire.bloodtotal >= target_amount)
		return 1
	else
		return 0

// /vg/; Vox Inviolate for humans :V
/datum/objective/minimize_casualties
	explanation_text = "Minimise casualties."
/datum/objective/minimize_casualties/check_completion()
	if(owner.kills.len>5) return 0
	return 1

//Vox heist objectives.

/datum/objective/heist
/datum/objective/heist/proc/choose_target()
	return

/datum/objective/heist/kidnap
/datum/objective/heist/kidnap/choose_target()
	var/list/roles = list("Chief Engineer","Research Director","Roboticist","Chemist","Station Engineer")
	var/list/possible_targets = list()
	var/list/priority_targets = list()

	for(var/datum/mind/possible_target in ticker.minds)
		if(possible_target != owner && ishuman(possible_target.current) && (possible_target.current.stat != DEAD) && (possible_target.assigned_role != "MODE"))
			possible_targets += possible_target
			for(var/role in roles)
				if(possible_target.assigned_role == role)
					priority_targets += possible_target
					continue

	if(priority_targets.len > 0)
		target = pick(priority_targets)
	else if(possible_targets.len > 0)
		target = pick(possible_targets)

	if(target && target.current)
		explanation_text = "The Shoal has a need for [target.current.real_name], the [target.assigned_role]. Take them alive."
	else
		explanation_text = "Free Objective"
	return target

/datum/objective/heist/kidnap/check_completion()
	if(target && target.current)
		if(target.current.stat == DEAD)
			return 0

		var/area/shuttle/vox/A = locate() //stupid fucking hardcoding
		var/area/vox_station/B = locate() //but necessary

		for(var/mob/living/carbon/human/M in A)
			if(target.current == M)
				return 1
		for(var/mob/living/carbon/human/M in B)
			if(target.current == M)
				return 1
	else
		return 0

/datum/objective/heist/loot
/datum/objective/heist/loot/choose_target()
	var/loot = "an object"
	switch(rand(1,8))
		if(1)
			target = /obj/structure/particle_accelerator
			target_amount = 6
			loot = "a complete particle accelerator"
		if(2)
			target = /obj/machinery/the_singularitygen
			target_amount = 1
			loot = "a gravitational singularity generator"
		if(3)
			target = /obj/machinery/power/emitter
			target_amount = 4
			loot = "four emitters"
		if(4)
			target = /obj/machinery/nuclearbomb
			target_amount = 1
			loot = "a nuclear bomb"
		if(5)
			target = /obj/item/weapon/gun
			target_amount = 6
			loot = "six guns. Tasers and other non-lethal guns are acceptable"
		if(6)
			target = /obj/item/weapon/gun/energy
			target_amount = 4
			loot = "four energy guns"
		if(7)
			target = /obj/item/weapon/gun/energy/laser
			target_amount = 2
			loot = "two laser guns"
		if(8)
			target = /obj/item/weapon/gun/energy/ionrifle
			target_amount = 1
			loot = "an ion gun"

	explanation_text = "We are lacking in hardware. Steal or trade [loot]."

/datum/objective/heist/loot/check_completion()
	var/total_amount = 0

	for(var/obj/O in locate(/area/shuttle/vox))
		if(istype(O, target))
			total_amount++
		for(var/obj/I in O.contents)
			if(istype(I, target))
				total_amount++
			if(total_amount >= target_amount)
				return 1

	for(var/obj/O in locate(/area/vox_station))
		if(istype(O, target))
			total_amount++
		for(var/obj/I in O.contents)
			if(istype(I, target))
				total_amount++
			if(total_amount >= target_amount)
				return 1

	var/datum/game_mode/heist/H = ticker.mode
	for(var/datum/mind/raider in H.raiders)
		if(raider.current)
			for(var/obj/O in raider.current.get_contents())
				if(istype(O,target))
					total_amount++
				if(total_amount >= target_amount)
					return 1

	return 0

/datum/objective/heist/salvage
/datum/objective/heist/salvage/choose_target()
	switch(rand(1,8))
		if(1)
			target = "metal"
			target_amount = 300
		if(2)
			target = "glass"
			target_amount = 200
		if(3)
			target = "plasteel"
			target_amount = 100
		if(4)
			target = "solid plasma"
			target_amount = 100
		if(5)
			target = "silver"
			target_amount = 50
		if(6)
			target = "gold"
			target_amount = 20
		if(7)
			target = "uranium"
			target_amount = 20
		if(8)
			target = "diamond"
			target_amount = 20

	explanation_text = "Ransack or trade with the station and escape with [target_amount] [target]."

/datum/objective/heist/salvage/check_completion()
	var/total_amount = 0

	for(var/obj/item/O in locate(/area/shuttle/vox))
		var/obj/item/stack/sheet/S
		if(istype(O,/obj/item/stack/sheet))
			if(O.name == target)
				S = O
				total_amount += S.get_amount()

		for(var/obj/I in O.contents)
			if(istype(I,/obj/item/stack/sheet))
				if(I.name == target)
					S = I
					total_amount += S.get_amount()

	for(var/obj/item/O in locate(/area/vox_station))
		var/obj/item/stack/sheet/S
		if(istype(O,/obj/item/stack/sheet))
			if(O.name == target)
				S = O
				total_amount += S.get_amount()

		for(var/obj/I in O.contents)
			if(istype(I,/obj/item/stack/sheet))
				if(I.name == target)
					S = I
					total_amount += S.get_amount()

	var/datum/game_mode/heist/H = ticker.mode
	for(var/datum/mind/raider in H.raiders)
		if(raider.current)
			for(var/obj/item/O in raider.current.get_contents())
				if(istype(O,/obj/item/stack/sheet))
					if(O.name == target)
						var/obj/item/stack/sheet/S = O
						total_amount += S.get_amount()

	if(total_amount >= target_amount) return 1
	return 0


/datum/objective/heist/inviolate_crew
	explanation_text = "Do not leave any Vox behind, alive or dead."

/datum/objective/heist/inviolate_crew/check_completion()
	var/datum/game_mode/heist/H = ticker.mode
	if(H.is_raider_crew_safe())
		return 1
	return 0

/datum/objective/heist/inviolate_death
	explanation_text = "Follow the Inviolate. Minimise death and loss of resources."

/datum/objective/heist/inviolate_death/check_completion()
	var/vox_allowed_kills = 3 // The number of people the vox can accidently kill. Mostly a counter to people killing themselves if a raider touches them to force fail.
	var/vox_total_kills = 0

	var/datum/game_mode/heist/H = ticker.mode
	for(var/datum/mind/raider in H.raiders)
		vox_total_kills += raider.kills.len // Kills are listed in the mind; uses this to calculate vox kills

	if(vox_total_kills > vox_allowed_kills) return 0
	return 1

// Traders

/datum/objective/trade // Yes, I know there's no check_completion. The objectives exist only to tell the traders what to get.
/datum/objective/trade/proc/choose_target(var/station)
	return

/datum/objective/trade/stock // Stock or spare parts.
	var/target_rating = 1
/datum/objective/trade/stock/choose_target(var/station)
	var/itemname
	switch(rand(1,8))
		if(1)
			target = /obj/item/weapon/stock_parts/cell
			target_amount = 10
			target_rating = 3
			itemname = "ten high-capacity power cells"
		if(2)
			target = /obj/item/weapon/stock_parts/manipulator
			target_amount = 20
			itemname = "twenty micro manipulators"
		if(3)
			target = /obj/item/weapon/stock_parts/matter_bin
			target_amount = 20
			itemname = "twenty matter bins"
		if(4)
			target = /obj/item/weapon/stock_parts/micro_laser
			target_amount = 15
			itemname = "fifteen micro-lasers"
		if(5)
			target = /obj/item/weapon/stock_parts/capacitor
			target_amount = 15
			itemname = "fifteen capacitors"
		if(6)
			target = /obj/item/weapon/stock_parts/subspace/filter
			target_amount = 4
			itemname = "four hyperwave filters"
		if(7)
			target = /obj/item/solar_assembly
			target_amount = 10
			itemname = "ten solar panel assemblies"
		if(8)
			target = /obj/item/device/flash
			target_amount = 6
			itemname = "six flashes"
	explanation_text = "We are running low on spare parts. Trade for [itemname]."

//wizard

/datum/objective/wizchaos
	explanation_text = "Wreak havoc upon the station as much you can. Send those wandless Nanotrasen scum a message!"
	completed = 1
