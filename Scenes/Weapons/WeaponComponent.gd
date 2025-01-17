extends Node2D
class_name WeaponComponent

# Export Variables
@export var bullet_fire_rate: float = 0.25  # Seconds between shots
@export var missile_launch_rate: float = 7.0  # Seconds between shots
@export var bomb_drop_rate: float = 1.5  # Seconds between shots
@export var max_bomb_inventory: int = 5
@export var bomb_inventory: int = max_bomb_inventory

# Timers
@onready var bullet_timer: Timer = Timer.new()
@onready var bomb_timer: Timer = Timer.new()
@onready var missile_timer: Timer = Timer.new()

# Scenes
@onready var bullet_scene: PackedScene = preload("res://Scenes/Weapons/Projectiles/BulletComponent.tscn")
@onready var bomb_scene: PackedScene = preload("res://Scenes/Weapons/Projectiles/BombComponent.tscn")
@onready var missile_scene: PackedScene = preload("res://Scenes/Weapons/Projectiles/MissileComponent.tscn")

# Components
@onready var muzzle_flash: AnimationPlayer = $MuzzleFlash

# Signals
signal bomb_inventory_change(new_bomb_inventory: int)

# Constants
const TIMER_CONFIG: Dictionary = {
    "bullet": {"one_shot": true}, "bomb": {"one_shot": true}, "missile": {"one_shot": true}
}


func _init() -> void:
    # Initialize non-node dependent properties
    self.set_process(false)


func _ready() -> void:
    self._initialize_timers()
    self.set_process(true)


func _initialize_timers() -> void:
    # Initialize bullet timer
    self._configure_timer(self.bullet_timer, self.bullet_fire_rate, TIMER_CONFIG.bullet.one_shot)

    # Initialize bomb timer
    self._configure_timer(self.bomb_timer, self.bomb_drop_rate, TIMER_CONFIG.bomb.one_shot)

    # Initialize missile timer
    self._configure_timer(
        self.missile_timer, self.missile_launch_rate, TIMER_CONFIG.missile.one_shot
    )


func _configure_timer(timer: Timer, wait_time: float, one_shot: bool) -> void:
    timer.wait_time = wait_time
    timer.one_shot = one_shot
    self.add_child(timer)


func release_projectile(
    shooter: Node, start_position: Vector2, type: ProjectileType.TYPE, direction: Vector2
) -> void:
    match type:
        ProjectileType.TYPE.BULLET:
            if self.bullet_timer.time_left == 0:  #TODO: I really don tlike this timer
                self.fire_bullet(shooter, start_position, direction)
                self.bullet_timer.start()
        ProjectileType.TYPE.DOUBLE_BULLET:
            if self.bullet_timer.time_left == 0:
                var left_barrel_position: Vector2 = start_position
                left_barrel_position.x -= 10
                var right_barrel_position: Vector2 = start_position
                right_barrel_position.x += 10
                self.fire_bullet(shooter, left_barrel_position, direction)
                self.fire_bullet(shooter, right_barrel_position, direction)
                self.bullet_timer.start()
        ProjectileType.TYPE.BOMB:
            self.drop_bomb(shooter, start_position, direction)
        ProjectileType.TYPE.MISSILE:
            self.launch_missile(shooter, start_position, direction)
        ProjectileType.TYPE.BOSS_BULLET:
            # Implement boss bullet firing logic
            pass
        ProjectileType.TYPE.BOSS_MISSILE:
            # Implement boss missile launching logic
            pass


