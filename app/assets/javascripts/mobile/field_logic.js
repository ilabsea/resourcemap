function FieldLogic (field_logic) {
  this.id = field_logic != null ? field_logic["id"] : void(0);
  this.value = field_logic != null ? field_logic["value"] : void(0);
  this.label = field_logic != null ? field_logic["label"] : void(0);
  this.field_id = field_logic != null ? field_logic["field_id"] : void(0);
  return this;
};