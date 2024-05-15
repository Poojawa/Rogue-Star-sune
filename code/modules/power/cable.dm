//Use this only for things that aren't a subtype of obj/machinery/power
//For things that are, override "should_have_node()" on them
GLOBAL_LIST_INIT(wire_node_generating_types, typecacheof(list(/obj/structure/grille, /obj/machinery/shield_gen, /obj/item/device/powersink, /obj/machinery/shieldwallgen)))

#define UNDER_SMES -1
#define UNDER_TERMINAL 1

/obj/structure/cable
	level = 1
	anchored =TRUE
	unacidable = TRUE
	var/datum/powernet/powernet
	name = "power cable"
	desc = "A flexible superconducting cable for heavy-duty power transfer."
	icon = 'icons/obj/cables/layer_cable.dmi'
	icon_state = "l2-1-2-4-8-node"
	color = CABLELAYERTWOCOLOR
	layer = WIRES_LAYER
	plane = PLATING_PLANE
	var/linked_dirs = 0 //bitflag
	var/node = FALSE //used for sprites display
	var/cable_layer = CABLE_LAYER_2 //bitflag 1,2,4
	var/obj/machinery/power/breakerbox/breaker_box

/obj/structure/cable/layer1
	color = CABLELAYERONECOLOR
	cable_layer = CABLE_LAYER_1
	layer = WIRES_LAYER - 0.01
	icon_state = "l1-1-2-4-8-node"

/obj/structure/cable/layer3
	color = CABLELAYERTHREECOLOR
	cable_layer = CABLE_LAYER_3
	layer = WIRES_LAYER + 0.01
	icon_state = "l4-1-2-4-8-node"

/obj/structure/cable/yellow
	color = COLOR_YELLOW

/obj/structure/cable/green
	color = COLOR_LIME

/obj/structure/cable/blue
	color = COLOR_BLUE

/obj/structure/cable/pink
	color = COLOR_PINK

/obj/structure/cable/orange
	color = COLOR_ORANGE

/obj/structure/cable/cyan
	color = COLOR_CYAN

/obj/structure/cable/white
	color = COLOR_WHITE

/obj/structure/cable/Initialize(mapload, param_color, layering) //extra vars to handle mapping_helpers
	. = ..()
	GLOB.cable_list += src //add it to the global cable list
	Connect_cable()
	var/turf/T = src.loc			// hide if turf is not intact
	if(level==1) hide(!T.is_plating())
	if(param_color)
		color = param_color
	if(layering)
		cable_layer = layering

/obj/structure/cable/LateInitialize()
	update_icon()

/obj/structure/cable/examine(mob/user)
	. = ..()
	if(isobserver(user))
		. += get_power_info()

///Set the linked indicator bitflags
/obj/structure/cable/proc/Connect_cable(clear_before_updating = FALSE)
	var/under_thing = NONE
	if(clear_before_updating)
		linked_dirs = 0
	var/obj/machinery/power/search_parent
	for(var/obj/machinery/power/P in loc)
		if(istype(P, /obj/machinery/power/terminal))
			under_thing = UNDER_TERMINAL
			search_parent = P
			break
		if(istype(P, /obj/machinery/power/smes))
			under_thing = UNDER_SMES
			search_parent = P
			break
		if(istype(P, /obj/machinery/power/breakerbox))
			under_thing = UNDER_SMES	//Allow breakerboxes to connect directly to the SMES node
			search_parent = P
			break
	for(var/check_dir in GLOB.cardinal)
		var/TB = get_step(src, check_dir)
		//don't link from smes to its terminal
		if(under_thing)
			switch(under_thing)
				if(UNDER_SMES)
					var/obj/machinery/power/terminal/term = locate(/obj/machinery/power/terminal) in TB
					//Why null or equal to the search parent?
					//during map init it's possible for a placed smes terminal to not have initialized to the smes yet
					//but the cable underneath it is ready to link.
					//I don't believe null is even a valid state for a smes terminal while the game is actually running
					//So in the rare case that this happens, we also shouldn't connect
					//This might break.

					//RS add Breaker boxes ought to be able to connect, though.
					if(term && (!term.master || term.master == search_parent))
						continue
				if(UNDER_TERMINAL)
					var/obj/machinery/power/smes/S = locate(/obj/machinery/power/smes) in TB
					for(var/obj/machinery/power/terminal/terms in S.terminalconnections)
						if(S && (!S.terms || terms.master == search_parent))
							continue
		var/inverse = REVERSE_DIR(check_dir)
		for(var/obj/structure/cable/C in TB)
			if(C.cable_layer & cable_layer)
				linked_dirs |= check_dir
				C.linked_dirs |= inverse

	update_icon()

