describe '<$- router $> router', ->

  describe '<$- view $> view', ->

    it 'should handle the truth', ->
      expect(true).toBeTruthy()

    it 'should exist', ->
      expect(<$- router.capitalize() $><$- view.capitalize() $>View).toBeTruthy()

    it 'should instantiate', ->
      x = new <$- router.capitalize() $><$- view.capitalize() $>View
      expect(x instanceof <$- router.capitalize() $><$- view.capitalize() $>View).toBeTruthy()
      expect(x instanceof Backbone.View).toBeTruthy()

    it 'should have render method', ->
      x = new <$- router.capitalize() $><$- view.capitalize() $>View
      x.render()

    # Implement as you see fit
    xit 'should render some text', ->
      x = new <$- router.capitalize() $><$- view.capitalize() $>View { el : $("<div />") }
      x.render()
      expect(x.$(".myselector").html()).toMatch /some text/
