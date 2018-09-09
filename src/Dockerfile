FROM docker

RUN apk update && apk add openssh && \
    echo "=========Create SSH KEY=========" && ssh-keygen -f ~/.ssh/id_rsa && cat ~/.ssh/id_rsa.pub

RUN apk update && apk add git && \
    apk add tzdata && \
    apk add python3 && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache && \
    pip install awscli

ENV TZ Asia/Shanghai

# ADD requirements.txt /
# RUN pip install -r requirements.txt

# CMD python run.py

ADD . /root
ENTRYPOINT ["/root/build.sh"] 