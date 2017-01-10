H2O.PartialDependenceInput = (_, _go) ->
  _exception = signal null #TODO display in .jade
  _destinationKey = signal "ppd-#{Flow.Util.uuid()}"

  _frames = signals []
  _models = signals []
  _selectedModel = signals null
  _selectedFrame = signal null
  _useCustomColumns = signal no
  _columns = signal []
  _nbins = signal 20


  # search & filter functionalities

  _visibleItems = signal []

  MaxItemsPerPage = 100

  _currentPage = signal 0
  _maxPages = lift _columns, (entries) -> Math.ceil entries.length / MaxItemsPerPage
  _canGoToPreviousPage = lift _currentPage, (index) -> index > 0
  _canGoToNextPage = lift _maxPages, _currentPage, (maxPages, index) -> index < maxPages - 1

  _selectionCount = signal 0

  _isUpdatingSelectionCount = no

  blockSelectionUpdates = (f) ->
    _isUpdatingSelectionCount = yes
    f()
    _isUpdatingSelectionCount = no

  incrementSelectionCount = (amount) ->
    _selectionCount _selectionCount() + amount

  _hasFilteredItems = lift _columns, (entries) -> entries.length > 0


  filterItems = ->
    start = _currentPage() * MaxItemsPerPage
    _visibleItems _columns().slice start, start + MaxItemsPerPage


  changeSelection = (source, value) ->
    for entry in source
      entry.isSelected value
    return

  selectFiltered = ->
    entries = _columns()
    blockSelectionUpdates -> changeSelection entries, yes
    _selectionCount entries.length

  deselectFiltered = ->
    blockSelectionUpdates -> changeSelection _columns(), no
    _selectionCount 0

  goToPreviousPage = ->
    if _canGoToPreviousPage()
      _currentPage _currentPage() - 1
      filterItems()
    return
  
  goToNextPage = ->
    if _canGoToNextPage()
      _currentPage _currentPage() + 1
      filterItems()
    return
  #end of search & filter functionalities  

  # a conditional check that makes sure that 
  # all fields in the form are filled in
  # before the button is shown as active
  _canCompute = lift _destinationKey, _selectedFrame, _selectedModel, _nbins, (dk, sf, sm, nb) ->
    dk and sf and sm and nb

  _compute = ->
    return unless _canCompute()

    # parameters are selections from Flow UI
    # form dropdown menus, text boxes, etc
    console.log("computing....columns")
    console.log(_columns())
    cols = ""

    for col in _columns() when col.isSelected()
      cols = cols + "\"" + col.value + "\","

    if cols != ""
      cols ="[" + cols + "]"

    console.log(cols)

    opts =
      destination_key: _destinationKey()
      model_id: _selectedModel()
      frame_id: _selectedFrame()
      cols: cols
      nbins: _nbins()

    cs = "buildPartialDependence #{stringify opts}"

    _.insertAndExecuteCell 'cs', cs

  _updateColumns = ->
      frameKey = _selectedFrame()
      if frameKey
        _.requestFrameSummaryWithoutData frameKey, (error, frame) ->
          unless error
            columnValues = map frame.columns, (column) -> column.label
            columnLabels = map frame.columns, (column) -> 
              missingPercent = 100 * column.missing_count / frame.rows
              isSelected = signal no
              react isSelected, (isSelected) -> 
                unless _isUpdatingSelectionCount
                  if isSelected
                    incrementSelectionCount 1
                  else
                    incrementSelectionCount -1
                return

              isSelected: isSelected
              type: if column.type is 'enum' then "enum(#{column.domain_cardinality})" else column.type
              value: column.label
              missingPercent: missingPercent
              missingLabel: if missingPercent is 0 then '' else "#{round missingPercent}% NA"

            console.log("frame updated:" + _selectedFrame() )
            console.log(columnValues)
            console.log(columnLabels)

            _columns columnLabels

            # reset page to first page
            _currentPage = signal 0
            filterItems()

  _.requestFrames (error, frames) ->
    if error
      _exception new Flow.Error 'Error fetching frame list.', error
    else
      _frames (frame.frame_id.name for frame in frames when not frame.is_text)

  _.requestModels (error, models) ->
    if error
      _exception new Flow.Error 'Error fetching model list.', error
    else
      #TODO use models directly
      _models (model.model_id.name for model in models)


  defer _go

  destinationKey: _destinationKey
  frames: _frames
  models: _models
  selectedModel: _selectedModel
  selectedFrame: _selectedFrame
  columns: _columns
  visibleItems: _visibleItems
  useCustomColumns: _useCustomColumns
  nbins: _nbins
  compute: _compute
  updateColumns: _updateColumns
  canCompute: _canCompute

  #search & filter functionalities of column selector
  hasFilteredItems: _hasFilteredItems
  selectFiltered: selectFiltered
  deselectFiltered: deselectFiltered
  goToPreviousPage: goToPreviousPage
  goToNextPage: goToNextPage
  canGoToPreviousPage: _canGoToPreviousPage
  canGoToNextPage: _canGoToNextPage


  template: 'flow-partial-dependence-input'


