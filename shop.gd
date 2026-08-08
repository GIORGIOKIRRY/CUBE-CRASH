extends Node

# ============================================================
# Autoload "shop" — negozio di Cube Crash (DRAFT/placeholder).
# Si comprano con le MONETE (missions.coins): AVATAR (placeholder colorati) e
# SKIN dei cubi. Possesso + equipaggiati persistiti in user://shop.dat.
# NB: per ora avatar/skin sono colori placeholder; l'applicazione visiva
# (avatar sul profilo, skin sui cubi in partita) verrà agganciata dopo.
# ============================================================

const SAVE := "user://shop.dat"

# Avatar acquistabili (solo questi 3 per ora): id, icona, prezzo. Niente default gratis.
# Comprarli nello shop SBLOCCA l'icona profilo corrispondente (edit profilo).
const AVATARS := [
	{"id": "av_bomb",     "icon": "res://CORE/Assets/Art/Home/Shop/av_bomb.png",     "color": Color(0.90, 0.20, 0.20), "price": 2500},
	{"id": "av_mushroom", "icon": "res://CORE/Assets/Art/Home/Shop/av_mushroom.png", "color": Color(0.30, 0.75, 0.30), "price": 2500},
	{"id": "av_penguin",  "icon": "res://CORE/Assets/Art/Home/Shop/av_penguin.png",  "color": Color(0.20, 0.55, 0.95), "price": 2500},
]

# Pacchetti MONETE acquistabili con SOLDI VERI (€). NB: l'acquisto reale (StoreKit /
# Google Play Billing) NON è ancora integrato: per ora i pacchetti sono mostrati con il
# prezzo in € e il tap segnala "prossimamente".
# ECONOMIA: valore/€ crescente (più grande = miglior affare), standard nei giochi mobile.
#  ~1.000 monete/€ nel primo pack, ~1.700/€ nell'ultimo. Riferimento: 1.000 monete ≈ 1 €.
const COIN_PACKS := [
	{"coins": 1200,   "price": "1,19 €"},     # ~1008/€
	{"coins": 7000,   "price": "5,99 €"},     # ~1169/€
	{"coins": 15000,  "price": "11,99 €"},    # ~1251/€
	{"coins": 32000,  "price": "23,99 €"},    # ~1334/€
	{"coins": 90000,  "price": "59,99 €"},    # ~1500/€
	{"coins": 200000, "price": "119,99 €"},   # ~1667/€
]

# Skin cubi acquistabili: tutte e 7 le "skin 2" dei cubi (id = colore), 5000 monete l'una.
const SKINS := [
	{"id": "sk_red",    "icon": "res://CORE/Assets/Art/Home/CubeInfo/RedSkin2/red2_1.png",       "color": Color(0.95, 0.35, 0.35), "price": 5000},
	{"id": "sk_blue",   "icon": "res://CORE/Assets/Art/Home/CubeInfo/BlueSkin2/blue2_1.png",     "color": Color(0.36, 0.75, 1.00), "price": 5000},
	{"id": "sk_green",  "icon": "res://CORE/Assets/Art/Home/CubeInfo/GreenSkin2/green2_1.png",   "color": Color(0.40, 0.85, 0.45), "price": 5000},
	{"id": "sk_yellow", "icon": "res://CORE/Assets/Art/Home/CubeInfo/YellowSkin2/yellow2_1.png", "color": Color(0.98, 0.82, 0.20), "price": 5000},
	{"id": "sk_orange", "icon": "res://CORE/Assets/Art/Home/CubeInfo/OrangeSkin2/orange2_1.png", "color": Color(1.00, 0.60, 0.20), "price": 5000},
	{"id": "sk_purple", "icon": "res://CORE/Assets/Art/Home/CubeInfo/PurpleSkin2/purple2_1.png", "color": Color(0.70, 0.45, 0.95), "price": 5000},
	{"id": "sk_pink",   "icon": "res://CORE/Assets/Art/Home/CubeInfo/PinkSkin2/pink2_1.png",     "color": Color(1.00, 0.50, 0.80), "price": 5000},
]

var owned_avatars: Dictionary = {}
var owned_skins: Dictionary = {}
var equipped_avatar: String = ""
var equipped_skin: String = ""

# --- ROTAZIONE GIORNALIERA -----------------------------------------------------
# Lo shop si aggiorna ogni 24h (bucket ancorato alle 03:00 UTC): 3 avatar (sono solo 3,
# quindi sempre tutti) + 3 SKIN scelte a caso ma in modo DETERMINISTICO dal giorno, così
# escono le STESSE skin per TUTTI gli utenti nello stesso giorno (nessun server).
const SKIN_DAILY_COUNT := 3

func _day_index() -> int:
	return int(floor((Time.get_unix_time_from_system() - 3.0 * 3600.0) / 86400.0))

func seconds_until_shop_refresh() -> int:
	var next := (_day_index() + 1) * 86400 + 3 * 3600
	return maxi(0, next - int(Time.get_unix_time_from_system()))

# Le 3 skin del giorno (stesse per tutti). Shuffle deterministico seed = giorno.
func daily_skins() -> Array:
	var arr: Array = SKINS.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = _day_index()
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = arr[i]; arr[i] = arr[j]; arr[j] = tmp
	return arr.slice(0, mini(SKIN_DAILY_COUNT, arr.size()))

func _ready() -> void:
	_load()

func owns_avatar(id: String) -> bool:
	return bool(owned_avatars.get(id, false))

func owns_skin(id: String) -> bool:
	return bool(owned_skins.get(id, false))

func _price(list: Array, id: String) -> int:
	for it in list:
		if str(it["id"]) == id:
			return int(it["price"])
	return 0

func color_of_avatar(id: String) -> Color:
	for it in AVATARS:
		if str(it["id"]) == id:
			return it["color"]
	return Color(0.5, 0.5, 0.5)

func color_of_skin(id: String) -> Color:
	for it in SKINS:
		if str(it["id"]) == id:
			return it["color"]
	return Color(0.5, 0.5, 0.5)

# Compra un avatar: scala le monete e lo sblocca. Ritorna true se comprato.
func buy_avatar(id: String) -> bool:
	if owns_avatar(id):
		return false
	if not missions.spend_coins(_price(AVATARS, id)):
		return false
	owned_avatars[id] = true
	_save()
	return true

func buy_skin(id: String) -> bool:
	if owns_skin(id):
		return false
	if not missions.spend_coins(_price(SKINS, id)):
		return false
	owned_skins[id] = true
	_save()
	return true

func equip_avatar(id: String) -> void:
	if owns_avatar(id):
		equipped_avatar = id
		_save()

func equip_skin(id: String) -> void:
	if owns_skin(id):
		equipped_skin = id
		_save()

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("shop", "owned_avatars", owned_avatars)
	cfg.set_value("shop", "owned_skins", owned_skins)
	cfg.set_value("shop", "equipped_avatar", equipped_avatar)
	cfg.set_value("shop", "equipped_skin", equipped_skin)
	cfg.save(SAVE)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) != OK:
		return
	owned_avatars = cfg.get_value("shop", "owned_avatars", owned_avatars)
	owned_skins = cfg.get_value("shop", "owned_skins", owned_skins)
	equipped_avatar = str(cfg.get_value("shop", "equipped_avatar", equipped_avatar))
	equipped_skin = str(cfg.get_value("shop", "equipped_skin", equipped_skin))
