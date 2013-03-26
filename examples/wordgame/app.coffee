fs = require 'fs'

MIN_WORD_LENGTH = 2
GRID_SIZE = 5
wordList = []

# Read word list from file
fs.readFile 'OWL2.txt', (err, data) ->
  console.log err if err
  
  # Remove the word definitions
  wordList = data.toString().match /^(\w+)/mg
  
  # Keep only words which can fit on the grid
  wordList = (word for word in wordList when word.length <= GRID_SIZE)

isWord = (str) ->
  str in wordList

inRange = (x, y) ->
  0 <= x < GRID_SIZE and 0 <= y < GRID_SIZE

# Generate a random grid with the right probability distribution
tileCounts =
  A: 9, B: 2, C: 2, D: 4, E: 12, F: 2, G: 3, H: 2, I: 9, J: 1, K: 1, L: 4
  M: 2, N: 6, O: 8, P: 2, Q: 1, R: 6, S: 4, T: 6, U: 4, V: 2, W: 2, X: 1
  Y: 2, Z: 1
totalTiles = 0
totalTiles += count for letter, count of tileCounts

# JavaScript hashes are unordered, so we need to make our own key array:
alphabet = (letter for letter of tileCounts).sort()

randomLetter = ->
  randomNumber = Math.ceil Math.random() * totalTiles
  x = 1
  for letter in alphabet
    x += tileCounts[letter]
    return letter if x > randomNumber

# Grid is a 2D array: grid[col][row], where 0, 0 is the upper-left corner
grid = for x in [0...GRID_SIZE]
  for y in [0...GRID_SIZE]
    randomLetter()

# Print the grid in a pretty format
printGrid = ->
  # Transpose the grid so we can draw rows
  rows = for x in [0...GRID_SIZE]
    for y in [0...GRID_SIZE]
      grid[y][x]
  rowStrings = (' ' + rows.join(' | ') for row in rows)
  rowSeparator = ('-' for i in [1...GRID_SIZE * 4].join(''))
  console.log '\n' + rowStrings.join("\n#{rowSeparator}\n") + '\n'

# Each letter has the same point value as in Scrabble.
tileValues =
  A: 1, B: 3, C: 3, D: 2, E: 1, F: 4, G: 2, H: 4, I: 1, J: 8, K: 5, L: 1
  M: 3, N: 1, O: 1, P: 3, Q: 10, R: 1, S: 1, T: 1, U: 1, V: 4, W: 4, X: 8,
  Y: 4, Z: 10

moveCount = 0
score = 0
usedWords = []

# Score function
scoreMove = (grid, swapCoordinates) ->
  {x1, x2, y1, y2} = swapCoordinates
  words = wordsThroughTile(grid, x1, y1).concat wordsThroughTile(grid, x2, y2)
  moveScore = multiplier = 0
  newWords = []
  for word in words when word not in usedWords and word not in newWords
    multiplier++
    moveScore += tileValues[letter] for letter in word
    newWords.push word
  usedWords = usedWords.concat newWords
  moveScore *= multiplier
  {moveScore, newWords}

wordsThroughTile = (grid, x, y) ->
  strings = []
  for length in [MIN_WORD_LENGTH..GRID_SIZE]
    range = length - 1
    addTiles = (func) ->
      strings.push (func(i) for i in [0..range]).join ''
    for offset in [0...length]
      # Vertical
      if inRange(x - offset, y) and inRange(x - offset + range, y)
        addTiles (i) -> grid[x - offset + i][y]
      # Horizontal
      if inRange(x, y - offset) and inRange(x, y - offset + range)
        addTiles (i) -> grid[x][y - offset + i]
      # Diagonal (upper-left to lower-right)
      if inRange(x - offset, y - offset) and inRange(x - offset + range, y - offset + range)
        addTiles (i) -> grid[x - offset + i][y - offset + i]
      # Diagonal (lower-left to upper-right)
      if inRange(x - offset, y + offset) and inRange(x - offset + range, y + offset - range)
        addTiles (i) -> grid[x - offset + i][y + offset - i]
  str for str in strings when isWord str
  
console.log "Welcome to 5x5"

# To count words that are already in the grid at the start as used, swap each tile with itself.
for x in [0...GRID_SIZE]
  for y in [0...GRID_SIZE]
    scoreMove grid, {x1: x, x2: x, y1: y, y2: y}
unless usedWords.length is 0
  console.log """
    Initially used words:
    #{usedWords.join(', ')}
  """
console.log "Please choose a tile in the form (x, y)."
    