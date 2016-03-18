/obj/machinery/recharger
	name = "recharger"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "recharger0"
	desc = "A charging dock for energy based weaponry."
	anchored = 1
	use_power = 1
	idle_power_usage = 4
	active_power_usage = 250
	var/obj/item/weapon/charging = null
	var/recharge_coeff = 1
 
/obj/machinery/recharger/New()
	..()
	component_parts = list()
	component_parts += new /obj/item/weapon/circuitboard/recharger()
	component_parts += new /obj/item/weapon/stock_parts/capacitor()
	RefreshParts()

/obj/machinery/recharger/RefreshParts()
	for(var/obj/item/weapon/stock_parts/capacitor/C in component_parts)
		recharge_coeff = C.rating


/obj/machinery/recharger/attackby(obj/item/weapon/G, mob/user, params)
	if(istype(user,/mob/living/silicon) && !ismommi(user))
		return
	if(istype(G, /obj/item/weapon/gun/energy) || istype(G, /obj/item/weapon/melee/baton))
		if(charging || panel_open)
			return

		//Checks to make sure he's not in space doing it, and that the area got proper power.
		var/area/a = get_area(src)
		if(!isarea(a) || a.power_equip == 0)
			user << "<span class='notice'>[src] blinks red as you try to insert [G].</span>"
			return

		if (istype(G, /obj/item/weapon/gun/energy))
			var/obj/item/weapon/gun/energy/gun = G
			if(!gun.can_charge)
				user << "<span class='notice'>Your gun has no external power connector.</span>"
				return

		user.drop_item()
		G.loc = src
		charging = G
		use_power = 2
		update_icon()
	else if(istype(G, /obj/item/weapon/wrench))
		if(charging)
			user << "<span class='notice'>Remove the charging item first!</span>"
			return
		anchored = !anchored
		user << "<span class='notice'>You [anchored ? "attached" : "detached"] [src].</span>"
		playsound(loc, 'sound/items/Ratchet.ogg', 75, 1)

	else (anchored && !charging)
		if(default_deconstruction_screwdriver(user, "rechargeropen", "recharger0", G))
			return

		if(panel_open && istype(G, /obj/item/weapon/crowbar))
			default_deconstruction_crowbar(G)
			return

/obj/machinery/recharger/attack_hand(mob/user)
	if(issilicon(user) && !ismommi(user))
		return

	add_fingerprint(user)
	if(charging)
		charging.update_icon()
		charging.loc = loc
		user.put_in_hands(charging)
		charging = null
		use_power = 1
		update_icon()

/obj/machinery/recharger/attack_paw(mob/user)
	return attack_hand(user)

/obj/machinery/recharger/attack_tk(mob/user)
	if(charging)
		charging.update_icon()
		charging.loc = loc
		charging = null
		use_power = 1
		update_icon()

/obj/machinery/recharger/process()
	if(stat & (NOPOWER|BROKEN) || !anchored)
		return

	if(charging)
		if(istype(charging, /obj/item/weapon/gun/energy))
			var/obj/item/weapon/gun/energy/E = charging
			if(E.power_supply.charge < E.power_supply.maxcharge)
				E.power_supply.give(E.power_supply.chargerate * recharge_coeff)
				icon_state = "recharger1"
				use_power(250 * recharge_coeff)
			else
				icon_state = "recharger2"
			return
		if(istype(charging, /obj/item/weapon/melee/baton))
			var/obj/item/weapon/melee/baton/B = charging
			if(B.bcell)
				if(B.bcell.give(B.bcell.chargerate * recharge_coeff))
					icon_state = "recharger1"
					use_power(200 * recharge_coeff)
				else
					icon_state = "recharger2"
			else
				icon_state = "recharger3"


/obj/machinery/recharger/emp_act(severity)
	if(stat & (NOPOWER|BROKEN) || !anchored)
		..(severity)
		return

	if(istype(charging,  /obj/item/weapon/gun/energy))
		var/obj/item/weapon/gun/energy/E = charging
		if(E.power_supply)
			E.power_supply.emp_act(severity)

	else if(istype(charging, /obj/item/weapon/melee/baton))
		var/obj/item/weapon/melee/baton/B = charging
		if(B.bcell)
			B.bcell.charge = 0
	..(severity)


/obj/machinery/recharger/update_icon()	//we have an update_icon() in addition to the stuff in process to make it feel a tiny bit snappier.
	if(charging)
		icon_state = "recharger1"
	else if(panel_open)
		icon_state = "rechargeropen"
	else
		icon_state = "recharger0"
