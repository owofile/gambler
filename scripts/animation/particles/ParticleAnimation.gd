## 粒子动画
##
## 根据数量生成粒子效果
class_name ParticleAnimation
extends BaseAnimation

var _spawned_nodes: Array = []

func _init():
	_animation_name = "Particle"

func play(config: Dictionary, on_complete: Callable) -> void:
	super.play(config)
	var target = config.get("target", null)
	var particle_count = config.get("particle_count", 10)
	var particle_scene = config.get("particle_scene", "")
	var spawn_position = config.get("spawn_position", Vector2.ZERO)
	var direction = config.get("direction", Vector2.RIGHT)
	var spread = config.get("spread", 30.0)
	var color = config.get("color", Color.WHITE)
	var particle_lifetime = config.get("lifetime", 1.0)

	if not target:
		target = get_parent()

	if not target:
		_on_complete.call()
		return

	set_target(target)
	_spawned_nodes.clear()

	for i in range(particle_count):
		var particle: Node2D
		if particle_scene != "" and ResourceLoader.exists(particle_scene):
			var res = load(particle_scene)
			if res:
				particle = res.instantiate()
		else:
			particle = _create_default_particle(color)

		if particle:
			particle.global_position = spawn_position
			particle.modulate = color
			target.add_child(particle)
			_spawned_nodes.append(particle)

			var offset = Vector2(randf() * spread - spread/2, randf() * spread - spread/2)
			var target_pos = spawn_position + direction * 200 + offset
			var tween = particle.create_tween()
			tween.set_parallel(true)
			tween.tween_property(particle, "position", target_pos, particle_lifetime)
			tween.tween_property(particle, "modulate:a", 0.0, particle_lifetime * 0.5)
			tween.chain().tween_callback(func(): _remove_particle(particle))

	var timer = _create_timer(particle_lifetime + 0.1)
	timer.start()

func _create_default_particle(color: Color) -> Node2D:
	var circle = ColorRect.new()
	circle.size = Vector2(8, 8)
	circle.color = color
	return circle

func _remove_particle(particle: Node) -> void:
	if particle in _spawned_nodes:
		_spawned_nodes.erase(particle)
		particle.queue_free()

func stop() -> void:
	super.stop()
	for node in _spawned_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_spawned_nodes.clear()
