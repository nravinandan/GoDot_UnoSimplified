# Playspace.gd - This is the space where all the action takes place.

extends CardBase
 
const CardData = preload("res://Assets/Cards/CardBase.tscn")
onready var cardinfo = CardDatabase.card_data
onready var popup_window = get_node("PopUpWindow")
const Player = preload("res://Player.gd")
var uno_font = preload("res://ARIAL.TTF")
var dynamic_font

#Constants
const HAND_SIZE = 7
const NUM_DECK = 2
const PLAYER1 = 0
const PLAYER2 = 1
const WILDCARD = 50
const DELAY_NEXTPLAY = 3  # Delay in sec

# Event Types: Numeric Cards, Action Cards and Wild Cards
enum EVENT { PLAY_CARD, DRAW_CARD, SKIP_CARD, DRAW_2CARD, DRAW_4CARD=4 }
enum STATE {INIT_STATE, START_STATE, NORMALPLAY_STATE, DRAW2_STATE, SKIP_STATE, WILD_STATE, WARNING_STATE, ENDGAME_STATE }
var state = STATE.INIT_STATE

var cid = 010   # Unique Card id for evey card created
	
# Variables
var deck = []             # Deck of cards: Type CardBase
var deck_pool = []        # Pool of Deck to be used during game play.
var visible_deck = []     # Cards visible on the deck
var players = []

var prev_player = -1
var discard_pile = []
var reverse = false
var draw_stack = 0
var top_card              # Top card on discard pile
var last_event            # One of PLAY_CARD, DRAW_CARD, DRAW_2CARD, DRAW_4CARD
var current_player = 0    # Player1 or Player2
var current_color = "NAC" # Not a color
var iscolor_picked = false
var color_buttons = []

# Called when the node enters the scene tree for the first time.
func _ready():
#	print(cardinfo)
	# Set up the current state
	state = STATE.INIT_STATE
	
	#Get special cards from user (SKIP, DRAW2, REVERSE, WILD, WILDDRAW4)
	#var special_cards = get_special_cards_from_user()
	#print(special_cards)
	
	#Initialize the Deck based on the cards in database
	initialize_deck()	
	shuffle_deck()
	create_players()
	initialize_ticker()
	initialize_font()
	deal_cards()
	setup_hands()
	setup_topcard()
	initialize_colorpick_buttons()
#	add_card(players[PLAYER2].hand, "wild")
	show_hand(PLAYER2)

# Create Labels for player info
var ticker = []
var ticker_info = []
var pos_delta = Vector2(0, -50)
var pos = Vector2(750, 300)
var pos1 = Vector2(850, 300)
var labelStr
func initialize_ticker():
	for num in range(players.size()):
		labelStr = "PLAYER " + str(num+1)
		ticker.append(create_label(labelStr, Vector2(100, 50), pos + (pos_delta*num)))
		add_child(ticker[num])
		
		#Create the info label for each player
		ticker_info.append(create_label("", Vector2(100, 50), pos1 + (pos_delta*num)))
		add_child(ticker_info[num])
		
func initialize_font():	
	dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load("res://ARIAL.TTF")
	dynamic_font.size = 25
	
# Button press event handler - Card played
func _button_pressed(card):
	if(state == STATE.INIT_STATE):
		return # Disregard Card select event in this state
		
	#Check if its a valid card
	if(not validate_card(card)):
		return
		
	play_card(card)
	update_state()
	#Turn change if we do not have action card played
	if(check_turn_change()):
		next_turn()
#	update_state()
#	play_turn()  # Continue game
	
# Check if turn changed based on the top_card
func check_turn_change():
	# Return true for Wild if color is chosen
	if((state == STATE.WILD_STATE) and (not iscolor_picked)):
		return false
	elif(state == STATE.ENDGAME_STATE):
		return false
	# Return true for Draw2 / Draw4 / Number Card
	return true 
	# Turn does not change for SKIP and REVERSE
	
#	# If player draw card during turn, we change turn irrespective of top card
#	if(last_event == DRAW_CARD):
#		return true
#
#	if((top_card.displayText == "DRAW2") and (last_event == PLAY_CARD)):
#		return true     # Player need to draw 2 cards
		
#	if(top_card.displayText == "SKIP" or top_card.displayText == "REVERSE"):
#		#Top card is SKIP or REVERSE
#		#In 2 player game, same player continues the play
#		return false
func _process(delta):
	
	match state:
		STATE.INIT_STATE:
