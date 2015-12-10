#/*
# * Licensed to the Apache Software Foundation (ASF) under one
# * or more contributor license agreements.  See the NOTICE file
# * distributed with this work for additional information
# * regarding copyright ownership.  The ASF licenses this file
# * to you under the Apache License, Version 2.0 (the
# * "License"); you may not use this file except in compliance
# * with the License.  You may obtain a copy of the License at
# *
# *     http://www.apache.org/licenses/LICENSE-2.0
# *
# * Unless required by applicable law or agreed to in writing, software
# * distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# * See the License for the specific language governing permissions and
# * limitations under the License.
# */

# Set Hadoop-specific environment variables here.

# The only required environment variable is JAVA_HOME.  All others are
# optional.  When running a distributed configuration it is best to
# set JAVA_HOME in this file, so that it is correctly defined on
# remote nodes.

# The java implementation to use.  Required.
export JAVA_HOME=${JAVA_HOME:-"{{java.java_home}}"} # RYBA CONF \"java.java_home\", DONT OVEWRITE
export HADOOP_HOME_WARN_SUPPRESS=1

# Hadoop home directory
export HADOOP_HOME=${HADOOP_HOME:-"/usr/hdp/current/hadoop-client"}

# Path to jsvc required by secure HDP 2.0 datanode
if [ -d /usr/libexec/bigtop-utils ]; then
  export JSVC_HOME=/usr/libexec/bigtop-utils
else
  export JSVC_HOME=/usr/lib/bigtop-utils
fi

# Where log files are stored.  $HADOOP_HOME/logs by default.
export HADOOP_LOG_DIR=${HADOOP_LOG_DIR:-{{ryba.hdfs.log_dir}}} # RYBA CONF "ryba.hdfs.log_dir", DONT OVEWRITE


# The maximum amount of heap to use, in MB. Default is 1000.
export HADOOP_HEAPSIZE=${HADOOP_HEAPSIZE:-"{{ryba.hadoop_heap}}"} # RYBA CONF "ryba.hadoop_heap", DONT OVEWRITE

export HADOOP_NAMENODE_INIT_HEAPSIZE=${HADOOP_NAMENODE_INIT_HEAPSIZE:-"{{ryba.hadoop_namenode_init_heap}}"} # RYBA CONF "ryba.hadoop_namenode_init_heap", DONT OVEWRITE

# Extra Java runtime options.  Empty by default.
HADOOP_OPTS=${HADOOP_OPTS:-"{{ryba.hadoop_opts}}"} # RYBA CONF "ryba.hadoop_opts", DONT OVEWRITE
export HADOOP_OPTS="-Djava.net.preferIPv4Stack=true ${HADOOP_OPTS}"

# Command specific options appended to HADOOP_OPTS when specified
HADOOP_DATANODE_OPTS="{{hdfs.namenode_opts}} ${HADOOP_DATANODE_OPTS}" # RYBA CONF "ryba.hdfs.datanode_opts", DONT OVERWRITE"
export HADOOP_NAMENODE_OPTS="-server -XX:ParallelGCThreads=8 -XX:+UseConcMarkSweepGC -XX:ErrorFile=${HADOOP_LOG_DIR}/hs_err_pid%p.log -XX:NewSize=200m -XX:MaxNewSize=200m -XX:PermSize=128m -XX:MaxPermSize=256m -Xloggc:${HADOOP_LOG_DIR}/gc.log-`date +'%Y%m%d%H%M'` -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -Xms1024m -Xmx1024m -Dhadoop.security.logger=INFO,DRFAS -Dhdfs.audit.logger=INFO,DRFAAUDIT ${HADOOP_NAMENODE_OPTS}"
HADOOP_JOBTRACKER_OPTS="-server -XX:ParallelGCThreads=8 -XX:+UseConcMarkSweepGC -XX:ErrorFile=${HADOOP_LOG_DIR}/hs_err_pid%p.log -XX:NewSize=200m -XX:MaxNewSize=200m -Xloggc:${HADOOP_LOG_DIR}/gc.log-`date +'%Y%m%d%H%M'` -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -Xmx1024m -Dhadoop.security.logger=INFO,DRFAS -Dmapred.audit.logger=INFO,MRAUDIT -Dhadoop.mapreduce.jobsummary.logger=INFO,JSA ${HADOOP_JOBTRACKER_OPTS}"

HADOOP_TASKTRACKER_OPTS="-server -Xmx1024m -Dhadoop.security.logger=ERROR,console -Dmapred.audit.logger=ERROR,console ${HADOOP_TASKTRACKER_OPTS}"
HADOOP_DATANODE_OPTS="{{ryba.hdfs.datanode_opts}} ${HADOOP_DATANODE_OPTS}" # RYBA CONF "ryba.hdfs.datanode_opts", DONT OVERWRITE"
export HADOOP_DATANODE_OPTS="-server -XX:ParallelGCThreads=4 -XX:+UseConcMarkSweepGC -XX:ErrorFile=${HADOOP_LOG_DIR}/hs_err_pid%p.log -XX:NewSize=200m -XX:MaxNewSize=200m -XX:PermSize=128m -XX:MaxPermSize=256m -Xloggc:${HADOOP_LOG_DIR}/gc.log-`date +'%Y%m%d%H%M'` -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -Xms1024m -Xmx1024m -Dhadoop.security.logger=INFO,DRFAS -Dhdfs.audit.logger=INFO,DRFAAUDIT ${HADOOP_DATANODE_OPTS}"
HADOOP_BALANCER_OPTS="-server -Xmx1024m ${HADOOP_BALANCER_OPTS}"

