extends Node

# ============================================================
# Autoload "ads" — pubblicità AdMob (plugin Poing Studios v5).
# BANNER: ancorato al bordo inferiore dello schermo, mostrato solo
#         durante il gameplay (game.tscn: tutte le modalità,
#         classic e speedrun incluse). show_banner() / hide_banner().
# INTERSTITIAL / REWARDED: precaricati all'avvio e ricaricati dopo
#         ogni visualizzazione. show_interstitial() / show_rewarded().
# CONSENSO: flusso UMP (GDPR) prima dell'inizializzazione dell'SDK.
# Nell'editor/PC il plugin mostra annunci finti (mock) per i test.
# ============================================================

signal rewarded_earned(amount: int, type: String)
signal rewarded_closed
signal interstitial_closed

# --- ID reali (account AdMob pub-7508049500048357) ---
# NB: sempre ID reali, anche in sviluppo (scelta voluta). Sul telefono
# MAI cliccare i propri annunci: i click fanno bannare l'account AdMob.
# Su PC/editor il plugin mostra comunque annunci finti (mock).
const REAL_BANNER_ANDROID := "ca-app-pub-7508049500048357/6293845523"
const REAL_INTERSTITIAL_ANDROID := "ca-app-pub-7508049500048357/3803413556"
const REAL_REWARDED_ANDROID := "ca-app-pub-7508049500048357/1177250219"
const REAL_BANNER_IOS := "ca-app-pub-7508049500048357/8815946941"
const REAL_INTERSTITIAL_IOS := "ca-app-pub-7508049500048357/8536177127"
const REAL_REWARDED_IOS := "ca-app-pub-7508049500048357/1504553278"

var _initialized: bool = false
var _banner: AdView = null
var _banner_wanted: bool = false        # richiesta arrivata prima dell'init
var _interstitial: InterstitialAd = null
var _interstitial_loader := InterstitialAdLoader.new()
var _rewarded: RewardedAd = null
var _rewarded_loader := RewardedAdLoader.new()

func _ready() -> void:
	_request_consent()

# ============================================================
# CONSENSO (UMP / GDPR) → poi inizializzazione SDK
# ============================================================
func _request_consent() -> void:
	# Su PC/editor il modulo consenso non ha il mock: si salta e si
	# inizializza subito (gli annunci finti funzionano comunque).
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		_initialize_sdk()
		return
	var params := ConsentRequestParameters.new()
	UserMessagingPlatform.consent_information.update(
		params, _on_consent_updated, _on_consent_update_failed
	)

func _on_consent_updated() -> void:
	var info := UserMessagingPlatform.consent_information
	if info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED \
			and info.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(_on_consent_form_loaded, _on_consent_form_failed)
	else:
		_initialize_sdk()

func _on_consent_update_failed(_error: FormError) -> void:
	# senza rete o fuori UE: si prosegue comunque
	_initialize_sdk()

func _on_consent_form_loaded(form: ConsentForm) -> void:
	form.show(_on_consent_form_dismissed)

func _on_consent_form_failed(_error: FormError) -> void:
	_initialize_sdk()

func _on_consent_form_dismissed(_error: FormError) -> void:
	_initialize_sdk()

func _initialize_sdk() -> void:
	# ATTENZIONE: niente listener a initialize(): il plugin lo collega con
	# una connessione one-shot a un metodo statico e Godot 4.7.1 crasha
	# (access violation). Si attende l'init con un polling sullo stato.
	MobileAds.initialize()
	_await_initialization()

func _await_initialization() -> void:
	for _i in 20:   # max ~10 secondi, poi si procede comunque
		await get_tree().create_timer(0.5).timeout
		if _is_sdk_ready():
			break
	_initialized = true
	_load_interstitial()
	_load_rewarded()
	if _banner_wanted:
		show_banner()

func _is_sdk_ready() -> bool:
	var status := MobileAds.get_initialization_status()
	if status == null:
		return false
	for adapter in status.adapter_status_map.values():
		if adapter.initialization_state == AdapterStatus.InitializationState.READY:
			return true
	return false

