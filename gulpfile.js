var gulp = require('gulp'),
	peg = require('gulp-peg'),
//	browserify = require('gulp-browserify'),
	rename = require('gulp-rename'),
	replace = require('gulp-replace'),
	coffee = require('gulp-coffee'),
	preprocess = require('gulp-preprocess'),
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

gulp.task("dist-coffee", function(){
	return gulp
		.src("lib/T5.coffee")
		.pipe(fileinclude({
			"prefix" : "#"
		}))
		.pipe(preprocess({context: { dist : true } }))
		.pipe(coffee())
		.pipe(gulp.dest("gen/"));
});

gulp.task("dist", ["default", "dist-coffee"]);

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
