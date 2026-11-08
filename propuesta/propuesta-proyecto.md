# Propuesta de Proyecto DAM

> **Estado: BORRADOR v1.** Stack y alcance confirmados. Falta el nombre del alumno y el título definitivo.
> El anexo final es de trabajo interno y se elimina antes de entregar.

|                         |                                                                |
| ----------------------- | -------------------------------------------------------------- |
| **TÍTULO DEL PROYECTO** | ComprensIA — Evaluación de comprensión de aula asistida por IA |
| **ALUMNO**              | Alan Smith Valencia Izquierdo                                  |

---

## FUNCIONALIDAD GENERAL

Aplicación **móvil Android** con **APIREST** en servidor LAN y **base de datos SQL**.

El profesor prepara un tema y entrega a la aplicación el contexto necesario (explicación, conceptos clave y recursos). El alumnado responde un resumen guiado por pasos, con sus propias palabras, en clase o en casa según lo configure el profesor. Un analizador categoriza el nivel de comprensión, señala puntos de mejora y devuelve estadísticas al profesor para que decida si **avanza**, **refuerza** o **vuelve a impartir** el tema.

**No es un examen.** No aprueba ni desaprueba: entrega información para la toma de decisiones del profesor y recomendaciones de mejora al alumnado.

### Actores

| Actor                 | Qué hace                                                                                                                                               |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Profesor              | Crea temas, define conceptos clave y criterios, publica recursos, elige el modo de entrega (aula/casa), consulta métricas y decide la siguiente acción |
| Alumno                | Se registra, ve los temas activos, entrega el resumen guiado por pasos, consulta su resultado y sus recomendaciones                                    |
| Analizador (servicio) | Evalúa la entrega contra los criterios del tema y produce categoría, puntuaciones y recomendaciones                                                    |

### Flujo principal

1. El profesor crea el tema, define los **conceptos clave** y los **criterios de evaluación**, y adjunta los recursos.
2. Publica el tema e indica el **modo de entrega**: `AULA` (con tiempo límite y un único intento) o `CASA` (sin límite, varios intentos).
3. El alumno recibe la notificación y abre el **asistente de resumen en 4 pasos**:
   1. Explicá el tema con tus palabras.
   2. Explicá cómo funciona o dá un ejemplo concreto.
   3. Indicá qué parte no te quedó clara.
   4. Indicá para qué sirve o dónde se aplica.
4. El backend recibe la entrega y la envía al **analizador de comprensión**, junto con el contexto del tema.
5. El analizador devuelve: categoría (`NO_COMPRENDIDO` / `PARCIAL` / `COMPRENDIDO` / `DOMINADO`), puntuación por criterio, evidencia textual y puntos de mejora.
6. El alumno ve su resultado y sus recomendaciones; el profesor ve el **panel del tema** con estadísticas del curso y un semáforo: avanzar / reforzar / reimpartir.
7. El profesor puede exportar el informe en PDF y enviarlo por mail.

### Motor de decisión (semáforo)

El sistema no decide: **recomienda**. A partir de la distribución de categorías de un tema calcula una sugerencia con umbrales configurables por el profesor.

| Umbral (por defecto)                                 | Sugerencia                     |
| ---------------------------------------------------- | ------------------------------ |
| ≥ 70 % de las entregas en `COMPRENDIDO` o `DOMINADO` | **AVANZAR** al siguiente tema  |
| Entre 40 % y 70 %                                    | **REFORZAR** el conocimiento   |
| < 40 %                                               | **VOLVER A IMPARTIR** la clase |

El profesor puede ajustar los umbrales por tema y siempre registra su decisión final. Esa decisión queda auditada con fecha y usuario, de modo que el sistema aprende si la sugerencia sirvió: es el cierre del ciclo que da sentido al proyecto.

### Alcance

El documento declara la ambición completa para valorar complejidad; el **MVP comprometido** es el núcleo que cierra el ciclo del producto. El resto se implementa por orden de valor si el tiempo lo permite.

| Prioridad                | Contenido                                                                                                                                                                                               |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **MVP (comprometido)**   | Login con roles · CRUD de temas y criterios · asistente de resumen en 4 pasos · analizador heurístico + LLM intercambiables · resultado del alumno · panel del profesor con semáforo y gráficos básicos |
| **Deseable (por orden)** | 1) Informe PDF · 2) Notificaciones push (FCM) · 3) Caché offline con Room · 4) Envío de mail · 5) QR de acceso al tema                                                                                  |
| **Fuera de alcance**     | Aplicación de escritorio (ver anexo, decisión A1)                                                                                                                                                       |

