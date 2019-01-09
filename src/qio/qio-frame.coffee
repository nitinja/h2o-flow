ko = require('../core/modules/knockout')

context = null

exports.init = (_) ->
    context = _
    localStorage.setItem 'contextPath', _.ContextPath
    console.log 'in init'
    getFrames()
    return

ko.components.register 'message-editor',
  viewModel: (params) ->
    self = this
    @text = ko.observable(params and params.initialText or '')
    @_frames = ko.observableArray []
    @selectedFrame= ko.observable()
    @frameComposedURL= ko.observable()
    @selectedFrameSourceURL= ko.observable()
    @selectedFrame.subscribe (latest) ->
        self.frameComposedURL context.ContextPath + '3/Frames/'+self.selectedFrame()
        self.selectedFrameSourceURL 'http://0.0.0.0:8050?framePath=' + self.frameComposedURL()
        console.log "Input changed .. "+latest
  
    context.requestFrames (error, frames) ->
        if error
            #TODO handle properly
        else
            textFrames = (frame.frame_id.name for frame in frames when not frame.is_text)
            self._frames.removeAll
            textFrames.forEach (item) ->
                self._frames.push item
            console.log _frames
        return
    @selectClicked = () -> 
        console.log 'in click handler'
    return
  template: '<div class="container-fluid flow-repl">
                Select Frame: 
                <select data-bind="options: _frames,
                       optionsCaption: \'Choose...\',
                       value: selectedFrame"></select>
                <div data-bind="text: frameComposedURL"></div> 
                
                    <iframe style="width:100%;height:600px;border:0;margin:1rem auto;" 
                    data-bind="attr: {src: selectedFrameSourceURL}" src="">
                    </iframe>
                </div>
</div>
            '


getFrames = () ->
    context.requestFrames (error, frames) ->
        
        if error
            #TODO handle properly
        else
            _frames = (frame.frame_id.name for frame in frames when not frame.is_text)
            console.log _frames
        return




