class Player
  constructor: (@name, dictionary) ->
    @setDictionary dictionary if dictionary?
  
  setDictionary: (@dictionary) ->
    @score = 0
    @moveCount = 0
  
  makeMove: (swapCoordinates) ->
    @dicitionary.grid.swap swapCoordinates
    @moveCount++
    result = scoreMove @dictionary, swapCoordinates
    @score += result.moveScore
    result