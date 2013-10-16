module.exports = class NoTabs

    rule:
        name: 'cyclomatic_complexity'
        value : 10
        level : 'ignore'
        message : 'The cyclomatic complexity is too damn high'
        description : 'Examine the complexity of your application.'

    # returns the "complexity" value of the current node.
    getComplexity : (node) ->
        name = node.constructor.name
        complexity = if name in ['If', 'While', 'For', 'Try']
            1
        else if name == 'Op' and node.operator in ['&&', '||']
            1
        else if name == 'Switch'
            node.cases.length
        else
            0
        return complexity

    lintAST : (node, @astApi) ->
        @lintNode node
        undefined

    # Lint the AST node and return its cyclomatic complexity.
    lintNode : (node, line) ->
        var_assignment_node_p = (node) ->
          node.name == "Assign" && node.parentNode.constructor.name != "Obj"
        # Get the complexity of the current node.
        name = node.constructor.name
        complexity = @getComplexity(node)

        # Add the complexity of all child's nodes to this one.
        node.eachChild (childNode) =>
          nodeLine = childNode.locationData.first_line
          if childNode
            childNode.parentNode = node
            complexity += @lintNode(childNode, nodeLine) if childNode

        rule = @astApi.config[@rule.name]

        # If the current node is a function, and it's over our limit, add an
        # error to the list.
        if name == 'Code' and complexity >= rule.value
          error = @astApi.createError {
            context: complexity + 1
            lineNumber: line + 1
            lineNumberEnd: node.locationData.last_line + 1
          }
          @errors.push error if error
        if var_assignment_node_p(node)
          @lintFreeAssignment(node, line)
        # Return the complexity for the benefit of parent nodes.
        return complexity

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
            @errors.push @astApi.createError('no_free_variable_assignment', {level: WARN, lineNumber: line + 1})
        null
