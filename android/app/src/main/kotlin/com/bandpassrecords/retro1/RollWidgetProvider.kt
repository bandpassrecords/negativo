package com.bandpassrecords.negativo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * The home-screen widget for an open roll: its name, film stock and frames,
 * a shutter that opens the camera on it, and ‹ › arrows that switch between
 * the open rolls right on the home screen. Each widget remembers its own
 * roll, so two widgets can show two rolls.
 *
 * The app writes the rolls as JSON under [DATA_KEY] (see
 * lib/services/roll_widget_service.dart); this only draws them.
 */
class RollWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val (rolls, labels) = readData(widgetData)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, render(context, id, rolls, labels))
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val step = when (intent.action) {
            ACTION_NEXT -> 1
            ACTION_PREVIOUS -> -1
            else -> 0
        }
        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        if (step == 0 || widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            super.onReceive(context, intent)
            return
        }
        // An arrow: move this widget to the next roll and redraw just it.
        val (rolls, labels) = readData(HomeWidgetPlugin.getData(context))
        val next = RollWidgetState.cycle(rolls, selectedRoll(context, widgetId), step)
        if (next != null) saveSelectedRoll(context, widgetId, next.id)
        AppWidgetManager.getInstance(context)
            .updateAppWidget(widgetId, render(context, widgetId, rolls, labels))
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = selectionPrefs(context).edit()
        for (id in appWidgetIds) prefs.remove(selectionKey(id))
        prefs.apply()
    }

    private fun render(
        context: Context,
        widgetId: Int,
        rolls: List<WidgetRoll>,
        labels: WidgetLabels,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.roll_widget)
        val index = RollWidgetState.indexFor(rolls, selectedRoll(context, widgetId))
        val roll = if (index >= 0) rolls[index] else null

        val open = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse(RollWidgetState.tapUri(roll)),
        )
        views.setOnClickPendingIntent(R.id.roll_widget_root, open)

        if (roll == null) {
            views.setTextViewText(R.id.roll_widget_name, labels.empty)
            views.setTextViewText(R.id.roll_widget_status, labels.load)
            views.setViewVisibility(R.id.roll_widget_frames_row, View.GONE)
            views.setViewVisibility(R.id.roll_widget_shutter, View.GONE)
            views.setViewVisibility(R.id.roll_widget_prev, View.INVISIBLE)
            views.setViewVisibility(R.id.roll_widget_next, View.INVISIBLE)
            return views
        }

        views.setTextViewText(R.id.roll_widget_name, roll.name)
        views.setTextViewText(
            R.id.roll_widget_status,
            RollWidgetState.statusText(roll, labels, System.currentTimeMillis()),
        )
        views.setViewVisibility(R.id.roll_widget_frames_row, View.VISIBLE)
        views.setTextViewText(R.id.roll_widget_frames, RollWidgetState.framesText(roll, labels))
        views.setProgressBar(R.id.roll_widget_progress, 100, RollWidgetState.progressPercent(roll), false)

        // The shutter only makes sense on a roll with frames left.
        if (roll.state == "shoot") {
            views.setViewVisibility(R.id.roll_widget_shutter, View.VISIBLE)
            views.setOnClickPendingIntent(R.id.roll_widget_shutter, open)
        } else {
            views.setViewVisibility(R.id.roll_widget_shutter, View.GONE)
        }

        val arrows = if (RollWidgetState.canCycle(rolls)) View.VISIBLE else View.INVISIBLE
        views.setViewVisibility(R.id.roll_widget_prev, arrows)
        views.setViewVisibility(R.id.roll_widget_next, arrows)
        views.setOnClickPendingIntent(R.id.roll_widget_prev, arrowIntent(context, widgetId, ACTION_PREVIOUS))
        views.setOnClickPendingIntent(R.id.roll_widget_next, arrowIntent(context, widgetId, ACTION_NEXT))
        return views
    }

    private fun arrowIntent(context: Context, widgetId: Int, action: String): PendingIntent {
        val intent = Intent(context, RollWidgetProvider::class.java).apply {
            this.action = action
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            // Distinct per widget and direction, so PendingIntents don't merge.
            data = Uri.parse("negativo://widget-arrow/$widgetId/$action")
        }
        return PendingIntent.getBroadcast(
            context,
            widgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        const val DATA_KEY = "roll_widget_v1"
        private const val ACTION_NEXT = "com.bandpassrecords.negativo.widget.NEXT_ROLL"
        private const val ACTION_PREVIOUS = "com.bandpassrecords.negativo.widget.PREVIOUS_ROLL"
        private const val SELECTION_PREFS = "roll_widget_selection"

        private fun selectionPrefs(context: Context) =
            context.getSharedPreferences(SELECTION_PREFS, Context.MODE_PRIVATE)

        private fun selectionKey(widgetId: Int) = "widget_$widgetId"

        private fun selectedRoll(context: Context, widgetId: Int): String? =
            selectionPrefs(context).getString(selectionKey(widgetId), null)

        private fun saveSelectedRoll(context: Context, widgetId: Int, rollId: String) =
            selectionPrefs(context).edit().putString(selectionKey(widgetId), rollId).apply()

        /** The rolls and labels the app last wrote; nothing yet means none. */
        fun readData(prefs: SharedPreferences): Pair<List<WidgetRoll>, WidgetLabels> {
            val raw = prefs.getString(DATA_KEY, null) ?: return emptyList<WidgetRoll>() to WidgetLabels()
            return try {
                val json = JSONObject(raw)
                val rollsJson = json.optJSONArray("rolls")
                val rolls = buildList {
                    if (rollsJson != null) {
                        for (i in 0 until rollsJson.length()) {
                            val r = rollsJson.getJSONObject(i)
                            add(
                                WidgetRoll(
                                    id = r.getString("id"),
                                    name = r.optString("name"),
                                    stock = r.optString("stock"),
                                    used = r.optInt("used"),
                                    capacity = r.optInt("capacity"),
                                    state = r.optString("state", "shoot"),
                                    readyAtMillis = if (r.isNull("readyAtMillis")) null else r.optLong("readyAtMillis"),
                                ),
                            )
                        }
                    }
                }
                val l = json.optJSONObject("labels")
                val defaults = WidgetLabels()
                val labels = if (l == null) defaults else WidgetLabels(
                    framesOf = l.optString("framesOf", defaults.framesOf),
                    readyInDays = l.optString("readyInDays", defaults.readyInDays),
                    readyInHours = l.optString("readyInHours", defaults.readyInHours),
                    ready = l.optString("ready", defaults.ready),
                    full = l.optString("full", defaults.full),
                    empty = l.optString("empty", defaults.empty),
                    load = l.optString("load", defaults.load),
                )
                rolls to labels
            } catch (e: Exception) {
                emptyList<WidgetRoll>() to WidgetLabels()
            }
        }
    }
}
