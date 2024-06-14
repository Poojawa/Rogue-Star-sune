//////////////////////////////
// POWER MACHINERY BASE CLASS
//////////////////////////////

/////////////////////////////
// Definitions
/////////////////////////////

/obj/machinery/power
	name = null
	icon = 'icons/obj/machines/power/power.dmi'
	anchored = TRUE
	use_power = USE_POWER_OFF
	idle_power_usage = 0
	active_power_usage = 0

	///The powernet our machine is connected to.
	var/datum/powernet/powernet
	///Cable layer to which the machine is connected.
	var/cable_layer = CABLE_LAYER_2
	///Can the cable_layer be tweaked with a multi tool?
	var/can_change_cable_layer = FALSE

/obj/machinery/power/Initialize(mapload)
	. = ..()
	adapt_to_cable_layer()	//because apparently machines aren't allowed to work properly to update.
	//Machines will call their connect_to_network() themselves after this

/obj/machinery/power/Destroy()
	disconnect_from_network()
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(update_cable_icons_on_turf), get_turf(src)), 0.3 SECONDS)
	return ..()

///////////////////////////////
// General procedures
//////////////////////////////

// common helper procs for all power machines

///override this if the machine needs special functionality for making wire nodes appear, ie emitters, generators, etc.
///Non power machines need to be added to GLOB.wire_node_generating_types in cable.dm, ie grilles.
/obj/machinery/power/proc/should_have_node()
	return FALSE

///Forcefully set power machines to their mapped cable layer
/obj/machinery/power/proc/adapt_to_cable_layer()
	var/turf/T = get_turf(src)
	if(T)
		for(var/obj/structure/cable/C in T.contents)
			if(!C)
				return
			if(can_change_cable_layer)
				cable_layer = C.cable_layer
			else
				return
	else
		return

/obj/machinery/power/examine(mob/user)
	. = ..()
	if(can_change_cable_layer)
		if(powernet == FALSE) //the only way I can think of to not double-examine APCs... No powernet = null
			return
		if(!QDELETED(powernet))
			. += span_notice("It's operating on the [LOWER_TEXT(GLOB.cable_layer_to_name["[cable_layer]"])].")
		else
			. += span_warning("It's disconnected from the [LOWER_TEXT(GLOB.cable_layer_to_name["[cable_layer]"])].")

/// common helper procs for all power machines //Snowflake code, entirely.
/obj/machinery/power/drain_power(var/drain_check, var/surge, var/amount = 0)
	if(drain_check)
		return TRUE

	if(powernet && powernet.avail)
		powernet.trigger_warning()
		return powernet.draw_power(amount)

/obj/machinery/power/proc/add_avail(amount)
	if(powernet)
		powernet.newavail += amount
		return TRUE
	else
		return 0

/obj/machinery/power/proc/draw_power(var/amount)
	if(powernet)
		return powernet.draw_power(amount)
	return 0

/obj/machinery/power/proc/surplus()
	if(powernet)
		return clamp(powernet.avail-powernet.load, 0, powernet.avail)
	else
		return 0

/obj/machinery/power/proc/avail(amount)
	if(powernet)
		return amount ? powernet.avail >= amount : powernet.avail
	else
		return 0

/obj/machinery/power/proc/viewload()
	if(powernet)
		return powernet.viewload
	else
		return 0

/obj/machinery/power/proc/newavail()
	if(powernet)
		return powernet.newavail
	else
		return 0

/obj/machinery/power/proc/disconnect_terminal() // machines without a terminal will just return, no harm no fowl.
	return

// connect the machine to a powernet if a node cable or a terminal is present on the turf
/obj/machinery/power/proc/connect_to_network()
	var/turf/T = get_turf(loc)
	if(!T || !istype(T))
		return FALSE

	var/obj/structure/cable/C = T.get_cable_node(cable_layer) //check if we have a node cable on the machine turf, the first found is picked
	if(!C || !C.powernet)
		var/obj/machinery/power/terminal/term = locate(/obj/machinery/power/terminal) in T
		if(!term || !term.powernet)
			return FALSE
		else
			term.powernet.add_machine(src)
			return TRUE

	C.powernet.add_machine(src)
	update_cable_icons_on_turf(get_turf(src))
	return TRUE

