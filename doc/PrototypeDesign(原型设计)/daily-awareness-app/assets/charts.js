(function() {
  var style = getComputedStyle(document.documentElement);
  var accent = style.getPropertyValue('--accent').trim();
  var accent2 = style.getPropertyValue('--accent2').trim();
  var ink = style.getPropertyValue('--ink').trim();
  var muted = style.getPropertyValue('--muted').trim();
  var rule = style.getPropertyValue('--rule').trim();
  var bg2 = style.getPropertyValue('--bg2').trim();
  var success = style.getPropertyValue('--success').trim();
  var warning = style.getPropertyValue('--warning').trim();
  var danger = style.getPropertyValue('--danger').trim();

  // --- Chart: Match Rate Trend ---
  var chartMatchRate = echarts.init(document.getElementById('chart-match-rate'), null, { renderer: 'svg' });
  chartMatchRate.setOption({
    animation: false,
    tooltip: {
      trigger: 'axis',
      appendToBody: true,
      formatter: function(params) {
        var p = params[0];
        return p.name + '<br/>匹配率: <strong>' + p.value + '%</strong>';
      }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '10%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: ['6/16', '6/17', '6/18', '6/19', '6/20', '6/21', '6/22'],
      axisLine: { lineStyle: { color: rule } },
      axisLabel: { color: muted }
    },
    yAxis: {
      type: 'value',
      min: 0,
      max: 100,
      axisLine: { lineStyle: { color: rule } },
      axisLabel: { color: muted, formatter: '{value}%' },
      splitLine: { lineStyle: { color: rule, type: 'dashed' } }
    },
    series: [{
      name: '匹配率',
      type: 'line',
      data: [60, 75, 70, 85, 80, 90, 67],
      smooth: true,
      symbol: 'circle',
      symbolSize: 8,
      lineStyle: { color: accent, width: 3 },
      itemStyle: { color: accent, borderWidth: 2, borderColor: bg2 },
      areaStyle: {
        color: {
          type: 'linear',
          x: 0, y: 0, x2: 0, y2: 1,
          colorStops: [
            { offset: 0, color: accent + '33' },
            { offset: 1, color: accent + '05' }
          ]
        }
      }
    }]
  });
  window.addEventListener('resize', function() { chartMatchRate.resize(); });

  // --- Chart: Timeline vs Agenda Comparison ---
  var chartTimelineCompare = echarts.init(document.getElementById('chart-timeline-compare'), null, { renderer: 'svg' });
  chartTimelineCompare.setOption({
    animation: false,
    tooltip: {
      trigger: 'axis',
      appendToBody: true,
      formatter: function(params) {
        var result = params[0].name + '<br/>';
        params.forEach(function(p) {
          result += p.marker + ' ' + p.seriesName + ': <strong>' + p.value + '</strong><br/>';
        });
        return result;
      }
    },
    legend: {
      data: ['计划事程', '实际记录'],
      top: 0,
      textStyle: { color: muted }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '15%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: ['09:00', '12:00', '15:00', '18:00'],
      axisLine: { lineStyle: { color: rule } },
      axisLabel: { color: muted }
    },
    yAxis: {
      type: 'value',
      min: 0,
      max: 5,
      axisLine: { lineStyle: { color: rule } },
      axisLabel: { color: muted },
      splitLine: { lineStyle: { color: rule, type: 'dashed' } }
    },
    series: [
      {
        name: '计划事程',
        type: 'bar',
        data: [1, 1, 1, 1],
        barWidth: '30%',
        itemStyle: { color: accent2 + '80', borderRadius: [4, 4, 0, 0] }
      },
      {
        name: '实际记录',
        type: 'bar',
        data: [1, 1, 0, 0],
        barWidth: '30%',
        itemStyle: {
          color: function(params) {
            return params.value > 0 ? success : danger;
          },
          borderRadius: [4, 4, 0, 0]
        }
      }
    ]
  });
  window.addEventListener('resize', function() { chartTimelineCompare.resize(); });

  // --- Chart: Behavior Heatmap ---
  var chartBehaviorHeatmap = echarts.init(document.getElementById('chart-behavior-heatmap'), null, { renderer: 'svg' });
  var behaviors = ['吃早饭', '吃药', '喝水', '吃午饭', '午睡', '运动', '吃晚饭'];
  var days = ['6/16', '6/17', '6/18', '6/19', '6/20', '6/21', '6/22'];
  var heatmapData = [
    [0, 0, 1], [0, 1, 1], [0, 2, 1], [0, 3, 1], [0, 4, 1], [0, 5, 1], [0, 6, 1],
    [1, 0, 1], [1, 1, 1], [1, 2, 0], [1, 3, 1], [1, 4, 1], [1, 5, 1], [1, 6, 0],
    [2, 0, 0], [2, 1, 1], [2, 2, 0], [2, 3, 1], [2, 4, 0], [2, 5, 0], [2, 6, 1],
    [3, 0, 1], [3, 1, 1], [3, 2, 1], [3, 3, 1], [3, 4, 1], [3, 5, 1], [3, 6, 1],
    [4, 0, 0], [4, 1, 1], [4, 2, 1], [4, 3, 0], [4, 4, 1], [4, 5, 0], [4, 6, 1],
    [5, 0, 1], [5, 1, 0], [5, 2, 1], [5, 3, 0], [5, 4, 1], [5, 5, 0], [5, 6, 0],
    [6, 0, 1], [6, 1, 1], [6, 2, 1], [6, 3, 1], [6, 4, 1], [6, 5, 1], [6, 6, 0]
  ];

  chartBehaviorHeatmap.setOption({
    animation: false,
    tooltip: {
      appendToBody: true,
      formatter: function(params) {
        return days[params.value[0]] + ' ' + behaviors[params.value[1]] +
          '<br/>状态: <strong>' + (params.value[2] === 1 ? '已完成' : '未完成') + '</strong>';
      }
    },
    grid: {
      left: '12%',
      right: '5%',
      bottom: '10%',
      top: '5%'
    },
    xAxis: {
      type: 'category',
      data: days,
      axisLine: { lineStyle: { color: rule } },
      axisLabel: { color: muted },
      splitArea: { show: false }
    },
    yAxis: {
      type: 'category',
      data: behaviors,
      axisLine: { lineStyle: { color: rule } },
      axisLabel: { color: ink },
      splitArea: { show: false }
    },
    visualMap: {
      min: 0,
      max: 1,
      show: false,
      inRange: {
        color: ['#FFEBEE', success]
      },
      outOfRange: { color: 'transparent' }
    },
    series: [{
      type: 'heatmap',
      data: heatmapData,
      label: {
        show: true,
        formatter: function(p) {
          return p.value[2] === 1 ? '✓' : '✗';
        },
        color: function(p) {
          return p.value[2] === 1 ? '#FFFFFF' : danger;
        },
        fontSize: 14,
        fontWeight: 'bold'
      },
      itemStyle: {
        borderWidth: 2,
        borderColor: bg2,
        borderRadius: 6
      }
    }]
  });
  window.addEventListener('resize', function() { chartBehaviorHeatmap.resize(); });
})();
