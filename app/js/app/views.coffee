App   = window.App ?= {}

# App.ChromeView [view class]
# The entire body thing. The main instance can be accessed
# via `App.chrome`.
class App.ChromeView extends Backbone.View
  el: 'body'

  # toolbar [attribute]
  # An instance of `ToolbarView`.
  toolbar: null

  # typenames [constant]
  # The supported code editor typenames.
  typenames: ['html', 'css', 'javascript']

  # Instances of CodeView.
  html: null
  css: null
  javascript: null

  # $iframe [attribute]
  # The preview iframe.
  $iframe: null

  # $spinner [attribute]
  # The loading spinner.
  $spinner: null

  # listener [attribute]
  # The `KeyListener` instance.
  listener: null

  # keyEvents [method]
  # Returns a hash of key events.
  keyEvents: ->
    'command enter': @run.bind this
    'command shift 1': -> #Switch to HTML...

  render: ->
    $(@el).html JST['editor/chrome']()

    @$iframe = @$("iframe")
    @$spinner = @$(".spinner")

    # Listen for window resizing.
    $(window).resize => @onResize()
    @onResize()

    # Listen for keys.
    @listener = new App.KeyListener
    events = @keyEvents()
    for i of events
      @listener.on i, events[i]

    # Initialize the toolbar.
    @toolbar = (new App.ToolbarView el: @$("#toolbar")).render()

    # Initialize each of the code editors.
    _.each @typenames, (type) =>
      @[type] = (new App.CodeView type: type).render()
      $("#editorPane .area").append @[type].el

    this

  # run() [method]
  # Runs the snippet.
  # Called when you click the *Run* button.
  run: ->
    @$spinner.show().css opacity: 0.7
    @$iframe.animate opacity: 0.3, 'fast'

    new App.Submitter
      action:             '/preview'
      target:             'preview'
      onSubmit:           @onUpdate.bind(this)
      html:               @html.val()
      css:                @css.val()
      javascript:         @javascript.val()
      html_format:        @html.format()
      css_format:         @css.format()
      javascript_format:  @javascript.format()

  # Triggered when the preview is okay.
  onUpdate: ->
    @$spinner.fadeOut 50
    @$iframe.stop().css opacity: 1.0

  onResize: ->
    $iframe = @$("iframe")
    n = $iframe.parent().innerHeight()
    $iframe.css height: "#{n}px"

# App.CodeView [view class]
# The code editor.
class App.CodeView extends Backbone.View
  tagName: 'article'
  className: 'code'

  # options.type [attribute]
  # Either `html`, `js`, or `css`.

  # $editor [attribute]
  # The `<textarea>` instance.
  $editor: null

  # $format: [attribute]
  # The `<select>` format.
  $format: null

  # editor [attribute]
  # The instance of `CodeMirror`.
  editor: null

  types:
    html:
      formats:
        plain: 'Plain'
        haml:  'HAML'
    css:
      formats:
        plain: 'Plain'
        scss: 'Sass CSS'
        sass: 'Sass (old syntax)'
        less: 'Less'
    javascript:
      formats:
        plain: 'Plain'
        coffee: 'CoffeeScript'

  # val() [method]
  # Sets or gets the value.
  val: (value) ->
    if value?
      @editor.setValue value
    else
      @editor.getValue()

  # format() [method]
  # Gets the format.
  format: ->
    @$format.val()

  render: ->
    # Initialize the container.
    $(@el).addClass @options.type

    # Drop in the code.
    $(@el).html JST['editor/code'](type: @options.type)

    # Set up the 'format' dropdown.
    @$format = @$ "select.format"

    # Populate the formats dropdown.
    formats = @types[@options.type].formats
    for name of formats
      @$format.append $("<option>").
        attr('value', name).
        text(formats[name])

    # Set up the <textarea> inside it to use the code editor.
    @$editor = @$('textarea')
    @$editor.attr 'id', "editor_#{@options.type}"

    @editor = CodeMirror.fromTextArea @$editor[0],
      lineNumbers: true
      matchBrackets: true
      mode: 'xml'
      theme: 'default'
      gutter: true

    # Fix for the weird gutter disappearing act.
    setTimeout (=> @editor.setValue('')), 0
    this

# App.ToolbarView [view class]
# The toolbar on the side. The main instance can be accessed
# via `App.chrome.toolbar`.
class App.ToolbarView extends Backbone.View
  events:
    'click button.run': 'run'
    
  render: ->
    $(@el).html JST['editor/toolbar']()
    this

  run: ->
    App.chrome.run()