// remove and disconnect the machine from its current powernet
/obj/machinery/power/proc/disconnect_from_network()
	if(!powernet)
		return FALSE
	powernet.remove_machine(src)
	update_cable_icons_on_turf(get_turf(src))
	return TRUE

// attach a wire to a power machine - leads from the turf you are standing on
//almost never called, overwritten by all power machines but terminal and generator
/obj/machinery/power/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/coil = W
		var/turf/T = user.loc
		if(T && !T.is_plating())
			return
		if(get_dist(src, user) > 1)
			return
		coil.place_turf(T, user)
	else
		return ..()

/obj/machinery/power/default_unfasten_wrench(mob/user, obj/item/W, time = 0)
	. = ..()
	if(anchored)
		connect_to_network()
	else
		disconnect_from_network()

///////////////////////////////////////////
// Powernet handling helpers
//////////////////////////////////////////

//returns all the cables WITHOUT a powernet in neighbors turfs,
//pointing towards the turf the machine is located at
/obj/machinery/power/proc/get_connections()
	. = list()
	var/turf/T

	for(var/card in GLOB.cardinal)
		T = get_step(loc,card)

		for(var/obj/structure/cable/C in T)
			if(C.powernet)
				continue
			. += C
	return .

//returns all the cables in neighbors turfs,
//pointing towards the turf the machine is located at
/obj/machinery/power/proc/get_marked_connections()
	. = list()
	var/turf/T

	for(var/card in GLOB.cardinal)
		T = get_step(loc,card)

		for(var/obj/structure/cable/C in T)
			. += C
	return .

//returns all the NODES (O-X) cables WITHOUT a powernet in the turf the machine is located at
/obj/machinery/power/proc/get_indirect_connections()
	. = list()
	for(var/obj/structure/cable/C in loc)
		if(C.powernet)
			continue
		. += C
	return .

/proc/update_cable_icons_on_turf(turf/T)
	for(var/obj/structure/cable/C in T.contents)
		C.update_icon()

// Used for power spikes by the engine, has specific effects on different machines.
/obj/machinery/power/proc/overload(var/obj/machinery/power/source)
	return

// Used by the grid checker upon receiving a power spike.
/obj/machinery/power/proc/do_grid_check()
	return

/obj/machinery/power/proc/power_spike()
	return

///////////////////////////////////////////
// GLOBAL PROCS for powernets handling
//////////////////////////////////////////

///remove the old powernet and replace it with a new one throughout the network.
/proc/propagate_network(obj/structure/cable/C, datum/powernet/PN, skip_assigned_powernets = FALSE)
	var/list/found_machines = list()
	var/list/cables = list()
	var/index = 1
	var/obj/structure/cable/working_cable

	cables[C] = TRUE //associated list for performance reasons

	while(index <= length(cables))
		working_cable = cables[index]
		index++

		var/list/connections = working_cable.get_cable_connections(skip_assigned_powernets, working_cable.cable_layer)

		for(var/obj/structure/cable/cable_entry in connections)
			if(!cables[cable_entry]) //Since it's an associated list, we can just do an access and check it's null before adding; prevents duplicate entries
				cables[cable_entry] = TRUE

	for(var/obj/structure/cable/cable_entry in cables)
		PN.add_cable(cable_entry)
		found_machines += cable_entry.get_machine_connections(skip_assigned_powernets)

	//now that the powernet is set, connect found machines to it
	for(var/obj/machinery/power/PM in found_machines)
		if(!PM.connect_to_network()) //couldn't find a node on its turf...
			PM.disconnect_from_network() //... so disconnect if already on a powernet


