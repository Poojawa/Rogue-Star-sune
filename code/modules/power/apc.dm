/area/proc/get_apc()
	return apc

/// EMP effect duration is divided by this number if the APC has "critical" flag
#define CRITICAL_APC_EMP_PROTECTION 10

///offsets
#define APC_PIXEL_OFFSET 26

///update_state
#define UPDATE_CELL_IN 1
#define UPDATE_OPENED1 2
#define UPDATE_OPENED2 4
#define UPDATE_MAINT 8
#define UPDATE_BROKE 16
#define UPDATE_BLUESCREEN 32
#define UPDATE_WIREEXP 64
#define UPDATE_ALLGOOD 128

///update_overlay
#define APC_UPOVERLAY_CHARGEING0 1
#define APC_UPOVERLAY_CHARGEING1 2
#define APC_UPOVERLAY_CHARGEING2 4
#define APC_UPOVERLAY_EQUIPMENT0 8
#define APC_UPOVERLAY_EQUIPMENT1 16
#define APC_UPOVERLAY_EQUIPMENT2 32
#define APC_UPOVERLAY_LIGHTING0 64
#define APC_UPOVERLAY_LIGHTING1 128
#define APC_UPOVERLAY_LIGHTING2 256
#define APC_UPOVERLAY_ENVIRON0 512
#define APC_UPOVERLAY_ENVIRON1 1024
#define APC_UPOVERLAY_ENVIRON2 2048
#define APC_UPOVERLAY_LOCKED 4096
#define APC_UPOVERLAY_OPERATING 8192

#define APC_UPDATE_ICON_COOLDOWN 10 SECONDS

// main_status var
#define APC_EXTERNAL_POWER_NOTCONNECTED 0
#define APC_EXTERNAL_POWER_NOENERGY 1
#define APC_EXTERNAL_POWER_GOOD 2

// has_electronics var
#define APC_HAS_ELECTRONICS_NONE 0
#define APC_HAS_ELECTRONICS_WIRED 1
#define APC_HAS_ELECTRONICS_SECURED 2

///Update States
#define APC_STATE_UPDATE_NONE		0
#define APC_STATE_UPDATE_ICON		1
#define APC_STATE_UPDATE_OVERLAY	2
#define APC_STATE_UPDATE_LIGHTGLOW	3

// the Area Power Controller (APC), formerly Power Distribution Unit (PDU)
// one per area, needs wire conection to power network through a terminal

// controls power to devices in that area
// may be opened to change power cell
// three different channels (lighting/equipment/environ) - may each be set to on, off, or auto
#define POWERCHAN_OFF      0	// Power channel is off and will stay that way dammit
#define POWERCHAN_OFF_AUTO 1	// Power channel is off until power rises above a threshold
#define POWERCHAN_ON       2	// Power channel is on until there is no power
#define POWERCHAN_ON_AUTO  3	// Power channel is on until power drops below a threshold

#define NIGHTSHIFT_AUTO 1
#define NIGHTSHIFT_NEVER 2
#define NIGHTSHIFT_ALWAYS 3

//NOTE: STUFF STOLEN FROM AIRLOCK.DM thx

/obj/machinery/power/apc/critical
	is_critical = TRUE

/obj/machinery/power/apc/high
	cell_type = /obj/item/weapon/cell/high

/obj/machinery/power/apc/super
	cell_type = /obj/item/weapon/cell/super

/obj/machinery/power/apc/super/critical
	is_critical = TRUE

/obj/machinery/power/apc/hyper
	cell_type = /obj/item/weapon/cell/hyper

/obj/machinery/power/apc/alarms_hidden
	alarms_hidden = TRUE

/obj/machinery/power/apc/angled
	icon = 'icons/obj/wall_machines_angled.dmi'

/obj/machinery/power/apc/angled/super
	cell_type = /obj/item/weapon/cell/super

/obj/machinery/power/apc/angled/hidden
	alarms_hidden = TRUE

/obj/machinery/power/apc
	name = "area power controller"
	desc = "A control terminal for the area electrical systems."
	icon_state = "apc0"
	layer = ABOVE_WINDOW_LAYER
	anchored = TRUE
	unacidable = TRUE
	use_power = USE_POWER_OFF
	clicksound = "switch"
	req_access = list(access_engine_equip)
	blocks_emissive = FALSE
	vis_flags = VIS_HIDE // They have an emissive that looks bad in openspace due to their wall-mounted nature
	var/area/area
	var/auto_name = TRUE
	var/areastring = null
	var/obj/item/weapon/cell/cell
	var/chargelevel = CELLRATE  // Cap for how fast APC cells charge, as a percentage-per-tick (0.01 means cellcharge is capped to 1% per second)
	var/start_charge = 90				// initial cell charge %
	var/cell_type = /obj/item/weapon/cell/apc
	var/opened = 0 //0=closed, 1=opened, 2=cover removed
	var/shorted = FALSE
	var/grid_check = FALSE
	var/lighting = POWERCHAN_ON_AUTO
	var/equipment = POWERCHAN_ON_AUTO
	var/environ = POWERCHAN_ON_AUTO
	var/operating = TRUE
	var/charging = FALSE
	var/chargemode = 1
	var/chargecount = 0
	var/locked = TRUE
	var/coverlocked = TRUE
	var/aidisabled = 0
	var/obj/machinery/power/terminal/terminal = null
	can_change_cable_layer = TRUE
	var/lastused_light = 0
	var/lastused_equip = 0
	var/lastused_environ = 0
	var/lastused_charging = 0
	var/lastused_total = 0
	var/main_status = APC_EXTERNAL_POWER_NOTCONNECTED
	var/mob/living/silicon/ai/hacker = null // Malfunction var. If set AI hacked the APC and has full control.
	var/wiresexposed = FALSE
	powernet = FALSE		// set so that APCs aren't found as powernet nodes //Hackish, Horrible, was like this before I changed it :(
	var/debug= FALSE
	var/autoflag= 0		// 0 = off, 1= eqp and lights off, 2 = eqp off, 3 = all on.
	var/has_electronics = APC_HAS_ELECTRONICS_NONE // 0 - none, 1 - plugged in, 2 - secured by screwdriver
	var/beenhit = 0 // used for counting how many times it has been hit, used for Aliens at the moment
	var/longtermpower = 10
	var/datum/wires/apc/wires = null
	var/emergency_lights = FALSE
	var/update_state = -1
	var/update_overlay = -1
	var/is_critical = FALSE
	var/global/status_overlays = 0
	var/failure_timer = 0
	var/force_update = FALSE
	var/updating_icon = 0
	var/global/list/status_overlays_environ
	var/alarms_hidden = FALSE //If power alarms from this APC are visible on consoles

	var/nightshift_lights = FALSE
	var/nightshift_setting = NIGHTSHIFT_AUTO
	var/last_nightshift_switch = 0
	/// Offsets the object by APC_PIXEL_OFFSET (defined in apc_defines.dm) pixels in the direction we want it placed in. This allows the APC to be embedded in a wall, yet still inside an area (like mapping).
	var/offset_old