#			get_tree().get_root().set_disable_input(true)
			$DRAW.disabled = true
			$START.disabled = false
			# Wait for START button press event
			
		STATE.START_STATE:
			if(top_card.type == "action"):
				match top_card.displayText:
					"+2":
						self.call(top_card.actionHandler)	
						next_turn()
						# Special action complete
						state = STATE.NORMALPLAY_STATE
						
					"SKIP":
						update_tickerinfo("Skip Turn", current_player)
						next_turn()
						# Special action complete
						state = STATE.NORMALPLAY_STATE

			elif(top_card.type == "wild"):
				match top_card.displayText:
					"WILD":#						
						if(not iscolor_picked):
							pick_color(true)#						
						else:
							state = STATE.NORMALPLAY_STATE
							iscolor_picked = false    # reset the var
				
		STATE.NORMALPLAY_STATE:
			if(play_turn()):
				next_turn()
				update_state()
			
		STATE.DRAW2_STATE:
			# Last played card is Draw2. Current player needs to draw 2 cards
			self.call(top_card.actionHandler)
			next_turn()
			update_state()
			
		STATE.SKIP_STATE:			
			# skip next player and return to normal state
#			next_turn()
			play_turn() # only update the ticker
#			last_event = EVENT.SKIP_CARD
			update_state()
			
		STATE.WILD_STATE:
			if(iscolor_picked):
				next_turn()
				state = STATE.NORMALPLAY_STATE
				iscolor_picked = false    # reset the var
			
		STATE.WARNING_STATE:
			# Player declared UNO (last card)
			pass
			
		STATE.ENDGAME_STATE:
			get_tree().get_root().set_disable_input(true)
			disable_hands()
			$DRAW.disabled = true
			$START.disabled = true
			
			
# Based on the top card, update state variable
func update_state():
	if(state == STATE.INIT_STATE):
		state = STATE.START_STATE
	elif(top_card.type == "number" or last_event == EVENT.DRAW_CARD):
		state = STATE.NORMALPLAY_STATE
	elif(top_card.type == "action"):
		match top_card.displayText:
			"+2":   # Draw 2 cards
				state = STATE.DRAW2_STATE
			"SKIP":
				if(last_event == EVENT.SKIP_CARD):
					state = STATE.NORMALPLAY_STATE
				else:
					state = STATE.SKIP_STATE
				
	elif(top_card.type == "wild" and last_event != EVENT.DRAW_CARD):
		match top_card.displayText:
			"WILD":
				iscolor_picked = false
				state = STATE.WILD_STATE
				
			"+4W":
				pass
	# Action card state to be updated NRN
	
func update_tickerinfo(msg, playerID):
	ticker_info[playerID].text = msg

func reset_tickerinfo():
	for num in range(players.size()):
		update_tickerinfo("", num)
	
#Play loop based on the player turn
func play_turn():
	var isPlayed = false  # True if card played or drawn. False when waiting for user pick
	if(state == STATE.SKIP_STATE):  # Add reverse as well
		update_tickerinfo("Skip Turn", PLAYER2)
		last_event = EVENT.SKIP_CARD
		isPlayed = true
		return
	
	match current_player:			
		PLAYER1:  # Need to enable button input for PLAYER 1
#			get_tree().get_root().set_disable_input(false)
			# if Top card is DRAW2, pick 2 cards
#			if((top_card.displayText == "DRAW2") and (last_event == PLAY_CARD)):
#				draw_card(2)    # Draw 2 cards
#				next_turn()     # Update Turn
#				play_turn()     # Continue game
#			# For other card types, Player to choose the card. 
			# Handler will do the rest			
			isPlayed = false
			
		PLAYER2:  #AI to pick card
			var index = pick_AICard()
			if(index >= 0):   # Found valid card to play				
					play_card(players[current_player].hand[index], true)
					isPlayed = true
#					if(check_turn_change()):        # Check Top card before turn change
#						next_turn()
									
					
			else:  # Did not find valid card
				draw_card()   # Draw a card				
				isPlayed = true
#				next_turn()   # Turn changes
#				play_turn()       # Continue game play
	return isPlayed
	
			
func draw2_handler():
	draw_card(2)
#	
# Update the Current player to next player
func next_turn():
	#Move to the next player
	prev_player = current_player
