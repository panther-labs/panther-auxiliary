.PHONY: test

bucket = panther-public-sam-artifacts

iter:
	find . -depth 1 -type d | xargs -I % make -C % --makefile=../Makefile $(action) samdir=%
	
publish:
	sam build --use-container --build-image public.ecr.aws/sam/build-python3.11; sam package --s3-bucket $(bucket)-$(region) --output-template-file ../../cloudformation/$(samdir)-$(region).yml

setup:
	find . -depth 1 -type d | xargs -I % python3 -m venv %/venv
	find . -depth 1 -type d | xargs -I % bash -c "%/venv/bin/pip install -r %/src/requirements.txt"
	find . -depth 1 -type d | xargs -I % bash -c "%/venv/bin/pip install pytest pylint"

clean:
	rm -rf */venv

test:
	find . -depth 1 -type d | xargs -I % bash -c "pushd %; AWS_DEFAULT_REGION=us-west-2 venv/bin/pytest test/; popd"

lint:
	find . -depth 1 -type d | xargs -I % bash -c "pushd %; venv/bin/pylint -j 0 --max-line-length 140 --score no src/; popd"
