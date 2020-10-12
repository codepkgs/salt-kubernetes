schedule:
  highstate:
    function: state.highstate
    cron: '*/30 * * * *'
    splay:
      start: 30
      end: 120