# Нам требуется образ, содержащий Gradle, при помощи
# ключевого слова as мы указываем псевдоним для контейнера сборки,
# чтобы при его помощи в дальнейшем обращаться к контейнеру
FROM gradle:8-jdk17 as build

# Собирать проект будем в /build
WORKDIR /build

# Теперь необходимо скопировать необходимые для сборки проекта файлы в конейнер
COPY src src
COPY build.gradle.kts build.gradle.kts
COPY settings.gradle.kts settings.gradle.kts

# И запустить сборку проекта. Загружаемые библиотеки желательно кэшировать между
# сборками,для этого нужно добавить --mount=type=cache,target=/root/.m2 к RUN
RUN --mount=type=cache,target=/root/.m2 gradle clean build downloadLibs

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

# Со временем у проекта будет изменяться версия, и чтобы не изменять всякий раз
# этот Dockerfile имя jar-файла вынесем в аргумент.
ARG JAR_FILE=sandbox-greetings-gradle-23.1.1-SNAPSHOT-plain.jar

# Создадим рабочую директорию проекта
WORKDIR /application

# Скопируем в рабочую директорию проекта JAR-файл проекта и его зависимости
COPY --from=build /build/build/libs/${JAR_FILE} application.jar
COPY --from=build /build/build/dependency lib

# В конце укажем точку входа. Выбран вариант с использованием exec для того, чтобы
# можно было передать в строку запуска дополнительные параметры запуска - JAVA_OPTS, а так же
# ${0} и ${@} для передачи аргументов запуска.
ENTRYPOINT exec java ${JAVA_OPTS} -cp lib/*:application.jar pro.akosarev.sandbox.GreetingsGradleApplication ${0} ${@}