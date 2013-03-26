# Underscore.inflection
# (c) 2011 Lance Carlson <lcarlson at rubyskills dot com>
# Ported from http://code.google.com/p/inflection-js/source/browse/trunk/inflection.js
_ = require 'underscore'
_.str = require 'underscore.string'
_.mixin(_.str.exports())

_s =
  uncountable_words: [
    'equipment', 'information', 'rice', 'money', 'species', 'series',
    'fish', 'sheep', 'moose', 'deer', 'news'
  ]

  plural_rules: [
    [new RegExp('(m)an$', 'gi'),                 '$1en'],
    [new RegExp('(pe)rson$', 'gi'),              '$1ople'],
    [new RegExp('(child)$', 'gi'),               '$1ren'],
    [new RegExp('^(ox)$', 'gi'),                 '$1en'],
    [new RegExp('(ax|test)is$', 'gi'),           '$1es'],
    [new RegExp('(octop|vir)us$', 'gi'),         '$1i'],
    [new RegExp('(alias|status)$', 'gi'),        '$1es'],
    [new RegExp('(bu)s$', 'gi'),                 '$1ses'],
    [new RegExp('(buffal|tomat|potat)o$', 'gi'), '$1oes'],
    [new RegExp('([ti])um$', 'gi'),              '$1a'],
    [new RegExp('sis$', 'gi'),                   'ses'],
    [new RegExp('(?:([^f])fe|([lr])f)$', 'gi'),  '$1$2ves'],
    [new RegExp('(hive)$', 'gi'),                '$1s'],
    [new RegExp('([^aeiouy]|qu)y$', 'gi'),       '$1ies'],
    [new RegExp('(x|ch|ss|sh)$', 'gi'),          '$1es'],
    [new RegExp('(matr|vert|ind)ix|ex$', 'gi'),  '$1ices'],
    [new RegExp('([m|l])ouse$', 'gi'),           '$1ice'],
    [new RegExp('(quiz)$', 'gi'),                '$1zes'],
    [new RegExp('s$', 'gi'),                     's'],
    [new RegExp('$', 'gi'),                      's']
  ]

  singular_rules: [
    [new RegExp('(m)en$', 'gi'),                                                       '$1an'],
    [new RegExp('(pe)ople$', 'gi'),                                                    '$1rson'],
    [new RegExp('(child)ren$', 'gi'),                                                  '$1'],
    [new RegExp('([ti])a$', 'gi'),                                                     '$1um'],
    [new RegExp('((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$','gi'), '$1$2sis'],
    [new RegExp('(hive)s$', 'gi'),                                                     '$1'],
    [new RegExp('(tive)s$', 'gi'),                                                     '$1'],
    [new RegExp('(curve)s$', 'gi'),                                                    '$1'],
    [new RegExp('([lr])ves$', 'gi'),                                                   '$1f'],
    [new RegExp('([^fo])ves$', 'gi'),                                                  '$1fe'],
    [new RegExp('([^aeiouy]|qu)ies$', 'gi'),                                           '$1y'],
    [new RegExp('(s)eries$', 'gi'),                                                    '$1eries'],
    [new RegExp('(m)ovies$', 'gi'),                                                    '$1ovie'],
    [new RegExp('(x|ch|ss|sh)es$', 'gi'),                                              '$1'],
    [new RegExp('([m|l])ice$', 'gi'),                                                  '$1ouse'],
    [new RegExp('(bus)es$', 'gi'),                                                     '$1'],
    [new RegExp('(o)es$', 'gi'),                                                       '$1'],
    [new RegExp('(shoe)s$', 'gi'),                                                     '$1'],
    [new RegExp('(cris|ax|test)es$', 'gi'),                                            '$1is'],
    [new RegExp('(octop|vir)i$', 'gi'),                                                '$1us'],
    [new RegExp('(alias|status)es$', 'gi'),                                            '$1'],
    [new RegExp('^(ox)en', 'gi'),                                                      '$1'],
    [new RegExp('(vert|ind)ices$', 'gi'),                                              '$1ex'],
    [new RegExp('(matr)ices$', 'gi'),                                                  '$1ix'],
    [new RegExp('(quiz)zes$', 'gi'),                                                   '$1'],
    [new RegExp('s$', 'gi'),                                                           '']
  ]

  pluralize: (str) ->
    _s.apply_rules str, _s.plural_rules, _s.uncountable_words

  singularize: (str) ->
    _s.apply_rules str, _s.singular_rules, _s.uncountable_words

  classify: (str) ->
    _.camelize _.capitalize _.singularize str

  apply_rules: (str, rules, skip) ->
    ignore = (skip.indexOf(str.toLowerCase()) > -1)
    if (!ignore)
      for rule in rules
        [regex, plurality] = rule
        if str.match(regex)
          str = str.replace(regex, plurality)
          break
    return str

_.mixin(_s)
module.exports = _