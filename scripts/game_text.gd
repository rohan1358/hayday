class_name GameText
extends RefCounted


static func format_number(number: int) -> String:
	var value := str(number)
	var formatted := ""
	for i in value.length():
		if i > 0 and (value.length() - i) % 3 == 0:
			formatted += "."
		formatted += value[i]
	return formatted
