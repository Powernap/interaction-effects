RCUBE.Dataset = function(file){
  this._file = file;
  var self = this;
  // Load the CSV file
  this.helper.loadCSV(file.name, function(data) {
    self._csv = data;
    self._names = Object.keys(self._csv[0]);
    console.log(self);
  });
}

RCUBE.Dataset.prototype.helper = {};

RCUBE.Dataset.prototype.helper.loadCSV = function(path, callback) {
  d3.csv(path, function(data){
    if (callback != undefined)
      callback(data);
  });
}
