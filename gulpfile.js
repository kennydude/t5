var gulp = require('gulp'),
	peg = require('gulp-peg'),
	fileinclude = require('gulp-file-include');

gulp.task("pegjs", function(){
	return gulp
		.src("lib/*.pegjs")
		.pipe(fileinclude({
			"prefix" : "//"
		}))
		.pipe(peg())
		.pipe(gulp.dest('peg/'));
});

gulp.task('default', ["pegjs"]);
