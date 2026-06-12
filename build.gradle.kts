import com.github.gradle.node.npm.task.NpmTask

plugins {
    java
    id("org.springframework.boot") version "3.4.5"
    id("io.spring.dependency-management") version "1.1.7"
    id("com.github.node-gradle.node") version "7.0.2"
}

group = "com.github.lafarer"
version = "0.1.0-SNAPSHOT"

java {
    toolchain { languageVersion = JavaLanguageVersion.of(21) }
}

configurations {
    compileOnly { extendsFrom(configurations.annotationProcessor.get()) }
}

repositories {
    mavenCentral()
}

dependencies {
    // Spring Boot
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-validation")

    // jte template engine
    implementation("gg.jte:jte-spring-boot-starter-3:3.1.12")

    // SQLite
    implementation("org.xerial:sqlite-jdbc:3.47.0.0")
    implementation("org.hibernate.orm:hibernate-community-dialects")

    // Anthropic Java SDK
    implementation("com.anthropic:anthropic-java:1.1.0")

    // PDF processing
    implementation("org.apache.pdfbox:pdfbox:3.0.3")

    // Utilities
    implementation("com.github.slugify:slugify:3.0.7")
    implementation("com.fasterxml.jackson.core:jackson-databind")

    // Lombok
    compileOnly("org.projectlombok:lombok")
    annotationProcessor("org.projectlombok:lombok")

    // Dev tools
    developmentOnly("org.springframework.boot:spring-boot-devtools")

    // Test
    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

node {
    version = "20.18.0"
    download = true
    nodeProjectDir = file("${projectDir}/src/main/frontend")
}

val compileSass = tasks.register<NpmTask>("compileSass") {
    dependsOn(tasks.npmInstall)
    args = listOf("run", "build:css")
    inputs.dir("src/main/frontend/scss")
    outputs.file("src/main/resources/static/css/app.css")
}

tasks.processResources {
    dependsOn(compileSass)
}

tasks.test {
    useJUnitPlatform()
}
