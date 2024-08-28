
/* ==================================================== */
/* -------------------- Dispensers -------------------- */
/* ==================================================== */

/obj/reagent_dispensers
	name = "Dispenser"
	desc = "..."
	icon = 'icons/obj/objects.dmi'
	icon_state = "watertank"
	density = 1
	anchored = UNANCHORED
	flags = FLUID_SUBMERGE | ACCEPTS_MOUSEDROP_REAGENTS
	object_flags = NO_GHOSTCRITTER
	pressure_resistance = 2*ONE_ATMOSPHERE
	p_class = 1.5

	var/amount_per_transfer_from_this = 10
	var/capacity = 4000

	New()
		..()
		// TODO enable when I do leaking
		// src.AddComponent(/datum/component/bullet_holes, 10, 5)
		src.create_reagents(src.capacity)


	get_desc(dist, mob/user)
		if (dist <= 2 && reagents)
			. += "<br>[SPAN_NOTICE("[reagents.get_description(user,RC_SCALE)]")]"

	proc/smash()
		var/turf/T = get_turf(src)
		T.fluid_react(src.reagents, min(src.reagents.total_volume,10000))
		src.reagents.clear_reagents()
		qdel(src)

	ex_act(severity)
		switch(severity)
			if (1)
				smash()
				return
			if (2)
				if (prob(50))
					smash()
					return
			if (3)
				if (prob(5))
					smash()
					return

	blob_act(var/power)
		if (prob(25))
			smash()

	temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume, cannot_be_cooled = FALSE)
		..()
		if (reagents)
			for (var/i = 0, i < 9, i++) // ugly hack
				reagents.temperature_reagents(exposed_temperature, exposed_volume)

	attackby(obj/item/W, mob/user)
		// prevent attacked by messages
		if(istype(W, /obj/item/reagent_containers/hypospray) || istype(W, /obj/item/reagent_containers/mender))
			return
		..(W, user)

	mouse_drop(atom/over_object as obj)
		if (!(over_object.flags & ACCEPTS_MOUSEDROP_REAGENTS))
			return ..()

		if (BOUNDS_DIST(usr, src) > 0 || BOUNDS_DIST(usr, over_object) > 0)
			boutput(usr, SPAN_ALERT("That's too far!"))
			return

		src.transfer_all_reagents(over_object, usr)

	is_open_container(input)
		if (input)
			return TRUE
		return ..()

	proc/bolt_unbolt(mob/user)
		if(!src.anchored)
			var/turf/T = get_turf(src)
			if (istype(T, /turf/space))
				boutput(user, SPAN_ALERT("What exactly are you gonna secure [src] to?"))
				return
			user.visible_message("<b>[user]</b> secures [src] to the floor!")
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
			src.anchored = ANCHORED
		else
			user.visible_message("<b>[user]</b> unbolts [src] from the floor!")
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
			src.anchored = UNANCHORED

	// brain check stolen from the reclaimer
	proc/brain_check(var/obj/item/I, var/mob/user, var/ask)
		if (!istype(I))
			return
		var/obj/item/organ/brain/brain = null
		if (istype(I, /obj/item/parts/robot_parts/head))
			var/obj/item/parts/robot_parts/head/head = I
			brain = head.brain
		else if (istype(I, /obj/item/organ/brain))
			brain = I

		if (brain)
			if (!ask)
				boutput(user, SPAN_ALERT("[I] turned the intelligence detection light on! You decide to not load it for now."))
				return FALSE
			var/accept = tgui_alert(user, "Possible intelligence detected. Are you sure you want to reclaim [I]?", "Incinerate brain?", list("Yes", "No")) == "Yes" && can_reach(user, src) && user.equipped() == I
			if (accept)
				logTheThing(LOG_COMBAT, user, "loads [brain] (owner's ckey [brain.owner ? brain.owner.ckey : null]) into a still.")
			return accept
		return TRUE

/* =================================================== */
/* -------------------- Sub-Types -------------------- */
/* =================================================== */
/obj/reagent_dispensers/cleanable
	flags = FLUID_SUBMERGE

/obj/reagent_dispensers/cleanable/ants
	name = "space ants"
	desc = "A bunch of space ants."
	icon = 'icons/effects/effects.dmi'
	icon_state = "spaceants"
	layer = MOB_LAYER
	density = 0
	anchored = ANCHORED
	amount_per_transfer_from_this = 5

	New()
		..()
		var/scale = (rand(2, 10) / 10) + (rand(0, 5) / 100)
		src.Scale(scale, scale)
		src.set_dir(pick(NORTH, SOUTH, EAST, WEST))
		reagents.add_reagent("ants",20)
		START_TRACKING_CAT(TR_CAT_BUGS)

	disposing()
		STOP_TRACKING_CAT(TR_CAT_BUGS)
		..()

	get_desc(dist, mob/user)
		return null

	attackby(obj/item/W, mob/user)
		..(W, user)
		SPAWN(1 SECOND)
			if (src?.reagents)
				if (src.reagents.total_volume <= 1)
					qdel(src)
		return

