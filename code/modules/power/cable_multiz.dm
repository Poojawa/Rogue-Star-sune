/obj/structure/cable/multilayer/multiz //This bridges powernets betwen Z levels
	name = "multi z layer cable hub"
	desc = "A flexible, superconducting insulated multi Z layer hub for heavy-duty multi Z power transfer."
	icon = 'icons/obj/cables/structures.dmi'
	icon_state = "cablerelay-on"
	layer = WIRES_LAYER
	cable_layer = CABLE_LAYER_1|CABLE_LAYER_2|CABLE_LAYER_3|CABLE_LAYER_4
	var/obj/structure/cable/multilayer/multiz/connectionup
	var/obj/structure/cable/multilayer/multiz/connectiondown
	/* //To Do: prevent powernet contamination between Z-levels
	/// Do we mix our powernet connections?
	var/mix_powernets = FALSE
	/// All Cable layer powernet
	var/datum/powernet/powernet
	/// Powernet channels list
	var/datum/powernet/powernet1
	var/datum/powernet/powernet2
	var/datum/powernet/powernet3
	var/datum/powernet/powernet4 */

/obj/structure/cable/multilayer/multiz/Destroy()
	if(connectionup)
		connectionup.disconnect(src)
	if(connectiondown)
		connectiondown.disconnect(src)
	. = ..()

/obj/structure/cable/multilayer/multiz/proc/disconnect(obj/structure/cable/multilayer/reference)
	if(reference == connectionup)
		if(istype(connectionup, /obj/structure/cable/multilayer/multiz))
			qdel(src)
		connectionup = null

	if(reference == connectiondown)
		if(istype(connectiondown, /obj/structure/cable/multilayer/multiz))
			qdel(src)
		connectiondown = null

	return null

/obj/structure/cable/multilayer/multiz/hides_under_flooring()
	return TRUE

/obj/structure/cable/multilayer/multiz/update_icon()
	. = ..()
	icon_state = "cablerelay-on"

/obj/structure/cable/multilayer/multiz/get_cable_connections_zlevel(powernetless_only)
	. = ..()
	var/turf/above = GetAbove(src)
	if(above)
		for(var/obj/structure/cable/multilayer/multiz/targetup in above)
			if(istype(targetup, /obj/structure/cable/multilayer/multiz))
				connectionup = targetup
				. += connectionup
	var/turf/below = GetBelow(src)
	if(below)
		for(var/obj/structure/cable/multilayer/multiz/targetdown in below)
			if(istype(targetdown, /obj/structure/cable/multilayer/multiz))
				connectiondown = targetdown
				. += connectiondown

/obj/structure/cable/multilayer/multiz/examine(mob/user)
	. = ..()
	. += span_notice("[connectionup ? "Detected" : "Undetected"] hub UP.")
	. += span_notice("[connectiondown ? "Detected" : "Undetected"] hub DOWN.")