export HADOOP_SECONDARYNAMENODE_OPTS=$HADOOP_NAMENODE_OPTS

# The following applies to multiple commands (fs, dfs, fsck, distcp etc)
HADOOP_CLIENT_OPTS=${HADOOP_CLIENT_OPTS:-"{{ryba.hadoop_client_opts}}"} # RYBA CONF "ryba.hadoop_client_opts", DONT OVEWRITE
export HADOOP_CLIENT_OPTS="-Xmx${HADOOP_HEAPSIZE}m -XX:MaxPermSize=512m $HADOOP_CLIENT_OPTS"

# On secure datanodes, user to run the datanode as after dropping privileges
export HADOOP_SECURE_DN_USER=${HADOOP_SECURE_DN_USER:-"{{hdfs.user.name}}"} # RYBA CONF "ryba.hdfs.user.name", DONT OVERWRITE"

# Extra ssh options.  Empty by default.
export HADOOP_SSH_OPTS="-o ConnectTimeout=5 -o SendEnv=HADOOP_CONF_DIR"

# History server logs
export HADOOP_MAPRED_LOG_DIR=${HADOOP_MAPRED_LOG_DIR:-{{ryba.mapred.log_dir}}}

# Where log files are stored in the secure data environment.
export HADOOP_SECURE_DN_LOG_DIR={{ryba.hdfs.log_dir}}

# File naming remote slave hosts.  $HADOOP_HOME/conf/slaves by default.
# export HADOOP_SLAVES=${HADOOP_HOME}/conf/slaves

# host:path where hadoop code should be rsync'd from.  Unset by default.
# export HADOOP_MASTER=master:/home/$USER/src/hadoop

# Seconds to sleep between slave commands.  Unset by default.  This
# can be useful in large clusters, where, e.g., slave rsyncs can
# otherwise arrive faster than the master can service them.
# export HADOOP_SLAVE_SLEEP=0.1

# The directory where pid files are stored. /tmp by default.
export HADOOP_PID_DIR=${HADOOP_PID_DIR:-"{{ryba.hdfs.pid_dir}}"} # RYBA CONF "ryba.hdfs.pid_dir", DONT OVEWRITE
export HADOOP_SECURE_DN_PID_DIR=${HADOOP_SECURE_DN_PID_DIR-"{{ryba.hdfs.secure_dn_pid_dir}}"} # RYBA CONF "ryba.hdfs.secure_dn_pid_dir", DONT OVEWRITE

# History server pid
export HADOOP_MAPRED_PID_DIR=${HADOOP_MAPRED_PID_DIR:-{{ryba.mapred.pid_dir}}}

YARN_RESOURCEMANAGER_OPTS="-Dyarn.server.resourcemanager.appsummary.logger=INFO,RMSUMMARY"

# A string representing this instance of hadoop. $USER by default.
export HADOOP_IDENT_STRING=$USER

# The scheduling priority for daemon processes.  See 'man nice'.

# export HADOOP_NICENESS=10

# Use libraries from standard classpath
JAVA_JDBC_LIBS=""
#Add libraries required by mysql connector
for jarFile in `ls /usr/share/java/*mysql* 2>/dev/null`
do
  JAVA_JDBC_LIBS=${JAVA_JDBC_LIBS}:$jarFile
done
# Add libraries required by oracle connector
for jarFile in `ls /usr/share/java/*ojdbc* 2>/dev/null`
do
  JAVA_JDBC_LIBS=${JAVA_JDBC_LIBS}:$jarFile
done
# Add libraries required by nodemanager
MAPREDUCE_LIBS=/usr/hdp/current/hadoop-mapreduce-client/*
HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:{{ryba.hadoop_classpath}}
export HADOOP_CLASSPATH=${HADOOP_CLASSPATH}${JAVA_JDBC_LIBS}:${MAPREDUCE_LIBS}

# added to the HADOOP_CLASSPATH
if [ -d "/usr/hdp/current/tez-client" ]; then
  if [ -d "/etc/tez/conf/" ]; then
    # When using versioned RPMs, the tez-client will be a symlink to the current folder of tez in HDP.
    export HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:/usr/hdp/current/tez-client/*:/usr/hdp/current/tez-client/lib/*:/etc/tez/conf/
  fi
fi

# Setting path to hdfs command line
export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec

# Mostly required for hadoop 2.0
export JAVA_LIBRARY_PATH=${JAVA_LIBRARY_PATH}

export HADOOP_OPTS="-Dhdp.version=$HDP_VERSION $HADOOP_OPTS"

export HADOOP_ZKFC_OPTS="{{ryba.zkfc.opts}} ${HADOOP_ZKFC_OPTS}" # RYBA ENV "ryba.zkfc.opts", DONT OVERWRITE
