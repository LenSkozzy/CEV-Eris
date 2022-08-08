/obj/effect/pulsar
	name = "pulsar"
	desc = "An insanely quickly rotating star, that releases 2 giant ratiation beams"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "pulsar"
	anchored = TRUE

//based on area/overmap
/area/pulsar
	name = "Pulsar Map"
	icon_state = "grid"
	requires_power = 0
	base_turf = /turf/unsimulated/map/pulsar

/turf/unsimulated/map/pulsar/New()
	..()
	name = "Deep Space"

/obj/effect/pulsar_beam
	name = "radiation beam"
	desc = "A beam of high energy radiation"
	icon = 'icons/obj/overmap.dmi'
	icon_state = "pulsar_beam"

/obj/effect/pulsar_beam/dl
	icon_state = "pulsar_beam_dl"

/obj/effect/pulsar_beam/ur
	icon_state = "pulsar_beam_ur"

/obj/effect/pulsar_ship
	name = "Technomancer satellite orbit"
	desc = "The orbit target for the satellite"
	icon = 'icons/obj/overmap.dmi'
	icon_state = "ihs_capital_g"
	var/obj/effect/pulsar_ship/shadow
	var/do_decay = TRUE
	var/decay_timer = 5 MINUTES
	var/fuel = 100
	var/fuel_movement_cost = 5
	var/crash_timer_id
	var/obj/item/device/radio/radio
	var/datum/event/pulsar_rad_storm/storm

/obj/effect/pulsar_ship/New()
	. = ..()
	if(do_decay)
		addtimer(CALLBACK(src, .proc/decay_orbit), decay_timer)
		radio = new /obj/item/device/radio{channels=list("Engineering")}(src)
	
/obj/effect/pulsar_ship/Destroy()
	. = ..()
	if(radio)
		qdel(radio)

/obj/effect/pulsar_ship/proc/decay_orbit()
	var/movedir = pick(NORTH, SOUTH, EAST, WEST)
	try_move(movedir)
	addtimer(CALLBACK(src, .proc/decay_orbit), decay_timer)

/obj/effect/pulsar_ship/proc/try_move(newdir)
	var/turf/newloc = get_step(src, newdir)
	if(!newloc || newloc.x > GLOB.maps_data.pulsar_size - 1 || newloc.x < 1 || newloc.y > GLOB.maps_data.pulsar_size - 1 || newloc.y < 1) // If movement outside of the map, reverse decay dir
		Move(get_step(src, turn(newdir, 180)))
		shadow.Move(get_step(shadow, newdir))
	else
		Move(newloc)
		shadow.Move(get_step(shadow, turn(newdir, 180)))

	if(radio)
		var/beam_collision = FALSE
		for(var/obj/O in get_turf(src))
			if(O.type == /obj/effect/pulsar_beam)
				beam_collision = TRUE
				if(!crash_timer_id)
					radio.autosay("WARNING: COLLISION WITH RADIATION BEAMS IMMINENT! ETA: 3 MINUTES!", "Pulsar Monitor", "Engineering")
					crash_timer_id = addtimer(CALLBACK(src, .proc/crash_into_beam), 3 MINUTES, TIMER_STOPPABLE)
		if(!beam_collision)
			if(crash_timer_id)
				deltimer(crash_timer_id)
				crash_timer_id = null
			if(storm)
				storm.endWhen = 1
				storm = null

/obj/effect/pulsar_ship/proc/crash_into_beam()
	for(var/obj/O in get_turf(src))
		if(O.type == /obj/effect/pulsar_beam)
			storm = new()
			storm.Initialize()

/obj/effect/pulsar_ship/shadow
	do_decay = FALSE
	alpha = 255 * 0.5
