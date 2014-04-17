
module.exports = (grunt) ->
  require('load-grunt-tasks') grunt

  grunt.initConfig
    watch:
      options:
        livereload: false
      src:
        files: ['src/**/*.coffee']
        tasks: ['src']
      test:
        files: ['src/**/*.coffee', 'test/**/*.coffee']
        tasks: ['test']

    coffee:
      src:
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'lib'
        ext: '.js'
      test:
        expand: true
        cwd: 'test'
        src: ['**/*.coffee']
        dest: 'test_lib'
        ext: '.js'

    clean:
      src: ['lib']
      test: ['test_lib']

    coffeelint:
      options:
        max_line_length:
          value: 120
      src:
        'src/**/*.coffee'
      test:
        'test/**/*.coffee'

    mochaTest:
      test:
        options:
          reporter: 'spec'
          timeout: 400000
          grep: process.env.GREP
        src: ['test_lib/*_test.js']

    env:
      coverage:
        APP_SRV_COVERAGE: "../coverage/instrument"

    instrument:
      files: ["lib/**/*.js"]
      options:
        lazy: true
        basePath: "coverage/instrument"

    storeCoverage:
      options:
        dir: "coverage/reports"

    makeReport:
      src: "coverage/reports/**/*.json"
      options:
        type: "lcov"
        dir: "coverage/reports"
        print: "detail"

    open:
      htmlReport:
        path: "coverage/reports/lcov-report/index.html"

    coverage:
      options:
        thresholds:
          statements: 89
          branches: 50
          lines: 90
          functions: 90

        root: "coverage"

  grunt.registerTask('src', ['coffeelint:src', 'clean:src', 'coffee:src'])
  grunt.registerTask('compile:test', ['coffeelint:test', 'clean:test', 'coffee:test'])
  grunt.registerTask('test', ['src', 'compile:test', 'mochaTest'])
  grunt.registerTask('coverage', [
    'src'
    'env:coverage'
    'src'
    'compile:test'
    'instrument'
    'mochaTest'
    'storeCoverage'
    'makeReport'
    'coverage'
  ])