///Clear the linked indicator bitflags
/obj/structure/cable/proc/Disconnect_cable()
	for(var/check_dir in GLOB.cardinal)
		var/inverse = REVERSE_DIR(check_dir)
		if(linked_dirs & check_dir)
			var/TB = get_step(loc, check_dir)
			for(var/obj/structure/cable/C in TB)
				if(cable_layer & C.cable_layer)
					C.linked_dirs &= ~inverse
					C.update_icon()

/obj/structure/cable/Destroy()					// called when a cable is deleted
	//Clear the linked indicator bitflags
	for(var/check_dir in GLOB.cardinal)
		var/inverse = turn(check_dir, 180)
		if(linked_dirs & check_dir)
			var/TB = get_step(loc, check_dir)
			for(var/obj/structure/cable/C in TB)
				if(cable_layer == C.cable_layer)
					C.linked_dirs &= ~inverse
					C.update_icon()

	if(powernet)
		cut_cable_from_powernet()				// update the powernets
	GLOB.cable_list -= src							//remove it from global cable list

	return ..()									// then go ahead and delete the cable

///////////////////////////////////
// General procedures
///////////////////////////////////

//If underfloor, hide the cable
/obj/structure/cable/hide(var/i)
	if(istype(loc, /turf))
		invisibility = i ? 101 : 0
	update_icon()

/obj/structure/cable/hides_under_flooring()
	return 1

/obj/structure/cable/update_icon()
	if(!linked_dirs)
		icon_state = "l[cable_layer]-noconnection"
	else
		var/list/dir_icon_list = list()
		for(var/check_dir in GLOB.cardinal)
			if(linked_dirs & check_dir)
				dir_icon_list += "[check_dir]"
		var/dir_string = dir_icon_list.Join("-")
		if(dir_icon_list.len > 1)
			for(var/obj/O in loc)
				if(GLOB.wire_node_generating_types[O.type])
					dir_string = "[dir_string]-node"
					break
				else if(istype(O, /obj/machinery/power))
					var/obj/machinery/power/P = O
					if(P.should_have_node())
						dir_string = "[dir_string]-node"
						break
		dir_string = "l[cable_layer]-[dir_string]"
		icon_state = dir_string

/obj/structure/cable/proc/handlecable(obj/item/W, mob/user, params)
	var/turf/T = get_turf(src)
	if(!T.is_plating())
		return
	if(W.has_tool_quality(TOOL_WIRECUTTER))

		if(breaker_box)
			to_chat(user, "<span class='warning'>This cable is connected to nearby breaker box. Use breaker box to interact with it.</span>")
			return
		if (shock(user, 50))
			return
		user.visible_message("<span class='notice'>[user] cuts the cable.</span>", "<span class='notice'>You cut the cable.</span>")
		investigate_log("was cut by [key_name(usr, usr.client)] in [user.loc.loc]","wires")
		deconstruct()
		return

	if(W.has_tool_quality(TOOL_MULTITOOL))
		if(powernet && (powernet.avail > 0))		// is it powered?
			to_chat(user, "<span class='danger'>Total power: [DisplayPower(powernet.avail)]\nLoad: [DisplayPower(powernet.load)]\nExcess power: [DisplayPower(powernet.surplus())]</span>")
		else
			to_chat(user, "<span class='danger'>The cable is not powered.</span>")
		shock(user, 5, 0.2)

	else
		if(!(W.flags & NOCONDUCT))
			shock(user, 50, 0.7)

	add_fingerprint(user)

