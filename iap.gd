extends Node
# ============================================================
# Autoload "iap" — ACQUISTI IN-APP dei pacchetti MONETE.
#   - Android: plugin "GodotGooglePlayBilling" v3 (classe BillingClient) — INTEGRATO.
#   - iOS:     plugin "godot-storekit2" (classe GDScriptStoreKit2)        — INTEGRATO.
#
# Perché funzionino davvero servono comunque (esterni al codice):
#   1) i PRODOTTI CONSUMABILI su Play Console / App Store Connect con gli ID di PRODUCT_IDS;
#   2) i pagamenti attivi (banca/tasse) sui due account sviluppatore.
#
# Senza backend disponibile: available()=false, purchase() -> purchase_failed(i,"unavailable")
# e lo shop mostra "PROSSIMAMENTE" (build sempre funzionante).
# ============================================================

signal purchase_success(index: int)
signal purchase_failed(index: int, reason: String)

# wrapper StoreKit 2. DEVE stare in res:// root: res://ios/ NON è incluso nell'export Android
# (né come script nel PCK iOS) -> preload da lì darebbe "file does not exist" a runtime.
const SK2 := preload("res://store_kit2_wrapper.gd")

# ID prodotto (STESSO ordine di shop.COIN_PACKS). Devono combaciare ESATTAMENTE con gli store.
const PRODUCT_IDS := [
	"com.rossellini.cubecrash.coins1",
	"com.rossellini.cubecrash.coins2",
	"com.rossellini.cubecrash.coins3",
	"com.rossellini.cubecrash.coins4",
	"com.rossellini.cubecrash.coins5",
	"com.rossellini.cubecrash.coins6",
]

# iOS (StoreKit 2)
var _sk = null   # istanza SK2 (iOS)
# Android (GodotGooglePlayBilling v3 -> BillingClient)
var _bc: BillingClient = null
var _android_ready := false           # true dopo query_product_details OK
var _granted: Dictionary = {}         # purchase_token -> true (persistito: anti doppio-accredito)

var _pending: int = -1

const IAP_CFG := "user://iap.cfg"

func _load_granted() -> void:
	var cf := ConfigFile.new()
	if cf.load(IAP_CFG) == OK:
		for k in cf.get_section_keys("granted") if cf.has_section("granted") else []:
			_granted[k] = true

func _save_granted() -> void:
	var cf := ConfigFile.new()
	for k in _granted:
		cf.set_value("granted", k, true)
	cf.save(IAP_CFG)


func _ready() -> void:
	if ClassDB.class_exists("GodotStoreKit2"):
		_sk = SK2.new()
		_sk.transaction_state_changed.connect(_on_ios_transaction)
		# pre-carica i prodotti da App Store (StoreKit 2 richiede il Product prima dell'acquisto)
		for pid in PRODUCT_IDS:
			_sk.request_product_info(pid)
	elif Engine.has_singleton("GodotGooglePlayBilling"):
		_load_granted()
		_bc = BillingClient.new()
		add_child(_bc)
		_bc.connected.connect(_on_android_connected)
		_bc.disconnected.connect(func() -> void: _android_ready = false)
		_bc.connect_error.connect(func(_code: int, _msg: String) -> void: _android_ready = false)
		_bc.query_product_details_response.connect(_on_android_product_details)
		_bc.on_purchase_updated.connect(_on_android_purchase_updated)
		_bc.query_purchases_response.connect(_on_android_purchases_query)
		_bc.start_connection()


# Un backend di billing è disponibile?
func available() -> bool:
	return _sk != null or _bc != null


# Avvia l'acquisto del pacchetto `index`. È ASINCRONO: l'esito arriva sui segnali.
func purchase(index: int) -> void:
	if index < 0 or index >= PRODUCT_IDS.size():
		return
	if not available():
		purchase_failed.emit(index, "unavailable")
		return
	_pending = index
	var pid: String = PRODUCT_IDS[index]
	if _sk != null:
		_sk.purchase_product(pid)
	elif _bc != null:
		if not _android_ready:
			purchase_failed.emit(index, "unavailable")
			return
		var res: Dictionary = _bc.purchase(pid)
		if int(res.get("response_code", -1)) != 0:
			purchase_failed.emit(index, "error")
			_pending = -1


func _index_of_product(pid: String) -> int:
	return PRODUCT_IDS.find(pid)


# --------------------------------- iOS (StoreKit 2) ----------------------------------
func _on_ios_transaction(t) -> void:
	if not t.error.is_empty():
		purchase_failed.emit(_pending, "error")
		_pending = -1
		return
	match t.transaction_state:
		SK2.TransactionState.PURCHASED, SK2.TransactionState.RESTORED:
			var idx := _index_of_product(t.product_id)
			if idx >= 0:
				_grant(idx)
		SK2.TransactionState.CANCELED, SK2.TransactionState.FAILED, SK2.TransactionState.EXPIRED:
			purchase_failed.emit(_pending, "error")
			_pending = -1


# --------------------------- ANDROID (Google Play Billing) ---------------------------
func _on_android_connected() -> void:
	_bc.query_product_details(PackedStringArray(PRODUCT_IDS), BillingClient.ProductType.INAPP)
	# recupero: processa eventuali acquisti già pagati ma non ancora consegnati
	_bc.query_purchases(BillingClient.ProductType.INAPP)


func _on_android_product_details(result: Dictionary) -> void:
	if int(result.get("response_code", -1)) == BillingClient.BillingResponseCode.OK:
		_android_ready = true


func _on_android_purchase_updated(result: Dictionary) -> void:
	if int(result.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		purchase_failed.emit(_pending, "error")
		_pending = -1
		return
	for p in result.get("purchases", []):
		_process_android_purchase(p)


func _on_android_purchases_query(result: Dictionary) -> void:
	# risposta a query_purchases: consegna gli acquisti rimasti in sospeso
	if int(result.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		return
	for p in result.get("purchases", []):
		_process_android_purchase(p)


# Accredita (una sola volta) un acquisto PURCHASED e lo consuma per permettere il riacquisto.
func _process_android_purchase(p: Dictionary) -> void:
	if int(p.get("purchase_state", 0)) != BillingClient.PurchaseState.PURCHASED:
		return   # PENDING: non accreditare finché non è PURCHASED
	# id prodotto (chiave "product_ids", con fallback "products")
	var ids: Array = p.get("product_ids", p.get("products", []))
	var pid := str(ids[0]) if ids.size() > 0 else ""
	var idx := _index_of_product(pid)
	if idx < 0:
		return
	var token := str(p.get("purchase_token", ""))
	# accredita SUBITO, ma una sola volta per token (persistito contro il doppio-accredito)
	if token == "" or not _granted.has(token):
		if token != "":
			_granted[token] = true
			_save_granted()
		_grant(idx)
	# consuma: rende il pacchetto riacquistabile e lo toglie dagli acquisti in sospeso
	if token != "":
		_bc.consume_purchase(token)


# Accredita le monete del pacchetto (SOLO dopo la conferma reale dello store).
func _grant(index: int) -> void:
	if index < 0 or index >= shop.COIN_PACKS.size():
		return
	missions.coins += int(shop.COIN_PACKS[index]["coins"])
	missions._save()
	settings.play_buy_coins()
	purchase_success.emit(index)
	_pending = -1
