FROM quay.io/konflux-ci/release-service-utils@sha256:bd541d08823b7b77a5637af44cb5042bb31d765a18c8739643c8e176f55c83cf

# It is mandatory to set these labels
LABEL name="Konflux Release Service Catalog"
LABEL description="Konflux Release Service Catalog"
LABEL io.k8s.description="Konflux Release Service Catalog"
LABEL io.k8s.display-name="release-service-catalog"
LABEL summary="Konflux Release Service Catalog"
LABEL com.redhat.component="release-service-catalog"

ADD integration-tests/collectors $HOME/tests/collectors
ADD integration-tests/scripts $HOME/tests/scripts

RUN python3 -m pip install --user ansible
RUN ansible-vault --version
RUN kubectl version --client=true
RUN echo $HOME

RUN curl -L https://github.com/tektoncd/cli/releases/download/v0.40.0/tektoncd-cli-0.40.0_Linux-64bit.rpm \
    -o /tmp/tektoncd-cli_Linux-64bit.rpm
RUN dnf install -y /tmp/tektoncd-cli-_Linux-64bit.rpm
RUN tkn version --component client