//Merge two powernets, the bigger (in cable length term) absorbing the other
/proc/merge_powernets(datum/powernet/net1, datum/powernet/net2)
	if(!net1 || !net2) //if one of the powernet doesn't exist, return
		return

	if(net1 == net2) //don't merge same powernets
		return

	//We assume net1 is larger. If net2 is in fact larger we are just going to make them switch places to reduce on code.
	if(net1.cables.len < net2.cables.len) //net2 is larger than net1. Let's switch them around
		var/temp = net1
		net1 = net2
		net2 = temp

	//merge net2 into net1
	for(var/obj/structure/cable/Cable in net2.cables) //merge cables
		net1.add_cable(Cable)

	if(!net2) return net1
	for(var/obj/machinery/power/Node in net2.nodes) //merge power machines
		if(!Node.connect_to_network())
			Node.disconnect_from_network() //if somehow we can't connect the machine to the new powernet, disconnect it from the old nonetheless

	return net1

//Determines how strong could be shock, deals damage to mob, uses power.
//M is a mob who touched wire/whatever
//power_source is a source of electricity, can be power cell, area, apc, cable, powernet or null
//source is an object caused electrocuting (airlock, grille, etc)
//siemens_coeff - layman's terms, conductivity
//dist_check - set to only shock mobs within 1 of source (vendors, airlocks, etc.)
//No animations will be performed by this proc.
/proc/electrocute_mob(mob/living/M as mob, var/power_source, var/obj/source, var/siemens_coeff = 1.0)
	if(ismecha(M.loc))
		return FALSE	//feckin mechs are dumb
	if(issilicon(M))
		return FALSE	//No more robot shocks from machinery
	var/area/source_area
	if(isarea(power_source))
		source_area = power_source
		power_source = source_area.get_apc()
	if(iscable(power_source))
		var/obj/structure/cable/Cable = power_source
		power_source = Cable.powernet

	var/datum/powernet/PN
	var/obj/item/weapon/cell/cell

	if(ispowernet(power_source))
		PN = power_source
	else if(isPowerCell(power_source))
		cell = power_source
	else if(isAPC(power_source))
		var/obj/machinery/power/apc/apc = power_source
		cell = apc.cell
		if (apc.terminal)
			PN = apc.terminal.powernet
	else if (!power_source)
		return 0
	else
		log_admin("ERROR: /proc/electrocute_mob([M], [power_source], [source]): wrong power_source")
		return 0
	//Triggers powernet warning, but only for 5 ticks (if applicable)
	//If following checks determine user is protected we won't alarm for long.
	if(PN)
		PN.trigger_warning(5)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.species.siemens_coefficient <= 0)
			return
		if(H.gloves)
			var/obj/item/clothing/gloves/G = H.gloves
			if(G.siemens_coefficient == 0)	return FALSE	//to avoid spamming with insulated glvoes on

	//Checks again. If we are still here subject will be shocked, trigger standard 20 tick warning
	//Since this one is longer it will override the original one.
	if(PN)
		PN.trigger_warning()

	if (!cell && !PN)
		return 0
	var/PN_damage = 0
	var/cell_damage = 0
	if (PN)
		PN_damage = PN.get_electrocute_damage()
	if (cell)
		cell_damage = cell.get_electrocute_damage()
	var/shock_damage = 0
	if (PN_damage>=cell_damage)
		power_source = PN
		shock_damage = PN_damage
	else
		power_source = cell
		shock_damage = cell_damage
	var/drained_hp = M.electrocute_act(shock_damage, source, siemens_coeff) //zzzzzzap!
	var/drained_energy = drained_hp*20

	if (source_area)
		source_area.use_power_oneoff(drained_energy/CELLRATE, EQUIP)
	else if (ispowernet(power_source))
		var/drained_power = drained_energy/CELLRATE
		drained_power = PN.draw_power(drained_power)
	else if (isPowerCell(power_source))
		cell.use(drained_energy)
	return drained_energy

////////////////////////////////////////////////
// Misc.
///////////////////////////////////////////////

// return a cable able connect to machinery on layer if there's one on the turf, null if there isn't one
/turf/proc/get_cable_node(cable_layer = CABLE_LAYER_ALL)
	if(!can_have_cabling())
		return null
	for(var/obj/structure/cable/C in src)
		if(C.cable_layer & cable_layer)
			C.update_icon()
			return C
	return null
