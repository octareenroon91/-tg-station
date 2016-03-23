var/datum/subsystem/mobs/SSmob

/datum/subsystem/mobs
	name = "Mobs"
	priority = 4

	var/list/currentrun = list()

/datum/subsystem/mobs/New()
	NEW_SS_GLOBAL(SSmob)


/datum/subsystem/mobs/stat_entry()
	..("P:[mob_list.len]")


/datum/subsystem/mobs/fire(resumed = 0)
	var/seconds = wait * 0.1
	if (!resumed)
		currentrun = mob_list.Copy()
	while (currentrun.len)
		var/mob/M = currentrun[1]
		currentrun.Cut(1, 2)
		if(M)
			M.Life(seconds)

		else

			mob_list.Remove(M)
		if(MC_TICK_CHECK)
			return
/datum/subsystem/mobs/AfterInitialize()
	set_clownplanet_mob_ai(AI_OFF)



/datum/subsystem/mobs/proc/set_clownplanet_mob_ai(var/AIstatus)
	for(var/mob/living/simple_animal/hostile/M in living_mob_list)
		if(M.z == ZLEVEL_CLOWN)	//Suspend mob AI in clown planet
			M.AIStatus = AIstatus