// shock the user with probability prb
/obj/structure/cable/proc/shock(mob/user, prb, var/siemens_coeff = 1.0)
	if(!prob(prb))
		return FALSE
	if (electrocute_mob(user, powernet, src, siemens_coeff))
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
		s.set_up(5, 1, src)
		s.start()
		if(usr.stunned)
			return TRUE
	return FALSE

//explosion handling
/obj/structure/cable/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
		if(2.0)
			if (prob(50))
				new/obj/item/stack/cable_coil(src.loc, color)
				qdel(src)

		if(3.0)
			if (prob(25))
				new/obj/item/stack/cable_coil(src.loc, color)
				qdel(src)
	return

/obj/structure/cable/proc/cableColor(var/colorC)
	var/color_n = "#DD0000"
	if(colorC)
		color_n = colorC
	color = color_n

// Items usable on a cable :
//   - Wirecutters : cut it duh !
//   - Multitool : get the power currently passing through the cable
//
/obj/structure/cable/attackby(obj/item/W, mob/user, params)
	handlecable(W, user, params)

//Telekinesis has no effect on a cable
/obj/structure/cable/attack_tk(mob/user)
	return

/////////////////////////////////////////////////
// Cable laying helpers
////////////////////////////////////////////////

// merge with the powernets of power objects in the given direction
/obj/structure/cable/proc/mergeConnectedNetworks(direction)

	var/inverse_dir = (!direction)? 0 : turn(direction, 180) //flip the direction, to match with the source position on its turf

	var/turf/TB  = get_step(src, direction)

	for(var/obj/structure/cable/C in TB)
		if(!C)
			continue

		if(src == C)
			continue

		if(!(cable_layer & C.cable_layer))
			continue

		if(C.linked_dirs & inverse_dir) //we've got a matching cable in the neighbor turf
			if(!C.powernet) //if the matching cable somehow got no powernet, make him one (should not happen for cables)
				var/datum/powernet/newPN = new()
				newPN.add_cable(C)

			if(powernet) //if we already have a powernet, then merge the two powernets
				merge_powernets(powernet, C.powernet)
			else
				C.powernet.add_cable(src) //else, we simply connect to the matching cable powernet

// merge with the powernets of power objects in the source turf
/obj/structure/cable/proc/mergeConnectedNetworksOnTurf()
	var/list/to_connect = list()
	node = FALSE

	if(!powernet) //if we somehow have no powernet, make one (should not happen for cables)
		var/datum/powernet/newPN = new()
		newPN.add_cable(src)

	//first let's add turf cables to our powernet
	//then we'll connect machines on turf where a cable is present
	for(var/atom/movable/AM in loc)
		if(istype(AM, /obj/machinery/power/apc))
			var/obj/machinery/power/apc/N = AM
			if(!N.terminal)
				continue // APC are connected through their terminal

			if(N.terminal.powernet == powernet) //already connected
				continue

			to_connect += N.terminal //we'll connect the machines after all cables are merged

		else if(istype(AM, /obj/machinery/power)) //other power machines
			var/obj/machinery/power/M = AM

			if(M.powernet == powernet)
				continue

			to_connect += M //we'll connect the machines after all cables are merged

	//now that cables are done, let's connect found machines
	for(var/obj/machinery/power/PM in to_connect)
		node = TRUE
		if(!PM.connect_to_network())
			PM.disconnect_from_network() //if we somehow can't connect the machine to the new powernet, remove it from the old nonetheless

//////////////////////////////////////////////
// Powernets handling helpers
//////////////////////////////////////////////

/obj/structure/cable/proc/get_cable_connections(powernetless_only)
	. = list()
	var/turf/T = get_turf(src)
	for(var/check_dir in GLOB.cardinal)
		if(linked_dirs & check_dir)
			T = get_step(src, check_dir)
			for(var/obj/structure/cable/C in T)
				if(cable_layer & C.cable_layer)
					. += C

