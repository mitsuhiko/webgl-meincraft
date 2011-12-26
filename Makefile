all: compile

watch-compile:
	coffee -cwo compiled src/*.coffee

compile:
	coffee -co compiled src/*.coffee

upload: compile
	rsync -a . pocoo.org:public_html/webglmc/
