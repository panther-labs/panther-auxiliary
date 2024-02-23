.PHONY: test

bucket = panther-public-sam-artifacts

iter:
	set -e; \
	for samapp in `ls`; do \
	    if [ -d $$samapp ]; then \
			cd $$samapp; \
			make --makefile=../Makefile $(action) samdir=$$samapp; \
			cd ..; \
		fi; \
	done
	
publish:
	sam build --use-container --build-image public.ecr.aws/sam/build-python3.11; sam package --s3-bucket $(bucket)-$(region) --output-template-file ../../cloudformation/panther-$(samdir)-$(region).yml

setup:
	python3 -m venv venv; venv/bin/pip install -r src/requirements.txt; venv/bin/pip install pytest pylint

clean:
	rm -rf venv

test:
	AWS_DEFAULT_REGION=us-west-2 venv/bin/pytest test/

lint:
	venv/bin/pylint -j 0 --max-line-length 140 --score no src/
