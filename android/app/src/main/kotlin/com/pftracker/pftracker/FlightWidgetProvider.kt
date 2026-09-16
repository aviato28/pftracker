package com.pftracker.pftracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home screen widget showing the current flight's altitude and speed.
 * Data is pushed from Dart (see data/widget/flight_widget_service.dart)
 * via HomeWidget.saveWidgetData/updateWidget — this class only ever reads
 * whatever was last written to [widgetData] and renders it. Tapping the
 * widget opens the app.
 */
class FlightWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.flight_widget).apply {
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                setTextViewText(
                    R.id.widget_route,
                    widgetData.getString("widget_route", null) ?: "No active flight",
                )
                setTextViewText(
                    R.id.widget_altitude,
                    widgetData.getString("widget_altitude", null) ?: "—",
                )
                setTextViewText(
                    R.id.widget_speed,
                    widgetData.getString("widget_speed", null) ?: "—",
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