/obj/machinery/power/apc/updateDialog()
	if(stat & (BROKEN|MAINT))
		return
	..()

/obj/machinery/power/apc/connect_to_network()
	//Override because the APC does not directly connect to the network; it goes through a terminal.
	//The terminal is what the power computer looks for anyway.
	if(terminal)
		terminal.connect_to_network()

/obj/machinery/power/apc/drain_power(var/drain_check, var/surge, var/amount = 0)

	if(drain_check)
		return TRUE

	//This makes sure fully draining an APC cell won't break the cell charging.
	charging = 0

	var/drained_energy = 0

	//Draws power from the grid first, if available.
	//This is like draining from a cable, so nins and
	//twizs can do that without having to pry floortiles.
	if(terminal && terminal.powernet)
		terminal.powernet.trigger_warning()
		drained_energy += terminal.powernet.draw_power(amount)

	//The grid rarely gives the full amount requested, or perhaps the grid
	//isn't connected (wire cut), in either case we draw what we didn't get
	//from the cell instead.
	if((drained_energy < amount) && cell)
		drained_energy += cell.drain_power(0, 0, (amount - drained_energy))

	return drained_energy

/obj/machinery/power/apc/Initialize(mapload, ndir)
	. = ..()
	wires = new(src)
	GLOB.apcs += src

	//Pixel offset its appearance based on its direction
	if(ndir)
		dir = ndir
	switch(dir)
		if(NORTH)
			offset_old = pixel_y
			pixel_y = APC_PIXEL_OFFSET
		if(SOUTH)
			offset_old = pixel_y
			pixel_y = -APC_PIXEL_OFFSET
		if(EAST)
			offset_old = pixel_x
			pixel_x = APC_PIXEL_OFFSET
		if(WEST)
			offset_old = pixel_x
			pixel_x = -APC_PIXEL_OFFSET

	//Assign it to its area. If mappers already assigned an area string fast load the area from it else get the current area
	var/area/our_area = get_area(loc)
	//TODO: port better area stuff from /tg/
	//like multi-area covering APCs, for shuttles for example!
	if(areastring)
		area = get_area_name(areastring)
		if(!area)
			area = our_area
			log_adminwarn("Bad areastring path for [src], [areastring]")

	if(isarea(our_area) && areastring == null)
		area = our_area
	if(area)
		if(area.apc)
			log_adminwarn("Duplicate APC created at [COORD(src)] [area.type]. Original at [COORD(area.apc)] [area.type].")
		area.apc = src

	if(mapload)
		has_electronics = APC_HAS_ELECTRONICS_SECURED //installed and secured
		// is starting with a power cell installed, create it and set its charge level
		if(cell_type)
			cell = new cell_type(src)
			cell.charge = start_charge * cell.maxcharge / 100.0 		// (convert percentage to actual value)
		if(istype(area, /area/submap))
			alarms_hidden = TRUE
		make_terminal(cable_layer)
		///This is how we test to ensure that mappers use the directional subtypes of APCs, rather than use the parent and pixel-shift it themselves.
		// Christ do you know the amount of effort this'll end up being, fuck me. TODO
	//	if(abs(offset_old) != APC_PIXEL_OFFSET)
	//		log_mapping("APC: ([src]) at [COORD(src)] with dir ([dir] | [uppertext(dir2text(dir))]) has pixel_[dir & (WEST|EAST) ? "x" : "y"] value [offset_old] - should be [dir & (SOUTH|EAST) ? "-" : ""][APC_PIXEL_OFFSET]. Use the directional/ helpers!")

	//Initialize name & access of the apc. Name requires area to be assigned first
	if(!req_access)
		req_access = list(access_engine_equip)
	if(auto_name)
		name = "\improper [get_area_name(area, TRUE)] APC"

	addtimer(CALLBACK(src, PROC_REF(update)), 0.5 SECONDS)
	update_icon()

/obj/machinery/power/apc/Destroy()
	GLOB.apcs -= src
	disconnect_from_area()
	if(wires)
		QDEL_NULL(wires)
	if(cell)
		QDEL_NULL(cell)
	if(terminal)
		disconnect_terminal()
	// Malf AI, removes the APC from AI's hacked APCs list.
	if((hacker) && (hacker.hacked_apcs) && (src in hacker.hacked_apcs))
		hacker.hacked_apcs -= src
	investigate_log("[src] was destroyed at [COORD(src)]", "powernet")
	return ..()

/obj/machinery/power/apc/proc/assign_to_area(area/target_area = get_area(src))
	if(area == target_area)
		return

	disconnect_from_area()
	area = target_area
	area.power_light = TRUE
	area.power_equip = TRUE
	area.power_environ = TRUE
	area.power_change()
	area.apc = src
	auto_name = TRUE
	update_icon()

/obj/machinery/power/apc/proc/disconnect_from_area()
	if(isnull(area))
		return

	area.power_light = FALSE
	area.power_equip = FALSE
	area.power_environ = FALSE
	area.power_change()
	area.apc = null
	area = null

/obj/machinery/power/apc/proc/update_area()
	var/area/NA = get_area(src)
	if(!(NA == area))
		if(area.apc == src)
			area.apc = null
		NA.apc = src
		area = NA
		name = "[area.name] APC"
	update()

/obj/machinery/power/apc/should_have_node()
	return TRUE

/obj/machinery/power/apc/proc/energy_fail(var/duration)
	failure_timer = max(failure_timer, round(duration))

/obj/machinery/power/apc/proc/make_terminal(cable_layer)
	// create a terminal object at the same position as original turf loc
	// wires will attach to this
	var/turf/T = get_turf(src)
	for(var/obj/structure/cable/C in T.contents)
		cable_layer = C.cable_layer	//let's ensure we operate on the correct layer
		if(cable_layer == CABLE_LAYER_1)
			terminal = new/obj/machinery/power/terminal/layer1(T)

		else if(cable_layer == CABLE_LAYER_2)
			terminal = new/obj/machinery/power/terminal(T)

		else if(cable_layer == CABLE_LAYER_3)
			terminal = new/obj/machinery/power/terminal/layer3(T)
		terminal.master = src
		terminal.set_dir(src.dir)
	update_cable_icons_on_turf(get_turf(src))

