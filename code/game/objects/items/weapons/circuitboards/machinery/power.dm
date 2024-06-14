#ifndef T_BOARD
#error T_BOARD macro is not defined but we need it!
#endif

/obj/item/weapon/circuitboard/smes
	name = T_BOARD("superconductive magnetic energy storage")
	build_path = /obj/machinery/power/smes
	board_type = new /datum/frame/frame_types/machine
	origin_tech = list(TECH_POWER = 6, TECH_ENGINEERING = 4)
	req_components = list(/obj/item/weapon/smes_coil = 1, /obj/item/stack/cable_coil = 30)

/obj/item/weapon/circuitboard/smes/construct(var/obj/machinery/power/smes/S)
	if(..(S))
		S.output_attempt = 0 //built SMES default to off

/obj/item/weapon/circuitboard/batteryrack
	name = T_BOARD("battery rack PSU")
	build_path = /obj/machinery/power/smes/batteryrack
	board_type = new /datum/frame/frame_types/machine
	origin_tech = list(TECH_POWER = 3, TECH_ENGINEERING = 2)
	req_components = list(/obj/item/weapon/stock_parts/capacitor/ = 3, /obj/item/weapon/stock_parts/matter_bin/ = 1)

/obj/item/weapon/circuitboard/grid_checker
	name = T_BOARD("power grid checker")
	build_path = /obj/machinery/power/grid_checker
	board_type = new /datum/frame/frame_types/machine
	origin_tech = list(TECH_POWER = 4, TECH_ENGINEERING = 3)
	req_components = list(/obj/item/weapon/stock_parts/capacitor = 3, /obj/item/stack/cable_coil = 10)

/obj/item/weapon/circuitboard/breakerbox
	name = T_BOARD("breaker box")
	build_path = /obj/machinery/power/breakerbox
	board_type = new /datum/frame/frame_types/machine
	origin_tech = list(TECH_POWER = 3, TECH_ENGINEERING = 3)
	req_components = list(
		/obj/item/weapon/stock_parts/spring = 1,
		/obj/item/weapon/stock_parts/manipulator = 1,
		/obj/item/stack/cable_coil = 10)

/obj/item/weapon/circuitboard/power_transmitter
	name = T_BOARD("Power Transmitter")
	build_path = /obj/machinery/power/power_transmitter
	board_type = new /datum/frame/frame_types/machine
	origin_tech = list(TECH_DATA = 3, TECH_ENGINEERING = 5, TECH_POWER = 5, TECH_BLUESPACE = 4)
	req_components = list(
							/obj/item/weapon/stock_parts/subspace/ansible = 1,
							/obj/item/weapon/smes_coil/super_io = 1,
							/obj/item/weapon/stock_parts/capacitor = 5,
							/obj/item/weapon/stock_parts/console_screen = 1,
							/obj/item/stack/cable_coil/heavyduty = 20
						)
