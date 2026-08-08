extends Node
# Localizzazione minimale IT/EN in base alla lingua del DISPOSITIVO.
# L'italiano è la lingua sorgente: se il dispositivo non è in italiano si usa
# l'inglese; se una traduzione manca, si ricade sull'italiano (mai testo vuoto).

var _italian := true

func _ready() -> void:
	refresh()

func refresh() -> void:
	var l := OS.get_locale().to_lower()   # es. "it_it", "en_us"
	_italian = l.begins_with("it")

func is_italian() -> bool:
	return _italian

# Traduce una stringa italiana sorgente nella lingua del dispositivo.
func t(it: String) -> String:
	if _italian:
		return it
	return MAP.get(it, it)

# Traduce con parametri stile printf: L.tf("Nuove tra %dh", [ore])
func tf(it: String, args: Array) -> String:
	return t(it) % args

# --- Dizionario IT -> EN ---------------------------------------------------
const MAP := {
	# Deck
	"CUBE DECK": "CUBE DECK",
	"CUBO ROSSO": "RED CUBE",
	"CUBO BLU": "BLUE CUBE",
	"CUBO VERDE": "GREEN CUBE",
	"CUBO GIALLO": "YELLOW CUBE",
	"CUBO ARANCIO": "ORANGE CUBE",
	"CUBO VIOLA": "PURPLE CUBE",
	"CUBO ROSA": "PINK CUBE",
	"FRECCIA VERT.": "V. ARROW",
	"FRECCIA ORIZ.": "H. ARROW",
	"BOMBA": "BOMB",
	"BOMBA X": "X BOMB",
	"BOMBA ANGOLI": "CORNER BOMB",

	# Home / modalità
	"SCEGLI MODALITÀ": "SELECT MODE",
	"CLASSIC": "CLASSIC",
	"SPEEDRUN": "SPEEDRUN",
	"combo + bombe": "combos + bombs",
	"piu punti in 5 minuti": "most points in 5 minutes",
	"NOME GIOCATORE": "PLAYER NAME",
	"PLAYER": "PLAYER",
	"PROSSIMAMENTE": "COMING SOON",
	"EDIT PROFILE": "EDIT PROFILE",
	"CONTROLLO...": "CHECKING...",
	"NOME GIA IN USO!": "NAME ALREADY TAKEN!",
	"TOP CRASHER": "TOP CRASHER",
	"È TUA!": "OWNED!",
	"IN USO": "IN USE",
	"USA": "USE",
	"CONTINUA?": "CONTINUE?",
	"Guarda una pubblicità\nper riprendere la partita": "Watch an ad\nto resume the game",
	"MORE": "MORE",

	# Nav / shop
	"SHOP": "SHOP",
	"NEGOZIO": "SHOP",
	"AVATAR": "AVATARS",
	"SKIN CUBI": "CUBE SKINS",
	"MONETE INSUFFICIENTI!": "NOT ENOUGH COINS!",
	"NUOVO SHOP TRA": "NEW SHOP IN",
	"ACQUISTO COMPLETATO!": "PURCHASE COMPLETE!",
	"ACQUISTO NON RIUSCITO": "PURCHASE FAILED",
	"monete insufficienti": "not enough coins",
	"MONETE": "COINS",

	# Missioni
	"MISSIONI": "MISSIONS",
	"SETTIMANALI": "WEEKLY",
	"GIORNALIERE": "DAILY",
	"RISCUOTI": "CLAIM",
	"FATTO": "DONE",
	"IN CORSO": "IN PROGRESS",
	"CHIUDI": "CLOSE",
	"Nuove tra %dh %dm": "New in %dh %dm",
	"Nuove missioni tra %dh %dm": "New missions in %dh %dm",

	# Settings
	"IMPOSTAZIONI": "SETTINGS",
	"SETTINGS": "SETTINGS",
	"MUSICA": "MUSIC",
	"SUONI": "SOUND",
	"VIBRAZIONE": "VIBRATION",
	"ALTRO": "MORE",
	"Contattaci": "Contact us",
	"Condividi il gioco": "Share the game",
	"Termini": "Terms",
	"Privacy": "Privacy",
	"Ringraziamenti": "Credits",
	"GRAZIE": "THANKS",
	"INDIETRO": "BACK",

	# Partita / game over
	"GAME OVER": "GAME OVER",
	"PUNTEGGIO": "SCORE",
	"RECORD": "RECORD",
	"NUOVO RECORD!": "NEW RECORD!",
	"BEST SCORE!": "BEST SCORE!",
	"GIOCA ANCORA": "PLAY AGAIN",
	"RIVIVI": "REVIVE",
	"NO SPACE": "NO SPACE",
	"NO MOVES": "NO MOVES",
	"MOSSE": "MOVES",
	"COMBO:": "COMBO:",
	"USCIRE DALLA PARTITA?": "QUIT THE GAME?",
	"Ci sono ancora mosse possibili!": "There are still moves left!",
	"RESTA": "STAY",
	"ESCI": "QUIT",

	# Loading
	"CARICAMENTO": "LOADING",
	"CARICAMENTO...": "LOADING...",

	# Popup info cubo
	"CUBE INFO": "CUBE INFO",
	"TIPO:": "TYPE:",
	"CLASSICO": "CLASSIC",
	"ABILITA": "ABILITY",
	"ESPLOSIVO": "EXPLOSIVE",
	"SKIN": "SKINS",
	"Rosso, quadrato e senza fronzoli. Nessun potere speciale: solo una gran voglia di essere abbinato.": "Red, square and no frills. No special powers: just a burning desire to be matched.",
	"Arancione come un tramonto, utile come... un altro cubo. Fa numero, e lo fa benissimo.": "Orange like a sunset, useful like... another cube. It makes up the numbers, and does it perfectly.",
	"Giallo acceso, personalita spenta. Non illumina la stanza, ma riempie la griglia.": "Bright yellow, dim personality. It won't light up the room, but it fills the grid.",
	"Verde speranza: spera sempre che tu lo abbini in tempo. Nessun superpotere, tanta pazienza.": "Hopeful green: always hoping you'll match it in time. No superpowers, lots of patience.",
	"Blu come il lunedi. Fa il suo dovere senza lamentarsi (troppo).": "Blue like a Monday. Does its job without complaining (too much).",
	"Viola misterioso... ma il mistero e che non fa niente di speciale. Elegante, pero.": "Mysterious purple... but the mystery is it does nothing special. Elegant, though.",
	"Rosa e fiero. Sembra tenero, ma sa il fatto suo quando si tratta di combo.": "Pink and proud. Looks cute, but knows its stuff when it comes to combos.",
	"Distrugge tutta la COLONNA in cui si trova. Verticale e senza pieta.": "Destroys the entire COLUMN it sits in. Vertical and merciless.",
	"Spazza via l'intera RIGA. Orizzontale e implacabile.": "Wipes out the entire ROW. Horizontal and relentless.",
	"Esplode e distrugge i cubi tutt'intorno (3x3). Boom!": "Explodes and destroys the cubes all around (3x3). Boom!",
	"Esplode lungo le due diagonali, a forma di X.": "Explodes along both diagonals, in an X shape.",
	"Colpisce i quattro angoli dell'area. Sorpresa!": "Hits the four corners of the area. Surprise!",
	"TEST": "TEST",
	"sperimentale, bombe swap": "experimental, swap bombs",
	"TEST 6": "TEST 6",
	"classica, 4 colori": "classic, 4 colors",
	"OK": "OK",
}
