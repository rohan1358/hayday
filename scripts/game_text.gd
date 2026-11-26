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


static func format_compact(number: int,threshold: int=10000) -> String:
	if absi(number)<threshold: return format_number(number)
	for unit in [[1000000000," M"],[1000000," jt"],[1000," rb"]]:
		if absi(number)>=int(unit[0]): return String.num(float(number)/int(unit[0]),1).trim_suffix(".0")+str(unit[1])
	return format_number(number)

static func format_hud_currency(number: int) -> String:
	if absi(number) < 10000: return format_number(number)
	if absi(number) < 1000000:
		return str(roundi(float(number) / 1000.0)) + "rb" if absi(number) >= 100000 else String.num(float(number) / 1000.0, 1).trim_suffix(".0") + "rb"
	return String.num(float(number) / 1000000.0, 1).trim_suffix(".0") + "jt"
