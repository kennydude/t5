var gulp = require('gulp'),
	peg = require('gulp-peg'),
//	browserify = require('gulp-browserify'),
	rename = require('gulp-rename'),
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

/*

WHY DOES GULP NOT LIKE THIS??????

I TRUESTED YOU

gulp.task('runtime', function() {
	// Runtime
	gulp.src('node_modules/ent/index.js')
		.pipe(browserify({
			standalone: true
		}))
		.pipe(rename("ent.js"))
		.pipe(gulp.dest('./gen/'))
});

*/

gulp.task('default', ["pegjs"]);
