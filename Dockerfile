FROM openjdk:17
VolUME /tmp
ADD target/citizenact.jar citizenact.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "citizenact.jar"]