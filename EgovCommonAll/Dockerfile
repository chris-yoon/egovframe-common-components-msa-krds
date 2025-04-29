FROM tomcat:9-jre8-temurin

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR file
COPY target/egovframework-all-in-one.war /usr/local/tomcat/webapps/ROOT.war

# Add custom server configuration if needed
COPY server.xml /usr/local/tomcat/conf/server.xml

# Set environment variables
ENV JAVA_OPTS="-Xms512m -Xmx1024m"

EXPOSE 8080
CMD ["catalina.sh", "run"]