/obj/structure/cable/proc/get_all_cable_connections(powernetless_only)
	. = list()
	var/turf/T
	for(var/check_dir in GLOB.cardinal)
		T = get_step(src, check_dir)
		for(var/obj/structure/cable/C in T.contents - src)
			. += C

/obj/structure/cable/proc/get_machine_connections(powernetless_only)
	. = list()
	for(var/obj/machinery/power/P in get_turf(src))
		if(!powernetless_only || !P.powernet)
			if(P.anchored)
				. += P

/obj/structure/cable/proc/auto_propagate_cut_cable(obj/O)
	if(O && !QDELETED(O))
		var/datum/powernet/newPN = new()// creates a new powernet...
		propagate_network(O, newPN)//... and propagates it to the other side of the cable

//Makes a new network for the cable and propgates it.
//If it finds another network in the process, aborts and uses that one and propagates off of it instead
/obj/structure/cable/proc/propagate_if_no_network()
	if(powernet)
		return
	var/datum/powernet/newPN = new()
	propagate_network(src, newPN, TRUE)

// cut the cable's powernet at this cable and updates the powergrid
/obj/structure/cable/proc/cut_cable_from_powernet(remove = TRUE)
	if(!powernet)
		return

	var/turf/T1 = loc
	if(!T1)
		return

	//clear the powernet of any machines on tile first
	for(var/obj/machinery/power/P in T1)
		P.disconnect_from_network()

	var/list/P_list = list()
	for(var/dir_check in GLOB.cardinal)
		if(linked_dirs & dir_check)
			T1 = get_step(loc, dir_check)
			P_list += locate(/obj/structure/cable) in T1

	// remove the cut cable from its turf and powernet, so that it doesn't get count in propagate_network worklist
	if(remove)
		moveToNullspace()
	powernet.remove_cable(src) //remove the cut cable from its powernet

	var/first = TRUE
	for(var/obj/O in P_list)
		if(first)
			first = FALSE
			continue
		addtimer(CALLBACK(O, .proc/auto_propagate_cut_cable, O), 0) //so we don't rebuild the network X times when singulo/explosion destroys a line of X cables

///////////////////////////////////////////////
// The cable coil object, used for laying cable
///////////////////////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////

/obj/item/stack/cable_coil
	name = "cable coil"
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	amount = MAXCOIL
	max_amount = MAXCOIL
	color = COLOR_RED
	gender = NEUTER
	desc = "A coil of power cable."
	throwforce = 10
	w_class = ITEMSIZE_SMALL
	throw_speed = 2
	throw_range = 5
	matter = list(MAT_STEEL = 50, MAT_GLASS = 20)
	slot_flags = SLOT_BELT
	item_state = "coil"
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")
	stacktype = /obj/item/stack/cable_coil
	singular_name = "length"
	drop_sound = 'sound/items/drop/accessory.ogg'
	pickup_sound = 'sound/items/pickup/accessory.ogg'
	tool_qualities = list(TOOL_CABLE_COIL)
	singular_name = "cable"

/obj/item/stack/cable_coil/cyborg
	name = "cable coil synthesizer"
	desc = "A device that makes cable."
	gender = NEUTER
	matter = null
	uses_charge = 1
	charge_costs = list(1)

////////////////////////////////
// Definitions
////////////////////////////////

GLOBAL_LIST_INIT(cable_coil_recipes, list(
				new/datum/stack_recipe("cable restraints", /obj/item/weapon/handcuffs/cable, 15),
				new/datum/stack_recipe("multilayer cable", /obj/structure/cable/multilayer, 1),
				new/datum/stack_recipe("multiZ cable", /obj/structure/cable/multilayer/multiz, 1)
				))

/obj/item/stack/cable_coil
	name = "cable coil"
	gender = NEUTER //That's a cable coil sounds better than that's some cable coils
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	item_state = "coil"
	max_amount = MAXCOIL
	amount = MAXCOIL
