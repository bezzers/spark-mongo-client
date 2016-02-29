FROM gettyimages/spark
MAINTAINER Paul Beswick

# Add necessary libraries for ipython and git
RUN apt-get update
RUN apt-get install -y python-dev python-pip python-numpy python-scipy python-pandas gfortran
RUN apt-get install -y git-all

# Install ipython
RUN pip install nose "ipython[notebook]"

# Add a non-root user
RUN useradd -ms /bin/sh notebook

EXPOSE 8888

# Create a file to run as the entrypoint which passes a spark master argument to docker run through
# This line writes the SPARK environment variables into a spark configuration file
RUN echo 'env | grep SPARK | awk '\''{print "export \"" $0 "\""}'\'' > /usr/spark/conf/spark-env.sh' > run.sh
# This line edits the dns resolvers file to point to the docker bridge and consul dns server
RUN echo 'echo nameserver 172.17.42.1 > /etc/resolv.conf && echo search service.consul node.consul >> /etc/resolv.conf' >> run.sh
# This line removes anything registered in /etc/hosts on the docker network - not needed when we run with --net=host
#RUN echo 'cat /etc/hosts | grep -v 172.17 > tmphosts && cat tmphosts > /etc/hosts && rm tmphosts' >> run.sh
# This line sets a bunch of PYSPARK options
RUN echo PYSPARK_DRIVER_PYTHON=ipython \
	PYSPARK_DRIVER_PYTHON_OPTS=\"notebook --no-browser --notebook-dir=/home/notebook --NotebookApp.password=sha1:fc71502d8f24:c1b14c601036d1cc8522ee36d39e97796abfa067 --port=8888 --ip=*\" \
	/usr/spark/bin/pyspark --master \"\$\@\" \
	--packages com.stratio.datasource:spark-mongodb_2.10:0.11.0 \
	>> /run.sh

RUN chmod +x /run.sh

USER notebook

ENTRYPOINT ["/bin/bash","/run.sh"]
CMD ["local"]
