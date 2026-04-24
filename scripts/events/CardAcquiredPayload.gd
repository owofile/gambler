class_name CardAcquiredPayload
extends RefCounted

var prototype_id: String
var instance_id: String

func _init(p_proto_id: String = "", p_instance_id: String = "") -> void:
	prototype_id = p_proto_id
	instance_id = p_instance_id