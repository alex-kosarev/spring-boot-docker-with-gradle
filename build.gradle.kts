import org.springframework.boot.gradle.tasks.bundling.BootBuildImage

plugins {
    java
    id("org.springframework.boot") version "3.1.4"
    id("io.spring.dependency-management") version "1.1.3"
}

group = "pro.akosarev.sandbox"
version = "23.1.1-SNAPSHOT"


java {
    sourceCompatibility = JavaVersion.VERSION_17
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

tasks.withType<Test> {
    useJUnitPlatform()
}

tasks.register<Copy>("downloadLibs") {
    from(configurations.named("runtimeClasspath"))
    into {
        project.layout.buildDirectory.dir("dependency")
    }
}

tasks.named<BootBuildImage>("bootBuildImage") {
    // Имя образа
    imageName = "sandbox-greetings-gradle"

    // Список используемых Buildpacks
    buildpacks.add("paketobuildpacks/ca-certificates:3.6.3")
    buildpacks.add("paketobuildpacks/bellsoft-liberica:10.4.0")
    buildpacks.add("paketobuildpacks/syft:1.32.1")
    buildpacks.add("paketobuildpacks/executable-jar:6.7.4")
    buildpacks.add("paketobuildpacks/dist-zip:5.6.4")
    buildpacks.add("paketobuildpacks/spring-boot:5.26.1")

    // Список пробрасываемых директорий в Buildpacks
    bindings.add("${projectDir}/platform/bindings:/platform/bindings")
}
