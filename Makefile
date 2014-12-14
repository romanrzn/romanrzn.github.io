
coffee_files = $(shell find -type f -name '*.coffee')
sass_files = $(shell find -type f -name '*.scss')

js_files = $(coffee_files:.coffee=.js)

all: clean gen
	@echo "Done all"

gen: coffee sass

coffee:
	@echo "Compiling coffee to js..."
	@coffee -c --bare $(coffee_files)

sass:
	@echo "Compiling sass to css..."
	@for f in $(sass_files); do sass -C --style compressed $${f} $${f/%.scss/.css}; done

clean:
	@echo "Performing clean..."
	@rm -f $(js_files)