#	if(state == STATE.SKIP_STATE):
	if(top_card.displayText == "SKIP" and last_event == EVENT.PLAY_CARD):
		# Skip the next player in the turn
		current_player = (current_player + 2) % players.size()
	else:
		current_player = (current_player + 1) % players.size()
	
	if(current_player == PLAYER1):
		# enable button input for PLAYER 1
		get_tree().get_root().set_disable_input(false)
		$DRAW.disabled = false		
	else:
		get_tree().get_root().set_disable_input(true)
		$DRAW.disabled = true
		# Disable button input for PLAYER 1.
	
	
func draw_card(var num_card = 1):
	# Draw 1 or more cards from the deck and pull it into player hand
	if(deck.size() == 0):
		print("Deck size is 0")
		# Reshuffle the discard pile except for the top card
		top_card = discard_pile.pop_back()
		deck = discard_pile
		print("New Deck size: ", deck.size())
		shuffle_deck()
		discard_pile = [top_card]
	
	# Draw card and add it to the current player's hand
	var arr = []    # Array of cards drawn
	var card
	for num in range(num_card):
		card = deck.pop_back()
		arr.append(card)
	# Create the Button and ColorButton properties and attach to card
	attach_deck(arr, current_player)	 
	# create the new hand = arr + player hand
	arr.append_array(players[current_player].hand)
	players[current_player].hand = arr
	
#	var hand_len = players[current_player].hand.size()
#	print("Added cards: ", num_card)
#	print("Hand len: ", hand_len)
	
	#Update Ticker
	ticker_info[current_player].text = "Draw " + str(num_card)
	
	last_event = EVENT.DRAW_CARD     
	#Arrange player hand NRN
	arrange_hand(arr, current_player)

# Look for a valid card beginning at index.
func pick_AICard():
	var arr = players[current_player].hand	
	var found = -1
	for num in range(arr.size()):
		# Pick the first matching card for AI, unless its not wild card.
		if(validate_card(arr[num])):
			found = num
			if(arr[num].type != "wild"):
				return found
				# Found a non wild card. Return index
				# else continue to look through the hand
	return found	
	
# Match the Color, Numeric Value, similar action cards
func validate_card(card):
	# If the card is wild or +4W return true
	if(card.colorDesc == "Wild"):
		return true
		
	if((top_card.colorDesc == "Wild") and (card.colorDesc == current_color)):
		return true
		
	# Match the picked card color with color of the top card
	if(card.colorDesc == top_card.colorDesc):
		return true
	elif(card.type == "number" and top_card.type == "number"):
		#For numeric cards, check value
		if(card.value == top_card.value):
			return true
		else:
			return false
		
	# Check for action cards
	if((card.type == "action") and (top_card.type == "action")):
		# Both cards to have the same action
		if(card.displayText == top_card.displayText):
			return true
	return false
	
	# Match the card value for number card. 
#	if((card.value == WILDCARD) or (top_card.value == WILDCARD)):
#		return true		
#	# Match the number cards. make sure we do not compare value for action cards. All action cards
#	# have same value
#	if((card.type != "action") and (top_card.type != "action") and (card.value == top_card.value)):
#		return true
#
func play_card(card, flip_card=false):
	
	#Find index in player hand
	var index = find_handIndex(players[current_player].hand, card.cardID)	
	if(index >= 0):
		#Remove the index element from player hand
		players[current_player].hand.remove(index)
		
	var hand_len = players[current_player].hand.size()
	#Update the top card
	update_topcard(card, flip_card)
	if(hand_len >= 1):
		update_currentcolor(card)		
		# This action not required if the player played the last card
		
	#Update Ticker
	ticker_info[current_player].text = "Card: " + card.displayText + " " + current_color
	last_event = EVENT.PLAY_CARD	
#	print("Removed Index: ", index)
#	print("Hand len: ", hand_len)
		
	if(hand_len == 1):
		ticker_info[current_player].text = ticker_info[current_player].text + " UNO!"
#		
	if(hand_len == 0):
		ticker_info[current_player].text = ticker_info[current_player].text + " !! WINNER !!"
		end_game()
	
func end_game():
	# Want to start another game? TBD
	get_tree().get_root().set_disable_input(true)	
	popup_window.set_visible(true)
	
	#Set the Popup window label
	var popup_label = $PopUpWindow/LabelResult
	var winner_text
