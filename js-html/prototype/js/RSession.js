RCUBE.RSession = function(URLToOpenCPUServer, name) {
  this._name = name;
  this._openCPUConnection = new RCUBE.Helper.OpenCPUConnection(URLToOpenCPUServer);
  this._datasetSession = undefined;
  this._rSquaredSession = undefined;
  this._rSquaredJSON = undefined;
};

RCUBE.RSession.prototype.loadDataset = function(csvFilePath, callback) {
  self = this;
  this._openCPUConnection.execute(
    "/library/regressionCube/R",
    'load_dataset',
  {"csv_filepath": csvFilePath},
  function(session){
    self._datasetSession = session;
    if (callback != undefined) callback(session);
  },
  function(req) {
    console.error("Error: " + req.responseText);
  });
};

RCUBE.RSession.prototype.calculateRSquaredValues = function(session, callback) {
  self = this;
  this._openCPUConnection.execute(
    "/library/regressionCube/R",
    'r_squared_matrix',
  {"data": session, "dependent": "age"},
  function(_session){
    self._rSquaredSession = _session;
    if (callback != undefined) callback(_session);
  },
  function(req) {
    console.error("Error: " + req.responseText);
  });
}
