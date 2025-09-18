# Multi-stage Dockerfile for the backend (Render compatible)
# Build stage: uses Maven with Temurin JDK to compile the Spring Boot app
FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy only pom.xml first to leverage Docker layer caching for dependencies
COPY pom.xml ./

# Go offline to cache dependencies
RUN --mount=type=cache,target=/root/.m2 \
    mvn -q -DskipTests=true dependency:go-offline

# Now copy the source code
COPY src ./src

# Build the application (skip tests for faster container builds)
RUN --mount=type=cache,target=/root/.m2 \
    mvn -q -DskipTests=true package


# Runtime stage: slim JRE image
FROM eclipse-temurin:21-jre-jammy AS runtime

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -Dfile.encoding=UTF-8"
WORKDIR /app

# Copy the built jar from the builder stage
COPY --from=builder /app/target/*.jar /app/app.jar

# Render sets PORT env; Spring is configured to read it via server.port=${PORT:8080}
EXPOSE 8080

# Use sh -c so JAVA_OPTS can be expanded
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
