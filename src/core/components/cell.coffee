Flow.Cell = (_, _renderers, type='cs', input='') ->
  _guid = do uniqueId
  _type = signal type
  _render = lift _type, (type) -> _renderers[type] _guid
  _isSelected = signal no
  _isActive = signal no
  _hasError = signal no
  _isBusy = signal no
  _isReady = lift _isBusy, (isBusy) -> not isBusy
  _hasInput = signal yes
  _input = signal input
  _outputs = signals []
  _result = signal null
  _hasOutput = lift _outputs, (outputs) -> outputs.length > 0
  _isOutputVisible = signal yes
  _isOutputHidden = lift _isOutputVisible, (visible) -> not visible

  # This is a shim.
  # The ko 'cursorPosition' custom binding attaches a read() method to this.
  _cursorPosition = {}

  # select and display input when activated
  act _isActive, (isActive) ->
    if isActive
      _.selectCell self
      _hasInput yes
      _outputs [] unless _render().isCode
    return

  # deactivate when deselected
  act _isSelected, (isSelected) ->
    _isActive no unless isSelected

  # tied to mouse-clicks on the cell
  select = ->
    _.selectCell self
    return yes # Explicity return true, otherwise KO will prevent the mouseclick event from bubbling up

  # tied to mouse-double-clicks on html content
  # TODO
  activate = -> _isActive yes

  execute = (go) ->
    input = _input().trim()
    unless input
      return if go then go() else undefined 

    render = _render()
    _isBusy yes
    # Clear any existing outputs
    _result null
    _outputs []
    _hasError no
    render input,
      data: (result) ->
        _outputs.push result
      close: (result) ->
        #XXX push to cell output
        _result result
      error: (error) ->
        _hasError yes
        #XXX review
        if error.name is 'FlowError'
          _outputs.push Flow.Failure error
        else
          _outputs.push
            text: JSON.stringify error, null, 2
            template: 'flow-raw'
      end: ->
        _hasInput render.isCode
        _isBusy no
        go() if go

    _isActive no

  self =
    guid: _guid
    type: _type
    isSelected: _isSelected
    isActive: _isActive
    hasError: _hasError
    isBusy: _isBusy
    isReady: _isReady
    input: _input
    hasInput: _hasInput
    outputs: _outputs
    result: _result
    hasOutput: _hasOutput
    isOutputVisible: _isOutputVisible
    toggleOutput: -> _isOutputVisible not _isOutputVisible()
    showOutput: -> _isOutputVisible yes
    hideOutput: -> _isOutputVisible no
    select: select
    activate: activate
    execute: execute
    _cursorPosition: _cursorPosition
    cursorPosition: -> _cursorPosition.read()
    templateOf: (view) -> view.template
    template: 'flow-cell'
