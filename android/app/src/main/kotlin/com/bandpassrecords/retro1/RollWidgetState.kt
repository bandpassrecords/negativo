package com.bandpassrecords.negativo

/**
 * What the roll widget knows about one roll, as written by the Flutter app
 * (see lib/services/roll_widget_service.dart). Plain data, no Android types,
 * so the logic below can be unit-tested on the JVM.
 */
data class WidgetRoll(
    val id: String,
    val name: String,
    val stock: String,
    val used: Int,
    val capacity: Int,
    /** "shoot", "full", "developing" or "ready". */
    val state: String,
    /** When development finishes, for "developing" rolls. */
    val readyAtMillis: Long?,
)

/** Wording the app hands over, already in the user's language. */
data class WidgetLabels(
    val framesOf: String = "{used} / {total}",
    val readyInDays: String = "Ready in {d}d {h}h",
    val readyInHours: String = "Ready in {h}h {m}m",
    val ready: String = "Ready to reveal",
    val full: String = "Roll full — send it to develop",
    val empty: String = "No film loaded",
    val load: String = "Load a roll",
)

object RollWidgetState {

    /**
     * Index of the roll a widget shows: the one it was left on, or the first
     * (the app lists the roll shot on most recently first). -1 with no rolls.
     */
    fun indexFor(rolls: List<WidgetRoll>, selectedId: String?): Int {
        if (rolls.isEmpty()) return -1
        val i = rolls.indexOfFirst { it.id == selectedId }
        return if (i >= 0) i else 0
    }

    /** The roll after (step 1) or before (step -1) [current], wrapping round. */
    fun cycle(rolls: List<WidgetRoll>, current: String?, step: Int): WidgetRoll? {
        if (rolls.isEmpty()) return null
        val from = indexFor(rolls, current)
        val next = Math.floorMod(from + step, rolls.size)
        return rolls[next]
    }

    /** Whether the arrows are worth showing: only with something to switch to. */
    fun canCycle(rolls: List<WidgetRoll>) = rolls.size > 1

    /** "12 / 36". */
    fun framesText(roll: WidgetRoll, labels: WidgetLabels): String =
        labels.framesOf
            .replace("{used}", roll.used.toString())
            .replace("{total}", roll.capacity.toString())

    /**
     * The status line under the name. A developing roll's countdown is worked
     * out here, at draw time, so it stays current between app launches.
     */
    fun statusText(roll: WidgetRoll, labels: WidgetLabels, nowMillis: Long): String =
        when (roll.state) {
            "full" -> labels.full
            "ready" -> labels.ready
            "developing" -> countdown(roll.readyAtMillis, labels, nowMillis)
            else -> roll.stock
        }

    private fun countdown(readyAt: Long?, labels: WidgetLabels, now: Long): String {
        if (readyAt == null || readyAt <= now) return labels.ready
        val minutesLeft = (readyAt - now + 59_999) / 60_000 // round up
        val days = minutesLeft / (60 * 24)
        val hours = (minutesLeft / 60) % 24
        val minutes = minutesLeft % 60
        return if (days > 0) {
            labels.readyInDays.replace("{d}", days.toString()).replace("{h}", hours.toString())
        } else {
            labels.readyInHours.replace("{h}", hours.toString()).replace("{m}", minutes.toString())
        }
    }

    /** Where tapping the widget's main area goes for [roll]. */
    fun tapUri(roll: WidgetRoll?): String = when {
        roll == null -> "negativo://widget/new"
        roll.state == "shoot" -> "negativo://widget/shoot?roll=${roll.id}"
        else -> "negativo://widget/roll?roll=${roll.id}"
    }

    /** Percent of the roll shot, for the progress bar. */
    fun progressPercent(roll: WidgetRoll): Int =
        if (roll.capacity <= 0) 0 else (roll.used * 100 / roll.capacity).coerceIn(0, 100)
}