Orden de implementación del MVP:

1. Base de datos y entidades JPA.
2. Autenticación con JWT y roles.
3. CRUD de temas, conceptos clave y criterios.
4. Asistente de resumen en Android + endpoint de entrega.
5. `AnalizadorHeuristico` y persistencia del análisis.
6. Resultado del alumno y panel del profesor con semáforo.
7. `AnalizadorLLM` como implementación alternativa.
8. Swagger y gráficos.

---

## FRONTEND (IDE y Lenguaje)

**IDE:** Android Studio — **Lenguaje:** Kotlin

| OPCIÓN DE MENÚ            | DESCRIPCIÓN                                                                                                              |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Iniciar sesión / Registro | Autenticación contra la APIREST con JWT. El rol devuelto (alumno/profesor) determina el menú visible                     |
| Mis temas                 | Listado de temas del curso con su estado: pendiente, entregado, analizado. Caché local para consulta sin conexión        |
| Entregar resumen          | Asistente de 4 pasos con guardado parcial, validación de longitud mínima y envío único o múltiple según el modo del tema |
| Mi resultado              | Categoría de comprensión obtenida, puntos fuertes, áreas de mejora y evidencia de lo que el sistema detectó              |
| Mi progreso               | Gráfico de evolución de la comprensión por tema y por materia                                                            |
| Recomendaciones           | Sugerencias de repaso personalizadas, generadas a partir del análisis                                                    |
| Panel del profesor        | Listado de temas con métricas agregadas, semáforo de decisión y detalle por alumno                                       |
| Notificaciones            | Avisos de tema nuevo y de resultado disponible (Firebase Cloud Messaging)                                                |
| Perfil                    | Datos del usuario, cambio de contraseña, cierre de sesión                                                                |

**Arquitectura:** MVVM (ViewModel + StateFlow), Retrofit para la APIREST, Room para caché, Firebase Cloud Messaging para push. Las llamadas de red se ejecutan en coroutines y el estado de la UI se expone como `StateFlow` inmutable, de modo que la pantalla no conoce al repositorio ni al cliente HTTP.

---

## BACKEND (IDE y Lenguaje)

**IDE:** IntelliJ IDEA — **Lenguaje:** Java — **Framework:** Spring Boot (Tomcat embebido)

| OPCIÓN DE MENÚ          | DESCRIPCIÓN                                                                                 |
| ----------------------- | ------------------------------------------------------------------------------------------- |
| Autenticación y roles   | Registro, login, emisión y validación de JWT, control de acceso por rol                     |
| Gestión de temas        | CRUD de temas, conceptos clave, criterios ponderados y modo de entrega                      |
| Gestión de recursos     | Subida y descarga de archivos del tema (PDF, imágenes) con control de tamaño y tipo         |
| Recepción de entregas   | Validación y persistencia de la entrega por pasos, respetando las reglas del modo aula/casa |
| Análisis de comprensión | Invoca el analizador, persiste resultado, puntuaciones por criterio y recomendaciones       |
| Panel del profesor      | Métricas por tema y curso, distribución de categorías, evolución y semáforo de decisión     |
| Recomendaciones         | Generación y consulta de recomendaciones para alumno y profesor                             |
| Informes                | Exportación a PDF de un tema o de un alumno                                                 |
| Documentación           | APIREST documentada con Swagger (anotaciones)                                               |

---

## TABLAS EN CASO DE USAR BASES DE DATOS SQL

**Motor:** MySQL

