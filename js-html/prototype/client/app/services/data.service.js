angular.module('cube')
  .factory('data', ['$rootScope', 'ocpuBridge', function($rootScope, ocpuBridge){
    var dataService = {};
    dataService.dataset = new RCUBE.Dataset();
    dataService.defaultFormula = new RCUBE.RegressionFormula('x+y');

    dataService.formulaUpdate = function(formula){
      
    };

    dataService.getRSquaredValues = function(){
      return dataService.dataset._rSquared;
    };

    var calculateRSquaredSequential = function(dimensions) {
      if (dimensions.length === 0)
        return;
      var dimensionName = dimensions[dimensions.length - 1];
      ocpuBridge.calculateRSquared(dimensionName).then(function(rSquared){
        dataService.dataset._rSquared[dimensionName] = rSquared;
        dimensions.pop();
        calculateRSquaredSequential(dimensions);
      });
    };

    dataService.loadData = function(url) {
      dataService.dataset._url = url;
      loadCSV(url, function(csvData){
        dataService.dataset.setCsvData(csvData);
        ocpuBridge.loadDataset(url).then(function(data){
          console.log("Dataset loaded for all active OpenCPU sessions");
          // ['age', 'gender'].forEach(function(dimensionName){
          // Copy the dimensions array, since the recurive algorithm will delete its contents
          // var recursionDimensions = dataService.dataset.getDimensionNames().slice(0);
          var recursionDimensions = ['age', 'gender'];
          calculateRSquaredSequential(recursionDimensions);
          // Code for parallel execution
          // dataService.dataset.getDimensionNames().forEach(function(dimensionName){
          // ocpuBridge.calculateRSquared(dimensionName).then(function(rSquared){
          //   dataService.dataset._rSquared[dimensionName] = rSquared;
          // });
          // });
        });
      });
    };

    var loadCSV = function(url, callback) {
      d3.csv(url, function(data){
        callback(data);
      });
    };
    return dataService;
  }])

  .factory('ocpuBridge', ['$rootScope', '$q', function($rootScope, $q){
    var ocpuBridgeService = {};
    ocpuBridgeService.sessions = [];

    ocpuBridgeService.calculateRSquared = function(targetVariable){
      return $q(function(resolve, reject){
        // TODO: Write distribution algorithm here!
        var rsession = ocpuBridgeService.sessions[0];

        rsession.calculateRSquaredValues(targetVariable, function(rsquaredSession){
          $.getJSON(rsquaredSession.loc + "R/.val/json" , function(rSquaredData){
            resolve(rSquaredData);
          });
        });
      });
    };

    // This event is called when the user uploads a new data set
    ocpuBridgeService.loadDataset = function(url) {
      return $q(function(resolve, reject){
        var numberSessionsLoaded = 0;
        ocpuBridgeService.sessions.forEach(function(rsession, i){
          rsession.loadDataset(url, function(){
            numberSessionsLoaded = numberSessionsLoaded + 1;
            if (numberSessionsLoaded == ocpuBridgeService.sessions.length)
              resolve();
          });
        });
      });
    };
    ocpuBridgeService.pushService = function(url, name){
      ocpuBridgeService.sessions.push(new RCUBE.RSession(url, name));
      console.log("Created new R Session: " + url + ", " + name);
    };
    return ocpuBridgeService;
  }]);
