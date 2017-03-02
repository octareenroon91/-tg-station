#define EXT_BOUND	1
#define INT_BOUND	2
#define NO_BOUND	3

/obj/machinery/atmospherics/components/unary/vent_pump
	icon_state = "vent_map"

	name = "air vent"
	desc = "Has a valve and pump attached to it"
	use_power = 1

	can_unwrench = 1

	welded = 0

	var/area/initial_loc
	level = 1
	var/area_uid
	var/id_tag = null

	var/on = 0
	var/pump_direction = 1 //0 = siphoning, 1 = releasing

	var/external_pressure_bound = ONE_ATMOSPHERE
	var/internal_pressure_bound = 0

	var/pressure_checks = 1
	//EXT_BOUND: Do not pass external_pressure_bound
	//INT_BOUND: Do not pass internal_pressure_bound
	//NO_BOUND: Do not pass either

	var/frequency = 1439
	var/datum/radio_frequency/radio_connection

	var/radio_filter_out
	var/radio_filter_in

	//Pest Spawner Vars
	var/pest_enable = 1 //wether the vent spawns pests (1) or not (0). Default is 1, set false for things like morgue and kitchen.
	var/trash_nearby //spawns rats
	var/blood_nearby //spawns bats
	var/corpse_nearby //spawns flies
	var/pest_nearby
	var/pest_max = 3 //maximum number of pests that can be around a vent. It won't spawn anymore until the one's found are dead/removed
	var/pest_chance = 20 //probability to spawn a pest. It is multiplied by the ammount of things it found that pertain to that pest.
	var/pest_ticker //var that counts until ticker_max. Only then it tries to spawn a pest
	var/pest_ticker_max = 500 //minimum number of ticks between the spawning of another pest

/obj/machinery/atmospherics/components/unary/vent_pump/on
	on = 1
	icon_state = "vent_out"

/obj/machinery/atmospherics/components/unary/vent_pump/siphon
	pump_direction = 0

/obj/machinery/atmospherics/components/unary/vent_pump/siphon/on
	on = 1
	icon_state = "vent_in"

/obj/machinery/atmospherics/components/unary/vent_pump/New()
	..()
	pest_ticker = rand(0,pest_ticker_max) //this way, vents trigger at diferent times, and don't try to spawn pests ALL at the same time. Should prevent that milli-second hang up when they do.
	initial_loc = get_area(loc)
	area_uid = initial_loc.uid
	if (!id_tag)
		assign_uid()
		id_tag = num2text(uid)

/obj/machinery/atmospherics/components/unary/vent_pump/Destroy()
	if(radio_controller)
		radio_controller.remove_object(src,frequency)
	..()

/obj/machinery/atmospherics/components/unary/vent_pump/high_volume
	name = "large air vent"
	power_channel = EQUIP

/obj/machinery/atmospherics/components/unary/vent_pump/high_volume/New()
	..()
	var/datum/gas_mixture/air_contents = airs[AIR1]
	air_contents.volume = 1000

/obj/machinery/atmospherics/components/unary/vent_pump/update_icon_nopipes()
	overlays.Cut()
	if(showpipe)
		overlays += getpipeimage('icons/obj/atmospherics/components/unary_devices.dmi', "vent_cap", initialize_directions)

	if(welded)
		icon_state = "vent_welded"
		return

	if(!nodes[NODE1] || !on || stat & (NOPOWER|BROKEN))
		icon_state = "vent_off"
		return

	if(pump_direction)
		icon_state = "vent_out"
	else
		icon_state = "vent_in"

