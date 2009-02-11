/* ANSI Datepicker Calendar - David Lee 2005

  david [at] davelee [dot] com [dot] au

  project homepage: http://projects.exactlyoneturtle.com/date_picker/

  License:
  use, modify and distribute freely as long as this header remains intact;
  please mail any improvements to the author
*/

var DatePicker = {
  version: 0.31,

  /* Configuration options */

  // if false, hide last row if empty
  constantHeight: true,

  // show select list for year?
  useDropForYear: false,

  // show select list for month?
  useDropForMonth: false,

  // number of years before current to show in select list
  yearsPriorInDrop: 10,

  // number of years after current to show in select list
  yearsNextInDrop: 10,

  // The current year
  year: new Date().getFullYear(),
  
  // The first day of the week (0=Sunday, 1=Monday, ...)
  firstDayOfWeek: 0,

  // show only 3 chars for month in link
  abbreviateMonthInLink: true,

  // show only 2 chars for year in link
  abbreviateYearInLink: false,

  // eg 1st
  showDaySuffixInLink: false,

  // eg 1st; doesn't play nice w/ month selector
  showDaySuffixInCalendar: false,

  // px size written inline when month selector used
  largeCellSize: 22,

  // if set, choosing a day will send the date to this URL, eg 'someUrl?date='
  urlBase: null,

  // show a cancel button to revert choice
  showCancelLink: true,

  // stores link text to revert to when cancelling
  _priorLinkText: [],

  // stores date before datepicker to revert to when cancelling
  _priorDate: [],

  _options: [],

  months: 'January,February,March,April,May,June,July,August,September,October,November,December'.split(','),

  days: 'Sun,Mon,Tue,Wed,Thu,Fri,Sat'.split(','),

  dateFormat: 'yyyy/mm/dd',
  dateSeparator: '-',

  /* Method declarations */

  toggleDatePicker: function (id, options) {
    if (null == options) options = {};
    var calendar = DatePicker.findCalendarElement(id);
    if (calendar.style.display == 'block') {  // If showing, hide
      calendar.style.display = 'none';
    } else {                                  // Else, show
      DatePicker.initializeOptions(id, options);
      calendar.style.display = 'block';
      DatePicker._priorLinkText[id] = DatePicker.findLinkElement(id).innerHTML;
      DatePicker._priorDate[id] = document.getElementById(id).value;
      DatePicker.writeCalendar(id);
    }
  },

  initializeOptions: function(id, options) {
    DatePicker._options[id] = { dateFormat: DatePicker.dateFormat,
                          dateSeparator: DatePicker.dateSeparator};

    for(opt in options) {
      DatePicker._options[id][opt] = options[opt];
    }

    if (null == DatePicker._options[id].formatter) {
      DatePicker._options[id].formatter = DatePicker.formatterFor(
              DatePicker._options[id].dateFormat, DatePicker._options[id].dateSeparator);
    }

    if (null == DatePicker._options[id].parser) {
      DatePicker._options[id].parser = DatePicker.parserFor(DatePicker._options[id].dateFormat);
    }
  },

  cancel: function (id) {
    DatePicker.findLinkElement(id).innerHTML = DatePicker._priorLinkText[id];
    document.getElementById(id).value = DatePicker._priorDate[id];
    DatePicker.findCalendarElement(id).style.display = 'none';
  },

  // mitigate clipping when new month has less days than selected date
  unclipDates: function (d1, d2) {
    if (d2.getDate() != d1.getDate()) {
      d2 = new Date(d2.getFullYear(), d2.getMonth(), 0);
    }

    return d2;
  },

  // change date given an offset from the current date as a number of months (+-)
  changeCalendar: function (id, offset) {
    var d1 = DatePicker.getSelectedDate(id), d2;
    if (offset % 12 == 0) { // 1 year forward / back (fix Safari bug)
      d2 = new Date (d1.getFullYear() + offset / 12, d1.getMonth(), d1.getDate() );
    } else if (d1.getMonth() == 0 && offset == -1) {// tiptoe around another Safari bug
      d2 = new Date (d1.getFullYear() - 1, 11, d1.getDate() );
    } else {
      d2 = new Date (d1.getFullYear(), d1.getMonth() + offset, d1.getDate() );
    }

    d2 = DatePicker.unclipDates(d1, d2);
    DatePicker.setDate(id, d2);
    DatePicker.writeCalendar(id);
  },

  setDate: function (id, date) {
    document.getElementById(id).value = DatePicker._options[id].formatter(date);
    DatePicker.findLinkElement(id).innerHTML = DatePicker._options[id].formatter(date);
  },

  pickDate: function (id, selectedDate) {
    DatePicker.setDate(id, selectedDate);
    DatePicker.toggleDatePicker(id);
    if (DatePicker.urlBase) {
      document.location.href = DatePicker.urlBase + DatePicker.formatterFor('yyyy/mm/dd', '-')(selectedDate);
    }
  },

  getMonthName: function(monthNum) { //anomalous
    return DatePicker.months[monthNum];
  },

  /**
   * Returns a function that formats a date according to a specified format.
   * The format parameter must be composed of any of the following components,
   * separated by slash (/) characters:
   *   d: day number, e.g. 1
   *   dd: day number with leading zero, e.g. 01
   *   m: month number, e.g. 9
   *   mm: month number with leading zero, e.g. 09
   *   mmm: abbreviated month name, e.g. Sep
   *   mmmm: full month name, e.g. September
   *   yy: last two digits of the year, e.g. 02
   *   yyyy: four digit year, e.g. 2002
   */
  formatterFor: function(format, separator) {
    if (null == separator) throw "No date separator specified";
    if (null == format.match(/([ymd]{1,4}\/){2}[ymd]{1,4}/)) {
      throw "Invalid date format specified";
    }

    var formatComponents = format.split(/[-\/]/);
    if (3 != formatComponents.length) {
      throw "Invalid date format specified - too many components found";
    }

    for (var i = 0; i < 3; i++) {
      switch(formatComponents[i]) {
        case 'd': case 'dd': case 'm': case 'mm': case 'mmm': case 'mmmm':
        case 'yy':  case 'yyyy':
          break;
        default:
          throw "Invalid format specifier found at component index " + (1+i).toString();
      }
    }


    return function(date) {
      var result = [];
      for (var i = 0; i < 3; i++) {
        switch(formatComponents[i]) {
          case 'd': result.push(date.getDate().toString()); break;
          case 'dd': result.push(('00' + date.getDate()).match(/\d\d$/)); break;
          case 'm': result.push((date.getMonth() + 1).toString()); break;
          case 'mm': result.push(('00' + (date.getMonth() + 1)).match(/\d\d$/)); break;
          case 'mmm': result.push(DatePicker.months[date.getMonth()].substring(0,3)); break;
          case 'mmmm': result.push(DatePicker.months[date.getMonth()]); break;
          case 'yy': result.push(('00' + date.getFullYear() % 100).match(/\d\d$/)); break;
          case 'yyyy': result.push(date.getFullYear()); break;
        }
      }

      return result.join(separator);
    };
  },

  /**
  * Returns a function that parses a date string into a real Date object.
  * The format argument must contain only the following characters: y, m,
  * d or slash (/).  If any other characters is contained in the
  * string, an exception will be thrown.  Additionnaly, the format string
  * cannot contain more than three elements, as separated by the slash and
  * dash characters.
  *
  * The returned function will respond to a single argument, and will return
  * a Date object, or throw an exception if the date would have been invalid.
  */
  parserFor: function(format) {
    if (null == format.match(/([ymd]{1,4}\/){2}[ymd]{1,4}/)) {
      throw "Invalid date format specified";
    }

    var formatComponents = format.split(/[-\/]/);
    if (3 != formatComponents.length) {
      throw "Invalid date format specified - too many components found";
    }

    // Make sure we understand everything at each position
    for (var i = 0; i < 3; i++) {
      switch(formatComponents[i].substring(0, 1)) {
        case 'd': case 'm': case 'y': break;
        default:
          throw "Invalid format specifier found at component index " + (1+i).toString();
      }
    }

    return function(stringifiedDate) {
      var dateComponents = stringifiedDate.split(/[-\/\s\.]/);
      var day, month, year;
      for (var i = 0; i < 3; i++) {
        switch(formatComponents[i].substring(0, 1)) {
          case 'd': day   = DatePicker.toInteger(dateComponents[i]); break;
          case 'm': month = DatePicker.toInteger(dateComponents[i]); break;
          case 'y': year  = DatePicker.toInteger(dateComponents[i]); break;
        }
      }

      if (day < 1 || day > 31) throw "Invalid day specified";
      if (month < 1 || month > 12) throw "Invalid month specified";
      if (year < 1) throw "Invalid year specified";

      return new Date(year, month - 1, day);
    };
  },

  toInteger: function(str) {
    if (!/^\d/.test(str)) throw "<" + str + "> is an invalid number - it does not start with a digit";
    var result;
    if (/^0/.test(str)) {
      result = parseInt(str.substring(str.search(/[1-9]/)));
    } else {
      result = parseInt(str);
    }

    return result;
  },

  getSelectedDate: function (id) {
    if (document.getElementById(id).value == '') return new Date(); // default to today if no value exists
    return DatePicker._options[id].parser(document.getElementById(id).value);
  },

  makeChangeCalendarLink: function (id, label, offset) {
    return ('<a href="#" onclick="DatePicker.changeCalendar(\''+id+'\','+offset+')">' + label + '</a>');
  },

  formatDay: function (n) {
    var x;
    switch (String(n)){
      case '1' :
      case '21': case '31': x = 'st'; break;
      case '2' : case '22': x = 'nd'; break;
      case '3' : case '23': x = 'rd'; break;
      default:
        x = 'th';
    }

    return n + x;
  },

  writeMonth: function (id, n) {
    if (DatePicker.useDropForMonth) {
      var opts = '';
      for (i in DatePicker.months) {
        sel = (i == DatePicker.getSelectedDate(id).getMonth() ? 'selected="selected" ' : '');
        opts += '<option ' + sel + 'value="'+ i +'">' + DatePicker.getMonthName(i) + '</option>';
      }

      return '<select onchange="DatePicker.selectMonth(\'' + id + '\', DatePicker.value)">' + opts + '</select>';
    } else {
      return DatePicker.getMonthName(n)
    }
  },

  writeYear: function (id, n) {
    if (DatePicker.useDropForYear) {
      var min = DatePicker.year - DatePicker.yearsPriorInDrop;
      var max = DatePicker.year + DatePicker.yearsNextInDrop;
      var opts = '';
      for (i = min; i < max; i++) {
        sel = (i == DatePicker.getSelectedDate(id).getFullYear() ? 'selected="selected" ' : '');
        opts += '<option ' + sel + 'value="'+ i +'">' + i + '</option>';
      }

      return '<select onchange="DatePicker.selectYear(\'' + id + '\', DatePicker.value)">' + opts + '</select>';
    } else {
      return n
    }
  },

  selectMonth: function (id, n) {
    d = DatePicker.getSelectedDate(id)
    d2 = new Date(d.getFullYear(), n, d.getDate())
    d2 = DatePicker.unclipDates(d, d2)
    DatePicker.setDate(id, d2.getFullYear() + '-' + (Number(n)+1) + '-' + d2.getDate() )
    DatePicker.writeCalendar(id)
  },

  selectYear: function (id, n) {
    d = DatePicker.getSelectedDate(id)
    d2 = new Date(n, d.getMonth(), d.getDate())
    d2 = DatePicker.unclipDates(d, d2)
    DatePicker.setDate(id, n + '-' + (d2.getMonth()+1) + '-' + d2.getDate() )
    DatePicker.writeCalendar(id)
  },

  writeCalendar: function (id) {
    var selectedDate = DatePicker.getSelectedDate(id);
    var firstWeekday = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1).getDay();
    var lastDateOfMonth = new Date(selectedDate.getFullYear(), selectedDate.getMonth() + 1, 0).getDate();
    var day  = 1; // current day of month

    // not quite entirely pointless: fix Safari display bug with absolute positioned div
    DatePicker.findLinkElement(id).innerHTML = DatePicker.findLinkElement(id).innerHTML;

    var o = '<table cellspacing="1">'; // start output buffer
    o += '<thead><tr>';

    // month buttons
    o +=
      '<th style="text-align:left">' + DatePicker.makeChangeCalendarLink(id,'&lt;',-1) + '</th>' +
      '<th colspan="5">' + (DatePicker.showDaySuffixInCalendar ? DatePicker.formatDay(selectedDate.getDate()) : selectedDate.getDate()) +
      ' ' + DatePicker.writeMonth(id, selectedDate.getMonth()) + '</th>' +
      '<th style="text-align:right">' + DatePicker.makeChangeCalendarLink(id,'&gt;',1) + '</th>';
    o += '</tr><tr>';

    // year buttons
    o +=
      '<th colspan="2" style="text-align:left">' + DatePicker.makeChangeCalendarLink(id,'&lt;&lt;',-12) + '</th>' +
      '<th colspan="3">' + DatePicker.writeYear(id,  selectedDate.getFullYear()) + '</th>' +
      '<th colspan="2" style="text-align:right">' + DatePicker.makeChangeCalendarLink(id,'&gt;&gt;',12) + '</th>';
    o += '</tr><tr class="day_labels">';

    // day labels
    for(var i = 0; i < DatePicker.days.length; i++) {
      o += '<th>' + DatePicker.days[(i+DatePicker.firstDayOfWeek) % 7] + '</th>';
    }
    o += '</tr></thead>';

    if (DatePicker.showCancelLink) {
      o += '<tfoot><tr><td colspan="7"><div class="cancel_butt"><a href="#" onclick="DatePicker.cancel(\''+id+'\')">[x] cancel</a></div></td></tr></tfoot>';
    }

    // day grid
    o += '<tbody>';
    for(rows = 1; rows < 7 && (DatePicker.constantHeight || day < lastDateOfMonth); rows++) {
      o += '<tr>';
      for(var day_num = 0; day_num < DatePicker.days.length; day_num++) {
        var translated_day = (DatePicker.firstDayOfWeek + day_num) % 7
        if ((translated_day >= firstWeekday || day > 1) && (day <= lastDateOfMonth) ) {
          style = (DatePicker.selectMonth ? 'style="width: ' + DatePicker.largeCellSize + 'px"' : '');
          o +=
            '<td ' + style + '>' + // link : each day
            "<a href=\"#\" onclick=\"DatePicker.pickDate('" + id + "', new Date(" + selectedDate.getFullYear() + ", " + selectedDate.getMonth() + ", " + day + ")); return false;\">" + day + '</a>' +
            '</td>';
          day++;
        } else {
          o += '<td>&nbsp;</td>';
        }
      }

      o += '</tr></tbody>';
    }

    o += '</table>';

    DatePicker.findCalendarElement(id).innerHTML = o;
  },

  findCalendarElement: function(id) {
    return document.getElementById('_' + id + '_calendar');
  },

  findLinkElement: function(id) {
    return document.getElementById('_' + id + '_link');
  }
};
