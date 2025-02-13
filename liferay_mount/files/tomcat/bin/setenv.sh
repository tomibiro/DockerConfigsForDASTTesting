#!/bin/sh
# NOTE: /bin/sh is used in catalina.sh in Tomcat, which executes this script in the same shell, so make sure to avoid any e.g. Bash-isms

# Original content, as shipped with Liferay DXP:
#CATALINA_OPTS="$CATALINA_OPTS -Dfile.encoding=UTF8 -Djava.net.preferIPv4Stack=true -Dorg.apache.catalina.loader.WebappClassLoader.ENABLE_CLEAR_REFERENCES=false -Duser.timezone=GMT -Xmx1024m -XX:MaxMetaspaceSize=512m"

if [ -z "$CATALINA_OPTS" ]; then
  # CATALINA_OPTS is empty or not set =>
  #     use our recommended settings + allow appending using LIFERAY_JAVA_OPTS environment variable
  #
  # Note: The base settings were picked for JDK 8u171, with no Docker / containers support assumed

  # The parent directory will not be created by the JVM (if not existing) and GC log file would never be created as a result
  gc_logs_dir="$CATALINA_HOME/logs"
  mkdir -p ${gc_logs_dir}

  # The originals from above, except heap / meta sizing, which we will do separately;
  # $CATALINA_OPTS is not set before this file is evaluated, so no need to use it
  # in the beginning of the new value
  CATALINA_OPTS_ORIGINAL="-Dfile.encoding=UTF8 \
  -Djava.locale.providers=JRE,COMPAT,CLDR \
  -Djava.net.preferIPv4Stack=true \
  -Dorg.apache.catalina.loader.WebappClassLoader.ENABLE_CLEAR_REFERENCES=false \
  -Duser.timezone=GMT"

  CATALINA_OPTS_BASIC="-server \
  -Duser.country=US \
  -Duser.language=en"

  CATALINA_OPTS_GC_LOGGING_FILE=${CATALINA_OPTS_GC_LOGGING_FILE:-"-Xlog:gc*,gc+ref=debug,gc+heap=debug,gc+age=trace:file=$gc_logs_dir/gc-%p-%t.log:tags,uptime,time,level:filecount=5,filesize=20m"}

  # Shenandoah GC
  CATALINA_OPTS_GC="-XX:+UseShenandoahGC \
  -XX:+DisableExplicitGC \
  -XX:+UseStringDeduplication \
  -XX:+UseNUMA \
  -XX:NewSize=4096m \
  -XX:SurvivorRatio=8 \
  -XX:TargetSurvivorRatio=80 \
  -XX:MaxTenuringThreshold=12 \
  -XX:InitialCodeCacheSize=64m \
  -XX:ReservedCodeCacheSize=256m"

  # Additional JVM info
  CATALINA_JVM_DIAG="-XshowSettings:all -XX:+UnlockDiagnosticVMOptions"

  LIFERAY_ADD_OPENS_OPTS="--add-opens=java.base/java.lang=ALL-UNNAMED \
  --add-opens=java.base/java.lang.invoke=ALL-UNNAMED \
  --add-opens=java.base/java.lang.reflect=ALL-UNNAMED \
  --add-opens=java.base/java.net=ALL-UNNAMED \
  --add-opens=java.base/sun.net.www.protocol.http=ALL-UNNAMED \
  --add-opens=java.base/sun.net.www.protocol.https=ALL-UNNAMED \
  --add-opens=java.base/sun.util.calendar=ALL-UNNAMED \
  --add-opens=jdk.zipfs/jdk.nio.zipfs=ALL-UNNAMED"

  CATALINA_CLUSTERING_JAVA11="--add-opens=jdk.naming.dns/com.sun.jndi.dns=java.naming"

  CATALINA_OPTS_METASPACE=${CATALINA_OPTS_METASPACE:-"-XX:MetaspaceSize=512m -XX:MaxMetaspaceSize=1g"}

  # For org.apache.catalina.security.SecurityListener in conf/server.xml
  # Not needed for Tomcat 9.0.7 and later, but we are on 9.0.6 for now.

  # Execute the same snippet here to have the same umask in the env as later set in the catalina.sh
  # BEGIN SNIPPET from stock catalina.sh;
  # Set UMASK unless it has been overridden
  if [ -z "$UMASK" ]; then
    UMASK="0027"
  fi
  umask $UMASK
  # END SNIPPET

  CATALINA_OPTS_UMASK="-Dorg.apache.catalina.security.SecurityListener.UMASK=$(umask)"

  LIFERAY_JVM_OPTS=${LIFERAY_JVM_OPTS:-${LIFERAY_JAVA_OPTS}}

  CATALINA_OPTS="$CATALINA_OPTS_ORIGINAL $CATALINA_OPTS_BASIC $CATALINA_JVM_DIAG $CATALINA_OPTS_GC_LOGGING_FILE $CATALINA_CLUSTERING_JAVA11 $LIFERAY_ADD_OPENS_OPTS $CATALINA_OPTS_GC $CATALINA_OPTS_METASPACE $CATALINA_OPTS_UMASK $LIFERAY_JVM_OPTS"

  # Json Layout logging for Tomcat
  CLASSPATH=$CLASSPATH:$CATALINA_BASE/lib/ecs-logging-core-1.6.0.jar:$CATALINA_BASE/lib/jul-ecs-formatter-1.6.0.jar
else
  # CATALINA_OPTS is set and not empty =>
  #     prevent the startup and suggest possible options

  echo ""
  echo "Overriding recommended JVM parameters for Lifery DXP using CATALINA_OPTS environment variable is not allowed. Hint: Use LIFERAY_JAVA_OPTS instead."
  echo "If you really want to replace CATALINA_OPTS with your set of JVM parameters, you need to replace the whole '$CATALINA_HOME/bin/setenv.sh', for example using a custom Dockerfile."
  echo ""

  exit 1
fi

# No need to echo the CATALINA_OPTS - they are listed both by Tomcat on startup and also by DXP 7.1 in recent fixpacks