#TODO: fix this to allow Multiple ProjectileTypes to be released
func release_projectiles_plural(
    shooter: Node,
    start_position: Vector2,
    projectiles: Array[ProjectileType.TYPE],
    direction: Vector2
) -> void:
    var positions: Array[Vector2] = calculate_starting_positions(
        start_position, projectiles.size(), 10
    )  # 10 is the spread amount

    # Check timers before firing
    var can_fire_bullet: bool = self.bullet_timer.time_left == 0
    var can_drop_bomb: bool = self.bomb_timer.time_left == 0
    var can_launch_missile: bool = self.missile_timer.time_left == 0

    for i: int in range(projectiles.size()):
        var type: ProjectileType.TYPE = projectiles[i]
        var pos: Vector2 = positions[i]

        match type:
            ProjectileType.TYPE.BULLET:
                if can_fire_bullet:
                    self.fire_bullet(shooter, pos, direction)
            ProjectileType.TYPE.BOMB:
                if can_drop_bomb:
                    self.drop_bomb(shooter, pos, direction)
            ProjectileType.TYPE.MISSILE:
                if can_launch_missile:
                    self.launch_missile(shooter, pos, direction)
            ProjectileType.TYPE.BOSS_BULLET:
                # Implement boss bullet firing logic
                pass
            ProjectileType.TYPE.BOSS_MISSILE:
                # Implement boss missile launching logic
                pass

    if can_fire_bullet:
        self.bullet_timer.start()
    if can_drop_bomb:
        self.bomb_timer.start()
    if can_launch_missile:
        self.missile_timer.start()


func calculate_starting_positions(
    center_position: Vector2, num_projectiles: int, spread: float
) -> Array:
    var positions: Array[Vector2] = []
    if num_projectiles == 1:
        positions.append(center_position)
    else:
        for i: int in range(num_projectiles):
            var offset: float = spread * (i - (num_projectiles - 1) / 2.0)
            var pos: Vector2 = center_position + Vector2(offset, 0)
            positions.append(pos)
    return positions


func fire_bullet(shooter: Node, start_position: Vector2, direction: Vector2) -> void:
    self.muzzle_flash.play("MuzzleFlashAnimation")
    var new_bullet: BulletComponent = self._instantiate_projectile(
        self.bullet_scene, shooter, start_position, direction
    )
    self._add_projectile_to_scene(new_bullet)


func drop_bomb(shooter: Node, start_position: Vector2, direction: Vector2) -> void:
    if self.bomb_inventory == 0:
        return
    if self.bomb_timer.time_left == 0:
        var bomb: BombComponent = self._instantiate_projectile(
            self.bomb_scene, shooter, start_position, direction
        )
        self._add_projectile_to_scene(bomb)
        self._update_bomb_inventory()
        self.bomb_timer.start()


func launch_missile(shooter: Node, start_position: Vector2, direction: Vector2) -> void:
    if self.missile_timer.time_left == 0:
        var missile: MissileComponent = self._instantiate_projectile(
            self.missile_scene, shooter, start_position, direction
        )
        self._add_projectile_to_scene(missile)
        self.missile_timer.start()


func _instantiate_projectile(
    scene: PackedScene, shooter: Node, start_position: Vector2, direction: Vector2
) -> Node:
    var projectile: Node = scene.instantiate()
    projectile.ownerr = shooter  #TODO: fix this garbage with a proper Projectile type
    projectile.direction = direction
    # THIS NEXT LINE NEEDS TO HAPPEN I GUESS BECAUSE THE CURRENT SCENE DOESNT KNOW WHERE TO PUT IT!!!!!
    projectile.position = start_position
    return projectile


func _add_projectile_to_scene(projectile: Node) -> void:
    # Add to main scene to prevent inheriting transforms of parent
    self.get_tree().current_scene.add_child(projectile)


func _update_bomb_inventory() -> void:
    self.bomb_inventory -= 1
    self.bomb_inventory_change.emit(self.bomb_inventory)


# Getters/Setters
func get_bomb_inventory() -> int:
    return self.bomb_inventory


func set_bomb_inventory(value: int) -> void:
    self.bomb_inventory = value
    self.bomb_inventory_change.emit(self.bomb_inventory)


func get_max_bomb_inventory() -> int:
    return self.max_bomb_inventory
