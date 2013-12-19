function Option (option) {
  this.id = option != null ? option["id"] : void(0);
  this.name = option != null ? option["label"] : void(0);
  this.code = option != null ? option["code"] : void(0);
  return this;
};