/obj/machinery/power/apc/examine(mob/user)
	. = ..()
	if(terminal)
		if(!QDELETED(terminal.powernet))
			. += span_notice("It's operating on the [LOWER_TEXT(GLOB.cable_layer_to_name["[terminal.cable_layer]"])].")
		else
			. += span_warning("It's disconnected from the [LOWER_TEXT(GLOB.cable_layer_to_name["[terminal.cable_layer]"])].")

	if(Adjacent(user))
		if(stat & BROKEN)
			. += "This APC is broken."

		else if(opened)
			if(has_electronics && terminal)
				. += "The cover is [opened == 2 ? "removed" : "open"] and [ cell ? "a power cell is installed" : "the power cell is missing"]."
			else if(!has_electronics && terminal)
				. += "The frame is wired, but the electronics are missing."
			else if(has_electronics && !terminal)
				. += "The electronics are installed, but not wired."
			else /* if(!has_electronics && !terminal) */
				. += "It's just an empty metal frame."

		else
			if(wiresexposed)
				. += "The cover is closed and the wires are exposed."
			else if((locked && emagged) || hacker) //Some things can cause locked && emagged. Malf AI causes hacker.
				. += "The cover is closed, but the panel is unresponsive."
			else if(!locked && emagged) //Normal emag does this.
				. += "The cover is closed, but the panel is flashing an error."
			else
				. += "The cover is closed."


// update the APC icon to show the three base states
// also add overlays for indicator lights
/obj/machinery/power/apc/update_icon()
	var/update = check_updates()
						//returns APC_STATE_UPDATE_NONE if no need to update icons.
						// APC_STATE_UPDATE_ICON		if we need to update the icon_state
						// APC_STATE_UPDATE_OVERLAY		if we need to update the overlays
						// APC_STATE_UPDATE_LIGHTGLOW	for lighting glows
	if(!update)
		return

	if(update & APC_STATE_UPDATE_ICON) // Updating the icon state
		if(update_state & UPDATE_ALLGOOD)
			icon_state = "apc0"
		else if(update_state & (UPDATE_OPENED1|UPDATE_OPENED2))
			var/basestate = "apc[ cell ? "2" : "1" ]"
			if(update_state & UPDATE_OPENED1)
				if(update_state & (UPDATE_MAINT|UPDATE_BROKE))
					icon_state = "apcmaint" //disabled APC cannot hold cell
				else
					icon_state = basestate
			else if(update_state & UPDATE_OPENED2)
				icon_state = "[basestate]-nocover"
		else if(update_state & UPDATE_BROKE)
			icon_state = "apc-b"
		else if(update_state & UPDATE_WIREEXP)
			icon_state = "apcewires"
		else if(update_state & UPDATE_BLUESCREEN)
			icon_state = "apcemag"

	if(!(update_state & UPDATE_ALLGOOD))
		cut_overlays()
		return

	if(update & APC_STATE_UPDATE_OVERLAY)
		cut_overlays()
		if(!(stat & (BROKEN|MAINT)) && update_state & UPDATE_ALLGOOD)
			var/list/new_overlays = list()
			new_overlays += mutable_appearance(icon, "apcox-[locked]")
			new_overlays += emissive_appearance(icon, "apcox-[locked]")
			new_overlays += mutable_appearance(icon, "apco3-[charging]")
			new_overlays += emissive_appearance(icon, "apco3-[charging]")
			if(operating)
				new_overlays += mutable_appearance(icon, "apco0-[equipment]")
				new_overlays += emissive_appearance(icon, "apco0-[equipment]")
				new_overlays += mutable_appearance(icon, "apco1-[lighting]")
				new_overlays += emissive_appearance(icon, "apco1-[lighting]")
				new_overlays += mutable_appearance(icon, "apco2-[environ]")
				new_overlays += emissive_appearance(icon, "apco2-[environ]")
			add_overlay(new_overlays)

	if(update & APC_STATE_UPDATE_LIGHTGLOW)
		if(update_state & UPDATE_BLUESCREEN)
			set_light(l_range = 2, l_power = 0.25, l_color = "#0000FF")
		else if(!(stat & (BROKEN|MAINT)) && update_state & UPDATE_ALLGOOD)
			var/color
			switch(charging)
				if(0)
					color = "#F86060"
				if(1)
					color = "#A8B0F8"
				if(2)
					color = "#82FF4C"
			set_light(l_range = 2, l_power = 0.25, l_color = color)
		else
			set_light(0)

/obj/machinery/power/apc/proc/check_updates()

	var/last_update_state = update_state
	var/last_update_overlay = update_overlay
	update_state = APC_STATE_UPDATE_NONE
	update_overlay = 0

	if(cell)
		update_state |= UPDATE_CELL_IN
	if(stat & BROKEN)
		update_state |= UPDATE_BROKE
	if(stat & MAINT)
		update_state |= UPDATE_MAINT
	if(opened)
		if(opened==1)
			update_state |= UPDATE_OPENED1
		if(opened==2)
			update_state |= UPDATE_OPENED2
	else if(wiresexposed)
		update_state |= UPDATE_WIREEXP
	else if(emagged || hacker || failure_timer)
		update_state |= UPDATE_BLUESCREEN
	if(update_state <= 1)
		update_state |= UPDATE_ALLGOOD

	if(operating)
		update_overlay |= APC_UPOVERLAY_OPERATING

	if(update_state & UPDATE_ALLGOOD)
		if(locked)
			update_overlay |= APC_UPOVERLAY_LOCKED

		if(!charging)
			update_overlay |= APC_UPOVERLAY_CHARGEING0
		else if(charging == 1)
			update_overlay |= APC_UPOVERLAY_CHARGEING1
		else if(charging == 2)
			update_overlay |= APC_UPOVERLAY_CHARGEING2

		if(!equipment)
			update_overlay |= APC_UPOVERLAY_EQUIPMENT0
		else if(equipment == 1)
			update_overlay |= APC_UPOVERLAY_EQUIPMENT1
		else if(equipment == 2)
			update_overlay |= APC_UPOVERLAY_EQUIPMENT2

		if(!lighting)
			update_overlay |= APC_UPOVERLAY_LIGHTING0
		else if(lighting == 1)
			update_overlay |= APC_UPOVERLAY_LIGHTING1
		else if(lighting == 2)
			update_overlay |= APC_UPOVERLAY_LIGHTING2

		if(!environ)
			update_overlay |= APC_UPOVERLAY_ENVIRON0
		else if(environ==1)
			update_overlay |= APC_UPOVERLAY_ENVIRON1
		else if(environ==2)
			update_overlay |= APC_UPOVERLAY_ENVIRON2


	var/results = 0
	if(last_update_state == update_state && last_update_overlay == update_overlay)
		return 0
	if(last_update_state != update_state)
		results += 1
	if(last_update_overlay != update_overlay)
		results += 2
	return results

// Used in process so it doesn't update the icon too much
/obj/machinery/power/apc/proc/queue_icon_update()

	if(!updating_icon)
		updating_icon = 1
		// Start the update
		spawn(APC_UPDATE_ICON_COOLDOWN)
			update_icon()
			updating_icon = 0

//attack with an item - open/close cover, insert cell, or (un)lock interface

