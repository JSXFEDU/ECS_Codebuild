#!/usr/bin/env sh 

echo ============== PROCESSING OPTIONS ==============
echo $@

TEMP=`getopt -l path:,checkout:,help -- p:c:h "$@"` || exit 1
eval set -- "$TEMP"
while true; do
	case "$1" in
	-p|--path)
        echo Set context path to $2
        CONTEXT_PATH=$2
        shift 2;;
	-c|--checkout)
        echo Set commit to $2
        CHECKOUT_COMMIT=$2
        shift 2;;
	-h|--help)
        echo $0 [-p code_path] [-c checkout_commit_id_or_branch_name] git_repo_path ECR_URI
        exit 0;;
	--)	shift; break;;
	*)
        echo Error when processing options. Unknown opetion "$1"
        exit 1;;
	esac
done


if [ -n "$1" ]; then
    GIT_REPO=$1
fi
if [ -n "$2" ]; then
    IMAGE_TAG=$2
fi
if [ $CONTEXT_PATH -n ]; then
    CONTEXT_PATH=.
fi
if [ ${CONTEXT_PATH:0:1} == '/' ]; then
    CONTEXT_PATH=.$CONTEXT_PATH
fi

echo GIT_REPO=$GIT_REPO
echo IMAGE_TAG=$IMAGE_TAG
echo CONTEXT_PATH=$CONTEXT_PATH
echo CHECKOUT_COMMIT=$CHECKOUT_COMMIT

echo ================== CLONE CODE ==================

if [ "${GIT_REPO:0:4}" == "git@" ]; then
    echo Clone code using SSH key:
    cat ~/.ssh/id_rsa.pub
    echo Add server key to known host:
    ssh-keyscan $(echo ${GIT_REPO:4} | cut -d ':' -f '1') >> ~/.ssh/known_hosts
fi

if ! git clone ${GIT_REPO} ~/code; then
    echo Error when clone code.
    exit 1
fi

cd ~/code

if [ -n "$CHECKOUT_COMMIT" ]; then
    echo Checkout ${CHECKOUT_COMMIT} ...
    if ! git checkout -q ${CHECKOUT_COMMIT}; then
        echo Error when checkout ${CHECKOUT_COMMIT}.
    fi
fi

if [ ! -f ${CONTEXT_PATH}/Dockerfile ]; then
    echo Can\'t find Dockerfile in "${CONTEXT_PATH}" !
    exit 1
fi

GIT_COMMIT=$(git log -1 --pretty=format:"%h" -- ./${CONTEXT_PATH:1}/)
echo GIT_COMMIT=$GIT_COMMIT

echo ================ PULL OLD IMAGE ================
REGION=$(echo ${IMAGE_TAG} | cut -d '.' -f 4)
echo Login in to ECR $REGION ...
if ! $(aws ecr get-login --region ${REGION} --no-include-email); then
    echo Error when login to ECR.
    exit 1
fi
docker pull ${IMAGE_TAG}
OLD_IMAGE=$?
echo ================== BUILD IMAGE =================
if [ $OLD_IMAGE -eq 0 ]; then
    echo Using old image for cache.
    docker build -t ${IMAGE_TAG} --cache-from ${IMAGE_TAG} --build-arg https_proxy=${https_proxy} --build-arg http_proxy=${http_proxy} ${CONTEXT_PATH}/
else
    docker build -t ${IMAGE_TAG} --build-arg https_proxy=${https_proxy} --build-arg http_proxy=${http_proxy} ${CONTEXT_PATH}/
fi
if [ $? != 0 ]; then
    echo Error when building image.
    exit 1
fi
echo ================== PUSH IMAGE ==================
IMAGE_REPO=$(echo ${IMAGE_TAG} | cut -d ':' -f '1')
docker tag ${IMAGE_TAG} ${IMAGE_REPO}:${GIT_COMMIT}
# docker push ${IMAGE_REPO}:${GIT_COMMIT}
if ! docker push ${IMAGE_TAG}; then
    echo Error when pushing image.
    exit 1
fi

echo ================ BUILD SUCCESSED ===============