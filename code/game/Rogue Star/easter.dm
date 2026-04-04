//RS FILE
/obj/easter_egg_spawner
	name = "easter egg spawner"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "egg"
	plane = PLANE_ADMIN_SECRET
	anchored = TRUE
	alpha = 125

	var/static/list/eggpaths

/obj/easter_egg_spawner/attack_ghost(mob/user)
	. = ..()

	if(!user?.client?.holder) return

	var/choice = tgui_input_number(user,"How many eggs would you like to spawn on this Z level?","Spawn Easter Eggs")

	if(!choice)
		return
	if(!isnum(choice))
		return
	while(choice > 0)
		if(spawn_egg())
			choice --

	to_chat(user, SPAN_NOTICE("Eggs were spawned."))

/obj/easter_egg_spawner/proc/spawn_egg()
	var/turf/T = locate(rand(1,world.maxx),rand(1,world.maxy),z)

	if(T.check_density(FALSE,TRUE))
		return FALSE
	if(isspace(T))
		return FALSE

	for(var/mob/living/sus in viewers(T))
		if(!isliving(sus))
			continue
		if(sus.ckey)
			return FALSE

	if(eggpaths?.len <= 0)
		eggpaths = subtypesof(/obj/item/weapon/reagent_containers/food/snacks/egg)

	var/which = pick(eggpaths)

	new which(T)
	return TRUE
