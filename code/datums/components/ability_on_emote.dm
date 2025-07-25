/// This component causes a mob to activate an ability when it does a specific emote.
/datum/component/ability_on_emote
	dupe_mode = COMPONENT_DUPE_ALLOWED
	var/emote
	var/ability_path
	var/voluntary_exclusive = FALSE // Should the ability be triggered only when the emote is voluntary?

TYPEINFO(/datum/component/ability_on_emote)
	initialization_args = list()

/datum/component/ability_on_emote/Initialize(var/emote, var/ability_path, var/voluntary_exclusive = FALSE)
	. = ..()
	if(!istype(parent, /mob))
		return COMPONENT_INCOMPATIBLE
	src.ability_path = ability_path
	src.emote = emote
	if (voluntary_exclusive)
		src.voluntary_exclusive = voluntary_exclusive
	RegisterSignal(parent, COMSIG_MOB_EMOTE, PROC_REF(cast_on_emote))

/datum/component/ability_on_emote/proc/cast_on_emote(mob/source, emote, voluntary, atom/target)
	if (emote != src.emote || (!voluntary && voluntary_exclusive))
		return
	if(!src.ability_path)
		return
	var/mob/parent_mob = parent
	var/datum/targetable/ability = parent_mob.abilityHolder?.getAbility(ability_path)
	if (!ability)
		return
	// we want to suppress the usual feedback messages for when an ability is, e.g. on cooldown, because it's an indirect action when via an emote.
	ability.handleCast(target, list("silent_fail" = TRUE))

/datum/component/ability_on_emote/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOB_EMOTE))
	. = ..()