//	merge_type = /obj/item/stack/cable_coil // This is here to let its children merge between themselves
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_RED
	desc = "A coil of insulated power cable."
	throwforce = 0
	w_class = ITEMSIZE_SMALL
	slot_flags = SLOT_BELT
	throw_speed = 3
	throw_range = 5
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")
	singular_name = "length"
	drop_sound = 'sound/items/drop/accessory.ogg'
	pickup_sound = 'sound/items/pickup/accessory.ogg'
	singular_name = "cable"
	usesound = 'sound/items/deconstruct.ogg'
	var/obj/structure/cable/target_type = /obj/structure/cable
	var/target_layer = CABLE_LAYER_2
	matter = list(MAT_STEEL = 50, MAT_GLASS = 20)
	tool_qualities = list(TOOL_CABLE_COIL)

/obj/item/stack/cable_coil/Initialize(mapload, new_amount = null)
	. = ..()
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	update_icon()
	recipes = GLOB.cable_coil_recipes

/obj/item/stack/cable_coil/examine(mob/user)
	. = ..()
	. += "<b>Ctrl+Click</b> to change the layer you are placing on."
	. += ""

/obj/item/stack/cable_coil/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

GLOBAL_LIST(cable_radial_layer_list)

/obj/item/stack/cable_coil/CtrlClick(mob/living/user)
	if(loc!=user)
		return ..()
	if(!user)
		return
	if(!GLOB.cable_radial_layer_list)
		GLOB.cable_radial_layer_list = list(
		"Layer 1" = image(icon = 'icons/mob/radial.dmi', icon_state = "coil-red"),
		"Layer 2" = image(icon = 'icons/mob/radial.dmi', icon_state = "coil-yellow"),
		"Layer 3" = image(icon = 'icons/mob/radial.dmi', icon_state = "coil-blue"),
		"Multilayer cable hub" = image(icon = 'icons/obj/cables/structures.dmi', icon_state = "cable_bridge"),
		"Multi Z layer cable hub" = image(icon = 'icons/obj/cables/structures.dmi', icon_state = "cablerelay-broken-cable")
		)
	var/layer_result = show_radial_menu(user, src, GLOB.cable_radial_layer_list, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(layer_result)
		if("Layer 1")
			if(istype(src, /obj/item/stack/cable_coil/alien))
				target_type = /obj/structure/cable/layer1
				target_layer = CABLE_LAYER_1
				icon = 'icons/obj/abductor.dmi'
				icon_state = "coil"
				return //snowflake ayylmao cable just gets its layers updated
			name = "cable coil"
			icon_state = "coil"
			color = CABLELAYERONECOLOR
			target_type = /obj/structure/cable/layer1
			target_layer = CABLE_LAYER_1
		if("Layer 2")
			if(istype(src, /obj/item/stack/cable_coil/alien))
				target_type = /obj/structure/cable
				target_layer = CABLE_LAYER_2
				icon = 'icons/obj/abductor.dmi'
				icon_state = "coil"
				return
			name = "cable coil"
			icon_state = "coil"
			color = CABLELAYERTWOCOLOR
			target_type = /obj/structure/cable
			target_layer = CABLE_LAYER_2
		if("Layer 3")
			if(istype(src, /obj/item/stack/cable_coil/alien))
				target_type = /obj/structure/cable/layer3
				target_layer = CABLE_LAYER_3
				icon = 'icons/obj/abductor.dmi'
				icon_state = "coil"
				return
			name = "cable coil"
			icon_state = "coil"
			color = CABLELAYERTHREECOLOR
			target_type = /obj/structure/cable/layer3
			target_layer = CABLE_LAYER_3
		if("Multilayer cable hub")
			if(istype(src, /obj/item/stack/cable_coil/alien))
				target_type = /obj/structure/cable/multilayer
				target_layer = CABLE_LAYER_2
				icon = 'icons/obj/cables/structures.dmi'
				icon_state = "cable_bridge"
				return
			name = "multilayer cable hub"
			icon_state = "cable_bridge"
			color = "white"
			target_type = /obj/structure/cable/multilayer
			target_layer = CABLE_LAYER_2
		if("Multi Z layer cable hub")
			if(istype(src, /obj/item/stack/cable_coil/alien))
				target_type = /obj/structure/cable/multilayer/multiz
				target_layer = CABLE_LAYER_2
				icon = 'icons/obj/cables/structures.dmi'
				icon_state = "cablerelay-broken-cable"
				return
			name = "multi z layer cable hub"
			icon_state = "cablerelay-broken-cable"
			color = "white"
			target_type = /obj/structure/cable/multilayer/multiz
			target_layer = CABLE_LAYER_2
	update_icon()

///////////////////////////////////
// General procedures
///////////////////////////////////

//you can use wires to heal robotics
/obj/item/stack/cable_coil/attack(var/atom/A, var/mob/living/user, var/def_zone)
	if(ishuman(A) && user.a_intent == I_HELP)
		var/mob/living/carbon/human/H = A
		var/obj/item/organ/external/S = H.organs_by_name[user.zone_sel.selecting]

		if(!S || S.robotic < ORGAN_ROBOT || S.open == 3)
			return ..()

		//VOREStation Add - No welding nanoform limbs
		if(S.robotic > ORGAN_LIFELIKE)
			return ..()
		//VOREStation Add End

		if(S.organ_tag == BP_HEAD)
			if(H.head && istype(H.head,/obj/item/clothing/head/helmet/space))
				to_chat(user, "<span class='warning'>You can't apply [src] through [H.head]!</span>")
				return 1
		else
			if(H.wear_suit && istype(H.wear_suit,/obj/item/clothing/suit/space))
				to_chat(user, "<span class='warning'>You can't apply [src] through [H.wear_suit]!</span>")
				return 1

		var/use_amt = min(src.amount, CEILING(S.burn_dam/5, 1), 5)
		if(can_use(use_amt))
			if(S.robo_repair(5*use_amt, BURN, "some damaged wiring", src, user))
				src.use(use_amt)

	else
		return ..()

/obj/item/stack/cable_coil/update_icon()
	if (!color)
		color = pick(COLOR_RED, COLOR_BLUE, COLOR_LIME, COLOR_ORANGE, COLOR_WHITE, COLOR_PINK, COLOR_YELLOW, COLOR_CYAN)
	if(amount == 1)
		icon_state = "coil1"
		name = "cable piece"
	else if(amount == 2)
		icon_state = "coil2"
		name = "cable piece"
	else
		icon_state = "coil"
		name = initial(name)

/obj/item/stack/cable_coil/proc/set_cable_color(var/selected_color, var/user)
	if(!selected_color)
		return

	var/final_color = GLOB.possible_cable_coil_colours[selected_color]
	if(!final_color)
		final_color = GLOB.possible_cable_coil_colours["Red"]
		selected_color = "red"
	color = final_color
	to_chat(user, "<span class='notice'>You change \the [src]'s color to [lowertext(selected_color)].</span>")

/obj/item/stack/cable_coil/proc/update_wclass()
	if(amount == 1)
		w_class = ITEMSIZE_TINY
	else
		w_class = ITEMSIZE_SMALL

/obj/item/stack/cable_coil/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/device/multitool))
		var/selected_type = tgui_input_list(usr, "Pick new colour.", "Cable Colour", GLOB.possible_cable_coil_colours)
		set_cable_color(selected_type, usr)
		return
	return ..()