#	popup_label.text = ticker_info[current_player].text	
	if(current_player == PLAYER1):
		winner_text = "YOU WON!!"
	else:
		winner_text = "PLAYER " + str(current_player+1) + " WINNER!!"
	popup_label.text = winner_text + " Play again?"
	
	# Disable any further input
	state = STATE.ENDGAME_STATE
	
func disable_hands():
	for player in players:
		for card in player.hand:
			card.button.disabled = true

func find_handIndex(hand, cid):
	for num in range(hand.size()):
		if(hand[num].cardID == cid):
			return num
	return -1  # Invalid index. Element not found.
		
# Find the index of the card with given type (wild, action)
func find_cardIndex(hand, type):
	for num in range(hand.size()):
		if(hand[num].type == type):
			return num	

func initialize_colorpick_buttons():
	color_buttons.append($RButton)
	color_buttons.append($GButton)
	color_buttons.append($BButton)
	color_buttons.append($YButton)
	
# Debugging purpose. Displays the card in player hand
func show_hand(playerID):
	var p_hand = players[playerID].hand
	print("PLAYER ", playerID+1, " Hand: ")
	for num in range(p_hand.size()):
		print(p_hand[num].displayText + " " + p_hand[num].colorDesc)
	
# Debugging purpose. Add a specific type of card to player hand
func add_card(player_hand, type):
	# Find the card of given type from the deck
	var index = find_cardIndex(deck, type)
	var card = deck[index]
	# Remove the last card from player hand and swap it on the deck	
#	deck[index] = player_hand.pop_back()
	player_hand.push_back(card) # Adding card
	player_hand.pop_front()     # Remove a card
	deck.remove(index)
	
	
#Initialize all the cards and add them to the deck
func initialize_deck():
	var colourRGB
	var colorDesc
	var card
	for numdeck in range(NUM_DECK):
		for color in cardinfo.keys():
			for card_data in cardinfo[color].values():
				match color:
					"Red":
						colourRGB = Color(1,0,0,1)
						colorDesc = "Red"
						
					"Blue":
						colourRGB = Color(0,0,1,1)
						colorDesc = "Blue"
						
					"Green":
						colourRGB = Color(0,1,0,1)
						colorDesc = "Green"
						
					"Yellow":
						colourRGB = Color(0.84,0.85,0.14,1)
						colorDesc = "Yellow"
						
					"Wild":
						colourRGB = Color(1,1,1,1)
						colorDesc = "Wild"
						
				card = CardBase.new(cid, colorDesc, colourRGB, card_data[0], card_data[1], card_data[2], card_data[3])
				deck.append(card)
				cid = cid + 1                # Every card has unique card ID
#	print("cards in deck: ")
#	print(deck.size())
		
# Re-Initialize the main deck of cards using player hands and discard pile
func reinitialize_deck():
	for player in players:
		deck.append_array(player.hand)
		player.hand.clear()
		# Appended player hands and clear player hand.
	# Now append discard pile to deck
	deck.append_array(discard_pile)	
	discard_pile.clear()
		