/obj/reagent_dispensers/cleanable/spiders
	name = "spiders"
	desc = "A bunch of spiders."
	icon = 'icons/effects/effects.dmi'
	icon_state = "spaceants"
	layer = MOB_LAYER
	density = 0
	anchored = ANCHORED
	amount_per_transfer_from_this = 5
	color = "#160505"

	New()
		..()
		var/scale = (rand(2, 10) / 10) + (rand(0, 5) / 100)
		src.Scale(scale, scale)
		src.set_dir(pick(NORTH, SOUTH, EAST, WEST))
		src.pixel_x = rand(-8,8)
		src.pixel_y = rand(-8,8)
		reagents.add_reagent("spiders", 5)
		START_TRACKING_CAT(TR_CAT_BUGS)

	disposing()
		STOP_TRACKING_CAT(TR_CAT_BUGS)
		..()

	get_desc(dist, mob/user)
		return null

	attackby(obj/item/W, mob/user)
		..(W, user)
		SPAWN(1 SECOND)
			if (src?.reagents)
				if (src.reagents.total_volume <= 1)
					qdel(src)
		return

/obj/reagent_dispensers/foamtank
	name = "foamtank"
	desc = "A massive tank full of firefighting foam, for refilling extinguishers."
	icon = 'icons/obj/objects.dmi'
	icon_state = "foamtank"
	amount_per_transfer_from_this = 25

	New()
		..()
		reagents.add_reagent("ff-foam",1000)

/obj/reagent_dispensers/watertank
	name = "watertank"
	desc = "A watertank"
	icon = 'icons/obj/objects.dmi'
	icon_state = "watertank"
	amount_per_transfer_from_this = 25
	capacity = 1000

	New()
		..()
		reagents.add_reagent("water",capacity)

/obj/reagent_dispensers/watertank/big
	name = "high-capacity watertank"
	desc = "A specialised high-pressure water tank for holding large amounts of water."
	icon = 'icons/obj/objects.dmi'
	icon_state = "watertankbig"
	anchored = UNANCHORED
	amount_per_transfer_from_this = 25

	attackby(obj/item/W, mob/user)
		if(istool(W, TOOL_SCREWING | TOOL_WRENCHING))
			if(!src.anchored)
				user.visible_message("<b>[user]</b> secures [src] to the floor!")
				playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
				src.anchored = ANCHORED
			else
				user.visible_message("<b>[user]</b> unbolts [src] from the floor!")
				playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
				src.anchored = UNANCHORED
			return

	New()
		..()
		src.create_reagents(10000)
		reagents.add_reagent("water",10000)

TYPEINFO(/obj/reagent_dispensers/watertank/fountain)
	mats = 8