| TABLA                | DESCRIPCIÓN                                                                                                                                                    |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `usuarios`           | Cuentas del sistema: nombre, email, hash de contraseña, rol (ALUMNO/PROFESOR), estado activo                                                                   |
| `cursos`             | Agrupación de alumnos y temas (asignatura o grupo clase)                                                                                                       |
| `matriculas`         | Relación N:M entre usuarios alumno y cursos                                                                                                                    |
| `temas`              | Tema impartido: título, descripción, profesor, curso, modo de entrega (AULA/CASA), estado y fecha                                                              |
| `conceptos_clave`    | Conceptos que el alumno debería mencionar, asociados a un tema y con su peso                                                                                   |
| `criterios`          | Criterios de evaluación del tema (claridad, corrección, ejemplo, aplicación) con su peso                                                                       |
| `recursos`           | Archivos adjuntos del tema: nombre, tipo MIME, ruta de almacenamiento y tamaño                                                                                 |
| `entregas`           | Entrega de un alumno para un tema: estado, intento, fecha de envío                                                                                             |
| `respuestas_entrega` | Texto de cada paso del asistente, con su número de paso y longitud                                                                                             |
| `analisis`           | Resultado global de una entrega: categoría, puntuación, versión del analizador y fecha                                                                         |
| `analisis_criterio`  | Puntuación y comentario por criterio, con la evidencia textual detectada                                                                                       |
| `recomendaciones`    | Sugerencias generadas: destinatario (alumno/profesor) y texto                                                                                                  |
| `notificaciones`     | Avisos enviados a un usuario: título, cuerpo, estado de lectura y fecha                                                                                        |
| `decisiones_tema`    | Decisión final del profesor sobre un tema (avanzar/reforzar/reimpartir), con la sugerencia del sistema, los umbrales usados, la fecha y el usuario que decidió |

### Relaciones principales

```
usuarios 1--N temas (profesor)
cursos   1--N temas
usuarios N--M cursos        (matriculas)
temas    1--N conceptos_clave
temas    1--N criterios
temas    1--N recursos
temas    1--N entregas  /  usuarios 1--N entregas
entregas 1--N respuestas_entrega
entregas 1--1 analisis
analisis 1--N analisis_criterio
analisis 1--N recomendaciones
temas    1--N decisiones_tema  /  usuarios 1--N decisiones_tema
```

---

## FUNCIONALIDAD EXTRA QUE AUMENTA COMPLEJIDAD

| FUNCIONALIDAD              | POSIBLES OPCIONES                                                               | DESCRIPCIÓN                                               | OPCIONES USADAS                                            |
| -------------------------- | ------------------------------------------------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------- |
| Identificación de usuarios | Validación · Registro · CRUD · Validación de email · Cookies/sesiones/JWT/OAuth | Acceso con roles diferenciados alumno/profesor            | **Registro, validación, CRUD y JWT** (MVP)                 |
| APIREST con SWAGGER        | Swagger con JSON · Swagger con anotaciones                                      | Documentación viva de los endpoints                       | **Swagger con anotaciones** (MVP)                          |
| Notificaciones             | Firebase                                                                        | Aviso de tema nuevo y de resultado disponible             | **Firebase Cloud Messaging** (deseable)                    |
| Envío de mails             | —                                                                               | Envío del informe del tema al profesor                    | **Sí** (deseable)                                          |
| Imágenes                   | Archivo local · FTP/SFTP · Blob Storage · Base64 en BD                          | Recursos gráficos aportados por el profesor               | **Archivo local en servidor** (MVP)                        |
| PDF                        | —                                                                               | Informe de comprensión por tema o por alumno              | **Sí** (deseable)                                          |
| Códigos QR                 | —                                                                               | Código del tema para que el alumno se una rápido en clase | **Sí** (deseable)                                          |
| Gráficos                   | Barras · Circulares · Líneas                                                    | Distribución de categorías y evolución del alumno         | **Barras, circulares y líneas** (MVP: barras y circulares) |
| Animaciones                | —                                                                               | Transiciones del asistente de resumen y del resultado     | **Sí** (menor, deseable)                                   |
| Sensores                   | —                                                                               | No aplica                                                 | —                                                          |

---

## ACCESO A FICHEROS

| TIPO DE ACCESO | LUGAR       | TECNOLOGÍA                                                                                          | USADO  |
| -------------- | ----------- | --------------------------------------------------------------------------------------------------- | ------ |
| Ficheros       | Local       | Caché de temas y recursos descargados para consulta sin conexión (almacenamiento interno de la app) | **Sí** |
| Ficheros       | LAN o Cloud | Carpeta del servidor para recursos subidos por el profesor, servida por la APIREST                  | **Sí** |

---

## ACCESO A DATOS DE BASE DE DATOS

