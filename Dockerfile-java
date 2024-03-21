FROM openjdk:11-jre-slim

WORKDIR /app

COPY java-webserver.jar .

EXPOSE 8080

CMD ["java", "-jar", "java-webserver.jar"]