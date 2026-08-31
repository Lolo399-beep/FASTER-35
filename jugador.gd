extends CharacterBody2D

# Variables ajustables desde el inspector de Godot
@export var velocidad : float = 200.0
@export var fuerza_salto : float = -400.0

# Obtiene la gravedad configurada por defecto en Godot
var gravedad : float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# 1. Aplicar gravedad si el personaje está en el aire
	if not is_on_floor():
		velocity.y += gravedad * delta

	# 2. Controlar el Salto (usa la barra espaciadora o la flecha arriba por defecto)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = fuerza_salto

	# 3. Controlar movimiento horizontal (Flechas Izquierda / Derecha)
	var direccion := Input.get_axis("ui_left", "ui_right")
	if direccion:
		velocity.x = direccion * velocidad
	else:
		# Frena al personaje suavemente cuando dejas de presionar
		velocity.x = move_toward(velocity.x, 0, velocidad)

	# 4. Ejecutar el movimiento y activar las físicas de colisión
	move_and_slide()
