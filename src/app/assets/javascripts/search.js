//= require highlightRegex.min.js

var chartData = [];
var pieData = [];

function toggle_gallery () {
  if ($('#gallery').css('visibility') === 'hidden') {
    $('#res').fadeToggle();
    $('#gallery').css('visibility', 'visible');
    $('#gallery').css('height', 'auto');
    $(window).trigger('resize');
  } else {
    $('#gallery').fadeToggle();
    $('#res').fadeToggle();
    $(window).trigger('resize');
  }
      
}

var loadChart = function (chartAPI) {
  chartAPI = (chartAPI !== 'undefined') ? chartAPI : "";

  if (chartData.length === 0)
  {
    if (chartAPI !== '')
    {
      $.getJSON( chartAPI )
      .done(function( data ) {
        if (data.length > 1) {
          for(i=0; i< data.length; i++)
          {
            var row = data[i];
            newRow = row.slice(0, 3);
            console.log(newRow[0])
            newRow.push(new Date(row[3]));
            newRow.push(new Date(row[4]));
            chartData[i] = newRow;
          }
          $('#toggleChart-1').show();
          $('#pie-chart').show();
          $('#bar-chart').show();
        }
      });
    }
  }
  else if ($('#chart-1').css('visibility') === 'hidden') {
    google.charts.load('current', {'packages':['timeline', 'corechart']});
    google.charts.setOnLoadCallback(drawChart);
    google.charts.setOnLoadCallback(drawPie);
    google.charts.setOnLoadCallback(drawBar);
    var drawChart = function () {
      var container = document.getElementById('chart-1');
      var chart = new google.visualization.Timeline(container);
      var dataTable = new google.visualization.DataTable();

      dataTable.addColumn({type: "string", id: "Name"});
      dataTable.addColumn({type: "string", id: 'dummy bar label' });
      dataTable.addColumn({type: "string", role: 'tooltip', 'p': {'html': true} });
      dataTable.addColumn({type: "date", id: "Start"});
      dataTable.addColumn({type: "date", id: "End"});
      dataTable.addRows(chartData);

      var options = {
        timeline: { colorByRowLabel: true },
        tooltip: {isHtml: true},
      };

      chart.draw(dataTable, options);


      $("#chart-tabs").css('visibility', 'visible');
      $("#histogram-tab").tab("show");
      $('#chart-1').css('visibility', 'visible');
      $('#chart-1').css('height', 'auto');
      $(window).trigger('resize');
    }; drawChart();
    var drawPie = function () {
      var pieContainer = document.getElementById('pie-chart');
      var pieChart = new google.visualization.PieChart(pieContainer);
      var pieDataTable = new google.visualization.DataTable();

      pieDataTable.addColumn({type: "string", id: "Year"});
      pieDataTable.addColumn({type: "number", id: "Occurences" });
      pieDataTable.addRows(pieData);

      var pieOptions = {
        tooltip: {isHtml: true},
      };

      pieChart.draw(pieDataTable, pieOptions);

      $('#pie-chart').css('visibility', 'visible');
      $('#pie-chart').css('height', 'auto');
      $(window).trigger('resize');
    }; drawPie();
    var drawBar = function () {
      var barContainer = document.getElementById('bar-chart');
      var barChart = new google.visualization.ColumnChart(barContainer);
      var barDataTable = new google.visualization.DataTable();

      barDataTable.addColumn({type: "string", id: "Year"});
      barDataTable.addColumn({type: "number", id: "Occurences" });
      barDataTable.addRows(pieData);

      var barOptions = {
        tooltip: {isHtml: true},
      };

      barChart.draw(barDataTable, barOptions);
      $('#bar-chart').css('visibility', 'visible');
      $('#bar-chart').css('height', 'auto');
      $(window).trigger('resize');
    }; drawBar();
  }
  else {
    $("#chart-tabs").fadeToggle();
    $('#chart-1').fadeToggle();
    $('#pie-chart').fadeToggle();
    $('#bar-chart').fadeToggle();
    $(window).trigger('resize');
  }
};

var loadPieData = function (pieChartAPI) {
  pieChartAPI = (pieChartAPI !== 'undefined') ? pieChartAPI : "";

  if (pieData.length === 0)
  {
    if (pieChartAPI !== '')
    {
      $.getJSON( pieChartAPI )
      .done(function( data ) {
        if (data.length > 1) {
          for(i=0; i< data.length; i++)
          {
            var row = data[i];
            pieData[i] = row;
          }
          $('#pie-chart').show();
          $('#bar-chart').show();
        }
      });
    }
  }
  else if ($('#pie-chart').css('visibility') === 'hidden') {
    google.charts.load('current', {'packages':['corechart']});
  }
  else {
    $(window).trigger('resize');
  }
};

toggle_search_tools_when_regex = function(){
  $disabled = $("select[name='sm']").val() == 5;
  $("select[name='m']").prop("disabled", $disabled);
};

$(function() {
  // Search method is Regex
  $('select').on('change', function() {
    toggle_search_tools_when_regex();
  });
  toggle_search_tools_when_regex();
  if($("select[name='sm']").val() == 5){
    $('.list-group-item').highlightRegex(new RegExp($("input.simple-search").val(), "ig"));
  }
});

$('#toggle-gallery').click(function(){toggle_gallery();});
