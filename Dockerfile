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
RUN echo PYSPARK_DRIVER_PYTHON=ipython \
	PYSPARK_DRIVER_PYTHON_OPTS=\"notebook --no-browser --notebook-dir=/home/notebook --NotebookApp.password=sha1:fc71502d8f24:c1b14c601036d1cc8522ee36d39e97796abfa067 --port=8888 --ip=*\" \
	/usr/spark/bin/pyspark --master \"\$\@\" \
	--packages com.stratio.datasource:spark-mongodb_2.10:0.11.0 \
	>> /run.sh
RUN chmod +x /run.sh

USER notebook

ENTRYPOINT ["/bin/bash","/run.sh"]
CMD ["local"]
