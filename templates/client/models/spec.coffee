describe '<$- model $> model', ->

  it 'should handle the truth', ->
    expect(true).toBeTruthy()

  it 'should exist', ->
    expect(<$- _.classify(model) $>).toBeTruthy()

  it 'should instantiate', ->
    x = new <$- _.classify(model) $>
    expect(x instanceof <$- _.classify(model) $>).toBeTruthy()
    expect(x instanceof Backbone.Model).toBeTruthy()