#Shuffle the deck of cards
func shuffle_deck():	
	var rng = RandomNumberGenerator.new()
	rng.randomize()	
	for i in range(deck.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		swap(deck, i, j)
	
func swap(arr, indexA, indexB):
	var temp = arr[indexA]
	arr[indexA] = arr[indexB]
	arr[indexB] = temp

func create_players():
	var player1 = Player.new("Player 1", 1)
	var player2 = Player.new("Player 2", 2)
	players = [player1, player2]
	
func deal_cards():
	# Deal initial cards to players
	for player in players:
		for num in range(HAND_SIZE):
			var card = deck.pop_back()
			player.hand.append(card)
			
# Drawn cards needs button and color button to be created
# Creation of the Buttons, ColorRect and Labels happen here. 
func attach_deck(arr, curr_player):
	var button
	var colorButton
	var label
	var card
	var flipColor = Color(0.51, 0.54, 0.51,1)
	
	for num in range(arr.size()):
		card = arr[num]
		#Create the Button if does not exist
		if(is_instance_valid(card.button)):
			pass
		else:
			button = create_Button()   # Default pos and size
			card.button = button
		
		#Create the colorRect
		if(is_instance_valid(card.displayCard)):
			pass
		else:
			colorButton = create_colorButton(card.cardColor)
			card.displayCard = colorButton
			card.button.add_child(colorButton)
		
		#Create the Label
		if(is_instance_valid(card.label)):
			pass
		else:			
			label = create_label(card.displayText)            #Default size and position
			card.label = label
			colorButton.add_child(label)                             
		card.isVisible = false
		
		# Player2 has flipped cards. Hide the Label
		if(curr_player == PLAYER2):
			card.label.visible = false   
			# This should be visible only when played	
	
var width = 100 #Width of each card
var gap = 15    # Gap between each card
var cardScale   # Scale value for the cards, when hand is more then 8 cards
var flipColor = Color(0.51, 0.54, 0.51,1)  # Grey Color
# Arrange all the cards in player hand. Set their positions and display in hand
func arrange_hand(player_hand, curr_player):
	var hand_size = player_hand.size()
	var card
	# Start position  PLAYER1       PLAYER2
	var pos = [Vector2(-50, 450), Vector2(-50, 0)]	
	var vectorScale    # Scale cards
	if(hand_size > 10):   # Apply scale of 0.6
		cardScale = 0.6
		vectorScale = Vector2(0.6,0.6)	
	elif(hand_size >= 8):   # Apply scale of 0.8		
		cardScale = 0.8
		vectorScale = Vector2(0.8,0.8)
	else:
		cardScale = 1
		vectorScale = Vector2(1,1)
		
	# Set card position 
	for num in range(hand_size):
		card = players[curr_player].hand[num]
		pos[curr_player] = pos[curr_player] + Vector2(((width * cardScale) + gap), 0)
		card.button.rect_position = pos[curr_player]
		card.button.rect_scale = vectorScale
		if(curr_player == PLAYER1):
			card.displayCard.color = card.cardColor
			card.button.connect("pressed", self, "_button_pressed", [card])
#			print("arrange_hand: Card " + str(num+1) + " Value: " + card.displayText, pos)
		else:
			card.displayCard.color = flipColor
			
		if(not card.isVisible):
			add_child(card.button)
			card.isVisible = true
		card.button.set_visible(true)

# Setup/Arrange the hands for the first time
func setup_hands():
	var num_hands = players.size()	
	for num in range(num_hands):
		attach_deck(players[num].hand, num)
		arrange_hand(players[num].hand, num)
		
		
func find_string(arr, text):
	var arrLen = arr.size()
	for num in range(arrLen):
		if(arr[num].displayText == text):
			return num
	return -1   # String not found

# Top card on the discard pile 
var top_card_pos = Vector2(440, 230)
func setup_topcard():
	#Test code
#	var index
#	index = find_string(deck, "SKIP")
#	top_card = deck[index]
#	deck.remove(index)
#	discard_pile.append(top_card)
	
	# Start the game by placing the top card of the deck on the discard pile
	top_card = deck.pop_back()
	discard_pile.append(top_card)
	
	var button
	var colorButton # ColorRect
	var label
	var labelSize = Vector2(100, 25)
	var labelPos = Vector2(0, 55)
	# Create colorRect and Label for top_card if not done
	if(not top_card.isVisible):
		if(not is_instance_valid(top_card.button)):
			button = create_Button(top_card_pos)   # Default size
			top_card.button = button
			add_child(top_card.button)
		
		if(not is_instance_valid(top_card.displayCard)):
			colorButton = create_colorButton(top_card.cardColor, top_card_pos, Vector2(100, 150))			
			top_card.displayCard = colorButton
			top_card.button.add_child(colorButton)
		
		if(not is_instance_valid(top_card.label)):
			label = create_label(top_card.displayText, labelSize, labelPos)
			top_card.displayCard.add_child(label)
			top_card.label = label
#			add_child(top_card.button)
			
		
		top_card.button.set_visible(true)
#		top_card.displayCard.set_visible(true)
		top_card.isVisible = true     # Mark the card visible
		
		
# Update the topcard on discard pile. Flip the card when bool is true.
func update_topcard(card, flip_card=false):
	# print the matching cards
	print("Match - TopCard :", top_card.displayText, top_card.colorDesc, " Card: ", card.displayText, card.colorDesc)
	var last_top = top_card
	discard_pile.pop_back()
	last_top.isVisible = false
	# NRN check
	if(is_instance_valid(last_top.button)):
		remove_child(last_top.button)
	else:
		remove_child(last_top.displayCard)
#
	top_card = card
	discard_pile.append(top_card)
	
	if(flip_card):
		top_card.displayCard.color = top_card.cardColor
		
	top_card.button.rect_position = top_card_pos
	top_card.button.set_visible(true)
	top_card.label.visible = true
	#Disconnect the button signal		
	top_card.button.disconnect("pressed", self, "_button_pressed")#	
	top_card.isVisible = true
	
func update_currentcolor(card):	
	if(card.type == "wild"):
		if(current_player == PLAYER1):
			iscolor_picked = false
			pick_color(true)
		else:
			pick_AI_color()
	else:
		current_color = card.colorDesc
	
# Display the 4 colored buttons for player to choose color
func pick_color(val):
	for num in range(color_buttons.size()):
		color_buttons[num].set_visible(val)

# pick a random color for AI
func pick_AI_color():	
	#Below colors need to be consistent with available colors
	var colors = {"Red": 0, "Blue": 0, "Green": 0, "Yellow": 0}
	var arr = players[PLAYER2].hand
	for num in range(arr.size()):
		print("Color Desc: " + arr[num].colorDesc + " " + arr[num].displayText)
		if(arr[num].colorDesc != "Wild"):
			colors[arr[num].colorDesc] = colors[arr[num].colorDesc] + 1
	print("Color Dict: ", colors)
	
	var color_picked
	var max_occurance = 0
#	for num in range(colors.size()):
#		if((arr[num].colorDesc != "Wild") and (colors[arr[num].colorDesc] > max_occurance)):
#			max_occurance = colors[arr[num].colorDesc]
			
	for color in colors.keys():
		if(colors[color] > max_occurance):
			max_occurance = colors[color]
			color_picked = color
		
#	color_picked = find_key(colors, max_occurance)
#	print("pick_AI_color: " + color_picked)
	current_color = color_picked	
		
# Returns the key for a value in dictionary
func find_key(temp_dictonary, val):
	var keys = temp_dictonary.keys()
	var values = temp_dictonary.values()
	var key_index = values.find(val)	
	var key = keys[key_index]
	return key

func _color_pressed():
	print("color_pressed reached")
	
func create_Button(position = Vector2(0,0), size = Vector2(100, 150)):
	button = Button.new()
	button.rect_min_size = size
	button.rect_position = position
	return button

func create_colorButton(color, position = Vector2(0,0), size = Vector2(100, 150)):
	var colorButton = ColorRect.new()
	colorButton.rect_min_size = size
	colorButton.rect_position = position
	colorButton.color = color
	colorButton.mouse_filter = Control.MOUSE_FILTER_PASS
	return colorButton
	
func create_label(text, size = Vector2(100, 25), position = Vector2(0, 55)):
	var label = Label.new()
	label.rect_min_size = size
	label.rect_position = position
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	label.set("custom_fonts/font", dynamic_font)
	label.set("custom_colors/font_color", Color(0,0,0))
	label.text = text
	return label
	
#Draw button pressed event
func _on_Button_pressed(): 
	draw_card()
	next_turn()           #Update the player turn
	update_state()

func _on_START_pressed():
	$DRAW.disabled = false
	$START.disabled = true
	
	# Randomize / Get the start from user?
	# Set player turn
	current_player = PLAYER1
	ticker_info[current_player].text = "Turn"
	# Update state variable
	update_state()
#	state = STATE.START_STATE
#	play_turn()	


func _on_RButton_pressed():
	current_color = "Red"
	iscolor_picked = true
	pick_color(false)
	print("color_pressed Red")
	
func _on_GButton_pressed():
	current_color = "Green"
	iscolor_picked = true
	pick_color(false)
	print("color_pressed Green")

func _on_BButton_pressed():
	current_color = "Blue"
	iscolor_picked = true
	pick_color(false)
	print("color_pressed Blue")

func _on_YButton_pressed():
	current_color = "Yellow"
	iscolor_picked = true
	pick_color(false)
	print("color_pressed Yellow")

# Restart the game with a freshly shuffled deck
func _on_YesButton_pressed():
	reinitialize_deck()
	shuffle_deck()
	deal_cards()	
	setup_hands()	
	setup_topcard()
	reset_tickerinfo()
	
	# Hide the pop-up window
	popup_window.set_visible(false)
	
	# Update state
	state = STATE.INIT_STATE
