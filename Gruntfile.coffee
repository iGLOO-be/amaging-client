
module.exports = (grunt) ->
  require('load-grunt-tasks') grunt

  grunt.initConfig
    watch:
      options:
        livereload: false
      coffee:
        files: ['src/**/*.coffee']
        tasks: ['default']
    coffee:
      main:
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'lib'
        ext: '.js'
    clean:
      lib: ['lib']
    coffeelint:
      options:
        max_line_length:
          value: 120
      src:
        'src/**/*.coffee'
