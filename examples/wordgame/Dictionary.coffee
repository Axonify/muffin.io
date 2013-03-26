class Dictionary
  constructor: (@originalWordList, grid) ->
    @setGrid grid if grid?
  
  setGrid: (@grid) ->
    @wordList = @originalWordList.slice(0)
    @wordList = (word for word in @wordList when word.length <= @grid.size)
    @minWordLength = Math.min.apply Math, (w.length for w in @wordList)
    @usedWords = []
    for x in [0...@grid.size]
      for y in [0...@grid.size]
        @markUsed word for word in @wordsThroughTile x, y
  
  markUsed: (str) ->
    if str in @usedWords
      false
    else
      @usedWords.push str
      true
  
  isWord: (str) -> str in @wordList
  isNewWord: (str) -> str in @wordList and str not in @usedWords
  
root = exports ? window
root.Dictionary = Dictionary
  