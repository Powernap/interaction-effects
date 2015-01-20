(function() {
var app = angular.module('cube', [ ]);

app.controller("HeatmapController", function(){
  this.visible = dataloaded; // This doesnt work right now
});

var dataloaded = true;

var performanceTest = function(id, serverURL) {
  myRSession = new RCUBE.RSession(serverURL);
  var start = new Date().getTime();
  myRSession.loadDataset("/Users/paul/Desktop/patients-100k.csv", function(session){
    myRSession.calculateRSquaredValues(myRSession._datasetSession, function(_session){
      // _session.getConsole(function(outtxt){console.log(outtxt)});
      var end = new Date();
      var time = (end.getTime() - start) / (1000);
      console.log("[" + end.getHours() + ":" + end.getMinutes() + ":" + end.getSeconds() + "] Execution time " + id + ": " + time + " seconds");
      $.getJSON(myRSession._rSquaredSession.loc + "R/.val/json" , function(data){
        myRSession._rSquaredJSON = data;
        console.log(data);
        myJSON = data;
        // Test: Create RSquared Values
        var rSquared = data;
        var names = ["gender","age","diab","hypertension","stroke","chd","smoking","bmi"];
        var myHeatmap = new RCUBE.Heatmap(".my-heatmap", rSquared, names);
        dataloaded = true;
      });
    });
  });
};
performanceTest(1, "http://localhost:9167/ocpu");
})();