/obj/reagent_dispensers/watertank/fountain
	name = "water cooler"
	desc = "A popular gathering place for NanoTrasen's finest bureaucrats and pencil-pushers."
	icon_state = "coolerbase"
	anchored = ANCHORED
	deconstruct_flags = DECON_SCREWDRIVER | DECON_CROWBAR
	capacity = 500
	_health = 250
	_max_health = 250

	var/has_tank = 1

	var/cup_max = 12
	var/cup_amount

	var/image/cup_sprite = null
	var/image/fluid_sprite = null
	var/image/tank_sprite = null

	New()
		..()

		src.cup_sprite = new /image(src.icon, "coolercup")
		src.fluid_sprite = new /image(src.icon,"fluid-coolertank")
		src.tank_sprite = new /image(src.icon,"coolertank", layer=src.fluid_sprite.layer + 0.1)
		src.tank_sprite.alpha = 180

		src.cup_amount = src.cup_max

		src.UpdateIcon()

	//on_reagent_change()
	//	src.UpdateIcon()

	update_icon()
		if (src.has_tank)
			if (src.reagents.total_volume)
				var/datum/color/average = reagents.get_average_color()
				src.fluid_sprite.color = average.to_rgba()
				src.UpdateOverlays(fluid_sprite, "fluid_overlay")
			src.UpdateOverlays(tank_sprite, "tank_overlay")
		else
			src.UpdateOverlays(null, "fluid_overlay")
			src.UpdateOverlays(null, "tank_overlay")
		if (cup_amount > 0)
			src.UpdateOverlays(cup_sprite, "cup_overlay")
		else
			src.UpdateOverlays(null, "cup_overlay")

	get_desc(dist, mob/user)
		. += "There's [cup_amount] paper cup[s_es(src.cup_amount)] in [src]'s cup dispenser."
		if (dist <= 2 && reagents)
			. += "<br>[SPAN_NOTICE("[reagents.get_description(user,RC_SCALE)]")]"

	attackby(obj/W, mob/user)
		if (has_tank)
			if (iswrenchingtool(W))
				user.show_text("You disconnect the bottle from [src].", "blue")
				var/obj/item/reagent_containers/food/drinks/P = new /obj/item/reagent_containers/food/drinks/coolerbottle(src.loc)
				P.reagents.maximum_volume = max(P.reagents.maximum_volume, src.reagents.total_volume)
				src.reagents.trans_to(P, reagents.total_volume)
				src.reagents.clear_reagents()
				src.has_tank = 0
				src.UpdateIcon()
				return
		else if (istype(W, /obj/item/reagent_containers/food/drinks/coolerbottle))
			user.show_text("You connect the bottle to [src].", "blue")
			W.reagents.trans_to(src, W.reagents.total_volume)
			user.u_equip(W)
			qdel(W)
			src.has_tank = 1
			src.UpdateIcon()
			return

		if (isscrewingtool(W))
			var/turf/T = get_turf(src)
			if (!src.anchored && istype(T, /turf/space))
				user.show_text("What exactly are you gunna secure [src] to?", "red")
				return
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
			user.show_text("You begin to [src.anchored ? "unscrew" : "secure"] [src].", "blue")
			SETUP_GENERIC_ACTIONBAR(user, src, 3 SECONDS, PROC_REF(toggle_bolts), list(user, T), W.icon, W.icon_state, null, INTERRUPT_MOVE | INTERRUPT_STUNNED | INTERRUPT_ACT)
			return
		..()

	proc/toggle_bolts(mob/user, turf/T)
		user.show_text("You [src.anchored ? "unscrew" : "secure"] [src] [src.anchored ? "from" : "to"] [T].", "blue")
		src.anchored = !src.anchored

	attack_hand(mob/user)
		if (src.cup_amount <= 0)
			user.show_text("\The [src] doesn't have any cups left, damnit.", "red")
			return
		else
			src.visible_message("<b>[user]</b> grabs a paper cup from [src].",\
			"You grab a paper cup from [src].")
			src.cup_amount --
			var/obj/item/reagent_containers/food/drinks/paper_cup/P = new /obj/item/reagent_containers/food/drinks/paper_cup(src)
			user.put_in_hand_or_drop(P)
			if (src.cup_amount <= 0)
				user.show_text("That was the last cup!", "red")
				src.UpdateIcon()

	bullet_act(obj/projectile/P)
		src.changeHealth(-P.power * P.proj_data.ks_ratio)

	onDestroy()
		src.smash()

	drugged
		New()
			..()
			src.create_reagents(4000)
			reagents.add_reagent("LSD",400)
			reagents.add_reagent("water",600)
			src.UpdateIcon()
		name = "discolored water fountain"
		desc = "It's called a fountain, but it's not very decorative or interesting. You can get a drink from it, though seeing the color you feel you shouldn't"
		color = "#ffffcc"

	juicer
		New()
			..()
			src.create_reagents(4000)
			reagents.add_reagent(pick("CBD","THC","refried_beans","coffee","methamphetamine"),100)
			reagents.add_reagent(pick("CBD","THC","refried_beans","coffee","methamphetamine"),100)
			reagents.add_reagent(pick("CBD","THC","refried_beans","coffee","methamphetamine"),100)
			reagents.add_reagent(pick("CBD","THC","refried_beans","coffee","methamphetamine"),100)
			reagents.add_reagent("water",600)
			src.UpdateIcon()
		name = "discolored water fountain"
		desc = "It's called a fountain, but it's not very decorative or interesting. You can get a drink from it, though seeing the color you feel you shouldn't"
		color = "#ccffcc"



/obj/reagent_dispensers/fueltank
	name = "fueltank"
	desc = "A high-pressure tank full of welding fuel. Keep away from open flames and sparks."
	icon = 'icons/obj/objects.dmi'
	icon_state = "weldtank"
	amount_per_transfer_from_this = 25
	var/isburst = FALSE

	New()
		..()
		reagents.add_reagent("fuel",4000)

	custom_suicide = 1
	suicide(var/mob/user as mob)
		if (!src.user_can_suicide(user))
			return 0
		if (!src.reagents.has_reagent("fuel",20))
			return 0
		user.visible_message(SPAN_ALERT("<b>[user] drinks deeply from [src]. [capitalize(he_or_she(user))] then pulls out a match from somewhere, strikes it and swallows it!</b>"))
		src.reagents.remove_any(20)
		playsound(src.loc, 'sound/items/drink.ogg', 50, 1, -6)
		user.TakeDamage("chest", 0, 150)
		if (isliving(user))
			var/mob/living/L = user
			L.changeStatus("burning", 10 SECONDS)
		SPAWN(50 SECONDS)
			if (user && !isdead(user))
				user.suiciding = 0
		return 1


	electric_expose(var/power = 1) //lets throw in ANOTHER hack to the temp expose one above
		if (reagents)
			for (var/i = 0, i < 3, i++)
				reagents.temperature_reagents(power*500, power*400, 1000, 1000, 1)

	Bumped(AM)
		. = ..()
		if (ismob(AM))
			add_fingerprint(AM, TRUE)
		else if (ismob(usr))
			add_fingerprint(usr, TRUE)

	ex_act(severity)
		..()
		icon_state = "weldtank-burst" //to ensure that a weldertank's always going to be updated by their own explosion
		isburst = TRUE

	is_open_container()
		return isburst

