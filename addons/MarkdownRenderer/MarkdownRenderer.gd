@icon("res://addons/MarkdownRenderer/IconMarkdown.svg")
extends Control
class_name MarkdownRenderer

@export_file(".md") var markdown_file
@export var _theme:Theme
@export_color_no_alpha var background_color:Color = Color("#333333")

@onready var _default_theme:Theme = preload("res://addons/MarkdownRenderer/markdown_default.theme")
var _bg:ColorRect
var _base_font_size:int
var _wrap_scroll_container:ScrollContainer
var _container:VBoxContainer
var _comp:Dictionary = {
	"p"		: null,
	"hr"	: null
}

# Define RegEx Patterns
var patterns:Dictionary = {
	"h1" : "(\n# |^# )(?<letter>.+)$",
	"h2" : "(\n## |^## )(?<letter>.+)$",
	"h3" : "(\n### |^### )(?<letter>.+)$",
	"h4" : "(\n#### |^#### )(?<letter>.+)$",
	"h5" : "(\n##### |^##### )(?<letter>.+)$",
	"h6" : "(\n###### |^###### )(?<letter>.+)$",
	"code": "(!<?`)*`(.+?)`",
	"bold": "\\*(?<letter>.*)\\*",
	"strong": "\\*\\*(?<letter>.*)\\*\\*",
	"si": "~~(.*)~~",
	"link": "(?<!\\!)\\[(.*)\\]\\((.*)\\)",
	"image": "\\!\\[(.*)\\]\\((.+)\\)",
	"hr": "^---+",
	"code-block": "```(?<letter>.*)\n(.*)\n```",
	"quote": "(\n>|^>) (.*)",
	"num-list": "(^|\n)[0-9]\\. "
}

func _ready():
	_setup_comp()
	_parse(markdown_file)
	
func _parse(_md_path:String):
	var _md:String = FileAccess.get_file_as_string(_md_path)
	var _blocks:Array = _md.split("\n\n", false)
	
	for _line in _blocks:
#		print(_line.c_escape())
		var _regex:RegEx = RegEx.new()
		
		## 水平線
		_regex.compile(patterns["hr"])
		if _regex.search(_line):
			var _hr = _get_component("hr")
			_container.add_child(_hr)
			continue
		
		# コードブロック
		_regex.compile(patterns["code-block"])
		if _regex.search(_line):
			_line = _regex.sub(_line, "$2")
			var _cb = _get_component("p")
			_cb.text = _line
			_cb.theme_type_variation = "CodeBlock"
			var _mb:MarginContainer = MarginContainer.new()
			_mb.layout_mode = 1
			_mb.anchors_preset = PRESET_FULL_RECT
			_mb.size_flags_horizontal = SIZE_EXPAND_FILL
			_mb.size_flags_vertical = SIZE_EXPAND_FILL
			var margin_value = 10
			_mb.add_theme_constant_override("margin_top", margin_value)
			_mb.add_theme_constant_override("margin_left", margin_value)
			_mb.add_theme_constant_override("margin_bottom", margin_value)
			_mb.add_theme_constant_override("margin_right", margin_value)
			_mb.add_child(_cb)
			_container.add_child(_mb)
			continue
		
		# 引用ブロック
		_regex.compile(patterns["quote"])
		if not _regex.search_all(_line).is_empty():
			_line = _line.replace("> ", "")
			var _qb:RichTextLabel = _get_component("p")
			_qb.text = "[color=#444444]"+_line+"[/color]"
			_qb.theme_type_variation = "Quote"
			var _mb:MarginContainer = MarginContainer.new()
			_mb.layout_mode = 1
			_mb.anchors_preset = PRESET_FULL_RECT
			_mb.size_flags_horizontal = SIZE_EXPAND_FILL
			_mb.size_flags_vertical = SIZE_EXPAND_FILL
			var margin_value = 10
			_mb.add_theme_constant_override("margin_top", margin_value)
			_mb.add_theme_constant_override("margin_left", margin_value)
			_mb.add_theme_constant_override("margin_bottom", margin_value)
			_mb.add_theme_constant_override("margin_right", margin_value)
			_mb.add_child(_qb)
			_container.add_child(_mb)
			continue
		
		var _p:RichTextLabel = _get_component("p")
		
		## ヘッダー1チェック
		_regex.compile(patterns["h1"])
		_line = _regex.sub(_line, "[font_size=%s]$letter[/font_size]" % int(_base_font_size * 2.5), true)
		
		## ヘッダー2チェック
		_regex.compile(patterns["h2"])
		_line = _regex.sub(_line, "[font_size=%s]$letter[/font_size]" % int(_base_font_size * 2.2), true)
		
		## ヘッダー3チェック
		_regex.compile(patterns["h3"])
		_line = _regex.sub(_line, "[font_size=%s]$letter[/font_size]" % int(_base_font_size * 2.0), true)
		
		## ヘッダー4チェック
		_regex.compile(patterns["h4"])
		_line = _regex.sub(_line, "[font_size=%s]$letter[/font_size]" % int(_base_font_size * 1.8), true)
		
		## ヘッダー5チェック
		_regex.compile(patterns["h5"])
		_line = _regex.sub(_line, "[font_size=%s]$letter[/font_size]" % int(_base_font_size * 1.6), true)
		
		## ヘッダー6チェック
		_regex.compile(patterns["h6"])
		_line = _regex.sub(_line, "[font_size=%s]$letter[/font_size]" % int(_base_font_size * 1.4), true)
		
		_regex.compile(patterns["strong"])
		_line = _regex.sub(_line, "[b]$letter[/b]", true)
		
		_regex.compile(patterns["bold"])
		_line = _regex.sub(_line, "[b]$letter[/b]", true)
		
		_regex.compile(patterns["si"])
		_line = _regex.sub(_line, "[s]$1[/s]", true)
		
		_regex.compile(patterns["code"])
		_line = _regex.sub(_line, "[color=#ff3333][code]$2[/code][/color]", true)
		
		_regex.compile(patterns["image"])
		_line = _regex.sub(_line, "[img]$2[/img]", true)
		
		_regex.compile(patterns["link"])
		if not _regex.search_all(_line).is_empty():
			_p.meta_clicked.connect(Callable(self,"_richtextlabel_on_meta_clicked"))
		_line = _regex.sub(_line, "[color=#3333ff][url={\"$2\"}]$1[/url][/color]", true)
		
		# ブロックを作る
		_p.text = _line
		_container.add_child(_p)
	