/obj/machinery/power/apc/attackby(obj/item/W, mob/user)
	if(issilicon(user) && get_dist(src,user) > 1)
		return attack_hand(user)
	add_fingerprint(user)
	if((W.has_tool_quality(TOOL_CROWBAR)) && opened)
		if(has_electronics == APC_HAS_ELECTRONICS_WIRED)
			if(terminal)
				to_chat(user, "<span class='warning'>Disconnect the wires first.</span>")
				return
			playsound(src, W.usesound, 50, 1)
			to_chat(user, "You begin to remove the power control board...") //lpeters - fixed grammar issues //Ner - grrrrrr
			if(do_after(user, 50 * W.toolspeed))
				if(has_electronics == APC_HAS_ELECTRONICS_WIRED)
					has_electronics = APC_HAS_ELECTRONICS_NONE
					if((stat & BROKEN))
						user.visible_message(\
							"<span class='warning'>[user.name] has broken the charred power control board inside [name]!</span>",\
							"<span class='notice'>You broke the charred power control board and remove the remains.</span>",
							"You hear a crack!")
						//ticker.mode:apcs-- //XSI said no and I agreed. -rastaf0
					else
						user.visible_message(\
							"<span class='warning'>[user.name] has removed the power control board from [name]!</span>",\
							"<span class='notice'>You remove the power control board.</span>")
						new /obj/item/weapon/module/power_control(loc)
		else if(opened != 2) //cover isn't removed
			opened = 0
			update_icon()
	else if((W.has_tool_quality(TOOL_CROWBAR)) && !(stat & BROKEN) )
		if(coverlocked && !(stat & MAINT))
			to_chat(user, "<span class='warning'>The cover is locked and cannot be opened.</span>")
			return
		else
			opened = 1
			update_icon()
	else if	(istype(W, /obj/item/weapon/cell) && opened)	// trying to put a cell inside
		if(cell)
			to_chat(user, "The [name] already has a power cell installed.")
			return
		if(stat & MAINT)
			to_chat(user, "<span class='warning'>You need to install the wiring and electronics first.</span>")
			return
		if(W.w_class != ITEMSIZE_NORMAL)
			to_chat(user, "\The [W] is too [W.w_class < 3? "small" : "large"] to work here.")
			return

		user.drop_item()
		W.forceMove(src)
		cell = W
		user.visible_message(\
			"<span class='warning'>[user.name] has inserted a power cell into [name]!</span>",\
			"<span class='notice'>You insert the power cell.</span>")
		chargecount = 0
		update_icon()
	else if	((W.has_tool_quality(TOOL_SCREWDRIVER)))	// haxing
		if(opened)
			if(cell)
				to_chat(user, "<span class='warning'>Remove the power cell first.</span>")
				return
			else
				if(has_electronics == APC_HAS_ELECTRONICS_WIRED && terminal)
					has_electronics = APC_HAS_ELECTRONICS_SECURED
					stat &= ~MAINT
					playsound(src, W.usesound, 50, 1)
					to_chat(user, "You screw the circuit electronics into place.")
				else if(has_electronics == APC_HAS_ELECTRONICS_SECURED)
					has_electronics = APC_HAS_ELECTRONICS_WIRED
					stat |= MAINT
					playsound(src, W.usesound, 50, 1)
					to_chat(user, "You unfasten the electronics.")
				else /* has_electronics == APC_HAS_ELECTRONICS_NONE */
					to_chat(user, "<span class='warning'>There is nothing to secure.</span>")
					return
				update_icon()
		else
			wiresexposed = !wiresexposed
			to_chat(user, "The wires have been [wiresexposed ? "exposed" : "unexposed"].")
			playsound(src, W.usesound, 50, 1)
			update_icon()

	else if(istype(W, /obj/item/weapon/card/id)||istype(W, /obj/item/device/pda))			// trying to unlock the interface with an ID card
		togglelock(user)

	else if(W.has_tool_quality(TOOL_CABLE_COIL) && !terminal && opened && has_electronics != APC_HAS_ELECTRONICS_SECURED)
		var/turf/T = loc
		if(istype(T) && !T.is_plating())
			to_chat(user, "<span class='warning'>You must remove the floor plating in front of the APC first.</span>")
			return

		var/obj/item/stack/cable_coil/C = W
		if(istype(C, /obj/structure/cable/heavyduty))
			to_chat(user, "<span class='warning'>This cable is too bulky for APC terminals.</span>")
			return

		if(C.get_amount() < 10)
			to_chat(user, "<span class='warning'>You need ten lengths of cable for that.</span>")
			return

		var/terminal_cable_layer = C.target_layer
		user.visible_message("<span class='warning'>[user.name] adds cables to the APC frame.</span>", \
							"You start adding cables to the APC frame...")
		playsound(src, 'sound/items/Deconstruct.ogg', 50, 1)
		if(do_after(user, 20))
			if(C.get_amount() >= 10 && !terminal && opened && has_electronics != APC_HAS_ELECTRONICS_SECURED)
				var/turf/our_turf = get_turf(src)
				var/obj/structure/cable/cable_node = our_turf.get_cable_node(terminal_cable_layer)
				if(prob(50) && electrocute_mob(usr, cable_node, cable_node))
					var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
					s.set_up(5, 1, src)
					s.start()
					if(user.stunned)
						return
				C.use(10)
				user.visible_message(\
					"<span class='warning'>[user.name] has added cables to the APC frame!</span>",\
					"You add cables to the APC frame.")
				make_terminal(terminal_cable_layer)
				terminal.connect_to_network()
				return
	else if((W.has_tool_quality(TOOL_WIRECUTTER)) && terminal && opened && has_electronics != APC_HAS_ELECTRONICS_SECURED)
		var/turf/T = loc
		if(istype(T) && !T.is_plating())
			to_chat(user, "<span class='warning'>You must remove the floor plating in front of the APC first.</span>")
			return
		user.visible_message("<span class='warning'>[user.name] starts dismantling the [src]'s power terminal.</span>", \
							"You begin to cut the cables...")
		playsound(src, 'sound/items/Deconstruct.ogg', 50, 1)
		if(do_after(user, 50 * W.toolspeed))
			if(terminal && opened && has_electronics != APC_HAS_ELECTRONICS_SECURED)
				if(prob(50) && electrocute_mob(usr, terminal.powernet, terminal))
					var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
					s.set_up(5, 1, src)
					s.start()
					if(usr.stunned)
						return
				new /obj/item/stack/cable_coil(loc,10)
				to_chat(user, "<span class='notice'>You cut the cables and dismantle the power terminal.</span>")
				disconnect_terminal(terminal)
				qdel(terminal)
	else if(istype(W, /obj/item/weapon/module/power_control) && opened && has_electronics == APC_HAS_ELECTRONICS_NONE && !((stat & BROKEN)))
		user.visible_message("<span class='warning'>[user.name] inserts the power control board into [src].</span>", \
							"You start to insert the power control board into the frame...")
		playsound(src, 'sound/items/Deconstruct.ogg', 50, 1)
		if(do_after(user, 10))
			if(has_electronics == APC_HAS_ELECTRONICS_NONE)
				has_electronics = APC_HAS_ELECTRONICS_WIRED
				reboot()
				to_chat(user, "<span class='notice'>You place the power control board inside the frame.</span>")
				qdel(W)
	else if(istype(W, /obj/item/weapon/module/power_control) && opened && has_electronics == APC_HAS_ELECTRONICS_NONE && ((stat & BROKEN)))
		to_chat(user, "<span class='warning'>The [src] is too broken for that. Repair it first.</span>")
		return
	else if((W.has_tool_quality(TOOL_WELDER)) && opened && has_electronics == APC_HAS_ELECTRONICS_NONE && !terminal)
		var/obj/item/weapon/weldingtool/WT = W
		if(WT.get_fuel() < 3)
			to_chat(user, "<span class='warning'>You need more welding fuel to complete this task.</span>")
			return
		user.visible_message("<span class='warning'>[user.name] begins cutting apart [src] with the [WT.name].</span>", \
							"You start welding the APC frame...", \
							"You hear welding.")
		playsound(src, WT.usesound, 25, 1)
		if(do_after(user, 50 * WT.toolspeed))
			if(!src || !WT.remove_fuel(3, user)) return
			if(emagged || (stat & BROKEN) || opened==2)
				new /obj/item/stack/material/steel(loc)
				user.visible_message(\
					"<span class='warning'>[src] has been cut apart by [user.name] with the [WT.name].</span>",\
					"<span class='notice'>You disassembled the broken APC frame.</span>",\
					"You hear welding.")
			else
				new /obj/item/frame/apc(loc)
				user.visible_message(\
					"<span class='warning'>[src] has been cut from the wall by [user.name] with the [WT.name].</span>",\
					"<span class='notice'>You cut the APC frame from the wall.</span>",\
					"You hear welding.")
			qdel(src)
			return
	else if(opened && ((stat & BROKEN) || hacker || emagged))
		if(istype(W, /obj/item/frame/apc) && (stat & BROKEN))
			if(cell)
				to_chat(user, "<span class='warning'>You need to remove the power cell first.</span>")
				return
			user.visible_message("<span class='warning'>[user.name] begins replacing the damaged APC cover with a new one.</span>",\
								"You begin to replace the damaged APC cover...")
			if(do_after(user, 50))
				user.visible_message("<span class='notice'>[user.name] has replaced the damaged APC cover with a new one.</span>",\
					"You replace the damaged APC cover with a new one.")
				qdel(W)
				stat &= ~BROKEN
				reboot()
				if(opened==2)
					opened = 1
				update_icon()
		else if((W.has_tool_quality(TOOL_MULTITOOL)) && (hacker || emagged))
			if(cell)
				to_chat(user, "<span class='warning'>You need to remove the power cell first.</span>")
				return
			user.visible_message("<span class='warning'>[user.name] connects their [W.name] to the APC and begins resetting it.</span>",\
								"You begin resetting the APC...")
			if(do_after(user, 50))
				user.visible_message("<span class='notice'>[user.name] resets the APC with a beep from their [W.name].</span>",\
									"You finish resetting the APC.")
				playsound(src, 'sound/machines/chime.ogg', 25, 1)
				reboot()
	else
		if((stat & BROKEN) \
				&& !opened \
				&& W.force >= 5 \
				&& W.w_class >= ITEMSIZE_SMALL )
			user.visible_message("<span class='danger'>The [name] has been hit with the [W.name] by [user.name]!</span>", \
				"<span class='danger'>You hit the [name] with your [W.name]!</span>", \
				"You hear a bang!")
			if(prob(20))
				opened = 2
				user.visible_message("<span class='danger'>The APC cover was knocked down with the [W.name] by [user.name]!</span>", \
					"<span class='danger'>You knock down the APC cover with your [W.name]!</span>", \
					"You hear a bang!")
				update_icon()
		else
			if(istype(user, /mob/living/silicon))
				return attack_hand(user)
			if(!opened && wiresexposed && (istype(W, /obj/item/device/multitool) || W.is_wirecutter() || istype(W, /obj/item/device/assembly/signaler)))
				return attack_hand(user)
			//Placeholder until someone can do take_damage() for APCs or something.
			to_chat(user, "<span class='notice'>The [name] looks too sturdy to bash open with \the [W.name].</span>")