# ============================================================
# ID UNITÀ (per piattaforma)
# ============================================================
func _banner_id() -> String:
	return REAL_BANNER_IOS if OS.get_name() == "iOS" else REAL_BANNER_ANDROID

func _interstitial_id() -> String:
	return REAL_INTERSTITIAL_IOS if OS.get_name() == "iOS" else REAL_INTERSTITIAL_ANDROID

func _rewarded_id() -> String:
	return REAL_REWARDED_IOS if OS.get_name() == "iOS" else REAL_REWARDED_ANDROID

# ============================================================
# BANNER (ancorato in basso, adattivo a tutta larghezza)
# ============================================================
func show_banner() -> void:
	_banner_wanted = true
	if not _initialized:
		return   # verrà mostrato appena l'SDK è pronto
	if _banner != null:
		_banner.show()
		return
	# Banner standard 320x50: piccolo e rettangolare, centrato in basso
	# (non a tutta larghezza), sotto la scorta dei pezzi.
	_banner = AdView.new(_banner_id(), AdSize.BANNER, AdPosition.BOTTOM)
	var listener := AdListener.new()
	listener.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		push_warning("ads: banner non caricato: %s" % error.message)
		if _banner != null:
			_banner.destroy()
			_banner = null
	_banner.ad_listener = listener
	_banner.load_ad(AdRequest.new())

func hide_banner() -> void:
	_banner_wanted = false
	if _banner != null:
		_banner.hide()

# ============================================================
# INTERSTITIAL (tra una partita e l'altra)
# ============================================================
func _load_interstitial() -> void:
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial = ad
		var callbacks := FullScreenContentCallback.new()
		callbacks.on_ad_dismissed_full_screen_content = func() -> void:
			_destroy_interstitial()
			interstitial_closed.emit()
			_load_interstitial()   # precarica il prossimo
		callbacks.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
			_destroy_interstitial()
			interstitial_closed.emit()
			_load_interstitial()
		_interstitial.full_screen_content_callback = callbacks
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		push_warning("ads: interstitial non caricato: %s" % error.message)
		await get_tree().create_timer(30.0).timeout   # riprova (rete assente ecc.)
		_load_interstitial()
	_interstitial_loader.load(_interstitial_id(), AdRequest.new(), callback)

func _destroy_interstitial() -> void:
	if _interstitial != null:
		_interstitial.destroy()
		_interstitial = null

func is_interstitial_ready() -> bool:
	return _interstitial != null

## Mostra l'interstitial se pronto. Ritorna true se è stato mostrato;
## in ogni caso chi ascolta "interstitial_closed" riprende il flusso.
func show_interstitial() -> bool:
	if _interstitial == null:
		return false
	_interstitial.show()
	return true

# ============================================================
# REWARDED (bonus in cambio del video)
# ============================================================
func _load_rewarded() -> void:
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded = ad
		var callbacks := FullScreenContentCallback.new()
		callbacks.on_ad_dismissed_full_screen_content = func() -> void:
			_destroy_rewarded()
			rewarded_closed.emit()
			_load_rewarded()   # precarica il prossimo
		callbacks.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
			_destroy_rewarded()
			rewarded_closed.emit()
			_load_rewarded()
		_rewarded.full_screen_content_callback = callbacks
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		push_warning("ads: rewarded non caricato: %s" % error.message)
		await get_tree().create_timer(30.0).timeout   # riprova (rete assente ecc.)
		_load_rewarded()
	_rewarded_loader.load(_rewarded_id(), AdRequest.new(), callback)

func _destroy_rewarded() -> void:
	if _rewarded != null:
		_rewarded.destroy()
		_rewarded = null

func is_rewarded_ready() -> bool:
	return _rewarded != null

## Mostra il rewarded se pronto. Il premio arriva via "rewarded_earned";
## la chiusura (con o senza premio) via "rewarded_closed".
func show_rewarded() -> bool:
	if _rewarded == null:
		return false
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(item: RewardedItem) -> void:
		rewarded_earned.emit(item.amount, item.type)
	_rewarded.show(listener)
	return true
