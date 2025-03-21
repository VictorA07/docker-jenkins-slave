FROM ubuntu:18.04

# Make sure the package repository is up to date.
RUN apt-get update && \
    apt-get install -qy git && \
# Install a basic SSH server
    apt-get install -qy openssh-server && \
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd && \
# Install JDK 17
    apt-get install -y openjdk-17-jdk && \
# Install Maven
    apt-get install -qy maven && \
# Cleanup old packages
    apt-get -qy autoremove && \
# Add user jenkins to the image
    adduser --quiet jenkins && \
# Set password for the jenkins user (you may want to alter this).
    echo "jenkins:password" | chpasswd && \
    mkdir /home/jenkins/.m2

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Set Maven options globally to allow access to restricted classes
ENV MAVEN_OPTS="--add-opens java.base/java.lang=ALL-UNNAMED \
                --add-opens java.base/java.lang.invoke=ALL-UNNAMED \
                --add-opens java.base/java.util=ALL-UNNAMED"

# Copy authorized keys
COPY .ssh/authorized_keys /home/jenkins/.ssh/authorized_keys

RUN chown -R jenkins:jenkins /home/jenkins/.m2/ && \
    chown -R jenkins:jenkins /home/jenkins/.ssh/

# Run Maven build with required Java security options
RUN mvn clean install \
    -Djava.security.manager=allow \
    --add-opens java.base/java.lang=ALL-UNNAMED \
    --add-opens java.base/java.lang.invoke=ALL-UNNAMED \
    --add-opens java.base/java.util=ALL-UNNAMED || true

# Standard SSH port
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
