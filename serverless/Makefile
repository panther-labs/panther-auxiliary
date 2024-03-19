.PHONY: iter publish setup clean test lint

bucket = panther-public-sam-artifacts
finddir = find . -maxdepth 1 -mindepth 1 -type d
xargs = xargs -I %

iter:
	$(finddir) | $(xargs) make -C % --makefile=../Makefile $(action) samdir=%
	
publish:
	sam build --use-container --build-image public.ecr.aws/sam/build-python3.11; sam package --s3-bucket $(bucket)-$(region) --output-template-file ../../cloudformation/$(samdir)-$(region).yml

setup:
	$(finddir) | $(xargs) python3 -m venv %/venv
	$(finddir) | $(xargs) bash -c "%/venv/bin/pip install -r %/src/requirements.txt"
	$(finddir) | $(xargs) bash -c "%/venv/bin/pip install pytest pylint"

clean:
	rm -rf */venv

test:
	$(finddir) | $(xargs) bash -c "pushd %; AWS_DEFAULT_REGION=us-west-2 venv/bin/pytest test/; popd"

lint:
	$(finddir) | $(xargs) bash -c "pushd %; venv/bin/pylint -j 0 --max-line-length 140 --score no src/; popd"
