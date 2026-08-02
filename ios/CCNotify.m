// Cube Crash — notifiche LOCALI (nessun server, nessuna capability push).
// Il file viene compilato nel target iOS (agganciato al pbxproj dalla pipeline di build).
// Grazie a +load + osservatore UIApplicationDidBecomeActiveNotification parte da solo:
// alla prima apertura chiede il permesso, poi (ri)programma le notifiche giornaliere.
@import Foundation;
@import UIKit;
@import UserNotifications;

@interface CCNotify : NSObject
@end

@implementation CCNotify

+ (void)load {
	// registra l'osservatore molto presto; la programmazione avviene a becomeActive
	[[NSNotificationCenter defaultCenter]
		addObserverForName:UIApplicationDidBecomeActiveNotification
		object:nil
		queue:[NSOperationQueue mainQueue]
		usingBlock:^(NSNotification * _Nonnull note) {
			[CCNotify scheduleDaily];
		}];
}

+ (void)scheduleDaily {
	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	// chiede il permesso (il sistema mostra il popup solo la prima volta)
	[center requestAuthorizationWithOptions:
			(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
		completionHandler:^(BOOL granted, NSError * _Nullable error) {
			if (!granted) return;
			// riprogramma da zero (idempotente ad ogni apertura)
			[center removeAllPendingNotificationRequests];

			// --- Notifiche giornaliere ricorrenti (modifica ora/testo qui) ---
			// { ora, minuto, titolo, testo, id }
			[CCNotify addDailyAtHour:13 minute:0
				title:@"Cube Crash 🧊"
				body:@"Fai il pieno di combo! Ti aspetta una partita 💥"
				identifier:@"cc_daily_lunch"];

			[CCNotify addDailyAtHour:19 minute:0
				title:@"Cube Crash 🧊"
				body:@"Le tue missioni ti aspettano! 🎯 Riscuoti le monete 🪙"
				identifier:@"cc_daily_evening"];
		}];
}

+ (void)addDailyAtHour:(NSInteger)hour minute:(NSInteger)minute
			title:(NSString *)title body:(NSString *)body
			identifier:(NSString *)identifier {
	UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
	content.title = title;
	content.body = body;
	content.sound = [UNNotificationSound defaultSound];

	NSDateComponents *dc = [[NSDateComponents alloc] init];
	dc.hour = hour;
	dc.minute = minute;
	UNCalendarNotificationTrigger *trigger =
		[UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dc repeats:YES];

	UNNotificationRequest *req =
		[UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
	[[UNUserNotificationCenter currentNotificationCenter]
		addNotificationRequest:req withCompletionHandler:nil];
}

@end