/obj/item/stack/cable_coil/verb/make_restraint()
	set name = "Make Cable Restraints"
	set category = "Object"
	var/mob/M = usr

	if(ishuman(M) && !M.restrained() && !M.stat && !M.paralysis && ! M.stunned)
		if(!istype(usr.loc,/turf)) return
		if(src.amount <= 14)
			to_chat(usr, "<span class='warning'>You need at least 15 lengths to make restraints!</span>")
			return
		var/obj/item/weapon/handcuffs/cable/B = new /obj/item/weapon/handcuffs/cable(usr.loc)
		B.color = color
		to_chat(usr, "<span class='notice'>You wind some cable together to make some restraints.</span>")
		src.use(15)
	else
		to_chat(usr, "<span class='notice'>You cannot do that.</span>")

/obj/item/stack/cable_coil/cyborg/verb/set_colour()
	set name = "Change Colour"
	set category = "Object"

	var/selected_type = tgui_input_list(usr, "Pick new colour.", "Cable Colour", GLOB.possible_cable_coil_colours)
	set_cable_color(selected_type, usr)

// Items usable on a cable coil :
//   - Wirecutters : cut them duh !
//   - Cable coil : merge cables

/obj/item/stack/cable_coil/transfer_to(obj/item/stack/cable_coil/S)
	if(!istype(S))
		return
	..()

