watch-compile:
	coffee -cwo compiled src/*.coffee

compile:
	coffee -co compiled src/*.coffee

upload:
	rsync -a . pocoo.org:public_html/webglmc/
