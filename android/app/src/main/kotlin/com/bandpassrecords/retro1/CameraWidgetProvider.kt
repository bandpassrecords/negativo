package com.bandpassrecords.negativo

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * A one-cell shutter button for the home screen: tapping it opens the camera
 * on the roll shot on most recently. It shows no roll data, so it never needs
 * redrawing; which roll to open is decided in the app at tap time (see
 * RollWidgetTap.camera in lib/services/roll_widget_service.dart).
 */
class CameraWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val views = RemoteViews(context.packageName, R.layout.camera_widget)
        val open = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse(CAMERA_URI),
        )
        views.setOnClickPendingIntent(R.id.camera_widget_root, open)
        appWidgetManager.updateAppWidget(appWidgetIds, views)
    }

    companion object {
        const val CAMERA_URI = "negativo://widget/camera"
    }
}
