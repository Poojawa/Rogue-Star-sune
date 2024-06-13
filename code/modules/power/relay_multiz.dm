///This bridges powernets betwen Z levels
/obj/machinery/power/deck_relay
	name = "Multi-deck power adapter"
	desc = "A huge bundle of double insulated cabling which seems to run up into the ceiling. There is no way to seperate power channels!"
	icon = 'icons/obj/cables/structures.dmi'
	icon_state = "cablerelay-off"
	level = 1
	plane = PLATING_PLANE
	layer = WIRE_MULTIZ_LAYER
	cable_layer = CABLE_LAYER_1|CABLE_LAYER_2|CABLE_LAYER_3|CABLE_LAYER_4
	var/obj/machinery/power/deck_relay/connectionup
	var/obj/machinery/power/deck_relay/connectiondown
	anchored = TRUE
	density = FALSE
	can_change_cable_layer = TRUE	//This should be false when power channel code works
	var/patched = FALSE
	/// Powernet channels list
	/*	//TODO: Actually making these channels a thing.
	var/datum/powernet/powernet1
	var/datum/powernet/powernet2
	var/datum/powernet/powernet3
	var/datum/powernet/powernet4
	var/list/powernets = list()*/

/obj/machinery/power/deck_relay/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(find_and_connect)), 30)
	addtimer(CALLBACK(src, PROC_REF(refresh)), 50) //Wait a bit so we can find the one below, then get powering
	if(level==1)
		var/turf/T = loc
		hide(!T.is_plating())

/obj/machinery/deck_relay/terminal/hide(i)
	if(i)
		invisibility = INVISIBILITY_MAXIMUM
	else
		invisibility = 0

/*	//Until we have clean power channels, we only have the one connection
//don't override our layering for this, since we omni-connect.
/obj/machinery/power/deck_relay/adapt_to_cable_layer()
	cable_layer = CABLE_LAYER_1|CABLE_LAYER_2|CABLE_LAYER_3|CABLE_LAYER_4
	return */

/obj/machinery/power/deck_relay/update_icon()
	if(stat & BROKEN)
		icon_state = "cablerelay-broken"
		return
	if(!connectiondown || QDELETED(connectiondown) || !connectionup || QDELETED(connectionup) || (powernet && (powernet.avail <= 0)))
		icon_state = "cablerelay-off"
		if(patched)
			icon_state = "cablerelay-off-patched"
	else
		icon_state = "cablerelay-on"
		if(patched)
			icon_state = "cablerelay-on-patched"

/obj/machinery/power/deck_relay/Destroy()
	. = ..()
	investigate_log("<font color='red'>deleted</font> at [COORD(src)]","powernet")
	if(connectionup) //Lose connections
		connectionup.connectiondown = null
	if(connectiondown)
		connectiondown.connectionup = null
	if(powernet)
		powernet = null
/*	if(powernet1)
		powernet1 = null
	if(powernet2)
		powernet2 = null
	if(powernet3)
		powernet3 = null
	if(powernet4)
		powernet4 = null
	powernets.Cut()*/
	return TRUE

/obj/machinery/power/deck_relay/process()
	if(!anchored)
		if(stat & BROKEN)
			icon_state = "cablerelay-broken"
		else
			icon_state = "cablerelay-off"
			if(patched)
				icon_state = "cablerelay-off-patched"
		if(connectionup) //Lose connections
			connectionup.connectiondown = null
		if(connectiondown)
			connectiondown.connectionup = null
		if(powernet)
			powernet = null
	/*	if(powernet2)
			powernet2 = null
		if(powernet3)
			powernet3 = null
		if(powernet4)
			powernet4 = null
		powernets.Cut() */
		return
	if(stat & BROKEN)
		if(connectionup) //Lose connections here too
			connectionup.connectiondown = null
		if(connectiondown)
			connectiondown.connectionup = null
		if(powernet)
			powernet = null
		icon_state = "cablerelay-broken"
		return
	refresh() //Sometimes the powernets get lost, so we need to keep checking.
	if(powernet && (powernet.avail <= 0))		// is it powered?
		icon_state = "cablerelay-off"
		if(patched)
			icon_state = "cablerelay-off-patched"

	icon_state = "cablerelay-on"
	if(patched)
		icon_state = "cablerelay-on-patched"

	/* if(!powernets)
		icon_state = "cablerelay-off"

	if(!connectiondown || QDELETED(connectiondown) || !connectionup || QDELETED(connectionup))
		icon_state = "cablerelay-off"
		find_and_connect()

	for(var/datum/powernet/connections in powernets) //this was a dumb plan, todo: overlays and blinky light overlays for each power channel connection & status
		var/missingnet = 0
		if(connections && (connections.avail > 0))
			continue
		else if(connections && (connections.avail <= 0))
			missingnet++
		else if(!connections)
			missingnet++
		else if(missingnet == 4)
			icon_state = "cablerelay-off"
		else
			icon_state = "cablerelay-on" */