/obj/machinery/atmospherics/components/unary/vent_pump/process_atmos()

	//before all else, I'll piggy back the Pest Spawner code
	if(pest_enable && !welded) //checks for pest enabler and wether or not it's welded
		process_pest_spawn()

	..()
	if(stat & (NOPOWER|BROKEN))
		return
	if (!nodes[NODE1])
		on = 0
	//broadcast_status() // from now air alarm/control computer should request update purposely --rastaf0
	if(!on)
		return 0

	if(welded)
		return 0

	var/datum/gas_mixture/air_contents = airs[AIR1]
	var/datum/gas_mixture/environment = loc.return_air()
	var/environment_pressure = environment.return_pressure()

	if(pump_direction) //internal -> external
		var/pressure_delta = 10000

		if(pressure_checks&EXT_BOUND)
			pressure_delta = min(pressure_delta, (external_pressure_bound - environment_pressure))
		if(pressure_checks&INT_BOUND)
			pressure_delta = min(pressure_delta, (air_contents.return_pressure() - internal_pressure_bound))

		if(pressure_delta > 0)
			if(air_contents.temperature > 0)
				var/transfer_moles = pressure_delta*environment.volume/(air_contents.temperature * R_IDEAL_GAS_EQUATION)

				var/datum/gas_mixture/removed = air_contents.remove(transfer_moles)

				loc.assume_air(removed)
				air_update_turf()

	else //external -> internal
		var/pressure_delta = 10000
		if(pressure_checks&EXT_BOUND)
			pressure_delta = min(pressure_delta, (environment_pressure - external_pressure_bound))
		if(pressure_checks&INT_BOUND)
			pressure_delta = min(pressure_delta, (internal_pressure_bound - air_contents.return_pressure()))

		if(pressure_delta > 0)
			if(environment.temperature > 0)
				var/transfer_moles = pressure_delta*air_contents.volume/(environment.temperature * R_IDEAL_GAS_EQUATION)

				var/datum/gas_mixture/removed = loc.remove_air(transfer_moles)
				if (isnull(removed)) //in space
					return

				air_contents.merge(removed)
				air_update_turf()
	update_parents()

	return 1

//Radio remote control

/obj/machinery/atmospherics/components/unary/vent_pump/proc/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = radio_controller.add_object(src, frequency,radio_filter_in)

/obj/machinery/atmospherics/components/unary/vent_pump/proc/broadcast_status()
	if(!radio_connection)
		return 0

	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.source = src

	signal.data = list(
		"area" = src.area_uid,
		"tag" = src.id_tag,
		"device" = "AVP",
		"power" = on,
		"direction" = pump_direction?("release"):("siphon"),
		"checks" = pressure_checks,
		"internal" = internal_pressure_bound,
		"external" = external_pressure_bound,
		"timestamp" = world.time,
		"sigtype" = "status"
	)

	if(!initial_loc.air_vent_names[id_tag])
		var/new_name = "\improper [initial_loc.name] vent pump #[initial_loc.air_vent_names.len+1]"
		initial_loc.air_vent_names[id_tag] = new_name
		src.name = new_name
	initial_loc.air_vent_info[id_tag] = signal.data

	radio_connection.post_signal(src, signal, radio_filter_out)

	return 1


/obj/machinery/atmospherics/components/unary/vent_pump/atmosinit()
	//some vents work his own spesial way
	radio_filter_in = frequency==1439?(RADIO_FROM_AIRALARM):null
	radio_filter_out = frequency==1439?(RADIO_TO_AIRALARM):null
	if(frequency)
		set_frequency(frequency)
	broadcast_status()
	..()

/obj/machinery/atmospherics/components/unary/vent_pump/receive_signal(datum/signal/signal)
	if(stat & (NOPOWER|BROKEN))
		return
	//log_admin("DEBUG \[[world.timeofday]\]: /obj/machinery/atmospherics/components/unary/vent_pump/receive_signal([signal.debug_print()])")
	if(!signal.data["tag"] || (signal.data["tag"] != id_tag) || (signal.data["sigtype"]!="command"))
		return 0

	if("purge" in signal.data)
		pressure_checks &= ~EXT_BOUND
		pump_direction = 0

	if("stabalize" in signal.data)
		pressure_checks |= EXT_BOUND
		pump_direction = 1

	if("power" in signal.data)
		on = text2num(signal.data["power"])

	if("power_toggle" in signal.data)
		on = !on

	if("checks" in signal.data)
		pressure_checks = text2num(signal.data["checks"])

	if("checks_toggle" in signal.data)
		pressure_checks = (pressure_checks?0:NO_BOUND)

	if("direction" in signal.data)
		pump_direction = text2num(signal.data["direction"])

	if("set_internal_pressure" in signal.data)
		internal_pressure_bound = Clamp(text2num(signal.data["set_internal_pressure"]),0,ONE_ATMOSPHERE*50)

	if("set_external_pressure" in signal.data)
		external_pressure_bound = Clamp(text2num(signal.data["set_external_pressure"]),0,ONE_ATMOSPHERE*50)

	if("adjust_internal_pressure" in signal.data)
		internal_pressure_bound = Clamp(internal_pressure_bound + text2num(signal.data["adjust_internal_pressure"]),0,ONE_ATMOSPHERE*50)

	if("adjust_external_pressure" in signal.data)
		external_pressure_bound = Clamp(external_pressure_bound + text2num(signal.data["adjust_external_pressure"]),0,ONE_ATMOSPHERE*50)

	if("init" in signal.data)
		name = signal.data["init"]
		return

	if("status" in signal.data)
		spawn(2)
			broadcast_status()
		return //do not update_icon

		//log_admin("DEBUG \[[world.timeofday]\]: vent_pump/receive_signal: unknown command \"[signal.data["command"]]\"\n[signal.debug_print()]")
	spawn(2)
		broadcast_status()
	update_icon()
	return

