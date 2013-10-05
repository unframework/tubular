
window.tubular = (rootModel, rootDom, rootView) ->
  rootViewPrototype =
    element: (options...) ->
      childView = null

      elementName = null
      elementId = null
      elementClassList = []

      if options.length and typeof(options[options.length - 1]) is 'function'
        childView = options.pop()

      if options.length and typeof(options[0]) is 'string'
        elementName = options.shift()

        # parse #id and .class suffixes
        elementName = elementName.replace /[#.][^#.]*/g, (a) ->
          if a[0] is '#'
            elementId = a.substring(1)
          else
            elementClassList.push a.substring(1)

          '' # strip suffix from original name

      childDom = @dom.ownerDocument.createElement(elementName or 'div')

      if elementId isnt null # still trigger for empty ID string
        childDom.setAttribute 'id', elementId

      if elementClassList.length
        childDom.setAttribute 'class', elementClassList.join ' '

      for o in options
        for n, v of o
          childDom.setAttribute n, v

      @dom.appendChild(childDom)

      if childView
        @withDOM childDom, childView

    attr: (setting) ->
      for n, path of setting
        snakeCaseName = n.replace /[a-z][A-Z]/g, (a) ->
          a[0] + '-' + a[1].toLowerCase()

        @with path, (v) ->
          @dom.setAttribute snakeCaseName, v

    text: (setting) ->
      childDom = @dom.ownerDocument.createTextNode(setting)
      @dom.appendChild(childDom)

  watchList = []

  invoke = (model, viewPrototype, viewDOM, view) ->
    viewContext =
      dom: viewDOM

      extend: (map, init) ->
        # copy the prototype into a clean object
        newPrototype = {}
        newPrototype[n] = v for n, v of map
        newPrototype.__proto__ = viewPrototype

        invoke model, newPrototype, viewDOM, init

      withDOM: (newDOM, init) ->
        invoke model, viewPrototype, newDOM, init

      with: (path, init) ->
        value = model[path]

        watchList.push ->
          # get and compare with cached values
          newValue = model[path]
          if newValue isnt value
            value = newValue
            invoke value, viewPrototype, viewDOM, init

        invoke value, viewPrototype, viewDOM, init

    viewContext.__proto__ = viewPrototype

    view.call(viewContext, model)

    undefined # prevent stray output

  invoke rootModel, rootViewPrototype, rootDom, rootView
