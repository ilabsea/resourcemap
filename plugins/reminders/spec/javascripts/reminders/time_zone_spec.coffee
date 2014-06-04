describe 'Reminders plugin', ->
  beforeEach ->
    window.runOnCallbacks 'reminders'

  describe 'TimeZone', ->
    it 'should have 420 minutes different to UTC when time zone is in Bangkok GMT +7', ->
      expect(TimeZone.calculate_time_different_by_zone("+07:00")).toEqual(420)

    it 'should have 600 minutes different to UTC when time zone is in Bangkok GMT +10', ->
      expect(TimeZone.calculate_time_different_by_zone("+10:00")).toEqual(600)

    it 'should have find Bangkok have GMT +07', ->
      expect(TimeZone.find_time_zone("Bangkok")["zone"]).toEqual("+07:00")

    it 'should have 420 minutes different to UTC when time zone is in Bangkok GMT +7', ->
      expect(TimeZone.calculate_time_different_by_time(new Date())).toEqual(420)
