FROM centos:6

COPY files/proxy.sh /tmp/proxy.sh
RUN /tmp/proxy.sh

RUN yum -y install \
  libffi-devel \
  libxml2-devel \
  libxslt-devel \
  perl \
  ruby \
  rubygems \
  ruby-devel \
  ; yum -y groupinstall "Development tools" \
  ; yum clean all

RUN gem install --no-rdoc --no-ri bundler rake rspec && rm -fr /root/.gem

COPY files/bundle.sh /tmp/bundle.sh
