extends Node
# ============================================================
# Autoload "iap" — ACQUISTI IN-APP dei pacchetti MONETE (iOS StoreKit / Android Play Billing).
#
# STATO: scaffold pronto ad agganciarsi. Perché gli acquisti reali funzionino servono 3 cose
# ESTERNE al codice (non integrabili da qui):
#   1) un PLUGIN di billing nel progetto Godot:
#        - iOS: InAppStore (godot-ios-plugins)  -> singleton "InAppStore"
#        - Android: GodotGooglePlayBilling       -> singleton "GodotGooglePlayBilling"
#   2) i PRODOTTI (consumabili) creati su App Store Connect e Google Play Console con
#      gli ID di PRODUCT_IDS e i prezzi per paese.
#   3) accordi bancari/fiscali attivi sui due account sviluppatore.
#
# Finché il plugin non è presente, purchase() emette subito purchase_failed(i, "unavailable")
# e lo shop mostra "PROSSIMAMENTE". Quando il plugin c'è, completare i punti marcati TODO
# (chiamate/segnali specifici del plugin) e chiamare _grant(index) alla conferma dello store.
# ============================================================

signal purchase_success(index: int)
signal purchase_failed(index: int, reason: String)

# ID prodotto dei 6 pacchetti (STESSO ordine di shop.COIN_PACKS). Devono combaciare con
# quelli creati negli store.
const PRODUCT_IDS := [
	"com.rossellini.cubecrash.coins1",
	"com.rossellini.cubecrash.coins2",
	"com.rossellini.cubecrash.coins3",
	"com.rossellini.cubecrash.coins4",
	"com.rossellini.cubecrash.coins5",
	"com.rossellini.cubecrash.coins6",
]

var _ios: Object = null       # singleton InAppStore (iOS)
var _android: Object = null   # singleton GodotGooglePlayBilling (Android)
var _pending: int = -1        # indice pacchetto in acquisto

func _ready() -> void:
	if Engine.has_singleton("InAppStore"):
		_ios = Engine.get_singleton("InAppStore")
		# TODO iOS: _ios.request_product_info({"product_ids": PRODUCT_IDS})
		#           collegare il polling degli eventi (_ios.get_pending_event_count / pop_pending_event)
	elif Engine.has_singleton("GodotGooglePlayBilling"):
		_android = Engine.get_singleton("GodotGooglePlayBilling")
		# TODO Android: connettere i segnali (connected, purchases_updated, sku_details_query_completed...)
		#               poi _android.startConnection()

# Un backend di billing è disponibile?
func available() -> bool:
	return _ios != null or _android != null

# Avvia l'acquisto del pacchetto `index`. I plugin sono ASINCRONI: alla conferma dello
# store va chiamato _grant(index). Senza plugin fallisce subito.
func purchase(index: int) -> void:
	if index < 0 or index >= PRODUCT_IDS.size():
		return
	if not available():
		purchase_failed.emit(index, "unavailable")
		return
	_pending = index
	var pid: String = PRODUCT_IDS[index]
	if _ios != null:
		pass   # TODO iOS: _ios.purchase({"product_id": pid}) + gestire l'evento risultante
	elif _android != null:
		pass   # TODO Android: _android.purchase(pid) + gestire purchases_updated
	# NB: quando arriva la conferma dal plugin -> chiamare _grant(index)

# Accredita le monete del pacchetto (da chiamare SOLO alla conferma reale dello store).
func _grant(index: int) -> void:
	if index < 0 or index >= shop.COIN_PACKS.size():
		return
	missions.coins += int(shop.COIN_PACKS[index]["coins"])
	missions._save()
	purchase_success.emit(index)
	_pending = -1