/obj/reagent_dispensers/heliumtank
	name = "heliumtank"
	desc = "A tank of helium."
	icon = 'icons/obj/objects.dmi'
	icon_state = "heliumtank"
	amount_per_transfer_from_this = 25

	New()
		..()
		reagents.add_reagent("helium",4000)

/obj/reagent_dispensers/beerkeg
	name = "beer keg"
	desc = "Full of delicious alcohol, hopefully."
	icon = 'icons/obj/objects.dmi'
	icon_state = "beertankTEMP"
	amount_per_transfer_from_this = 25

	New()
		..()
		reagents.add_reagent("beer",1000)

/obj/reagent_dispensers/chemicalbarrel
	name = "chemical barrel"
	desc = "For storing medical chemicals and less savory things. It can be labeled with a pen."
	icon = 'icons/obj/objects.dmi'
	icon_state = "barrel-blue"
	amount_per_transfer_from_this = 25
	p_class = 3
	flags = FLUID_SUBMERGE | OPENCONTAINER | ACCEPTS_MOUSEDROP_REAGENTS
	var/base_icon_state = "barrel-blue"
	var/funnel_active = TRUE //if TRUE, allows players pouring liquids from beakers with just one click instead of clickdrag, for convenience
	var/image/fluid_image = null
	var/image/lid_image = null
	var/image/spout_image = null
	var/obj/machinery/chem_master/linked_machine = null

	New()
		..()
		src.UpdateIcon()

	update_icon()
		var/fluid_state = round(clamp((src.reagents.total_volume / src.reagents.maximum_volume * 9 + 1), 1, 9))
		if (!src.fluid_image)
			src.fluid_image = image(src.icon)
		if (src.reagents && src.reagents.total_volume)
			var/datum/color/average = reagents.get_average_color()
			src.fluid_image.color = average.to_rgba()
			src.fluid_image.icon_state = "fluid-barrel-[fluid_state]"
		else
			fluid_image.icon_state = "fluid-barrel-0"
		src.UpdateOverlays(src.fluid_image, "fluid")

		if (!src.lid_image)
			src.lid_image = image(src.icon)
			src.lid_image.appearance_flags = PIXEL_SCALE | RESET_COLOR | RESET_ALPHA
		if(!src.is_open_container())
			src.lid_image.icon_state = "[base_icon_state]-lid"
			src.UpdateOverlays(src.lid_image, "lid")
		else
			src.lid_image.layer = src.fluid_image.layer + 0.1
			src.lid_image.icon_state = null
			src.UpdateOverlays(null, "lid")

		if (!src.spout_image)
			src.spout_image = image(src.icon)
			src.spout_image.appearance_flags = PIXEL_SCALE | RESET_COLOR | RESET_ALPHA
		if(src.funnel_active)
			src.spout_image.icon_state = "[base_icon_state]-funnel"
		else
			src.spout_image.icon_state = "[base_icon_state]-spout"
		src.UpdateOverlays(src.spout_image, "spout")

		..()

	attackby(obj/item/W, mob/user)
		if (istype(W, /obj/item/pen) && (src.name == initial(src.name)))
			var/t = tgui_input_text(user, "Enter a label for the barrel.", "Label", "chemical", 24)
			if(t && t != src.name)
				phrase_log.log_phrase("barrel", t, no_duplicates=TRUE)
			t = copytext(strip_html(t), 1, 24)
			if (isnull(t) || !length(t) || t == " ")
				return
			if (!findtext(t, "barrel"))     //so we don't see lube barrel barrel
				t += " barrel"          	//so it's clear it's a barrel, and not just "lube"
			if (!in_interact_range(src, user) && src.loc != user)
				return

			src.name = t

			src.desc = "For storing medical chemicals and less savory things."

		if (istype(W, /obj/item/reagent_containers/synthflesh_pustule))
			if (src.reagents.total_volume >= src.reagents.maximum_volume)
				boutput(user, SPAN_ALERT("[src] is full."))
				return

			boutput(user, SPAN_NOTICE("You squeeze the [W] into [src]. Gross."))
			playsound(src.loc, pick('sound/effects/splort.ogg'), 100, 1)

			W.reagents.trans_to(src, W.reagents.total_volume)
			user.u_equip(W)
			qdel(W)

		if (istool(W, TOOL_WRENCHING))
			if(src.flags & OPENCONTAINER)
				user.visible_message("<b>[user]</b> wrenches [src]'s lid closed!")
			else
				user.visible_message("<b>[user]</b> wrenches [src]'s lid open!")
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
			src.set_open_container(!src.is_open_container())
			UpdateIcon()
		else
			..()

	mouse_drop(atom/over_object, src_location, over_location)
		if (istype(over_object, /obj/machinery/chem_master))
			var/obj/machinery/chem_master/chem_master = over_object
			chem_master.try_attach_barrel(src, usr)
			return
		..()

	bullet_act()
		..()
		playsound(src.loc, 'sound/impact_sounds/Metal_Hit_Heavy_1.ogg', 30, 1)

	attack_hand(var/mob/user)
		if(funnel_active)
			funnel_active = FALSE
			boutput(user, SPAN_NOTICE("You flip the funnel into spout mode on the [src.name]."))
		else
			funnel_active = TRUE
			boutput(user, SPAN_NOTICE("You flip the spout into funnel mode on the [src.name]."))
		UpdateIcon()
		..()

	on_reagent_change()
		..()
		src.UpdateIcon()

	is_open_container(input)
		if (src.funnel_active && input) //Can pour stuff down the funnel even if the lid is closed
			return TRUE
		. = ..()

	shatter_chemically(var/projectiles = FALSE) //needs sound probably definitely for sure
		for(var/mob/M in AIviewers(src))
			boutput(M, SPAN_ALERT("The <B>[src.name]</B> breaks open!"))
		if(projectiles)
			var/datum/projectile/special/spreader/uniform_burst/circle/circle = new /datum/projectile/special/spreader/uniform_burst/circle/(get_turf(src))
			circle.shot_sound = null //no grenade sound ty
			circle.spread_projectile_type = /datum/projectile/bullet/shrapnel/shrapnel_implant
			circle.pellet_shot_volume = 0
			circle.pellets_to_fire = 10
			shoot_projectile_ST_pixel_spread(get_turf(src), circle, get_step(src, NORTH))
		var/obj/shattered_barrel/shattered_barrel = new /obj/shattered_barrel
		shattered_barrel.icon_state = "[src.base_icon_state]-shattered"
		shattered_barrel.set_loc(get_turf(src))
		src.smash()
		return TRUE

	disposing()
		src.linked_machine?.eject_beaker(null)
		. = ..()

	get_chemical_effect_position()
		return 10
	red
		icon_state = "barrel-red"
		base_icon_state = "barrel-red"
	yellow
		icon_state = "barrel-yellow"
		base_icon_state = "barrel-yellow"
	oil
		icon_state = "barrel-flamable"
		base_icon_state = "barrel-flamable"
		name = "oil barrel"
		desc = "A barrel for storing large amounts of oil."

		New()
			..()
			reagents.add_reagent("oil", 4000)