/obj/machinery/power/deck_relay/hides_under_flooring()	//Some routing is just painful
	return TRUE

///Handles re-acquiring + merging powernets found by find_and_connect()
/obj/machinery/power/deck_relay/proc/refresh()
	if(connectiondown)
		connectiondown.merge(src)
	if(connectionup)
		connectionup.merge(src)

/obj/machinery/power/deck_relay/proc/merge(var/obj/machinery/power/deck_relay/MZ)
	if(!MZ)
		return
	var/turf/merge_from = get_turf(MZ)
	var/turf/merge_to = get_turf(src)

	var/obj/structure/cable/C = merge_from.get_cable_node()
	var/obj/structure/cable/XR = merge_to.get_cable_node()
	if(C && XR)
		merge_powernets(XR.powernet,C.powernet)//Bridge the powernets.

	/*
	//Let's try to match up each other's powernets, without just mixing willy-nilly.
	// probably better as a seperate proc when channels are figured out.
	if(powernet1 && MZ.powernet1)
		var/obj/structure/cable/C = merge_from.get_cable_node(CABLE_LAYER_1)
		var/obj/structure/cable/XR = merge_to.get_cable_node(CABLE_LAYER_1)
		if(C && XR)
			merge_powernets(XR.powernet,C.powernet)
	else if(powernet2 && MZ.powernet2)
		var/obj/structure/cable/C = merge_from.get_cable_node(CABLE_LAYER_2)
		var/obj/structure/cable/XR = merge_to.get_cable_node(CABLE_LAYER_2)
		if(C && XR)
			merge_powernets(XR.powernet,C.powernet)
	else if(powernet3 && MZ.powernet3)
		var/obj/structure/cable/C = merge_from.get_cable_node(CABLE_LAYER_3)
		var/obj/structure/cable/XR = merge_to.get_cable_node(CABLE_LAYER_3)
		if(C && XR)
			merge_powernets(XR.powernet,C.powernet)
	else if(powernet4 && MZ.powernet4)
		var/obj/structure/cable/C = merge_from.get_cable_node(CABLE_LAYER_4)
		var/obj/structure/cable/XR = merge_to.get_cable_node(CABLE_LAYER_4)
		if(C && XR)
			merge_powernets(XR.powernet,C.powernet) */

///Locates relays that are above and below this object
/obj/machinery/power/deck_relay/proc/find_and_connect()
	if(stat & BROKEN)
		//don't even bother, we're broken after all.
		return

	var/turf/T = get_turf(src)
	if(!T || !istype(T))
		return FALSE
	connectiondown = null //in case we're re-establishing
	connectionup = null
//	powernets.Cut()
	var/obj/structure/cable/C = T.get_cable_node() //check if we have a node cable on the machine turf, the first found is picked
	if(C && C.powernet)
		C.powernet.add_machine(src) //Nice we're in.
		powernet = C.powernet
/* // Commented out until someone helps me figure out how to search all nodes lol
	//Find our local cable nodes first
	for(var/obj/structure/cable/C in T.contents)
		if(!C)
			return
		var/list/foundcables = list()
		C = T.get_cable_node() //check if we have a node cable on the machine turf.
		//we only have four layers of cable, and they *shouldn't* have more than one per tile.
		foundcables.Add(C)
		to_world_log("[name] has found [C] for foundcables: [foundcables.len]")
		for(C in foundcables)
			if(!C)
				return
			var/list/foundnodes = list()
			foundnodes.Add(C)
			to_world_log("[name] has found [C] in [foundnodes]")
			powernet = null	//because apparently I can't have nice things.
			for(C in foundnodes[C])
				if(C.powernet)
					to_world_log("[C] has a powernet, it's [C.powernet] on layer [C.cable_layer]")
					switch(C.cable_layer)
						if(CABLE_LAYER_1)
							if(powernet1)
								continue //we've already checked here, try the next one.
							powernet1 = C.powernet
							powernet = null
							C.powernet.add_relays_together(src, C.powernet, CABLE_LAYER_1)
							powernets |= powernet1
							return

						if(CABLE_LAYER_2)
							if(powernet2)
								return
							powernet2 = C.powernet
							powernet = null
							C.powernet.add_relays_together(src, C.powernet, CABLE_LAYER_2)
							powernets |= powernet2
							return

						if(CABLE_LAYER_3)
							if(powernet3)
								return
							powernet3 = C.powernet
							powernet = null
							C.powernet.add_relays_together(src, C.powernet, CABLE_LAYER_3)
							powernets |= powernet3
							return

						if(CABLE_LAYER_4)
							if(powernet4)
								return
							powernet4 = C.powernet
							powernet = null
							C.powernet.add_relays_together(src, C.powernet, CABLE_LAYER_4)
							powernets |= powernet4
							return
						else
							return
				else
					return */

	for(var/direction in list(DOWN, UP))
		var/turf/TD = get_zstep(src, direction)
		if(!TD) continue
		var/obj/machinery/power/deck_relay/MZ = locate(/obj/machinery/power/deck_relay, TD)
		if(!MZ) continue
		if(direction == DOWN && (src.z in using_map.below_blocked_levels)) continue
		if(direction == UP && (MZ.z in using_map.below_blocked_levels)) continue
		if(direction == UP)
			connectionup = MZ
		if(direction == DOWN)
			connectiondown = MZ
	return TRUE

