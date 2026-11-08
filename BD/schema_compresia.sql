-- =============================================================================
-- BASE DE DATOS: ComprensIA (v1.0.0)
-- Motor: MySQL 8.0+ / MariaDB 10.5+
-- =============================================================================

DROP DATABASE IF EXISTS `comprensia_db`;

CREATE DATABASE IF NOT EXISTS `comprensia_db` 
  DEFAULT CHARACTER SET utf8mb4 
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `comprensia_db`;

-- 1. USUARIOS
CREATE TABLE `usuarios` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `nombre` VARCHAR(100) NOT NULL,
  `apellidos` VARCHAR(150) NOT NULL,
  `email` VARCHAR(150) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `rol` ENUM('ALUMNO', 'PROFESOR') NOT NULL,
  `activo` BOOLEAN NOT NULL DEFAULT TRUE,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_usuarios_email` (`email`),
  INDEX `idx_usuarios_rol` (`rol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. CURSOS Y MATRÍCULAS
CREATE TABLE `cursos` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `nombre` VARCHAR(150) NOT NULL,
  `codigo_grupo` VARCHAR(50) NOT NULL UNIQUE,
  `descripcion` TEXT NULL,
  `profesor_id` BIGINT NOT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_cursos_profesor` FOREIGN KEY (`profesor_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_cursos_profesor` (`profesor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `matriculas` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `alumno_id` BIGINT NOT NULL,
  `curso_id` BIGINT NOT NULL,
  `fecha_matricula` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_matriculas_alumno` FOREIGN KEY (`alumno_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_matriculas_curso` FOREIGN KEY (`curso_id`) REFERENCES `cursos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY `uk_alumno_curso` (`alumno_id`, `curso_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. TEMAS, CRITERIOS Y RECURSOS
CREATE TABLE `temas` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `curso_id` BIGINT NOT NULL,
  `profesor_id` BIGINT NOT NULL,
  `titulo` VARCHAR(200) NOT NULL,
  `descripcion` TEXT NULL,
  `contexto_explicacion` LONGTEXT NOT NULL,
  `modo_entrega` ENUM('AULA', 'CASA') NOT NULL DEFAULT 'AULA',
  `estado` ENUM('BORRADOR', 'PUBLICADO', 'CERRADO') NOT NULL DEFAULT 'BORRADOR',
  `codigo_qr` VARCHAR(255) NULL UNIQUE,
  `tiempo_limite_minutos` INT NULL,
  `umbral_avanzar` DECIMAL(5,2) NOT NULL DEFAULT 70.00,
  `umbral_reforzar` DECIMAL(5,2) NOT NULL DEFAULT 40.00,
  `fecha_publicacion` DATETIME NULL,
  `fecha_limite` DATETIME NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_temas_curso` FOREIGN KEY (`curso_id`) REFERENCES `cursos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_temas_profesor` FOREIGN KEY (`profesor_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_temas_curso` (`curso_id`),
  INDEX `idx_temas_estado` (`estado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `conceptos_clave` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `tema_id` BIGINT NOT NULL,
  `concepto` VARCHAR(150) NOT NULL,
  `definicion_esperada` TEXT NOT NULL,
  `peso` DECIMAL(5,2) NOT NULL DEFAULT 1.00,
  `es_obligatorio` BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT `fk_conceptos_tema` FOREIGN KEY (`tema_id`) REFERENCES `temas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_conceptos_tema` (`tema_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `criterios` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `tema_id` BIGINT NOT NULL,
  `tipo` ENUM('CLARIDAD', 'CORRECCION', 'EJEMPLO', 'APLICACION', 'PERSONALIZADO') NOT NULL,
  `nombre` VARCHAR(150) NOT NULL,
  `descripcion` TEXT NOT NULL,
  `peso` DECIMAL(5,2) NOT NULL DEFAULT 1.00,
  CONSTRAINT `fk_criterios_tema` FOREIGN KEY (`tema_id`) REFERENCES `temas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_criterios_tema` (`tema_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `recursos` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `tema_id` BIGINT NOT NULL,
  `nombre_archivo` VARCHAR(255) NOT NULL,
  `ruta_almacenamiento` VARCHAR(500) NOT NULL,
  `tipo_mime` VARCHAR(100) NOT NULL,
  `tamano_bytes` BIGINT NOT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_recursos_tema` FOREIGN KEY (`tema_id`) REFERENCES `temas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_recursos_tema` (`tema_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. ENTREGAS Y RESPUESTAS
CREATE TABLE `entregas` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `tema_id` BIGINT NOT NULL,
  `alumno_id` BIGINT NOT NULL,
  `numero_intento` INT NOT NULL DEFAULT 1,
  `estado` ENUM('EN_PROGRESO', 'ENVIADO', 'ANALIZADO', 'ERROR_ANALISIS') NOT NULL DEFAULT 'ENVIADO',
  `fecha_envio` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_entregas_tema` FOREIGN KEY (`tema_id`) REFERENCES `temas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_entregas_alumno` FOREIGN KEY (`alumno_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_entregas_tema_alumno` (`tema_id`, `alumno_id`),
  INDEX `idx_entregas_estado` (`estado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `respuestas_entrega` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `entrega_id` BIGINT NOT NULL,
  `numero_paso` TINYINT NOT NULL,
  `pregunta_paso` VARCHAR(255) NOT NULL,
  `texto_respuesta` LONGTEXT NOT NULL,
  `longitud_caracteres` INT NOT NULL,
  CONSTRAINT `fk_respuestas_entrega` FOREIGN KEY (`entrega_id`) REFERENCES `entregas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY `uk_entrega_paso` (`entrega_id`, `numero_paso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. ANÁLISIS E INTELIGENCIA ARTIFICIAL
CREATE TABLE `analisis` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `entrega_id` BIGINT NOT NULL UNIQUE,
  `categoria` ENUM('NO_COMPRENDIDO', 'PARCIAL', 'COMPRENDIDO', 'DOMINADO') NOT NULL,
  `puntuacion_global` DECIMAL(5,2) NOT NULL,
  `tipo_analizador` VARCHAR(50) NOT NULL,
  `modelo_version` VARCHAR(50) NULL,
  `resumen_diagnostico` TEXT NULL,
  `tiempo_procesamiento_ms` INT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_analisis_entrega` FOREIGN KEY (`entrega_id`) REFERENCES `entregas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_analisis_categoria` (`categoria`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `analisis_criterio` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `analisis_id` BIGINT NOT NULL,
  `criterio_id` BIGINT NOT NULL,
  `puntuacion` DECIMAL(5,2) NOT NULL,
  `evidencia_textual` TEXT NULL,
  `comentario_mejora` TEXT NULL,
  CONSTRAINT `fk_analisis_criterio_analisis` FOREIGN KEY (`analisis_id`) REFERENCES `analisis` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_analisis_criterio_criterio` FOREIGN KEY (`criterio_id`) REFERENCES `criterios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_analisis_criterio_analisis` (`analisis_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. FEEDBACK Y DECISIONES
CREATE TABLE `recomendaciones` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `analisis_id` BIGINT NOT NULL,
  `destinatario` ENUM('ALUMNO', 'PROFESOR') NOT NULL,
  `tipo_recomendacion` VARCHAR(50) NOT NULL DEFAULT 'REPASO',
  `texto_recomendacion` TEXT NOT NULL,
  `prioridad` ENUM('BAJA', 'MEDIA', 'ALTA') NOT NULL DEFAULT 'MEDIA',
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_recomendaciones_analisis` FOREIGN KEY (`analisis_id`) REFERENCES `analisis` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_recomendaciones_analisis` (`analisis_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `decisiones_tema` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `tema_id` BIGINT NOT NULL,
  `profesor_id` BIGINT NOT NULL,
  `sugerencia_sistema` ENUM('AVANZAR', 'REFORZAR', 'REIMPARTIR') NOT NULL,
  `decision_final` ENUM('AVANZAR', 'REFORZAR', 'REIMPARTIR') NOT NULL,
  `porcentaje_comprendido` DECIMAL(5,2) NOT NULL,
  `porcentaje_parcial` DECIMAL(5,2) NOT NULL,
  `porcentaje_no_comprendido` DECIMAL(5,2) NOT NULL,
  `observaciones_profesor` TEXT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_decisiones_tema` FOREIGN KEY (`tema_id`) REFERENCES `temas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_decisiones_profesor` FOREIGN KEY (`profesor_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_decisiones_tema` (`tema_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. NOTIFICACIONES
CREATE TABLE `notificaciones` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `usuario_id` BIGINT NOT NULL,
  `titulo` VARCHAR(150) NOT NULL,
  `cuerpo` TEXT NOT NULL,
  `tipo` VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
  `leida` BOOLEAN NOT NULL DEFAULT FALSE,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_notificaciones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_notificaciones_usuario` (`usuario_id`),
  INDEX `idx_notificaciones_leida` (`leida`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
