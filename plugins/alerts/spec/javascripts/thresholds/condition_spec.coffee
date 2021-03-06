describe 'Alerts plugin', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

  describe 'Condition', ->
    beforeEach ->
      @collectionId = 1
      @field = new Field id: 1, code: 'beds', kind: 'numeric'
      window.model = new MainViewModel @collectionId
      window.model.fields [@field]
      @condition = new Condition field: '1', op: 'eq', value: 10, type: 'value'

    it 'should convert to json', ->
      expect(@condition.toJSON()).toEqual {field: '1', op: 'eq', value: 10, type: 'value', compare_field: '1'}

    describe 'formatted value', ->
      it 'should format value', ->
        condition = new Condition field: '1', type: 'value', value: 12
        expect(condition.formattedValue()).toEqual '12'

      it 'should format percentage', ->
        condition = new Condition field: '1', type: 'percentage', value: 12
        expect(condition.formattedValue()).toEqual '12%'

      describe 'yes_no', ->
        beforeEach ->
          @field = new Field id: 1, kind: 'yes_no'
          window.model.fields [@field]

        it 'should format "true"', ->
          condition = new Condition field: '1', value: true
          expect(condition.formattedValue()).toEqual 'Yes'

        it 'should format "false"', ->
          condition = new Condition field: '1', value: false
          expect(condition.formattedValue()).toEqual 'No'

      describe 'select', ->
        beforeEach ->
          @options = [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}]
          @field = new Field id: 1, kind: 'select_one', config: { options: @options }
          window.model.fields [@field]

        describe '_one', ->
          it 'should get option label', ->
            condition = new Condition field: '1', value: 1
            expect(condition.formattedValue()).toEqual 'One'

        describe '_many', ->
          beforeEach -> @field.kind 'select_many'

          it 'should get option label', ->
            condition = new Condition field: '1', value: 2
            expect(condition.formattedValue()).toEqual 'Two'

      describe 'date', ->
        beforeEach ->
          @field = new Field id: 1, kind: 'date'
          window.model.fields [@field]

        it 'should return m/d/yyyy', ->
          condition = new Condition field: '1', value: '2014-06-12T00:00:00Z'
          expect(condition.formattedValue()).toEqual '06/12/2014'

    describe 'field change', ->
      beforeEach ->
        @field_2 = new Field id: 2, code: 'doctors', kind: 'numeric'
        window.model.fields [@field, @field_2]

        @condition = new Condition field: '1', op: 'lt', type: 'percentage', compare_field: '2', value: 50
        @condition.field @field_2

      it 'should reset operator', ->
        expect(@condition.op()).toEqual Operator.EQ

      it 'should reset compare field', ->
        expect(@condition.compareField()).toBeNull()

      it 'should reset value', ->
        expect(@condition.value()).toBeNull()

      it 'should reset operator', ->
        expect(@condition.valueType()).toEqual ValueType.VALUE
