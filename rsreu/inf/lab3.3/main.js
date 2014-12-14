// Generated by CoffeeScript 1.8.0
$(function() {
  var alpha, m, n, p, selector, _i, _len, _ref;
  p = 0.01;
  alpha = .5;
  m = 24;
  n = 3 * Math.pow(10, 5);
  config.define({
    title: 'p<sub>ош</sub>',
    "default": p,
    valid: function(v) {
      return v > 0 && v < .5;
    },
    change: function(v) {
      return p = v;
    }
  });
  config.define({
    title: 'Коэффициент группирования α',
    "default": alpha,
    valid: function(v) {
      return v > 0 && v < 1;
    },
    change: function(v) {
      return alpha = v;
    }
  });
  config.define({
    title: 'Длина последовательности N',
    "default": n,
    valid: function(v) {
      return v > 1;
    },
    change: function(v) {
      return n = v;
    }
  });
  config.define({
    title: 'Длина блока m',
    "default": m,
    valid: function(v) {
      return 10 < v && v < 500;
    },
    change: function(v) {
      return m = v;
    }
  });
  _ref = ['#blocks'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    selector = _ref[_i];
    $(selector).spinner({
      spin: function() {
        return false;
      }
    });
    $(selector).css('margin-right', '.4em');
    $(selector).parent().children('.ui-spinner-button').remove();
  }
  $('#apply-config').button().click(function() {
    return (function(p_, p) {
      var STATE_ERR, STATE_GOOD, blockErrors, errorBlocksCount, state, yesno, _p00, _p10;
      p = [[_p00 = (1 - p_ * Math.pow(2 * m, 1 - alpha)) / (1 - p_ * Math.pow(m, 1 - alpha)), 1 - _p00], [_p10 = 1 - (2 - Math.pow(2, 1 - alpha)), 1 - _p10]];
      console.log(JSON.stringify(p));
      yesno = function(yesprob) {
        return Math.random() <= yesprob;
      };
      blockErrors = [];
      STATE_GOOD = 0;
      STATE_ERR = 1;
      state = STATE_GOOD;
      while (len(blockErrors) < n) {
        switch (state) {
          case STATE_GOOD:
            blockErrors.push(0);
            if (yesno(p[0][1])) {
              state = STATE_ERR;
            }
            break;
          case STATE_ERR:
            blockErrors.push(1);
            if (yesno(p[1][0])) {
              state = STATE_GOOD;
            }
        }
      }
      $('#blocks').val(blockErrors.join(','));
      errorBlocksCount = len(filter_(blockErrors, function(x) {
        return !!x;
      }));
      $('#block-error-coeff').text(sprintf('%.3f', errorBlocksCount / (len(blockErrors))));
      return $('#grouping-coeff').text(sprintf('%.3f', ((log((len(blockErrors)) * p_ * m)) - (log(errorBlocksCount))) / (log(m))));
    })(p, null);
  });
  return $('#apply-config').click();
});

//# sourceMappingURL=main.js.map