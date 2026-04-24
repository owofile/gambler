class_name UUID
extends RefCounted

static func v4() -> String:
	var bytes: Array[int] = []
	for i in 16:
		bytes.append(randi() % 256)
	bytes[6] = (bytes[6] & 0x0F) | 0x40
	bytes[8] = (bytes[8] & 0x3F) | 0x80
	var hex_chars := "0123456789abcdef"
	var result := ""
	for i in range(16):
		if i == 4 or i == 6 or i == 8 or i == 10:
			result += "-"
		result += hex_chars[bytes[i] >> 4]
		result += hex_chars[bytes[i] & 0x0F]
	return result