/obj/item/stack/cable_coil/use()
	. = ..()
	update_icon()
	return

/obj/item/stack/cable_coil/add()
	. = ..()
	update_icon()
	return

///////////////////////////////////////////////
// Cable laying procedures
//////////////////////////////////////////////

// called when cable_coil is clicked on a turf
/obj/item/stack/cable_coil/proc/place_turf(turf/T, mob/user, dirnew)
	if(!isturf(user.loc))
		return

	if(!isturf(T) || T.is_plating() || !T.can_have_cabling())
		to_chat(user, "<span class='warning'>You can only lay cables on catwalks and plating!</span>")
		return

	if(get_amount() < 1) // Out of cable
		to_chat(user, "<span class='warning'>There is no cable left!</span>")
		return

	if(get_dist(T,user) > 1) // Too far
		to_chat(user, "<span class='warning'>You can't lay cable at a place that far away!</span>")
		return

	for(var/obj/structure/cable/C in T)
		if(C.cable_layer & target_layer)
			to_chat(user, "<span class='warning'>There's already a cable at that position!</span>")
			return

	var/obj/structure/cable/C = new target_type(T)

	//create a new powernet with the cable, if needed it will be merged later
	var/datum/powernet/PN = new()
	PN.add_cable(C)

	for(var/dir_check in GLOB.cardinal)
		C.mergeConnectedNetworks(dir_check) //merge the powernet with adjacents powernets
	C.mergeConnectedNetworksOnTurf() //merge the powernet with on turf powernets

	use(1)

	if(C.shock(user, 50))
		if(prob(50)) //fail
			new /obj/item/stack/cable_coil(get_turf(C), 1)
			C.deconstruct()

	return C

/obj/item/stack/cable_coil/five
	amount = 5

/obj/item/stack/cable_coil/cut
	amount = null
	icon_state = "coil2"

/obj/item/stack/cable_coil/cut/Initialize(mapload)
	. = ..()
	if(!amount)
		amount = rand(1,2)
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	update_icon()

#undef UNDER_SMES
#undef UNDER_TERMINAL

/obj/item/stack/cable_coil/yellow
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_YELLOW

/obj/item/stack/cable_coil/blue
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_BLUE

/obj/item/stack/cable_coil/green
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_LIME

/obj/item/stack/cable_coil/pink
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_PINK

/obj/item/stack/cable_coil/orange
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_ORANGE

/obj/item/stack/cable_coil/cyan
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_CYAN

/obj/item/stack/cable_coil/white
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_WHITE

/obj/item/stack/cable_coil/silver
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_SILVER

/obj/item/stack/cable_coil/gray
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_GRAY

/obj/item/stack/cable_coil/black
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_BLACK

/obj/item/stack/cable_coil/maroon
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_MAROON

/obj/item/stack/cable_coil/olive
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_OLIVE

/obj/item/stack/cable_coil/lime
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_LIME

/obj/item/stack/cable_coil/teal
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_TEAL

/obj/item/stack/cable_coil/navy
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_NAVY

/obj/item/stack/cable_coil/purple
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_PURPLE

/obj/item/stack/cable_coil/beige
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_BEIGE

/obj/item/stack/cable_coil/brown
	stacktype = /obj/item/stack/cable_coil
	color = COLOR_BROWN

