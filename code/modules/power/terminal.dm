// the underfloor wiring terminal for the APC
// autogenerated when an APC is placed
// all conduit connects go to this object instead of the APC
// using this solves the problem of having the APC in a wall yet also inside an area

/obj/machinery/power/terminal
	name = "terminal (L2)"
	icon_state = "term"
	desc = "It's an underfloor wiring terminal for power equipment."
	level = 1
	plane = PLATING_PLANE
	anchored = TRUE
	layer = WIRE_TERMINAL_LAYER
	unacidable = TRUE
	cable_layer = CABLE_LAYER_2
	var/obj/machinery/power/master = null

/obj/machinery/power/terminal/layer1
	name = "terminal (L1)"
	cable_layer = CABLE_LAYER_1

/obj/machinery/power/terminal/layer3
	name = "terminal (L3)"
	cable_layer = CABLE_LAYER_3


// Needed so terminals are not removed from machines list.
// Powernet rebuilds need this to work properly.
/obj/machinery/power/terminal/process()
	return TRUE

/obj/machinery/power/terminal/Initialize()
	. = ..()
	var/turf/T = get_turf(src)
	if(level==1)
		hide(!T.is_plating())
	if(!powernet)
		connect_to_network()

/obj/machinery/power/terminal/Destroy()
	if(master)
		master.disconnect_terminal(cable_layer)
		master = null
	return ..()

/obj/machinery/power/terminal/hide(i)
	if(i)
		invisibility = INVISIBILITY_MAXIMUM
		icon_state = "term-f"
	else
		invisibility = 0
		icon_state = "term"

/obj/machinery/power/terminal/hides_under_flooring()
	return TRUE

/obj/machinery/power/terminal/overload(var/obj/machinery/power/source)
	if(master)
		master.overload(source)

/obj/machinery/power/terminal/examine(mob/user)
	. = ..()
	if(!QDELETED(powernet))
		. += span_notice("It's operating on the [LOWER_TEXT(GLOB.cable_layer_to_name["[cable_layer]"])].")
	else
		. += span_warning("It's disconnected from the [LOWER_TEXT(GLOB.cable_layer_to_name["[cable_layer]"])].")

/obj/machinery/power/terminal/should_have_node()
	return TRUE

/obj/machinery/power/proc/can_terminal_dismantle()
	. = FALSE

/obj/machinery/power/apc/can_terminal_dismantle()
	. = FALSE
	if(opened)
		. = TRUE

/obj/machinery/power/smes/can_terminal_dismantle()
	. = FALSE
	if(panel_open)
		. = TRUE

/obj/machinery/power/terminal/dismantle(mob/living/user, obj/item/I, cable_layer)
	if(!istype(I))
		return
	if(isturf(loc))
		var/turf/T = loc
		if(T.is_plating())
			to_chat(user, "<span class='filter_notice'><span class='warning'>You must remove the floor plating first!</span></span>")
			return FALSE

	if(master && !master.can_terminal_dismantle())
		return FALSE

	user.visible_message(span_notice("[user.name] dismantles the cable terminal from [master]."))
	playsound(src.loc, 'sound/items/deconstruct.ogg', 50, TRUE)
	if(I.has_tool_quality(TOOL_WIRECUTTER))
		if(do_after(user, 20 * I.toolspeed))
			if(master && !master.can_terminal_dismantle())
				return FALSE

		if(prob(50) && electrocute_mob(user, powernet, src, 1, TRUE))
			var/datum/effect/effect/system/spark_spread/sparks = new /datum/effect/effect/system/spark_spread()
			sparks.set_up(5, 0, src)
			sparks.attach(loc)
			sparks.start()
			return FALSE

		new /obj/item/stack/cable_coil(get_turf(src), 10)
		qdel(src)
		if(isSMES(master))
			var/obj/machinery/power/smes/fatbat = master
			var/terminalslot = fatbat.get_terminal_slot(cable_layer)
			fatbat.disconnect_terminal(terminalslot)
		else
			master.disconnect_terminal()
		to_chat(user, "<span class='filter_notice'><span class='warning'>You finish removing the terminal.</span></span>")
		return TRUE
	else
		to_chat(user, "<span class='filter_notice'><span class='warning'>You need to use a wirecutting tool!</span></span>")
		return FALSE
