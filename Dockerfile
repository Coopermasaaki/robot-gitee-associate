FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
WORKDIR /go/src/github.com/opensourceways/robot-gitee-associate
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 go build -a -o robot-gitee-associate -buildmode=pie --ldflags "-s -linkmode 'external' -extldflags '-Wl,-z,now'" .

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow && \
    dnf remove -y gdb-gdbserver && \
    groupadd -g 1000 associate && \
    useradd -u 1000 -g associate -s /sbin/nologin -m associate && \
    echo > /etc/issue && echo > /etc/issue.net && echo > /etc/motd && \
    mkdir /home/associate -p && \
    chmod 700 /home/associate && \
    chown associate:associate /home/associate && \
    echo 'set +o history' >> /root/.bashrc && \
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs && \
    rm -rf /tmp/*

USER associate

WORKDIR /opt/app

COPY  --chown=associate --from=BUILDER /go/src/github.com/opensourceways/robot-gitee-associate/robot-gitee-associate /opt/app/robot-gitee-associate

RUN chmod 550 /opt/app/robot-gitee-associate && \
    echo "umask 027" >> /home/associate/.bashrc && \
    echo 'set +o history' >> /home/associate/.bashrc

ENTRYPOINT ["/opt/app/robot-gitee-associate"]
