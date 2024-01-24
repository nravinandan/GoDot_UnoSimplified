# CardBase.gd - Class for player card
extends Node2D

onready var CardDatabase = preload("res://Assets/Cards/CardDatabase.gd")

# CardBase: blueprint for cards
class_name CardBase
var cardID      #Unique card ID
var button      #Button node to handle press events
var displayCard #ColorRect node to display the cards
var cardColor   #Holds the color of the card
var colorDesc   #Color description in english text
var type        #Number / Action card
var value       #Holds the inherent value of the card
var displayText #Holds the text to be displayed on the card
var label       #Label node to display the text
var isVisible   #True when the card is in play
var actionHandler #Method to handle actions for Action cards

# Constructor to initialize the members
func _init(cid = -1, colorDesc = "NONE", colorRGB = Color(1,1,1,1), type = "number", value = 0, text = "NONE", actionHandler = "NONE"):
	self.cardID = cid
	self.colorDesc = colorDesc
	self.cardColor = colorRGB
	self.type = type
	self.value = value
	self.displayText = text
	self.isVisible = false
	self.actionHandler = actionHandler
	
	#Initialization of button, displayCard and label would be done when 
	# they are being added to player hand or top of discard pile.
#	
