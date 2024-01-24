# Card Database

# Card Types: Numeric Cards, Action Cards and Wild Cards
enum {Zero, One, Two, Three, Four, Five, Six, Seven, Eight, Nine, Skip, DrawTwo, Reverse, Wild, WildDrawFour}

# Card details
# [Type, Value, DisplayText, ActionHandler]
const card_data = {
	"Red" : {
		0: ["number", 0, "0", "NONE"],
		1: ["number", 1, "1", "NONE"],
		2: ["number", 2, "2", "NONE"],
		3: ["number", 3, "3", "NONE"],
		4: ["number", 4, "4", "NONE"],
		5: ["number", 5, "5", "NONE"],
		6: ["number", 6, "6", "NONE"],
		7: ["number", 7, "7", "NONE"],
		8: ["number", 8, "8", "NONE"],
		9: ["number", 9, "9", "NONE"],
		10: ["action", 20, "+2", "draw2_handler"],
		11: ["action", 20, "SKIP", "NONE"],
#		12: ["action", 20, "REVERSE"],
	},
	
	"Blue" : {
		0: ["number", 0, "0", "NONE"],
		1: ["number", 1, "1", "NONE"],
		2: ["number", 2, "2", "NONE"],
		3: ["number", 3, "3", "NONE"],
		4: ["number", 4, "4", "NONE"],
		5: ["number", 5, "5", "NONE"],
		6: ["number", 6, "6", "NONE"],
		7: ["number", 7, "7", "NONE"],
		8: ["number", 8, "8", "NONE"],
		9: ["number", 9, "9", "NONE"],
		10: ["action", 20, "+2", "draw2_handler"],
		11: ["action", 20, "SKIP", "NONE"],
#		12: ["action", 20, "REVERSE"],
	},
	
	"Green" : {
		0: ["number", 0, "0", "NONE"],
		1: ["number", 1, "1", "NONE"],
		2: ["number", 2, "2", "NONE"],
		3: ["number", 3, "3", "NONE"],
		4: ["number", 4, "4", "NONE"],
		5: ["number", 5, "5", "NONE"],
		6: ["number", 6, "6", "NONE"],
		7: ["number", 7, "7", "NONE"],
		8: ["number", 8, "8", "NONE"],
		9: ["number", 9, "9", "NONE"],
		10: ["action", 20, "+2", "draw2_handler"],
		11: ["action", 20, "SKIP", "NONE"],
#		12: ["action", 20, "REVERSE"],
	},
	
	"Yellow" : {
		0: ["number", 0, "0", "NONE"],
		1: ["number", 1, "1", "NONE"],
		2: ["number", 2, "2", "NONE"],
		3: ["number", 3, "3", "NONE"],
		4: ["number", 4, "4", "NONE"],
		5: ["number", 5, "5", "NONE"],
		6: ["number", 6, "6", "NONE"],
		7: ["number", 7, "7", "NONE"],
		8: ["number", 8, "8", "NONE"],
		9: ["number", 9, "9", "NONE"],
		10: ["action", 20, "+2", "draw2_handler"],
		11: ["action", 20, "SKIP", "NONE"],
#		12: ["action", 20, "REVE"],
	},
	
	"Wild" : {
		13: ["wild", 50, "WILD", "NONE"],
		14: ["wild", 50, "WILD", "NONE"],
#		15: ["wild", 50, "+4W", "NONE"],
	},
}

