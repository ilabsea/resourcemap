describe 'Alerts plugin', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

  describe 'Operator', ->
    it 'finds by code', ->
      expect(Operator.findByCode 'lt').toBe Operator.LT

    it 'should return equal to operator when failed to find by code', ->
      expect(Operator.findByCode '').toBe Operator.EQ