func _setup_comp():
	theme = _default_theme if _theme == null else _theme
	if theme.has_default_font_size():
		_base_font_size = theme.default_font_size
	else:
		_base_font_size = ThemeDB.fallback_font_size
		
	anchors_preset = PRESET_FULL_RECT
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	
	_bg = ColorRect.new()
	_bg.name = "background"
	_bg.layout_mode = 1
	_bg.anchors_preset = PRESET_FULL_RECT
	_bg.size_flags_horizontal = SIZE_EXPAND_FILL
	_bg.size_flags_vertical = SIZE_EXPAND_FILL
	_bg.color = background_color
	add_child(_bg)
	
	_wrap_scroll_container = ScrollContainer.new()
	_wrap_scroll_container.layout_mode = 1
	_wrap_scroll_container.anchors_preset = PRESET_FULL_RECT
	_wrap_scroll_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_wrap_scroll_container.size_flags_vertical = SIZE_EXPAND_FILL
	_wrap_scroll_container.name = "ScrollContainer"
	add_child(_wrap_scroll_container)
	
	_container = VBoxContainer.new()
	_container.name = "conainer"
	_container.anchors_preset = PRESET_FULL_RECT
	_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_container.size_flags_vertical = SIZE_EXPAND_FILL
	_wrap_scroll_container.add_child(_container)
	
	_comp["p"] = RichTextLabel.new()
	_comp["p"].name = "paragraph"
	_comp["p"].bbcode_enabled = true
	_comp["p"].fit_content_height = true
	_comp["p"].size_flags_horizontal = SIZE_EXPAND_FILL
	_comp["p"].theme_type_variation = "p"
	
	_comp["hr"] = ColorRect.new()
	_comp["hr"].color = Color(0.02,0.02,0.02,0.3)
	_comp["hr"].size_flags_horizontal = SIZE_EXPAND_FILL
	_comp["hr"].custom_minimum_size = Vector2(0, 1.0);

func _get_component(key:String):
	if not _comp.has(key) or not is_instance_valid(_comp[key]):
		return null
	var _d = _comp[key].duplicate()
	return _d

func _richtextlabel_on_meta_clicked(meta):
	OS.shell_open(str(meta))
	print(str(meta))
