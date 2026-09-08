extends CharacterBody2D

# --- REFERENCIAS A LAS LLANTAS ---
@onready var llanta1: Sprite2D = $Sprite2D/llanta1
@onready var llanta2: Sprite2D = $Sprite2D/llanta2

# --- PARÁMETROS VISUALES ---
@export var multiplicador_rotacion_llantas: float = 0.05 

# --- PARÁMETROS DE VIDA ---
@export var puntos_de_vida: int = 5

# --- PARÁMETROS DE VELOCIDAD ---
@export var velocidad_normal: float = 800.0
@export var velocidad_turbo: float = 1600.0
# Se eliminó "velocidad_lenta" porque ya no se usará

# --- PARÁMETROS DE ENERGÍA ---
@export var energia_maxima: float = 100.0
var energia_actual: float = energia_maxima
var agotado: bool = false
var puede_recargar: bool = true
var timer_recarga: Timer

# --- PARÁMETROS DE SALTO ---
@export var fuerza_salto: float = -450.0
var saltos_realizados: int = 0
var max_saltos: int = 3

# --- PARÁMETROS DE INCLINACIÓN ---
@export var velocidad_rotacion: float = 4.0
@export var limite_inclinacion_grados: float = 45.0 

# Obtenemos la gravedad de la configuración del proyecto
var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	# Configuramos el temporizador de castigo (1.5 segundos) dinámicamente
	timer_recarga = Timer.new()
	timer_recarga.wait_time = 1.5
	timer_recarga.one_shot = true
	timer_recarga.timeout.connect(_on_timer_recarga_timeout)
	add_child(timer_recarga)

func _physics_process(delta: float) -> void:
	# 1. GRAVEDAD Y REINICIO DE SALTOS
	if not is_on_floor():
		velocity.y += gravedad * delta
	else:
		saltos_realizados = 0

	# 2. TRIPLE SALTO
	if Input.is_action_just_pressed("ui_accept"):
		if saltos_realizados < max_saltos:
			velocity.y = fuerza_salto
			saltos_realizados += 1

	# 3. INCLINACIÓN DEL AUTO
	var direccion_inclinacion = Input.get_axis("ui_up", "ui_down")
	rotation += direccion_inclinacion * velocidad_rotacion * delta
	
	# Limitamos la rotación
	var limite_rad = deg_to_rad(limite_inclinacion_grados)
	rotation = clamp(rotation, -limite_rad, limite_rad)

	# 4. SISTEMA DE VELOCIDAD Y TURBO (Shift)
	var velocidad_actual = velocidad_normal
	var usando_turbo = Input.is_physical_key_pressed(KEY_SHIFT)

	if agotado:
		# MODIFICACIÓN: En lugar de "velocidad_lenta", el auto mantiene su velocidad base
		velocidad_actual = velocidad_normal 
	elif usando_turbo and energia_actual > 0:
		velocidad_actual = velocidad_turbo
		energia_actual -= 60.0 * delta # Gasta la energía
		
		if energia_actual <= 0:
			energia_actual = 0
			agotado = true
			puede_recargar = false
			timer_recarga.start()
	else:
		velocidad_actual = velocidad_normal
		
		if puede_recargar and energia_actual < energia_maxima:
			energia_actual += 40.0 * delta
			if energia_actual > energia_maxima:
				energia_actual = energia_maxima

	# 5. MOVIMIENTO
	var input_derecha = Input.get_action_strength("ui_right")
	var direccion_auto = Vector2(cos(rotation), sin(rotation))

	if input_derecha > 0:
		# Movimiento horizontal en X
		velocity.x = direccion_auto.x * velocidad_actual * input_derecha
		
		# EMPUJE DEL PROPULSOR EN Y
		if usando_turbo and not agotado:
			velocity.y += direccion_auto.y * velocidad_actual * delta * 2.0
		else:
			velocity.y += direccion_auto.y * (velocidad_actual * 0.5) * delta
	else:
		# Fricción horizontal si se suelta el acelerador
		velocity.x = move_toward(velocity.x, 0, velocidad_normal)

	# 6. ROTACIÓN DE LAS LLANTAS
	llanta1.rotation += velocity.x * multiplicador_rotacion_llantas * delta
	llanta2.rotation += velocity.x * multiplicador_rotacion_llantas * delta

	move_and_slide()

# Función que se ejecuta cuando pasan los 1.5 segundos sin energía
func _on_timer_recarga_timeout() -> void:
	agotado = false
	puede_recargar = true

# Función extra para manejar el daño
func recibir_dano(cantidad: int) -> void:
	puntos_de_vida -= cantidad
	if puntos_de_vida <= 0:
		print("El auto ha sido destruido")
