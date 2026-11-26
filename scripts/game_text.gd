class_name GameText
extends RefCounted

const LANG = preload("res://scripts/garden_language.gd")


static func format_number(number: int) -> String:
	var value := str(number).trim_prefix("-")
	var formatted := "-" if number < 0 else ""
	var separator := "," if LANG.locale == "en" else "."
	for i in value.length():
		if i > 0 and (value.length() - i) % 3 == 0:
			formatted += separator
		formatted += value[i]
	return formatted


static func decimal(value: float) -> String:
	var result := String.num(value, 1).trim_suffix(".0")
	return result if LANG.locale == "en" else result.replace(".", ",")


static func format_compact(number: int, threshold: int = 10000) -> String:
	if absi(number) < threshold:
		return format_number(number)
	var units := [[1000000000, "B"], [1000000, "M"], [1000, "K"]] if LANG.locale == "en" else [[1000000000, " M"], [1000000, " jt"], [1000, " rb"]]
	for unit in units:
		if absi(number) >= int(unit[0]):
			return decimal(float(number) / int(unit[0])) + str(unit[1])
	return format_number(number)


static func format_hud_currency(number: int) -> String:
	if absi(number) < 10000:
		return format_number(number)
	if absi(number) < 1000000:
		var suffix := "K" if LANG.locale == "en" else "rb"
		return str(roundi(float(number) / 1000.0)) + suffix if absi(number) >= 100000 else decimal(float(number) / 1000.0) + suffix
	return decimal(float(number) / 1000000.0) + ("M" if LANG.locale == "en" else "jt")