// attack with hand - remove cell (if cover open) or interact with the APC

/obj/machinery/power/apc/verb/togglelock(mob/user as mob)
	if(emagged)
		to_chat(user, "<span class='warning'>The panel is unresponsive.</span>")
	else if(opened)
		to_chat(user, "<span class='warning'>You must close the cover to swipe an ID card.</span>")
	else if(wiresexposed)
		to_chat(user, "<span class='warning'>You must close the wire panel.</span>")
	else if(stat & (BROKEN|MAINT))
		to_chat(user, "<span class='notice'>Nothing happens.</span>")
	else if(hacker)
		to_chat(user, "<span class='warning'>Access denied.</span>")
	else
		if(allowed(user) && !wires.is_cut(WIRE_IDSCAN))
			locked = !locked
			to_chat(user, "<span class='notice'>You [ locked ? "lock" : "unlock"] the APC interface.</span>")
			update_icon()
		else
			to_chat(user, "<span class='warning'>Access denied.</span>")

/obj/machinery/power/apc/AltClick(mob/user)
	..()
	togglelock(user)

/obj/machinery/power/apc/emag_act(var/remaining_charges, var/mob/user)
	if(!(emagged || hacker))		// trying to unlock with an emag card
		if(opened)
			to_chat(user, "You must close the cover to do that.")
		else if(wiresexposed)
			to_chat(user, "You must close the wire panel first.")
		else if(stat & (BROKEN|MAINT))
			to_chat(user, "The [src] isn't working.")
		else
			flick("apc-spark", src)
			if(do_after(user,6))
				emagged = TRUE
				locked = FALSE
				to_chat(user, "<span class='notice'>You emag the APC interface.</span>")
				update_icon()
				investigate_log("[user] emagged [name]", "powernet")
				return TRUE

/obj/machinery/power/apc/blob_act()
	if(!wires.is_all_cut())
		wiresexposed = TRUE
		wires.cut_all()
		update_icon()

