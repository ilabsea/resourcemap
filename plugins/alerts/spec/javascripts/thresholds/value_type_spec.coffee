describe 'Alerts plugin', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

  describe 'ValueType', ->
    it 'finds by code', ->
      expect(ValueType.findByCode 'value').toBe ValueType.VALUE

