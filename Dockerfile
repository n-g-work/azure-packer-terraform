FROM maven:3.8.4-openjdk-11-slim as builder
RUN apt-get update && apt-get install -y git
RUN cd /usr/src \
  && git clone https://github.com/spring-projects/spring-petclinic.git \
  && cd spring-petclinic \
  && mvn package

FROM openjdk:19-jdk-alpine
RUN cd /usr/local/bin
COPY --from=builder /usr/src/spring-petclinic/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]