/obj/shattered_barrel
	name = "shattered chemical barrel"
	desc = "It's been totally wrecked. Just unbarrelable. Fuck."
	icon = 'icons/obj/objects.dmi'
	icon_state = "barrel-blue-shattered"
	anchored = UNANCHORED

/obj/reagent_dispensers/beerkeg/rum
	name = "barrel of rum"
	desc = "It better not be empty."
	icon_state = "rum_barrel"

	New()
		..()
		reagents.remove_reagent("beer",1000)
		reagents.add_reagent("rum",1000)

/obj/reagent_dispensers/compostbin
	name = "compost tank"
	desc = "A device that mulches up unwanted produce into usable fertiliser."
	icon = 'icons/obj/objects.dmi'
	icon_state = "compost"
	anchored = UNANCHORED
	amount_per_transfer_from_this = 30
	event_handler_flags = NO_MOUSEDROP_QOL
	New()
		..()

	get_desc(dist, mob/user)
		if (dist > 2)
			return
		if (!reagents)
			return
		. = "<br>[SPAN_NOTICE("[reagents.get_description(user,RC_FULLNESS)]")]"
		return

	attackby(obj/item/W, mob/user)
		if(istool(W, TOOL_SCREWING | TOOL_WRENCHING))
			bolt_unbolt(user)
			return
		var/load = 1
		if (istype(W,/obj/item/reagent_containers/food/snacks/plant/)) src.reagents.add_reagent("poo", 20)
		else if (istype(W,/obj/item/reagent_containers/food/snacks/mushroom/)) src.reagents.add_reagent("poo", 25)
		else if (istype(W,/obj/item/seed/)) src.reagents.add_reagent("poo", 2)
		else if (istype(W,/obj/item/plant/) \
				|| istype(W,/obj/item/clothing/head/flower/) \
				|| istype(W,/obj/item/reagent_containers/food/snacks/ingredient/rice_sprig)) src.reagents.add_reagent("poo", 15)
		else if (istype(W,/obj/item/organ/)) src.reagents.add_reagent("poo", 35)
		else load = 0

		if(load)
			boutput(user, SPAN_NOTICE("[src] mulches up [W]."))
			playsound(src.loc, 'sound/impact_sounds/Slimy_Hit_4.ogg', 30, 1)
			user.u_equip(W)
			W.dropped(user)
			qdel( W )
			return
		else ..()

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (!isliving(user))
			boutput(user, SPAN_ALERT("Excuse me you are dead, get your gross dead hands off that!"))
			return
		if (BOUNDS_DIST(user, src) > 0)
			// You have to be adjacent to the compost bin
			boutput(user, SPAN_ALERT("You need to move closer to [src] to do that."))
			return
		if (BOUNDS_DIST(O, user) > 0)
			// You have to be adjacent to the seeds also
			boutput(user, SPAN_ALERT("[O] is too far away to load into [src]!"))
			return
		if (istype(O, /obj/item/reagent_containers/food/snacks/plant/) \
			|| istype(O, /obj/item/reagent_containers/food/snacks/mushroom/) \
			|| istype(O, /obj/item/seed/) || istype(O, /obj/item/plant/) \
			|| istype(O, /obj/item/clothing/head/flower/) \
			|| istype(O, /obj/item/reagent_containers/food/snacks/ingredient/rice_sprig))
			user.visible_message(SPAN_NOTICE("[user] begins quickly stuffing [O] into [src]!"))
			var/itemtype = O.type
			var/staystill = user.loc
			for(var/obj/item/P in view(1,user))
				if (src.reagents.total_volume >= src.reagents.maximum_volume)
					boutput(user, SPAN_ALERT("[src] is full!"))
					break
				if (user.loc != staystill) break
				if (P.type != itemtype) continue
				var/amount = 20
				if (istype(P,/obj/item/reagent_containers/food/snacks/mushroom/))
					amount = 25
				else if (istype(P,/obj/item/seed/))
					amount = 2
				else if (istype(P,/obj/item/plant/) || istype(P,/obj/item/reagent_containers/food/snacks/ingredient/rice_sprig))
					amount = 15
				playsound(src.loc, 'sound/impact_sounds/Slimy_Hit_4.ogg', 30, 1)
				src.reagents.add_reagent("poo", amount)
				qdel( P )
				sleep(0.3 SECONDS)
			boutput(user, SPAN_NOTICE("You finish stuffing [O] into [src]!"))
		else ..()

