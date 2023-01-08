extends HBoxContainer

onready var coinTextCounter = $Text
onready var coinIcon = $CoinSprite

var coinAmmount

func _ready():
	coinAmmount = 0

func addCoins(var ammount):
	coinAmmount += ammount
	updateText()

func setCoins(var ammount):
	coinAmmount = ammount
	updateText()

func updateText():
	coinTextCounter.text = coinAmmount