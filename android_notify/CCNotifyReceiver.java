package com.godot.game;

// Riceve l'allarme giornaliero e mostra la notifica. Gestisce anche il riavvio del telefono.

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

public class CCNotifyReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context ctx, Intent intent) {
        String action = intent.getAction();

        // dopo un riavvio del telefono gli allarmi si perdono: riprogrammali
        if (Intent.ACTION_BOOT_COMPLETED.equals(action)) {
            CCNotifyProvider.createChannel(ctx);
            CCNotifyProvider.scheduleAll(ctx);
            return;
        }

        int id = intent.getIntExtra("id", 0);
        String title = intent.getStringExtra("title");
        String body = intent.getStringExtra("body");
        if (title == null) title = "Cube Crash";
        if (body == null) body = "Torna a giocare! 🧊";

        // al tap: apre l'app
        Intent open = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) flags |= PendingIntent.FLAG_IMMUTABLE;
        PendingIntent contentPi = (open != null)
                ? PendingIntent.getActivity(ctx, 100 + id, open, flags) : null;

        Notification.Builder b;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            b = new Notification.Builder(ctx, CCNotifyProvider.CHANNEL_ID);
        } else {
            b = new Notification.Builder(ctx);
        }
        b.setSmallIcon(ctx.getApplicationInfo().icon)
                .setContentTitle(title)
                .setContentText(body)
                .setAutoCancel(true);
        if (contentPi != null) b.setContentIntent(contentPi);

        NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) nm.notify(id, b.build());
    }
}
