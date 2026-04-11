/obj/item/triangle
	name = "tick"
	desc = "A curious triangular coin made primarily of some kind of dark, smooth metal. "
	icon = 'icons/rogue-star/coins.dmi'
	icon_state = "1"
	randpixel = 8
	force = 0.5
	throwforce = 0.5
	w_class = ITEMSIZE_TINY
	slot_flags = SLOT_EARS
	drop_sound = 'sound/items/drop/ring.ogg'
	pickup_sound = 'sound/items/pickup/ring.ogg'

	var/value = 1
	var/close_desc = "It has some writing along its edge that seems to be some language that you are not familiar with. The face of the coin is very smooth, with what appears to be some kind of angular logo along the left side, and a couple of lines of the alien text along the opposite side. The reverse side is similarly smooth, the top of it features what appears to be some kind of vortex, surrounded by six stars, three on either side, with further swirls and intricate patterns along the bottom sections of this face. Looking closely, you can see that there is more text hidden among the swirls."

/obj/item/triangle/New()
	randpixel_xy()
	update_icon()

/obj/item/triangle/get_nametag_desc(mob/user)
	return "[value]◬"

/obj/item/triangle/examine(mob/user)
	. = ..()
	if(Adjacent(user))
		. += SPAN_NOTICE(close_desc)
		. += SPAN_OCCULT("It is worth [value]◬.")

/obj/item/triangle/Moved(atom/old_loc, direction, forced, movetime)
	. = ..()
	update_icon()

/obj/item/triangle/update_icon()
	if(ismob(loc))
		icon_state = "[value]"
	else
		icon_state = "[value]s"

/obj/item/triangle/attackby(obj/item/weapon/W, mob/user)
	if(istype(W,/obj/item/triangle))
		var/obj/item/coinstack/stack
		if(istype(src.loc,/obj/item/coinstack))
			stack = src.loc
		else
			stack = new(get_turf(src))
			var/pre_loc = src.loc
			stack.stack(src,user)
			if(istype(pre_loc,/obj/item/weapon/storage))
				var/obj/item/weapon/storage/S = pre_loc
				if(S.can_be_inserted(stack))
					S.handle_item_insertion(stack)

		stack.stack(W,user)
		return
	return ..()
/obj/item/triangle/attack_hand(mob/living/user)
	if(istype(src.loc,/obj/item/coinstack))
		var/obj/item/coinstack/stack = src.loc
		stack.attack_hand(user)
		return
	return ..()

/obj/item/triangle/proc/flip_coin(mob/user)
	var/result = rand(1,2)
	var/comment = ""
	if(result == 1)
		comment = "tails"
	else if(result == 2)
		comment = "heads"
	if(loc == user)
		user.visible_message("<span class='notice'>[user] has thrown [src]. It lands on [comment]! </span>", runemessage = "[comment]! ! !")
	else
		if(user)
			visible_message("<span class='notice'>[user] has thrown [src]. It lands on [comment]! </span>", runemessage = "[comment]! ! !")
		else
			visible_message("<span class='notice'>\The [src] lands on [comment]! </span>", runemessage = "[comment]! ! !")

/obj/item/triangle/attack_self(mob/user as mob)
	flip_coin(user)

/obj/item/triangle/throw_at(atom/target, range, speed, mob/thrower, spin, datum/callback/callback)
	. = ..()
	flip_coin(thrower)

/////VARIANTS/////

/obj/item/triangle/u02
	name = "bit"
	desc = "A small oval coin made of a smooth dark metal."
	icon_state = "02"
	value = 0.2
	close_desc = "A small and simply decorated coin. Used for very small transactions. You could buy some everyday nessesities with one or two of these."

/obj/item/triangle/u1
	name = "tick"
	desc = "A small triangular coin made of a smooth dark metal."
	icon_state = "1"
	value = 1
	close_desc = "A small and simply decorated coin. The kind of thing you might get for an hour's work. The kind of coin one might gamble with."

/obj/item/triangle/u5
	name = "tack"
	desc = "A small triangular coin made of a smooth silver metal. It has a small hole in the middle."
	icon_state = "5"
	value = 5
	close_desc = "A small shiny coin with pretty intricate decorations. This coin might cover a modest meal."

/obj/item/triangle/u10
	name = "mark"
	desc = "A triangular coin made of a smooth dark metal. It has a oblong hole in the middle lined with a golden colored accent."
	icon_state = "10"
	value = 10
	close_desc = "A very intricately decorated coin. This coin might represent a day's wage."

/obj/item/triangle/u13
	name = "???"
	desc = "A small circular coin made of a smooth dark metal. It shows two opposing triangles in gold and magenta colored accents."
	icon_state = "13"
	value = 13
	close_desc = "A strange coin with intricate iconography covering its surfaces!"

