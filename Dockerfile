FROM gettyimages/spark
MAINTAINER Paul Beswick

# Add necessary libraries for ipython and git
RUN apt-get update
RUN apt-get install -y python-dev python-pip python-numpy python-scipy python-pandas gfortran
RUN apt-get install -y git-all

# Install ipython
RUN pip install nose "ipython[notebook]"

# Download the mongo-hadoop connector library and build it
RUN git clone https://github.com/mongodb/mongo-hadoop.git
RUN cd /mongo-hadoop && ./gradlew jar

# Install pymongo-spark
RUN cd /mongo-hadoop/spark/src/main/python && python setup.py install

# Add a non-root user
RUN useradd -ms /bin/sh notebook

EXPOSE 8888

# Create a file to run as the entrypoint which passes a spark master argument to docker run through
#RUN echo '/usr/spark/bin/spark-class org.apache.spark.deploy.worker.Worker "$@" -h $(hostname) &' >> /run.sh
RUN echo PYSPARK_DRIVER_PYTHON=ipython \
	PYSPARK_DRIVER_PYTHON_OPTS=\"notebook --no-browser --notebook-dir=/home/notebook --NotebookApp.password=sha1:fc71502d8f24:c1b14c601036d1cc8522ee36d39e97796abfa067 --port=8888 --ip=*\" \
	/usr/spark/bin/pyspark --master \"\$\@\" \
	--jars /mongo-hadoop/spark/build/libs/mongo-hadoop-spark-1.5.0-rc1-SNAPSHOT.jar \
	--driver-class-path /mongo-hadoop/spark/build/libs/mongo-hadoop-spark-1.5.0-rc1-SNAPSHOT.jar \
	--py-files /mongo-hadoop/spark/src/main/python/pymongo_spark.py \
	>> /run.sh
RUN chmod +x /run.sh

USER notebook

ENTRYPOINT ["/bin/bash","/run.sh"]
CMD ["local"]
