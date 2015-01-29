angular.module('cube')
  .factory('data', ['$rootScope', 'ocpuBridge', function($rootScope, ocpuBridge){
    var dataService = {};
    dataService.dataset = new RCUBE.Dataset();

    dataService.loadData = function(url) {
      dataService.dataset._url = url;
      loadCSV(url, function(csvData){
        dataService.dataset.setCsvData(csvData);
        ocpuBridge.loadDataset(url).then(function(data){
          console.log("Dataset loaded for all active OpenCPU sessions");
          // TODO: All requests are executed in parallel, it will be a good
          // idea to perform it manually
          // dataService.dataset.getDimensionNames().forEach(function(dimensionName){
          ['age'].forEach(function(dimensionName){
            ocpuBridge.calculateRSquared(dimensionName).then(function(rSquared){
              dataService.dataset._rSquared[dimensionName] = rSquared;
              $rootScope.$broadcast('rSquaredCalculationDone', dimensionName);
            });
          });
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

  .factory('ocpuBridge', ['$q', function($q){
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
      ocpuBridgeService.sessions.push(new RCUBE.RSession(url, name))
      console.log("Created new R Session: " + url + ", " + name);
    };
    return ocpuBridgeService;
  }]);
