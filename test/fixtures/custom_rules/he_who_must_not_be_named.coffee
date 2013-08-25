
matcher = /Voldemort/i

module.exports = class NoTabs
    rule:
        name: 'he_who_must_not_be_named'
        level : 'error'
        message : "Forbidden variable name. The snatchers have been alerted"
        description: """
        """

    tokens: [ 'IDENTIFIER' ]

    lintToken : (token, tokenApi) ->
        if matcher.test(token[1])
            true