/obj/reagent_dispensers/still
	name = "still"
	desc = "A piece of equipment for brewing alcoholic beverages."
	icon = 'icons/obj/objects.dmi'
	icon_state = "still"
	amount_per_transfer_from_this = 25
	event_handler_flags = NO_MOUSEDROP_QOL

	var/active = FALSE
	var/stopping = FALSE
	// If true, temperature functionality gets turned on. I can't figure out how to get atmos to work on the still,
	// and this stuff doesn't really work nicely gameplay-wise if the still doesn't return to room-temp naturally.
	// So, here's an on/off switch.
	var/temp_function = TRUE

	// the base number of seconds it takes for fermentation to build up at room temperature
	var/ferment_buildup = 20
	/// the base number of 1/10 seconds between items brewing, at room temperature
	var/ferment_pause = 5
	/// the number of items that will be brewed instantly after the fermentation build up
	var/initial_brew_total = 20

	// the time multiplier at 0C, starting at room temp
	var/freezing_multiplier = 8
	// the time multiplier at the 'perfect' temperature, starting at room temp
	var/perfect_temp_multiplier = 0.3
	// the minimum temperature at which fermentation is the fastest
	var/perfect_temp = 333



	var/sound/sound_brew = sound('sound/effects/bubbles_short.ogg')
	var/sound/sound_load = sound('sound/items/Deconstruct.ogg')

	// returns whether the inserted item was brewed
	proc/brew(var/obj/item/W as obj)
		if (!istype(W))
			return FALSE
		var/list/brew_result = W.brew_result
		var/list/brew_amount = 10 // how much brew could a brewstill brew if a brewstill still brewed brew?

		if (!brew_result)
			return FALSE

		var/potency_amount = potency_amount(W)

		// keep track of whether a valid reagent was found in the brew results
		// because we want to avoid distilling into nothing and then deleting the item anyway
		var/validresult = FALSE

		if (islist(brew_result))
			// we need the total base amounts first so we can divvy up the potency-additions fractionally
			var/total_value = 0
			for (var/key in brew_result)
				var/value = brew_result[key]
				if (isnum(value)) total_value += value
				else total_value += brew_amount
			for(var/I in brew_result)
				var/result = I
				var/amount = brew_result[I]
				if (!amount)
					amount = brew_amount
				if (result != TRUE && reagents_cache[result]) // check that brew_result is a valid reagent first, because add_reagent just causes a crash if it's not
					src.reagents.add_reagent(result, round(amount + (potency_amount * (total_value / amount)), 1))
					validresult = TRUE
		// I don't understand why, but if brew_result is explicitly true it causes add_reagent to crash.
		// I would have expected it to either not be a valid key or for add_reagent to just find aluminium, but...
		else if (brew_result != TRUE && reagents_cache[brew_result])
			src.reagents.add_reagent(brew_result, brew_amount + potency_amount)
			validresult = TRUE

		//src.visible_message(SPAN_NOTICE("[src] brews up [W]!"))
		return validresult

	proc/potency_amount(var/obj/item/W)
		if(istype(W, /obj/item/reagent_containers/food/snacks/plant))
			var/obj/item/reagent_containers/food/snacks/plant/Plant = W
			return HYPfull_potency_calculation(Plant.plantgenes)
		return 0

	proc/fermentation_process()
		// Do nothing for a while; fermentation needs a little time to build up
		for (var/i = 1; i <= (ferment_buildup * 5); i++)
		{
			sleep(2 * temp_multiplier())
			if (stopping)
			{
				stop_fermentation()
				return
			}
			if (temp_function && src.reagents.total_temperature <= T0C)
				stop_fermentation()
				src.visible_message(SPAN_ALERT("[src]'s fermentation stalls due to suboptimal temperatures."))
				return
		}
		if (stopping)
		{
			stop_fermentation()
			return
		}
		var/list/unfermentables = list()
		// Brew a number of items immediately
		for (var/i = min(initial_brew_total, src.contents.len); i >= 1; i--)
		{
			if (src.reagents.is_full())
				break
			if ((temp_function && src.reagents.total_temperature >= T100C) || src.brew(src.contents[i]))
				qdel(src.contents[i])
			else
				unfermentables.Add(src.contents[i])
		}
		playsound(src.loc, sound_brew, 30, 1)
		if (!(unfermentables.len == src.contents.len) && src.contents.len >= 1) src.visible_message(SPAN_NOTICE("[src] bubbles and lets off a yeasty smell!"))
		// Brew remaining items one by one until finished or full
		for (var/i = src.contents.len; i >= 1; i--)
		{
			sleep(ferment_pause * temp_multiplier())
			if (stopping)
			{
				stop_fermentation()
				return
			}
			if (temp_function && src.reagents.total_temperature <= T0C)
				stop_fermentation()
				src.visible_message(SPAN_ALERT("[src]'s fermentation stalls due to suboptimal temperatures."))
				return
			if ((temp_function && src.reagents.total_temperature >= T100C))
				qdel(src.contents[i])
				// play sound only every so often so it isn't too annoying
				if (i % 4 == 0) playsound(src.loc, sound_brew, 30, 1)
			else if (src.brew(src.contents[i]))
				qdel(src.contents[i])
				if (i % 4 == 0) playsound(src.loc, sound_brew, 30, 1)
			if (src.reagents.is_full())
				break
		}
		active = FALSE
		stopping = FALSE
		if (src.reagents.is_full())
			src.visible_message(SPAN_ALERT("[src] has reached capacity, the fermentation ceases!"))
		else
			src.visible_message(SPAN_NOTICE("[src] finishes brewing up its contents!"))


	// Look me ain't maths so good alright, me not understand how to exponentials, me just slap two linear equations together and call it day.
	proc/temp_multiplier()
		if (!temp_function) return 1
		var/temp = min(src.reagents.total_temperature, perfect_temp)
		if (temp >= 290)
			var/proportion = (temp - T20C) / (T100C - T20C)
			return 1 - proportion * (1 - perfect_temp_multiplier)
		else
			var/proportion = (temp - T0C) / (T20C - T0C)
			return freezing_multiplier - proportion * (freezing_multiplier - 1)

	// helper method in the hopes that this will also handle an icon state change at some point
	proc/stop_fermentation()
		active = FALSE
		stopping = FALSE


	attack_hand(var/mob/user)
		if(active)
			if (stopping)
				boutput(user, SPAN_NOTICE("The fermentation process is already stopping."))
			else
				stopping = TRUE
				user.visible_message(SPAN_NOTICE("[user] opens [src]'s valves, stopping fermentation!"))
				playsound(src.loc, 'sound/effects/valve_creak.ogg', 20, 0, 0, 1.1)
			return
		if (length(src.contents) < 1)
			boutput(user, SPAN_ALERT("There's nothing inside to ferment."))
			return
		if (temp_function && src.reagents.total_temperature <= T0C)
			boutput(user, SPAN_ALERT("The [src]'s temperature is too low to start fermentation."))
			return
		user.visible_message(SPAN_NOTICE("[user] closes [src]'s valves, the contents will soon start to ferment!"))
		playsound(src.loc, 'sound/effects/valve_creak.ogg', 20, 0, 0, 2)
		active = TRUE
		fermentation_process()

	// We only check truthiness of brew_result here, and the boiling-temp item-deletion bypasses the extra validity check performed during fermentation_process,
	// this means items with a truthy but non-reagent 'brew_result' will be loadable and won't be deleted during the normal fermentation process, but will
	// lengthen the brewing time and will be destroyed during the boiling-temp item-deletion check. Potentially, therefore, you can set 'brew_result' to an arbitrary value
	// and that item will be fermentationally-destructable... it's niche and weird and probably pointless unless you want to turn an item into a brewing red herring,
	// but I figure I should document it.
	proc/load_still(obj/item/W as obj, mob/user as mob)
		. = FALSE
		if (!W.brew_result)
			return FALSE
		if (brain_check(W, user, TRUE))
			if (W.stored)
				W.stored.transfer_stored_item(W, src, user = user)
			else
				W.set_loc(src)
				if (user) user.u_equip(W)
			W.dropped(user)
			. = TRUE

	attackby(obj/item/W, mob/user)
		if(istool(W, TOOL_SCREWING | TOOL_WRENCHING))
			bolt_unbolt(user)
			return
		if (active)
			boutput(user, SPAN_ALERT("Can't put anything into [src] while it's fermenting."))
			return
		else if (W.storage || istype(W, /obj/item/satchel))
			var/items = W
			if (W.storage)
				items = W.storage.get_contents()
			for(var/obj/item/O in items)
				if (load_still(O, user))
					. = TRUE
			if (istype(W, /obj/item/satchel) && .)
				W.UpdateIcon()
			//Users loading individual items would make an annoying amount of messages
			//But loading a container is more noticable and there should be less
			if (.)
				user.visible_message("<b>[user]</b> charges [src] with the contents of [W].")
				playsound(src, sound_load, 40, TRUE)
				logTheThing(LOG_STATION, user, "loads [W] into \the [src] at [log_loc(src)].")
		else if (W?.cant_drop)
			boutput(user, SPAN_ALERT("You can't put that in [src] when it's attached to you!"))
			return
		else if (load_still(W, user))
			boutput(user, "You load [W] into [src].")
			playsound(src, sound_load, 30, TRUE)
			logTheThing(LOG_STATION, user, "loads [W] into \the [src] at [log_loc(src)].")
			return

		// create feedback for items which don't produce attack messages
		// but not for chemistry containers, because they have their own feedback
		else if (W && (W.flags & (SUPPRESSATTACK | OPENCONTAINER)) == SUPPRESSATTACK)
			if (src.reagents.is_full())
				boutput(user, SPAN_ALERT("[src] is already full."))
			else
				boutput(user, SPAN_ALERT("Can't brew anything from [W]."))
		..()

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (!isliving(user))
			boutput(user, SPAN_ALERT("It's probably a bit too late for you to drink your problems away!"))
			return
		if (BOUNDS_DIST(user, src) > 0)
			// You have to be adjacent to the still
			boutput(user, SPAN_ALERT("You need to move closer to [src] to do that."))
			return
		if (BOUNDS_DIST(O, user) > 0)
			// You have to be adjacent to the brewables also
			boutput(user, SPAN_ALERT("[O] is too far away to load into [src]!"))
			return
		// loading from crate
		if (istype(O, /obj/storage/crate/))
			if (active)
				boutput(user, SPAN_ALERT("[src] is currently fermenting."))
				return
			user.visible_message(SPAN_NOTICE("[user] charges [src] with [O]'s contents!"))
			var/amtload = 0
			for (var/obj/item/Produce in O.contents)
				if (load_still(Produce, user))
					amtload++
			if (amtload)
				boutput(user, SPAN_NOTICE("Charged [src] with [amtload] items from [O]!"))
				playsound(src.loc, sound_load, 40, 1)
			else
				boutput(user, SPAN_ALERT("Nothing was put into [src]!"))
		// loading from the ground
		else if (istype(O, /obj/item))
			var/obj/item/item = O
			if (!item.brew_result)
				return ..()
			if (active)
				boutput(user, SPAN_ALERT("[src] is currently fermenting."))
				return
			// "charging" is for sure correct terminology, I'm an expert because I asked chatgpt AND read the first result on google. Mhm mhm.
			user.visible_message(SPAN_NOTICE("[user] begins quickly charging [src] with [O]!"))

			var/staystill = user.loc
			var/itemtype = O.type
			for(var/obj/item/Produce in view(1,user))
				if (src.reagents.total_volume >= src.reagents.maximum_volume)
					boutput(user, SPAN_ALERT("[src] is full!"))
					break
				if (user.loc != staystill) break
				if (Produce.type != itemtype) continue
				if (load_still(Produce, user))
					playsound(src.loc, sound_brew, 30, 1)
					sleep(0.3 SECONDS)
			boutput(user, SPAN_NOTICE("You finish charging [src] with [O]!"))

		else
			return ..()

	verb/Eject_Items()
		set name = "Remove Items"
		set src in oview(1)
		set category = "Local"
		if (active)
			boutput(usr, SPAN_NOTICE("Cannot remove items from [src] while fermentation is active."))
			return
		if (src.contents.len < 1)
			boutput(usr, SPAN_NOTICE("There are no items in [src] to remove."))
			return
		usr.visible_message(SPAN_NOTICE("[usr] empties items from [src]!"))
		for (var/i = src.contents.len; i >= 1; i--)
		{
			src.contents[i].loc = src.loc
		}

	// Can't seem to make the still itself add to the composite heat capacity of the reagents,
	// so I guess modifying the exposed heat capacity is a slap-dash way to lower the rate of temp change.
	// Ideally I suppose the still would have it's own temperature.
	temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume, cannot_be_cooled = FALSE)
		/obj::temperature_expose()
		reagents.temperature_reagents(exposed_temperature, exposed_volume, 10)



/* ==================================================== */
/* --------------- Water Cooler Bottle ---------------- */
/* ==================================================== */

/obj/item/reagent_containers/food/drinks/coolerbottle
	name = "water cooler bottle"
	desc = "A water cooler bottle. Can hold up to 500 units."
	icon = 'icons/obj/items/chemistry_glassware.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	icon_state = "cooler_bottle"
	item_state = "flask"
	initial_volume = 500
	w_class = W_CLASS_BULKY
	incompatible_with_chem_dispensers = 1
	can_chug = 0

	New()
		. = ..()
		src.AddComponent( \
			/datum/component/reagent_overlay, \
			reagent_overlay_icon = src.icon, \
			reagent_overlay_icon_state = src.icon_state, \
			reagent_overlay_states = 15, \
			reagent_overlay_scaling = RC_REAGENT_OVERLAY_SCALING_LINEAR, \
		)
