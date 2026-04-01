//RS FILE

/*
/////IDEAS
Make search potentially require being approached from a certain direction?
Sofa and comfy chair hidden inventory has a small chance to add small searchers to their hidden inventory

Make a corresponding HIDE ability, in which you can stash things in an object, and have stashes persist. :)

/////POSSIBLE SEARCHABLES
Sofa
Bed
Potted plant
Comfy chair
Vending machiene - ONLY FROM BEHIND?
Trash piles?
*/


/atom/proc/search()
	if(!Adjacent(usr))
		return FALSE
	SEND_SIGNAL(src,COMSIG_SEARCHED,usr)

/mob
	var/click_flags = 0
/mob/proc/search_on()
	click_flags |= CLICK_SEARCH
/mob/proc/search_off()
	click_flags &= ~CLICK_SEARCH
/mob/verb/toggle_search()
	set name = "Toggle-Search"
	set hidden = TRUE
	if(click_flags & CLICK_SEARCH)
		search_off()
	else
		search_on()

/obj/search()
	. = ..()
	if(micro_target)
		if(!Adjacent(usr))
			return FALSE
		micro_interact()
		return TRUE

/obj/structure/bed/chair/sofa/Initialize()
	. = ..()
	LoadComponent(/datum/component/hidden_inventory,/obj/item/weapon/coin/gold,"Under the cushions.")

/datum/component/hidden_inventory
	var/description = "A small compartment."
	var/list/inventory = list()
	var/found = FALSE

/datum/component/hidden_inventory/New(list/raw_args)
	. = ..()
	if(raw_args[2])
		var/ourpath = raw_args[2]
		var/a = new ourpath()
		inventory |= a
	if(raw_args[3])
		description = raw_args[3]

/datum/component/hidden_inventory/Initialize()
	. = ..()
	RegisterSignal(parent, COMSIG_SEARCHED, PROC_REF(search))

/datum/component/hidden_inventory/proc/search()
	to_world("Search triggered on [parent]!")
	if(inventory.len == 0)
		return
	if(!isliving(args[2]))
		return
	var/mob/living/L = args[2]
	if(!L)
		return
	if(!found)
		found = TRUE
		L.grant_xp(SKILL_SEEKING,1)

	var/choice = tgui_input_list(L,description,"Search",inventory)
	if(choice)
		inventory -= choice
		if(isobj(choice))
			var/obj/thing = choice
			thing.forceMove(get_turf(L))
			thing.visible_message(SPAN_WARNING("\The [thing] tumbles free from \the [parent]!"),runemessage = "POF!")
