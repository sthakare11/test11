FROM amazeeio/commons as commons
FROM registry.redhat.io/rhel7:latest
RUN yum update --enablerepo=rhel-7-server-rpms -y
RUN yum install --enablerepo=rhel-7-server-rpms vi vim zsh  systemd -y
RUN yum install --enablerepo=rhel-7-server-extras-rpms openssh-server openssh openldap-clients compat-openldap pam_krb5 sssd -y
ENV SFTP_USER 'sftpupload'
ENV SFTP_PASSWORD 'ITAdds^^'
COPY .lagoon.env.* /
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/
COPY --from=commons /sbin/tini /sbin/
RUN yum update -y && \
    mkdir -p /var/run/sshd && \
    mkdir -p /var/run/sftp && \
    rm -f /etc/ssh/ssh_host_*key*
RUN rm /lagoon/entrypoints/10-passwd.sh

COPY sftp-container/init.sh /
RUN chmod +x init.sh && ./init.sh
COPY sftp-container/sshd_config /etc/ssh/sshd_config
COPY sftp-container/docker-entrypoint.sh /lagoon/entrypoints/70-sshd-start

RUN fix-permissions /run/
RUN fix-permissions /home/${SFTP_USER}/

EXPOSE 2222

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["/usr/sbin/sshd", "-e", "-D", "-f", "/etc/ssh/sshd_config"]
