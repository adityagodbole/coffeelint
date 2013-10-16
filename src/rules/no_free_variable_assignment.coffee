module.exports = class NoTabs
    rule:
        name: 'no_free_variable_assignment'
        value : 10
        level : 'warn'
        message : 'Free variable assignment not allowed'
        description : 'Use do to create locally scoped variables'

    lintAST : (node, @astApi) ->
        @lintNode node
        undefined

    # Lint the AST node and return its cyclomatic complexity.
    lintNode : (node, line) ->
        var_assignment_node_p = (node) ->
          node.constructor.name == "Assign" && node.parentNode && node.parentNode.constructor.name != "Obj"
        # Get the complexity of the current node.
        name = node.constructor.name

        # Add the complexity of all child's nodes to this one.
        node.eachChild (childNode) =>
          nodeLine = childNode.locationData.first_line
          if childNode
            childNode.parentNode = node
            @lintNode(childNode, nodeLine) if childNode

        if var_assignment_node_p(node)
          @lintFreeAssignment(node, line)

    lintFreeAssignment: (node, line) ->
      do(lvalues = null, vars = null, do_vars = null, parentCodeBlock = null) =>
        parentCodeBlock = (node) ->
          node = node.parentNode while node && !node.params
          node
        lvalues = (variable) ->
          if variable.value
            [variable.value]
          else if variable.objects
            [].concat((lvalues(child.base) for child in variable.objects)...)
          else
            []
        vars = lvalues(node.variable.base).filter((v) -> v != "this")
        do_vars = do(pcb = parentCodeBlock(node)) ->
          if pcb
            pcb.params.map((p) -> p.name.value)
          else
            []
        vars.forEach (v) =>
          if v not in do_vars
            @errors.push @astApi.createError({lineNumber: line + 1})
        null
