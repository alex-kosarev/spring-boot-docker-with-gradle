FROM gradle:8-jdk17 as build
WORKDIR /build
COPY src src
COPY build.gradle.kts build.gradle.kts
COPY settings.gradle.kts settings.gradle.kts

RUN --mount=type=cache,target=/root/.m2 \
    gradle clean build && \
    java -Djarmode=layertools \
    -jar build/libs/sandbox-greetings-gradle-23.1.1-SNAPSHOT.jar \
    extract --destination build/extracted

# При помощи ключевого слова FROM необходимо указать исходный образ,
# который мы будем использовать для создания своего.
# Для данного примера выбран образ на основе Debian с установленным
# Liberica OpenJDK 17 версии, поскольку нам он нужен для запуска приложения.
FROM bellsoft/liberica-openjdk-debian:17

# Желательно запускать приложения не от имени суперпользователя, который
# используется по умолчанию, поэтому нужно создать пользователя и группу
# для запуска приложения.
RUN addgroup spring-boot-group && adduser --ingroup spring-boot-group spring-boot
USER spring-boot:spring-boot-group

# Иногда требуется получить доступ к файлам, генерирующимся в процессе выполнения,
# для этого зарегистрируем том /tmp
VOLUME /tmp

# Создадим рабочую директорию проекта
WORKDIR /application
COPY --from=build /build/build/extracted/application .
COPY --from=build /build/build/extracted/dependencies .
COPY --from=build /build/build/extracted/snapshot-dependencies .
COPY --from=build /build/build/extracted/spring-boot-loader .
ENTRYPOINT exec java org.springframework.boot.loader.JarLauncher ${0} ${@}