RCUBE.Dataset = function(){
  this._url = undefined;
  this._csvData = undefined;
  this._dimensionNames = [];
  this._rSquared = {};
};

RCUBE.Dataset.prototype.setCsvData = function(csvData) {
  this._csvData = csvData;
  // Reset dimensionNames array to not loose angular watch
  this._dimensionNames.length = 0;
  var _dimensionNamesReference = this._dimensionNames;
  Object.keys(this._csvData[0]).forEach(function(name){
    _dimensionNamesReference.push(name);
  });
};

RCUBE.Dataset.prototype.getDimensionNames = function(){
  return this._dimensionNames;
};