/obj/machinery/power/deck_relay/examine(mob/user)
	. = ..()
	. += span_notice("[connectionup ? "Detected" : "Undetected"] hub UP.")
	. += span_notice("[connectiondown ? "Detected" : "Undetected"] hub DOWN.")
	. += span_notice("Alt Click to initiate a power cycle and reconnect grids between decks.")
	/*
	if(powernet1)
		. += span_notice("The [LOWER_TEXT(GLOB.cable_layer_to_name["[CABLE_LAYER_1]"])] is connected.")
	if(powernet2)
		. += span_notice("The [LOWER_TEXT(GLOB.cable_layer_to_name["[CABLE_LAYER_2]"])] is connected.")
	if(powernet3)
		. += span_notice("The [LOWER_TEXT(GLOB.cable_layer_to_name["[CABLE_LAYER_3]"])] is connected.")
	if(powernet4)
		. += span_notice("The [LOWER_TEXT(GLOB.cable_layer_to_name["[CABLE_LAYER_4]"])] is connected.") */

/obj/machinery/power/deck_relay/AltClick(mob/living/user)	//Ctrl click is pull and it was annoying me
	to_chat(user, span_warning("You push the reset button."))
	addtimer(CALLBACK(src, PROC_REF(find_and_connect)), 30, TIMER_UNIQUE)
	addtimer(CALLBACK(src, PROC_REF(refresh)), 50, TIMER_UNIQUE)

/obj/machinery/power/deck_relay/proc/deconstruct()
	new /obj/item/stack/cable_coil/random(drop_location(), CABLE_CONSTRUCTIONS_COSTS)
	qdel(src)

/obj/machinery/power/deck_relay/attackby(obj/item/O, mob/user)
	if(default_unfasten_wrench(user, O, 40))
		update_cable_icons_on_turf(get_turf(src))
		if(anchored)
			find_and_connect()
		return FALSE

	if(O.has_tool_quality(TOOL_WIRECUTTER))
		if(stat & BROKEN)
			user.visible_message(span_warning("[user] is cutting out \the [src]!"), span_notice("You start to cut \the [src] completely out."))
			playsound(src, O.usesound, 50, 1)
			if(do_after(user, 20 * O.toolspeed))
				user.visible_message(span_warning("[user] removes \the [src]."), span_notice("You finish removing \the [src] entirely."))
				deconstruct()
		else
			user.visible_message(span_warning("[user] is cutting up \the [src]!"), span_notice("You start to cut \the [src]."))
			playsound(src, O.usesound, 50, 1)
			if(do_after(user, 20 * O.toolspeed))
				user.visible_message(span_notice("[user] mangles the wiring in \the [src]."), span_notice("You mangle the wires of \the [src]."))
				stat |= BROKEN
				patched = FALSE
				return

	if(O.has_tool_quality(TOOL_CABLE_COIL))	//the rare heavy cable repair permitted, too.
		var/obj/item/stack/cable_coil/cables = O
		if(stat & BROKEN)
			if(cables.apply_wiring(5))
				stat &= ~BROKEN
				patched = TRUE
				user.visible_message(span_notice("[user.name] has patched the wiring of \the [src]."), span_notice("You patch \the [src] wires."))
				return
			else
				to_chat(user, span_warning("You need at least five lengths of cable to repair this relay."))
				return

	if(O.has_tool_quality(TOOL_MULTITOOL))
		visible_message(span_notice("[user] adjusts the plugged in cable layer."))
		adapt_to_cable_layer()
		return
	. = ..()
