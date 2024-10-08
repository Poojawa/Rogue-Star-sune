SUBSYSTEM_DEF(chat)
	name = "Chat"
	flags = SS_TICKER
	wait = 1 // SS_TICKER means this runs every tick
	priority = FIRE_PRIORITY_CHAT
	init_order = INIT_ORDER_CHAT

	var/list/list/msg_queue = list() //List of lists

/datum/controller/subsystem/chat/Initialize(timeofday)
	init_vchat()
	..()

/datum/controller/subsystem/chat/fire()
	var/list/msg_queue = src.msg_queue // Local variable for sanic speed.
	for(var/client/C as anything in msg_queue)
		var/list/messages = msg_queue[C]
		msg_queue -= C
		if (C)
			C << output(jsEncode(messages), "htmloutput:putmessage")

		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/chat/stat_entry()
	..("C:[msg_queue.len]")

/datum/controller/subsystem/chat/proc/queue(target, time, message, handle_whitespace = TRUE)
	if(!target || !message)
		return

	if(!istext(message))
		stack_trace("to_chat called with invalid input type")
		return

	// Currently to_chat(world, ...) gets sent individually to each client.  Consider.
	if(target == world)
		target = GLOB.clients

	//Some macros remain in the string even after parsing and fuck up the eventual output
	var/original_message = message
	message = replacetext(message, "\n", "<br>")
	message = replacetext(message, "\improper", "")
	message = replacetext(message, "\proper", "")

	if(isnull(time))
		time = world.time

	var/list/messageStruct = list("time" = time, "message" = message);

	if(islist(target))
		for(var/I in target)
			var/client/C = CLIENT_FROM_VAR(I) //Grab us a client if possible

			if(!C || !C.chatOutput)
				continue // No client? No care.

			// RSEdit: Originally we didn't send it to oldchat because why? But, turns out that's
			// really the only way to log-as-a-stream to a file in byond, so, we send it both ways.
			DIRECT_OUTPUT(C, original_message)

			if(C.chatOutput.broken || !C.chatOutput.loaded)
				continue // No vchat instance to queue it for, why bother.

			LAZYINITLIST(msg_queue[C])
			msg_queue[C][++msg_queue[C].len] = messageStruct
	else
		var/client/C = CLIENT_FROM_VAR(target) //Grab us a client if possible

		if(!C || !C.chatOutput)
			return // No client? No care.

		DIRECT_OUTPUT(C, original_message) // RSEdit - Moved this up from the branch below

		if(C.chatOutput.broken || !C.chatOutput.loaded)
			return // If not loaded yet, do nothing and history-sending on load will get it.

		LAZYINITLIST(msg_queue[C])
		msg_queue[C][++msg_queue[C].len] = messageStruct