/obj/item/triangle/u25
	name = "glint"
	desc = "A triangular coin made of a smooth dark metal. It has a triangular hole in the middle lined with a magenta colored accent. It has intricate designs on it."
	icon_state = "25"
	value = 25
	close_desc = "A very intricately decorated coin! This one might cover a week of rent in a modest home!"

/obj/item/triangle/u100
	name = "shine"
	desc = "A triangular coin made of a smooth pearlescent metal. It has a square hole in the center with some kind of crystaline structure running through the center."
	icon_state = "100"
	value = 100
	close_desc = "An extremely ornate coin worth quite a lot!"

/obj/item/triangle/u1000
	name = "gleam"
	desc = "An ominous looking triangular coin made of black metal. It has strangely reflective yellow accents."
	icon_state = "1000"
	value = 1000
	close_desc = "A surprisingly gloomy and plain looking coin. It represents quite a lot of wealth! You could probably afford to live most of a year on this kind of money."

/obj/item/triangle/random
	name = "RANDOM COIN"
	desc = "You shouldn't see this."
	value = 0

/obj/item/triangle/random/New()
	. = ..()
	var/list/coins = list(
		/obj/item/triangle/u1 = 5000,
		/obj/item/triangle/u02 = 1000,
		/obj/item/triangle/u5 = 500,
		/obj/item/triangle/u10 = 100,
		/obj/item/triangle/u13 = 25,
		/obj/item/triangle/u25 = 1
	)
	var/which = pickweight(coins)
	new which(get_turf(src))
	qdel(src)

/////COIN POUCH/////
/obj/item/coinpouch
	name = "coin pouch"
	desc = "A pouch for holding coins."
	icon = 'icons/rogue-star/coins.dmi'
	icon_state = "pouch"
	color = "#5f3c69"
	var/list/stored_coins = list()
	var/static/list/overlays_cache = list()
	var/accent_color = "#971504"

/obj/item/coinpouch/examine(mob/user)
	. = ..()

	. += SPAN_OCCULT("If you use this on help intent, you can pick any coin you like. On harm intent, you will empty \the [src]. On any other intent, you will pick a random coin.")

/obj/item/coinpouch/Destroy()
	empty()
	return ..()

/obj/item/coinpouch/update_icon()
	cut_overlays()

	if(accent_color)
		var/combine_key = "[icon_state]-accent-[accent_color]"
		var/image/contact = overlays_cache[combine_key]
		if(!contact)
			contact = image(icon,null,"[icon_state]-accent")
			contact.color = accent_color
			contact.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
			overlays_cache[combine_key] = contact
		add_overlay(contact)


/obj/item/key/scifi/Initialize()
	. = ..()
	update_icon()

/obj/item/key/scifi/update_icon()





/obj/item/coinpouch/attackby(obj/item/weapon/W, mob/user)
	if(istype(W,/obj/item/triangle))
		var/obj/item/triangle/T = W
		user.drop_from_inventory(T)
		T.forceMove(src)
		stored_coins += T
		to_chat(user,SPAN_NOTICE("You place \the [T] into \the [src]."))

/obj/item/coinpouch/attack_self(mob/user)
	if(loc != user)
		return
	if(stored_coins.len <= 0)
		return
	var/obj/item/triangle/T
	if(user.a_intent == I_HELP)
		T = tgui_input_list(user,"Which one do you want?","[src]",stored_coins)
		if(!T)
			return
	else if(user.a_intent == I_HURT)
		empty()
		user.visible_message(SPAN_DANGER("\The [user] empties \the [src], spilling its contents on the floor!"),SPAN_DANGER("You empty \the [src], spilling its contents on the floor!"),runemessage = "CLINK")
		return

	if(!T)
		take_random_coin(user)
	else
		take_coin(user,T)

/obj/item/coinpouch/attack_hand(mob/living/user)
	if(user.a_intent == I_HELP)
		return ..()
	take_random_coin(user)

/obj/item/coinpouch/resolve_attackby(atom/A, mob/user, attack_modifier, click_parameters)
	if(!collect_coins_from_turf(A,user))
		return ..()

/obj/item/coinpouch/proc/collect_coins_from_turf(var/search,var/mob/living/user)
	var/turf/T
	if(isturf(search))
		T = search
		var/found = FALSE
		for(var/thing in T.contents)
			if(istype(thing,/obj/item/triangle))
				found = TRUE
				break
		if(!found)
			return FALSE
	else if(istype(search,/obj/item/triangle))
		T = get_turf(search)
	if(!T)
		return FALSE

	user.visible_message(SPAN_WARNING("\The [user] begins scooping the coins into \the [src]..."),SPAN_NOTICE("You begin scooping the coins into \the [src]..."),runemessage = ". . .")
	if(do_after(user,0.25 * T.contents.len SECONDS,T,exclusive = TRUE))
		for(var/obj/item/triangle/coin in T.contents)
			if(istype(coin,/obj/item/triangle))
				coin.forceMove(src)
				stored_coins += coin
		user.visible_message(SPAN_WARNING("\The [user] scoops all of the coins into \the [src]!"),SPAN_NOTICE("You scoop all of the coins into \the [src]!"),runemessage = "clink ! ! !")
	else
		user.visible_message(SPAN_WARNING("\The [user] was interrupted!"),SPAN_NOTICE("You were interrupted!"),runemessage = "!")

	return TRUE

