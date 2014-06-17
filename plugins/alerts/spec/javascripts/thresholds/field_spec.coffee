describe 'Alerts plugin', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

  describe 'Field', ->
    describe 'kind is text', ->
      beforeEach ->
        @field = new Field kind: 'text'

      it 'should have equal to ignore case operator', ->
        expect(@field.operators()).toContain Operator.EQI

      it 'should have contain operator', ->
        expect(@field.operators()).toContain Operator.CON

      it 'should not validate empty string', ->
        expect(@field.valid('')).toBe false

      it 'should not validate null', ->
        expect(@field.valid(null)).toBe false

      it 'should validate white spaces', ->
        expect(@field.valid('      ')).toBe true

    describe 'kind is numeric', ->
      beforeEach ->
        @field = new Field kind: 'numeric'

      it 'should have equal to operator', ->
        expect(@field.operators()).toContain Operator.EQ

      it 'should have less than operator', ->
        expect(@field.operators()).toContain Operator.LT

      it 'should have larger than operator', ->
        expect(@field.operators()).toContain Operator.GT

      it 'should validate number', ->
        expect(@field.valid('17')).toBe true

      it 'should not validate character string', ->
        expect(@field.valid('foo')).toBe false

    describe 'kind is select one', ->
      beforeEach ->
        @field = new Field kind: 'select_one', config: {options: [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}]}

      it 'should has is operator', ->
        expect(@field.operators()).toContain Operator.EQ

      it 'should have options', ->
        expect(@field.options().length).toEqual 2

    describe 'kind is yes_no', ->
      beforeEach ->
        @field = new Field kind: 'yes_no'

      it 'should have equal to operator', ->
        expect(@field.operators()).toContain Operator.EQ

      it 'should validate true', ->
        expect(@field.valid(true)).toBe true

      it 'should validate false', ->
        expect(@field.valid(false)).toBe true

      it 'should not validate string', ->
        expect(@field.valid('true')).toBe false

    describe 'kind is date', ->
      beforeEach ->
        @field = new Field kind: 'date'

      it 'should have equal to operator', ->
        expect(@field.operators()).toContain Operator.EQ

      it 'should have less than operator', ->
        expect(@field.operators()).toContain Operator.LT

      it 'should have larger than operator', ->
        expect(@field.operators()).toContain Operator.GT

      describe 'encode', ->
        beforeEach ->
          @m_d_y = '06/12/2014'
          @y_m_d = '2014-06-12'

        it 'should support m/d/yyyy', ->
          expect(@field.encode(@m_d_y)).toEqual @m_d_y

        it 'should support yyyy-mm-dd', ->
          expect(@field.encode(@y_m_d)).toEqual @m_d_y

      it 'should not validate null', ->
        expect(@field.valid(null)).toBe false

    describe 'kind is email', ->
      beforeEach ->
        @field = new Field kind: 'email'

      it 'should have equal to ignore case operator', ->
        expect(@field.operators()).toContain Operator.EQI

      it 'should have contain operator', ->
        expect(@field.operators()).toContain Operator.CON

      it 'should not validate null', ->
        expect(@field.valid(null)).toBe false

    describe 'kind is phone', ->
      beforeEach ->
        @field = new Field kind: 'phone'

      it 'should have equal to ignore case operator', ->
        expect(@field.operators()).toContain Operator.EQI

      it 'should have contain operator', ->
        expect(@field.operators()).toContain Operator.CON

      it 'should not validate null', ->
        expect(@field.valid(null)).toBe false