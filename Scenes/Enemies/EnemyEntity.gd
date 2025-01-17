extends CharacterBody2D
class_name EnemyEntity

# Components
@onready var health: HealthComponent = $HealthComponent
@onready var weapon: WeaponComponent = $WeaponComponent
@onready var upgrade_component: UpgradeComponent = $UpgradeComponent
@onready var visibility: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D

# Export variables
# THIS enemy_level GETS SET IN THE SPAWNER!!!!!!!!!!! AHHHHHHHHHHHHHHHH
@export var enemy_level: int = 0
@export var path_speed: float = 0.0  # Speed along the path

# Constants
const BASE_POINTS: int = 100
const PROJECTILE_DIRECTION: Vector2 = Vector2.DOWN

# Signals
signal give_points(points: int)  #TODO: figure out how to maybe make this have effect on the Upgrade logic of the PlayerEntity

# Properties
var points: int = BASE_POINTS


func _ready() -> void:
    self._initialize()
    self._setup_signals()


func _setup_signals() -> void:
    self.upgrade_component.active_explosion_animation.animation_finished.connect(
        _on_animation_finished
    )
    self.health.entity_died.connect(_death)
    #TODO: EWWWWW NOOOOOOOOO figure out how to get the boss to not fuck up here...
    #self.visibility.screen_exited.connect(queue_free)


func _initialize() -> void:
    self.health.set_current_health(1)
    # Configure upgrade component
    self.upgrade_component.current_upgrade_index = self.enemy_level  # THIS GETS SET IN THE SPAWNER!!!!!!!!!!! AHHHHHHHHHHHHHHHH
    #TODO: this requirement of .update() to be called proves that @onready calls the _ready() of
    # the upgrade_component before this classes _ready() func is called!!!!!!!!
    #TODO: update() relies on the`upgrade_component.current_upgrade_index` being set first and thats STUPID AND MISLEADING
    self.upgrade_component._update_upgrade()

    # Set up collision
    var collision_shape: CollisionShape2D = self.upgrade_component.active_collision_shape
    self.add_child(collision_shape)

    # Configure speed
    self.path_speed = self.upgrade_component.active_speed  #TODO: this seems sloppy, not sure where to best control speed yet


func _process(_delta: float) -> void:
    #TODO: figure out how to rotate the Enemy????? (maybe just the weapon? as the rotation changes on the path
    self.weapon.release_projectile(
        self, self.global_position, upgrade_component.active_projectiles[0], PROJECTILE_DIRECTION
    )


func _death() -> void:
    self.health.entity_died.disconnect(_death)  # TODO: is this the only way to prevent the signal from occuring more than once??? seems wack
    self.upgrade_component.active_explosion_sprite.visible = true
    self.upgrade_component.active_explosion_animation.play("Explosion")


func take_damage(damage: int) -> void:
    self.health.take_damage(damage)


#TODO: OVERWRITABLE??
func _on_animation_finished(anim_name: String) -> void:
    if anim_name == "Explosion":
        GameStatsManager.score += self.points
        self.give_points.emit(self.points)
        self.queue_free()


# Getters/Setters
func get_points() -> int:
    return self.points


func set_points(value: int) -> void:
    self.points = value