| TIPO DE ACCESO            | LUGAR                | TECNOLOGÍA                                                        | USADO  |
| ------------------------- | -------------------- | ----------------------------------------------------------------- | ------ |
| JDBC                      | Local                | SQLite mediante Room, como caché offline del alumno               | **Sí** |
| JDBC para BD SQL          | LAN o Cloud          | MySQL con JPA/Hibernate                                           | **Sí** |
| JDBC para noSQL           | LAN o Cloud          | No usado                                                          | —      |
| APIREST JPA - Local       | Servidor en LAN      | Spring Boot (Tomcat embebido) + MySQL                             | **Sí** |
| APIREST PHP - Local       | Servidor en LAN      | No usado                                                          | —      |
| APIREST - Local (otras)   | Servidor en LAN      | No usado: sin soporte del profesorado                             | —      |
| APIREST DAO / JPA - Cloud | Azure o AWS          | No usado                                                          | —      |
| APIREST - Open Data       | Servidor en Internet | API del proveedor de IA, consumida solo desde el backend (ver A3) | **Sí** |

---

## ANEXO — DECISIONES DE ALCANCE (uso interno, no entregar)

### A1. Desktop queda fuera del alcance comprometido

El enunciado exige **al menos una** tecnología no web, y Android ya lo cumple. Prometer escritorio "si me da el tiempo" en un trabajo individual es cómo se entrega un proyecto a medias: el tribunal evalúa lo que prometiste, no lo que intentaste. Si sobra tiempo, se agrega sin tocar el diseño (el backend ya expone todo por APIREST).

### A2. Framework de backend: Spring Boot

Confirmado que Spring Boot se vio en clase, es la opción correcta: es lo que el profesorado puede soportar y es el camino más corto hacia JPA, JWT y Swagger. Al traer **Tomcat embebido**, encaja además en la fila `APIREST JPA - Local (Apache Tomcat)` de la tabla de acceso a datos, sin necesidad de instalar un contenedor aparte.

Capas: `controller` (exposición y validación de entrada) → `service` (reglas de negocio) → `repository` (JPA/Hibernate) → `entity`/`dto`. El servicio de análisis queda aislado del controlador, que es lo que permite intercambiar el analizador sin tocar la APIREST.

### A3. La IA va detrás de una interfaz (decisión clave)

Una llamada a un proveedor externo no la da soporte ningún profesor, cuesta por token, exige red y puede fallar en plena defensa. Por eso el núcleo del sistema **no depende de la IA**:

```
AnalizadorComprension (interfaz)
├── AnalizadorHeuristico   → determinista: cobertura de conceptos clave,
│                            estructura de los pasos, longitud y coherencia.
│                            Sin red, sin costo, testeable. Siempre disponible.
└── AnalizadorLLM          → llama a un proveedor externo o a un modelo local
                             (Ollama). Se activa por configuración.
```

Ambos devuelven el **mismo DTO**, así que el resto del sistema no sabe cuál está activo. El profesor ve siempre categoría, puntuación por criterio y evidencia.

Consecuencia: si la API externa falla o no hay internet, la demo funciona igual. Y los tests son deterministas.

### A4. El profesor define los criterios, la IA solo los aplica

Si la IA "decide sola" qué está bien, el resultado es indefendible ante un tribunal y opaco para el alumno. En este diseño el profesor declara **conceptos clave y criterios con peso**; el analizador los usa como rúbrica. La IA aporta redacción y matices, no el criterio.

### A5. Privacidad: no enviar datos identificables a un servicio externo

Los resúmenes son producción intelectual de menores de edad en un centro educativo. Si se usa un proveedor externo, la petición debe ir **anonimizada** (sin nombre ni email) y la política tiene que quedar documentada. Es un requisito, no un detalle.

### A6. Modelo de entrega por tema

`AULA`: tiempo límite, un intento, sin material a la vista.
`CASA`: sin límite, varios intentos, se registra el intento.

Esto responde al "a preferencia del evaluador" del enunciado.

### A7. Riesgo de que el alumno responda con IA (límite conocido)

El sistema analiza **texto**, no verifica autoría. Un resumen generado por otra IA puede obtener una categoría alta y producir una decisión equivocada del profesor.

Mitigación estructural: el modo `AULA` (tiempo límite corto, un único intento, entrega dentro de la app, sin material a la vista) reduce la ventana para consultar una IA externa.

Límite declarado: en modo `CASA` el sistema **no puede garantizar** que la producción sea propia. Se documenta en la propuesta y se comunica al profesorado. No se implementa detección de estilo: daría falsos positivos imposibles de defender. La decisión final sigue siendo del profesor, que conoce el contexto del aula.

Es preferible un sistema honesto sobre lo que mide que uno que promete detectar lo que no puede.

---

## PENDIENTE DE CONFIRMAR