/obj/machinery/atmospherics/components/unary/vent_pump/attackby(obj/item/W, mob/user, params)
	if (istype(W, /obj/item/weapon/wrench)&& !(stat & NOPOWER) && on)
		user << "<span class='warning'>You cannot unwrench this [src], turn it off first!</span>"
		return 1
	if(istype(W, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/WT = W
		if (WT.remove_fuel(0,user))
			playsound(loc, 'sound/items/Welder.ogg', 40, 1)
			user << "<span class='notice'>You begin welding the vent...</span>"
			if(do_after(user, 20, target = src))
				if(!src || !WT.isOn()) return
				playsound(src.loc, 'sound/items/Welder2.ogg', 50, 1)
				if(!welded)
					user.visible_message("[user] welds the vent shut.", "<span class='notice'>You weld the vent shut.</span>", "<span class='italics'>You hear welding.</span>")
					welded = 1
					update_icon()
				else
					user.visible_message("[user] unwelds the vent.", "<span class='notice'>You unweld the vent.</span>", "<span class='italics'>You hear welding.</span>")
					welded = 0
					update_icon()
			return 1
	else
		return ..()

/obj/machinery/atmospherics/components/unary/vent_pump/examine(mob/user)
	..()
	if(welded)
		user << "It seems welded shut."

/obj/machinery/atmospherics/components/unary/vent_pump/power_change()
	if(powered(power_channel))
		stat &= ~NOPOWER
	else
		stat |= NOPOWER
	update_icon_nopipes()

/obj/machinery/atmospherics/components/unary/vent_pump/Destroy()
	if(initial_loc)
		initial_loc.air_vent_info -= id_tag
		initial_loc.air_vent_names -= id_tag
	..()


/obj/machinery/atmospherics/components/unary/vent_pump/can_crawl_through()
	return !welded

/*
	Alt-click to ventcrawl
*/
/obj/machinery/atmospherics/components/unary/vent_pump/AltClick(var/mob/living/L)
	if(!isliving(L) || !Adjacent(L)|| !L.ventcrawler)
		return
	if(L.stat)
		L << "You must be conscious to do this!"
		return
	if(L.lying)
		L << "You can't vent crawl while you're stunned!"
		return
	if(!isturf(L.loc))
		L << "You can't vent crawl while you're inside [L.loc]!"
		return
	if(iscarbon(L))
		var/mob/living/carbon/C = L
		if(C.handcuffed)
			return

	if(welded)
		L << "That vent is welded shut."
		return


	var/list/vents = list()
	var/datum/pipeline/vent_parent = parents["p1"]

	for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent in vent_parent.other_atmosmch)
		if(temp_vent.welded)
			continue
		if(temp_vent in loc)
			continue
		var/turf/T = get_turf(temp_vent)

		if(!T || T.z != loc.z)
			continue

		var/index = temp_vent.name
		vents[index] = temp_vent
	if(!vents.len)
		L << "<span class='warning'>There are no available vents to travel to, they could be welded. </span>"
		return

	var/obj/selection = input(L,"Select a destination.", "Duct System") as null|anything in sortList(vents)
	if(!selection)
		return

	if(!Adjacent(L) || L.stat || L.lying || !L.ventcrawler || welded)
		return
	if(iscarbon(L))
		var/mob/living/carbon/C = L
		if(L.ventcrawler < 2)
			for(var/obj/item/carried_item in L.contents)
				if(!istype(carried_item, /obj/item/weapon/implant))//If it's not an implant
					L << "<span class='warning'>You can't be carrying items or have items equipped when vent crawling!</span>"
					return
		if(C.handcuffed)
			return
	if(isborer(L))
		var/mob/living/simple_animal/borer/B = L
		if (B.host)
			L << "You cannot ventcrawl while inside a host"
			return


	var/obj/machinery/atmospherics/components/unary/vent_pump/target_vent = vents[selection]
	if(!target_vent)
		return

	L.visible_message("<span class='notice'>[L] scrambles into the ventilation ducts!</span>", \
						"<span class='notice'>You scramble into the ventilation ducts.</span>")

	target_vent.audible_message("<span class='notice'>You hear something squeezing through the ventilation ducts.</span>")

	if(target_vent.welded)		//the vent can be welded while they scrolled through the list.
		target_vent = src
		L << "<span class='warning'>The vent you were heading to appears to be welded.</span>"
	L.loc = target_vent.loc
	var/area/new_area = get_area(L.loc)
	if(new_area)
		new_area.Entered(L)


//code for the spawning of pests
/obj/machinery/atmospherics/components/unary/vent_pump/proc/process_pest_spawn()
	pest_ticker ++
	if(pest_ticker > pest_ticker_max) //ticker activates, let's try to spawn a pest
		trash_nearby = 0
		blood_nearby = 0
		corpse_nearby = 0
		pest_nearby = 0
		pest_ticker = 0 //reset the counter
		for(var/obj/item/trash/T in oview(7, src)) 					 		//find trash
			trash_nearby++
		for(var/obj/effect/decal/cleanable/vomit/V in oview(7, src)) 		//find vomit, counts as trash aswell
			if(!istype(V,/obj/effect/decal/cleanable/vomit/old)) 			//prevents old vomit from counting
				trash_nearby++
		for(var/obj/effect/decal/cleanable/blood/B in oview(7, src)) 		//find blood
			if(!istype(B,/obj/effect/decal/cleanable/blood/old)) 			//prevents crusty blood from counting
				blood_nearby ++
		for(var/obj/effect/decal/cleanable/blood/gibs/G in oview(7, src)) 	//find gibs, they count as blood
			if(!istype(G,/obj/effect/decal/cleanable/blood/gibs/old)) 		//prevents old gibs from counting
				blood_nearby ++
		for(var/mob/M in oview(7, src)) 							 //find corpses && pests
			if(istype(M,/mob/living/simple_animal/mouse) || istype(M,/mob/living/simple_animal/hostile/retaliate/bat) || istype(M,/mob/living/simple_animal/hostile/poison/bees/flies))
				if(!M.stat) //dead pests don't count
					pest_nearby ++
			if(M.stat == 2) //they count as corpses, though, alongside any other corpses
				corpse_nearby ++

		//now it spawns the pests. 3 rolls, one for each diferent pest. Chance gets higher the more trash/blood/corpses it finds.
		//If it finds none, prob is still 0 so it doesn't happen.
		if(pest_nearby < pest_max)
			if(prob(pest_chance*trash_nearby))
				new/mob/living/simple_animal/mouse(get_turf(src))
				visible_message("<span class='alert'>A mouse crawls from the vent!</span>", "You hear something squeeking.")
			if(prob(pest_chance*blood_nearby))
				new/mob/living/simple_animal/hostile/retaliate/bat(get_turf(src))
				visible_message("<span class='alert'>A bat flies out of the vent!</span>", "You hear something flapping.")
			if(prob(pest_chance*corpse_nearby))
				new/mob/living/simple_animal/hostile/poison/bees/flies(get_turf(src))
				visible_message("<span class='alert'>A swarm of flies comes from the vent!</span>", "You hear something buzzing.")