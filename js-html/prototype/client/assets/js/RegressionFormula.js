(function() {
RCUBE.RegressionFormula = function(formula) {
  this._formula = '';
  this._valid = false;
  this._reconstructedFormula = '';
  this._validVariables = [];
  this.update(formula);
};

RCUBE.RegressionFormula.prototype.setValidVariables = function(validVariables) {
  this._validVariables = validVariables;
  this.update(this._formula);
};

RCUBE.RegressionFormula.prototype.update = function(formula) {
  var self = this;
  this._valid = false;
  // Fallback to empty formula
  if (typeof(formula) == 'undefined')
    return;
  this._formula = formula.slice(0);
  // Regex formulas for variables and operators
  this._regexVariables = /([^\^\+\-\:\*\/\|\s]+)/g;
  this._regexOperators = /([\^\+\-\:\*\/\|])/g;
  // Apply regex to the input formula
  this._variables = formula.match(this._regexVariables);
  this._operators = formula.match(this._regexOperators);

  // Check the formula for validity
  if (this._variables !== null && this._operators !== null && this._operators.length == this._variables.length - 1) {
    this._valid = true;
    this._variables.forEach(function(variable, index) {
      // check if the current variable is valid
      if (self._validVariables.indexOf(variable) == -1) {
        self._valid = false;
        return;
      }
      self._reconstructedFormula = self._reconstructedFormula + variable;
      // If it is not the last element, attach the operator
      if (index != self._variables.length - 1)
        self._reconstructedFormula = self._reconstructedFormula + self._operators[index];
    });
  }
};

RCUBE.RegressionFormula.prototype.isValid = function(){
  return this._valid;
};

RCUBE.RegressionFormula.prototype.toString = function(){
  return this._reconstructedFormula;
};
})();
