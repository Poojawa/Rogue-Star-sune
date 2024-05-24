//////////////////////////////
// POWER MACHINERY BASE CLASS
//////////////////////////////

/////////////////////////////
// Definitions
/////////////////////////////

/obj/machinery/power
	name = null
	icon = 'icons/obj/power.dmi'
	anchored = TRUE
	use_power = USE_POWER_OFF
	idle_power_usage = 0
	active_power_usage = 0

	///The powernet our machine is connected to.
	var/datum/powernet/powernet
	///Cable layer to which the machine is connected.
	var/cable_layer = CABLE_LAYER_2
	///Can the cable_layer be tweked with a multi tool
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
			cable_layer = C.cable_layer
	else
		return

/obj/machinery/power/examine(mob/user)
	. = ..()
	if(can_change_cable_layer)
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

/obj/machinery/power/proc/add_delayedload(amount)
	if(powernet)
		powernet.delayedload += amount

/obj/machinery/power/proc/delayed_surplus()
	if(powernet)
		return clamp(powernet.newavail - powernet.delayedload, 0, powernet.newavail)
	else
		return 0

/obj/machinery/power/proc/newavail()
	if(powernet)
		return powernet.newavail
	else
		return 0

/obj/machinery/power/proc/disconnect_terminal() // machines without a terminal will just return, no harm no fowl.
	return

// returns true if the area has power on given channel (or doesn't require power).
// defaults to power_channel
/obj/machinery/proc/powered(chan = power_channel, ignore_use_power = FALSE)
	if(!loc)
		return FALSE
	if(!use_power && !ignore_use_power)
		return TRUE

	var/area/A = get_area(src) // make sure it's in an area
	if(!A)
		return FALSE // if not, then not powered

	return A.powered(chan) // return power status of the area

// increment the power usage stats for an area
/obj/machinery/proc/use_power(amount, chan = power_channel)
	amount = max(amount * machine_power_rectifier, 0) // make sure we don't use negative power
	var/area/A = get_area(src) // make sure it's in an area
	A?.use_power_oneoff(amount, chan)

/**
 * An alternative to 'use_power', this proc directly costs the APC in direct charge, as opposed to being calculated periodically.
 * - Amount: How much power the APC's cell is to be costed.
 */
/obj/machinery/proc/directly_use_power(amount)
	var/area/my_area = get_area(src)
	if(isnull(my_area))
		stack_trace("machinery is somehow not in an area, nullspace?")
		return FALSE
	if(!my_area.requires_power)
		return TRUE

	var/obj/machinery/power/apc/my_apc = my_area.apc
	if(isnull(my_apc))
		return FALSE
	return my_apc.cell.use(amount)

/**
 * Attempts to draw power directly from the APC's Powernet rather than the APC's battery. For high-draw machines, like the cell charger
 *
 * Checks the surplus power on the APC's powernet, and compares to the requested amount. If the requested amount is available, this proc
 * will add the amount to the APC's usage and return that amount. Otherwise, this proc will return FALSE.
 * If the take_any var arg is set to true, this proc will use and return any surplus that is under the requested amount, assuming that
 * the surplus is above zero.
 * Args:
 * - amount, the amount of power requested from the Powernet. In standard loosely-defined SS13 power units.
 * - take_any, a bool of whether any amount of power is acceptable, instead of all or nothing. Defaults to FALSE
 */
/obj/machinery/proc/use_power_from_net(amount, take_any = FALSE)
	if(amount <= 0) //just in case
		return FALSE
	var/area/home = get_area(src)

	if(!home)
		return FALSE //apparently space isn't an area
	if(!home.requires_power)
		return amount //Shuttles get free power, don't ask why

	var/obj/machinery/power/apc/local_apc = home.apc
	if(!local_apc)
		return FALSE
	var/surplus = local_apc.surplus()
	if(surplus <= 0) //I don't know if powernet surplus can ever end up negative, but I'm just gonna failsafe it
		return FALSE
	if(surplus < amount)
		if(!take_any)
			return FALSE
		amount = surplus
	local_apc.draw_power(amount)
	return amount

