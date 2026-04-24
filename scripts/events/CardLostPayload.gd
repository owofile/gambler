class_name CardLostPayload
extends RefCounted

var instance_id: String
var prototype_id: String

func _init(p_instance_id: String = "", p_proto_id: String = "") -> void:
	instance_id = p_instance_id
	prototype_id = p_proto_id