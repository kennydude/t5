var gulp = require('gulp');
var peg = require('gulp-peg');

gulp.task("pegjs", function(){
	return gulp .src("lib/*.pegjs")
		.pipe(peg())
		.pipe(gulp.dest('peg/'));
});

gulp.task('default', ["pegjs"]);