/obj/item/coinpouch/proc/take_coin(var/mob/living/user,var/obj/item/triangle/coin)
	if(!coin || !user)
		return
	user.face_atom(src)
	stored_coins -= coin
	if(user.put_in_hands(coin))
		user.visible_message(SPAN_WARNING("\The [user] reaches into \the [src]... and pulls out \the [coin]!"),SPAN_NOTICE("You reach into \the [src] and pull out \the [coin]!"),runemessage = ". . .")
	else
		user.visible_message(SPAN_WARNING("\The [user] reaches into \the [src]... and pulls out \the [coin]!"),SPAN_DANGER("You reach into \the [src] and pull out \the [coin]... your hands are full though so it falls on the floor..."),runemessage = ". . .")
	playsound(get_turf(user),'sound/items/pickup/ring.ogg',100,TRUE)

/obj/item/coinpouch/proc/take_random_coin(var/mob/living/user)
	var/obj/item/triangle/coin = pick(contents)
	take_coin(user,coin)

/obj/item/coinpouch/proc/empty()
	var/turf/ourturf = get_turf(src)
	for(var/obj/item/triangle/coin in stored_coins)
		coin.forceMove(ourturf)
		stored_coins -= coin
		coin.randpixel_xy()

///// Stacked up /////

/obj/item/coinstack
	name = "coin stack"
	desc = "A stack of coins."
	icon = null
	icon_state = null
	plane = MOB_PLANE
	layer = MOB_LAYER

/obj/item/coinstack/examine(mob/user)
	. = ..()
	. += SPAN_OCCULT("There are [contents.len] coins in the stack.")

/obj/item/coinstack/attackby(obj/item/weapon/W, mob/user)
	. = ..()
	if(istype(W,/obj/item/triangle))
		stack(W)
	else
		qdel(src)

/obj/item/coinstack/Destroy()
	if(contents.len <= 0)
		return ..()

	var/turf/ourturf = get_turf(src)
	ourturf.visible_message(SPAN_DANGER("\The [src] topples over!"),runemessage = "CLATTER ! ! !")
	for(var/obj/item/triangle/coin in contents)
		unstack(coin)
	playsound(ourturf,'sound/items/drop/ring.ogg',100,TRUE)

	if(istype(loc,/obj/item/weapon/storage))
		var/obj/item/weapon/storage/S = loc
		S.remove_from_storage(src)
		ourturf.visible_message(SPAN_DANGER("Coins spill out of \the [S]!!!"),runemessage = "!")

	return ..()

/obj/item/coinstack/attack_hand(mob/living/user)
	if(!isturf(loc))
		return ..()
	if(user.a_intent == I_HELP)
		var/obj/item/triangle/coin = contents[contents.len]
		unstack(coin,user)
	else if(user.a_intent == I_GRAB)
		return ..()
	else
		user.visible_message(SPAN_DANGER("\The [user] shoves \the [src]!"),runemessage = "! ! !")
		qdel(src)

/obj/item/coinstack/proc/stack(var/obj/item/triangle/coin,var/mob/living/user)
	if(!coin)
		return
	if(user)
		user.face_atom(src)
		user.visible_message("\The [user] places \the [coin] on top of \the [src]...",runemessage = ". . .")
	if(isliving(coin.loc))
		var/mob/living/L = coin.loc
		L.drop_from_inventory(coin)
	else if(istype(coin.loc,/obj/item/weapon/storage))
		var/obj/item/weapon/storage/S = coin.loc
		S.remove_from_storage(coin)
	coin.forceMove(src)
	coin.pixel_y = (contents.len - 1) * 2
	coin.pixel_x = rand(0,1)
	vis_contents += coin

	if(contents.len > 10)
		if(prob(contents.len - 10))
			qdel(src)

/obj/item/coinstack/proc/unstack(var/obj/item/triangle/coin,var/mob/living/user)
	var/turf/ourturf = get_turf(src)
	if(!coin)
		return
	coin.pixel_x = 0
	coin.pixel_y = 0
	vis_contents -= coin
	if(user)
		user.face_atom(src)
		user.put_in_hands(coin)
		user.visible_message(SPAN_WARNING("\The [user] removes a [coin] from \the [src]."), runemessage = ". . .")
		playsound(get_turf(user),'sound/items/pickup/ring.ogg',100,TRUE)

	else
		coin.forceMove(ourturf)
		coin.randpixel_xy()

	if(contents.len <= 1)
		qdel(src)
