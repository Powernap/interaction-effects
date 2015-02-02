angular.module('cube')
  .directive('formulaEditor', ['$rootScope', 'data', function($rootScope, data) {
    return {
      restrict: 'E',
      templateUrl: 'app/directives/formula-editor.html',

      controller: function($scope) {
        var editorController = this;
        this.popup = {};
        this.popup.header = 'My Header';
        this.popup.content = 'My Body';
        this.popup.show = false;

        this.updatePopup = function(name){
          console.log(name);
          if (name !== undefined){
            editorController.popup.header = name;
            // $scope.$apply(editorController.popup.content = name);
            editorController.popup.content = 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';
            $scope.$apply();
          }
          else {
            // TODO: Hier weitermachen. Default-Tooltup in watchcollection definieren
            // TODO: HTML Inject machen
            var dimensions = data.dataset.getDimensionNames();
            var dimensionString = '';
            dimensions.forEach(function(dimension) {
              dimensionString = dimensionString + dimension + ', ';
            });
            editorController.popup.header = 'Available commands';
            editorController.popup.content = dimensionString.toString();
            $scope.$apply();
          }
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
            $('#formulaInput').textcomplete([{
              words: typeaheadDimensions,
              match: /\b(\w{0,})$/,
              search: function(term, callback) {
                callback($.map(this.words, function(word) {
                  var currentWord = word.indexOf(term) === 0 ? word : null;
                  if (currentWord !== null)
                    editorController.updatePopup(currentWord);
                  return word.indexOf(term) === 0 ? word : null;
                }));
              },
              index: 1,
              replace: function(word) {
                return word + ' ';
              }
            }]);
          }
        });
      },
      controllerAs: 'editor'
    };
  }]);
