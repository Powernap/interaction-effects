angular.module('cube')
  .directive('formulaEditor', ['$rootScope', 'data', function($rootScope, data) {
    return {
      restrict: 'E',
      require: 'ngModel',
      templateUrl: 'app/directives/formula-editor.html',

      controller: function($scope) {
        var editorController = this;
        this.popup = {};
        this.popup.lastTextCompleteWord = '';
        this.popup.show = false;
        this.popup.defaultHeader = 'Available commands';
        this.popup.defaultContentOperators = 'Available Operators: +, -, :, *, /, |';
        // The default dimensions are fetched in the watch statement
        this.popup.defaultContentDimensions = '';
        this.popup.header = editorController.popup.defaultHeader;
        this.popup.content = editorController.popup.defaultContentOperators;
        this.formula = new RCUBE.RegressionFormula();

        this.formulaChange = function(){
          this.formula.update($scope.formulaInput);
          if (this.formula.isValid()){
            console.log("isValid");
          }
        };

        this.updatePopup = function(name){
          if (name !== undefined){
            editorController.popup.header = name;
            // $scope.$apply(editorController.popup.content = name);
            editorController.popup.content = 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';
            $scope.$apply();
          }
          else {
            editorController.popup.header = editorController.popup.defaultHeader;
            editorController.popup.content = editorController.popup.defaultContentOperators + '\nDimensions:\n' + editorController.popup.defaultContentDimensions;
            $scope.$apply();
          }
        };

        this.parseFormula = function(formula) {
          var regexVariables = /([^\^\+\-\:\*\/\|\s]+)/g;
          var regexOperators = /([\^\+\-\:\*\/\|])/g;
          var variables = formula.match(regexVariables);
          var operators = formula.match(regexOperators);
          var reconstructedFormula = '';
          var reconstructionSuccessfull = false;
          if (operators.length == variables.length - 1) {
            reconstructionSuccessfull = true;
            variables.forEach(function(variable, index){
              reconstructedFormula = reconstructedFormula + variable;
              // If it is not the last element, attach the operator
              if (index != variables.length - 1)
                reconstructedFormula = reconstructedFormula + operators[index];
            });
          }
          return reconstructedFormula;
        };

        // Watch the dimension array
        $scope.dimensions = data.dataset.getDimensionNames();
        // Attach typeahead logic to the UI
        $scope.$watchCollection('dimensions', function(dimensions) {
          // Only attach the typeahead logic if there are dimensions available
          if (dimensions.length > 0) {
            // Attach X and Y variables to the dimension list
            // We copy the dimensions list to not interfere with it in other controllers
            var typeaheadDimensions = dimensions.slice(0);
            typeaheadDimensions.splice(0, 0, 'x', 'y');

            // Update Dimension String for default tooltip
            var dimensionsAsString = '';
            dimensions.forEach(function(dimension) {
              dimensionsAsString = dimensionsAsString + dimension + ', ';
            });
            editorController.popup.defaultContentDimensions = dimensionsAsString;

            // Update textcomplete Plugin
            $('#formulaInput').textcomplete([{
              words: typeaheadDimensions,
              match: /\b(\w{0,})$/,
              search: function(term, callback) {
                callback($.map(this.words, function(word) {
                  var currentWord = word.indexOf(term) === 0 ? word : null;
                  if (currentWord !== null)
                    editorController.popup.lastTextCompleteWord = currentWord;
                  return word.indexOf(term) === 0 ? word : null;
                }));
              },
              index: 1,
              replace: function(word) {
                return word + ' ';
              }
            }])
            .on({
              'textComplete:show': function (e) {
                editorController.updatePopup(editorController.popup.lastTextCompleteWord);
              },
              'textComplete:hide': function (e) {
                editorController.updatePopup();
              }
            });
          }
        });
      },
      controllerAs: 'editor'
    };
  }]);
