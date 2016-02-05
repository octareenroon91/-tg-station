/mob/living/simple_animal/hostile/poison/bees
	name = "space bee swarm"
	desc = ""
	icon_state = "bee_1"
	icon_living = "bee"
	icon_dead = ""
	var/bee_or_fly = "bee" //to tell teh bees apart from the flies
	speak_emote = list("buzzes")
	emote_hear = list("buzzes")
	turns_per_move = 0
	melee_damage_lower = 1
	melee_damage_upper = 1
	attacktext = "stings"
	response_help  = "shoos"
	response_disarm = "swats away"
	response_harm   = "squashes"
	stop_automated_movement_when_pulled = 0
	maxHealth = 10
	health = 10
	faction = list("hostile")
	move_to_delay = 0
	environment_smash = 0
	mouse_opacity = 2
	pass_flags = PASSTABLE

	//Spaceborn beings don't get hurt by space
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0

/mob/living/simple_animal/hostile/poison/bees/Process_Spacemove(var/movement_dir = 0)
	return 1

/mob/living/simple_animal/hostile/poison/bees/New()
	..()
	update_bees()

/mob/living/simple_animal/hostile/poison/bees/death(gibbed)
	..(gibbed)
	qdel(src)
	return

/mob/living/simple_animal/hostile/poison/bees/Life()
	..()
	update_bees()

/mob/living/simple_animal/hostile/poison/bees/proc/update_bees()
	while(overlays.len != health-1) //how many bees do we have in the swarm?
		var/N = rand(1, 4)
		var/image/I = image(icon='icons/mob/animal.dmi',icon_state="[bee_or_fly]_[N]", pixel_x = rand(-8, 8), pixel_y = rand(-8, 8))
		if(overlays.len < health-1)
			overlays.Add(I)
		if(overlays.len > health-1)
			overlays.Remove(I)
	if(bee_or_fly == "bee")
		poison_per_bite = health * 0.5 //each bee is half a toxin reagent
	else
		poison_per_bite = 0
	if(health > 1)
		if(bee_or_fly == "bee")
			desc = "A buzzy swarm of [health] poisonous space bees, renowned for their aggressiveness."
		else
			desc = "A buzzy swarm of [health] infectious space flies, who can carry several diseases."
	else
		desc = "Although now lonely, this single space [bee_or_fly] is still poisonous and very angry at you."

//pretty much the same as bees, but less dangerous, only with virus spreading ability
//should code them ignoring fly people later, or give flypeople some immunity to diseases.
/mob/living/simple_animal/hostile/poison/bees/flies
	name = "flies"
	maxHealth = 4
	health = 4
	bee_or_fly = "fly"
	icon_state = "fly_1"
	icon_living = "fly"
	infected = 1
	infected_bite = 1
	infection_chance = 60 //slightly more chance, since it's flies, and flies are filthy
	infections = list(/datum/disease/dna_retrovirus,/datum/disease/brainrot,/datum/disease/appendicitis)