extends Control

var texture: Texture2D = null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw():
	if texture == null:
		return
	var tex_size = Vector2(texture.get_width(), texture.get_height())
	var scale = min(size.x / tex_size.x, size.y / tex_size.y)
	var draw_size = tex_size * scale
	var offset = (size - draw_size) / 2.0
	draw_texture_rect(texture, Rect2(offset, draw_size), false)
