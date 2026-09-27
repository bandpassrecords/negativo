package com.bandpassrecords.negativo

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class RollWidgetStateTest {

    private fun roll(
        id: String,
        state: String = "shoot",
        used: Int = 0,
        capacity: Int = 36,
        readyAt: Long? = null,
    ) = WidgetRoll(id, "Roll $id", "Kodak Portra 400", used, capacity, state, readyAt)

    private val rolls = listOf(roll("a"), roll("b"), roll("c"))
    private val labels = WidgetLabels()

    // ── Which roll a widget shows ────────────────────────────────────────────

    @Test
    fun `a new widget shows the first roll`() {
        assertEquals(0, RollWidgetState.indexFor(rolls, null))
    }

    @Test
    fun `a widget keeps showing the roll it was left on`() {
        assertEquals(2, RollWidgetState.indexFor(rolls, "c"))
    }

    @Test
    fun `a roll that is gone falls back to the first`() {
        assertEquals(0, RollWidgetState.indexFor(rolls, "deleted"))
    }

    @Test
    fun `no rolls means nothing to show`() {
        assertEquals(-1, RollWidgetState.indexFor(emptyList(), "a"))
        assertNull(RollWidgetState.cycle(emptyList(), "a", 1))
    }

    // ── The arrows ───────────────────────────────────────────────────────────

    @Test
    fun `next and previous step through the rolls`() {
        assertEquals("b", RollWidgetState.cycle(rolls, "a", 1)?.id)
        assertEquals("a", RollWidgetState.cycle(rolls, "b", -1)?.id)
    }

    @Test
    fun `the arrows wrap round at both ends`() {
        assertEquals("a", RollWidgetState.cycle(rolls, "c", 1)?.id)
        assertEquals("c", RollWidgetState.cycle(rolls, "a", -1)?.id)
    }

    @Test
    fun `arrows only show when there is another roll to switch to`() {
        assertTrue(RollWidgetState.canCycle(rolls))
        assertFalse(RollWidgetState.canCycle(listOf(roll("only"))))
    }

    // ── What it says ─────────────────────────────────────────────────────────

    @Test
    fun `frames read used over total`() {
        assertEquals("12 / 36", RollWidgetState.framesText(roll("a", used = 12), labels))
    }

    @Test
    fun `a roll to shoot on shows its film stock`() {
        assertEquals("Kodak Portra 400", RollWidgetState.statusText(roll("a"), labels, 0))
    }

    @Test
    fun `a full roll says to send it off`() {
        assertEquals(labels.full, RollWidgetState.statusText(roll("a", state = "full"), labels, 0))
    }

    @Test
    fun `a developing roll counts down in days and hours`() {
        val now = 1_000_000_000L
        val readyAt = now + ((2 * 24 + 5) * 60 + 30) * 60_000L // 2d 5h 30m
        val text = RollWidgetState.statusText(roll("a", "developing", readyAt = readyAt), labels, now)
        assertEquals("Ready in 2d 5h", text)
    }

    @Test
    fun `under a day it counts down in hours and minutes, rounding up`() {
        val now = 1_000_000_000L
        val readyAt = now + (3 * 60 + 14) * 60_000L + 1_000 // 3h 14m 1s
        val text = RollWidgetState.statusText(roll("a", "developing", readyAt = readyAt), labels, now)
        assertEquals("Ready in 3h 15m", text)
    }

    @Test
    fun `a developing roll whose time is up says it is ready`() {
        val text = RollWidgetState.statusText(roll("a", "developing", readyAt = 10), labels, 20)
        assertEquals(labels.ready, text)
    }

    @Test
    fun `the countdown uses the app's wording`() {
        val pt = labels.copy(readyInHours = "Pronto em {h}h {m}min")
        val text = RollWidgetState.statusText(roll("a", "developing", readyAt = 90 * 60_000L), pt, 0)
        assertEquals("Pronto em 1h 30min", text)
    }

    // ── Where a tap goes ─────────────────────────────────────────────────────

    @Test
    fun `tapping a roll with frames left opens the camera on it`() {
        assertEquals("negativo://widget/shoot?roll=a", RollWidgetState.tapUri(roll("a")))
    }

    @Test
    fun `tapping any other roll opens the roll`() {
        assertEquals("negativo://widget/roll?roll=a", RollWidgetState.tapUri(roll("a", "developing")))
        assertEquals("negativo://widget/roll?roll=a", RollWidgetState.tapUri(roll("a", "full")))
    }

    @Test
    fun `with no rolls a tap loads a new one`() {
        assertEquals("negativo://widget/new", RollWidgetState.tapUri(null))
    }

    @Test
    fun `progress is the share of frames shot, kept in range`() {
        assertEquals(50, RollWidgetState.progressPercent(roll("a", used = 18)))
        assertEquals(0, RollWidgetState.progressPercent(roll("a", capacity = 0)))
        assertEquals(100, RollWidgetState.progressPercent(roll("a", used = 40)))
    }
}