/obj/machinery/proc/addStaticPower(value, powerchannel)
	var/area/A = get_area(src)
	A?.use_power_oneoff(value, powerchannel)

/obj/machinery/proc/removeStaticPower(value, powerchannel)
	addStaticPower(-value, powerchannel)

/**
 * Called whenever the power settings of the containing area change
 *
 * by default, check equipment channel & set flag, can override if needed
 *
 * Returns TRUE if the NOPOWER flag was toggled
 */
/obj/machinery/proc/power_change()		// called whenever the power settings of the containing area change
										// by default, check equipment channel & set flag
										// can override if needed
	if(powered(power_channel))
		stat &= ~NOPOWER
	else
		stat |= NOPOWER
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

	var/obj/machinery/power/deck_relay/connector = locate(/obj/machinery/power/deck_relay) in T
	if(connector && connector.powernet)
		C.powernet.add_relays_together(connector, C.cable_layer)
		return TRUE
	else
		C.powernet.add_machine(src)
		return TRUE

// remove and disconnect the machine from its current powernet
/obj/machinery/power/proc/disconnect_from_network()
	if(!powernet)
		return FALSE
	powernet.remove_machine(src)
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

	for(var/obj/machinery/power/Node in net2.nodes) //merge power machines
		if(!Node.connect_to_network())
			Node.disconnect_from_network() //if somehow we can't connect the machine to the new powernet, disconnect it from the old nonetheless

	return net1

/// Extracts the powernet and cell of the provided power source
/proc/get_powernet_info_from_source(power_source)
	var/area/source_area
	if (isarea(power_source))
		source_area = power_source
		power_source = source_area.apc
	else if (istype(power_source, /obj/structure/cable))
		var/obj/structure/cable/Cable = power_source
		power_source = Cable.powernet

	var/datum/powernet/PN
	var/obj/item/weapon/cell/cell

	if (istype(power_source, /datum/powernet))
		PN = power_source
	else if (istype(power_source, /obj/item/weapon/cell))
		cell = power_source
	else if (istype(power_source, /obj/machinery/power/apc))
		var/obj/machinery/power/apc/apc = power_source
		cell = apc.cell
		if (apc.terminal)
			PN = apc.terminal.powernet
	else
		return FALSE

	if (!cell && !PN)
		return

	return list("powernet" = PN, "cell" = cell)

/obj/machinery/power/proc/viewload()
	if(powernet)
		return powernet.viewload
	else
		return FALSE

//Determines how strong could be shock, deals damage to mob, uses power.
//M is a mob who touched wire/whatever
//power_source is a source of electricity, can be power cell, area, apc, cable, powernet or null
//source is an object caused electrocuting (airlock, grille, etc)
//siemens_coeff - layman's terms, conductivity
//dist_check - set to only shock mobs within 1 of source (vendors, airlocks, etc.)
//No animations will be performed by this proc.
/proc/electrocute_mob(mob/living/M as mob, var/power_source, var/obj/source, var/siemens_coeff = 1.0)
	if(istype(M.loc,/obj/mecha))
		return FALSE	//feckin mechs are dumb
	if(issilicon(M))
		return FALSE	//No more robot shocks from machinery
	var/area/source_area
	if(istype(power_source,/area))
		source_area = power_source
		power_source = source_area.get_apc()
	if(istype(power_source,/obj/structure/cable))
		var/obj/structure/cable/Cable = power_source
		power_source = Cable.powernet

	var/datum/powernet/PN
	var/obj/item/weapon/cell/cell

	if(istype(power_source,/datum/powernet))
		PN = power_source
	else if(istype(power_source,/obj/item/weapon/cell))
		cell = power_source
	else if(istype(power_source,/obj/machinery/power/apc))
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
	if(istype(M,/mob/living/carbon/human))
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
	else if (istype(power_source,/datum/powernet))
		var/drained_power = drained_energy/CELLRATE
		drained_power = PN.draw_power(drained_power)
	else if (istype(power_source, /obj/item/weapon/cell))
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
			C.update_icon() // I hate this. it's here because update_icon_state SCANS nearby turfs for objects to connect to. Wastes cpu time
			return C
	return null
