package com.rootexp.aj

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class BalanceWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.balance_widget).apply {
                val balance = widgetData.getString("total_balance", "₱0.00")
                val account = widgetData.getString("account_name", "Account")
                val lastUpdate = widgetData.getString("last_update", "Tap to sync")

                setTextViewText(R.id.total_balance, balance)
                setTextViewText(R.id.account_name, account)
                setTextViewText(R.id.last_update, lastUpdate)

                // Setup Intent for main app
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                setOnClickPendingIntent(R.id.total_balance, pendingIntent)
                setOnClickPendingIntent(R.id.widget_quick_add, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