/obj/machinery/power/apc/attack_hand(mob/user)
	if(!user)
		return
	add_fingerprint(user)

	//Human mob special interaction goes here.
	if(istype(user,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = user

		if(H.species.can_shred(H))
			user.setClickCooldown(user.get_attack_speed())
			user.visible_message("<span call='warning'>[user.name] slashes at the [name]!</span>", "<span class='notice'>You slash at the [name]!</span>")
			playsound(src, 'sound/weapons/slash.ogg', 100, 1)

			var/allcut = wires.is_all_cut()

			if(beenhit >= pick(3, 4) && wiresexposed != 1)
				wiresexposed = 1
				update_icon()
				visible_message("<span call='warning'>The [name]'s cover flies open, exposing the wires!</span>")

			else if(wiresexposed == 1 && allcut == 0)
				wires.cut_all()
				update_icon()
				visible_message("<span call='warning'>The [name]'s wires are shredded!</span>")
			else
				beenhit += 1
			return

	if(usr == user && opened && (!issilicon(user)))
		if(cell)
			user.put_in_hands(cell)
			cell.add_fingerprint(user)
			cell.update_icon()

			cell = null
			user.visible_message("<span class='warning'>[user.name] removes the power cell from [name]!</span>",\
								 "<span class='notice'>You remove the power cell.</span>")
			charging = 0
			update_icon()
		return
	if(stat & (BROKEN|MAINT))
		return
	// do APC interaction
	interact(user)

/obj/machinery/power/apc/attack_ghost(mob/user)
	if(panel_open)
		return wires.Interact(user)
	return tgui_interact(user)

/obj/machinery/power/apc/interact(mob/user)
	if(!user)
		return

	if(wiresexposed && !istype(user, /mob/living/silicon/ai))
		wires.Interact(user)
		return	//The panel is visibly dark when the wires are exposed, so we shouldn't be able to interact with it.

	return tgui_interact(user)

/obj/machinery/power/apc/tgui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "APC", name) // 510, 460
		ui.open()

/obj/machinery/power/apc/tgui_data(mob/user)
	var/list/data = list(
		"locked" = locked,
		"normallyLocked" = locked,
		"emagged" = emagged,
		"isOperating" = operating,
		"externalPower" = main_status,
		"powerCellStatus" = cell ? cell.percent() : null,
		"chargeMode" = chargemode,
		"chargingStatus" = charging,
		"totalLoad" = round(lastused_total),
		"totalCharging" = round(lastused_charging),
		"failTime" = failure_timer * 2,
		"gridCheck" = grid_check,
		"coverLocked" = coverlocked,
		"siliconUser" = issilicon(user) || (isobserver(user) && is_admin(user)), //I add observer here so admins can have more control, even if it makes 'siliconUser' seem inaccurate.
		"emergencyLights" = !emergency_lights,
		"nightshiftLights" = nightshift_lights,
		"nightshiftSetting" = nightshift_setting,

		"powerChannels" = list(
			list(
				"title" = "Equipment",
				"powerLoad" = lastused_equip,
				"status" = equipment,
				"topicParams" = list(
					"auto" = list("eqp" = 3),
					"on"   = list("eqp" = 2),
					"off"  = list("eqp" = 1)
				)
			),
			list(
				"title" = "Lighting",
				"powerLoad" = round(lastused_light),
				"status" = lighting,
				"topicParams" = list(
					"auto" = list("lgt" = 3),
					"on"   = list("lgt" = 2),
					"off"  = list("lgt" = 1)
				)
			),
			list(
				"title" = "Environment",
				"powerLoad" = round(lastused_environ),
				"status" = environ,
				"topicParams" = list(
					"auto" = list("env" = 3),
					"on"   = list("env" = 2),
					"off"  = list("env" = 1)
				)
			)
		)
	)

	return data

/obj/machinery/power/apc/proc/report()
	return "[area.name] : [equipment]/[lighting]/[environ] ([lastused_equip+lastused_light+lastused_environ]) : [cell? cell.percent() : "N/C"] ([charging])"

/obj/machinery/power/apc/proc/update()
	if(operating && !shorted && !grid_check && !failure_timer)
		area.power_light = (lighting >= POWERCHAN_ON)
		area.power_equip = (equipment >= POWERCHAN_ON)
		area.power_environ = (environ >= POWERCHAN_ON)
		playsound(src.loc, 'sound/machines/terminal_on.ogg', 50, FALSE)
//		if(area.name == "AI Chamber")
//			spawn(10)
//				to_world(" [area.name] [area.power_equip]")
	else
		area.power_light = FALSE
		area.power_equip = FALSE
		area.power_environ = FALSE
		playsound(src.loc, 'sound/machines/terminal_off.ogg', 50, FALSE)
//		if(area.name == "AI Chamber")
//			to_world("[area.power_equip]")
	area.power_change()

/obj/machinery/power/apc/proc/can_use(mob/user as mob, var/loud = FALSE) //used by attack_hand() and Topic()
	if(!user.client)
		return FALSE
	if(isobserver(user) && is_admin(user)) //This is to allow nanoUI interaction by ghost admins.
		return TRUE
	if(user.stat)
		return FALSE
	if(inoperable())
		return FALSE
	if(!user.IsAdvancedToolUser())
		return FALSE
	if(user.restrained())
		to_chat(user, "<span class='warning'>Your hands must be free to use [src].</span>")
		return FALSE
	if(user.lying)
		to_chat(user, "<span class='warning'>You must stand to use [src]!</span>")
		return FALSE
	autoflag = 5
	if(istype(user, /mob/living/silicon))
		var/permit = 0 // Malfunction variable. If AI hacks APC it can control it even without AI control wire.
		var/mob/living/silicon/ai/AI = user
		var/mob/living/silicon/robot/robot = user
		if(hacker)
			if(hacker == AI)
				permit = 1
			else if(istype(robot) && robot.connected_ai && robot.connected_ai == hacker) // Cyborgs can use APCs hacked by their AI
				permit = 1

		if(aidisabled && !permit)
			if(!loud)
				to_chat(user, "<span class='danger'>\The AI control for [src] has been disabled!</span>")
			return FALSE
	else
		if(!in_range(src, user) || !istype(loc, /turf))
			return FALSE
	var/mob/living/carbon/human/H = user
	if(istype(H) && prob(H.getBrainLoss()))
		to_chat(user, "<span class='danger'>You momentarily forget how to use [src].</span>")
		return FALSE
	return TRUE

/obj/machinery/power/apc/tgui_act(action, params)
	if(..() || !can_use(usr, TRUE))
		return TRUE

	// There's a handful of cases where we want to allow users to bypass the `locked` variable.
	// If can_admin_interact() wasn't only defined on observers, this could just be part of a single-line
	// conditional.
	var/locked_exception = FALSE
	if(issilicon(usr) || action == "nightshift")
		locked_exception = TRUE
	if(isobserver(usr))
		var/mob/observer/dead/D = usr
		if(D.can_admin_interact())
			locked_exception = TRUE

	if(locked && !locked_exception)
		return

	. = TRUE
	switch(action)
		if("lock")
			if(locked_exception) // Yay code reuse
				if(emagged || (stat & (BROKEN|MAINT)))
					to_chat(usr, "The APC does not respond to the command.")
					return
				locked = !locked
				update_icon()
		if("cover")
			coverlocked = !coverlocked
		if("breaker")
			toggle_breaker()
		if("nightshift")
			if(last_nightshift_switch > world.time - 10 SECONDS) // don't spam...
				to_chat(usr, "<span class='warning'>[src]'s night lighting circuit breaker is still cycling!</span>")
				return FALSE
			last_nightshift_switch = world.time
			nightshift_setting = params["nightshift"]
			update_nightshift()
		if("charge")
			chargemode = !chargemode
			if(!chargemode)
				charging = 0
				update_icon()
		if("channel")
			if(params["eqp"])
				equipment = setsubsystem(text2num(params["eqp"]))
				update_icon()
				update()
			else if(params["lgt"])
				lighting = setsubsystem(text2num(params["lgt"]))
				update_icon()
				update()
			else if(params["env"])
				environ = setsubsystem(text2num(params["env"]))
				update_icon()
				update()
		if("reboot")
			failure_timer = 0
			update_icon()
			update()
		if("emergency_lighting")
			emergency_lights = !emergency_lights
			for(var/obj/machinery/light/L in area)
				if(!initial(L.no_emergency)) //If there was an override set on creation, keep that override
					L.no_emergency = emergency_lights
					INVOKE_ASYNC(L, TYPE_PROC_REF(/obj/machinery/light, update), FALSE)
				CHECK_TICK
		if("overload")
			if(locked_exception) // Reusing for simplicity!
				overload_lighting()

/obj/machinery/power/apc/proc/toggle_breaker()
	operating = !operating
	update()
	update_icon()

/obj/machinery/power/apc/surplus()
	if(terminal)
		return terminal.surplus()
	else
		return 0

/obj/machinery/power/apc/proc/last_surplus()
	if(terminal && terminal.powernet)
		return terminal.powernet.last_surplus()
	else
		return 0

//Returns 1 if the APC should attempt to charge
/obj/machinery/power/apc/proc/attempt_charging()
	return (chargemode && charging == 1 && operating)


/obj/machinery/power/apc/draw_power(var/amount)
	if(terminal && terminal.powernet)
		return terminal.powernet.draw_power(amount)
	return 0

/obj/machinery/power/apc/avail()
	if(terminal)
		return terminal.avail()
	else
		return 0

/obj/machinery/power/apc/process()
	if(!area.requires_power)
		return PROCESS_KILL
	if(stat & (BROKEN|MAINT))
		return
	if(failure_timer)
		update()
		queue_icon_update()
		failure_timer--
		force_update = 1
		return

	lastused_light = area.usage(LIGHT, lighting >= POWERCHAN_ON)
	lastused_equip = area.usage(EQUIP, equipment >= POWERCHAN_ON)
	lastused_environ = area.usage(ENVIRON, environ >= POWERCHAN_ON)
	area.clear_usage()

	lastused_total = lastused_light + lastused_equip + lastused_environ

	//store states to update icon if any change
	var/last_lt = lighting
	var/last_eq = equipment
	var/last_en = environ
	var/last_ch = charging

	var/excess = surplus()

	if(!avail())
		main_status = APC_EXTERNAL_POWER_NOTCONNECTED
	else if(excess < 0)
		main_status = APC_EXTERNAL_POWER_NOENERGY
	else
		main_status = APC_EXTERNAL_POWER_GOOD

	if(debug)
		log_debug("Status: [main_status] - Excess: [excess] - Last Equip: [lastused_equip] - Last Light: [lastused_light] - Longterm: [longtermpower]")

	if(cell && !shorted && !grid_check)
		// draw power from cell as before to power the area
		var/cellused = min(cell.charge, CELLRATE * lastused_total)	// clamp deduction to a max, amount left in cell
		cell.use(cellused)

		if(excess > lastused_total)		// if power excess recharge the cell
										// by the same amount just used
			var/draw = draw_power(cellused/CELLRATE) // draw the power needed to charge this cell
			cell.give(draw * CELLRATE)
		else		// no excess, and not enough per-apc
			if( (cell.charge/CELLRATE + excess) >= lastused_total)		// can we draw enough from cell+grid to cover last usage?
				var/draw = draw_power(excess)
				cell.charge = min(cell.maxcharge, cell.charge + CELLRATE * draw)	//recharge with what we can
				charging = 0
			else	// not enough power available to run the last tick!
				charging = 0
				chargecount = 0
				// This turns everything off in the case that there is still a charge left on the battery, just not enough to run the room.
				equipment = autoset(equipment, 0)
				lighting = autoset(lighting, 0)
				environ = autoset(environ, 0)
				autoflag = 0


		// Set channels depending on how much charge we have left
		update_channels()

		// now trickle-charge the cell
		lastused_charging = 0 // Clear the variable for new use.
		if(attempt_charging())
			if(excess > 0)		// check to make sure we have enough to charge
				// Max charge is capped to % per second constant
				var/ch = min(excess*CELLRATE, cell.maxcharge*chargelevel)

				ch = draw_power(ch/CELLRATE) // Removes the power we're taking from the grid
				cell.give(ch*CELLRATE) // actually recharge the cell
				lastused_charging = ch
				lastused_total += ch // Sensors need this to stop reporting APC charging as "Other" load
			else
				charging = 0		// stop charging
				chargecount = 0

		// show cell as fully charged if so
		if(cell.charge >= cell.maxcharge)
			cell.charge = cell.maxcharge
			charging = 2

		if(chargemode)
			if(!charging)
				if(excess > cell.maxcharge*chargelevel)
					chargecount++
				else
					chargecount = 0

				if(chargecount >= 10)

					chargecount = 0
					charging = 1

		else // chargemode off
			charging = 0
			chargecount = 0

	else // no cell, switch everything off
		charging = 0
		chargecount = 0
		equipment = autoset(equipment, 0)
		lighting = autoset(lighting, 0)
		environ = autoset(environ, 0)
		power_alarm.triggerAlarm(loc, src, hidden=alarms_hidden)
		autoflag = 0

	// update icon & area power if anything changed
	if(last_lt != lighting || last_eq != equipment || last_en != environ || force_update)
		force_update = 0
		queue_icon_update()
		update()
	else if(last_ch != charging)
		queue_icon_update()

/obj/machinery/power/apc/proc/update_channels()
	// Allow the APC to operate as normal if the cell can charge
	if(charging && longtermpower < 10)
		longtermpower += 1
	else if(longtermpower > -10)
		longtermpower -= 2

	if((cell.percent() > 30) || longtermpower > 0)              // Put most likely at the top so we don't check it last, effeciency 101
		if(autoflag != 3)
			equipment = autoset(equipment, 1)
			lighting = autoset(lighting, 1)
			environ = autoset(environ, 1)
			autoflag = 3
			power_alarm.clearAlarm(loc, src)
	else if((cell.percent() <= 30) && (cell.percent() > 15) && longtermpower < 0)                       // <30%, turn off equipment
		if(autoflag != 2)
			equipment = autoset(equipment, 2)
			lighting = autoset(lighting, 1)
			environ = autoset(environ, 1)
			power_alarm.triggerAlarm(loc, src, hidden=alarms_hidden)
			autoflag = 2
	else if(cell.percent() <= 15)        // <15%, turn off lighting & equipment
		if((autoflag > 1 && longtermpower < 0) || (autoflag > 1 && longtermpower >= 0))
			equipment = autoset(equipment, 2)
			lighting = autoset(lighting, 2)
			environ = autoset(environ, 1)
			power_alarm.triggerAlarm(loc, src, hidden=alarms_hidden)
			autoflag = 1
	else                                   // zero charge, turn all off
		if(autoflag != 0)
			equipment = autoset(equipment, 0)
			lighting = autoset(lighting, 0)
			environ = autoset(environ, 0)
			power_alarm.triggerAlarm(loc, src, hidden=alarms_hidden)
			autoflag = 0

// val 0=off, 1=off(auto) 2=on 3=on(auto)
// on 0=off, 1=on, 2=autooff
// defines a state machine, returns the new state
/obj/machinery/power/apc/proc/autoset(var/cur_state, var/on)
	switch(cur_state)
		//if(POWERCHAN_OFF); //autoset will never turn on a channel set to off
		if(POWERCHAN_OFF_AUTO)
			if(on == 1)
				return POWERCHAN_ON_AUTO
		if(POWERCHAN_ON)
			if(on == 0)
				return POWERCHAN_OFF
		if(POWERCHAN_ON_AUTO)
			if(on == 0 || on == 2)
				return POWERCHAN_OFF_AUTO

	return cur_state //leave unchanged


// damage and destruction acts
/obj/machinery/power/apc/emp_act(severity)
	// Fail for 8-12 minutes (divided by severity)
	// Division by 2 is required, because machinery ticks are every two seconds. Without it we would fail for 16-24 minutes.
	if(is_critical)
		// Critical APCs are considered EMP shielded and will be offline only for about half minute. Prevents AIs being one-shot disabled by EMP strike.
		// Critical APCs are also more resilient to cell corruption/power drain.
		energy_fail(rand(240, 360) / severity / CRITICAL_APC_EMP_PROTECTION)
		if(cell)
			cell.emp_act(severity+2)
	else
		// Regular APCs fail for normal time.
		energy_fail(rand(240, 360) / severity)
		//Cells are partially shielded by the APC frame.
		if(cell)
			cell.emp_act(severity+1)

	update_icon()
	..()

/obj/machinery/power/apc/ex_act(severity)

	switch(severity)
		if(1)
			//set_broken() //now qdel() do what we need
			if(cell)
				cell.ex_act(1) // more lags woohoo
			qdel(src)
			return
		if(2)
			if(prob(75))
				set_broken()
				if(cell && prob(50))
					cell.ex_act(2)
		if(3)
			if(prob(50))
				set_broken()
				if(cell && prob(50))
					cell.ex_act(3)
		if(4)
			if(prob(25))
				set_broken()
				if(cell && prob(50))
					cell.ex_act(3)
	return

/obj/machinery/power/apc/disconnect_terminal(var/obj/machinery/power/terminal/term)
	if(terminal)
		terminal.master = null
		terminal = null
	update_cable_icons_on_turf(get_turf(src))

/obj/machinery/power/apc/proc/set_broken()
	// Aesthetically much better!
	spawn(rand(2,5))
		visible_message("<span class='warning'>[src]'s screen flickers suddenly, then explodes in a rain of sparks and small debris!</span>")
		stat |= BROKEN
		operating = 0
		update_icon()
		update()

// overload the lights in this APC area

/obj/machinery/power/apc/proc/overload_lighting(var/chance = 100)
	if(/* !get_connection() || */ !operating || shorted || grid_check)
		return
	if( cell && cell.charge>=20)
		cell.use(20);
		spawn(0)
			for(var/obj/machinery/light/L in area)
				if(prob(chance))
					L.on = 1
					L.broken()
				sleep(1)

/obj/machinery/power/apc/proc/setsubsystem(val)
	if(cell && cell.charge > 0)
		return (val==1) ? 0 : val
	else if(val == 3)
		return 1
	else
		return 0

// Malfunction: Transfers APC under AI's control
/obj/machinery/power/apc/proc/ai_hack(var/mob/living/silicon/ai/A = null)
	if(!A || !A.hacked_apcs || hacker || aidisabled || A.stat == DEAD)
		return FALSE
	hacker = A
	A.hacked_apcs += src
	locked = 1
	update_icon()
	return TRUE

/obj/machinery/power/apc/proc/reboot()
	//reset various counters so that process() will start fresh
	charging = initial(charging)
	chargecount = initial(chargecount)
	autoflag = initial(autoflag)
	longtermpower = initial(longtermpower)
	failure_timer = initial(failure_timer)

	//start with main breaker off, chargemode in the default state and all channels on auto upon reboot
	operating = 0
	chargemode = initial(chargemode)
	power_alarm.clearAlarm(loc, src)

	lighting = POWERCHAN_ON_AUTO
	equipment = POWERCHAN_ON_AUTO
	environ = POWERCHAN_ON_AUTO

	//If malf AI had this APC before, they don't now.
	if(hacker && hacker.hacked_apcs && (src in hacker.hacked_apcs))
		hacker.hacked_apcs -= src
		hacker = null

	emagged = initial(emagged) //Resets emagging, too.

	update_icon()
	update()

/obj/machinery/power/apc/overload(var/obj/machinery/power/source)
	if(is_critical)
		return

	if(prob(30)) // Nothing happens.
		return

	if(prob(40)) // Lights blow.
		overload_lighting()

	if(prob(40)) // Spooky flickers.
		for(var/obj/machinery/light/L in area)
			L.flicker(rand(20,30))

	if(prob(25)) // Bluescreens.
		emagged = 1
		locked = 0
		update_icon()

	if(prob(25)) // Cell gets damaged.
		if(cell)
			cell.corrupt()

	if(prob(10)) // Computers get broken.
		for(var/obj/machinery/computer/comp in area)
			comp.ex_act(3)

	if(prob(5)) // APC completely ruined.
		set_broken()

/obj/machinery/power/apc/do_grid_check()
	if(is_critical)
		return
	grid_check = TRUE
	spawn(15 MINUTES) // Protection against someone deconning the grid checker after a grid check happens, preventing infinte blackout.
		if(src && grid_check == TRUE)
			grid_check = FALSE

/obj/machinery/power/apc/proc/set_nightshift(on, var/automated)
	set waitfor = FALSE
	if(automated && istype(area, /area/shuttle))
		return
	nightshift_lights = on
	update_nightshift()

/obj/machinery/power/apc/proc/update_nightshift()
	var/new_state = nightshift_lights

	switch(nightshift_setting)
		if(NIGHTSHIFT_NEVER)
			new_state = FALSE
		if(NIGHTSHIFT_ALWAYS)
			new_state = TRUE

	for(var/obj/machinery/light/L in area)
		L.nightshift_mode(new_state)
		L.update() //For some reason it gets hung up on updating the overlay for the light fixture somewhere down the line. This fixes it.
		CHECK_TICK

#undef APC_UPDATE_ICON_COOLDOWN

#undef APC_EXTERNAL_POWER_NOTCONNECTED
#undef APC_EXTERNAL_POWER_NOENERGY
#undef APC_EXTERNAL_POWER_GOOD

#undef APC_HAS_ELECTRONICS_NONE
#undef APC_HAS_ELECTRONICS_WIRED
#undef APC_HAS_ELECTRONICS_SECURED
