package com.godot.game;

// Cube Crash - notifiche LOCALI Android (nessun server).
// ContentProvider: viene creato AUTOMATICAMENTE all'avvio dell'app (prima dell'Activity),
// quindi programma da solo i promemoria giornalieri via AlarmManager.

import android.app.AlarmManager;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;

import java.util.Calendar;

public class CCNotifyProvider extends ContentProvider {
    public static final String CHANNEL_ID = "cc_reminders";

    @Override
    public boolean onCreate() {
        Context ctx = getContext();
        if (ctx == null) return false;
        createChannel(ctx);
        scheduleAll(ctx);
        return true;
    }

    // Promemoria giornalieri: { id, ora, minuto, titolo, testo }. Modifica qui orari/testi.
    public static void scheduleAll(Context ctx) {
        scheduleDaily(ctx, 0, 13, 0, "Cube Crash 🧊", "Fai il pieno di combo! 💥");
        scheduleDaily(ctx, 1, 19, 0, "Cube Crash 🧊", "Le tue missioni ti aspettano! 🎯");
    }

    static void createChannel(Context ctx) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel ch = new NotificationChannel(
                    CHANNEL_ID, "Promemoria", NotificationManager.IMPORTANCE_DEFAULT);
            NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null) nm.createNotificationChannel(ch);
        }
    }

    static void scheduleDaily(Context ctx, int id, int hour, int minute, String title, String body) {
        AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
        if (am == null) return;

        Intent i = new Intent(ctx, CCNotifyReceiver.class);
        i.setAction("com.godot.game.CC_NOTIFY");
        i.putExtra("id", id);
        i.putExtra("title", title);
        i.putExtra("body", body);

        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) flags |= PendingIntent.FLAG_IMMUTABLE;
        PendingIntent pi = PendingIntent.getBroadcast(ctx, id, i, flags);

        Calendar cal = Calendar.getInstance();
        cal.set(Calendar.HOUR_OF_DAY, hour);
        cal.set(Calendar.MINUTE, minute);
        cal.set(Calendar.SECOND, 0);
        if (cal.getTimeInMillis() <= System.currentTimeMillis()) {
            cal.add(Calendar.DAY_OF_YEAR, 1);
        }
        // inesatto ripetuto giornaliero: consentito senza permessi speciali
        am.setInexactRepeating(AlarmManager.RTC_WAKEUP, cal.getTimeInMillis(),
                AlarmManager.INTERVAL_DAY, pi);
    }

    // --- stub ContentProvider (non usati) ---
    @Override public Cursor query(Uri u, String[] p, String s, String[] a, String o) { return null; }
    @Override public String getType(Uri u) { return null; }
    @Override public Uri insert(Uri u, ContentValues v) { return null; }
    @Override public int delete(Uri u, String s, String[] a) { return 0; }
    @Override public int update(Uri u, ContentValues v, String s, String[] a) { return 0; }
}