/obj/item/stack/cable_coil/random/New()
	stacktype = /obj/item/stack/cable_coil
	color = pick(COLOR_RED, COLOR_BLUE, COLOR_LIME, COLOR_WHITE, COLOR_PINK, COLOR_YELLOW, COLOR_CYAN, COLOR_SILVER, COLOR_GRAY, COLOR_BLACK, COLOR_MAROON, COLOR_OLIVE, COLOR_LIME, COLOR_TEAL, COLOR_NAVY, COLOR_PURPLE, COLOR_BEIGE, COLOR_BROWN)
	..()

/obj/item/stack/cable_coil/random_belt/New()
	stacktype = /obj/item/stack/cable_coil
	color = pick(COLOR_RED, COLOR_YELLOW, COLOR_ORANGE)
	amount = 30
	..()

//Endless alien cable coil

/datum/category_item/catalogue/anomalous/precursor_a/alien_wire
	name = "Precursor Alpha Object - Recursive Spool"
	desc = "Upon visual inspection, this merely appears to be a \
	spool for silver-colored cable. If one were to use this for \
	some time, however, it would become apparent that the cables \
	inside the spool appear to coil around the spool endlessly, \
	suggesting an infinite length of wire.\
	<br><br>\
	In reality, an infinite amount of something within a finite space \
	would likely not be able to exist. Instead, the spool likely has \
	some method of creating new wire as it is unspooled. How this is \
	accomplished without an apparent source of material would require \
	further study."
	value = CATALOGUER_REWARD_EASY

/obj/item/stack/cable_coil/alien
	name = "alien spool"
	desc = "A spool of cable. No matter how hard you try, you can never seem to get to the end."
	catalogue_data = list(/datum/category_item/catalogue/anomalous/precursor_a/alien_wire)
	icon = 'icons/obj/abductor.dmi'
	icon_state = "coil"
	amount = MAXCOIL
	max_amount = MAXCOIL
	color = COLOR_SILVER
	throwforce = 10
	w_class = ITEMSIZE_SMALL
	throw_speed = 2
	throw_range = 5
	matter = list(MAT_STEEL = 50, MAT_GLASS = 20)
	slot_flags = SLOT_BELT
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")
	stacktype = null
	toolspeed = 0.25

/obj/item/stack/cable_coil/alien/New(loc, amount = MAXCOIL, var/param_color = null)		//There has to be a better way to do this.
	if(embed_chance == -1)		//From /obj/item, don't want to do what the normal cable_coil does
		if(sharp)
			embed_chance = force/w_class
		else
			embed_chance = force/(w_class*3)
	update_icon()

/obj/item/stack/cable_coil/alien/update_icon()
	icon_state = initial(icon_state)

/obj/item/stack/cable_coil/alien/can_use(var/used)
	return 1

/obj/item/stack/cable_coil/alien/use()	//It's endless
	return 1

/obj/item/stack/cable_coil/alien/add()	//Still endless
	return 0

/obj/item/stack/cable_coil/alien/update_wclass()
	return 0

/obj/item/stack/cable_coil/alien/examine(mob/user)
	. = ..()

	if(Adjacent(user))
		. += "It doesn't seem to have a beginning, or an end."

/obj/item/stack/cable_coil/alien/attack_hand(mob/user as mob)
	if (user.get_inactive_hand() == src)
		var/N = tgui_input_number(usr, "How many units of wire do you want to take from [src]?  You can only take up to [amount] at a time.", "Split stacks", 1)
		if(N && N <= amount)
			var/obj/item/stack/cable_coil/CC = new/obj/item/stack/cable_coil(user.loc)
			CC.amount = N
			CC.update_icon()
			to_chat(user,"<font color='blue'>You take [N] units of wire from the [src].</font>")
			if (CC)
				user.put_in_hands(CC)
				src.add_fingerprint(user)
				CC.add_fingerprint(user)
				spawn(0)
					if (src && usr.machine==src)
						src.interact(usr)
		else
			return
	else
		..()
	return
