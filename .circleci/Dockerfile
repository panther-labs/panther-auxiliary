FROM hashicorp/terraform
RUN apk add bash
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/pytho
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools && pip3 install 
RUN curl https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
