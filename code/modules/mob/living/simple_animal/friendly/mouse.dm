/mob/living/simple_animal/mouse
	name = "mouse"
	desc = "It's a nasty, ugly, evil, disease-ridden rodent."
	icon_state = "mouse_gray"
	icon_living = "mouse_gray"
	icon_dead = "mouse_gray_dead"
	speak = list("Squeek!","SQUEEK!","Squeek?")
	speak_emote = list("squeeks")
	emote_hear = list("squeeks")
	emote_see = list("runs in a circle", "shakes")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	maxHealth = 5
	health = 5
	meat_type = /obj/item/weapon/reagent_containers/food/snacks/meat/slab
	meat_amount = 1
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "splats"
	density = 0
	ventcrawler = 2
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_size = MOB_SIZE_SMALL
	var/body_color //brown, gray and white, leave blank for random
	infected = 1
	var/bite_chance = 50 //chance that the rat will bite someone that steps on it. One tenth of this is also the chance it will chew a wire.

/mob/living/simple_animal/mouse/New()
	..()
	if(!body_color)
		body_color = pick( list("brown","gray","white") )
	icon_state = "mouse_[body_color]"
	icon_living = "mouse_[body_color]"
	icon_dead = "mouse_[body_color]_dead"


/mob/living/simple_animal/mouse/proc/splat()
	src.health = 0
	src.icon_dead = "mouse_[body_color]_splat"
	death()

/mob/living/simple_animal/mouse/death(gibbed)
	..(gibbed)
	if(!ckey)
		var/obj/item/trash/deadmouse/M = new(src.loc)
		M.icon_state = src.icon_dead
		qdel(src)

/mob/living/simple_animal/mouse/Crossed(AM as mob|obj)
	if( ishuman(AM) )
		if(!stat)
			var/mob/M = AM
			M << "<span class='notice'>\icon[src] Squeek!</span>"
			playsound(src, 'sound/effects/mousesqueek.ogg', 100, 1)
			if(prob(bite_chance))
				M << "<span class='alert'>The [src] bites you!</span>"
				if(istype(M,/mob/living))
					var/mob/living/L = M
					L.adjustBruteLoss(-5)
				var/datum/disease/D = pick(infections)
				M.ContractDisease(new D)
	..()

/mob/living/simple_animal/mouse/handle_automated_action()
	if(prob(bite_chance/10))
		var/turf/simulated/floor/F = get_turf(src)
		if(istype(F) && !F.intact)
			var/obj/structure/cable/C = locate() in F
			if(C && prob(15))
				if(C.avail())
					visible_message("<span class='warning'>[src] chews through the [C]. It's toast!</span>")
					playsound(src, 'sound/effects/sparks2.ogg', 100, 1)
					C.Deconstruct()
					new /obj/item/weapon/reagent_containers/food/snacks/burger/rat(src.loc)
					qdel(src) //it's a bit silly, but we don't sprites for fried rats aparently. Shame. Still, it's ghetto food.
				else
					C.Deconstruct()
					visible_message("<span class='warning'>[src] chews through the [C].</span>")

/*
 * Mouse types
 */

/mob/living/simple_animal/mouse/white
	body_color = "white"
	icon_state = "mouse_white"

/mob/living/simple_animal/mouse/gray
	body_color = "gray"
	icon_state = "mouse_gray"

/mob/living/simple_animal/mouse/brown
	body_color = "brown"
	icon_state = "mouse_brown"

//TOM IS ALIVE! SQUEEEEEEEE~K :)
/mob/living/simple_animal/mouse/brown/Tom
	name = "Tom"
	desc = "Jerry the cat is not amused."
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "splats"

/obj/item/trash/deadmouse
	name = "dead mouse"
	desc = "It looks like somebody dropped the bass on it."
	icon = 'icons/mob/animal.dmi'
	icon_state = "mouse_gray_dead"
