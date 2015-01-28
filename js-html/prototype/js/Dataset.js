RCUBE.Dataset = function(){
  this._url = undefined;
  this._csvData = undefined;
  this._dimensionNames = undefined;
  this._rSquared = {};
};

RCUBE.Dataset.prototype.setCsvData = function(csvData) {
  this._csvData = csvData;
  this._dimensionNames = Object.keys(this._csvData[0]);
}

RCUBE.Dataset.prototype.getDimensionNames = function(){
  return this._dimensionNames;
}
